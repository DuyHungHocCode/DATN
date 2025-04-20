-- =============================================================================
-- File: database/partitioning/partitioning_functions.sql
-- Description: Định nghĩa các function PL/pgSQL để thiết lập và quản lý
--              phân vùng dữ liệu cho hệ thống QLDCQG.
-- Version: 1.0 (Tách từ file setup_partitioning.sql gốc)
--
-- Lưu ý: Các function này cần được tạo trong database tương ứng
--       (ministry_of_public_security, ministry_of_justice,
--        national_citizen_central_server) nơi chúng sẽ được sử dụng.
-- =============================================================================

\echo '*** BẮT ĐẦU ĐỊNH NGHĨA CÁC FUNCTIONS PHÂN VÙNG ***'

-- ============================================================================
-- I. FUNCTIONS CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\connect ministry_of_public_security
\echo '-> Định nghĩa functions phân vùng cho ministry_of_public_security...'

-- Function helper trích xuất cấu trúc tạo bảng (cần thiết cho setup_nested_partitioning)
-- Cần tạo ở cả 3 DB nếu setup_nested_partitioning dùng nó.
CREATE OR REPLACE FUNCTION partitioning.pg_get_tabledef(p_table_name TEXT) RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_list TEXT;
BEGIN
    -- Trích xuất danh sách cột và kiểu dữ liệu cơ bản, ràng buộc NOT NULL
    -- Lưu ý: Hàm này đơn giản hóa, không lấy FK, CHECK, default values...
    -- Chỉ đủ dùng cho việc tạo bảng LIKE trong ngữ cảnh phân vùng này.
    SELECT string_agg(
        quote_ident(column_name) || ' ' ||
        CASE
            WHEN udt_name IN ('varchar', 'bpchar') AND character_maximum_length IS NOT NULL THEN data_type || '(' || character_maximum_length || ')'
            WHEN udt_name IN ('numeric', 'decimal') AND numeric_precision IS NOT NULL AND numeric_scale IS NOT NULL THEN data_type || '(' || numeric_precision || ',' || numeric_scale || ')'
            WHEN udt_name IN ('numeric', 'decimal') AND numeric_precision IS NOT NULL THEN data_type || '(' || numeric_precision || ')'
            ELSE data_type
        END ||
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END,
        E',\n    ' ORDER BY ordinal_position
    )
    INTO v_column_list
    FROM information_schema.columns
    WHERE table_schema = split_part(p_table_name, '.', 1)
      AND table_name = split_part(p_table_name, '.', 2);

    -- Tạo câu lệnh DDL cơ bản
    v_table_ddl := E'(\n    ' || v_column_list || E'\n)';

    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql;

-- Function khởi tạo phân vùng đơn giản theo vùng địa lý
CREATE OR REPLACE FUNCTION partitioning.setup_region_partitioning(
    p_schema TEXT,
    p_table TEXT,
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_regions TEXT[] := ARRAY['Bắc', 'Trung', 'Nam'];
    v_region TEXT;
    v_partition_name TEXT;
    v_old_table_exists BOOLEAN;
    v_ddl TEXT;
BEGIN
    \echo format('    - Bắt đầu setup_region_partitioning cho %I.%I...', p_schema, p_table);

    -- Kiểm tra bảng gốc có tồn tại không
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = p_schema AND table_name = p_table
    ) INTO v_old_table_exists;

    IF NOT v_old_table_exists THEN
        \echo format('      Lỗi: Bảng %I.%I không tồn tại.', p_schema, p_table);
        RETURN FALSE;
    END IF;

    -- Lấy DDL của bảng gốc
    v_ddl := partitioning.pg_get_tabledef(p_schema || '.' || p_table);

    -- Tạo bảng tạm thời với cấu trúc phân vùng (nếu chưa có)
    -- Sử dụng tên có hậu tố _root để tránh xung đột khi đổi tên
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.%I_root %s
        PARTITION BY LIST (%I);
    ', p_schema, p_table, v_ddl, p_column);
    \echo format('      Đã tạo/xác nhận bảng gốc phân vùng %I.%I_root.', p_schema, p_table);

    -- Tạo các bảng con phân vùng (nếu chưa có)
    FOREACH v_region IN ARRAY v_regions LOOP
        v_partition_name := p_table || '_' || lower(unaccent(replace(v_region, ' ', '_'))); -- Chuẩn hóa tên partition
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I
            PARTITION OF %I.%I_root
            FOR VALUES IN (%L);
        ', p_schema, v_partition_name, p_schema, p_table || '_root', v_region);
        EXECUTE v_sql;
        \echo format('      Đã tạo/xác nhận partition %I.%I cho miền %s.', p_schema, v_partition_name, v_region);
    END LOOP;

    -- Di chuyển dữ liệu và đổi tên (chỉ thực hiện nếu bảng gốc chưa phải là bảng đã phân vùng)
    -- Kiểm tra đơn giản bằng cách xem nó có phải là parent partition không
    PERFORM 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_partitioned_table p ON c.oid = p.partrelid
    WHERE c.relnamespace = (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = p_schema)
      AND c.relname = p_table;

    IF NOT FOUND THEN
        \echo format('      Bảng %I.%I chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', p_schema, p_table);
        BEGIN
            EXECUTE format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE;', p_schema, p_table);

            -- Di chuyển dữ liệu
            EXECUTE format('INSERT INTO %I.%I_root SELECT * FROM %I.%I;', p_schema, p_table, p_schema, p_table);
            \echo format('      Đã di chuyển dữ liệu từ %I.%I sang %I.%I_root.', p_schema, p_table, p_schema, p_table);

            -- Đổi tên (cần cẩn thận với dependencies)
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I_old;', p_schema, p_table, p_table);
            EXECUTE format('ALTER TABLE %I.%I_root RENAME TO %I;', p_schema, p_table || '_root', p_table);
            \echo format('      Đã đổi tên %I.%I -> %I_old và %I.%I_root -> %I.%I.', p_schema, p_table, p_table, p_schema, p_table, p_schema, p_table);

             -- Ghi log vào bảng partitioning.history (nếu bảng tồn tại)
            BEGIN
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, p_table, 'REPARTITIONED', 'Đã di chuyển dữ liệu và đổi tên thành bảng phân vùng theo miền.');
            EXCEPTION WHEN undefined_table THEN
                -- Bỏ qua nếu bảng history chưa được tạo
            END;

        EXCEPTION WHEN OTHERS THEN
            \echo format('      Lỗi khi di chuyển/đổi tên cho %I.%I: %s. Có thể cần thực hiện thủ công.', p_schema, p_table, SQLERRM);
            RETURN FALSE; -- Hoặc rollback transaction nếu chạy trong transaction lớn hơn
        END;
    ELSE
        \echo format('      Bảng %I.%I đã được phân vùng.', p_schema, p_table);
    END IF;

    -- Ghi log cấu hình vào bảng partitioning.config (nếu bảng tồn tại)
     BEGIN
        INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column, is_active)
        VALUES (p_table, p_schema, 'REGION', p_column, TRUE)
        ON CONFLICT (table_name) DO UPDATE SET
            schema_name = EXCLUDED.schema_name,
            partition_type = EXCLUDED.partition_type,
            partition_column = EXCLUDED.partition_column,
            is_active = TRUE,
            updated_at = CURRENT_TIMESTAMP;
    EXCEPTION WHEN undefined_table THEN
         -- Bỏ qua nếu bảng config chưa được tạo
    END;

    \echo format('    - Hoàn thành setup_region_partitioning cho %I.%I.', p_schema, p_table);
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function khởi tạo phân vùng phức tạp theo miền → tỉnh → quận/huyện (phân vùng lồng nhau)
CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT,
    p_table TEXT,
    p_region_column TEXT,
    p_province_column TEXT,
    p_district_column TEXT,
    p_include_district BOOLEAN DEFAULT TRUE -- Mặc định bao gồm cấp huyện
) RETURNS BOOLEAN AS $$
DECLARE
    v_regions RECORD;
    v_provinces RECORD;
    v_districts RECORD;
    v_sql TEXT;
    v_partition_name_l1 TEXT; -- region level
    v_partition_name_l2 TEXT; -- province level
    v_partition_name_l3 TEXT; -- district level
    v_region_code TEXT;
    v_province_code TEXT;
    v_district_code TEXT;
    v_old_table_exists BOOLEAN;
    v_ddl TEXT;
    v_root_table_name TEXT := p_table || '_root';
BEGIN
    \echo format('    - Bắt đầu setup_nested_partitioning cho %I.%I (Include District: %s)...', p_schema, p_table, p_include_district);

    -- Kiểm tra bảng gốc
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = p_schema AND table_name = p_table
    ) INTO v_old_table_exists;

    IF NOT v_old_table_exists THEN
        \echo format('      Lỗi: Bảng %I.%I không tồn tại.', p_schema, p_table);
        RETURN FALSE;
    END IF;

    -- Lấy DDL bảng gốc
    v_ddl := partitioning.pg_get_tabledef(p_schema || '.' || p_table);

    -- 1. Tạo bảng gốc phân vùng (nếu chưa có)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.%I %s
        PARTITION BY LIST (%I);
    ', p_schema, v_root_table_name, v_ddl, p_region_column);
     \echo format('      Đã tạo/xác nhận bảng gốc phân vùng %I.%I.', p_schema, v_root_table_name);

    -- 2. Lặp qua từng miền để tạo phân vùng cấp 1 (nếu chưa có)
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions LOOP
        v_region_code := lower(unaccent(replace(v_regions.region_code, ' ', '_')));
        v_partition_name_l1 := p_table || '_' || v_region_code;

        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.%I
            PARTITION OF %I.%I
            FOR VALUES IN (%L)
            PARTITION BY LIST (%I);
        ', p_schema, v_partition_name_l1,
           p_schema, v_root_table_name,
           v_regions.region_name, -- Giá trị cho LIST partitioning cấp 1
           p_province_column); -- Khóa phân vùng cho cấp 2
        \echo format('      Đã tạo/xác nhận partition cấp 1: %I.%I cho miền %s', p_schema, v_partition_name_l1, v_regions.region_name);

        -- 3. Lặp qua từng tỉnh trong miền để tạo phân vùng cấp 2 (nếu chưa có)
        FOR v_provinces IN SELECT province_id, province_code, province_name
                           FROM reference.provinces WHERE region_id = v_regions.region_id LOOP
            v_province_code := lower(unaccent(replace(v_provinces.province_code, ' ', '_')));
            v_partition_name_l2 := v_partition_name_l1 || '_' || v_province_code;

            IF p_include_district THEN
                 -- Tạo phân vùng cấp 2 (tỉnh) và khai báo nó phân vùng tiếp theo cấp 3 (huyện)
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L)
                    PARTITION BY LIST (%I);
                ', p_schema, v_partition_name_l2,
                   p_schema, v_partition_name_l1,
                   v_provinces.province_id, -- Giá trị cho LIST partitioning cấp 2
                   p_district_column); -- Khóa phân vùng cho cấp 3
                \echo format('        Đã tạo/xác nhận partition cấp 2: %I.%I cho tỉnh %s (sẽ phân vùng tiếp theo huyện)', p_schema, v_partition_name_l2, v_provinces.province_name);

                -- 4. Lặp qua từng quận/huyện trong tỉnh để tạo phân vùng cấp 3 (nếu chưa có)
                FOR v_districts IN SELECT district_id, district_code, district_name
                                   FROM reference.districts WHERE province_id = v_provinces.province_id LOOP
                    v_district_code := lower(unaccent(replace(v_districts.district_code, ' ', '_')));
                    v_partition_name_l3 := v_partition_name_l2 || '_' || v_district_code;

                    EXECUTE format('
                        CREATE TABLE IF NOT EXISTS %I.%I
                        PARTITION OF %I.%I
                        FOR VALUES IN (%L);
                    ', p_schema, v_partition_name_l3,
                       p_schema, v_partition_name_l2,
                       v_districts.district_id); -- Giá trị cho LIST partitioning cấp 3
                     \echo format('          Đã tạo/xác nhận partition cấp 3: %I.%I cho huyện %s', p_schema, v_partition_name_l3, v_districts.district_name);

                END LOOP; -- Hết vòng lặp huyện
            ELSE
                -- Nếu không bao gồm cấp huyện, tạo phân vùng tỉnh là cấp cuối cùng
                 EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L);
                ', p_schema, v_partition_name_l2,
                   p_schema, v_partition_name_l1,
                   v_provinces.province_id);
                \echo format('        Đã tạo/xác nhận partition cấp 2 (cuối cùng): %I.%I cho tỉnh %s', p_schema, v_partition_name_l2, v_provinces.province_name);
            END IF;
        END LOOP; -- Hết vòng lặp tỉnh
    END LOOP; -- Hết vòng lặp miền

    -- 5. Di chuyển dữ liệu và đổi tên (tương tự như setup_region_partitioning)
    PERFORM 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_partitioned_table p ON c.oid = p.partrelid
    WHERE c.relnamespace = (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = p_schema)
      AND c.relname = p_table;

    IF NOT FOUND THEN
         \echo format('      Bảng %I.%I chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', p_schema, p_table);
        BEGIN
            EXECUTE format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE;', p_schema, p_table);
            EXECUTE format('INSERT INTO %I.%I SELECT * FROM %I.%I;', p_schema, v_root_table_name, p_schema, p_table);
             \echo format('      Đã di chuyển dữ liệu từ %I.%I sang %I.%I.', p_schema, p_table, p_schema, v_root_table_name);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I_old;', p_schema, p_table, p_table);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, v_root_table_name, p_table);
             \echo format('      Đã đổi tên %I.%I -> %I_old và %I.%I -> %I.%I.', p_schema, p_table, p_table, p_schema, v_root_table_name, p_schema, p_table);

            -- Ghi log history
            BEGIN
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, p_table, 'REPARTITIONED', 'Đã di chuyển dữ liệu và đổi tên thành bảng phân vùng đa cấp.');
            EXCEPTION WHEN undefined_table THEN
                 -- Bỏ qua
            END;
        EXCEPTION WHEN OTHERS THEN
            \echo format('      Lỗi khi di chuyển/đổi tên cho %I.%I: %s. Có thể cần thực hiện thủ công.', p_schema, p_table, SQLERRM);
            RETURN FALSE;
        END;
    ELSE
        \echo format('      Bảng %I.%I đã được phân vùng.', p_schema, p_table);
    END IF;

    -- 6. Ghi log cấu hình
    BEGIN
        INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column, is_active)
        VALUES (p_table, p_schema, 'NESTED',
            CASE WHEN p_include_district
                THEN p_region_column || ',' || p_province_column || ',' || p_district_column
                ELSE p_region_column || ',' || p_province_column
            END, TRUE)
        ON CONFLICT (table_name) DO UPDATE SET
            schema_name = EXCLUDED.schema_name,
            partition_type = EXCLUDED.partition_type,
            partition_column = EXCLUDED.partition_column,
            is_active = TRUE,
            updated_at = CURRENT_TIMESTAMP;
     EXCEPTION WHEN undefined_table THEN
         -- Bỏ qua
     END;

    \echo format('    - Hoàn thành setup_nested_partitioning cho %I.%I.', p_schema, p_table);
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function khởi tạo phân vùng theo tỉnh/thành phố (cho các bảng đơn giản hơn)
CREATE OR REPLACE FUNCTION partitioning.setup_province_partitioning(
    p_schema TEXT,
    p_table TEXT,
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_provinces RECORD;
    v_partition_name TEXT;
    v_old_table_exists BOOLEAN;
    v_ddl TEXT;
    v_root_table_name TEXT := p_table || '_root';
BEGIN
     \echo format('    - Bắt đầu setup_province_partitioning cho %I.%I...', p_schema, p_table);

    -- Kiểm tra bảng gốc
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = p_schema AND table_name = p_table
    ) INTO v_old_table_exists;

    IF NOT v_old_table_exists THEN
        \echo format('      Lỗi: Bảng %I.%I không tồn tại.', p_schema, p_table);
        RETURN FALSE;
    END IF;

    -- Lấy DDL
     v_ddl := partitioning.pg_get_tabledef(p_schema || '.' || p_table);

    -- Tạo bảng gốc phân vùng
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.%I %s
        PARTITION BY LIST (%I);
    ', p_schema, v_root_table_name, v_ddl, p_column);
    \echo format('      Đã tạo/xác nhận bảng gốc phân vùng %I.%I.', p_schema, v_root_table_name);

    -- Tạo các phân vùng cho từng tỉnh/thành phố
    FOR v_provinces IN SELECT province_id, province_code, province_name FROM reference.provinces LOOP
        v_partition_name := p_table || '_' || lower(unaccent(replace(v_provinces.province_code, ' ', '_')));
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I
            PARTITION OF %I.%I
            FOR VALUES IN (%L);
        ', p_schema, v_partition_name, p_schema, v_root_table_name, v_provinces.province_id);
        EXECUTE v_sql;
         \echo format('        Đã tạo/xác nhận partition %I.%I cho tỉnh %s.', p_schema, v_partition_name, v_provinces.province_name);
    END LOOP;

    -- Di chuyển dữ liệu và đổi tên
    PERFORM 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_partitioned_table p ON c.oid = p.partrelid
    WHERE c.relnamespace = (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = p_schema)
      AND c.relname = p_table;

    IF NOT FOUND THEN
         \echo format('      Bảng %I.%I chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', p_schema, p_table);
        BEGIN
            EXECUTE format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE;', p_schema, p_table);
            EXECUTE format('INSERT INTO %I.%I SELECT * FROM %I.%I;', p_schema, v_root_table_name, p_schema, p_table);
             \echo format('      Đã di chuyển dữ liệu từ %I.%I sang %I.%I.', p_schema, p_table, p_schema, v_root_table_name);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I_old;', p_schema, p_table, p_table);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, v_root_table_name, p_table);
            \echo format('      Đã đổi tên %I.%I -> %I_old và %I.%I -> %I.%I.', p_schema, p_table, p_table, p_schema, v_root_table_name, p_schema, p_table);

            -- Ghi log history
            BEGIN
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, p_table, 'REPARTITIONED', 'Đã di chuyển dữ liệu và đổi tên thành bảng phân vùng theo tỉnh.');
             EXCEPTION WHEN undefined_table THEN
                 -- Bỏ qua
             END;
        EXCEPTION WHEN OTHERS THEN
             \echo format('      Lỗi khi di chuyển/đổi tên cho %I.%I: %s. Có thể cần thực hiện thủ công.', p_schema, p_table, SQLERRM);
             RETURN FALSE;
        END;
    ELSE
         \echo format('      Bảng %I.%I đã được phân vùng.', p_schema, p_table);
    END IF;

    -- Ghi log cấu hình
    BEGIN
        INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column, is_active)
        VALUES (p_table, p_schema, 'PROVINCE', p_column, TRUE)
        ON CONFLICT (table_name) DO UPDATE SET
            schema_name = EXCLUDED.schema_name,
            partition_type = EXCLUDED.partition_type,
            partition_column = EXCLUDED.partition_column,
            is_active = TRUE,
            updated_at = CURRENT_TIMESTAMP;
    EXCEPTION WHEN undefined_table THEN
        -- Bỏ qua
    END;

    \echo format('    - Hoàn thành setup_province_partitioning cho %I.%I.', p_schema, p_table);
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function di chuyển dữ liệu giữa các phân vùng (khi công dân thay đổi địa chỉ)
-- Lưu ý: Function này giả định cấu trúc phân vùng đa cấp và cần được kiểm tra kỹ lưỡng
-- về hiệu năng và tính đúng đắn trong môi trường thực tế.
CREATE OR REPLACE FUNCTION partitioning.move_data_between_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_citizen_id TEXT, -- Hoặc một khóa định danh khác của bản ghi cần di chuyển
    p_key_column TEXT, -- Tên cột chứa khóa định danh (ví dụ: 'citizen_id')
    p_new_region TEXT,
    p_new_province INTEGER,
    p_new_district INTEGER DEFAULT NULL -- Cần thiết nếu bảng phân vùng đến cấp huyện
) RETURNS BOOLEAN AS $$
DECLARE
    v_record RECORD;
    v_rows_affected INTEGER := 0;
    v_new_region_id SMALLINT;
BEGIN
    -- Lấy region_id mới
    SELECT region_id INTO v_new_region_id
    FROM reference.provinces WHERE province_id = p_new_province;

    IF v_new_region_id IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy region_id cho province_id: %', p_new_province;
        RETURN FALSE;
    END IF;

    -- Lấy bản ghi cần di chuyển
    EXECUTE format('SELECT * FROM %I.%I WHERE %I = %L LIMIT 1',
                   p_schema, p_table, p_key_column, p_citizen_id)
    INTO v_record;

    IF v_record IS NULL THEN
        RAISE NOTICE 'Không tìm thấy bản ghi với % = % trong bảng %I.%I', p_key_column, p_citizen_id, p_schema, p_table;
        RETURN FALSE;
    END IF;

    -- Xóa bản ghi khỏi vị trí cũ
    EXECUTE format('DELETE FROM %I.%I WHERE %I = %L',
                   p_schema, p_table, p_key_column, p_citizen_id);
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF v_rows_affected = 1 THEN
        -- Cập nhật các cột phân vùng trong bản ghi đã lấy
        -- Lưu ý: Cần đảm bảo tên cột phân vùng chính xác và tồn tại trong bản ghi `v_record`
        -- Cách tiếp cận an toàn hơn là xây dựng câu lệnh INSERT với các giá trị mới
        -- thay vì dựa vào cấu trúc động của `v_record`.
        -- Ví dụ đơn giản hóa (cần điều chỉnh cho cấu trúc bảng cụ thể):
        DECLARE
            v_insert_sql TEXT;
            v_cols TEXT;
            v_vals TEXT;
            v_col_name TEXT;
            v_col_value TEXT;
        BEGIN
            SELECT string_agg(quote_ident(key), ', '), string_agg(quote_nullable(value), ', ')
            INTO v_cols, v_vals
            FROM json_each_text(row_to_json(v_record)) AS t(key, value);

            -- Cập nhật giá trị cột phân vùng mới
            v_cols := v_cols || ', geographical_region, province_id, region_id' || CASE WHEN p_new_district IS NOT NULL THEN ', district_id' ELSE '' END;
            v_vals := v_vals || format(', %L, %L, %L', p_new_region, p_new_province, v_new_region_id) || CASE WHEN p_new_district IS NOT NULL THEN format(', %L', p_new_district) ELSE '' END;

            -- Cập nhật lại các giá trị cột phân vùng cũ nếu chúng bị trùng tên
             v_insert_sql := format('INSERT INTO %I.%I (%s) VALUES (%s)', p_schema, p_table, v_cols, v_vals);
            -- Đây là cách tiếp cận đơn giản, có thể cần tinh chỉnh để xử lý kiểu dữ liệu và tên cột chính xác hơn

             RAISE NOTICE 'Executing insert: %', v_insert_sql; -- Để debug
             -- Thay thế câu lệnh cập nhật v_record bằng câu lệnh INSERT đã xây dựng
             -- EXECUTE v_insert_sql; -- Cần kiểm tra và hoàn thiện câu lệnh này

            -- Tạm thời dùng cách gán trực tiếp (kém an toàn hơn nếu tên cột động)
             -- Giả sử bảng có các cột này
             -- v_record.geographical_region := p_new_region;
             -- v_record.province_id := p_new_province;
             -- v_record.region_id := v_new_region_id;
             -- IF p_new_district IS NOT NULL THEN
             --     v_record.district_id := p_new_district;
             -- END IF;
             -- Chèn lại bản ghi vào bảng cha (PostgreSQL sẽ tự định tuyến đến partition đúng)
             -- EXECUTE format('INSERT INTO %I.%I VALUES (%L::%I.%I)', p_schema, p_table, v_record, p_schema, p_table);

             RAISE EXCEPTION 'Phần INSERT dữ liệu đã cập nhật cần được hoàn thiện và kiểm tra kỹ lưỡng'; -- Đánh dấu cần hoàn thiện

        END;

        -- Ghi log di chuyển
        BEGIN
             INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
             VALUES (p_table, p_schema, p_key_column || '=' || p_citizen_id, 'MOVE', format('Đã di chuyển đến phân vùng mới (%s, %s, %s)', p_new_region, p_new_province, COALESCE(p_new_district::text, 'N/A')));
        EXCEPTION WHEN undefined_table THEN
             -- Bỏ qua
        END;
        RETURN TRUE;
    ELSE
        RAISE WARNING 'Không thể xóa bản ghi gốc với % = % trong bảng %I.%I để di chuyển.', p_key_column, p_citizen_id, p_schema, p_table;
        RETURN FALSE;
    END IF;

EXCEPTION WHEN OTHERS THEN
     \echo format('      Lỗi khi di chuyển dữ liệu cho %I.%I, key %s=%s: %s', p_schema, p_table, p_key_column, p_citizen_id, SQLERRM);
     RETURN FALSE; -- Hoặc rollback transaction
END;
$$ LANGUAGE plpgsql;

-- Function tạo báo cáo về phân vùng dữ liệu
CREATE OR REPLACE FUNCTION partitioning.generate_partition_report() RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    partition_name TEXT,
    row_count BIGINT,
    total_size_bytes BIGINT,
    total_size_pretty TEXT,
    last_analyzed TIMESTAMP WITH TIME ZONE,
    region TEXT,
    province TEXT,
    district TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH partition_info AS (
        SELECT
            inh.inhparent::regclass::text AS parent_table_fq,
            c.relname AS partition_name,
            pg_catalog.pg_get_expr(c.relpartbound, c.oid) AS partition_expression,
            nsp.nspname AS schema_name,
            pc.relname AS table_name -- Tên bảng cha
        FROM pg_catalog.pg_inherits inh
        JOIN pg_catalog.pg_class c ON inh.inhrelid = c.oid
        JOIN pg_catalog.pg_namespace nsp ON c.relnamespace = nsp.oid
        JOIN pg_catalog.pg_class pc ON inh.inhparent = pc.oid
        WHERE c.relkind = 'r' -- Chỉ lấy bảng (relation)
          AND nsp.nspname NOT IN ('pg_catalog', 'information_schema')
    ),
    partition_stats AS (
        SELECT
            pi.schema_name,
            pi.table_name, -- Lấy tên bảng cha từ partition_info
            pi.partition_name,
            stat.n_live_tup + stat.n_dead_tup AS estimated_rows, -- Ước tính row count
            pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name) AS total_size_bytes,
            pg_catalog.pg_size_pretty(pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name)) AS total_size_pretty,
            stat.last_analyze AS last_analyzed,
            -- Trích xuất thông tin địa lý từ tên partition (giả định theo quy ước đặt tên)
            CASE
                WHEN pi.partition_name ~ pconf.table_name || '_bac' THEN 'Bắc'
                WHEN pi.partition_name ~ pconf.table_name || '_trung' THEN 'Trung'
                WHEN pi.partition_name ~ pconf.table_name || '_nam' THEN 'Nam'
                ELSE NULL
            END AS derived_region,
            CASE
                WHEN pi.partition_name ~ pconf.table_name || '_(bac|trung|nam)_([a-z0-9_]+)' THEN
                     substring(pi.partition_name from pconf.table_name || '_(?:bac|trung|nam)_([a-z0-9_]+)')
                ELSE NULL
            END AS derived_province_code,
             CASE
                 WHEN pi.partition_name ~ pconf.table_name || '_(bac|trung|nam)_[a-z0-9_]+_([a-z0-9_]+)' THEN
                      substring(pi.partition_name from pconf.table_name || '_(?:bac|trung|nam)_[a-z0-9_]+_([a-z0-9_]+)')
                 ELSE NULL
             END AS derived_district_code
        FROM partition_info pi
        LEFT JOIN pg_catalog.pg_stat_all_tables stat ON stat.schemaname = pi.schema_name AND stat.relname = pi.partition_name
        LEFT JOIN partitioning.config pconf ON pconf.schema_name = pi.schema_name AND pconf.table_name = pi.table_name -- Join với config
        WHERE pconf.is_active = TRUE -- Chỉ lấy các bảng đang active partition
    )
    SELECT
        ps.schema_name::TEXT,
        ps.table_name::TEXT,
        ps.partition_name::TEXT,
        ps.estimated_rows::BIGINT,
        ps.total_size_bytes::BIGINT,
        ps.total_size_pretty::TEXT,
        ps.last_analyzed::TIMESTAMP WITH TIME ZONE,
        ps.derived_region::TEXT,
        prov.province_name::TEXT,
        dist.district_name::TEXT
    FROM partition_stats ps
    LEFT JOIN reference.provinces prov ON lower(prov.province_code) = ps.derived_province_code
    LEFT JOIN reference.districts dist ON lower(dist.district_code) = ps.derived_district_code
    ORDER BY ps.schema_name, ps.table_name, ps.partition_name;

EXCEPTION WHEN undefined_table THEN
     RAISE NOTICE 'Bảng partitioning.config hoặc reference tables chưa tồn tại, báo cáo có thể không đầy đủ.';
     RETURN QUERY SELECT NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::BIGINT, NULL::BIGINT, NULL::TEXT, NULL::TIMESTAMP WITH TIME ZONE, NULL::TEXT, NULL::TEXT, NULL::TEXT WHERE FALSE;

END;
$$ LANGUAGE plpgsql;

-- Function xác định phân vùng cho công dân dựa trên địa chỉ
-- Cần đảm bảo các bảng permanent_residence, temporary_residence, address tồn tại và có dữ liệu
CREATE OR REPLACE FUNCTION partitioning.determine_partition_for_citizen(
    p_citizen_id TEXT
) RETURNS TABLE (
    geographical_region TEXT,
    province_id INTEGER,
    district_id INTEGER
) AS $$
DECLARE
    v_address_id INTEGER;
    v_province_id INTEGER;
    v_district_id INTEGER;
    v_region_id SMALLINT;
BEGIN
    -- Tìm địa chỉ thường trú mới nhất
    SELECT pr.address_id INTO v_address_id
    FROM public_security.permanent_residence pr
    WHERE pr.citizen_id = p_citizen_id AND pr.status = TRUE
    ORDER BY pr.registration_date DESC, pr.permanent_residence_id DESC -- Thêm PK để đảm bảo duy nhất
    LIMIT 1;

    -- Nếu không có, tìm địa chỉ tạm trú mới nhất
    IF v_address_id IS NULL THEN
        SELECT tr.address_id INTO v_address_id
        FROM public_security.temporary_residence tr
        WHERE tr.citizen_id = p_citizen_id AND tr.status = 'Active' -- Giả sử status 'Active'
        ORDER BY tr.registration_date DESC, tr.temporary_residence_id DESC
        LIMIT 1;
    END IF;

    -- Nếu có địa chỉ, lấy thông tin tỉnh/huyện và vùng
    IF v_address_id IS NOT NULL THEN
        SELECT a.province_id, a.district_id, p.region_id
        INTO v_province_id, v_district_id, v_region_id
        FROM public_security.address a
        JOIN reference.provinces p ON a.province_id = p.province_id
        WHERE a.address_id = v_address_id;

        IF FOUND THEN -- Đảm bảo join thành công
            RETURN QUERY
            SELECT
                CASE
                    WHEN v_region_id = 1 THEN 'Bắc'::TEXT
                    WHEN v_region_id = 2 THEN 'Trung'::TEXT
                    WHEN v_region_id = 3 THEN 'Nam'::TEXT
                    ELSE NULL::TEXT -- Trường hợp không xác định
                END AS geographical_region,
                v_province_id,
                v_district_id;
            RETURN; -- Kết thúc nếu tìm thấy
        END IF;
    END IF;

    -- Trả về giá trị mặc định hoặc NULL nếu không tìm thấy thông tin
    RAISE NOTICE 'Không thể xác định phân vùng cho citizen_id: %. Trả về NULL.', p_citizen_id;
    RETURN QUERY SELECT NULL::TEXT, NULL::INTEGER, NULL::INTEGER WHERE FALSE;

END;
$$ LANGUAGE plpgsql;


-- Function lưu trữ các partition cũ (chưa hoàn thiện, cần logic xác định partition theo thời gian)
CREATE OR REPLACE FUNCTION partitioning.archive_old_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_retention_period INTERVAL -- Ví dụ: INTERVAL '5 years'
) RETURNS VOID AS $$
DECLARE
    v_partition_name TEXT;
    v_cutoff_timestamp TIMESTAMP WITH TIME ZONE;
    v_detach_sql TEXT;
    v_archive_table_name TEXT;
BEGIN
    v_cutoff_timestamp := CURRENT_TIMESTAMP - p_retention_period;
     \echo format('    - Bắt đầu archive_old_partitions cho %I.%I, giữ lại dữ liệu trong vòng %s.', p_schema, p_table, p_retention_period);

    -- Logic này cần được điều chỉnh dựa trên CÁCH bạn đặt tên partition theo thời gian
    -- Ví dụ: Nếu partition theo tháng dạng table_YYYYMM
    -- Cần vòng lặp qua các partition và kiểm tra xem giới hạn trên (upper bound) của nó có nhỏ hơn v_cutoff_timestamp không

    RAISE NOTICE 'Logic xác định và tách các partition theo thời gian cần được triển khai cụ thể dựa trên cấu trúc phân vùng RANGE/LIST theo thời gian.';

    -- Ví dụ giả định cho phân vùng RANGE theo ngày (cột 'created_at')
    -- FOR v_partition_name IN
    --     SELECT child.relname
    --     FROM pg_inherits i
    --     JOIN pg_class child ON i.inhrelid = child.oid
    --     JOIN pg_namespace nsp ON child.relnamespace = nsp.oid
    --     JOIN pg_class parent ON i.inhparent = parent.oid
    --     WHERE parent.relname = p_table AND nsp.nspname = p_schema
    --     -- Giả sử partition boundary được lưu trong description hoặc lấy từ định nghĩa constraint
    --     -- AND parse_partition_upper_bound(pg_get_constraintdef(con.oid)) < v_cutoff_timestamp
    -- LOOP
    --     v_archive_table_name := p_schema || '.' || v_partition_name || '_archived';
    --     v_detach_sql := format('ALTER TABLE %I.%I DETACH PARTITION %I.%I;',
    --                             p_schema, p_table, p_schema, v_partition_name);
    --     RAISE NOTICE 'Detaching partition: %', v_detach_sql;
    --     -- EXECUTE v_detach_sql;
    --     -- EXECUTE format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, v_partition_name, v_archive_table_name);
    --     -- Log vào partitioning.history
    -- END LOOP;

     \echo format('    - Hoàn thành (logic chưa đầy đủ) archive_old_partitions cho %I.%I.', p_schema, p_table);
END;
$$ LANGUAGE plpgsql;


-- Function tạo index trên các partition (nếu chưa tồn tại)
-- Cần chạy sau khi các partition đã được tạo
CREATE OR REPLACE FUNCTION partitioning.create_partition_indexes(
    p_schema TEXT,
    p_table TEXT,
    p_index_definitions TEXT[] -- Mảng chứa định nghĩa CREATE INDEX đầy đủ, ví dụ: ARRAY['CREATE INDEX idx_col1 ON %1$I.%2$I (col1)', 'CREATE UNIQUE INDEX uq_col2 ON %1$I.%2$I (col2)']
                                -- %1$I là schema, %2$I là tên partition
) RETURNS VOID AS $$
DECLARE
    v_partition_name TEXT;
    v_index_def TEXT;
    v_index_name TEXT;
    v_sql TEXT;
BEGIN
     \echo format('    - Bắt đầu create_partition_indexes cho %I.%I...', p_schema, p_table);
    -- Lặp qua tất cả các partition con hiện có của bảng cha
    FOR v_partition_name IN
        SELECT c.relname
        FROM pg_catalog.pg_inherits i
        JOIN pg_catalog.pg_class c ON i.inhrelid = c.oid
        JOIN pg_catalog.pg_namespace nsp ON c.relnamespace = nsp.oid
        JOIN pg_catalog.pg_class parent ON i.inhparent = parent.oid
        WHERE parent.relname = p_table AND nsp.nspname = p_schema AND c.relkind = 'r'
    LOOP
         \echo format('      - Xử lý partition: %I.%I', p_schema, v_partition_name);
        -- Lặp qua các định nghĩa index cần tạo
        FOREACH v_index_def IN ARRAY p_index_definitions
        LOOP
            -- Trích xuất tên index dự kiến từ định nghĩa (cần chuẩn hóa cách đặt tên)
            -- Giả sử tên index nằm sau 'CREATE INDEX' hoặc 'CREATE UNIQUE INDEX'
             SELECT (regexp_matches(v_index_def, 'CREATE(?: UNIQUE)? INDEX\s+(\S+)\s+ON', 'i'))[1] INTO v_index_name;

             IF v_index_name IS NULL THEN
                 RAISE WARNING 'Không thể trích xuất tên index từ định nghĩa: %', v_index_def;
                 CONTINUE;
             END IF;

            -- Kiểm tra xem index đã tồn tại trên partition này chưa
            PERFORM 1
            FROM pg_catalog.pg_indexes
            WHERE schemaname = p_schema
              AND tablename = v_partition_name
              AND indexname = v_index_name;

            -- Nếu index chưa tồn tại, tạo nó
            IF NOT FOUND THEN
                -- Thay thế placeholder bằng schema và tên partition
                v_sql := format(v_index_def, p_schema, v_partition_name);
                RAISE NOTICE 'Tạo index: %', v_sql;
                EXECUTE v_sql;

                -- Ghi log (nếu cần)
                BEGIN
                    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                    VALUES (p_table, p_schema, v_partition_name, 'CREATE_INDEX', 'Đã tạo index: ' || v_index_name);
                EXCEPTION WHEN undefined_table THEN
                    -- Bỏ qua
                END;
            ELSE
                 RAISE NOTICE 'Index % đã tồn tại trên %I.%I.', v_index_name, p_schema, v_partition_name;
            END IF;
        END LOOP; -- Hết vòng lặp định nghĩa index
    END LOOP; -- Hết vòng lặp partition
     \echo format('    - Hoàn thành create_partition_indexes cho %I.%I.', p_schema, p_table);
END;
$$ LANGUAGE plpgsql;


-- Các function gọi tuần tự việc setup partitioning cho từng nhóm bảng
CREATE OR REPLACE FUNCTION partitioning.setup_citizen_tables_partitioning() RETURNS VOID AS $$
BEGIN
    \echo '  -- Bắt đầu phân vùng các bảng citizen (BCA)...';
    -- Phân vùng bảng citizen theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'citizen',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng identification_card theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'identification_card',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
    -- Phân vùng bảng citizen_status theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'citizen_status',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
    -- Phân vùng bảng criminal_record theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'criminal_record',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
     \echo '  -- Kết thúc phân vùng các bảng citizen (BCA).';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION partitioning.setup_residence_tables_partitioning() RETURNS VOID AS $$
BEGIN
     \echo '  -- Bắt đầu phân vùng các bảng residence (BCA)...';
    -- Phân vùng bảng address theo 3 cấp (miền -> tỉnh -> quận/huyện)
     PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'address',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng citizen_address theo 3 cấp (miền -> tỉnh -> quận/huyện)
     PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'citizen_address',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng permanent_residence theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'permanent_residence',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng temporary_residence theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'temporary_residence',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng temporary_absence theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'temporary_absence',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
    -- Phân vùng bảng citizen_movement theo 2 cấp (miền -> tỉnh)
     PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'citizen_movement',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
     \echo '  -- Kết thúc phân vùng các bảng residence (BCA).';
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- II. FUNCTIONS CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\connect ministry_of_justice
\echo '-> Định nghĩa functions phân vùng cho ministry_of_justice...'

-- Tạo lại các function helper cần thiết (nếu chưa có hoặc cần định nghĩa riêng)
CREATE OR REPLACE FUNCTION partitioning.pg_get_tabledef(p_table_name TEXT) RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_list TEXT;
BEGIN
    -- Trích xuất danh sách cột và kiểu dữ liệu cơ bản, ràng buộc NOT NULL
    -- Lưu ý: Hàm này đơn giản hóa, không lấy FK, CHECK, default values...
    -- Chỉ đủ dùng cho việc tạo bảng LIKE trong ngữ cảnh phân vùng này.
    SELECT string_agg(
        quote_ident(column_name) || ' ' ||
        CASE
            WHEN udt_name IN ('varchar', 'bpchar') AND character_maximum_length IS NOT NULL THEN data_type || '(' || character_maximum_length || ')'
            WHEN udt_name IN ('numeric', 'decimal') AND numeric_precision IS NOT NULL AND numeric_scale IS NOT NULL THEN data_type || '(' || numeric_precision || ',' || numeric_scale || ')'
            WHEN udt_name IN ('numeric', 'decimal') AND numeric_precision IS NOT NULL THEN data_type || '(' || numeric_precision || ')'
            ELSE data_type
        END ||
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END,
        E',\n    ' ORDER BY ordinal_position
    )
    INTO v_column_list
    FROM information_schema.columns
    WHERE table_schema = split_part(p_table_name, '.', 1)
      AND table_name = split_part(p_table_name, '.', 2);

    -- Tạo câu lệnh DDL cơ bản
    v_table_ddl := E'(\n    ' || v_column_list || E'\n)';

    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT,
    p_table TEXT,
    p_region_column TEXT,
    p_province_column TEXT,
    p_district_column TEXT,
    p_include_district BOOLEAN DEFAULT TRUE
) RETURNS BOOLEAN AS $$
DECLARE
    v_regions RECORD;
    v_provinces RECORD;
    v_districts RECORD;
    v_sql TEXT;
    v_partition_name_l1 TEXT; -- region level
    v_partition_name_l2 TEXT; -- province level
    v_partition_name_l3 TEXT; -- district level
    v_region_code TEXT;
    v_province_code TEXT;
    v_district_code TEXT;
    v_old_table_exists BOOLEAN;
    v_ddl TEXT;
    v_root_table_name TEXT := p_table || '_root';
BEGIN
    \echo format('    - Bắt đầu setup_nested_partitioning cho %I.%I (Include District: %s)...', p_schema, p_table, p_include_district);

    -- Kiểm tra bảng gốc
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = p_schema AND table_name = p_table
    ) INTO v_old_table_exists;

    IF NOT v_old_table_exists THEN
        \echo format('      Lỗi: Bảng %I.%I không tồn tại.', p_schema, p_table);
        RETURN FALSE;
    END IF;

    -- Lấy DDL bảng gốc
    v_ddl := partitioning.pg_get_tabledef(p_schema || '.' || p_table);

    -- 1. Tạo bảng gốc phân vùng (nếu chưa có)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.%I %s
        PARTITION BY LIST (%I);
    ', p_schema, v_root_table_name, v_ddl, p_region_column);
     \echo format('      Đã tạo/xác nhận bảng gốc phân vùng %I.%I.', p_schema, v_root_table_name);

    -- 2. Lặp qua từng miền để tạo phân vùng cấp 1 (nếu chưa có)
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions LOOP
        v_region_code := lower(unaccent(replace(v_regions.region_code, ' ', '_')));
        v_partition_name_l1 := p_table || '_' || v_region_code;

        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.%I
            PARTITION OF %I.%I
            FOR VALUES IN (%L)
            PARTITION BY LIST (%I);
        ', p_schema, v_partition_name_l1,
           p_schema, v_root_table_name,
           v_regions.region_name, -- Giá trị cho LIST partitioning cấp 1
           p_province_column); -- Khóa phân vùng cho cấp 2
        \echo format('      Đã tạo/xác nhận partition cấp 1: %I.%I cho miền %s', p_schema, v_partition_name_l1, v_regions.region_name);

        -- 3. Lặp qua từng tỉnh trong miền để tạo phân vùng cấp 2 (nếu chưa có)
        FOR v_provinces IN SELECT province_id, province_code, province_name
                           FROM reference.provinces WHERE region_id = v_regions.region_id LOOP
            v_province_code := lower(unaccent(replace(v_provinces.province_code, ' ', '_')));
            v_partition_name_l2 := v_partition_name_l1 || '_' || v_province_code;

            IF p_include_district THEN
                 -- Tạo phân vùng cấp 2 (tỉnh) và khai báo nó phân vùng tiếp theo cấp 3 (huyện)
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L)
                    PARTITION BY LIST (%I);
                ', p_schema, v_partition_name_l2,
                   p_schema, v_partition_name_l1,
                   v_provinces.province_id, -- Giá trị cho LIST partitioning cấp 2
                   p_district_column); -- Khóa phân vùng cho cấp 3
                \echo format('        Đã tạo/xác nhận partition cấp 2: %I.%I cho tỉnh %s (sẽ phân vùng tiếp theo huyện)', p_schema, v_partition_name_l2, v_provinces.province_name);

                -- 4. Lặp qua từng quận/huyện trong tỉnh để tạo phân vùng cấp 3 (nếu chưa có)
                FOR v_districts IN SELECT district_id, district_code, district_name
                                   FROM reference.districts WHERE province_id = v_provinces.province_id LOOP
                    v_district_code := lower(unaccent(replace(v_districts.district_code, ' ', '_')));
                    v_partition_name_l3 := v_partition_name_l2 || '_' || v_district_code;

                    EXECUTE format('
                        CREATE TABLE IF NOT EXISTS %I.%I
                        PARTITION OF %I.%I
                        FOR VALUES IN (%L);
                    ', p_schema, v_partition_name_l3,
                       p_schema, v_partition_name_l2,
                       v_districts.district_id); -- Giá trị cho LIST partitioning cấp 3
                     \echo format('          Đã tạo/xác nhận partition cấp 3: %I.%I cho huyện %s', p_schema, v_partition_name_l3, v_districts.district_name);

                END LOOP; -- Hết vòng lặp huyện
            ELSE
                -- Nếu không bao gồm cấp huyện, tạo phân vùng tỉnh là cấp cuối cùng
                 EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L);
                ', p_schema, v_partition_name_l2,
                   p_schema, v_partition_name_l1,
                   v_provinces.province_id);
                \echo format('        Đã tạo/xác nhận partition cấp 2 (cuối cùng): %I.%I cho tỉnh %s', p_schema, v_partition_name_l2, v_provinces.province_name);
            END IF;
        END LOOP; -- Hết vòng lặp tỉnh
    END LOOP; -- Hết vòng lặp miền

    -- 5. Di chuyển dữ liệu và đổi tên (tương tự như setup_region_partitioning)
    PERFORM 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_partitioned_table p ON c.oid = p.partrelid
    WHERE c.relnamespace = (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = p_schema)
      AND c.relname = p_table;

    IF NOT FOUND THEN
         \echo format('      Bảng %I.%I chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', p_schema, p_table);
        BEGIN
            EXECUTE format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE;', p_schema, p_table);
            EXECUTE format('INSERT INTO %I.%I SELECT * FROM %I.%I;', p_schema, v_root_table_name, p_schema, p_table);
             \echo format('      Đã di chuyển dữ liệu từ %I.%I sang %I.%I.', p_schema, p_table, p_schema, v_root_table_name);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I_old;', p_schema, p_table, p_table);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, v_root_table_name, p_table);
             \echo format('      Đã đổi tên %I.%I -> %I_old và %I.%I -> %I.%I.', p_schema, p_table, p_table, p_schema, v_root_table_name, p_schema, p_table);

            -- Ghi log history
            BEGIN
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, p_table, 'REPARTITIONED', 'Đã di chuyển dữ liệu và đổi tên thành bảng phân vùng đa cấp.');
            EXCEPTION WHEN undefined_table THEN
                 -- Bỏ qua
            END;
        EXCEPTION WHEN OTHERS THEN
            \echo format('      Lỗi khi di chuyển/đổi tên cho %I.%I: %s. Có thể cần thực hiện thủ công.', p_schema, p_table, SQLERRM);
            RETURN FALSE;
        END;
    ELSE
        \echo format('      Bảng %I.%I đã được phân vùng.', p_schema, p_table);
    END IF;

    -- 6. Ghi log cấu hình
    BEGIN
        INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column, is_active)
        VALUES (p_table, p_schema, 'NESTED',
            CASE WHEN p_include_district
                THEN p_region_column || ',' || p_province_column || ',' || p_district_column
                ELSE p_region_column || ',' || p_province_column
            END, TRUE)
        ON CONFLICT (table_name) DO UPDATE SET
            schema_name = EXCLUDED.schema_name,
            partition_type = EXCLUDED.partition_type,
            partition_column = EXCLUDED.partition_column,
            is_active = TRUE,
            updated_at = CURRENT_TIMESTAMP;
     EXCEPTION WHEN undefined_table THEN
         -- Bỏ qua
     END;

    \echo format('    - Hoàn thành setup_nested_partitioning cho %I.%I.', p_schema, p_table);
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


-- Function setup cho các bảng hộ tịch
CREATE OR REPLACE FUNCTION partitioning.setup_civil_status_tables_partitioning() RETURNS VOID AS $$
BEGIN
    \echo '  -- Bắt đầu phân vùng các bảng civil_status (BTP)...';
    -- Phân vùng bảng birth_certificate theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'birth_certificate',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng death_certificate theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'death_certificate',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng marriage theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'marriage',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng divorce theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'divorce',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
    \echo '  -- Kết thúc phân vùng các bảng civil_status (BTP).';
END;
$$ LANGUAGE plpgsql;

-- Function setup cho các bảng hộ khẩu và gia đình
CREATE OR REPLACE FUNCTION partitioning.setup_household_tables_partitioning() RETURNS VOID AS $$
BEGIN
    \echo '  -- Bắt đầu phân vùng các bảng household (BTP)...';
    -- Phân vùng bảng household theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'household',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng household_member theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'household_member',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
    -- Phân vùng bảng family_relationship theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'family_relationship',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
    -- Phân vùng bảng population_change theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'population_change',
        'geographical_region', 'province_id', 'district_id', FALSE -- Chỉ đến tỉnh
    );
     \echo '  -- Kết thúc phân vùng các bảng household (BTP).';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- III. FUNCTIONS CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\connect national_citizen_central_server
\echo '-> Định nghĩa functions phân vùng cho national_citizen_central_server...'

-- Tạo lại các function helper cần thiết (nếu chưa có hoặc cần định nghĩa riêng)
CREATE OR REPLACE FUNCTION partitioning.pg_get_tabledef(p_table_name TEXT) RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_list TEXT;
BEGIN
    -- Trích xuất danh sách cột và kiểu dữ liệu cơ bản, ràng buộc NOT NULL
    -- Lưu ý: Hàm này đơn giản hóa, không lấy FK, CHECK, default values...
    -- Chỉ đủ dùng cho việc tạo bảng LIKE trong ngữ cảnh phân vùng này.
    SELECT string_agg(
        quote_ident(column_name) || ' ' ||
        CASE
            WHEN udt_name IN ('varchar', 'bpchar') AND character_maximum_length IS NOT NULL THEN data_type || '(' || character_maximum_length || ')'
            WHEN udt_name IN ('numeric', 'decimal') AND numeric_precision IS NOT NULL AND numeric_scale IS NOT NULL THEN data_type || '(' || numeric_precision || ',' || numeric_scale || ')'
            WHEN udt_name IN ('numeric', 'decimal') AND numeric_precision IS NOT NULL THEN data_type || '(' || numeric_precision || ')'
            ELSE data_type
        END ||
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END,
        E',\n    ' ORDER BY ordinal_position
    )
    INTO v_column_list
    FROM information_schema.columns
    WHERE table_schema = split_part(p_table_name, '.', 1)
      AND table_name = split_part(p_table_name, '.', 2);

    -- Tạo câu lệnh DDL cơ bản
    v_table_ddl := E'(\n    ' || v_column_list || E'\n)';

    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT,
    p_table TEXT,
    p_region_column TEXT,
    p_province_column TEXT,
    p_district_column TEXT,
    p_include_district BOOLEAN DEFAULT TRUE
) RETURNS BOOLEAN AS $$
DECLARE
    v_regions RECORD;
    v_provinces RECORD;
    v_districts RECORD;
    v_sql TEXT;
    v_partition_name_l1 TEXT; -- region level
    v_partition_name_l2 TEXT; -- province level
    v_partition_name_l3 TEXT; -- district level
    v_region_code TEXT;
    v_province_code TEXT;
    v_district_code TEXT;
    v_old_table_exists BOOLEAN;
    v_ddl TEXT;
    v_root_table_name TEXT := p_table || '_root';
BEGIN
    \echo format('    - Bắt đầu setup_nested_partitioning cho %I.%I (Include District: %s)...', p_schema, p_table, p_include_district);

    -- Kiểm tra bảng gốc
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = p_schema AND table_name = p_table
    ) INTO v_old_table_exists;

    IF NOT v_old_table_exists THEN
        \echo format('      Lỗi: Bảng %I.%I không tồn tại.', p_schema, p_table);
        RETURN FALSE;
    END IF;

    -- Lấy DDL bảng gốc
    v_ddl := partitioning.pg_get_tabledef(p_schema || '.' || p_table);

    -- 1. Tạo bảng gốc phân vùng (nếu chưa có)
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.%I %s
        PARTITION BY LIST (%I);
    ', p_schema, v_root_table_name, v_ddl, p_region_column);
     \echo format('      Đã tạo/xác nhận bảng gốc phân vùng %I.%I.', p_schema, v_root_table_name);

    -- 2. Lặp qua từng miền để tạo phân vùng cấp 1 (nếu chưa có)
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions LOOP
        v_region_code := lower(unaccent(replace(v_regions.region_code, ' ', '_')));
        v_partition_name_l1 := p_table || '_' || v_region_code;

        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.%I
            PARTITION OF %I.%I
            FOR VALUES IN (%L)
            PARTITION BY LIST (%I);
        ', p_schema, v_partition_name_l1,
           p_schema, v_root_table_name,
           v_regions.region_name, -- Giá trị cho LIST partitioning cấp 1
           p_province_column); -- Khóa phân vùng cho cấp 2
        \echo format('      Đã tạo/xác nhận partition cấp 1: %I.%I cho miền %s', p_schema, v_partition_name_l1, v_regions.region_name);

        -- 3. Lặp qua từng tỉnh trong miền để tạo phân vùng cấp 2 (nếu chưa có)
        FOR v_provinces IN SELECT province_id, province_code, province_name
                           FROM reference.provinces WHERE region_id = v_regions.region_id LOOP
            v_province_code := lower(unaccent(replace(v_provinces.province_code, ' ', '_')));
            v_partition_name_l2 := v_partition_name_l1 || '_' || v_province_code;

            IF p_include_district THEN
                 -- Tạo phân vùng cấp 2 (tỉnh) và khai báo nó phân vùng tiếp theo cấp 3 (huyện)
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L)
                    PARTITION BY LIST (%I);
                ', p_schema, v_partition_name_l2,
                   p_schema, v_partition_name_l1,
                   v_provinces.province_id, -- Giá trị cho LIST partitioning cấp 2
                   p_district_column); -- Khóa phân vùng cho cấp 3
                \echo format('        Đã tạo/xác nhận partition cấp 2: %I.%I cho tỉnh %s (sẽ phân vùng tiếp theo huyện)', p_schema, v_partition_name_l2, v_provinces.province_name);

                -- 4. Lặp qua từng quận/huyện trong tỉnh để tạo phân vùng cấp 3 (nếu chưa có)
                FOR v_districts IN SELECT district_id, district_code, district_name
                                   FROM reference.districts WHERE province_id = v_provinces.province_id LOOP
                    v_district_code := lower(unaccent(replace(v_districts.district_code, ' ', '_')));
                    v_partition_name_l3 := v_partition_name_l2 || '_' || v_district_code;

                    EXECUTE format('
                        CREATE TABLE IF NOT EXISTS %I.%I
                        PARTITION OF %I.%I
                        FOR VALUES IN (%L);
                    ', p_schema, v_partition_name_l3,
                       p_schema, v_partition_name_l2,
                       v_districts.district_id); -- Giá trị cho LIST partitioning cấp 3
                     \echo format('          Đã tạo/xác nhận partition cấp 3: %I.%I cho huyện %s', p_schema, v_partition_name_l3, v_districts.district_name);

                END LOOP; -- Hết vòng lặp huyện
            ELSE
                -- Nếu không bao gồm cấp huyện, tạo phân vùng tỉnh là cấp cuối cùng
                 EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L);
                ', p_schema, v_partition_name_l2,
                   p_schema, v_partition_name_l1,
                   v_provinces.province_id);
                \echo format('        Đã tạo/xác nhận partition cấp 2 (cuối cùng): %I.%I cho tỉnh %s', p_schema, v_partition_name_l2, v_provinces.province_name);
            END IF;
        END LOOP; -- Hết vòng lặp tỉnh
    END LOOP; -- Hết vòng lặp miền

    -- 5. Di chuyển dữ liệu và đổi tên (tương tự như setup_region_partitioning)
    PERFORM 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_partitioned_table p ON c.oid = p.partrelid
    WHERE c.relnamespace = (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = p_schema)
      AND c.relname = p_table;

    IF NOT FOUND THEN
         \echo format('      Bảng %I.%I chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', p_schema, p_table);
        BEGIN
            EXECUTE format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE;', p_schema, p_table);
            EXECUTE format('INSERT INTO %I.%I SELECT * FROM %I.%I;', p_schema, v_root_table_name, p_schema, p_table);
             \echo format('      Đã di chuyển dữ liệu từ %I.%I sang %I.%I.', p_schema, p_table, p_schema, v_root_table_name);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I_old;', p_schema, p_table, p_table);
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, v_root_table_name, p_table);
             \echo format('      Đã đổi tên %I.%I -> %I_old và %I.%I -> %I.%I.', p_schema, p_table, p_table, p_schema, v_root_table_name, p_schema, p_table);

            -- Ghi log history
            BEGIN
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, p_table, 'REPARTITIONED', 'Đã di chuyển dữ liệu và đổi tên thành bảng phân vùng đa cấp.');
            EXCEPTION WHEN undefined_table THEN
                 -- Bỏ qua
            END;
        EXCEPTION WHEN OTHERS THEN
            \echo format('      Lỗi khi di chuyển/đổi tên cho %I.%I: %s. Có thể cần thực hiện thủ công.', p_schema, p_table, SQLERRM);
            RETURN FALSE;
        END;
    ELSE
        \echo format('      Bảng %I.%I đã được phân vùng.', p_schema, p_table);
    END IF;

    -- 6. Ghi log cấu hình
    BEGIN
        INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column, is_active)
        VALUES (p_table, p_schema, 'NESTED',
            CASE WHEN p_include_district
                THEN p_region_column || ',' || p_province_column || ',' || p_district_column
                ELSE p_region_column || ',' || p_province_column
            END, TRUE)
        ON CONFLICT (table_name) DO UPDATE SET
            schema_name = EXCLUDED.schema_name,
            partition_type = EXCLUDED.partition_type,
            partition_column = EXCLUDED.partition_column,
            is_active = TRUE,
            updated_at = CURRENT_TIMESTAMP;
     EXCEPTION WHEN undefined_table THEN
         -- Bỏ qua
     END;

    \echo format('    - Hoàn thành setup_nested_partitioning cho %I.%I.', p_schema, p_table);
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function setup cho các bảng dữ liệu tích hợp
CREATE OR REPLACE FUNCTION partitioning.setup_integrated_data_partitioning() RETURNS VOID AS $$
BEGIN
     \echo '  -- Bắt đầu phân vùng các bảng integrated_data (TT)...';
    -- Phân vùng bảng integrated_citizen theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'central', 'integrated_citizen',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Phân vùng bảng integrated_household theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'central', 'integrated_household',
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    -- Các bảng khác trong central hoặc analytics nếu cần phân vùng theo địa lý tương tự
    -- Ví dụ: Phân vùng bảng fact trong analytics theo tỉnh (nếu cần)
    -- PERFORM partitioning.setup_province_partitioning('analytics', 'fact_population_snapshot', 'location_key'); -- Cần join với dim_location để lấy province_id
     \echo '  -- Kết thúc phân vùng các bảng integrated_data (TT).';

     -- Lưu ý: Bảng analytics.fact_* có thể nên phân vùng theo thời gian (RANGE) thay vì địa lý
     -- Ví dụ: PARTITION BY RANGE (snapshot_date_key)
     -- Việc này cần function riêng hoặc dùng pg_partman.
END;
$$ LANGUAGE plpgsql;


\echo '*** HOÀN THÀNH ĐỊNH NGHĨA CÁC FUNCTIONS PHÂN VÙNG ***'
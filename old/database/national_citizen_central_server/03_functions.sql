-- File: national_citizen_central_server/03_functions.sql
-- Description: Định nghĩa TẤT CẢ các functions/procedures PL/pgSQL
--              cho database Máy chủ Trung tâm (TT), bao gồm hàm phân vùng và đồng bộ.
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
--
-- Dependencies:
-- - Schemas 'central', 'sync', 'public_security_mirror', 'justice_mirror', 'reference', 'partitioning'.
-- - Các bảng trong các schema trên.
-- - Các ENUMs cần thiết.
-- - Extension 'unaccent'.
-- =============================================================================

\echo '*** BẮT ĐẦU ĐỊNH NGHĨA FUNCTIONS CHO DATABASE national_citizen_central_server ***'
\connect national_citizen_central_server

-- Đảm bảo các schema cần thiết tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;
CREATE SCHEMA IF NOT EXISTS sync;
CREATE SCHEMA IF NOT EXISTS central;
-- Các schema mirror (public_security_mirror, justice_mirror) và reference được giả định đã tồn tại

BEGIN;

-- ============================================================================
-- I. FUNCTIONS HỖ TRỢ PHÂN VÙNG (PARTITIONING HELPER FUNCTIONS)
-- (Lấy từ national_citizen_central_server/partitioning/functions.sql cũ)
-- ============================================================================

\echo '--> 1. Định nghĩa các hàm hỗ trợ phân vùng...'

-- Function: partitioning.log_history
-- Description: Ghi log vào bảng partitioning.history một cách nhất quán.
CREATE OR REPLACE FUNCTION partitioning.log_history(
    _schema TEXT,
    _table TEXT,
    _partition TEXT,
    _action TEXT,
    _status TEXT DEFAULT 'Success',
    _details TEXT DEFAULT NULL,
    _rows BIGINT DEFAULT NULL,
    _duration BIGINT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO partitioning.history (
        schema_name, table_name, partition_name, action, status, details, affected_rows, duration_ms
    ) VALUES (
        _schema, _table, _partition, _action, _status, _details, _rows, _duration
    );
EXCEPTION WHEN undefined_table THEN
    RAISE NOTICE '[partitioning.log_history] Bảng partitioning.history không tồn tại, bỏ qua ghi log.';
WHEN OTHERS THEN
     RAISE WARNING '[partitioning.log_history] Lỗi khi ghi log: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.log_history(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BIGINT, BIGINT) IS '[QLDCQG-TT] Hàm tiện ích để ghi log vào bảng partitioning.history.';


-- Function: partitioning.standardize_name
-- Description: Chuẩn hóa tên (loại bỏ dấu, khoảng trắng, chuyển thành chữ thường) để tạo tên partition.
CREATE OR REPLACE FUNCTION partitioning.standardize_name(_input_name TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Cần extension unaccent
    RETURN lower(regexp_replace(unaccent(_input_name), '[^a-zA-Z0-9_]+', '_', 'g'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
COMMENT ON FUNCTION partitioning.standardize_name(TEXT) IS '[QLDCQG-TT] Chuẩn hóa tên (bỏ dấu, khoảng trắng->_, lowercase) dùng cho tên partition.';


-- Function: partitioning.pg_get_tabledef
-- Description: Lấy định nghĩa cột cơ bản của bảng (không bao gồm FK, CHECK phức tạp, default...)
--              Đủ dùng cho việc tạo bảng con phân vùng có cấu trúc tương tự bảng cha.
CREATE OR REPLACE FUNCTION partitioning.pg_get_tabledef(p_schema_name TEXT, p_table_name TEXT)
RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_record RECORD;
    v_column_defs TEXT[] := '{}';
    v_partition_key_cols TEXT[];
BEGIN
    -- Lấy danh sách cột khóa phân vùng của bảng cha (nếu có) để loại trừ khỏi định nghĩa cột con
    SELECT string_to_array(pg_get_partition_keydef(c.oid), ', ')
    INTO v_partition_key_cols
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = p_schema_name AND c.relname = p_table_name AND c.relkind = 'p'; -- Chỉ lấy bảng cha (partitioned table)

    v_partition_key_cols := COALESCE(v_partition_key_cols, '{}'); -- Xử lý trường hợp bảng chưa được phân vùng

    FOR v_column_record IN
        SELECT
            column_name,
            data_type,
            udt_name,
            is_nullable,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            column_default
        FROM information_schema.columns
        WHERE table_schema = p_schema_name AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        -- Bỏ qua các cột là khóa phân vùng của bảng cha
        IF quote_ident(v_column_record.column_name) = ANY(v_partition_key_cols) THEN
            CONTINUE;
        END IF;

        v_column_defs := array_append(v_column_defs,
            quote_ident(v_column_record.column_name) || ' ' ||
            CASE
                WHEN v_column_record.udt_name IN ('varchar', 'bpchar') AND v_column_record.character_maximum_length IS NOT NULL THEN v_column_record.data_type || '(' || v_column_record.character_maximum_length || ')'
                WHEN v_column_record.udt_name IN ('numeric', 'decimal') AND v_column_record.numeric_precision IS NOT NULL AND v_column_record.numeric_scale IS NOT NULL THEN v_column_record.data_type || '(' || v_column_record.numeric_precision || ',' || v_column_record.numeric_scale || ')'
                WHEN v_column_record.udt_name IN ('numeric', 'decimal') AND v_column_record.numeric_precision IS NOT NULL THEN v_column_record.data_type || '(' || v_column_record.numeric_precision || ')'
                ELSE v_column_record.data_type
            END ||
            CASE WHEN v_column_record.is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
            -- Cố gắng giữ lại DEFAULT đơn giản (cần kiểm tra kỹ lưỡng hơn nếu default phức tạp)
            CASE WHEN v_column_record.column_default IS NOT NULL AND v_column_record.column_default !~* 'nextval' THEN ' DEFAULT ' || v_column_record.column_default ELSE '' END
        );
    END LOOP;

    -- Tạo câu lệnh DDL cơ bản
    v_table_ddl := E'(\n    ' || array_to_string(v_column_defs, E',\n    ') || E'\n)';

    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.pg_get_tabledef(TEXT, TEXT) IS '[QLDCQG-TT] Lấy định nghĩa cột cơ bản của bảng (trừ cột khóa phân vùng cha) để tạo partition con.';


-- ============================================================================
-- II. FUNCTIONS SETUP VÀ QUẢN LÝ PHÂN VÙNG
-- (Lấy từ national_citizen_central_server/partitioning/functions.sql cũ)
-- ============================================================================

\echo '--> 2. Định nghĩa các hàm setup và quản lý phân vùng...'

-- Function: partitioning.setup_nested_partitioning
-- Description: Khởi tạo phân vùng lồng nhau theo Miền -> Tỉnh -> Quận/Huyện (hoặc chỉ Miền -> Tỉnh).
CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT,
    p_table TEXT,
    p_region_column TEXT,       -- Cột chứa tên Miền (vd: geographical_region)
    p_province_column TEXT,     -- Cột chứa ID Tỉnh (vd: province_id)
    p_district_column TEXT,     -- Cột chứa ID Huyện (vd: district_id)
    p_include_district BOOLEAN DEFAULT TRUE -- TRUE: Phân vùng 3 cấp, FALSE: 2 cấp (đến Tỉnh)
) RETURNS BOOLEAN AS $$
DECLARE
    v_regions RECORD;
    v_provinces RECORD;
    v_districts RECORD;
    v_sql TEXT;
    v_partition_name_l1 TEXT; -- Tên partition cấp 1 (region)
    v_partition_name_l2 TEXT; -- Tên partition cấp 2 (province)
    v_partition_name_l3 TEXT; -- Tên partition cấp 3 (district)
    v_region_std_name TEXT;   -- Tên miền chuẩn hóa
    v_province_std_name TEXT; -- Tên tỉnh chuẩn hóa
    v_district_std_name TEXT; -- Tên huyện chuẩn hóa
    v_old_table_exists BOOLEAN;
    v_is_already_partitioned BOOLEAN;
    v_ddl_columns TEXT;
    v_root_table_name TEXT := p_table || '_partitioned'; -- Tên bảng cha mới (tạm thời)
    v_old_table_name TEXT := p_table || '_old';       -- Tên bảng cũ sau khi đổi tên
    v_row_count BIGINT;
    v_start_time TIMESTAMPTZ;
    v_duration BIGINT;
BEGIN
    v_start_time := clock_timestamp();
    RAISE NOTICE '[%] Bắt đầu setup_nested_partitioning cho %.% (Cấp huyện: %)...', v_start_time, p_schema, p_table, p_include_district;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Running', format('Bắt đầu phân vùng đa cấp (Cấp huyện: %s)', p_include_district));

    -- Kiểm tra bảng gốc tồn tại
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = p_table)
    INTO v_old_table_exists;

    IF NOT v_old_table_exists THEN
        RAISE WARNING '[%] Lỗi: Bảng %.% không tồn tại.', clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', format('Bảng %.% không tồn tại.', p_schema, p_table));
        RETURN FALSE;
    END IF;

    -- Kiểm tra bảng gốc đã được phân vùng chưa
    SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_partitioned_table pt JOIN pg_catalog.pg_class c ON pt.partrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = p_schema AND c.relname = p_table)
    INTO v_is_already_partitioned;

    -- Lấy định nghĩa cột cơ bản của bảng gốc
    v_ddl_columns := partitioning.pg_get_tabledef(p_schema, p_table);
    IF v_ddl_columns IS NULL OR v_ddl_columns = '()' THEN
         RAISE WARNING '[%] Lỗi: Không thể lấy định nghĩa cột cho %.%.', clock_timestamp(), p_schema, p_table;
         PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', 'Không thể lấy định nghĩa cột.');
         RETURN FALSE;
    END IF;

    -- 1. Tạo bảng gốc phân vùng mới (nếu chưa tồn tại hoặc bảng cũ chưa phân vùng)
    IF NOT v_is_already_partitioned THEN
        -- Đảm bảo tên bảng tạm thời không bị trùng
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', p_schema, v_root_table_name);
        v_sql := format('
            CREATE TABLE %I.%I %s
            PARTITION BY LIST (%I);
        ', p_schema, v_root_table_name, v_ddl_columns, p_region_column);
        RAISE NOTICE '[%] Tạo bảng gốc phân vùng tạm: %', clock_timestamp(), v_sql;
        EXECUTE v_sql;
        PERFORM partitioning.log_history(p_schema, p_table, v_root_table_name, 'CREATE_PARTITION', 'Success', 'Tạo bảng gốc phân vùng tạm thời.');
    ELSE
        v_root_table_name := p_table; -- Nếu đã phân vùng rồi thì dùng chính tên bảng đó
        RAISE NOTICE '[%] Bảng %.% đã được phân vùng. Bỏ qua tạo bảng gốc mới.', clock_timestamp(), p_schema, p_table;
    END IF;

    -- 2. Lặp qua từng Miền -> Tỉnh -> Huyện để tạo các partition con
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions ORDER BY region_id LOOP
        v_region_std_name := partitioning.standardize_name(v_regions.region_code);
        v_partition_name_l1 := p_table || '_' || v_region_std_name;

        -- Tạo partition cấp 1 (Miền) nếu chưa có
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l1) THEN
            v_sql := format('
                CREATE TABLE %I.%I PARTITION OF %I.%I
                FOR VALUES IN (%L) PARTITION BY LIST (%I);
            ', p_schema, v_partition_name_l1, p_schema, v_root_table_name, v_regions.region_name, p_province_column);
            RAISE NOTICE '[%] Tạo partition L1: %', clock_timestamp(), v_sql;
            EXECUTE v_sql;
            PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l1, 'CREATE_PARTITION', 'Success', format('Partition cấp 1 cho miền %s', v_regions.region_name));
        END IF;

        -- Lặp qua Tỉnh
        FOR v_provinces IN SELECT province_id, province_code, province_name FROM reference.provinces WHERE region_id = v_regions.region_id ORDER BY province_id LOOP
            v_province_std_name := partitioning.standardize_name(v_provinces.province_code);
            v_partition_name_l2 := v_partition_name_l1 || '_' || v_province_std_name;

            IF p_include_district THEN -- Nếu phân vùng đến cấp Huyện
                 -- Tạo partition cấp 2 (Tỉnh) nếu chưa có, khai báo phân vùng tiếp theo Huyện
                IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l2) THEN
                    v_sql := format('
                        CREATE TABLE %I.%I PARTITION OF %I.%I
                        FOR VALUES IN (%L) PARTITION BY LIST (%I);
                    ', p_schema, v_partition_name_l2, p_schema, v_partition_name_l1, v_provinces.province_id, p_district_column);
                    RAISE NOTICE '[%] Tạo partition L2: %', clock_timestamp(), v_sql;
                    EXECUTE v_sql;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Success', format('Partition cấp 2 cho tỉnh %s', v_provinces.province_name));
                 END IF;

                 -- Lặp qua Huyện
                 FOR v_districts IN SELECT district_id, district_code, district_name FROM reference.districts WHERE province_id = v_provinces.province_id ORDER BY district_id LOOP
                     v_district_std_name := partitioning.standardize_name(v_districts.district_code);
                     v_partition_name_l3 := v_partition_name_l2 || '_' || v_district_std_name;

                     -- Tạo partition cấp 3 (Huyện) nếu chưa có
                     IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l3) THEN
                         v_sql := format('
                             CREATE TABLE %I.%I PARTITION OF %I.%I
                             FOR VALUES IN (%L);
                         ', p_schema, v_partition_name_l3, p_schema, v_partition_name_l2, v_districts.district_id);
                         RAISE NOTICE '[%] Tạo partition L3: %', clock_timestamp(), v_sql;
                         EXECUTE v_sql;
                         PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l3, 'CREATE_PARTITION', 'Success', format('Partition cấp 3 cho huyện %s', v_districts.district_name));
                     END IF;
                 END LOOP; -- Hết vòng lặp Huyện
            ELSE -- Nếu chỉ phân vùng đến cấp Tỉnh
                 -- Tạo partition cấp 2 (Tỉnh) nếu chưa có, đây là cấp cuối
                 IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l2) THEN
                     v_sql := format('
                         CREATE TABLE %I.%I PARTITION OF %I.%I
                         FOR VALUES IN (%L);
                     ', p_schema, v_partition_name_l2, p_schema, v_partition_name_l1, v_provinces.province_id);
                     RAISE NOTICE '[%] Tạo partition L2 (cuối): %', clock_timestamp(), v_sql;
                     EXECUTE v_sql;
                     PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Success', format('Partition cấp 2 (cuối) cho tỉnh %s', v_provinces.province_name));
                 END IF;
            END IF; -- Hết if p_include_district
        END LOOP; -- Hết vòng lặp Tỉnh
    END LOOP; -- Hết vòng lặp Miền

    -- 3. Di chuyển dữ liệu và đổi tên (chỉ thực hiện nếu bảng gốc chưa phân vùng)
    IF NOT v_is_already_partitioned THEN
        RAISE NOTICE '[%] Bảng %.% chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', clock_timestamp(), p_schema, p_table;
        -- Khóa bảng gốc để tránh ghi dữ liệu mới trong quá trình di chuyển
        v_sql := format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE;', p_schema, p_table);
        RAISE NOTICE '[%] Khóa bảng gốc: %', clock_timestamp(), v_sql;
        EXECUTE v_sql;

        -- Di chuyển dữ liệu
        v_sql := format('INSERT INTO %I.%I SELECT * FROM %I.%I;', p_schema, v_root_table_name, p_schema, p_table);
        RAISE NOTICE '[%] Di chuyển dữ liệu: %', clock_timestamp(), v_sql;
        EXECUTE v_sql;
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        RAISE NOTICE '[%] Đã di chuyển % dòng.', clock_timestamp(), v_row_count;

        -- Đổi tên bảng cũ và bảng mới
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', p_schema, v_old_table_name); -- Xóa bảng _old cũ nếu có
        v_sql := format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, p_table, v_old_table_name);
        RAISE NOTICE '[%] Đổi tên bảng cũ: %', clock_timestamp(), v_sql;
        EXECUTE v_sql;

        v_sql := format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, v_root_table_name, p_table);
        RAISE NOTICE '[%] Đổi tên bảng mới: %', clock_timestamp(), v_sql;
        EXECUTE v_sql;

        v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'REPARTITIONED', 'Success', format('Đã di chuyển %s dòng và đổi tên thành bảng phân vùng.', v_row_count), v_row_count, v_duration);
        RAISE NOTICE '[%] Hoàn tất di chuyển và đổi tên cho %.%.', clock_timestamp(), p_schema, p_table;
    END IF;

    -- 4. Ghi hoặc cập nhật cấu hình vào partitioning.config
    BEGIN
        INSERT INTO partitioning.config (schema_name, table_name, partition_type, partition_columns, is_active, updated_at)
        VALUES (p_schema, p_table, 'NESTED',
            CASE WHEN p_include_district
                THEN p_region_column || ',' || p_province_column || ',' || p_district_column
                ELSE p_region_column || ',' || p_province_column
            END, TRUE, CURRENT_TIMESTAMP)
        ON CONFLICT (schema_name, table_name) DO UPDATE SET
            partition_type = EXCLUDED.partition_type,
            partition_columns = EXCLUDED.partition_columns,
            is_active = TRUE,
            updated_at = CURRENT_TIMESTAMP;
        RAISE NOTICE '[%] Đã ghi/cập nhật cấu hình phân vùng cho %.%.', clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CONFIG_UPDATE', 'Success', 'Ghi/cập nhật cấu hình phân vùng NESTED.');
    EXCEPTION WHEN undefined_table THEN
        RAISE NOTICE '[%] Bảng partitioning.config không tồn tại, bỏ qua ghi cấu hình.';
    END;

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Hoàn thành setup_nested_partitioning cho %.% sau % ms.', clock_timestamp(), p_schema, p_table, v_duration;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Success', format('Hoàn thành phân vùng đa cấp sau %s ms', v_duration), v_row_count, v_duration);

    RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE WARNING '[%] Lỗi khi thực hiện setup_nested_partitioning cho %.%: %', clock_timestamp(), p_schema, p_table, SQLERRM;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', SQLERRM, NULL, v_duration);
    RETURN FALSE; -- Hoặc RAISE EXCEPTION tùy thuộc vào muốn dừng hẳn hay không
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.setup_nested_partitioning(TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS '[QLDCQG-TT] Thiết lập phân vùng lồng nhau theo Miền->Tỉnh->Huyện (hoặc Miền->Tỉnh) cho bảng, tự động tạo partition con và di chuyển dữ liệu nếu cần.';


-- Function: partitioning.move_data_between_partitions
-- Description: Di chuyển một bản ghi cụ thể từ partition hiện tại sang partition mới.
CREATE OR REPLACE FUNCTION partitioning.move_data_between_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_key_column TEXT, -- Tên cột khóa chính logic (vd: 'citizen_id')
    p_key_value ANYELEMENT, -- Giá trị của khóa chính logic (cần cùng kiểu với cột p_key_column)
    p_new_geographical_region TEXT, -- Tên Miền mới
    p_new_province_id INTEGER,      -- ID Tỉnh mới
    p_new_district_id INTEGER       -- ID Huyện mới (NULL nếu bảng chỉ phân vùng đến Tỉnh)
) RETURNS BOOLEAN AS $$
DECLARE
    v_record RECORD;
    v_rows_affected INTEGER := 0;
    v_delete_sql TEXT;
    v_insert_sql TEXT;
    v_cols TEXT;
    v_placeholders TEXT;
    v_col_name TEXT;
    v_col_idx INTEGER := 1;
    v_values ANYARRAY;
    v_region_col TEXT;
    v_province_col TEXT;
    v_district_col TEXT;
    v_start_time TIMESTAMPTZ;
    v_duration BIGINT;
BEGIN
    v_start_time := clock_timestamp();
    RAISE NOTICE '[%] Bắt đầu move_data_between_partitions cho %.%, key %=%', v_start_time, p_schema, p_table, p_key_column, p_key_value;
    PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Running', 'Bắt đầu di chuyển bản ghi sang partition mới.');

    -- Lấy tên các cột khóa phân vùng từ config
    SELECT split_part(partition_columns, ',', 1),
           split_part(partition_columns, ',', 2),
           split_part(partition_columns, ',', 3)
    INTO v_region_col, v_province_col, v_district_col
    FROM partitioning.config
    WHERE schema_name = p_schema AND table_name = p_table AND partition_type = 'NESTED';

    IF v_region_col IS NULL OR v_province_col IS NULL THEN
        RAISE WARNING '[%] Không tìm thấy cấu hình phân vùng NESTED cho %.%', clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 'Không tìm thấy cấu hình phân vùng NESTED.');
        RETURN FALSE;
    END IF;
    -- Nếu bảng chỉ có 2 cấp, v_district_col sẽ là '' hoặc NULL, cần xử lý
    IF v_district_col = '' THEN v_district_col := NULL; END IF;
    IF v_district_col IS NOT NULL AND p_new_district_id IS NULL THEN
        RAISE WARNING '[%] Bảng %.% phân vùng đến cấp huyện nhưng không cung cấp p_new_district_id.', clock_timestamp(), p_schema, p_table;
         PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 'Thiếu district_id mới cho bảng phân vùng 3 cấp.');
        RETURN FALSE;
    END IF;


    -- 1. Lấy bản ghi cần di chuyển (chỉ 1 bản ghi)
    EXECUTE format('SELECT * FROM %I.%I WHERE %I = $1 LIMIT 1',
                   p_schema, p_table, p_key_column)
    INTO v_record
    USING p_key_value;

    IF v_record IS NULL THEN
        RAISE NOTICE '[%] Không tìm thấy bản ghi với % = % trong bảng %.%', clock_timestamp(), p_key_column, p_key_value, p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 'Không tìm thấy bản ghi gốc.');
        RETURN FALSE;
    END IF;

    -- 2. Xóa bản ghi khỏi vị trí cũ (khỏi bảng cha, PG sẽ tự tìm partition)
    v_delete_sql := format('DELETE FROM %I.%I WHERE %I = $1',
                           p_schema, p_table, p_key_column);
    RAISE NOTICE '[%] Thực thi DELETE: % (USING %)', clock_timestamp(), v_delete_sql, p_key_value;
    EXECUTE v_delete_sql USING p_key_value;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF v_rows_affected <> 1 THEN
        -- Có thể do race condition hoặc bản ghi đã bị xóa bởi process khác
        RAISE WARNING '[%] Không xóa được (hoặc xóa nhiều hơn 1) bản ghi gốc với % = %. Rows affected: %.', clock_timestamp(), p_key_column, p_key_value, v_rows_affected;
        PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', format('Lỗi khi xóa bản ghi gốc. Rows affected: %s', v_rows_affected));
        -- Cân nhắc ROLLBACK nếu đang trong transaction lớn hơn
        RETURN FALSE;
    END IF;

    -- 3. Chuẩn bị dữ liệu để INSERT lại với thông tin phân vùng mới
    SELECT string_agg(quote_ident(key), ', '),
           string_agg('$' || (row_number() over ()), ', '),
           array_agg(value)
    INTO v_cols, v_placeholders, v_values
    FROM jsonb_each_text(to_jsonb(v_record)) AS t(key, value)
    -- Cập nhật lại giá trị cho các cột khóa phân vùng
    WHERE key <> v_region_col
      AND key <> v_province_col
      AND (v_district_col IS NULL OR key <> v_district_col);

    -- Thêm các cột khóa phân vùng mới vào danh sách cột và giá trị
    v_cols := v_cols || ', ' || quote_ident(v_region_col) || ', ' || quote_ident(v_province_col);
    v_values := v_values || ARRAY[p_new_geographical_region::TEXT, p_new_province_id::TEXT]; -- Cast sang TEXT để array_agg hoạt động
    v_placeholders := v_placeholders || ', $' || (array_length(v_values, 1) - 1) || ', $' || array_length(v_values, 1);


    IF v_district_col IS NOT NULL THEN
        v_cols := v_cols || ', ' || quote_ident(v_district_col);
        v_values := v_values || ARRAY[p_new_district_id::TEXT];
        v_placeholders := v_placeholders || ', $' || array_length(v_values, 1);
    END IF;

    -- 4. Chèn lại bản ghi vào bảng cha (PG sẽ tự định tuyến đến partition mới)
    v_insert_sql := format('INSERT INTO %I.%I (%s) VALUES (%s)',
                           p_schema, p_table, v_cols, v_placeholders);
    RAISE NOTICE '[%] Thực thi INSERT: % (USING %)', clock_timestamp(), v_insert_sql, v_values;
    EXECUTE v_insert_sql USING VARIADIC v_values; -- Sử dụng USING VARIADIC để truyền mảng giá trị

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Đã di chuyển thành công bản ghi % = % sang phân vùng mới (%s, %, %)', clock_timestamp(), p_key_column, p_key_value, p_new_geographical_region, p_new_province_id, p_new_district_id;
    PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Success', format('Đã di chuyển đến phân vùng mới (%s, %s, %s)', p_new_geographical_region, p_new_province_id, COALESCE(p_new_district_id::text, 'N/A')), 1, v_duration);

    RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE WARNING '[%] Lỗi khi di chuyển dữ liệu cho %.%, key %=%: %', clock_timestamp(), p_schema, p_table, p_key_column, p_key_value, SQLERRM;
    PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', SQLERRM, NULL, v_duration);
    -- Cân nhắc ROLLBACK nếu đang trong transaction lớn hơn
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.move_data_between_partitions(TEXT, TEXT, TEXT, ANYELEMENT, TEXT, INTEGER, INTEGER) IS '[QLDCQG-TT] Di chuyển một bản ghi cụ thể sang partition mới dựa trên thông tin phân vùng mới được cung cấp.';


-- Function: partitioning.create_partition_indexes
-- Description: Tự động tạo các index cần thiết trên TẤT CẢ các partition con
CREATE OR REPLACE FUNCTION partitioning.create_partition_indexes(
    p_schema TEXT,
    p_table TEXT,
    p_index_definitions TEXT[] -- Mảng chứa định nghĩa CREATE INDEX đầy đủ, ví dụ: ARRAY['CREATE INDEX idx_col1 ON %1$I.%2$I (col1)']
                               -- %1$I là schema, %2$I là tên partition
) RETURNS VOID AS $$
DECLARE
    v_partition_name TEXT;
    v_index_def TEXT;
    v_index_name TEXT;
    v_sql TEXT;
    v_start_time TIMESTAMPTZ;
    v_duration BIGINT;
BEGIN
    v_start_time := clock_timestamp();
    RAISE NOTICE '[%] Bắt đầu create_partition_indexes cho %.%...', v_start_time, p_schema, p_table;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Running', 'Bắt đầu tạo index trên các partition.');

    -- Lặp qua tất cả các partition con hiện có của bảng cha
    FOR v_partition_name IN
        SELECT c.relname
        FROM pg_catalog.pg_inherits i
        JOIN pg_catalog.pg_class c ON i.inhrelid = c.oid
        JOIN pg_catalog.pg_namespace nsp ON c.relnamespace = nsp.oid
        JOIN pg_catalog.pg_class parent ON i.inhparent = parent.oid
        WHERE parent.relname = p_table AND nsp.nspname = p_schema AND c.relkind = 'r' -- Chỉ lấy partition là bảng (relation)
    LOOP
        RAISE NOTICE '[%]   - Xử lý partition: %.%', clock_timestamp(), p_schema, v_partition_name;
        -- Lặp qua các định nghĩa index cần tạo
        FOREACH v_index_def IN ARRAY p_index_definitions
        LOOP
            -- Trích xuất tên index dự kiến từ định nghĩa
            SELECT (regexp_matches(v_index_def, 'CREATE(?: UNIQUE)? INDEX\s+(?:IF NOT EXISTS\s+)?(\S+)\s+ON', 'i'))[1] INTO v_index_name;

             IF v_index_name IS NULL THEN
                 RAISE WARNING '[%] Không thể trích xuất tên index từ định nghĩa: %', clock_timestamp(), v_index_def;
                 CONTINUE; -- Bỏ qua định nghĩa này
             END IF;

             -- Chuẩn hóa tên index (thay placeholder %2$s bằng tên partition)
             v_index_name := replace(v_index_name, '%2$s', v_partition_name);

            -- Kiểm tra xem index đã tồn tại trên partition này chưa
            IF NOT EXISTS (
                SELECT 1
                FROM pg_catalog.pg_indexes
                WHERE schemaname = p_schema
                  AND tablename = v_partition_name
                  AND indexname = v_index_name
            ) THEN
                -- Thay thế placeholder %1$I (schema) và %2$I (partition name) bằng giá trị thực tế
                BEGIN
                    v_sql := format(v_index_def, p_schema, v_partition_name);
                    RAISE NOTICE '[%]     Tạo index: %', clock_timestamp(), v_sql;
                    EXECUTE v_sql;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name, 'CREATE_INDEX', 'Success', 'Đã tạo index: ' || v_index_name);
                EXCEPTION WHEN OTHERS THEN
                    RAISE WARNING '[%] Lỗi khi tạo index "%" trên partition %.%: %', clock_timestamp(), v_index_name, p_schema, v_partition_name, SQLERRM;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name, 'CREATE_INDEX', 'Failed', format('Lỗi tạo index %s: %s', v_index_name, SQLERRM));
                END;
            ELSE
                 RAISE NOTICE '[%]     Index "%" đã tồn tại trên %.%.', clock_timestamp(), v_index_name, p_schema, v_partition_name;
            END IF;
        END LOOP; -- Hết vòng lặp định nghĩa index
    END LOOP; -- Hết vòng lặp partition

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Hoàn thành create_partition_indexes cho %.% sau % ms.', clock_timestamp(), p_schema, p_table, v_duration;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Success', format('Hoàn thành tạo index trên các partition sau %s ms.', v_duration), NULL, v_duration);

END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.create_partition_indexes(TEXT, TEXT, TEXT[]) IS '[QLDCQG-TT] Tạo các index được định nghĩa trong mảng p_index_definitions trên tất cả các partition con của bảng p_table.';


-- ============================================================================
-- III. FUNCTIONS LOGIC ĐỒNG BỘ HÓA DỮ LIỆU
-- (Lấy từ national_citizen_central_server/functions/sync_logic.sql cũ)
-- ============================================================================

\echo '--> 3. Định nghĩa các hàm logic đồng bộ hóa dữ liệu...'

-- Function: sync.run_synchronization
-- Description: Hàm chính điều phối toàn bộ quy trình đồng bộ dữ liệu từ BCA và BTP vào DB Trung tâm.
CREATE OR REPLACE FUNCTION sync.run_synchronization() RETURNS VOID AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_last_sync_bca TIMESTAMPTZ;
    v_last_sync_btp TIMESTAMPTZ;
    v_current_sync_time TIMESTAMPTZ := v_start_time; -- Thời điểm bắt đầu của lần sync này
    v_processed_citizens BIGINT := 0;
    v_processed_households BIGINT := 0;
    v_error_details TEXT;
    v_sync_status RECORD;
BEGIN
    RAISE NOTICE '[%] Bắt đầu sync.run_synchronization...', v_start_time;
    PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_START', 'Running', 'Bắt đầu quy trình đồng bộ hóa.');

    -- 1. Lấy thời điểm đồng bộ thành công lần cuối từ bảng sync.sync_status
    BEGIN
        SELECT * INTO v_sync_status FROM sync.sync_status ORDER BY last_run_timestamp DESC NULLS LAST LIMIT 1;
        IF v_sync_status IS NULL OR v_sync_status.last_run_status <> 'Success' THEN
            -- Nếu chưa có trạng thái hoặc lần chạy trước thất bại, đồng bộ từ đầu
            v_last_sync_bca := '1970-01-01 00:00:00+00'::TIMESTAMPTZ;
            v_last_sync_btp := '1970-01-01 00:00:00+00'::TIMESTAMPTZ;
            RAISE NOTICE '[%] Không tìm thấy trạng thái đồng bộ thành công trước đó hoặc lần cuối thất bại. Đồng bộ lại từ đầu.';
        ELSE
            v_last_sync_bca := v_sync_status.last_sync_bca;
            v_last_sync_btp := v_sync_status.last_sync_btp;
            RAISE NOTICE '[%] Đồng bộ thay đổi từ BCA sau: %, từ BTP sau: %', clock_timestamp(), v_last_sync_bca, v_last_sync_btp;
        END IF;
    EXCEPTION WHEN undefined_table THEN
        RAISE WARNING '[%] Bảng sync.sync_status không tồn tại. Đồng bộ từ đầu.';
        v_last_sync_bca := '1970-01-01 00:00:00+00'::TIMESTAMPTZ;
        v_last_sync_btp := '1970-01-01 00:00:00+00'::TIMESTAMPTZ;
    END;


    -- 2. Đồng bộ dữ liệu Công dân (Citizen)
    RAISE NOTICE '[%] Bắt đầu đồng bộ Công dân...', clock_timestamp();
    BEGIN
        -- *** QUAN TRỌNG: Logic chi tiết của sync_citizens cần được hoàn thiện ***
        v_processed_citizens := sync.sync_citizens(v_last_sync_bca, v_last_sync_btp, v_current_sync_time);
        RAISE NOTICE '[%] Hoàn thành đồng bộ Công dân. Đã xử lý (ước tính): % bản ghi.', clock_timestamp(), v_processed_citizens;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_citizen', 'SYNC_STEP', 'Success', format('Đồng bộ công dân hoàn thành. Xử lý: %s', v_processed_citizens));
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_details = PG_EXCEPTION_CONTEXT; -- Get more context
        RAISE WARNING '[%] Lỗi khi đồng bộ Công dân: %. Chi tiết: %. Context: %', clock_timestamp(), SQLERRM, SQLSTATE, v_error_details;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_citizen', 'SYNC_STEP', 'Failed', format('Lỗi đồng bộ công dân: %s. State: %s. Detail: %s', SQLERRM, SQLSTATE, v_error_details));
         -- Ghi nhận lỗi vào sync_status và kết thúc
         BEGIN
             INSERT INTO sync.sync_status (last_sync_bca, last_sync_btp, last_run_status, last_run_timestamp, last_error_message)
             VALUES (v_last_sync_bca, v_last_sync_btp, 'Failed', v_current_sync_time, format('Lỗi đồng bộ công dân: %s. State: %s. Detail: %s', SQLERRM, SQLSTATE, v_error_details));
         EXCEPTION WHEN undefined_table THEN RAISE WARNING 'Không thể ghi lỗi vào sync.sync_status.'; END;
         PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_END', 'Failed', format('Quy trình dừng do lỗi đồng bộ công dân: %s', SQLERRM));
        RETURN;
    END;

    -- 3. Đồng bộ dữ liệu Hộ khẩu (Household)
    RAISE NOTICE '[%] Bắt đầu đồng bộ Hộ khẩu...', clock_timestamp();
     BEGIN
        -- *** QUAN TRỌNG: Logic chi tiết của sync_households cần được hoàn thiện ***
        v_processed_households := sync.sync_households(v_last_sync_btp, v_current_sync_time);
        RAISE NOTICE '[%] Hoàn thành đồng bộ Hộ khẩu. Đã xử lý (ước tính): % bản ghi.', clock_timestamp(), v_processed_households;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_household', 'SYNC_STEP', 'Success', format('Đồng bộ hộ khẩu hoàn thành. Xử lý: %s', v_processed_households));
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_details = PG_EXCEPTION_CONTEXT;
        RAISE WARNING '[%] Lỗi khi đồng bộ Hộ khẩu: %. Chi tiết: %. Context: %', clock_timestamp(), SQLERRM, SQLSTATE, v_error_details;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_household', 'SYNC_STEP', 'Failed', format('Lỗi đồng bộ hộ khẩu: %s. State: %s. Detail: %s', SQLERRM, SQLSTATE, v_error_details));
         -- Ghi nhận lỗi vào sync_status và kết thúc
         BEGIN
             INSERT INTO sync.sync_status (last_sync_bca, last_sync_btp, last_run_status, last_run_timestamp, last_error_message)
             VALUES (v_last_sync_bca, v_last_sync_btp, 'Failed', v_current_sync_time, format('Lỗi đồng bộ hộ khẩu: %s. State: %s. Detail: %s', SQLERRM, SQLSTATE, v_error_details));
         EXCEPTION WHEN undefined_table THEN RAISE WARNING 'Không thể ghi lỗi vào sync.sync_status.'; END;
         PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_END', 'Failed', format('Quy trình dừng do lỗi đồng bộ hộ khẩu: %s', SQLERRM));
        RETURN;
    END;

    -- 4. Cập nhật thời điểm đồng bộ thành công lần cuối
    RAISE NOTICE '[%] Cập nhật thời điểm đồng bộ thành công: %', clock_timestamp(), v_current_sync_time;
    BEGIN
        -- Thêm bản ghi mới để lưu lịch sử, thay vì UPDATE dòng cũ
        INSERT INTO sync.sync_status (last_sync_bca, last_sync_btp, last_run_status, last_run_timestamp, last_error_message)
        VALUES (v_current_sync_time, v_current_sync_time, 'Success', v_current_sync_time, NULL);
    EXCEPTION WHEN undefined_table THEN
        RAISE WARNING '[%] Bảng sync.sync_status không tồn tại. Không thể cập nhật trạng thái.';
    END;

    PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_END', 'Success', format('Hoàn thành đồng bộ. Công dân: %s, Hộ khẩu: %s.', v_processed_citizens, v_processed_households), (v_processed_citizens + v_processed_households), EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000);
    RAISE NOTICE '[%] Kết thúc sync.run_synchronization.', clock_timestamp();

END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sync.run_synchronization() IS '[QLDCQG-TT] Hàm chính điều phối toàn bộ quy trình đồng bộ dữ liệu từ BCA và BTP vào DB Trung tâm.';


-- Function: sync.sync_citizens (Cần hoàn thiện logic)
-- Description: Đồng bộ dữ liệu công dân từ mirror vào bảng central.integrated_citizen.
CREATE OR REPLACE FUNCTION sync.sync_citizens(
    _last_sync_bca TIMESTAMPTZ,
    _last_sync_btp TIMESTAMPTZ,
    _current_sync_time TIMESTAMPTZ
) RETURNS BIGINT AS $$
DECLARE
    v_upserted_count BIGINT := 0;
    v_processed_count BIGINT := 0;
    v_row RECORD;
    v_citizen_data JSONB;
    v_id_card_data JSONB;
    v_perm_addr_data RECORD;
    v_temp_addr_data RECORD;
    v_birth_cert_data RECORD;
    v_death_cert_data RECORD;
    v_marriage_data RECORD;
    v_divorce_data RECORD;
    v_partition_info RECORD;
    v_citizen_updates JSONB;
    v_source_updated_bca BOOLEAN := FALSE;
    v_source_updated_btp BOOLEAN := FALSE;
    v_data_sources TEXT[];
    v_sql TEXT;
BEGIN
    RAISE NOTICE '[sync.sync_citizens] Bắt đầu xử lý công dân thay đổi sau BCA: %, BTP: %', _last_sync_bca, _last_sync_btp;

    -- Bước 1: Xác định các citizen_id cần cập nhật
    -- Bao gồm những citizen mới hoặc có thay đổi trong BCA hoặc BTP kể từ lần sync cuối
    -- Lưu ý: Điều kiện `updated_at > _last_sync_*` cần được kiểm tra kỹ lưỡng
    -- vì FDW có thể không tối ưu hóa tốt hoặc không có cột updated_at ở bảng nguồn.
    -- Có thể cần một cơ chế khác để xác định thay đổi (VD: Dùng bảng staging hoặc CDC).
    -- Giả định các bảng mirror có cột 'updated_at' để minh họa.
    CREATE TEMP TABLE temp_changed_citizens (citizen_id VARCHAR(12) PRIMARY KEY) ON COMMIT DROP;

    RAISE NOTICE '[sync.sync_citizens]   -> Tìm công dân thay đổi từ BCA...';
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT citizen_id FROM public_security_mirror.citizen WHERE updated_at > _last_sync_bca
    ON CONFLICT (citizen_id) DO NOTHING;
    -- Thêm các nguồn thay đổi khác từ BCA (identification_card, permanent_residence, temporary_residence...)
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT citizen_id FROM public_security_mirror.identification_card WHERE updated_at > _last_sync_bca
    ON CONFLICT (citizen_id) DO NOTHING;
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT citizen_id FROM public_security_mirror.permanent_residence WHERE updated_at > _last_sync_bca
    ON CONFLICT (citizen_id) DO NOTHING;
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT citizen_id FROM public_security_mirror.temporary_residence WHERE updated_at > _last_sync_bca
    ON CONFLICT (citizen_id) DO NOTHING;

    RAISE NOTICE '[sync.sync_citizens]   -> Tìm công dân thay đổi từ BTP...';
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT citizen_id FROM justice_mirror.birth_certificate WHERE updated_at > _last_sync_btp
    ON CONFLICT (citizen_id) DO NOTHING;
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT citizen_id FROM justice_mirror.death_certificate WHERE updated_at > _last_sync_btp
    ON CONFLICT (citizen_id) DO NOTHING;
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT husband_id FROM justice_mirror.marriage WHERE updated_at > _last_sync_btp
    UNION
    SELECT wife_id FROM justice_mirror.marriage WHERE updated_at > _last_sync_btp
    ON CONFLICT (citizen_id) DO NOTHING;
    INSERT INTO temp_changed_citizens (citizen_id)
    SELECT husband_id FROM justice_mirror.divorce d JOIN justice_mirror.marriage m ON d.marriage_id = m.marriage_id WHERE d.updated_at > _last_sync_btp
    UNION
    SELECT wife_id FROM justice_mirror.divorce d JOIN justice_mirror.marriage m ON d.marriage_id = m.marriage_id WHERE d.updated_at > _last_sync_btp
    ON CONFLICT (citizen_id) DO NOTHING;

    RAISE NOTICE '[sync.sync_citizens]   -> Tổng số công dân cần kiểm tra: %', (SELECT count(*) FROM temp_changed_citizens);

    -- Bước 2: Lặp qua từng citizen_id cần xử lý
    FOR v_row IN SELECT citizen_id FROM temp_changed_citizens LOOP
        v_processed_count := v_processed_count + 1;
        v_source_updated_bca := FALSE;
        v_source_updated_btp := FALSE;
        v_citizen_updates := '{}'::jsonb; -- Reset cho mỗi công dân

        -- Bước 3: Thu thập dữ liệu mới nhất từ các bảng mirror cho citizen_id này
        -- Lấy thông tin cơ bản từ BCA
        SELECT to_jsonb(c.*) INTO v_citizen_data
        FROM public_security_mirror.citizen c
        WHERE c.citizen_id = v_row.citizen_id;

        IF v_citizen_data IS NULL THEN
            RAISE WARNING '[sync.sync_citizens] Không tìm thấy thông tin citizen % trong mirror BCA. Bỏ qua.', v_row.citizen_id;
            CONTINUE; -- Bỏ qua nếu không có thông tin cơ bản
        END IF;

        IF (v_citizen_data->>'updated_at')::TIMESTAMPTZ > _last_sync_bca THEN
           v_source_updated_bca := TRUE;
        END IF;
        -- Khởi tạo mảng data_sources
        v_data_sources := ARRAY['BCA'];

        -- 3.1 Lấy thông tin CCCD mới nhất từ BCA
        SELECT to_jsonb(ic.*) INTO v_id_card_data
        FROM public_security_mirror.identification_card ic
        WHERE ic.citizen_id = v_row.citizen_id
        ORDER BY ic.issue_date DESC, ic.id_card_id DESC -- Ưu tiên thẻ mới nhất
        LIMIT 1;

        IF v_id_card_data IS NOT NULL THEN
            IF (v_id_card_data->>'updated_at')::TIMESTAMPTZ > _last_sync_bca THEN
                 v_source_updated_bca := TRUE;
            END IF;
            v_citizen_updates := v_citizen_updates || jsonb_build_object(
                'current_id_card_number', v_id_card_data->'card_number',
                'current_id_card_type', v_id_card_data->'card_type',
                'current_id_card_issue_date', v_id_card_data->'issue_date',
                'current_id_card_expiry_date', v_id_card_data->'expiry_date',
                'current_id_card_issuing_authority_id', v_id_card_data->'issuing_authority_id'
            );
        END IF;

        -- 3.2 Lấy địa chỉ thường trú mới nhất từ BCA
        SELECT pr.address_id, pr.registration_date, a.address_detail, a.district_id, a.province_id, a.geographical_region, pr.updated_at
        INTO v_perm_addr_data
        FROM public_security_mirror.permanent_residence pr
        JOIN public_security_mirror.address a ON pr.address_id = a.address_id
        WHERE pr.citizen_id = v_row.citizen_id AND pr.status = TRUE
        ORDER BY pr.registration_date DESC, pr.permanent_residence_id DESC
        LIMIT 1;

        IF FOUND THEN
            IF v_perm_addr_data.updated_at > _last_sync_bca THEN
                 v_source_updated_bca := TRUE;
            END IF;
            v_citizen_updates := v_citizen_updates || jsonb_build_object(
                'current_permanent_address_id', v_perm_addr_data.address_id,
                'current_permanent_address_detail', v_perm_addr_data.address_detail,
                'current_permanent_registration_date', v_perm_addr_data.registration_date
            );
            -- Xác định thông tin phân vùng dựa trên địa chỉ thường trú
             v_partition_info := ROW(
                v_perm_addr_data.geographical_region::TEXT,
                v_perm_addr_data.province_id::INTEGER,
                v_perm_addr_data.district_id::INTEGER
            );
        ELSE
             v_partition_info := NULL; -- Reset nếu không có địa chỉ thường trú
        END IF;

        -- 3.3 Lấy địa chỉ tạm trú mới nhất từ BCA
        SELECT tr.address_id, tr.registration_date, tr.expiry_date, a.address_detail, a.district_id, a.province_id, a.geographical_region, tr.updated_at
        INTO v_temp_addr_data
        FROM public_security_mirror.temporary_residence tr
        JOIN public_security_mirror.address a ON tr.address_id = a.address_id
        WHERE tr.citizen_id = v_row.citizen_id AND tr.status = 'Active' -- Giả sử có status 'Active'
        ORDER BY tr.registration_date DESC, tr.temporary_residence_id DESC
        LIMIT 1;

        IF FOUND THEN
             IF v_temp_addr_data.updated_at > _last_sync_bca THEN
                 v_source_updated_bca := TRUE;
            END IF;
             v_citizen_updates := v_citizen_updates || jsonb_build_object(
                'current_temporary_address_id', v_temp_addr_data.address_id,
                'current_temporary_address_detail', v_temp_addr_data.address_detail,
                'current_temporary_registration_date', v_temp_addr_data.registration_date,
                'current_temporary_expiry_date', v_temp_addr_data.expiry_date
            );
            -- Nếu không có địa chỉ thường trú, dùng tạm trú để phân vùng
            IF v_partition_info IS NULL THEN
                v_partition_info := ROW(
                    v_temp_addr_data.geographical_region::TEXT,
                    v_temp_addr_data.province_id::INTEGER,
                    v_temp_addr_data.district_id::INTEGER
                );
            END IF;
        END IF;

        -- Bước 4: Lấy dữ liệu từ BTP
        -- 4.1 Khai sinh
        SELECT bc.birth_certificate_no, bc.registration_date AS birth_reg_date, bc.updated_at
        INTO v_birth_cert_data
        FROM justice_mirror.birth_certificate bc
        WHERE bc.citizen_id = v_row.citizen_id;
        IF FOUND THEN
             IF v_birth_cert_data.updated_at > _last_sync_btp THEN
                  v_source_updated_btp := TRUE;
             END IF;
            v_citizen_updates := v_citizen_updates || jsonb_build_object(
                'birth_certificate_no', v_birth_cert_data.birth_certificate_no,
                'birth_registration_date', v_birth_cert_data.birth_reg_date
            );
            v_data_sources := array_append(v_data_sources, 'BTP');
        END IF;

        -- 4.2 Khai tử
        SELECT dc.death_certificate_no, dc.date_of_death, dc.place_of_death, dc.cause_of_death, dc.updated_at
        INTO v_death_cert_data
        FROM justice_mirror.death_certificate dc
        WHERE dc.citizen_id = v_row.citizen_id;
        IF FOUND THEN
            IF v_death_cert_data.updated_at > _last_sync_btp THEN
                  v_source_updated_btp := TRUE;
            END IF;
            v_citizen_updates := v_citizen_updates || jsonb_build_object(
                'death_status', 'Đã mất'::death_status, -- Suy ra trạng thái
                'death_certificate_no', v_death_cert_data.death_certificate_no,
                'date_of_death', v_death_cert_data.date_of_death,
                'place_of_death', v_death_cert_data.place_of_death,
                'cause_of_death', v_death_cert_data.cause_of_death
            );
            v_data_sources := array_append(v_data_sources, 'BTP');
        ELSE
            -- Nếu không có khai tử, mặc định là còn sống
             v_citizen_updates := v_citizen_updates || jsonb_build_object('death_status', 'Còn sống'::death_status);
        END IF;

        -- 4.3 Kết hôn (Lấy cuộc hôn nhân mới nhất chưa bị ghi ly hôn)
        -- Logic này phức tạp, cần join marriage và divorce
        -- Tạm thời lấy cuộc hôn nhân mới nhất làm ví dụ
        SELECT m.marriage_id, m.husband_id, m.wife_id, m.marriage_date, m.updated_at
        INTO v_marriage_data
        FROM justice_mirror.marriage m
        LEFT JOIN justice_mirror.divorce d ON m.marriage_id = d.marriage_id
        WHERE (m.husband_id = v_row.citizen_id OR m.wife_id = v_row.citizen_id)
          AND d.divorce_id IS NULL -- Chưa có bản ghi ly hôn
        ORDER BY m.marriage_date DESC, m.marriage_id DESC
        LIMIT 1;

         IF FOUND THEN
             IF v_marriage_data.updated_at > _last_sync_btp THEN
                   v_source_updated_btp := TRUE;
             END IF;
             v_citizen_updates := v_citizen_updates || jsonb_build_object(
                 'marital_status', 'Đã kết hôn'::marital_status,
                 'current_marriage_id', v_marriage_data.marriage_id,
                 'current_spouse_citizen_id', CASE WHEN v_marriage_data.husband_id = v_row.citizen_id THEN v_marriage_data.wife_id ELSE v_marriage_data.husband_id END,
                 'current_marriage_date', v_marriage_data.marriage_date
             );
              v_data_sources := array_append(v_data_sources, 'BTP');
         ELSE
            -- Nếu không có hôn nhân active, kiểm tra ly hôn gần nhất
            SELECT d.divorce_date, dv_m.updated_at INTO v_divorce_data
            FROM justice_mirror.divorce d
            JOIN justice_mirror.marriage dv_m ON d.marriage_id = dv_m.marriage_id
            WHERE (dv_m.husband_id = v_row.citizen_id OR dv_m.wife_id = v_row.citizen_id)
            ORDER BY d.divorce_date DESC, d.divorce_id DESC
            LIMIT 1;

            IF FOUND THEN
                 IF v_divorce_data.updated_at > _last_sync_btp THEN
                       v_source_updated_btp := TRUE;
                 END IF;
                 v_citizen_updates := v_citizen_updates || jsonb_build_object(
                     'marital_status', 'Đã ly hôn'::marital_status,
                     'last_divorce_date', v_divorce_data.divorce_date
                 );
                 v_data_sources := array_append(v_data_sources, 'BTP');
            ELSE
                 -- Nếu không kết hôn, không ly hôn -> Độc thân (trừ khi đã mất hoặc góa)
                 IF (v_citizen_updates->>'death_status') = 'Còn sống' THEN
                     v_citizen_updates := v_citizen_updates || jsonb_build_object('marital_status', 'Độc thân'::marital_status);
                 -- Logic xác định 'Góa' cần phức tạp hơn (kiểm tra vợ/chồng đã mất chưa)
                 END IF;
            END IF;
         END IF;


        -- Bước 5: Xác định thông tin phân vùng cuối cùng
        IF v_partition_info IS NULL OR v_partition_info.geographical_region IS NULL OR v_partition_info.province_id IS NULL OR v_partition_info.district_id IS NULL THEN
             RAISE WARNING '[sync.sync_citizens] Không thể xác định phân vùng hợp lệ cho citizen %. Bỏ qua.', v_row.citizen_id;
             CONTINUE; -- Bỏ qua nếu không xác định được phân vùng
        END IF;

        -- *** TODO: Bước 6: Xử lý xung đột dữ liệu (Merge Logic) ***
        -- Ví dụ: Ưu tiên thông tin từ BCA cho CCCD, Cư trú. Ưu tiên BTP cho Hộ tịch.
        -- Cần xây dựng quy tắc rõ ràng.

        -- Bước 7: Upsert vào bảng central.integrated_citizen
        v_sql := format($$
            INSERT INTO central.integrated_citizen (
                citizen_id, full_name, date_of_birth, place_of_birth, gender, ethnicity_id, religion_id, nationality_id, -- Thông tin cơ bản
                current_id_card_number, current_id_card_type, current_id_card_issue_date, current_id_card_expiry_date, current_id_card_issuing_authority_id, -- CCCD
                marital_status, death_status, date_of_death, place_of_death, cause_of_death, birth_certificate_no, birth_registration_date, death_certificate_no, current_marriage_id, current_spouse_citizen_id, current_marriage_date, last_divorce_date, -- Hộ tịch
                current_permanent_address_id, current_permanent_address_detail, current_permanent_registration_date, current_temporary_address_id, current_temporary_address_detail, current_temporary_registration_date, current_temporary_expiry_date, -- Cư trú
                education_level, occupation_id, occupation_detail, tax_code, social_insurance_no, health_insurance_no, -- Xã hội
                father_citizen_id, mother_citizen_id, -- Gia đình
                geographical_region, province_id, district_id, region_id, -- Phân vùng & Hành chính (region_id cần join để lấy)
                data_sources, last_synced_from_bca, last_synced_from_btp, last_integrated_at, record_status -- Metadata
            ) VALUES (
                %L, %L, %L::DATE, %L, %L::gender_type, %L::SMALLINT, %L::SMALLINT, %L::SMALLINT, -- Thông tin cơ bản
                %L, %L::card_type, %L::DATE, %L::DATE, %L::SMALLINT, -- CCCD
                %L::marital_status, %L::death_status, %L::DATE, %L, %L, %L, %L::DATE, %L, %L::INT, %L, %L::DATE, %L::DATE, -- Hộ tịch
                %L::INT, %L, %L::DATE, %L::INT, %L, %L::DATE, %L::DATE, -- Cư trú
                %L::education_level, %L::SMALLINT, %L, %L, %L, %L, -- Xã hội
                %L, %L, -- Gia đình
                %L, %L::INT, %L::INT, (SELECT region_id FROM reference.provinces WHERE province_id = %L)::SMALLINT, -- Phân vùng & Hành chính
                %L::TEXT[], %L::TIMESTAMPTZ, %L::TIMESTAMPTZ, %L::TIMESTAMPTZ, 'Active' -- Metadata
            )
            ON CONFLICT (citizen_id, geographical_region, province_id, district_id) DO UPDATE SET -- PK bao gồm cột phân vùng
                full_name = EXCLUDED.full_name,
                date_of_birth = EXCLUDED.date_of_birth,
                place_of_birth = EXCLUDED.place_of_birth,
                gender = EXCLUDED.gender,
                ethnicity_id = EXCLUDED.ethnicity_id,
                religion_id = EXCLUDED.religion_id,
                nationality_id = EXCLUDED.nationality_id,
                current_id_card_number = EXCLUDED.current_id_card_number,
                current_id_card_type = EXCLUDED.current_id_card_type,
                current_id_card_issue_date = EXCLUDED.current_id_card_issue_date,
                current_id_card_expiry_date = EXCLUDED.current_id_card_expiry_date,
                current_id_card_issuing_authority_id = EXCLUDED.current_id_card_issuing_authority_id,
                marital_status = EXCLUDED.marital_status,
                death_status = EXCLUDED.death_status,
                date_of_death = EXCLUDED.date_of_death,
                place_of_death = EXCLUDED.place_of_death,
                cause_of_death = EXCLUDED.cause_of_death,
                birth_certificate_no = EXCLUDED.birth_certificate_no,
                birth_registration_date = EXCLUDED.birth_registration_date,
                death_certificate_no = EXCLUDED.death_certificate_no,
                current_marriage_id = EXCLUDED.current_marriage_id,
                current_spouse_citizen_id = EXCLUDED.current_spouse_citizen_id,
                current_marriage_date = EXCLUDED.current_marriage_date,
                last_divorce_date = EXCLUDED.last_divorce_date,
                current_permanent_address_id = EXCLUDED.current_permanent_address_id,
                current_permanent_address_detail = EXCLUDED.current_permanent_address_detail,
                current_permanent_registration_date = EXCLUDED.current_permanent_registration_date,
                current_temporary_address_id = EXCLUDED.current_temporary_address_id,
                current_temporary_address_detail = EXCLUDED.current_temporary_address_detail,
                current_temporary_registration_date = EXCLUDED.current_temporary_registration_date,
                current_temporary_expiry_date = EXCLUDED.current_temporary_expiry_date,
                education_level = EXCLUDED.education_level,
                occupation_id = EXCLUDED.occupation_id,
                occupation_detail = EXCLUDED.occupation_detail,
                tax_code = EXCLUDED.tax_code,
                social_insurance_no = EXCLUDED.social_insurance_no,
                health_insurance_no = EXCLUDED.health_insurance_no,
                father_citizen_id = EXCLUDED.father_citizen_id,
                mother_citizen_id = EXCLUDED.mother_citizen_id,
                region_id = EXCLUDED.region_id,
                -- Cột phân vùng không nên thay đổi trong ON CONFLICT trừ khi di chuyển partition
                -- geographical_region = EXCLUDED.geographical_region,
                -- province_id = EXCLUDED.province_id,
                -- district_id = EXCLUDED.district_id,
                data_sources = EXCLUDED.data_sources,
                last_synced_from_bca = GREATEST(central.integrated_citizen.last_synced_from_bca, EXCLUDED.last_synced_from_bca),
                last_synced_from_btp = GREATEST(central.integrated_citizen.last_synced_from_btp, EXCLUDED.last_synced_from_btp),
                last_integrated_at = EXCLUDED.last_integrated_at,
                record_status = EXCLUDED.record_status,
                updated_at = now() -- Thêm cột này nếu bảng central có updated_at trigger
            WHERE
                -- Chỉ UPDATE nếu dữ liệu mới thực sự khác dữ liệu cũ HOẶC cột phân vùng thay đổi
                -- Cần kiểm tra cẩn thận các cột để tránh update không cần thiết
                ROW(central.integrated_citizen.full_name, central.integrated_citizen.date_of_birth, ..., central.integrated_citizen.last_integrated_at)
                IS DISTINCT FROM
                ROW(EXCLUDED.full_name, EXCLUDED.date_of_birth, ..., EXCLUDED.last_integrated_at)
                OR -- Nếu các cột phân vùng thay đổi, phải di chuyển dữ liệu
                (central.integrated_citizen.geographical_region IS DISTINCT FROM EXCLUDED.geographical_region OR
                 central.integrated_citizen.province_id IS DISTINCT FROM EXCLUDED.province_id OR
                 central.integrated_citizen.district_id IS DISTINCT FROM EXCLUDED.district_id);

            $$,
            v_row.citizen_id, v_citizen_data->>'full_name', v_citizen_data->>'date_of_birth', v_citizen_data->>'place_of_birth_detail', v_citizen_data->>'gender', v_citizen_data->>'ethnicity_id', v_citizen_data->>'religion_id', v_citizen_data->>'nationality_id',
            v_citizen_updates->>'current_id_card_number', v_citizen_updates->>'current_id_card_type', v_citizen_updates->>'current_id_card_issue_date', v_citizen_updates->>'current_id_card_expiry_date', v_citizen_updates->>'current_id_card_issuing_authority_id',
            v_citizen_updates->>'marital_status', v_citizen_updates->>'death_status', v_citizen_updates->>'date_of_death', v_citizen_updates->>'place_of_death', v_citizen_updates->>'cause_of_death', v_citizen_updates->>'birth_certificate_no', v_citizen_updates->>'birth_registration_date', v_citizen_updates->>'death_certificate_no', v_citizen_updates->>'current_marriage_id', v_citizen_updates->>'current_spouse_citizen_id', v_citizen_updates->>'current_marriage_date', v_citizen_updates->>'last_divorce_date',
            v_citizen_updates->>'current_permanent_address_id', v_citizen_updates->>'current_permanent_address_detail', v_citizen_updates->>'current_permanent_registration_date', v_citizen_updates->>'current_temporary_address_id', v_citizen_updates->>'current_temporary_address_detail', v_citizen_updates->>'current_temporary_registration_date', v_citizen_updates->>'current_temporary_expiry_date',
            v_citizen_data->>'education_level', v_citizen_data->>'occupation_id', v_citizen_data->>'occupation_detail', v_citizen_data->>'tax_code', v_citizen_data->>'social_insurance_no', v_citizen_data->>'health_insurance_no',
            v_citizen_data->>'father_citizen_id', v_citizen_data->>'mother_citizen_id',
            v_partition_info.geographical_region, v_partition_info.province_id, v_partition_info.district_id, v_partition_info.province_id, -- Lấy region_id từ province_id
            v_data_sources,
            CASE WHEN v_source_updated_bca THEN _current_sync_time ELSE NULL END,
            CASE WHEN v_source_updated_btp THEN _current_sync_time ELSE NULL END,
            _current_sync_time
        );

        -- Thực thi Upsert
        BEGIN
            EXECUTE v_sql;
            GET DIAGNOSTICS v_upserted_count = ROW_COUNT;
        EXCEPTION WHEN OTHERS THEN
             RAISE WARNING '[sync.sync_citizens] Lỗi khi UPSERT citizen %: %. SQL: %', v_row.citizen_id, SQLERRM, v_sql;
             -- Ghi lỗi vào đâu đó nếu cần
        END;

    END LOOP;

    RAISE NOTICE '[sync.sync_citizens] Hoàn thành xử lý % công dân. Số bản ghi được UPSERT: %', v_processed_count, v_upserted_count;
    RETURN v_upserted_count; -- Trả về số lượng đã xử lý
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sync.sync_citizens(TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) IS '[QLDCQG-TT] Đồng bộ dữ liệu công dân từ mirror vào bảng central.integrated_citizen (Cần hoàn thiện logic chi tiết, đặc biệt là xử lý xung đột và kiểm tra thay đổi trước khi UPDATE).';


-- Function: sync.sync_households (Cần hoàn thiện logic)
-- Description: Đồng bộ dữ liệu hộ khẩu từ mirror vào bảng central.integrated_household.
CREATE OR REPLACE FUNCTION sync.sync_households(
    _last_sync_btp TIMESTAMPTZ,
    _current_sync_time TIMESTAMPTZ
) RETURNS BIGINT AS $$
DECLARE
    v_upserted_count BIGINT := 0;
    v_processed_count BIGINT := 0;
    v_row RECORD;
    v_household_data RECORD; -- Sử dụng RECORD thay vì JSONB để dễ truy cập
    v_address_data RECORD;
    v_partition_info RECORD;
    v_sql TEXT;
BEGIN
    RAISE NOTICE '[sync.sync_households] Bắt đầu xử lý hộ khẩu thay đổi sau BTP: %', _last_sync_btp;

    CREATE TEMP TABLE temp_changed_households (household_id INT PRIMARY KEY) ON COMMIT DROP;

    -- Bước 1: Xác định các household_id cần cập nhật từ justice_mirror.household
    RAISE NOTICE '[sync.sync_households]   -> Tìm hộ khẩu thay đổi từ BTP...';
    INSERT INTO temp_changed_households (household_id)
    SELECT household_id FROM justice_mirror.household WHERE updated_at > _last_sync_btp
    ON CONFLICT (household_id) DO NOTHING;
    -- Thêm các nguồn thay đổi liên quan đến hộ khẩu nếu có (vd: household_member)
    INSERT INTO temp_changed_households (household_id)
    SELECT household_id FROM justice_mirror.household_member WHERE updated_at > _last_sync_btp
    ON CONFLICT (household_id) DO NOTHING;

    RAISE NOTICE '[sync.sync_households]   -> Tổng số hộ khẩu cần kiểm tra: %', (SELECT count(*) FROM temp_changed_households);


    -- Bước 2: Lặp qua từng household_id cần xử lý
    FOR v_row IN SELECT household_id FROM temp_changed_households LOOP
        v_processed_count := v_processed_count + 1;

        -- Bước 3: Thu thập dữ liệu hộ khẩu từ mirror
        SELECT h.* INTO v_household_data
        FROM justice_mirror.household h
        WHERE h.household_id = v_row.household_id;

        IF v_household_data IS NULL THEN
             RAISE WARNING '[sync.sync_households] Không tìm thấy thông tin household % trong mirror BTP. Bỏ qua.', v_row.household_id;
             CONTINUE;
        END IF;

        -- Bước 4: Lấy thông tin địa chỉ chi tiết và xác định phân vùng
        -- Dựa vào v_household_data.address_id liên kết đến public_security_mirror.address
        -- *** Logic này cần đảm bảo address_id trong BTP mapping đúng với address_id trong BCA ***
        SELECT a.address_detail, a.ward_id, a.district_id, a.province_id, a.geographical_region, p.region_id
        INTO v_address_data
        FROM public_security_mirror.address a
        JOIN reference.provinces p ON a.province_id = p.province_id
        WHERE a.address_id = v_household_data.address_id;

        IF NOT FOUND OR v_address_data.geographical_region IS NULL OR v_address_data.province_id IS NULL OR v_address_data.district_id IS NULL THEN
             RAISE WARNING '[sync.sync_households] Không thể xác định địa chỉ hoặc phân vùng cho household % (address_id: %). Bỏ qua.', v_row.household_id, v_household_data.address_id;
             CONTINUE;
        END IF;

        v_partition_info := ROW(
            v_address_data.geographical_region::TEXT,
            v_address_data.province_id::INTEGER,
            v_address_data.district_id::INTEGER
        );

        -- Bước 5: Upsert vào bảng central.integrated_household
         v_sql := format($$
            INSERT INTO central.integrated_household (
                source_system, source_household_id, household_book_no, head_of_household_citizen_id,
                address_detail, ward_id, registration_date, issuing_authority_id, household_type, status, notes,
                region_id, province_id, district_id, geographical_region, -- Cột phân vùng
                source_created_at, source_updated_at, integrated_at -- Metadata
            ) VALUES (
                'BTP', %L, %L, %L,
                %L, %L::INT, %L::DATE, %L::SMALLINT, %L::household_type, %L::household_status, %L,
                %L::SMALLINT, %L::INT, %L::INT, %L, -- Cột phân vùng
                %L::TIMESTAMPTZ, %L::TIMESTAMPTZ, %L::TIMESTAMPTZ
            )
            ON CONFLICT (source_system, source_household_id) DO UPDATE SET
                household_book_no = EXCLUDED.household_book_no,
                head_of_household_citizen_id = EXCLUDED.head_of_household_citizen_id,
                address_detail = EXCLUDED.address_detail, -- Cập nhật địa chỉ
                ward_id = EXCLUDED.ward_id,             -- Cập nhật ward_id
                registration_date = EXCLUDED.registration_date,
                issuing_authority_id = EXCLUDED.issuing_authority_id,
                household_type = EXCLUDED.household_type,
                status = EXCLUDED.status,
                notes = EXCLUDED.notes,
                region_id = EXCLUDED.region_id,             -- Cập nhật phân vùng
                province_id = EXCLUDED.province_id,
                district_id = EXCLUDED.district_id,
                geographical_region = EXCLUDED.geographical_region,
                source_updated_at = EXCLUDED.source_updated_at,
                integrated_at = EXCLUDED.integrated_at,
                updated_at = now() -- Nếu có trigger updated_at
            WHERE
                -- Chỉ UPDATE nếu có thay đổi thực sự (so sánh các cột quan trọng)
                ROW(central.integrated_household.household_book_no, central.integrated_household.head_of_household_citizen_id, central.integrated_household.address_detail, central.integrated_household.status, ...)
                IS DISTINCT FROM
                ROW(EXCLUDED.household_book_no, EXCLUDED.head_of_household_citizen_id, EXCLUDED.address_detail, EXCLUDED.status, ...)
                 OR -- Hoặc nếu phân vùng thay đổi
                 (central.integrated_household.geographical_region IS DISTINCT FROM EXCLUDED.geographical_region OR
                  central.integrated_household.province_id IS DISTINCT FROM EXCLUDED.province_id OR
                  central.integrated_household.district_id IS DISTINCT FROM EXCLUDED.district_id);
         $$,
            v_household_data.household_id::VARCHAR, v_household_data.household_book_no, v_household_data.head_of_household_id,
            v_address_data.address_detail, v_address_data.ward_id, v_household_data.registration_date, v_household_data.issuing_authority_id, v_household_data.household_type, v_household_data.status, v_household_data.notes,
            v_address_data.region_id, v_partition_info.province_id, v_partition_info.district_id, v_partition_info.geographical_region,
            v_household_data.created_at, v_household_data.updated_at, _current_sync_time
         );

         -- Thực thi Upsert
         BEGIN
             EXECUTE v_sql;
             GET DIAGNOSTICS v_upserted_count = ROW_COUNT;
         EXCEPTION WHEN OTHERS THEN
              RAISE WARNING '[sync.sync_households] Lỗi khi UPSERT household %: %. SQL: %', v_row.household_id, SQLERRM, v_sql;
              -- Ghi lỗi
         END;

    END LOOP;

     RAISE NOTICE '[sync.sync_households] Hoàn thành xử lý % hộ khẩu. Số bản ghi được UPSERT: %', v_processed_count, v_upserted_count;
     RETURN v_upserted_count;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sync.sync_households(TIMESTAMPTZ, TIMESTAMPTZ) IS '[QLDCQG-TT] Đồng bộ dữ liệu hộ khẩu từ mirror vào bảng central.integrated_household (Cần hoàn thiện logic chi tiết, đặc biệt là join địa chỉ và xử lý thay đổi).';


-- ============================================================================
-- IV. FUNCTIONS TIỆN ÍCH KHÁC
-- (Lấy từ national_citizen_central_server/partitioning/functions.sql cũ)
-- ============================================================================

\echo '--> 4. Định nghĩa các hàm tiện ích khác...'

-- Function: partitioning.generate_partition_report
-- Description: Tạo báo cáo về trạng thái các partition của các bảng được cấu hình phân vùng.
CREATE OR REPLACE FUNCTION partitioning.generate_partition_report(p_target_schema TEXT DEFAULT 'central')
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    partition_name TEXT,
    partition_expression TEXT,
    row_count BIGINT,
    total_size_bytes BIGINT,
    total_size_pretty TEXT,
    last_analyzed TIMESTAMP WITH TIME ZONE,
    derived_region TEXT,
    derived_province TEXT,
    derived_district TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH partition_info AS (
        SELECT
            nsp.nspname AS schema_name,
            parent.relname AS table_name,
            child.relname AS partition_name,
            pg_catalog.pg_get_expr(child.relpartbound, child.oid) AS partition_expression
        FROM pg_catalog.pg_inherits inh
        JOIN pg_catalog.pg_class child ON inh.inhrelid = child.oid
        JOIN pg_catalog.pg_class parent ON inh.inhparent = parent.oid
        JOIN pg_catalog.pg_namespace nsp ON parent.relnamespace = nsp.oid
        WHERE child.relkind = 'r'
          AND nsp.nspname = p_target_schema -- *** Lọc theo schema được truyền vào ***
    ),
    partition_stats AS (
        SELECT
            pi.schema_name,
            pi.table_name,
            pi.partition_name,
            pi.partition_expression,
            stat.n_live_tup + stat.n_dead_tup AS estimated_rows,
            pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name) AS total_size_bytes,
            pg_catalog.pg_size_pretty(pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name)) AS total_size_pretty,
            stat.last_analyze AS last_analyzed,
            CASE
                WHEN pi.partition_name ~ ('_' || partitioning.standardize_name('BAC') || '(?:_|$)') THEN 'Bắc'
                WHEN pi.partition_name ~ ('_' || partitioning.standardize_name('TRUNG') || '(?:_|$)') THEN 'Trung'
                WHEN pi.partition_name ~ ('_' || partitioning.standardize_name('NAM') || '(?:_|$)') THEN 'Nam'
                ELSE NULL
            END AS derived_region_name,
            substring(pi.partition_name from p_conf.table_name || '_(?:bac|trung|nam)_([a-z0-9_]+)(?:_[a-z0-9_]+)?$') AS derived_province_std_code,
            substring(pi.partition_name from p_conf.table_name || '_(?:bac|trung|nam)_[a-z0-9_]+_([a-z0-9_]+)$') AS derived_district_std_code
        FROM partition_info pi
        LEFT JOIN pg_catalog.pg_stat_all_tables stat ON stat.schemaname = pi.schema_name AND stat.relname = pi.partition_name
        JOIN partitioning.config p_conf ON p_conf.schema_name = pi.schema_name AND p_conf.table_name = pi.table_name AND p_conf.is_active = TRUE
    )
    SELECT
        ps.schema_name::TEXT,
        ps.table_name::TEXT,
        ps.partition_name::TEXT,
        ps.partition_expression::TEXT,
        ps.estimated_rows::BIGINT,
        ps.total_size_bytes::BIGINT,
        ps.total_size_pretty::TEXT,
        ps.last_analyzed::TIMESTAMP WITH TIME ZONE,
        ps.derived_region_name::TEXT,
        prov.province_name::TEXT,
        dist.district_name::TEXT
    FROM partition_stats ps
    LEFT JOIN reference.provinces prov ON partitioning.standardize_name(prov.province_code) = ps.derived_province_std_code
    LEFT JOIN reference.districts dist ON partitioning.standardize_name(dist.district_code) = ps.derived_district_std_code AND dist.province_id = prov.province_id
    ORDER BY ps.schema_name, ps.table_name, ps.derived_region_name, prov.province_name, dist.district_name, ps.partition_name;

EXCEPTION WHEN undefined_table THEN
     RAISE NOTICE 'Bảng partitioning.config hoặc reference tables chưa tồn tại/đầy đủ, báo cáo có thể không đầy đủ.';
     RETURN QUERY SELECT NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::BIGINT, NULL::BIGINT, NULL::TEXT, NULL::TIMESTAMP WITH TIME ZONE, NULL::TEXT, NULL::TEXT, NULL::TEXT WHERE FALSE;
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.generate_partition_report(TEXT) IS '[QLDCQG-TT] Tạo báo cáo về trạng thái các partition (kích thước, số dòng...) của các bảng được phân vùng trong schema được chỉ định (mặc định là central) của DB TT.';


-- Function: partitioning.archive_old_partitions (Placeholder)
-- Description: Hàm khung để xử lý việc tách và lưu trữ các partition cũ dựa trên thời gian.
CREATE OR REPLACE FUNCTION partitioning.archive_old_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_retention_period INTERVAL -- Ví dụ: INTERVAL '5 years'
) RETURNS VOID AS $$
DECLARE
    -- Khai báo các biến cần thiết
BEGIN
    RAISE NOTICE '[archive_old_partitions] Bắt đầu kiểm tra partition cũ cho %.% (lưu trữ %)...', p_schema, p_table, p_retention_period;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'ARCHIVE_START', 'Running', format('Bắt đầu kiểm tra partition cũ hơn %s', p_retention_period));

    -- >>> LOGIC CỤ THỂ CẦN TRIỂN KHAI Ở ĐÂY <<<
    -- Áp dụng cho bảng audit.audit_log của TT nếu cần.
    -- Logic sẽ tương tự như bên BCA/BTP.

    RAISE WARNING '[archive_old_partitions] Logic xử lý lưu trữ partition cũ cho %.% chưa được triển khai đầy đủ!', p_schema, p_table;

    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'ARCHIVE_COMPLETE', 'Skipped', 'Logic chưa triển khai đầy đủ.');
    RAISE NOTICE '[archive_old_partitions] Kết thúc kiểm tra (logic chưa đầy đủ) cho %.%.', p_schema, p_table;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.archive_old_partitions(TEXT, TEXT, INTERVAL) IS '[QLDCQG-TT] Placeholder - Xử lý tách và lưu trữ các partition cũ (cần triển khai logic cụ thể, ví dụ cho audit_log).';


-- ============================================================================
-- V. FUNCTIONS NGHIỆP VỤ RIÊNG CỦA TRUNG TÂM (NẾU CÓ)
-- ============================================================================
-- Hiện tại không có hàm nghiệp vụ riêng được định nghĩa trong các file đã cung cấp.
-- Nếu có nhu cầu, thêm các hàm vào đây. Ví dụ: các hàm API cung cấp dữ liệu tổng hợp.
-- \echo '--> 5. Định nghĩa các hàm nghiệp vụ TT (nếu có)...'


COMMIT;

\echo '*** HOÀN THÀNH ĐỊNH NGHĨA FUNCTIONS CHO DATABASE national_citizen_central_server ***'
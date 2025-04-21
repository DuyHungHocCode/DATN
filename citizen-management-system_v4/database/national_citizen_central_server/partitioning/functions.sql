-- File: national_citizen_central_server/partitioning/functions.sql
-- Description: Định nghĩa các function PL/pgSQL để hỗ trợ thiết lập và quản lý
--              phân vùng dữ liệu trong database Máy chủ Trung tâm (TT).
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Schema 'partitioning' và các bảng 'partitioning.config', 'partitioning.history'.
-- - Schema 'reference' và các bảng địa giới hành chính (regions, provinces, districts).
-- - Schema 'central' và các bảng cần phân vùng (integrated_citizen, integrated_household...).
-- - Extension 'unaccent'.
-- =============================================================================

\echo '--> Định nghĩa functions phân vùng cho national_citizen_central_server...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
\connect national_citizen_central_server

BEGIN;

-- Đảm bảo schema partitioning tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;

-- ============================================================================
-- I. FUNCTIONS HELPER (Hàm trợ giúp) - Tương tự như bên BCA/BTP
-- ============================================================================

-- Function: partitioning.log_history
-- Description: Ghi log vào bảng partitioning.history một cách nhất quán.
-- Arguments: _schema, _table, _partition, _action, _status, _details, _rows, _duration
-- Returns: VOID
-- ----------------------------------------------------------------------------
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
-- Arguments: _input_name TEXT
-- Returns: TEXT
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION partitioning.standardize_name(_input_name TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN lower(regexp_replace(unaccent(_input_name), '[^a-zA-Z0-9_]+', '_', 'g'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
COMMENT ON FUNCTION partitioning.standardize_name(TEXT) IS '[QLDCQG-TT] Chuẩn hóa tên (bỏ dấu, khoảng trắng->_, lowercase) dùng cho tên partition.';


-- Function: partitioning.pg_get_tabledef
-- Description: Lấy định nghĩa cột cơ bản của bảng (không bao gồm FK, CHECK phức tạp, default...)
--              Đủ dùng cho việc tạo bảng con phân vùng có cấu trúc tương tự bảng cha.
-- Arguments: p_schema_name TEXT, p_table_name TEXT
-- Returns: TEXT (chứa phần định nghĩa cột trong ngoặc đơn)
-- ----------------------------------------------------------------------------
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
-- II. FUNCTIONS SETUP PHÂN VÙNG CHÍNH - Tương tự như bên BCA/BTP
-- ============================================================================

-- Function: partitioning.setup_nested_partitioning
-- Description: Khởi tạo phân vùng lồng nhau theo Miền -> Tỉnh -> Quận/Huyện (hoặc chỉ Miền -> Tỉnh).
--              Tự động tạo các partition con dựa trên dữ liệu bảng tham chiếu.
--              Tự động di chuyển dữ liệu từ bảng gốc (nếu chưa phân vùng) sang bảng đã phân vùng.
-- Arguments: p_schema, p_table, p_region_column, p_province_column, p_district_column, p_include_district (DEFAULT TRUE)
-- Returns: BOOLEAN (TRUE nếu thành công)
-- Requires: Bảng gốc tồn tại, các bảng reference.* có dữ liệu, bảng partitioning.* tồn tại.
-- ----------------------------------------------------------------------------
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
--              Hữu ích khi thông tin phân vùng của bản ghi tích hợp thay đổi.
--              Lưu ý: Hàm này thực hiện DELETE và INSERT, cần cẩn thận về transaction và hiệu năng.
-- Arguments: p_schema, p_table, p_key_column, p_key_value, p_new_region, p_new_province, p_new_district
-- Returns: BOOLEAN (TRUE nếu thành công)
-- ----------------------------------------------------------------------------
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
--              của một bảng cha đã phân vùng, nếu index đó chưa tồn tại.
-- Arguments: p_schema, p_table, p_index_definitions (Mảng các câu lệnh CREATE INDEX mẫu)
-- Returns: VOID
-- ----------------------------------------------------------------------------
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
-- III. FUNCTIONS TIỆN ÍCH KHÁC (Nếu cần) - Tương tự như bên BCA/BTP
-- ============================================================================

-- Function: partitioning.generate_partition_report
-- Description: Tạo báo cáo về trạng thái các partition của các bảng được cấu hình phân vùng.
-- Arguments: p_target_schema TEXT DEFAULT 'central' -- Schema mặc định để báo cáo
-- Returns: TABLE (schema_name, table_name, partition_name, row_count, total_size_bytes, total_size_pretty, last_analyzed, region, province, district)
-- Requires: Bảng partitioning.config, các bảng reference.*, extension pg_stat_statements (cho last_analyzed).
-- ----------------------------------------------------------------------------
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
--              Cần được triển khai cụ thể nếu có bảng phân vùng theo thời gian (vd: audit_log).
-- Arguments: p_schema, p_table, p_retention_period
-- Returns: VOID
-- ----------------------------------------------------------------------------
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
    -- (Tương tự như bên BCA/BTP, áp dụng cho bảng audit_log của TT nếu cần)

    RAISE WARNING '[archive_old_partitions] Logic xử lý lưu trữ partition cũ cho %.% chưa được triển khai đầy đủ!', p_schema, p_table;

    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'ARCHIVE_COMPLETE', 'Skipped', 'Logic chưa triển khai đầy đủ.');
    RAISE NOTICE '[archive_old_partitions] Kết thúc kiểm tra (logic chưa đầy đủ) cho %.%.', p_schema, p_table;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.archive_old_partitions(TEXT, TEXT, INTERVAL) IS '[QLDCQG-TT] Placeholder - Xử lý tách và lưu trữ các partition cũ (cần triển khai logic cụ thể, ví dụ cho audit_log).';

COMMIT;

\echo '-> Hoàn thành định nghĩa functions phân vùng cho national_citizen_central_server.'

-- TODO (Các bước tiếp theo):
-- 1. Execute Setup: Tạo file `execute_setup.sql` trong cùng thư mục để gọi các hàm setup (vd: `setup_nested_partitioning`) cho các bảng cụ thể trong DB TT (integrated_citizen, integrated_household).
-- 2. Index Creation: Gọi hàm `create_partition_indexes` trong `execute_setup.sql` sau khi partition được tạo.
-- 3. Maintenance: Lập lịch (qua pg_cron hoặc Airflow) để chạy các hàm bảo trì nếu cần (vd: `archive_old_partitions` cho audit_log).
-- 4. Permissions: Cấp quyền EXECUTE trên các hàm này cho role quản trị hoặc role thực thi phân vùng (`sync_user` có thể cần quyền EXECUTE trên `move_data_between_partitions` nếu logic đồng bộ cần di chuyển dữ liệu).
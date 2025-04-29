-- File: ministry_of_justice/03_functions.sql
-- Description: Định nghĩa TẤT CẢ các functions/procedures PL/pgSQL
--              cho database Bộ Tư pháp (BTP), bao gồm cả các hàm phân vùng.
-- Version: 2.0 (Cải tiến với xử lý lỗi tốt hơn)
--
-- Dependencies:
-- - Schema 'partitioning' và các bảng 'partitioning.config', 'partitioning.history'.
-- - Schema 'reference' và các bảng địa giới hành chính (regions, provinces, districts).
-- - Schema 'justice' và các bảng cần phân vùng (birth_certificate, marriage...).
-- - Extension 'unaccent'.
-- =============================================================================

\echo '*** BẮT ĐẦU ĐỊNH NGHĨA FUNCTIONS CHO DATABASE ministry_of_justice ***'
\connect ministry_of_justice

-- Đảm bảo schema partitioning tồn tại (phòng trường hợp chạy file riêng lẻ)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'partitioning') THEN
        CREATE SCHEMA partitioning;
        RAISE NOTICE 'Schema partitioning đã được tạo.';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Không thể kiểm tra/tạo schema partitioning: %', SQLERRM;
END;
$$;

BEGIN;

-- ============================================================================
-- I. FUNCTIONS HỖ TRỢ PHÂN VÙNG (PARTITIONING HELPER FUNCTIONS)
-- ============================================================================

\echo '--> Định nghĩa các hàm hỗ trợ phân vùng...'

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
DECLARE
    v_err_context TEXT;
BEGIN
    -- Kiểm tra tham số đầu vào không được NULL
    IF _schema IS NULL OR _table IS NULL OR _action IS NULL THEN
        RAISE WARNING '[partitioning.log_history] Tham số đầu vào không được NULL (_schema, _table, _action)';
        RETURN;
    END IF;

    -- Xử lý partition name nếu NULL
    IF _partition IS NULL THEN
        _partition := _table;
    END IF;

    -- Thử chèn log vào bảng history
    BEGIN
        INSERT INTO partitioning.history (
            schema_name, table_name, partition_name, action, status, details, affected_rows, duration_ms
        ) VALUES (
            _schema, _table, _partition, _action, _status, _details, _rows, _duration
        );
    EXCEPTION 
        WHEN undefined_table THEN
            RAISE NOTICE '[partitioning.log_history] Bảng partitioning.history không tồn tại, thử tạo bảng...';
            
            -- Thử tạo bảng history nếu chưa tồn tại
            BEGIN
                CREATE TABLE IF NOT EXISTS partitioning.history (
                    history_id BIGSERIAL PRIMARY KEY,
                    schema_name VARCHAR(100) NOT NULL,
                    table_name VARCHAR(100) NOT NULL,
                    partition_name VARCHAR(200) NOT NULL,
                    action VARCHAR(50) NOT NULL,
                    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    status VARCHAR(20) DEFAULT 'Success',
                    affected_rows BIGINT,
                    duration_ms BIGINT,
                    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
                    details TEXT
                );
                
                -- Thử insert lại sau khi tạo bảng
                INSERT INTO partitioning.history (
                    schema_name, table_name, partition_name, action, status, details, affected_rows, duration_ms
                ) VALUES (
                    _schema, _table, _partition, _action, _status, _details, _rows, _duration
                );
                RAISE NOTICE '[partitioning.log_history] Đã tạo bảng và ghi log thành công';
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
                RAISE WARNING '[partitioning.log_history] Không thể tạo bảng history: % (%)', SQLERRM, v_err_context;
            END;
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
            RAISE WARNING '[partitioning.log_history] Lỗi khi ghi log: % (%)', SQLERRM, v_err_context;
    END;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.log_history(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BIGINT, BIGINT) IS '[QLDCQG-BTP] Hàm tiện ích để ghi log vào bảng partitioning.history.';


-- Function: partitioning.standardize_name
-- Description: Chuẩn hóa tên (loại bỏ dấu, khoảng trắng, chuyển thành chữ thường) để tạo tên partition.
CREATE OR REPLACE FUNCTION partitioning.standardize_name(_input_name TEXT)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    -- Kiểm tra tham số đầu vào không được NULL
    IF _input_name IS NULL THEN
        RAISE WARNING '[partitioning.standardize_name] Tham số đầu vào NULL, trả về chuỗi rỗng';
        RETURN '';
    END IF;

    -- Kiểm tra nếu extension unaccent chưa được cài đặt
    BEGIN
        -- Cần extension unaccent
        result := lower(regexp_replace(unaccent(_input_name), '[^a-zA-Z0-9_]+', '_', 'g'));
        
        -- Đảm bảo không có dấu gạch dưới ở đầu hoặc cuối
        result := trim(both '_' from result);
        
        -- Đảm bảo kết quả không rỗng
        IF result = '' THEN
            result := 'unnamed_' || md5(_input_name);
        END IF;
        
        RETURN result;
    EXCEPTION WHEN undefined_function THEN
        RAISE WARNING '[partitioning.standardize_name] Extension unaccent chưa được cài đặt, sử dụng phương pháp thay thế';
        -- Phương pháp thay thế không dùng unaccent
        result := lower(regexp_replace(_input_name, '[^a-zA-Z0-9_]+', '_', 'g'));
        result := trim(both '_' from result);
        
        IF result = '' THEN
            result := 'unnamed_' || md5(_input_name);
        END IF;
        
        RETURN result;
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
COMMENT ON FUNCTION partitioning.standardize_name(TEXT) IS '[QLDCQG-BTP] Chuẩn hóa tên (bỏ dấu, khoảng trắng->_, lowercase) dùng cho tên partition.';


-- Function: partitioning.pg_get_tabledef
-- Description: Lấy định nghĩa cột cơ bản của bảng để tạo bảng con phân vùng.
CREATE OR REPLACE FUNCTION partitioning.pg_get_tabledef(p_schema_name TEXT, p_table_name TEXT)
RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_record RECORD;
    v_column_defs TEXT[] := '{}';
    v_partition_key_cols TEXT[];
    v_table_exists BOOLEAN;
    v_err_context TEXT;
BEGIN
    -- Kiểm tra bảng tồn tại
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = p_schema_name AND table_name = p_table_name
    ) INTO v_table_exists;
    
    IF NOT v_table_exists THEN
        RAISE WARNING '[partitioning.pg_get_tabledef] Bảng %.% không tồn tại', p_schema_name, p_table_name;
        RETURN NULL;
    END IF;

    -- Lấy danh sách cột khóa phân vùng của bảng cha (nếu có)
    BEGIN
        SELECT string_to_array(pg_get_partition_keydef(c.oid), ', ')
        INTO v_partition_key_cols
        FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = p_schema_name AND c.relname = p_table_name AND c.relkind = 'p';

        v_partition_key_cols := COALESCE(v_partition_key_cols, '{}');
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RAISE WARNING '[partitioning.pg_get_tabledef] Lỗi khi lấy partition key: % (%)', SQLERRM, v_err_context;
        v_partition_key_cols := '{}';
    END;

    -- Lấy thông tin cột từ bảng
    BEGIN
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
                -- Xử lý DEFAULT an toàn hơn
                CASE 
                    WHEN v_column_record.column_default IS NOT NULL AND v_column_record.column_default !~* 'nextval' AND v_column_record.column_default !~* 'function' THEN ' DEFAULT ' || v_column_record.column_default 
                    ELSE '' 
                END
            );
        END LOOP;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RAISE WARNING '[partitioning.pg_get_tabledef] Lỗi khi lấy định nghĩa cột: % (%)', SQLERRM, v_err_context;
        RETURN NULL;
    END;

    -- Kiểm tra ít nhất một cột được xử lý
    IF array_length(v_column_defs, 1) < 1 THEN
        RAISE WARNING '[partitioning.pg_get_tabledef] Không thể lấy cột nào từ bảng %.%', p_schema_name, p_table_name;
        RETURN NULL;
    END IF;

    -- Tạo câu lệnh DDL cơ bản
    v_table_ddl := E'(\n    ' || array_to_string(v_column_defs, E',\n    ') || E'\n)';

    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.pg_get_tabledef(TEXT, TEXT) IS '[QLDCQG-BTP] Lấy định nghĩa cột cơ bản của bảng (trừ cột khóa phân vùng cha) để tạo partition con.';


-- ============================================================================
-- II. FUNCTIONS SETUP VÀ QUẢN LÝ PHÂN VÙNG
-- ============================================================================

\echo '--> Định nghĩa các hàm setup và quản lý phân vùng...'

-- Function: partitioning.setup_nested_partitioning
-- Description: Thiết lập phân vùng lồng nhau theo Miền -> Tỉnh -> Quận/Huyện (hoặc chỉ Miền -> Tỉnh).
CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT,
    p_table TEXT,
    p_region_column TEXT,       -- Cột chứa tên Miền (vd: geographical_region)
    p_province_column TEXT,     -- Cột chứa ID Tỉnh (vd: province_id)
    p_district_column TEXT,     -- Cột chứa ID Huyện (vd: district_id)
    p_include_district BOOLEAN DEFAULT TRUE, -- TRUE: Phân vùng 3 cấp, FALSE: 2 cấp (đến Tỉnh)
    p_batch_size INTEGER DEFAULT 10000     -- Kích thước batch cho di chuyển dữ liệu
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
    v_row_count BIGINT := 0;
    v_batch_count BIGINT := 0;
    v_total_rows BIGINT := 0;
    v_processed_rows BIGINT := 0;
    v_start_time TIMESTAMPTZ;
    v_batch_start_time TIMESTAMPTZ;
    v_duration BIGINT;
    v_err_context TEXT;
    v_reference_tables_exist BOOLEAN;
BEGIN
    v_start_time := clock_timestamp();
    RAISE NOTICE '[%] Bắt đầu setup_nested_partitioning cho %.% (Cấp huyện: %)...', v_start_time, p_schema, p_table, p_include_district;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Running', format('Bắt đầu phân vùng đa cấp (Cấp huyện: %s)', p_include_district));

    -- Kiểm tra tham số đầu vào
    IF p_schema IS NULL OR p_table IS NULL OR p_region_column IS NULL OR p_province_column IS NULL THEN
        RAISE WARNING '[%] Lỗi: Các tham số cơ bản không được NULL (schema, table, region_column, province_column)', clock_timestamp();
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', 'Các tham số cơ bản không được NULL');
        RETURN FALSE;
    END IF;

    -- Kiểm tra bảng reference tồn tại
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'reference' AND table_name = 'regions'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'reference' AND table_name = 'provinces'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema = 'reference' AND table_name = 'districts'
    ) INTO v_reference_tables_exist;

    IF NOT v_reference_tables_exist THEN
        RAISE WARNING '[%] Lỗi: Bảng tham chiếu (regions, provinces, districts) không tồn tại.', clock_timestamp();
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', 'Bảng tham chiếu không tồn tại');
        RETURN FALSE;
    END IF;

    -- Kiểm tra bảng gốc tồn tại
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = p_table)
    INTO v_old_table_exists;

    IF NOT v_old_table_exists THEN
        RAISE WARNING '[%] Lỗi: Bảng %.% không tồn tại.', clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', format('Bảng %.% không tồn tại.', p_schema, p_table));
        RETURN FALSE;
    END IF;

    -- Kiểm tra các cột tồn tại
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = p_schema AND table_name = p_table AND column_name = p_region_column
    ) THEN
        RAISE WARNING '[%] Lỗi: Cột % không tồn tại trong bảng %.%.', clock_timestamp(), p_region_column, p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', format('Cột %s không tồn tại', p_region_column));
        RETURN FALSE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = p_schema AND table_name = p_table AND column_name = p_province_column
    ) THEN
        RAISE WARNING '[%] Lỗi: Cột % không tồn tại trong bảng %.%.', clock_timestamp(), p_province_column, p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', format('Cột %s không tồn tại', p_province_column));
        RETURN FALSE;
    END IF;

    IF p_include_district AND p_district_column IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = p_schema AND table_name = p_table AND column_name = p_district_column
    ) THEN
        RAISE WARNING '[%] Lỗi: Cột % không tồn tại trong bảng %.%.', clock_timestamp(), p_district_column, p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', format('Cột %s không tồn tại', p_district_column));
        RETURN FALSE;
    END IF;

    -- Kiểm tra bảng gốc đã được phân vùng chưa
    SELECT EXISTS (
        SELECT 1 FROM pg_catalog.pg_partitioned_table pt 
        JOIN pg_catalog.pg_class c ON pt.partrelid = c.oid 
        JOIN pg_namespace n ON c.relnamespace = n.oid 
        WHERE n.nspname = p_schema AND c.relname = p_table
    ) INTO v_is_already_partitioned;

    -- Lấy định nghĩa cột cơ bản của bảng gốc
    v_ddl_columns := partitioning.pg_get_tabledef(p_schema, p_table);
    IF v_ddl_columns IS NULL OR v_ddl_columns = '()' THEN
         RAISE WARNING '[%] Lỗi: Không thể lấy định nghĩa cột cho %.%.', clock_timestamp(), p_schema, p_table;
         PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', 'Không thể lấy định nghĩa cột.');
         RETURN FALSE;
    END IF;

    -- 1. Tạo bảng gốc phân vùng mới (nếu chưa tồn tại hoặc bảng cũ chưa phân vùng)
    IF NOT v_is_already_partitioned THEN
        BEGIN
            -- Đảm bảo tên bảng tạm thời không bị trùng
            EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', p_schema, v_root_table_name);
            v_sql := format('
                CREATE TABLE %I.%I %s
                PARTITION BY LIST (%I);
            ', p_schema, v_root_table_name, v_ddl_columns, p_region_column);
            RAISE NOTICE '[%] Tạo bảng gốc phân vùng tạm: %', clock_timestamp(), v_sql;
            EXECUTE v_sql;
            PERFORM partitioning.log_history(p_schema, p_table, v_root_table_name, 'CREATE_PARTITION', 'Success', 'Tạo bảng gốc phân vùng tạm thời.');
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
            RAISE WARNING '[%] Lỗi khi tạo bảng gốc phân vùng: % (%)', clock_timestamp(), SQLERRM, v_err_context;
            PERFORM partitioning.log_history(p_schema, p_table, v_root_table_name, 'CREATE_PARTITION', 'Failed', format('Lỗi: %s', SQLERRM));
            RETURN FALSE;
        END;
    ELSE
        v_root_table_name := p_table; -- Nếu đã phân vùng rồi thì dùng chính tên bảng đó
        RAISE NOTICE '[%] Bảng %.% đã được phân vùng. Bỏ qua tạo bảng gốc mới.', clock_timestamp(), p_schema, p_table;
    END IF;

    -- 2. Lặp qua từng Miền -> Tỉnh -> Huyện để tạo các partition con
    BEGIN
        FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions ORDER BY region_id LOOP
            v_region_std_name := partitioning.standardize_name(v_regions.region_code);
            v_partition_name_l1 := p_table || '_' || v_region_std_name;

            -- Tạo partition cấp 1 (Miền) nếu chưa có
            IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l1) THEN
                BEGIN
                    v_sql := format('
                        CREATE TABLE %I.%I PARTITION OF %I.%I
                        FOR VALUES IN (%L) PARTITION BY LIST (%I);
                    ', p_schema, v_partition_name_l1, p_schema, v_root_table_name, v_regions.region_name, p_province_column);
                    RAISE NOTICE '[%] Tạo partition L1: %', clock_timestamp(), v_sql;
                    EXECUTE v_sql;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l1, 'CREATE_PARTITION', 'Success', format('Partition cấp 1 cho miền %s', v_regions.region_name));
                EXCEPTION WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
                    RAISE WARNING '[%] Lỗi khi tạo partition cấp 1 (Miền): % (%)', clock_timestamp(), SQLERRM, v_err_context;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l1, 'CREATE_PARTITION', 'Failed', format('Lỗi tạo partition miền: %s', SQLERRM));
                    -- Tiếp tục với miền khác thay vì dừng lại hoàn toàn
                    CONTINUE;
                END;
            END IF;

            -- Lặp qua Tỉnh
            FOR v_provinces IN SELECT province_id, province_code, province_name FROM reference.provinces WHERE region_id = v_regions.region_id ORDER BY province_id LOOP
                v_province_std_name := partitioning.standardize_name(v_provinces.province_code);
                v_partition_name_l2 := v_partition_name_l1 || '_' || v_province_std_name;

                IF p_include_district AND p_district_column IS NOT NULL THEN -- Nếu phân vùng đến cấp Huyện
                     -- Tạo partition cấp 2 (Tỉnh) nếu chưa có, khai báo phân vùng tiếp theo Huyện
                    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l2) THEN
                        BEGIN
                            v_sql := format('
                                CREATE TABLE %I.%I PARTITION OF %I.%I
                                FOR VALUES IN (%L) PARTITION BY LIST (%I);
                            ', p_schema, v_partition_name_l2, p_schema, v_partition_name_l1, v_provinces.province_id, p_district_column);
                            RAISE NOTICE '[%] Tạo partition L2: %', clock_timestamp(), v_sql;
                            EXECUTE v_sql;
                            PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Success', format('Partition cấp 2 cho tỉnh %s', v_provinces.province_name));
                        EXCEPTION WHEN OTHERS THEN
                            GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
                            RAISE WARNING '[%] Lỗi khi tạo partition cấp 2 (Tỉnh): % (%)', clock_timestamp(), SQLERRM, v_err_context;
                            PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Failed', format('Lỗi tạo partition tỉnh: %s', SQLERRM));
                            CONTINUE; -- Tiếp tục với tỉnh khác
                        END;
                     END IF;

                     -- Lặp qua Huyện
                     FOR v_districts IN SELECT district_id, district_code, district_name FROM reference.districts WHERE province_id = v_provinces.province_id ORDER BY district_id LOOP
                         v_district_std_name := partitioning.standardize_name(v_districts.district_code);
                         v_partition_name_l3 := v_partition_name_l2 || '_' || v_district_std_name;

                         -- Tạo partition cấp 3 (Huyện) nếu chưa có
                         IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l3) THEN
                             BEGIN
                                 v_sql := format('
                                     CREATE TABLE %I.%I PARTITION OF %I.%I
                                     FOR VALUES IN (%L);
                                 ', p_schema, v_partition_name_l3, p_schema, v_partition_name_l2, v_districts.district_id);
                                 RAISE NOTICE '[%] Tạo partition L3: %', clock_timestamp(), v_sql;
                                 EXECUTE v_sql;
                                 PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l3, 'CREATE_PARTITION', 'Success', format('Partition cấp 3 cho huyện %s', v_districts.district_name));
                             EXCEPTION WHEN OTHERS THEN
                                 GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
                                 RAISE WARNING '[%] Lỗi khi tạo partition cấp 3 (Huyện): % (%)', clock_timestamp(), SQLERRM, v_err_context;
                                 PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l3, 'CREATE_PARTITION', 'Failed', format('Lỗi tạo partition huyện: %s', SQLERRM));
                                 CONTINUE; -- Tiếp tục với huyện khác
                             END;
                         END IF;
                     END LOOP; -- Hết vòng lặp Huyện
                ELSE -- Nếu chỉ phân vùng đến cấp Tỉnh
                     -- Tạo partition cấp 2 (Tỉnh) nếu chưa có, đây là cấp cuối
                     IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l2) THEN
                         BEGIN
                             v_sql := format('
                                 CREATE TABLE %I.%I PARTITION OF %I.%I
                                 FOR VALUES IN (%L);
                             ', p_schema, v_partition_name_l2, p_schema, v_partition_name_l1, v_provinces.province_id);
                             RAISE NOTICE '[%] Tạo partition L2 (cuối): %', clock_timestamp(), v_sql;
                             EXECUTE v_sql;
                             PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Success', format('Partition cấp 2 (cuối) cho tỉnh %s', v_provinces.province_name));
                         EXCEPTION WHEN OTHERS THEN
                             GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
                             RAISE WARNING '[%] Lỗi khi tạo partition cấp 2 (cuối): % (%)', clock_timestamp(), SQLERRM, v_err_context;
                             PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Failed', format('Lỗi tạo partition tỉnh (cuối): %s', SQLERRM));
                             CONTINUE; -- Tiếp tục với tỉnh khác
                         END;
                     END IF;
                END IF; -- Hết if p_include_district
            END LOOP; -- Hết vòng lặp Tỉnh
        END LOOP; -- Hết vòng lặp Miền
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RAISE WARNING '[%] Lỗi không mong muốn khi tạo partition: % (%)', clock_timestamp(), SQLERRM, v_err_context;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_PARTITION', 'Failed', format('Lỗi không mong muốn: %s', SQLERRM));
        RETURN FALSE;
    END;

    -- 3. Di chuyển dữ liệu và đổi tên (chỉ thực hiện nếu bảng gốc chưa phân vùng)
    IF NOT v_is_already_partitioned THEN
        RAISE NOTICE '[%] Bảng %.% chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', clock_timestamp(), p_schema, p_table;
        
        BEGIN
            -- Khóa bảng gốc để tránh ghi dữ liệu mới trong quá trình di chuyển
            v_sql := format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE', p_schema, p_table);
            RAISE NOTICE '[%] Khóa bảng gốc: %', clock_timestamp(), v_sql;
            EXECUTE v_sql;
            
            -- Lấy tổng số dòng cần di chuyển
            EXECUTE format('SELECT COUNT(*) FROM %I.%I', p_schema, p_table) INTO v_total_rows;
            RAISE NOTICE '[%] Tổng số dòng cần di chuyển: %', clock_timestamp(), v_total_rows;

            -- Thiết lập tối ưu tạm thời cho việc batch insert
            SET LOCAL work_mem = '128MB';
            SET LOCAL maintenance_work_mem = '512MB';
            
            -- Di chuyển dữ liệu theo batch để tránh transaction quá lớn
            v_processed_rows := 0;
            
            WHILE v_processed_rows < v_total_rows LOOP
                v_batch_start_time := clock_timestamp();
                v_sql := format('
                    WITH batch AS (
                        SELECT * FROM %I.%I 
                        ORDER BY %s 
                        LIMIT %s OFFSET %s
                    )
                    INSERT INTO %I.%I SELECT * FROM batch;
                ', 
                p_schema, p_table, 
                CASE 
                    WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = p_schema AND table_name = p_table AND column_name = 'created_at')
                    THEN 'created_at'
                    ELSE (SELECT column_name FROM information_schema.columns WHERE table_schema = p_schema AND table_name = p_table AND ordinal_position = 1)
                END,
                p_batch_size, v_processed_rows,
                p_schema, v_root_table_name);
                
                EXECUTE v_sql;
                GET DIAGNOSTICS v_batch_count = ROW_COUNT;
                
                v_processed_rows := v_processed_rows + v_batch_count;
                v_row_count := v_row_count + v_batch_count;
                
                RAISE NOTICE '[%] Batch #%: Di chuyển % dòng (tổng: % / %)', 
                    clock_timestamp(), 
                    CEIL(v_processed_rows::numeric / p_batch_size), 
                    v_batch_count, 
                    v_processed_rows, 
                    v_total_rows;
                    
                -- Ghi log tiến độ
                PERFORM partitioning.log_history(
                    p_schema, p_table, v_root_table_name, 
                    'MOVE_DATA', 'Running', 
                    format('Batch #%s: %s/%s dòng (%s%%)', 
                        CEIL(v_processed_rows::numeric / p_batch_size),
                        v_processed_rows, 
                        v_total_rows, 
                        ROUND((v_processed_rows::numeric / GREATEST(v_total_rows, 1)) * 100, 2)
                    ),
                    v_batch_count,
                    EXTRACT(EPOCH FROM (clock_timestamp() - v_batch_start_time)) * 1000
                );

                -- Dừng nếu batch trống
                EXIT WHEN v_batch_count = 0;
                
                -- COMMIT sau mỗi batch để giảm lock và ghi transaction log
                -- COMMIT;
            END LOOP;
            
            -- Kiểm tra dữ liệu đã di chuyển đầy đủ
            EXECUTE format('SELECT COUNT(*) FROM %I.%I', p_schema, v_root_table_name) INTO v_batch_count;
            IF v_batch_count <> v_total_rows THEN
                RAISE WARNING '[%] Cảnh báo: Số dòng đã di chuyển (%) khác với số dòng ban đầu (%)', 
                    clock_timestamp(), v_batch_count, v_total_rows;
                PERFORM partitioning.log_history(p_schema, p_table, v_root_table_name, 'MOVE_DATA', 'Warning', 
                    format('Số dòng không khớp: %s di chuyển, %s ban đầu', v_batch_count, v_total_rows));
            END IF;

            -- Đổi tên bảng cũ và bảng mới
            EXECUTE format('ALTER TABLE IF EXISTS %I.%I RENAME TO %I', p_schema, p_table, v_old_table_name);
            RAISE NOTICE '[%] Đổi tên bảng cũ thành %', clock_timestamp(), v_old_table_name;
            
            EXECUTE format('ALTER TABLE %I.%I RENAME TO %I', p_schema, v_root_table_name, p_table);
            RAISE NOTICE '[%] Đổi tên bảng mới thành %', clock_timestamp(), p_table;
            
            v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
            PERFORM partitioning.log_history(p_schema, p_table, p_table, 'REPARTITIONED', 'Success', 
                format('Đã di chuyển %s dòng và đổi tên thành bảng phân vùng.', v_row_count), 
                v_row_count, v_duration);
                
            RAISE NOTICE '[%] Hoàn tất di chuyển và đổi tên cho %.%. Thời gian: %ms, Số dòng: %', 
                clock_timestamp(), p_schema, p_table, v_duration, v_row_count;
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
            RAISE WARNING '[%] Lỗi khi di chuyển dữ liệu hoặc đổi tên bảng: % (%)', 
                clock_timestamp(), SQLERRM, v_err_context;
            PERFORM partitioning.log_history(p_schema, p_table, p_table, 'REPARTITIONED', 'Failed', 
                format('Lỗi: %s (%s)', SQLERRM, v_err_context), v_processed_rows);
            RETURN FALSE;
        END;
    END IF;

    -- 4. Ghi hoặc cập nhật cấu hình vào partitioning.config
    BEGIN
        -- Kiểm tra bảng config tồn tại chưa
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                      WHERE table_schema = 'partitioning' AND table_name = 'config') THEN
            CREATE TABLE IF NOT EXISTS partitioning.config (
                config_id SERIAL PRIMARY KEY,
                schema_name VARCHAR(100) NOT NULL,
                table_name VARCHAR(100) NOT NULL,
                partition_type VARCHAR(20) NOT NULL,
                partition_columns TEXT NOT NULL,
                partition_interval VARCHAR(100),
                retention_period VARCHAR(100),
                premake INTEGER DEFAULT 4,
                is_active BOOLEAN DEFAULT TRUE,
                use_pg_partman BOOLEAN DEFAULT FALSE,
                notes TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT uq_partition_config UNIQUE (schema_name, table_name)
            );
            RAISE NOTICE '[%] Đã tạo bảng partitioning.config mới.', clock_timestamp();
        END IF;
        
        INSERT INTO partitioning.config (schema_name, table_name, partition_type, partition_columns, is_active, updated_at)
        VALUES (p_schema, p_table, 'NESTED',
            CASE WHEN p_include_district AND p_district_column IS NOT NULL
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
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RAISE WARNING '[%] Không thể ghi/cập nhật cấu hình: % (%)', 
            clock_timestamp(), SQLERRM, v_err_context;
        -- Không return FALSE vì lỗi này không nghiêm trọng
    END;

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Hoàn thành setup_nested_partitioning cho %.% sau % ms.', 
        clock_timestamp(), p_schema, p_table, v_duration;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Success', 
        format('Hoàn thành phân vùng đa cấp sau %s ms', v_duration), v_row_count, v_duration);

    RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE WARNING '[%] Lỗi khi thực hiện setup_nested_partitioning cho %.%: % (%) - %', 
        clock_timestamp(), p_schema, p_table, SQLERRM, v_err_context, v_sql;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', 
        format('Lỗi: %s (%s)', SQLERRM, v_err_context), NULL, v_duration);
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.setup_nested_partitioning(TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, INTEGER) IS 
'[QLDCQG-BTP] Thiết lập phân vùng lồng nhau theo Miền->Tỉnh->Huyện (hoặc Miền->Tỉnh) cho bảng, tự động tạo partition con và di chuyển dữ liệu theo batch nếu cần.';


-- Function: partitioning.move_data_between_partitions
-- Description: Di chuyển một bản ghi cụ thể từ partition hiện tại sang partition mới.
CREATE OR REPLACE FUNCTION partitioning.move_data_between_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_key_column TEXT, -- Tên cột khóa chính logic (vd: 'birth_certificate_id')
    p_key_value ANYELEMENT, -- Giá trị của khóa chính logic (cần cùng kiểu với cột p_key_column)
    p_new_geographical_region TEXT, -- Tên Miền mới
    p_new_province_id INTEGER,      -- ID Tỉnh mới
    p_new_district_id INTEGER = NULL -- ID Huyện mới (NULL nếu bảng chỉ phân vùng đến Tỉnh)
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
    v_err_context TEXT;
    v_has_config BOOLEAN;
    v_include_district BOOLEAN;
BEGIN
    v_start_time := clock_timestamp();
    
    -- Kiểm tra tham số đầu vào
    IF p_schema IS NULL OR p_table IS NULL OR p_key_column IS NULL OR p_key_value IS NULL OR
       p_new_geographical_region IS NULL OR p_new_province_id IS NULL THEN
        RAISE WARNING '[%] Lỗi: Các tham số bắt buộc không được NULL', clock_timestamp();
        PERFORM partitioning.log_history(p_schema, p_table, 
            format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
            'Các tham số bắt buộc không được NULL');
        RETURN FALSE;
    END IF;
    
    -- Kiểm tra bảng tồn tại
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = p_table) THEN
        RAISE WARNING '[%] Lỗi: Bảng %.% không tồn tại', clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, 
            format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
            format('Bảng %.% không tồn tại', p_schema, p_table));
        RETURN FALSE;
    END IF;
    
    -- Kiểm tra cột khóa tồn tại
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_schema = p_schema AND table_name = p_table AND column_name = p_key_column) THEN
        RAISE WARNING '[%] Lỗi: Cột khóa % không tồn tại trong bảng %.%', 
            clock_timestamp(), p_key_column, p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, 
            format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
            format('Cột khóa %s không tồn tại', p_key_column));
        RETURN FALSE;
    END IF;

    RAISE NOTICE '[%] Bắt đầu move_data_between_partitions cho %.%, key %=%', 
        v_start_time, p_schema, p_table, p_key_column, p_key_value;
    PERFORM partitioning.log_history(p_schema, p_table, 
        format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Running', 
        'Bắt đầu di chuyển bản ghi sang partition mới.');

    -- Lấy tên các cột khóa phân vùng từ config
    SELECT 
        COUNT(*) > 0,
        split_part(partition_columns, ',', 1),
        split_part(partition_columns, ',', 2),
        split_part(partition_columns, ',', 3),
        array_length(string_to_array(partition_columns, ','), 1) > 2
    INTO 
        v_has_config,
        v_region_col, 
        v_province_col, 
        v_district_col,
        v_include_district
    FROM partitioning.config
    WHERE schema_name = p_schema AND table_name = p_table AND partition_type = 'NESTED';

    -- Nếu không tìm thấy config, thử đoán tên cột từ tên các cột thông thường
    IF NOT v_has_config THEN
        RAISE NOTICE '[%] Không tìm thấy cấu hình phân vùng, thử đoán tên cột...', clock_timestamp();
        
        -- Đoán tên các cột phân vùng
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_schema = p_schema AND table_name = p_table AND column_name = 'geographical_region') THEN
            v_region_col := 'geographical_region';
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_schema = p_schema AND table_name = p_table AND column_name = 'province_id') THEN
            v_province_col := 'province_id';
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_schema = p_schema AND table_name = p_table AND column_name = 'district_id') THEN
            v_district_col := 'district_id';
            v_include_district := TRUE;
        ELSE
            v_include_district := FALSE;
        END IF;
        
        IF v_region_col IS NULL OR v_province_col IS NULL THEN
            RAISE WARNING '[%] Không thể xác định cột phân vùng', clock_timestamp();
            PERFORM partitioning.log_history(p_schema, p_table, 
                format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
                'Không tìm thấy cấu hình phân vùng và không thể đoán tên cột');
            RETURN FALSE;
        END IF;
    END IF;

    -- Xử lý trường hợp cột district null hoặc rỗng
    IF v_district_col = '' THEN 
        v_district_col := NULL; 
        v_include_district := FALSE;
    END IF;
    
    -- Kiểm tra cần district_id nhưng không cung cấp
    IF v_include_district AND p_new_district_id IS NULL THEN
        RAISE WARNING '[%] Bảng %.% phân vùng đến cấp huyện nhưng không cung cấp p_new_district_id', 
            clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, 
            format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
            'Thiếu district_id mới cho bảng phân vùng 3 cấp');
        RETURN FALSE;
    END IF;

    -- Tạo savepoint để có thể rollback nếu có lỗi
    SAVEPOINT move_data_savepoint;

    BEGIN
        -- 1. Lấy bản ghi cần di chuyển (chỉ 1 bản ghi)
        EXECUTE format('SELECT * FROM %I.%I WHERE %I = $1 LIMIT 1',
                       p_schema, p_table, p_key_column)
        INTO v_record
        USING p_key_value;

        IF v_record IS NULL THEN
            RAISE WARNING '[%] Không tìm thấy bản ghi với % = % trong bảng %.%', 
                clock_timestamp(), p_key_column, p_key_value, p_schema, p_table;
            PERFORM partitioning.log_history(p_schema, p_table, 
                format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
                'Không tìm thấy bản ghi gốc');
            ROLLBACK TO SAVEPOINT move_data_savepoint;
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
            RAISE WARNING '[%] Không xóa được (hoặc xóa nhiều hơn 1) bản ghi gốc với % = %. Rows affected: %', 
                clock_timestamp(), p_key_column, p_key_value, v_rows_affected;
            PERFORM partitioning.log_history(p_schema, p_table, 
                format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
                format('Lỗi khi xóa bản ghi gốc. Rows affected: %s', v_rows_affected));
            ROLLBACK TO SAVEPOINT move_data_savepoint;
            RETURN FALSE;
        END IF;

        -- 3. Chuẩn bị dữ liệu để INSERT lại với thông tin phân vùng mới
        BEGIN
            SELECT string_agg(quote_ident(key), ', '),
                   string_agg('$' || (row_number() over ()), ', '),
                   array_agg(COALESCE(value::text, 'NULL'))
            INTO v_cols, v_placeholders, v_values
            FROM jsonb_each_text(to_jsonb(v_record)) AS t(key, value)
            -- Cập nhật lại giá trị cho các cột khóa phân vùng
            WHERE key <> v_region_col
              AND key <> v_province_col
              AND (v_district_col IS NULL OR key <> v_district_col);

            -- Thêm các cột khóa phân vùng mới vào danh sách cột và giá trị
            v_cols := v_cols || ', ' || quote_ident(v_region_col) || ', ' || quote_ident(v_province_col);
            v_values := v_values || ARRAY[p_new_geographical_region::TEXT, p_new_province_id::TEXT];
            v_placeholders := v_placeholders || ', $' || (array_length(v_values, 1) - 1) || ', $' || array_length(v_values, 1);

            IF v_include_district AND v_district_col IS NOT NULL THEN
                v_cols := v_cols || ', ' || quote_ident(v_district_col);
                v_values := v_values || ARRAY[p_new_district_id::TEXT];
                v_placeholders := v_placeholders || ', $' || array_length(v_values, 1);
            END IF;
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
            RAISE WARNING '[%] Lỗi khi chuẩn bị dữ liệu INSERT: % (%)', 
                clock_timestamp(), SQLERRM, v_err_context;
            PERFORM partitioning.log_history(p_schema, p_table, 
                format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
                format('Lỗi chuẩn bị dữ liệu: %s', SQLERRM));
            ROLLBACK TO SAVEPOINT move_data_savepoint;
            RETURN FALSE;
        END;

        -- 4. Chèn lại bản ghi vào bảng cha (PG sẽ tự định tuyến đến partition mới)
        BEGIN
            v_insert_sql := format('INSERT INTO %I.%I (%s) VALUES (%s)',
                                   p_schema, p_table, v_cols, v_placeholders);
            RAISE NOTICE '[%] Thực thi INSERT: % (USING %)', clock_timestamp(), v_insert_sql, v_values;
            EXECUTE v_insert_sql USING VARIADIC v_values;
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
            RAISE WARNING '[%] Lỗi khi INSERT bản ghi vào partition mới: % (%)', 
                clock_timestamp(), SQLERRM, v_err_context;
            PERFORM partitioning.log_history(p_schema, p_table, 
                format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
                format('Lỗi INSERT: %s', SQLERRM));
            ROLLBACK TO SAVEPOINT move_data_savepoint;
            RETURN FALSE;
        END;

        v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
        RAISE NOTICE '[%] Đã di chuyển thành công bản ghi % = % sang phân vùng mới (%s, %, %)', 
            clock_timestamp(), p_key_column, p_key_value, p_new_geographical_region, p_new_province_id, p_new_district_id;
        PERFORM partitioning.log_history(p_schema, p_table, 
            format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Success', 
            format('Đã di chuyển đến phân vùng mới (%s, %s, %s)', 
                   p_new_geographical_region, p_new_province_id, COALESCE(p_new_district_id::text, 'N/A')), 
            1, v_duration);

        RETURN TRUE;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
        RAISE WARNING '[%] Lỗi khi di chuyển dữ liệu cho %.%, key %=%: % (%)', 
            clock_timestamp(), p_schema, p_table, p_key_column, p_key_value, SQLERRM, v_err_context;
        PERFORM partitioning.log_history(p_schema, p_table, 
            format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', 
            format('Lỗi: %s', SQLERRM), NULL, v_duration);
        
        -- Rollback đến savepoint
        ROLLBACK TO SAVEPOINT move_data_savepoint;
        RETURN FALSE;
    END;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.move_data_between_partitions(TEXT, TEXT, TEXT, ANYELEMENT, TEXT, INTEGER, INTEGER) IS 
'[QLDCQG-BTP] Di chuyển một bản ghi cụ thể sang partition mới dựa trên thông tin phân vùng mới được cung cấp. Sử dụng transaction để đảm bảo tính nhất quán.';


-- Function: partitioning.create_partition_indexes
-- Description: Tự động tạo các index cần thiết trên TẤT CẢ các partition con
CREATE OR REPLACE FUNCTION partitioning.create_partition_indexes(
    p_schema TEXT,
    p_table TEXT,
    p_index_definitions TEXT[] -- Mảng chứa định nghĩa CREATE INDEX đầy đủ, ví dụ: ARRAY['CREATE INDEX idx_col1 ON %1$I.%2$I (col1)']
                               -- %1$I là schema, %2$I là tên partition
) RETURNS BOOLEAN AS $$
DECLARE
    v_partition_name TEXT;
    v_index_def TEXT;
    v_index_name TEXT;
    v_sql TEXT;
    v_start_time TIMESTAMPTZ;
    v_duration BIGINT;
    v_success BOOLEAN := TRUE;
    v_count_success INTEGER := 0;
    v_count_skipped INTEGER := 0;
    v_count_failed INTEGER := 0;
    v_total_partitions INTEGER := 0;
    v_is_partitioned BOOLEAN;
    v_err_context TEXT;
BEGIN
    v_start_time := clock_timestamp();
    
    -- Kiểm tra tham số đầu vào
    IF p_schema IS NULL OR p_table IS NULL THEN
        RAISE WARNING '[%] Lỗi: Tham số schema hoặc table không được NULL', clock_timestamp();
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Failed', 'Tham số không hợp lệ');
        RETURN FALSE;
    END IF;
    
    -- Kiểm tra bảng tồn tại và là bảng phân vùng
    SELECT EXISTS (
        SELECT 1 FROM pg_catalog.pg_partitioned_table pt 
        JOIN pg_catalog.pg_class c ON pt.partrelid = c.oid 
        JOIN pg_namespace n ON c.relnamespace = n.oid 
        WHERE n.nspname = p_schema AND c.relname = p_table
    ) INTO v_is_partitioned;
    
    IF NOT v_is_partitioned THEN
        RAISE WARNING '[%] Lỗi: Bảng %.% không tồn tại hoặc không phải bảng phân vùng', 
            clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Failed', 'Không phải bảng phân vùng');
        RETURN FALSE;
    END IF;
    
    -- Kiểm tra định nghĩa index
    IF p_index_definitions IS NULL OR array_length(p_index_definitions, 1) IS NULL THEN
        RAISE WARNING '[%] Lỗi: Không có định nghĩa index nào được cung cấp', clock_timestamp();
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Failed', 'Không có định nghĩa index');
        RETURN FALSE;
    END IF;

    RAISE NOTICE '[%] Bắt đầu create_partition_indexes cho %.%...', v_start_time, p_schema, p_table;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Running', 'Bắt đầu tạo index trên các partition');

    -- Thiết lập memory tạm thời cho việc tạo index
    SET LOCAL maintenance_work_mem = '512MB';

    -- Lặp qua tất cả các partition con hiện có của bảng cha
    FOR v_partition_name IN
        SELECT c.relname
        FROM pg_catalog.pg_inherits i
        JOIN pg_catalog.pg_class c ON i.inhrelid = c.oid
        JOIN pg_catalog.pg_namespace nsp ON c.relnamespace = nsp.oid
        JOIN pg_catalog.pg_class parent ON i.inhparent = parent.oid
        WHERE parent.relname = p_table AND nsp.nspname = p_schema AND c.relkind = 'r' -- Chỉ lấy partition là bảng (relation)
        ORDER BY c.relname
    LOOP
        v_total_partitions := v_total_partitions + 1;
        RAISE NOTICE '[%]   - Xử lý partition: %.%', clock_timestamp(), p_schema, v_partition_name;
        
        -- Lặp qua các định nghĩa index cần tạo
        FOREACH v_index_def IN ARRAY p_index_definitions
        LOOP
            BEGIN
                -- Trích xuất tên index dự kiến từ định nghĩa
                SELECT (regexp_matches(v_index_def, 'CREATE(?: UNIQUE)? INDEX\s+(?:IF NOT EXISTS\s+)?(\S+)\s+ON', 'i'))[1] INTO v_index_name;

                IF v_index_name IS NULL THEN
                    RAISE WARNING '[%] Không thể trích xuất tên index từ định nghĩa: %', clock_timestamp(), v_index_def;
                    v_count_failed := v_count_failed + 1;
                    CONTINUE; -- Bỏ qua định nghĩa này
                END IF;

                -- Chuẩn hóa tên index (thay placeholder %2$s bằng tên partition)
                v_index_name := replace(v_index_name, '%2$s', v_partition_name);
                v_index_name := replace(v_index_name, '%2$I', v_partition_name);

                -- Kiểm tra xem index đã tồn tại trên partition này chưa
                IF EXISTS (
                    SELECT 1
                    FROM pg_catalog.pg_indexes
                    WHERE schemaname = p_schema
                      AND tablename = v_partition_name
                      AND indexname = v_index_name
                ) THEN
                    RAISE NOTICE '[%]     Index "%" đã tồn tại trên %.%.', 
                        clock_timestamp(), v_index_name, p_schema, v_partition_name;
                    v_count_skipped := v_count_skipped + 1;
                    CONTINUE;
                END IF;

                -- Thay thế placeholder %1$I (schema) và %2$I (partition name) bằng giá trị thực tế
                v_sql := format(v_index_def, p_schema, v_partition_name);
                RAISE NOTICE '[%]     Tạo index: %', clock_timestamp(), v_sql;
                
                EXECUTE v_sql;
                v_count_success := v_count_success + 1;
                PERFORM partitioning.log_history(p_schema, p_table, v_partition_name, 'CREATE_INDEX', 'Success', 'Đã tạo index: ' || v_index_name);
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
                RAISE WARNING '[%] Lỗi khi tạo index "%" trên partition %.%: % (%)', 
                    clock_timestamp(), v_index_name, p_schema, v_partition_name, SQLERRM, v_err_context;
                PERFORM partitioning.log_history(p_schema, p_table, v_partition_name, 'CREATE_INDEX', 'Failed', 
                    format('Lỗi tạo index %s: %s', v_index_name, SQLERRM));
                v_count_failed := v_count_failed + 1;
                v_success := FALSE;
            END;
        END LOOP; -- Hết vòng lặp định nghĩa index
    END LOOP; -- Hết vòng lặp partition

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Hoàn thành create_partition_indexes cho %.% sau % ms. Kết quả: % thành công, % bỏ qua, % lỗi trên % partition.', 
        clock_timestamp(), p_schema, p_table, v_duration, v_count_success, v_count_skipped, v_count_failed, v_total_partitions;
        
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 
        CASE WHEN v_success THEN 'Success' ELSE 'Warning' END, 
        format('Hoàn thành tạo index trên %s partition: %s thành công, %s bỏ qua, %s lỗi. Thời gian: %s ms.', 
            v_total_partitions, v_count_success, v_count_skipped, v_count_failed, v_duration), 
        v_count_success, v_duration);

    RETURN v_success;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE WARNING '[%] Lỗi không mong muốn khi tạo index: % (%)', 
        clock_timestamp(), SQLERRM, v_err_context;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Failed', 
        format('Lỗi không mong muốn: %s', SQLERRM), NULL, v_duration);
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.create_partition_indexes(TEXT, TEXT, TEXT[]) IS 
'[QLDCQG-BTP] Tạo các index được định nghĩa trong mảng p_index_definitions trên tất cả các partition con của bảng p_table.';


-- ============================================================================
-- III. FUNCTIONS TIỆN ÍCH KHÁC
-- ============================================================================

\echo '--> Định nghĩa các hàm tiện ích khác...'

-- Function: partitioning.generate_partition_report
-- Description: Tạo báo cáo về trạng thái các partition của các bảng được cấu hình phân vùng.
CREATE OR REPLACE FUNCTION partitioning.generate_partition_report()
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
DECLARE
    v_has_dependencies BOOLEAN;
BEGIN
    -- Kiểm tra các dependencies tồn tại
    SELECT 
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'partitioning' AND table_name = 'config')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'reference' AND table_name = 'provinces')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'reference' AND table_name = 'districts')
    INTO v_has_dependencies;
    
    IF NOT v_has_dependencies THEN
        RAISE WARNING 'Bảng partitioning.config hoặc reference tables chưa tồn tại/đầy đủ, báo cáo có thể không đầy đủ.';
    END IF;

    -- Tạo báo cáo từ thông tin partition
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
          AND nsp.nspname = 'justice' -- *** Chỉ xét schema justice trong DB BTP ***
    ),
    partition_stats AS (
        SELECT
            pi.schema_name,
            pi.table_name,
            pi.partition_name,
            pi.partition_expression,
            COALESCE(stat.n_live_tup, 0) + COALESCE(stat.n_dead_tup, 0) AS estimated_rows,
            pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name) AS total_size_bytes,
            pg_catalog.pg_size_pretty(pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name)) AS total_size_pretty,
            stat.last_analyze AS last_analyzed,
            CASE
                WHEN pi.partition_name ~ ('_' || COALESCE(partitioning.standardize_name('BAC'), 'bac') || '(?:_|$)') THEN 'Bắc'
                WHEN pi.partition_name ~ ('_' || COALESCE(partitioning.standardize_name('TRUNG'), 'trung') || '(?:_|$)') THEN 'Trung'
                WHEN pi.partition_name ~ ('_' || COALESCE(partitioning.standardize_name('NAM'), 'nam') || '(?:_|$)') THEN 'Nam'
                ELSE NULL
            END AS derived_region_name,
            substring(pi.partition_name from p_conf.table_name || '_(?:bac|trung|nam)_([a-z0-9_]+)(?:_[a-z0-9_]+)?$') AS derived_province_std_code,
            substring(pi.partition_name from p_conf.table_name || '_(?:bac|trung|nam)_[a-z0-9_]+_([a-z0-9_]+)$') AS derived_district_std_code
        FROM partition_info pi
        LEFT JOIN pg_catalog.pg_stat_all_tables stat ON stat.schemaname = pi.schema_name AND stat.relname = pi.partition_name
        LEFT JOIN partitioning.config p_conf ON p_conf.schema_name = pi.schema_name AND p_conf.table_name = pi.table_name
        WHERE p_conf.is_active IS NULL OR p_conf.is_active = TRUE
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
        COALESCE(prov.province_name, 'Unknown')::TEXT,
        COALESCE(dist.district_name, 'Unknown')::TEXT
    FROM partition_stats ps
    LEFT JOIN reference.provinces prov ON 
        partitioning.standardize_name(prov.province_code) = ps.derived_province_std_code
    LEFT JOIN reference.districts dist ON 
        partitioning.standardize_name(dist.district_code) = ps.derived_district_std_code 
        AND dist.province_id = prov.province_id
    ORDER BY 
        ps.schema_name, 
        ps.table_name, 
        ps.derived_region_name, 
        COALESCE(prov.province_name, 'Unknown'), 
        COALESCE(dist.district_name, 'Unknown'), 
        ps.partition_name;

EXCEPTION 
    WHEN undefined_function THEN
        RAISE NOTICE 'Function partitioning.standardize_name() không tồn tại, đang sử dụng phương pháp thay thế.';
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
              AND nsp.nspname = 'justice'
        )
        SELECT
            pi.schema_name::TEXT,
            pi.table_name::TEXT,
            pi.partition_name::TEXT,
            pi.partition_expression::TEXT,
            COALESCE(stat.n_live_tup, 0) + COALESCE(stat.n_dead_tup, 0)::BIGINT,
            pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name)::BIGINT,
            pg_catalog.pg_size_pretty(pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name))::TEXT,
            stat.last_analyze::TIMESTAMP WITH TIME ZONE,
            CASE
                WHEN pi.partition_name ~ ('_bac_') THEN 'Bắc'
                WHEN pi.partition_name ~ ('_trung_') THEN 'Trung'
                WHEN pi.partition_name ~ ('_nam_') THEN 'Nam'
                ELSE NULL
            END::TEXT,
            NULL::TEXT,
            NULL::TEXT
        FROM partition_info pi
        LEFT JOIN pg_catalog.pg_stat_all_tables stat ON stat.schemaname = pi.schema_name AND stat.relname = pi.partition_name
        ORDER BY pi.schema_name, pi.table_name, pi.partition_name;
    
    WHEN undefined_table THEN
        RAISE NOTICE 'Bảng partitioning.config hoặc reference tables chưa tồn tại/đầy đủ, báo cáo có thể không đầy đủ.';
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
              AND nsp.nspname = 'justice'
        )
        SELECT
            pi.schema_name::TEXT,
            pi.table_name::TEXT,
            pi.partition_name::TEXT,
            pi.partition_expression::TEXT,
            COALESCE(stat.n_live_tup, 0) + COALESCE(stat.n_dead_tup, 0)::BIGINT,
            pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name)::BIGINT,
            pg_catalog.pg_size_pretty(pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name))::TEXT,
            stat.last_analyze::TIMESTAMP WITH TIME ZONE,
            NULL::TEXT,
            NULL::TEXT,
            NULL::TEXT
        FROM partition_info pi
        LEFT JOIN pg_catalog.pg_stat_all_tables stat ON stat.schemaname = pi.schema_name AND stat.relname = pi.partition_name
        ORDER BY pi.schema_name, pi.table_name, pi.partition_name;
    
    WHEN OTHERS THEN
        RAISE WARNING 'Lỗi không xác định khi tạo báo cáo phân vùng: %', SQLERRM;
        RETURN QUERY SELECT NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::BIGINT, NULL::BIGINT, NULL::TEXT, NULL::TIMESTAMP WITH TIME ZONE, NULL::TEXT, NULL::TEXT, NULL::TEXT WHERE FALSE;
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.generate_partition_report() IS '[QLDCQG-BTP] Tạo báo cáo về trạng thái các partition (kích thước, số dòng...) của các bảng được phân vùng trong DB BTP.';


-- Function: partitioning.verify_partition_consistency
-- Description: Kiểm tra tính nhất quán của cấu trúc phân vùng.
CREATE OR REPLACE FUNCTION partitioning.verify_partition_consistency(
    p_schema TEXT,
    p_table TEXT
) RETURNS TABLE (
    check_type TEXT,
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_region_col TEXT;
    v_province_col TEXT;
    v_district_col TEXT;
    v_include_district BOOLEAN;
    v_has_config BOOLEAN;
    v_err_context TEXT;
BEGIN
    -- Kiểm tra tham số đầu vào
    IF p_schema IS NULL OR p_table IS NULL THEN
        RETURN QUERY SELECT 
            'CONFIG'::TEXT, 
            'Parameters'::TEXT, 
            'ERROR'::TEXT, 
            'Tham số p_schema và p_table không được NULL'::TEXT;
        RETURN;
    END IF;
    
    -- Kiểm tra bảng tồn tại và là bảng phân vùng
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_partitioned_table pt 
        JOIN pg_catalog.pg_class c ON pt.partrelid = c.oid 
        JOIN pg_namespace n ON c.relnamespace = n.oid 
        WHERE n.nspname = p_schema AND c.relname = p_table
    ) THEN
        RETURN QUERY SELECT 
            'CONFIG'::TEXT, 
            'Table Existence'::TEXT, 
            'ERROR'::TEXT, 
            format('Bảng %.% không tồn tại hoặc không phải bảng phân vùng', p_schema, p_table)::TEXT;
        RETURN;
    END IF;
    
    -- Lấy thông tin cấu hình phân vùng
    SELECT 
        COUNT(*) > 0,
        split_part(partition_columns, ',', 1),
        split_part(partition_columns, ',', 2),
        split_part(partition_columns, ',', 3),
        array_length(string_to_array(partition_columns, ','), 1) > 2
    INTO 
        v_has_config,
        v_region_col, 
        v_province_col, 
        v_district_col,
        v_include_district
    FROM partitioning.config
    WHERE schema_name = p_schema AND table_name = p_table AND partition_type = 'NESTED';
    
    -- Kiểm tra config
    IF NOT v_has_config THEN
        RETURN QUERY SELECT 
            'CONFIG'::TEXT, 
            'Partition Config'::TEXT, 
            'WARNING'::TEXT, 
            format('Không tìm thấy cấu hình phân vùng cho %.% trong bảng partitioning.config', p_schema, p_table)::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'CONFIG'::TEXT, 
            'Partition Config'::TEXT, 
            'OK'::TEXT, 
            format('Cấu hình phân vùng (%s, %s, %s) đã được tìm thấy', v_region_col, v_province_col, COALESCE(v_district_col, 'N/A'))::TEXT;
    END IF;
    
    -- Kiểm tra cấu trúc phân vùng cấp 1 (region)
    BEGIN
        RETURN QUERY
        WITH expected_regions AS (
            SELECT region_name FROM reference.regions
        ),
        actual_regions AS (
            SELECT DISTINCT(TRIM(BOTH '''' FROM SUBSTRING(pg_get_expr(c.relpartbound, parent.oid) FROM 'FOR VALUES IN \((.+?)\)')))
            FROM pg_class c
            JOIN pg_inherits i ON c.oid = i.inhrelid
            JOIN pg_class parent ON i.inhparent = parent.oid
            JOIN pg_namespace n ON parent.relnamespace = n.oid
            WHERE n.nspname = p_schema AND parent.relname = p_table
        )
        SELECT 
            'STRUCTURE'::TEXT, 
            'Region Partitions'::TEXT, 
            CASE 
                WHEN (SELECT COUNT(*) FROM expected_regions) = (SELECT COUNT(*) FROM actual_regions) 
                    AND NOT EXISTS (SELECT 1 FROM expected_regions WHERE region_name NOT IN (SELECT * FROM actual_regions))
                THEN 'OK'::TEXT
                ELSE 'WARNING'::TEXT
            END,
            CASE 
                WHEN (SELECT COUNT(*) FROM expected_regions) = (SELECT COUNT(*) FROM actual_regions) 
                    AND NOT EXISTS (SELECT 1 FROM expected_regions WHERE region_name NOT IN (SELECT * FROM actual_regions))
                THEN format('Tìm thấy đủ %s phân vùng cấp 1 (region)', (SELECT COUNT(*) FROM expected_regions))::TEXT
                ELSE format('Thiếu phân vùng cấp 1 (region). Kỳ vọng: %s, Thực tế: %s', 
                        string_agg(er.region_name, ', '), 
                        string_agg(COALESCE(ar.*, 'N/A'), ', '))::TEXT
            END
        FROM expected_regions er
        FULL OUTER JOIN actual_regions ar ON er.region_name = ar.* 
        GROUP BY 1, 2;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RETURN QUERY SELECT 
            'STRUCTURE'::TEXT, 
            'Region Partitions'::TEXT, 
            'ERROR'::TEXT, 
            format('Lỗi khi kiểm tra phân vùng cấp 1: %s (%s)', SQLERRM, v_err_context)::TEXT;
    END;
    
    -- Kiểm tra dữ liệu orphaned (không có trong partition)
    BEGIN
        RETURN QUERY
        WITH orphaned_data AS (
            -- Dữ liệu có giá trị region không thuộc bất kỳ partition nào
            SELECT COUNT(*) AS count
            FROM ONLY %I.%I
        )
        SELECT 
            'DATA'::TEXT, 
            'Orphaned Data'::TEXT, 
            CASE 
                WHEN (SELECT count FROM orphaned_data) = 0 THEN 'OK'::TEXT
                ELSE 'WARNING'::TEXT
            END,
            CASE 
                WHEN (SELECT count FROM orphaned_data) = 0 THEN 'Không có dữ liệu mồ côi (orphaned)'::TEXT
                ELSE format('Có %s bản ghi không thuộc bất kỳ partition nào', (SELECT count FROM orphaned_data))::TEXT
            END;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RETURN QUERY SELECT 
            'DATA'::TEXT, 
            'Orphaned Data'::TEXT, 
            'ERROR'::TEXT, 
            format('Lỗi khi kiểm tra dữ liệu mồ côi: %s (%s)', SQLERRM, v_err_context)::TEXT;
    END;
    
    -- Kiểm tra các index cần thiết
    BEGIN
        -- Kiểm tra index trên cột phân vùng
        RETURN QUERY
        SELECT 
            'INDEX'::TEXT, 
            'Partition Columns Index'::TEXT, 
            CASE 
                WHEN EXISTS (
                    SELECT 1
                    FROM pg_catalog.pg_indexes
                    WHERE schemaname = p_schema
                      AND tablename = p_table
                      AND (
                        indexdef ILIKE '%' || v_region_col || '%' OR
                        indexdef ILIKE '%' || v_province_col || '%' OR
                        (v_include_district AND indexdef ILIKE '%' || v_district_col || '%')
                      )
                ) THEN 'OK'::TEXT
                ELSE 'WARNING'::TEXT
            END,
            CASE 
                WHEN EXISTS (
                    SELECT 1
                    FROM pg_catalog.pg_indexes
                    WHERE schemaname = p_schema
                      AND tablename = p_table
                      AND (
                        indexdef ILIKE '%' || v_region_col || '%' OR
                        indexdef ILIKE '%' || v_province_col || '%' OR
                        (v_include_district AND indexdef ILIKE '%' || v_district_col || '%')
                      )
                ) THEN 'Index trên các cột phân vùng đã được tạo'::TEXT
                ELSE 'Không tìm thấy index trên các cột phân vùng, có thể ảnh hưởng hiệu suất truy vấn'::TEXT
            END;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RETURN QUERY SELECT 
            'INDEX'::TEXT, 
            'Partition Columns Index'::TEXT, 
            'ERROR'::TEXT, 
            format('Lỗi khi kiểm tra index: %s (%s)', SQLERRM, v_err_context)::TEXT;
    END;

    -- Kiểm tra tình trạng auto-vacuum và analyze
    BEGIN
        RETURN QUERY
        SELECT 
            'MAINTENANCE'::TEXT, 
            'Vacuum and Analyze'::TEXT, 
            CASE 
                WHEN MAX(last_vacuum) < NOW() - INTERVAL '7 days' OR MAX(last_analyze) < NOW() - INTERVAL '7 days'
                THEN 'WARNING'::TEXT
                ELSE 'OK'::TEXT
            END,
            CASE 
                WHEN MAX(last_vacuum) < NOW() - INTERVAL '7 days' OR MAX(last_analyze) < NOW() - INTERVAL '7 days'
                THEN 'Các partition chưa được vacuum hoặc analyze trong 7 ngày qua'::TEXT
                ELSE 'Các partition đã được vacuum và analyze gần đây'::TEXT
            END
        FROM pg_stat_all_tables
        WHERE schemaname = p_schema
        AND relname LIKE p_table || '_%';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
        RETURN QUERY SELECT 
            'MAINTENANCE'::TEXT, 
            'Vacuum and Analyze'::TEXT, 
            'ERROR'::TEXT, 
            format('Lỗi khi kiểm tra thông tin vacuum/analyze: %s (%s)', SQLERRM, v_err_context)::TEXT;
    END;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_err_context = PG_EXCEPTION_CONTEXT;
    RETURN QUERY SELECT 
        'GENERAL'::TEXT, 
        'Function Execution'::TEXT, 
        'ERROR'::TEXT, 
        format('Lỗi không mong muốn: %s (%s)', SQLERRM, v_err_context)::TEXT;
END;
$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.verify_partition_consistency(TEXT, TEXT) IS 
'[QLDCQG-BTP] Kiểm tra tính nhất quán của cấu trúc phân vùng cho một bảng, bao gồm cấu hình, phân vùng, dữ liệu và index.';
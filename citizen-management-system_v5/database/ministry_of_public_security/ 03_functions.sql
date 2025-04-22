-- =============================================================================
-- File: ministry_of_public_security/03_functions.sql
-- Description: Định nghĩa các function PL/pgSQL cần thiết cho database Bộ Công an (BCA),
--              bao gồm các hàm hỗ trợ quản lý phân vùng dữ liệu.
-- Version: 3.1 (Consolidated partitioning functions)
--
-- Yêu cầu:
-- - Chạy sau khi đã tạo cấu trúc bảng và thêm ràng buộc.
-- - Cần quyền tạo function trong các schema liên quan (partitioning, public_security...).
-- =============================================================================

\echo '*** BẮT ĐẦU ĐỊNH NGHĨA FUNCTIONS CHO DATABASE BỘ CÔNG AN ***'
\connect ministry_of_public_security

-- Đảm bảo schema partitioning tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;

-- === I. CÁC HÀM HỖ TRỢ (HELPERS) CHO PHÂN VÙNG ===

\echo '[1] Định nghĩa các hàm hỗ trợ phân vùng...'

-- Function: partitioning.log_history
-- Description: Ghi log vào bảng partitioning.history một cách nhất quán.
CREATE OR REPLACE FUNCTION partitioning.log_history(
    _schema TEXT, _table TEXT, _partition TEXT, _action TEXT,
    _status TEXT DEFAULT 'Success', _details TEXT DEFAULT NULL,
    _rows BIGINT DEFAULT NULL, _duration BIGINT DEFAULT NULL
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
COMMENT ON FUNCTION partitioning.log_history(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BIGINT, BIGINT)
    IS '[QLDCQG-BCA] Hàm tiện ích để ghi log vào bảng partitioning.history.';

-- Function: partitioning.standardize_name
-- Description: Chuẩn hóa tên (loại bỏ dấu, khoảng trắng, chữ thường) để tạo tên partition.
CREATE OR REPLACE FUNCTION partitioning.standardize_name(_input_name TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Cần extension unaccent
    RETURN lower(regexp_replace(unaccent(_input_name), '[^a-zA-Z0-9_]+', '_', 'g'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
COMMENT ON FUNCTION partitioning.standardize_name(TEXT)
    IS '[QLDCQG-BCA] Chuẩn hóa tên (bỏ dấu, khoảng trắng->_, lowercase) dùng cho tên partition.';

-- Function: partitioning.pg_get_tabledef
-- Description: Lấy định nghĩa cột cơ bản của bảng (không bao gồm FK, CHECK phức tạp, default...)
--              để tạo bảng con phân vùng.
CREATE OR REPLACE FUNCTION partitioning.pg_get_tabledef(p_schema_name TEXT, p_table_name TEXT)
RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_record RECORD;
    v_column_defs TEXT[] := '{}';
    v_partition_key_cols TEXT[];
BEGIN
    -- Lấy danh sách cột khóa phân vùng của bảng cha (nếu có)
    SELECT string_to_array(pg_get_partition_keydef(c.oid), ', ')
    INTO v_partition_key_cols
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = p_schema_name AND c.relname = p_table_name AND c.relkind = 'p';

    v_partition_key_cols := COALESCE(v_partition_key_cols, '{}');

    FOR v_column_record IN
        SELECT
            column_name, data_type, udt_name, is_nullable,
            character_maximum_length, numeric_precision, numeric_scale, column_default
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
            CASE WHEN v_column_record.column_default IS NOT NULL AND v_column_record.column_default !~* 'nextval' THEN ' DEFAULT ' || v_column_record.column_default ELSE '' END
        );
    END LOOP;

    v_table_ddl := E'(\n    ' || array_to_string(v_column_defs, E',\n    ') || E'\n)';
    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.pg_get_tabledef(TEXT, TEXT)
    IS '[QLDCQG-BCA] Lấy định nghĩa cột cơ bản của bảng (trừ cột khóa phân vùng cha) để tạo partition con.';


-- === II. HÀM THIẾT LẬP PHÂN VÙNG CHÍNH ===

\echo '[2] Định nghĩa hàm thiết lập phân vùng chính...'

-- Function: partitioning.setup_nested_partitioning
-- Description: Khởi tạo phân vùng lồng nhau theo Miền -> Tỉnh -> Quận/Huyện (hoặc chỉ Miền -> Tỉnh).
CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT, p_table TEXT, p_region_column TEXT,
    p_province_column TEXT, p_district_column TEXT,
    p_include_district BOOLEAN DEFAULT TRUE
) RETURNS BOOLEAN AS $$
DECLARE
    v_regions RECORD; v_provinces RECORD; v_districts RECORD;
    v_sql TEXT;
    v_partition_name_l1 TEXT; v_partition_name_l2 TEXT; v_partition_name_l3 TEXT;
    v_region_std_name TEXT; v_province_std_name TEXT; v_district_std_name TEXT;
    v_old_table_exists BOOLEAN; v_is_already_partitioned BOOLEAN;
    v_ddl_columns TEXT;
    v_root_table_name TEXT := p_table || '_partitioned';
    v_old_table_name TEXT := p_table || '_old';
    v_row_count BIGINT; v_start_time TIMESTAMPTZ := clock_timestamp(); v_duration BIGINT;
BEGIN
    RAISE NOTICE '[%] Bắt đầu setup_nested_partitioning cho %.% (Cấp huyện: %)...', v_start_time, p_schema, p_table, p_include_district;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Running', format('Bắt đầu phân vùng đa cấp (Cấp huyện: %s)', p_include_district));

    -- Kiểm tra bảng gốc và lấy định nghĩa cột
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = p_table) INTO v_old_table_exists;
    IF NOT v_old_table_exists THEN
        RAISE WARNING '[%] Lỗi: Bảng %.% không tồn tại.', clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', format('Bảng %.% không tồn tại.', p_schema, p_table));
        RETURN FALSE;
    END IF;
    SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_partitioned_table pt JOIN pg_catalog.pg_class c ON pt.partrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = p_schema AND c.relname = p_table) INTO v_is_already_partitioned;
    v_ddl_columns := partitioning.pg_get_tabledef(p_schema, p_table);
    IF v_ddl_columns IS NULL OR v_ddl_columns = '()' THEN
         RAISE WARNING '[%] Lỗi: Không thể lấy định nghĩa cột cho %.%.', clock_timestamp(), p_schema, p_table;
         PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', 'Không thể lấy định nghĩa cột.');
         RETURN FALSE;
    END IF;

    -- 1. Tạo bảng gốc phân vùng mới (nếu cần)
    IF NOT v_is_already_partitioned THEN
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', p_schema, v_root_table_name);
        v_sql := format('CREATE TABLE %I.%I %s PARTITION BY LIST (%I);', p_schema, v_root_table_name, v_ddl_columns, p_region_column);
        RAISE NOTICE '[%] Tạo bảng gốc phân vùng tạm: %', clock_timestamp(), v_sql; EXECUTE v_sql;
        PERFORM partitioning.log_history(p_schema, p_table, v_root_table_name, 'CREATE_PARTITION', 'Success', 'Tạo bảng gốc phân vùng tạm thời.');
    ELSE
        v_root_table_name := p_table;
        RAISE NOTICE '[%] Bảng %.% đã được phân vùng. Bỏ qua tạo bảng gốc mới.', clock_timestamp(), p_schema, p_table;
    END IF;

    -- 2. Tạo các partition con lồng nhau
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions ORDER BY region_id LOOP
        v_region_std_name := partitioning.standardize_name(v_regions.region_code);
        v_partition_name_l1 := p_table || '_' || v_region_std_name;
        -- Tạo partition cấp 1 (Miền)
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l1) THEN
            v_sql := format('CREATE TABLE %I.%I PARTITION OF %I.%I FOR VALUES IN (%L) PARTITION BY LIST (%I);', p_schema, v_partition_name_l1, p_schema, v_root_table_name, v_regions.region_name, p_province_column);
            RAISE NOTICE '[%] Tạo partition L1: %', clock_timestamp(), v_sql; EXECUTE v_sql;
            PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l1, 'CREATE_PARTITION', 'Success', format('Partition cấp 1 cho miền %s', v_regions.region_name));
        END IF;

        FOR v_provinces IN SELECT province_id, province_code, province_name FROM reference.provinces WHERE region_id = v_regions.region_id ORDER BY province_id LOOP
            v_province_std_name := partitioning.standardize_name(v_provinces.province_code);
            v_partition_name_l2 := v_partition_name_l1 || '_' || v_province_std_name;
            IF p_include_district THEN -- Phân vùng 3 cấp
                -- Tạo partition cấp 2 (Tỉnh)
                IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l2) THEN
                    v_sql := format('CREATE TABLE %I.%I PARTITION OF %I.%I FOR VALUES IN (%L) PARTITION BY LIST (%I);', p_schema, v_partition_name_l2, p_schema, v_partition_name_l1, v_provinces.province_id, p_district_column);
                    RAISE NOTICE '[%] Tạo partition L2: %', clock_timestamp(), v_sql; EXECUTE v_sql;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Success', format('Partition cấp 2 cho tỉnh %s', v_provinces.province_name));
                 END IF;
                 -- Tạo partition cấp 3 (Huyện)
                 FOR v_districts IN SELECT district_id, district_code, district_name FROM reference.districts WHERE province_id = v_provinces.province_id ORDER BY district_id LOOP
                     v_district_std_name := partitioning.standardize_name(v_districts.district_code);
                     v_partition_name_l3 := v_partition_name_l2 || '_' || v_district_std_name;
                     IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l3) THEN
                         v_sql := format('CREATE TABLE %I.%I PARTITION OF %I.%I FOR VALUES IN (%L);', p_schema, v_partition_name_l3, p_schema, v_partition_name_l2, v_districts.district_id);
                         RAISE NOTICE '[%] Tạo partition L3: %', clock_timestamp(), v_sql; EXECUTE v_sql;
                         PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l3, 'CREATE_PARTITION', 'Success', format('Partition cấp 3 cho huyện %s', v_districts.district_name));
                     END IF;
                 END LOOP;
            ELSE -- Phân vùng 2 cấp
                 -- Tạo partition cấp 2 (Tỉnh) - cấp cuối
                 IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = p_schema AND table_name = v_partition_name_l2) THEN
                     v_sql := format('CREATE TABLE %I.%I PARTITION OF %I.%I FOR VALUES IN (%L);', p_schema, v_partition_name_l2, p_schema, v_partition_name_l1, v_provinces.province_id);
                     RAISE NOTICE '[%] Tạo partition L2 (cuối): %', clock_timestamp(), v_sql; EXECUTE v_sql;
                     PERFORM partitioning.log_history(p_schema, p_table, v_partition_name_l2, 'CREATE_PARTITION', 'Success', format('Partition cấp 2 (cuối) cho tỉnh %s', v_provinces.province_name));
                 END IF;
            END IF;
        END LOOP;
    END LOOP;

    -- 3. Di chuyển dữ liệu và đổi tên (nếu bảng gốc chưa phân vùng)
    IF NOT v_is_already_partitioned THEN
        RAISE NOTICE '[%] Bảng %.% chưa được phân vùng, tiến hành di chuyển dữ liệu và đổi tên...', clock_timestamp(), p_schema, p_table;
        EXECUTE format('LOCK TABLE %I.%I IN ACCESS EXCLUSIVE MODE;', p_schema, p_table);
        EXECUTE format('INSERT INTO %I.%I SELECT * FROM %I.%I;', p_schema, v_root_table_name, p_schema, p_table);
        GET DIAGNOSTICS v_row_count = ROW_COUNT; RAISE NOTICE '[%] Đã di chuyển % dòng.', clock_timestamp(), v_row_count;
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', p_schema, v_old_table_name);
        EXECUTE format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, p_table, v_old_table_name);
        EXECUTE format('ALTER TABLE %I.%I RENAME TO %I;', p_schema, v_root_table_name, p_table);
        v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'REPARTITIONED', 'Success', format('Đã di chuyển %s dòng và đổi tên thành bảng phân vùng.', v_row_count), v_row_count, v_duration);
        RAISE NOTICE '[%] Hoàn tất di chuyển và đổi tên cho %.%.', clock_timestamp(), p_schema, p_table;
    END IF;

    -- 4. Ghi/Cập nhật cấu hình
    BEGIN
        INSERT INTO partitioning.config (schema_name, table_name, partition_type, partition_columns, is_active, updated_at)
        VALUES (p_schema, p_table, 'NESTED',
            CASE WHEN p_include_district THEN p_region_column||','||p_province_column||','||p_district_column ELSE p_region_column||','||p_province_column END,
            TRUE, CURRENT_TIMESTAMP)
        ON CONFLICT (schema_name, table_name) DO UPDATE SET
            partition_type = EXCLUDED.partition_type, partition_columns = EXCLUDED.partition_columns,
            is_active = TRUE, updated_at = CURRENT_TIMESTAMP;
        RAISE NOTICE '[%] Đã ghi/cập nhật cấu hình phân vùng cho %.%.', clock_timestamp(), p_schema, p_table;
        PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CONFIG_UPDATE', 'Success', 'Ghi/cập nhật cấu hình phân vùng NESTED.');
    EXCEPTION WHEN undefined_table THEN RAISE NOTICE '[%] Bảng partitioning.config không tồn tại, bỏ qua ghi cấu hình.';
    END;

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Hoàn thành setup_nested_partitioning cho %.% sau % ms.', clock_timestamp(), p_schema, p_table, v_duration;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Success', format('Hoàn thành phân vùng đa cấp sau %s ms', v_duration), v_row_count, v_duration);
    RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE WARNING '[%] Lỗi khi thực hiện setup_nested_partitioning cho %.%: %', clock_timestamp(), p_schema, p_table, SQLERRM;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'INIT_PARTITIONING', 'Failed', SQLERRM, NULL, v_duration);
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.setup_nested_partitioning(TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN)
    IS '[QLDCQG-BCA] Thiết lập phân vùng lồng nhau theo Miền->Tỉnh->Huyện (hoặc Miền->Tỉnh) cho bảng, tự động tạo partition con và di chuyển dữ liệu nếu cần.';

-- Function: partitioning.determine_partition_for_citizen
-- Description: Xác định thông tin phân vùng (Miền, Tỉnh, Huyện) cho công dân dựa trên địa chỉ hiện tại.
CREATE OR REPLACE FUNCTION partitioning.determine_partition_for_citizen(p_citizen_id TEXT)
RETURNS TABLE (geographical_region TEXT, province_id INTEGER, district_id INTEGER) AS $$
DECLARE
    v_address_id INTEGER; v_province_id INTEGER; v_district_id INTEGER; v_region_id SMALLINT;
BEGIN
    -- Ưu tiên tìm địa chỉ thường trú hiện tại
    SELECT pr.address_id INTO v_address_id
    FROM public_security.permanent_residence pr
    WHERE pr.citizen_id = p_citizen_id AND pr.status = TRUE
    ORDER BY pr.registration_date DESC, pr.permanent_residence_id DESC LIMIT 1;

    -- Nếu không có thường trú, tìm tạm trú hiện tại
    IF v_address_id IS NULL THEN
        SELECT tr.address_id INTO v_address_id
        FROM public_security.temporary_residence tr
        WHERE tr.citizen_id = p_citizen_id AND tr.status = 'Active'
        ORDER BY tr.registration_date DESC, tr.temporary_residence_id DESC LIMIT 1;
    END IF;

    -- Lấy thông tin phân vùng từ địa chỉ tìm được
    IF v_address_id IS NOT NULL THEN
        SELECT a.province_id, a.district_id, p.region_id
        INTO v_province_id, v_district_id, v_region_id
        FROM public_security.address a
        JOIN reference.provinces p ON a.province_id = p.province_id
        WHERE a.address_id = v_address_id;

        IF FOUND THEN
            RETURN QUERY SELECT CASE v_region_id WHEN 1 THEN 'Bắc'::TEXT WHEN 2 THEN 'Trung'::TEXT WHEN 3 THEN 'Nam'::TEXT ELSE NULL::TEXT END, v_province_id, v_district_id;
            RETURN;
        ELSE RAISE NOTICE '[determine_partition_for_citizen] Không tìm thấy thông tin tỉnh/huyện/vùng cho address_id: %', v_address_id;
        END IF;
    ELSE RAISE NOTICE '[determine_partition_for_citizen] Không tìm thấy địa chỉ thường trú/tạm trú hiện tại cho citizen_id: %', p_citizen_id;
    END IF;

    -- Trả về rỗng nếu không xác định được
    RAISE NOTICE '[determine_partition_for_citizen] Không thể xác định phân vùng cho citizen_id: %. Trả về NULL.', p_citizen_id;
    RETURN QUERY SELECT NULL::TEXT, NULL::INTEGER, NULL::INTEGER WHERE FALSE;
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.determine_partition_for_citizen(TEXT)
    IS '[QLDCQG-BCA] Xác định thông tin phân vùng (Miền, Tỉnh, Huyện) cho công dân dựa trên địa chỉ hiện tại.';


-- === III. HÀM BẢO TRÌ VÀ TIỆN ÍCH PHÂN VÙNG ===

\echo '[3] Định nghĩa các hàm bảo trì và tiện ích phân vùng...'

-- Function: partitioning.move_data_between_partitions
-- Description: Di chuyển một bản ghi cụ thể sang partition mới khi thông tin phân vùng thay đổi.
CREATE OR REPLACE FUNCTION partitioning.move_data_between_partitions(
    p_schema TEXT, p_table TEXT, p_key_column TEXT, p_key_value ANYELEMENT,
    p_new_geographical_region TEXT, p_new_province_id INTEGER, p_new_district_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_record RECORD; v_rows_affected INTEGER := 0;
    v_delete_sql TEXT; v_insert_sql TEXT;
    v_cols TEXT; v_placeholders TEXT; v_values ANYARRAY;
    v_region_col TEXT; v_province_col TEXT; v_district_col TEXT;
    v_start_time TIMESTAMPTZ := clock_timestamp(); v_duration BIGINT;
BEGIN
    RAISE NOTICE '[%] Bắt đầu move_data_between_partitions cho %.%, key %=%', v_start_time, p_schema, p_table, p_key_column, p_key_value;
    PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Running', 'Bắt đầu di chuyển bản ghi.');

    -- Lấy tên cột phân vùng từ config
    SELECT split_part(partition_columns, ',', 1), split_part(partition_columns, ',', 2), split_part(partition_columns, ',', 3)
    INTO v_region_col, v_province_col, v_district_col
    FROM partitioning.config WHERE schema_name = p_schema AND table_name = p_table AND partition_type = 'NESTED';
    IF v_region_col IS NULL OR v_province_col IS NULL THEN
        RAISE WARNING '[%] Không tìm thấy cấu hình phân vùng NESTED cho %.%', clock_timestamp(), p_schema, p_table; RETURN FALSE;
    END IF;
    IF v_district_col = '' THEN v_district_col := NULL; END IF;
    IF v_district_col IS NOT NULL AND p_new_district_id IS NULL THEN
        RAISE WARNING '[%] Thiếu district_id mới cho bảng %.% phân vùng 3 cấp.', clock_timestamp(), p_schema, p_table; RETURN FALSE;
    END IF;

    -- 1. Lấy bản ghi gốc
    EXECUTE format('SELECT * FROM %I.%I WHERE %I = $1 LIMIT 1', p_schema, p_table, p_key_column) INTO v_record USING p_key_value;
    IF v_record IS NULL THEN RAISE NOTICE '[%] Không tìm thấy bản ghi % = %', clock_timestamp(), p_key_column, p_key_value; RETURN FALSE; END IF;

    -- 2. Xóa bản ghi cũ
    v_delete_sql := format('DELETE FROM %I.%I WHERE %I = $1', p_schema, p_table, p_key_column);
    RAISE NOTICE '[%] Thực thi DELETE: % (USING %)', clock_timestamp(), v_delete_sql, p_key_value; EXECUTE v_delete_sql USING p_key_value;
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    IF v_rows_affected <> 1 THEN RAISE WARNING '[%] Lỗi khi xóa bản ghi gốc % = %. Rows affected: %.', clock_timestamp(), p_key_column, p_key_value, v_rows_affected; RETURN FALSE; END IF;

    -- 3. Chuẩn bị dữ liệu INSERT mới
    SELECT string_agg(quote_ident(key), ', '), string_agg('$' || (row_number() over ()), ', '), array_agg(value)
    INTO v_cols, v_placeholders, v_values
    FROM jsonb_each_text(to_jsonb(v_record)) AS t(key, value)
    WHERE key <> v_region_col AND key <> v_province_col AND (v_district_col IS NULL OR key <> v_district_col);

    v_cols := v_cols || ', ' || quote_ident(v_region_col) || ', ' || quote_ident(v_province_col);
    v_values := v_values || ARRAY[p_new_geographical_region::TEXT, p_new_province_id::TEXT];
    v_placeholders := v_placeholders || ', $' || (array_length(v_values, 1) - 1) || ', $' || array_length(v_values, 1);
    IF v_district_col IS NOT NULL THEN
        v_cols := v_cols || ', ' || quote_ident(v_district_col);
        v_values := v_values || ARRAY[p_new_district_id::TEXT];
        v_placeholders := v_placeholders || ', $' || array_length(v_values, 1);
    END IF;

    -- 4. Chèn lại bản ghi
    v_insert_sql := format('INSERT INTO %I.%I (%s) VALUES (%s)', p_schema, p_table, v_cols, v_placeholders);
    RAISE NOTICE '[%] Thực thi INSERT: % (USING %)', clock_timestamp(), v_insert_sql, v_values; EXECUTE v_insert_sql USING VARIADIC v_values;

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Đã di chuyển thành công bản ghi % = % sang phân vùng mới (%s, %, %)', clock_timestamp(), p_key_column, p_key_value, p_new_geographical_region, p_new_province_id, p_new_district_id;
    PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Success', format('Đã di chuyển đến phân vùng mới (%s, %s, %s)', p_new_geographical_region, p_new_province_id, COALESCE(p_new_district_id::text, 'N/A')), 1, v_duration);
    RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE WARNING '[%] Lỗi khi di chuyển dữ liệu cho %.%, key %=%: %', clock_timestamp(), p_schema, p_table, p_key_column, p_key_value, SQLERRM;
    PERFORM partitioning.log_history(p_schema, p_table, format('%s=%s', p_key_column, p_key_value), 'MOVE_DATA', 'Failed', SQLERRM, NULL, v_duration);
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.move_data_between_partitions(TEXT, TEXT, TEXT, ANYELEMENT, TEXT, INTEGER, INTEGER)
    IS '[QLDCQG-BCA] Di chuyển một bản ghi cụ thể sang partition mới dựa trên thông tin phân vùng mới được cung cấp.';

-- Function: partitioning.create_partition_indexes
-- Description: Tự động tạo các index cần thiết trên TẤT CẢ các partition con.
CREATE OR REPLACE FUNCTION partitioning.create_partition_indexes(
    p_schema TEXT, p_table TEXT, p_index_definitions TEXT[]
) RETURNS VOID AS $$
DECLARE
    v_partition_name TEXT; v_index_def TEXT; v_index_name TEXT; v_sql TEXT;
    v_start_time TIMESTAMPTZ := clock_timestamp(); v_duration BIGINT;
BEGIN
    RAISE NOTICE '[%] Bắt đầu create_partition_indexes cho %.%...', v_start_time, p_schema, p_table;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Running', 'Bắt đầu tạo index trên các partition.');

    FOR v_partition_name IN
        SELECT c.relname FROM pg_catalog.pg_inherits i JOIN pg_catalog.pg_class c ON i.inhrelid = c.oid JOIN pg_catalog.pg_namespace nsp ON c.relnamespace = nsp.oid JOIN pg_catalog.pg_class parent ON i.inhparent = parent.oid
        WHERE parent.relname = p_table AND nsp.nspname = p_schema AND c.relkind = 'r'
    LOOP
        RAISE NOTICE '[%]   - Xử lý partition: %.%', clock_timestamp(), p_schema, v_partition_name;
        FOREACH v_index_def IN ARRAY p_index_definitions LOOP
            SELECT (regexp_matches(v_index_def, 'CREATE(?: UNIQUE)? INDEX\s+(?:IF NOT EXISTS\s+)?(\S+)\s+ON', 'i'))[1] INTO v_index_name;
            IF v_index_name IS NULL THEN RAISE WARNING '[%] Không thể trích xuất tên index từ: %', clock_timestamp(), v_index_def; CONTINUE; END IF;
            v_index_name := replace(v_index_name, '%2$s', v_partition_name); -- Thay placeholder tên partition

            IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_indexes WHERE schemaname = p_schema AND tablename = v_partition_name AND indexname = v_index_name) THEN
                BEGIN
                    v_sql := format(v_index_def, p_schema, v_partition_name);
                    RAISE NOTICE '[%]     Tạo index: %', clock_timestamp(), v_sql; EXECUTE v_sql;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name, 'CREATE_INDEX', 'Success', 'Đã tạo index: ' || v_index_name);
                EXCEPTION WHEN OTHERS THEN
                    RAISE WARNING '[%] Lỗi khi tạo index "%" trên partition %.%: %', clock_timestamp(), v_index_name, p_schema, v_partition_name, SQLERRM;
                    PERFORM partitioning.log_history(p_schema, p_table, v_partition_name, 'CREATE_INDEX', 'Failed', format('Lỗi tạo index %s: %s', v_index_name, SQLERRM));
                END;
            ELSE RAISE NOTICE '[%]     Index "%" đã tồn tại trên %.%.', clock_timestamp(), v_index_name, p_schema, v_partition_name;
            END IF;
        END LOOP;
    END LOOP;

    v_duration := EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000;
    RAISE NOTICE '[%] Hoàn thành create_partition_indexes cho %.% sau % ms.', clock_timestamp(), p_schema, p_table, v_duration;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'CREATE_INDEX', 'Success', format('Hoàn thành tạo index trên các partition sau %s ms.', v_duration), NULL, v_duration);
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.create_partition_indexes(TEXT, TEXT, TEXT[])
    IS '[QLDCQG-BCA] Tạo các index được định nghĩa trong mảng p_index_definitions trên tất cả các partition con của bảng p_table.';

-- Function: partitioning.generate_partition_report
-- Description: Tạo báo cáo về trạng thái các partition của các bảng được phân vùng.
CREATE OR REPLACE FUNCTION partitioning.generate_partition_report()
RETURNS TABLE ( schema_name TEXT, table_name TEXT, partition_name TEXT, partition_expression TEXT, row_count BIGINT, total_size_bytes BIGINT, total_size_pretty TEXT, last_analyzed TIMESTAMP WITH TIME ZONE, derived_region TEXT, derived_province TEXT, derived_district TEXT ) AS $$
BEGIN
    RETURN QUERY
    WITH partition_info AS (
        SELECT nsp.nspname AS schema_name, parent.relname AS table_name, child.relname AS partition_name, pg_catalog.pg_get_expr(child.relpartbound, child.oid) AS partition_expression
        FROM pg_catalog.pg_inherits inh JOIN pg_catalog.pg_class child ON inh.inhrelid = child.oid JOIN pg_catalog.pg_class parent ON inh.inhparent = parent.oid JOIN pg_catalog.pg_namespace nsp ON parent.relnamespace = nsp.oid
        WHERE child.relkind = 'r' AND nsp.nspname = 'public_security' -- Chỉ xét schema public_security
    ), partition_stats AS (
        SELECT pi.*, stat.n_live_tup + stat.n_dead_tup AS estimated_rows, pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name) AS total_size_bytes, pg_catalog.pg_size_pretty(pg_catalog.pg_total_relation_size(pi.schema_name || '.' || pi.partition_name)) AS total_size_pretty, stat.last_analyze AS last_analyzed,
               CASE WHEN pi.partition_name ~ ('_' || partitioning.standardize_name('BAC') || '(?:_|$)') THEN 'Bắc' WHEN pi.partition_name ~ ('_' || partitioning.standardize_name('TRUNG') || '(?:_|$)') THEN 'Trung' WHEN pi.partition_name ~ ('_' || partitioning.standardize_name('NAM') || '(?:_|$)') THEN 'Nam' ELSE NULL END AS derived_region_name,
               substring(pi.partition_name from p_conf.table_name || '_(?:bac|trung|nam)_([a-z0-9_]+)(?:_[a-z0-9_]+)?$') AS derived_province_std_code,
               substring(pi.partition_name from p_conf.table_name || '_(?:bac|trung|nam)_[a-z0-9_]+_([a-z0-9_]+)$') AS derived_district_std_code
        FROM partition_info pi LEFT JOIN pg_catalog.pg_stat_all_tables stat ON stat.schemaname = pi.schema_name AND stat.relname = pi.partition_name JOIN partitioning.config p_conf ON p_conf.schema_name = pi.schema_name AND p_conf.table_name = pi.table_name AND p_conf.is_active = TRUE
    )
    SELECT ps.schema_name::TEXT, ps.table_name::TEXT, ps.partition_name::TEXT, ps.partition_expression::TEXT, ps.estimated_rows::BIGINT, ps.total_size_bytes::BIGINT, ps.total_size_pretty::TEXT, ps.last_analyzed::TIMESTAMP WITH TIME ZONE, ps.derived_region_name::TEXT, prov.province_name::TEXT, dist.district_name::TEXT
    FROM partition_stats ps LEFT JOIN reference.provinces prov ON partitioning.standardize_name(prov.province_code) = ps.derived_province_std_code LEFT JOIN reference.districts dist ON partitioning.standardize_name(dist.district_code) = ps.derived_district_std_code AND dist.province_id = prov.province_id
    ORDER BY ps.schema_name, ps.table_name, ps.derived_region_name, prov.province_name, dist.district_name, ps.partition_name;
EXCEPTION WHEN undefined_table THEN
     RAISE NOTICE 'Bảng partitioning.config hoặc reference tables chưa tồn tại/đầy đủ, báo cáo có thể không đầy đủ.';
     RETURN QUERY SELECT NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::BIGINT, NULL::BIGINT, NULL::TEXT, NULL::TIMESTAMP WITH TIME ZONE, NULL::TEXT, NULL::TEXT, NULL::TEXT WHERE FALSE;
END;
$$ LANGUAGE plpgsql STABLE;
COMMENT ON FUNCTION partitioning.generate_partition_report()
    IS '[QLDCQG-BCA] Tạo báo cáo về trạng thái các partition của các bảng được phân vùng trong DB BCA.';

-- Function: partitioning.archive_old_partitions (Placeholder)
-- Description: Placeholder cho việc xử lý lưu trữ partition cũ theo thời gian (vd: cho audit_log).
CREATE OR REPLACE FUNCTION partitioning.archive_old_partitions(
    p_schema TEXT, p_table TEXT, p_retention_period INTERVAL
) RETURNS VOID AS $$
BEGIN
    RAISE NOTICE '[archive_old_partitions] Bắt đầu kiểm tra partition cũ cho %.% (lưu trữ %)...', p_schema, p_table, p_retention_period;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'ARCHIVE_START', 'Running', format('Bắt đầu kiểm tra partition cũ hơn %s', p_retention_period));
    -- >>> LOGIC CỤ THỂ CẦN TRIỂN KHAI Ở ĐÂY (ví dụ: DETACH PARTITION, RENAME, MOVE...) <<<
    RAISE WARNING '[archive_old_partitions] Logic xử lý lưu trữ partition cũ cho %.% chưa được triển khai đầy đủ!', p_schema, p_table;
    PERFORM partitioning.log_history(p_schema, p_table, p_table, 'ARCHIVE_COMPLETE', 'Skipped', 'Logic chưa triển khai đầy đủ.');
    RAISE NOTICE '[archive_old_partitions] Kết thúc kiểm tra (logic chưa đầy đủ) cho %.%.', p_schema, p_table;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION partitioning.archive_old_partitions(TEXT, TEXT, INTERVAL)
    IS '[QLDCQG-BCA] Placeholder - Xử lý tách và lưu trữ các partition cũ (cần triển khai logic cụ thể, ví dụ cho audit_log).';


-- === IV. CÁC HÀM NGHIỆP VỤ KHÁC (NẾU CÓ) ===

\echo '[4] Định nghĩa các hàm nghiệp vụ khác (nếu có)...'
-- Thêm các hàm PL/pgSQL khác đặc thù cho nghiệp vụ của BCA tại đây nếu cần.
-- Ví dụ: Hàm tính toán, kiểm tra logic phức tạp, API nội bộ...
-- CREATE OR REPLACE FUNCTION public_security.calculate_something(...) ...


\echo '*** HOÀN THÀNH ĐỊNH NGHĨA FUNCTIONS CHO DATABASE BỘ CÔNG AN ***'
\echo '-> Đã tạo các hàm hỗ trợ phân vùng và các hàm khác (nếu có).'
\echo '-> Bước tiếp theo: Chạy script 04_triggers.sql để tạo và gắn các trigger.'


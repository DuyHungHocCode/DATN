-- =============================================================================
-- File: database/init/setup_partitioning.sql
-- Description: Thiết lập phân vùng dữ liệu cho hệ thống quản lý dân cư quốc gia
-- Version: 2.0
-- 
-- Tính năng chính:
-- - Phân vùng dữ liệu theo 3 cấp: miền (Bắc, Trung, Nam) → tỉnh/thành phố → quận/huyện
-- - Sử dụng Declarative Partitioning của PostgreSQL với phân vùng lồng nhau
-- - Cải thiện hiệu suất truy vấn và quản lý dữ liệu theo đơn vị hành chính
-- =============================================================================

\echo 'Thiết lập phân vùng dữ liệu cho hệ thống quản lý dân cư quốc gia...'

-- ============================================================================
-- 1. THIẾT LẬP PHÂN VÙNG CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo 'Thiết lập phân vùng dữ liệu cho database Bộ Công an...'
\connect ministry_of_public_security

-- Tạo schema partitioning nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;

-- Tạo các bảng cấu hình phân vùng
CREATE TABLE IF NOT EXISTS partitioning.config (
    table_name VARCHAR(100) PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL, -- 'REGION', 'PROVINCE', 'DISTRICT', 'NESTED', 'RANGE', 'LIST'
    partition_column VARCHAR(200) NOT NULL, -- Có thể chứa nhiều cột phân tách bởi dấu phẩy
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tạo bảng lịch sử thao tác phân vùng
CREATE TABLE IF NOT EXISTS partitioning.history (
    history_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL, -- 'CREATE', 'DETACH', 'DROP', 'ARCHIVE', 'ATTACH'
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    affected_rows BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    notes TEXT
);

-- Tạo function khởi tạo phân vùng đơn giản theo vùng địa lý (dùng cho các bảng nhỏ và ít truy cập)
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
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng theo miền');

    -- Tạo câu lệnh SQL để chuyển bảng thành bảng phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        
        -- Tạo bảng mới với cấu trúc phân vùng
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned (LIKE %I.%I) 
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table, 
    p_column);
    
    -- Tạo các bảng con phân vùng
    FOREACH v_region IN ARRAY v_regions LOOP
        v_partition_name := p_table || '_' || lower(replace(v_region, 'ắ', 'a'));
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (''%s'');
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_region);
        
        EXECUTE v_sql;
        
        -- Ghi log tạo phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cho miền: ' || v_region);
    END LOOP;
    
    -- Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'REGION', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng theo miền');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function khởi tạo phân vùng phức tạp theo miền → tỉnh → quận/huyện (phân vùng lồng nhau)
CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT, 
    p_table TEXT,
    p_table_ddl TEXT,  -- Định nghĩa CREATE TABLE đầy đủ
    p_region_column TEXT,
    p_province_column TEXT,
    p_district_column TEXT,
    p_include_district BOOLEAN DEFAULT FALSE  -- Có bao gồm cấp quận/huyện không
) RETURNS BOOLEAN AS $$
DECLARE
    v_regions RECORD;
    v_provinces RECORD;
    v_districts RECORD;
    v_sql TEXT;
    v_partition_name TEXT;
    v_region_code TEXT;
    v_province_code TEXT;
    v_district_code TEXT;
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng đa cấp (miền → tỉnh → quận/huyện)');

    -- 1. Tạo bảng mới với cấu trúc phân vùng đa cấp
    EXECUTE format('
        -- Tạo bảng mới với partition by list
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned %s
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, p_table_ddl, p_region_column);
    
    -- 2. Lặp qua từng miền để tạo phân vùng cấp 1
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions
    LOOP
        -- Chuẩn hóa tên phân vùng
        v_region_code := lower(v_regions.region_code);
        v_partition_name := p_table || '_' || v_region_code;
        
        -- Tạo phân vùng cấp 1 (miền)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (''%s'')
            PARTITION BY LIST (%I);
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_regions.region_name, 
        p_province_column);
        
        -- Ghi log tạo phân vùng cấp 1
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 1 cho miền: ' || v_regions.region_name);
        
        -- 3. Lặp qua từng tỉnh trong miền để tạo phân vùng cấp 2
        FOR v_provinces IN SELECT province_id, province_code, province_name 
            FROM reference.provinces WHERE region_id = v_regions.region_id
        LOOP
            -- Chuẩn hóa tên phân vùng tỉnh
            v_province_code := lower(v_provinces.province_code);
            v_partition_name := p_table || '_' || v_region_code || '_' || v_province_code;
            
            -- Tạo phân vùng cấp 2 (tỉnh/thành phố)
            IF p_include_district THEN
                -- Nếu bao gồm cấp quận/huyện, tạo phân vùng tỉnh với partition by list
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I 
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L)
                    PARTITION BY LIST (%I);
                ', 
                p_schema, v_partition_name,
                p_schema, p_table || '_' || v_region_code,
                v_provinces.province_id, 
                p_district_column);
                
                -- Ghi log tạo phân vùng cấp 2
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 2 cho tỉnh: ' || v_provinces.province_name);
                
                -- 4. Lặp qua từng quận/huyện trong tỉnh để tạo phân vùng cấp 3
                FOR v_districts IN SELECT district_id, district_code, district_name 
                    FROM reference.districts WHERE province_id = v_provinces.province_id
                LOOP
                    -- Chuẩn hóa tên phân vùng quận/huyện
                    v_district_code := lower(v_districts.district_code);
                    v_partition_name := p_table || '_' || v_region_code || '_' || v_province_code || '_' || v_district_code;
                    
                    -- Tạo phân vùng cấp 3 (quận/huyện)
                    EXECUTE format('
                        CREATE TABLE IF NOT EXISTS %I.%I 
                        PARTITION OF %I.%I
                        FOR VALUES IN (%L);
                    ', 
                    p_schema, v_partition_name,
                    p_schema, p_table || '_' || v_region_code || '_' || v_province_code,
                    v_districts.district_id);
                    
                    -- Ghi log tạo phân vùng cấp 3
                    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                    VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 3 cho quận/huyện: ' || v_districts.district_name);
                END LOOP;
            ELSE
                -- Nếu không bao gồm cấp quận/huyện, tạo phân vùng tỉnh làm phân vùng cuối cùng
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I 
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L);
                ', 
                p_schema, v_partition_name,
                p_schema, p_table || '_' || v_region_code,
                v_provinces.province_id);
                
                -- Ghi log tạo phân vùng cấp 2 (cuối cùng)
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cuối cùng cho tỉnh: ' || v_provinces.province_name);
            END IF;
        END LOOP;
    END LOOP;
    
    -- 5. Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- 6. Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- 7. Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'NESTED', 
        CASE WHEN p_include_district 
            THEN p_region_column || ',' || p_province_column || ',' || p_district_column
            ELSE p_region_column || ',' || p_province_column
        END)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- 8. Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng đa cấp');
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        -- Ghi log lỗi
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, p_table, 'ERROR', 'Lỗi: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function để thiết lập phân vùng theo tỉnh/thành phố (cho các bảng tham chiếu)
CREATE OR REPLACE FUNCTION partitioning.setup_province_partitioning(
    p_schema TEXT, 
    p_table TEXT, 
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_provinces RECORD;
    v_partition_name TEXT;
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng theo tỉnh/thành phố');

    -- Tạo bảng mới với cấu trúc phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        
        -- Tạo bảng mới với partition by list
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned (LIKE %I.%I) 
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table, 
    p_column);
    
    -- Tạo các phân vùng cho từng tỉnh/thành phố
    FOR v_provinces IN SELECT province_id, province_code, province_name FROM reference.provinces
    LOOP
        -- Chuẩn hóa tên phân vùng
        v_partition_name := p_table || '_' || lower(v_provinces.province_code);
        
        -- Tạo phân vùng tỉnh/thành phố
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (%L);
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_provinces.province_id);
        
        EXECUTE v_sql;
        
        -- Ghi log tạo phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cho tỉnh/thành phố: ' || v_provinces.province_name);
    END LOOP;
    
    -- Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'PROVINCE', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng theo tỉnh/thành phố');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function cho phép chuyển dữ liệu giữa các phân vùng (cho hoạt động di chuyển dân cư)
CREATE OR REPLACE FUNCTION partitioning.move_data_between_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_citizen_id TEXT,
    p_old_region TEXT,
    p_new_region TEXT,
    p_old_province INTEGER,
    p_new_province INTEGER,
    p_old_district INTEGER DEFAULT NULL,
    p_new_district INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_temp_id TEXT;
    v_count INTEGER;
    v_sql TEXT;
BEGIN
    -- Tạo ID tạm thời duy nhất
    v_temp_id := 'TEMP-' || p_citizen_id || '-' || to_char(now(), 'YYYYMMDDHH24MISS');
    
    -- 1. Sao chép dữ liệu sang bảng tạm thời
    EXECUTE format('
        CREATE TEMPORARY TABLE IF NOT EXISTS temp_partition_move (LIKE %I.%I);
        
        INSERT INTO temp_partition_move
        SELECT * FROM %I.%I
        WHERE citizen_id = %L;
        
        SELECT count(*) INTO v_count FROM temp_partition_move;
    ', 
    p_schema, p_table,
    p_schema, p_table,
    p_citizen_id);
    
    -- Nếu không có dữ liệu để chuyển, trả về false
    IF v_count = 0 THEN
        DROP TABLE IF EXISTS temp_partition_move;
        RETURN FALSE;
    END IF;
    
    -- 2. Cập nhật thông tin địa lý cho dữ liệu tạm thời
    EXECUTE format('
        UPDATE temp_partition_move
        SET geographical_region = %L,
            province_id = %L,
            region_id = (SELECT region_id FROM reference.provinces WHERE province_id = %L)
            %s
    ', 
    p_new_region, 
    p_new_province,
    p_new_province,
    CASE WHEN p_new_district IS NOT NULL THEN ', district_id = ' || p_new_district ELSE '' END);
    
    -- 3. Xóa dữ liệu cũ
    EXECUTE format('
        DELETE FROM %I.%I
        WHERE citizen_id = %L
    ', 
    p_schema, p_table,
    p_citizen_id);
    
    -- 4. Chèn dữ liệu mới với thông tin địa lý đã cập nhật
    EXECUTE format('
        INSERT INTO %I.%I
        SELECT * FROM temp_partition_move
    ', 
    p_schema, p_table);
    
    -- Dọn dẹp bảng tạm thời
    DROP TABLE IF EXISTS temp_partition_move;
    
    -- Ghi log di chuyển dữ liệu
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (
        p_table, 
        p_schema, 
        'MOVE_DATA', 
        'MOVE',
        format('Di chuyển dữ liệu công dân %s từ %s(%s,%s) sang %s(%s,%s)', 
            p_citizen_id, 
            p_old_region, p_old_province, COALESCE(p_old_district::text, 'NULL'),
            p_new_region, p_new_province, COALESCE(p_new_district::text, 'NULL')
        )
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function gắn các bảng lưu trữ dữ liệu công dân vào phân vùng
CREATE OR REPLACE FUNCTION partitioning.setup_citizen_tables_partitioning() RETURNS VOID AS $$
DECLARE
    v_ddl_citizen TEXT;
    v_ddl_identification TEXT;
    v_ddl_biometric TEXT;
    v_ddl_address TEXT;
    v_ddl_citizen_status TEXT;
    v_ddl_criminal_record TEXT;
BEGIN
    -- Trích xuất cấu trúc SQL của các bảng để sử dụng trong phân vùng
    SELECT pg_get_tabledef('public_security.citizen') INTO v_ddl_citizen;
    SELECT pg_get_tabledef('public_security.identification_card') INTO v_ddl_identification;
    SELECT pg_get_tabledef('public_security.biometric_data') INTO v_ddl_biometric;
    SELECT pg_get_tabledef('public_security.address') INTO v_ddl_address;
    SELECT pg_get_tabledef('public_security.citizen_status') INTO v_ddl_citizen_status;
    SELECT pg_get_tabledef('public_security.criminal_record') INTO v_ddl_criminal_record;
    
    -- Phân vùng bảng citizen theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'citizen', v_ddl_citizen,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng identification_card theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'identification_card', v_ddl_identification,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
    
    -- Phân vùng bảng biometric_data theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'biometric_data', v_ddl_biometric,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
    
    -- Phân vùng bảng address theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'address', v_ddl_address,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng citizen_status theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'citizen_status', v_ddl_citizen_status,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
    
    -- Phân vùng bảng criminal_record theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'criminal_record', v_ddl_criminal_record,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
END;
$$ LANGUAGE plpgsql;

-- Tạo function gắn các bảng lưu trữ dữ liệu cư trú vào phân vùng
CREATE OR REPLACE FUNCTION partitioning.setup_residence_tables_partitioning() RETURNS VOID AS $$
DECLARE
    v_ddl_permanent TEXT;
    v_ddl_temporary TEXT;
    v_ddl_absence TEXT;
BEGIN
    -- Trích xuất cấu trúc SQL của các bảng để sử dụng trong phân vùng
    SELECT pg_get_tabledef('public_security.permanent_residence') INTO v_ddl_permanent;
    SELECT pg_get_tabledef('public_security.temporary_residence') INTO v_ddl_temporary;
    SELECT pg_get_tabledef('public_security.temporary_absence') INTO v_ddl_absence;
    
    -- Phân vùng bảng permanent_residence theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'permanent_residence', v_ddl_permanent,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng temporary_residence theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'temporary_residence', v_ddl_temporary,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng temporary_absence theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'public_security', 'temporary_absence', v_ddl_absence,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
END;
$$ LANGUAGE plpgsql;

-- Tạo function helper trích xuất cấu trúc tạo bảng
CREATE OR REPLACE FUNCTION pg_get_tabledef(p_table_name TEXT) RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_list TEXT;
BEGIN
    -- Trích xuất danh sách cột
    SELECT string_agg(column_name || ' ' || data_type || 
        CASE WHEN character_maximum_length IS NOT NULL 
            THEN '(' || character_maximum_length || ')' 
            ELSE '' END ||
        CASE WHEN is_nullable = 'NO' 
            THEN ' NOT NULL' 
            ELSE '' END, 
        ', ' ORDER BY ordinal_position) 
    INTO v_column_list
    FROM information_schema.columns
    WHERE table_name = split_part(p_table_name, '.', 2)
    AND table_schema = split_part(p_table_name, '.', 1);
    
    -- Tạo câu lệnh DDL
    v_table_ddl := '(' || v_column_list || ')';
    
    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. THIẾT LẬP PHÂN VÙNG CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Thiết lập phân vùng dữ liệu cho database Bộ Tư pháp...'
\connect ministry_of_justice

-- Tạo schema partitioning nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;

-- Tạo bảng cấu hình và lịch sử phân vùng (tương tự như ở Bộ Công an)
CREATE TABLE IF NOT EXISTS partitioning.config (
    table_name VARCHAR(100) PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL, -- 'REGION', 'PROVINCE', 'DISTRICT', 'NESTED', 'RANGE', 'LIST'
    partition_column VARCHAR(200) NOT NULL, -- Có thể chứa nhiều cột phân tách bởi dấu phẩy
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS partitioning.history (
    history_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL, -- 'CREATE', 'DETACH', 'DROP', 'ARCHIVE', 'ATTACH'
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    affected_rows BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    notes TEXT
);

-- Tạo các function tương tự như ở Bộ Công an
-- (Do tương tự nên chỉ tạo lại tham chiếu, nội dung copy từ khai báo ở Bộ Công an)
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
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng theo miền');

    -- Tạo câu lệnh SQL để chuyển bảng thành bảng phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        
        -- Tạo bảng mới với cấu trúc phân vùng
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned (LIKE %I.%I) 
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table, 
    p_column);
    
    -- Tạo các bảng con phân vùng
    FOREACH v_region IN ARRAY v_regions LOOP
        v_partition_name := p_table || '_' || lower(replace(v_region, 'ắ', 'a'));
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (''%s'');
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_region);
        
        EXECUTE v_sql;
        
        -- Ghi log tạo phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cho miền: ' || v_region);
    END LOOP;
    
    -- Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'REGION', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng theo miền');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT, 
    p_table TEXT,
    p_table_ddl TEXT,
    p_region_column TEXT,
    p_province_column TEXT,
    p_district_column TEXT,
    p_include_district BOOLEAN DEFAULT FALSE
) RETURNS BOOLEAN AS $$
-- [Nội dung copy từ khai báo trước]
DECLARE
    v_regions RECORD;
    v_provinces RECORD;
    v_districts RECORD;
    v_sql TEXT;
    v_partition_name TEXT;
    v_region_code TEXT;
    v_province_code TEXT;
    v_district_code TEXT;
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng đa cấp (miền → tỉnh → quận/huyện)');

    -- 1. Tạo bảng mới với cấu trúc phân vùng đa cấp
    EXECUTE format('
        -- Tạo bảng mới với partition by list
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned %s
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, p_table_ddl, p_region_column);
    
    -- 2. Lặp qua từng miền để tạo phân vùng cấp 1
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions
    LOOP
        -- Chuẩn hóa tên phân vùng
        v_region_code := lower(v_regions.region_code);
        v_partition_name := p_table || '_' || v_region_code;
        
        -- Tạo phân vùng cấp 1 (miền)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (''%s'')
            PARTITION BY LIST (%I);
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_regions.region_name, 
        p_province_column);
        
        -- Ghi log tạo phân vùng cấp 1
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 1 cho miền: ' || v_regions.region_name);
        
        -- 3. Lặp qua từng tỉnh trong miền để tạo phân vùng cấp 2
        FOR v_provinces IN SELECT province_id, province_code, province_name 
            FROM reference.provinces WHERE region_id = v_regions.region_id
        LOOP
            -- Chuẩn hóa tên phân vùng tỉnh
            v_province_code := lower(v_provinces.province_code);
            v_partition_name := p_table || '_' || v_region_code || '_' || v_province_code;
            
            -- Tạo phân vùng cấp 2 (tỉnh/thành phố)
            IF p_include_district THEN
                -- Nếu bao gồm cấp quận/huyện, tạo phân vùng tỉnh với partition by list
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I 
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L)
                    PARTITION BY LIST (%I);
                ', 
                p_schema, v_partition_name,
                p_schema, p_table || '_' || v_region_code,
                v_provinces.province_id, 
                p_district_column);
                
                -- Ghi log tạo phân vùng cấp 2
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 2 cho tỉnh: ' || v_provinces.province_name);
                
                -- 4. Lặp qua từng quận/huyện trong tỉnh để tạo phân vùng cấp 3
                FOR v_districts IN SELECT district_id, district_code, district_name 
                    FROM reference.districts WHERE province_id = v_provinces.province_id
                LOOP
                    -- Chuẩn hóa tên phân vùng quận/huyện
                    v_district_code := lower(v_districts.district_code);
                    v_partition_name := p_table || '_' || v_region_code || '_' || v_province_code || '_' || v_district_code;
                    
                    -- Tạo phân vùng cấp 3 (quận/huyện)
                    EXECUTE format('
                        CREATE TABLE IF NOT EXISTS %I.%I 
                        PARTITION OF %I.%I
                        FOR VALUES IN (%L);
                    ', 
                    p_schema, v_partition_name,
                    p_schema, p_table || '_' || v_region_code || '_' || v_province_code,
                    v_districts.district_id);
                    
                    -- Ghi log tạo phân vùng cấp 3
                    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                    VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 3 cho quận/huyện: ' || v_districts.district_name);
                END LOOP;
            ELSE
                -- Nếu không bao gồm cấp quận/huyện, tạo phân vùng tỉnh làm phân vùng cuối cùng
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I 
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L);
                ', 
                p_schema, v_partition_name,
                p_schema, p_table || '_' || v_region_code,
                v_provinces.province_id);
                
                -- Ghi log tạo phân vùng cấp 2 (cuối cùng)
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cuối cùng cho tỉnh: ' || v_provinces.province_name);
            END IF;
        END LOOP;
    END LOOP;
    
    -- 5. Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- 6. Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- 7. Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'NESTED', 
        CASE WHEN p_include_district 
            THEN p_region_column || ',' || p_province_column || ',' || p_district_column
            ELSE p_region_column || ',' || p_province_column
        END)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- 8. Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng đa cấp');
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        -- Ghi log lỗi
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, p_table, 'ERROR', 'Lỗi: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION partitioning.setup_province_partitioning(
    p_schema TEXT, 
    p_table TEXT, 
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_provinces RECORD;
    v_partition_name TEXT;
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng theo tỉnh/thành phố');

    -- Tạo bảng mới với cấu trúc phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        
        -- Tạo bảng mới với partition by list
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned (LIKE %I.%I) 
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table, 
    p_column);
    
    -- Tạo các phân vùng cho từng tỉnh/thành phố
    FOR v_provinces IN SELECT province_id, province_code, province_name FROM reference.provinces
    LOOP
        -- Chuẩn hóa tên phân vùng
        v_partition_name := p_table || '_' || lower(v_provinces.province_code);
        
        -- Tạo phân vùng tỉnh/thành phố
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (%L);
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_provinces.province_id);
        
        EXECUTE v_sql;
        
        -- Ghi log tạo phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cho tỉnh/thành phố: ' || v_provinces.province_name);
    END LOOP;
    
    -- Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'PROVINCE', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng theo tỉnh/thành phố');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function cho phép chuyển dữ liệu giữa các phân vùng (cho hoạt động di chuyển dân cư)
CREATE OR REPLACE FUNCTION partitioning.move_data_between_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_citizen_id TEXT,
    p_old_region TEXT,
    p_new_region TEXT,
    p_old_province INTEGER,
    p_new_province INTEGER,
    p_old_district INTEGER DEFAULT NULL,
    p_new_district INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_temp_id TEXT;
    v_count INTEGER;
    v_sql TEXT;
BEGIN
    -- Tạo ID tạm thời duy nhất
    v_temp_id := 'TEMP-' || p_citizen_id || '-' || to_char(now(), 'YYYYMMDDHH24MISS');
    
    -- 1. Sao chép dữ liệu sang bảng tạm thời
    EXECUTE format('
        CREATE TEMPORARY TABLE IF NOT EXISTS temp_partition_move (LIKE %I.%I);
        
        INSERT INTO temp_partition_move
        SELECT * FROM %I.%I
        WHERE citizen_id = %L;
        
        SELECT count(*) INTO v_count FROM temp_partition_move;
    ', 
    p_schema, p_table,
    p_schema, p_table,
    p_citizen_id);
    
    -- Nếu không có dữ liệu để chuyển, trả về false
    IF v_count = 0 THEN
        DROP TABLE IF EXISTS temp_partition_move;
        RETURN FALSE;
    END IF;
    
    -- 2. Cập nhật thông tin địa lý cho dữ liệu tạm thời
    EXECUTE format('
        UPDATE temp_partition_move
        SET geographical_region = %L,
            province_id = %L,
            region_id = (SELECT region_id FROM reference.provinces WHERE province_id = %L)
            %s
    ', 
    p_new_region, 
    p_new_province,
    p_new_province,
    CASE WHEN p_new_district IS NOT NULL THEN ', district_id = ' || p_new_district ELSE '' END);
    
    -- 3. Xóa dữ liệu cũ
    EXECUTE format('
        DELETE FROM %I.%I
        WHERE citizen_id = %L
    ', 
    p_schema, p_table,
    p_citizen_id);
    
    -- 4. Chèn dữ liệu mới với thông tin địa lý đã cập nhật
    EXECUTE format('
        INSERT INTO %I.%I
        SELECT * FROM temp_partition_move
    ', 
    p_schema, p_table);
    
    -- Dọn dẹp bảng tạm thời
    DROP TABLE IF EXISTS temp_partition_move;
    
    -- Ghi log di chuyển dữ liệu
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (
        p_table, 
        p_schema, 
        'MOVE_DATA', 
        'MOVE',
        format('Di chuyển dữ liệu công dân %s từ %s(%s,%s) sang %s(%s,%s)', 
            p_citizen_id, 
            p_old_region, p_old_province, COALESCE(p_old_district::text, 'NULL'),
            p_new_region, p_new_province, COALESCE(p_new_district::text, 'NULL')
        )
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pg_get_tabledef(p_table_name TEXT) RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_list TEXT;
BEGIN
    -- Trích xuất danh sách cột
    SELECT string_agg(column_name || ' ' || data_type || 
        CASE WHEN character_maximum_length IS NOT NULL 
            THEN '(' || character_maximum_length || ')' 
            ELSE '' END ||
        CASE WHEN is_nullable = 'NO' 
            THEN ' NOT NULL' 
            ELSE '' END, 
        ', ' ORDER BY ordinal_position) 
    INTO v_column_list
    FROM information_schema.columns
    WHERE table_name = split_part(p_table_name, '.', 2)
    AND table_schema = split_part(p_table_name, '.', 1);
    
    -- Tạo câu lệnh DDL
    v_table_ddl := '(' || v_column_list || ')';
    
    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql;


-- Tạo function thiết lập phân vùng cho các bảng hộ tịch
CREATE OR REPLACE FUNCTION partitioning.setup_civil_status_tables_partitioning() RETURNS VOID AS $$
DECLARE
    v_ddl_birth TEXT;
    v_ddl_death TEXT;
    v_ddl_marriage TEXT;
    v_ddl_divorce TEXT;
BEGIN
    -- Trích xuất cấu trúc SQL của các bảng để sử dụng trong phân vùng
    SELECT pg_get_tabledef('justice.birth_certificate') INTO v_ddl_birth;
    SELECT pg_get_tabledef('justice.death_certificate') INTO v_ddl_death;
    SELECT pg_get_tabledef('justice.marriage') INTO v_ddl_marriage;
    SELECT pg_get_tabledef('justice.divorce') INTO v_ddl_divorce;
    
    -- Phân vùng bảng birth_certificate theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'birth_certificate', v_ddl_birth,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng death_certificate theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'death_certificate', v_ddl_death,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng marriage theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'marriage', v_ddl_marriage,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng divorce theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'divorce', v_ddl_divorce,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
END;
$$ LANGUAGE plpgsql;

-- Tạo function thiết lập phân vùng cho các bảng hộ khẩu và gia đình
CREATE OR REPLACE FUNCTION partitioning.setup_household_tables_partitioning() RETURNS VOID AS $$
DECLARE
    v_ddl_household TEXT;
    v_ddl_household_member TEXT;
    v_ddl_family_relationship TEXT;
    v_ddl_population_change TEXT;
BEGIN
    -- Trích xuất cấu trúc SQL của các bảng để sử dụng trong phân vùng
    SELECT pg_get_tabledef('justice.household') INTO v_ddl_household;
    SELECT pg_get_tabledef('justice.household_member') INTO v_ddl_household_member;
    SELECT pg_get_tabledef('justice.family_relationship') INTO v_ddl_family_relationship;
    SELECT pg_get_tabledef('justice.population_change') INTO v_ddl_population_change;
    
    -- Phân vùng bảng household theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'household', v_ddl_household,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng household_member theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'household_member', v_ddl_household_member,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
    
    -- Phân vùng bảng family_relationship theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'family_relationship', v_ddl_family_relationship,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
    
    -- Phân vùng bảng population_change theo 2 cấp (miền -> tỉnh)
    PERFORM partitioning.setup_nested_partitioning(
        'justice', 'population_change', v_ddl_population_change,
        'geographical_region', 'province_id', 'district_id', FALSE
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. THIẾT LẬP PHÂN VÙNG CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Thiết lập phân vùng dữ liệu cho database Máy chủ trung tâm...'
\connect national_citizen_central_server

-- Tạo schema partitioning nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;

-- Tạo bảng cấu hình và lịch sử phân vùng (tương tự như ở Bộ Công an)
CREATE TABLE IF NOT EXISTS partitioning.config (
    table_name VARCHAR(100) PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL, -- 'REGION', 'PROVINCE', 'DISTRICT', 'NESTED', 'RANGE', 'LIST'
    partition_column VARCHAR(200) NOT NULL, -- Có thể chứa nhiều cột phân tách bởi dấu phẩy
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS partitioning.history (
    history_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL, -- 'CREATE', 'DETACH', 'DROP', 'ARCHIVE', 'ATTACH'
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    affected_rows BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    notes TEXT
);

-- Tạo các function tương tự như ở Bộ Công an
-- (Do tương tự nên chỉ tạo lại tham chiếu, nội dung copy từ khai báo ở Bộ Công an)
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
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng theo miền');

    -- Tạo câu lệnh SQL để chuyển bảng thành bảng phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        
        -- Tạo bảng mới với cấu trúc phân vùng
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned (LIKE %I.%I) 
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table, 
    p_column);
    
    -- Tạo các bảng con phân vùng
    FOREACH v_region IN ARRAY v_regions LOOP
        v_partition_name := p_table || '_' || lower(replace(v_region, 'ắ', 'a'));
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (''%s'');
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_region);
        
        EXECUTE v_sql;
        
        -- Ghi log tạo phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cho miền: ' || v_region);
    END LOOP;
    
    -- Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'REGION', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng theo miền');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;   



CREATE OR REPLACE FUNCTION partitioning.setup_nested_partitioning(
    p_schema TEXT, 
    p_table TEXT,
    p_table_ddl TEXT,
    p_region_column TEXT,
    p_province_column TEXT,
    p_district_column TEXT,
    p_include_district BOOLEAN DEFAULT FALSE
) RETURNS BOOLEAN AS $$
DECLARE
    v_regions RECORD;
    v_provinces RECORD;
    v_districts RECORD;
    v_sql TEXT;
    v_partition_name TEXT;
    v_region_code TEXT;
    v_province_code TEXT;
    v_district_code TEXT;
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng đa cấp (miền → tỉnh → quận/huyện)');

    -- 1. Tạo bảng mới với cấu trúc phân vùng đa cấp
    EXECUTE format('
        -- Tạo bảng mới với partition by list
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned %s
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, p_table_ddl, p_region_column);
    
    -- 2. Lặp qua từng miền để tạo phân vùng cấp 1
    FOR v_regions IN SELECT region_id, region_code, region_name FROM reference.regions
    LOOP
        -- Chuẩn hóa tên phân vùng
        v_region_code := lower(v_regions.region_code);
        v_partition_name := p_table || '_' || v_region_code;
        
        -- Tạo phân vùng cấp 1 (miền)
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (''%s'')
            PARTITION BY LIST (%I);
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_regions.region_name, 
        p_province_column);
        
        -- Ghi log tạo phân vùng cấp 1
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 1 cho miền: ' || v_regions.region_name);
        
        -- 3. Lặp qua từng tỉnh trong miền để tạo phân vùng cấp 2
        FOR v_provinces IN SELECT province_id, province_code, province_name 
            FROM reference.provinces WHERE region_id = v_regions.region_id
        LOOP
            -- Chuẩn hóa tên phân vùng tỉnh
            v_province_code := lower(v_provinces.province_code);
            v_partition_name := p_table || '_' || v_region_code || '_' || v_province_code;
            
            -- Tạo phân vùng cấp 2 (tỉnh/thành phố)
            IF p_include_district THEN
                -- Nếu bao gồm cấp quận/huyện, tạo phân vùng tỉnh với partition by list
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I 
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L)
                    PARTITION BY LIST (%I);
                ', 
                p_schema, v_partition_name,
                p_schema, p_table || '_' || v_region_code,
                v_provinces.province_id, 
                p_district_column);
                
                -- Ghi log tạo phân vùng cấp 2
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 2 cho tỉnh: ' || v_provinces.province_name);
                
                -- 4. Lặp qua từng quận/huyện trong tỉnh để tạo phân vùng cấp 3
                FOR v_districts IN SELECT district_id, district_code, district_name 
                    FROM reference.districts WHERE province_id = v_provinces.province_id
                LOOP
                    -- Chuẩn hóa tên phân vùng quận/huyện
                    v_district_code := lower(v_districts.district_code);
                    v_partition_name := p_table || '_' || v_region_code || '_' || v_province_code || '_' || v_district_code;
                    
                    -- Tạo phân vùng cấp 3 (quận/huyện)
                    EXECUTE format('
                        CREATE TABLE IF NOT EXISTS %I.%I 
                        PARTITION OF %I.%I
                        FOR VALUES IN (%L);
                    ', 
                    p_schema, v_partition_name,
                    p_schema, p_table || '_' || v_region_code || '_' || v_province_code,
                    v_districts.district_id);
                    
                    -- Ghi log tạo phân vùng cấp 3
                    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                    VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cấp 3 cho quận/huyện: ' || v_districts.district_name);
                END LOOP;
            ELSE
                -- Nếu không bao gồm cấp quận/huyện, tạo phân vùng tỉnh làm phân vùng cuối cùng
                EXECUTE format('
                    CREATE TABLE IF NOT EXISTS %I.%I 
                    PARTITION OF %I.%I
                    FOR VALUES IN (%L);
                ', 
                p_schema, v_partition_name,
                p_schema, p_table || '_' || v_region_code,
                v_provinces.province_id);
                
                -- Ghi log tạo phân vùng cấp 2 (cuối cùng)
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cuối cùng cho tỉnh: ' || v_provinces.province_name);
            END IF;
        END LOOP;
    END LOOP;
    
    -- 5. Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- 6. Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- 7. Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'NESTED', 
        CASE WHEN p_include_district 
            THEN p_region_column || ',' || p_province_column || ',' || p_district_column
            ELSE p_region_column || ',' || p_province_column
        END)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- 8. Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng đa cấp');
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        -- Ghi log lỗi
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, p_table, 'ERROR', 'Lỗi: ' || SQLERRM);
        RAISE;
END;
$$ LANGUAGE plpgsql;  

CREATE OR REPLACE FUNCTION partitioning.setup_province_partitioning(
    p_schema TEXT, 
    p_table TEXT, 
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_provinces RECORD;
    v_partition_name TEXT;
BEGIN
    -- Ghi log bắt đầu tạo phân vùng
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'INIT', 'Bắt đầu thiết lập phân vùng theo tỉnh/thành phố');

    -- Tạo bảng mới với cấu trúc phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        
        -- Tạo bảng mới với partition by list
        CREATE TABLE IF NOT EXISTS %I.%I_partitioned (LIKE %I.%I) 
        PARTITION BY LIST (%I);
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table, 
    p_column);
    
    -- Tạo các phân vùng cho từng tỉnh/thành phố
    FOR v_provinces IN SELECT province_id, province_code, province_name FROM reference.provinces
    LOOP
        -- Chuẩn hóa tên phân vùng
        v_partition_name := p_table || '_' || lower(v_provinces.province_code);
        
        -- Tạo phân vùng tỉnh/thành phố
        v_sql := format('
            CREATE TABLE IF NOT EXISTS %I.%I 
            PARTITION OF %I.%I_partitioned
            FOR VALUES IN (%L);
        ', 
        p_schema, v_partition_name, 
        p_schema, p_table || '_partitioned', 
        v_provinces.province_id);
        
        EXECUTE v_sql;
        
        -- Ghi log tạo phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, v_partition_name, 'CREATE', 'Tạo phân vùng cho tỉnh/thành phố: ' || v_provinces.province_name);
    END LOOP;
    
    -- Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng mới
    EXECUTE format('
        INSERT INTO %I.%I_partitioned
        SELECT * FROM %I.%I;
    ', 
    p_schema, p_table, 
    p_schema, p_table);
    
    -- Đổi tên bảng
    EXECUTE format('
        ALTER TABLE %I.%I RENAME TO %I_old;
        ALTER TABLE %I.%I_partitioned RENAME TO %I;
    ', 
    p_schema, p_table, p_table, 
    p_schema, p_table, p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'PROVINCE', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    -- Ghi log hoàn thành
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, p_table, 'COMPLETE', 'Hoàn thành thiết lập phân vùng theo tỉnh/thành phố');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION partitioning.move_data_between_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_citizen_id TEXT,
    p_old_region TEXT,
    p_new_region TEXT,
    p_old_province INTEGER,
    p_new_province INTEGER,
    p_old_district INTEGER DEFAULT NULL,
    p_new_district INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_temp_id TEXT;
    v_count INTEGER;
    v_sql TEXT;
BEGIN
    -- Tạo ID tạm thời duy nhất
    v_temp_id := 'TEMP-' || p_citizen_id || '-' || to_char(now(), 'YYYYMMDDHH24MISS');
    
    -- 1. Sao chép dữ liệu sang bảng tạm thời
    EXECUTE format('
        CREATE TEMPORARY TABLE IF NOT EXISTS temp_partition_move (LIKE %I.%I);
        
        INSERT INTO temp_partition_move
        SELECT * FROM %I.%I
        WHERE citizen_id = %L;
        
        SELECT count(*) INTO v_count FROM temp_partition_move;
    ', 
    p_schema, p_table,
    p_schema, p_table,
    p_citizen_id);
    
    -- Nếu không có dữ liệu để chuyển, trả về false
    IF v_count = 0 THEN
        DROP TABLE IF EXISTS temp_partition_move;
        RETURN FALSE;
    END IF;
    
    -- 2. Cập nhật thông tin địa lý cho dữ liệu tạm thời
    EXECUTE format('
        UPDATE temp_partition_move
        SET geographical_region = %L,
            province_id = %L,
            region_id = (SELECT region_id FROM reference.provinces WHERE province_id = %L)
            %s
    ', 
    p_new_region, 
    p_new_province,
    p_new_province,
    CASE WHEN p_new_district IS NOT NULL THEN ', district_id = ' || p_new_district ELSE '' END);
    
    -- 3. Xóa dữ liệu cũ
    EXECUTE format('
        DELETE FROM %I.%I
        WHERE citizen_id = %L
    ', 
    p_schema, p_table,
    p_citizen_id);
    
    -- 4. Chèn dữ liệu mới với thông tin địa lý đã cập nhật
    EXECUTE format('
        INSERT INTO %I.%I
        SELECT * FROM temp_partition_move
    ', 
    p_schema, p_table);
    
    -- Dọn dẹp bảng tạm thời
    DROP TABLE IF EXISTS temp_partition_move;
    
    -- Ghi log di chuyển dữ liệu
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (
        p_table, 
        p_schema, 
        'MOVE_DATA', 
        'MOVE',
        format('Di chuyển dữ liệu công dân %s từ %s(%s,%s) sang %s(%s,%s)', 
            p_citizen_id, 
            p_old_region, p_old_province, COALESCE(p_old_district::text, 'NULL'),
            p_new_region, p_new_province, COALESCE(p_new_district::text, 'NULL')
        )
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function helper trích xuất cấu trúc tạo bảng
CREATE OR REPLACE FUNCTION pg_get_tabledef(p_table_name TEXT) RETURNS TEXT AS $$
DECLARE
    v_table_ddl TEXT;
    v_column_list TEXT;
BEGIN
    -- Trích xuất danh sách cột
    SELECT string_agg(column_name || ' ' || data_type || 
        CASE WHEN character_maximum_length IS NOT NULL 
            THEN '(' || character_maximum_length || ')' 
            ELSE '' END ||
        CASE WHEN is_nullable = 'NO' 
            THEN ' NOT NULL' 
            ELSE '' END, 
        ', ' ORDER BY ordinal_position) 
    INTO v_column_list
    FROM information_schema.columns
    WHERE table_name = split_part(p_table_name, '.', 2)
    AND table_schema = split_part(p_table_name, '.', 1);
    
    -- Tạo câu lệnh DDL
    v_table_ddl := '(' || v_column_list || ')';
    
    RETURN v_table_ddl;
END;
$$ LANGUAGE plpgsql;

-- Tạo function thiết lập phân vùng cho các bảng dữ liệu tích hợp
CREATE OR REPLACE FUNCTION partitioning.setup_integrated_data_partitioning() RETURNS VOID AS $$
DECLARE
    v_ddl_integrated_citizen TEXT;
    v_ddl_integrated_household TEXT;
    v_ddl_sync_status TEXT;
    v_ddl_analytics TEXT;
BEGIN
    -- Trích xuất cấu trúc SQL của các bảng để sử dụng trong phân vùng
    SELECT pg_get_tabledef('central.integrated_citizen') INTO v_ddl_integrated_citizen;
    SELECT pg_get_tabledef('central.integrated_household') INTO v_ddl_integrated_household;
    SELECT pg_get_tabledef('central.sync_status') INTO v_ddl_sync_status;
    SELECT pg_get_tabledef('central.analytics_tables') INTO v_ddl_analytics;
    
    -- Phân vùng bảng integrated_citizen theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'central', 'integrated_citizen', v_ddl_integrated_citizen,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng integrated_household theo 3 cấp (miền -> tỉnh -> quận/huyện)
    PERFORM partitioning.setup_nested_partitioning(
        'central', 'integrated_household', v_ddl_integrated_household,
        'geographical_region', 'province_id', 'district_id', TRUE
    );
    
    -- Phân vùng bảng sync_status theo miền
    PERFORM partitioning.setup_region_partitioning(
        'central', 'sync_status', 'geographical_region'
    );
    
    -- Phân vùng bảng analytics theo miền
    PERFORM partitioning.setup_region_partitioning(
        'central', 'analytics_tables', 'geographical_region'
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. CÁC CHỨC NĂNG BẢO TRÌ VÀ GIÁM SÁT PHÂN VÙNG
-- ============================================================================

-- Tạo function tạo báo cáo về phân vùng dữ liệu
CREATE OR REPLACE FUNCTION partitioning.generate_partition_report() RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    partition_name TEXT,
    row_count BIGINT,
    total_size_bytes BIGINT,
    total_size_pretty TEXT,
    last_analyzed TIMESTAMP,
    region TEXT,
    province TEXT,
    district TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH partition_stats AS (
        SELECT 
            nsp.nspname AS schema_name,
            rel.relname AS table_name,
            child.relname AS partition_name,
            pg_stat_get_numrows(child.oid) AS row_count,
            pg_total_relation_size(child.oid) AS total_size_bytes,
            pg_size_pretty(pg_total_relation_size(child.oid)) AS total_size_pretty,
            stats.last_analyze AS last_analyzed,
            -- Trích xuất thông tin khu vực từ tên phân vùng (có thể cải thiện với regex)
            split_part(split_part(child.relname, '_', 2), '_', 1) AS region_code,
            CASE
                WHEN child.relname ~ '_bac_[a-z]+'
                THEN split_part(split_part(child.relname, '_bac_', 2), '_', 1)
                WHEN child.relname ~ '_trung_[a-z]+'
                THEN split_part(split_part(child.relname, '_trung_', 2), '_', 1)
                WHEN child.relname ~ '_nam_[a-z]+'
                THEN split_part(split_part(child.relname, '_nam_', 2), '_', 1)
                ELSE NULL
            END AS province_code,
            CASE
                WHEN child.relname ~ '_bac_[a-z]+_[a-z]+'
                THEN split_part(split_part(child.relname, '_bac_', 2), '_', 2)
                WHEN child.relname ~ '_trung_[a-z]+_[a-z]+'
                THEN split_part(split_part(child.relname, '_trung_', 2), '_', 2)
                WHEN child.relname ~ '_nam_[a-z]+_[a-z]+'
                THEN split_part(split_part(child.relname, '_nam_', 2), '_', 2)
                ELSE NULL
            END AS district_code
        FROM pg_inherits
        JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
        JOIN pg_class child ON pg_inherits.inhrelid = child.oid
        JOIN pg_namespace nsp ON parent.relnamespace = nsp.oid
        LEFT JOIN pg_stat_all_tables stats ON child.oid = stats.relid
        WHERE nsp.nspname NOT IN ('pg_catalog', 'information_schema')
        ORDER BY 
            nsp.nspname,
            parent.relname,
            child.relname
    )
    SELECT 
        ps.schema_name,
        ps.table_name,
        ps.partition_name,
        ps.row_count,
        ps.total_size_bytes,
        ps.total_size_pretty,
        ps.last_analyzed,
        CASE 
            WHEN ps.region_code = 'bac' THEN 'Bắc'
            WHEN ps.region_code = 'trung' THEN 'Trung'
            WHEN ps.region_code = 'nam' THEN 'Nam'
            ELSE NULL
        END AS region,
        COALESCE(prov.province_name, '') AS province,
        COALESCE(dist.district_name, '') AS district
    FROM 
        partition_stats ps
    LEFT JOIN 
        reference.provinces prov ON lower(prov.province_code) = ps.province_code
    LEFT JOIN 
        reference.districts dist ON lower(dist.district_code) = ps.district_code;
END;
$$ LANGUAGE plpgsql;

-- Tạo function để tự động xác định phân vùng cho dữ liệu mới
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
    -- Tìm địa chỉ thường trú của công dân
    SELECT address_id INTO v_address_id
    FROM public_security.permanent_residence
    WHERE citizen_id = p_citizen_id AND status = TRUE
    ORDER BY registration_date DESC
    LIMIT 1;
    
    -- Nếu không có địa chỉ thường trú, tìm địa chỉ tạm trú
    IF v_address_id IS NULL THEN
        SELECT address_id INTO v_address_id
        FROM public_security.temporary_residence
        WHERE citizen_id = p_citizen_id AND status = 'Active'
        ORDER BY registration_date DESC
        LIMIT 1;
    END IF;
    
    -- Nếu có địa chỉ, lấy thông tin tỉnh/quận
    IF v_address_id IS NOT NULL THEN
        SELECT province_id, district_id
        INTO v_province_id, v_district_id
        FROM public_security.address
        WHERE address_id = v_address_id;
        
        -- Lấy thông tin vùng
        SELECT region_id INTO v_region_id
        FROM reference.provinces
        WHERE province_id = v_province_id;
        
        -- Trả về thông tin phân vùng
        RETURN QUERY
        SELECT
            CASE
                WHEN v_region_id = 1 THEN 'Bắc'
                WHEN v_region_id = 2 THEN 'Trung'
                WHEN v_region_id = 3 THEN 'Nam'
                ELSE 'Bắc' -- Mặc định nếu không xác định được
            END AS geographical_region,
            v_province_id,
            v_district_id;
    ELSE
        -- Mặc định nếu không tìm thấy địa chỉ
        RETURN QUERY
        SELECT 'Bắc'::TEXT, 1::INTEGER, 101::INTEGER;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Tạo function để quản lý phân vùng theo thời gian (archiving)
CREATE OR REPLACE FUNCTION partitioning.archive_old_partitions(
    p_schema TEXT,
    p_table TEXT,
    p_months INTEGER DEFAULT 60 -- Mặc định lưu trữ dữ liệu cũ hơn 5 năm
) RETURNS VOID AS $$
DECLARE
    v_partition_name TEXT;
    v_archive_date DATE;
    v_row_count BIGINT;
    v_sql TEXT;
BEGIN
    -- Xác định ngày lưu trữ
    v_archive_date := CURRENT_DATE - INTERVAL '1 month' * p_months;
    
    -- Ghi log bắt đầu quy trình lưu trữ
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, 'ALL', 'ARCHIVE_START', 'Bắt đầu lưu trữ các phân vùng cũ hơn ' || p_months || ' tháng');
    
    -- Tìm và lưu trữ các phân vùng thời gian cũ
    -- (Chỉ áp dụng cho các bảng có phân vùng theo thời gian)
    FOR v_partition_name IN 
        SELECT child.relname
        FROM pg_inherits
        JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
        JOIN pg_class child ON pg_inherits.inhrelid = child.oid
        JOIN pg_namespace nsp ON parent.relnamespace = nsp.oid
        WHERE nsp.nspname = p_schema
          AND parent.relname = p_table
          AND child.relname ~ '_time_[0-9]{6}' -- Pattern cho phân vùng thời gian YYYYMM
          AND to_date(substring(child.relname FROM '_time_([0-9]{6})'), 'YYYYMM') < v_archive_date
    LOOP
        -- Đếm số lượng bản ghi trong phân vùng
        EXECUTE format('SELECT count(*) FROM %I.%I', p_schema, v_partition_name) INTO v_row_count;
        
        -- Ghi log phân vùng cần lưu trữ
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes, affected_rows)
        VALUES (p_table, p_schema, v_partition_name, 'ARCHIVE', 'Đang lưu trữ phân vùng', v_row_count);
        
        -- Tạo bảng lưu trữ
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I.%I_archive (LIKE %I.%I);
            INSERT INTO %I.%I_archive SELECT * FROM %I.%I;
        ', 
        p_schema, v_partition_name,
        p_schema, v_partition_name,
        p_schema, v_partition_name,
        p_schema, v_partition_name);
        
        -- Tách phân vùng khỏi bảng chính
        EXECUTE format('
            ALTER TABLE %I.%I DETACH PARTITION %I.%I;
        ',
        p_schema, p_table,
        p_schema, v_partition_name);
        
        -- Ghi log hoàn thành lưu trữ phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes, affected_rows)
        VALUES (p_table, p_schema, v_partition_name, 'ARCHIVED', 'Đã lưu trữ thành công', v_row_count);
    END LOOP;
    
    -- Ghi log kết thúc quy trình lưu trữ
    INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
    VALUES (p_table, p_schema, 'ALL', 'ARCHIVE_COMPLETE', 'Hoàn thành lưu trữ các phân vùng cũ');
END;
$$ LANGUAGE plpgsql;

-- Tạo function để tạo tự động chỉ mục trên các phân vùng
CREATE OR REPLACE FUNCTION partitioning.create_partition_indexes(
    p_schema TEXT,
    p_table TEXT,
    p_index_columns TEXT[] -- Mảng các cột cần đánh chỉ mục
) RETURNS VOID AS $$
DECLARE
    v_partition_name TEXT;
    v_column TEXT;
    v_index_name TEXT;
    v_sql TEXT;
BEGIN
    -- Lặp qua tất cả các phân vùng của bảng
    FOR v_partition_name IN 
        SELECT child.relname
        FROM pg_inherits
        JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
        JOIN pg_class child ON pg_inherits.inhrelid = child.oid
        JOIN pg_namespace nsp ON parent.relnamespace = nsp.oid
        WHERE nsp.nspname = p_schema
          AND parent.relname = p_table
    LOOP
        -- Lặp qua các cột cần đánh chỉ mục
        FOREACH v_column IN ARRAY p_index_columns
        LOOP
            -- Tạo tên chỉ mục
            v_index_name := 'idx_' || v_partition_name || '_' || v_column;
            
            -- Kiểm tra xem chỉ mục đã tồn tại chưa
            PERFORM 1
            FROM pg_indexes
            WHERE schemaname = p_schema
              AND tablename = v_partition_name
              AND indexname = v_index_name;
            
            -- Nếu chỉ mục chưa tồn tại, tạo mới
            IF NOT FOUND THEN
                v_sql := format('
                    CREATE INDEX %I ON %I.%I (%I);
                ',
                v_index_name, p_schema, v_partition_name, v_column);
                
                EXECUTE v_sql;
                
                -- Ghi log tạo chỉ mục
                INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
                VALUES (p_table, p_schema, v_partition_name, 'CREATE_INDEX', 'Đã tạo chỉ mục cho cột ' || v_column);
            END IF;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. THỰC THI PHÂN VÙNG CHO CÁC BẢNG CHÍNH
-- ============================================================================

-- Thực thi phân vùng cho các bảng của Bộ Công an
\connect ministry_of_public_security
SELECT partitioning.setup_citizen_tables_partitioning();
SELECT partitioning.setup_residence_tables_partitioning();

-- Thực thi phân vùng cho các bảng của Bộ Tư pháp
\connect ministry_of_justice
SELECT partitioning.setup_civil_status_tables_partitioning();
SELECT partitioning.setup_household_tables_partitioning();

-- Thực thi phân vùng cho các bảng của Máy chủ trung tâm
\connect national_citizen_central_server
SELECT partitioning.setup_integrated_data_partitioning();

\echo 'Đã hoàn thành thiết lập phân vùng dữ liệu cho toàn bộ hệ thống'
\echo 'Đã thiết lập phân vùng đa cấp theo miền (Bắc/Trung/Nam) → tỉnh/thành phố → quận/huyện'
\echo 'Đã tạo các chức năng quản lý và giám sát phân vùng'
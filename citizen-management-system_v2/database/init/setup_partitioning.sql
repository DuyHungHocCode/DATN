-- Script thiết lập phân vùng dữ liệu cho hệ thống quản lý dân cư quốc gia
-- File: database/init/setup_partitioning.sql

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
    partition_type VARCHAR(20) NOT NULL, -- 'REGION', 'PROVINCE', 'DISTRICT', 'DATE', 'RANGE', 'LIST'
    partition_column VARCHAR(100) NOT NULL,
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tạo function khởi tạo pg_partman cho phân vùng theo vùng địa lý
CREATE OR REPLACE FUNCTION partitioning.setup_region_partitioning(
    p_schema TEXT, 
    p_table TEXT, 
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_regions TEXT[] := ARRAY['Bắc', 'Trung', 'Nam'];
    v_region TEXT;
BEGIN
    -- Tạo câu lệnh SQL để tạo bảng cha phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I_pkey CASCADE;
        ALTER TABLE %I.%I ADD PRIMARY KEY (%I, %I);
    ', p_schema, p_table, p_table, p_schema, p_table, 'citizen_id', p_column);
    
    -- Chuyển bảng thành bảng phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Bắc'');
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Trung'');
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Nam'');
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table || '_bac',
    p_schema, p_table, p_schema, p_table || '_trung',
    p_schema, p_table, p_schema, p_table || '_nam');
    
    -- Tạo các bảng con phân vùng
    FOREACH v_region IN ARRAY v_regions LOOP
        CASE 
            WHEN v_region = 'Bắc' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Bắc'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_bac', 
                p_column, 
                p_schema, p_table);
            WHEN v_region = 'Trung' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Trung'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_trung', 
                p_column, 
                p_schema, p_table);
            WHEN v_region = 'Nam' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Nam'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_nam', 
                p_column, 
                p_schema, p_table);
        END CASE;
        
        EXECUTE v_sql;
    END LOOP;
    
    -- Tạo function trigger để chuyển hướng dữ liệu
    EXECUTE format('
        CREATE OR REPLACE FUNCTION partitioning.%I_insert_trigger()
        RETURNS TRIGGER AS $func$
        BEGIN
            IF NEW.%I = ''Bắc'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSIF NEW.%I = ''Trung'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSIF NEW.%I = ''Nam'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSE
                RAISE EXCEPTION ''Vùng địa lý không hợp lệ: %%'', NEW.%I;
            END IF;
            RETURN NULL;
        END;
        $func$ LANGUAGE plpgsql;
    ', 
    p_table, 
    p_column, 
    p_schema, p_table || '_bac',
    p_column,
    p_schema, p_table || '_trung',
    p_column,
    p_schema, p_table || '_nam',
    p_column);
    
    -- Gắn trigger vào bảng cha
    EXECUTE format('
        DROP TRIGGER IF EXISTS insert_%I_trigger ON %I.%I;
        CREATE TRIGGER insert_%I_trigger
        BEFORE INSERT ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION partitioning.%I_insert_trigger();
    ', 
    p_table, p_schema, p_table, 
    p_table, p_schema, p_table, 
    p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'REGION', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function khởi tạo pg_partman cho phân vùng theo tỉnh/thành phố
CREATE OR REPLACE FUNCTION partitioning.setup_province_partitioning(
    p_schema TEXT, 
    p_table TEXT, 
    p_column TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    -- Kết nối đến pg_partman để tạo phân vùng LIST
    PERFORM partman.create_parent(
        p_parent_table := p_schema || '.' || p_table,
        p_control := p_column,
        p_type := 'list',
        p_premake := 0
    );
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'PROVINCE', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function gắn các bảng lưu trữ dữ liệu công dân vào phân vùng
CREATE OR REPLACE FUNCTION partitioning.setup_citizen_partitioning() RETURNS VOID AS $$
BEGIN
    -- Phân vùng bảng citizen theo geographical_region
    PERFORM partitioning.setup_region_partitioning('public_security', 'citizen', 'geographical_region');
    
    -- Phân vùng bảng identification_card theo geographical_region
    PERFORM partitioning.setup_region_partitioning('public_security', 'identification_card', 'geographical_region');
    
    -- Phân vùng bảng biometric_data theo geographical_region
    PERFORM partitioning.setup_region_partitioning('public_security', 'biometric_data', 'geographical_region');
    
    -- Phân vùng bảng address theo geographical_region
    PERFORM partitioning.setup_region_partitioning('public_security', 'address', 'geographical_region');
    
    -- Phân vùng bảng citizen_status theo geographical_region
    PERFORM partitioning.setup_region_partitioning('public_security', 'citizen_status', 'geographical_region');
    
    -- Phân vùng bảng criminal_record theo geographical_region
    PERFORM partitioning.setup_region_partitioning('public_security', 'criminal_record', 'geographical_region');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. THIẾT LẬP PHÂN VÙNG CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Thiết lập phân vùng dữ liệu cho database Bộ Tư pháp...'
\connect ministry_of_justice

-- Tạo schema partitioning nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;

-- Tạo bảng cấu hình phân vùng
CREATE TABLE IF NOT EXISTS partitioning.config (
    table_name VARCHAR(100) PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL, -- 'REGION', 'PROVINCE', 'DISTRICT', 'DATE', 'RANGE', 'LIST'
    partition_column VARCHAR(100) NOT NULL,
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tạo function khởi tạo pg_partman cho phân vùng theo vùng địa lý (tương tự như ở Bộ Công an)
CREATE OR REPLACE FUNCTION partitioning.setup_region_partitioning(
    p_schema TEXT, 
    p_table TEXT, 
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_regions TEXT[] := ARRAY['Bắc', 'Trung', 'Nam'];
    v_region TEXT;
BEGIN
    -- Tạo câu lệnh SQL để tạo bảng cha phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I_pkey CASCADE;
        ALTER TABLE %I.%I ADD PRIMARY KEY (%I, %I);
    ', p_schema, p_table, p_table, p_schema, p_table, 'citizen_id', p_column);
    
    -- Chuyển bảng thành bảng phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Bắc'');
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Trung'');
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Nam'');
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table || '_bac',
    p_schema, p_table, p_schema, p_table || '_trung',
    p_schema, p_table, p_schema, p_table || '_nam');
    
    -- Tạo các bảng con phân vùng
    FOREACH v_region IN ARRAY v_regions LOOP
        CASE 
            WHEN v_region = 'Bắc' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Bắc'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_bac', 
                p_column, 
                p_schema, p_table);
            WHEN v_region = 'Trung' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Trung'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_trung', 
                p_column, 
                p_schema, p_table);
            WHEN v_region = 'Nam' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Nam'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_nam', 
                p_column, 
                p_schema, p_table);
        END CASE;
        
        EXECUTE v_sql;
    END LOOP;
    
    -- Tạo function trigger để chuyển hướng dữ liệu
    EXECUTE format('
        CREATE OR REPLACE FUNCTION partitioning.%I_insert_trigger()
        RETURNS TRIGGER AS $func$
        BEGIN
            IF NEW.%I = ''Bắc'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSIF NEW.%I = ''Trung'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSIF NEW.%I = ''Nam'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSE
                RAISE EXCEPTION ''Vùng địa lý không hợp lệ: %%'', NEW.%I;
            END IF;
            RETURN NULL;
        END;
        $func$ LANGUAGE plpgsql;
    ', 
    p_table, 
    p_column, 
    p_schema, p_table || '_bac',
    p_column,
    p_schema, p_table || '_trung',
    p_column,
    p_schema, p_table || '_nam',
    p_column);
    
    -- Gắn trigger vào bảng cha
    EXECUTE format('
        DROP TRIGGER IF EXISTS insert_%I_trigger ON %I.%I;
        CREATE TRIGGER insert_%I_trigger
        BEFORE INSERT ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION partitioning.%I_insert_trigger();
    ', 
    p_table, p_schema, p_table, 
    p_table, p_schema, p_table, 
    p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'REGION', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function gắn các bảng lưu trữ dữ liệu hộ tịch vào phân vùng
CREATE OR REPLACE FUNCTION partitioning.setup_civil_status_partitioning() RETURNS VOID AS $$
BEGIN
    -- Phân vùng bảng birth_certificate theo geographical_region
    PERFORM partitioning.setup_region_partitioning('justice', 'birth_certificate', 'geographical_region');
    
    -- Phân vùng bảng death_certificate theo geographical_region
    PERFORM partitioning.setup_region_partitioning('justice', 'death_certificate', 'geographical_region');
    
    -- Phân vùng bảng marriage theo geographical_region
    PERFORM partitioning.setup_region_partitioning('justice', 'marriage', 'geographical_region');
    
    -- Phân vùng bảng divorce theo geographical_region
    PERFORM partitioning.setup_region_partitioning('justice', 'divorce', 'geographical_region');
    
    -- Phân vùng bảng household theo geographical_region
    PERFORM partitioning.setup_region_partitioning('justice', 'household', 'geographical_region');
    
    -- Phân vùng bảng family_relationship theo geographical_region
    PERFORM partitioning.setup_region_partitioning('justice', 'family_relationship', 'geographical_region');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. THIẾT LẬP PHÂN VÙNG CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Thiết lập phân vùng dữ liệu cho database Máy chủ trung tâm...'
\connect national_citizen_central_server

-- Tạo schema partitioning nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;

-- Tạo bảng cấu hình phân vùng
CREATE TABLE IF NOT EXISTS partitioning.config (
    table_name VARCHAR(100) PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL, -- 'REGION', 'PROVINCE', 'DISTRICT', 'DATE', 'RANGE', 'LIST'
    partition_column VARCHAR(100) NOT NULL,
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tạo bảng lịch sử phân vùng
CREATE TABLE IF NOT EXISTS partitioning.history (
    history_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL, -- 'CREATE', 'DETACH', 'DROP', 'ARCHIVE'
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    affected_rows BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    notes TEXT
);

-- Tạo function khởi tạo pg_partman cho phân vùng theo vùng địa lý (tương tự như các database khác)
CREATE OR REPLACE FUNCTION partitioning.setup_region_partitioning(
    p_schema TEXT, 
    p_table TEXT, 
    p_column TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_sql TEXT;
    v_regions TEXT[] := ARRAY['Bắc', 'Trung', 'Nam'];
    v_region TEXT;
BEGIN
    -- Tạo câu lệnh SQL để tạo bảng cha phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I_pkey CASCADE;
        ALTER TABLE %I.%I ADD PRIMARY KEY (%I, %I);
    ', p_schema, p_table, p_table, p_schema, p_table, 'citizen_id', p_column);
    
    -- Chuyển bảng thành bảng phân vùng
    EXECUTE format('
        ALTER TABLE %I.%I SET UNLOGGED;
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Bắc'');
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Trung'');
        ALTER TABLE %I.%I DETACH PARTITION IF EXISTS %I.%I FOR VALUES IN (''Nam'');
    ', 
    p_schema, p_table, 
    p_schema, p_table, p_schema, p_table || '_bac',
    p_schema, p_table, p_schema, p_table || '_trung',
    p_schema, p_table, p_schema, p_table || '_nam');
    
    -- Tạo các bảng con phân vùng
    FOREACH v_region IN ARRAY v_regions LOOP
        CASE 
            WHEN v_region = 'Bắc' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Bắc'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_bac', 
                p_column, 
                p_schema, p_table);
            WHEN v_region = 'Trung' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Trung'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_trung', 
                p_column, 
                p_schema, p_table);
            WHEN v_region = 'Nam' THEN
                v_sql := format('
                    CREATE TABLE IF NOT EXISTS %I.%I (
                        CHECK (%I = ''Nam'')
                    ) INHERITS (%I.%I);
                ', 
                p_schema, p_table || '_nam', 
                p_column, 
                p_schema, p_table);
        END CASE;
        
        EXECUTE v_sql;
        
        -- Ghi lại lịch sử tạo phân vùng
        INSERT INTO partitioning.history (table_name, schema_name, partition_name, action, notes)
        VALUES (p_table, p_schema, p_table || '_' || lower(v_region), 'CREATE', 'Phân vùng theo khu vực địa lý: ' || v_region);
    END LOOP;
    
    -- Tạo function trigger để chuyển hướng dữ liệu
    EXECUTE format('
        CREATE OR REPLACE FUNCTION partitioning.%I_insert_trigger()
        RETURNS TRIGGER AS $func$
        BEGIN
            IF NEW.%I = ''Bắc'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSIF NEW.%I = ''Trung'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSIF NEW.%I = ''Nam'' THEN
                INSERT INTO %I.%I VALUES (NEW.*);
            ELSE
                RAISE EXCEPTION ''Vùng địa lý không hợp lệ: %%'', NEW.%I;
            END IF;
            RETURN NULL;
        END;
        $func$ LANGUAGE plpgsql;
    ', 
    p_table, 
    p_column, 
    p_schema, p_table || '_bac',
    p_column,
    p_schema, p_table || '_trung',
    p_column,
    p_schema, p_table || '_nam',
    p_column);
    
    -- Gắn trigger vào bảng cha
    EXECUTE format('
        DROP TRIGGER IF EXISTS insert_%I_trigger ON %I.%I;
        CREATE TRIGGER insert_%I_trigger
        BEFORE INSERT ON %I.%I
        FOR EACH ROW EXECUTE FUNCTION partitioning.%I_insert_trigger();
    ', 
    p_table, p_schema, p_table, 
    p_table, p_schema, p_table, 
    p_table);
    
    -- Ghi log cấu hình
    INSERT INTO partitioning.config (table_name, schema_name, partition_type, partition_column)
    VALUES (p_table, p_schema, 'REGION', p_column)
    ON CONFLICT (table_name) DO UPDATE SET
        schema_name = EXCLUDED.schema_name,
        partition_type = EXCLUDED.partition_type,
        partition_column = EXCLUDED.partition_column,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tạo function khởi tạo phân vùng cho dữ liệu tích hợp
CREATE OR REPLACE FUNCTION partitioning.setup_integrated_data_partitioning() RETURNS VOID AS $$
BEGIN
    -- Phân vùng bảng integrated_citizen theo geographical_region
    PERFORM partitioning.setup_region_partitioning('central', 'integrated_citizen', 'geographical_region');
    
    -- Phân vùng bảng integrated_household theo geographical_region
    PERFORM partitioning.setup_region_partitioning('central', 'integrated_household', 'geographical_region');
END;
$$ LANGUAGE plpgsql;

\echo 'Đã hoàn thành thiết lập phân vùng dữ liệu cho toàn bộ hệ thống'
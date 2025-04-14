-- Tạo bảng PopulationChange (Biến động dân cư) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng PopulationChange cho các database vùng miền...'





-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng PopulationChange
CREATE OR REPLACE FUNCTION create_population_change_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng PopulationChange trong schema justice
    CREATE TABLE IF NOT EXISTS justice.population_change (
        change_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        change_type population_change_type NOT NULL,
        change_date DATE NOT NULL,
        source_location_id INT,
        destination_location_id INT,
        reason TEXT,
        related_document_no VARCHAR(50),
        related_document_id INT,
        processing_authority_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng PopulationChange
CREATE OR REPLACE FUNCTION create_population_change_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng PopulationChange trong schema justice
    CREATE TABLE IF NOT EXISTS justice.population_change (
        change_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        change_type population_change_type NOT NULL,
        change_date DATE NOT NULL,
        source_location_id INT,
        destination_location_id INT,
        reason TEXT,
        related_document_no VARCHAR(50),
        related_document_id INT,
        processing_authority_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng PopulationChange
CREATE OR REPLACE FUNCTION create_population_change_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng PopulationChange trong schema justice
    CREATE TABLE IF NOT EXISTS justice.population_change (
        change_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        change_type population_change_type NOT NULL,
        change_date DATE NOT NULL,
        source_location_id INT,
        destination_location_id INT,
        reason TEXT,
        related_document_no VARCHAR(50),
        related_document_id INT,
        processing_authority_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng PopulationChange
CREATE OR REPLACE FUNCTION create_population_change_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng PopulationChange trong schema justice
    CREATE TABLE IF NOT EXISTS justice.population_change (
        change_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        change_type population_change_type NOT NULL,
        change_date DATE NOT NULL,
        source_location_id INT,
        destination_location_id INT,
        reason TEXT,
        related_document_no VARCHAR(50),
        related_document_id INT,
        processing_authority_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng PopulationChange cho tất cả các database.'
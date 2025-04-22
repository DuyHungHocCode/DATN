-- Tạo bảng CitizenStatus (Trạng thái công dân) cho hệ thống CSDL phân
-- tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng CitizenStatus cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng CitizenStatus
CREATE OR REPLACE FUNCTION create_citizen_status_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenStatus trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_status (
        status_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        status_type death_status NOT NULL DEFAULT 'Còn sống',
        status_date DATE NOT NULL,
        description TEXT,
        authority_id SMALLINT,
        document_number VARCHAR(50),
        document_date DATE,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng CitizenStatus
CREATE OR REPLACE FUNCTION create_citizen_status_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenStatus trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_status (
        status_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        status_type death_status NOT NULL DEFAULT 'Còn sống',
        status_date DATE NOT NULL,
        description TEXT,
        authority_id SMALLINT,
        document_number VARCHAR(50),
        document_date DATE,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng CitizenStatus
CREATE OR REPLACE FUNCTION create_citizen_status_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenStatus trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_status (
        status_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        status_type death_status NOT NULL DEFAULT 'Còn sống',
        status_date DATE NOT NULL,
        description TEXT,
        authority_id SMALLINT,
        document_number VARCHAR(50),
        document_date DATE,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng CitizenStatus
CREATE OR REPLACE FUNCTION create_citizen_status_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenStatus trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_status (
        status_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        status_type death_status NOT NULL DEFAULT 'Còn sống',
        status_date DATE NOT NULL,
        description TEXT,
        authority_id SMALLINT,
        document_number VARCHAR(50),
        document_date DATE,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng CitizenStatus cho tất cả các database.'
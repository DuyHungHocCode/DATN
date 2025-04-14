-- citizen.sql
-- Tạo bảng Citizen (Công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database bộ quản lý
\echo 'Tạo bảng Citizen cho các database bộ quản lý...'

\connect ministry_of_public_security

-- Hàm tạo bảng Citizen
CREATE OR REPLACE FUNCTION create_citizen_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Citizen trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen (
        citizen_id VARCHAR(12) PRIMARY KEY, -- Mã định danh công dân (12 số)
        full_name VARCHAR(100) NOT NULL,
        date_of_birth DATE NOT NULL,
        place_of_birth TEXT NOT NULL,
        gender gender_type NOT NULL,
        ethnicity_id SMALLINT,
        religion_id SMALLINT,
        nationality_id SMALLINT,
        blood_type blood_type DEFAULT 'Không xác định',
        death_status death_status DEFAULT 'Còn sống',
        birth_certificate_no VARCHAR(20),
        marital_status marital_status DEFAULT 'Độc thân',
        education_level_id SMALLINT,
        occupation_type_id SMALLINT,
        occupation_detail TEXT,
        tax_code VARCHAR(13),
        social_insurance_no VARCHAR(13),
        health_insurance_no VARCHAR(15),
        father_citizen_id VARCHAR(12),
        mother_citizen_id VARCHAR(12),
        region_id SMALLINT,
        province_id INT,
        avatar BYTEA, -- Ảnh đại diện
        notes TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_table();
\echo 'Đã tạo bảng Citizen cho database BCA'

-- Kết nối đến database bộ tư pháp
\connect ministry_of_justice

-- Hàm tạo bảng Citizen
CREATE OR REPLACE FUNCTION create_citizen_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Citizen trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen (
        citizen_id VARCHAR(12) PRIMARY KEY, -- Mã định danh công dân (12 số)
        full_name VARCHAR(100) NOT NULL,
        date_of_birth DATE NOT NULL,
        place_of_birth TEXT NOT NULL,
        gender gender_type NOT NULL,
        ethnicity_id SMALLINT,
        religion_id SMALLINT,
        nationality_id SMALLINT,
        blood_type blood_type DEFAULT 'Không xác định',
        death_status death_status DEFAULT 'Còn sống',
        birth_certificate_no VARCHAR(20),
        marital_status marital_status DEFAULT 'Độc thân',
        education_level_id SMALLINT,
        occupation_type_id SMALLINT,
        occupation_detail TEXT,
        tax_code VARCHAR(13),
        social_insurance_no VARCHAR(13),
        health_insurance_no VARCHAR(15),
        father_citizen_id VARCHAR(12),
        mother_citizen_id VARCHAR(12),
        region_id SMALLINT,
        province_id INT,
        avatar BYTEA, -- Ảnh đại diện
        notes TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_table();
\echo 'Đã tạo bảng Citizen cho database BTP'

-- Kết nối đến database máy chủ trung tâm
\connect national_citizen_central_server

-- Hàm tạo bảng Citizen
CREATE OR REPLACE FUNCTION create_citizen_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Citizen trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen (
        citizen_id VARCHAR(12) PRIMARY KEY, -- Mã định danh công dân (12 số)
        full_name VARCHAR(100) NOT NULL,
        date_of_birth DATE NOT NULL,
        place_of_birth TEXT NOT NULL,
        gender gender_type NOT NULL,
        ethnicity_id SMALLINT,
        religion_id SMALLINT,
        nationality_id SMALLINT,
        blood_type blood_type DEFAULT 'Không xác định',
        death_status death_status DEFAULT 'Còn sống',
        birth_certificate_no VARCHAR(20),
        marital_status marital_status DEFAULT 'Độc thân',
        education_level_id SMALLINT,
        occupation_type_id SMALLINT,
        occupation_detail TEXT,
        tax_code VARCHAR(13),
        social_insurance_no VARCHAR(13),
        health_insurance_no VARCHAR(15),
        father_citizen_id VARCHAR(12),
        mother_citizen_id VARCHAR(12),
        region_id SMALLINT,
        province_id INT,
        avatar BYTEA, -- Ảnh đại diện
        notes TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_table();
\echo 'Đã tạo bảng Citizen cho database máy chủ trung tâm'

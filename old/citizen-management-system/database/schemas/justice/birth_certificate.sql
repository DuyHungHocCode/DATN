-- Tạo bảng BirthCertificate (Giấy khai sinh) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng BirthCertificate cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng BirthCertificate
CREATE OR REPLACE FUNCTION create_birth_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BirthCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.birth_certificate (
        birth_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        birth_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        registration_date DATE NOT NULL,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        issuing_authority_id SMALLINT,
        place_of_birth TEXT NOT NULL,
        date_of_birth DATE NOT NULL,
        gender_at_birth gender_type NOT NULL,
        father_full_name VARCHAR(100),
        father_citizen_id VARCHAR(12),
        father_date_of_birth DATE,
        father_nationality_id SMALLINT,
        mother_full_name VARCHAR(100),
        mother_citizen_id VARCHAR(12),
        mother_date_of_birth DATE,
        mother_nationality_id SMALLINT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        birth_notification_no VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng BirthCertificate
CREATE OR REPLACE FUNCTION create_birth_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BirthCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.birth_certificate (
        birth_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        birth_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        registration_date DATE NOT NULL,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        issuing_authority_id SMALLINT,
        place_of_birth TEXT NOT NULL,
        date_of_birth DATE NOT NULL,
        gender_at_birth gender_type NOT NULL,
        father_full_name VARCHAR(100),
        father_citizen_id VARCHAR(12),
        father_date_of_birth DATE,
        father_nationality_id SMALLINT,
        mother_full_name VARCHAR(100),
        mother_citizen_id VARCHAR(12),
        mother_date_of_birth DATE,
        mother_nationality_id SMALLINT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        birth_notification_no VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng BirthCertificate
CREATE OR REPLACE FUNCTION create_birth_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BirthCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.birth_certificate (
        birth_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        birth_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        registration_date DATE NOT NULL,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        issuing_authority_id SMALLINT,
        place_of_birth TEXT NOT NULL,
        date_of_birth DATE NOT NULL,
        gender_at_birth gender_type NOT NULL,
        father_full_name VARCHAR(100),
        father_citizen_id VARCHAR(12),
        father_date_of_birth DATE,
        father_nationality_id SMALLINT,
        mother_full_name VARCHAR(100),
        mother_citizen_id VARCHAR(12),
        mother_date_of_birth DATE,
        mother_nationality_id SMALLINT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        birth_notification_no VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng BirthCertificate
CREATE OR REPLACE FUNCTION create_birth_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BirthCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.birth_certificate (
        birth_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        birth_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        registration_date DATE NOT NULL,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        issuing_authority_id SMALLINT,
        place_of_birth TEXT NOT NULL,
        date_of_birth DATE NOT NULL,
        gender_at_birth gender_type NOT NULL,
        father_full_name VARCHAR(100),
        father_citizen_id VARCHAR(12),
        father_date_of_birth DATE,
        father_nationality_id SMALLINT,
        mother_full_name VARCHAR(100),
        mother_citizen_id VARCHAR(12),
        mother_date_of_birth DATE,
        mother_nationality_id SMALLINT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        birth_notification_no VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng BirthCertificate cho tất cả các database.'
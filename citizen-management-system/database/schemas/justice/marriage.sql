
-- Tạo bảng Marriage (Đăng ký kết hôn) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng Marriage cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng Marriage
CREATE OR REPLACE FUNCTION create_marriage_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Marriage trong schema justice
    CREATE TABLE IF NOT EXISTS justice.marriage (
        marriage_id SERIAL PRIMARY KEY,
        marriage_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        husband_id VARCHAR(12) NOT NULL,
        husband_full_name VARCHAR(100) NOT NULL,
        husband_date_of_birth DATE NOT NULL,
        husband_nationality_id SMALLINT,
        husband_previous_marriage_status marital_status NOT NULL,
        wife_id VARCHAR(12) NOT NULL,
        wife_full_name VARCHAR(100) NOT NULL,
        wife_date_of_birth DATE NOT NULL,
        wife_nationality_id SMALLINT,
        wife_previous_marriage_status marital_status NOT NULL,
        marriage_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        issuing_place TEXT,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_husband_wife CHECK (husband_id <> wife_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng Marriage
CREATE OR REPLACE FUNCTION create_marriage_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Marriage trong schema justice
    CREATE TABLE IF NOT EXISTS justice.marriage (
        marriage_id SERIAL PRIMARY KEY,
        marriage_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        husband_id VARCHAR(12) NOT NULL,
        husband_full_name VARCHAR(100) NOT NULL,
        husband_date_of_birth DATE NOT NULL,
        husband_nationality_id SMALLINT,
        husband_previous_marriage_status marital_status NOT NULL,
        wife_id VARCHAR(12) NOT NULL,
        wife_full_name VARCHAR(100) NOT NULL,
        wife_date_of_birth DATE NOT NULL,
        wife_nationality_id SMALLINT,
        wife_previous_marriage_status marital_status NOT NULL,
        marriage_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        issuing_place TEXT,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_husband_wife CHECK (husband_id <> wife_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng Marriage
CREATE OR REPLACE FUNCTION create_marriage_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Marriage trong schema justice
    CREATE TABLE IF NOT EXISTS justice.marriage (
        marriage_id SERIAL PRIMARY KEY,
        marriage_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        husband_id VARCHAR(12) NOT NULL,
        husband_full_name VARCHAR(100) NOT NULL,
        husband_date_of_birth DATE NOT NULL,
        husband_nationality_id SMALLINT,
        husband_previous_marriage_status marital_status NOT NULL,
        wife_id VARCHAR(12) NOT NULL,
        wife_full_name VARCHAR(100) NOT NULL,
        wife_date_of_birth DATE NOT NULL,
        wife_nationality_id SMALLINT,
        wife_previous_marriage_status marital_status NOT NULL,
        marriage_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        issuing_place TEXT,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_husband_wife CHECK (husband_id <> wife_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng Marriage
CREATE OR REPLACE FUNCTION create_marriage_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Marriage trong schema justice
    CREATE TABLE IF NOT EXISTS justice.marriage (
        marriage_id SERIAL PRIMARY KEY,
        marriage_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        husband_id VARCHAR(12) NOT NULL,
        husband_full_name VARCHAR(100) NOT NULL,
        husband_date_of_birth DATE NOT NULL,
        husband_nationality_id SMALLINT,
        husband_previous_marriage_status marital_status NOT NULL,
        wife_id VARCHAR(12) NOT NULL,
        wife_full_name VARCHAR(100) NOT NULL,
        wife_date_of_birth DATE NOT NULL,
        wife_nationality_id SMALLINT,
        wife_previous_marriage_status marital_status NOT NULL,
        marriage_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        issuing_place TEXT,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_husband_wife CHECK (husband_id <> wife_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng Marriage cho tất cả các database.'
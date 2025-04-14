-- Tạo bảng DeathCertificate (Giấy khai tử) cho hệ thống CSDL phân tán quản lý dân cư quốc gia
-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng DeathCertificate cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng DeathCertificate
CREATE OR REPLACE FUNCTION create_death_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DeathCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.death_certificate (
        death_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        death_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        date_of_death DATE NOT NULL,
        time_of_death TIME,
        place_of_death TEXT NOT NULL,
        cause_of_death TEXT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        death_notification_no VARCHAR(50),
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng DeathCertificate
CREATE OR REPLACE FUNCTION create_death_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DeathCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.death_certificate (
        death_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        death_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        date_of_death DATE NOT NULL,
        time_of_death TIME,
        place_of_death TEXT NOT NULL,
        cause_of_death TEXT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        death_notification_no VARCHAR(50),
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng DeathCertificate
CREATE OR REPLACE FUNCTION create_death_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DeathCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.death_certificate (
        death_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        death_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        date_of_death DATE NOT NULL,
        time_of_death TIME,
        place_of_death TEXT NOT NULL,
        cause_of_death TEXT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        death_notification_no VARCHAR(50),
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng DeathCertificate
CREATE OR REPLACE FUNCTION create_death_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DeathCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.death_certificate (
        death_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        death_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        date_of_death DATE NOT NULL,
        time_of_death TIME,
        place_of_death TEXT NOT NULL,
        cause_of_death TEXT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12),
        declarant_relationship VARCHAR(50) NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        death_notification_no VARCHAR(50),
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng DeathCertificate cho tất cả các database.'
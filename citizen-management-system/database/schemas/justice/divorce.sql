-- Tạo bảng Divorce (Đăng ký ly hôn) cho hệ thống CSDL phân tán quản lý dân cư quốc gia
-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng Divorce cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng Divorce
CREATE OR REPLACE FUNCTION create_divorce_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Divorce trong schema justice
    CREATE TABLE IF NOT EXISTS justice.divorce (
        divorce_id SERIAL PRIMARY KEY,
        divorce_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        marriage_id INT,
        divorce_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        court_name VARCHAR(200),
        judgment_no VARCHAR(50),
        judgment_date DATE,
        issuing_authority_id SMALLINT,
        reason TEXT,
        child_custody TEXT,
        property_division TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng Divorce
CREATE OR REPLACE FUNCTION create_divorce_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Divorce trong schema justice
    CREATE TABLE IF NOT EXISTS justice.divorce (
        divorce_id SERIAL PRIMARY KEY,
        divorce_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        marriage_id INT,
        divorce_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        court_name VARCHAR(200),
        judgment_no VARCHAR(50),
        judgment_date DATE,
        issuing_authority_id SMALLINT,
        reason TEXT,
        child_custody TEXT,
        property_division TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng Divorce
CREATE OR REPLACE FUNCTION create_divorce_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Divorce trong schema justice
    CREATE TABLE IF NOT EXISTS justice.divorce (
        divorce_id SERIAL PRIMARY KEY,
        divorce_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        marriage_id INT,
        divorce_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        court_name VARCHAR(200),
        judgment_no VARCHAR(50),
        judgment_date DATE,
        issuing_authority_id SMALLINT,
        reason TEXT,
        child_custody TEXT,
        property_division TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng Divorce
CREATE OR REPLACE FUNCTION create_divorce_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Divorce trong schema justice
    CREATE TABLE IF NOT EXISTS justice.divorce (
        divorce_id SERIAL PRIMARY KEY,
        divorce_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        marriage_id INT,
        divorce_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        court_name VARCHAR(200),
        judgment_no VARCHAR(50),
        judgment_date DATE,
        issuing_authority_id SMALLINT,
        reason TEXT,
        child_custody TEXT,
        property_division TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng Divorce cho tất cả các database.'
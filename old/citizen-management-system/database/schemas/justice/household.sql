-- Tạo bảng Household (Hộ khẩu) cho hệ thống CSDL phân tán quản lý dân cư quốc gia
-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng Household cho các database vùng miền...'


-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng Household
CREATE OR REPLACE FUNCTION create_household_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Household trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household (
        household_id SERIAL PRIMARY KEY,
        household_book_no VARCHAR(20) NOT NULL UNIQUE,
        head_of_household_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        area_code VARCHAR(10),
        household_type VARCHAR(50) NOT NULL, -- X Thường trú/Tạm trú tham chieu den bang trong enum
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng Household
CREATE OR REPLACE FUNCTION create_household_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Household trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household (
        household_id SERIAL PRIMARY KEY,
        household_book_no VARCHAR(20) NOT NULL UNIQUE,
        head_of_household_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        area_code VARCHAR(10),
        household_type VARCHAR(50) NOT NULL, -- X Thường trú/Tạm trú tham chieu den bang trong enum
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng Household
CREATE OR REPLACE FUNCTION create_household_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Household trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household (
        household_id SERIAL PRIMARY KEY,
        household_book_no VARCHAR(20) NOT NULL UNIQUE,
        head_of_household_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        area_code VARCHAR(10),
        household_type VARCHAR(50) NOT NULL, -- X Thường trú/Tạm trú tham chieu den bang trong enum
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng Household
CREATE OR REPLACE FUNCTION create_household_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Household trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household (
        household_id SERIAL PRIMARY KEY,
        household_book_no VARCHAR(20) NOT NULL UNIQUE,
        head_of_household_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT,
        area_code VARCHAR(10),
        household_type VARCHAR(50) NOT NULL, -- X Thường trú/Tạm trú tham chieu den bang trong enum
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng Household cho tất cả các database.'
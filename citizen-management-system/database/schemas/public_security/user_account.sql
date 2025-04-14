-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng UserAccount cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng UserAccount
CREATE OR REPLACE FUNCTION create_user_account_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng UserAccount trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.user_account (
        user_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12),
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        user_type user_type NOT NULL,
        role_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        two_factor_enabled BOOLEAN DEFAULT FALSE,
        locked_until TIMESTAMP WITH TIME ZONE,
        failed_login_attempts SMALLINT DEFAULT 0,
        password_change_required BOOLEAN DEFAULT FALSE,
        last_password_change TIMESTAMP WITH TIME ZONE,
        email VARCHAR(100),
        phone_number VARCHAR(15),
        agency_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng UserAccount
CREATE OR REPLACE FUNCTION create_user_account_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng UserAccount trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.user_account (
        user_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12),
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        user_type user_type NOT NULL,
        role_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        two_factor_enabled BOOLEAN DEFAULT FALSE,
        locked_until TIMESTAMP WITH TIME ZONE,
        failed_login_attempts SMALLINT DEFAULT 0,
        password_change_required BOOLEAN DEFAULT FALSE,
        last_password_change TIMESTAMP WITH TIME ZONE,
        email VARCHAR(100),
        phone_number VARCHAR(15),
        agency_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng UserAccount
CREATE OR REPLACE FUNCTION create_user_account_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng UserAccount trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.user_account (
        user_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12),
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        user_type user_type NOT NULL,
        role_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        two_factor_enabled BOOLEAN DEFAULT FALSE,
        locked_until TIMESTAMP WITH TIME ZONE,
        failed_login_attempts SMALLINT DEFAULT 0,
        password_change_required BOOLEAN DEFAULT FALSE,
        last_password_change TIMESTAMP WITH TIME ZONE,
        email VARCHAR(100),
        phone_number VARCHAR(15),
        agency_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng UserAccount
CREATE OR REPLACE FUNCTION create_user_account_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng UserAccount trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.user_account (
        user_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12),
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        user_type user_type NOT NULL,
        role_id SMALLINT,
        status BOOLEAN DEFAULT TRUE,
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        two_factor_enabled BOOLEAN DEFAULT FALSE,
        locked_until TIMESTAMP WITH TIME ZONE,
        failed_login_attempts SMALLINT DEFAULT 0,
        password_change_required BOOLEAN DEFAULT FALSE,
        last_password_change TIMESTAMP WITH TIME ZONE,
        email VARCHAR(100),
        phone_number VARCHAR(15),
        agency_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng UserAccount cho tất cả các database.'
-- Tạo bảng DigitalIdentity (Định danh điện tử) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng DigitalIdentity cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng DigitalIdentity
CREATE OR REPLACE FUNCTION create_digital_identity_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DigitalIdentity trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.digital_identity (
        digital_identity_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        digital_id VARCHAR(50) NOT NULL UNIQUE, -- Mã định danh điện tử
        activation_date TIMESTAMP WITH TIME ZONE NOT NULL,
        verification_level verification_level NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        device_info TEXT, -- Thông tin thiết bị
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        otp_method VARCHAR(50), -- Phương thức OTP
        phone_number VARCHAR(15),
        email VARCHAR(100),
        security_question TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng DigitalIdentity
CREATE OR REPLACE FUNCTION create_digital_identity_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DigitalIdentity trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.digital_identity (
        digital_identity_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        digital_id VARCHAR(50) NOT NULL UNIQUE, -- Mã định danh điện tử
        activation_date TIMESTAMP WITH TIME ZONE NOT NULL,
        verification_level verification_level NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        device_info TEXT, -- Thông tin thiết bị
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        otp_method VARCHAR(50), -- Phương thức OTP
        phone_number VARCHAR(15),
        email VARCHAR(100),
        security_question TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng DigitalIdentity
CREATE OR REPLACE FUNCTION create_digital_identity_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DigitalIdentity trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.digital_identity (
        digital_identity_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        digital_id VARCHAR(50) NOT NULL UNIQUE, -- Mã định danh điện tử
        activation_date TIMESTAMP WITH TIME ZONE NOT NULL,
        verification_level verification_level NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        device_info TEXT, -- Thông tin thiết bị
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        otp_method VARCHAR(50), -- Phương thức OTP
        phone_number VARCHAR(15),
        email VARCHAR(100),
        security_question TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng DigitalIdentity
CREATE OR REPLACE FUNCTION create_digital_identity_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DigitalIdentity trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.digital_identity (
        digital_identity_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        digital_id VARCHAR(50) NOT NULL UNIQUE, -- Mã định danh điện tử
        activation_date TIMESTAMP WITH TIME ZONE NOT NULL,
        verification_level verification_level NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        device_info TEXT, -- Thông tin thiết bị
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        otp_method VARCHAR(50), -- Phương thức OTP
        phone_number VARCHAR(15),
        email VARCHAR(100),
        security_question TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng DigitalIdentity cho tất cả các database.'
-- Tạo bảng BiometricData (Dữ liệu sinh trắc học) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng BiometricData cho các database vùng miền...'



    -- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng BiometricData
CREATE OR REPLACE FUNCTION create_biometric_data_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BiometricData trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.biometric_data (
        biometric_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        biometric_type biometric_type NOT NULL,
        biometric_sub_type VARCHAR(50), -- Loại phụ (Ngón tay cụ thể, Mắt trái/phải, etc.)
        biometric_data BYTEA NOT NULL,  -- Dữ liệu sinh trắc học dạng binary
        biometric_format VARCHAR(50) NOT NULL, -- Định dạng dữ liệu (JPG, WSQ, ISO, etc.)
        biometric_template BYTEA, -- Mẫu sinh trắc học đã được xử lý
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        quality SMALLINT, -- Chất lượng (0-100)
        device_id VARCHAR(50), -- Mã thiết bị thu nhận
        device_model VARCHAR(100), -- Model thiết bị
        status BOOLEAN DEFAULT TRUE,
        reason TEXT, -- Lý do cập nhật
        region_id SMALLINT,
        province_id INT,
        encryption_type_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_biometric_type_subtype UNIQUE (citizen_id, biometric_type, biometric_sub_type)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng BiometricData
CREATE OR REPLACE FUNCTION create_biometric_data_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BiometricData trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.biometric_data (
        biometric_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        biometric_type biometric_type NOT NULL,
        biometric_sub_type VARCHAR(50), -- Loại phụ (Ngón tay cụ thể, Mắt trái/phải, etc.)
        biometric_data BYTEA NOT NULL,  -- Dữ liệu sinh trắc học dạng binary
        biometric_format VARCHAR(50) NOT NULL, -- Định dạng dữ liệu (JPG, WSQ, ISO, etc.)
        biometric_template BYTEA, -- Mẫu sinh trắc học đã được xử lý
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        quality SMALLINT, -- Chất lượng (0-100)
        device_id VARCHAR(50), -- Mã thiết bị thu nhận
        device_model VARCHAR(100), -- Model thiết bị
        status BOOLEAN DEFAULT TRUE,
        reason TEXT, -- Lý do cập nhật
        region_id SMALLINT,
        province_id INT,
        encryption_type_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_biometric_type_subtype UNIQUE (citizen_id, biometric_type, biometric_sub_type)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng BiometricData
CREATE OR REPLACE FUNCTION create_biometric_data_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BiometricData trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.biometric_data (
        biometric_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        biometric_type biometric_type NOT NULL,
        biometric_sub_type VARCHAR(50), -- Loại phụ (Ngón tay cụ thể, Mắt trái/phải, etc.)
        biometric_data BYTEA NOT NULL,  -- Dữ liệu sinh trắc học dạng binary
        biometric_format VARCHAR(50) NOT NULL, -- Định dạng dữ liệu (JPG, WSQ, ISO, etc.)
        biometric_template BYTEA, -- Mẫu sinh trắc học đã được xử lý
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        quality SMALLINT, -- Chất lượng (0-100)
        device_id VARCHAR(50), -- Mã thiết bị thu nhận
        device_model VARCHAR(100), -- Model thiết bị
        status BOOLEAN DEFAULT TRUE,
        reason TEXT, -- Lý do cập nhật
        region_id SMALLINT,
        province_id INT,
        encryption_type_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_biometric_type_subtype UNIQUE (citizen_id, biometric_type, biometric_sub_type)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng BiometricData
CREATE OR REPLACE FUNCTION create_biometric_data_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BiometricData trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.biometric_data (
        biometric_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        biometric_type biometric_type NOT NULL,
        biometric_sub_type VARCHAR(50), -- Loại phụ (Ngón tay cụ thể, Mắt trái/phải, etc.)
        biometric_data BYTEA NOT NULL,  -- Dữ liệu sinh trắc học dạng binary
        biometric_format VARCHAR(50) NOT NULL, -- Định dạng dữ liệu (JPG, WSQ, ISO, etc.)
        biometric_template BYTEA, -- Mẫu sinh trắc học đã được xử lý
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        quality SMALLINT, -- Chất lượng (0-100)
        device_id VARCHAR(50), -- Mã thiết bị thu nhận
        device_model VARCHAR(100), -- Model thiết bị
        status BOOLEAN DEFAULT TRUE,
        reason TEXT, -- Lý do cập nhật
        region_id SMALLINT,
        province_id INT,
        encryption_type_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_biometric_type_subtype UNIQUE (citizen_id, biometric_type, biometric_sub_type)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng BiometricData cho tất cả các database.'
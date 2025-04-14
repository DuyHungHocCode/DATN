-- Tạo bảng CitizenImage (Ảnh công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng CitizenImage cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng CitizenImage
CREATE OR REPLACE FUNCTION create_citizen_image_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenImage trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_image (
        image_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        image_type VARCHAR(50) NOT NULL, -- Chân dung/Toàn thân/Khác
        image_data BYTEA NOT NULL,
        image_format VARCHAR(20) NOT NULL, -- JPG/PNG/GIF
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        status BOOLEAN DEFAULT TRUE,
        purpose VARCHAR(100), -- Mục đích sử dụng
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng CitizenImage
CREATE OR REPLACE FUNCTION create_citizen_image_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenImage trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_image (
        image_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        image_type VARCHAR(50) NOT NULL, -- Chân dung/Toàn thân/Khác
        image_data BYTEA NOT NULL,
        image_format VARCHAR(20) NOT NULL, -- JPG/PNG/GIF
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        status BOOLEAN DEFAULT TRUE,
        purpose VARCHAR(100), -- Mục đích sử dụng
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng CitizenImage
CREATE OR REPLACE FUNCTION create_citizen_image_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenImage trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_image (
        image_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        image_type VARCHAR(50) NOT NULL, -- Chân dung/Toàn thân/Khác
        image_data BYTEA NOT NULL,
        image_format VARCHAR(20) NOT NULL, -- JPG/PNG/GIF
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        status BOOLEAN DEFAULT TRUE,
        purpose VARCHAR(100), -- Mục đích sử dụng
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng CitizenImage
CREATE OR REPLACE FUNCTION create_citizen_image_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenImage trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_image (
        image_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        image_type VARCHAR(50) NOT NULL, -- Chân dung/Toàn thân/Khác
        image_data BYTEA NOT NULL,
        image_format VARCHAR(20) NOT NULL, -- JPG/PNG/GIF
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        status BOOLEAN DEFAULT TRUE,
        purpose VARCHAR(100), -- Mục đích sử dụng
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng CitizenImage cho tất cả các database.'


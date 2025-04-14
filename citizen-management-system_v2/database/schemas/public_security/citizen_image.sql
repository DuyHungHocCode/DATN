-- Tạo bảng CitizenImage (Ảnh công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database bộ ngành và tạo bảng
\echo 'Tạo bảng CitizenImage cho các database bộ ngành...'



-- Kết nối đến database BCA
\connect ministry_of_public_security
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
\echo 'Đã tạo bảng CitizenImage cho BCA'

-- Kết nối đến database BTP
\connect ministry_of_justice
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
\echo 'Đã tạo bảng CitizenImage cho database BTP'

-- Kết nối đến database máy chủ trung tâm
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
\echo 'Đã tạo bảng CitizenImage cho database máy chủ trung tâm'


-- Tạo bảng CitizenImage (Ảnh công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng CitizenImage cho các database vùng miền...'

-- Hàm tạo bảng CitizenImage
CREATE OR REPLACE FUNCTION create_citizen_image_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenImage trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_image (
        image_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        image_type VARCHAR(50) NOT NULL, -- Chân dung/Toàn thân/Khác
        image_data BYTEA NOT NULL,
        image_format VARCHAR(20) NOT NULL, -- JPG/PNG/GIF
        capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        status BOOLEAN DEFAULT TRUE,
        purpose VARCHAR(100), -- Mục đích sử dụng
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE public_security.citizen_image IS 'Bảng lưu trữ ảnh của công dân';
    COMMENT ON COLUMN public_security.citizen_image.image_id IS 'Mã ảnh';
    COMMENT ON COLUMN public_security.citizen_image.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN public_security.citizen_image.image_type IS 'Loại ảnh (Chân dung/Toàn thân/Khác)';
    COMMENT ON COLUMN public_security.citizen_image.image_data IS 'Dữ liệu ảnh dạng binary';
    COMMENT ON COLUMN public_security.citizen_image.image_format IS 'Định dạng ảnh (JPG/PNG/GIF)';
    COMMENT ON COLUMN public_security.citizen_image.capture_date IS 'Ngày chụp ảnh';
    COMMENT ON COLUMN public_security.citizen_image.status IS 'Trạng thái hoạt động của ảnh';
    COMMENT ON COLUMN public_security.citizen_image.purpose IS 'Mục đích sử dụng ảnh';
    COMMENT ON COLUMN public_security.citizen_image.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN public_security.citizen_image.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN public_security.citizen_image.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.citizen_image.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_citizen_image_table();
\echo 'Đã tạo bảng CitizenImage cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_citizen_image_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng CitizenImage cho tất cả các database.'


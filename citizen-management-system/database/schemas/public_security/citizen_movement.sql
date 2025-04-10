-- Tạo bảng CitizenMovement (Di chuyển công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng CitizenMovement cho các database vùng miền...'

-- Hàm tạo bảng CitizenMovement
CREATE OR REPLACE FUNCTION create_citizen_movement_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenMovement trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_movement (
        movement_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        movement_type movement_type NOT NULL,
        from_address_id INT REFERENCES public_security.address(address_id),
        to_address_id INT REFERENCES public_security.address(address_id),
        departure_date DATE NOT NULL,
        arrival_date DATE,
        purpose TEXT,
        document_no VARCHAR(50),
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        source_region_id SMALLINT REFERENCES reference.region(region_id),
        target_region_id SMALLINT REFERENCES reference.region(region_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE public_security.citizen_movement IS 'Bảng lưu trữ thông tin di chuyển của công dân';
    COMMENT ON COLUMN public_security.citizen_movement.movement_id IS 'Mã di chuyển';
    COMMENT ON COLUMN public_security.citizen_movement.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN public_security.citizen_movement.movement_type IS 'Loại di chuyển (Trong nước/Xuất cảnh/Nhập cảnh/Tái nhập cảnh)';
    COMMENT ON COLUMN public_security.citizen_movement.from_address_id IS 'Mã địa chỉ đi';
    COMMENT ON COLUMN public_security.citizen_movement.to_address_id IS 'Mã địa chỉ đến';
    COMMENT ON COLUMN public_security.citizen_movement.departure_date IS 'Ngày đi';
    COMMENT ON COLUMN public_security.citizen_movement.arrival_date IS 'Ngày đến';
    COMMENT ON COLUMN public_security.citizen_movement.purpose IS 'Mục đích di chuyển';
    COMMENT ON COLUMN public_security.citizen_movement.document_no IS 'Số giấy tờ liên quan';
    COMMENT ON COLUMN public_security.citizen_movement.description IS 'Mô tả chi tiết';
    COMMENT ON COLUMN public_security.citizen_movement.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN public_security.citizen_movement.source_region_id IS 'Mã vùng miền nguồn';
    COMMENT ON COLUMN public_security.citizen_movement.target_region_id IS 'Mã vùng miền đích';
    COMMENT ON COLUMN public_security.citizen_movement.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.citizen_movement.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_citizen_movement_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng CitizenMovement cho tất cả các database.'
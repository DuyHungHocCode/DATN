-- Tạo bảng CitizenStatus (Trạng thái công dân) cho hệ thống CSDL phân
-- tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng CitizenStatus cho các database vùng miền...'

-- Hàm tạo bảng CitizenStatus
CREATE OR REPLACE FUNCTION create_citizen_status_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenStatus trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_status (
        status_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        status_type death_status NOT NULL DEFAULT 'Còn sống',
        status_date DATE NOT NULL,
        description TEXT,
        authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        document_number VARCHAR(50),
        document_date DATE,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    COMMENT ON TABLE public_security.citizen_status IS 'Bảng lưu trữ thông tin trạng thái công dân (sống/mất/mất tích)';
    COMMENT ON COLUMN public_security.citizen_status.status_id IS 'Mã trạng thái';
    COMMENT ON COLUMN public_security.citizen_status.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN public_security.citizen_status.status_type IS 'Loại trạng thái (Còn sống/Đã mất/Mất tích)';
    COMMENT ON COLUMN public_security.citizen_status.status_date IS 'Ngày cập nhật trạng thái';
    COMMENT ON COLUMN public_security.citizen_status.description IS 'Mô tả chi tiết';
    COMMENT ON COLUMN public_security.citizen_status.authority_id IS 'Mã cơ quan xác nhận';
    COMMENT ON COLUMN public_security.citizen_status.document_number IS 'Số văn bản';
    COMMENT ON COLUMN public_security.citizen_status.document_date IS 'Ngày văn bản';
    COMMENT ON COLUMN public_security.citizen_status.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN public_security.citizen_status.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN public_security.citizen_status.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN public_security.citizen_status.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.citizen_status.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_citizen_status_table();
\echo 'Đã tạo bảng CitizenStatus cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_citizen_status_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng CitizenStatus cho tất cả các database.'
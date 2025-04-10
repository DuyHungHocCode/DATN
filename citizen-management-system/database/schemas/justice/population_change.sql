-- Tạo bảng PopulationChange (Biến động dân cư) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng PopulationChange cho các database vùng miền...'

-- Hàm tạo bảng PopulationChange
CREATE OR REPLACE FUNCTION create_population_change_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng PopulationChange trong schema justice
    CREATE TABLE IF NOT EXISTS justice.population_change (
        change_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        change_type population_change_type NOT NULL,
        change_date DATE NOT NULL,
        source_location_id INT REFERENCES public_security.address(address_id),
        destination_location_id INT REFERENCES public_security.address(address_id),
        reason TEXT,
        related_document_no VARCHAR(50),
        related_document_id INT,
        processing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE justice.population_change IS 'Bảng lưu trữ thông tin biến động dân cư';
    COMMENT ON COLUMN justice.population_change.change_id IS 'Mã biến động';
    COMMENT ON COLUMN justice.population_change.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN justice.population_change.change_type IS 'Loại biến động (Sinh/Tử/Chuyển đến/Chuyển đi/Thay đổi HKTT/Kết hôn/Ly hôn/Thay đổi thông tin cá nhân)';
    COMMENT ON COLUMN justice.population_change.change_date IS 'Ngày biến động';
    COMMENT ON COLUMN justice.population_change.source_location_id IS 'Mã địa điểm nguồn';
    COMMENT ON COLUMN justice.population_change.destination_location_id IS 'Mã địa điểm đích';
    COMMENT ON COLUMN justice.population_change.reason IS 'Lý do';
    COMMENT ON COLUMN justice.population_change.related_document_no IS 'Số văn bản liên quan';
    COMMENT ON COLUMN justice.population_change.related_document_id IS 'Mã văn bản liên quan';
    COMMENT ON COLUMN justice.population_change.processing_authority_id IS 'Mã cơ quan xử lý';
    COMMENT ON COLUMN justice.population_change.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.population_change.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.population_change.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.population_change.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.population_change.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.population_change.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_population_change_table();
\echo 'Đã tạo bảng PopulationChange cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_population_change_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng PopulationChange cho tất cả các database.'
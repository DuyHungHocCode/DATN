-- Tạo bảng BiometricData (Dữ liệu sinh trắc học) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng BiometricData cho các database vùng miền...'

-- Hàm tạo bảng BiometricData
CREATE OR REPLACE FUNCTION create_biometric_data_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BiometricData trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.biometric_data (
        biometric_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
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
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        encryption_type_id SMALLINT REFERENCES reference.encryption_type(encryption_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_biometric_type_subtype UNIQUE (citizen_id, biometric_type, biometric_sub_type)
    );

-- Thêm comment cho bảng và các cột
    COMMENT ON TABLE public_security.biometric_data IS 'Bảng lưu trữ dữ liệu sinh trắc học của công dân';
    COMMENT ON COLUMN public_security.biometric_data.biometric_id IS 'Mã định danh sinh trắc học';
    COMMENT ON COLUMN public_security.biometric_data.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN public_security.biometric_data.biometric_type IS 'Loại sinh trắc học (Vân tay/Khuôn mặt/Mống mắt/Giọng nói)';
    COMMENT ON COLUMN public_security.biometric_data.biometric_sub_type IS 'Loại phụ (Ngón tay cụ thể, Mắt trái/phải, etc.)';
    COMMENT ON COLUMN public_security.biometric_data.biometric_data IS 'Dữ liệu sinh trắc học dạng binary';
    COMMENT ON COLUMN public_security.biometric_data.biometric_format IS 'Định dạng dữ liệu (JPG, WSQ, ISO, etc.)';
    COMMENT ON COLUMN public_security.biometric_data.biometric_template IS 'Mẫu sinh trắc học đã được xử lý';
    COMMENT ON COLUMN public_security.biometric_data.capture_date IS 'Ngày lấy dữ liệu';
    COMMENT ON COLUMN public_security.biometric_data.quality IS 'Chất lượng (0-100)';
    COMMENT ON COLUMN public_security.biometric_data.device_id IS 'Mã thiết bị thu nhận';
    COMMENT ON COLUMN public_security.biometric_data.device_model IS 'Model thiết bị';
    COMMENT ON COLUMN public_security.biometric_data.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN public_security.biometric_data.reason IS 'Lý do cập nhật';
    COMMENT ON COLUMN public_security.biometric_data.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN public_security.biometric_data.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN public_security.biometric_data.encryption_type_id IS 'Mã loại mã hóa';
    COMMENT ON COLUMN public_security.biometric_data.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.biometric_data.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
    COMMENT ON COLUMN public_security.biometric_data.created_by IS 'Người tạo bản ghi';
    COMMENT ON COLUMN public_security.biometric_data.updated_by IS 'Người cập nhật bản ghi gần nhất';

    -- -- Tạo index cho các cột thường xuyên truy vấn
    -- CREATE INDEX IF NOT EXISTS idx_bio_citizen_id ON public_security.biometric_data(citizen_id);
    -- CREATE INDEX IF NOT EXISTS idx_bio_type ON public_security.biometric_data(biometric_type);
    -- CREATE INDEX IF NOT EXISTS idx_bio_subtype ON public_security.biometric_data(biometric_sub_type);
    -- CREATE INDEX IF NOT EXISTS idx_bio_capture_date ON public_security.biometric_data(capture_date);
    -- CREATE INDEX IF NOT EXISTS idx_bio_quality ON public_security.biometric_data(quality);
    -- CREATE INDEX IF NOT EXISTS idx_bio_region ON public_security.biometric_data(region_id);
    -- CREATE INDEX IF NOT EXISTS idx_bio_province ON public_security.biometric_data(province_id);
    -- CREATE INDEX IF NOT EXISTS idx_bio_status ON public_security.biometric_data(status);


    -- -- Tạo chỉ mục tìm kiếm theo ngày chụp/lấy dữ liệu
    -- CREATE INDEX IF NOT EXISTS idx_bio_capture_date_range ON public_security.biometric_data USING btree (capture_date);

    -- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_biometric_data_table();
\echo 'Đã tạo bảng BiometricData cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_biometric_data_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng BiometricData cho tất cả các database.'
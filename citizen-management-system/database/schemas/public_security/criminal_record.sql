-- Tạo bảng CriminalRecord (Hồ sơ phạm nhân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng CriminalRecord cho các database vùng miền...'

-- Hàm tạo bảng CriminalRecord
CREATE OR REPLACE FUNCTION create_criminal_record_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CriminalRecord trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.criminal_record (
        record_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        crime_type VARCHAR(100) NOT NULL,
        crime_date DATE NOT NULL,
        court_name VARCHAR(200) NOT NULL,
        sentence_date DATE NOT NULL,
        sentence_length VARCHAR(100) NOT NULL, -- "5 năm", "Chung thân"
        prison_facility_id INT,
        prison_facility_name VARCHAR(200),
        release_date DATE,
        status VARCHAR(50) NOT NULL, -- Đang thụ án/Đã mãn hạn/Ân xá
        decision_number VARCHAR(50) NOT NULL,
        decision_date DATE NOT NULL,
        note TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE public_security.criminal_record IS 'Bảng lưu trữ thông tin hồ sơ phạm nhân';
    COMMENT ON COLUMN public_security.criminal_record.record_id IS 'Mã hồ sơ';
    COMMENT ON COLUMN public_security.criminal_record.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN public_security.criminal_record.crime_type IS 'Loại tội phạm';
    COMMENT ON COLUMN public_security.criminal_record.crime_date IS 'Ngày phạm tội';
    COMMENT ON COLUMN public_security.criminal_record.court_name IS 'Tên tòa án';
    COMMENT ON COLUMN public_security.criminal_record.sentence_date IS 'Ngày tuyên án';
    COMMENT ON COLUMN public_security.criminal_record.sentence_length IS 'Thời gian án phạt';
    COMMENT ON COLUMN public_security.criminal_record.prison_facility_id IS 'Mã cơ sở giam giữ';
    COMMENT ON COLUMN public_security.criminal_record.prison_facility_name IS 'Tên cơ sở giam giữ';
    COMMENT ON COLUMN public_security.criminal_record.release_date IS 'Ngày ra tù';
    COMMENT ON COLUMN public_security.criminal_record.status IS 'Trạng thái';
    COMMENT ON COLUMN public_security.criminal_record.decision_number IS 'Số quyết định';
    COMMENT ON COLUMN public_security.criminal_record.decision_date IS 'Ngày quyết định';
    COMMENT ON COLUMN public_security.criminal_record.note IS 'Ghi chú';
    COMMENT ON COLUMN public_security.criminal_record.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN public_security.criminal_record.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN public_security.criminal_record.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.criminal_record.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_criminal_record_table();
\echo 'Đã tạo bảng CriminalRecord cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_criminal_record_table();
\echo 'Đã tạo bảng CriminalRecord cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_criminal_record_table();
\echo 'Đã tạo bảng CriminalRecord cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_criminal_record_table();
\echo 'Đã tạo bảng CriminalRecord cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_criminal_record_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng CriminalRecord cho tất cả các database.'
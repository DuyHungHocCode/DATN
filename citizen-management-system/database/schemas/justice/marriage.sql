
-- Tạo bảng Marriage (Đăng ký kết hôn) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng Marriage cho các database vùng miền...'

-- Hàm tạo bảng Marriage
CREATE OR REPLACE FUNCTION create_marriage_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Marriage trong schema justice
    CREATE TABLE IF NOT EXISTS justice.marriage (
        marriage_id SERIAL PRIMARY KEY,
        marriage_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        husband_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        husband_full_name VARCHAR(100) NOT NULL,
        husband_date_of_birth DATE NOT NULL,
        husband_nationality_id SMALLINT REFERENCES reference.nationality(nationality_id),
        husband_previous_marriage_status marital_status NOT NULL,
        wife_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        wife_full_name VARCHAR(100) NOT NULL,
        wife_date_of_birth DATE NOT NULL,
        wife_nationality_id SMALLINT REFERENCES reference.nationality(nationality_id),
        wife_previous_marriage_status marital_status NOT NULL,
        marriage_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        issuing_place TEXT,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_husband_wife CHECK (husband_id <> wife_id)
    );
    
    COMMENT ON TABLE justice.marriage IS 'Bảng lưu trữ thông tin đăng ký kết hôn';
    COMMENT ON COLUMN justice.marriage.marriage_id IS 'Mã kết hôn';
    COMMENT ON COLUMN justice.marriage.marriage_certificate_no IS 'Số giấy chứng nhận kết hôn';
    COMMENT ON COLUMN justice.marriage.book_id IS 'Mã sổ';
    COMMENT ON COLUMN justice.marriage.page_no IS 'Số trang';
    COMMENT ON COLUMN justice.marriage.husband_id IS 'Mã định danh chồng';
    COMMENT ON COLUMN justice.marriage.husband_full_name IS 'Họ tên chồng';
    COMMENT ON COLUMN justice.marriage.husband_date_of_birth IS 'Ngày sinh chồng';
    COMMENT ON COLUMN justice.marriage.husband_nationality_id IS 'Mã quốc tịch chồng';
    COMMENT ON COLUMN justice.marriage.husband_previous_marriage_status IS 'Tình trạng hôn nhân trước của chồng';
    COMMENT ON COLUMN justice.marriage.wife_id IS 'Mã định danh vợ';
    COMMENT ON COLUMN justice.marriage.wife_full_name IS 'Họ tên vợ';
    COMMENT ON COLUMN justice.marriage.wife_date_of_birth IS 'Ngày sinh vợ';
    COMMENT ON COLUMN justice.marriage.wife_nationality_id IS 'Mã quốc tịch vợ';
    COMMENT ON COLUMN justice.marriage.wife_previous_marriage_status IS 'Tình trạng hôn nhân trước của vợ';
    COMMENT ON COLUMN justice.marriage.marriage_date IS 'Ngày kết hôn';
    COMMENT ON COLUMN justice.marriage.registration_date IS 'Ngày đăng ký';
    COMMENT ON COLUMN justice.marriage.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN justice.marriage.issuing_place IS 'Nơi cấp';
    COMMENT ON COLUMN justice.marriage.witness1_name IS 'Tên nhân chứng 1';
    COMMENT ON COLUMN justice.marriage.witness2_name IS 'Tên nhân chứng 2';
    COMMENT ON COLUMN justice.marriage.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.marriage.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.marriage.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.marriage.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.marriage.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.marriage.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_marriage_table();
\echo 'Đã tạo bảng Marriage cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_marriage_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng Marriage cho tất cả các database.'
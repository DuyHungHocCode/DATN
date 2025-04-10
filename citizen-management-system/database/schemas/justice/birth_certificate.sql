-- Tạo bảng BirthCertificate (Giấy khai sinh) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng BirthCertificate cho các database vùng miền...'

-- Hàm tạo bảng BirthCertificate
CREATE OR REPLACE FUNCTION create_birth_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng BirthCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.birth_certificate (
        birth_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        birth_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        registration_date DATE NOT NULL,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        place_of_birth TEXT NOT NULL,
        date_of_birth DATE NOT NULL,
        gender_at_birth gender_type NOT NULL,
        father_full_name VARCHAR(100),
        father_citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),
        father_date_of_birth DATE,
        father_nationality_id SMALLINT REFERENCES reference.nationality(nationality_id),
        mother_full_name VARCHAR(100),
        mother_citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),
        mother_date_of_birth DATE,
        mother_nationality_id SMALLINT REFERENCES reference.nationality(nationality_id),
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),
        declarant_relationship VARCHAR(50) NOT NULL,
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        birth_notification_no VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE justice.birth_certificate IS 'Bảng lưu trữ thông tin giấy khai sinh';
    COMMENT ON COLUMN justice.birth_certificate.birth_certificate_id IS 'Mã khai sinh';
    COMMENT ON COLUMN justice.birth_certificate.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN justice.birth_certificate.birth_certificate_no IS 'Số giấy khai sinh';
    COMMENT ON COLUMN justice.birth_certificate.registration_date IS 'Ngày đăng ký';
    COMMENT ON COLUMN justice.birth_certificate.book_id IS 'Mã sổ';
    COMMENT ON COLUMN justice.birth_certificate.page_no IS 'Số trang';
    COMMENT ON COLUMN justice.birth_certificate.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN justice.birth_certificate.place_of_birth IS 'Nơi sinh';
    COMMENT ON COLUMN justice.birth_certificate.date_of_birth IS 'Ngày sinh';
    COMMENT ON COLUMN justice.birth_certificate.gender_at_birth IS 'Giới tính khi sinh';
    COMMENT ON COLUMN justice.birth_certificate.father_full_name IS 'Họ tên cha';
    COMMENT ON COLUMN justice.birth_certificate.father_citizen_id IS 'Mã định danh cha';
    COMMENT ON COLUMN justice.birth_certificate.father_date_of_birth IS 'Ngày sinh cha';
    COMMENT ON COLUMN justice.birth_certificate.father_nationality_id IS 'Mã quốc tịch cha';
    COMMENT ON COLUMN justice.birth_certificate.mother_full_name IS 'Họ tên mẹ';
    COMMENT ON COLUMN justice.birth_certificate.mother_citizen_id IS 'Mã định danh mẹ';
    COMMENT ON COLUMN justice.birth_certificate.mother_date_of_birth IS 'Ngày sinh mẹ';
    COMMENT ON COLUMN justice.birth_certificate.mother_nationality_id IS 'Mã quốc tịch mẹ';
    COMMENT ON COLUMN justice.birth_certificate.declarant_name IS 'Người khai sinh';
    COMMENT ON COLUMN justice.birth_certificate.declarant_citizen_id IS 'Mã định danh người khai sinh';
    COMMENT ON COLUMN justice.birth_certificate.declarant_relationship IS 'Quan hệ với người khai sinh';
    COMMENT ON COLUMN justice.birth_certificate.witness1_name IS 'Tên nhân chứng 1';
    COMMENT ON COLUMN justice.birth_certificate.witness2_name IS 'Tên nhân chứng 2';
    COMMENT ON COLUMN justice.birth_certificate.birth_notification_no IS 'Số giấy chứng sinh (từ cơ sở y tế)';
    COMMENT ON COLUMN justice.birth_certificate.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.birth_certificate.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.birth_certificate.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.birth_certificate.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.birth_certificate.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.birth_certificate.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_birth_certificate_table();
\echo 'Đã tạo bảng BirthCertificate cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_birth_certificate_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng BirthCertificate cho tất cả các database.'
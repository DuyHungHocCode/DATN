-- Tạo bảng DeathCertificate (Giấy khai tử) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng DeathCertificate cho các database vùng miền...'

-- Hàm tạo bảng DeathCertificate
CREATE OR REPLACE FUNCTION create_death_certificate_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DeathCertificate trong schema justice
    CREATE TABLE IF NOT EXISTS justice.death_certificate (
        death_certificate_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        death_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        date_of_death DATE NOT NULL,
        time_of_death TIME,
        place_of_death TEXT NOT NULL,
        cause_of_death TEXT,
        declarant_name VARCHAR(100) NOT NULL,
        declarant_citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),
        declarant_relationship VARCHAR(50) NOT NULL,
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        death_notification_no VARCHAR(50),
        witness1_name VARCHAR(100),
        witness2_name VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE justice.death_certificate IS 'Bảng lưu trữ thông tin giấy khai tử';
    COMMENT ON COLUMN justice.death_certificate.death_certificate_id IS 'Mã khai tử';
    COMMENT ON COLUMN justice.death_certificate.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN justice.death_certificate.death_certificate_no IS 'Số giấy chứng tử';
    COMMENT ON COLUMN justice.death_certificate.book_id IS 'Mã sổ';
    COMMENT ON COLUMN justice.death_certificate.page_no IS 'Số trang';
    COMMENT ON COLUMN justice.death_certificate.date_of_death IS 'Ngày mất';
    COMMENT ON COLUMN justice.death_certificate.time_of_death IS 'Giờ mất';
    COMMENT ON COLUMN justice.death_certificate.place_of_death IS 'Nơi mất';
    COMMENT ON COLUMN justice.death_certificate.cause_of_death IS 'Nguyên nhân';
    COMMENT ON COLUMN justice.death_certificate.declarant_name IS 'Người khai tử';
    COMMENT ON COLUMN justice.death_certificate.declarant_citizen_id IS 'Mã định danh người khai tử';
    COMMENT ON COLUMN justice.death_certificate.declarant_relationship IS 'Quan hệ với người khai tử';
    COMMENT ON COLUMN justice.death_certificate.registration_date IS 'Ngày đăng ký';
    COMMENT ON COLUMN justice.death_certificate.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN justice.death_certificate.death_notification_no IS 'Số giấy báo tử (từ cơ sở y tế)';
    COMMENT ON COLUMN justice.death_certificate.witness1_name IS 'Tên nhân chứng 1';
    COMMENT ON COLUMN justice.death_certificate.witness2_name IS 'Tên nhân chứng 2';
    COMMENT ON COLUMN justice.death_certificate.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.death_certificate.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.death_certificate.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.death_certificate.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.death_certificate.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.death_certificate.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_death_certificate_table();
\echo 'Đã tạo bảng DeathCertificate cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_death_certificate_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng DeathCertificate cho tất cả các database.'
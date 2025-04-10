-- Tạo bảng Divorce (Đăng ký ly hôn) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng Divorce cho các database vùng miền...'

-- Hàm tạo bảng Divorce
CREATE OR REPLACE FUNCTION create_divorce_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Divorce trong schema justice
    CREATE TABLE IF NOT EXISTS justice.divorce (
        divorce_id SERIAL PRIMARY KEY,
        divorce_certificate_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        marriage_id INT REFERENCES justice.marriage(marriage_id),
        divorce_date DATE NOT NULL,
        registration_date DATE NOT NULL,
        court_name VARCHAR(200),
        judgment_no VARCHAR(50),
        judgment_date DATE,
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        reason TEXT,
        child_custody TEXT,
        property_division TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE justice.divorce IS 'Bảng lưu trữ thông tin đăng ký ly hôn';
    COMMENT ON COLUMN justice.divorce.divorce_id IS 'Mã ly hôn';
    COMMENT ON COLUMN justice.divorce.divorce_certificate_no IS 'Số giấy chứng nhận ly hôn';
    COMMENT ON COLUMN justice.divorce.book_id IS 'Mã sổ';
    COMMENT ON COLUMN justice.divorce.page_no IS 'Số trang';
    COMMENT ON COLUMN justice.divorce.marriage_id IS 'Mã kết hôn';
    COMMENT ON COLUMN justice.divorce.divorce_date IS 'Ngày ly hôn';
    COMMENT ON COLUMN justice.divorce.registration_date IS 'Ngày đăng ký';
    COMMENT ON COLUMN justice.divorce.court_name IS 'Tên tòa án';
    COMMENT ON COLUMN justice.divorce.judgment_no IS 'Số bản án';
    COMMENT ON COLUMN justice.divorce.judgment_date IS 'Ngày bản án';
    COMMENT ON COLUMN justice.divorce.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN justice.divorce.reason IS 'Lý do';
    COMMENT ON COLUMN justice.divorce.child_custody IS 'Thông tin quyền nuôi con';
    COMMENT ON COLUMN justice.divorce.property_division IS 'Thông tin phân chia tài sản';
    COMMENT ON COLUMN justice.divorce.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.divorce.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.divorce.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.divorce.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.divorce.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.divorce.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_divorce_table();
\echo 'Đã tạo bảng Divorce cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_divorce_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng Divorce cho tất cả các database.'
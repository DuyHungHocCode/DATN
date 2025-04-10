-- Tạo bảng GuardianRelationship (Quan hệ giám hộ) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng GuardianRelationship cho các database vùng miền...'

-- Hàm tạo bảng GuardianRelationship
CREATE OR REPLACE FUNCTION create_guardian_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng GuardianRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.guardian_relationship (
        guardianship_id SERIAL PRIMARY KEY,
        guardianship_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        ward_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        ward_full_name VARCHAR(100) NOT NULL,
        guardian_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        guardian_full_name VARCHAR(100) NOT NULL,
        guardianship_type guardianship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        registration_date DATE NOT NULL,
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        reason TEXT,
        scope TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_ward_guardian CHECK (ward_id <> guardian_id)
    );
    
    COMMENT ON TABLE justice.guardian_relationship IS 'Bảng lưu trữ thông tin quan hệ giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.guardianship_id IS 'Mã giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.guardianship_no IS 'Số giấy chứng nhận giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.book_id IS 'Mã sổ';
    COMMENT ON COLUMN justice.guardian_relationship.page_no IS 'Số trang';
    COMMENT ON COLUMN justice.guardian_relationship.ward_id IS 'Mã định danh người được giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.ward_full_name IS 'Họ tên người được giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.guardian_id IS 'Mã định danh người giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.guardian_full_name IS 'Họ tên người giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.guardianship_type IS 'Loại giám hộ (Người chưa thành niên/Người mất năng lực hành vi)';
    COMMENT ON COLUMN justice.guardian_relationship.start_date IS 'Ngày bắt đầu';
    COMMENT ON COLUMN justice.guardian_relationship.end_date IS 'Ngày kết thúc';
    COMMENT ON COLUMN justice.guardian_relationship.registration_date IS 'Ngày đăng ký';
    COMMENT ON COLUMN justice.guardian_relationship.document_no IS 'Số văn bản';
    COMMENT ON COLUMN justice.guardian_relationship.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN justice.guardian_relationship.reason IS 'Lý do';
    COMMENT ON COLUMN justice.guardian_relationship.scope IS 'Phạm vi giám hộ';
    COMMENT ON COLUMN justice.guardian_relationship.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.guardian_relationship.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.guardian_relationship.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.guardian_relationship.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.guardian_relationship.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.guardian_relationship.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_guardian_relationship_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng GuardianRelationship cho tất cả các database.'
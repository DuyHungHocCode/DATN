-- Tạo bảng FamilyRelationship (Quan hệ gia đình) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng FamilyRelationship cho các database vùng miền...'

-- Hàm tạo bảng FamilyRelationship
CREATE OR REPLACE FUNCTION create_family_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng FamilyRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.family_relationship (
        relationship_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        related_citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        relationship_type family_relationship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        status BOOLEAN DEFAULT TRUE,
        document_proof VARCHAR(100),
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_family_relationship UNIQUE (citizen_id, related_citizen_id, relationship_type),
        CONSTRAINT check_different_citizens CHECK (citizen_id <> related_citizen_id)
    );
    
    COMMENT ON TABLE justice.family_relationship IS 'Bảng lưu trữ thông tin quan hệ gia đình';
    COMMENT ON COLUMN justice.family_relationship.relationship_id IS 'Mã quan hệ';
    COMMENT ON COLUMN justice.family_relationship.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN justice.family_relationship.related_citizen_id IS 'Mã định danh người có quan hệ';
    COMMENT ON COLUMN justice.family_relationship.relationship_type IS 'Loại quan hệ';
    COMMENT ON COLUMN justice.family_relationship.start_date IS 'Ngày bắt đầu';
    COMMENT ON COLUMN justice.family_relationship.end_date IS 'Ngày kết thúc';
    COMMENT ON COLUMN justice.family_relationship.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.family_relationship.document_proof IS 'Văn bản chứng minh';
    COMMENT ON COLUMN justice.family_relationship.document_no IS 'Số văn bản';
    COMMENT ON COLUMN justice.family_relationship.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN justice.family_relationship.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.family_relationship.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.family_relationship.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.family_relationship.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.family_relationship.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_family_relationship_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng FamilyRelationship cho tất cả các database.'
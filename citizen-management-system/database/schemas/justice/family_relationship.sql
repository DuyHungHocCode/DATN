-- Tạo bảng FamilyRelationship (Quan hệ gia đình) cho hệ thống CSDL phân tán quản lý dân cư quốc gia
-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng FamilyRelationship cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng FamilyRelationship
CREATE OR REPLACE FUNCTION create_family_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng FamilyRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.family_relationship (
        relationship_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        related_citizen_id VARCHAR(12) NOT NULL,
        relationship_type family_relationship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        status BOOLEAN DEFAULT TRUE,
        document_proof VARCHAR(100),
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_family_relationship UNIQUE (citizen_id, related_citizen_id, relationship_type),
        CONSTRAINT check_different_citizens CHECK (citizen_id <> related_citizen_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng FamilyRelationship
CREATE OR REPLACE FUNCTION create_family_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng FamilyRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.family_relationship (
        relationship_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        related_citizen_id VARCHAR(12) NOT NULL,
        relationship_type family_relationship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        status BOOLEAN DEFAULT TRUE,
        document_proof VARCHAR(100),
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_family_relationship UNIQUE (citizen_id, related_citizen_id, relationship_type),
        CONSTRAINT check_different_citizens CHECK (citizen_id <> related_citizen_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng FamilyRelationship
CREATE OR REPLACE FUNCTION create_family_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng FamilyRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.family_relationship (
        relationship_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        related_citizen_id VARCHAR(12) NOT NULL,
        relationship_type family_relationship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        status BOOLEAN DEFAULT TRUE,
        document_proof VARCHAR(100),
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_family_relationship UNIQUE (citizen_id, related_citizen_id, relationship_type),
        CONSTRAINT check_different_citizens CHECK (citizen_id <> related_citizen_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng FamilyRelationship
CREATE OR REPLACE FUNCTION create_family_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng FamilyRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.family_relationship (
        relationship_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        related_citizen_id VARCHAR(12) NOT NULL,
        relationship_type family_relationship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        status BOOLEAN DEFAULT TRUE,
        document_proof VARCHAR(100),
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_family_relationship UNIQUE (citizen_id, related_citizen_id, relationship_type),
        CONSTRAINT check_different_citizens CHECK (citizen_id <> related_citizen_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_family_relationship_table();
\echo 'Đã tạo bảng FamilyRelationship cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng FamilyRelationship cho tất cả các database.'
-- Tạo bảng GuardianRelationship (Quan hệ giám hộ) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng GuardianRelationship cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng GuardianRelationship
CREATE OR REPLACE FUNCTION create_guardian_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng GuardianRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.guardian_relationship (
        guardianship_id SERIAL PRIMARY KEY,
        guardianship_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        ward_id VARCHAR(12) NOT NULL,
        ward_full_name VARCHAR(100) NOT NULL,
        guardian_id VARCHAR(12) NOT NULL,
        guardian_full_name VARCHAR(100) NOT NULL,
        guardianship_type guardianship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        registration_date DATE NOT NULL,
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        reason TEXT,
        scope TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_ward_guardian CHECK (ward_id <> guardian_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng GuardianRelationship
CREATE OR REPLACE FUNCTION create_guardian_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng GuardianRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.guardian_relationship (
        guardianship_id SERIAL PRIMARY KEY,
        guardianship_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        ward_id VARCHAR(12) NOT NULL,
        ward_full_name VARCHAR(100) NOT NULL,
        guardian_id VARCHAR(12) NOT NULL,
        guardian_full_name VARCHAR(100) NOT NULL,
        guardianship_type guardianship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        registration_date DATE NOT NULL,
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        reason TEXT,
        scope TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_ward_guardian CHECK (ward_id <> guardian_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng GuardianRelationship
CREATE OR REPLACE FUNCTION create_guardian_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng GuardianRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.guardian_relationship (
        guardianship_id SERIAL PRIMARY KEY,
        guardianship_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        ward_id VARCHAR(12) NOT NULL,
        ward_full_name VARCHAR(100) NOT NULL,
        guardian_id VARCHAR(12) NOT NULL,
        guardian_full_name VARCHAR(100) NOT NULL,
        guardianship_type guardianship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        registration_date DATE NOT NULL,
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        reason TEXT,
        scope TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_ward_guardian CHECK (ward_id <> guardian_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng GuardianRelationship
CREATE OR REPLACE FUNCTION create_guardian_relationship_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng GuardianRelationship trong schema justice
    CREATE TABLE IF NOT EXISTS justice.guardian_relationship (
        guardianship_id SERIAL PRIMARY KEY,
        guardianship_no VARCHAR(20) NOT NULL UNIQUE,
        book_id VARCHAR(20),
        page_no VARCHAR(10),
        ward_id VARCHAR(12) NOT NULL,
        ward_full_name VARCHAR(100) NOT NULL,
        guardian_id VARCHAR(12) NOT NULL,
        guardian_full_name VARCHAR(100) NOT NULL,
        guardianship_type guardianship_type NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE,
        registration_date DATE NOT NULL,
        document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        reason TEXT,
        scope TEXT,
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT check_different_ward_guardian CHECK (ward_id <> guardian_id)
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_guardian_relationship_table();
\echo 'Đã tạo bảng GuardianRelationship cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng GuardianRelationship cho tất cả các database.'
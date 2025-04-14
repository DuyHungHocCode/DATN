-- Tạo các bảng tham chiếu dùng chung cho hệ thống CSDL phân tán quản lý dân cư quốc gia



-- Tạo schema reference trên tất cả các database

-- Kết nối đến database miền Bắc
\connect national_citizen_north
CREATE SCHEMA IF NOT EXISTS reference;
-- Hàm tạo các bảng tham chiếu tiêu chuẩn
CREATE OR REPLACE FUNCTION create_reference_tables() RETURNS void AS $$
BEGIN
    -- Bảng vùng miền (Region)
    CREATE TABLE IF NOT EXISTS reference.region (
        region_id SMALLINT PRIMARY KEY,
        region_code VARCHAR(10) NOT NULL UNIQUE,
        region_name VARCHAR(50) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tỉnh/thành phố (Province)
    CREATE TABLE IF NOT EXISTS reference.province (
        province_id INT PRIMARY KEY,
        province_code VARCHAR(10) NOT NULL UNIQUE,
        province_name VARCHAR(100) NOT NULL,
        province_type division_type, -- Tỉnh/Thành phố trực thuộc TW
        region_id SMALLINT,
        area_code VARCHAR(10), -- Mã vùng điện thoại
        postal_code VARCHAR(10), -- Mã bưu chính
        phone_code VARCHAR(10), -- Mã điện thoại
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quận/huyện (District)
    CREATE TABLE IF NOT EXISTS reference.district (
        district_id INT PRIMARY KEY,
        district_code VARCHAR(10) NOT NULL UNIQUE,
        district_name VARCHAR(100) NOT NULL,
        province_id INT,
        district_type division_type, -- Quận/Huyện/Thị xã/Thành phố thuộc tỉnh
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng phường/xã (Ward)
    CREATE TABLE IF NOT EXISTS reference.ward (
        ward_id INT PRIMARY KEY,
        ward_code VARCHAR(10) NOT NULL UNIQUE,
        ward_name VARCHAR(100) NOT NULL,
        district_id INT,
        ward_type division_type, -- Phường/Xã/Thị trấn
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng dân tộc (Ethnicity)
    CREATE TABLE IF NOT EXISTS reference.ethnicity (
        ethnicity_id SMALLINT PRIMARY KEY,
        ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
        ethnicity_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tôn giáo (Religion)
    CREATE TABLE IF NOT EXISTS reference.religion (
        religion_id SMALLINT PRIMARY KEY,
        religion_code VARCHAR(10) NOT NULL UNIQUE,
        religion_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quốc tịch (Nationality)
    CREATE TABLE IF NOT EXISTS reference.nationality (
        nationality_id SMALLINT PRIMARY KEY,
        nationality_code VARCHAR(10) NOT NULL UNIQUE,
        nationality_name VARCHAR(100) NOT NULL,
        country_code VARCHAR(10) NOT NULL,
        country_name VARCHAR(100) NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại quan hệ gia đình (RelationshipType)
    CREATE TABLE IF NOT EXISTS reference.relationship_type (
        relationship_type_id SMALLINT PRIMARY KEY,
        relationship_code VARCHAR(10) NOT NULL UNIQUE,
        relationship_name VARCHAR(100) NOT NULL,
        description TEXT,
        category VARCHAR(50), -- Nhóm quan hệ: Gia đình/Họ hàng/Giám hộ
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trình độ học vấn (EducationLevel)
    CREATE TABLE IF NOT EXISTS reference.education_level (
        education_level_id SMALLINT PRIMARY KEY,
        education_code VARCHAR(10) NOT NULL UNIQUE,
        education_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại nghề nghiệp (OccupationType)
    CREATE TABLE IF NOT EXISTS reference.occupation_type (
        occupation_type_id SMALLINT PRIMARY KEY,
        occupation_code VARCHAR(10) NOT NULL UNIQUE,
        occupation_name VARCHAR(100) NOT NULL,
        category VARCHAR(50), -- Nhóm nghề nghiệp
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại giấy tờ (DocumentType)
    CREATE TABLE IF NOT EXISTS reference.document_type (
        document_type_id SMALLINT PRIMARY KEY,
        document_code VARCHAR(10) NOT NULL UNIQUE,
        document_name VARCHAR(100) NOT NULL,
        issuing_agency VARCHAR(200), -- Cơ quan cấp
        validity_period INT, -- Thời hạn hiệu lực (tháng)
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trạng thái hồ sơ (RecordStatus)
    CREATE TABLE IF NOT EXISTS reference.record_status (
        status_id SMALLINT PRIMARY KEY,
        status_code VARCHAR(10) NOT NULL UNIQUE,
        status_name VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng cơ quan cấp (IssuingAuthority)
    CREATE TABLE IF NOT EXISTS reference.issuing_authority (
        authority_id SMALLINT PRIMARY KEY,
        authority_code VARCHAR(10) NOT NULL UNIQUE,
        authority_name VARCHAR(200) NOT NULL,
        authority_type VARCHAR(50), -- Loại cơ quan: Công an/Tư pháp/Hành chính
        parent_authority_id SMALLINT,
        province_id INT,
        district_id INT,
        address TEXT,
        phone VARCHAR(20),
        email VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng vai trò người dùng (UserRole)
    CREATE TABLE IF NOT EXISTS reference.user_role (
        role_id SMALLINT PRIMARY KEY,
        role_code VARCHAR(20) NOT NULL UNIQUE,
        role_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng các yếu tố mã hóa (EncryptionType)
    CREATE TABLE IF NOT EXISTS reference.encryption_type (
        encryption_id SMALLINT PRIMARY KEY,
        encryption_name VARCHAR(50) NOT NULL UNIQUE,
        algorithm VARCHAR(50) NOT NULL,
        key_length INT,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng lý do truy cập dữ liệu (AccessReason)
    CREATE TABLE IF NOT EXISTS reference.access_reason (
        reason_id SMALLINT PRIMARY KEY,
        reason_code VARCHAR(20) NOT NULL UNIQUE,
        reason_name VARCHAR(200) NOT NULL,
        description TEXT,
        requires_approval BOOLEAN DEFAULT FALSE,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng đặc biệt chỉ có ở máy chủ trung tâm
    CREATE TABLE IF NOT EXISTS reference.sync_config (
        config_id SERIAL PRIMARY KEY,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        sync_table_name VARCHAR(100) NOT NULL,
        sync_frequency VARCHAR(50), -- Tần suất đồng bộ: realtime, hourly, daily
        last_sync_time TIMESTAMP WITH TIME ZONE,
        priority SMALLINT DEFAULT 5, -- Độ ưu tiên (1-10)
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_tables();
\echo 'Đã tạo các bảng tham chiếu cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
CREATE SCHEMA IF NOT EXISTS reference;
-- Hàm tạo các bảng tham chiếu tiêu chuẩn
CREATE OR REPLACE FUNCTION create_reference_tables() RETURNS void AS $$
BEGIN
    -- Bảng vùng miền (Region)
    CREATE TABLE IF NOT EXISTS reference.region (
        region_id SMALLINT PRIMARY KEY,
        region_code VARCHAR(10) NOT NULL UNIQUE,
        region_name VARCHAR(50) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tỉnh/thành phố (Province)
    CREATE TABLE IF NOT EXISTS reference.province (
        province_id INT PRIMARY KEY,
        province_code VARCHAR(10) NOT NULL UNIQUE,
        province_name VARCHAR(100) NOT NULL,
        province_type division_type, -- Tỉnh/Thành phố trực thuộc TW
        region_id SMALLINT,
        area_code VARCHAR(10), -- Mã vùng điện thoại
        postal_code VARCHAR(10), -- Mã bưu chính
        phone_code VARCHAR(10), -- Mã điện thoại
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quận/huyện (District)
    CREATE TABLE IF NOT EXISTS reference.district (
        district_id INT PRIMARY KEY,
        district_code VARCHAR(10) NOT NULL UNIQUE,
        district_name VARCHAR(100) NOT NULL,
        province_id INT,
        district_type division_type, -- Quận/Huyện/Thị xã/Thành phố thuộc tỉnh
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng phường/xã (Ward)
    CREATE TABLE IF NOT EXISTS reference.ward (
        ward_id INT PRIMARY KEY,
        ward_code VARCHAR(10) NOT NULL UNIQUE,
        ward_name VARCHAR(100) NOT NULL,
        district_id INT,
        ward_type division_type, -- Phường/Xã/Thị trấn
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng dân tộc (Ethnicity)
    CREATE TABLE IF NOT EXISTS reference.ethnicity (
        ethnicity_id SMALLINT PRIMARY KEY,
        ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
        ethnicity_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tôn giáo (Religion)
    CREATE TABLE IF NOT EXISTS reference.religion (
        religion_id SMALLINT PRIMARY KEY,
        religion_code VARCHAR(10) NOT NULL UNIQUE,
        religion_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quốc tịch (Nationality)
    CREATE TABLE IF NOT EXISTS reference.nationality (
        nationality_id SMALLINT PRIMARY KEY,
        nationality_code VARCHAR(10) NOT NULL UNIQUE,
        nationality_name VARCHAR(100) NOT NULL,
        country_code VARCHAR(10) NOT NULL,
        country_name VARCHAR(100) NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại quan hệ gia đình (RelationshipType)
    CREATE TABLE IF NOT EXISTS reference.relationship_type (
        relationship_type_id SMALLINT PRIMARY KEY,
        relationship_code VARCHAR(10) NOT NULL UNIQUE,
        relationship_name VARCHAR(100) NOT NULL,
        description TEXT,
        category VARCHAR(50), -- Nhóm quan hệ: Gia đình/Họ hàng/Giám hộ
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trình độ học vấn (EducationLevel)
    CREATE TABLE IF NOT EXISTS reference.education_level (
        education_level_id SMALLINT PRIMARY KEY,
        education_code VARCHAR(10) NOT NULL UNIQUE,
        education_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại nghề nghiệp (OccupationType)
    CREATE TABLE IF NOT EXISTS reference.occupation_type (
        occupation_type_id SMALLINT PRIMARY KEY,
        occupation_code VARCHAR(10) NOT NULL UNIQUE,
        occupation_name VARCHAR(100) NOT NULL,
        category VARCHAR(50), -- Nhóm nghề nghiệp
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại giấy tờ (DocumentType)
    CREATE TABLE IF NOT EXISTS reference.document_type (
        document_type_id SMALLINT PRIMARY KEY,
        document_code VARCHAR(10) NOT NULL UNIQUE,
        document_name VARCHAR(100) NOT NULL,
        issuing_agency VARCHAR(200), -- Cơ quan cấp
        validity_period INT, -- Thời hạn hiệu lực (tháng)
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trạng thái hồ sơ (RecordStatus)
    CREATE TABLE IF NOT EXISTS reference.record_status (
        status_id SMALLINT PRIMARY KEY,
        status_code VARCHAR(10) NOT NULL UNIQUE,
        status_name VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng cơ quan cấp (IssuingAuthority)
    CREATE TABLE IF NOT EXISTS reference.issuing_authority (
        authority_id SMALLINT PRIMARY KEY,
        authority_code VARCHAR(10) NOT NULL UNIQUE,
        authority_name VARCHAR(200) NOT NULL,
        authority_type VARCHAR(50), -- Loại cơ quan: Công an/Tư pháp/Hành chính
        parent_authority_id SMALLINT,
        province_id INT,
        district_id INT,
        address TEXT,
        phone VARCHAR(20),
        email VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng vai trò người dùng (UserRole)
    CREATE TABLE IF NOT EXISTS reference.user_role (
        role_id SMALLINT PRIMARY KEY,
        role_code VARCHAR(20) NOT NULL UNIQUE,
        role_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng các yếu tố mã hóa (EncryptionType)
    CREATE TABLE IF NOT EXISTS reference.encryption_type (
        encryption_id SMALLINT PRIMARY KEY,
        encryption_name VARCHAR(50) NOT NULL UNIQUE,
        algorithm VARCHAR(50) NOT NULL,
        key_length INT,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng lý do truy cập dữ liệu (AccessReason)
    CREATE TABLE IF NOT EXISTS reference.access_reason (
        reason_id SMALLINT PRIMARY KEY,
        reason_code VARCHAR(20) NOT NULL UNIQUE,
        reason_name VARCHAR(200) NOT NULL,
        description TEXT,
        requires_approval BOOLEAN DEFAULT FALSE,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng đặc biệt chỉ có ở máy chủ trung tâm
    CREATE TABLE IF NOT EXISTS reference.sync_config (
        config_id SERIAL PRIMARY KEY,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        sync_table_name VARCHAR(100) NOT NULL,
        sync_frequency VARCHAR(50), -- Tần suất đồng bộ: realtime, hourly, daily
        last_sync_time TIMESTAMP WITH TIME ZONE,
        priority SMALLINT DEFAULT 5, -- Độ ưu tiên (1-10)
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_tables();
\echo 'Đã tạo các bảng tham chiếu cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
CREATE SCHEMA IF NOT EXISTS reference;
-- Hàm tạo các bảng tham chiếu tiêu chuẩn
CREATE OR REPLACE FUNCTION create_reference_tables() RETURNS void AS $$
BEGIN
    -- Bảng vùng miền (Region)
    CREATE TABLE IF NOT EXISTS reference.region (
        region_id SMALLINT PRIMARY KEY,
        region_code VARCHAR(10) NOT NULL UNIQUE,
        region_name VARCHAR(50) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tỉnh/thành phố (Province)
    CREATE TABLE IF NOT EXISTS reference.province (
        province_id INT PRIMARY KEY,
        province_code VARCHAR(10) NOT NULL UNIQUE,
        province_name VARCHAR(100) NOT NULL,
        province_type division_type, -- Tỉnh/Thành phố trực thuộc TW
        region_id SMALLINT,
        area_code VARCHAR(10), -- Mã vùng điện thoại
        postal_code VARCHAR(10), -- Mã bưu chính
        phone_code VARCHAR(10), -- Mã điện thoại
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quận/huyện (District)
    CREATE TABLE IF NOT EXISTS reference.district (
        district_id INT PRIMARY KEY,
        district_code VARCHAR(10) NOT NULL UNIQUE,
        district_name VARCHAR(100) NOT NULL,
        province_id INT,
        district_type division_type, -- Quận/Huyện/Thị xã/Thành phố thuộc tỉnh
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng phường/xã (Ward)
    CREATE TABLE IF NOT EXISTS reference.ward (
        ward_id INT PRIMARY KEY,
        ward_code VARCHAR(10) NOT NULL UNIQUE,
        ward_name VARCHAR(100) NOT NULL,
        district_id INT,
        ward_type division_type, -- Phường/Xã/Thị trấn
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng dân tộc (Ethnicity)
    CREATE TABLE IF NOT EXISTS reference.ethnicity (
        ethnicity_id SMALLINT PRIMARY KEY,
        ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
        ethnicity_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tôn giáo (Religion)
    CREATE TABLE IF NOT EXISTS reference.religion (
        religion_id SMALLINT PRIMARY KEY,
        religion_code VARCHAR(10) NOT NULL UNIQUE,
        religion_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quốc tịch (Nationality)
    CREATE TABLE IF NOT EXISTS reference.nationality (
        nationality_id SMALLINT PRIMARY KEY,
        nationality_code VARCHAR(10) NOT NULL UNIQUE,
        nationality_name VARCHAR(100) NOT NULL,
        country_code VARCHAR(10) NOT NULL,
        country_name VARCHAR(100) NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại quan hệ gia đình (RelationshipType)
    CREATE TABLE IF NOT EXISTS reference.relationship_type (
        relationship_type_id SMALLINT PRIMARY KEY,
        relationship_code VARCHAR(10) NOT NULL UNIQUE,
        relationship_name VARCHAR(100) NOT NULL,
        description TEXT,
        category VARCHAR(50), -- Nhóm quan hệ: Gia đình/Họ hàng/Giám hộ
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trình độ học vấn (EducationLevel)
    CREATE TABLE IF NOT EXISTS reference.education_level (
        education_level_id SMALLINT PRIMARY KEY,
        education_code VARCHAR(10) NOT NULL UNIQUE,
        education_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại nghề nghiệp (OccupationType)
    CREATE TABLE IF NOT EXISTS reference.occupation_type (
        occupation_type_id SMALLINT PRIMARY KEY,
        occupation_code VARCHAR(10) NOT NULL UNIQUE,
        occupation_name VARCHAR(100) NOT NULL,
        category VARCHAR(50), -- Nhóm nghề nghiệp
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại giấy tờ (DocumentType)
    CREATE TABLE IF NOT EXISTS reference.document_type (
        document_type_id SMALLINT PRIMARY KEY,
        document_code VARCHAR(10) NOT NULL UNIQUE,
        document_name VARCHAR(100) NOT NULL,
        issuing_agency VARCHAR(200), -- Cơ quan cấp
        validity_period INT, -- Thời hạn hiệu lực (tháng)
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trạng thái hồ sơ (RecordStatus)
    CREATE TABLE IF NOT EXISTS reference.record_status (
        status_id SMALLINT PRIMARY KEY,
        status_code VARCHAR(10) NOT NULL UNIQUE,
        status_name VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng cơ quan cấp (IssuingAuthority)
    CREATE TABLE IF NOT EXISTS reference.issuing_authority (
        authority_id SMALLINT PRIMARY KEY,
        authority_code VARCHAR(10) NOT NULL UNIQUE,
        authority_name VARCHAR(200) NOT NULL,
        authority_type VARCHAR(50), -- Loại cơ quan: Công an/Tư pháp/Hành chính
        parent_authority_id SMALLINT,
        province_id INT,
        district_id INT,
        address TEXT,
        phone VARCHAR(20),
        email VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng vai trò người dùng (UserRole)
    CREATE TABLE IF NOT EXISTS reference.user_role (
        role_id SMALLINT PRIMARY KEY,
        role_code VARCHAR(20) NOT NULL UNIQUE,
        role_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng các yếu tố mã hóa (EncryptionType)
    CREATE TABLE IF NOT EXISTS reference.encryption_type (
        encryption_id SMALLINT PRIMARY KEY,
        encryption_name VARCHAR(50) NOT NULL UNIQUE,
        algorithm VARCHAR(50) NOT NULL,
        key_length INT,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng lý do truy cập dữ liệu (AccessReason)
    CREATE TABLE IF NOT EXISTS reference.access_reason (
        reason_id SMALLINT PRIMARY KEY,
        reason_code VARCHAR(20) NOT NULL UNIQUE,
        reason_name VARCHAR(200) NOT NULL,
        description TEXT,
        requires_approval BOOLEAN DEFAULT FALSE,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng đặc biệt chỉ có ở máy chủ trung tâm
    CREATE TABLE IF NOT EXISTS reference.sync_config (
        config_id SERIAL PRIMARY KEY,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        sync_table_name VARCHAR(100) NOT NULL,
        sync_frequency VARCHAR(50), -- Tần suất đồng bộ: realtime, hourly, daily
        last_sync_time TIMESTAMP WITH TIME ZONE,
        priority SMALLINT DEFAULT 5, -- Độ ưu tiên (1-10)
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_tables();
\echo 'Đã tạo các bảng tham chiếu cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
CREATE SCHEMA IF NOT EXISTS reference;
-- Hàm tạo các bảng tham chiếu tiêu chuẩn
CREATE OR REPLACE FUNCTION create_reference_tables() RETURNS void AS $$
BEGIN
    -- Bảng vùng miền (Region)
    CREATE TABLE IF NOT EXISTS reference.region (
        region_id SMALLINT PRIMARY KEY,
        region_code VARCHAR(10) NOT NULL UNIQUE,
        region_name VARCHAR(50) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tỉnh/thành phố (Province)
    CREATE TABLE IF NOT EXISTS reference.province (
        province_id INT PRIMARY KEY,
        province_code VARCHAR(10) NOT NULL UNIQUE,
        province_name VARCHAR(100) NOT NULL,
        province_type division_type, -- Tỉnh/Thành phố trực thuộc TW
        region_id SMALLINT,
        area_code VARCHAR(10), -- Mã vùng điện thoại
        postal_code VARCHAR(10), -- Mã bưu chính
        phone_code VARCHAR(10), -- Mã điện thoại
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quận/huyện (District)
    CREATE TABLE IF NOT EXISTS reference.district (
        district_id INT PRIMARY KEY,
        district_code VARCHAR(10) NOT NULL UNIQUE,
        district_name VARCHAR(100) NOT NULL,
        province_id INT,
        district_type division_type, -- Quận/Huyện/Thị xã/Thành phố thuộc tỉnh
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng phường/xã (Ward)
    CREATE TABLE IF NOT EXISTS reference.ward (
        ward_id INT PRIMARY KEY,
        ward_code VARCHAR(10) NOT NULL UNIQUE,
        ward_name VARCHAR(100) NOT NULL,
        district_id INT,
        ward_type division_type, -- Phường/Xã/Thị trấn
        area_code VARCHAR(10),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng dân tộc (Ethnicity)
    CREATE TABLE IF NOT EXISTS reference.ethnicity (
        ethnicity_id SMALLINT PRIMARY KEY,
        ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
        ethnicity_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng tôn giáo (Religion)
    CREATE TABLE IF NOT EXISTS reference.religion (
        religion_id SMALLINT PRIMARY KEY,
        religion_code VARCHAR(10) NOT NULL UNIQUE,
        religion_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng quốc tịch (Nationality)
    CREATE TABLE IF NOT EXISTS reference.nationality (
        nationality_id SMALLINT PRIMARY KEY,
        nationality_code VARCHAR(10) NOT NULL UNIQUE,
        nationality_name VARCHAR(100) NOT NULL,
        country_code VARCHAR(10) NOT NULL,
        country_name VARCHAR(100) NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại quan hệ gia đình (RelationshipType)
    CREATE TABLE IF NOT EXISTS reference.relationship_type (
        relationship_type_id SMALLINT PRIMARY KEY,
        relationship_code VARCHAR(10) NOT NULL UNIQUE,
        relationship_name VARCHAR(100) NOT NULL,
        description TEXT,
        category VARCHAR(50), -- Nhóm quan hệ: Gia đình/Họ hàng/Giám hộ
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trình độ học vấn (EducationLevel)
    CREATE TABLE IF NOT EXISTS reference.education_level (
        education_level_id SMALLINT PRIMARY KEY,
        education_code VARCHAR(10) NOT NULL UNIQUE,
        education_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại nghề nghiệp (OccupationType)
    CREATE TABLE IF NOT EXISTS reference.occupation_type (
        occupation_type_id SMALLINT PRIMARY KEY,
        occupation_code VARCHAR(10) NOT NULL UNIQUE,
        occupation_name VARCHAR(100) NOT NULL,
        category VARCHAR(50), -- Nhóm nghề nghiệp
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng loại giấy tờ (DocumentType)
    CREATE TABLE IF NOT EXISTS reference.document_type (
        document_type_id SMALLINT PRIMARY KEY,
        document_code VARCHAR(10) NOT NULL UNIQUE,
        document_name VARCHAR(100) NOT NULL,
        issuing_agency VARCHAR(200), -- Cơ quan cấp
        validity_period INT, -- Thời hạn hiệu lực (tháng)
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng trạng thái hồ sơ (RecordStatus)
    CREATE TABLE IF NOT EXISTS reference.record_status (
        status_id SMALLINT PRIMARY KEY,
        status_code VARCHAR(10) NOT NULL UNIQUE,
        status_name VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng cơ quan cấp (IssuingAuthority)
    CREATE TABLE IF NOT EXISTS reference.issuing_authority (
        authority_id SMALLINT PRIMARY KEY,
        authority_code VARCHAR(10) NOT NULL UNIQUE,
        authority_name VARCHAR(200) NOT NULL,
        authority_type VARCHAR(50), -- Loại cơ quan: Công an/Tư pháp/Hành chính
        parent_authority_id SMALLINT,
        province_id INT,
        district_id INT,
        address TEXT,
        phone VARCHAR(20),
        email VARCHAR(100),
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng vai trò người dùng (UserRole)
    CREATE TABLE IF NOT EXISTS reference.user_role (
        role_id SMALLINT PRIMARY KEY,
        role_code VARCHAR(20) NOT NULL UNIQUE,
        role_name VARCHAR(100) NOT NULL,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng các yếu tố mã hóa (EncryptionType)
    CREATE TABLE IF NOT EXISTS reference.encryption_type (
        encryption_id SMALLINT PRIMARY KEY,
        encryption_name VARCHAR(50) NOT NULL UNIQUE,
        algorithm VARCHAR(50) NOT NULL,
        key_length INT,
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng lý do truy cập dữ liệu (AccessReason)
    CREATE TABLE IF NOT EXISTS reference.access_reason (
        reason_id SMALLINT PRIMARY KEY,
        reason_code VARCHAR(20) NOT NULL UNIQUE,
        reason_name VARCHAR(200) NOT NULL,
        description TEXT,
        requires_approval BOOLEAN DEFAULT FALSE,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Bảng đặc biệt chỉ có ở máy chủ trung tâm
    CREATE TABLE IF NOT EXISTS reference.sync_config (
        config_id SERIAL PRIMARY KEY,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        sync_table_name VARCHAR(100) NOT NULL,
        sync_frequency VARCHAR(50), -- Tần suất đồng bộ: realtime, hourly, daily
        last_sync_time TIMESTAMP WITH TIME ZONE,
        priority SMALLINT DEFAULT 5, -- Độ ưu tiên (1-10)
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_tables();

-- Thêm bảng đặc biệt chỉ có ở máy chủ trung tâm
CREATE TABLE IF NOT EXISTS reference.sync_config (
    config_id SERIAL PRIMARY KEY,
    source_region_id SMALLINT REFERENCES reference.region(region_id),
    target_region_id SMALLINT REFERENCES reference.region(region_id),
    sync_table_name VARCHAR(100) NOT NULL,
    sync_frequency VARCHAR(50), -- Tần suất đồng bộ: realtime, hourly, daily
    last_sync_time TIMESTAMP WITH TIME ZONE,
    priority SMALLINT DEFAULT 5, -- Độ ưu tiên (1-10)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.sync_config IS 'Bảng cấu hình đồng bộ dữ liệu giữa các vùng miền';

\echo 'Đã tạo các bảng tham chiếu cho database trung tâm'

-- Tạo các chỉ mục cho bảng tham chiếu



-- Kết nối đến database miền Bắc và tạo chỉ mục
\connect national_citizen_north
-- Hàm tạo các chỉ mục cho bảng tham chiếu
CREATE OR REPLACE FUNCTION create_reference_indexes() RETURNS void AS $$
BEGIN
    -- Chỉ mục cho bảng province
    CREATE INDEX IF NOT EXISTS idx_province_region_id ON reference.province(region_id);
    
    -- Chỉ mục cho bảng district
    CREATE INDEX IF NOT EXISTS idx_district_province_id ON reference.district(province_id);
    
    -- Chỉ mục cho bảng ward
    CREATE INDEX IF NOT EXISTS idx_ward_district_id ON reference.ward(district_id);
    
    -- Chỉ mục tìm kiếm văn bản cho các trường tên
    CREATE INDEX IF NOT EXISTS idx_province_name_trgm ON reference.province USING gin (province_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_district_name_trgm ON reference.district USING gin (district_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ward_name_trgm ON reference.ward USING gin (ward_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_name_trgm ON reference.ethnicity USING gin (ethnicity_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_religion_name_trgm ON reference.religion USING gin (religion_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_nationality_name_trgm ON reference.nationality USING gin (nationality_name gin_trgm_ops);
    
    -- Chỉ mục cho các trường code
    CREATE INDEX IF NOT EXISTS idx_province_code ON reference.province(province_code);
    CREATE INDEX IF NOT EXISTS idx_district_code ON reference.district(district_code);
    CREATE INDEX IF NOT EXISTS idx_ward_code ON reference.ward(ward_code);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_code ON reference.ethnicity(ethnicity_code);
    CREATE INDEX IF NOT EXISTS idx_religion_code ON reference.religion(religion_code);
    CREATE INDEX IF NOT EXISTS idx_nationality_code ON reference.nationality(nationality_code);
    CREATE INDEX IF NOT EXISTS idx_relationship_code ON reference.relationship_type(relationship_code);
    CREATE INDEX IF NOT EXISTS idx_education_code ON reference.education_level(education_code);
    CREATE INDEX IF NOT EXISTS idx_occupation_code ON reference.occupation_type(occupation_code);
    CREATE INDEX IF NOT EXISTS idx_document_code ON reference.document_type(document_code);
    
    -- Chỉ mục cho bảng issuing_authority
    CREATE INDEX IF NOT EXISTS idx_authority_province_id ON reference.issuing_authority(province_id);
    CREATE INDEX IF NOT EXISTS idx_authority_district_id ON reference.issuing_authority(district_id);
    CREATE INDEX IF NOT EXISTS idx_authority_parent_id ON reference.issuing_authority(parent_authority_id);
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_indexes();

-- Kết nối đến database miền Trung và tạo chỉ mục
\connect national_citizen_central
-- Hàm tạo các chỉ mục cho bảng tham chiếu
CREATE OR REPLACE FUNCTION create_reference_indexes() RETURNS void AS $$
BEGIN
    -- Chỉ mục cho bảng province
    CREATE INDEX IF NOT EXISTS idx_province_region_id ON reference.province(region_id);
    
    -- Chỉ mục cho bảng district
    CREATE INDEX IF NOT EXISTS idx_district_province_id ON reference.district(province_id);
    
    -- Chỉ mục cho bảng ward
    CREATE INDEX IF NOT EXISTS idx_ward_district_id ON reference.ward(district_id);
    
    -- Chỉ mục tìm kiếm văn bản cho các trường tên
    CREATE INDEX IF NOT EXISTS idx_province_name_trgm ON reference.province USING gin (province_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_district_name_trgm ON reference.district USING gin (district_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ward_name_trgm ON reference.ward USING gin (ward_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_name_trgm ON reference.ethnicity USING gin (ethnicity_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_religion_name_trgm ON reference.religion USING gin (religion_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_nationality_name_trgm ON reference.nationality USING gin (nationality_name gin_trgm_ops);
    
    -- Chỉ mục cho các trường code
    CREATE INDEX IF NOT EXISTS idx_province_code ON reference.province(province_code);
    CREATE INDEX IF NOT EXISTS idx_district_code ON reference.district(district_code);
    CREATE INDEX IF NOT EXISTS idx_ward_code ON reference.ward(ward_code);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_code ON reference.ethnicity(ethnicity_code);
    CREATE INDEX IF NOT EXISTS idx_religion_code ON reference.religion(religion_code);
    CREATE INDEX IF NOT EXISTS idx_nationality_code ON reference.nationality(nationality_code);
    CREATE INDEX IF NOT EXISTS idx_relationship_code ON reference.relationship_type(relationship_code);
    CREATE INDEX IF NOT EXISTS idx_education_code ON reference.education_level(education_code);
    CREATE INDEX IF NOT EXISTS idx_occupation_code ON reference.occupation_type(occupation_code);
    CREATE INDEX IF NOT EXISTS idx_document_code ON reference.document_type(document_code);
    
    -- Chỉ mục cho bảng issuing_authority
    CREATE INDEX IF NOT EXISTS idx_authority_province_id ON reference.issuing_authority(province_id);
    CREATE INDEX IF NOT EXISTS idx_authority_district_id ON reference.issuing_authority(district_id);
    CREATE INDEX IF NOT EXISTS idx_authority_parent_id ON reference.issuing_authority(parent_authority_id);
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_indexes();

-- Kết nối đến database miền Nam và tạo chỉ mục
\connect national_citizen_south
-- Hàm tạo các chỉ mục cho bảng tham chiếu
CREATE OR REPLACE FUNCTION create_reference_indexes() RETURNS void AS $$
BEGIN
    -- Chỉ mục cho bảng province
    CREATE INDEX IF NOT EXISTS idx_province_region_id ON reference.province(region_id);
    
    -- Chỉ mục cho bảng district
    CREATE INDEX IF NOT EXISTS idx_district_province_id ON reference.district(province_id);
    
    -- Chỉ mục cho bảng ward
    CREATE INDEX IF NOT EXISTS idx_ward_district_id ON reference.ward(district_id);
    
    -- Chỉ mục tìm kiếm văn bản cho các trường tên
    CREATE INDEX IF NOT EXISTS idx_province_name_trgm ON reference.province USING gin (province_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_district_name_trgm ON reference.district USING gin (district_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ward_name_trgm ON reference.ward USING gin (ward_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_name_trgm ON reference.ethnicity USING gin (ethnicity_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_religion_name_trgm ON reference.religion USING gin (religion_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_nationality_name_trgm ON reference.nationality USING gin (nationality_name gin_trgm_ops);
    
    -- Chỉ mục cho các trường code
    CREATE INDEX IF NOT EXISTS idx_province_code ON reference.province(province_code);
    CREATE INDEX IF NOT EXISTS idx_district_code ON reference.district(district_code);
    CREATE INDEX IF NOT EXISTS idx_ward_code ON reference.ward(ward_code);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_code ON reference.ethnicity(ethnicity_code);
    CREATE INDEX IF NOT EXISTS idx_religion_code ON reference.religion(religion_code);
    CREATE INDEX IF NOT EXISTS idx_nationality_code ON reference.nationality(nationality_code);
    CREATE INDEX IF NOT EXISTS idx_relationship_code ON reference.relationship_type(relationship_code);
    CREATE INDEX IF NOT EXISTS idx_education_code ON reference.education_level(education_code);
    CREATE INDEX IF NOT EXISTS idx_occupation_code ON reference.occupation_type(occupation_code);
    CREATE INDEX IF NOT EXISTS idx_document_code ON reference.document_type(document_code);
    
    -- Chỉ mục cho bảng issuing_authority
    CREATE INDEX IF NOT EXISTS idx_authority_province_id ON reference.issuing_authority(province_id);
    CREATE INDEX IF NOT EXISTS idx_authority_district_id ON reference.issuing_authority(district_id);
    CREATE INDEX IF NOT EXISTS idx_authority_parent_id ON reference.issuing_authority(parent_authority_id);
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_indexes();

-- Kết nối đến database trung tâm và tạo chỉ mục
\connect national_citizen_central_server
-- Hàm tạo các chỉ mục cho bảng tham chiếu
CREATE OR REPLACE FUNCTION create_reference_indexes() RETURNS void AS $$
BEGIN
    -- Chỉ mục cho bảng province
    CREATE INDEX IF NOT EXISTS idx_province_region_id ON reference.province(region_id);
    
    -- Chỉ mục cho bảng district
    CREATE INDEX IF NOT EXISTS idx_district_province_id ON reference.district(province_id);
    
    -- Chỉ mục cho bảng ward
    CREATE INDEX IF NOT EXISTS idx_ward_district_id ON reference.ward(district_id);
    
    -- Chỉ mục tìm kiếm văn bản cho các trường tên
    CREATE INDEX IF NOT EXISTS idx_province_name_trgm ON reference.province USING gin (province_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_district_name_trgm ON reference.district USING gin (district_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ward_name_trgm ON reference.ward USING gin (ward_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_name_trgm ON reference.ethnicity USING gin (ethnicity_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_religion_name_trgm ON reference.religion USING gin (religion_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_nationality_name_trgm ON reference.nationality USING gin (nationality_name gin_trgm_ops);
    
    -- Chỉ mục cho các trường code
    CREATE INDEX IF NOT EXISTS idx_province_code ON reference.province(province_code);
    CREATE INDEX IF NOT EXISTS idx_district_code ON reference.district(district_code);
    CREATE INDEX IF NOT EXISTS idx_ward_code ON reference.ward(ward_code);
    CREATE INDEX IF NOT EXISTS idx_ethnicity_code ON reference.ethnicity(ethnicity_code);
    CREATE INDEX IF NOT EXISTS idx_religion_code ON reference.religion(religion_code);
    CREATE INDEX IF NOT EXISTS idx_nationality_code ON reference.nationality(nationality_code);
    CREATE INDEX IF NOT EXISTS idx_relationship_code ON reference.relationship_type(relationship_code);
    CREATE INDEX IF NOT EXISTS idx_education_code ON reference.education_level(education_code);
    CREATE INDEX IF NOT EXISTS idx_occupation_code ON reference.occupation_type(occupation_code);
    CREATE INDEX IF NOT EXISTS idx_document_code ON reference.document_type(document_code);
    
    -- Chỉ mục cho bảng issuing_authority
    CREATE INDEX IF NOT EXISTS idx_authority_province_id ON reference.issuing_authority(province_id);
    CREATE INDEX IF NOT EXISTS idx_authority_district_id ON reference.issuing_authority(district_id);
    CREATE INDEX IF NOT EXISTS idx_authority_parent_id ON reference.issuing_authority(parent_authority_id);
END;
$$ LANGUAGE plpgsql;
SELECT create_reference_indexes();

-- Tạo chỉ mục cho bảng đặc biệt của máy chủ trung tâm
CREATE INDEX IF NOT EXISTS idx_sync_config_source ON reference.sync_config(source_region_id);
CREATE INDEX IF NOT EXISTS idx_sync_config_target ON reference.sync_config(target_region_id);
CREATE INDEX IF NOT EXISTS idx_sync_config_table ON reference.sync_config(sync_table_name);

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong tất cả các bảng tham chiếu cho hệ thống quản lý dân cư quốc gia.'
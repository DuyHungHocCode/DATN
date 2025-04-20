-- Script tạo các bảng tham chiếu dùng chung cho hệ thống quản lý dân cư quốc gia
-- File: database/common/reference_tables.sql

-- ============================================================================
-- CÁC BẢNG THAM CHIẾU ĐỊA GIỚI HÀNH CHÍNH
-- ============================================================================

-- ---------------------------------
-- 1. Bảng tham chiếu vùng/miền
-- ---------------------------------
-- Tạo bảng ở cả 3 database để đảm bảo tính nhất quán
\echo 'Tạo bảng tham chiếu vùng/miền (regions)...'

-- Bảng vùng/miền cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions (
    region_id SMALLINT PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.regions IS 'Bảng tham chiếu vùng/miền (Bắc, Trung, Nam)';
COMMENT ON COLUMN reference.regions.region_id IS 'ID vùng/miền';
COMMENT ON COLUMN reference.regions.region_code IS 'Mã vùng/miền';
COMMENT ON COLUMN reference.regions.region_name IS 'Tên vùng/miền';
COMMENT ON COLUMN reference.regions.description IS 'Mô tả chi tiết';

CREATE INDEX idx_regions_region_code ON reference.regions(region_code);

-- Bảng vùng/miền cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions (
    region_id SMALLINT PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.regions IS 'Bảng tham chiếu vùng/miền (Bắc, Trung, Nam)';
CREATE INDEX idx_regions_region_code ON reference.regions(region_code);

-- Bảng vùng/miền cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions (
    region_id SMALLINT PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.regions IS 'Bảng tham chiếu vùng/miền (Bắc, Trung, Nam)';
CREATE INDEX idx_regions_region_code ON reference.regions(region_code);

-- ---------------------------------
-- 2. Bảng tham chiếu tỉnh/thành phố
-- ---------------------------------
\echo 'Tạo bảng tham chiếu tỉnh/thành phố (provinces)...'

-- Bảng tỉnh/thành phố cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces (
    province_id INTEGER PRIMARY KEY,
    province_code VARCHAR(10) NOT NULL UNIQUE,
    province_name VARCHAR(100) NOT NULL,
    region_id SMALLINT NOT NULL REFERENCES reference.regions(region_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_city BOOLEAN DEFAULT FALSE, -- Có phải thành phố trực thuộc TW không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    administrative_region_id SMALLINT, -- Vùng kinh tế-xã hội
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.provinces IS 'Bảng tham chiếu tỉnh/thành phố';
COMMENT ON COLUMN reference.provinces.province_id IS 'ID tỉnh/thành phố';
COMMENT ON COLUMN reference.provinces.province_code IS 'Mã tỉnh/thành phố';
COMMENT ON COLUMN reference.provinces.province_name IS 'Tên tỉnh/thành phố';
COMMENT ON COLUMN reference.provinces.region_id IS 'ID vùng/miền';
COMMENT ON COLUMN reference.provinces.is_city IS 'Là thành phố trực thuộc trung ương';

CREATE INDEX idx_provinces_region_id ON reference.provinces(region_id);
CREATE INDEX idx_provinces_province_code ON reference.provinces(province_code);

-- Bảng tỉnh/thành phố cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces (
    province_id INTEGER PRIMARY KEY,
    province_code VARCHAR(10) NOT NULL UNIQUE,
    province_name VARCHAR(100) NOT NULL,
    region_id SMALLINT NOT NULL REFERENCES reference.regions(region_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_city BOOLEAN DEFAULT FALSE, -- Có phải thành phố trực thuộc TW không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    administrative_region_id SMALLINT, -- Vùng kinh tế-xã hội
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.provinces IS 'Bảng tham chiếu tỉnh/thành phố';
CREATE INDEX idx_provinces_region_id ON reference.provinces(region_id);
CREATE INDEX idx_provinces_province_code ON reference.provinces(province_code);

-- Bảng tỉnh/thành phố cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces (
    province_id INTEGER PRIMARY KEY,
    province_code VARCHAR(10) NOT NULL UNIQUE,
    province_name VARCHAR(100) NOT NULL,
    region_id SMALLINT NOT NULL REFERENCES reference.regions(region_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_city BOOLEAN DEFAULT FALSE, -- Có phải thành phố trực thuộc TW không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    administrative_region_id SMALLINT, -- Vùng kinh tế-xã hội
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.provinces IS 'Bảng tham chiếu tỉnh/thành phố';
CREATE INDEX idx_provinces_region_id ON reference.provinces(region_id);
CREATE INDEX idx_provinces_province_code ON reference.provinces(province_code);

-- ---------------------------------
-- 3. Bảng tham chiếu quận/huyện
-- ---------------------------------
\echo 'Tạo bảng tham chiếu quận/huyện (districts)...'

-- Bảng quận/huyện cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts (
    district_id INTEGER PRIMARY KEY,
    district_code VARCHAR(10) NOT NULL UNIQUE,
    district_name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_urban BOOLEAN DEFAULT FALSE, -- Có phải quận/thành phố không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.districts IS 'Bảng tham chiếu quận/huyện';
COMMENT ON COLUMN reference.districts.district_id IS 'ID quận/huyện';
COMMENT ON COLUMN reference.districts.district_code IS 'Mã quận/huyện';
COMMENT ON COLUMN reference.districts.district_name IS 'Tên quận/huyện';
COMMENT ON COLUMN reference.districts.province_id IS 'ID tỉnh/thành phố';
COMMENT ON COLUMN reference.districts.is_urban IS 'Là quận/thành phố thuộc tỉnh';

CREATE INDEX idx_districts_province_id ON reference.districts(province_id);
CREATE INDEX idx_districts_district_code ON reference.districts(district_code);

-- Bảng quận/huyện cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts (
    district_id INTEGER PRIMARY KEY,
    district_code VARCHAR(10) NOT NULL UNIQUE,
    district_name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_urban BOOLEAN DEFAULT FALSE, -- Có phải quận/thành phố không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.districts IS 'Bảng tham chiếu quận/huyện';
CREATE INDEX idx_districts_province_id ON reference.districts(province_id);
CREATE INDEX idx_districts_district_code ON reference.districts(district_code);

-- Bảng quận/huyện cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts (
    district_id INTEGER PRIMARY KEY,
    district_code VARCHAR(10) NOT NULL UNIQUE,
    district_name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_urban BOOLEAN DEFAULT FALSE, -- Có phải quận/thành phố không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.districts IS 'Bảng tham chiếu quận/huyện';
CREATE INDEX idx_districts_province_id ON reference.districts(province_id);
CREATE INDEX idx_districts_district_code ON reference.districts(district_code);

-- ---------------------------------
-- 4. Bảng tham chiếu phường/xã
-- ---------------------------------
\echo 'Tạo bảng tham chiếu phường/xã (wards)...'

-- Bảng phường/xã cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards (
    ward_id INTEGER PRIMARY KEY,
    ward_code VARCHAR(10) NOT NULL UNIQUE,
    ward_name VARCHAR(100) NOT NULL,
    district_id INTEGER NOT NULL REFERENCES reference.districts(district_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_urban BOOLEAN DEFAULT FALSE, -- Có phải phường/thị trấn không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.wards IS 'Bảng tham chiếu phường/xã';
COMMENT ON COLUMN reference.wards.ward_id IS 'ID phường/xã';
COMMENT ON COLUMN reference.wards.ward_code IS 'Mã phường/xã';
COMMENT ON COLUMN reference.wards.ward_name IS 'Tên phường/xã';
COMMENT ON COLUMN reference.wards.district_id IS 'ID quận/huyện';
COMMENT ON COLUMN reference.wards.is_urban IS 'Là phường/thị trấn';

CREATE INDEX idx_wards_district_id ON reference.wards(district_id);
CREATE INDEX idx_wards_ward_code ON reference.wards(ward_code);

-- Bảng phường/xã cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards (
    ward_id INTEGER PRIMARY KEY,
    ward_code VARCHAR(10) NOT NULL UNIQUE,
    ward_name VARCHAR(100) NOT NULL,
    district_id INTEGER NOT NULL REFERENCES reference.districts(district_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_urban BOOLEAN DEFAULT FALSE, -- Có phải phường/thị trấn không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.wards IS 'Bảng tham chiếu phường/xã';
CREATE INDEX idx_wards_district_id ON reference.wards(district_id);
CREATE INDEX idx_wards_ward_code ON reference.wards(ward_code);

-- Bảng phường/xã cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards (
    ward_id INTEGER PRIMARY KEY,
    ward_code VARCHAR(10) NOT NULL UNIQUE,
    ward_name VARCHAR(100) NOT NULL,
    district_id INTEGER NOT NULL REFERENCES reference.districts(district_id),
    area DECIMAL(10,2), -- Diện tích (km2)
    population INTEGER, -- Dân số
    gso_code VARCHAR(10), -- Mã theo tổng cục thống kê
    is_urban BOOLEAN DEFAULT FALSE, -- Có phải phường/thị trấn không
    administrative_unit_id SMALLINT, -- Loại đơn vị hành chính
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.wards IS 'Bảng tham chiếu phường/xã';
CREATE INDEX idx_wards_district_id ON reference.wards(district_id);
CREATE INDEX idx_wards_ward_code ON reference.wards(ward_code);

-- ============================================================================
-- CÁC BẢNG THAM CHIẾU THÔNG TIN CƠ BẢN
-- ============================================================================

-- ---------------------------------
-- 5. Bảng tham chiếu dân tộc
-- ---------------------------------
\echo 'Tạo bảng tham chiếu dân tộc (ethnicities)...'

-- Bảng dân tộc cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities (
    ethnicity_id SMALLINT PRIMARY KEY,
    ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
    ethnicity_name VARCHAR(100) NOT NULL,
    description TEXT,
    population INTEGER, -- Dân số dân tộc
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.ethnicities IS 'Bảng tham chiếu dân tộc';
COMMENT ON COLUMN reference.ethnicities.ethnicity_id IS 'ID dân tộc';
COMMENT ON COLUMN reference.ethnicities.ethnicity_code IS 'Mã dân tộc';
COMMENT ON COLUMN reference.ethnicities.ethnicity_name IS 'Tên dân tộc';

CREATE INDEX idx_ethnicities_ethnicity_code ON reference.ethnicities(ethnicity_code);

-- Bảng dân tộc cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities (
    ethnicity_id SMALLINT PRIMARY KEY,
    ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
    ethnicity_name VARCHAR(100) NOT NULL,
    description TEXT,
    population INTEGER, -- Dân số dân tộc
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.ethnicities IS 'Bảng tham chiếu dân tộc';
CREATE INDEX idx_ethnicities_ethnicity_code ON reference.ethnicities(ethnicity_code);

-- Bảng dân tộc cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities (
    ethnicity_id SMALLINT PRIMARY KEY,
    ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
    ethnicity_name VARCHAR(100) NOT NULL,
    description TEXT,
    population INTEGER, -- Dân số dân tộc
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.ethnicities IS 'Bảng tham chiếu dân tộc';
CREATE INDEX idx_ethnicities_ethnicity_code ON reference.ethnicities(ethnicity_code);

-- ---------------------------------
-- 6. Bảng tham chiếu tôn giáo
-- ---------------------------------
\echo 'Tạo bảng tham chiếu tôn giáo (religions)...'

-- Bảng tôn giáo cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions (
    religion_id SMALLINT PRIMARY KEY,
    religion_code VARCHAR(10) NOT NULL UNIQUE,
    religion_name VARCHAR(100) NOT NULL,
    description TEXT,
    followers INTEGER, -- Số tín đồ
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.religions IS 'Bảng tham chiếu tôn giáo';
COMMENT ON COLUMN reference.religions.religion_id IS 'ID tôn giáo';
COMMENT ON COLUMN reference.religions.religion_code IS 'Mã tôn giáo';
COMMENT ON COLUMN reference.religions.religion_name IS 'Tên tôn giáo';

CREATE INDEX idx_religions_religion_code ON reference.religions(religion_code);

-- Bảng tôn giáo cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions (
    religion_id SMALLINT PRIMARY KEY,
    religion_code VARCHAR(10) NOT NULL UNIQUE,
    religion_name VARCHAR(100) NOT NULL,
    description TEXT,
    followers INTEGER, -- Số tín đồ
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.religions IS 'Bảng tham chiếu tôn giáo';
CREATE INDEX idx_religions_religion_code ON reference.religions(religion_code);

-- Bảng tôn giáo cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions (
    religion_id SMALLINT PRIMARY KEY,
    religion_code VARCHAR(10) NOT NULL UNIQUE,
    religion_name VARCHAR(100) NOT NULL,
    description TEXT,
    followers INTEGER, -- Số tín đồ
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.religions IS 'Bảng tham chiếu tôn giáo';
CREATE INDEX idx_religions_religion_code ON reference.religions(religion_code);

-- ---------------------------------
-- 7. Bảng tham chiếu quốc tịch
-- ---------------------------------
\echo 'Tạo bảng tham chiếu quốc tịch (nationalities)...'

-- Bảng quốc tịch cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities (
    nationality_id SMALLINT PRIMARY KEY,
    nationality_code VARCHAR(10) NOT NULL UNIQUE, -- Mã quốc tịch theo tiêu chuẩn Việt Nam
    iso_code VARCHAR(3) NOT NULL, -- Mã ISO 3166-1 alpha-3
    nationality_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.nationalities IS 'Bảng tham chiếu quốc tịch';
COMMENT ON COLUMN reference.nationalities.nationality_id IS 'ID quốc tịch';
COMMENT ON COLUMN reference.nationalities.nationality_code IS 'Mã quốc tịch theo tiêu chuẩn Việt Nam';
COMMENT ON COLUMN reference.nationalities.iso_code IS 'Mã ISO 3166-1 alpha-3';
COMMENT ON COLUMN reference.nationalities.nationality_name IS 'Tên quốc tịch';
COMMENT ON COLUMN reference.nationalities.country_name IS 'Tên quốc gia';

CREATE INDEX idx_nationalities_nationality_code ON reference.nationalities(nationality_code);
CREATE INDEX idx_nationalities_iso_code ON reference.nationalities(iso_code);

-- Bảng quốc tịch cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities (
    nationality_id SMALLINT PRIMARY KEY,
    nationality_code VARCHAR(10) NOT NULL UNIQUE, -- Mã quốc tịch theo tiêu chuẩn Việt Nam
    iso_code VARCHAR(3) NOT NULL, -- Mã ISO 3166-1 alpha-3
    nationality_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.nationalities IS 'Bảng tham chiếu quốc tịch';
CREATE INDEX idx_nationalities_nationality_code ON reference.nationalities(nationality_code);
CREATE INDEX idx_nationalities_iso_code ON reference.nationalities(iso_code);

-- Bảng quốc tịch cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities (
    nationality_id SMALLINT PRIMARY KEY,
    nationality_code VARCHAR(10) NOT NULL UNIQUE, -- Mã quốc tịch theo tiêu chuẩn Việt Nam
    iso_code VARCHAR(3) NOT NULL, -- Mã ISO 3166-1 alpha-3
    nationality_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.nationalities IS 'Bảng tham chiếu quốc tịch';
CREATE INDEX idx_nationalities_nationality_code ON reference.nationalities(nationality_code);
CREATE INDEX idx_nationalities_iso_code ON reference.nationalities(iso_code);

-- ---------------------------------
-- 8. Bảng tham chiếu nghề nghiệp
-- ---------------------------------
\echo 'Tạo bảng tham chiếu nghề nghiệp (occupations)...'

-- Bảng nghề nghiệp cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations (
    occupation_id INTEGER PRIMARY KEY,
    occupation_code VARCHAR(10) NOT NULL UNIQUE,
    occupation_name VARCHAR(200) NOT NULL,
    occupation_group_id SMALLINT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.occupations IS 'Bảng tham chiếu nghề nghiệp';
COMMENT ON COLUMN reference.occupations.occupation_id IS 'ID nghề nghiệp';
COMMENT ON COLUMN reference.occupations.occupation_code IS 'Mã nghề nghiệp';
COMMENT ON COLUMN reference.occupations.occupation_name IS 'Tên nghề nghiệp';
COMMENT ON COLUMN reference.occupations.occupation_group_id IS 'ID nhóm nghề nghiệp';

CREATE INDEX idx_occupations_occupation_code ON reference.occupations(occupation_code);
CREATE INDEX idx_occupations_occupation_group_id ON reference.occupations(occupation_group_id);

-- Bảng nghề nghiệp cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations (
    occupation_id INTEGER PRIMARY KEY,
    occupation_code VARCHAR(10) NOT NULL UNIQUE,
    occupation_name VARCHAR(200) NOT NULL,
    occupation_group_id SMALLINT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.occupations IS 'Bảng tham chiếu nghề nghiệp';
CREATE INDEX idx_occupations_occupation_code ON reference.occupations(occupation_code);
CREATE INDEX idx_occupations_occupation_group_id ON reference.occupations(occupation_group_id);

-- Bảng nghề nghiệp cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations (
    occupation_id INTEGER PRIMARY KEY,
    occupation_code VARCHAR(10) NOT NULL UNIQUE,
    occupation_name VARCHAR(200) NOT NULL,
    occupation_group_id SMALLINT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.occupations IS 'Bảng tham chiếu nghề nghiệp';
CREATE INDEX idx_occupations_occupation_code ON reference.occupations(occupation_code);
CREATE INDEX idx_occupations_occupation_group_id ON reference.occupations(occupation_group_id);

-- ---------------------------------
-- 9. Bảng tham chiếu cơ quan có thẩm quyền
-- ---------------------------------
\echo 'Tạo bảng tham chiếu cơ quan có thẩm quyền (authorities)...'

-- Bảng cơ quan có thẩm quyền cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities (
    authority_id INTEGER PRIMARY KEY,
    authority_code VARCHAR(20) NOT NULL UNIQUE,
    authority_name VARCHAR(200) NOT NULL,
    authority_type VARCHAR(50) NOT NULL, -- Loại cơ quan: Công an, Tư pháp, UBND,...
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    province_id INTEGER REFERENCES reference.provinces(province_id),
    district_id INTEGER REFERENCES reference.districts(district_id),
    ward_id INTEGER REFERENCES reference.wards(ward_id),
    parent_authority_id INTEGER REFERENCES reference.authorities(authority_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.authorities IS 'Bảng tham chiếu cơ quan có thẩm quyền';
COMMENT ON COLUMN reference.authorities.authority_id IS 'ID cơ quan có thẩm quyền';
COMMENT ON COLUMN reference.authorities.authority_code IS 'Mã cơ quan';
COMMENT ON COLUMN reference.authorities.authority_name IS 'Tên cơ quan';
COMMENT ON COLUMN reference.authorities.authority_type IS 'Loại cơ quan';
COMMENT ON COLUMN reference.authorities.parent_authority_id IS 'ID cơ quan cấp trên';

CREATE INDEX idx_authorities_authority_code ON reference.authorities(authority_code);
CREATE INDEX idx_authorities_province_id ON reference.authorities(province_id);
CREATE INDEX idx_authorities_district_id ON reference.authorities(district_id);
CREATE INDEX idx_authorities_ward_id ON reference.authorities(ward_id);
CREATE INDEX idx_authorities_parent_authority_id ON reference.authorities(parent_authority_id);

-- Bảng cơ quan có thẩm quyền cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities (
    authority_id INTEGER PRIMARY KEY,
    authority_code VARCHAR(20) NOT NULL UNIQUE,
    authority_name VARCHAR(200) NOT NULL,
    authority_type VARCHAR(50) NOT NULL, -- Loại cơ quan: Công an, Tư pháp, UBND,...
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    province_id INTEGER REFERENCES reference.provinces(province_id),
    district_id INTEGER REFERENCES reference.districts(district_id),
    ward_id INTEGER REFERENCES reference.wards(ward_id),
    parent_authority_id INTEGER REFERENCES reference.authorities(authority_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.authorities IS 'Bảng tham chiếu cơ quan có thẩm quyền';
CREATE INDEX idx_authorities_authority_code ON reference.authorities(authority_code);
CREATE INDEX idx_authorities_province_id ON reference.authorities(province_id);
CREATE INDEX idx_authorities_district_id ON reference.authorities(district_id);
CREATE INDEX idx_authorities_ward_id ON reference.authorities(ward_id);
CREATE INDEX idx_authorities_parent_authority_id ON reference.authorities(parent_authority_id);

-- Bảng cơ quan có thẩm quyền cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities (
    authority_id INTEGER PRIMARY KEY,
    authority_code VARCHAR(20) NOT NULL UNIQUE,
    authority_name VARCHAR(200) NOT NULL,
    authority_type VARCHAR(50) NOT NULL, -- Loại cơ quan: Công an, Tư pháp, UBND,...
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    province_id INTEGER REFERENCES reference.provinces(province_id),
    district_id INTEGER REFERENCES reference.districts(district_id),
    ward_id INTEGER REFERENCES reference.wards(ward_id),
    parent_authority_id INTEGER REFERENCES reference.authorities(authority_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.authorities IS 'Bảng tham chiếu cơ quan có thẩm quyền';
CREATE INDEX idx_authorities_authority_code ON reference.authorities(authority_code);
CREATE INDEX idx_authorities_province_id ON reference.authorities(province_id);
CREATE INDEX idx_authorities_district_id ON reference.authorities(district_id);
CREATE INDEX idx_authorities_ward_id ON reference.authorities(ward_id);
CREATE INDEX idx_authorities_parent_authority_id ON reference.authorities(parent_authority_id);

-- ---------------------------------
-- 10. Bảng tham chiếu mối quan hệ gia đình
-- ---------------------------------
\echo 'Tạo bảng tham chiếu mối quan hệ gia đình (relationship_types)...'

-- Bảng mối quan hệ gia đình cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types (
    relationship_type_id SMALLINT PRIMARY KEY,
    relationship_code VARCHAR(10) NOT NULL UNIQUE,
    relationship_name VARCHAR(100) NOT NULL,
    inverse_relationship_type_id SMALLINT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.relationship_types IS 'Bảng tham chiếu mối quan hệ gia đình';
COMMENT ON COLUMN reference.relationship_types.relationship_type_id IS 'ID mối quan hệ';
COMMENT ON COLUMN reference.relationship_types.relationship_code IS 'Mã mối quan hệ';
COMMENT ON COLUMN reference.relationship_types.relationship_name IS 'Tên mối quan hệ';
COMMENT ON COLUMN reference.relationship_types.inverse_relationship_type_id IS 'ID mối quan hệ ngược lại';

CREATE INDEX idx_relationship_types_relationship_code ON reference.relationship_types(relationship_code);
ALTER TABLE reference.relationship_types ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id) REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;

-- Bảng mối quan hệ gia đình cho Bộ Tư pháp
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types (
    relationship_type_id SMALLINT PRIMARY KEY,
    relationship_code VARCHAR(10) NOT NULL UNIQUE,
    relationship_name VARCHAR(100) NOT NULL,
    inverse_relationship_type_id SMALLINT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.relationship_types IS 'Bảng tham chiếu mối quan hệ gia đình';
CREATE INDEX idx_relationship_types_relationship_code ON reference.relationship_types(relationship_code);
ALTER TABLE reference.relationship_types ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id) REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;

-- Bảng mối quan hệ gia đình cho máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types (
    relationship_type_id SMALLINT PRIMARY KEY,
    relationship_code VARCHAR(10) NOT NULL UNIQUE,
    relationship_name VARCHAR(100) NOT NULL,
    inverse_relationship_type_id SMALLINT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.relationship_types IS 'Bảng tham chiếu mối quan hệ gia đình';
CREATE INDEX idx_relationship_types_relationship_code ON reference.relationship_types(relationship_code);
ALTER TABLE reference.relationship_types ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id) REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;





-- ============================================================================
-- 11. Bảng tham chiếu cơ sở giam giữ (Thêm mới)
-- ============================================================================
\echo 'Tạo bảng tham chiếu cơ sở giam giữ (prison_facilities)...'

-- Bảng cơ sở giam giữ cho Bộ Công an
\connect ministry_of_public_security
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities (
    prison_facility_id SERIAL PRIMARY KEY,        -- ID tự tăng của cơ sở
    facility_code VARCHAR(20) UNIQUE,             -- Mã định danh cơ sở (nếu có)
    facility_name VARCHAR(255) NOT NULL,          -- Tên đầy đủ của cơ sở giam giữ
    facility_type VARCHAR(50),                    -- Loại cơ sở (Trại giam, Trại tạm giam, Nhà tạm giữ...)
    address_detail TEXT,                          -- Địa chỉ chi tiết
    ward_id INTEGER REFERENCES reference.wards(ward_id),             -- Phường/Xã
    district_id INTEGER REFERENCES reference.districts(district_id), -- Quận/Huyện
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id), -- Tỉnh/Thành phố
    capacity INTEGER,                             -- Sức chứa (số người)
    managing_authority_id INTEGER REFERENCES reference.authorities(authority_id), -- Cơ quan quản lý
    phone_number VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,               -- Trạng thái hoạt động
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reference.prison_facilities IS 'Bảng tham chiếu các cơ sở giam giữ (trại giam, trại tạm giam...).';
COMMENT ON COLUMN reference.prison_facilities.prison_facility_id IS 'ID tự tăng của cơ sở giam giữ.';
COMMENT ON COLUMN reference.prison_facilities.facility_code IS 'Mã định danh duy nhất của cơ sở (nếu có).';
COMMENT ON COLUMN reference.prison_facilities.facility_name IS 'Tên đầy đủ của cơ sở giam giữ.';
COMMENT ON COLUMN reference.prison_facilities.facility_type IS 'Loại hình cơ sở (ví dụ: Trại giam, Trại tạm giam).';
COMMENT ON COLUMN reference.prison_facilities.province_id IS 'Tỉnh/Thành phố nơi cơ sở tọa lạc.';
COMMENT ON COLUMN reference.prison_facilities.capacity IS 'Sức chứa tối đa của cơ sở.';
COMMENT ON COLUMN reference.prison_facilities.managing_authority_id IS 'Cơ quan trực tiếp quản lý cơ sở.';
COMMENT ON COLUMN reference.prison_facilities.is_active IS 'Cơ sở có đang hoạt động không?';

CREATE INDEX idx_prison_facilities_name ON reference.prison_facilities(facility_name);
CREATE INDEX idx_prison_facilities_province ON reference.prison_facilities(province_id);
CREATE INDEX idx_prison_facilities_type ON reference.prison_facilities(facility_type);
CREATE INDEX idx_prison_facilities_active ON reference.prison_facilities(is_active);

-- Bảng cơ sở giam giữ cho Bộ Tư pháp (Có thể cần để tham chiếu hoặc không, tùy logic nghiệp vụ)
\connect ministry_of_justice
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities (
    prison_facility_id SERIAL PRIMARY KEY,
    facility_code VARCHAR(20) UNIQUE,
    facility_name VARCHAR(255) NOT NULL,
    facility_type VARCHAR(50),
    address_detail TEXT,
    ward_id INTEGER REFERENCES reference.wards(ward_id),
    district_id INTEGER REFERENCES reference.districts(district_id),
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    capacity INTEGER,
    managing_authority_id INTEGER REFERENCES reference.authorities(authority_id),
    phone_number VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.prison_facilities IS 'Bảng tham chiếu các cơ sở giam giữ (Bản sao tại BTP nếu cần).';
CREATE INDEX idx_prison_facilities_name ON reference.prison_facilities(facility_name);
CREATE INDEX idx_prison_facilities_province ON reference.prison_facilities(province_id);
CREATE INDEX idx_prison_facilities_type ON reference.prison_facilities(facility_type);
CREATE INDEX idx_prison_facilities_active ON reference.prison_facilities(is_active);

-- Bảng cơ sở giam giữ cho Máy chủ trung tâm
\connect national_citizen_central_server
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities (
    prison_facility_id SERIAL PRIMARY KEY,
    facility_code VARCHAR(20) UNIQUE,
    facility_name VARCHAR(255) NOT NULL,
    facility_type VARCHAR(50),
    address_detail TEXT,
    ward_id INTEGER REFERENCES reference.wards(ward_id),
    district_id INTEGER REFERENCES reference.districts(district_id),
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    capacity INTEGER,
    managing_authority_id INTEGER REFERENCES reference.authorities(authority_id),
    phone_number VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.prison_facilities IS 'Bảng tham chiếu các cơ sở giam giữ (Bản tổng hợp tại TT).';
CREATE INDEX idx_prison_facilities_name ON reference.prison_facilities(facility_name);
CREATE INDEX idx_prison_facilities_province ON reference.prison_facilities(province_id);
CREATE INDEX idx_prison_facilities_type ON reference.prison_facilities(facility_type);
CREATE INDEX idx_prison_facilities_active ON reference.prison_facilities(is_active);

\echo '-> Đã bổ sung bảng tham chiếu cơ sở giam giữ (prison_facilities).'


\echo 'Quá trình tạo các bảng tham chiếu đã hoàn tất'
\echo 'Đã tạo các bảng: regions, provinces, districts, wards, ethnicities, religions, nationalities, occupations, authorities, relationship_types'
\echo 'Tiếp theo là nhập dữ liệu tham chiếu vào các bảng này...'
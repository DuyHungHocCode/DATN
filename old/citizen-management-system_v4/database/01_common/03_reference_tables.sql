-- File: 01_common/03_reference_tables.sql
-- Description: Tạo cấu trúc cho các bảng tham chiếu dùng chung trong schema 'reference'.
--              Script này cần được chạy trên CẢ 3 database (BCA, BTP, TT).
-- Version: 3.1 (Added CREATE EXTENSION pg_trgm before index creation)
--
-- Chức năng chính:
-- 1. Tạo bảng regions (Vùng/Miền).
-- 2. Tạo bảng provinces (Tỉnh/Thành phố).
-- 3. Tạo bảng districts (Quận/Huyện).
-- 4. Tạo bảng wards (Phường/Xã).
-- 5. Tạo bảng ethnicities (Dân tộc).
-- 6. Tạo bảng religions (Tôn giáo).
-- 7. Tạo bảng nationalities (Quốc tịch).
-- 8. Tạo bảng occupations (Nghề nghiệp).
-- 9. Tạo bảng authorities (Cơ quan có thẩm quyền).
-- 10. Tạo bảng relationship_types (Loại quan hệ gia đình).
-- 11. Tạo bảng prison_facilities (Cơ sở giam giữ).
--
-- Yêu cầu: Chạy sau script 01_common/02_enum.sql.
--          Extension pg_trgm phải được cài đặt ở OS level.
--          Cần quyền tạo bảng và extension trong schema 'reference' trên cả 3 DB.
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO CẤU TRÚC BẢNG THAM CHIẾU (REFERENCE TABLES) ***'
\echo 'Lưu ý: Script này sẽ chạy trên cả 3 database.'

-- ============================================================================
-- Helper function to ensure pg_trgm extension exists
-- ============================================================================
-- (No function needed, will add directly after \connect)

-- ============================================================================
-- 1. Bảng reference.regions (Vùng/Miền)
-- ============================================================================
\echo '--> 1. Tạo bảng reference.regions...'

-- Trên DB BCA
\connect ministry_of_public_security
-- Đảm bảo extension pg_trgm tồn tại trước khi tạo index GIN
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions (
    region_id SMALLINT PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.regions IS '[Chung] Bảng tham chiếu vùng/miền (Bắc, Trung, Nam)';
COMMENT ON COLUMN reference.regions.region_id IS 'ID vùng/miền (1: Bắc, 2: Trung, 3: Nam)';
COMMENT ON COLUMN reference.regions.region_code IS 'Mã code của vùng (BAC, TRUNG, NAM)';
COMMENT ON COLUMN reference.regions.region_name IS 'Tên vùng/miền';
CREATE INDEX idx_regions_region_code ON reference.regions(region_code);
\echo '    - Đã tạo reference.regions trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions (
    region_id SMALLINT PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.regions IS '[Chung] Bảng tham chiếu vùng/miền (Bắc, Trung, Nam)';
CREATE INDEX idx_regions_region_code ON reference.regions(region_code);
\echo '    - Đã tạo reference.regions trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions (
    region_id SMALLINT PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.regions IS '[Chung] Bảng tham chiếu vùng/miền (Bắc, Trung, Nam)';
CREATE INDEX idx_regions_region_code ON reference.regions(region_code);
\echo '    - Đã tạo reference.regions trên national_citizen_central_server.'

-- ============================================================================
-- 2. Bảng reference.provinces (Tỉnh/Thành phố)
-- ============================================================================
\echo '--> 2. Tạo bảng reference.provinces...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces (
    province_id INTEGER PRIMARY KEY,
    province_code VARCHAR(10) NOT NULL UNIQUE,
    province_name VARCHAR(100) NOT NULL,
    region_id SMALLINT NOT NULL REFERENCES reference.regions(region_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_city BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.provinces IS '[Chung] Bảng tham chiếu tỉnh/thành phố trực thuộc Trung ương';
COMMENT ON COLUMN reference.provinces.province_id IS 'ID tỉnh/thành phố (theo quy ước chung)';
COMMENT ON COLUMN reference.provinces.province_code IS 'Mã code của tỉnh/thành phố';
COMMENT ON COLUMN reference.provinces.province_name IS 'Tên đầy đủ của tỉnh/thành phố';
COMMENT ON COLUMN reference.provinces.region_id IS 'Khóa ngoại tham chiếu đến vùng/miền';
COMMENT ON COLUMN reference.provinces.is_city IS 'Đánh dấu là thành phố trực thuộc Trung ương';
CREATE INDEX idx_provinces_region_id ON reference.provinces(region_id);
CREATE INDEX idx_provinces_province_code ON reference.provinces(province_code);
CREATE INDEX idx_provinces_province_name ON reference.provinces USING gin (province_name gin_trgm_ops); -- Index GIN yêu cầu pg_trgm
\echo '    - Đã tạo reference.provinces trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces (
    province_id INTEGER PRIMARY KEY, province_code VARCHAR(10) NOT NULL UNIQUE, province_name VARCHAR(100) NOT NULL,
    region_id SMALLINT NOT NULL REFERENCES reference.regions(region_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_city BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.provinces IS '[Chung] Bảng tham chiếu tỉnh/thành phố trực thuộc Trung ương';
CREATE INDEX idx_provinces_region_id ON reference.provinces(region_id);
CREATE INDEX idx_provinces_province_code ON reference.provinces(province_code);
CREATE INDEX idx_provinces_province_name ON reference.provinces USING gin (province_name gin_trgm_ops);
\echo '    - Đã tạo reference.provinces trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces (
    province_id INTEGER PRIMARY KEY, province_code VARCHAR(10) NOT NULL UNIQUE, province_name VARCHAR(100) NOT NULL,
    region_id SMALLINT NOT NULL REFERENCES reference.regions(region_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_city BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.provinces IS '[Chung] Bảng tham chiếu tỉnh/thành phố trực thuộc Trung ương';
CREATE INDEX idx_provinces_region_id ON reference.provinces(region_id);
CREATE INDEX idx_provinces_province_code ON reference.provinces(province_code);
CREATE INDEX idx_provinces_province_name ON reference.provinces USING gin (province_name gin_trgm_ops);
\echo '    - Đã tạo reference.provinces trên national_citizen_central_server.'


-- ============================================================================
-- 3. Bảng reference.districts (Quận/Huyện)
-- ============================================================================
\echo '--> 3. Tạo bảng reference.districts...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts (
    district_id INTEGER PRIMARY KEY,
    district_code VARCHAR(10) NOT NULL UNIQUE,
    district_name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.districts IS '[Chung] Bảng tham chiếu quận/huyện/thị xã/thành phố thuộc tỉnh';
COMMENT ON COLUMN reference.districts.district_id IS 'ID quận/huyện (theo quy ước chung)';
COMMENT ON COLUMN reference.districts.district_code IS 'Mã code của quận/huyện';
COMMENT ON COLUMN reference.districts.district_name IS 'Tên đầy đủ của quận/huyện';
COMMENT ON COLUMN reference.districts.province_id IS 'Khóa ngoại tham chiếu đến tỉnh/thành phố';
COMMENT ON COLUMN reference.districts.is_urban IS 'Đánh dấu là đơn vị hành chính đô thị cấp huyện';
CREATE INDEX idx_districts_province_id ON reference.districts(province_id);
CREATE INDEX idx_districts_district_code ON reference.districts(district_code);
CREATE INDEX idx_districts_district_name ON reference.districts USING gin (district_name gin_trgm_ops);
\echo '    - Đã tạo reference.districts trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts (
    district_id INTEGER PRIMARY KEY, district_code VARCHAR(10) NOT NULL UNIQUE, district_name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.districts IS '[Chung] Bảng tham chiếu quận/huyện/thị xã/thành phố thuộc tỉnh';
CREATE INDEX idx_districts_province_id ON reference.districts(province_id);
CREATE INDEX idx_districts_district_code ON reference.districts(district_code);
CREATE INDEX idx_districts_district_name ON reference.districts USING gin (district_name gin_trgm_ops);
\echo '    - Đã tạo reference.districts trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts (
    district_id INTEGER PRIMARY KEY, district_code VARCHAR(10) NOT NULL UNIQUE, district_name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.districts IS '[Chung] Bảng tham chiếu quận/huyện/thị xã/thành phố thuộc tỉnh';
CREATE INDEX idx_districts_province_id ON reference.districts(province_id);
CREATE INDEX idx_districts_district_code ON reference.districts(district_code);
CREATE INDEX idx_districts_district_name ON reference.districts USING gin (district_name gin_trgm_ops);
\echo '    - Đã tạo reference.districts trên national_citizen_central_server.'


-- ============================================================================
-- 4. Bảng reference.wards (Phường/Xã)
-- ============================================================================
\echo '--> 4. Tạo bảng reference.wards...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards (
    ward_id INTEGER PRIMARY KEY,
    ward_code VARCHAR(10) NOT NULL UNIQUE,
    ward_name VARCHAR(100) NOT NULL,
    district_id INTEGER NOT NULL REFERENCES reference.districts(district_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.wards IS '[Chung] Bảng tham chiếu phường/xã/thị trấn';
COMMENT ON COLUMN reference.wards.ward_id IS 'ID phường/xã (theo quy ước chung)';
COMMENT ON COLUMN reference.wards.ward_code IS 'Mã code của phường/xã';
COMMENT ON COLUMN reference.wards.ward_name IS 'Tên đầy đủ của phường/xã';
COMMENT ON COLUMN reference.wards.district_id IS 'Khóa ngoại tham chiếu đến quận/huyện';
COMMENT ON COLUMN reference.wards.is_urban IS 'Đánh dấu là đơn vị hành chính đô thị cấp xã';
CREATE INDEX idx_wards_district_id ON reference.wards(district_id);
CREATE INDEX idx_wards_ward_code ON reference.wards(ward_code);
CREATE INDEX idx_wards_ward_name ON reference.wards USING gin (ward_name gin_trgm_ops);
\echo '    - Đã tạo reference.wards trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards (
    ward_id INTEGER PRIMARY KEY, ward_code VARCHAR(10) NOT NULL UNIQUE, ward_name VARCHAR(100) NOT NULL,
    district_id INTEGER NOT NULL REFERENCES reference.districts(district_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.wards IS '[Chung] Bảng tham chiếu phường/xã/thị trấn';
CREATE INDEX idx_wards_district_id ON reference.wards(district_id);
CREATE INDEX idx_wards_ward_code ON reference.wards(ward_code);
CREATE INDEX idx_wards_ward_name ON reference.wards USING gin (ward_name gin_trgm_ops);
\echo '    - Đã tạo reference.wards trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards (
    ward_id INTEGER PRIMARY KEY, ward_code VARCHAR(10) NOT NULL UNIQUE, ward_name VARCHAR(100) NOT NULL,
    district_id INTEGER NOT NULL REFERENCES reference.districts(district_id),
    area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.wards IS '[Chung] Bảng tham chiếu phường/xã/thị trấn';
CREATE INDEX idx_wards_district_id ON reference.wards(district_id);
CREATE INDEX idx_wards_ward_code ON reference.wards(ward_code);
CREATE INDEX idx_wards_ward_name ON reference.wards USING gin (ward_name gin_trgm_ops);
\echo '    - Đã tạo reference.wards trên national_citizen_central_server.'


-- ============================================================================
-- 5. Bảng reference.ethnicities (Dân tộc)
-- ============================================================================
\echo '--> 5. Tạo bảng reference.ethnicities...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities (
    ethnicity_id SMALLINT PRIMARY KEY,
    ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
    ethnicity_name VARCHAR(100) NOT NULL,
    description TEXT, population INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.ethnicities IS '[Chung] Bảng tham chiếu các dân tộc Việt Nam';
CREATE INDEX idx_ethnicities_ethnicity_code ON reference.ethnicities(ethnicity_code);
CREATE INDEX idx_ethnicities_ethnicity_name ON reference.ethnicities USING gin (ethnicity_name gin_trgm_ops);
\echo '    - Đã tạo reference.ethnicities trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities (
    ethnicity_id SMALLINT PRIMARY KEY, ethnicity_code VARCHAR(10) NOT NULL UNIQUE, ethnicity_name VARCHAR(100) NOT NULL,
    description TEXT, population INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.ethnicities IS '[Chung] Bảng tham chiếu các dân tộc Việt Nam';
CREATE INDEX idx_ethnicities_ethnicity_code ON reference.ethnicities(ethnicity_code);
CREATE INDEX idx_ethnicities_ethnicity_name ON reference.ethnicities USING gin (ethnicity_name gin_trgm_ops);
\echo '    - Đã tạo reference.ethnicities trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities (
    ethnicity_id SMALLINT PRIMARY KEY, ethnicity_code VARCHAR(10) NOT NULL UNIQUE, ethnicity_name VARCHAR(100) NOT NULL,
    description TEXT, population INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.ethnicities IS '[Chung] Bảng tham chiếu các dân tộc Việt Nam';
CREATE INDEX idx_ethnicities_ethnicity_code ON reference.ethnicities(ethnicity_code);
CREATE INDEX idx_ethnicities_ethnicity_name ON reference.ethnicities USING gin (ethnicity_name gin_trgm_ops);
\echo '    - Đã tạo reference.ethnicities trên national_citizen_central_server.'


-- ============================================================================
-- 6. Bảng reference.religions (Tôn giáo)
-- ============================================================================
\echo '--> 6. Tạo bảng reference.religions...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions (
    religion_id SMALLINT PRIMARY KEY,
    religion_code VARCHAR(10) NOT NULL UNIQUE,
    religion_name VARCHAR(100) NOT NULL,
    description TEXT, followers INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.religions IS '[Chung] Bảng tham chiếu các tôn giáo được công nhận tại Việt Nam';
CREATE INDEX idx_religions_religion_code ON reference.religions(religion_code);
CREATE INDEX idx_religions_religion_name ON reference.religions USING gin (religion_name gin_trgm_ops);
\echo '    - Đã tạo reference.religions trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions (
    religion_id SMALLINT PRIMARY KEY, religion_code VARCHAR(10) NOT NULL UNIQUE, religion_name VARCHAR(100) NOT NULL,
    description TEXT, followers INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.religions IS '[Chung] Bảng tham chiếu các tôn giáo được công nhận tại Việt Nam';
CREATE INDEX idx_religions_religion_code ON reference.religions(religion_code);
CREATE INDEX idx_religions_religion_name ON reference.religions USING gin (religion_name gin_trgm_ops);
\echo '    - Đã tạo reference.religions trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions (
    religion_id SMALLINT PRIMARY KEY, religion_code VARCHAR(10) NOT NULL UNIQUE, religion_name VARCHAR(100) NOT NULL,
    description TEXT, followers INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.religions IS '[Chung] Bảng tham chiếu các tôn giáo được công nhận tại Việt Nam';
CREATE INDEX idx_religions_religion_code ON reference.religions(religion_code);
CREATE INDEX idx_religions_religion_name ON reference.religions USING gin (religion_name gin_trgm_ops);
\echo '    - Đã tạo reference.religions trên national_citizen_central_server.'


-- ============================================================================
-- 7. Bảng reference.nationalities (Quốc tịch)
-- ============================================================================
\echo '--> 7. Tạo bảng reference.nationalities...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities (
    nationality_id SMALLINT PRIMARY KEY,
    nationality_code VARCHAR(10) NOT NULL UNIQUE, iso_code_alpha2 VARCHAR(2) UNIQUE, iso_code_alpha3 VARCHAR(3) UNIQUE,
    nationality_name VARCHAR(100) NOT NULL, country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.nationalities IS '[Chung] Bảng tham chiếu quốc tịch và quốc gia';
COMMENT ON COLUMN reference.nationalities.nationality_code IS 'Mã quốc tịch theo quy định của Việt Nam';
COMMENT ON COLUMN reference.nationalities.iso_code_alpha2 IS 'Mã quốc gia theo ISO 3166-1 alpha-2';
COMMENT ON COLUMN reference.nationalities.iso_code_alpha3 IS 'Mã quốc gia theo ISO 3166-1 alpha-3';
COMMENT ON COLUMN reference.nationalities.nationality_name IS 'Tên quốc tịch';
COMMENT ON COLUMN reference.nationalities.country_name IS 'Tên quốc gia chính thức hoặc phổ biến';
CREATE INDEX idx_nationalities_nationality_code ON reference.nationalities(nationality_code);
CREATE INDEX idx_nationalities_iso_code_alpha2 ON reference.nationalities(iso_code_alpha2);
CREATE INDEX idx_nationalities_iso_code_alpha3 ON reference.nationalities(iso_code_alpha3);
CREATE INDEX idx_nationalities_name ON reference.nationalities USING gin (nationality_name gin_trgm_ops, country_name gin_trgm_ops);
\echo '    - Đã tạo reference.nationalities trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities (
    nationality_id SMALLINT PRIMARY KEY, nationality_code VARCHAR(10) NOT NULL UNIQUE, iso_code_alpha2 VARCHAR(2) UNIQUE, iso_code_alpha3 VARCHAR(3) UNIQUE,
    nationality_name VARCHAR(100) NOT NULL, country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.nationalities IS '[Chung] Bảng tham chiếu quốc tịch và quốc gia';
CREATE INDEX idx_nationalities_nationality_code ON reference.nationalities(nationality_code);
CREATE INDEX idx_nationalities_iso_code_alpha2 ON reference.nationalities(iso_code_alpha2);
CREATE INDEX idx_nationalities_iso_code_alpha3 ON reference.nationalities(iso_code_alpha3);
CREATE INDEX idx_nationalities_name ON reference.nationalities USING gin (nationality_name gin_trgm_ops, country_name gin_trgm_ops);
\echo '    - Đã tạo reference.nationalities trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities (
    nationality_id SMALLINT PRIMARY KEY, nationality_code VARCHAR(10) NOT NULL UNIQUE, iso_code_alpha2 VARCHAR(2) UNIQUE, iso_code_alpha3 VARCHAR(3) UNIQUE,
    nationality_name VARCHAR(100) NOT NULL, country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.nationalities IS '[Chung] Bảng tham chiếu quốc tịch và quốc gia';
CREATE INDEX idx_nationalities_nationality_code ON reference.nationalities(nationality_code);
CREATE INDEX idx_nationalities_iso_code_alpha2 ON reference.nationalities(iso_code_alpha2);
CREATE INDEX idx_nationalities_iso_code_alpha3 ON reference.nationalities(iso_code_alpha3);
CREATE INDEX idx_nationalities_name ON reference.nationalities USING gin (nationality_name gin_trgm_ops, country_name gin_trgm_ops);
\echo '    - Đã tạo reference.nationalities trên national_citizen_central_server.'


-- ============================================================================
-- 8. Bảng reference.occupations (Nghề nghiệp)
-- ============================================================================
\echo '--> 8. Tạo bảng reference.occupations...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations (
    occupation_id INTEGER PRIMARY KEY,
    occupation_code VARCHAR(20) NOT NULL UNIQUE, occupation_name VARCHAR(255) NOT NULL,
    occupation_group_id INTEGER, description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    -- CONSTRAINT fk_occupation_group FOREIGN KEY (occupation_group_id) REFERENCES reference.occupation_groups(group_id) -- Nếu có bảng group
);
COMMENT ON TABLE reference.occupations IS '[Chung] Bảng tham chiếu nghề nghiệp';
COMMENT ON COLUMN reference.occupations.occupation_code IS 'Mã nghề nghiệp theo chuẩn phân loại Việt Nam (VSCO) hoặc quốc tế (ISCO)';
COMMENT ON COLUMN reference.occupations.occupation_name IS 'Tên nghề nghiệp';
COMMENT ON COLUMN reference.occupations.occupation_group_id IS 'ID nhóm nghề nghiệp (nếu có phân cấp)';
CREATE INDEX idx_occupations_occupation_code ON reference.occupations(occupation_code);
CREATE INDEX idx_occupations_occupation_group_id ON reference.occupations(occupation_group_id);
CREATE INDEX idx_occupations_occupation_name ON reference.occupations USING gin (occupation_name gin_trgm_ops);
\echo '    - Đã tạo reference.occupations trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations (
    occupation_id INTEGER PRIMARY KEY, occupation_code VARCHAR(20) NOT NULL UNIQUE, occupation_name VARCHAR(255) NOT NULL,
    occupation_group_id INTEGER, description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.occupations IS '[Chung] Bảng tham chiếu nghề nghiệp';
CREATE INDEX idx_occupations_occupation_code ON reference.occupations(occupation_code);
CREATE INDEX idx_occupations_occupation_group_id ON reference.occupations(occupation_group_id);
CREATE INDEX idx_occupations_occupation_name ON reference.occupations USING gin (occupation_name gin_trgm_ops);
\echo '    - Đã tạo reference.occupations trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations (
    occupation_id INTEGER PRIMARY KEY, occupation_code VARCHAR(20) NOT NULL UNIQUE, occupation_name VARCHAR(255) NOT NULL,
    occupation_group_id INTEGER, description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.occupations IS '[Chung] Bảng tham chiếu nghề nghiệp';
CREATE INDEX idx_occupations_occupation_code ON reference.occupations(occupation_code);
CREATE INDEX idx_occupations_occupation_group_id ON reference.occupations(occupation_group_id);
CREATE INDEX idx_occupations_occupation_name ON reference.occupations USING gin (occupation_name gin_trgm_ops);
\echo '    - Đã tạo reference.occupations trên national_citizen_central_server.'


-- ============================================================================
-- 9. Bảng reference.authorities (Cơ quan có thẩm quyền)
-- ============================================================================
\echo '--> 9. Tạo bảng reference.authorities...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities (
    authority_id INTEGER PRIMARY KEY,
    authority_code VARCHAR(30) NOT NULL UNIQUE, authority_name VARCHAR(255) NOT NULL, authority_type VARCHAR(100) NOT NULL,
    address_detail TEXT, ward_id INTEGER REFERENCES reference.wards(ward_id), district_id INTEGER REFERENCES reference.districts(district_id), province_id INTEGER REFERENCES reference.provinces(province_id),
    phone VARCHAR(50), email VARCHAR(100), website VARCHAR(255), parent_authority_id INTEGER REFERENCES reference.authorities(authority_id), is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.authorities IS '[Chung] Bảng tham chiếu các cơ quan, tổ chức có thẩm quyền liên quan';
COMMENT ON COLUMN reference.authorities.authority_code IS 'Mã định danh duy nhất của cơ quan';
COMMENT ON COLUMN reference.authorities.authority_name IS 'Tên đầy đủ của cơ quan';
COMMENT ON COLUMN reference.authorities.authority_type IS 'Phân loại cơ quan (Công an, Tư pháp, UBND...)';
COMMENT ON COLUMN reference.authorities.parent_authority_id IS 'ID của cơ quan quản lý cấp trên trực tiếp';
CREATE INDEX idx_authorities_authority_code ON reference.authorities(authority_code);
CREATE INDEX idx_authorities_province_id ON reference.authorities(province_id);
CREATE INDEX idx_authorities_district_id ON reference.authorities(district_id);
CREATE INDEX idx_authorities_ward_id ON reference.authorities(ward_id);
CREATE INDEX idx_authorities_parent_authority_id ON reference.authorities(parent_authority_id);
CREATE INDEX idx_authorities_authority_type ON reference.authorities(authority_type);
CREATE INDEX idx_authorities_authority_name ON reference.authorities USING gin (authority_name gin_trgm_ops);
\echo '    - Đã tạo reference.authorities trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities (
    authority_id INTEGER PRIMARY KEY, authority_code VARCHAR(30) NOT NULL UNIQUE, authority_name VARCHAR(255) NOT NULL, authority_type VARCHAR(100) NOT NULL,
    address_detail TEXT, ward_id INTEGER REFERENCES reference.wards(ward_id), district_id INTEGER REFERENCES reference.districts(district_id), province_id INTEGER REFERENCES reference.provinces(province_id),
    phone VARCHAR(50), email VARCHAR(100), website VARCHAR(255), parent_authority_id INTEGER REFERENCES reference.authorities(authority_id), is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.authorities IS '[Chung] Bảng tham chiếu các cơ quan, tổ chức có thẩm quyền liên quan';
CREATE INDEX idx_authorities_authority_code ON reference.authorities(authority_code);
CREATE INDEX idx_authorities_province_id ON reference.authorities(province_id);
CREATE INDEX idx_authorities_district_id ON reference.authorities(district_id);
CREATE INDEX idx_authorities_ward_id ON reference.authorities(ward_id);
CREATE INDEX idx_authorities_parent_authority_id ON reference.authorities(parent_authority_id);
CREATE INDEX idx_authorities_authority_type ON reference.authorities(authority_type);
CREATE INDEX idx_authorities_authority_name ON reference.authorities USING gin (authority_name gin_trgm_ops);
\echo '    - Đã tạo reference.authorities trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities (
     authority_id INTEGER PRIMARY KEY, authority_code VARCHAR(30) NOT NULL UNIQUE, authority_name VARCHAR(255) NOT NULL, authority_type VARCHAR(100) NOT NULL,
    address_detail TEXT, ward_id INTEGER REFERENCES reference.wards(ward_id), district_id INTEGER REFERENCES reference.districts(district_id), province_id INTEGER REFERENCES reference.provinces(province_id),
    phone VARCHAR(50), email VARCHAR(100), website VARCHAR(255), parent_authority_id INTEGER REFERENCES reference.authorities(authority_id), is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.authorities IS '[Chung] Bảng tham chiếu các cơ quan, tổ chức có thẩm quyền liên quan';
CREATE INDEX idx_authorities_authority_code ON reference.authorities(authority_code);
CREATE INDEX idx_authorities_province_id ON reference.authorities(province_id);
CREATE INDEX idx_authorities_district_id ON reference.authorities(district_id);
CREATE INDEX idx_authorities_ward_id ON reference.authorities(ward_id);
CREATE INDEX idx_authorities_parent_authority_id ON reference.authorities(parent_authority_id);
CREATE INDEX idx_authorities_authority_type ON reference.authorities(authority_type);
CREATE INDEX idx_authorities_authority_name ON reference.authorities USING gin (authority_name gin_trgm_ops);
\echo '    - Đã tạo reference.authorities trên national_citizen_central_server.'


-- ============================================================================
-- 10. Bảng reference.relationship_types (Loại quan hệ gia đình/hộ khẩu)
-- ============================================================================
\echo '--> 10. Tạo bảng reference.relationship_types...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types (
    relationship_type_id SMALLINT PRIMARY KEY,
    relationship_code VARCHAR(20) NOT NULL UNIQUE, relationship_name VARCHAR(100) NOT NULL,
    inverse_relationship_type_id SMALLINT, description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.relationship_types IS '[Chung] Bảng tham chiếu các loại quan hệ gia đình/hộ khẩu';
COMMENT ON COLUMN reference.relationship_types.inverse_relationship_type_id IS 'ID của mối quan hệ ngược lại trong bảng này (tham chiếu đến chính bảng này)';
CREATE INDEX idx_relationship_types_relationship_code ON reference.relationship_types(relationship_code);
ALTER TABLE reference.relationship_types
    ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id)
    REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;
\echo '    - Đã tạo reference.relationship_types trên ministry_of_public_security.'

-- Trên DB BTP
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types (
    relationship_type_id SMALLINT PRIMARY KEY, relationship_code VARCHAR(20) NOT NULL UNIQUE, relationship_name VARCHAR(100) NOT NULL,
    inverse_relationship_type_id SMALLINT, description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.relationship_types IS '[Chung] Bảng tham chiếu các loại quan hệ gia đình/hộ khẩu';
CREATE INDEX idx_relationship_types_relationship_code ON reference.relationship_types(relationship_code);
ALTER TABLE reference.relationship_types
    ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id)
    REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;
\echo '    - Đã tạo reference.relationship_types trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types (
    relationship_type_id SMALLINT PRIMARY KEY, relationship_code VARCHAR(20) NOT NULL UNIQUE, relationship_name VARCHAR(100) NOT NULL,
    inverse_relationship_type_id SMALLINT, description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.relationship_types IS '[Chung] Bảng tham chiếu các loại quan hệ gia đình/hộ khẩu';
CREATE INDEX idx_relationship_types_relationship_code ON reference.relationship_types(relationship_code);
ALTER TABLE reference.relationship_types
    ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id)
    REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;
\echo '    - Đã tạo reference.relationship_types trên national_citizen_central_server.'


-- ============================================================================
-- 11. Bảng reference.prison_facilities (Cơ sở giam giữ)
-- ============================================================================
\echo '--> 11. Tạo bảng reference.prison_facilities...'

-- Trên DB BCA
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities (
    prison_facility_id SERIAL PRIMARY KEY,
    facility_code VARCHAR(30) UNIQUE, facility_name VARCHAR(255) NOT NULL, facility_type VARCHAR(100),
    address_detail TEXT, ward_id INTEGER REFERENCES reference.wards(ward_id), district_id INTEGER REFERENCES reference.districts(district_id), province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    capacity INTEGER, managing_authority_id INTEGER REFERENCES reference.authorities(authority_id), phone_number VARCHAR(50), is_active BOOLEAN DEFAULT TRUE, notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.prison_facilities IS '[Chung] Bảng tham chiếu các cơ sở giam giữ (trại giam, trại tạm giam...).';
COMMENT ON COLUMN reference.prison_facilities.facility_code IS 'Mã định danh duy nhất của cơ sở (nếu có).';
COMMENT ON COLUMN reference.prison_facilities.province_id IS 'Tỉnh/Thành phố nơi cơ sở tọa lạc.';
COMMENT ON COLUMN reference.prison_facilities.managing_authority_id IS 'Cơ quan trực tiếp quản lý cơ sở.';
CREATE INDEX idx_prison_facilities_name ON reference.prison_facilities USING gin (facility_name gin_trgm_ops);
CREATE INDEX idx_prison_facilities_province ON reference.prison_facilities(province_id);
CREATE INDEX idx_prison_facilities_type ON reference.prison_facilities(facility_type);
CREATE INDEX idx_prison_facilities_active ON reference.prison_facilities(is_active);
\echo '    - Đã tạo reference.prison_facilities trên ministry_of_public_security.'

-- Trên DB BTP (Tạo cấu trúc để nhất quán, dù có thể ít dùng)
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities (
    prison_facility_id SERIAL PRIMARY KEY, facility_code VARCHAR(30) UNIQUE, facility_name VARCHAR(255) NOT NULL, facility_type VARCHAR(100),
    address_detail TEXT, ward_id INTEGER REFERENCES reference.wards(ward_id), district_id INTEGER REFERENCES reference.districts(district_id), province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    capacity INTEGER, managing_authority_id INTEGER REFERENCES reference.authorities(authority_id), phone_number VARCHAR(50), is_active BOOLEAN DEFAULT TRUE, notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.prison_facilities IS '[Chung] Bảng tham chiếu các cơ sở giam giữ.';
CREATE INDEX idx_prison_facilities_name ON reference.prison_facilities USING gin (facility_name gin_trgm_ops);
CREATE INDEX idx_prison_facilities_province ON reference.prison_facilities(province_id);
CREATE INDEX idx_prison_facilities_type ON reference.prison_facilities(facility_type);
CREATE INDEX idx_prison_facilities_active ON reference.prison_facilities(is_active);
\echo '    - Đã tạo reference.prison_facilities trên ministry_of_justice.'

-- Trên DB TT
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Đảm bảo tồn tại
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities (
    prison_facility_id SERIAL PRIMARY KEY, facility_code VARCHAR(30) UNIQUE, facility_name VARCHAR(255) NOT NULL, facility_type VARCHAR(100),
    address_detail TEXT, ward_id INTEGER REFERENCES reference.wards(ward_id), district_id INTEGER REFERENCES reference.districts(district_id), province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),
    capacity INTEGER, managing_authority_id INTEGER REFERENCES reference.authorities(authority_id), phone_number VARCHAR(50), is_active BOOLEAN DEFAULT TRUE, notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.prison_facilities IS '[Chung] Bảng tham chiếu các cơ sở giam giữ.';
CREATE INDEX idx_prison_facilities_name ON reference.prison_facilities USING gin (facility_name gin_trgm_ops);
CREATE INDEX idx_prison_facilities_province ON reference.prison_facilities(province_id);
CREATE INDEX idx_prison_facilities_type ON reference.prison_facilities(facility_type);
CREATE INDEX idx_prison_facilities_active ON reference.prison_facilities(is_active);
\echo '    - Đã tạo reference.prison_facilities trên national_citizen_central_server.'


-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH TẠO CẤU TRÚC BẢNG THAM CHIẾU ***'
\echo '-> Đã tạo cấu trúc các bảng trong schema "reference" trên cả 3 database.'
\echo '-> Bước tiếp theo: Nạp dữ liệu vào các bảng tham chiếu này (thư mục 01_common/reference_data/).'
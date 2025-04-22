-- =============================================================================
-- File: 01_common/03_reference_tables_structure.sql
-- Description: Tạo cấu trúc cơ bản (CREATE TABLE) cho các bảng tham chiếu
--              dùng chung trong schema 'reference'. Script này cần chạy
--              trên CẢ 3 database (BCA, BTP, TT).
-- Version: 3.1 (Structure only, constraints moved)
--
-- Lưu ý:
-- - Chỉ định nghĩa cột, kiểu dữ liệu, NOT NULL, DEFAULT đơn giản, PRIMARY KEY, UNIQUE.
-- - KHÔNG định nghĩa FOREIGN KEY, CHECK phức tạp, INDEX truy vấn ở đây.
--
-- Yêu cầu: Chạy sau script 01_common/02_enum.sql.
--          Cần quyền tạo bảng trong schema 'reference'.
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO CẤU TRÚC BẢNG THAM CHIẾU (REFERENCE TABLES) ***'

-- === 1. THỰC THI TRÊN DATABASE BỘ CÔNG AN (ministry_of_public_security) ===

\echo '[Bước 1] Tạo cấu trúc bảng tham chiếu cho database: ministry_of_public_security...'
\connect ministry_of_public_security

-- Bảng: regions (Vùng/Miền)
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions (
    region_id SMALLINT PRIMARY KEY,
    region_code VARCHAR(10) NOT NULL UNIQUE,
    region_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.regions IS '[Chung] Bảng tham chiếu vùng/miền (Bắc, Trung, Nam).';
COMMENT ON COLUMN reference.regions.region_id IS 'ID vùng/miền (1: Bắc, 2: Trung, 3: Nam).';
COMMENT ON COLUMN reference.regions.region_code IS 'Mã code của vùng (BAC, TRUNG, NAM).';

-- Bảng: provinces (Tỉnh/Thành phố)
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces (
    province_id INTEGER PRIMARY KEY,
    province_code VARCHAR(10) NOT NULL UNIQUE,
    province_name VARCHAR(100) NOT NULL,
    region_id SMALLINT NOT NULL, -- FK sẽ được thêm sau
    administrative_unit_id SMALLINT, -- ID loại đơn vị HC (1: TPTTTW, 2: Tỉnh)
    administrative_region_id SMALLINT, -- ID vùng hành chính/kinh tế (nếu có)
    area DECIMAL(10,2),
    population INTEGER,
    gso_code VARCHAR(10), -- Mã theo Tổng cục Thống kê
    is_city BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.provinces IS '[Chung] Bảng tham chiếu tỉnh/thành phố trực thuộc Trung ương.';
COMMENT ON COLUMN reference.provinces.region_id IS 'ID vùng/miền mà tỉnh/TP thuộc về.';
COMMENT ON COLUMN reference.provinces.is_city IS 'TRUE nếu là Thành phố trực thuộc Trung ương.';

-- Bảng: districts (Quận/Huyện)
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts (
    district_id INTEGER PRIMARY KEY,
    district_code VARCHAR(10) NOT NULL UNIQUE,
    district_name VARCHAR(100) NOT NULL,
    province_id INTEGER NOT NULL, -- FK sẽ được thêm sau
    administrative_unit_id SMALLINT, -- ID loại đơn vị HC (1: Quận, 2: Huyện, 3: Thị xã, 4: TP thuộc tỉnh)
    area DECIMAL(10,2),
    population INTEGER,
    gso_code VARCHAR(10),
    is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.districts IS '[Chung] Bảng tham chiếu quận/huyện/thị xã/thành phố thuộc tỉnh.';
COMMENT ON COLUMN reference.districts.province_id IS 'ID tỉnh/thành phố mà quận/huyện trực thuộc.';
COMMENT ON COLUMN reference.districts.is_urban IS 'TRUE nếu là đơn vị hành chính đô thị cấp huyện (Quận, Thị xã, TP thuộc tỉnh).';

-- Bảng: wards (Phường/Xã)
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards (
    ward_id INTEGER PRIMARY KEY,
    ward_code VARCHAR(10) NOT NULL UNIQUE,
    ward_name VARCHAR(100) NOT NULL,
    district_id INTEGER NOT NULL, -- FK sẽ được thêm sau
    administrative_unit_id SMALLINT, -- ID loại đơn vị HC (5: Phường, 6: Xã, 7: Thị trấn)
    area DECIMAL(10,2),
    population INTEGER,
    gso_code VARCHAR(10),
    is_urban BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.wards IS '[Chung] Bảng tham chiếu phường/xã/thị trấn.';
COMMENT ON COLUMN reference.wards.district_id IS 'ID quận/huyện mà phường/xã trực thuộc.';
COMMENT ON COLUMN reference.wards.is_urban IS 'TRUE nếu là đơn vị hành chính đô thị cấp xã (Phường, Thị trấn).';

-- Bảng: ethnicities (Dân tộc)
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities (
    ethnicity_id SMALLINT PRIMARY KEY,
    ethnicity_code VARCHAR(10) NOT NULL UNIQUE,
    ethnicity_name VARCHAR(100) NOT NULL,
    description TEXT,
    population INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.ethnicities IS '[Chung] Bảng tham chiếu các dân tộc Việt Nam.';

-- Bảng: religions (Tôn giáo)
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions (
    religion_id SMALLINT PRIMARY KEY,
    religion_code VARCHAR(10) NOT NULL UNIQUE,
    religion_name VARCHAR(100) NOT NULL,
    description TEXT,
    followers INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.religions IS '[Chung] Bảng tham chiếu các tôn giáo được công nhận tại Việt Nam.';

-- Bảng: nationalities (Quốc tịch)
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities (
    nationality_id SMALLINT PRIMARY KEY,
    nationality_code VARCHAR(10) NOT NULL UNIQUE,
    iso_code_alpha2 VARCHAR(2) UNIQUE,
    iso_code_alpha3 VARCHAR(3) UNIQUE,
    nationality_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.nationalities IS '[Chung] Bảng tham chiếu quốc tịch và quốc gia.';
COMMENT ON COLUMN reference.nationalities.iso_code_alpha2 IS 'Mã quốc gia theo ISO 3166-1 alpha-2.';
COMMENT ON COLUMN reference.nationalities.iso_code_alpha3 IS 'Mã quốc gia theo ISO 3166-1 alpha-3.';

-- Bảng: occupations (Nghề nghiệp)
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations (
    occupation_id INTEGER PRIMARY KEY,
    occupation_code VARCHAR(20) NOT NULL UNIQUE,
    occupation_name VARCHAR(255) NOT NULL,
    occupation_group_id INTEGER, -- FK (nếu có bảng group) sẽ thêm sau
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.occupations IS '[Chung] Bảng tham chiếu nghề nghiệp.';
COMMENT ON COLUMN reference.occupations.occupation_code IS 'Mã nghề nghiệp theo chuẩn phân loại (VSCO, ISCO...).';

-- Bảng: authorities (Cơ quan có thẩm quyền)
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities (
    authority_id INTEGER PRIMARY KEY,
    authority_code VARCHAR(30) NOT NULL UNIQUE,
    authority_name VARCHAR(255) NOT NULL,
    authority_type VARCHAR(100) NOT NULL, -- Phân loại cơ quan (Công an, Tư pháp, UBND...)
    address_detail TEXT,
    ward_id INTEGER, -- FK sẽ được thêm sau
    district_id INTEGER, -- FK sẽ được thêm sau
    province_id INTEGER, -- FK sẽ được thêm sau
    phone VARCHAR(50),
    email VARCHAR(100),
    website VARCHAR(255),
    parent_authority_id INTEGER, -- FK tự tham chiếu sẽ thêm sau
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.authorities IS '[Chung] Bảng tham chiếu các cơ quan, tổ chức có thẩm quyền liên quan.';
COMMENT ON COLUMN reference.authorities.parent_authority_id IS 'ID của cơ quan quản lý cấp trên trực tiếp.';

-- Bảng: relationship_types (Loại quan hệ gia đình/hộ khẩu)
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types (
    relationship_type_id SMALLINT PRIMARY KEY,
    relationship_code VARCHAR(20) NOT NULL UNIQUE,
    relationship_name VARCHAR(100) NOT NULL,
    inverse_relationship_type_id SMALLINT, -- FK tự tham chiếu sẽ thêm sau
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.relationship_types IS '[Chung] Bảng tham chiếu các loại quan hệ gia đình/hộ khẩu.';
COMMENT ON COLUMN reference.relationship_types.inverse_relationship_type_id IS 'ID của mối quan hệ ngược lại (vd: Cha-Con -> Con-Cha).';

-- Bảng: prison_facilities (Cơ sở giam giữ) - Chủ yếu dùng cho BCA nhưng để ở common
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities (
    prison_facility_id SERIAL PRIMARY KEY,
    facility_code VARCHAR(30) UNIQUE,
    facility_name VARCHAR(255) NOT NULL,
    facility_type VARCHAR(100), -- Loại hình (Trại giam, Trại tạm giam...)
    address_detail TEXT,
    ward_id INTEGER, -- FK sẽ được thêm sau
    district_id INTEGER, -- FK sẽ được thêm sau
    province_id INTEGER NOT NULL, -- FK sẽ được thêm sau
    capacity INTEGER,
    managing_authority_id INTEGER, -- FK sẽ được thêm sau
    phone_number VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reference.prison_facilities IS '[Chung] Bảng tham chiếu các cơ sở giam giữ (trại giam, trại tạm giam...).';

\echo '   -> Hoàn thành tạo cấu trúc bảng tham chiếu cho ministry_of_public_security.'


-- === 2. THỰC THI TRÊN DATABASE BỘ TƯ PHÁP (ministry_of_justice) ===

\echo '[Bước 2] Tạo cấu trúc bảng tham chiếu cho database: ministry_of_justice...'
\connect ministry_of_justice

-- (Lặp lại các lệnh DROP TABLE IF EXISTS và CREATE TABLE như trên)
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions ( 
    region_id SMALLINT PRIMARY KEY, 
    region_code VARCHAR(10) NOT NULL UNIQUE, 
    region_name VARCHAR(50) NOT NULL, 
    description TEXT, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, 
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
    
COMMENT ON TABLE reference.regions IS '[Chung] Bảng tham chiếu vùng/miền (Bắc, Trung, Nam).';
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces ( province_id INTEGER PRIMARY KEY, province_code VARCHAR(10) NOT NULL UNIQUE, province_name VARCHAR(100) NOT NULL, region_id SMALLINT NOT NULL, administrative_unit_id SMALLINT, administrative_region_id SMALLINT, area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_city BOOLEAN DEFAULT FALSE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.provinces IS '[Chung] Bảng tham chiếu tỉnh/thành phố trực thuộc Trung ương.';
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts ( district_id INTEGER PRIMARY KEY, district_code VARCHAR(10) NOT NULL UNIQUE, district_name VARCHAR(100) NOT NULL, province_id INTEGER NOT NULL, administrative_unit_id SMALLINT, area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.districts IS '[Chung] Bảng tham chiếu quận/huyện/thị xã/thành phố thuộc tỉnh.';
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards ( ward_id INTEGER PRIMARY KEY, ward_code VARCHAR(10) NOT NULL UNIQUE, ward_name VARCHAR(100) NOT NULL, district_id INTEGER NOT NULL, administrative_unit_id SMALLINT, area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.wards IS '[Chung] Bảng tham chiếu phường/xã/thị trấn.';
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities ( ethnicity_id SMALLINT PRIMARY KEY, ethnicity_code VARCHAR(10) NOT NULL UNIQUE, ethnicity_name VARCHAR(100) NOT NULL, description TEXT, population INTEGER, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.ethnicities IS '[Chung] Bảng tham chiếu các dân tộc Việt Nam.';
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions ( religion_id SMALLINT PRIMARY KEY, religion_code VARCHAR(10) NOT NULL UNIQUE, religion_name VARCHAR(100) NOT NULL, description TEXT, followers INTEGER, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.religions IS '[Chung] Bảng tham chiếu các tôn giáo được công nhận tại Việt Nam.';
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities ( nationality_id SMALLINT PRIMARY KEY, nationality_code VARCHAR(10) NOT NULL UNIQUE, iso_code_alpha2 VARCHAR(2) UNIQUE, iso_code_alpha3 VARCHAR(3) UNIQUE, nationality_name VARCHAR(100) NOT NULL, country_name VARCHAR(100) NOT NULL, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.nationalities IS '[Chung] Bảng tham chiếu quốc tịch và quốc gia.';
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations ( occupation_id INTEGER PRIMARY KEY, occupation_code VARCHAR(20) NOT NULL UNIQUE, occupation_name VARCHAR(255) NOT NULL, occupation_group_id INTEGER, description TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.occupations IS '[Chung] Bảng tham chiếu nghề nghiệp.';
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities ( authority_id INTEGER PRIMARY KEY, authority_code VARCHAR(30) NOT NULL UNIQUE, authority_name VARCHAR(255) NOT NULL, authority_type VARCHAR(100) NOT NULL, address_detail TEXT, ward_id INTEGER, district_id INTEGER, province_id INTEGER, phone VARCHAR(50), email VARCHAR(100), website VARCHAR(255), parent_authority_id INTEGER, is_active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.authorities IS '[Chung] Bảng tham chiếu các cơ quan, tổ chức có thẩm quyền liên quan.';
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types ( relationship_type_id SMALLINT PRIMARY KEY, relationship_code VARCHAR(20) NOT NULL UNIQUE, relationship_name VARCHAR(100) NOT NULL, inverse_relationship_type_id SMALLINT, description TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.relationship_types IS '[Chung] Bảng tham chiếu các loại quan hệ gia đình/hộ khẩu.';
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities ( prison_facility_id SERIAL PRIMARY KEY, facility_code VARCHAR(30) UNIQUE, facility_name VARCHAR(255) NOT NULL, facility_type VARCHAR(100), address_detail TEXT, ward_id INTEGER, district_id INTEGER, province_id INTEGER NOT NULL, capacity INTEGER, managing_authority_id INTEGER, phone_number VARCHAR(50), is_active BOOLEAN DEFAULT TRUE, notes TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.prison_facilities IS '[Chung] Bảng tham chiếu các cơ sở giam giữ.';

\echo '   -> Hoàn thành tạo cấu trúc bảng tham chiếu cho ministry_of_justice.'


-- === 3. THỰC THI TRÊN DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server) ===

\echo '[Bước 3] Tạo cấu trúc bảng tham chiếu cho database: national_citizen_central_server...'
\connect national_citizen_central_server

-- (Lặp lại các lệnh DROP TABLE IF EXISTS và CREATE TABLE như trên)
DROP TABLE IF EXISTS reference.regions CASCADE;
CREATE TABLE reference.regions ( region_id SMALLINT PRIMARY KEY, region_code VARCHAR(10) NOT NULL UNIQUE, region_name VARCHAR(50) NOT NULL, description TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.regions IS '[Chung] Bảng tham chiếu vùng/miền (Bắc, Trung, Nam).';
DROP TABLE IF EXISTS reference.provinces CASCADE;
CREATE TABLE reference.provinces ( province_id INTEGER PRIMARY KEY, province_code VARCHAR(10) NOT NULL UNIQUE, province_name VARCHAR(100) NOT NULL, region_id SMALLINT NOT NULL, administrative_unit_id SMALLINT, administrative_region_id SMALLINT, area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_city BOOLEAN DEFAULT FALSE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.provinces IS '[Chung] Bảng tham chiếu tỉnh/thành phố trực thuộc Trung ương.';
DROP TABLE IF EXISTS reference.districts CASCADE;
CREATE TABLE reference.districts ( district_id INTEGER PRIMARY KEY, district_code VARCHAR(10) NOT NULL UNIQUE, district_name VARCHAR(100) NOT NULL, province_id INTEGER NOT NULL, administrative_unit_id SMALLINT, area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.districts IS '[Chung] Bảng tham chiếu quận/huyện/thị xã/thành phố thuộc tỉnh.';
DROP TABLE IF EXISTS reference.wards CASCADE;
CREATE TABLE reference.wards ( ward_id INTEGER PRIMARY KEY, ward_code VARCHAR(10) NOT NULL UNIQUE, ward_name VARCHAR(100) NOT NULL, district_id INTEGER NOT NULL, administrative_unit_id SMALLINT, area DECIMAL(10,2), population INTEGER, gso_code VARCHAR(10), is_urban BOOLEAN DEFAULT FALSE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.wards IS '[Chung] Bảng tham chiếu phường/xã/thị trấn.';
DROP TABLE IF EXISTS reference.ethnicities CASCADE;
CREATE TABLE reference.ethnicities ( ethnicity_id SMALLINT PRIMARY KEY, ethnicity_code VARCHAR(10) NOT NULL UNIQUE, ethnicity_name VARCHAR(100) NOT NULL, description TEXT, population INTEGER, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.ethnicities IS '[Chung] Bảng tham chiếu các dân tộc Việt Nam.';
DROP TABLE IF EXISTS reference.religions CASCADE;
CREATE TABLE reference.religions ( religion_id SMALLINT PRIMARY KEY, religion_code VARCHAR(10) NOT NULL UNIQUE, religion_name VARCHAR(100) NOT NULL, description TEXT, followers INTEGER, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.religions IS '[Chung] Bảng tham chiếu các tôn giáo được công nhận tại Việt Nam.';
DROP TABLE IF EXISTS reference.nationalities CASCADE;
CREATE TABLE reference.nationalities ( nationality_id SMALLINT PRIMARY KEY, nationality_code VARCHAR(10) NOT NULL UNIQUE, iso_code_alpha2 VARCHAR(2) UNIQUE, iso_code_alpha3 VARCHAR(3) UNIQUE, nationality_name VARCHAR(100) NOT NULL, country_name VARCHAR(100) NOT NULL, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.nationalities IS '[Chung] Bảng tham chiếu quốc tịch và quốc gia.';
DROP TABLE IF EXISTS reference.occupations CASCADE;
CREATE TABLE reference.occupations ( occupation_id INTEGER PRIMARY KEY, occupation_code VARCHAR(20) NOT NULL UNIQUE, occupation_name VARCHAR(255) NOT NULL, occupation_group_id INTEGER, description TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.occupations IS '[Chung] Bảng tham chiếu nghề nghiệp.';
DROP TABLE IF EXISTS reference.authorities CASCADE;
CREATE TABLE reference.authorities ( authority_id INTEGER PRIMARY KEY, authority_code VARCHAR(30) NOT NULL UNIQUE, authority_name VARCHAR(255) NOT NULL, authority_type VARCHAR(100) NOT NULL, address_detail TEXT, ward_id INTEGER, district_id INTEGER, province_id INTEGER, phone VARCHAR(50), email VARCHAR(100), website VARCHAR(255), parent_authority_id INTEGER, is_active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.authorities IS '[Chung] Bảng tham chiếu các cơ quan, tổ chức có thẩm quyền liên quan.';
DROP TABLE IF EXISTS reference.relationship_types CASCADE;
CREATE TABLE reference.relationship_types ( relationship_type_id SMALLINT PRIMARY KEY, relationship_code VARCHAR(20) NOT NULL UNIQUE, relationship_name VARCHAR(100) NOT NULL, inverse_relationship_type_id SMALLINT, description TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.relationship_types IS '[Chung] Bảng tham chiếu các loại quan hệ gia đình/hộ khẩu.';
DROP TABLE IF EXISTS reference.prison_facilities CASCADE;
CREATE TABLE reference.prison_facilities ( prison_facility_id SERIAL PRIMARY KEY, facility_code VARCHAR(30) UNIQUE, facility_name VARCHAR(255) NOT NULL, facility_type VARCHAR(100), address_detail TEXT, ward_id INTEGER, district_id INTEGER, province_id INTEGER NOT NULL, capacity INTEGER, managing_authority_id INTEGER, phone_number VARCHAR(50), is_active BOOLEAN DEFAULT TRUE, notes TEXT, created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP );
COMMENT ON TABLE reference.prison_facilities IS '[Chung] Bảng tham chiếu các cơ sở giam giữ.';

\echo '   -> Hoàn thành tạo cấu trúc bảng tham chiếu cho national_citizen_central_server.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH TẠO CẤU TRÚC BẢNG THAM CHIẾU ***'
\echo '-> Đã tạo cấu trúc cơ bản cho các bảng trong schema "reference" trên cả 3 database.'
\echo '-> Bước tiếp theo: Nạp dữ liệu vào các bảng tham chiếu (thư mục 01_common/reference_data/).'
\echo '-> Sau đó: Chạy script 01_common/04_reference_tables_constraints.sql để thêm các ràng buộc (FK, CHECK...).'
```

**Những điểm chính:**

* **Chỉ `CREATE TABLE`:** File này chỉ chứa các lệnh `DROP TABLE IF EXISTS ... CASCADE;` và `CREATE TABLE ...` cơ bản.
* **Ràng buộc cơ bản:** Chỉ giữ lại các ràng buộc `PRIMARY KEY`, `UNIQUE` đơn giản, `NOT NULL`, và `DEFAULT` đơn giản.
* **Loại bỏ FK và CHECK phức tạp:** Các `CONSTRAINT FOREIGN KEY` và `CONSTRAINT CHECK` phức tạp đã được loại bỏ và sẽ được định nghĩa trong file `04_reference_tables_constraints.sql`.
* **Loại bỏ Index:** Các lệnh `CREATE INDEX` (bao gồm cả index GIN cho `pg_trgm`) đã được loại bỏ theo yêu cầu trước đó.
* **Chạy trên 3 DB:** Script sử dụng `\connect` để thực thi việc tạo cấu trúc trên cả 3 CSDL (BCA, BTP, TT).
* **Comment chuẩn:** Sử dụng `COMMENT ON TABLE` và `COMMENT ON COLUMN` để ghi chú thích.

File này giờ đây chỉ tập trung vào việc định nghĩa cấu trúc cột và kiểu dữ liệu của các bảng tham chi
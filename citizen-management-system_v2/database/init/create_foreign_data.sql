-- Vẫn cần chỉnh sửa lại
-- Script thiết lập Foreign Data Wrapper (FDW) để kết nối giữa các database
-- Cho phép truy cập dữ liệu giữa Bộ Công an và Bộ Tư pháp

-----------------------------------------------------------------------------------
-- 1. THIẾT LẬP FDW TỪ BỘ TƯ PHÁP ĐẾN BỘ CÔNG AN
-----------------------------------------------------------------------------------
-- Kết nối đến database Bộ Tư pháp
\connect ministry_of_justice

-- Tạo extension postgres_fdw nếu chưa tồn tại
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Tạo foreign server kết nối đến database Bộ Công an
DROP SERVER IF EXISTS public_security_server CASCADE;
CREATE SERVER public_security_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost', 
    port '5432', 
    dbname 'ministry_of_public_security'
);

-- Tạo user mapping cho người dùng quản trị
CREATE USER MAPPING FOR justice_admin
SERVER public_security_server
OPTIONS (
    user 'security_reader', 
    password 'ReaderMPS@2025'
);

-- Tạo user mapping cho người dùng đọc
CREATE USER MAPPING FOR justice_reader
SERVER public_security_server
OPTIONS (
    user 'security_reader', 
    password 'ReaderMPS@2025'
);

-- Tạo user mapping cho người dùng ghi
CREATE USER MAPPING FOR justice_writer
SERVER public_security_server
OPTIONS (
    user 'security_reader', 
    password 'ReaderMPS@2025'
);

-- Tạo user mapping cho người dùng đồng bộ
CREATE USER MAPPING FOR sync_user
SERVER public_security_server
OPTIONS (
    user 'sync_user', 
    password 'SyncData@2025'
);

-- Tạo schema để chứa foreign tables
CREATE SCHEMA IF NOT EXISTS public_security;

-- Tạo foreign table cho bảng Citizen của Bộ Công an
CREATE FOREIGN TABLE public_security.citizen (
    citizen_id VARCHAR(12),
    full_name VARCHAR(100),
    date_of_birth DATE,
    place_of_birth TEXT,
    gender TEXT,
    ethnicity_id SMALLINT,
    religion_id SMALLINT,
    nationality_id SMALLINT,
    blood_type TEXT,
    death_status TEXT,
    birth_certificate_no VARCHAR(20),
    marital_status TEXT,
    education_level_id SMALLINT,
    occupation_type_id SMALLINT,
    occupation_detail TEXT,
    tax_code VARCHAR(13),
    social_insurance_no VARCHAR(13),
    health_insurance_no VARCHAR(15),
    father_citizen_id VARCHAR(12),
    mother_citizen_id VARCHAR(12),
    region_id SMALLINT,
    province_id INT,
    avatar BYTEA,
    notes TEXT,
    status BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    geographical_region VARCHAR(20)
)
SERVER public_security_server
OPTIONS (
    schema_name 'public_security', 
    table_name 'citizen'
);

-- Tạo foreign table cho bảng IdentificationCard của Bộ Công an
CREATE FOREIGN TABLE public_security.identification_card (
    card_id SERIAL,
    citizen_id VARCHAR(12),
    card_number VARCHAR(12),
    issue_date DATE,
    expiry_date DATE,
    issuing_authority_id SMALLINT,
    card_type TEXT,
    fingerprint_left_index BYTEA,
    fingerprint_right_index BYTEA,
    chip_serial_number VARCHAR(50),
    card_status TEXT,
    previous_card_number VARCHAR(12),
    notes TEXT,
    region_id SMALLINT,
    province_id INT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    geographical_region VARCHAR(20)
)
SERVER public_security_server
OPTIONS (
    schema_name 'public_security', 
    table_name 'identification_card'
);

-- Tạo foreign table cho bảng Address của Bộ Công an
CREATE FOREIGN TABLE public_security.address (
    address_id SERIAL,
    address_detail TEXT,
    ward_id INT,
    district_id INT,
    province_id INT,
    address_type TEXT,
    postal_code VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    status BOOLEAN,
    region_id SMALLINT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    geographical_region VARCHAR(20)
)
SERVER public_security_server
OPTIONS (
    schema_name 'public_security', 
    table_name 'address'
);

-- Thêm các foreign tables khác của Bộ Công an nếu cần...

-----------------------------------------------------------------------------------
-- 2. THIẾT LẬP FDW TỪ BỘ CÔNG AN ĐẾN BỘ TƯ PHÁP
-----------------------------------------------------------------------------------
-- Kết nối đến database Bộ Công an
\connect ministry_of_public_security

-- Tạo extension postgres_fdw nếu chưa tồn tại
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Tạo foreign server kết nối đến database Bộ Tư pháp
DROP SERVER IF EXISTS justice_server CASCADE;
CREATE SERVER justice_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost', 
    port '5432', 
    dbname 'ministry_of_justice'
);

-- Tạo user mapping cho người dùng quản trị
CREATE USER MAPPING FOR security_admin
SERVER justice_server
OPTIONS (
    user 'justice_reader', 
    password 'ReaderMOJ@2025'
);

-- Tạo user mapping cho người dùng đọc
CREATE USER MAPPING FOR security_reader
SERVER justice_server
OPTIONS (
    user 'justice_reader', 
    password 'ReaderMOJ@2025'
);

-- Tạo user mapping cho người dùng ghi
CREATE USER MAPPING FOR security_writer
SERVER justice_server
OPTIONS (
    user 'justice_reader', 
    password 'ReaderMOJ@2025'
);

-- Tạo user mapping cho người dùng đồng bộ
CREATE USER MAPPING FOR sync_user
SERVER justice_server
OPTIONS (
    user 'sync_user', 
    password 'SyncData@2025'
);

-- Tạo schema để chứa foreign tables
CREATE SCHEMA IF NOT EXISTS justice;

-- Tạo foreign table cho bảng BirthCertificate của Bộ Tư pháp
CREATE FOREIGN TABLE justice.birth_certificate (
    birth_certificate_id SERIAL,
    citizen_id VARCHAR(12),
    birth_certificate_no VARCHAR(20),
    registration_date DATE,
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    issuing_authority_id SMALLINT,
    place_of_birth TEXT,
    date_of_birth DATE,
    gender_at_birth TEXT,
    father_full_name VARCHAR(100),
    father_citizen_id VARCHAR(12),
    father_date_of_birth DATE,
    father_nationality_id SMALLINT,
    mother_full_name VARCHAR(100),
    mother_citizen_id VARCHAR(12),
    mother_date_of_birth DATE,
    mother_nationality_id SMALLINT,
    declarant_name VARCHAR(100),
    declarant_citizen_id VARCHAR(12),
    declarant_relationship VARCHAR(50),
    witness1_name VARCHAR(100),
    witness2_name VARCHAR(100),
    birth_notification_no VARCHAR(50),
    status BOOLEAN,
    notes TEXT,
    region_id SMALLINT,
    province_id INT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    geographical_region VARCHAR(20)
)
SERVER justice_server
OPTIONS (
    schema_name 'justice', 
    table_name 'birth_certificate'
);

-- Tạo foreign table cho bảng Marriage của Bộ Tư pháp
CREATE FOREIGN TABLE justice.marriage (
    marriage_id SERIAL,
    marriage_certificate_no VARCHAR(20),
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    husband_id VARCHAR(12),
    husband_full_name VARCHAR(100),
    husband_date_of_birth DATE,
    husband_nationality_id SMALLINT,
    husband_previous_marriage_status TEXT,
    wife_id VARCHAR(12),
    wife_full_name VARCHAR(100),
    wife_date_of_birth DATE,
    wife_nationality_id SMALLINT,
    wife_previous_marriage_status TEXT,
    marriage_date DATE,
    registration_date DATE,
    issuing_authority_id SMALLINT,
    issuing_place TEXT,
    witness1_name VARCHAR(100),
    witness2_name VARCHAR(100),
    status BOOLEAN,
    notes TEXT,
    region_id SMALLINT,
    province_id INT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    geographical_region VARCHAR(20)
)
SERVER justice_server
OPTIONS (
    schema_name 'justice', 
    table_name 'marriage'
);

-- Tạo foreign table cho bảng Household của Bộ Tư pháp
CREATE FOREIGN TABLE justice.household (
    household_id SERIAL,
    household_book_no VARCHAR(20),
    head_of_household_id VARCHAR(12),
    address_id INT,
    registration_date DATE,
    issuing_authority_id SMALLINT,
    area_code VARCHAR(10),
    household_type VARCHAR(50),
    status BOOLEAN,
    notes TEXT,
    region_id SMALLINT,
    province_id INT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    geographical_region VARCHAR(20)
)
SERVER justice_server
OPTIONS (
    schema_name 'justice', 
    table_name 'household'
);

-- Thêm các foreign tables khác của Bộ Tư pháp nếu cần...

-----------------------------------------------------------------------------------
-- 3. THIẾT LẬP FDW TỪ MÁY CHỦ TRUNG TÂM ĐẾN CẢ HAI BỘ
-----------------------------------------------------------------------------------
-- Kết nối đến database máy chủ trung tâm
\connect national_citizen_central_server

-- Tạo extension postgres_fdw nếu chưa tồn tại
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Tạo foreign server kết nối đến database Bộ Công an
DROP SERVER IF EXISTS public_security_server CASCADE;
CREATE SERVER public_security_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost', 
    port '5432', 
    dbname 'ministry_of_public_security'
);

-- Tạo foreign server kết nối đến database Bộ Tư pháp
DROP SERVER IF EXISTS justice_server CASCADE;
CREATE SERVER justice_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost', 
    port '5432', 
    dbname 'ministry_of_justice'
);

-- Tạo user mapping cho máy chủ trung tâm đến Bộ Công an
CREATE USER MAPPING FOR central_server_admin
SERVER public_security_server
OPTIONS (
    user 'security_reader', 
    password 'ReaderMPS@2025'
);

-- Tạo user mapping cho máy chủ trung tâm đến Bộ Tư pháp
CREATE USER MAPPING FOR central_server_admin
SERVER justice_server
OPTIONS (
    user 'justice_reader', 
    password 'ReaderMOJ@2025'
);

-- Tạo user mapping cho người dùng đồng bộ
CREATE USER MAPPING FOR sync_user
SERVER public_security_server
OPTIONS (
    user 'sync_user', 
    password 'SyncData@2025'
);

CREATE USER MAPPING FOR sync_user
SERVER justice_server
OPTIONS (
    user 'sync_user', 
    password 'SyncData@2025'
);

-- Tạo các schema để chứa foreign tables
CREATE SCHEMA IF NOT EXISTS public_security;
CREATE SCHEMA IF NOT EXISTS justice;

-- Tạo foreign table cho các bảng cần thiết từ Bộ Công an
CREATE FOREIGN TABLE public_security.citizen (
    citizen_id VARCHAR(12),
    full_name VARCHAR(100),
    date_of_birth DATE,
    place_of_birth TEXT,
    gender TEXT,
    -- Các trường khác...
    region_id SMALLINT,
    province_id INT,
    geographical_region VARCHAR(20)
)
SERVER public_security_server
OPTIONS (
    schema_name 'public_security', 
    table_name 'citizen'
);

-- Tạo foreign table cho các bảng cần thiết từ Bộ Tư pháp
CREATE FOREIGN TABLE justice.birth_certificate (
    birth_certificate_id SERIAL,
    citizen_id VARCHAR(12),
    birth_certificate_no VARCHAR(20),
    -- Các trường khác...
    region_id SMALLINT,
    province_id INT,
    geographical_region VARCHAR(20)
)
SERVER justice_server
OPTIONS (
    schema_name 'justice', 
    table_name 'birth_certificate'
);

-- Thêm các foreign tables khác nếu cần...

-- Tạo các views tích hợp để kết hợp dữ liệu từ cả hai bộ
CREATE OR REPLACE VIEW central.citizen_complete_info AS
SELECT 
    c.citizen_id,
    c.full_name,
    c.date_of_birth,
    c.place_of_birth,
    c.gender,
    bc.birth_certificate_no,
    bc.registration_date AS birth_registration_date,
    (SELECT m.marriage_certificate_no FROM justice.marriage m WHERE m.husband_id = c.citizen_id OR m.wife_id = c.citizen_id ORDER BY m.marriage_date DESC LIMIT 1) AS latest_marriage_certificate,
    c.geographical_region,
    c.region_id,
    c.province_id
FROM 
    public_security.citizen c
LEFT JOIN 
    justice.birth_certificate bc ON c.citizen_id = bc.citizen_id;

\echo 'Đã thiết lập xong Foreign Data Wrappers (FDW) giữa các database'
\echo 'Đã tạo Foreign Tables trên từng database'
\echo 'Đã tạo View tích hợp dữ liệu từ nhiều nguồn trên máy chủ trung tâm'
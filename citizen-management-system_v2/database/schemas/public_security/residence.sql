-- Tạo bảng Citizen (Công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia
-- Áp dụng nguyên tắc FDW: Bảng chỉ được tạo ở database chủ quản (Bộ Công An)

\echo 'Tạo các bảng quản lý cư trú...'

-- Kết nối đến database Bộ Công An (database chủ quản cho dữ liệu cư trú)
\connect ministry_of_public_security

BEGIN;
-- Xóa bảng nếu đã tồn tại để tạo lại
DROP TABLE IF EXISTS public_security.address CASCADE;
DROP TABLE IF EXISTS public_security.citizen_address CASCADE;
DROP TABLE IF EXISTS public_security.permanent_residence CASCADE;
DROP TABLE IF EXISTS public_security.temporary_residence CASCADE;
DROP TABLE IF EXISTS public_security.temporary_absence CASCADE;
-- Tạo các bảng cho quản lý cư trú
-- =============================================================================
-- 1. Bảng Address (Địa chỉ)
CREATE TABLE IF NOT EXISTS public_security.address (
    address_id SERIAL PRIMARY KEY,
    address_detail TEXT NOT NULL,
    ward_id INT,                    -- FK to: Ward
    district_id INT,                -- FK to: District
    province_id INT,                -- FK to: Province
    address_type address_type,
    postal_code VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    status BOOLEAN DEFAULT TRUE,
    region_id SMALLINT,             -- FK to: Region
    data_sensitivity_level data_sensitivity_level DEFAULT 'Công khai',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng CitizenAddress (Địa chỉ công dân)
CREATE TABLE IF NOT EXISTS public_security.citizen_address (
    citizen_address_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL, -- FK to: Citizen
    address_id INT NOT NULL,         -- FK to: Address
    address_type address_type NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE,
    status BOOLEAN DEFAULT TRUE,
    registration_document_no VARCHAR(50),
    issuing_authority_id SMALLINT,   -- FK to: Authority
    region_id SMALLINT,              -- FK to: Region
    province_id INT,                 -- FK to: Province
    data_sensitivity_level data_sensitivity_level DEFAULT 'Công khai',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bảng PermanentResidence (Đăng ký thường trú)
CREATE TABLE IF NOT EXISTS public_security.permanent_residence (
    permanent_residence_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,  -- FK to: Citizen
    address_id INT NOT NULL,          -- FK to: Address
    registration_date DATE NOT NULL,
    decision_no VARCHAR(50),
    issuing_authority_id SMALLINT,    -- FK to: Authority
    previous_address_id INT,          -- FK to: Address
    change_reason TEXT,
    status BOOLEAN DEFAULT TRUE,
    region_id SMALLINT,               -- FK to: Region
    province_id INT,                  -- FK to: Province
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng TemporaryResidence (Đăng ký tạm trú)
CREATE TABLE IF NOT EXISTS public_security.temporary_residence (
    temporary_residence_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,   -- FK to: Citizen
    address_id INT NOT NULL,           -- FK to: Address
    registration_date DATE NOT NULL,
    expiry_date DATE,
    purpose TEXT,
    issuing_authority_id SMALLINT,     -- FK to: Authority
    registration_number VARCHAR(50),
    status BOOLEAN DEFAULT TRUE,
    permanent_address_id INT,          -- FK to: Address
    host_name VARCHAR(100),
    host_citizen_id VARCHAR(12),       -- FK to: Citizen
    host_relationship VARCHAR(50),
    region_id SMALLINT,                -- FK to: Region
    province_id INT,                   -- FK to: Province
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Bảng TemporaryAbsence (Đăng ký tạm vắng)
CREATE TABLE IF NOT EXISTS public_security.temporary_absence (
    temporary_absence_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,    -- FK to: Citizen
    from_date DATE NOT NULL,
    to_date DATE,
    reason TEXT,
    destination_address_id INT,         -- FK to: Address
    destination_detail TEXT,
    contact_information TEXT,
    registration_authority_id SMALLINT, -- FK to: Authority
    registration_number VARCHAR(50),
    status BOOLEAN DEFAULT TRUE,
    region_id SMALLINT,                -- FK to: Region
    province_id INT,                   -- FK to: Province
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Ghi chú:
-- 1. Các bảng được tạo một lần duy nhất tại database chủ quản (Bộ Công An)
-- 2. Các database khác sẽ truy cập thông qua Foreign Data Wrapper (FDW)
-- 3. TODO: Tạo các chỉ mục (INDEX) riêng trong file indexes.sql
-- 4. TODO: Tạo các ràng buộc khóa ngoại (FOREIGN KEY) trong file constraints.sql
-- 5. TODO: Tạo các trigger và bảng CDC trong file triggers.sql
-- 6. TODO: Thiết lập FDW cho các database khác trong file fdw_setup.sql

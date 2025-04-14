-- citizen.sql
-- Tạo bảng Citizen (Công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database bộ quản lý
\echo 'Tạo các bảng cư trú cho các database bộ quản lý...'

\connect ministry_of_public_security

CREATE OR REPLACE FUNCTION create_residence_tables() RETURNS void AS $$
BEGIN
    -- 1. Bảng Address (Địa chỉ)
    CREATE TABLE IF NOT EXISTS public_security.address (
        address_id SERIAL PRIMARY KEY,
        address_detail TEXT NOT NULL,
        ward_id INT,
        district_id INT,
        province_id INT,
        address_type address_type,
        postal_code VARCHAR(10),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 2. Bảng CitizenAddress (Địa chỉ công dân)
    CREATE TABLE IF NOT EXISTS public_security.citizen_address (
        citizen_address_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        address_type address_type NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        status BOOLEAN DEFAULT TRUE,
        registration_document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 3. Bảng PermanentResidence (Đăng ký thường trú)
    CREATE TABLE IF NOT EXISTS public_security.permanent_residence (
        permanent_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        decision_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        previous_address_id INT,
        change_reason TEXT,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 4. Bảng TemporaryResidence (Đăng ký tạm trú)
    CREATE TABLE IF NOT EXISTS public_security.temporary_residence (
        temporary_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        expiry_date DATE,
        purpose TEXT,
        issuing_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        permanent_address_id INT,
        host_name VARCHAR(100),
        host_citizen_id VARCHAR(12),
        host_relationship VARCHAR(50),
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 5. Bảng TemporaryAbsence (Đăng ký tạm vắng)
    CREATE TABLE IF NOT EXISTS public_security.temporary_absence (
        temporary_absence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        reason TEXT,
        destination_address_id INT,
        destination_detail TEXT,
        contact_information TEXT,
        registration_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_residence_tables();
\echo 'Đã tạo các bảng quản lý cư trú cho database BCA'

-- Kết nối đến database bộ tư pháp
\connect ministry_of_justice

CREATE OR REPLACE FUNCTION create_residence_tables() RETURNS void AS $$
BEGIN
    -- 1. Bảng Address (Địa chỉ)
    CREATE TABLE IF NOT EXISTS public_security.address (
        address_id SERIAL PRIMARY KEY,
        address_detail TEXT NOT NULL,
        ward_id INT,
        district_id INT,
        province_id INT,
        address_type address_type,
        postal_code VARCHAR(10),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 2. Bảng CitizenAddress (Địa chỉ công dân)
    CREATE TABLE IF NOT EXISTS public_security.citizen_address (
        citizen_address_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        address_type address_type NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        status BOOLEAN DEFAULT TRUE,
        registration_document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 3. Bảng PermanentResidence (Đăng ký thường trú)
    CREATE TABLE IF NOT EXISTS public_security.permanent_residence (
        permanent_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        decision_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        previous_address_id INT,
        change_reason TEXT,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 4. Bảng TemporaryResidence (Đăng ký tạm trú)
    CREATE TABLE IF NOT EXISTS public_security.temporary_residence (
        temporary_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        expiry_date DATE,
        purpose TEXT,
        issuing_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        permanent_address_id INT,
        host_name VARCHAR(100),
        host_citizen_id VARCHAR(12),
        host_relationship VARCHAR(50),
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 5. Bảng TemporaryAbsence (Đăng ký tạm vắng)
    CREATE TABLE IF NOT EXISTS public_security.temporary_absence (
        temporary_absence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        reason TEXT,
        destination_address_id INT,
        destination_detail TEXT,
        contact_information TEXT,
        registration_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_residence_tables();
\echo 'Đã tạo các bảng quản lý cư trú cho database BTP'

-- Kết nối đến database máy chủ trung tâm
\connect national_citizen_central_server

CREATE OR REPLACE FUNCTION create_residence_tables() RETURNS void AS $$
BEGIN
    -- 1. Bảng Address (Địa chỉ)
    CREATE TABLE IF NOT EXISTS public_security.address (
        address_id SERIAL PRIMARY KEY,
        address_detail TEXT NOT NULL,
        ward_id INT,
        district_id INT,
        province_id INT,
        address_type address_type,
        postal_code VARCHAR(10),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 2. Bảng CitizenAddress (Địa chỉ công dân)
    CREATE TABLE IF NOT EXISTS public_security.citizen_address (
        citizen_address_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        address_type address_type NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        status BOOLEAN DEFAULT TRUE,
        registration_document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 3. Bảng PermanentResidence (Đăng ký thường trú)
    CREATE TABLE IF NOT EXISTS public_security.permanent_residence (
        permanent_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        decision_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        previous_address_id INT,
        change_reason TEXT,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 4. Bảng TemporaryResidence (Đăng ký tạm trú)
    CREATE TABLE IF NOT EXISTS public_security.temporary_residence (
        temporary_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        expiry_date DATE,
        purpose TEXT,
        issuing_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        permanent_address_id INT,
        host_name VARCHAR(100),
        host_citizen_id VARCHAR(12),
        host_relationship VARCHAR(50),
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 5. Bảng TemporaryAbsence (Đăng ký tạm vắng)
    CREATE TABLE IF NOT EXISTS public_security.temporary_absence (
        temporary_absence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        reason TEXT,
        destination_address_id INT,
        destination_detail TEXT,
        contact_information TEXT,
        registration_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_residence_tables();
\echo 'Đã tạo các bảng quản lý cư trú cho database máy chủ'

-- Tạo bảng CriminalRecord (Hồ sơ phạm nhân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database bộ ngành và tạo bảng
\echo 'Tạo bảng CriminalRecord cho các database bộ ngành...'

\connect ministry_of_public_security

-- Hàm tạo bảng CriminalRecord
CREATE OR REPLACE FUNCTION create_criminal_record_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CriminalRecord trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.criminal_record (
        record_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        crime_type VARCHAR(100) NOT NULL,
        crime_date DATE NOT NULL,
        court_name VARCHAR(200) NOT NULL,
        sentence_date DATE NOT NULL,
        sentence_length VARCHAR(100) NOT NULL, -- "5 năm", "Chung thân"
        prison_facility_id INT,
        prison_facility_name VARCHAR(200),
        release_date DATE,
        status VARCHAR(50) NOT NULL, -- Đang thụ án/Đã mãn hạn/Ân xá
        decision_number VARCHAR(50) NOT NULL,
        decision_date DATE NOT NULL,
        note TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_criminal_record_table();
\echo 'Đã tạo bảng CriminalRecord cho database BCA'

-- Kết nối đến database bộ tư pháp
\connect ministry_of_justice

-- Hàm tạo bảng CriminalRecord
CREATE OR REPLACE FUNCTION create_criminal_record_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CriminalRecord trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.criminal_record (
        record_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        crime_type VARCHAR(100) NOT NULL,
        crime_date DATE NOT NULL,
        court_name VARCHAR(200) NOT NULL,
        sentence_date DATE NOT NULL,
        sentence_length VARCHAR(100) NOT NULL, -- "5 năm", "Chung thân"
        prison_facility_id INT,
        prison_facility_name VARCHAR(200),
        release_date DATE,
        status VARCHAR(50) NOT NULL, -- Đang thụ án/Đã mãn hạn/Ân xá
        decision_number VARCHAR(50) NOT NULL,
        decision_date DATE NOT NULL,
        note TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_criminal_record_table();
\echo 'Đã tạo bảng CriminalRecord cho database BTP'

-- Kết nối đến database máy chủ trung tâm
\connect national_citizen_central_server

-- Hàm tạo bảng CriminalRecord
CREATE OR REPLACE FUNCTION create_criminal_record_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CriminalRecord trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.criminal_record (
        record_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        crime_type VARCHAR(100) NOT NULL,
        crime_date DATE NOT NULL,
        court_name VARCHAR(200) NOT NULL,
        sentence_date DATE NOT NULL,
        sentence_length VARCHAR(100) NOT NULL, -- "5 năm", "Chung thân"
        prison_facility_id INT,
        prison_facility_name VARCHAR(200),
        release_date DATE,
        status VARCHAR(50) NOT NULL, -- Đang thụ án/Đã mãn hạn/Ân xá
        decision_number VARCHAR(50) NOT NULL,
        decision_date DATE NOT NULL,
        note TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_criminal_record_table();
\echo 'Đã tạo bảng CriminalRecord cho database máy chủ'
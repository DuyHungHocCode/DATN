-- Tạo bảng IdentificationCard (Căn cước công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng IdentificationCard cho các database bộ ngành...'

-- Kết nối đến database miền Bắc
\connect ministry_of_public_security
-- Hàm tạo bảng IdentificationCard

CREATE OR REPLACE FUNCTION create_identification_card_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng IdentificationCard trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.identification_card (
        card_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        card_number VARCHAR(12) NOT NULL UNIQUE,
        issue_date DATE NOT NULL,
        expiry_date DATE,
        issuing_authority_id SMALLINT,
        card_type card_type NOT NULL,
        fingerprint_left_index BYTEA,
        fingerprint_right_index BYTEA,
        fingerprint_left_thumb BYTEA,
        fingerprint_right_thumb BYTEA,
        facial_biometric BYTEA,
        iris_data BYTEA,
        chip_serial_number VARCHAR(50),
        card_status card_status NOT NULL DEFAULT 'Đang sử dụng',
        previous_card_number VARCHAR(12),
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_active_card UNIQUE (citizen_id, card_status)
        DEFERRABLE INITIALLY DEFERRED -- Cho phép tạm thời vi phạm ràng buộc trong cùng giao dịch
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_identification_card_table();
\echo 'Đã tạo bảng IdentificationCard cho database BCA'

-- Kết nối đến database BTP
\connect ministry_of_justice

CREATE OR REPLACE FUNCTION create_identification_card_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng IdentificationCard trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.identification_card (
        card_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        card_number VARCHAR(12) NOT NULL UNIQUE,
        issue_date DATE NOT NULL,
        expiry_date DATE,
        issuing_authority_id SMALLINT,
        card_type card_type NOT NULL,
        fingerprint_left_index BYTEA,
        fingerprint_right_index BYTEA,
        fingerprint_left_thumb BYTEA,
        fingerprint_right_thumb BYTEA,
        facial_biometric BYTEA,
        iris_data BYTEA,
        chip_serial_number VARCHAR(50),
        card_status card_status NOT NULL DEFAULT 'Đang sử dụng',
        previous_card_number VARCHAR(12),
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_active_card UNIQUE (citizen_id, card_status)
        DEFERRABLE INITIALLY DEFERRED -- Cho phép tạm thời vi phạm ràng buộc trong cùng giao dịch
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_identification_card_table();
\echo 'Đã tạo bảng IdentificationCard cho database BTP'

-- Kết nối đến database máy chủ trung tâm
\connect national_citizen_central_server
CREATE OR REPLACE FUNCTION create_identification_card_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng IdentificationCard trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.identification_card (
        card_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        card_number VARCHAR(12) NOT NULL UNIQUE,
        issue_date DATE NOT NULL,
        expiry_date DATE,
        issuing_authority_id SMALLINT,
        card_type card_type NOT NULL,
        fingerprint_left_index BYTEA,
        fingerprint_right_index BYTEA,
        fingerprint_left_thumb BYTEA,
        fingerprint_right_thumb BYTEA,
        facial_biometric BYTEA,
        iris_data BYTEA,
        chip_serial_number VARCHAR(50),
        card_status card_status NOT NULL DEFAULT 'Đang sử dụng',
        previous_card_number VARCHAR(12),
        notes TEXT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_active_card UNIQUE (citizen_id, card_status)
        DEFERRABLE INITIALLY DEFERRED -- Cho phép tạm thời vi phạm ràng buộc trong cùng giao dịch
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_identification_card_table();
\echo 'Đã tạo bảng IdentificationCard cho database máy chủ trung tâm'


-- =============================================================================
-- File: ministry_of_public_security/01_tables_structure.sql
-- Description: Tạo cấu trúc cơ bản (CREATE TABLE) cho TẤT CẢ các bảng
--              trong database Bộ Công an (ministry_of_public_security).
-- Version: 3.1 (Structure only, constraints/indexes deferred)
--
-- Lưu ý:
-- - Chỉ định nghĩa cột, kiểu dữ liệu, NOT NULL, DEFAULT đơn giản, PRIMARY KEY, UNIQUE.
-- - KHÔNG định nghĩa FOREIGN KEY, CHECK phức tạp, INDEX truy vấn ở đây.
-- - Các ràng buộc và index sẽ được thêm trong file 02_tables_constraints.sql
--   và/hoặc partitioning_setup.sql.
--
-- Yêu cầu: Chạy sau khi đã tạo database, schema và các ENUM cần thiết.
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO CẤU TRÚC BẢNG CHO DATABASE BỘ CÔNG AN ***'
\connect ministry_of_public_security

-- === Schema: public_security ===

\echo '[1] Tạo cấu trúc bảng trong schema: public_security...'

-- Bảng: citizen (Công dân) - Phân vùng theo địa lý
DROP TABLE IF EXISTS public_security.citizen CASCADE;
CREATE TABLE public_security.citizen (
    -- Thông tin định danh
    citizen_id VARCHAR(12) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    place_of_birth_code VARCHAR(10),
    place_of_birth_detail TEXT,
    gender gender_type NOT NULL,
    blood_type blood_type,
    -- Nhân khẩu học
    ethnicity_id SMALLINT,
    religion_id SMALLINT,
    nationality_id SMALLINT NOT NULL DEFAULT 1,
    -- Gia đình
    father_citizen_id VARCHAR(12),
    mother_citizen_id VARCHAR(12),
    -- Học vấn, Nghề nghiệp
    education_level education_level,
    occupation_id SMALLINT,
    occupation_detail TEXT,
    -- Xã hội
    tax_code VARCHAR(13), -- UNIQUE sẽ thêm sau
    social_insurance_no VARCHAR(13), -- UNIQUE sẽ thêm sau
    health_insurance_no VARCHAR(15), -- UNIQUE sẽ thêm sau
    -- Liên hệ
    current_email VARCHAR(100),
    current_phone_number VARCHAR(15),
    -- Phân vùng
    region_id SMALLINT,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_citizen PRIMARY KEY (citizen_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.citizen IS '[BCA] Bảng trung tâm lưu trữ thông tin cơ bản của công dân.';
COMMENT ON COLUMN public_security.citizen.citizen_id IS 'Số định danh cá nhân (CCCD 12 số) - Khóa chính logic.';
COMMENT ON COLUMN public_security.citizen.geographical_region IS 'Vùng địa lý (Bắc, Trung, Nam) - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.citizen.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.citizen.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: address (Địa chỉ) - Phân vùng theo địa lý
DROP TABLE IF EXISTS public_security.address CASCADE;
CREATE TABLE public_security.address (
    address_id SERIAL NOT NULL,
    address_detail TEXT NOT NULL,
    ward_id INT NOT NULL,
    -- Phân vùng
    district_id INT NOT NULL,
    province_id INT NOT NULL,
    region_id SMALLINT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Thông tin thêm
    postal_code VARCHAR(10),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    -- geometry geometry(Point, 4326), -- Nếu dùng PostGIS
    status BOOLEAN DEFAULT TRUE,
    notes TEXT,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_address PRIMARY KEY (address_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.address IS '[BCA] Lưu trữ thông tin chi tiết về các địa chỉ hành chính.';
COMMENT ON COLUMN public_security.address.address_id IS 'ID tự tăng duy nhất cho mỗi địa chỉ.';
COMMENT ON COLUMN public_security.address.geographical_region IS 'Vùng địa lý (Bắc, Trung, Nam) - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.address.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.address.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: identification_card (CCCD/CMND) - Phân vùng theo địa lý
DROP TABLE IF EXISTS public_security.identification_card CASCADE;
CREATE TABLE public_security.identification_card (
    id_card_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    card_number VARCHAR(12) NOT NULL, -- UNIQUE sẽ thêm sau
    card_type card_type NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE,
    issuing_authority_id SMALLINT NOT NULL,
    issuing_place TEXT,
    card_status card_status DEFAULT 'Đang sử dụng',
    previous_card_number VARCHAR(12),
    biometric_data BYTEA,
    chip_id VARCHAR(50), -- UNIQUE sẽ thêm sau (nếu cần)
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_identification_card PRIMARY KEY (id_card_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.identification_card IS '[BCA] Lưu trữ thông tin về các thẻ CCCD/CMND.';
COMMENT ON COLUMN public_security.identification_card.card_number IS 'Số thẻ CCCD/CMND (Cần kiểm tra unique ở tầng ứng dụng/trigger).';
COMMENT ON COLUMN public_security.identification_card.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.identification_card.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.identification_card.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: permanent_residence (Thường trú) - Phân vùng theo địa lý
DROP TABLE IF EXISTS public_security.permanent_residence CASCADE;
CREATE TABLE public_security.permanent_residence (
    permanent_residence_id SERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    address_id INT NOT NULL,
    registration_date DATE NOT NULL,
    decision_no VARCHAR(50) NOT NULL,
    issuing_authority_id SMALLINT NOT NULL,
    previous_address_id INT,
    change_reason TEXT,
    document_url VARCHAR(255),
    status BOOLEAN DEFAULT TRUE,
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_permanent_residence PRIMARY KEY (permanent_residence_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.permanent_residence IS '[BCA] Lưu trữ thông tin đăng ký thường trú của công dân.';
COMMENT ON COLUMN public_security.permanent_residence.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.permanent_residence.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.permanent_residence.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: temporary_residence (Tạm trú) - Phân vùng theo địa lý
DROP TABLE IF EXISTS public_security.temporary_residence CASCADE;
CREATE TABLE public_security.temporary_residence (
    temporary_residence_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    address_id INT NOT NULL,
    registration_date DATE NOT NULL,
    expiry_date DATE,
    purpose VARCHAR(200) NOT NULL,
    registration_number VARCHAR(50) NOT NULL, -- UNIQUE sẽ thêm sau
    issuing_authority_id SMALLINT NOT NULL,
    permanent_address_id INT,
    host_name VARCHAR(100),
    host_citizen_id VARCHAR(12),
    host_relationship VARCHAR(50),
    document_url VARCHAR(255),
    extension_count SMALLINT DEFAULT 0,
    last_extension_date DATE,
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh',
    verification_date DATE,
    verified_by VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Active', -- CHECK constraint sẽ thêm sau
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_temporary_residence PRIMARY KEY (temporary_residence_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.temporary_residence IS '[BCA] Lưu thông tin đăng ký tạm trú của công dân.';
COMMENT ON COLUMN public_security.temporary_residence.registration_number IS 'Số sổ/giấy đăng ký tạm trú (Cần kiểm tra unique).';
COMMENT ON COLUMN public_security.temporary_residence.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.temporary_residence.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.temporary_residence.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: temporary_absence (Tạm vắng) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS public_security.temporary_absence CASCADE;
CREATE TABLE public_security.temporary_absence (
    temporary_absence_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE,
    reason TEXT NOT NULL,
    destination_address_id INT,
    destination_detail TEXT,
    contact_information TEXT,
    registration_authority_id SMALLINT,
    registration_number VARCHAR(50), -- UNIQUE sẽ thêm sau (nếu cần)
    document_url VARCHAR(255),
    return_date DATE,
    return_confirmed BOOLEAN DEFAULT FALSE,
    return_confirmed_by VARCHAR(100),
    return_confirmed_date DATE,
    return_notes TEXT,
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh',
    verification_date DATE,
    verified_by VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Active', -- CHECK constraint sẽ thêm sau
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_temporary_absence PRIMARY KEY (temporary_absence_id, geographical_region, province_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.temporary_absence IS '[BCA] Lưu thông tin đăng ký tạm vắng của công dân.';
COMMENT ON COLUMN public_security.temporary_absence.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.temporary_absence.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

-- Bảng: citizen_status (Lịch sử trạng thái) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS public_security.citizen_status CASCADE;
CREATE TABLE public_security.citizen_status (
    status_id SERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    status_type death_status NOT NULL DEFAULT 'Còn sống',
    status_date DATE NOT NULL,
    description TEXT,
    cause VARCHAR(200),
    location VARCHAR(200),
    authority_id SMALLINT,
    document_number VARCHAR(50),
    document_date DATE,
    certificate_id VARCHAR(50),
    reported_by VARCHAR(100),
    relationship VARCHAR(50),
    verification_status VARCHAR(50) DEFAULT 'Chưa xác minh',
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_citizen_status PRIMARY KEY (status_id, geographical_region, province_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.citizen_status IS '[BCA] Lưu trữ lịch sử thay đổi trạng thái của công dân (Còn sống, Đã mất, Mất tích).';
COMMENT ON COLUMN public_security.citizen_status.is_current IS 'TRUE nếu đây là bản ghi trạng thái mới nhất và đang có hiệu lực.';
COMMENT ON COLUMN public_security.citizen_status.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.citizen_status.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

-- Bảng: citizen_movement (Di biến động) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS public_security.citizen_movement CASCADE;
CREATE TABLE public_security.citizen_movement (
    movement_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    movement_type movement_type NOT NULL,
    from_address_id INT,
    to_address_id INT,
    from_country_id SMALLINT,
    to_country_id SMALLINT,
    departure_date DATE NOT NULL,
    arrival_date DATE,
    purpose VARCHAR(255),
    document_no VARCHAR(50),
    document_type VARCHAR(50),
    document_issue_date DATE,
    document_expiry_date DATE,
    carrier VARCHAR(100),
    border_checkpoint VARCHAR(150),
    description TEXT,
    status VARCHAR(50) DEFAULT 'Hoạt động' NOT NULL, -- CHECK constraint sẽ thêm sau
    -- Phân vùng
    source_region_id SMALLINT,
    target_region_id SMALLINT,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_citizen_movement PRIMARY KEY (movement_id, geographical_region, province_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.citizen_movement IS '[BCA] Lưu trữ thông tin về các lần di biến động (trong nước, xuất nhập cảnh) của công dân.';
COMMENT ON COLUMN public_security.citizen_movement.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.citizen_movement.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

-- Bảng: criminal_record (Tiền án, tiền sự) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS public_security.criminal_record CASCADE;
CREATE TABLE public_security.criminal_record (
    record_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    crime_type criminal_record_type NOT NULL,
    crime_description TEXT,
    crime_date DATE NOT NULL,
    court_name VARCHAR(200) NOT NULL,
    sentence_date DATE NOT NULL,
    sentence_length VARCHAR(100) NOT NULL,
    sentence_details TEXT,
    prison_facility_id INTEGER,
    entry_date DATE,
    release_date DATE,
    execution_status VARCHAR(50) NOT NULL DEFAULT 'Đã thi hành xong',
    decision_number VARCHAR(50) NOT NULL, -- UNIQUE sẽ thêm sau
    decision_date DATE NOT NULL,
    note TEXT,
    -- Phân vùng
    region_id SMALLINT,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata & Bảo mật
    data_sensitivity_level data_sensitivity_level DEFAULT 'Bảo mật',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_criminal_record PRIMARY KEY (record_id, geographical_region, province_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.criminal_record IS '[BCA] Lưu trữ thông tin về tiền án, tiền sự của công dân.';
COMMENT ON COLUMN public_security.criminal_record.decision_number IS 'Số bản án hoặc quyết định của tòa án (Cần kiểm tra unique).';
COMMENT ON COLUMN public_security.criminal_record.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.criminal_record.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

-- Bảng: digital_identity (Định danh điện tử - VNeID) - Không phân vùng
DROP TABLE IF EXISTS public_security.digital_identity CASCADE;
CREATE TABLE public_security.digital_identity (
    digital_identity_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL, -- UNIQUE sẽ thêm sau (khi status=TRUE)
    digital_id VARCHAR(50) NOT NULL UNIQUE,
    activation_date TIMESTAMP WITH TIME ZONE NOT NULL,
    verification_level verification_level NOT NULL,
    status BOOLEAN NOT NULL DEFAULT TRUE,
    device_info JSONB,
    last_login_date TIMESTAMP WITH TIME ZONE,
    last_login_ip VARCHAR(45),
    otp_method VARCHAR(50) DEFAULT 'SMS',
    phone_number VARCHAR(15),
    email VARCHAR(100),
    security_question_hash TEXT,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);
COMMENT ON TABLE public_security.digital_identity IS '[BCA] Lưu trữ thông tin về tài khoản định danh điện tử (VNeID) của công dân.';
COMMENT ON COLUMN public_security.digital_identity.digital_id IS 'Mã định danh điện tử duy nhất do hệ thống VNeID cấp.';
COMMENT ON COLUMN public_security.digital_identity.verification_level IS 'Mức độ xác thực tài khoản (Mức 1, Mức 2).';

-- Bảng: user_account (Tài khoản hệ thống) - Không phân vùng
DROP TABLE IF EXISTS public_security.user_account CASCADE;
CREATE TABLE public_security.user_account (
    user_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL UNIQUE, -- Mỗi cán bộ/quản trị chỉ có 1 tài khoản
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type user_type NOT NULL, -- CHECK constraint sẽ thêm sau
    status VARCHAR(20) NOT NULL DEFAULT 'Active', -- CHECK constraint sẽ thêm sau
    last_login_date TIMESTAMP WITH TIME ZONE,
    last_login_ip VARCHAR(45),
    failed_login_attempts SMALLINT DEFAULT 0,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret TEXT,
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(15) UNIQUE,
    locked_until TIMESTAMP WITH TIME ZONE,
    verification_token TEXT,
    verification_token_expires TIMESTAMP WITH TIME ZONE,
    password_reset_token TEXT,
    password_reset_expires TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE public_security.user_account IS '[BCA] Quản lý tài khoản đăng nhập hệ thống cho Cán bộ và Quản trị viên.';
COMMENT ON COLUMN public_security.user_account.password_hash IS 'Hash mật khẩu đã được mã hóa an toàn (vd: bcrypt).';
COMMENT ON COLUMN public_security.user_account.user_type IS 'Loại tài khoản (Chỉ Cán bộ hoặc Quản trị viên).';

-- Bảng: citizen_address (Liên kết Công dân - Địa chỉ) - Phân vùng theo địa lý
DROP TABLE IF EXISTS public_security.citizen_address CASCADE;
CREATE TABLE public_security.citizen_address (
    citizen_address_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    address_id INTEGER NOT NULL,
    address_type address_type NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE,
    is_primary BOOLEAN DEFAULT FALSE, -- UNIQUE constraint sẽ thêm sau
    status BOOLEAN DEFAULT TRUE,
    registration_document_no VARCHAR(50),
    registration_date DATE,
    issuing_authority_id INTEGER,
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh',
    verification_date DATE,
    verified_by VARCHAR(100),
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INTEGER NOT NULL,
    district_id INTEGER NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_citizen_address PRIMARY KEY (citizen_address_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE public_security.citizen_address IS '[BCA] Bảng liên kết giữa công dân và địa chỉ theo thời gian, loại địa chỉ.';
COMMENT ON COLUMN public_security.citizen_address.is_primary IS 'Đánh dấu địa chỉ chính cho loại địa chỉ tương ứng (vd: 1 thường trú chính).';
COMMENT ON COLUMN public_security.citizen_address.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.citizen_address.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.citizen_address.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

\echo '   -> Hoàn thành tạo cấu trúc bảng schema public_security.'

-- === Schema: audit ===

\echo '[2] Tạo cấu trúc bảng trong schema: audit...'

-- Bảng: audit_log (Nhật ký thay đổi) - Phân vùng theo thời gian
DROP TABLE IF EXISTS audit.audit_log CASCADE;
CREATE TABLE audit.audit_log (
    log_id BIGSERIAL NOT NULL,
    action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(), -- Cột phân vùng
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation cdc_operation_type NOT NULL,
    session_user_name TEXT DEFAULT current_user,
    application_name TEXT DEFAULT current_setting('application_name'),
    client_addr INET DEFAULT inet_client_addr(),
    client_port INTEGER DEFAULT inet_client_port(),
    transaction_id BIGINT DEFAULT txid_current(),
    statement_only BOOLEAN NOT NULL DEFAULT FALSE,
    row_data JSONB,
    changed_fields JSONB,
    query TEXT,
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_audit_log PRIMARY KEY (log_id, action_tstamp)
) PARTITION BY RANGE (action_tstamp);
COMMENT ON TABLE audit.audit_log IS '[BCA] Bảng ghi nhật ký chi tiết các thay đổi dữ liệu (INSERT, UPDATE, DELETE).';
COMMENT ON COLUMN audit.audit_log.action_tstamp IS 'Thời điểm thay đổi (Cột phân vùng RANGE).';

\echo '   -> Hoàn thành tạo cấu trúc bảng schema audit.'

-- === Schema: partitioning ===

\echo '[3] Tạo cấu trúc bảng trong schema: partitioning...'

-- Bảng: config (Cấu hình phân vùng) - Không phân vùng
DROP TABLE IF EXISTS partitioning.config CASCADE;
CREATE TABLE partitioning.config (
    config_id SERIAL PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL, -- CHECK constraint sẽ thêm sau
    partition_columns TEXT NOT NULL,
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    premake INTEGER DEFAULT 4,
    is_active BOOLEAN DEFAULT TRUE,
    use_pg_partman BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_partition_config UNIQUE (schema_name, table_name)
);
COMMENT ON TABLE partitioning.config IS '[BCA] Lưu trữ cấu hình phân vùng cho các bảng trong database này.';

-- Bảng: history (Lịch sử phân vùng) - Không phân vùng
DROP TABLE IF EXISTS partitioning.history CASCADE;
CREATE TABLE partitioning.history (
    history_id BIGSERIAL PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(200) NOT NULL,
    action VARCHAR(50) NOT NULL, -- CHECK constraint sẽ thêm sau
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Success', -- CHECK constraint sẽ thêm sau
    affected_rows BIGINT,
    duration_ms BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    details TEXT
    -- FK đến config sẽ thêm sau
);
COMMENT ON TABLE partitioning.history IS '[BCA] Ghi lại lịch sử các hành động liên quan đến phân vùng.';

\echo '   -> Hoàn thành tạo cấu trúc bảng schema partitioning.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH TẠO CẤU TRÚC BẢNG CHO DATABASE BỘ CÔNG AN ***'
\echo '-> Đã tạo cấu trúc cơ bản cho các bảng trong các schema: public_security, audit, partitioning.'
\echo '-> Bước tiếp theo: Chạy script 02_tables_constraints.sql để thêm các ràng buộc (FK, CHECK, UNIQUE...).'

-- File: national_citizen_central_server/01_tables_structure.sql
-- Description: Tạo cấu trúc (CREATE TABLE) cho TẤT CẢ các bảng
--              trong database Máy chủ Trung tâm (TT), không bao gồm constraints.
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO CẤU TRÚC BẢNG CHO DATABASE national_citizen_central_server ***'
\connect national_citizen_central_server

-- Đảm bảo các schema cần thiết tồn tại (phòng trường hợp chạy file riêng lẻ)
CREATE SCHEMA IF NOT EXISTS central;
CREATE SCHEMA IF NOT EXISTS sync;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS partitioning;
-- Schema mirror (public_security_mirror, justice_mirror) sẽ được tạo bởi 00_init và import bởi 05_fdw_setup.sql

BEGIN;

-- ============================================================================
-- Schema: central (Dữ liệu tích hợp)
-- ============================================================================

\echo '--> Tạo cấu trúc bảng cho schema central...'

-- 1. Bảng: central.integrated_citizen
\echo '    -> Bảng central.integrated_citizen...'
DROP TABLE IF EXISTS central.integrated_citizen CASCADE;
CREATE TABLE central.integrated_citizen (
    -- === Thông tin Định danh Cốt lõi ===
    citizen_id VARCHAR(12),                       -- Số định danh cá nhân (CCCD 12 số). Khóa chính logic.
    full_name VARCHAR(100),                      -- Họ và tên khai sinh đầy đủ.
    date_of_birth DATE,                          -- Ngày sinh.
    place_of_birth TEXT,                         -- Nơi sinh chi tiết (từ Giấy khai sinh).
    gender gender_type,                          -- Giới tính (ENUM: Nam, Nữ, Khác).

    -- === Thông tin Nhân khẩu học ===
    ethnicity_id SMALLINT,                       -- Dân tộc (FK reference.ethnicities).
    religion_id SMALLINT,                        -- Tôn giáo (FK reference.religions).
    nationality_id SMALLINT DEFAULT 1,           -- Quốc tịch (FK reference.nationalities, mặc định VN).

    -- === Thông tin CCCD/CMND Hiện tại ===
    current_id_card_number VARCHAR(12),
    current_id_card_type card_type,
    current_id_card_issue_date DATE,
    current_id_card_expiry_date DATE,
    current_id_card_issuing_authority_id SMALLINT, -- FK reference.authorities

    -- === Thông tin Hộ tịch ===
    marital_status marital_status DEFAULT 'Độc thân',
    death_status death_status DEFAULT 'Còn sống',
    date_of_death DATE,
    place_of_death TEXT,
    cause_of_death TEXT,
    birth_certificate_no VARCHAR(20),
    birth_registration_date DATE,
    death_certificate_no VARCHAR(20),
    current_marriage_id INT,                      -- ID logic của cuộc hôn nhân hiện tại
    current_spouse_citizen_id VARCHAR(12),
    current_marriage_date DATE,
    last_divorce_date DATE,

    -- === Thông tin Cư trú Hiện tại ===
    current_permanent_address_id INT,             -- ID logic địa chỉ thường trú hiện tại
    current_permanent_address_detail TEXT,
    current_permanent_registration_date DATE,
    current_temporary_address_id INT,             -- ID logic địa chỉ tạm trú hiện tại
    current_temporary_address_detail TEXT,
    current_temporary_registration_date DATE,
    current_temporary_expiry_date DATE,

    -- === Thông tin Học vấn, Nghề nghiệp, Xã hội ===
    education_level education_level,
    occupation_id SMALLINT,                       -- FK reference.occupations
    occupation_detail TEXT,
    tax_code VARCHAR(13),                         -- Mã số thuế cá nhân
    social_insurance_no VARCHAR(13),              -- Số sổ BHXH
    health_insurance_no VARCHAR(15),              -- Số thẻ BHYT

    -- === Thông tin Gia đình ===
    father_citizen_id VARCHAR(12),
    mother_citizen_id VARCHAR(12),

    -- === Thông tin Hành chính & Phân vùng ===
    region_id SMALLINT,                           -- FK reference.regions
    province_id INT,                              -- FK reference.provinces, Cột phân vùng cấp 2
    district_id INT,                              -- FK reference.districts, Cột phân vùng cấp 3
    geographical_region VARCHAR(20),              -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- === Metadata Đồng bộ & Hệ thống ===
    data_sources TEXT[],
    last_synced_from_bca TIMESTAMP WITH TIME ZONE,
    last_synced_from_btp TIMESTAMP WITH TIME ZONE,
    last_integrated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    record_status VARCHAR(50) DEFAULT 'Active',
    notes TEXT
) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)

COMMENT ON TABLE central.integrated_citizen IS '[TT] Bảng chứa dữ liệu công dân đã được tích hợp và tổng hợp từ các nguồn (BCA, BTP). Phân vùng theo Miền->Tỉnh->Huyện.';
COMMENT ON COLUMN central.integrated_citizen.citizen_id IS 'Số định danh cá nhân (CCCD 12 số) - Khóa chính logic.';
COMMENT ON COLUMN central.integrated_citizen.geographical_region IS 'Tên vùng địa lý hiện tại của công dân (dùng cho phân vùng cấp 1).';
COMMENT ON COLUMN central.integrated_citizen.province_id IS 'Tỉnh/Thành phố hiện tại của công dân (dùng cho phân vùng cấp 2).';
COMMENT ON COLUMN central.integrated_citizen.district_id IS 'Quận/Huyện hiện tại của công dân (dùng cho phân vùng cấp 3).';
COMMENT ON COLUMN central.integrated_citizen.last_integrated_at IS 'Thời điểm bản ghi tích hợp này được cập nhật lần cuối.';
COMMENT ON COLUMN central.integrated_citizen.data_sources IS 'Mảng chứa nguồn gốc dữ liệu (BCA, BTP) cho bản ghi này.';
COMMENT ON COLUMN central.integrated_citizen.record_status IS 'Trạng thái của bản ghi tích hợp (Active, Merged, Conflict, Archived...).';


-- 2. Bảng: central.integrated_household
\echo '    -> Bảng central.integrated_household...'
DROP TABLE IF EXISTS central.integrated_household CASCADE;
CREATE TABLE central.integrated_household (
    integrated_household_id BIGSERIAL,          -- Khóa chính tự tăng của bản ghi tích hợp (PK sẽ thêm sau)
    source_system VARCHAR(50),                  -- Nguồn dữ liệu gốc ('BTP', 'BCA'?)
    source_household_id VARCHAR(50),            -- Khóa chính của hộ khẩu ở hệ thống nguồn

    household_book_no VARCHAR(20),              -- Số sổ hộ khẩu
    head_of_household_citizen_id VARCHAR(12),   -- ID công dân của chủ hộ (Logic FK đến central.integrated_citizen)
    address_detail TEXT,                        -- Chi tiết địa chỉ (số nhà, đường...)
    ward_id INT,                                -- Phường/Xã (FK reference.wards)

    registration_date DATE,                     -- Ngày đăng ký hộ khẩu gốc
    issuing_authority_id SMALLINT,              -- Cơ quan cấp sổ gốc (FK reference.authorities)
    household_type household_type,              -- Loại hộ khẩu (ENUM)
    status household_status,                    -- Trạng thái hộ khẩu (ENUM)
    notes TEXT,                                 -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng
    region_id SMALLINT,                         -- FK reference.regions
    province_id INT,                            -- FK reference.provinces, Cột phân vùng cấp 2
    district_id INT,                            -- FK reference.districts, Cột phân vùng cấp 3
    geographical_region VARCHAR(20),            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata đồng bộ và tích hợp
    source_created_at TIMESTAMP WITH TIME ZONE,
    source_updated_at TIMESTAMP WITH TIME ZONE,
    integrated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)

COMMENT ON TABLE central.integrated_household IS '[TT] Bảng chứa dữ liệu hộ khẩu đã được tích hợp từ các nguồn (chủ yếu là Bộ Tư pháp). Phân vùng theo Miền->Tỉnh->Huyện.';
COMMENT ON COLUMN central.integrated_household.source_system IS 'Hệ thống nguồn của dữ liệu (vd: BTP, BCA).';
COMMENT ON COLUMN central.integrated_household.source_household_id IS 'ID gốc của hộ khẩu trên hệ thống nguồn.';
COMMENT ON COLUMN central.integrated_household.head_of_household_citizen_id IS 'ID Công dân của chủ hộ (Logic FK đến central.integrated_citizen).';
COMMENT ON COLUMN central.integrated_household.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN central.integrated_household.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN central.integrated_household.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';
COMMENT ON COLUMN central.integrated_household.integrated_at IS 'Thời điểm bản ghi tích hợp này được tạo hoặc cập nhật lần cuối.';


-- ============================================================================
-- Schema: sync (Hỗ trợ đồng bộ)
-- ============================================================================

\echo '--> Tạo cấu trúc bảng cho schema sync...'

-- 1. Bảng: sync.sync_status (Ví dụ)
\echo '    -> Bảng sync.sync_status (Ví dụ)...'
DROP TABLE IF EXISTS sync.sync_status CASCADE;
CREATE TABLE sync.sync_status (
    sync_id SERIAL,                             -- Khóa chính (sẽ thêm sau)
    last_sync_bca TIMESTAMP WITH TIME ZONE,
    last_sync_btp TIMESTAMP WITH TIME ZONE,
    last_run_status VARCHAR(50),                -- Trạng thái lần chạy cuối (Success, Failed)
    last_run_timestamp TIMESTAMP WITH TIME ZONE,
    last_error_message TEXT,
    notes TEXT
    -- Không phân vùng bảng này vì thường chỉ có 1 dòng
);
COMMENT ON TABLE sync.sync_status IS '[TT] Lưu trữ trạng thái của lần đồng bộ dữ liệu cuối cùng từ BCA và BTP.';
COMMENT ON COLUMN sync.sync_status.last_sync_bca IS 'Thời điểm dữ liệu từ BCA được đồng bộ thành công lần cuối.';
COMMENT ON COLUMN sync.sync_status.last_sync_btp IS 'Thời điểm dữ liệu từ BTP được đồng bộ thành công lần cuối.';
COMMENT ON COLUMN sync.sync_status.last_run_status IS 'Trạng thái của lần chạy job đồng bộ gần nhất.';


-- ============================================================================
-- Schema: audit
-- ============================================================================

\echo '--> Tạo cấu trúc bảng cho schema audit...'

-- 1. Bảng: audit.audit_log
\echo '    -> Bảng audit.audit_log...'
DROP TABLE IF EXISTS audit.audit_log CASCADE;
CREATE TABLE audit.audit_log (
    log_id BIGSERIAL,                      -- Khóa chính tự tăng (PK sẽ thêm sau)
    action_tstamp TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp(), -- Thời điểm hành động xảy ra (Cột phân vùng)
    schema_name TEXT,                      -- Schema của bảng bị thay đổi
    table_name TEXT,                       -- Tên bảng bị thay đổi
    operation cdc_operation_type,          -- Loại hành động (ENUM)
    session_user_name TEXT DEFAULT current_user,
    application_name TEXT DEFAULT current_setting('application_name'),
    client_addr INET DEFAULT inet_client_addr(),
    client_port INTEGER DEFAULT inet_client_port(),
    transaction_id BIGINT DEFAULT txid_current(),
    statement_only BOOLEAN DEFAULT FALSE,
    row_data JSONB,
    changed_fields JSONB,
    query TEXT
) PARTITION BY RANGE (action_tstamp); -- Khai báo phân vùng theo RANGE thời gian

COMMENT ON TABLE audit.audit_log IS '[TT] Bảng ghi nhật ký chi tiết các thay đổi dữ liệu trên các bảng được theo dõi trong DB Trung tâm. Phân vùng theo thời gian.';
COMMENT ON COLUMN audit.audit_log.action_tstamp IS 'Thời điểm chính xác khi hành động thay đổi dữ liệu xảy ra (Cột phân vùng).';
COMMENT ON COLUMN audit.audit_log.row_data IS 'Dữ liệu cũ của hàng dưới dạng JSONB (cho UPDATE, DELETE).';
COMMENT ON COLUMN audit.audit_log.changed_fields IS 'Các trường thay đổi và giá trị mới dưới dạng JSONB (cho UPDATE).';


-- ============================================================================
-- Schema: partitioning
-- ============================================================================

\echo '--> Tạo cấu trúc bảng cho schema partitioning...'

-- 1. Bảng: partitioning.config
\echo '    -> Bảng partitioning.config...'
DROP TABLE IF EXISTS partitioning.config CASCADE;
CREATE TABLE partitioning.config (
    config_id SERIAL,                         -- Khóa chính (sẽ thêm sau)
    schema_name VARCHAR(100),
    table_name VARCHAR(100),
    partition_type VARCHAR(20),
    partition_columns TEXT,
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    premake INTEGER DEFAULT 4,
    is_active BOOLEAN DEFAULT TRUE,
    use_pg_partman BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    -- UNIQUE constraint (schema_name, table_name) sẽ thêm sau
    -- CHECK constraint partition_type sẽ thêm sau
);
COMMENT ON TABLE partitioning.config IS '[TT] Lưu trữ cấu hình phân vùng cho các bảng trong database Máy chủ Trung tâm.';

-- 2. Bảng: partitioning.history
\echo '    -> Bảng partitioning.history...'
DROP TABLE IF EXISTS partitioning.history CASCADE;
CREATE TABLE partitioning.history (
    history_id BIGSERIAL,                 -- Khóa chính (sẽ thêm sau)
    schema_name VARCHAR(100),
    table_name VARCHAR(100),
    partition_name VARCHAR(200),
    action VARCHAR(50),
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Success',
    affected_rows BIGINT,
    duration_ms BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    details TEXT
    -- FK đến partitioning.config sẽ thêm sau
    -- CHECK constraints cho action, status sẽ thêm sau
);
COMMENT ON TABLE partitioning.history IS '[TT] Ghi lại lịch sử các hành động liên quan đến việc tạo, sửa, xóa, lưu trữ các partition trong database Máy chủ Trung tâm.';


COMMIT;

\echo '*** HOÀN THÀNH TẠO CẤU TRÚC BẢNG CHO DATABASE national_citizen_central_server ***'
-- File: national_citizen_central_server/02_tables_constraints.sql
-- Description: Thêm Khóa chính (PK), Khóa ngoại (FK), và Ràng buộc (CHECK, UNIQUE)
--              cho các bảng trong database Máy chủ Trung tâm (TT).
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
-- =============================================================================

\echo '*** BẮT ĐẦU THÊM CONSTRAINTS CHO DATABASE national_citizen_central_server ***'
\connect national_citizen_central_server

BEGIN;

-- ============================================================================
-- Schema: central (Dữ liệu tích hợp)
-- ============================================================================

\echo '--> Thêm constraints cho schema central...'

-- 1. Bảng: central.integrated_citizen
\echo '    -> Bảng central.integrated_citizen...'
ALTER TABLE central.integrated_citizen
    -- Khóa chính (bao gồm các cột phân vùng)
    ADD CONSTRAINT pk_integrated_citizen PRIMARY KEY (citizen_id, geographical_region, province_id, district_id),
    -- Khóa ngoại (chỉ tham chiếu đến bảng reference cục bộ)
    ADD CONSTRAINT fk_integrated_citizen_ethnicity FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicities(ethnicity_id),
    ADD CONSTRAINT fk_integrated_citizen_religion FOREIGN KEY (religion_id) REFERENCES reference.religions(religion_id),
    ADD CONSTRAINT fk_integrated_citizen_nationality FOREIGN KEY (nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_integrated_citizen_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupations(occupation_id),
    ADD CONSTRAINT fk_integrated_citizen_id_authority FOREIGN KEY (current_id_card_issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_integrated_citizen_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_integrated_citizen_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_integrated_citizen_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- Ràng buộc UNIQUE (Lưu ý về partitioning)
    ADD CONSTRAINT uq_integrated_citizen_tax_code UNIQUE (tax_code),
    ADD CONSTRAINT uq_integrated_citizen_bhxh UNIQUE (social_insurance_no),
    ADD CONSTRAINT uq_integrated_citizen_bhyt UNIQUE (health_insurance_no),
    -- Ràng buộc CHECK
    ADD CONSTRAINT ck_integrated_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$'),
    ADD CONSTRAINT ck_integrated_citizen_birth_date CHECK (date_of_birth < CURRENT_DATE),
    ADD CONSTRAINT ck_integrated_citizen_death_logic CHECK ( (death_status = 'Đã mất' AND date_of_death IS NOT NULL) OR (death_status != 'Đã mất') ),
    ADD CONSTRAINT ck_integrated_citizen_id_card_dates CHECK ( current_id_card_issue_date IS NULL OR current_id_card_issue_date <= CURRENT_DATE ),
    ADD CONSTRAINT ck_integrated_citizen_id_card_expiry CHECK ( current_id_card_expiry_date IS NULL OR current_id_card_issue_date IS NULL OR current_id_card_expiry_date > current_id_card_issue_date ),
    ADD CONSTRAINT ck_integrated_citizen_marriage_logic CHECK ( (marital_status IN ('Đã kết hôn', 'Ly thân') AND current_spouse_citizen_id IS NOT NULL AND current_marriage_date IS NOT NULL) OR (marital_status NOT IN ('Đã kết hôn', 'Ly thân')) ),
    ADD CONSTRAINT ck_integrated_citizen_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') OR region_id IS NULL );

-- 2. Bảng: central.integrated_household
\echo '    -> Bảng central.integrated_household...'
ALTER TABLE central.integrated_household
    -- Khóa chính (bao gồm các cột phân vùng)
    ADD CONSTRAINT pk_integrated_household PRIMARY KEY (integrated_household_id, geographical_region, province_id, district_id),
    -- Ràng buộc UNIQUE (Lưu ý về partitioning)
    ADD CONSTRAINT uq_integrated_household_source UNIQUE (source_system, source_household_id),
    ADD CONSTRAINT uq_integrated_household_book_no UNIQUE (household_book_no),
    -- Khóa ngoại (tham chiếu bảng reference cục bộ và bảng integrated_citizen cục bộ)
    ADD CONSTRAINT fk_integrated_household_head FOREIGN KEY (head_of_household_citizen_id) REFERENCES central.integrated_citizen(citizen_id) ON DELETE SET NULL, -- FK đến bảng phân vùng khác
    ADD CONSTRAINT fk_integrated_household_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    ADD CONSTRAINT fk_integrated_household_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT fk_integrated_household_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_integrated_household_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_integrated_household_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    -- Ràng buộc CHECK
    ADD CONSTRAINT ck_integrated_household_dates CHECK (registration_date IS NULL OR registration_date <= CURRENT_DATE),
    ADD CONSTRAINT ck_integrated_household_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );


-- ============================================================================
-- Schema: sync (Hỗ trợ đồng bộ)
-- ============================================================================

\echo '--> Thêm constraints cho schema sync...'

-- 1. Bảng: sync.sync_status (Ví dụ)
\echo '    -> Bảng sync.sync_status (Ví dụ)...'
ALTER TABLE sync.sync_status
    ADD CONSTRAINT pk_sync_status PRIMARY KEY (sync_id),
    ADD CONSTRAINT ck_sync_status_last_run CHECK (last_run_status IS NULL OR last_run_status IN ('Success', 'Failed'));


-- ============================================================================
-- Schema: audit
-- ============================================================================

\echo '--> Thêm constraints cho schema audit...'

-- 1. Bảng: audit.audit_log
\echo '    -> Bảng audit.audit_log...'
ALTER TABLE audit.audit_log
    ADD CONSTRAINT pk_audit_log PRIMARY KEY (log_id, action_tstamp);
    -- Bảng này phân vùng theo action_tstamp, PK đã bao gồm cột phân vùng.


-- ============================================================================
-- Schema: partitioning
-- ============================================================================

\echo '--> Thêm constraints cho schema partitioning...'

-- 1. Bảng: partitioning.config
\echo '    -> Bảng partitioning.config...'
ALTER TABLE partitioning.config
    ADD CONSTRAINT pk_partition_config PRIMARY KEY (config_id),
    ADD CONSTRAINT uq_partition_config UNIQUE (schema_name, table_name),
    ADD CONSTRAINT ck_partition_config_type CHECK (partition_type IN ('NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER'));

-- 2. Bảng: partitioning.history
\echo '    -> Bảng partitioning.history...'
ALTER TABLE partitioning.history
    ADD CONSTRAINT pk_partition_history PRIMARY KEY (history_id),
    ADD CONSTRAINT fk_partition_history_config FOREIGN KEY (schema_name, table_name) REFERENCES partitioning.config(schema_name, table_name) ON DELETE SET NULL,
    ADD CONSTRAINT ck_partition_history_action CHECK (action IN ('INIT_PARTITIONING', 'CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION', 'ARCHIVE_START', 'ARCHIVE_PARTITION', 'ARCHIVED', 'ARCHIVE_COMPLETE', 'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'DROP_INDEX', 'CONFIG_UPDATE', 'ERROR', 'SYNC_START', 'SYNC_STEP', 'SYNC_END')), -- Thêm action liên quan sync
    ADD CONSTRAINT ck_partition_history_status CHECK (status IN ('Success', 'Failed', 'Running', 'Skipped'));

COMMIT;

\echo '*** HOÀN THÀNH THÊM CONSTRAINTS CHO DATABASE national_citizen_central_server ***'
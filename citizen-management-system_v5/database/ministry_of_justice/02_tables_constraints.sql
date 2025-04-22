-- File: ministry_of_justice/02_tables_constraints.sql
-- Description: Thêm Khóa chính (PK), Khóa ngoại (FK), và Ràng buộc (CHECK, UNIQUE)
--              cho các bảng trong database Bộ Tư pháp (BTP).
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
-- =============================================================================

\echo '*** BẮT ĐẦU THÊM CONSTRAINTS CHO DATABASE ministry_of_justice ***'
\connect ministry_of_justice

BEGIN;

-- ============================================================================
-- Schema: justice
-- ============================================================================

\echo '--> Thêm constraints cho schema justice...'

-- 1. Bảng: justice.birth_certificate
\echo '    -> Bảng justice.birth_certificate...'
ALTER TABLE justice.birth_certificate
    ADD CONSTRAINT pk_birth_certificate PRIMARY KEY (birth_certificate_id, geographical_region, province_id, district_id),
    -- UNIQUE Constraints (Kiểm tra tính tương thích với partitioning nếu cần)
    ADD CONSTRAINT uq_birth_certificate_no UNIQUE (birth_certificate_no),
    ADD CONSTRAINT uq_birth_certificate_citizen_id UNIQUE (citizen_id),
    -- Foreign Key Constraints (chỉ tham chiếu bảng trong BTP hoặc reference)
    ADD CONSTRAINT fk_birth_certificate_father_nat FOREIGN KEY (father_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_birth_certificate_mother_nat FOREIGN KEY (mother_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_birth_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_birth_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_birth_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_birth_certificate_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_birth_certificate_dates CHECK (date_of_birth < CURRENT_DATE AND registration_date >= date_of_birth AND registration_date <= CURRENT_DATE AND (father_date_of_birth IS NULL OR father_date_of_birth < date_of_birth) AND (mother_date_of_birth IS NULL OR mother_date_of_birth < date_of_birth)),
    ADD CONSTRAINT ck_birth_certificate_parents CHECK (citizen_id <> father_citizen_id AND citizen_id <> mother_citizen_id),
    ADD CONSTRAINT ck_birth_certificate_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam'));

-- 2. Bảng: justice.death_certificate
\echo '    -> Bảng justice.death_certificate...'
ALTER TABLE justice.death_certificate
    ADD CONSTRAINT pk_death_certificate PRIMARY KEY (death_certificate_id, geographical_region, province_id, district_id),
    -- UNIQUE Constraints (Kiểm tra tính tương thích với partitioning nếu cần)
    ADD CONSTRAINT uq_death_certificate_no UNIQUE (death_certificate_no),
    ADD CONSTRAINT uq_death_certificate_citizen_id UNIQUE (citizen_id),
    -- Foreign Key Constraints
    ADD CONSTRAINT fk_death_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_death_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_death_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_death_certificate_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_death_certificate_dates CHECK (date_of_death <= CURRENT_DATE AND registration_date >= date_of_death AND registration_date <= CURRENT_DATE),
    ADD CONSTRAINT ck_death_certificate_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam'));

-- 3. Bảng: justice.marriage
\echo '    -> Bảng justice.marriage...'
ALTER TABLE justice.marriage
    ADD CONSTRAINT pk_marriage PRIMARY KEY (marriage_id, geographical_region, province_id, district_id),
    -- UNIQUE Constraints (Kiểm tra tính tương thích với partitioning nếu cần)
    ADD CONSTRAINT uq_marriage_certificate_no UNIQUE (marriage_certificate_no),
    -- Foreign Key Constraints
    ADD CONSTRAINT fk_marriage_husband_nationality FOREIGN KEY (husband_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_marriage_wife_nationality FOREIGN KEY (wife_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_marriage_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_marriage_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_marriage_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_marriage_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_marriage_dates CHECK (marriage_date <= CURRENT_DATE AND registration_date >= marriage_date AND registration_date <= CURRENT_DATE),
    ADD CONSTRAINT ck_marriage_husband_age CHECK (husband_date_of_birth <= (marriage_date - INTERVAL '20 years')),
    ADD CONSTRAINT ck_marriage_wife_age CHECK (wife_date_of_birth <= (marriage_date - INTERVAL '18 years')),
    ADD CONSTRAINT ck_marriage_different_people CHECK (husband_id <> wife_id),
    ADD CONSTRAINT ck_marriage_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam'));

-- 4. Bảng: justice.divorce
\echo '    -> Bảng justice.divorce...'
ALTER TABLE justice.divorce
    ADD CONSTRAINT pk_divorce PRIMARY KEY (divorce_id, geographical_region, province_id),
    -- UNIQUE Constraints (Kiểm tra tính tương thích với partitioning nếu cần)
    ADD CONSTRAINT uq_divorce_certificate_no UNIQUE (divorce_certificate_no),
    ADD CONSTRAINT uq_divorce_judgment_no UNIQUE (judgment_no),
    ADD CONSTRAINT uq_divorce_marriage_id UNIQUE (marriage_id),
    -- Foreign Key Constraints
    ADD CONSTRAINT fk_divorce_marriage FOREIGN KEY (marriage_id) REFERENCES justice.marriage(marriage_id) ON DELETE RESTRICT, -- Tham chiếu đến bảng marriage đã phân vùng
    ADD CONSTRAINT fk_divorce_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_divorce_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_divorce_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_divorce_dates CHECK (divorce_date <= CURRENT_DATE AND registration_date <= CURRENT_DATE AND judgment_date <= registration_date AND divorce_date <= registration_date AND judgment_date <= divorce_date),
    ADD CONSTRAINT ck_divorce_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam'));

-- 5. Bảng: justice.household
\echo '    -> Bảng justice.household...'
ALTER TABLE justice.household
    ADD CONSTRAINT pk_household PRIMARY KEY (household_id, geographical_region, province_id, district_id),
    -- UNIQUE Constraints (Kiểm tra tính tương thích với partitioning nếu cần)
    ADD CONSTRAINT uq_household_book_no UNIQUE (household_book_no),
    -- Foreign Key Constraints
    ADD CONSTRAINT fk_household_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_household_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_household_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_household_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_household_registration_date CHECK (registration_date <= CURRENT_DATE),
    ADD CONSTRAINT ck_household_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam'));

-- 6. Bảng: justice.household_member
\echo '    -> Bảng justice.household_member...'
ALTER TABLE justice.household_member
    ADD CONSTRAINT pk_household_member PRIMARY KEY (household_member_id, geographical_region, province_id),
    -- UNIQUE Constraints (Kiểm tra tính tương thích với partitioning nếu cần)
    ADD CONSTRAINT uq_household_member_join UNIQUE (household_id, citizen_id, join_date),
    -- Foreign Key Constraints
    ADD CONSTRAINT fk_household_member_household FOREIGN KEY (household_id) REFERENCES justice.household(household_id) ON DELETE CASCADE, -- Tham chiếu đến bảng household đã phân vùng
    ADD CONSTRAINT fk_household_member_prev_household FOREIGN KEY (previous_household_id) REFERENCES justice.household(household_id) ON DELETE SET NULL, -- Tham chiếu đến bảng household đã phân vùng
    ADD CONSTRAINT fk_household_member_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_household_member_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_household_member_dates CHECK (join_date <= CURRENT_DATE AND (leave_date IS NULL OR leave_date >= join_date)),
    ADD CONSTRAINT ck_household_member_order CHECK (order_in_household IS NULL OR order_in_household > 0),
    ADD CONSTRAINT ck_household_member_status CHECK (status IN ('Active', 'Left', 'Moved', 'Deceased', 'Cancelled')),
    ADD CONSTRAINT ck_household_member_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam'));

-- 7. Bảng: justice.family_relationship
\echo '    -> Bảng justice.family_relationship...'
ALTER TABLE justice.family_relationship
    ADD CONSTRAINT pk_family_relationship PRIMARY KEY (relationship_id, geographical_region, province_id),
    -- Foreign Key Constraints
    ADD CONSTRAINT fk_family_relationship_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_family_relationship_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_family_relationship_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_family_relationship_dates CHECK (start_date <= CURRENT_DATE AND (end_date IS NULL OR end_date >= start_date)),
    ADD CONSTRAINT ck_family_relationship_different_people CHECK (citizen_id <> related_citizen_id),
    ADD CONSTRAINT ck_family_relationship_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') OR region_id IS NULL);

-- 8. Bảng: justice.population_change
\echo '    -> Bảng justice.population_change...'
ALTER TABLE justice.population_change
    ADD CONSTRAINT pk_population_change PRIMARY KEY (change_id, geographical_region, province_id),
    -- Foreign Key Constraints
    ADD CONSTRAINT fk_population_change_authority FOREIGN KEY (processing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_population_change_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_population_change_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    -- CHECK Constraints
    ADD CONSTRAINT ck_population_change_date CHECK (change_date <= CURRENT_DATE),
    ADD CONSTRAINT ck_population_change_locations CHECK ((change_type IN ('Chuyển đi thường trú', 'Xóa tạm trú') AND source_location_id IS NOT NULL) OR (change_type IN ('Chuyển đến thường trú', 'Đăng ký tạm trú') AND destination_location_id IS NOT NULL) OR (change_type NOT IN ('Chuyển đi thường trú', 'Xóa tạm trú', 'Chuyển đến thường trú', 'Đăng ký tạm trú'))),
    ADD CONSTRAINT ck_population_change_region_consistency CHECK ((region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') OR region_id IS NULL);

-- ============================================================================
-- Schema: audit
-- ============================================================================

\echo '--> Thêm constraints cho schema audit...'

-- 9. Bảng: audit.audit_log
\echo '    -> Bảng audit.audit_log...'
ALTER TABLE audit.audit_log
    ADD CONSTRAINT pk_audit_log PRIMARY KEY (log_id, action_tstamp);
    -- Bảng này phân vùng theo action_tstamp, PK đã bao gồm cột phân vùng.
    -- Không có FK, UNIQUE, hoặc CHECK constraint cần thêm ở đây.

-- ============================================================================
-- Schema: partitioning
-- ============================================================================

\echo '--> Thêm constraints cho schema partitioning...'

-- 10. Bảng: partitioning.config
\echo '    -> Bảng partitioning.config...'
ALTER TABLE partitioning.config
    ADD CONSTRAINT pk_partition_config PRIMARY KEY (config_id),
    ADD CONSTRAINT uq_partition_config UNIQUE (schema_name, table_name),
    ADD CONSTRAINT ck_partition_config_type CHECK (partition_type IN ('NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER'));

-- 11. Bảng: partitioning.history
\echo '    -> Bảng partitioning.history...'
ALTER TABLE partitioning.history
    ADD CONSTRAINT pk_partition_history PRIMARY KEY (history_id),
    ADD CONSTRAINT fk_partition_history_config FOREIGN KEY (schema_name, table_name) REFERENCES partitioning.config(schema_name, table_name) ON DELETE SET NULL,
    ADD CONSTRAINT ck_partition_history_action CHECK (action IN ('INIT_PARTITIONING', 'CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION', 'ARCHIVE_START', 'ARCHIVE_PARTITION', 'ARCHIVED', 'ARCHIVE_COMPLETE', 'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'DROP_INDEX', 'CONFIG_UPDATE', 'ERROR')),
    ADD CONSTRAINT ck_partition_history_status CHECK (status IN ('Success', 'Failed', 'Running', 'Skipped'));

COMMIT;

\echo '*** HOÀN THÀNH THÊM CONSTRAINTS CHO DATABASE ministry_of_justice ***'
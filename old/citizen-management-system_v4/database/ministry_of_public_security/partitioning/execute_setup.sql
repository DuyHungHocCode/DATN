-- File: ministry_of_public_security/partitioning/execute_setup.sql
-- Description: Thực thi việc thiết lập phân vùng cho các bảng trong database
--              Bộ Công an (BCA) bằng cách gọi các function đã định nghĩa.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Các functions trong ministry_of_public_security/partitioning/functions.sql đã được tạo.
-- - Dữ liệu cấu hình trong partitioning.config đã được nạp.
-- - Dữ liệu trong các bảng reference.* đã được nạp.
-- - Extension 'pg_partman' (nếu dùng cho audit_log).
-- =============================================================================

\echo '--> Bắt đầu thực thi thiết lập phân vùng cho ministry_of_public_security...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
\connect ministry_of_public_security

BEGIN;

-- ============================================================================
-- 1. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen
-- ============================================================================
\echo '--> 1. Thiết lập phân vùng cho public_security.citizen (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'citizen',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.citizen...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'citizen',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_full_name ON %1$I.%2$I USING gin (full_name gin_trgm_ops)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dob ON %1$I.%2$I(date_of_birth)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_gender ON %1$I.%2$I(gender)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_ethnicity ON %1$I.%2$I(ethnicity_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_nationality ON %1$I.%2$I(nationality_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_father_id ON %1$I.%2$I(father_citizen_id) WHERE father_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_mother_id ON %1$I.%2$I(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_marital_status ON %1$I.%2$I(marital_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_death_status ON %1$I.%2$I(death_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_tax_code ON %1$I.%2$I(tax_code) WHERE tax_code IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_bhxh ON %1$I.%2$I(social_insurance_no) WHERE social_insurance_no IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_bhyt ON %1$I.%2$I(health_insurance_no) WHERE health_insurance_no IS NOT NULL'
    ]
);

-- ============================================================================
-- 2. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.address
-- ============================================================================
\echo '--> 2. Thiết lập phân vùng cho public_security.address (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'address',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.address...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'address',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_ward_id ON %1$I.%2$I(ward_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_full_address ON %1$I.%2$I USING gin (full_address gin_trgm_ops)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_postgis_geom ON %1$I.%2$I USING gist (coordinates)' -- Index cho PostGIS
    ]
);

-- ============================================================================
-- 3. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.identification_card
-- ============================================================================
\echo '--> 3. Thiết lập phân vùng cho public_security.identification_card (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'identification_card',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.identification_card...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'identification_card',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_card_type ON %1$I.%2$I(card_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_card_status ON %1$I.%2$I(card_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_issue_date ON %1$I.%2$I(issue_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_expiry_date ON %1$I.%2$I(expiry_date)',
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_active_id_card ON %1$I.%2$I (citizen_id) WHERE card_status = ''Đang sử dụng''' -- Unique index trên partition
    ]
);

-- ============================================================================
-- 4. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.permanent_residence
-- ============================================================================
\echo '--> 4. Thiết lập phân vùng cho public_security.permanent_residence (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'permanent_residence',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.permanent_residence...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'permanent_residence',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_active_perm_res ON %1$I.%2$I (citizen_id) WHERE status = TRUE' -- Unique index trên partition
    ]
);

-- ============================================================================
-- 5. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.temporary_residence
-- ============================================================================
\echo '--> 5. Thiết lập phân vùng cho public_security.temporary_residence (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'temporary_residence',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.temporary_residence...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'temporary_residence',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_expiry_date ON %1$I.%2$I(expiry_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_perm_addr_id ON %1$I.%2$I(permanent_address_id) WHERE permanent_address_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_host_citizen_id ON %1$I.%2$I(host_citizen_id) WHERE host_citizen_id IS NOT NULL'
    ]
);

-- ============================================================================
-- 6. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.temporary_absence
-- ============================================================================
\echo '--> 6. Thiết lập phân vùng cho public_security.temporary_absence (Miền -> Tỉnh)...'
-- Bảng này chỉ phân vùng 2 cấp theo Miền -> Tỉnh
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'temporary_absence',
    p_region_column     := 'geographical_region', p_province_column := 'province_id',
    p_district_column   := NULL, -- Không dùng cột huyện
    p_include_district  := FALSE -- Chỉ phân vùng 2 cấp
);
\echo '    -> Tạo indexes cho các partition của public_security.temporary_absence...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'temporary_absence',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_from_date ON %1$I.%2$I(from_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_to_date ON %1$I.%2$I(to_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_return_date ON %1$I.%2$I(return_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dest_addr_id ON %1$I.%2$I(destination_address_id) WHERE destination_address_id IS NOT NULL',
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_temp_abs_reg_num ON %1$I.%2$I (registration_number) WHERE registration_number IS NOT NULL'
    ]
);

-- ============================================================================
-- 7. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen_status
-- ============================================================================
\echo '--> 7. Thiết lập phân vùng cho public_security.citizen_status (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'citizen_status',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.citizen_status...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'citizen_status',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status_type ON %1$I.%2$I(status_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_effective_date ON %1$I.%2$I(effective_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_is_current ON %1$I.%2$I(is_current)'
    ]
);

-- ============================================================================
-- 8. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen_movement
-- ============================================================================
\echo '--> 8. Thiết lập phân vùng cho public_security.citizen_movement (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'citizen_movement',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.citizen_movement...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'citizen_movement',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_movement_type ON %1$I.%2$I(movement_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_movement_date ON %1$I.%2$I(movement_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_from_address_id ON %1$I.%2$I(from_address_id) WHERE from_address_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_to_address_id ON %1$I.%2$I(to_address_id) WHERE to_address_id IS NOT NULL'
    ]
);

-- ============================================================================
-- 9. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.criminal_record
-- ============================================================================
\echo '--> 9. Thiết lập phân vùng cho public_security.criminal_record (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'criminal_record',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.criminal_record...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'criminal_record',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_record_type ON %1$I.%2$I(record_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_decision_date ON %1$I.%2$I(decision_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
        -- Index trên decision_number đã có từ UNIQUE constraint
    ]
);

-- ============================================================================
-- 10. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.digital_identity
-- ============================================================================
\echo '--> 10. Thiết lập phân vùng cho public_security.digital_identity (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'digital_identity',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.digital_identity...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'digital_identity',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_verification_level ON %1$I.%2$I(verification_level)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_last_updated ON %1$I.%2$I(last_updated_time)',
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_active_digital_id ON %1$I.%2$I (citizen_id) WHERE status = ''Active''' -- Unique index trên partition
        -- Index trên digital_id đã có từ UNIQUE constraint
    ]
);

-- ============================================================================
-- 11. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen_address
-- ============================================================================
\echo '--> 11. Thiết lập phân vùng cho public_security.citizen_address (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'citizen_address',
    p_region_column     := 'geographical_region', p_province_column := 'province_id', p_district_column := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cho các partition của public_security.citizen_address...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'citizen_address',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_type ON %1$I.%2$I(address_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_start_date ON %1$I.%2$I(start_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_end_date ON %1$I.%2$I(end_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_is_primary ON %1$I.%2$I(is_primary)',
        'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_citizen_addr_primary ON %1$I.%2$I (citizen_id, address_type) WHERE is_primary = TRUE' -- Unique index trên partition
    ]
);


-- ============================================================================
-- 12. THIẾT LẬP PHÂN VÙNG CHO BẢNG audit.audit_log (THEO THỜI GIAN)
-- ============================================================================
\echo '--> 12. Thiết lập phân vùng cho audit.audit_log (Theo thời gian)...'

DO $$
DECLARE
    v_use_pg_partman BOOLEAN;
    v_partition_interval TEXT;
    v_retention TEXT;
    v_premake INTEGER;
BEGIN
    -- Kiểm tra cấu hình trong partitioning.config
    SELECT use_pg_partman, partition_interval, retention_period, premake
    INTO v_use_pg_partman, v_partition_interval, v_retention, v_premake
    FROM partitioning.config
    WHERE schema_name = 'audit' AND table_name = 'audit_log';

    IF FOUND THEN
        IF v_use_pg_partman THEN
            -- Nếu cấu hình sử dụng pg_partman, gọi hàm create_parent của pg_partman
             RAISE NOTICE '    -> Sử dụng pg_partman để quản lý audit.audit_log. Gọi create_parent...';
             BEGIN
                 PERFORM public.create_parent( -- Hàm của pg_partman thường nằm trong schema public
                     p_parent_table := 'audit.audit_log',
                     p_control := 'action_tstamp',
                     p_type := 'native', -- Sử dụng native partitioning của PostgreSQL
                     p_interval := v_partition_interval, -- Lấy từ config, vd: '1 month'
                     p_premake := v_premake -- Lấy từ config, vd: 4
                 );
                 -- Thiết lập retention policy (nếu có)
                 IF v_retention IS NOT NULL THEN
                     UPDATE public.part_config -- Bảng config của pg_partman
                     SET retention = v_retention,
                         retention_keep_table = true, -- Giữ lại bảng khi detach
                         retention_keep_index = true
                     WHERE parent_table = 'audit.audit_log';
                     RAISE NOTICE '       -> Đã thiết lập retention policy: %', v_retention;
                 END IF;

                 PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Success', 'Đã gọi pg_partman.create_parent.');
                 RAISE NOTICE '    -> Đã gọi pg_partman.create_parent cho audit.audit_log.';
                 RAISE NOTICE '    -> Lưu ý: Cần chạy pg_partman.run_maintenance() định kỳ (qua pg_cron/Airflow) để tạo partition mới và xử lý retention.';

             EXCEPTION WHEN undefined_function THEN
                 RAISE WARNING '    -> Lỗi: Hàm pg_partman.create_parent không tồn tại. Hãy đảm bảo extension pg_partman đã được cài đặt và cấu hình đúng.';
                 PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Failed', 'Hàm pg_partman.create_parent không tồn tại.');
             WHEN OTHERS THEN
                 RAISE WARNING '    -> Lỗi khi gọi pg_partman.create_parent: %', SQLERRM;
                 PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Failed', format('Lỗi pg_partman: %s', SQLERRM));
             END;
        ELSE
            -- Nếu không dùng pg_partman, cần có script/hàm tùy chỉnh khác để tạo partition theo thời gian
            RAISE WARNING '    -> Cấu hình cho audit.audit_log không sử dụng pg_partman. Cần có script tùy chỉnh để tạo partition theo thời gian.';
            PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Skipped', 'Không sử dụng pg_partman, cần script tùy chỉnh.');
        END IF;
    ELSE
        RAISE WARNING '    -> Không tìm thấy cấu hình phân vùng cho audit.audit_log trong partitioning.config. Bỏ qua thiết lập phân vùng thời gian.';
         PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Skipped', 'Không tìm thấy cấu hình trong partitioning.config.');
    END IF;
END $$;


COMMIT;

\echo '-> Hoàn thành thực thi thiết lập phân vùng cho ministry_of_public_security.'
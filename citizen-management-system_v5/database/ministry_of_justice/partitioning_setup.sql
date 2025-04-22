-- File: ministry_of_justice/partitioning_setup.sql
-- Description: Thực thi việc thiết lập phân vùng cho các bảng trong database
--              Bộ Tư pháp (BTP), bao gồm tạo partition con và các index cơ bản.
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
--
-- Dependencies:
-- - Các functions trong ministry_of_justice/03_functions.sql đã được tạo.
-- - Dữ liệu cấu hình trong partitioning.config đã được nạp (tùy chọn, hàm setup_nested_partitioning sẽ ghi).
-- - Dữ liệu trong các bảng reference.* đã được nạp.
-- - Extension 'pg_partman' (nếu dùng cho audit_log).
-- =============================================================================

\echo '*** BẮT ĐẦU THỰC THI SETUP PHÂN VÙNG CHO ministry_of_justice ***'
\connect ministry_of_justice

BEGIN;

-- ============================================================================
-- 1. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.birth_certificate
-- ============================================================================
\echo '--> 1. Thiết lập phân vùng cho justice.birth_certificate (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'birth_certificate',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.birth_certificate...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'birth_certificate',
    p_index_definitions := ARRAY[
        -- Index trên FK và các cột lọc thông dụng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dob ON %1$I.%2$I(date_of_birth)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_father_id ON %1$I.%2$I(father_citizen_id) WHERE father_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_mother_id ON %1$I.%2$I(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_declarant_id ON %1$I.%2$I(declarant_citizen_id) WHERE declarant_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)'
        -- Lưu ý: Index cho PK và UNIQUE constraints (birth_certificate_no, citizen_id)
        -- thường được PostgreSQL tự động tạo trên các partition khi constraint được tạo trên bảng cha.
    ]
);

-- ============================================================================
-- 2. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.death_certificate
-- ============================================================================
\echo '--> 2. Thiết lập phân vùng cho justice.death_certificate (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'death_certificate',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.death_certificate...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'death_certificate',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_date_of_death ON %1$I.%2$I(date_of_death)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_declarant_id ON %1$I.%2$I(declarant_citizen_id) WHERE declarant_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)'
        -- Index cho PK và UNIQUE constraints (death_certificate_no, citizen_id) được tạo tự động.
    ]
);

-- ============================================================================
-- 3. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.marriage
-- ============================================================================
\echo '--> 3. Thiết lập phân vùng cho justice.marriage (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'marriage',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.marriage...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'marriage',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_husband_id ON %1$I.%2$I(husband_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_wife_id ON %1$I.%2$I(wife_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_marriage_date ON %1$I.%2$I(marriage_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_registration_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)'
        -- Index cho PK và UNIQUE constraint (marriage_certificate_no) được tạo tự động.
    ]
);

-- ============================================================================
-- 4. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.divorce
-- ============================================================================
\echo '--> 4. Thiết lập phân vùng cho justice.divorce (Miền -> Tỉnh)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'divorce',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := NULL, -- Không dùng cột district
    p_include_district  := FALSE -- Chỉ phân vùng đến cấp Tỉnh
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.divorce...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'divorce',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_divorce_date ON %1$I.%2$I(divorce_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_registration_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_judgment_date ON %1$I.%2$I(judgment_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_issuing_authority_id ON %1$I.%2$I(issuing_authority_id)'
        -- Index cho PK và UNIQUE constraints (divorce_certificate_no, judgment_no, marriage_id) được tạo tự động.
        -- Index cho FK (marriage_id) đã có trong UNIQUE constraint.
    ]
);

-- ============================================================================
-- 5. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.household
-- ============================================================================
\echo '--> 5. Thiết lập phân vùng cho justice.household (Miền -> Tỉnh -> Huyện)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'household',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := 'district_id',
    p_include_district  := TRUE
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.household...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'household',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_head_id ON %1$I.%2$I(head_of_household_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)', -- address_id là logic link
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(household_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)'
        -- Index cho PK và UNIQUE constraint (household_book_no) được tạo tự động.
    ]
);

-- ============================================================================
-- 6. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.household_member
-- ============================================================================
\echo '--> 6. Thiết lập phân vùng cho justice.household_member (Miền -> Tỉnh)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'household_member',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := NULL, -- Không dùng cột district
    p_include_district  := FALSE -- Chỉ phân vùng đến cấp Tỉnh
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.household_member...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'household_member',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_household_id ON %1$I.%2$I(household_id)', -- FK
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)', -- Cột lọc quan trọng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_join_date ON %1$I.%2$I(join_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_leave_date ON %1$I.%2$I(leave_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_prev_hhold_id ON %1$I.%2$I(previous_household_id) WHERE previous_household_id IS NOT NULL' -- FK
        -- Index cho PK và UNIQUE constraint (household_id, citizen_id, join_date) được tạo tự động.
    ]
);

-- ============================================================================
-- 7. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.family_relationship
-- ============================================================================
\echo '--> 7. Thiết lập phân vùng cho justice.family_relationship (Miền -> Tỉnh)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'family_relationship',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := NULL, -- Không dùng cột district
    p_include_district  := FALSE -- Chỉ phân vùng đến cấp Tỉnh
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.family_relationship...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'family_relationship',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen1 ON %1$I.%2$I(citizen_id)', -- Cột lọc quan trọng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen2 ON %1$I.%2$I(related_citizen_id)', -- Cột lọc quan trọng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(relationship_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_start_date ON %1$I.%2$I(start_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_end_date ON %1$I.%2$I(end_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)', -- FK
        'CREATE INDEX IF NOT EXISTS idx_%2$s_pair ON %1$I.%2$I(citizen_id, related_citizen_id)' -- Hỗ trợ tìm cặp quan hệ
        -- Index cho PK được tạo tự động.
    ]
);

-- ============================================================================
-- 8. THIẾT LẬP PHÂN VÙNG CHO BẢNG justice.population_change
-- ============================================================================
\echo '--> 8. Thiết lập phân vùng cho justice.population_change (Miền -> Tỉnh)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'justice',
    p_table             := 'population_change',
    p_region_column     := 'geographical_region',
    p_province_column   := 'province_id',
    p_district_column   := NULL, -- Không dùng cột district
    p_include_district  := FALSE -- Chỉ phân vùng đến cấp Tỉnh
);
\echo '    -> Tạo indexes cơ bản cho các partition của justice.population_change...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'justice',
    p_table  := 'population_change',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)', -- Cột lọc quan trọng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_change_type ON %1$I.%2$I(change_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_change_date ON %1$I.%2$I(change_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_source_loc_id ON %1$I.%2$I(source_location_id) WHERE source_location_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dest_loc_id ON %1$I.%2$I(destination_location_id) WHERE destination_location_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(processing_authority_id)' -- FK
        -- Index cho PK được tạo tự động.
    ]
);

-- ============================================================================
-- 9. THIẾT LẬP PHÂN VÙNG CHO BẢNG audit.audit_log (THEO THỜI GIAN)
-- ============================================================================
\echo '--> 9. Thiết lập phân vùng cho audit.audit_log (Theo thời gian)...'

DO $$
DECLARE
    v_use_pg_partman BOOLEAN;
    v_partition_interval TEXT;
    v_retention TEXT;
    v_premake INTEGER;
BEGIN
    -- Kiểm tra cấu hình trong partitioning.config (cần đảm bảo bảng này có dữ liệu cấu hình cho audit_log)
    SELECT use_pg_partman, partition_interval, retention_period, premake
    INTO v_use_pg_partman, v_partition_interval, v_retention, v_premake
    FROM partitioning.config
    WHERE schema_name = 'audit' AND table_name = 'audit_log'
    LIMIT 1; -- Chỉ lấy 1 cấu hình nếu có

    IF FOUND THEN
        IF v_use_pg_partman THEN
            -- Nếu cấu hình sử dụng pg_partman, gọi hàm create_parent của pg_partman
            -- Hàm này sẽ tạo partition đầu tiên và thiết lập cấu hình cho pg_partman quản lý
            -- Lưu ý: Cần đảm bảo pg_partman extension đã được cài đặt và cấu hình đúng.
             RAISE NOTICE '    -> Sử dụng pg_partman để quản lý audit.audit_log. Gọi create_parent...';
             BEGIN
                 -- Kiểm tra sự tồn tại của hàm trước khi gọi
                 IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'create_parent' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
                     RAISE WARNING '    -> Lỗi: Hàm public.create_parent (pg_partman) không tồn tại. Bỏ qua thiết lập phân vùng tự động cho audit.audit_log.';
                     PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Failed', 'Hàm pg_partman.create_parent không tồn tại.');
                 ELSE
                     PERFORM public.create_parent(
                         p_parent_table := 'audit.audit_log',
                         p_control := 'action_tstamp',
                         p_type := 'native', -- Sử dụng native partitioning của PostgreSQL
                         p_interval := COALESCE(v_partition_interval, '1 month'), -- Lấy từ config, mặc định '1 month'
                         p_premake := COALESCE(v_premake, 4), -- Lấy từ config, mặc định 4
                         p_start_partition := date_trunc('month', current_date)::text -- Bắt đầu từ tháng hiện tại
                     );
                     -- Thiết lập retention policy (nếu có)
                     IF v_retention IS NOT NULL THEN
                         UPDATE public.part_config -- Bảng config của pg_partman
                         SET retention = v_retention,
                             retention_keep_table = true, -- Giữ lại bảng khi detach (để có thể archive)
                             retention_keep_index = true
                         WHERE parent_table = 'audit.audit_log';
                         RAISE NOTICE '       -> Đã thiết lập retention policy: %', v_retention;
                     END IF;

                     PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Success', 'Đã gọi pg_partman.create_parent.');
                     RAISE NOTICE '    -> Đã gọi pg_partman.create_parent cho audit.audit_log.';
                     RAISE NOTICE '    -> Lưu ý: Cần chạy pg_partman.run_maintenance() định kỳ (qua pg_cron/Airflow) để tạo partition mới và xử lý retention.';
                 END IF;
             EXCEPTION WHEN OTHERS THEN
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

\echo '*** HOÀN THÀNH THỰC THI SETUP PHÂN VÙNG CHO ministry_of_justice ***'
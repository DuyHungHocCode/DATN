-- File: national_citizen_central_server/partitioning/execute_setup.sql
-- Description: Thực thi việc thiết lập phân vùng cho các bảng trong database
--              Máy chủ Trung tâm (TT) bằng cách gọi các function đã định nghĩa.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Các functions trong national_citizen_central_server/partitioning/functions.sql đã được tạo.
-- - Dữ liệu cấu hình trong partitioning.config đã được nạp.
-- - Dữ liệu trong các bảng reference.* đã được nạp.
-- - Extension 'pg_partman' (nếu dùng cho audit_log).
-- =============================================================================

\echo '--> Bắt đầu thực thi thiết lập phân vùng cho national_citizen_central_server...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
\connect national_citizen_central_server

BEGIN;

-- ============================================================================
-- 1. THIẾT LẬP PHÂN VÙNG CHO BẢNG central.integrated_citizen
-- ============================================================================
\echo '--> 1. Thiết lập phân vùng cho central.integrated_citizen (Miền -> Tỉnh -> Huyện)...'

-- Gọi hàm setup phân vùng lồng nhau 3 cấp
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'central',
    p_table             := 'integrated_citizen',
    p_region_column     := 'geographical_region', -- Cột chứa tên Miền
    p_province_column   := 'province_id',         -- Cột chứa ID Tỉnh
    p_district_column   := 'district_id',         -- Cột chứa ID Huyện
    p_include_district  := TRUE                     -- Phân vùng đến cấp Huyện
);

-- Gọi hàm tạo index cho các partition con của integrated_citizen
-- Lưu ý: Thay thế các định nghĩa index này bằng các index thực tế bạn cần cho bảng integrated_citizen
\echo '    -> Tạo indexes cho các partition của central.integrated_citizen...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'central',
    p_table  := 'integrated_citizen',
    p_index_definitions := ARRAY[
        -- Index trên các cột thường dùng để lọc/tìm kiếm
        'CREATE INDEX IF NOT EXISTS idx_%2$s_full_name ON %1$I.%2$I USING gin (full_name gin_trgm_ops)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dob ON %1$I.%2$I(date_of_birth)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_id_card_num ON %1$I.%2$I(current_id_card_number) WHERE current_id_card_number IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_marital_status ON %1$I.%2$I(marital_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_death_status ON %1$I.%2$I(death_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_perm_addr_id ON %1$I.%2$I(current_permanent_address_id) WHERE current_permanent_address_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_temp_addr_id ON %1$I.%2$I(current_temporary_address_id) WHERE current_temporary_address_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_father_id ON %1$I.%2$I(father_citizen_id) WHERE father_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_mother_id ON %1$I.%2$I(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_spouse_id ON %1$I.%2$I(current_spouse_citizen_id) WHERE current_spouse_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_tax_code ON %1$I.%2$I(tax_code) WHERE tax_code IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_bhxh ON %1$I.%2$I(social_insurance_no) WHERE social_insurance_no IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_bhyt ON %1$I.%2$I(health_insurance_no) WHERE health_insurance_no IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_last_integrated ON %1$I.%2$I(last_integrated_at)'
        -- Thêm các index khác nếu cần
    ]
);

-- ============================================================================
-- 2. THIẾT LẬP PHÂN VÙNG CHO BẢNG central.integrated_household
-- ============================================================================
\echo '--> 2. Thiết lập phân vùng cho central.integrated_household (Miền -> Tỉnh -> Huyện)...'

-- Gọi hàm setup phân vùng lồng nhau 3 cấp
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'central',
    p_table             := 'integrated_household',
    p_region_column     := 'geographical_region', -- Cột chứa tên Miền
    p_province_column   := 'province_id',         -- Cột chứa ID Tỉnh
    p_district_column   := 'district_id',         -- Cột chứa ID Huyện
    p_include_district  := TRUE                     -- Phân vùng đến cấp Huyện
);

-- Gọi hàm tạo index cho các partition con của integrated_household
\echo '    -> Tạo indexes cho các partition của central.integrated_household...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'central',
    p_table  := 'integrated_household',
    p_index_definitions := ARRAY[
        -- Index trên các cột thường dùng để lọc/tìm kiếm
        'CREATE INDEX IF NOT EXISTS idx_%2$s_source ON %1$I.%2$I(source_system, source_household_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_head_id ON %1$I.%2$I(head_of_household_citizen_id) WHERE head_of_household_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_ward_id ON %1$I.%2$I(ward_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(household_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_integrated_at ON %1$I.%2$I(integrated_at)'
        -- Thêm các index khác nếu cần
    ]
);

-- ============================================================================
-- 3. THIẾT LẬP PHÂN VÙNG CHO BẢNG audit.audit_log (THEO THỜI GIAN)
-- ============================================================================
\echo '--> 3. Thiết lập phân vùng cho audit.audit_log (Theo thời gian)...'

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
            -- Hàm này sẽ tạo partition đầu tiên và thiết lập cấu hình cho pg_partman quản lý
            -- Lưu ý: Cần đảm bảo pg_partman extension đã được cài đặt và cấu hình đúng.
             RAISE NOTICE '    -> Sử dụng pg_partman để quản lý audit.audit_log. Gọi create_parent...';
             BEGIN
                 PERFORM public.create_parent( -- Hàm của pg_partman thường nằm trong schema public
                     p_parent_table := 'audit.audit_log',
                     p_control := 'action_tstamp',
                     p_type := 'native', -- Sử dụng native partitioning của PostgreSQL
                     p_interval := v_partition_interval, -- Lấy từ config, vd: '1 month'
                     p_premake := v_premake, -- Lấy từ config, vd: 4
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

\echo '-> Hoàn thành thực thi thiết lập phân vùng cho national_citizen_central_server.'
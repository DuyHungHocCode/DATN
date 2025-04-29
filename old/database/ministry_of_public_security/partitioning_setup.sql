-- =============================================================================
-- File: ministry_of_public_security/partitioning_setup.sql
-- Description: Thực thi việc thiết lập phân vùng cho các bảng trong database
--              Bộ Công an (BCA) bằng cách gọi các function đã định nghĩa
--              trong file 03_functions.sql.
-- Version: 3.1 (Aligned with new directory structure)
--
-- Bao gồm:
-- 1. Thiết lập phân vùng lồng nhau (Miền -> Tỉnh -> Huyện hoặc Miền -> Tỉnh).
-- 2. Tạo các index cần thiết trên từng partition con.
-- 3. Thiết lập phân vùng theo thời gian cho bảng audit_log (sử dụng pg_partman nếu cấu hình).
--
-- Yêu cầu:
-- - Chạy sau khi đã tạo các hàm (03_functions.sql).
-- - Dữ liệu trong các bảng reference.* (regions, provinces, districts) đã được nạp.
-- - Dữ liệu cấu hình trong partitioning.config đã được nạp (đặc biệt cho audit_log).
-- - Extension 'pg_partman' đã được cài đặt và cấu hình nếu sử dụng cho audit_log.
-- - Cần quyền thực thi các hàm trong schema partitioning và tạo bảng/index.
-- =============================================================================

\echo '--> Bắt đầu thực thi thiết lập phân vùng cho ministry_of_public_security...'
\connect ministry_of_public_security

BEGIN;

-- === 1. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen ===
\echo '[1] Thiết lập phân vùng cho public_security.citizen (3 cấp)...'
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
        -- Thêm các index khác cần thiết cho citizen dựa trên file gốc
        'CREATE INDEX IF NOT EXISTS idx_%2$s_father_id ON %1$I.%2$I(father_citizen_id) WHERE father_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_mother_id ON %1$I.%2$I(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_tax_code ON %1$I.%2$I(tax_code) WHERE tax_code IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_bhxh ON %1$I.%2$I(social_insurance_no) WHERE social_insurance_no IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_bhyt ON %1$I.%2$I(health_insurance_no) WHERE health_insurance_no IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_phone ON %1$I.%2$I(current_phone_number) WHERE current_phone_number IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_email ON %1$I.%2$I(current_email) WHERE current_email IS NOT NULL'
    ]
);

-- === 2. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.address ===
\echo '[2] Thiết lập phân vùng cho public_security.address (3 cấp)...'
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
        'CREATE INDEX IF NOT EXISTS idx_%2$s_postcode ON %1$I.%2$I(postal_code) WHERE postal_code IS NOT NULL'
        -- 'CREATE INDEX IF NOT EXISTS idx_%2$s_postgis_geom ON %1$I.%2$I USING gist (coordinates)' -- Nếu dùng PostGIS
    ]
);

-- === 3. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.identification_card ===
\echo '[3] Thiết lập phân vùng cho public_security.identification_card (3 cấp)...'
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
        'CREATE INDEX IF NOT EXISTS idx_%2$s_card_number ON %1$I.%2$I(card_number)', -- Index thường, không unique
        'CREATE INDEX IF NOT EXISTS idx_%2$s_card_type ON %1$I.%2$I(card_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_card_status ON %1$I.%2$I(card_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_issue_date ON %1$I.%2$I(issue_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_expiry_date ON %1$I.%2$I(expiry_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_chip_id ON %1$I.%2$I(chip_id) WHERE chip_id IS NOT NULL'
        -- Unique Index trên từng partition: Đảm bảo mỗi công dân chỉ có 1 thẻ active trong partition đó
        -- Lưu ý: Logic kiểm tra unique toàn cục cần xử lý ở tầng ứng dụng/trigger khác.
        -- 'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_active_id_card ON %1$I.%2$I (citizen_id) WHERE card_status = ''Đang sử dụng'''
    ]
);

-- === 4. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.permanent_residence ===
\echo '[4] Thiết lập phân vùng cho public_security.permanent_residence (3 cấp)...'
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
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
        -- Unique Index trên từng partition: Đảm bảo mỗi công dân chỉ có 1 đăng ký thường trú active trong partition đó.
        -- 'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_active_perm_res ON %1$I.%2$I (citizen_id) WHERE status = TRUE'
    ]
);

-- === 5. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.temporary_residence ===
\echo '[5] Thiết lập phân vùng cho public_security.temporary_residence (3 cấp)...'
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
        -- Index cho registration_number đã tạo bởi UNIQUE constraint (nếu có)
    ]
);

-- === 6. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.temporary_absence ===
\echo '[6] Thiết lập phân vùng cho public_security.temporary_absence (2 cấp: Miền -> Tỉnh)...'
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
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dest_addr_id ON %1$I.%2$I(destination_address_id) WHERE destination_address_id IS NOT NULL'
        -- Index cho registration_number đã tạo bởi UNIQUE constraint (nếu có)
    ]
);

-- === 7. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen_status ===
\echo '[7] Thiết lập phân vùng cho public_security.citizen_status (2 cấp: Miền -> Tỉnh)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'citizen_status',
    p_region_column     := 'geographical_region', p_province_column := 'province_id',
    p_district_column   := NULL,
    p_include_district  := FALSE
);
\echo '    -> Tạo indexes cho các partition của public_security.citizen_status...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'citizen_status',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status_type ON %1$I.%2$I(status_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status_date ON %1$I.%2$I(status_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_is_current ON %1$I.%2$I(is_current)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_doc_num ON %1$I.%2$I(document_number) WHERE document_number IS NOT NULL'
    ]
);

-- === 8. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen_movement ===
\echo '[8] Thiết lập phân vùng cho public_security.citizen_movement (2 cấp: Miền -> Tỉnh)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'citizen_movement',
    p_region_column     := 'geographical_region', p_province_column := 'province_id',
    p_district_column   := NULL,
    p_include_district  := FALSE
);
\echo '    -> Tạo indexes cho các partition của public_security.citizen_movement...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'citizen_movement',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_movement_type ON %1$I.%2$I(movement_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_departure_date ON %1$I.%2$I(departure_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_arrival_date ON %1$I.%2$I(arrival_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_from_address_id ON %1$I.%2$I(from_address_id) WHERE from_address_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_to_address_id ON %1$I.%2$I(to_address_id) WHERE to_address_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_doc_no ON %1$I.%2$I(document_no) WHERE document_no IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
    ]
);

-- === 9. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.criminal_record ===
\echo '[9] Thiết lập phân vùng cho public_security.criminal_record (2 cấp: Miền -> Tỉnh)...'
SELECT partitioning.setup_nested_partitioning(
    p_schema            := 'public_security', p_table := 'criminal_record',
    p_region_column     := 'geographical_region', p_province_column := 'province_id',
    p_district_column   := NULL,
    p_include_district  := FALSE
);
\echo '    -> Tạo indexes cho các partition của public_security.criminal_record...'
SELECT partitioning.create_partition_indexes(
    p_schema := 'public_security', p_table  := 'criminal_record',
    p_index_definitions := ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_crime_type ON %1$I.%2$I(crime_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_crime_date ON %1$I.%2$I(crime_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_sentence_date ON %1$I.%2$I(sentence_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(execution_status)'
        -- Index trên decision_number đã tạo bởi UNIQUE constraint (nếu có)
    ]
);

-- === 10. THIẾT LẬP PHÂN VÙNG CHO BẢNG public_security.citizen_address ===
\echo '[10] Thiết lập phân vùng cho public_security.citizen_address (3 cấp)...'
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
        'CREATE INDEX IF NOT EXISTS idx_%2$s_from_date ON %1$I.%2$I(from_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_to_date ON %1$I.%2$I(to_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_is_primary ON %1$I.%2$I(is_primary)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
        -- Unique Index trên từng partition: Đảm bảo mỗi công dân chỉ có 1 địa chỉ chính cho mỗi loại địa chỉ trong partition đó.
        -- 'CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_%2$s_citizen_addr_primary ON %1$I.%2$I (citizen_id, address_type) WHERE is_primary = TRUE AND status = TRUE'
    ]
);

-- === 11. THIẾT LẬP PHÂN VÙNG CHO BẢNG audit.audit_log (THEO THỜI GIAN) ===
\echo '[11] Thiết lập phân vùng cho audit.audit_log (Theo thời gian)...'
DO $$
DECLARE
    v_use_pg_partman BOOLEAN; v_partition_interval TEXT; v_retention TEXT; v_premake INTEGER;
BEGIN
    -- Kiểm tra cấu hình
    SELECT use_pg_partman, partition_interval, retention_period, premake
    INTO v_use_pg_partman, v_partition_interval, v_retention, v_premake
    FROM partitioning.config WHERE schema_name = 'audit' AND table_name = 'audit_log';

    IF FOUND THEN
        IF v_use_pg_partman THEN
             RAISE NOTICE '    -> Sử dụng pg_partman để quản lý audit.audit_log. Gọi create_parent...';
             BEGIN
                 -- Gọi hàm của pg_partman (thường nằm trong schema public)
                 PERFORM public.create_parent(
                     p_parent_table := 'audit.audit_log', p_control := 'action_tstamp',
                     p_type := 'native', p_interval := v_partition_interval,
                     p_premake := v_premake, p_start_partition := date_trunc('month', current_date)::text
                 );
                 -- Thiết lập retention policy (nếu có)
                 IF v_retention IS NOT NULL THEN
                     UPDATE public.part_config SET retention = v_retention, retention_keep_table = true, retention_keep_index = true
                     WHERE parent_table = 'audit.audit_log';
                     RAISE NOTICE '       -> Đã thiết lập retention policy: %', v_retention;
                 END IF;
                 PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Success', 'Đã gọi pg_partman.create_parent.');
                 RAISE NOTICE '    -> Đã gọi pg_partman.create_parent cho audit.audit_log.';
                 RAISE NOTICE '    -> Lưu ý: Cần chạy pg_partman.run_maintenance() định kỳ.';
             EXCEPTION WHEN undefined_function THEN
                 RAISE WARNING '    -> Lỗi: Hàm pg_partman.create_parent không tồn tại. Đảm bảo pg_partman đã được cài đặt.';
                 PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Failed', 'Hàm pg_partman.create_parent không tồn tại.');
             WHEN OTHERS THEN
                 RAISE WARNING '    -> Lỗi khi gọi pg_partman.create_parent: %', SQLERRM;
                 PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Failed', format('Lỗi pg_partman: %s', SQLERRM));
             END;
        ELSE
            RAISE WARNING '    -> Cấu hình audit.audit_log không dùng pg_partman. Cần script tùy chỉnh.';
            PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Skipped', 'Không sử dụng pg_partman.');
        END IF;
    ELSE
        RAISE WARNING '    -> Không tìm thấy cấu hình cho audit.audit_log trong partitioning.config.';
         PERFORM partitioning.log_history('audit', 'audit_log', 'audit.audit_log', 'INIT_PARTITIONING', 'Skipped', 'Không tìm thấy cấu hình.');
    END IF;
END $$;

COMMIT;

\echo '*** HOÀN THÀNH THIẾT LẬP PHÂN VÙNG CHO DATABASE BỘ CÔNG AN ***'
\echo '-> Đã thực thi tạo partition và index cho các bảng liên quan.'
\echo '-> Bước tiếp theo: Xem xét nạp dữ liệu ban đầu (nếu có).'

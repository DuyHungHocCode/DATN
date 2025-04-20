-- =============================================================================
-- File: database/partitioning/execute_partitioning_setup.sql
-- Description: Script thực thi việc thiết lập phân vùng cho các bảng chính
--              trong hệ thống QLDCQG bằng cách gọi các function đã định nghĩa.
-- Version: 1.0
--
-- **QUAN TRỌNG - ĐIỀU KIỆN TIÊN QUYẾT TRƯỚC KHI CHẠY SCRIPT NÀY:**
-- 1. Các database (ministry_of_public_security, ministry_of_justice,
--    national_citizen_central_server) đã được tạo.
-- 2. Các schema cần thiết (public_security, justice, central, reference,
--    partitioning...) đã được tạo trong các database tương ứng.
-- 3. Các bảng tham chiếu (reference.*) đã được tạo VÀ CÓ DỮ LIỆU.
--    Đặc biệt là `reference.regions`, `reference.provinces`, `reference.districts`.
-- 4. Các bảng nghiệp vụ cần phân vùng (ví dụ: public_security.citizen,
--    justice.birth_certificate...) đã được tạo (chưa có dữ liệu hoặc có ít).
-- 5. Các function phân vùng (trong partitioning_functions.sql) đã được load
--    vào các database tương ứng.
-- 6. Các bảng quản lý phân vùng (partitioning.config, partitioning.history)
--    (trong partitioning_tables.sql) đã được tạo.
-- 7. Nên chạy script này trong thời gian bảo trì hệ thống vì nó có thể
--    khóa bảng và di chuyển lượng lớn dữ liệu nếu bảng đã có dữ liệu.
-- =============================================================================

\echo '*** BẮT ĐẦU THỰC THI THIẾT LẬP PHÂN VÙNG DỮ LIỆU ***'
\echo 'Lưu ý: Quá trình này có thể mất nhiều thời gian tùy thuộc vào kích thước dữ liệu ban đầu.'

-- ============================================================================
-- 1. THỰC THI PHÂN VÙNG CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo '--> Bước 1: Thực thi phân vùng cho ministry_of_public_security...'
\connect ministry_of_public_security

-- Gọi các function chính để setup partitioning cho từng nhóm bảng
\echo '  -> Phân vùng các bảng liên quan đến Citizen...'
SELECT partitioning.setup_citizen_tables_partitioning();

\echo '  -> Phân vùng các bảng liên quan đến Residence...'
SELECT partitioning.setup_residence_tables_partitioning();

-- Tạo các index cần thiết trên các partition đã tạo
-- Lưu ý: Định nghĩa index cần khớp với các index đã tạo trong script gốc của bảng
\echo '  -> Tạo indexes trên các partition của Bộ Công an...'

-- Indexes cho bảng citizen
SELECT partitioning.create_partition_indexes(
    'public_security',
    'citizen',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_full_name ON %1$I.%2$I USING gin (full_name gin_trgm_ops)', -- %1$I là schema, %2$I là tên partition
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dob ON %1$I.%2$I(date_of_birth)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_father_id ON %1$I.%2$I(father_citizen_id) WHERE father_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_mother_id ON %1$I.%2$I(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_region_province ON %1$I.%2$I(region_id, province_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_ethnicity_id ON %1$I.%2$I(ethnicity_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_religion_id ON %1$I.%2$I(religion_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_nationality_id ON %1$I.%2$I(nationality_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_occupation_id ON %1$I.%2$I(occupation_id)'
    ]
);

-- Indexes cho bảng identification_card
SELECT partitioning.create_partition_indexes(
    'public_security',
    'identification_card',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_card_status ON %1$I.%2$I(card_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_issue_date ON %1$I.%2$I(issue_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_expiry_date ON %1$I.%2$I(expiry_date)'
        -- UNIQUE index trên bảng gốc (uq_idx_active_id_card_per_citizen) cần xem xét lại khi phân vùng
        -- Có thể cần tạo unique index trên từng partition hoặc global index nếu cần thiết và DB hỗ trợ
    ]
);

-- Indexes cho bảng address
SELECT partitioning.create_partition_indexes(
    'public_security',
    'address',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_ward_id ON %1$I.%2$I(ward_id)',
        -- district_id, province_id, geographical_region đã là phần của PK phân vùng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_region_id ON %1$I.%2$I(region_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(address_type)'
    ]
);

-- Indexes cho bảng citizen_address
SELECT partitioning.create_partition_indexes(
    'public_security',
    'citizen_address',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_type ON %1$I.%2$I(address_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_from_date ON %1$I.%2$I(from_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_to_date ON %1$I.%2$I(to_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
        -- UNIQUE index uq_idx_citizen_address_primary cần xem xét lại
    ]
);

-- Indexes cho bảng permanent_residence
SELECT partitioning.create_partition_indexes(
    'public_security',
    'permanent_residence',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_household_id ON %1$I.%2$I(household_id) WHERE household_id IS NOT NULL'
        -- UNIQUE index uq_idx_active_permanent_residence_per_citizen cần xem xét lại
    ]
);

-- Indexes cho bảng temporary_residence
SELECT partitioning.create_partition_indexes(
    'public_security',
    'temporary_residence',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_expiry_date ON %1$I.%2$I(expiry_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
    ]
);

-- Indexes cho bảng temporary_absence
SELECT partitioning.create_partition_indexes(
    'public_security',
    'temporary_absence',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_from_date ON %1$I.%2$I(from_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_to_date ON %1$I.%2$I(to_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_return_date ON %1$I.%2$I(return_date)'
        -- UNIQUE index uq_idx_temporary_absence_reg_num cần xem xét lại
    ]
);

-- Indexes cho bảng citizen_movement
SELECT partitioning.create_partition_indexes(
    'public_security',
    'citizen_movement',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(movement_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dep_date ON %1$I.%2$I(departure_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_arr_date ON %1$I.%2$I(arrival_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_doc_no ON %1$I.%2$I(document_no) WHERE document_no IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
        -- province_id đã là phần của PK phân vùng
    ]
);

-- Indexes cho bảng citizen_status
SELECT partitioning.create_partition_indexes(
    'public_security',
    'citizen_status',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status_type ON %1$I.%2$I(status_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status_date ON %1$I.%2$I(status_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_doc_num ON %1$I.%2$I(document_number) WHERE document_number IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_is_current ON %1$I.%2$I(is_current)'
    ]
);

-- Indexes cho bảng criminal_record
SELECT partitioning.create_partition_indexes(
    'public_security',
    'criminal_record',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_crime_type ON %1$I.%2$I(crime_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_crime_date ON %1$I.%2$I(crime_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_sentence_date ON %1$I.%2$I(sentence_date)'
    ]
);

\echo '--> Hoàn thành bước 1.'

-- ============================================================================
-- 2. THỰC THI PHÂN VÙNG CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo '--> Bước 2: Thực thi phân vùng cho ministry_of_justice...'
\connect ministry_of_justice

-- Gọi các function chính để setup partitioning cho từng nhóm bảng
\echo '  -> Phân vùng các bảng liên quan đến Hộ tịch...'
SELECT partitioning.setup_civil_status_tables_partitioning();

\echo '  -> Phân vùng các bảng liên quan đến Hộ khẩu...'
SELECT partitioning.setup_household_tables_partitioning();

-- Tạo các index cần thiết trên các partition đã tạo
\echo '  -> Tạo indexes trên các partition của Bộ Tư pháp...'

-- Indexes cho bảng birth_certificate
SELECT partitioning.create_partition_indexes(
    'justice',
    'birth_certificate',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dob ON %1$I.%2$I(date_of_birth)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_father_id ON %1$I.%2$I(father_citizen_id) WHERE father_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_mother_id ON %1$I.%2$I(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)'
    ]
);

-- Indexes cho bảng death_certificate
SELECT partitioning.create_partition_indexes(
    'justice',
    'death_certificate',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_date_of_death ON %1$I.%2$I(date_of_death)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_reg_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_declarant_id ON %1$I.%2$I(declarant_citizen_id) WHERE declarant_citizen_id IS NOT NULL'
    ]
);

-- Indexes cho bảng marriage
SELECT partitioning.create_partition_indexes(
    'justice',
    'marriage',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_husband_id ON %1$I.%2$I(husband_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_wife_id ON %1$I.%2$I(wife_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_marriage_date ON %1$I.%2$I(marriage_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_registration_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_authority_id ON %1$I.%2$I(issuing_authority_id)'
    ]
);

-- Indexes cho bảng divorce
SELECT partitioning.create_partition_indexes(
    'justice',
    'divorce',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_divorce_date ON %1$I.%2$I(divorce_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_registration_date ON %1$I.%2$I(registration_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_issuing_authority_id ON %1$I.%2$I(issuing_authority_id)'
    ]
);

-- Indexes cho bảng household
SELECT partitioning.create_partition_indexes(
    'justice',
    'household',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_head_id ON %1$I.%2$I(head_of_household_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_address_id ON %1$I.%2$I(address_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(household_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
        -- province_id, district_id đã là phần của PK phân vùng
    ]
);

-- Indexes cho bảng household_member
SELECT partitioning.create_partition_indexes(
    'justice',
    'household_member',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_household_id ON %1$I.%2$I(household_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_join_date ON %1$I.%2$I(join_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_leave_date ON %1$I.%2$I(leave_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)'
    ]
);

-- Indexes cho bảng family_relationship
SELECT partitioning.create_partition_indexes(
    'justice',
    'family_relationship',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen1 ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen2 ON %1$I.%2$I(related_citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(relationship_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_start_date ON %1$I.%2$I(start_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_end_date ON %1$I.%2$I(end_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_pair ON %1$I.%2$I(citizen_id, related_citizen_id)'
    ]
);

-- Indexes cho bảng population_change
SELECT partitioning.create_partition_indexes(
    'justice',
    'population_change',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_citizen_id ON %1$I.%2$I(citizen_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_change_type ON %1$I.%2$I(change_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_change_date ON %1$I.%2$I(change_date)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_source_loc_id ON %1$I.%2$I(source_location_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dest_loc_id ON %1$I.%2$I(destination_location_id)'
    ]
);

\echo '--> Hoàn thành bước 2.'

-- ============================================================================
-- 3. THỰC THI PHÂN VÙNG CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo '--> Bước 3: Thực thi phân vùng cho national_citizen_central_server...'
\connect national_citizen_central_server

-- Gọi function chính để setup partitioning
\echo '  -> Phân vùng các bảng dữ liệu tích hợp...'
SELECT partitioning.setup_integrated_data_partitioning();

-- Tạo các index cần thiết trên các partition đã tạo
\echo '  -> Tạo indexes trên các partition của Máy chủ Trung tâm...'

-- Indexes cho bảng integrated_citizen
SELECT partitioning.create_partition_indexes(
    'central',
    'integrated_citizen',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_full_name ON %1$I.%2$I USING gin (full_name gin_trgm_ops)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_dob ON %1$I.%2$I(date_of_birth)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_id_card_num ON %1$I.%2$I(current_id_card_number) WHERE current_id_card_number IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_marital_status ON %1$I.%2$I(marital_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_death_status ON %1$I.%2$I(death_status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_perm_addr_id ON %1$I.%2$I(current_permanent_address_id) WHERE current_permanent_address_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_father_id ON %1$I.%2$I(father_citizen_id) WHERE father_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_mother_id ON %1$I.%2$I(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_spouse_id ON %1$I.%2$I(current_spouse_citizen_id) WHERE current_spouse_citizen_id IS NOT NULL',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_region_prov_dist ON %1$I.%2$I(region_id, province_id, district_id)', -- Đã có trong PK nhưng tạo thêm để rõ ràng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_last_integrated ON %1$I.%2$I(last_integrated_at)'
    ]
);

-- Indexes cho bảng integrated_household
SELECT partitioning.create_partition_indexes(
    'central',
    'integrated_household',
    ARRAY[
        'CREATE INDEX IF NOT EXISTS idx_%2$s_source ON %1$I.%2$I(source_system, source_household_id)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_book_no ON %1$I.%2$I(household_book_no)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_head_id ON %1$I.%2$I(head_of_household_citizen_id) WHERE head_of_household_citizen_id IS NOT NULL',
        -- province_id, district_id đã là phần của PK phân vùng
        'CREATE INDEX IF NOT EXISTS idx_%2$s_status ON %1$I.%2$I(status)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_type ON %1$I.%2$I(household_type)',
        'CREATE INDEX IF NOT EXISTS idx_%2$s_integrated_at ON %1$I.%2$I(integrated_at)'
    ]
);

-- Lưu ý: Các bảng trong schema 'analytics' có thể cần chiến lược phân vùng và indexing khác (ví dụ theo thời gian)
-- Việc tạo index cho các bảng analytics cần được thực hiện riêng dựa trên nhu cầu truy vấn cụ thể.

\echo '--> Hoàn thành bước 3.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH THỰC THI THIẾT LẬP PHÂN VÙNG DỮ LIỆU ***'
\echo 'Kiểm tra log và bảng partitioning.history trong từng database để xem chi tiết.'
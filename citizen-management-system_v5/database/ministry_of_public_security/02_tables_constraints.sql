-- =============================================================================
-- File: ministry_of_public_security/02_tables_constraints.sql
-- Description: Thêm các ràng buộc (FOREIGN KEY, CHECK, UNIQUE) cho các bảng
--              trong database Bộ Công an (ministry_of_public_security).
-- =============================================================================

\echo '*** BẮT ĐẦU THÊM RÀNG BUỘC CHO CÁC BẢNG NGHIỆP VỤ BCA ***'
\connect ministry_of_public_security

-- === Schema: public_security ===

\echo '[1] Thêm ràng buộc cho các bảng trong schema: public_security...'

-- Ràng buộc cho bảng: citizen
ALTER TABLE public_security.citizen
    ADD CONSTRAINT fk_citizen_ethnicity FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicities(ethnicity_id),
    ADD CONSTRAINT fk_citizen_religion FOREIGN KEY (religion_id) REFERENCES reference.religions(religion_id),
    ADD CONSTRAINT fk_citizen_nationality FOREIGN KEY (nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_citizen_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupations(occupation_id),
    ADD CONSTRAINT fk_citizen_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_citizen_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- FK tự tham chiếu cho cha/mẹ cần kiểm tra kỹ với partitioning, tạm thời bỏ qua hoặc xử lý bằng logic ứng dụng
    -- ADD CONSTRAINT fk_citizen_father FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id),
    -- ADD CONSTRAINT fk_citizen_mother FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT ck_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$'),
    ADD CONSTRAINT ck_citizen_birth_date CHECK (date_of_birth < CURRENT_DATE),
    ADD CONSTRAINT ck_citizen_parents CHECK (citizen_id <> father_citizen_id AND citizen_id <> mother_citizen_id),
    ADD CONSTRAINT ck_citizen_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') OR region_id IS NULL );
    -- Lưu ý: Ràng buộc UNIQUE trên tax_code, social_insurance_no, health_insurance_no
    -- có thể không hoạt động hiệu quả hoặc không được hỗ trợ trực tiếp trên bảng phân vùng
    -- nếu không bao gồm đủ các cột khóa phân vùng. Cân nhắc kiểm tra ở tầng ứng dụng.
    -- Tuy nhiên, vẫn thêm constraint để thể hiện ý định thiết kế.
    -- ALTER TABLE public_security.citizen ADD CONSTRAINT uq_citizen_tax_code UNIQUE (tax_code); -- Gây lỗi nếu không có cột phân vùng
    -- ALTER TABLE public_security.citizen ADD CONSTRAINT uq_citizen_social_insurance_no UNIQUE (social_insurance_no); -- Gây lỗi nếu không có cột phân vùng
    -- ALTER TABLE public_security.citizen ADD CONSTRAINT uq_citizen_health_insurance_no UNIQUE (health_insurance_no); -- Gây lỗi nếu không có cột phân vùng

-- Ràng buộc cho bảng: address
ALTER TABLE public_security.address
    ADD CONSTRAINT fk_address_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    ADD CONSTRAINT fk_address_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT fk_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT ck_address_lat_lon CHECK ( (latitude IS NULL AND longitude IS NULL) OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) ),
    ADD CONSTRAINT ck_address_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );

-- Ràng buộc cho bảng: identification_card
ALTER TABLE public_security.identification_card
    -- Lưu ý: FK đến bảng citizen đã phân vùng cần kiểm tra kỹ
    ADD CONSTRAINT fk_identification_card_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_identification_card_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_identification_card_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_identification_card_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_identification_card_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT ck_identification_card_dates CHECK (issue_date <= CURRENT_DATE AND (expiry_date IS NULL OR expiry_date > issue_date)),
    ADD CONSTRAINT ck_identification_card_number_format CHECK (card_number ~ '^[0-9]{9}$' OR card_number ~ '^[0-9]{12}$'),
    ADD CONSTRAINT ck_identification_card_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );
    -- ALTER TABLE public_security.identification_card ADD CONSTRAINT uq_identification_card_number UNIQUE (card_number); -- Gây lỗi nếu không có cột phân vùng
    -- ALTER TABLE public_security.identification_card ADD CONSTRAINT uq_identification_card_chip_id UNIQUE (chip_id) WHERE chip_id IS NOT NULL; -- Gây lỗi nếu không có cột phân vùng
    -- Ràng buộc UNIQUE logic: Mỗi công dân chỉ có 1 thẻ active (cần xử lý ở tầng ứng dụng hoặc trigger phức tạp hơn trên bảng phân vùng)
    -- ALTER TABLE public_security.identification_card ADD CONSTRAINT uq_active_id_card_per_citizen UNIQUE (citizen_id) WHERE card_status = 'Đang sử dụng';

-- Ràng buộc cho bảng: permanent_residence
ALTER TABLE public_security.permanent_residence
    ADD CONSTRAINT fk_permanent_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_permanent_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_permanent_residence_prev_address FOREIGN KEY (previous_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_permanent_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_permanent_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_permanent_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_permanent_residence_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT ck_permanent_residence_date CHECK (registration_date <= CURRENT_DATE),
    ADD CONSTRAINT ck_permanent_residence_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );
    -- Ràng buộc UNIQUE logic: Mỗi công dân chỉ có 1 đăng ký thường trú active
    -- ALTER TABLE public_security.permanent_residence ADD CONSTRAINT uq_active_permanent_residence_per_citizen UNIQUE (citizen_id) WHERE status = TRUE;

-- Ràng buộc cho bảng: temporary_residence
ALTER TABLE public_security.temporary_residence
    ADD CONSTRAINT fk_temporary_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_temporary_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_temporary_residence_perm_addr FOREIGN KEY (permanent_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_temporary_residence_host FOREIGN KEY (host_citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_temporary_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_temporary_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_temporary_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_temporary_residence_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT ck_temporary_residence_dates CHECK ( registration_date <= CURRENT_DATE AND (expiry_date IS NULL OR expiry_date >= registration_date) AND (last_extension_date IS NULL OR (last_extension_date >= registration_date AND last_extension_date <= CURRENT_DATE)) AND (verification_date IS NULL OR verification_date <= CURRENT_DATE) ),
    ADD CONSTRAINT ck_temporary_residence_status CHECK (status IN ('Active', 'Expired', 'Cancelled', 'Extended')),
    ADD CONSTRAINT ck_temporary_residence_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );
    -- ALTER TABLE public_security.temporary_residence ADD CONSTRAINT uq_temporary_residence_reg_num UNIQUE (registration_number); -- Gây lỗi nếu không có cột phân vùng

-- Ràng buộc cho bảng: temporary_absence
ALTER TABLE public_security.temporary_absence
    ADD CONSTRAINT fk_temporary_absence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_temporary_absence_dest_addr FOREIGN KEY (destination_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_temporary_absence_authority FOREIGN KEY (registration_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_temporary_absence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_temporary_absence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT ck_temporary_absence_dates CHECK ( from_date <= CURRENT_DATE AND (to_date IS NULL OR to_date >= from_date) AND (return_date IS NULL OR return_date >= from_date) AND (return_confirmed_date IS NULL OR (return_confirmed_date >= from_date AND return_confirmed_date <= CURRENT_DATE)) AND (verification_date IS NULL OR verification_date <= CURRENT_DATE) ),
    ADD CONSTRAINT ck_temporary_absence_status CHECK (status IN ('Active', 'Expired', 'Cancelled', 'Returned')),
    ADD CONSTRAINT ck_temporary_absence_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );
    -- ALTER TABLE public_security.temporary_absence ADD CONSTRAINT uq_temporary_absence_reg_num UNIQUE (registration_number) WHERE registration_number IS NOT NULL; -- Gây lỗi nếu không có cột phân vùng

-- Ràng buộc cho bảng: citizen_status
ALTER TABLE public_security.citizen_status
    ADD CONSTRAINT fk_citizen_status_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_citizen_status_authority FOREIGN KEY (authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_citizen_status_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_status_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT ck_citizen_status_date CHECK (status_date <= CURRENT_DATE),
    ADD CONSTRAINT ck_citizen_document_date CHECK (document_date IS NULL OR (document_date <= CURRENT_DATE)),
    ADD CONSTRAINT ck_citizen_cause_location_required CHECK ( (status_type IN ('Đã mất', 'Mất tích') AND cause IS NOT NULL AND location IS NOT NULL) OR (status_type = 'Còn sống') ),
    ADD CONSTRAINT ck_citizen_status_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );

-- Ràng buộc cho bảng: citizen_movement
ALTER TABLE public_security.citizen_movement
    ADD CONSTRAINT fk_citizen_movement_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_citizen_movement_from_addr FOREIGN KEY (from_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_citizen_movement_to_addr FOREIGN KEY (to_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_citizen_movement_from_ctry FOREIGN KEY (from_country_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_citizen_movement_to_ctry FOREIGN KEY (to_country_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_citizen_movement_src_region FOREIGN KEY (source_region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_movement_tgt_region FOREIGN KEY (target_region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_movement_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT ck_citizen_movement_dates CHECK ( departure_date <= CURRENT_DATE AND (arrival_date IS NULL OR arrival_date >= departure_date) AND (document_issue_date IS NULL OR document_issue_date <= departure_date) AND (document_expiry_date IS NULL OR document_expiry_date >= document_issue_date) ),
    ADD CONSTRAINT ck_citizen_movement_status CHECK (status IN ('Hoạt động', 'Hoàn thành', 'Đã hủy')),
    ADD CONSTRAINT ck_citizen_movement_international CHECK ( (movement_type IN ('Xuất cảnh', 'Tái nhập cảnh') AND to_country_id IS NOT NULL AND border_checkpoint IS NOT NULL) OR (movement_type = 'Nhập cảnh' AND from_country_id IS NOT NULL AND border_checkpoint IS NOT NULL) OR (movement_type = 'Trong nước') ),
    ADD CONSTRAINT ck_citizen_movement_address_country CHECK ( NOT (movement_type = 'Xuất cảnh' AND from_address_id IS NOT NULL) AND NOT (movement_type = 'Nhập cảnh' AND to_address_id IS NOT NULL) ),
    ADD CONSTRAINT ck_citizen_movement_geo_region CHECK ( geographical_region IN ('Bắc', 'Trung', 'Nam') );

-- Ràng buộc cho bảng: criminal_record
ALTER TABLE public_security.criminal_record
    ADD CONSTRAINT fk_criminal_record_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_criminal_record_prison FOREIGN KEY (prison_facility_id) REFERENCES reference.prison_facilities(prison_facility_id),
    ADD CONSTRAINT fk_criminal_record_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_criminal_record_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT ck_criminal_record_dates CHECK ( crime_date <= sentence_date AND sentence_date <= decision_date AND decision_date <= CURRENT_DATE AND (entry_date IS NULL OR (entry_date >= sentence_date AND entry_date <= CURRENT_DATE)) AND (release_date IS NULL OR release_date >= entry_date) ),
    ADD CONSTRAINT ck_criminal_record_region_consistency CHECK ( (region_id IS NULL) OR (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );
    -- ALTER TABLE public_security.criminal_record ADD CONSTRAINT uq_criminal_record_decision_number UNIQUE (decision_number); -- Gây lỗi nếu không có cột phân vùng

-- Ràng buộc cho bảng: digital_identity
ALTER TABLE public_security.digital_identity
    ADD CONSTRAINT fk_digital_identity_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT ck_digital_id_phone_format CHECK (phone_number IS NULL OR phone_number ~ '^\+?[0-9]{10,14}$'),
    ADD CONSTRAINT ck_digital_id_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    ADD CONSTRAINT ck_digital_id_format CHECK (digital_id ~ '^[A-Za-z0-9.-]+$'),
    ADD CONSTRAINT ck_digital_id_activation_date CHECK (activation_date <= CURRENT_TIMESTAMP);
    -- Ràng buộc UNIQUE logic: Mỗi công dân chỉ có 1 định danh active
    -- ALTER TABLE public_security.digital_identity ADD CONSTRAINT uq_active_digital_id_per_citizen UNIQUE (citizen_id) WHERE status = TRUE;

-- Ràng buộc cho bảng: user_account
ALTER TABLE public_security.user_account
    ADD CONSTRAINT fk_user_account_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE SET NULL,
    ADD CONSTRAINT ck_user_account_user_type CHECK (user_type IN ('Cán bộ', 'Quản trị viên')),
    ADD CONSTRAINT ck_user_account_status CHECK (status IN ('Active', 'Inactive', 'Locked', 'PendingVerification')),
    ADD CONSTRAINT ck_user_account_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    ADD CONSTRAINT ck_user_account_phone_format CHECK (phone_number IS NULL OR phone_number ~* '^\+?[0-9]{10,15}$');

-- Ràng buộc cho bảng: citizen_address
ALTER TABLE public_security.citizen_address
    ADD CONSTRAINT fk_citizen_address_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_citizen_address_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_citizen_address_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_citizen_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_citizen_address_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT ck_citizen_address_dates CHECK ( from_date <= CURRENT_DATE AND (to_date IS NULL OR to_date >= from_date) AND (registration_date IS NULL OR registration_date <= CURRENT_DATE) AND (verification_date IS NULL OR verification_date <= CURRENT_DATE) ),
    ADD CONSTRAINT ck_citizen_address_region_consistency CHECK ( (region_id = 1 AND geographical_region = 'Bắc') OR (region_id = 2 AND geographical_region = 'Trung') OR (region_id = 3 AND geographical_region = 'Nam') );
    -- Ràng buộc UNIQUE logic: Mỗi công dân chỉ có 1 địa chỉ chính cho mỗi loại địa chỉ
    -- ALTER TABLE public_security.citizen_address ADD CONSTRAINT uq_citizen_address_primary UNIQUE (citizen_id, address_type) WHERE is_primary = TRUE AND status = TRUE;

\echo '   -> Hoàn thành thêm ràng buộc schema public_security.'


-- === Schema: partitioning ===

\echo '[2] Thêm ràng buộc cho các bảng trong schema: partitioning...'

-- Ràng buộc cho bảng: config
ALTER TABLE partitioning.config
    ADD CONSTRAINT ck_partition_config_type CHECK (partition_type IN ('NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER'));

-- Ràng buộc cho bảng: history
ALTER TABLE partitioning.history
    ADD CONSTRAINT fk_partition_history_config FOREIGN KEY (schema_name, table_name) REFERENCES partitioning.config(schema_name, table_name) ON DELETE SET NULL,
    ADD CONSTRAINT ck_partition_history_action CHECK (action IN ('INIT_PARTITIONING', 'CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION', 'ARCHIVE_START', 'ARCHIVE_PARTITION', 'ARCHIVED', 'ARCHIVE_COMPLETE', 'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'DROP_INDEX', 'CONFIG_UPDATE', 'ERROR')),
    ADD CONSTRAINT ck_partition_history_status CHECK (status IN ('Success', 'Failed', 'Running', 'Skipped'));

\echo '   -> Hoàn thành thêm ràng buộc schema partitioning.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH THÊM RÀNG BUỘC CHO DATABASE BỘ CÔNG AN ***'
\echo '-> Đã thêm các ràng buộc FOREIGN KEY, CHECK, UNIQUE cần thiết.'
\echo '-> Bước tiếp theo: Chạy script 03_functions.sql để tạo các hàm.'


-- =============================================================================
-- File: database/constraints/public_security_constraints.sql
-- Description: Định nghĩa các ràng buộc cho schema public_security
-- Version: 1.0
-- =============================================================================

\echo 'Thiết lập ràng buộc cho schema public_security...'
\connect ministry_of_public_security

BEGIN;

-- =============================================================================
-- 1. RÀNG BUỘC KHÓA CHÍNH (PRIMARY KEY CONSTRAINTS)
-- =============================================================================

-- Đã có một số ràng buộc khóa chính khi tạo bảng, bổ sung thêm nếu cần
ALTER TABLE IF EXISTS public_security.citizen 
    ADD CONSTRAINT pk_citizen PRIMARY KEY (citizen_id);

ALTER TABLE IF EXISTS public_security.identification_card 
    ADD CONSTRAINT pk_identification_card PRIMARY KEY (card_id);

ALTER TABLE IF EXISTS public_security.biometric_data 
    ADD CONSTRAINT pk_biometric_data PRIMARY KEY (biometric_id);

ALTER TABLE IF EXISTS public_security.citizen_address 
    ADD CONSTRAINT pk_citizen_address PRIMARY KEY (citizen_address_id);

ALTER TABLE IF EXISTS public_security.permanent_residence 
    ADD CONSTRAINT pk_permanent_residence PRIMARY KEY (permanent_residence_id);

ALTER TABLE IF EXISTS public_security.temporary_residence 
    ADD CONSTRAINT pk_temporary_residence PRIMARY KEY (temporary_residence_id);

ALTER TABLE IF EXISTS public_security.temporary_absence 
    ADD CONSTRAINT pk_temporary_absence PRIMARY KEY (temporary_absence_id);

ALTER TABLE IF EXISTS public_security.citizen_status 
    ADD CONSTRAINT pk_citizen_status PRIMARY KEY (status_id);

ALTER TABLE IF EXISTS public_security.criminal_record 
    ADD CONSTRAINT pk_criminal_record PRIMARY KEY (record_id);

ALTER TABLE IF EXISTS public_security.digital_identity 
    ADD CONSTRAINT pk_digital_identity PRIMARY KEY (digital_identity_id);

ALTER TABLE IF EXISTS public_security.citizen_movement 
    ADD CONSTRAINT pk_citizen_movement PRIMARY KEY (movement_id);

ALTER TABLE IF EXISTS public_security.citizen_image 
    ADD CONSTRAINT pk_citizen_image PRIMARY KEY (image_id);

ALTER TABLE IF EXISTS public_security.user_account 
    ADD CONSTRAINT pk_user_account PRIMARY KEY (user_id);

-- =============================================================================
-- 2. RÀNG BUỘC DUY NHẤT (UNIQUE CONSTRAINTS)
-- =============================================================================

-- Citizen: Không có ràng buộc uniqueness trực tiếp vì citizen_id đã là khóa chính

-- IdentificationCard: Số CCCD phải là duy nhất
ALTER TABLE IF EXISTS public_security.identification_card 
    ADD CONSTRAINT uq_identification_card_number UNIQUE (card_number);

-- Đảm bảo mỗi công dân chỉ có một CCCD đang hoạt động
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_id_card_per_citizen 
    ON public_security.identification_card (citizen_id) 
    WHERE card_status = 'Đang sử dụng';

-- DigitalIdentity: Mã số định danh điện tử phải là duy nhất
ALTER TABLE IF EXISTS public_security.digital_identity 
    ADD CONSTRAINT uq_digital_identity_digital_id UNIQUE (digital_id);

-- Đảm bảo mỗi công dân chỉ có một định danh điện tử đang hoạt động
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_digital_id_per_citizen 
    ON public_security.digital_identity (citizen_id) 
    WHERE status = TRUE;

-- UserAccount: Tên đăng nhập phải là duy nhất
ALTER TABLE IF EXISTS public_security.user_account 
    ADD CONSTRAINT uq_user_account_username UNIQUE (username);

-- Mỗi công dân chỉ có một tài khoản khi citizen_id không null
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_user_account_citizen_id 
    ON public_security.user_account (citizen_id) 
    WHERE citizen_id IS NOT NULL;

-- BiometricData: Mỗi loại dữ liệu sinh trắc học của một công dân phải là duy nhất
ALTER TABLE IF EXISTS public_security.biometric_data
    ADD CONSTRAINT uq_citizen_biometric_type_subtype UNIQUE (citizen_id, biometric_type, biometric_sub_type);

-- PermanentResidence: Mỗi công dân chỉ có một nơi đăng ký thường trú đang hoạt động
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_permanent_residence_per_citizen
    ON public_security.permanent_residence (citizen_id)
    WHERE status = TRUE;

-- =============================================================================
-- 3. RÀNG BUỘC KHÓA NGOẠI (FOREIGN KEY CONSTRAINTS)
-- =============================================================================

-- Các ràng buộc liên quan đến Citizen
ALTER TABLE IF EXISTS public_security.citizen
    ADD CONSTRAINT fk_citizen_ethnicity FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicities(ethnicity_id),
    ADD CONSTRAINT fk_citizen_religion FOREIGN KEY (religion_id) REFERENCES reference.religions(religion_id),
    ADD CONSTRAINT fk_citizen_nationality FOREIGN KEY (nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_citizen_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupations(occupation_id),
    ADD CONSTRAINT fk_citizen_father FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_citizen_mother FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_citizen_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến IdentificationCard
ALTER TABLE IF EXISTS public_security.identification_card
    ADD CONSTRAINT fk_identification_card_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_identification_card_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_identification_card_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_identification_card_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến BiometricData
ALTER TABLE IF EXISTS public_security.biometric_data
    ADD CONSTRAINT fk_biometric_data_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_biometric_data_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_biometric_data_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến Address
ALTER TABLE IF EXISTS public_security.address
    ADD CONSTRAINT fk_address_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    ADD CONSTRAINT fk_address_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT fk_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id);

-- Các ràng buộc liên quan đến CitizenAddress
ALTER TABLE IF EXISTS public_security.citizen_address
    ADD CONSTRAINT fk_citizen_address_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_citizen_address_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_citizen_address_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_citizen_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến PermanentResidence
ALTER TABLE IF EXISTS public_security.permanent_residence
    ADD CONSTRAINT fk_permanent_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_permanent_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_permanent_residence_prev_address FOREIGN KEY (previous_address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_permanent_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_permanent_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_permanent_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến TemporaryResidence
ALTER TABLE IF EXISTS public_security.temporary_residence
    ADD CONSTRAINT fk_temporary_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_temporary_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_temporary_residence_perm_address FOREIGN KEY (permanent_address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_temporary_residence_host FOREIGN KEY (host_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_temporary_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_temporary_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_temporary_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến TemporaryAbsence
ALTER TABLE IF EXISTS public_security.temporary_absence
    ADD CONSTRAINT fk_temporary_absence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_temporary_absence_dest_address FOREIGN KEY (destination_address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_temporary_absence_authority FOREIGN KEY (registration_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_temporary_absence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_temporary_absence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến CitizenStatus
ALTER TABLE IF EXISTS public_security.citizen_status
    ADD CONSTRAINT fk_citizen_status_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_citizen_status_authority FOREIGN KEY (authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_citizen_status_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_status_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến CriminalRecord
ALTER TABLE IF EXISTS public_security.criminal_record
    ADD CONSTRAINT fk_criminal_record_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_criminal_record_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_criminal_record_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến DigitalIdentity
ALTER TABLE IF EXISTS public_security.digital_identity
    ADD CONSTRAINT fk_digital_identity_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);

-- Các ràng buộc liên quan đến CitizenMovement
ALTER TABLE IF EXISTS public_security.citizen_movement
    ADD CONSTRAINT fk_citizen_movement_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_citizen_movement_from_address FOREIGN KEY (from_address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_citizen_movement_to_address FOREIGN KEY (to_address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_citizen_movement_from_country FOREIGN KEY (from_country_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_citizen_movement_to_country FOREIGN KEY (to_country_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_citizen_movement_source_region FOREIGN KEY (source_region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_movement_target_region FOREIGN KEY (target_region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_movement_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến CitizenImage
ALTER TABLE IF EXISTS public_security.citizen_image
    ADD CONSTRAINT fk_citizen_image_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_citizen_image_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_citizen_image_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến UserAccount
ALTER TABLE IF EXISTS public_security.user_account
    ADD CONSTRAINT fk_user_account_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);

-- =============================================================================
-- 4. RÀNG BUỘC KIỂM TRA (CHECK CONSTRAINTS)
-- =============================================================================

-- Kiểm tra định dạng mã công dân (12 số)
ALTER TABLE IF EXISTS public_security.citizen
    ADD CONSTRAINT ck_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$');

-- Kiểm tra ngày sinh hợp lệ (không trong tương lai)
ALTER TABLE IF EXISTS public_security.citizen
    ADD CONSTRAINT ck_citizen_birth_date CHECK (date_of_birth <= CURRENT_DATE);

-- Kiểm tra ngày cấp/hết hạn CCCD hợp lệ
ALTER TABLE IF EXISTS public_security.identification_card
    ADD CONSTRAINT ck_identification_card_dates CHECK (
        issue_date <= CURRENT_DATE AND
        (expiry_date IS NULL OR expiry_date > issue_date)
    );

-- Kiểm tra định dạng số CCCD (9 hoặc 12 số tùy loại)
ALTER TABLE IF EXISTS public_security.identification_card
    ADD CONSTRAINT ck_card_number_format CHECK (
        (card_type = 'CMND 9 số' AND card_number ~ '^[0-9]{9}$') OR
        (card_type = 'CMND 12 số' AND card_number ~ '^[0-9]{12}$') OR
        (card_type IN ('CCCD', 'CCCD gắn chip') AND card_number ~ '^[0-9]{12}$')
    );

-- Kiểm tra chất lượng sinh trắc học (0-100)
ALTER TABLE IF EXISTS public_security.biometric_data
    ADD CONSTRAINT ck_biometric_quality CHECK (quality IS NULL OR (quality >= 0 AND quality <= 100));

-- Kiểm tra các ngày đăng ký cư trú hợp lệ
ALTER TABLE IF EXISTS public_security.permanent_residence
    ADD CONSTRAINT ck_permanent_residence_date CHECK (registration_date <= CURRENT_DATE);

ALTER TABLE IF EXISTS public_security.temporary_residence
    ADD CONSTRAINT ck_temporary_residence_dates CHECK (
        registration_date <= CURRENT_DATE AND
        (expiry_date IS NULL OR expiry_date > registration_date)
    );

ALTER TABLE IF EXISTS public_security.temporary_absence
    ADD CONSTRAINT ck_temporary_absence_dates CHECK (
        from_date <= CURRENT_DATE AND
        (to_date IS NULL OR to_date > from_date) AND
        (return_date IS NULL OR return_date >= from_date)
    );

-- Kiểm tra ngày cập nhật trạng thái công dân hợp lệ
ALTER TABLE IF EXISTS public_security.citizen_status
    ADD CONSTRAINT ck_citizen_status_date CHECK (status_date <= CURRENT_DATE);

-- Kiểm tra khoảng thời gian địa chỉ công dân
ALTER TABLE IF EXISTS public_security.citizen_address
    ADD CONSTRAINT ck_citizen_address_dates CHECK (
        from_date <= CURRENT_DATE AND
        (to_date IS NULL OR to_date > from_date)
    );

-- Kiểm tra thông tin di chuyển của công dân
ALTER TABLE IF EXISTS public_security.citizen_movement
    ADD CONSTRAINT ck_citizen_movement_dates CHECK (
        departure_date <= CURRENT_DATE AND
        (arrival_date IS NULL OR arrival_date >= departure_date)
    );

-- Kiểm tra định dạng địa chỉ email và số điện thoại trong định danh điện tử
ALTER TABLE IF EXISTS public_security.digital_identity
    ADD CONSTRAINT ck_digital_id_email CHECK (
        email IS NULL OR email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'
    ),
    ADD CONSTRAINT ck_digital_id_phone CHECK (
        phone_number IS NULL OR phone_number ~* '^\+?[0-9]{10,14}$'
    );

-- =============================================================================
-- 5. CÁC RÀNG BUỘC MẶC ĐỊNH (DEFAULT CONSTRAINTS)
-- =============================================================================

-- Thiết lập các giá trị mặc định đã được xử lý khi tạo bảng

-- =============================================================================
-- 6. RÀNG BUỘC VÙNG (PARTITION CHECK CONSTRAINTS)
-- =============================================================================

-- Kiểm tra tính nhất quán của vùng địa lý
ALTER TABLE IF EXISTS public_security.citizen
    ADD CONSTRAINT ck_citizen_region_consistency CHECK (
        (region_id = 1 AND geographical_region = 'Bắc') OR
        (region_id = 2 AND geographical_region = 'Trung') OR
        (region_id = 3 AND geographical_region = 'Nam')
    );

-- Tương tự cho các bảng khác có trường geographical_region

COMMIT;

\echo 'Thiết lập ràng buộc cho schema public_security thành công!'
-- =============================================================================
-- File: database/constraints/justice_constraints.sql
-- Description: Định nghĩa các ràng buộc cho schema justice
-- Version: 1.0
-- =============================================================================

\echo 'Thiết lập ràng buộc cho schema justice...'
\connect ministry_of_justice

BEGIN;

-- =============================================================================
-- 1. RÀNG BUỘC KHÓA CHÍNH (PRIMARY KEY CONSTRAINTS)
-- =============================================================================

-- Đã có một số ràng buộc khóa chính khi tạo bảng, bổ sung thêm nếu cần
ALTER TABLE IF EXISTS justice.birth_certificate 
    ADD CONSTRAINT pk_birth_certificate PRIMARY KEY (birth_certificate_id);

ALTER TABLE IF EXISTS justice.death_certificate 
    ADD CONSTRAINT pk_death_certificate PRIMARY KEY (death_certificate_id);

ALTER TABLE IF EXISTS justice.marriage 
    ADD CONSTRAINT pk_marriage PRIMARY KEY (marriage_id);

ALTER TABLE IF EXISTS justice.divorce 
    ADD CONSTRAINT pk_divorce PRIMARY KEY (divorce_id);

ALTER TABLE IF EXISTS justice.household 
    ADD CONSTRAINT pk_household PRIMARY KEY (household_id);

ALTER TABLE IF EXISTS justice.household_member 
    ADD CONSTRAINT pk_household_member PRIMARY KEY (household_member_id);

ALTER TABLE IF EXISTS justice.family_relationship 
    ADD CONSTRAINT pk_family_relationship PRIMARY KEY (relationship_id);

ALTER TABLE IF EXISTS justice.guardian_relationship 
    ADD CONSTRAINT pk_guardian_relationship PRIMARY KEY (relationship_id);

ALTER TABLE IF EXISTS justice.adoption 
    ADD CONSTRAINT pk_adoption PRIMARY KEY (adoption_id);

ALTER TABLE IF EXISTS justice.nationality_change 
    ADD CONSTRAINT pk_nationality_change PRIMARY KEY (change_id);

ALTER TABLE IF EXISTS justice.population_change 
    ADD CONSTRAINT pk_population_change PRIMARY KEY (change_id);

-- =============================================================================
-- 2. RÀNG BUỘC DUY NHẤT (UNIQUE CONSTRAINTS)
-- =============================================================================

-- BirthCertificate: Số giấy khai sinh phải là duy nhất
ALTER TABLE IF EXISTS justice.birth_certificate 
    ADD CONSTRAINT uq_birth_certificate_no UNIQUE (birth_certificate_no);

-- Mỗi công dân chỉ có một giấy khai sinh
ALTER TABLE IF EXISTS justice.birth_certificate 
    ADD CONSTRAINT uq_birth_certificate_citizen_id UNIQUE (citizen_id);

-- DeathCertificate: Số giấy khai tử phải là duy nhất
ALTER TABLE IF EXISTS justice.death_certificate 
    ADD CONSTRAINT uq_death_certificate_no UNIQUE (death_certificate_no);

-- Mỗi công dân chỉ có một giấy khai tử
ALTER TABLE IF EXISTS justice.death_certificate 
    ADD CONSTRAINT uq_death_certificate_citizen_id UNIQUE (citizen_id);

-- Marriage: Số giấy đăng ký kết hôn phải là duy nhất
ALTER TABLE IF EXISTS justice.marriage 
    ADD CONSTRAINT uq_marriage_certificate_no UNIQUE (marriage_certificate_no);

-- Divorce: Số giấy đăng ký ly hôn phải là duy nhất
ALTER TABLE IF EXISTS justice.divorce 
    ADD CONSTRAINT uq_divorce_certificate_no UNIQUE (divorce_certificate_no);

-- Một cuộc hôn nhân chỉ có thể có một giấy ly hôn
ALTER TABLE IF EXISTS justice.divorce 
    ADD CONSTRAINT uq_divorce_marriage_id UNIQUE (marriage_id);

-- Household: Số sổ hộ khẩu phải là duy nhất
ALTER TABLE IF EXISTS justice.household 
    ADD CONSTRAINT uq_household_book_no UNIQUE (household_book_no);

-- =============================================================================
-- 3. RÀNG BUỘC KHÓA NGOẠI (FOREIGN KEY CONSTRAINTS)
-- =============================================================================

-- Các ràng buộc liên quan đến BirthCertificate
ALTER TABLE IF EXISTS justice.birth_certificate
    ADD CONSTRAINT fk_birth_certificate_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_birth_certificate_father FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_birth_certificate_mother FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_birth_certificate_declarant FOREIGN KEY (declarant_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_birth_certificate_father_nationality FOREIGN KEY (father_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_birth_certificate_mother_nationality FOREIGN KEY (mother_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_birth_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_birth_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_birth_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến DeathCertificate
ALTER TABLE IF EXISTS justice.death_certificate
    ADD CONSTRAINT fk_death_certificate_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_death_certificate_declarant FOREIGN KEY (declarant_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_death_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_death_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_death_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến Marriage
ALTER TABLE IF EXISTS justice.marriage
    ADD CONSTRAINT fk_marriage_husband FOREIGN KEY (husband_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_marriage_wife FOREIGN KEY (wife_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_marriage_husband_nationality FOREIGN KEY (husband_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_marriage_wife_nationality FOREIGN KEY (wife_nationality_id) REFERENCES reference.nationalities(nationality_id),
    ADD CONSTRAINT fk_marriage_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_marriage_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_marriage_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến Divorce
ALTER TABLE IF EXISTS justice.divorce
    ADD CONSTRAINT fk_divorce_marriage FOREIGN KEY (marriage_id) REFERENCES justice.marriage(marriage_id),
    ADD CONSTRAINT fk_divorce_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_divorce_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_divorce_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến Household
ALTER TABLE IF EXISTS justice.household
    ADD CONSTRAINT fk_household_head FOREIGN KEY (head_of_household_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_household_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_household_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_household_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_household_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến HouseholdMember
ALTER TABLE IF EXISTS justice.household_member
    ADD CONSTRAINT fk_household_member_household FOREIGN KEY (household_id) REFERENCES justice.household(household_id),
    ADD CONSTRAINT fk_household_member_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_household_member_previous_household FOREIGN KEY (previous_household_id) REFERENCES justice.household(household_id),
    ADD CONSTRAINT fk_household_member_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_household_member_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến FamilyRelationship
ALTER TABLE IF EXISTS justice.family_relationship
    ADD CONSTRAINT fk_family_relationship_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_family_relationship_related FOREIGN KEY (related_citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_family_relationship_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_family_relationship_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến GuardianRelationship (nếu có)
ALTER TABLE IF EXISTS justice.guardian_relationship
    ADD CONSTRAINT fk_guardian_relationship_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_guardian_relationship_guardian FOREIGN KEY (guardian_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_guardian_relationship_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_guardian_relationship_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- Các ràng buộc liên quan đến PopulationChange
ALTER TABLE IF EXISTS justice.population_change
    ADD CONSTRAINT fk_population_change_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id),
    ADD CONSTRAINT fk_population_change_source_location FOREIGN KEY (source_location_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_population_change_destination_location FOREIGN KEY (destination_location_id) REFERENCES public_security.address(address_id),
    ADD CONSTRAINT fk_population_change_authority FOREIGN KEY (processing_authority_id) REFERENCES reference.authorities(authority_id),
    ADD CONSTRAINT fk_population_change_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    ADD CONSTRAINT fk_population_change_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);

-- =============================================================================
-- 4. RÀNG BUỘC KIỂM TRA (CHECK CONSTRAINTS)
-- =============================================================================

-- Kiểm tra các ngày khai sinh hợp lệ
ALTER TABLE IF EXISTS justice.birth_certificate
    ADD CONSTRAINT ck_birth_certificate_dates CHECK (
        date_of_birth <= CURRENT_DATE AND
        registration_date >= date_of_birth AND
        registration_date <= CURRENT_DATE
    );

-- Kiểm tra các ngày khai tử hợp lệ
ALTER TABLE IF EXISTS justice.death_certificate
    ADD CONSTRAINT ck_death_certificate_dates CHECK (
        date_of_death <= CURRENT_DATE AND
        registration_date >= date_of_death AND
        registration_date <= CURRENT_DATE
    );

-- Kiểm tra các ngày đăng ký kết hôn hợp lệ
ALTER TABLE IF EXISTS justice.marriage
    ADD CONSTRAINT ck_marriage_dates CHECK (
        marriage_date <= CURRENT_DATE AND
        registration_date >= marriage_date AND
        registration_date <= CURRENT_DATE
    );

-- Kiểm tra các ngày đăng ký ly hôn hợp lệ
ALTER TABLE IF EXISTS justice.divorce
    ADD CONSTRAINT ck_divorce_dates CHECK (
        divorce_date <= CURRENT_DATE AND
        registration_date >= divorce_date AND
        registration_date <= CURRENT_DATE AND
        judgment_date <= registration_date
    );

-- Kiểm tra các ngày đăng ký hộ khẩu hợp lệ
ALTER TABLE IF EXISTS justice.household
    ADD CONSTRAINT ck_household_dates CHECK (
        registration_date <= CURRENT_DATE
    );

-- Kiểm tra các ngày liên quan đến thành viên hộ khẩu
ALTER TABLE IF EXISTS justice.household_member
    ADD CONSTRAINT ck_household_member_dates CHECK (
        join_date <= CURRENT_DATE AND
        (leave_date IS NULL OR leave_date >= join_date)
    );

-- Kiểm tra các ngày liên quan đến mối quan hệ gia đình
ALTER TABLE IF EXISTS justice.family_relationship
    ADD CONSTRAINT ck_family_relationship_dates CHECK (
        start_date <= CURRENT_DATE AND
        (end_date IS NULL OR end_date >= start_date)
    );

-- Kiểm tra mối quan hệ gia đình không thể là chính mình
ALTER TABLE IF EXISTS justice.family_relationship
    ADD CONSTRAINT ck_family_relationship_different_people CHECK (
        citizen_id <> related_citizen_id
    );

-- Kiểm tra các ngày liên quan đến thay đổi dân cư
ALTER TABLE IF EXISTS justice.population_change
    ADD CONSTRAINT ck_population_change_dates CHECK (
        change_date <= CURRENT_DATE
    );

-- Kiểm tra các điều kiện đặc biệt cho bảng marriage
-- Đảm bảo vợ, chồng phải đủ tuổi kết hôn (nam từ 20 tuổi, nữ từ 18 tuổi)
ALTER TABLE IF EXISTS justice.marriage
    ADD CONSTRAINT ck_marriage_husband_age CHECK (
        husband_date_of_birth <= (marriage_date - INTERVAL '20 years')
    ),
    ADD CONSTRAINT ck_marriage_wife_age CHECK (
        wife_date_of_birth <= (marriage_date - INTERVAL '18 years')
    );

-- Đảm bảo vợ chồng phải là khác giới tính 
ALTER TABLE IF EXISTS justice.marriage
    ADD CONSTRAINT ck_marriage_different_people CHECK (
        husband_id <> wife_id
    );

-- =============================================================================
-- 5. CÁC RÀNG BUỘC MẶC ĐỊNH (DEFAULT CONSTRAINTS)
-- =============================================================================

-- Thiết lập các giá trị mặc định đã được xử lý khi tạo bảng

-- =============================================================================
-- 6. RÀNG BUỘC VÙNG (PARTITION CHECK CONSTRAINTS)
-- =============================================================================

-- Kiểm tra tính nhất quán của vùng địa lý cho các bảng có trường geographical_region
ALTER TABLE IF EXISTS justice.birth_certificate
    ADD CONSTRAINT ck_birth_certificate_region_consistency CHECK (
        (region_id = 1 AND geographical_region = 'Bắc') OR
        (region_id = 2 AND geographical_region = 'Trung') OR
        (region_id = 3 AND geographical_region = 'Nam')
    );

ALTER TABLE IF EXISTS justice.death_certificate
    ADD CONSTRAINT ck_death_certificate_region_consistency CHECK (
        (region_id = 1 AND geographical_region = 'Bắc') OR
        (region_id = 2 AND geographical_region = 'Trung') OR
        (region_id = 3 AND geographical_region = 'Nam')
    );

ALTER TABLE IF EXISTS justice.marriage
    ADD CONSTRAINT ck_marriage_region_consistency CHECK (
        (region_id = 1 AND geographical_region = 'Bắc') OR
        (region_id = 2 AND geographical_region = 'Trung') OR
        (region_id = 3 AND geographical_region = 'Nam')
    );

ALTER TABLE IF EXISTS justice.divorce
    ADD CONSTRAINT ck_divorce_region_consistency CHECK (
        (region_id = 1 AND geographical_region = 'Bắc') OR
        (region_id = 2 AND geographical_region = 'Trung') OR
        (region_id = 3 AND geographical_region = 'Nam')
    );

ALTER TABLE IF EXISTS justice.household
    ADD CONSTRAINT ck_household_region_consistency CHECK (
        (region_id = 1 AND geographical_region = 'Bắc') OR
        (region_id = 2 AND geographical_region = 'Trung') OR
        (region_id = 3 AND geographical_region = 'Nam')
    );

COMMIT;

\echo 'Thiết lập ràng buộc cho schema justice thành công!'
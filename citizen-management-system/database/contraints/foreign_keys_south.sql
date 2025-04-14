-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng và thêm ràng buộc khóa ngoại cho các database vùng miền...'
-- Kết nối đến database miền Bắc
\connect national_citizen_south
-- Hàm tạo ràng buộc cho bảng BirthCertificate
CREATE OR REPLACE FUNCTION add_birth_certificate_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_issuing_authority 
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_father_citizen_id 
        FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_father_nationality 
        FOREIGN KEY (father_nationality_id) REFERENCES reference.nationality(nationality_id);
    
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_mother_citizen_id 
        FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_mother_nationality 
        FOREIGN KEY (mother_nationality_id) REFERENCES reference.nationality(nationality_id);
    
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_declarant_citizen_id 
        FOREIGN KEY (declarant_citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.birth_certificate ADD CONSTRAINT fk_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc cho bảng DeathCertificate
CREATE OR REPLACE FUNCTION add_death_certificate_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.death_certificate ADD CONSTRAINT fk_death_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.death_certificate ADD CONSTRAINT fk_death_declarant_citizen_id 
        FOREIGN KEY (declarant_citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.death_certificate ADD CONSTRAINT fk_death_issuing_authority 
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE justice.death_certificate ADD CONSTRAINT fk_death_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.death_certificate ADD CONSTRAINT fk_death_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc cho bảng Divorce
CREATE OR REPLACE FUNCTION add_divorce_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.divorce ADD CONSTRAINT fk_marriage_id 
        FOREIGN KEY (marriage_id) REFERENCES justice.marriage(marriage_id);
    
    ALTER TABLE justice.divorce ADD CONSTRAINT fk_divorce_issuing_authority 
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE justice.divorce ADD CONSTRAINT fk_divorce_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.divorce ADD CONSTRAINT fk_divorce_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc cho bảng FamilyRelationship
CREATE OR REPLACE FUNCTION add_family_relationship_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.family_relationship ADD CONSTRAINT fk_family_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.family_relationship ADD CONSTRAINT fk_family_related_citizen_id 
        FOREIGN KEY (related_citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.family_relationship ADD CONSTRAINT fk_family_issuing_authority 
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE justice.family_relationship ADD CONSTRAINT fk_family_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.family_relationship ADD CONSTRAINT fk_family_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc cho bảng GuardianRelationship
CREATE OR REPLACE FUNCTION add_guardian_relationship_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.guardian_relationship ADD CONSTRAINT fk_ward_id 
        FOREIGN KEY (ward_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.guardian_relationship ADD CONSTRAINT fk_guardian_id 
        FOREIGN KEY (guardian_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.guardian_relationship ADD CONSTRAINT fk_guardian_issuing_authority 
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE justice.guardian_relationship ADD CONSTRAINT fk_guardian_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.guardian_relationship ADD CONSTRAINT fk_guardian_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc cho bảng HouseholdMember
CREATE OR REPLACE FUNCTION add_household_member_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.household_member ADD CONSTRAINT fk_household_id 
        FOREIGN KEY (household_id) REFERENCES justice.household(household_id);
    
    ALTER TABLE justice.household_member ADD CONSTRAINT fk_member_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.household_member ADD CONSTRAINT fk_previous_household_id 
        FOREIGN KEY (previous_household_id) REFERENCES justice.household(household_id);
    
    ALTER TABLE justice.household_member ADD CONSTRAINT fk_member_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.household_member ADD CONSTRAINT fk_member_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng Marriage
CREATE OR REPLACE FUNCTION add_marriage_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.marriage ADD CONSTRAINT fk_husband_id 
        FOREIGN KEY (husband_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.marriage ADD CONSTRAINT fk_husband_nationality 
        FOREIGN KEY (husband_nationality_id) REFERENCES reference.nationality(nationality_id);
    
    ALTER TABLE justice.marriage ADD CONSTRAINT fk_wife_id 
        FOREIGN KEY (wife_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.marriage ADD CONSTRAINT fk_wife_nationality 
        FOREIGN KEY (wife_nationality_id) REFERENCES reference.nationality(nationality_id);
    
    ALTER TABLE justice.marriage ADD CONSTRAINT fk_marriage_issuing_authority 
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE justice.marriage ADD CONSTRAINT fk_marriage_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.marriage ADD CONSTRAINT fk_marriage_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng PopulationChange
CREATE OR REPLACE FUNCTION add_population_change_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE justice.population_change ADD CONSTRAINT fk_change_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE justice.population_change ADD CONSTRAINT fk_source_location_id 
        FOREIGN KEY (source_location_id) REFERENCES public_security.address(address_id);
    
    ALTER TABLE justice.population_change ADD CONSTRAINT fk_destination_location_id 
        FOREIGN KEY (destination_location_id) REFERENCES public_security.address(address_id);
    
    ALTER TABLE justice.population_change ADD CONSTRAINT fk_processing_authority_id 
        FOREIGN KEY (processing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE justice.population_change ADD CONSTRAINT fk_change_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE justice.population_change ADD CONSTRAINT fk_change_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------

-- Hàm thêm ràng buộc khóa ngoại cho bảng BiometricData
CREATE OR REPLACE FUNCTION add_biometric_data_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.biometric_data ADD CONSTRAINT fk_biometric_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.biometric_data ADD CONSTRAINT fk_biometric_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.biometric_data ADD CONSTRAINT fk_biometric_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
    
    ALTER TABLE public_security.biometric_data ADD CONSTRAINT fk_encryption_type_id 
        FOREIGN KEY (encryption_type_id) REFERENCES reference.encryption_type(encryption_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng CitizenImage
CREATE OR REPLACE FUNCTION add_citizen_image_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.citizen_image ADD CONSTRAINT fk_image_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.citizen_image ADD CONSTRAINT fk_image_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.citizen_image ADD CONSTRAINT fk_image_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng CitizenMovement
CREATE OR REPLACE FUNCTION add_citizen_movement_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.citizen_movement ADD CONSTRAINT fk_movement_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.citizen_movement ADD CONSTRAINT fk_from_address_id 
        FOREIGN KEY (from_address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.citizen_movement ADD CONSTRAINT fk_to_address_id 
        FOREIGN KEY (to_address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.citizen_movement ADD CONSTRAINT fk_source_region_id 
        FOREIGN KEY (source_region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.citizen_movement ADD CONSTRAINT fk_target_region_id 
        FOREIGN KEY (target_region_id) REFERENCES reference.region(region_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng CitizenStatus
CREATE OR REPLACE FUNCTION add_citizen_status_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.citizen_status ADD CONSTRAINT fk_status_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.citizen_status ADD CONSTRAINT fk_status_authority_id 
        FOREIGN KEY (authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE public_security.citizen_status ADD CONSTRAINT fk_status_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.citizen_status ADD CONSTRAINT fk_status_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng Citizen
CREATE OR REPLACE FUNCTION add_citizen_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_ethnicity_id
        FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicity(ethnicity_id);
    
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_religion_id
        FOREIGN KEY (religion_id) REFERENCES reference.religion(religion_id);
    
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_nationality_id
        FOREIGN KEY (nationality_id) REFERENCES reference.nationality(nationality_id);
    
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_education_level_id
        FOREIGN KEY (education_level_id) REFERENCES reference.education_level(education_level_id);
    
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_occupation_type_id
        FOREIGN KEY (occupation_type_id) REFERENCES reference.occupation_type(occupation_type_id);
    
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_father_citizen_id
        FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_mother_citizen_id
        FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_citizen_region_id
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.citizen ADD CONSTRAINT fk_citizen_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng CriminalRecord
CREATE OR REPLACE FUNCTION add_criminal_record_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.criminal_record ADD CONSTRAINT fk_criminal_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.criminal_record ADD CONSTRAINT fk_criminal_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.criminal_record ADD CONSTRAINT fk_criminal_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng DigitalIdentity
CREATE OR REPLACE FUNCTION add_digital_identity_constraints() RETURNS void AS $$
BEGIN
    -- Thêm khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.digital_identity ADD CONSTRAINT fk_digital_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng IdentificationCard
CREATE OR REPLACE FUNCTION add_identification_card_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.identification_card ADD CONSTRAINT fk_card_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.identification_card ADD CONSTRAINT fk_card_issuing_authority 
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE public_security.identification_card ADD CONSTRAINT fk_card_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.identification_card ADD CONSTRAINT fk_card_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm tạo các bảng quản lý cư trú không có ràng buộc khóa ngoại
CREATE OR REPLACE FUNCTION create_residence_tables() RETURNS void AS $$
BEGIN
    -- 1. Bảng Address (Địa chỉ)
    CREATE TABLE IF NOT EXISTS public_security.address (
        address_id SERIAL PRIMARY KEY,
        address_detail TEXT NOT NULL,
        ward_id INT,
        district_id INT,
        province_id INT,
        address_type address_type,
        postal_code VARCHAR(10),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 2. Bảng CitizenAddress (Địa chỉ công dân)
    CREATE TABLE IF NOT EXISTS public_security.citizen_address (
        citizen_address_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        address_type address_type NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        status BOOLEAN DEFAULT TRUE,
        registration_document_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 3. Bảng PermanentResidence (Đăng ký thường trú)
    CREATE TABLE IF NOT EXISTS public_security.permanent_residence (
        permanent_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        decision_no VARCHAR(50),
        issuing_authority_id SMALLINT,
        previous_address_id INT,
        change_reason TEXT,
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 4. Bảng TemporaryResidence (Đăng ký tạm trú)
    CREATE TABLE IF NOT EXISTS public_security.temporary_residence (
        temporary_residence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        address_id INT NOT NULL,
        registration_date DATE NOT NULL,
        expiry_date DATE,
        purpose TEXT,
        issuing_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        permanent_address_id INT,
        host_name VARCHAR(100),
        host_citizen_id VARCHAR(12),
        host_relationship VARCHAR(50),
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 5. Bảng TemporaryAbsence (Đăng ký tạm vắng)
    CREATE TABLE IF NOT EXISTS public_security.temporary_absence (
        temporary_absence_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        from_date DATE NOT NULL,
        to_date DATE,
        reason TEXT,
        destination_address_id INT,
        destination_detail TEXT,
        contact_information TEXT,
        registration_authority_id SMALLINT,
        registration_number VARCHAR(50),
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho các bảng quản lý cư trú
CREATE OR REPLACE FUNCTION add_residence_constraints() RETURNS void AS $$
BEGIN
    -- 1. Ràng buộc khóa ngoại cho bảng address
    ALTER TABLE public_security.address ADD CONSTRAINT fk_address_ward_id
        FOREIGN KEY (ward_id) REFERENCES reference.ward(ward_id);
        
    ALTER TABLE public_security.address ADD CONSTRAINT fk_address_district_id
        FOREIGN KEY (district_id) REFERENCES reference.district(district_id);
        
    ALTER TABLE public_security.address ADD CONSTRAINT fk_address_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
        
    ALTER TABLE public_security.address ADD CONSTRAINT fk_address_region_id
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
    
    -- 2. Ràng buộc khóa ngoại cho bảng citizen_address
    ALTER TABLE public_security.citizen_address ADD CONSTRAINT fk_citizen_address_citizen_id
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
        
    ALTER TABLE public_security.citizen_address ADD CONSTRAINT fk_citizen_address_address_id
        FOREIGN KEY (address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.citizen_address ADD CONSTRAINT fk_citizen_address_authority_id
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
        
    ALTER TABLE public_security.citizen_address ADD CONSTRAINT fk_citizen_address_region_id
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.citizen_address ADD CONSTRAINT fk_citizen_address_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
    
    -- 3. Ràng buộc khóa ngoại cho bảng permanent_residence
    ALTER TABLE public_security.permanent_residence ADD CONSTRAINT fk_permanent_residence_citizen_id
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
        
    ALTER TABLE public_security.permanent_residence ADD CONSTRAINT fk_permanent_residence_address_id
        FOREIGN KEY (address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.permanent_residence ADD CONSTRAINT fk_permanent_residence_authority_id
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
        
    ALTER TABLE public_security.permanent_residence ADD CONSTRAINT fk_permanent_residence_previous_address_id
        FOREIGN KEY (previous_address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.permanent_residence ADD CONSTRAINT fk_permanent_residence_region_id
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.permanent_residence ADD CONSTRAINT fk_permanent_residence_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
    
    -- 4. Ràng buộc khóa ngoại cho bảng temporary_residence
    ALTER TABLE public_security.temporary_residence ADD CONSTRAINT fk_temporary_residence_citizen_id
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
        
    ALTER TABLE public_security.temporary_residence ADD CONSTRAINT fk_temporary_residence_address_id
        FOREIGN KEY (address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.temporary_residence ADD CONSTRAINT fk_temporary_residence_authority_id
        FOREIGN KEY (issuing_authority_id) REFERENCES reference.issuing_authority(authority_id);
        
    ALTER TABLE public_security.temporary_residence ADD CONSTRAINT fk_temporary_residence_permanent_address_id
        FOREIGN KEY (permanent_address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.temporary_residence ADD CONSTRAINT fk_temporary_residence_host_citizen_id
        FOREIGN KEY (host_citizen_id) REFERENCES public_security.citizen(citizen_id);
        
    ALTER TABLE public_security.temporary_residence ADD CONSTRAINT fk_temporary_residence_region_id
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.temporary_residence ADD CONSTRAINT fk_temporary_residence_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
    
    -- 5. Ràng buộc khóa ngoại cho bảng temporary_absence
    ALTER TABLE public_security.temporary_absence ADD CONSTRAINT fk_temporary_absence_citizen_id
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
        
    ALTER TABLE public_security.temporary_absence ADD CONSTRAINT fk_temporary_absence_destination_address_id
        FOREIGN KEY (destination_address_id) REFERENCES public_security.address(address_id);
        
    ALTER TABLE public_security.temporary_absence ADD CONSTRAINT fk_temporary_absence_authority_id
        FOREIGN KEY (registration_authority_id) REFERENCES reference.issuing_authority(authority_id);
        
    ALTER TABLE public_security.temporary_absence ADD CONSTRAINT fk_temporary_absence_region_id
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.temporary_absence ADD CONSTRAINT fk_temporary_absence_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho bảng UserAccount
CREATE OR REPLACE FUNCTION add_user_account_constraints() RETURNS void AS $$
BEGIN
    -- Thêm các khóa ngoại bằng ALTER TABLE
    ALTER TABLE public_security.user_account ADD CONSTRAINT fk_user_citizen_id 
        FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id);
    
    ALTER TABLE public_security.user_account ADD CONSTRAINT fk_user_role_id 
        FOREIGN KEY (role_id) REFERENCES reference.user_role(role_id);
    
    ALTER TABLE public_security.user_account ADD CONSTRAINT fk_user_agency_id 
        FOREIGN KEY (agency_id) REFERENCES reference.issuing_authority(authority_id);
    
    ALTER TABLE public_security.user_account ADD CONSTRAINT fk_user_region_id 
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE public_security.user_account ADD CONSTRAINT fk_user_province_id 
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
END;
$$ LANGUAGE plpgsql;

-- Hàm thêm ràng buộc khóa ngoại cho các bảng tham chiếu
CREATE OR REPLACE FUNCTION add_reference_constraints() RETURNS void AS $$
BEGIN
    -- Ràng buộc cho bảng province
    ALTER TABLE reference.province ADD CONSTRAINT fk_province_region_id
        FOREIGN KEY (region_id) REFERENCES reference.region(region_id);
    
    -- Ràng buộc cho bảng district
    ALTER TABLE reference.district ADD CONSTRAINT fk_district_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
    
    -- Ràng buộc cho bảng ward
    ALTER TABLE reference.ward ADD CONSTRAINT fk_ward_district_id
        FOREIGN KEY (district_id) REFERENCES reference.district(district_id);
    
    -- Ràng buộc cho bảng issuing_authority
    ALTER TABLE reference.issuing_authority ADD CONSTRAINT fk_authority_province_id
        FOREIGN KEY (province_id) REFERENCES reference.province(province_id);
        
    ALTER TABLE reference.issuing_authority ADD CONSTRAINT fk_authority_district_id
        FOREIGN KEY (district_id) REFERENCES reference.district(district_id);
        
    ALTER TABLE reference.issuing_authority ADD CONSTRAINT fk_parent_authority
        FOREIGN KEY (parent_authority_id) REFERENCES reference.issuing_authority(authority_id);
    
    -- Ràng buộc cho bảng sync_config
    ALTER TABLE reference.sync_config ADD CONSTRAINT fk_sync_source_region
        FOREIGN KEY (source_region_id) REFERENCES reference.region(region_id);
        
    ALTER TABLE reference.sync_config ADD CONSTRAINT fk_sync_target_region
        FOREIGN KEY (target_region_id) REFERENCES reference.region(region_id);
END;
$$ LANGUAGE plpgsql;


-- Gọi các hàm để thêm ràng buộc khóa ngoại
SELECT add_birth_certificate_constraints();
SELECT add_death_certificate_constraints();
SELECT add_divorce_constraints();
SELECT add_family_relationship_constraints();
SELECT add_guardian_relationship_constraints();
SELECT add_household_member_constraints();
SELECT add_marriage_constraints();
SELECT add_population_change_constraints();
SELECT add_biometric_data_constraints();
SELECT add_citizen_image_constraints();
SELECT add_citizen_movement_constraints();
SELECT add_citizen_status_constraints();
SELECT add_citizen_constraints();
SELECT add_criminal_record_constraints();
SELECT add_digital_identity_constraints();
SELECT add_identification_card_constraints();
SELECT add_residence_constraints();
SELECT add_user_account_constraints();
SELECT add_reference_constraints();
-- Kết thúc



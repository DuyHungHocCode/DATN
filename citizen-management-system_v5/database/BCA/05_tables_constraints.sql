-- Script để tạo các ràng buộc cho cơ sở dữ liệu DB_BCA (Bộ Công an)
-- File đã được cập nhật để phản ánh các thay đổi trong cấu trúc bảng

USE [DB_BCA];
GO

PRINT N'Creating constraints for tables in DB_BCA...';

--------------------------------------------------------------------------------
-- I. RÀNG BUỘC CHO CÁC BẢNG THAM CHIẾU (Reference)
--------------------------------------------------------------------------------
PRINT N'Creating constraints for Reference tables...';

-- Ràng buộc cho Reference.Provinces
PRINT N'  Adding constraints to Reference.Provinces...';
IF OBJECT_ID('Reference.FK_Province_Region', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Provinces] DROP CONSTRAINT FK_Province_Region;
GO
ALTER TABLE [Reference].[Provinces]
    ADD CONSTRAINT FK_Province_Region FOREIGN KEY ([region_id])
    REFERENCES [Reference].[Regions]([region_id]);
GO

-- Ràng buộc cho Reference.Districts
PRINT N'  Adding constraints to Reference.Districts...';
IF OBJECT_ID('Reference.FK_District_Province', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Districts] DROP CONSTRAINT FK_District_Province;
GO
ALTER TABLE [Reference].[Districts]
    ADD CONSTRAINT FK_District_Province FOREIGN KEY ([province_id])
    REFERENCES [Reference].[Provinces]([province_id]);
GO

-- Ràng buộc cho Reference.Wards
PRINT N'  Adding constraints to Reference.Wards...';
IF OBJECT_ID('Reference.FK_Ward_District', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Wards] DROP CONSTRAINT FK_Ward_District;
GO
ALTER TABLE [Reference].[Wards]
    ADD CONSTRAINT FK_Ward_District FOREIGN KEY ([district_id])
    REFERENCES [Reference].[Districts]([district_id]);
GO

-- Ràng buộc cho Reference.Authorities
PRINT N'  Adding constraints to Reference.Authorities...';
IF OBJECT_ID('Reference.FK_Authority_Ward', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_Ward;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_Ward FOREIGN KEY ([ward_id])
    REFERENCES [Reference].[Wards]([ward_id]);
GO

IF OBJECT_ID('Reference.FK_Authority_District', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_District;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_District FOREIGN KEY ([district_id])
    REFERENCES [Reference].[Districts]([district_id]);
GO

IF OBJECT_ID('Reference.FK_Authority_Province', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_Province;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_Province FOREIGN KEY ([province_id])
    REFERENCES [Reference].[Provinces]([province_id]);
GO

IF OBJECT_ID('Reference.FK_Authority_Parent', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_Parent;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_Parent FOREIGN KEY ([parent_authority_id])
    REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Ràng buộc cho Reference.RelationshipTypes
PRINT N'  Adding constraints to Reference.RelationshipTypes...';
IF OBJECT_ID('Reference.FK_Inverse_Relationship', 'F') IS NOT NULL
    ALTER TABLE [Reference].[RelationshipTypes] DROP CONSTRAINT FK_Inverse_Relationship;
GO
ALTER TABLE [Reference].[RelationshipTypes]
    ADD CONSTRAINT FK_Inverse_Relationship FOREIGN KEY ([inverse_relationship_type_id])
    REFERENCES [Reference].[RelationshipTypes]([relationship_type_id]);
GO

-- Ràng buộc cho Reference.PrisonFacilities
PRINT N'  Adding constraints to Reference.PrisonFacilities...';
IF OBJECT_ID('Reference.FK_Prison_Ward', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_Ward;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_Ward FOREIGN KEY ([ward_id])
    REFERENCES [Reference].[Wards]([ward_id]);
GO

IF OBJECT_ID('Reference.FK_Prison_District', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_District;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_District FOREIGN KEY ([district_id])
    REFERENCES [Reference].[Districts]([district_id]);
GO

IF OBJECT_ID('Reference.FK_Prison_Province', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_Province;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_Province FOREIGN KEY ([province_id])
    REFERENCES [Reference].[Provinces]([province_id]);
GO

IF OBJECT_ID('Reference.FK_Prison_Managing_Authority', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_Managing_Authority;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_Managing_Authority FOREIGN KEY ([managing_authority_id])
    REFERENCES [Reference].[Authorities]([authority_id]);
GO

--------------------------------------------------------------------------------
-- II. RÀNG BUỘC CHO BẢNG BCA.Citizen
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.Citizen...';

-- Ràng buộc khóa ngoại từ BCA.Citizen đến các bảng tham chiếu
IF OBJECT_ID('BCA.FK_Citizen_Gender', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Gender;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Gender FOREIGN KEY ([gender_id]) REFERENCES [Reference].[Genders]([gender_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_BirthWard', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthWard;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthWard FOREIGN KEY ([birth_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_BirthDistrict', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthDistrict;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthDistrict FOREIGN KEY ([birth_district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_BirthProvince', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthProvince;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthProvince FOREIGN KEY ([birth_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_BirthCountry', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthCountry;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthCountry FOREIGN KEY ([birth_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_NativeWard', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_NativeWard;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeWard FOREIGN KEY ([native_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_NativeDistrict', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_NativeDistrict;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeDistrict FOREIGN KEY ([native_district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_NativeProvince', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_NativeProvince;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeProvince FOREIGN KEY ([native_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_PrimaryAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_PrimaryAddress;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_PrimaryAddress FOREIGN KEY ([primary_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Nationality', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Nationality;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Nationality FOREIGN KEY ([nationality_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Ethnicity', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Ethnicity;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Ethnicity FOREIGN KEY ([ethnicity_id]) REFERENCES [Reference].[Ethnicities]([ethnicity_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Religion', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Religion;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Religion FOREIGN KEY ([religion_id]) REFERENCES [Reference].[Religions]([religion_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_MaritalStatus', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_MaritalStatus;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_MaritalStatus FOREIGN KEY ([marital_status_id]) REFERENCES [Reference].[MaritalStatuses]([marital_status_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_EducationLevel', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_EducationLevel;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_EducationLevel FOREIGN KEY ([education_level_id]) REFERENCES [Reference].[EducationLevels]([education_level_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Occupation', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Occupation;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Occupation FOREIGN KEY ([occupation_id]) REFERENCES [Reference].[Occupations]([occupation_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Status', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Status;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Status FOREIGN KEY ([citizen_status_id]) REFERENCES [Reference].[CitizenStatusTypes]([citizen_status_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_BloodType', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BloodType;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BloodType FOREIGN KEY ([blood_type_id]) REFERENCES [Reference].[BloodTypes]([blood_type_id]);
GO

-- Ràng buộc tự tham chiếu cho BCA.Citizen
IF OBJECT_ID('BCA.FK_Citizen_Father', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Father;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Father FOREIGN KEY ([father_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Mother', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Mother;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Mother FOREIGN KEY ([mother_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Spouse', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Spouse;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Spouse FOREIGN KEY ([spouse_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Representative', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Representative;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Representative FOREIGN KEY ([representative_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

--------------------------------------------------------------------------------
-- III. RÀNG BUỘC CHO BẢNG BCA.Address
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.Address...';

IF OBJECT_ID('BCA.FK_Address_Ward', 'F') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT FK_Address_Ward;
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Ward FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO

IF OBJECT_ID('BCA.FK_Address_District', 'F') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT FK_Address_District;
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO

IF OBJECT_ID('BCA.FK_Address_Province', 'F') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT FK_Address_Province;
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

--------------------------------------------------------------------------------
-- IV. RÀNG BUỘC CHO BẢNG BCA.IdentificationCard
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.IdentificationCard...';

IF OBJECT_ID('BCA.FK_IdentificationCard_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IdentificationCard_Citizen;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_IdentificationCard_Authority', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IdentificationCard_Authority;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

IF OBJECT_ID('BCA.FK_IdentificationCard_Type', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IdentificationCard_Type;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Type FOREIGN KEY ([card_type_id]) REFERENCES [Reference].[IdentificationCardTypes]([card_type_id]);
GO

IF OBJECT_ID('BCA.FK_IdentificationCard_Status', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IdentificationCard_Status;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Status FOREIGN KEY ([card_status_id]) REFERENCES [Reference].[IdentificationCardStatuses]([card_status_id]);
GO

-- UNIQUE constraint for IdentificationCard.card_number (commented out per request)
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_IdentificationCard_Number') 
--     DROP INDEX UQ_IdentificationCard_Number ON BCA.IdentificationCard;
-- GO
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_IdentificationCard_Number ON BCA.IdentificationCard(card_number) 
--     WHERE card_status_id IN (1, 2); -- Unique constraint for active and expiring cards
-- GO

--------------------------------------------------------------------------------
-- V. RÀNG BUỘC CHO BẢNG BCA.ResidenceHistory
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.ResidenceHistory...';

IF OBJECT_ID('BCA.FK_ResidenceHistory_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResidenceHistory_Citizen;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_ResidenceHistory_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResidenceHistory_Address;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

IF OBJECT_ID('BCA.FK_ResidenceHistory_PreviousAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResidenceHistory_PreviousAddress;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_PreviousAddress FOREIGN KEY ([previous_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

IF OBJECT_ID('BCA.FK_ResidenceHistory_Authority', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResidenceHistory_Authority;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

IF OBJECT_ID('BCA.FK_ResidenceHistory_Type', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResidenceHistory_Type;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Type FOREIGN KEY ([residence_type_id]) REFERENCES [Reference].[ResidenceTypes]([residence_type_id]);
GO

IF OBJECT_ID('BCA.FK_ResidenceHistory_Status', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResidenceHistory_Status;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Status FOREIGN KEY ([res_reg_status_id]) REFERENCES [Reference].[ResidenceRegistrationStatuses]([res_reg_status_id]);
GO

--------------------------------------------------------------------------------
-- VI. RÀNG BUỘC CHO BẢNG BCA.TemporaryAbsence
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.TemporaryAbsence...';

IF OBJECT_ID('BCA.FK_TemporaryAbsence_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_Citizen;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_TemporaryAbsence_DestAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_DestAddress;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_DestAddress FOREIGN KEY ([destination_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

IF OBJECT_ID('BCA.FK_TemporaryAbsence_Authority', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_Authority;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Authority FOREIGN KEY ([registration_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

IF OBJECT_ID('BCA.FK_TemporaryAbsence_Status', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_Status;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Status FOREIGN KEY ([temp_abs_status_id]) REFERENCES [Reference].[TemporaryAbsenceStatuses]([temp_abs_status_id]);
GO

IF OBJECT_ID('BCA.FK_TemporaryAbsence_Sensitivity', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_Sensitivity;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Sensitivity FOREIGN KEY ([sensitivity_level_id]) REFERENCES [Reference].[DataSensitivityLevels]([sensitivity_level_id]);
GO

--------------------------------------------------------------------------------
-- VII. RÀNG BUỘC CHO BẢNG BCA.CitizenStatus
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenStatus...';

IF OBJECT_ID('BCA.FK_CitizenStatus_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Citizen;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenStatus_Status', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Status;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Status FOREIGN KEY ([citizen_status_id]) REFERENCES [Reference].[CitizenStatusTypes]([citizen_status_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenStatus_Authority', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Authority;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Authority FOREIGN KEY ([authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

--------------------------------------------------------------------------------
-- VIII. RÀNG BUỘC CHO BẢNG BCA.CitizenMovement
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenMovement...';

IF OBJECT_ID('BCA.FK_CitizenMovement_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_Citizen;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenMovement_FromAddr', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_FromAddr;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_FromAddr FOREIGN KEY ([from_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenMovement_ToAddr', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_ToAddr;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_ToAddr FOREIGN KEY ([to_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenMovement_FromCtry', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_FromCtry;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_FromCtry FOREIGN KEY ([from_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenMovement_ToCtry', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_ToCtry;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_ToCtry FOREIGN KEY ([to_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenMovement_Type', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_Type;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_Type FOREIGN KEY ([movement_type_id]) REFERENCES [Reference].[CitizenMovementTypes]([movement_type_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenMovement_Status', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_Status;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_Status FOREIGN KEY ([movement_status_id]) REFERENCES [Reference].[CitizenMovementStatuses]([movement_status_id]);
GO

-- Ràng buộc mới cho DocumentTypes
IF OBJECT_ID('BCA.FK_CitizenMovement_DocType', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_DocType;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_DocType FOREIGN KEY ([document_type_id]) REFERENCES [Reference].[DocumentTypes]([document_type_id]);
GO

--------------------------------------------------------------------------------
-- IX. RÀNG BUỘC CHO BẢNG BCA.CriminalRecord
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CriminalRecord...';

IF OBJECT_ID('BCA.FK_CriminalRecord_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_Citizen;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_CriminalRecord_Prison', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_Prison;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Prison FOREIGN KEY ([prison_facility_id]) REFERENCES [Reference].[PrisonFacilities]([prison_facility_id]);
GO

IF OBJECT_ID('BCA.FK_CriminalRecord_CrimeType', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_CrimeType;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_CrimeType FOREIGN KEY ([crime_type_id]) REFERENCES [Reference].[CrimeTypes]([crime_type_id]);
GO

IF OBJECT_ID('BCA.FK_CriminalRecord_Sensitivity', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_Sensitivity;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Sensitivity FOREIGN KEY ([sensitivity_level_id]) REFERENCES [Reference].[DataSensitivityLevels]([sensitivity_level_id]);
GO

-- Ràng buộc mới cho ExecutionStatuses
IF OBJECT_ID('BCA.FK_CriminalRecord_ExecStatus', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_ExecStatus;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_ExecStatus FOREIGN KEY ([execution_status_id]) REFERENCES [Reference].[ExecutionStatuses]([execution_status_id]);
GO

--------------------------------------------------------------------------------
-- X. RÀNG BUỘC CHO BẢNG BCA.CitizenAddress
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenAddress...';

IF OBJECT_ID('BCA.FK_CitizenAddress_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Citizen;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenAddress_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Address;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenAddress_Authority', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Authority;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenAddress_Type', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Type;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Type FOREIGN KEY ([address_type_id]) REFERENCES [Reference].[AddressTypes]([address_type_id]);
GO

--------------------------------------------------------------------------------
-- UNIQUE CONSTRAINTS (Commented out per request)
--------------------------------------------------------------------------------

-- Citizen.citizen_id (primary key already enforces uniqueness)
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_Citizen_ID')
--    DROP INDEX UQ_Citizen_ID ON BCA.Citizen;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_Citizen_ID ON BCA.Citizen(citizen_id);
-- GO

-- IdentificationCard.card_number - Unique constraint commented out
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_IdentificationCard_Number')
--    DROP INDEX UQ_IdentificationCard_Number ON BCA.IdentificationCard;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_IdentificationCard_Number ON BCA.IdentificationCard(card_number) 
--    WHERE card_status_id IN (1, 2); -- Active and expiring cards
-- GO

-- CitizenAddress - Primary address per citizen restriction commented out
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_CitizenAddress_PrimaryPerCitizen')
--    DROP INDEX UQ_CitizenAddress_PrimaryPerCitizen ON BCA.CitizenAddress;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_CitizenAddress_PrimaryPerCitizen ON BCA.CitizenAddress(citizen_id) 
--    WHERE is_primary = 1 AND status = 1;
-- GO

-- CitizenStatus - Current status per citizen restriction commented out
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_CitizenStatus_CurrentPerCitizen')
--    DROP INDEX UQ_CitizenStatus_CurrentPerCitizen ON BCA.CitizenStatus;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_CitizenStatus_CurrentPerCitizen ON BCA.CitizenStatus(citizen_id) 
--    WHERE is_current = 1;
-- GO

PRINT N'Finished creating constraints for tables in DB_BCA.';
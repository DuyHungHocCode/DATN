USE [DB_BCA];
GO

PRINT N'Bắt đầu tạo các ràng buộc khóa ngoại cho DB_BCA...';

--------------------------------------------------------------------------------
-- PHẦN I: RÀNG BUỘC CHO CÁC BẢNG TRONG SCHEMA [REFERENCE]
--------------------------------------------------------------------------------
PRINT N'--> I. Đang tạo ràng buộc cho schema [Reference]...';

-- Bảng: Reference.Provinces
PRINT N'  [Reference].[Provinces]';
IF OBJECT_ID('Reference.FK_Provinces_Regions', 'F') IS NOT NULL ALTER TABLE [Reference].[Provinces] DROP CONSTRAINT FK_Provinces_Regions;
GO
ALTER TABLE [Reference].[Provinces] ADD CONSTRAINT FK_Provinces_Regions FOREIGN KEY ([region_id]) REFERENCES [Reference].[Regions]([region_id]);
GO

-- Bảng: Reference.Districts
PRINT N'  [Reference].[Districts]';
IF OBJECT_ID('Reference.FK_Districts_Provinces', 'F') IS NOT NULL ALTER TABLE [Reference].[Districts] DROP CONSTRAINT FK_Districts_Provinces;
GO
ALTER TABLE [Reference].[Districts] ADD CONSTRAINT FK_Districts_Provinces FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

-- Bảng: Reference.Wards
PRINT N'  [Reference].[Wards]';
IF OBJECT_ID('Reference.FK_Wards_Districts', 'F') IS NOT NULL ALTER TABLE [Reference].[Wards] DROP CONSTRAINT FK_Wards_Districts;
GO
ALTER TABLE [Reference].[Wards] ADD CONSTRAINT FK_Wards_Districts FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO

-- Bảng: Reference.Authorities
PRINT N'  [Reference].[Authorities]';
IF OBJECT_ID('Reference.FK_Authorities_Wards', 'F') IS NOT NULL ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authorities_Wards;
ALTER TABLE [Reference].[Authorities] ADD CONSTRAINT FK_Authorities_Wards FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
IF OBJECT_ID('Reference.FK_Authorities_Districts', 'F') IS NOT NULL ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authorities_Districts;
ALTER TABLE [Reference].[Authorities] ADD CONSTRAINT FK_Authorities_Districts FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
IF OBJECT_ID('Reference.FK_Authorities_Provinces', 'F') IS NOT NULL ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authorities_Provinces;
ALTER TABLE [Reference].[Authorities] ADD CONSTRAINT FK_Authorities_Provinces FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
IF OBJECT_ID('Reference.FK_Authorities_ParentAuthority', 'F') IS NOT NULL ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authorities_ParentAuthority;
ALTER TABLE [Reference].[Authorities] ADD CONSTRAINT FK_Authorities_ParentAuthority FOREIGN KEY ([parent_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Bảng: Reference.RelationshipTypes (Tự tham chiếu)
PRINT N'  [Reference].[RelationshipTypes]';
IF OBJECT_ID('Reference.FK_RelationshipTypes_Inverse', 'F') IS NOT NULL ALTER TABLE [Reference].[RelationshipTypes] DROP CONSTRAINT FK_RelationshipTypes_Inverse;
GO
ALTER TABLE [Reference].[RelationshipTypes] ADD CONSTRAINT FK_RelationshipTypes_Inverse FOREIGN KEY ([inverse_relationship_type_id]) REFERENCES [Reference].[RelationshipTypes]([relationship_type_id]);
GO

-- Bảng: Reference.PrisonFacilities
PRINT N'  [Reference].[PrisonFacilities]';
IF OBJECT_ID('Reference.FK_PrisonFacilities_Wards', 'F') IS NOT NULL ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_PrisonFacilities_Wards;
ALTER TABLE [Reference].[PrisonFacilities] ADD CONSTRAINT FK_PrisonFacilities_Wards FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
IF OBJECT_ID('Reference.FK_PrisonFacilities_Districts', 'F') IS NOT NULL ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_PrisonFacilities_Districts;
ALTER TABLE [Reference].[PrisonFacilities] ADD CONSTRAINT FK_PrisonFacilities_Districts FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
IF OBJECT_ID('Reference.FK_PrisonFacilities_Provinces', 'F') IS NOT NULL ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_PrisonFacilities_Provinces;
ALTER TABLE [Reference].[PrisonFacilities] ADD CONSTRAINT FK_PrisonFacilities_Provinces FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
IF OBJECT_ID('Reference.FK_PrisonFacilities_Authorities', 'F') IS NOT NULL ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_PrisonFacilities_Authorities;
ALTER TABLE [Reference].[PrisonFacilities] ADD CONSTRAINT FK_PrisonFacilities_Authorities FOREIGN KEY ([managing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

--------------------------------------------------------------------------------
-- PHẦN II: RÀNG BUỘC CHO CÁC BẢNG TRONG SCHEMA [BCA]
--------------------------------------------------------------------------------
PRINT N'--> II. Đang tạo ràng buộc cho schema [BCA]...';

-- Bảng: BCA.Citizen
PRINT N'  [BCA].[Citizen]';
IF OBJECT_ID('BCA.FK_Citizen_Gender', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Gender;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Gender FOREIGN KEY ([gender_id]) REFERENCES [Reference].[Genders]([gender_id]);
IF OBJECT_ID('BCA.FK_Citizen_BirthWard', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthWard;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthWard FOREIGN KEY ([birth_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
IF OBJECT_ID('BCA.FK_Citizen_BirthDistrict', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthDistrict;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthDistrict FOREIGN KEY ([birth_district_id]) REFERENCES [Reference].[Districts]([district_id]);
IF OBJECT_ID('BCA.FK_Citizen_BirthProvince', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthProvince;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthProvince FOREIGN KEY ([birth_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
IF OBJECT_ID('BCA.FK_Citizen_BirthCountry', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BirthCountry;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthCountry FOREIGN KEY ([birth_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
IF OBJECT_ID('BCA.FK_Citizen_NativeWard', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_NativeWard;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeWard FOREIGN KEY ([native_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
IF OBJECT_ID('BCA.FK_Citizen_NativeDistrict', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_NativeDistrict;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeDistrict FOREIGN KEY ([native_district_id]) REFERENCES [Reference].[Districts]([district_id]);
IF OBJECT_ID('BCA.FK_Citizen_NativeProvince', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_NativeProvince;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeProvince FOREIGN KEY ([native_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
IF OBJECT_ID('BCA.FK_Citizen_PrimaryAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_PrimaryAddress;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_PrimaryAddress FOREIGN KEY ([primary_address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_Citizen_Nationality', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Nationality;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Nationality FOREIGN KEY ([nationality_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
IF OBJECT_ID('BCA.FK_Citizen_Ethnicity', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Ethnicity;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Ethnicity FOREIGN KEY ([ethnicity_id]) REFERENCES [Reference].[Ethnicities]([ethnicity_id]);
IF OBJECT_ID('BCA.FK_Citizen_Religion', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Religion;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Religion FOREIGN KEY ([religion_id]) REFERENCES [Reference].[Religions]([religion_id]);
IF OBJECT_ID('BCA.FK_Citizen_MaritalStatus', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_MaritalStatus;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_MaritalStatus FOREIGN KEY ([marital_status_id]) REFERENCES [Reference].[MaritalStatuses]([marital_status_id]);
IF OBJECT_ID('BCA.FK_Citizen_EducationLevel', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_EducationLevel;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_EducationLevel FOREIGN KEY ([education_level_id]) REFERENCES [Reference].[EducationLevels]([education_level_id]);
IF OBJECT_ID('BCA.FK_Citizen_Occupation', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Occupation;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Occupation FOREIGN KEY ([occupation_id]) REFERENCES [Reference].[Occupations]([occupation_id]);
IF OBJECT_ID('BCA.FK_Citizen_StatusType', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_StatusType;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_StatusType FOREIGN KEY ([citizen_status_id]) REFERENCES [Reference].[CitizenStatusTypes]([citizen_status_id]);
IF OBJECT_ID('BCA.FK_Citizen_BloodType', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BloodType;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BloodType FOREIGN KEY ([blood_type_id]) REFERENCES [Reference].[BloodTypes]([blood_type_id]);
IF OBJECT_ID('BCA.FK_Citizen_CitizenshipDocType', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_CitizenshipDocType;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CitizenshipDocType FOREIGN KEY ([citizenship_document_type_id]) REFERENCES [Reference].[DocumentTypes]([document_type_id]);
-- Tự tham chiếu
IF OBJECT_ID('BCA.FK_Citizen_Father', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Father;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Father FOREIGN KEY ([father_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);

IF OBJECT_ID('BCA.FK_Citizen_Mother', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Mother;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Mother FOREIGN KEY ([mother_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_Citizen_Spouse', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Spouse;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Spouse FOREIGN KEY ([spouse_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_Citizen_Representative', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Representative;
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Representative FOREIGN KEY ([representative_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

-- Bảng: BCA.Address
PRINT N'  [BCA].[Address]';
IF OBJECT_ID('BCA.FK_Address_Wards', 'F') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT FK_Address_Wards;
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Wards FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
IF OBJECT_ID('BCA.FK_Address_Districts', 'F') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT FK_Address_Districts;
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Districts FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
IF OBJECT_ID('BCA.FK_Address_Provinces', 'F') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT FK_Address_Provinces;
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Provinces FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

-- Bảng: BCA.IdentificationCard
PRINT N'  [BCA].[IdentificationCard]';
IF OBJECT_ID('BCA.FK_IDCard_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IDCard_Citizen;
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IDCard_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_IDCard_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IDCard_Authorities;
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IDCard_Authorities FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
IF OBJECT_ID('BCA.FK_IDCard_CardTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IDCard_CardTypes;
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IDCard_CardTypes FOREIGN KEY ([card_type_id]) REFERENCES [Reference].[IdentificationCardTypes]([card_type_id]);
IF OBJECT_ID('BCA.FK_IDCard_CardStatuses', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IDCard_CardStatuses;
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IDCard_CardStatuses FOREIGN KEY ([card_status_id]) REFERENCES [Reference].[IdentificationCardStatuses]([card_status_id]);
GO

-- Bảng: BCA.ResidenceHistory
PRINT N'  [BCA].[ResidenceHistory]';
IF OBJECT_ID('BCA.FK_ResHistory_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_Citizen;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_ResHistory_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_Address;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_ResHistory_PrevAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_PrevAddress;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_PrevAddress FOREIGN KEY ([previous_address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_ResHistory_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_Authorities;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_Authorities FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
IF OBJECT_ID('BCA.FK_ResHistory_ResidenceTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_ResidenceTypes;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_ResidenceTypes FOREIGN KEY ([residence_type_id]) REFERENCES [Reference].[ResidenceTypes]([residence_type_id]);
IF OBJECT_ID('BCA.FK_ResHistory_RegStatuses', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_RegStatuses;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_RegStatuses FOREIGN KEY ([res_reg_status_id]) REFERENCES [Reference].[ResidenceRegistrationStatuses]([res_reg_status_id]);
IF OBJECT_ID('BCA.FK_ResHistory_ChangeReasons', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_ChangeReasons;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_ChangeReasons FOREIGN KEY ([residence_status_change_reason_id]) REFERENCES [Reference].[ResidenceStatusChangeReasons]([reason_id]);
IF OBJECT_ID('BCA.FK_ResHistory_AccomFacility', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_AccomFacility;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_AccomFacility FOREIGN KEY ([accommodation_facility_id]) REFERENCES [BCA].[AccommodationFacility]([facility_id]);
-- Ràng buộc đến TNMT sẽ được thêm ở phần III
GO

-- Bảng: BCA.TemporaryAbsence
PRINT N'  [BCA].[TemporaryAbsence]';
IF OBJECT_ID('BCA.FK_TempAbsence_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TempAbsence_Citizen;
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TempAbsence_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_TempAbsence_DestAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TempAbsence_DestAddress;
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TempAbsence_DestAddress FOREIGN KEY ([destination_address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_TempAbsence_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TempAbsence_Authorities;
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TempAbsence_Authorities FOREIGN KEY ([registration_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
IF OBJECT_ID('BCA.FK_TempAbsence_Statuses', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TempAbsence_Statuses;
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TempAbsence_Statuses FOREIGN KEY ([temp_abs_status_id]) REFERENCES [Reference].[TemporaryAbsenceStatuses]([temp_abs_status_id]);
IF OBJECT_ID('BCA.FK_TempAbsence_Types', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TempAbsence_Types;
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TempAbsence_Types FOREIGN KEY ([temporary_absence_type_id]) REFERENCES [Reference].[TemporaryAbsenceTypes]([temp_abs_type_id]);
IF OBJECT_ID('BCA.FK_TempAbsence_Sensitivity', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TempAbsence_Sensitivity;
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TempAbsence_Sensitivity FOREIGN KEY ([sensitivity_level_id]) REFERENCES [Reference].[DataSensitivityLevels]([sensitivity_level_id]);
GO

-- Bảng: BCA.CitizenStatus
PRINT N'  [BCA].[CitizenStatus]';
IF OBJECT_ID('BCA.FK_CitizenStatus_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Citizen;
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_CitizenStatus_StatusTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_StatusTypes;
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_StatusTypes FOREIGN KEY ([citizen_status_id]) REFERENCES [Reference].[CitizenStatusTypes]([citizen_status_id]);
IF OBJECT_ID('BCA.FK_CitizenStatus_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Authorities;
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Authorities FOREIGN KEY ([authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Bảng: BCA.CitizenMovement
PRINT N'  [BCA].[CitizenMovement]';
IF OBJECT_ID('BCA.FK_Movement_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_Citizen;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_Movement_FromAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_FromAddress;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_FromAddress FOREIGN KEY ([from_address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_Movement_ToAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_ToAddress;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_ToAddress FOREIGN KEY ([to_address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_Movement_FromCountry', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_FromCountry;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_FromCountry FOREIGN KEY ([from_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
IF OBJECT_ID('BCA.FK_Movement_ToCountry', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_ToCountry;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_ToCountry FOREIGN KEY ([to_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
IF OBJECT_ID('BCA.FK_Movement_MovementTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_MovementTypes;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_MovementTypes FOREIGN KEY ([movement_type_id]) REFERENCES [Reference].[CitizenMovementTypes]([movement_type_id]);
IF OBJECT_ID('BCA.FK_Movement_Statuses', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_Statuses;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_Statuses FOREIGN KEY ([movement_status_id]) REFERENCES [Reference].[CitizenMovementStatuses]([movement_status_id]);
IF OBJECT_ID('BCA.FK_Movement_DocTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_Movement_DocTypes;
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_Movement_DocTypes FOREIGN KEY ([document_type_id]) REFERENCES [Reference].[DocumentTypes]([document_type_id]);
GO

-- Bảng: BCA.CriminalRecord
PRINT N'  [BCA].[CriminalRecord]';
IF OBJECT_ID('BCA.FK_CrimRecord_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CrimRecord_Citizen;
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CrimRecord_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_CrimRecord_CrimeTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CrimRecord_CrimeTypes;
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CrimRecord_CrimeTypes FOREIGN KEY ([crime_type_id]) REFERENCES [Reference].[CrimeTypes]([crime_type_id]);
IF OBJECT_ID('BCA.FK_CrimRecord_PrisonFacilities', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CrimRecord_PrisonFacilities;
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CrimRecord_PrisonFacilities FOREIGN KEY ([prison_facility_id]) REFERENCES [Reference].[PrisonFacilities]([prison_facility_id]);
IF OBJECT_ID('BCA.FK_CrimRecord_ExecStatuses', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CrimRecord_ExecStatuses;
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CrimRecord_ExecStatuses FOREIGN KEY ([execution_status_id]) REFERENCES [Reference].[ExecutionStatuses]([execution_status_id]);
IF OBJECT_ID('BCA.FK_CrimRecord_Sensitivity', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CrimRecord_Sensitivity;
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CrimRecord_Sensitivity FOREIGN KEY ([sensitivity_level_id]) REFERENCES [Reference].[DataSensitivityLevels]([sensitivity_level_id]);
GO

-- Bảng: BCA.CitizenAddress
PRINT N'  [BCA].[CitizenAddress]';
IF OBJECT_ID('BCA.FK_CitizenAddr_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddr_Citizen;
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddr_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_CitizenAddr_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddr_Address;
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddr_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_CitizenAddr_AddressTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddr_AddressTypes;
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddr_AddressTypes FOREIGN KEY ([address_type_id]) REFERENCES [Reference].[AddressTypes]([address_type_id]);
IF OBJECT_ID('BCA.FK_CitizenAddr_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddr_Authorities;
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddr_Authorities FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
IF OBJECT_ID('BCA.FK_CitizenAddr_ResHistory', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddr_ResHistory;
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddr_ResHistory FOREIGN KEY ([related_residence_history_id]) REFERENCES [BCA].[ResidenceHistory]([residence_history_id]);
GO

-- Bảng: BCA.Household
PRINT N'  [BCA].[Household]';
IF OBJECT_ID('BCA.FK_Household_HeadCitizen', 'F') IS NOT NULL ALTER TABLE [BCA].[Household] DROP CONSTRAINT FK_Household_HeadCitizen;
ALTER TABLE [BCA].[Household] ADD CONSTRAINT FK_Household_HeadCitizen FOREIGN KEY ([head_of_household_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_Household_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[Household] DROP CONSTRAINT FK_Household_Address;
ALTER TABLE [BCA].[Household] ADD CONSTRAINT FK_Household_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_Household_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[Household] DROP CONSTRAINT FK_Household_Authorities;
ALTER TABLE [BCA].[Household] ADD CONSTRAINT FK_Household_Authorities FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
IF OBJECT_ID('BCA.FK_Household_Types', 'F') IS NOT NULL ALTER TABLE [BCA].[Household] DROP CONSTRAINT FK_Household_Types;
ALTER TABLE [BCA].[Household] ADD CONSTRAINT FK_Household_Types FOREIGN KEY ([household_type_id]) REFERENCES [Reference].[HouseholdTypes]([household_type_id]);
IF OBJECT_ID('BCA.FK_Household_Statuses', 'F') IS NOT NULL ALTER TABLE [BCA].[Household] DROP CONSTRAINT FK_Household_Statuses;
ALTER TABLE [BCA].[Household] ADD CONSTRAINT FK_Household_Statuses FOREIGN KEY ([household_status_id]) REFERENCES [Reference].[HouseholdStatuses]([household_status_id]);
-- Ràng buộc đến TNMT sẽ được thêm ở phần III
GO

-- Bảng: BCA.HouseholdMember
PRINT N'  [BCA].[HouseholdMember]';
IF OBJECT_ID('BCA.FK_HHMember_Household', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdMember] DROP CONSTRAINT FK_HHMember_Household;
ALTER TABLE [BCA].[HouseholdMember] ADD CONSTRAINT FK_HHMember_Household FOREIGN KEY ([household_id]) REFERENCES [BCA].[Household]([household_id]);
IF OBJECT_ID('BCA.FK_HHMember_PrevHousehold', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdMember] DROP CONSTRAINT FK_HHMember_PrevHousehold;
ALTER TABLE [BCA].[HouseholdMember] ADD CONSTRAINT FK_HHMember_PrevHousehold FOREIGN KEY ([previous_household_id]) REFERENCES [BCA].[Household]([household_id]);
IF OBJECT_ID('BCA.FK_HHMember_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdMember] DROP CONSTRAINT FK_HHMember_Citizen;
ALTER TABLE [BCA].[HouseholdMember] ADD CONSTRAINT FK_HHMember_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_HHMember_RelWithHeadTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdMember] DROP CONSTRAINT FK_HHMember_RelWithHeadTypes;
ALTER TABLE [BCA].[HouseholdMember] ADD CONSTRAINT FK_HHMember_RelWithHeadTypes FOREIGN KEY ([rel_with_head_id]) REFERENCES [Reference].[RelationshipWithHeadTypes]([rel_with_head_id]);
IF OBJECT_ID('BCA.FK_HHMember_MemberStatuses', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdMember] DROP CONSTRAINT FK_HHMember_MemberStatuses;
ALTER TABLE [BCA].[HouseholdMember] ADD CONSTRAINT FK_HHMember_MemberStatuses FOREIGN KEY ([member_status_id]) REFERENCES [Reference].[HouseholdMemberStatuses]([member_status_id]);
GO

-- Bảng: BCA.AccommodationFacility
PRINT N'  [BCA].[AccommodationFacility]';
IF OBJECT_ID('BCA.FK_AccomFacility_Types', 'F') IS NOT NULL ALTER TABLE [BCA].[AccommodationFacility] DROP CONSTRAINT FK_AccomFacility_Types;
ALTER TABLE [BCA].[AccommodationFacility] ADD CONSTRAINT FK_AccomFacility_Types FOREIGN KEY ([facility_type_id]) REFERENCES [Reference].[AccommodationFacilityTypes]([facility_type_id]);
IF OBJECT_ID('BCA.FK_AccomFacility_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[AccommodationFacility] DROP CONSTRAINT FK_AccomFacility_Address;
ALTER TABLE [BCA].[AccommodationFacility] ADD CONSTRAINT FK_AccomFacility_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_AccomFacility_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[AccommodationFacility] DROP CONSTRAINT FK_AccomFacility_Authorities;
ALTER TABLE [BCA].[AccommodationFacility] ADD CONSTRAINT FK_AccomFacility_Authorities FOREIGN KEY ([managing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Bảng: BCA.MobileResidence
PRINT N'  [BCA].[MobileResidence]';
IF OBJECT_ID('BCA.FK_MobileRes_VehicleTypes', 'F') IS NOT NULL ALTER TABLE [BCA].[MobileResidence] DROP CONSTRAINT FK_MobileRes_VehicleTypes;
ALTER TABLE [BCA].[MobileResidence] ADD CONSTRAINT FK_MobileRes_VehicleTypes FOREIGN KEY ([vehicle_type_id]) REFERENCES [Reference].[VehicleTypes]([vehicle_type_id]);
IF OBJECT_ID('BCA.FK_MobileRes_OwnerCitizen', 'F') IS NOT NULL ALTER TABLE [BCA].[MobileResidence] DROP CONSTRAINT FK_MobileRes_OwnerCitizen;
ALTER TABLE [BCA].[MobileResidence] ADD CONSTRAINT FK_MobileRes_OwnerCitizen FOREIGN KEY ([owner_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_MobileRes_MooringAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[MobileResidence] DROP CONSTRAINT FK_MobileRes_MooringAddress;
ALTER TABLE [BCA].[MobileResidence] ADD CONSTRAINT FK_MobileRes_MooringAddress FOREIGN KEY ([fixed_mooring_address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('BCA.FK_MobileRes_Authorities', 'F') IS NOT NULL ALTER TABLE [BCA].[MobileResidence] DROP CONSTRAINT FK_MobileRes_Authorities;
ALTER TABLE [BCA].[MobileResidence] ADD CONSTRAINT FK_MobileRes_Authorities FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Bảng: BCA.HouseholdChangeLog
PRINT N'  [BCA].[HouseholdChangeLog]';
IF OBJECT_ID('BCA.FK_HHChangeLog_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdChangeLog] DROP CONSTRAINT FK_HHChangeLog_Citizen;
ALTER TABLE [BCA].[HouseholdChangeLog] ADD CONSTRAINT FK_HHChangeLog_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('BCA.FK_HHChangeLog_Reason', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdChangeLog] DROP CONSTRAINT FK_HHChangeLog_Reason;
ALTER TABLE [BCA].[HouseholdChangeLog] ADD CONSTRAINT FK_HHChangeLog_Reason FOREIGN KEY ([reason_id]) REFERENCES [Reference].[HouseholdChangeType]([id]);
IF OBJECT_ID('BCA.FK_HHChangeLog_FromHousehold', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdChangeLog] DROP CONSTRAINT FK_HHChangeLog_FromHousehold;
ALTER TABLE [BCA].[HouseholdChangeLog] ADD CONSTRAINT FK_HHChangeLog_FromHousehold FOREIGN KEY ([from_household_id]) REFERENCES [BCA].[Household]([household_id]);
IF OBJECT_ID('BCA.FK_HHChangeLog_ToHousehold', 'F') IS NOT NULL ALTER TABLE [BCA].[HouseholdChangeLog] DROP CONSTRAINT FK_HHChangeLog_ToHousehold;
ALTER TABLE [BCA].[HouseholdChangeLog] ADD CONSTRAINT FK_HHChangeLog_ToHousehold FOREIGN KEY ([to_household_id]) REFERENCES [BCA].[Household]([household_id]);
GO

--------------------------------------------------------------------------------
-- PHẦN III: RÀNG BUỘC CHO CÁC BẢNG TRONG SCHEMA [TNMT] VÀ LIÊN KẾT
--------------------------------------------------------------------------------
PRINT N'--> III. Đang tạo ràng buộc cho schema [TNMT] và các liên kết...';

-- Bảng: TNMT.OwnershipCertificate
PRINT N'  [TNMT].[OwnershipCertificate]';
IF OBJECT_ID('TNMT.FK_OwnershipCert_DocTypes', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipCertificate] DROP CONSTRAINT FK_OwnershipCert_DocTypes;
ALTER TABLE [TNMT].[OwnershipCertificate] ADD CONSTRAINT FK_OwnershipCert_DocTypes FOREIGN KEY ([certificate_type_id]) REFERENCES [Reference].[DocumentTypes]([document_type_id]);
IF OBJECT_ID('TNMT.FK_OwnershipCert_Authorities', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipCertificate] DROP CONSTRAINT FK_OwnershipCert_Authorities;
ALTER TABLE [TNMT].[OwnershipCertificate] ADD CONSTRAINT FK_OwnershipCert_Authorities FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
IF OBJECT_ID('TNMT.FK_OwnershipCert_OwnerCitizen', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipCertificate] DROP CONSTRAINT FK_OwnershipCert_OwnerCitizen;
ALTER TABLE [TNMT].[OwnershipCertificate] ADD CONSTRAINT FK_OwnershipCert_OwnerCitizen FOREIGN KEY ([owner_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('TNMT.FK_OwnershipCert_PropertyAddress', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipCertificate] DROP CONSTRAINT FK_OwnershipCert_PropertyAddress;
ALTER TABLE [TNMT].[OwnershipCertificate] ADD CONSTRAINT FK_OwnershipCert_PropertyAddress FOREIGN KEY ([property_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

-- Bảng: TNMT.OwnershipHistory
PRINT N'  [TNMT].[OwnershipHistory]';
IF OBJECT_ID('TNMT.FK_OwnershipHist_Cert', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipHistory] DROP CONSTRAINT FK_OwnershipHist_Cert;
ALTER TABLE [TNMT].[OwnershipHistory] ADD CONSTRAINT FK_OwnershipHist_Cert FOREIGN KEY ([certificate_id]) REFERENCES [TNMT].[OwnershipCertificate]([certificate_id]);
IF OBJECT_ID('TNMT.FK_OwnershipHist_Citizen', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipHistory] DROP CONSTRAINT FK_OwnershipHist_Citizen;
ALTER TABLE [TNMT].[OwnershipHistory] ADD CONSTRAINT FK_OwnershipHist_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('TNMT.FK_OwnershipHist_PrevOwner', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipHistory] DROP CONSTRAINT FK_OwnershipHist_PrevOwner;
ALTER TABLE [TNMT].[OwnershipHistory] ADD CONSTRAINT FK_OwnershipHist_PrevOwner FOREIGN KEY ([previous_owner_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('TNMT.FK_OwnershipHist_NewOwner', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipHistory] DROP CONSTRAINT FK_OwnershipHist_NewOwner;
ALTER TABLE [TNMT].[OwnershipHistory] ADD CONSTRAINT FK_OwnershipHist_NewOwner FOREIGN KEY ([new_owner_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('TNMT.FK_OwnershipHist_TransTypes', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipHistory] DROP CONSTRAINT FK_OwnershipHist_TransTypes;
ALTER TABLE [TNMT].[OwnershipHistory] ADD CONSTRAINT FK_OwnershipHist_TransTypes FOREIGN KEY ([transaction_type_id]) REFERENCES [Reference].[TransactionTypes]([transaction_type_id]);
IF OBJECT_ID('TNMT.FK_OwnershipHist_DocTypes', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipHistory] DROP CONSTRAINT FK_OwnershipHist_DocTypes;
ALTER TABLE [TNMT].[OwnershipHistory] ADD CONSTRAINT FK_OwnershipHist_DocTypes FOREIGN KEY ([document_type_id]) REFERENCES [Reference].[DocumentTypes]([document_type_id]);
IF OBJECT_ID('TNMT.FK_OwnershipHist_Authorities', 'F') IS NOT NULL ALTER TABLE [TNMT].[OwnershipHistory] DROP CONSTRAINT FK_OwnershipHist_Authorities;
ALTER TABLE [TNMT].[OwnershipHistory] ADD CONSTRAINT FK_OwnershipHist_Authorities FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Bảng: TNMT.RentalContract
PRINT N'  [TNMT].[RentalContract]';
IF OBJECT_ID('TNMT.FK_RentalContract_ContractTypes', 'F') IS NOT NULL ALTER TABLE [TNMT].[RentalContract] DROP CONSTRAINT FK_RentalContract_ContractTypes;
ALTER TABLE [TNMT].[RentalContract] ADD CONSTRAINT FK_RentalContract_ContractTypes FOREIGN KEY ([contract_type_id]) REFERENCES [Reference].[ContractTypes]([contract_type_id]);
IF OBJECT_ID('TNMT.FK_RentalContract_Lessor', 'F') IS NOT NULL ALTER TABLE [TNMT].[RentalContract] DROP CONSTRAINT FK_RentalContract_Lessor;
ALTER TABLE [TNMT].[RentalContract] ADD CONSTRAINT FK_RentalContract_Lessor FOREIGN KEY ([lessor_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('TNMT.FK_RentalContract_Lessee', 'F') IS NOT NULL ALTER TABLE [TNMT].[RentalContract] DROP CONSTRAINT FK_RentalContract_Lessee;
ALTER TABLE [TNMT].[RentalContract] ADD CONSTRAINT FK_RentalContract_Lessee FOREIGN KEY ([lessee_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
IF OBJECT_ID('TNMT.FK_RentalContract_Address', 'F') IS NOT NULL ALTER TABLE [TNMT].[RentalContract] DROP CONSTRAINT FK_RentalContract_Address;
ALTER TABLE [TNMT].[RentalContract] ADD CONSTRAINT FK_RentalContract_Address FOREIGN KEY ([property_address_id]) REFERENCES [BCA].[Address]([address_id]);
IF OBJECT_ID('TNMT.FK_RentalContract_Authorities', 'F') IS NOT NULL ALTER TABLE [TNMT].[RentalContract] DROP CONSTRAINT FK_RentalContract_Authorities;
ALTER TABLE [TNMT].[RentalContract] ADD CONSTRAINT FK_RentalContract_Authorities FOREIGN KEY ([notarization_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Ràng buộc liên kết từ BCA đến TNMT
PRINT N'  Tạo ràng buộc từ [BCA] đến [TNMT]...';
IF OBJECT_ID('BCA.FK_ResHistory_OwnershipCert', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_OwnershipCert;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_OwnershipCert FOREIGN KEY ([ownership_certificate_id]) REFERENCES [TNMT].[OwnershipCertificate]([certificate_id]);
IF OBJECT_ID('BCA.FK_ResHistory_RentalContract', 'F') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT FK_ResHistory_RentalContract;
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResHistory_RentalContract FOREIGN KEY ([rental_contract_id]) REFERENCES [TNMT].[RentalContract]([contract_id]);

IF OBJECT_ID('BCA.FK_Household_OwnershipCert', 'F') IS NOT NULL ALTER TABLE [BCA].[Household] DROP CONSTRAINT FK_Household_OwnershipCert;
ALTER TABLE [BCA].[Household] ADD CONSTRAINT FK_Household_OwnershipCert FOREIGN KEY ([ownership_certificate_id]) REFERENCES [TNMT].[OwnershipCertificate]([certificate_id]);
IF OBJECT_ID('BCA.FK_Household_RentalContract', 'F') IS NOT NULL ALTER TABLE [BCA].[Household] DROP CONSTRAINT FK_Household_RentalContract;
ALTER TABLE [BCA].[Household] ADD CONSTRAINT FK_Household_RentalContract FOREIGN KEY ([rental_contract_id]) REFERENCES [TNMT].[RentalContract]([contract_id]);
GO

PRINT N'Hoàn thành việc tạo tất cả các ràng buộc khóa ngoại.';
GO

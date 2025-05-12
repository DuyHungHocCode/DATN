-- Script to create ALL constraints for tables in database DB_BCA
-- This script includes constraints for both Reference schema tables (moved from DB_Reference)
-- and BCA schema tables, with Foreign Keys between them now enabled.
-- Run this script after all tables in DB_BCA (both BCA and Reference schemas) have been created.

USE [DB_BCA];
GO

PRINT N'============================================================';
PRINT N'Creating constraints for tables in DB_BCA.Reference schema...';
PRINT N'============================================================';
GO

-- Constraints for Reference.Provinces
-- Each Province must belong to a valid Region.
PRINT N'  Adding FK_Province_Region to Reference.Provinces...';
IF OBJECT_ID('Reference.FK_Province_Region', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Provinces] DROP CONSTRAINT FK_Province_Region;
GO
ALTER TABLE [Reference].[Provinces]
    ADD CONSTRAINT FK_Province_Region FOREIGN KEY ([region_id])
    REFERENCES [Reference].[Regions]([region_id]);
GO

-- Constraints for Reference.Districts
-- Each District must belong to a valid Province.
PRINT N'  Adding FK_District_Province to Reference.Districts...';
IF OBJECT_ID('Reference.FK_District_Province', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Districts] DROP CONSTRAINT FK_District_Province;
GO
ALTER TABLE [Reference].[Districts]
    ADD CONSTRAINT FK_District_Province FOREIGN KEY ([province_id])
    REFERENCES [Reference].[Provinces]([province_id]);
GO

-- Constraints for Reference.Wards
-- Each Ward must belong to a valid District.
PRINT N'  Adding FK_Ward_District to Reference.Wards...';
IF OBJECT_ID('Reference.FK_Ward_District', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Wards] DROP CONSTRAINT FK_Ward_District;
GO
ALTER TABLE [Reference].[Wards]
    ADD CONSTRAINT FK_Ward_District FOREIGN KEY ([district_id])
    REFERENCES [Reference].[Districts]([district_id]);
GO

-- Constraints for Reference.Authorities
-- Authority's location (Ward, District, Province) must be valid.
-- Parent authority must be a valid existing authority.
PRINT N'  Adding FK_Authority_Ward to Reference.Authorities...';
IF OBJECT_ID('Reference.FK_Authority_Ward', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_Ward;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_Ward FOREIGN KEY ([ward_id])
    REFERENCES [Reference].[Wards]([ward_id]);
GO

PRINT N'  Adding FK_Authority_District to Reference.Authorities...';
IF OBJECT_ID('Reference.FK_Authority_District', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_District;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_District FOREIGN KEY ([district_id])
    REFERENCES [Reference].[Districts]([district_id]);
GO

PRINT N'  Adding FK_Authority_Province to Reference.Authorities...';
IF OBJECT_ID('Reference.FK_Authority_Province', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_Province;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_Province FOREIGN KEY ([province_id])
    REFERENCES [Reference].[Provinces]([province_id]);
GO

PRINT N'  Adding FK_Authority_Parent to Reference.Authorities...';
IF OBJECT_ID('Reference.FK_Authority_Parent', 'F') IS NOT NULL
    ALTER TABLE [Reference].[Authorities] DROP CONSTRAINT FK_Authority_Parent;
GO
ALTER TABLE [Reference].[Authorities]
    ADD CONSTRAINT FK_Authority_Parent FOREIGN KEY ([parent_authority_id])
    REFERENCES [Reference].[Authorities]([authority_id]); -- Self-referencing for hierarchical structure
GO

-- Constraints for Reference.RelationshipTypes
-- Inverse relationship must be a valid existing relationship type.
PRINT N'  Adding FK_Inverse_Relationship to Reference.RelationshipTypes...';
IF OBJECT_ID('Reference.FK_Inverse_Relationship', 'F') IS NOT NULL
    ALTER TABLE [Reference].[RelationshipTypes] DROP CONSTRAINT FK_Inverse_Relationship;
GO
ALTER TABLE [Reference].[RelationshipTypes]
    ADD CONSTRAINT FK_Inverse_Relationship FOREIGN KEY ([inverse_relationship_type_id])
    REFERENCES [Reference].[RelationshipTypes]([relationship_type_id]); -- Self-referencing
GO

-- Constraints for Reference.PrisonFacilities
-- Prison facility's location and managing authority must be valid.
PRINT N'  Adding FK_Prison_Ward to Reference.PrisonFacilities...';
IF OBJECT_ID('Reference.FK_Prison_Ward', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_Ward;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_Ward FOREIGN KEY ([ward_id])
    REFERENCES [Reference].[Wards]([ward_id]);
GO

PRINT N'  Adding FK_Prison_District to Reference.PrisonFacilities...';
IF OBJECT_ID('Reference.FK_Prison_District', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_District;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_District FOREIGN KEY ([district_id])
    REFERENCES [Reference].[Districts]([district_id]);
GO

PRINT N'  Adding FK_Prison_Province to Reference.PrisonFacilities...';
IF OBJECT_ID('Reference.FK_Prison_Province', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_Province;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_Province FOREIGN KEY ([province_id])
    REFERENCES [Reference].[Provinces]([province_id]);
GO

PRINT N'  Adding FK_Prison_Managing_Authority to Reference.PrisonFacilities...';
IF OBJECT_ID('Reference.FK_Prison_Managing_Authority', 'F') IS NOT NULL
    ALTER TABLE [Reference].[PrisonFacilities] DROP CONSTRAINT FK_Prison_Managing_Authority;
GO
ALTER TABLE [Reference].[PrisonFacilities]
    ADD CONSTRAINT FK_Prison_Managing_Authority FOREIGN KEY ([managing_authority_id])
    REFERENCES [Reference].[Authorities]([authority_id]);
GO

PRINT N'Finished creating constraints for tables in DB_BCA.Reference schema.';
GO

PRINT N'========================================================';
PRINT N'Creating constraints for tables in DB_BCA.BCA schema...';
PRINT N'========================================================';
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.Citizen
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.Citizen...';

-- Foreign Keys to DB_BCA.Reference schema (Previously Logical, now Physical)
PRINT N'  Adding Foreign Keys from BCA.Citizen to Reference schema...';
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

IF OBJECT_ID('BCA.FK_Citizen_Occupation', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Occupation;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Occupation FOREIGN KEY ([occupation_id]) REFERENCES [Reference].[Occupations]([occupation_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_CurrentWard', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_CurrentWard;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentWard FOREIGN KEY ([current_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_CurrentDistrict', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_CurrentDistrict;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentDistrict FOREIGN KEY ([current_district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_CurrentProvince', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_CurrentProvince;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentProvince FOREIGN KEY ([current_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_Gender', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_Gender;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Gender FOREIGN KEY ([gender_id]) REFERENCES [Reference].[Genders]([gender_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_MaritalStatus', 'F') IS-- Script to create constraints for tables in database DB_BCA (Bộ Công an)
-- This script should be run on the SQL Server instance dedicated to DB_BCA,
-- after DB_BCA tables have been created.
-- NOTE: Physical Foreign Keys to DB_Reference are commented out as they require Linked Servers
--       or application-level enforcement due to separate DB instances.

USE [DB_BCA];
GO

PRINT N'Creating constraints for tables in DB_BCA...';

--------------------------------------------------------------------------------
-- Constraints for BCA.Citizen
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.Citizen...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthWard FOREIGN KEY ([birth_ward_id]) REFERENCES [DB_Reference].[Reference].[Wards]([ward_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthDistrict FOREIGN KEY ([birth_district_id]) REFERENCES [DB_Reference].[Reference].[Districts]([district_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthProvince FOREIGN KEY ([birth_province_id]) REFERENCES [DB_Reference].[Reference].[Provinces]([province_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthCountry FOREIGN KEY ([birth_country_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeWard FOREIGN KEY ([native_ward_id]) REFERENCES [DB_Reference].[Reference].[Wards]([ward_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeDistrict FOREIGN KEY ([native_district_id]) REFERENCES [DB_Reference].[Reference].[Districts]([district_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeProvince FOREIGN KEY ([native_province_id]) REFERENCES [DB_Reference].[Reference].[Provinces]([province_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Nationality FOREIGN KEY ([nationality_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Ethnicity FOREIGN KEY ([ethnicity_id]) REFERENCES [DB_Reference].[Reference].[Ethnicities]([ethnicity_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Religion FOREIGN KEY ([religion_id]) REFERENCES [DB_Reference].[Reference].[Religions]([religion_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Occupation FOREIGN KEY ([occupation_id]) REFERENCES [DB_Reference].[Reference].[Occupations]([occupation_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentWard FOREIGN KEY ([current_ward_id]) REFERENCES [DB_Reference].[Reference].[Wards]([ward_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentDistrict FOREIGN KEY ([current_district_id]) REFERENCES [DB_Reference].[Reference].[Districts]([district_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentProvince FOREIGN KEY ([current_province_id]) REFERENCES [DB_Reference].[Reference].[Provinces]([province_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Gender FOREIGN KEY ([gender_id]) REFERENCES [DB_Reference].[Reference].[Genders]([gender_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_MaritalStatus FOREIGN KEY ([marital_status_id]) REFERENCES [DB_Reference].[Reference].[MaritalStatuses]([marital_status_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_EducationLevel FOREIGN KEY ([education_level_id]) REFERENCES [DB_Reference].[Reference].[EducationLevels]([education_level_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_DeathStatus FOREIGN KEY ([citizen_death_status_id]) REFERENCES [DB_Reference].[Reference].[CitizenDeathStatuses]([citizen_death_status_id]);
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BloodType FOREIGN KEY ([blood_type_id]) REFERENCES [DB_Reference].[Reference].[BloodTypes]([blood_type_id]);

-- Self-referencing Foreign Keys (within DB_BCA)
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

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_Citizen_BirthDate', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_BirthDate;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_BirthDate CHECK ([date_of_birth] < GETDATE());
GO

-- Check constraint for death date (needs adaptation if using ID)
-- The original constraint checked death_status = N'Đã mất'. Now we use citizen_death_status_id.
-- We need to know the ID for 'Đã mất' to adapt this check. Assuming ID=2 for 'Đã mất' for illustration.
-- You MUST verify and update the ID based on your Reference.CitizenDeathStatuses data.
-- Example: ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_DeathDate CHECK (([citizen_death_status_id] = 2 AND [date_of_death] IS NOT NULL AND [date_of_death] <= GETDATE()) OR ([citizen_death_status_id] <> 2));
-- For now, commenting out as the ID is unknown. Application logic should enforce this.
-- IF OBJECT_ID('BCA.CK_Citizen_DeathDate', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_DeathDate;
-- GO
-- PRINT N'  WARNING: CK_Citizen_DeathDate needs adaptation based on actual citizen_death_status_id for "Đã mất". Constraint not created.';
-- GO

IF OBJECT_ID('BCA.CK_Citizen_Parents', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_Parents;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_Parents CHECK ([citizen_id] <> [father_citizen_id] AND [citizen_id] <> [mother_citizen_id]);
GO

IF OBJECT_ID('BCA.CK_Citizen_EmailFormat', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_EmailFormat;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_EmailFormat CHECK ([email] IS NULL OR [email] LIKE '%_@__%.__%');
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.Address
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.Address...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Ward FOREIGN KEY ([ward_id]) REFERENCES [DB_Reference].[Reference].[Wards]([ward_id]);
-- ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_District FOREIGN KEY ([district_id]) REFERENCES [DB_Reference].[Reference].[Districts]([district_id]);
-- ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Province FOREIGN KEY ([province_id]) REFERENCES [DB_Reference].[Reference].[Provinces]([province_id]);

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_Address_LatLon', 'C') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT CK_Address_LatLon;
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT CK_Address_LatLon CHECK (([latitude] IS NULL AND [longitude] IS NULL) OR ([latitude] BETWEEN -90 AND 90 AND [longitude] BETWEEN -180 AND 180));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.IdentificationCard
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.IdentificationCard...';

-- Foreign Keys within DB_BCA
IF OBJECT_ID('BCA.FK_IdentificationCard_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IdentificationCard_Citizen;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Type FOREIGN KEY ([card_type_id]) REFERENCES [DB_Reference].[Reference].[IdentificationCardTypes]([card_type_id]);
-- ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Status FOREIGN KEY ([card_status_id]) REFERENCES [DB_Reference].[Reference].[IdentificationCardStatuses]([card_status_id]);

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_IdentificationCard_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT CK_IdentificationCard_Dates;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT CK_IdentificationCard_Dates CHECK ([issue_date] <= GETDATE() AND ([expiry_date] IS NULL OR [expiry_date] > [issue_date]));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.ResidenceHistory
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.ResidenceHistory...';

-- Foreign Keys within DB_BCA
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

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Type FOREIGN KEY ([residence_type_id]) REFERENCES [DB_Reference].[Reference].[ResidenceTypes]([residence_type_id]);
-- ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Status FOREIGN KEY ([res_reg_status_id]) REFERENCES [DB_Reference].[Reference].[ResidenceRegistrationStatuses]([res_reg_status_id]);

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_ResidenceHistory_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT CK_ResidenceHistory_Dates;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT CK_ResidenceHistory_Dates CHECK ([registration_date] <= GETDATE() AND ([expiry_date] IS NULL OR [expiry_date] >= [registration_date]) AND ([last_extension_date] IS NULL OR ([last_extension_date] >= [registration_date] AND [last_extension_date] <= GETDATE())) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.TemporaryAbsence
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.TemporaryAbsence...';

-- Foreign Keys within DB_BCA
IF OBJECT_ID('BCA.FK_TemporaryAbsence_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_Citizen;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_TemporaryAbsence_DestAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_DestAddress;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_DestAddress FOREIGN KEY ([destination_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Authority FOREIGN KEY ([registration_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Status FOREIGN KEY ([temp_abs_status_id]) REFERENCES [DB_Reference].[Reference].[TemporaryAbsenceStatuses]([temp_abs_status_id]);
-- ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Sensitivity FOREIGN KEY ([sensitivity_level_id]) REFERENCES [DB_Reference].[Reference].[DataSensitivityLevels]([sensitivity_level_id]);

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_TemporaryAbsence_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT CK_TemporaryAbsence_Dates;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT CK_TemporaryAbsence_Dates CHECK ([from_date] <= GETDATE() AND ([to_date] IS NULL OR [to_date] >= [from_date]) AND ([return_date] IS NULL OR [return_date] >= [from_date]) AND ([return_confirmed_date] IS NULL OR ([return_confirmed_date] >= [from_date] AND [return_confirmed_date] <= GETDATE())) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.CitizenStatus
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenStatus...';

-- Foreign Keys within DB_BCA
IF OBJECT_ID('BCA.FK_CitizenStatus_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Citizen;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Authority FOREIGN KEY ([authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Type FOREIGN KEY ([citizen_status_type_id]) REFERENCES [DB_Reference].[Reference].[CitizenStatusTypes]([citizen_status_type_id]);

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_CitizenStatus_Date', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT CK_CitizenStatus_Date;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_Date CHECK ([status_date] <= GETDATE());
GO

IF OBJECT_ID('BCA.CK_CitizenStatus_DocumentDate', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT CK_CitizenStatus_DocumentDate;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_DocumentDate CHECK ([document_date] IS NULL OR [document_date] <= GETDATE());
GO

-- Check constraint relating status type to cause/location (needs adaptation based on IDs)
-- Original: CHECK (([status_type] IN (N'Đã mất', N'Mất tích') AND [cause] IS NOT NULL AND [location] IS NOT NULL) OR ([status_type] = N'Còn sống'))
-- This needs to be updated based on the actual IDs assigned to 'Đã mất', 'Mất tích', 'Còn sống' in Reference.CitizenStatusTypes.
-- Commenting out for now. Application logic should enforce this.
-- IF OBJECT_ID('BCA.CK_CitizenStatus_CauseLocationRequired', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT CK_CitizenStatus_CauseLocationRequired;
-- GO
-- PRINT N'  WARNING: CK_CitizenStatus_CauseLocationRequired needs adaptation based on actual citizen_status_type_id values. Constraint not created.';
-- GO

--------------------------------------------------------------------------------
-- Constraints for BCA.CitizenMovement
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenMovement...';

-- Foreign Keys within DB_BCA
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

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_FromCtry FOREIGN KEY ([from_country_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_ToCtry FOREIGN KEY ([to_country_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_Type FOREIGN KEY ([movement_type_id]) REFERENCES [DB_Reference].[Reference].[CitizenMovementTypes]([movement_type_id]);
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_Status FOREIGN KEY ([movement_status_id]) REFERENCES [DB_Reference].[Reference].[CitizenMovementStatuses]([movement_status_id]);
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_DocType FOREIGN KEY ([document_type_id]) REFERENCES [DB_Reference].[Reference].[DocumentTypes]([document_type_id]); -- Assuming DocumentTypes table exists

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_CitizenMovement_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT CK_CitizenMovement_Dates;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT CK_CitizenMovement_Dates CHECK ([departure_date] <= GETDATE() AND ([arrival_date] IS NULL OR [arrival_date] >= [departure_date]) AND ([document_issue_date] IS NULL OR [document_issue_date] <= [departure_date]) AND ([document_expiry_date] IS NULL OR [document_expiry_date] >= [document_issue_date]));
GO

-- Check constraints related to movement type (needs adaptation based on IDs)
-- Original CK_CitizenMovement_International: CHECK (([movement_type] IN (N'Xuất cảnh', N'Tái nhập cảnh') AND [to_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type] = N'Nhập cảnh' AND [from_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type] = N'Trong nước'))
-- Original CK_CitizenMovement_AddressCountry: CHECK ( NOT ([movement_type] = N'Xuất cảnh' AND [from_address_id] IS NOT NULL) AND NOT ([movement_type] = N'Nhập cảnh' AND [to_address_id] IS NOT NULL) )
-- Commenting out for now. Application logic should enforce these based on movement_type_id.
-- IF OBJECT_ID('BCA.CK_CitizenMovement_International', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT CK_CitizenMovement_International;
-- GO
-- IF OBJECT_ID('BCA.CK_CitizenMovement_AddressCountry', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT CK_CitizenMovement_AddressCountry;
-- GO
-- PRINT N'  WARNING: CK_CitizenMovement_International and CK_CitizenMovement_AddressCountry need adaptation based on actual movement_type_id values. Constraints not created.';
-- GO


--------------------------------------------------------------------------------
-- Constraints for BCA.CriminalRecord
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CriminalRecord...';

-- Foreign Keys within DB_BCA
IF OBJECT_ID('BCA.FK_CriminalRecord_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_Citizen;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Prison FOREIGN KEY ([prison_facility_id]) REFERENCES [DB_Reference].[Reference].[PrisonFacilities]([prison_facility_id]);
-- ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_CrimeType FOREIGN KEY ([crime_type_id]) REFERENCES [DB_Reference].[Reference].[CrimeTypes]([crime_type_id]);
-- ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Sensitivity FOREIGN KEY ([sensitivity_level_id]) REFERENCES [DB_Reference].[Reference].[DataSensitivityLevels]([sensitivity_level_id]);
-- ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_ExecStatus FOREIGN KEY ([execution_status_id]) REFERENCES [DB_Reference].[Reference].[ExecutionStatuses]([execution_status_id]); -- Assuming ExecutionStatuses table exists


-- CHECK Constraints
IF OBJECT_ID('BCA.CK_CriminalRecord_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT CK_CriminalRecord_Dates;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT CK_CriminalRecord_Dates CHECK (([crime_date] IS NULL OR [crime_date] <= GETDATE()) AND ([judgment_date] IS NULL OR [judgment_date] <= GETDATE()) AND ([sentence_start_date] IS NULL OR [sentence_start_date] <= GETDATE()) AND ([sentence_end_date] IS NULL OR [sentence_end_date] >= [sentence_start_date]));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.CitizenAddress
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenAddress...';

-- Foreign Keys within DB_BCA
IF OBJECT_ID('BCA.FK_CitizenAddress_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Citizen;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenAddress_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Address;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Type FOREIGN KEY ([address_type_id]) REFERENCES [DB_Reference].[Reference].[AddressTypes]([address_type_id]);

-- CHECK Constraints
IF OBJECT_ID('BCA.CK_CitizenAddress_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT CK_CitizenAddress_Dates;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT CK_CitizenAddress_Dates CHECK ([from_date] <= GETDATE() AND ([to_date] IS NULL OR [to_date] >= [from_date]) AND ([registration_date] IS NULL OR [registration_date] <= GETDATE()) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO

PRINT N'Finished creating constraints for tables in DB_BCA.'; NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_MaritalStatus;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_MaritalStatus FOREIGN KEY ([marital_status_id]) REFERENCES [Reference].[MaritalStatuses]([marital_status_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_EducationLevel', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_EducationLevel;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_EducationLevel FOREIGN KEY ([education_level_id]) REFERENCES [Reference].[EducationLevels]([education_level_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_DeathStatus', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_DeathStatus;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_DeathStatus FOREIGN KEY ([citizen_death_status_id]) REFERENCES [Reference].[CitizenDeathStatuses]([citizen_death_status_id]);
GO

IF OBJECT_ID('BCA.FK_Citizen_BloodType', 'F') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT FK_Citizen_BloodType;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BloodType FOREIGN KEY ([blood_type_id]) REFERENCES [Reference].[BloodTypes]([blood_type_id]);
GO

-- Self-referencing Foreign Keys (within BCA.Citizen)
PRINT N'  Adding Self-Referencing Foreign Keys for BCA.Citizen...';
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

-- CHECK Constraints for BCA.Citizen
PRINT N'  Adding CHECK Constraints for BCA.Citizen...';
IF OBJECT_ID('BCA.CK_Citizen_BirthDate', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_BirthDate;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_BirthDate CHECK ([date_of_birth] < GETDATE());
GO

-- Check constraint for death date (requires knowing the ID for 'Đã mất')
-- Assuming ID=2 for 'Đã mất' based on sample_data.sql. Verify this ID!
-- IF OBJECT_ID('BCA.CK_Citizen_DeathDate', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_DeathDate;
-- GO
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_DeathDate CHECK (([citizen_death_status_id] = 2 AND [date_of_death] IS NOT NULL AND [date_of_death] <= GETDATE()) OR ([citizen_death_status_id] <> 2));
-- GO
PRINT N'  WARNING: CK_Citizen_DeathDate check requires knowing the exact ID for "Đã mất" status. Constraint commented out for safety.';

IF OBJECT_ID('BCA.CK_Citizen_Parents', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_Parents;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_Parents CHECK ([citizen_id] <> [father_citizen_id] AND [citizen_id] <> [mother_citizen_id]);
GO

IF OBJECT_ID('BCA.CK_Citizen_EmailFormat', 'C') IS NOT NULL ALTER TABLE [BCA].[Citizen] DROP CONSTRAINT CK_Citizen_EmailFormat;
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_EmailFormat CHECK ([email] IS NULL OR [email] LIKE '%_@__%.__%');
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.Address
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.Address...';

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.Address to Reference schema...';
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

-- CHECK Constraints for BCA.Address
PRINT N'  Adding CHECK Constraints for BCA.Address...';
IF OBJECT_ID('BCA.CK_Address_LatLon', 'C') IS NOT NULL ALTER TABLE [BCA].[Address] DROP CONSTRAINT CK_Address_LatLon;
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT CK_Address_LatLon CHECK (([latitude] IS NULL AND [longitude] IS NULL) OR ([latitude] BETWEEN -90 AND 90 AND [longitude] BETWEEN -180 AND 180));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.IdentificationCard
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.IdentificationCard...';

-- Foreign Keys within DB_BCA (to BCA.Citizen)
PRINT N'  Adding Foreign Key from BCA.IdentificationCard to BCA.Citizen...';
IF OBJECT_ID('BCA.FK_IdentificationCard_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT FK_IdentificationCard_Citizen;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.IdentificationCard to Reference schema...';
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

-- CHECK Constraints for BCA.IdentificationCard
PRINT N'  Adding CHECK Constraints for BCA.IdentificationCard...';
IF OBJECT_ID('BCA.CK_IdentificationCard_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[IdentificationCard] DROP CONSTRAINT CK_IdentificationCard_Dates;
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT CK_IdentificationCard_Dates CHECK ([issue_date] <= GETDATE() AND ([expiry_date] IS NULL OR [expiry_date] > [issue_date]));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.ResidenceHistory
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.ResidenceHistory...';

-- Foreign Keys within DB_BCA (to BCA.Citizen, BCA.Address)
PRINT N'  Adding Foreign Keys from BCA.ResidenceHistory to BCA schema...';
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

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.ResidenceHistory to Reference schema...';
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

-- CHECK Constraints for BCA.ResidenceHistory
PRINT N'  Adding CHECK Constraints for BCA.ResidenceHistory...';
IF OBJECT_ID('BCA.CK_ResidenceHistory_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[ResidenceHistory] DROP CONSTRAINT CK_ResidenceHistory_Dates;
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT CK_ResidenceHistory_Dates CHECK ([registration_date] <= GETDATE() AND ([expiry_date] IS NULL OR [expiry_date] >= [registration_date]) AND ([last_extension_date] IS NULL OR ([last_extension_date] >= [registration_date] AND [last_extension_date] <= GETDATE())) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.TemporaryAbsence
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.TemporaryAbsence...';

-- Foreign Keys within DB_BCA (to BCA.Citizen, BCA.Address)
PRINT N'  Adding Foreign Keys from BCA.TemporaryAbsence to BCA schema...';
IF OBJECT_ID('BCA.FK_TemporaryAbsence_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_Citizen;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_TemporaryAbsence_DestAddress', 'F') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT FK_TemporaryAbsence_DestAddress;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_DestAddress FOREIGN KEY ([destination_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.TemporaryAbsence to Reference schema...';
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

-- CHECK Constraints for BCA.TemporaryAbsence
PRINT N'  Adding CHECK Constraints for BCA.TemporaryAbsence...';
IF OBJECT_ID('BCA.CK_TemporaryAbsence_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[TemporaryAbsence] DROP CONSTRAINT CK_TemporaryAbsence_Dates;
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT CK_TemporaryAbsence_Dates CHECK ([from_date] <= GETDATE() AND ([to_date] IS NULL OR [to_date] >= [from_date]) AND ([return_date] IS NULL OR [return_date] >= [from_date]) AND ([return_confirmed_date] IS NULL OR ([return_confirmed_date] >= [from_date] AND [return_confirmed_date] <= GETDATE())) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.CitizenStatus
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenStatus...';

-- Foreign Keys within DB_BCA (to BCA.Citizen)
PRINT N'  Adding Foreign Key from BCA.CitizenStatus to BCA.Citizen...';
IF OBJECT_ID('BCA.FK_CitizenStatus_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Citizen;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.CitizenStatus to Reference schema...';
IF OBJECT_ID('BCA.FK_CitizenStatus_Authority', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Authority;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Authority FOREIGN KEY ([authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenStatus_Type', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT FK_CitizenStatus_Type;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Type FOREIGN KEY ([citizen_status_type_id]) REFERENCES [Reference].[CitizenStatusTypes]([citizen_status_type_id]);
GO

-- CHECK Constraints for BCA.CitizenStatus
PRINT N'  Adding CHECK Constraints for BCA.CitizenStatus...';
IF OBJECT_ID('BCA.CK_CitizenStatus_Date', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT CK_CitizenStatus_Date;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_Date CHECK ([status_date] <= GETDATE());
GO

IF OBJECT_ID('BCA.CK_CitizenStatus_DocumentDate', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT CK_CitizenStatus_DocumentDate;
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_DocumentDate CHECK ([document_date] IS NULL OR [document_date] <= GETDATE());
GO

-- Check constraint relating status type to cause/location (requires specific IDs)
-- Original: CHECK (([status_type] IN (N'Đã mất', N'Mất tích') AND [cause] IS NOT NULL AND [location] IS NOT NULL) OR ([status_type] = N'Còn sống'))
-- Assuming IDs from sample_data: 'Đã mất' = 2, 'Mất tích' = 3
-- IF OBJECT_ID('BCA.CK_CitizenStatus_CauseLocationRequired', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenStatus] DROP CONSTRAINT CK_CitizenStatus_CauseLocationRequired;
-- GO
-- ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_CauseLocationRequired CHECK (([citizen_status_type_id] IN (2, 3) AND [cause] IS NOT NULL AND [location] IS NOT NULL) OR ([citizen_status_type_id] NOT IN (2, 3)));
-- GO
PRINT N'  WARNING: CK_CitizenStatus_CauseLocationRequired needs adaptation based on actual citizen_status_type_id values. Constraint commented out for safety.';


--------------------------------------------------------------------------------
-- Constraints for BCA.CitizenMovement
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenMovement...';

-- Foreign Keys within DB_BCA (to BCA.Citizen, BCA.Address)
PRINT N'  Adding Foreign Keys from BCA.CitizenMovement to BCA schema...';
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

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.CitizenMovement to Reference schema...';
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

-- Note: FK_CitizenMovement_DocType depends on a Reference.DocumentTypes table which was not explicitly defined in the original CSDLQG structure.
-- If you create Reference.DocumentTypes, uncomment and add the following:
-- IF OBJECT_ID('BCA.FK_CitizenMovement_DocType', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT FK_CitizenMovement_DocType;
-- GO
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_DocType FOREIGN KEY ([document_type_id]) REFERENCES [Reference].[DocumentTypes]([document_type_id]);
-- GO

-- CHECK Constraints for BCA.CitizenMovement
PRINT N'  Adding CHECK Constraints for BCA.CitizenMovement...';
IF OBJECT_ID('BCA.CK_CitizenMovement_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT CK_CitizenMovement_Dates;
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT CK_CitizenMovement_Dates CHECK ([departure_date] <= GETDATE() AND ([arrival_date] IS NULL OR [arrival_date] >= [departure_date]) AND ([document_issue_date] IS NULL OR [document_issue_date] <= [departure_date]) AND ([document_expiry_date] IS NULL OR [document_expiry_date] >= [document_issue_date]));
GO

-- Check constraints related to movement type (require specific IDs)
-- Original CK_CitizenMovement_International: CHECK (([movement_type] IN (N'Xuất cảnh', N'Tái nhập cảnh') AND [to_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type] = N'Nhập cảnh' AND [from_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type] = N'Trong nước'))
-- Original CK_CitizenMovement_AddressCountry: CHECK ( NOT ([movement_type] = N'Xuất cảnh' AND [from_address_id] IS NOT NULL) AND NOT ([movement_type] = N'Nhập cảnh' AND [to_address_id] IS NOT NULL) )
-- Assuming IDs from sample_data: 'Trong nước'=1, 'Xuất cảnh'=2, 'Nhập cảnh'=3, 'Tái nhập cảnh'=4
-- IF OBJECT_ID('BCA.CK_CitizenMovement_International', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT CK_CitizenMovement_International;
-- GO
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT CK_CitizenMovement_International CHECK (([movement_type_id] IN (2, 4) AND [to_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type_id] = 3 AND [from_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type_id] NOT IN (2, 3, 4)));
-- GO
-- IF OBJECT_ID('BCA.CK_CitizenMovement_AddressCountry', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenMovement] DROP CONSTRAINT CK_CitizenMovement_AddressCountry;
-- GO
-- ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT CK_CitizenMovement_AddressCountry CHECK ( NOT ([movement_type_id] = 2 AND [from_address_id] IS NOT NULL) AND NOT ([movement_type_id] = 3 AND [to_address_id] IS NOT NULL) );
-- GO
PRINT N'  WARNING: CK_CitizenMovement_International and CK_CitizenMovement_AddressCountry need adaptation based on actual movement_type_id values. Constraints commented out for safety.';


--------------------------------------------------------------------------------
-- Constraints for BCA.CriminalRecord
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CriminalRecord...';

-- Foreign Keys within DB_BCA (to BCA.Citizen)
PRINT N'  Adding Foreign Key from BCA.CriminalRecord to BCA.Citizen...';
IF OBJECT_ID('BCA.FK_CriminalRecord_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_Citizen;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.CriminalRecord to Reference schema...';
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

-- Note: FK_CriminalRecord_ExecStatus depends on a Reference.ExecutionStatuses table which was not defined.
-- If you create Reference.ExecutionStatuses, uncomment and add the following:
-- IF OBJECT_ID('BCA.FK_CriminalRecord_ExecStatus', 'F') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT FK_CriminalRecord_ExecStatus;
-- GO
-- ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_ExecStatus FOREIGN KEY ([execution_status_id]) REFERENCES [Reference].[ExecutionStatuses]([execution_status_id]);
-- GO

-- CHECK Constraints for BCA.CriminalRecord
PRINT N'  Adding CHECK Constraints for BCA.CriminalRecord...';
IF OBJECT_ID('BCA.CK_CriminalRecord_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[CriminalRecord] DROP CONSTRAINT CK_CriminalRecord_Dates;
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT CK_CriminalRecord_Dates CHECK (([crime_date] IS NULL OR [crime_date] <= GETDATE()) AND ([judgment_date] IS NULL OR [judgment_date] <= GETDATE()) AND ([sentence_start_date] IS NULL OR [sentence_start_date] <= GETDATE()) AND ([sentence_end_date] IS NULL OR [sentence_end_date] >= [sentence_start_date]));
GO

--------------------------------------------------------------------------------
-- Constraints for BCA.CitizenAddress
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BCA.CitizenAddress...';

-- Foreign Keys within DB_BCA (to BCA.Citizen, BCA.Address)
PRINT N'  Adding Foreign Keys from BCA.CitizenAddress to BCA schema...';
IF OBJECT_ID('BCA.FK_CitizenAddress_Citizen', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Citizen;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenAddress_Address', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Address;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
GO

-- Foreign Keys to DB_BCA.Reference schema
PRINT N'  Adding Foreign Keys from BCA.CitizenAddress to Reference schema...';
IF OBJECT_ID('BCA.FK_CitizenAddress_Authority', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Authority;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

IF OBJECT_ID('BCA.FK_CitizenAddress_Type', 'F') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT FK_CitizenAddress_Type;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Type FOREIGN KEY ([address_type_id]) REFERENCES [Reference].[AddressTypes]([address_type_id]);
GO

-- CHECK Constraints for BCA.CitizenAddress
PRINT N'  Adding CHECK Constraints for BCA.CitizenAddress...';
IF OBJECT_ID('BCA.CK_CitizenAddress_Dates', 'C') IS NOT NULL ALTER TABLE [BCA].[CitizenAddress] DROP CONSTRAINT CK_CitizenAddress_Dates;
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT CK_CitizenAddress_Dates CHECK ([from_date] <= GETDATE() AND ([to_date] IS NULL OR [to_date] >= [from_date]) AND ([registration_date] IS NULL OR [registration_date] <= GETDATE()) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO

PRINT N'Finished creating constraints for tables in DB_BCA.BCA schema.';
GO

PRINT N'========================================================';
PRINT N'Finished creating ALL constraints for DB_BCA.';
PRINT N'========================================================';
GO
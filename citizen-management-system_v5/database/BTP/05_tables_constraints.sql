-- Script to create constraints for tables in database DB_BTP (Bộ Tư pháp)
-- This script should be run on the SQL Server instance dedicated to DB_BTP,
-- after DB_BTP tables have been created.
-- NOTE: Physical Foreign Keys to DB_Reference or DB_BCA are commented out as they require Linked Servers
--       or application-level enforcement due to separate DB instances.

USE [DB_BTP];
GO

PRINT N'Creating constraints for tables in DB_BTP...';

--------------------------------------------------------------------------------
-- Constraints for BTP.BirthCertificate
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.BirthCertificate...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT FK_BirthCertificate_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT FK_BirthCertificate_FatherNationality FOREIGN KEY ([father_nationality_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT FK_BirthCertificate_MotherNationality FOREIGN KEY ([mother_nationality_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT FK_BirthCertificate_Gender FOREIGN KEY ([gender_id]) REFERENCES [DB_Reference].[Reference].[Genders]([gender_id]);

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_BirthCertificate_Dates', 'C') IS NOT NULL ALTER TABLE [BTP].[BirthCertificate] DROP CONSTRAINT CK_BirthCertificate_Dates;
GO
ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT CK_BirthCertificate_Dates CHECK ([date_of_birth] < GETDATE() AND [registration_date] >= [date_of_birth] AND [registration_date] <= GETDATE());
GO

-- UNIQUE Constraints (Consider implementing via NonClustered Index or at application level)
-- PRINT N'  Recommendation: Add UNIQUE constraint/index for [birth_certificate_no] on BTP.BirthCertificate.';
-- PRINT N'  Recommendation: Add UNIQUE constraint/index for [citizen_id] on BTP.BirthCertificate (if one citizen has only one birth cert).';
-- Example using Index:
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_BirthCertificate_Number') DROP INDEX UQ_BirthCertificate_Number ON BTP.BirthCertificate;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_BirthCertificate_Number ON BTP.BirthCertificate(birth_certificate_no) WHERE status = 1; -- Optional: Only for active certs
-- GO

--------------------------------------------------------------------------------
-- Constraints for BTP.DeathCertificate
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.DeathCertificate...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_PlaceWard FOREIGN KEY ([place_of_death_ward_id]) REFERENCES [DB_Reference].[Reference].[Wards]([ward_id]);
-- ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_PlaceDistrict FOREIGN KEY ([place_of_death_district_id]) REFERENCES [DB_Reference].[Reference].[Districts]([district_id]);
-- ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_PlaceProvince FOREIGN KEY ([place_of_death_province_id]) REFERENCES [DB_Reference].[Reference].[Provinces]([province_id]);

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_DeathCertificate_Dates', 'C') IS NOT NULL ALTER TABLE [BTP].[DeathCertificate] DROP CONSTRAINT CK_DeathCertificate_Dates;
GO
ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT CK_DeathCertificate_Dates CHECK ([date_of_death] <= GETDATE() AND [registration_date] >= [date_of_death] AND [registration_date] <= GETDATE());
GO

-- UNIQUE Constraints (from original file)
PRINT N'  Adding UNIQUE constraints for BTP.DeathCertificate...';
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BTP.DeathCertificate') AND name = 'UQ_DeathCertificate_CitizenID')
    DROP INDEX UQ_DeathCertificate_CitizenID ON [BTP].[DeathCertificate];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_DeathCertificate_CitizenID
ON [BTP].[DeathCertificate] ([citizen_id])
WHERE ([status] = 1); -- Chỉ áp dụng cho giấy chứng tử còn hiệu lực (status=1 means Active)
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('BTP.DeathCertificate') AND name = 'UQ_DeathCertificate_Number')
    DROP INDEX UQ_DeathCertificate_Number ON [BTP].[DeathCertificate];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_DeathCertificate_Number
ON [BTP].[DeathCertificate] ([death_certificate_no])
WHERE ([status] = 1); -- Chỉ áp dụng cho giấy chứng tử còn hiệu lực
GO

--------------------------------------------------------------------------------
-- Constraints for BTP.MarriageCertificate
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.MarriageCertificate...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_HusbandNationality FOREIGN KEY ([husband_nationality_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_WifeNationality FOREIGN KEY ([wife_nationality_id]) REFERENCES [DB_Reference].[Reference].[Nationalities]([nationality_id]);
-- ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_HusbandPrevStatus FOREIGN KEY ([husband_previous_marital_status_id]) REFERENCES [DB_Reference].[Reference].[MaritalStatuses]([marital_status_id]);
-- ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_WifePrevStatus FOREIGN KEY ([wife_previous_marital_status_id]) REFERENCES [DB_Reference].[Reference].[MaritalStatuses]([marital_status_id]);

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_MarriageCertificate_Dates', 'C') IS NOT NULL ALTER TABLE [BTP].[MarriageCertificate] DROP CONSTRAINT CK_MarriageCertificate_Dates;
GO
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT CK_MarriageCertificate_Dates CHECK ([marriage_date] <= GETDATE() AND [registration_date] >= [marriage_date] AND [registration_date] <= GETDATE());
GO

IF OBJECT_ID('BTP.CK_MarriageCertificate_Ages', 'C') IS NOT NULL ALTER TABLE [BTP].[MarriageCertificate] DROP CONSTRAINT CK_MarriageCertificate_Ages;
GO
-- Check age based on marriage date (adjust ages according to Vietnamese Law, e.g., >= 20 for male, >= 18 for female)
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT CK_MarriageCertificate_Ages CHECK (DATEDIFF(year, [husband_date_of_birth], [marriage_date]) >= 20 AND DATEDIFF(year, [wife_date_of_birth], [marriage_date]) >= 18);
GO

IF OBJECT_ID('BTP.CK_MarriageCertificate_DifferentPeople', 'C') IS NOT NULL ALTER TABLE [BTP].[MarriageCertificate] DROP CONSTRAINT CK_MarriageCertificate_DifferentPeople;
GO
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT CK_MarriageCertificate_DifferentPeople CHECK ([husband_id] <> [wife_id]);
GO

-- UNIQUE Constraints (Consider adding)
-- PRINT N'  Recommendation: Add UNIQUE constraint/index for [marriage_certificate_no] on BTP.MarriageCertificate.';
-- Example:
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_MarriageCertificate_Number') DROP INDEX UQ_MarriageCertificate_Number ON BTP.MarriageCertificate;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_MarriageCertificate_Number ON BTP.MarriageCertificate(marriage_certificate_no) WHERE status = 1;
-- GO

--------------------------------------------------------------------------------
-- Constraints for BTP.DivorceRecord
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.DivorceRecord...';

-- Foreign Keys within DB_BTP
IF OBJECT_ID('BTP.FK_DivorceRecord_MarriageCertificate', 'F') IS NOT NULL ALTER TABLE [BTP].[DivorceRecord] DROP CONSTRAINT FK_DivorceRecord_MarriageCertificate;
GO
ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT FK_DivorceRecord_MarriageCertificate FOREIGN KEY ([marriage_certificate_id]) REFERENCES [BTP].[MarriageCertificate]([marriage_certificate_id]);
GO

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT FK_DivorceRecord_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_DivorceRecord_Dates', 'C') IS NOT NULL ALTER TABLE [BTP].[DivorceRecord] DROP CONSTRAINT CK_DivorceRecord_Dates;
GO
ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT CK_DivorceRecord_Dates CHECK ([divorce_date] <= GETDATE() AND [registration_date] <= GETDATE() AND [judgment_date] <= [registration_date] AND [judgment_date] <= [divorce_date]);
GO

-- UNIQUE Constraints (Consider adding)
-- PRINT N'  Recommendation: Add UNIQUE constraint/index for [judgment_no] on BTP.DivorceRecord.';
-- PRINT N'  Recommendation: Add UNIQUE constraint/index for [marriage_certificate_id] on BTP.DivorceRecord (if a marriage can only be divorced once).';
-- Example:
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_DivorceRecord_JudgmentNo') DROP INDEX UQ_DivorceRecord_JudgmentNo ON BTP.DivorceRecord;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_DivorceRecord_JudgmentNo ON BTP.DivorceRecord(judgment_no);
-- GO
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_DivorceRecord_MarriageCert') DROP INDEX UQ_DivorceRecord_MarriageCert ON BTP.DivorceRecord;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_DivorceRecord_MarriageCert ON BTP.DivorceRecord(marriage_certificate_id);
-- GO

--------------------------------------------------------------------------------
-- Constraints for BTP.Household
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.Household...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[Household] ADD CONSTRAINT FK_Household_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BTP].[Household] ADD CONSTRAINT FK_Household_Type FOREIGN KEY ([household_type_id]) REFERENCES [DB_Reference].[Reference].[HouseholdTypes]([household_type_id]);
-- ALTER TABLE [BTP].[Household] ADD CONSTRAINT FK_Household_Status FOREIGN KEY ([household_status_id]) REFERENCES [DB_Reference].[Reference].[HouseholdStatuses]([household_status_id]);

-- == Logical Foreign Keys to other DBs (BCA) ==
-- Note: [head_of_household_id] logically links to BCA.Citizen
-- Note: [address_id] logically links to BCA.Address

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_Household_RegistrationDate', 'C') IS NOT NULL ALTER TABLE [BTP].[Household] DROP CONSTRAINT CK_Household_RegistrationDate;
GO
ALTER TABLE [BTP].[Household] ADD CONSTRAINT CK_Household_RegistrationDate CHECK ([registration_date] <= GETDATE());
GO

-- UNIQUE Constraints (Consider adding)
-- PRINT N'  Recommendation: Add UNIQUE constraint/index for [household_book_no] on BTP.Household.';
-- Example:
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_Household_BookNo') DROP INDEX UQ_Household_BookNo ON BTP.Household;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_Household_BookNo ON BTP.Household(household_book_no);
-- GO

--------------------------------------------------------------------------------
-- Constraints for BTP.HouseholdMember
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.HouseholdMember...';

-- Foreign Keys within DB_BTP
IF OBJECT_ID('BTP.FK_HouseholdMember_Household', 'F') IS NOT NULL ALTER TABLE [BTP].[HouseholdMember] DROP CONSTRAINT FK_HouseholdMember_Household;
GO
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT FK_HouseholdMember_Household FOREIGN KEY ([household_id]) REFERENCES [BTP].[Household]([household_id]);
GO

IF OBJECT_ID('BTP.FK_HouseholdMember_PreviousHousehold', 'F') IS NOT NULL ALTER TABLE [BTP].[HouseholdMember] DROP CONSTRAINT FK_HouseholdMember_PreviousHousehold;
GO
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT FK_HouseholdMember_PreviousHousehold FOREIGN KEY ([previous_household_id]) REFERENCES [BTP].[Household]([household_id]);
GO

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT FK_HouseholdMember_Relationship FOREIGN KEY ([rel_with_head_id]) REFERENCES [DB_Reference].[Reference].[RelationshipWithHeadTypes]([rel_with_head_id]);
-- ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT FK_HouseholdMember_Status FOREIGN KEY ([member_status_id]) REFERENCES [DB_Reference].[Reference].[HouseholdMemberStatuses]([member_status_id]);

-- == Logical Foreign Keys to other DBs (BCA) ==
-- Note: [citizen_id] logically links to BCA.Citizen

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_HouseholdMember_Dates', 'C') IS NOT NULL ALTER TABLE [BTP].[HouseholdMember] DROP CONSTRAINT CK_HouseholdMember_Dates;
GO
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT CK_HouseholdMember_Dates CHECK ([join_date] <= GETDATE() AND ([leave_date] IS NULL OR [leave_date] >= [join_date]));
GO

IF OBJECT_ID('BTP.CK_HouseholdMember_Order', 'C') IS NOT NULL ALTER TABLE [BTP].[HouseholdMember] DROP CONSTRAINT CK_HouseholdMember_Order;
GO
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT CK_HouseholdMember_Order CHECK ([order_in_household] IS NULL OR [order_in_household] > 0);
GO

-- UNIQUE Constraints (More complex logic, often handled at application level)
-- PRINT N'  Note: Ensuring a citizen is active in only one household usually requires triggers or application logic.';
-- Example Constraint (may not work directly depending on SQL Server version/edition without indexed view):
-- IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_HouseholdMember_ActiveCitizen') DROP INDEX UQ_HouseholdMember_ActiveCitizen ON BTP.HouseholdMember;
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_HouseholdMember_ActiveCitizen ON BTP.HouseholdMember(citizen_id) WHERE member_status_id = [ID for 'Active'];
-- GO

--------------------------------------------------------------------------------
-- Constraints for BTP.FamilyRelationship
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.FamilyRelationship...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT FK_FamilyRelationship_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT FK_FamilyRelationship_Type FOREIGN KEY ([relationship_type_id]) REFERENCES [DB_Reference].[Reference].[RelationshipTypes]([relationship_type_id]);
-- ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT FK_FamilyRelationship_Status FOREIGN KEY ([family_rel_status_id]) REFERENCES [DB_Reference].[Reference].[FamilyRelationshipStatuses]([family_rel_status_id]);

-- == Logical Foreign Keys to other DBs (BCA) ==
-- Note: [citizen_id], [related_citizen_id] logically link to BCA.Citizen

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_FamilyRelationship_Dates', 'C') IS NOT NULL ALTER TABLE [BTP].[FamilyRelationship] DROP CONSTRAINT CK_FamilyRelationship_Dates;
GO
ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT CK_FamilyRelationship_Dates CHECK ([start_date] <= GETDATE() AND ([end_date] IS NULL OR [end_date] >= [start_date]));
GO

IF OBJECT_ID('BTP.CK_FamilyRelationship_DifferentPeople', 'C') IS NOT NULL ALTER TABLE [BTP].[FamilyRelationship] DROP CONSTRAINT CK_FamilyRelationship_DifferentPeople;
GO
ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT CK_FamilyRelationship_DifferentPeople CHECK ([citizen_id] <> [related_citizen_id]);
GO

--------------------------------------------------------------------------------
-- Constraints for BTP.PopulationChange
--------------------------------------------------------------------------------
PRINT N'Applying constraints to BTP.PopulationChange...';

-- == Logical Foreign Keys to DB_Reference (Enforced by Application) ==
-- ALTER TABLE [BTP].[PopulationChange] ADD CONSTRAINT FK_PopulationChange_Authority FOREIGN KEY ([processing_authority_id]) REFERENCES [DB_Reference].[Reference].[Authorities]([authority_id]);
-- ALTER TABLE [BTP].[PopulationChange] ADD CONSTRAINT FK_PopulationChange_Type FOREIGN KEY ([pop_change_type_id]) REFERENCES [DB_Reference].[Reference].[PopulationChangeTypes]([pop_change_type_id]);
-- Note: [source_location_id], [destination_location_id] might logically link to Reference.Wards or other location tables.

-- == Logical Foreign Keys to other DBs (BCA) ==
-- Note: [citizen_id] logically links to BCA.Citizen

-- CHECK Constraints
IF OBJECT_ID('BTP.CK_PopulationChange_Date', 'C') IS NOT NULL ALTER TABLE [BTP].[PopulationChange] DROP CONSTRAINT CK_PopulationChange_Date;
GO
ALTER TABLE [BTP].[PopulationChange] ADD CONSTRAINT CK_PopulationChange_Date CHECK ([change_date] <= GETDATE());
GO

--------------------------------------------------------------------------------
-- Constraints for Audit.AuditLog (in DB_BTP)
--------------------------------------------------------------------------------
-- No specific FKs typically defined on AuditLog, but keeping the CHECK constraint
IF OBJECT_ID('Audit.CK_AuditLog_Operation', 'C') IS NOT NULL ALTER TABLE [Audit].[AuditLog] DROP CONSTRAINT CK_AuditLog_Operation;
GO
-- Re-adding CHECK constraint if it was dropped with the table
ALTER TABLE [Audit].[AuditLog] ADD CONSTRAINT CK_AuditLog_Operation CHECK ([operation] IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE'));
GO

--------------------------------------------------------------------------------
-- Constraints for BTP.EventOutbox
--------------------------------------------------------------------------------
-- No specific FKs or standard CHECK constraints typically defined on EventOutbox by default.

PRINT N'Finished creating constraints for tables in DB_BTP.';
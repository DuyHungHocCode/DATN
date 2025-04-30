-- Cleanup Script with Complete Tables for DB_BCA
-- This script removes all sample data to enable clean re-testing

-- ============================================
-- CLEANUP FOR DB_BCA WITH ALL TABLES
-- ============================================
USE [DB_BCA];
GO

-- Disable foreign key constraints temporarily
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Clear Audit logs if they exist
IF OBJECT_ID('Audit.AuditLog', 'U') IS NOT NULL
BEGIN
    TRUNCATE TABLE [Audit].[AuditLog];
END
GO

-- Clear Business tables in proper order (considering dependencies)

-- Tables that depend on Citizen but have no dependents
IF OBJECT_ID('BCA.TemporaryAbsence', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[TemporaryAbsence];
    DBCC CHECKIDENT ('[BCA].[TemporaryAbsence]', RESEED, 0);
END
GO

IF OBJECT_ID('BCA.CitizenMovement', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[CitizenMovement];
    DBCC CHECKIDENT ('[BCA].[CitizenMovement]', RESEED, 0);
END
GO

IF OBJECT_ID('BCA.CitizenAddress', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[CitizenAddress];
    DBCC CHECKIDENT ('[BCA].[CitizenAddress]', RESEED, 0);
END
GO

IF OBJECT_ID('BCA.CitizenStatus', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[CitizenStatus];
    DBCC CHECKIDENT ('[BCA].[CitizenStatus]', RESEED, 0);
END
GO

IF OBJECT_ID('BCA.CriminalRecord', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[CriminalRecord];
    DBCC CHECKIDENT ('[BCA].[CriminalRecord]', RESEED, 0);
END
GO

IF OBJECT_ID('BCA.ResidenceHistory', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[ResidenceHistory];
    DBCC CHECKIDENT ('[BCA].[ResidenceHistory]', RESEED, 0);
END
GO

IF OBJECT_ID('BCA.IdentificationCard', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[IdentificationCard];
    DBCC CHECKIDENT ('[BCA].[IdentificationCard]', RESEED, 0);
END
GO

-- Clear Citizen table (needs special handling for self-references)
IF OBJECT_ID('BCA.Citizen', 'U') IS NOT NULL
BEGIN
    -- First reset any self-references
    UPDATE [BCA].[Citizen]
    SET [father_citizen_id] = NULL,
        [mother_citizen_id] = NULL,
        [spouse_citizen_id] = NULL,
        [representative_citizen_id] = NULL;
    
    -- Then delete all records
    DELETE FROM [BCA].[Citizen];
END
GO

-- Clear Address table (after tables that reference it)
IF OBJECT_ID('BCA.Address', 'U') IS NOT NULL
BEGIN
    DELETE FROM [BCA].[Address];
    DBCC CHECKIDENT ('[BCA].[Address]', RESEED, 0);
END
GO

-- Clear Reference tables 
-- First, remove self-references
IF OBJECT_ID('Reference.PrisonFacilities', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[PrisonFacilities];
    DBCC CHECKIDENT ('[Reference].[PrisonFacilities]', RESEED, 0);
END
GO

IF OBJECT_ID('Reference.RelationshipTypes', 'U') IS NOT NULL
BEGIN
    -- First reset the self-reference
    UPDATE [Reference].[RelationshipTypes]
    SET [inverse_relationship_type_id] = NULL;
    -- Then delete all records
    DELETE FROM [Reference].[RelationshipTypes];
END
GO

IF OBJECT_ID('Reference.Authorities', 'U') IS NOT NULL
BEGIN
    -- First reset the self-reference 
    UPDATE [Reference].[Authorities]
    SET [parent_authority_id] = NULL;
    -- Then delete all records
    DELETE FROM [Reference].[Authorities];
END
GO

IF OBJECT_ID('Reference.Occupations', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Occupations];
END
GO

IF OBJECT_ID('Reference.Nationalities', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Nationalities];
END
GO

IF OBJECT_ID('Reference.Religions', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Religions];
END
GO

IF OBJECT_ID('Reference.Ethnicities', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Ethnicities];
END
GO

IF OBJECT_ID('Reference.Wards', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Wards];
END
GO

IF OBJECT_ID('Reference.Districts', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Districts];
END
GO

IF OBJECT_ID('Reference.Provinces', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Provinces];
END
GO

IF OBJECT_ID('Reference.Regions', 'U') IS NOT NULL
BEGIN
    DELETE FROM [Reference].[Regions];
END
GO

-- Re-enable all constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';
GO

PRINT 'All sample data has been cleared from DB_BCA database with all tables.';
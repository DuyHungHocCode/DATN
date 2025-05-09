-- Script to create constraints (Foreign Keys) for reference tables in DB_Reference
-- This script should be run on the SQL Server instance dedicated to DB_Reference,
-- after all reference tables in the 'Reference' schema have been created.

USE [DB_Reference];
GO

PRINT N'Creating constraints for tables in DB_Reference.Reference schema...';

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



PRINT N'Finished creating constraints for tables in DB_Reference.Reference schema.';
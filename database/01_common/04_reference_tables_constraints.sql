-- Add constraints for reference tables in DB_BCA
USE [DB_BCA];
GO

-- Constraints for Reference.Provinces
ALTER TABLE [Reference].[Provinces]
ADD CONSTRAINT FK_Province_Region FOREIGN KEY ([region_id]) REFERENCES [Reference].[Regions]([region_id]);
GO

-- Constraints for Reference.Districts
ALTER TABLE [Reference].[Districts]
ADD CONSTRAINT FK_District_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

-- Constraints for Reference.Wards
ALTER TABLE [Reference].[Wards]
ADD CONSTRAINT FK_Ward_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO

-- Constraints for Reference.Authorities
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_Ward FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_Parent FOREIGN KEY ([parent_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Constraints for Reference.RelationshipTypes
-- Note: SQL Server does not support DEFERRABLE constraints directly.
-- This FK implies insertion order matters or NULLs must be used initially.
ALTER TABLE [Reference].[RelationshipTypes]
ADD CONSTRAINT FK_Inverse_Relationship FOREIGN KEY ([inverse_relationship_type_id]) REFERENCES [Reference].[RelationshipTypes]([relationship_type_id]);
GO

-- Constraints for Reference.PrisonFacilities
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_Ward FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_Managing_Authority FOREIGN KEY ([managing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO


-- Add constraints for reference tables in DB_BTP
USE [DB_BTP];
GO

-- Constraints for Reference.Provinces
ALTER TABLE [Reference].[Provinces]
ADD CONSTRAINT FK_Province_Region FOREIGN KEY ([region_id]) REFERENCES [Reference].[Regions]([region_id]);
GO

-- Constraints for Reference.Districts
ALTER TABLE [Reference].[Districts]
ADD CONSTRAINT FK_District_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO

-- Constraints for Reference.Wards
ALTER TABLE [Reference].[Wards]
ADD CONSTRAINT FK_Ward_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO

-- Constraints for Reference.Authorities
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_Ward FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [Reference].[Authorities]
ADD CONSTRAINT FK_Authority_Parent FOREIGN KEY ([parent_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO

-- Constraints for Reference.RelationshipTypes
ALTER TABLE [Reference].[RelationshipTypes]
ADD CONSTRAINT FK_Inverse_Relationship FOREIGN KEY ([inverse_relationship_type_id]) REFERENCES [Reference].[RelationshipTypes]([relationship_type_id]);
GO

-- Constraints for Reference.PrisonFacilities
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_Ward FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [Reference].[PrisonFacilities]
ADD CONSTRAINT FK_Prison_Managing_Authority FOREIGN KEY ([managing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO


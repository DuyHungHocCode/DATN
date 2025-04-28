USE [DB_BCA];
GO

-- Constraints for BCA.Citizen
-- Foreign Keys to Reference schema
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthWard FOREIGN KEY ([birth_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthDistrict FOREIGN KEY ([birth_district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthProvince FOREIGN KEY ([birth_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_BirthCountry FOREIGN KEY ([birth_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeWard FOREIGN KEY ([native_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeDistrict FOREIGN KEY ([native_district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_NativeProvince FOREIGN KEY ([native_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Nationality FOREIGN KEY ([nationality_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Ethnicity FOREIGN KEY ([ethnicity_id]) REFERENCES [Reference].[Ethnicities]([ethnicity_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Religion FOREIGN KEY ([religion_id]) REFERENCES [Reference].[Religions]([religion_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_Occupation FOREIGN KEY ([occupation_id]) REFERENCES [Reference].[Occupations]([occupation_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentWard FOREIGN KEY ([current_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentDistrict FOREIGN KEY ([current_district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT FK_Citizen_CurrentProvince FOREIGN KEY ([current_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
-- Foreign Keys to Citizen table itself (Self-referencing - Use NOCHECK to avoid issues during bulk inserts if needed, but generally enforce)
-- ALTER TABLE [BCA].[Citizen] WITH CHECK ADD CONSTRAINT FK_Citizen_Father FOREIGN KEY ([father_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO
-- ALTER TABLE [BCA].[Citizen] WITH CHECK ADD CONSTRAINT FK_Citizen_Mother FOREIGN KEY ([mother_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO
-- ALTER TABLE [BCA].[Citizen] WITH CHECK ADD CONSTRAINT FK_Citizen_Spouse FOREIGN KEY ([spouse_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO
-- ALTER TABLE [BCA].[Citizen] WITH CHECK ADD CONSTRAINT FK_Citizen_Representative FOREIGN KEY ([representative_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO

-- CHECK Constraints for BCA.Citizen
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_BirthDate CHECK ([date_of_birth] < GETDATE());
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_DeathDate CHECK (([death_status] = N'Đã mất' AND [date_of_death] IS NOT NULL AND [date_of_death] <= GETDATE()) OR ([death_status] <> N'Đã mất'));
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_Parents CHECK ([citizen_id] <> [father_citizen_id] AND [citizen_id] <> [mother_citizen_id]);
GO
ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT CK_Citizen_EmailFormat CHECK ([email] IS NULL OR [email] LIKE '%_@__%.__%');
GO


-- Constraints for BCA.Address
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Ward FOREIGN KEY ([ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_District FOREIGN KEY ([district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT FK_Address_Province FOREIGN KEY ([province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [BCA].[Address] ADD CONSTRAINT CK_Address_LatLon CHECK (([latitude] IS NULL AND [longitude] IS NULL) OR ([latitude] BETWEEN -90 AND 90 AND [longitude] BETWEEN -180 AND 180));
GO


-- Constraints for BCA.IdentificationCard
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT FK_IdentificationCard_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT CK_IdentificationCard_Dates CHECK ([issue_date] <= GETDATE() AND ([expiry_date] IS NULL OR [expiry_date] > [issue_date]));
GO
-- Add Unique constraint for card_number if it should be unique across the system
-- ALTER TABLE [BCA].[IdentificationCard] ADD CONSTRAINT UQ_IdentificationCard_Number UNIQUE ([card_number]);
-- GO


-- Constraints for BCA.ResidenceHistory
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_PreviousAddress FOREIGN KEY ([previous_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT FK_ResidenceHistory_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT CK_ResidenceHistory_Dates CHECK ([registration_date] <= GETDATE() AND ([expiry_date] IS NULL OR [expiry_date] >= [registration_date]));
GO


-- Constraints for BCA.CriminalRecord
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT CK_CriminalRecord_Dates CHECK (([crime_date] IS NULL OR [crime_date] <= GETDATE()) AND ([judgment_date] IS NULL OR [judgment_date] <= GETDATE()) AND ([sentence_start_date] IS NULL OR [sentence_start_date] <= GETDATE()) AND ([sentence_end_date] IS NULL OR [sentence_end_date] >= [sentence_start_date]));
GO
-- Add Unique constraint for judgment_no if it should be unique
-- ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT UQ_CriminalRecord_JudgmentNo UNIQUE ([judgment_no]);
-- GO


-- Constraints for BCA.CitizenStatus
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT FK_CitizenStatus_Authority FOREIGN KEY ([authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_Date CHECK ([status_date] <= GETDATE());
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_DocumentDate CHECK ([document_date] IS NULL OR [document_date] <= GETDATE());
GO
ALTER TABLE [BCA].[CitizenStatus] ADD CONSTRAINT CK_CitizenStatus_CauseLocationRequired CHECK (([status_type] IN (N'Đã mất', N'Mất tích') AND [cause] IS NOT NULL AND [location] IS NOT NULL) OR ([status_type] = N'Còn sống'));
GO


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
-- Consider enabling these based on data loading strategy
-- ALTER TABLE [BCA].[Citizen] WITH NOCHECK ADD CONSTRAINT FK_Citizen_Father FOREIGN KEY ([father_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO
-- ALTER TABLE [BCA].[Citizen] NOCHECK CONSTRAINT FK_Citizen_Father; -- Disable check initially if needed
-- GO
-- ALTER TABLE [BCA].[Citizen] WITH NOCHECK ADD CONSTRAINT FK_Citizen_Mother FOREIGN KEY ([mother_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO
-- ALTER TABLE [BCA].[Citizen] NOCHECK CONSTRAINT FK_Citizen_Mother;
-- GO
-- ALTER TABLE [BCA].[Citizen] WITH NOCHECK ADD CONSTRAINT FK_Citizen_Spouse FOREIGN KEY ([spouse_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO
-- ALTER TABLE [BCA].[Citizen] NOCHECK CONSTRAINT FK_Citizen_Spouse;
-- GO
-- ALTER TABLE [BCA].[Citizen] WITH NOCHECK ADD CONSTRAINT FK_Citizen_Representative FOREIGN KEY ([representative_citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
-- GO
-- ALTER TABLE [BCA].[Citizen] NOCHECK CONSTRAINT FK_Citizen_Representative;
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
-- Add UNIQUE constraints if needed and manageable (consider application level check)
-- ALTER TABLE [BCA].[Citizen] ADD CONSTRAINT UQ_Citizen_TaxCode UNIQUE ([tax_code]) WHERE [tax_code] IS NOT NULL; -- Filtered unique constraint syntax varies
-- GO


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
ALTER TABLE [BCA].[ResidenceHistory] ADD CONSTRAINT CK_ResidenceHistory_Dates CHECK ([registration_date] <= GETDATE() AND ([expiry_date] IS NULL OR [expiry_date] >= [registration_date]) AND ([last_extension_date] IS NULL OR ([last_extension_date] >= [registration_date] AND [last_extension_date] <= GETDATE())) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO


-- Constraints for BCA.TemporaryAbsence
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_DestAddress FOREIGN KEY ([destination_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT FK_TemporaryAbsence_Authority FOREIGN KEY ([registration_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BCA].[TemporaryAbsence] ADD CONSTRAINT CK_TemporaryAbsence_Dates CHECK ([from_date] <= GETDATE() AND ([to_date] IS NULL OR [to_date] >= [from_date]) AND ([return_date] IS NULL OR [return_date] >= [from_date]) AND ([return_confirmed_date] IS NULL OR ([return_confirmed_date] >= [from_date] AND [return_confirmed_date] <= GETDATE())) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO


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


-- Constraints for BCA.CitizenMovement
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_FromAddr FOREIGN KEY ([from_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_ToAddr FOREIGN KEY ([to_address_id]) REFERENCES [BCA].[Address]([address_id]);
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_FromCtry FOREIGN KEY ([from_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT FK_CitizenMovement_ToCtry FOREIGN KEY ([to_country_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT CK_CitizenMovement_Dates CHECK ([departure_date] <= GETDATE() AND ([arrival_date] IS NULL OR [arrival_date] >= [departure_date]) AND ([document_issue_date] IS NULL OR [document_issue_date] <= [departure_date]) AND ([document_expiry_date] IS NULL OR [document_expiry_date] >= [document_issue_date]));
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT CK_CitizenMovement_International CHECK (([movement_type] IN (N'Xuất cảnh', N'Tái nhập cảnh') AND [to_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type] = N'Nhập cảnh' AND [from_country_id] IS NOT NULL AND [border_checkpoint] IS NOT NULL) OR ([movement_type] = N'Trong nước'));
GO
ALTER TABLE [BCA].[CitizenMovement] ADD CONSTRAINT CK_CitizenMovement_AddressCountry CHECK ( NOT ([movement_type] = N'Xuất cảnh' AND [from_address_id] IS NOT NULL) AND NOT ([movement_type] = N'Nhập cảnh' AND [to_address_id] IS NOT NULL) );
GO


-- Constraints for BCA.CriminalRecord
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT FK_CriminalRecord_Prison FOREIGN KEY ([prison_facility_id]) REFERENCES [Reference].[PrisonFacilities]([prison_facility_id]);
GO
ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT CK_CriminalRecord_Dates CHECK (([crime_date] IS NULL OR [crime_date] <= GETDATE()) AND ([judgment_date] IS NULL OR [judgment_date] <= GETDATE()) AND ([sentence_start_date] IS NULL OR [sentence_start_date] <= GETDATE()) AND ([sentence_end_date] IS NULL OR [sentence_end_date] >= [sentence_start_date]));
GO
-- Add Unique constraint for judgment_no if it should be unique
-- ALTER TABLE [BCA].[CriminalRecord] ADD CONSTRAINT UQ_CriminalRecord_JudgmentNo UNIQUE ([judgment_no]);
-- GO


-- Constraints for BCA.CitizenAddress
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Citizen FOREIGN KEY ([citizen_id]) REFERENCES [BCA].[Citizen]([citizen_id]);
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT FK_CitizenAddress_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BCA].[CitizenAddress] ADD CONSTRAINT CK_CitizenAddress_Dates CHECK ([from_date] <= GETDATE() AND ([to_date] IS NULL OR [to_date] >= [from_date]) AND ([registration_date] IS NULL OR [registration_date] <= GETDATE()) AND ([verification_date] IS NULL OR [verification_date] <= GETDATE()));
GO
-- Add logic for UNIQUE constraint on (citizen_id, address_type) WHERE is_primary = 1 and status = 1 using filtered index or trigger if needed
-- CREATE UNIQUE NONCLUSTERED INDEX UQ_CitizenAddress_Primary ON BCA.CitizenAddress(citizen_id, address_type) WHERE is_primary = 1 AND status = 1; -- Example syntax
-- GO


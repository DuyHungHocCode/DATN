USE [DB_BTP];
GO

-- Constraints for BTP.BirthCertificate
ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT FK_BirthCertificate_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT FK_BirthCertificate_FatherNationality FOREIGN KEY ([father_nationality_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT FK_BirthCertificate_MotherNationality FOREIGN KEY ([mother_nationality_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT CK_BirthCertificate_Dates CHECK ([date_of_birth] < GETDATE() AND [registration_date] >= [date_of_birth] AND [registration_date] <= GETDATE());
GO
-- Consider adding UNIQUE constraints at application/API level for better concurrency control
-- ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT UQ_BirthCertificate_No UNIQUE ([birth_certificate_no]);
-- GO
-- ALTER TABLE [BTP].[BirthCertificate] ADD CONSTRAINT UQ_BirthCertificate_CitizenId UNIQUE ([citizen_id]);
-- GO


-- Constraints for BTP.DeathCertificate
ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_PlaceWard FOREIGN KEY ([place_of_death_ward_id]) REFERENCES [Reference].[Wards]([ward_id]);
GO
--Add FKs for district/province if these columns are populated and needed
ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_PlaceDistrict FOREIGN KEY ([place_of_death_district_id]) REFERENCES [Reference].[Districts]([district_id]);
GO
ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT FK_DeathCertificate_PlaceProvince FOREIGN KEY ([place_of_death_province_id]) REFERENCES [Reference].[Provinces]([province_id]);
GO
ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT CK_DeathCertificate_Dates CHECK ([date_of_death] <= GETDATE() AND [registration_date] >= [date_of_death] AND [registration_date] <= GETDATE());
GO
-- Consider adding UNIQUE constraints at application/API level
-- ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT UQ_DeathCertificate_No UNIQUE ([death_certificate_no]);
-- GO
-- ALTER TABLE [BTP].[DeathCertificate] ADD CONSTRAINT UQ_DeathCertificate_CitizenId UNIQUE ([citizen_id]);
-- GO


-- Constraints for BTP.MarriageCertificate
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_HusbandNationality FOREIGN KEY ([husband_nationality_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_WifeNationality FOREIGN KEY ([wife_nationality_id]) REFERENCES [Reference].[Nationalities]([nationality_id]);
GO
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT FK_MarriageCertificate_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT CK_MarriageCertificate_Dates CHECK ([marriage_date] <= GETDATE() AND [registration_date] >= [marriage_date] AND [registration_date] <= GETDATE());
GO
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT CK_MarriageCertificate_Ages CHECK (DATEDIFF(year, [husband_date_of_birth], [marriage_date]) >= 20 AND DATEDIFF(year, [wife_date_of_birth], [marriage_date]) >= 18); -- Check age based on marriage date
GO
ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT CK_MarriageCertificate_DifferentPeople CHECK ([husband_id] <> [wife_id]);
GO
-- Consider adding UNIQUE constraints at application/API level
-- ALTER TABLE [BTP].[MarriageCertificate] ADD CONSTRAINT UQ_MarriageCertificate_No UNIQUE ([marriage_certificate_no]);
-- GO


-- Constraints for BTP.DivorceRecord
ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT FK_DivorceRecord_MarriageCertificate FOREIGN KEY ([marriage_certificate_id]) REFERENCES [BTP].[MarriageCertificate]([marriage_certificate_id]);
GO
ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT FK_DivorceRecord_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT CK_DivorceRecord_Dates CHECK ([divorce_date] <= GETDATE() AND [registration_date] <= GETDATE() AND [judgment_date] <= [registration_date] AND [divorce_date] <= [registration_date] AND [judgment_date] <= [divorce_date]);
GO
-- Consider adding UNIQUE constraints at application/API level
-- ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT UQ_DivorceRecord_JudgmentNo UNIQUE ([judgment_no]);
-- GO
-- ALTER TABLE [BTP].[DivorceRecord] ADD CONSTRAINT UQ_DivorceRecord_MarriageId UNIQUE ([marriage_certificate_id]); -- A marriage can only be divorced once
-- GO


-- Constraints for BTP.Household
ALTER TABLE [BTP].[Household] ADD CONSTRAINT FK_Household_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
-- Cannot add FK to BCA.Address directly, handle via API Service
-- ALTER TABLE [BTP].[Household] ADD CONSTRAINT FK_Household_Address FOREIGN KEY ([address_id]) REFERENCES [BCA].[Address]([address_id]);
-- GO
ALTER TABLE [BTP].[Household] ADD CONSTRAINT CK_Household_RegistrationDate CHECK ([registration_date] <= GETDATE());
GO
-- Consider adding UNIQUE constraints at application/API level
-- ALTER TABLE [BTP].[Household] ADD CONSTRAINT UQ_Household_BookNo UNIQUE ([household_book_no]);
-- GO


-- Constraints for BTP.HouseholdMember
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT FK_HouseholdMember_Household FOREIGN KEY ([household_id]) REFERENCES [BTP].[Household]([household_id]);
GO
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT FK_HouseholdMember_PreviousHousehold FOREIGN KEY ([previous_household_id]) REFERENCES [BTP].[Household]([household_id]);
GO
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT CK_HouseholdMember_Dates CHECK ([join_date] <= GETDATE() AND ([leave_date] IS NULL OR [leave_date] >= [join_date]));
GO
ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT CK_HouseholdMember_Order CHECK ([order_in_household] IS NULL OR [order_in_household] > 0);
GO
-- Consider adding UNIQUE constraints at application/API level (e.g., citizen_id active in only one household)
-- ALTER TABLE [BTP].[HouseholdMember] ADD CONSTRAINT UQ_HouseholdMember_Active UNIQUE ([citizen_id]) WHERE [status] = 'Active'; -- SQL Server doesn't support filtered unique constraints directly like this, needs indexed view or trigger
-- GO


-- Constraints for BTP.FamilyRelationship
ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT FK_FamilyRelationship_Authority FOREIGN KEY ([issuing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT CK_FamilyRelationship_Dates CHECK ([start_date] <= GETDATE() AND ([end_date] IS NULL OR [end_date] >= [start_date]));
GO
ALTER TABLE [BTP].[FamilyRelationship] ADD CONSTRAINT CK_FamilyRelationship_DifferentPeople CHECK ([citizen_id] <> [related_citizen_id]);
GO


-- Constraints for BTP.PopulationChange
ALTER TABLE [BTP].[PopulationChange] ADD CONSTRAINT FK_PopulationChange_Authority FOREIGN KEY ([processing_authority_id]) REFERENCES [Reference].[Authorities]([authority_id]);
GO
-- Cannot add FK to Reference.Wards for source/destination directly as they are logical links
-- ALTER TABLE [BTP].[PopulationChange] ADD CONSTRAINT FK_PopulationChange_SourceLocation FOREIGN KEY ([source_location_id]) REFERENCES [Reference].[Wards]([ward_id]);
-- GO
-- ALTER TABLE [BTP].[PopulationChange] ADD CONSTRAINT FK_PopulationChange_DestinationLocation FOREIGN KEY ([destination_location_id]) REFERENCES [Reference].[Wards]([ward_id]);
-- GO
ALTER TABLE [BTP].[PopulationChange] ADD CONSTRAINT CK_PopulationChange_Date CHECK ([change_date] <= GETDATE());
GO


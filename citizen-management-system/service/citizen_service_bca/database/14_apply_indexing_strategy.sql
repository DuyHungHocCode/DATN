
USE [DB_BCA];
GO

PRINT N'Applying optimized indexing strategy...';
GO

--------------------------------------------------------------------------------
-- 1. Indexes for BCA.Citizen Table (Central Table)
-- Description: Optimizes joins in GetCitizenDetails and family lookups.
--------------------------------------------------------------------------------
PRINT N'  Creating indexes on BCA.Citizen...';

-- Indexes for foreign keys to speed up JOINs in GetCitizenDetails and other queries.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Citizen_GenderId' AND object_id = OBJECT_ID('BCA.Citizen'))
CREATE NONCLUSTERED INDEX IX_Citizen_GenderId ON [BCA].[Citizen](gender_id);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Citizen_NationalityId' AND object_id = OBJECT_ID('BCA.Citizen'))
CREATE NONCLUSTERED INDEX IX_Citizen_NationalityId ON [BCA].[Citizen](nationality_id);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Citizen_MaritalStatusId' AND object_id = OBJECT_ID('BCA.Citizen'))
CREATE NONCLUSTERED INDEX IX_Citizen_MaritalStatusId ON [BCA].[Citizen](marital_status_id);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Citizen_CitizenStatusId' AND object_id = OBJECT_ID('BCA.Citizen'))
CREATE NONCLUSTERED INDEX IX_Citizen_CitizenStatusId ON [BCA].[Citizen](citizen_status_id);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Citizen_PrimaryAddressId' AND object_id = OBJECT_ID('BCA.Citizen'))
CREATE NONCLUSTERED INDEX IX_Citizen_PrimaryAddressId ON [BCA].[Citizen](primary_address_id);

-- Index for family tree lookups (optimizes GetCitizenFamilyTree)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Citizen_FamilyLinks' AND object_id = OBJECT_ID('BCA.Citizen'))
CREATE NONCLUSTERED INDEX IX_Citizen_FamilyLinks ON [BCA].[Citizen] (father_citizen_id, mother_citizen_id);

-- Index for basic search (optimizes SearchCitizens)
-- NOTE: For full_name LIKE '%...%', Full-Text Search is the recommended solution for performance.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Citizen_Search_DobName' AND object_id = OBJECT_ID('BCA.Citizen'))
CREATE NONCLUSTERED INDEX IX_Citizen_Search_DobName ON [BCA].[Citizen] (date_of_birth, full_name);

GO

--------------------------------------------------------------------------------
-- 2. Indexes for BCA.IdentificationCard Table
-- Description: Optimizes lookups for a citizen's cards and finding the latest card.
--------------------------------------------------------------------------------
PRINT N'  Creating indexes on BCA.IdentificationCard...';

-- Covering index to optimize fetching the latest card (used in GetCitizenFamilyTree)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_IdentificationCard_Citizen_Latest' AND object_id = OBJECT_ID('BCA.IdentificationCard'))
CREATE NONCLUSTERED INDEX IX_IdentificationCard_Citizen_Latest
ON [BCA].[IdentificationCard] (citizen_id, issue_date DESC)
INCLUDE (card_number, card_type_id, expiry_date, issuing_authority_id, card_status_id);

-- Unique index to enforce and speed up lookups by card number.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_IdentificationCard_CardNumber' AND object_id = OBJECT_ID('BCA.IdentificationCard'))
CREATE UNIQUE NONCLUSTERED INDEX IX_IdentificationCard_CardNumber ON [BCA].[IdentificationCard] (card_number);

GO

--------------------------------------------------------------------------------
-- 3. Indexes for History and Relationship Tables
-- Description: Speeds up finding records related to a specific citizen or household.
--------------------------------------------------------------------------------
PRINT N'  Creating indexes on history and relationship tables...';

-- For BCA.ResidenceHistory (optimizes GetResidenceHistory)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ResidenceHistory_CitizenId' AND object_id = OBJECT_ID('BCA.ResidenceHistory'))
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_CitizenId ON [BCA].[ResidenceHistory](citizen_id);

-- For BCA.Household (optimizes joins to find head of household info)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Household_HeadOfHouseholdId' AND object_id = OBJECT_ID('BCA.Household'))
CREATE NONCLUSTERED INDEX IX_Household_HeadOfHouseholdId ON [BCA].[Household](head_of_household_id);

-- For BCA.HouseholdMember (optimizes GetHouseholdDetails and general lookups)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_HouseholdMember_HouseholdLookup' AND object_id = OBJECT_ID('BCA.HouseholdMember'))
CREATE NONCLUSTERED INDEX IX_HouseholdMember_HouseholdLookup ON [BCA].[HouseholdMember](household_id, order_in_household, join_date);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_HouseholdMember_CitizenId' AND object_id = OBJECT_ID('BCA.HouseholdMember'))
CREATE NONCLUSTERED INDEX IX_HouseholdMember_CitizenId ON [BCA].[HouseholdMember](citizen_id);

-- For BCA.CriminalRecord
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CriminalRecord_CitizenId' AND object_id = OBJECT_ID('BCA.CriminalRecord'))
CREATE NONCLUSTERED INDEX IX_CriminalRecord_CitizenId ON [BCA].[CriminalRecord](citizen_id);

GO

--------------------------------------------------------------------------------
-- 4. Indexes for BCA.Address Table
-- Description: Optimizes the address lookup in residence registration procedures.
--------------------------------------------------------------------------------
PRINT N'  Creating indexes on BCA.Address...';

-- Index to optimize address lookups by geographic IDs before comparing the full address string.
-- (Optimizes RegisterPermanentResidence_OwnedProperty_DataOnly)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Address_GeographicLookup' AND object_id = OBJECT_ID('BCA.Address'))
CREATE NONCLUSTERED INDEX IX_Address_GeographicLookup
ON [BCA].[Address] (province_id, district_id, ward_id)
INCLUDE (address_detail);

GO



PRINT N'Indexing strategy applied successfully.';
GO 
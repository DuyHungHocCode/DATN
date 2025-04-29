-- Create reference tables for DB_BCA
USE [DB_BCA];
GO

-- Table: Reference.Regions
IF OBJECT_ID('Reference.Regions', 'U') IS NOT NULL DROP TABLE [Reference].[Regions];
GO
CREATE TABLE [Reference].[Regions] (
    [region_id] SMALLINT PRIMARY KEY,
    [region_code] VARCHAR(10) NOT NULL UNIQUE,
    [region_name] NVARCHAR(50) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Provinces
IF OBJECT_ID('Reference.Provinces', 'U') IS NOT NULL DROP TABLE [Reference].[Provinces];
GO
CREATE TABLE [Reference].[Provinces] (
    [province_id] INT PRIMARY KEY,
    [province_code] VARCHAR(10) NOT NULL UNIQUE,
    [province_name] NVARCHAR(100) NOT NULL,
    [region_id] SMALLINT NOT NULL, -- FK added later
    [administrative_unit_id] SMALLINT NULL,
    [administrative_region_id] SMALLINT NULL,
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL,
    [is_city] BIT DEFAULT 0,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Districts
IF OBJECT_ID('Reference.Districts', 'U') IS NOT NULL DROP TABLE [Reference].[Districts];
GO
CREATE TABLE [Reference].[Districts] (
    [district_id] INT PRIMARY KEY,
    [district_code] VARCHAR(10) NOT NULL UNIQUE,
    [district_name] NVARCHAR(100) NOT NULL,
    [province_id] INT NOT NULL, -- FK added later
    [administrative_unit_id] SMALLINT NULL,
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL,
    [is_urban] BIT DEFAULT 0,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Wards
IF OBJECT_ID('Reference.Wards', 'U') IS NOT NULL DROP TABLE [Reference].[Wards];
GO
CREATE TABLE [Reference].[Wards] (
    [ward_id] INT PRIMARY KEY,
    [ward_code] VARCHAR(10) NOT NULL UNIQUE,
    [ward_name] NVARCHAR(100) NOT NULL,
    [district_id] INT NOT NULL, -- FK added later
    [administrative_unit_id] SMALLINT NULL,
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL,
    [is_urban] BIT DEFAULT 0,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Ethnicities
IF OBJECT_ID('Reference.Ethnicities', 'U') IS NOT NULL DROP TABLE [Reference].[Ethnicities];
GO
CREATE TABLE [Reference].[Ethnicities] (
    [ethnicity_id] SMALLINT PRIMARY KEY,
    [ethnicity_code] VARCHAR(10) NOT NULL UNIQUE,
    [ethnicity_name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [population] INT NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Religions
IF OBJECT_ID('Reference.Religions', 'U') IS NOT NULL DROP TABLE [Reference].[Religions];
GO
CREATE TABLE [Reference].[Religions] (
    [religion_id] SMALLINT PRIMARY KEY,
    [religion_code] VARCHAR(10) NOT NULL UNIQUE,
    [religion_name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [followers] INT NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Nationalities
IF OBJECT_ID('Reference.Nationalities', 'U') IS NOT NULL DROP TABLE [Reference].[Nationalities];
GO
CREATE TABLE [Reference].[Nationalities] (
    [nationality_id] SMALLINT PRIMARY KEY,
    [nationality_code] VARCHAR(10) NOT NULL UNIQUE,
    [iso_code_alpha2] VARCHAR(2) UNIQUE,
    [iso_code_alpha3] VARCHAR(3) UNIQUE,
    [nationality_name] NVARCHAR(100) NOT NULL,
    [country_name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Occupations
IF OBJECT_ID('Reference.Occupations', 'U') IS NOT NULL DROP TABLE [Reference].[Occupations];
GO
CREATE TABLE [Reference].[Occupations] (
    [occupation_id] INT PRIMARY KEY,
    [occupation_code] VARCHAR(20) NOT NULL UNIQUE,
    [occupation_name] NVARCHAR(255) NOT NULL,
    [occupation_group_id] INT NULL, -- FK added later if needed
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Authorities
IF OBJECT_ID('Reference.Authorities', 'U') IS NOT NULL DROP TABLE [Reference].[Authorities];
GO
CREATE TABLE [Reference].[Authorities] (
    [authority_id] INT PRIMARY KEY,
    [authority_code] VARCHAR(30) NOT NULL UNIQUE,
    [authority_name] NVARCHAR(255) NOT NULL,
    [authority_type] NVARCHAR(100) NOT NULL,
    [address_detail] NVARCHAR(MAX) NULL,
    [ward_id] INT NULL, -- FK added later
    [district_id] INT NULL, -- FK added later
    [province_id] INT NULL, -- FK added later
    [phone] VARCHAR(50) NULL,
    [email] VARCHAR(100) NULL,
    [website] VARCHAR(255) NULL,
    [parent_authority_id] INT NULL, -- FK added later
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.RelationshipTypes
IF OBJECT_ID('Reference.RelationshipTypes', 'U') IS NOT NULL DROP TABLE [Reference].[RelationshipTypes];
GO
CREATE TABLE [Reference].[RelationshipTypes] (
    [relationship_type_id] SMALLINT PRIMARY KEY,
    [relationship_code] VARCHAR(20) NOT NULL UNIQUE,
    [relationship_name] NVARCHAR(100) NOT NULL,
    [inverse_relationship_type_id] SMALLINT NULL, -- FK added later
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.PrisonFacilities
IF OBJECT_ID('Reference.PrisonFacilities', 'U') IS NOT NULL DROP TABLE [Reference].[PrisonFacilities];
GO
CREATE TABLE [Reference].[PrisonFacilities] (
    [prison_facility_id] INT IDENTITY(1,1) PRIMARY KEY,
    [facility_code] VARCHAR(30) UNIQUE,
    [facility_name] NVARCHAR(255) NOT NULL,
    [facility_type] NVARCHAR(100) NULL,
    [address_detail] NVARCHAR(MAX) NULL,
    [ward_id] INT NULL, -- FK added later
    [district_id] INT NULL, -- FK added later
    [province_id] INT NOT NULL, -- FK added later
    [capacity] INT NULL,
    [managing_authority_id] INT NULL, -- FK added later
    [phone_number] VARCHAR(50) NULL,
    [is_active] BIT DEFAULT 1,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Create reference tables for DB_BTP
USE [DB_BTP];
GO

-- Table: Reference.Regions
IF OBJECT_ID('Reference.Regions', 'U') IS NOT NULL DROP TABLE [Reference].[Regions];
GO
CREATE TABLE [Reference].[Regions] (
    [region_id] SMALLINT PRIMARY KEY,
    [region_code] VARCHAR(10) NOT NULL UNIQUE,
    [region_name] NVARCHAR(50) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Provinces
IF OBJECT_ID('Reference.Provinces', 'U') IS NOT NULL DROP TABLE [Reference].[Provinces];
GO
CREATE TABLE [Reference].[Provinces] (
    [province_id] INT PRIMARY KEY,
    [province_code] VARCHAR(10) NOT NULL UNIQUE,
    [province_name] NVARCHAR(100) NOT NULL,
    [region_id] SMALLINT NOT NULL, -- FK added later
    [administrative_unit_id] SMALLINT NULL,
    [administrative_region_id] SMALLINT NULL,
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL,
    [is_city] BIT DEFAULT 0,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Districts
IF OBJECT_ID('Reference.Districts', 'U') IS NOT NULL DROP TABLE [Reference].[Districts];
GO
CREATE TABLE [Reference].[Districts] (
    [district_id] INT PRIMARY KEY,
    [district_code] VARCHAR(10) NOT NULL UNIQUE,
    [district_name] NVARCHAR(100) NOT NULL,
    [province_id] INT NOT NULL, -- FK added later
    [administrative_unit_id] SMALLINT NULL,
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL,
    [is_urban] BIT DEFAULT 0,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Wards
IF OBJECT_ID('Reference.Wards', 'U') IS NOT NULL DROP TABLE [Reference].[Wards];
GO
CREATE TABLE [Reference].[Wards] (
    [ward_id] INT PRIMARY KEY,
    [ward_code] VARCHAR(10) NOT NULL UNIQUE,
    [ward_name] NVARCHAR(100) NOT NULL,
    [district_id] INT NOT NULL, -- FK added later
    [administrative_unit_id] SMALLINT NULL,
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL,
    [is_urban] BIT DEFAULT 0,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Ethnicities
IF OBJECT_ID('Reference.Ethnicities', 'U') IS NOT NULL DROP TABLE [Reference].[Ethnicities];
GO
CREATE TABLE [Reference].[Ethnicities] (
    [ethnicity_id] SMALLINT PRIMARY KEY,
    [ethnicity_code] VARCHAR(10) NOT NULL UNIQUE,
    [ethnicity_name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [population] INT NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Religions
IF OBJECT_ID('Reference.Religions', 'U') IS NOT NULL DROP TABLE [Reference].[Religions];
GO
CREATE TABLE [Reference].[Religions] (
    [religion_id] SMALLINT PRIMARY KEY,
    [religion_code] VARCHAR(10) NOT NULL UNIQUE,
    [religion_name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [followers] INT NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Nationalities
IF OBJECT_ID('Reference.Nationalities', 'U') IS NOT NULL DROP TABLE [Reference].[Nationalities];
GO
CREATE TABLE [Reference].[Nationalities] (
    [nationality_id] SMALLINT PRIMARY KEY,
    [nationality_code] VARCHAR(10) NOT NULL UNIQUE,
    [iso_code_alpha2] VARCHAR(2) UNIQUE,
    [iso_code_alpha3] VARCHAR(3) UNIQUE,
    [nationality_name] NVARCHAR(100) NOT NULL,
    [country_name] NVARCHAR(100) NOT NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Occupations
IF OBJECT_ID('Reference.Occupations', 'U') IS NOT NULL DROP TABLE [Reference].[Occupations];
GO
CREATE TABLE [Reference].[Occupations] (
    [occupation_id] INT PRIMARY KEY,
    [occupation_code] VARCHAR(20) NOT NULL UNIQUE,
    [occupation_name] NVARCHAR(255) NOT NULL,
    [occupation_group_id] INT NULL, -- FK added later if needed
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.Authorities
IF OBJECT_ID('Reference.Authorities', 'U') IS NOT NULL DROP TABLE [Reference].[Authorities];
GO
CREATE TABLE [Reference].[Authorities] (
    [authority_id] INT PRIMARY KEY,
    [authority_code] VARCHAR(30) NOT NULL UNIQUE,
    [authority_name] NVARCHAR(255) NOT NULL,
    [authority_type] NVARCHAR(100) NOT NULL,
    [address_detail] NVARCHAR(MAX) NULL,
    [ward_id] INT NULL, -- FK added later
    [district_id] INT NULL, -- FK added later
    [province_id] INT NULL, -- FK added later
    [phone] VARCHAR(50) NULL,
    [email] VARCHAR(100) NULL,
    [website] VARCHAR(255) NULL,
    [parent_authority_id] INT NULL, -- FK added later
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.RelationshipTypes
IF OBJECT_ID('Reference.RelationshipTypes', 'U') IS NOT NULL DROP TABLE [Reference].[RelationshipTypes];
GO
CREATE TABLE [Reference].[RelationshipTypes] (
    [relationship_type_id] SMALLINT PRIMARY KEY,
    [relationship_code] VARCHAR(20) NOT NULL UNIQUE,
    [relationship_name] NVARCHAR(100) NOT NULL,
    [inverse_relationship_type_id] SMALLINT NULL, -- FK added later
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Table: Reference.PrisonFacilities
IF OBJECT_ID('Reference.PrisonFacilities', 'U') IS NOT NULL DROP TABLE [Reference].[PrisonFacilities];
GO
CREATE TABLE [Reference].[PrisonFacilities] (
    [prison_facility_id] INT IDENTITY(1,1) PRIMARY KEY,
    [facility_code] VARCHAR(30) UNIQUE,
    [facility_name] NVARCHAR(255) NOT NULL,
    [facility_type] NVARCHAR(100) NULL,
    [address_detail] NVARCHAR(MAX) NULL,
    [ward_id] INT NULL, -- FK added later
    [district_id] INT NULL, -- FK added later
    [province_id] INT NOT NULL, -- FK added later
    [capacity] INT NULL,
    [managing_authority_id] INT NULL, -- FK added later
    [phone_number] VARCHAR(50) NULL,
    [is_active] BIT DEFAULT 1,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

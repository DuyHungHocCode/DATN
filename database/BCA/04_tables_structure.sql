-- Script to create table structures for database DB_BCA (Bộ Công an)
-- This script contains improved table structures based on review
-- Improvements: Removed redundancy, clarified relationships, added missing reference tables

USE [DB_BCA];
GO

PRINT N'Creating improved table structures in DB_BCA...';

--------------------------------------------------------------------------------
-- Schema: BCA (Core tables)
--------------------------------------------------------------------------------
PRINT N'Creating tables in schema [BCA]...';

-- Table: BCA.Citizen (Cải tiến: loại bỏ thông tin địa chỉ trùng lặp)
IF OBJECT_ID('BCA.Citizen', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[Citizen] exists. Dropping it...';
    DROP TABLE [BCA].[Citizen];
    PRINT N'  Table [BCA].[Citizen] dropped.';
END
GO
PRINT N'  Creating table [BCA].[Citizen]...';
CREATE TABLE [BCA].[Citizen] (
    [citizen_id] VARCHAR(12) PRIMARY KEY,
    [full_name] NVARCHAR(100) NOT NULL,
    [date_of_birth] DATE NOT NULL,
    [gender_id] SMALLINT NOT NULL, -- FK to Reference.Genders
    [birth_ward_id] INT NULL, -- FK to Reference.Wards
    [birth_district_id] INT NULL, -- FK to Reference.Districts
    [birth_province_id] INT NULL, -- FK to Reference.Provinces
    [birth_country_id] SMALLINT DEFAULT 1, -- FK to Reference.Nationalities
    [native_ward_id] INT NULL, -- FK to Reference.Wards
    [native_district_id] INT NULL, -- FK to Reference.Districts
    [native_province_id] INT NULL, -- FK to Reference.Provinces
    [primary_address_id] BIGINT NULL, -- FK to BCA.Address (thay thế current_address*)
    [nationality_id] SMALLINT NOT NULL DEFAULT 1, -- FK to Reference.Nationalities
    [ethnicity_id] SMALLINT NULL, -- FK to Reference.Ethnicities
    [religion_id] SMALLINT NULL, -- FK to Reference.Religions
    [marital_status_id] SMALLINT NULL, -- FK to Reference.MaritalStatuses
    [education_level_id] SMALLINT NULL, -- FK to Reference.EducationLevels
    [occupation_id] INT NULL, -- FK to Reference.Occupations
    [father_citizen_id] VARCHAR(12) NULL,
    [mother_citizen_id] VARCHAR(12) NULL,
    [spouse_citizen_id] VARCHAR(12) NULL,
    [representative_citizen_id] VARCHAR(12) NULL,
    [citizen_status_id] SMALLINT NOT NULL, -- FK to Reference.CitizenStatusTypes (thay thế citizen_death_status_id)
    [status_change_date] DATE NULL, -- Ngày thay đổi trạng thái (thay thế date_of_death)
    [phone_number] VARCHAR(15) NULL,
    [email] VARCHAR(100) NULL,
    [blood_type_id] SMALLINT NULL, -- FK to Reference.BloodTypes
    [place_of_birth_code] VARCHAR(10) NULL,
    [place_of_birth_detail] NVARCHAR(MAX) NULL,
    [tax_code] VARCHAR(13) NULL,
    [social_insurance_no] VARCHAR(13) NULL,
    [health_insurance_no] VARCHAR(15) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[Citizen] created.';
GO

-- Table: BCA.Address (Không thay đổi)
IF OBJECT_ID('BCA.Address', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[Address] exists. Dropping it...';
    DROP TABLE [BCA].[Address];
    PRINT N'  Table [BCA].[Address] dropped.';
END
GO
PRINT N'  Creating table [BCA].[Address]...';
CREATE TABLE [BCA].[Address] (
    [address_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [address_detail] NVARCHAR(MAX) NOT NULL,
    [ward_id] INT NOT NULL, -- FK to Reference.Wards
    [district_id] INT NOT NULL, -- FK to Reference.Districts
    [province_id] INT NOT NULL, -- FK to Reference.Provinces
    [postal_code] VARCHAR(10) NULL,
    [latitude] DECIMAL(9,6) NULL,
    [longitude] DECIMAL(9,6) NULL,
    [status] BIT DEFAULT 1,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[Address] created.';
GO

-- Table: BCA.IdentificationCard (Không thay đổi)
IF OBJECT_ID('BCA.IdentificationCard', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[IdentificationCard] exists. Dropping it...';
    DROP TABLE [BCA].[IdentificationCard];
    PRINT N'  Table [BCA].[IdentificationCard] dropped.';
END
GO
PRINT N'  Creating table [BCA].[IdentificationCard]...';
CREATE TABLE [BCA].[IdentificationCard] (
    [id_card_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [card_number] VARCHAR(12) NOT NULL,
    [card_type_id] SMALLINT NOT NULL, -- FK to Reference.IdentificationCardTypes
    [issue_date] DATE NOT NULL,
    [expiry_date] DATE NULL,
    [issuing_authority_id] INT NOT NULL, -- FK to Reference.Authorities
    [issuing_place] NVARCHAR(255) NULL,
    [card_status_id] SMALLINT NOT NULL, -- FK to Reference.IdentificationCardStatuses
    [previous_card_number] VARCHAR(12) NULL,
    [biometric_data] VARBINARY(MAX) NULL,
    [chip_id] VARCHAR(50) NULL,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[IdentificationCard] created.';
GO

-- Table: BCA.ResidenceHistory (Cải tiến: làm rõ mục đích quản lý đăng ký cư trú)
IF OBJECT_ID('BCA.ResidenceHistory', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[ResidenceHistory] exists. Dropping it...';
    DROP TABLE [BCA].[ResidenceHistory];
    PRINT N'  Table [BCA].[ResidenceHistory] dropped.';
END
GO
PRINT N'  Creating table [BCA].[ResidenceHistory]...';
CREATE TABLE [BCA].[ResidenceHistory] (
    [residence_history_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [address_id] BIGINT NOT NULL, -- FK to BCA.Address
    [residence_type_id] SMALLINT NOT NULL, -- FK to Reference.ResidenceTypes
    [registration_date] DATE NOT NULL,
    [expiry_date] DATE NULL,
    [registration_reason] NVARCHAR(MAX) NULL,
    [previous_address_id] BIGINT NULL, -- FK to BCA.Address
    [issuing_authority_id] INT NOT NULL, -- FK to Reference.Authorities
    [registration_number] VARCHAR(50) NULL,
    [host_name] NVARCHAR(100) NULL,
    [host_citizen_id] VARCHAR(12) NULL,
    [host_relationship] NVARCHAR(50) NULL,
    [document_url] VARCHAR(255) NULL,
    [extension_count] SMALLINT DEFAULT 0,
    [last_extension_date] DATE NULL,
    [verification_status] NVARCHAR(50) DEFAULT N'Đã xác minh',
    [verification_date] DATE NULL,
    [verified_by] NVARCHAR(100) NULL,
    [res_reg_status_id] SMALLINT NOT NULL, -- FK to Reference.ResidenceRegistrationStatuses
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[ResidenceHistory] created.';
GO

-- Table: BCA.TemporaryAbsence (Không thay đổi)
IF OBJECT_ID('BCA.TemporaryAbsence', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[TemporaryAbsence] exists. Dropping it...';
    DROP TABLE [BCA].[TemporaryAbsence];
    PRINT N'  Table [BCA].[TemporaryAbsence] dropped.';
END
GO
PRINT N'  Creating table [BCA].[TemporaryAbsence]...';
CREATE TABLE [BCA].[TemporaryAbsence] (
    [temporary_absence_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [from_date] DATE NOT NULL,
    [to_date] DATE NULL,
    [reason] NVARCHAR(MAX) NOT NULL,
    [destination_address_id] BIGINT NULL, -- FK to BCA.Address
    [destination_detail] NVARCHAR(MAX) NULL,
    [contact_information] NVARCHAR(MAX) NULL,
    [registration_authority_id] INT NULL, -- FK to Reference.Authorities
    [registration_number] VARCHAR(50) NULL,
    [document_url] VARCHAR(255) NULL,
    [return_date] DATE NULL,
    [return_confirmed] BIT DEFAULT 0,
    [return_confirmed_by] NVARCHAR(100) NULL,
    [return_confirmed_date] DATE NULL,
    [return_notes] NVARCHAR(MAX) NULL,
    [verification_status] NVARCHAR(50) DEFAULT N'Đã xác minh',
    [verification_date] DATE NULL,
    [verified_by] NVARCHAR(100) NULL,
    [temp_abs_status_id] SMALLINT NOT NULL, -- FK to Reference.TemporaryAbsenceStatuses
    [notes] NVARCHAR(MAX) NULL,
    [sensitivity_level_id] SMALLINT NOT NULL, -- FK to Reference.DataSensitivityLevels
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[TemporaryAbsence] created.';
GO

-- Table: BCA.CitizenStatus (Cải tiến: làm rõ mục đích lịch sử thay đổi trạng thái)
IF OBJECT_ID('BCA.CitizenStatus', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[CitizenStatus] exists. Dropping it...';
    DROP TABLE [BCA].[CitizenStatus];
    PRINT N'  Table [BCA].[CitizenStatus] dropped.';
END
GO
PRINT N'  Creating table [BCA].[CitizenStatus]...';
CREATE TABLE [BCA].[CitizenStatus] (
    [status_id] INT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [citizen_status_id] SMALLINT NOT NULL, -- FK to Reference.CitizenStatusTypes (đổi từ citizen_status_type_id)
    [status_date] DATE NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [cause] NVARCHAR(200) NULL,
    [location] NVARCHAR(200) NULL,
    [authority_id] INT NULL, -- FK to Reference.Authorities
    [document_number] VARCHAR(50) NULL,
    [document_date] DATE NULL,
    [certificate_id] VARCHAR(50) NULL, -- Logical link to DeathCertificate in DB_BTP
    [reported_by] NVARCHAR(100) NULL,
    [relationship] NVARCHAR(50) NULL,
    [verification_status] NVARCHAR(50) DEFAULT N'Chưa xác minh',
    [is_current] BIT NOT NULL DEFAULT 1,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[CitizenStatus] created.';
GO

-- Table: BCA.CitizenMovement (Cải tiến: tham chiếu đến DocumentTypes)
IF OBJECT_ID('BCA.CitizenMovement', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[CitizenMovement] exists. Dropping it...';
    DROP TABLE [BCA].[CitizenMovement];
    PRINT N'  Table [BCA].[CitizenMovement] dropped.';
END
GO
PRINT N'  Creating table [BCA].[CitizenMovement]...';
CREATE TABLE [BCA].[CitizenMovement] (
    [movement_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [movement_type_id] SMALLINT NOT NULL, -- FK to Reference.CitizenMovementTypes
    [from_address_id] BIGINT NULL, -- FK to BCA.Address
    [to_address_id] BIGINT NULL, -- FK to BCA.Address
    [from_country_id] SMALLINT NULL, -- FK to Reference.Nationalities
    [to_country_id] SMALLINT NULL, -- FK to Reference.Nationalities
    [departure_date] DATE NOT NULL,
    [arrival_date] DATE NULL,
    [purpose] NVARCHAR(255) NULL,
    [document_no] VARCHAR(50) NULL,
    [document_type_id] SMALLINT NULL, -- FK to Reference.DocumentTypes (bảng mới)
    [document_issue_date] DATE NULL,
    [document_expiry_date] DATE NULL,
    [carrier] NVARCHAR(100) NULL,
    [border_checkpoint] NVARCHAR(150) NULL,
    [description] NVARCHAR(MAX) NULL,
    [movement_status_id] SMALLINT NOT NULL, -- FK to Reference.CitizenMovementStatuses
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[CitizenMovement] created.';
GO

-- Table: BCA.CriminalRecord (Cải tiến: tham chiếu đến ExecutionStatuses)
IF OBJECT_ID('BCA.CriminalRecord', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[CriminalRecord] exists. Dropping it...';
    DROP TABLE [BCA].[CriminalRecord];
    PRINT N'  Table [BCA].[CriminalRecord] dropped.';
END
GO
PRINT N'  Creating table [BCA].[CriminalRecord]...';
CREATE TABLE [BCA].[CriminalRecord] (
    [record_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [crime_type_id] INT NULL, -- FK to Reference.CrimeTypes
    [crime_description] NVARCHAR(MAX) NULL,
    [crime_date] DATE NULL,
    [court_name] NVARCHAR(200) NULL,
    [judgment_no] VARCHAR(50) NULL,
    [judgment_date] DATE NULL,
    [sentence_description] NVARCHAR(MAX) NULL,
    [sentence_start_date] DATE NULL,
    [sentence_end_date] DATE NULL,
    [probation_period] NVARCHAR(100) NULL,
    [prison_facility_id] INT NULL, -- FK to Reference.PrisonFacilities
    [execution_status_id] SMALLINT NULL, -- FK to Reference.ExecutionStatuses (bảng mới)
    [notes] NVARCHAR(MAX) NULL,
    [sensitivity_level_id] SMALLINT NOT NULL, -- FK to Reference.DataSensitivityLevels
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[CriminalRecord] created.';
GO

-- Table: BCA.CitizenAddress (Cải tiến: làm rõ mục đích lưu trữ tất cả loại địa chỉ)
IF OBJECT_ID('BCA.CitizenAddress', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[CitizenAddress] exists. Dropping it...';
    DROP TABLE [BCA].[CitizenAddress];
    PRINT N'  Table [BCA].[CitizenAddress] dropped.';
END
GO
PRINT N'  Creating table [BCA].[CitizenAddress]...';
CREATE TABLE [BCA].[CitizenAddress] (
    [citizen_address_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [address_id] BIGINT NOT NULL, -- FK to BCA.Address
    [address_type_id] SMALLINT NOT NULL, -- FK to Reference.AddressTypes
    [from_date] DATE NOT NULL,
    [to_date] DATE NULL,
    [is_primary] BIT DEFAULT 0,
    [status] BIT DEFAULT 1,
    [registration_document_no] VARCHAR(50) NULL,
    [registration_date] DATE NULL,
    [issuing_authority_id] INT NULL, -- FK to Reference.Authorities
    [verification_status] NVARCHAR(50) DEFAULT N'Đã xác minh',
    [verification_date] DATE NULL,
    [verified_by] NVARCHAR(100) NULL,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[CitizenAddress] created.';
GO


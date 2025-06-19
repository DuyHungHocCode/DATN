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
    [primary_address_id] BIGINT NULL, -- FK to BCA.CitizenAddress
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
    [citizenship_acquisition_date] DATE NULL,
    [citizenship_document_no] VARCHAR(50) NULL,
    [citizenship_document_type_id] SMALLINT NULL, --FK to Reference.DocumentTypes
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
    [ownership_certificate_id] BIGINT NULL, -- FK to TNMT.OwnershipCertificate
    [host_relationship] NVARCHAR(50) NULL,
    [rental_contract_id] BIGINT NULL, -- FK to TNMT.RentalContract (sẽ được định nghĩa sau)
    [accommodation_facility_id] BIGINT NULL, -- FK to BCA.AccommodationFacility
    [is_head_of_household] BIT DEFAULT 0,
    [family_relationship_id] BIGINT NULL, -- FK to BTP.FamilyRelationship (Logical FK)
    [residence_status_change_reason_id] SMALLINT NULL, -- FK to Reference.ResidenceStatusChangeReasons
    [document_url] VARCHAR(255) NULL,
    [extension_count] SMALLINT DEFAULT 0,
    [last_extension_date] DATE NULL,
    [verification_status] NVARCHAR(50) DEFAULT N'Đã xác minh',
    [verification_date] DATE NULL,
    [verified_by] NVARCHAR(100) NULL,
    [res_reg_status_id] SMALLINT NOT NULL, 
    [registration_case_type] NVARCHAR(50) NULL,
    [supporting_document_info] NVARCHAR(MAX) NULL,-- FK to Reference.ResidenceRegistrationStatuses
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
    [temporary_absence_type_id] SMALLINT NULL, -- FK to Reference.TemporaryAbsenceTypes
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
    [is_permanent_residence] BIT DEFAULT 0,
    [is_temporary_residence] BIT DEFAULT 0,
    [related_residence_history_id] BIGINT NULL, -- FK to BCA.ResidenceHistory
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[CitizenAddress] created.';
GO

-- Add Household table to BCA schema
IF OBJECT_ID('BCA.Household', 'U') IS NOT NULL DROP TABLE [BCA].[Household];
GO
PRINT N'  Creating table [BCA].[Household]...';
CREATE TABLE [BCA].[Household] (
    [household_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [household_book_no] VARCHAR(20) NOT NULL,
    [head_of_household_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen.citizen_id
    [address_id] BIGINT NOT NULL, -- FK to BCA.Address.address_id
    [registration_date] DATE NOT NULL,
    [issuing_authority_id] INT NULL, -- FK to Reference.Authorities
    [area_code] VARCHAR(20) NULL,
    [household_type_id] SMALLINT NOT NULL, -- FK to Reference.HouseholdTypes
    [household_status_id] SMALLINT NOT NULL, -- FK to Reference.HouseholdStatuses
    [ownership_certificate_id] BIGINT NULL, -- Logical  FK to TNMT.OwnershipCertificate
    [rental_contract_id] BIGINT NULL, -- Logical FK to TNMT.RentalContract 
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BCA].[Household] created.';
GO

-- Add HouseholdMember table to BCA schema
IF OBJECT_ID('BCA.HouseholdMember', 'U') IS NOT NULL DROP TABLE [BCA].[HouseholdMember];
GO
PRINT N'  Creating table [BCA].[HouseholdMember]...';
CREATE TABLE [BCA].[HouseholdMember] (
    [household_member_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [household_id] BIGINT NOT NULL, -- FK to BCA.Household
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen.citizen_id
    [rel_with_head_id] SMALLINT NOT NULL, -- FK to Reference.RelationshipWithHeadTypes
    [join_date] DATE NOT NULL,
    [leave_date] DATE NULL,
    [leave_reason] NVARCHAR(MAX) NULL,
    [previous_household_id] BIGINT NULL, -- FK to BCA.Household
    [member_status_id] SMALLINT NOT NULL, -- FK to Reference.HouseholdMemberStatuses
    [order_in_household] SMALLINT NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BCA].[HouseholdMember] created.';
GO

PRINT N'  Creating table [Audit].[AuditLog]...';
CREATE TABLE [Audit].[AuditLog] (
    [log_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [action_tstamp] DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    [schema_name] VARCHAR(100) NOT NULL,
    [table_name] VARCHAR(100) NOT NULL,
    [operation] VARCHAR(10) NOT NULL CHECK ([operation] IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')),
    [session_user_name] NVARCHAR(128) DEFAULT SUSER_SNAME(),
    [application_name] NVARCHAR(128) DEFAULT APP_NAME(),
    [client_net_address] VARCHAR(48) NULL,
    [host_name] NVARCHAR(128) DEFAULT HOST_NAME(),
    [transaction_id] BIGINT NULL,
    [statement_only] BIT NOT NULL DEFAULT 0,
    [row_data] NVARCHAR(MAX) NULL,
    [changed_fields] NVARCHAR(MAX) NULL,
    [query_text] NVARCHAR(MAX) NULL
);
PRINT N'  Table [Audit].[AuditLog] created.';
GO

-- Table: BCA.AccommodationFacility (Cơ sở lưu trú đặc biệt)
IF OBJECT_ID('BCA.AccommodationFacility', 'U') IS NOT NULL DROP TABLE [BCA].[AccommodationFacility];
GO
PRINT N'  Creating table [BCA].[AccommodationFacility]...';
CREATE TABLE [BCA].[AccommodationFacility] (
    [facility_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [facility_code] VARCHAR(50) UNIQUE NOT NULL,
    [facility_name] NVARCHAR(255) NOT NULL,
    [facility_type_id] SMALLINT NOT NULL, -- FK to Reference.AccommodationFacilityTypes
    [address_id] BIGINT NOT NULL, -- FK to BCA.Address
    [managing_authority_id] INT NULL, -- FK to Reference.Authorities (Đơn vị quản lý cơ sở)
    [contact_person] NVARCHAR(100) NULL,
    [phone_number] VARCHAR(50) NULL,
    [capacity] INT NULL,
    [notes] NVARCHAR(MAX) NULL,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[AccommodationFacility] created.';
GO

-- Table: BCA.MobileResidence (Nơi cư trú trên phương tiện di động)
IF OBJECT_ID('BCA.MobileResidence', 'U') IS NOT NULL DROP TABLE [BCA].[MobileResidence];
GO
PRINT N'  Creating table [BCA].[MobileResidence]...';
CREATE TABLE [BCA].[MobileResidence] (
    [mobile_residence_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [vehicle_registration_number] VARCHAR(50) NOT NULL UNIQUE,
    [vehicle_type_id] SMALLINT NOT NULL, -- FK to Reference.VehicleTypes
    [owner_citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen
    [fixed_mooring_address_id] BIGINT NULL, -- FK to BCA.Address (Địa điểm đậu đỗ thường xuyên)
    [certificate_of_safety_no] VARCHAR(50) NULL, -- Giấy chứng nhận an toàn kỹ thuật
    [purpose_of_use] NVARCHAR(255) NULL, -- Mục đích sử dụng (để ở, kinh doanh...)
    [issuing_authority_id] INT NULL, -- Cơ quan cấp giấy tờ phương tiện
    [notes] NVARCHAR(MAX) NULL,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [BCA].[MobileResidence] created.';
GO

IF OBJECT_ID('BCA.EventOutbox', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [BCA].[EventOutbox] already exists. Dropping it...';
    DROP TABLE [BCA].[EventOutbox];
    PRINT N'  Table [BCA].[EventOutbox] dropped.';
END
GO

CREATE TABLE [BCA].[EventOutbox] (
    [outbox_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [aggregate_type] VARCHAR(50) NOT NULL, -- Loại đối tượng gốc (e.g., 'Citizen', 'Household')
    [aggregate_id] VARCHAR(50) NOT NULL,   -- ID của đối tượng gốc (e.g., citizen_id)
    [event_type] VARCHAR(100) NOT NULL,    -- Loại sự kiện (e.g., 'CitizenCreated', 'HouseholdMemberAdded')
    [payload] NVARCHAR(MAX) NOT NULL,      -- Nội dung sự kiện (thường là JSON)
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(), --
    [processed] BIT DEFAULT 0,             -- Đã được xử lý bởi consumer hay chưa
    [processed_at] DATETIME2(7) NULL, --
    [retry_count] INT DEFAULT 0, --
    [error_message] NVARCHAR(MAX) NULL, --
    [next_retry_at] DATETIME2(7) NULL --
);
PRINT N'  Table [BCA].[EventOutbox] created.';
GO


CREATE TABLE [BCA].[HouseholdChangeLog] (
    [log_id] INT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL,
    [reason_id] INT NOT NULL,
    [from_household_id] BIGINT NULL,
    [to_household_id] BIGINT NOT NULL,
    [effective_date] DATE NOT NULL,
    [notes] NVARCHAR(500) NULL,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [created_by_user_id] NVARCHAR(100) NULL, -- ID của cán bộ thực hiện
);
GO

  -- -- Foreign Key Constraints
    -- CONSTRAINT [FK_HouseholdChangeLog_Citizen] FOREIGN KEY ([citizen_id]) 
    --     REFERENCES [BCA].[Citizen]([citizen_id]),

    -- CONSTRAINT [FK_HouseholdChangeLog_Reason] FOREIGN KEY ([reason_id]) 
    --     REFERENCES [Reference].[HouseholdChangeReason]([reason_id]),

    -- CONSTRAINT [FK_HouseholdChangeLog_FromHousehold] FOREIGN KEY ([from_household_id]) 
    --     REFERENCES [BCA].[Household]([household_id]),

    -- CONSTRAINT [FK_HouseholdChangeLog_ToHousehold] FOREIGN KEY ([to_household_id]) 
    --     REFERENCES [BCA].[Household]([household_id])
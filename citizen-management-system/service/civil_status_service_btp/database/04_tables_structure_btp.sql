-- Script to create table structures for database DB_BTP (Bộ Tư pháp)
-- This script should be run on the SQL Server instance dedicated to DB_BTP,
-- after DB_BTP and its schemas (BTP, Audit, API_Internal) have been created.
-- Columns previously using CHECK constraints for lists are now ID columns
-- referencing tables in DB_Reference.

USE [DB_BTP];
GO

PRINT N'Creating table structures in DB_BTP...';

--------------------------------------------------------------------------------
-- Schema: BTP
--------------------------------------------------------------------------------
PRINT N'Creating tables in schema [BTP]...';

-- Table: BTP.BirthCertificate (Giấy khai sinh)
IF OBJECT_ID('BTP.BirthCertificate', 'U') IS NOT NULL DROP TABLE [BTP].[BirthCertificate];
GO
PRINT N'  Creating table [BTP].[BirthCertificate]...';
CREATE TABLE [BTP].[BirthCertificate] (
    [birth_certificate_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen.citizen_id
    [birth_certificate_no] VARCHAR(20) NOT NULL,
    [registration_date] DATE NOT NULL,
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,
    [issuing_authority_id] INT NOT NULL, -- FK to DB_Reference.Reference.Authorities
    [place_of_birth] NVARCHAR(MAX) NOT NULL, -- Có thể chuẩn hóa thêm nếu cần
    [date_of_birth] DATE NOT NULL,
    [gender_id] SMALLINT NOT NULL, -- FK to DB_Reference.Reference.Genders
    [father_full_name] NVARCHAR(100) NULL,
    [father_citizen_id] VARCHAR(12) NULL, -- Logical link to BCA.Citizen.citizen_id
    [father_date_of_birth] DATE NULL,
    [father_nationality_id] SMALLINT NULL, -- FK to DB_Reference.Reference.Nationalities
    [mother_full_name] NVARCHAR(100) NULL,
    [mother_citizen_id] VARCHAR(12) NULL, -- Logical link to BCA.Citizen.citizen_id
    [mother_date_of_birth] DATE NULL,
    [mother_nationality_id] SMALLINT NULL, -- FK to DB_Reference.Reference.Nationalities
    [declarant_name] NVARCHAR(100) NOT NULL,
    [declarant_citizen_id] VARCHAR(12) NULL, -- Logical link to BCA.Citizen.citizen_id
    [declarant_relationship] NVARCHAR(50) NULL, -- Có thể thay bằng ID nếu có bảng Reference.DeclarantRelationshipTypes
    [witness1_name] NVARCHAR(100) NULL,
    [witness2_name] NVARCHAR(100) NULL,
    [birth_notification_no] VARCHAR(50) NULL,
    [status] BIT DEFAULT 1, -- Active/Inactive (Có thể cân nhắc chuyển sang status_id nếu nhiều trạng thái)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BTP].[BirthCertificate] created.';
GO

-- Table: BTP.DeathCertificate (Giấy chứng tử)
IF OBJECT_ID('BTP.DeathCertificate', 'U') IS NOT NULL DROP TABLE [BTP].[DeathCertificate];
GO
PRINT N'  Creating table [BTP].[DeathCertificate]...';
CREATE TABLE [BTP].[DeathCertificate] (
    [death_certificate_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen.citizen_id
    [death_certificate_no] VARCHAR(20) NOT NULL,
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,
    [date_of_death] DATE NOT NULL,
    [time_of_death] TIME NULL,
    [place_of_death_detail] NVARCHAR(MAX) NOT NULL,
    [place_of_death_ward_id] INT NULL, -- FK to DB_Reference.Reference.Wards
    [place_of_death_district_id] INT NULL, -- FK to DB_Reference.Reference.Districts
    [place_of_death_province_id] INT NULL, -- FK to DB_Reference.Reference.Provinces
    [cause_of_death] NVARCHAR(MAX) NULL,
    [declarant_name] NVARCHAR(100) NOT NULL,
    [declarant_citizen_id] VARCHAR(12) NULL, -- Logical link to BCA.Citizen.citizen_id
    [declarant_relationship] NVARCHAR(50) NULL, -- Có thể thay bằng ID
    [registration_date] DATE NOT NULL,
    [issuing_authority_id] INT NULL, -- FK to DB_Reference.Reference.Authorities
    [death_notification_no] VARCHAR(50) NULL,
    [witness1_name] NVARCHAR(100) NULL,
    [witness2_name] NVARCHAR(100) NULL,
    [status] BIT DEFAULT 1, -- Active/Cancelled (Có thể cân nhắc chuyển sang status_id)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BTP].[DeathCertificate] created.';
GO

-- Table: BTP.MarriageCertificate (Giấy chứng nhận kết hôn)
IF OBJECT_ID('BTP.MarriageCertificate', 'U') IS NOT NULL DROP TABLE [BTP].[MarriageCertificate];
GO
PRINT N'  Creating table [BTP].[MarriageCertificate]...';
CREATE TABLE [BTP].[MarriageCertificate] (
    [marriage_certificate_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [marriage_certificate_no] VARCHAR(20) NOT NULL,
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,

    [husband_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen.citizen_id
    [husband_full_name] NVARCHAR(100) NOT NULL,
    [husband_date_of_birth] DATE NOT NULL,
    [husband_nationality_id] SMALLINT NOT NULL, -- FK to DB_Reference.Reference.Nationalities
    [husband_previous_marital_status_id] SMALLINT NULL, -- FK to DB_Reference.Reference.MaritalStatuses

    [wife_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen.citizen_id
    [wife_full_name] NVARCHAR(100) NOT NULL,
    [wife_date_of_birth] DATE NOT NULL,
    [wife_nationality_id] SMALLINT NOT NULL, -- FK to DB_Reference.Reference.Nationalities
    [wife_previous_marital_status_id] SMALLINT NULL, -- FK to DB_Reference.Reference.MaritalStatuses

    [marriage_date] DATE NOT NULL,
    [registration_date] DATE NOT NULL,
    [issuing_authority_id] INT NOT NULL, -- FK to DB_Reference.Reference.Authorities
    [issuing_place] NVARCHAR(MAX) NOT NULL, -- Hoặc có thể chuẩn hóa thành issuing_place_ward/district/province_id
    [witness1_name] NVARCHAR(100) NULL,
    [witness2_name] NVARCHAR(100) NULL,
    [status] BIT DEFAULT 1, -- Marriage status (1=Valid, 0=Dissolved/Annulled) - Có thể chuyển thành status_id
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BTP].[MarriageCertificate] created.';
GO

-- Table: BTP.DivorceRecord (Quyết định/Bản án ly hôn)
IF OBJECT_ID('BTP.DivorceRecord', 'U') IS NOT NULL DROP TABLE [BTP].[DivorceRecord];
GO
PRINT N'  Creating table [BTP].[DivorceRecord]...';
CREATE TABLE [BTP].[DivorceRecord] (
    [divorce_record_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [divorce_certificate_no] VARCHAR(20) NULL, -- Số giấy chứng nhận ly hôn (nếu có)
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,
    [marriage_certificate_id] BIGINT NOT NULL, -- FK to BTP.MarriageCertificate
    [divorce_date] DATE NOT NULL,
    [registration_date] DATE NOT NULL, -- Ngày ghi vào sổ
    [court_name] NVARCHAR(200) NOT NULL, -- Tên Tòa án ra quyết định/bản án
    [judgment_no] VARCHAR(50) NOT NULL, -- Số quyết định/bản án
    [judgment_date] DATE NOT NULL,
    [issuing_authority_id] INT NULL, -- FK to DB_Reference.Reference.Authorities (có thể là Tòa án)
    [reason] NVARCHAR(MAX) NULL,
    [child_custody] NVARCHAR(MAX) NULL,
    [property_division] NVARCHAR(MAX) NULL,
    [status] BIT DEFAULT 1, -- Record status (Valid/Cancelled) - Có thể chuyển thành status_id
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BTP].[DivorceRecord] created.';
GO

-- Table: BTP.FamilyRelationship (Quan hệ gia đình khác)
-- Lưu các mối quan hệ không nhất thiết trong cùng hộ khẩu, hoặc cần ghi nhận chính thức
IF OBJECT_ID('BTP.FamilyRelationship', 'U') IS NOT NULL DROP TABLE [BTP].[FamilyRelationship];
GO
PRINT N'  Creating table [BTP].[FamilyRelationship]...';
CREATE TABLE [BTP].[FamilyRelationship] (
    [relationship_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen.citizen_id
    [related_citizen_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen.citizen_id (Người có quan hệ)
    [relationship_type_id] SMALLINT NOT NULL, -- FK to DB_Reference.Reference.RelationshipTypes
    [start_date] DATE NOT NULL, -- Ngày bắt đầu quan hệ (ví dụ: ngày kết hôn, ngày nhận nuôi)
    [end_date] DATE NULL, -- Ngày kết thúc quan hệ (ví dụ: ngày ly hôn, ngày mất)
    [family_rel_status_id] SMALLINT NOT NULL, -- FK to DB_Reference.Reference.FamilyRelationshipStatuses (e.g., default 'Active')
    [document_proof] NVARCHAR(MAX) NULL, -- Thông tin giấy tờ chứng minh
    [document_no] VARCHAR(50) NULL,
    [issuing_authority_id] INT NULL, -- FK to DB_Reference.Reference.Authorities (Cơ quan cấp giấy tờ)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BTP].[FamilyRelationship] created.';
GO

-- Table: BTP.PopulationChange (Biến động dân số/hộ tịch)
IF OBJECT_ID('BTP.PopulationChange', 'U') IS NOT NULL DROP TABLE [BTP].[PopulationChange];
GO
PRINT N'  Creating table [BTP].[PopulationChange]...';
CREATE TABLE [BTP].[PopulationChange] (
    [change_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen.citizen_id (Công dân có biến động)
    [pop_change_type_id] INT NOT NULL, -- FK to DB_Reference.Reference.PopulationChangeTypes
    [change_date] DATE NOT NULL, -- Ngày xảy ra biến động
    [source_location_id] INT NULL, -- Logical link to a location ID (e.g., Ward ID nơi đi)
    [destination_location_id] INT NULL, -- Logical link to a location ID (e.g., Ward ID nơi đến)
    [reason] NVARCHAR(MAX) NULL,
    [related_document_no] VARCHAR(50) NULL, -- Số giấy tờ liên quan (Giấy KS, KT, KH, LH,...)
    [processing_authority_id] INT NULL, -- FK to DB_Reference.Reference.Authorities (Cơ quan xử lý)
    [status] BIT DEFAULT 1, -- Change processed successfully? (Có thể chuyển thành status_id)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
PRINT N'  Table [BTP].[PopulationChange] created.';
GO

-- Table: BTP.EventOutbox (Bảng Outbox Pattern)
-- Dùng để ghi nhận các sự kiện nghiệp vụ quan trọng cần thông báo cho các hệ thống khác (ví dụ: DB_BCA)
IF OBJECT_ID('BTP.EventOutbox', 'U') IS NOT NULL DROP TABLE [BTP].[EventOutbox];
GO
PRINT N'  Creating table [BTP].[EventOutbox]...';
CREATE TABLE [BTP].[EventOutbox] (
    [outbox_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [aggregate_type] VARCHAR(50) NOT NULL, -- Loại đối tượng gốc (e.g., 'DeathCertificate', 'MarriageCertificate')
    [aggregate_id] VARCHAR(50) NOT NULL,   -- ID của đối tượng gốc (e.g., death_certificate_id, marriage_certificate_id, hoặc citizen_id)
    [event_type] VARCHAR(100) NOT NULL,    -- Loại sự kiện (e.g., 'CitizenDied', 'CitizenMarried')
    [payload] NVARCHAR(MAX) NOT NULL,      -- Nội dung sự kiện (thường là JSON)
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [processed] BIT DEFAULT 0,             -- Đã được xử lý bởi consumer hay chưa
    [processed_at] DATETIME2(7) NULL,
    [retry_count] INT DEFAULT 0,
    [error_message] NVARCHAR(MAX) NULL,
    [next_retry_at] DATETIME2(7) NULL
);
PRINT N'  Table [BTP].[EventOutbox] created.';
GO

PRINT N'Finished creating tables in schema [BTP].';
GO

--------------------------------------------------------------------------------
-- Schema: Audit (trong DB_BTP)
--------------------------------------------------------------------------------
PRINT N'Creating tables in schema [Audit]...';

-- Table: Audit.AuditLog
-- Cấu trúc tương tự như trong DB_BCA
IF OBJECT_ID('Audit.AuditLog', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Audit].[AuditLog] exists. Dropping it...';
    DROP TABLE [Audit].[AuditLog];
    PRINT N'  Table [Audit].[AuditLog] dropped.';
END
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

PRINT N'Finished creating tables in schema [Audit].';
GO

PRINT N'Finished creating all table structures in DB_BTP.';
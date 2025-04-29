USE [DB_BCA];
GO

-- Schema: BCA

-- Table: BCA.Citizen
IF OBJECT_ID('BCA.Citizen', 'U') IS NOT NULL DROP TABLE [BCA].[Citizen];
GO
CREATE TABLE [BCA].[Citizen] (
    [citizen_id] VARCHAR(12) PRIMARY KEY,
    [full_name] NVARCHAR(100) NOT NULL,
    [date_of_birth] DATE NOT NULL,
    [gender] NVARCHAR(10) NOT NULL CHECK ([gender] IN (N'Nam', N'Nữ', N'Khác')),
    [birth_ward_id] INT NULL, -- FK added later
    [birth_district_id] INT NULL, -- FK added later
    [birth_province_id] INT NULL, -- FK added later
    [birth_country_id] SMALLINT DEFAULT 1, -- FK added later
    [native_ward_id] INT NULL, -- FK added later
    [native_district_id] INT NULL, -- FK added later
    [native_province_id] INT NULL, -- FK added later
    [nationality_id] SMALLINT NOT NULL DEFAULT 1, -- FK added later
    [ethnicity_id] SMALLINT NULL, -- FK added later
    [religion_id] SMALLINT NULL, -- FK added later
    [marital_status] NVARCHAR(20) NULL CHECK ([marital_status] IN (N'Độc thân', N'Đã kết hôn', N'Đã ly hôn', N'Góa', N'Ly thân')), -- Updated via API
    [education_level] NVARCHAR(50) NULL CHECK ([education_level] IN (N'Chưa đi học', N'Tiểu học', N'Trung học cơ sở', N'Trung học phổ thông', N'Trung cấp', N'Cao đẳng', N'Đại học', N'Thạc sĩ', N'Tiến sĩ', N'Khác', N'Không xác định')),
    [occupation_id] INT NULL, -- FK added later
    [current_address_detail] NVARCHAR(MAX) NULL,
    [current_ward_id] INT NULL, -- FK added later
    [current_district_id] INT NULL, -- FK added later
    [current_province_id] INT NULL, -- FK added later
    [father_citizen_id] VARCHAR(12) NULL,
    [mother_citizen_id] VARCHAR(12) NULL,
    [spouse_citizen_id] VARCHAR(12) NULL, -- Updated via API
    [representative_citizen_id] VARCHAR(12) NULL,
    [death_status] NVARCHAR(20) DEFAULT N'Còn sống' CHECK ([death_status] IN (N'Còn sống', N'Đã mất', N'Mất tích')), -- Updated via API
    [date_of_death] DATE NULL, -- Updated via API
    [phone_number] VARCHAR(15) NULL,
    [email] VARCHAR(100) NULL,
    [blood_type] VARCHAR(15) NULL CHECK ([blood_type] IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', N'Không xác định')), -- Added from original script
    [place_of_birth_code] VARCHAR(10) NULL, -- Added from original script
    [place_of_birth_detail] NVARCHAR(MAX) NULL, -- Added from original script
    [tax_code] VARCHAR(13) NULL, -- Added from original script
    [social_insurance_no] VARCHAR(13) NULL, -- Added from original script
    [health_insurance_no] VARCHAR(15) NULL, -- Added from original script
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.Address
IF OBJECT_ID('BCA.Address', 'U') IS NOT NULL DROP TABLE [BCA].[Address];
GO
CREATE TABLE [BCA].[Address] (
    [address_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [address_detail] NVARCHAR(MAX) NOT NULL,
    [ward_id] INT NOT NULL, -- FK added later
    [district_id] INT NOT NULL, -- FK added later
    [province_id] INT NOT NULL, -- FK added later
    [postal_code] VARCHAR(10) NULL,
    [latitude] DECIMAL(9,6) NULL,
    [longitude] DECIMAL(9,6) NULL,
    [status] BIT DEFAULT 1, -- Renamed from is_active for consistency
    [notes] NVARCHAR(MAX) NULL, -- Added from original script
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.IdentificationCard
IF OBJECT_ID('BCA.IdentificationCard', 'U') IS NOT NULL DROP TABLE [BCA].[IdentificationCard];
GO
CREATE TABLE [BCA].[IdentificationCard] (
    [id_card_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK added later
    [card_number] VARCHAR(12) NOT NULL, -- Unique constraint added later if needed globally
    [card_type] NVARCHAR(20) NOT NULL CHECK ([card_type] IN (N'CMND 9 số', N'CMND 12 số', N'CCCD', N'CCCD gắn chip')),
    [issue_date] DATE NOT NULL,
    [expiry_date] DATE NULL,
    [issuing_authority_id] INT NOT NULL, -- FK added later
    [issuing_place] NVARCHAR(255) NULL,
    [card_status] NVARCHAR(20) DEFAULT N'Đang sử dụng' CHECK ([card_status] IN (N'Đang sử dụng', N'Hết hạn', N'Mất', N'Hỏng', N'Thu hồi', N'Đã thay thế', N'Tạm giữ')),
    [previous_card_number] VARCHAR(12) NULL,
    [biometric_data] VARBINARY(MAX) NULL,
    [chip_id] VARCHAR(50) NULL, -- Unique constraint added later if needed
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.ResidenceHistory (Combines Permanent and Temporary Residence)
IF OBJECT_ID('BCA.ResidenceHistory', 'U') IS NOT NULL DROP TABLE [BCA].[ResidenceHistory];
GO
CREATE TABLE [BCA].[ResidenceHistory] (
    [residence_history_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK added later
    [address_id] BIGINT NOT NULL, -- FK added later
    [residence_type] NVARCHAR(20) NOT NULL CHECK ([residence_type] IN (N'Thường trú', N'Tạm trú')),
    [registration_date] DATE NOT NULL,
    [expiry_date] DATE NULL, -- Primarily for temporary residence
    [registration_reason] NVARCHAR(MAX) NULL, -- Renamed from change_reason/purpose
    [previous_address_id] BIGINT NULL, -- FK added later
    [issuing_authority_id] INT NOT NULL, -- FK added later
    [registration_number] VARCHAR(50) NULL, -- For temporary residence book/form (decision_no for permanent)
    [host_name] NVARCHAR(100) NULL, -- Added from temporary residence
    [host_citizen_id] VARCHAR(12) NULL, -- Added from temporary residence
    [host_relationship] NVARCHAR(50) NULL, -- Added from temporary residence
    [document_url] VARCHAR(255) NULL, -- Added from original scripts
    [extension_count] SMALLINT DEFAULT 0, -- Added from temporary residence
    [last_extension_date] DATE NULL, -- Added from temporary residence
    [verification_status] NVARCHAR(50) DEFAULT N'Đã xác minh', -- Added from temporary residence
    [verification_date] DATE NULL, -- Added from temporary residence
    [verified_by] NVARCHAR(100) NULL, -- Added from temporary residence
    [status] NVARCHAR(20) DEFAULT N'Active' CHECK ([status] IN (N'Active', N'Expired', N'Cancelled', N'Moved')), -- Combined status
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.TemporaryAbsence (Added from original script)
IF OBJECT_ID('BCA.TemporaryAbsence', 'U') IS NOT NULL DROP TABLE [BCA].[TemporaryAbsence];
GO
CREATE TABLE [BCA].[TemporaryAbsence] (
    [temporary_absence_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK added later
    [from_date] DATE NOT NULL,
    [to_date] DATE NULL,
    [reason] NVARCHAR(MAX) NOT NULL,
    [destination_address_id] BIGINT NULL, -- FK added later
    [destination_detail] NVARCHAR(MAX) NULL,
    [contact_information] NVARCHAR(MAX) NULL,
    [registration_authority_id] INT NULL, -- FK added later
    [registration_number] VARCHAR(50) NULL, -- Unique constraint added later if needed
    [document_url] VARCHAR(255) NULL,
    [return_date] DATE NULL,
    [return_confirmed] BIT DEFAULT 0,
    [return_confirmed_by] NVARCHAR(100) NULL,
    [return_confirmed_date] DATE NULL,
    [return_notes] NVARCHAR(MAX) NULL,
    [verification_status] NVARCHAR(50) DEFAULT N'Đã xác minh',
    [verification_date] DATE NULL,
    [verified_by] NVARCHAR(100) NULL,
    [status] NVARCHAR(20) DEFAULT N'Active' CHECK ([status] IN (N'Active', N'Expired', N'Cancelled', N'Returned')),
    [notes] NVARCHAR(MAX) NULL,
    [data_sensitivity_level] NVARCHAR(20) DEFAULT N'Hạn chế' CHECK ([data_sensitivity_level] IN (N'Công khai', N'Hạn chế', N'Bảo mật', N'Tối mật')), -- Added from original script
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.CitizenStatus
IF OBJECT_ID('BCA.CitizenStatus', 'U') IS NOT NULL DROP TABLE [BCA].[CitizenStatus];
GO
CREATE TABLE [BCA].[CitizenStatus] (
    [status_id] INT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK added later
    [status_type] NVARCHAR(20) NOT NULL CHECK ([status_type] IN (N'Còn sống', N'Đã mất', N'Mất tích')),
    [status_date] DATE NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [cause] NVARCHAR(200) NULL,
    [location] NVARCHAR(200) NULL,
    [authority_id] INT NULL, -- FK added later
    [document_number] VARCHAR(50) NULL,
    [document_date] DATE NULL,
    [certificate_id] VARCHAR(50) NULL, -- Link to DeathCertificate in BTP (logical)
    [reported_by] NVARCHAR(100) NULL,
    [relationship] NVARCHAR(50) NULL,
    [verification_status] NVARCHAR(50) DEFAULT N'Chưa xác minh',
    [is_current] BIT NOT NULL DEFAULT 1, -- Indicates if this is the latest status
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.CitizenMovement (Added from original script)
IF OBJECT_ID('BCA.CitizenMovement', 'U') IS NOT NULL DROP TABLE [BCA].[CitizenMovement];
GO
CREATE TABLE [BCA].[CitizenMovement] (
    [movement_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK added later
    [movement_type] NVARCHAR(20) NOT NULL CHECK ([movement_type] IN (N'Trong nước', N'Xuất cảnh', N'Nhập cảnh', N'Tái nhập cảnh')),
    [from_address_id] BIGINT NULL, -- FK added later
    [to_address_id] BIGINT NULL, -- FK added later
    [from_country_id] SMALLINT NULL, -- FK added later
    [to_country_id] SMALLINT NULL, -- FK added later
    [departure_date] DATE NOT NULL,
    [arrival_date] DATE NULL,
    [purpose] NVARCHAR(255) NULL,
    [document_no] VARCHAR(50) NULL,
    [document_type] NVARCHAR(50) NULL,
    [document_issue_date] DATE NULL,
    [document_expiry_date] DATE NULL,
    [carrier] NVARCHAR(100) NULL,
    [border_checkpoint] NVARCHAR(150) NULL,
    [description] NVARCHAR(MAX) NULL,
    [status] NVARCHAR(20) DEFAULT N'Hoạt động' NOT NULL CHECK ([status] IN (N'Hoạt động', N'Hoàn thành', N'Đã hủy')),
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.CriminalRecord
IF OBJECT_ID('BCA.CriminalRecord', 'U') IS NOT NULL DROP TABLE [BCA].[CriminalRecord];
GO
CREATE TABLE [BCA].[CriminalRecord] (
    [record_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK added later
    [crime_type] NVARCHAR(100) NULL CHECK ([crime_type] IN (N'Vi phạm hành chính', N'Tội phạm ít nghiêm trọng', N'Tội phạm nghiêm trọng', N'Tội phạm rất nghiêm trọng', N'Tội phạm đặc biệt nghiêm trọng')),
    [crime_description] NVARCHAR(MAX) NULL,
    [crime_date] DATE NULL,
    [court_name] NVARCHAR(200) NULL,
    [judgment_no] VARCHAR(50) NULL, -- Unique constraint added later if needed
    [judgment_date] DATE NULL,
    [sentence_description] NVARCHAR(MAX) NULL, -- Renamed from sentence_details/sentence_length
    [sentence_start_date] DATE NULL, -- Renamed from entry_date
    [sentence_end_date] DATE NULL, -- Renamed from release_date
    [probation_period] NVARCHAR(100) NULL, -- Added for clarity
    [prison_facility_id] INT NULL, -- Added from original script, FK later
    [execution_status] NVARCHAR(50) NULL,
    [notes] NVARCHAR(MAX) NULL, -- Renamed from note
    [data_sensitivity_level] NVARCHAR(20) DEFAULT N'Bảo mật' CHECK ([data_sensitivity_level] IN (N'Công khai', N'Hạn chế', N'Bảo mật', N'Tối mật')), -- Added from original script
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Table: BCA.CitizenAddress (Added from original script)
IF OBJECT_ID('BCA.CitizenAddress', 'U') IS NOT NULL DROP TABLE [BCA].[CitizenAddress];
GO
CREATE TABLE [BCA].[CitizenAddress] (
    [citizen_address_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- FK added later
    [address_id] BIGINT NOT NULL, -- FK added later
    [address_type] NVARCHAR(20) NOT NULL CHECK ([address_type] IN (N'Thường trú', N'Tạm trú', N'Nơi ở hiện tại', N'Công ty', N'Học tập', N'Khác')),
    [from_date] DATE NOT NULL,
    [to_date] DATE NULL,
    [is_primary] BIT DEFAULT 0, -- Unique constraint added later if needed
    [status] BIT DEFAULT 1,
    [registration_document_no] VARCHAR(50) NULL,
    [registration_date] DATE NULL,
    [issuing_authority_id] INT NULL, -- FK added later
    [verification_status] NVARCHAR(50) DEFAULT N'Đã xác minh',
    [verification_date] DATE NULL,
    [verified_by] NVARCHAR(100) NULL,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL, -- Added from original script
    [updated_by] VARCHAR(50) NULL -- Added from original script
);
GO

-- Schema: Audit

-- Table: Audit.AuditLog
IF OBJECT_ID('Audit.AuditLog', 'U') IS NOT NULL DROP TABLE [Audit].[AuditLog];
GO
CREATE TABLE [Audit].[AuditLog] (
    [log_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [action_tstamp] DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    [schema_name] VARCHAR(100) NOT NULL,
    [table_name] VARCHAR(100) NOT NULL,
    [operation] VARCHAR(10) NOT NULL CHECK ([operation] IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')),
    [session_user_name] NVARCHAR(128) DEFAULT SUSER_SNAME(),
    [application_name] NVARCHAR(128) DEFAULT APP_NAME(),
    [client_net_address] VARCHAR(48) NULL, -- Retrieved via trigger context if needed
    [host_name] NVARCHAR(128) DEFAULT HOST_NAME(),
    [transaction_id] BIGINT NULL, -- Retrieved via trigger context if needed
    [statement_only] BIT NOT NULL DEFAULT 0,
    [row_data] NVARCHAR(MAX) NULL, -- Store as JSON or XML
    [changed_fields] NVARCHAR(MAX) NULL, -- Store as JSON or XML
    [query_text] NVARCHAR(MAX) NULL -- Retrieved via trigger context if needed
);
GO

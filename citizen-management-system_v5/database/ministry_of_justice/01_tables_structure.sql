USE [DB_BTP];
GO

-- Schema: BTP

-- Table: BTP.BirthCertificate
IF OBJECT_ID('BTP.BirthCertificate', 'U') IS NOT NULL DROP TABLE [BTP].[BirthCertificate];
GO
CREATE TABLE [BTP].[BirthCertificate] (
    [birth_certificate_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link, unique constraint added later if needed
    [birth_certificate_no] VARCHAR(20) NOT NULL, -- Unique constraint added later if needed
    [registration_date] DATE NOT NULL,
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,
    [issuing_authority_id] INT NOT NULL, -- FK added later
    [place_of_birth] NVARCHAR(MAX) NOT NULL,
    [date_of_birth] DATE NOT NULL,
    [gender_at_birth] NVARCHAR(10) NOT NULL CHECK ([gender_at_birth] IN (N'Nam', N'Nữ', N'Khác')),
    [father_full_name] NVARCHAR(100) NULL,
    [father_citizen_id] VARCHAR(12) NULL,
    [father_date_of_birth] DATE NULL,
    [father_nationality_id] SMALLINT NULL, -- FK added later
    [mother_full_name] NVARCHAR(100) NULL,
    [mother_citizen_id] VARCHAR(12) NULL,
    [mother_date_of_birth] DATE NULL,
    [mother_nationality_id] SMALLINT NULL, -- FK added later
    [declarant_name] NVARCHAR(100) NOT NULL,
    [declarant_citizen_id] VARCHAR(12) NULL,
    [declarant_relationship] NVARCHAR(50) NULL,
    [witness1_name] NVARCHAR(100) NULL,
    [witness2_name] NVARCHAR(100) NULL,
    [birth_notification_no] VARCHAR(50) NULL,
    [status] BIT DEFAULT 1, -- Active/Inactive
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Table: BTP.DeathCertificate
IF OBJECT_ID('BTP.DeathCertificate', 'U') IS NOT NULL DROP TABLE [BTP].[DeathCertificate];
GO
CREATE TABLE [BTP].[DeathCertificate] (
    [death_certificate_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link, unique constraint added later if needed
    [death_certificate_no] VARCHAR(20) NOT NULL, -- Unique constraint added later if needed
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,
    [date_of_death] DATE NOT NULL,
    [time_of_death] TIME NULL,
    [place_of_death_detail] NVARCHAR(MAX) NOT NULL,
    [place_of_death_ward_id] INT NULL, -- FK added later
    [place_of_death_district_id] INT NULL, -- Derived/FK added later
    [place_of_death_province_id] INT NULL, -- Derived/FK added later
    [cause_of_death] NVARCHAR(MAX) NULL,
    [declarant_name] NVARCHAR(100) NOT NULL,
    [declarant_citizen_id] VARCHAR(12) NULL,
    [declarant_relationship] NVARCHAR(50) NULL,
    [registration_date] DATE NOT NULL,
    [issuing_authority_id] INT NULL, -- FK added later
    [death_notification_no] VARCHAR(50) NULL,
    [witness1_name] NVARCHAR(100) NULL,
    [witness2_name] NVARCHAR(100) NULL,
    [status] BIT DEFAULT 1, -- Active/Cancelled
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Table: BTP.MarriageCertificate
IF OBJECT_ID('BTP.MarriageCertificate', 'U') IS NOT NULL DROP TABLE [BTP].[MarriageCertificate];
GO
CREATE TABLE [BTP].[MarriageCertificate] (
    [marriage_certificate_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [marriage_certificate_no] VARCHAR(20) NOT NULL, -- Unique constraint added later if needed
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,
    [husband_id] VARCHAR(12) NOT NULL, -- Logical link
    [husband_full_name] NVARCHAR(100) NOT NULL,
    [husband_date_of_birth] DATE NOT NULL,
    [husband_nationality_id] SMALLINT NOT NULL, -- FK added later
    [husband_previous_marriage_status] NVARCHAR(50) NULL,
    [wife_id] VARCHAR(12) NOT NULL, -- Logical link
    [wife_full_name] NVARCHAR(100) NOT NULL,
    [wife_date_of_birth] DATE NOT NULL,
    [wife_nationality_id] SMALLINT NOT NULL, -- FK added later
    [wife_previous_marriage_status] NVARCHAR(50) NULL,
    [marriage_date] DATE NOT NULL,
    [registration_date] DATE NOT NULL,
    [issuing_authority_id] INT NOT NULL, -- FK added later
    [issuing_place] NVARCHAR(MAX) NOT NULL,
    [witness1_name] NVARCHAR(100) NULL,
    [witness2_name] NVARCHAR(100) NULL,
    [status] BIT DEFAULT 1, -- Marriage status (1=Valid, 0=Dissolved/Annulled)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Table: BTP.DivorceRecord
IF OBJECT_ID('BTP.DivorceRecord', 'U') IS NOT NULL DROP TABLE [BTP].[DivorceRecord];
GO
CREATE TABLE [BTP].[DivorceRecord] (
    [divorce_record_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [divorce_certificate_no] VARCHAR(20) NULL, -- May not always have a separate certificate number
    [book_id] VARCHAR(20) NULL,
    [page_no] VARCHAR(10) NULL,
    [marriage_certificate_id] BIGINT NOT NULL, -- FK added later
    [divorce_date] DATE NOT NULL,
    [registration_date] DATE NOT NULL, -- Date the divorce was officially recorded
    [court_name] NVARCHAR(200) NOT NULL,
    [judgment_no] VARCHAR(50) NOT NULL, -- Unique constraint added later if needed
    [judgment_date] DATE NOT NULL,
    [issuing_authority_id] INT NULL, -- FK added later (Court or Justice Dept.)
    [reason] NVARCHAR(MAX) NULL,
    [child_custody] NVARCHAR(MAX) NULL,
    [property_division] NVARCHAR(MAX) NULL,
    [status] BIT DEFAULT 1, -- Record status (Valid/Cancelled)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Table: BTP.Household
IF OBJECT_ID('BTP.Household', 'U') IS NOT NULL DROP TABLE [BTP].[Household];
GO
CREATE TABLE [BTP].[Household] (
    [household_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [household_book_no] VARCHAR(20) NOT NULL, -- Unique constraint added later if needed
    [head_of_household_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen
    [address_id] BIGINT NOT NULL, -- Logical link to BCA.Address
    [registration_date] DATE NOT NULL,
    [issuing_authority_id] INT NULL, -- FK added later
    [area_code] VARCHAR(10) NULL,
    [household_type] NVARCHAR(20) NOT NULL CHECK ([household_type] IN (N'Hộ gia đình', N'Hộ tập thể', N'Hộ tạm trú')),
    [status] NVARCHAR(30) DEFAULT N'Đang hoạt động' CHECK ([status] IN (N'Đang hoạt động', N'Tách hộ', N'Đã chuyển đi', N'Đã xóa', N'Đang cập nhật', N'Lưu trữ')),
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Table: BTP.HouseholdMember
IF OBJECT_ID('BTP.HouseholdMember', 'U') IS NOT NULL DROP TABLE [BTP].[HouseholdMember];
GO
CREATE TABLE [BTP].[HouseholdMember] (
    [household_member_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [household_id] BIGINT NOT NULL, -- FK added later
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link to BCA.Citizen
    [relationship_with_head] NVARCHAR(50) NOT NULL CHECK ([relationship_with_head] IN (N'Chủ hộ', N'Vợ', N'Chồng', N'Con đẻ', N'Con nuôi', N'Bố đẻ', N'Mẹ đẻ', N'Bố nuôi', N'Mẹ nuôi', N'Ông nội', N'Bà nội', N'Ông ngoại', N'Bà ngoại', N'Anh ruột', N'Chị ruột', N'Em ruột', N'Cháu ruột', N'Chắt ruột', N'Cô ruột', N'Dì ruột', N'Chú ruột', N'Bác ruột', N'Người giám hộ', N'Người ở nhờ', N'Người làm thuê', N'Khác')),
    [join_date] DATE NOT NULL,
    [leave_date] DATE NULL,
    [leave_reason] NVARCHAR(MAX) NULL,
    [previous_household_id] BIGINT NULL, -- FK added later
    [status] NVARCHAR(20) DEFAULT N'Active' CHECK ([status] IN (N'Active', N'Left', N'Moved', N'Deceased', N'Cancelled')),
    [order_in_household] SMALLINT NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Table: BTP.FamilyRelationship
IF OBJECT_ID('BTP.FamilyRelationship', 'U') IS NOT NULL DROP TABLE [BTP].[FamilyRelationship];
GO
CREATE TABLE [BTP].[FamilyRelationship] (
    [relationship_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link
    [related_citizen_id] VARCHAR(12) NOT NULL, -- Logical link
    [relationship_type] NVARCHAR(50) NOT NULL CHECK ([relationship_type] IN (N'Vợ-Chồng', N'Cha đẻ-Con đẻ', N'Mẹ đẻ-Con đẻ', N'Cha nuôi-Con nuôi', N'Mẹ nuôi-Con nuôi', N'Ông nội-Cháu nội', N'Bà nội-Cháu nội', N'Ông ngoại-Cháu ngoại', N'Bà ngoại-Cháu ngoại', N'Anh ruột-Em ruột', N'Chị ruột-Em ruột', N'Giám hộ-Được giám hộ', N'Khác')),
    [start_date] DATE NOT NULL,
    [end_date] DATE NULL,
    [status] NVARCHAR(20) DEFAULT N'Active' CHECK ([status] IN (N'Active', N'Inactive', N'Pending Verification')),
    [document_proof] NVARCHAR(MAX) NULL,
    [document_no] VARCHAR(50) NULL,
    [issuing_authority_id] INT NULL, -- FK added later
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Table: BTP.PopulationChange
IF OBJECT_ID('BTP.PopulationChange', 'U') IS NOT NULL DROP TABLE [BTP].[PopulationChange];
GO
CREATE TABLE [BTP].[PopulationChange] (
    [change_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [citizen_id] VARCHAR(12) NOT NULL, -- Logical link
    [change_type] NVARCHAR(100) NOT NULL CHECK ([change_type] IN (N'Đăng ký khai sinh', N'Đăng ký khai tử', N'Đăng ký kết hôn', N'Đăng ký ly hôn', N'Đăng ký giám hộ', N'Chấm dứt giám hộ', N'Đăng ký nhận cha mẹ con', N'Đăng ký thay đổi/cải chính/bổ sung hộ tịch', N'Xác định lại dân tộc', N'Xác định lại giới tính', N'Đăng ký thường trú', N'Xóa đăng ký thường trú', N'Đăng ký tạm trú', N'Xóa đăng ký tạm trú', N'Tạm vắng', N'Nhập quốc tịch', N'Thôi quốc tịch', N'Trở lại quốc tịch', N'Khác')),
    [change_date] DATE NOT NULL,
    [source_location_id] INT NULL, -- Logical link (e.g., Ward ID)
    [destination_location_id] INT NULL, -- Logical link (e.g., Ward ID)
    [reason] NVARCHAR(MAX) NULL,
    [related_document_no] VARCHAR(50) NULL,
    [processing_authority_id] INT NULL, -- FK added later
    [status] BIT DEFAULT 1, -- Change processed successfully?
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME()
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

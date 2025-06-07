-- Schema: TNMT (for Ministry of Natural Resources and Environment tables)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'TNMT')
BEGIN
    PRINT N'  Creating schema [TNMT]...';
    EXEC('CREATE SCHEMA [TNMT]');
    PRINT N'  Schema [TNMT] created.';
END
ELSE
    PRINT N'  Schema [TNMT] already exists.';
GO

USE [DB_BCA];
GO

PRINT N'Creating tables in schema [TNMT]...';

-- Table: TNMT.OwnershipCertificate (Giấy chứng nhận Quyền sử dụng đất, quyền sở hữu nhà ở)
IF OBJECT_ID('TNMT.OwnershipCertificate', 'U') IS NOT NULL DROP TABLE [TNMT].[OwnershipCertificate];
GO
PRINT N'  Creating table [TNMT].[OwnershipCertificate]...';
CREATE TABLE [TNMT].[OwnershipCertificate] (
    [certificate_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [certificate_no] VARCHAR(50) NOT NULL UNIQUE, -- Số seri trên Giấy chứng nhận
    [certificate_type_id] SMALLINT NOT NULL, -- FK to Reference.DocumentTypes (e.g., 'GCN_QSDĐ', 'GCN_SHNĐ')
    [issuing_date] DATE NOT NULL,
    [issuing_authority_id] INT NOT NULL, -- FK to Reference.Authorities (Sở TNMT hoặc Bộ TNMT)
    [owner_citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen.citizen_id (Người đứng tên sở hữu)
    [property_address_id] BIGINT NOT NULL, -- FK to BCA.Address.address_id (Địa chỉ tài sản được chứng nhận)
    [land_area_sqm] DECIMAL(18,2) NULL, -- Diện tích đất (m2)
    [land_use_purpose] NVARCHAR(255) NULL, -- Mục đích sử dụng đất
    [house_area_sqm] DECIMAL(18,2) NULL, -- Diện tích xây dựng nhà (m2)
    [house_floor_area_sqm] DECIMAL(18,2) NULL, -- Diện tích sàn nhà (m2)
    [property_description] NVARCHAR(MAX) NULL, -- Mô tả tài sản (số tầng, kết cấu...)
    [map_sheet_no] VARCHAR(20) NULL, -- Số tờ bản đồ
    [parcel_no] VARCHAR(20) NULL, -- Số thửa đất
    [status] BIT DEFAULT 1, -- Trạng thái (1=Có hiệu lực, 0=Đã hủy/Thu hồi)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [TNMT].[OwnershipCertificate] created.';
GO

-- Table: TNMT.OwnershipHistory (Lịch sử sở hữu tài sản)
IF OBJECT_ID('TNMT.OwnershipHistory', 'U') IS NOT NULL DROP TABLE [TNMT].[OwnershipHistory];
GO
PRINT N'  Creating table [TNMT].[OwnershipHistory]...';
CREATE TABLE [TNMT].[OwnershipHistory] (
    [ownership_history_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [certificate_id] BIGINT NOT NULL, -- FK to TNMT.OwnershipCertificate.certificate_id
    [citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen.citizen_id (Công dân liên quan đến giao dịch này: người mua, người bán, người thừa kế)
    [transaction_type_id] SMALLINT NOT NULL, -- FK to Reference.TransactionTypes
    [transaction_date] DATE NOT NULL,
    [previous_owner_citizen_id] VARCHAR(12) NULL, -- FK to BCA.Citizen.citizen_id (Chủ sở hữu trước đó)
    [new_owner_citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen.citizen_id (Chủ sở hữu mới)
    [document_no] VARCHAR(50) NULL, -- Số văn bản giao dịch (Hợp đồng mua bán, Quyết định thừa kế...)
    [document_type_id] SMALLINT NULL, -- FK to Reference.DocumentTypes (Loại văn bản giao dịch)
    [issuing_authority_id] INT NULL, -- FK to Reference.Authorities (Cơ quan công chứng, Tòa án...)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [TNMT].[OwnershipHistory] created.';
GO


PRINT N'Creating table [TNMT].[RentalContract]...';

-- Table: TNMT.RentalContract (Hợp đồng thuê, mượn, ở nhờ nhà ở)
IF OBJECT_ID('TNMT.RentalContract', 'U') IS NOT NULL DROP TABLE [TNMT].[RentalContract];
GO
CREATE TABLE [TNMT].[RentalContract] (
    [contract_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [contract_no] VARCHAR(50) NOT NULL UNIQUE, -- Số hợp đồng (nếu có) hoặc mã định danh
    [contract_type_id] SMALLINT NOT NULL, -- FK to Reference.ContractTypes (thuê, mượn, ở nhờ)
    [lessor_citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen (Người cho thuê/mượn/ở nhờ)
    [lessee_citizen_id] VARCHAR(12) NOT NULL, -- FK to BCA.Citizen (Người thuê/mượn/ở nhờ)
    [property_address_id] BIGINT NOT NULL, -- FK to BCA.Address (Địa chỉ nhà cho thuê/mượn/ở nhờ)
    [start_date] DATE NOT NULL,
    [end_date] DATE NULL,
    [is_notarized] BIT DEFAULT 0, -- Có công chứng/chứng thực không
    [notarization_date] DATE NULL,
    [notarization_authority_id] INT NULL, -- FK to Reference.Authorities (Cơ quan công chứng/chứng thực)
    [status] BIT DEFAULT 1, -- Trạng thái hợp đồng (1=Còn hiệu lực, 0=Hết hiệu lực/Thanh lý)
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [updated_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [created_by] VARCHAR(50) NULL,
    [updated_by] VARCHAR(50) NULL
);
PRINT N'  Table [TNMT].[RentalContract] created.';
GO
-- ==========================================================================================
-- DANH SÁCH CÁC BẢNG THAM CHIẾU TRONG SCHEMA [REFERENCE] CỦA DB_REFERENCE
-- ==========================================================================================
--
-- ------------------------------------------------------------------------------------------
-- 1.  Reference.Regions                     -- Vùng/Miền địa lý
-- 2.  Reference.Provinces                   -- Tỉnh/Thành phố trực thuộc trung ương
-- 3.  Reference.Districts                   -- Quận/Huyện/Thị xã/Thành phố thuộc tỉnh
-- 4.  Reference.Wards                       -- Phường/Xã/Thị trấn
-- 5.  Reference.Ethnicities                 -- Dân tộc
-- 6.  Reference.Religions                   -- Tôn giáo
-- 7.  Reference.Nationalities               -- Quốc tịch
-- 8.  Reference.Occupations                 -- Nghề nghiệp
-- 9.  Reference.Authorities                 -- Cơ quan có thẩm quyền/Đơn vị cấp phát
-- 10. Reference.RelationshipTypes           -- Loại quan hệ gia đình/thân nhân (dùng chung)
-- 11. Reference.PrisonFacilities            -- Cơ sở giam giữ
--
-- CÁC BẢNG THAM CHIẾU BỔ SUNG (Tạo từ các CHECK constraint trước đây)
-- ------------------------------------------------------------------------------------------
-- Từ DB_BCA:
-- 12. Reference.Genders                     -- Giới tính (Nam, Nữ, Khác)
-- 13. Reference.MaritalStatuses             -- Tình trạng hôn nhân
-- 14. Reference.EducationLevels             -- Trình độ học vấn
-- 15. Reference.CitizenDeathStatuses        -- Trạng thái tử vong của Công dân (trong BCA.Citizen)
-- 16. Reference.BloodTypes                  -- Nhóm máu
-- 17. Reference.IdentificationCardTypes     -- Loại thẻ CCCD/CMND
-- 18. Reference.IdentificationCardStatuses  -- Trạng thái thẻ CCCD/CMND
-- 19. Reference.ResidenceTypes              -- Loại cư trú (Thường trú, Tạm trú)
-- 20. Reference.ResidenceRegistrationStatuses -- Trạng thái đăng ký cư trú
-- 21. Reference.TemporaryAbsenceStatuses    -- Trạng thái tạm vắng
-- 22. Reference.DataSensitivityLevels       -- Mức độ nhạy cảm dữ liệu
-- 23. Reference.CitizenStatusTypes          -- Loại trạng thái công dân (trong BCA.CitizenStatus)
-- 24. Reference.CitizenMovementTypes        -- Loại di biến động dân cư
-- 25. Reference.CitizenMovementStatuses     -- Trạng thái di biến động dân cư
-- 26. Reference.CrimeTypes                  -- Loại tội phạm
-- 27. Reference.AddressTypes                -- Loại địa chỉ (trong BCA.CitizenAddress)
--
-- Từ DB_BTP:
-- 28. Reference.HouseholdTypes              -- Loại hộ khẩu
-- 29. Reference.HouseholdStatuses           -- Trạng thái hộ khẩu
-- 30. Reference.RelationshipWithHeadTypes   -- Quan hệ với chủ hộ (cho BTP.HouseholdMember)
-- 31. Reference.HouseholdMemberStatuses     -- Trạng thái thành viên hộ
-- 32. Reference.FamilyRelationshipStatuses  -- Trạng thái quan hệ gia đình (cho BTP.FamilyRelationship)
-- 33. Reference.PopulationChangeTypes       -- Loại thay đổi dân số
--
-- ==========================================================================================



USE [DB_Reference];
GO

PRINT N'Creating table structures in DB_Reference.Reference schema...';

--------------------------------------------------------------------------------
-- Schema: Reference
--------------------------------------------------------------------------------

-- Table: Reference.Regions (Vùng/Miền)
-- Mô tả: Lưu trữ thông tin về các vùng miền địa lý của Việt Nam.
IF OBJECT_ID('Reference.Regions', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Regions] exists. Dropping it...';
    DROP TABLE [Reference].[Regions];
    PRINT N'  Table [Reference].[Regions] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Regions]...';
CREATE TABLE [Reference].[Regions] (
    [region_id] SMALLINT PRIMARY KEY,               -- Khóa chính, ID của vùng miền
    [region_code] VARCHAR(10) NOT NULL UNIQUE,      -- Mã vùng miền (ví dụ: BAC, TRU, NAM)
    [region_name] NVARCHAR(50) NOT NULL,            -- Tên vùng miền (ví dụ: Miền Bắc, Miền Trung)
    [description] NVARCHAR(MAX) NULL,               -- Mô tả chi tiết về vùng miền
    [created_at] DATETIME2(7) DEFAULT GETDATE(),    -- Ngày giờ tạo bản ghi
    [updated_at] DATETIME2(7) DEFAULT GETDATE()     -- Ngày giờ cập nhật bản ghi cuối cùng
);
PRINT N'  Table [Reference].[Regions] created.';
GO

-- Table: Reference.Provinces (Tỉnh/Thành phố)
-- Mô tả: Lưu trữ thông tin về các tỉnh/thành phố trực thuộc trung ương.
IF OBJECT_ID('Reference.Provinces', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Provinces] exists. Dropping it...';
    DROP TABLE [Reference].[Provinces];
    PRINT N'  Table [Reference].[Provinces] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Provinces]...';
CREATE TABLE [Reference].[Provinces] (
    [province_id] INT PRIMARY KEY,                  -- Khóa chính, ID của tỉnh/thành phố
    [province_code] VARCHAR(10) NOT NULL UNIQUE,    -- Mã tỉnh/thành phố (ví dụ: HNO, HCM)
    [province_name] NVARCHAR(100) NOT NULL,         -- Tên tỉnh/thành phố (ví dụ: Thành phố Hà Nội)
    [region_id] SMALLINT NULL,                      -- Khóa ngoại tham chiếu đến Regions.region_id (sẽ tạo ở file constraints)
    [administrative_unit_id] SMALLINT NULL,         -- ID loại đơn vị hành chính (ví dụ: 1 cho Thành phố TW, 2 cho Tỉnh)
    [administrative_region_id] SMALLINT NULL,       -- ID của vùng hành chính theo phân loại của GSO (ví dụ: Đồng bằng sông Hồng, Tây Nguyên)
    [area] DECIMAL(10,2) NULL,                      -- Diện tích (km2)
    [population] INT NULL,                          -- Dân số
    [gso_code] VARCHAR(10) NULL UNIQUE,             -- Mã tỉnh/thành phố theo Tổng cục Thống kê
    [is_city] BIT DEFAULT 0,                        -- Cờ đánh dấu là thành phố trực thuộc trung ương (1) hay tỉnh (0)
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Provinces] created.';
GO

-- Table: Reference.Districts (Quận/Huyện/Thị xã/Thành phố thuộc tỉnh)
-- Mô tả: Lưu trữ thông tin về các đơn vị hành chính cấp quận/huyện.
IF OBJECT_ID('Reference.Districts', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Districts] exists. Dropping it...';
    DROP TABLE [Reference].[Districts];
    PRINT N'  Table [Reference].[Districts] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Districts]...';
CREATE TABLE [Reference].[Districts] (
    [district_id] INT PRIMARY KEY,                  -- Khóa chính, ID của quận/huyện
    [district_code] VARCHAR(10) NOT NULL UNIQUE,    -- Mã quận/huyện
    [district_name] NVARCHAR(100) NOT NULL,         -- Tên quận/huyện (ví dụ: Quận Ba Đình)
    [province_id] INT NOT NULL,                     -- Khóa ngoại tham chiếu đến Provinces.province_id
    [administrative_unit_id] SMALLINT NULL,         -- ID loại đơn vị hành chính (ví dụ: Quận, Huyện, Thị xã, TP thuộc tỉnh)
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL UNIQUE,             -- Mã quận/huyện theo Tổng cục Thống kê
    [is_urban] BIT DEFAULT 0,                       -- Cờ đánh dấu là đô thị (Quận, Thành phố thuộc tỉnh, Thị xã)
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Districts] created.';
GO

-- Table: Reference.Wards (Phường/Xã/Thị trấn)
-- Mô tả: Lưu trữ thông tin về các đơn vị hành chính cấp phường/xã.
IF OBJECT_ID('Reference.Wards', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Wards] exists. Dropping it...';
    DROP TABLE [Reference].[Wards];
    PRINT N'  Table [Reference].[Wards] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Wards]...';
CREATE TABLE [Reference].[Wards] (
    [ward_id] INT PRIMARY KEY,                      -- Khóa chính, ID của phường/xã
    [ward_code] VARCHAR(10) NOT NULL UNIQUE,        -- Mã phường/xã
    [ward_name] NVARCHAR(100) NOT NULL,             -- Tên phường/xã (ví dụ: Phường Phúc Xá)
    [district_id] INT NOT NULL,                     -- Khóa ngoại tham chiếu đến Districts.district_id
    [administrative_unit_id] SMALLINT NULL,         -- ID loại đơn vị hành chính (ví dụ: Phường, Xã, Thị trấn)
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL UNIQUE,             -- Mã phường/xã theo Tổng cục Thống kê
    [is_urban] BIT DEFAULT 0,                       -- Cờ đánh dấu là đô thị (Phường, Thị trấn)
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Wards] created.';
GO

-- Table: Reference.Ethnicities (Dân tộc)
-- Mô tả: Lưu trữ danh sách các dân tộc Việt Nam.
IF OBJECT_ID('Reference.Ethnicities', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Ethnicities] exists. Dropping it...';
    DROP TABLE [Reference].[Ethnicities];
    PRINT N'  Table [Reference].[Ethnicities] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Ethnicities]...';
CREATE TABLE [Reference].[Ethnicities] (
    [ethnicity_id] SMALLINT PRIMARY KEY,            -- Khóa chính, ID dân tộc
    [ethnicity_code] VARCHAR(10) NOT NULL UNIQUE,   -- Mã dân tộc (ví dụ: KINH, TAY)
    [ethnicity_name] NVARCHAR(100) NOT NULL,        -- Tên dân tộc (ví dụ: Kinh, Tày)
    [description] NVARCHAR(MAX) NULL,               -- Mô tả thêm
    [population] INT NULL,                          -- Dân số (tham khảo)
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Ethnicities] created.';
GO

-- Table: Reference.Religions (Tôn giáo)
-- Mô tả: Lưu trữ danh sách các tôn giáo được công nhận hoặc phổ biến.
IF OBJECT_ID('Reference.Religions', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Religions] exists. Dropping it...';
    DROP TABLE [Reference].[Religions];
    PRINT N'  Table [Reference].[Religions] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Religions]...';
CREATE TABLE [Reference].[Religions] (
    [religion_id] SMALLINT PRIMARY KEY,             -- Khóa chính, ID tôn giáo
    [religion_code] VARCHAR(10) NOT NULL UNIQUE,    -- Mã tôn giáo (ví dụ: BUDD, CATH)
    [religion_name] NVARCHAR(100) NOT NULL,         -- Tên tôn giáo (ví dụ: Phật giáo, Công giáo)
    [description] NVARCHAR(MAX) NULL,               -- Mô tả thêm
    [followers] INT NULL,                           -- Số lượng tín đồ (tham khảo)
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Religions] created.';
GO

-- Table: Reference.Nationalities (Quốc tịch)
-- Mô tả: Lưu trữ danh sách các quốc tịch.
IF OBJECT_ID('Reference.Nationalities', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Nationalities] exists. Dropping it...';
    DROP TABLE [Reference].[Nationalities];
    PRINT N'  Table [Reference].[Nationalities] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Nationalities]...';
CREATE TABLE [Reference].[Nationalities] (
    [nationality_id] SMALLINT PRIMARY KEY,          -- Khóa chính, ID quốc tịch
    [nationality_code] VARCHAR(10) NOT NULL UNIQUE, -- Mã quốc tịch (thường là mã ISO 2 chữ cái)
    [iso_code_alpha2] VARCHAR(2) NULL UNIQUE,       -- Mã ISO 3166-1 alpha-2 (ví dụ: VN, US)
    [iso_code_alpha3] VARCHAR(3) NULL UNIQUE,       -- Mã ISO 3166-1 alpha-3 (ví dụ: VNM, USA)
    [nationality_name] NVARCHAR(100) NOT NULL,     -- Tên quốc tịch (ví dụ: Việt Nam, Hoa Kỳ)
    [country_name] NVARCHAR(100) NOT NULL,          -- Tên quốc gia tương ứng
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Nationalities] created.';
GO

-- Table: Reference.Occupations (Nghề nghiệp)
-- Mô tả: Lưu trữ danh mục các ngành nghề.
IF OBJECT_ID('Reference.Occupations', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Occupations] exists. Dropping it...';
    DROP TABLE [Reference].[Occupations];
    PRINT N'  Table [Reference].[Occupations] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Occupations]...';
CREATE TABLE [Reference].[Occupations] (
    [occupation_id] INT PRIMARY KEY,                -- Khóa chính, ID nghề nghiệp
    [occupation_code] VARCHAR(20) NOT NULL UNIQUE,  -- Mã nghề nghiệp
    [occupation_name] NVARCHAR(255) NOT NULL,       -- Tên nghề nghiệp
    [occupation_group_id] INT NULL,                 -- ID nhóm nghề (nếu có phân cấp, tham chiếu đến bảng khác hoặc tự tham chiếu)
    [description] NVARCHAR(MAX) NULL,               -- Mô tả chi tiết
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Occupations] created.';
GO

-- Table: Reference.Authorities (Cơ quan có thẩm quyền/Đơn vị cấp phát)
-- Mô tả: Lưu trữ thông tin về các cơ quan, đơn vị có thẩm quyền (ví dụ: Bộ Công an, UBND Phường X, Công an Tỉnh Y).
IF OBJECT_ID('Reference.Authorities', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[Authorities] exists. Dropping it...';
    DROP TABLE [Reference].[Authorities];
    PRINT N'  Table [Reference].[Authorities] dropped.';
END
GO
PRINT N'  Creating table [Reference].[Authorities]...';
CREATE TABLE [Reference].[Authorities] (
    [authority_id] INT PRIMARY KEY,                 -- Khóa chính, ID cơ quan
    [authority_code] VARCHAR(30) NOT NULL UNIQUE,   -- Mã cơ quan
    [authority_name] NVARCHAR(255) NOT NULL,        -- Tên cơ quan
    [authority_type] NVARCHAR(100) NOT NULL,        -- Loại cơ quan (ví dụ: Bộ, Cục, Sở, Phòng, UBND Phường, Công an Tỉnh)
    [address_detail] NVARCHAR(MAX) NULL,            -- Địa chỉ chi tiết của cơ quan
    [ward_id] INT NULL,                             -- Khóa ngoại tham chiếu đến Wards.ward_id (nếu có)
    [district_id] INT NULL,                         -- Khóa ngoại tham chiếu đến Districts.district_id (nếu có)
    [province_id] INT NULL,                         -- Khóa ngoại tham chiếu đến Provinces.province_id (nếu có)
    [phone] VARCHAR(50) NULL,                       -- Số điện thoại liên hệ
    [email] VARCHAR(100) NULL,                      -- Địa chỉ email
    [website] VARCHAR(255) NULL,                    -- Trang web
    [parent_authority_id] INT NULL,                 -- ID của cơ quan cha (tự tham chiếu để tạo phân cấp)
    [is_active] BIT DEFAULT 1,                      -- Trạng thái hoạt động
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Authorities] created.';
GO

-- Table: Reference.RelationshipTypes (Loại quan hệ gia đình/thân nhân)
-- Mô tả: Định nghĩa các loại mối quan hệ (ví dụ: Cha-Con, Vợ-Chồng).
IF OBJECT_ID('Reference.RelationshipTypes', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[RelationshipTypes] exists. Dropping it...';
    DROP TABLE [Reference].[RelationshipTypes];
    PRINT N'  Table [Reference].[RelationshipTypes] dropped.';
END
GO
PRINT N'  Creating table [Reference].[RelationshipTypes]...';
CREATE TABLE [Reference].[RelationshipTypes] (
    [relationship_type_id] SMALLINT PRIMARY KEY,    -- Khóa chính, ID loại quan hệ
    [relationship_code] VARCHAR(20) NOT NULL UNIQUE,-- Mã loại quan hệ
    [relationship_name] NVARCHAR(100) NOT NULL,     -- Tên loại quan hệ (ví dụ: Con đẻ, Vợ, Chồng)
    [inverse_relationship_type_id] SMALLINT NULL,   -- ID của loại quan hệ đối ứng (ví dụ: Cha <-> Con)
    [description] NVARCHAR(MAX) NULL,               -- Mô tả
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[RelationshipTypes] created.';
GO

-- Table: Reference.PrisonFacilities (Cơ sở giam giữ)
-- Mô tả: Lưu trữ thông tin về các trại giam, cơ sở giáo dục bắt buộc.
IF OBJECT_ID('Reference.PrisonFacilities', 'U') IS NOT NULL
BEGIN
    PRINT N'  Table [Reference].[PrisonFacilities] exists. Dropping it...';
    DROP TABLE [Reference].[PrisonFacilities];
    PRINT N'  Table [Reference].[PrisonFacilities] dropped.';
END
GO
PRINT N'  Creating table [Reference].[PrisonFacilities]...';
CREATE TABLE [Reference].[PrisonFacilities] (
    [prison_facility_id] INT IDENTITY(1,1) PRIMARY KEY, -- Khóa chính, ID cơ sở giam giữ
    [facility_code] VARCHAR(30) NULL UNIQUE,        -- Mã cơ sở (nếu có)
    [facility_name] NVARCHAR(255) NOT NULL,         -- Tên cơ sở
    [facility_type] NVARCHAR(100) NULL,             -- Loại cơ sở (ví dụ: Trại giam, Trại tạm giam, Cơ sở giáo dục)
    [address_detail] NVARCHAR(MAX) NULL,            -- Địa chỉ chi tiết
    [ward_id] INT NULL,                             -- Khóa ngoại tham chiếu đến Wards.ward_id
    [district_id] INT NULL,                         -- Khóa ngoại tham chiếu đến Districts.district_id
    [province_id] INT NOT NULL,                     -- Khóa ngoại tham chiếu đến Provinces.province_id
    [capacity] INT NULL,                            -- Sức chứa (số lượng người)
    [managing_authority_id] INT NULL,               -- ID cơ quan quản lý (tham chiếu đến Authorities.authority_id)
    [phone_number] VARCHAR(50) NULL,
    [is_active] BIT DEFAULT 1,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[PrisonFacilities] created.';
GO

-- Table: Reference.Genders (Giới tính)
-- Replaces CHECK constraint for gender columns
IF OBJECT_ID('Reference.Genders', 'U') IS NOT NULL DROP TABLE [Reference].[Genders];
GO
PRINT N'  Creating table [Reference].[Genders]...';
CREATE TABLE [Reference].[Genders] (
    [gender_id] SMALLINT PRIMARY KEY,
    [gender_code] VARCHAR(10) UNIQUE, -- e.g., 'NAM', 'NU', 'KHAC'
    [gender_name_vi] NVARCHAR(20) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[Genders] created.';
GO

-- Table: Reference.MaritalStatuses (Tình trạng hôn nhân)
IF OBJECT_ID('Reference.MaritalStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[MaritalStatuses];
GO
PRINT N'  Creating table [Reference].[MaritalStatuses]...';
CREATE TABLE [Reference].[MaritalStatuses] (
    [marital_status_id] SMALLINT PRIMARY KEY,
    [marital_status_code] VARCHAR(20) UNIQUE, -- e.g., 'DOCTHAN', 'DAKETHON'
    [marital_status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[MaritalStatuses] created.';
GO

-- Table: Reference.EducationLevels (Trình độ học vấn)
IF OBJECT_ID('Reference.EducationLevels', 'U') IS NOT NULL DROP TABLE [Reference].[EducationLevels];
GO
PRINT N'  Creating table [Reference].[EducationLevels]...';
CREATE TABLE [Reference].[EducationLevels] (
    [education_level_id] SMALLINT PRIMARY KEY,
    [education_level_code] VARCHAR(30) UNIQUE, -- e.g., 'TIEUHOC', 'DAIHOC'
    [education_level_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[EducationLevels] created.';
GO

-- Table: Reference.CitizenDeathStatuses (Trạng thái tử vong của Công dân trong bảng Citizen)
-- Phân biệt với CitizenStatusTypes nếu cần ngữ nghĩa khác
IF OBJECT_ID('Reference.CitizenDeathStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[CitizenDeathStatuses];
GO
PRINT N'  Creating table [Reference].[CitizenDeathStatuses]...';
CREATE TABLE [Reference].[CitizenDeathStatuses] (
    [citizen_death_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE, -- e.g., 'CONSống', 'DAMAT'
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[CitizenDeathStatuses] created.';
GO

-- Table: Reference.BloodTypes (Nhóm máu)
IF OBJECT_ID('Reference.BloodTypes', 'U') IS NOT NULL DROP TABLE [Reference].[BloodTypes];
GO
PRINT N'  Creating table [Reference].[BloodTypes]...';
CREATE TABLE [Reference].[BloodTypes] (
    [blood_type_id] SMALLINT PRIMARY KEY,
    [blood_type_code] VARCHAR(10) UNIQUE, -- e.g., 'A_PLUS', 'O_MINUS'
    [blood_type_name_vi] NVARCHAR(20) NOT NULL, -- e.g., 'A+', 'O-'
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[BloodTypes] created.';
GO

-- Table: Reference.IdentificationCardTypes (Loại thẻ CCCD/CMND)
IF OBJECT_ID('Reference.IdentificationCardTypes', 'U') IS NOT NULL DROP TABLE [Reference].[IdentificationCardTypes];
GO
PRINT N'  Creating table [Reference].[IdentificationCardTypes]...';
CREATE TABLE [Reference].[IdentificationCardTypes] (
    [card_type_id] SMALLINT PRIMARY KEY,
    [card_type_code] VARCHAR(20) UNIQUE, -- e.g., 'CMND9', 'CCCD_CHIP'
    [card_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[IdentificationCardTypes] created.';
GO

-- Table: Reference.IdentificationCardStatuses (Trạng thái thẻ CCCD/CMND)
IF OBJECT_ID('Reference.IdentificationCardStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[IdentificationCardStatuses];
GO
PRINT N'  Creating table [Reference].[IdentificationCardStatuses]...';
CREATE TABLE [Reference].[IdentificationCardStatuses] (
    [card_status_id] SMALLINT PRIMARY KEY,
    [card_status_code] VARCHAR(20) UNIQUE, -- e.g., 'DANGSUDUNG', 'HETHAN'
    [card_status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[IdentificationCardStatuses] created.';
GO

-- Table: Reference.ResidenceTypes (Loại cư trú: Thường trú, Tạm trú)
IF OBJECT_ID('Reference.ResidenceTypes', 'U') IS NOT NULL DROP TABLE [Reference].[ResidenceTypes];
GO
PRINT N'  Creating table [Reference].[ResidenceTypes]...';
CREATE TABLE [Reference].[ResidenceTypes] (
    [residence_type_id] SMALLINT PRIMARY KEY,
    [residence_type_code] VARCHAR(20) UNIQUE, -- e.g., 'THUONGTRU', 'TAMTRU'
    [residence_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[ResidenceTypes] created.';
GO

-- Table: Reference.ResidenceRegistrationStatuses (Trạng thái đăng ký cư trú)
IF OBJECT_ID('Reference.ResidenceRegistrationStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[ResidenceRegistrationStatuses];
GO
PRINT N'  Creating table [Reference].[ResidenceRegistrationStatuses]...';
CREATE TABLE [Reference].[ResidenceRegistrationStatuses] (
    [res_reg_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE, -- e.g., 'ACTIVE', 'EXPIRED'
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[ResidenceRegistrationStatuses] created.';
GO

-- Table: Reference.TemporaryAbsenceStatuses (Trạng thái tạm vắng)
IF OBJECT_ID('Reference.TemporaryAbsenceStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[TemporaryAbsenceStatuses];
GO
PRINT N'  Creating table [Reference].[TemporaryAbsenceStatuses]...';
CREATE TABLE [Reference].[TemporaryAbsenceStatuses] (
    [temp_abs_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE, -- e.g., 'ACTIVE', 'RETURNED'
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[TemporaryAbsenceStatuses] created.';
GO

-- Table: Reference.DataSensitivityLevels (Mức độ nhạy cảm dữ liệu)
IF OBJECT_ID('Reference.DataSensitivityLevels', 'U') IS NOT NULL DROP TABLE [Reference].[DataSensitivityLevels];
GO
PRINT N'  Creating table [Reference].[DataSensitivityLevels]...';
CREATE TABLE [Reference].[DataSensitivityLevels] (
    [sensitivity_level_id] SMALLINT PRIMARY KEY,
    [level_code] VARCHAR(20) UNIQUE, -- e.g., 'CONGKHAI', 'BAOMAT'
    [level_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[DataSensitivityLevels] created.';
GO

-- Table: Reference.CitizenStatusTypes (Loại trạng thái công dân trong bảng CitizenStatus)
IF OBJECT_ID('Reference.CitizenStatusTypes', 'U') IS NOT NULL DROP TABLE [Reference].[CitizenStatusTypes];
GO
PRINT N'  Creating table [Reference].[CitizenStatusTypes]...';
CREATE TABLE [Reference].[CitizenStatusTypes] (
    [citizen_status_type_id] SMALLINT PRIMARY KEY,
    [status_type_code] VARCHAR(20) UNIQUE, -- e.g., 'CONSống', 'MATTICH'
    [status_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[CitizenStatusTypes] created.';
GO

-- Table: Reference.CitizenMovementTypes (Loại di biến động dân cư)
IF OBJECT_ID('Reference.CitizenMovementTypes', 'U') IS NOT NULL DROP TABLE [Reference].[CitizenMovementTypes];
GO
PRINT N'  Creating table [Reference].[CitizenMovementTypes]...';
CREATE TABLE [Reference].[CitizenMovementTypes] (
    [movement_type_id] SMALLINT PRIMARY KEY,
    [movement_type_code] VARCHAR(20) UNIQUE, -- e.g., 'TRONGNUOC', 'XUATCANH'
    [movement_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[CitizenMovementTypes] created.';
GO

-- Table: Reference.CitizenMovementStatuses (Trạng thái di biến động dân cư)
IF OBJECT_ID('Reference.CitizenMovementStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[CitizenMovementStatuses];
GO
PRINT N'  Creating table [Reference].[CitizenMovementStatuses]...';
CREATE TABLE [Reference].[CitizenMovementStatuses] (
    [movement_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE, -- e.g., 'HOATDONG', 'HOANTHANH'
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[CitizenMovementStatuses] created.';
GO

-- Table: Reference.CrimeTypes (Loại tội phạm)
IF OBJECT_ID('Reference.CrimeTypes', 'U') IS NOT NULL DROP TABLE [Reference].[CrimeTypes];
GO
PRINT N'  Creating table [Reference].[CrimeTypes]...';
CREATE TABLE [Reference].[CrimeTypes] (
    [crime_type_id] INT PRIMARY KEY,
    [crime_type_code] VARCHAR(50) UNIQUE, -- e.g., 'VPHC', 'TPNGHIEMTRONG'
    [crime_type_name_vi] NVARCHAR(150) NOT NULL,
    [description_vi] NVARCHAR(500) NULL,
    [severity_level] SMALLINT NULL, -- Mức độ nghiêm trọng (nếu có thể đánh số)
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[CrimeTypes] created.';
GO

-- Table: Reference.AddressTypes (Loại địa chỉ trong BCA.CitizenAddress)
IF OBJECT_ID('Reference.AddressTypes', 'U') IS NOT NULL DROP TABLE [Reference].[AddressTypes];
GO
PRINT N'  Creating table [Reference].[AddressTypes]...';
CREATE TABLE [Reference].[AddressTypes] (
    [address_type_id] SMALLINT PRIMARY KEY,
    [address_type_code] VARCHAR(20) UNIQUE, -- e.g., 'THUONGTRU', 'NOIOHIENTAI'
    [address_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[AddressTypes] created.';
GO


--------------------------------------------------------------------------------
-- Lookup Tables from DB_BTP CHECK constraints
--------------------------------------------------------------------------------

-- Table: Reference.HouseholdTypes (Loại hộ khẩu)
IF OBJECT_ID('Reference.HouseholdTypes', 'U') IS NOT NULL DROP TABLE [Reference].[HouseholdTypes];
GO
PRINT N'  Creating table [Reference].[HouseholdTypes]...';
CREATE TABLE [Reference].[HouseholdTypes] (
    [household_type_id] SMALLINT PRIMARY KEY,
    [household_type_code] VARCHAR(20) UNIQUE, -- e.g., 'HOGIADINH', 'HOTAPTHE'
    [household_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[HouseholdTypes] created.';
GO

-- Table: Reference.HouseholdStatuses (Trạng thái hộ khẩu)
IF OBJECT_ID('Reference.HouseholdStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[HouseholdStatuses];
GO
PRINT N'  Creating table [Reference].[HouseholdStatuses]...';
CREATE TABLE [Reference].[HouseholdStatuses] (
    [household_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(30) UNIQUE, -- e.g., 'DANGHOATDONG', 'DACHUYENDI'
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[HouseholdStatuses] created.';
GO

-- Table: Reference.RelationshipWithHeadTypes (Quan hệ với chủ hộ)
-- Có thể trùng với RelationshipTypes hoặc chi tiết hơn cho nghiệp vụ hộ khẩu
IF OBJECT_ID('Reference.RelationshipWithHeadTypes', 'U') IS NOT NULL DROP TABLE [Reference].[RelationshipWithHeadTypes];
GO
PRINT N'  Creating table [Reference].[RelationshipWithHeadTypes]...';
CREATE TABLE [Reference].[RelationshipWithHeadTypes] (
    [rel_with_head_id] SMALLINT PRIMARY KEY,
    [rel_code] VARCHAR(30) UNIQUE, -- e.g., 'CHUHO', 'VO', 'CONDE'
    [rel_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[RelationshipWithHeadTypes] created.';
GO

-- Table: Reference.HouseholdMemberStatuses (Trạng thái thành viên hộ)
IF OBJECT_ID('Reference.HouseholdMemberStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[HouseholdMemberStatuses];
GO
PRINT N'  Creating table [Reference].[HouseholdMemberStatuses]...';
CREATE TABLE [Reference].[HouseholdMemberStatuses] (
    [member_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE, -- e.g., 'ACTIVE', 'LEFT', 'DECEASED'
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[HouseholdMemberStatuses] created.';
GO

-- Table: Reference.FamilyRelationshipStatuses (Trạng thái quan hệ gia đình trong BTP.FamilyRelationship)
IF OBJECT_ID('Reference.FamilyRelationshipStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[FamilyRelationshipStatuses];
GO
PRINT N'  Creating table [Reference].[FamilyRelationshipStatuses]...';
CREATE TABLE [Reference].[FamilyRelationshipStatuses] (
    [family_rel_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE, -- e.g., 'ACTIVE', 'INACTIVE'
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[FamilyRelationshipStatuses] created.';
GO

-- Table: Reference.PopulationChangeTypes (Loại thay đổi dân số)
IF OBJECT_ID('Reference.PopulationChangeTypes', 'U') IS NOT NULL DROP TABLE [Reference].[PopulationChangeTypes];
GO
PRINT N'  Creating table [Reference].[PopulationChangeTypes]...';
CREATE TABLE [Reference].[PopulationChangeTypes] (
    [pop_change_type_id] INT PRIMARY KEY,
    [change_type_code] VARCHAR(50) UNIQUE, -- e.g., 'DK_KHAISINH', 'DK_KETHON'
    [change_type_name_vi] NVARCHAR(150) NOT NULL,
    [description_vi] NVARCHAR(500) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
PRINT N'  Table [Reference].[PopulationChangeTypes] created.';
GO
PRINT N'Finished creating all table structures in DB_Reference.Reference schema.';
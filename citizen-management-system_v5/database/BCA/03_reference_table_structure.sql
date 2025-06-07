-- Script để tạo cấu trúc các bảng tham chiếu (Reference) cho DB_BCA
-- Các bảng được phân nhóm theo chức năng và đã được cải tiến để tối ưu

USE [DB_BCA];
GO

PRINT N'Creating improved reference tables in DB_BCA.Reference schema...';

--------------------------------------------------------------------------------
-- I. BẢNG ĐỊA LÝ HÀNH CHÍNH
--------------------------------------------------------------------------------

-- 1. Reference.Regions (Vùng/Miền địa lý)
-- Mô tả: Lưu trữ thông tin về các vùng miền địa lý của Việt Nam
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

-- 2. Reference.Provinces (Tỉnh/Thành phố trực thuộc trung ương)
-- Mô tả: Lưu trữ thông tin về các tỉnh/thành phố trực thuộc trung ương
IF OBJECT_ID('Reference.Provinces', 'U') IS NOT NULL DROP TABLE [Reference].[Provinces];
GO
CREATE TABLE [Reference].[Provinces] (
    [province_id] INT PRIMARY KEY,
    [province_code] VARCHAR(10) NOT NULL UNIQUE,
    [province_name] NVARCHAR(100) NOT NULL,
    [region_id] SMALLINT NULL,                      -- FK to Reference.Regions
    [administrative_unit_id] SMALLINT NULL,         -- ID đơn vị hành chính
    [administrative_region_id] SMALLINT NULL,       -- ID vùng hành chính theo GSO
    [area] DECIMAL(10,2) NULL,                      -- Diện tích (km2)
    [population] INT NULL,                          -- Dân số
    [gso_code] VARCHAR(10) NULL UNIQUE,             -- Mã tỉnh/thành theo Tổng cục Thống kê
    [is_city] BIT DEFAULT 0,                        -- Cờ đánh dấu là TP trực thuộc TW (1) hay tỉnh (0)
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 3. Reference.Districts (Quận/Huyện/Thị xã/Thành phố thuộc tỉnh)
-- Mô tả: Lưu trữ thông tin về các đơn vị hành chính cấp quận/huyện
IF OBJECT_ID('Reference.Districts', 'U') IS NOT NULL DROP TABLE [Reference].[Districts];
GO
CREATE TABLE [Reference].[Districts] (
    [district_id] INT PRIMARY KEY,
    [district_code] VARCHAR(10) NOT NULL UNIQUE,
    [district_name] NVARCHAR(100) NOT NULL,
    [province_id] INT NOT NULL,                     -- FK to Reference.Provinces
    [administrative_unit_id] SMALLINT NULL,         -- ID loại đơn vị hành chính
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL UNIQUE,             -- Mã quận/huyện theo GSO
    [is_urban] BIT DEFAULT 0,                       -- Cờ đánh dấu là đô thị
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 4. Reference.Wards (Phường/Xã/Thị trấn)
-- Mô tả: Lưu trữ thông tin về các đơn vị hành chính cấp phường/xã
IF OBJECT_ID('Reference.Wards', 'U') IS NOT NULL DROP TABLE [Reference].[Wards];
GO
CREATE TABLE [Reference].[Wards] (
    [ward_id] INT PRIMARY KEY,
    [ward_code] VARCHAR(10) NOT NULL UNIQUE,
    [ward_name] NVARCHAR(100) NOT NULL,
    [district_id] INT NOT NULL,                     -- FK to Reference.Districts
    [administrative_unit_id] SMALLINT NULL,         -- ID loại đơn vị hành chính
    [area] DECIMAL(10,2) NULL,
    [population] INT NULL,
    [gso_code] VARCHAR(10) NULL UNIQUE,             -- Mã phường/xã theo GSO
    [is_urban] BIT DEFAULT 0,                       -- Cờ đánh dấu là đô thị
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- II. BẢNG NHÂN KHẨU HỌC
--------------------------------------------------------------------------------

-- 5. Reference.Ethnicities (Dân tộc)
-- Mô tả: Lưu trữ danh sách các dân tộc Việt Nam
IF OBJECT_ID('Reference.Ethnicities', 'U') IS NOT NULL DROP TABLE [Reference].[Ethnicities];
GO
CREATE TABLE [Reference].[Ethnicities] (
    [ethnicity_id] SMALLINT PRIMARY KEY,
    [ethnicity_code] VARCHAR(10) NOT NULL UNIQUE,
    [ethnicity_name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [population] INT NULL,                          -- Dân số tham khảo
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 6. Reference.Religions (Tôn giáo)
-- Mô tả: Lưu trữ danh sách các tôn giáo được công nhận hoặc phổ biến
IF OBJECT_ID('Reference.Religions', 'U') IS NOT NULL DROP TABLE [Reference].[Religions];
GO
CREATE TABLE [Reference].[Religions] (
    [religion_id] SMALLINT PRIMARY KEY,
    [religion_code] VARCHAR(10) NOT NULL UNIQUE,
    [religion_name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [followers] INT NULL,                           -- Số lượng tín đồ tham khảo
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 7. Reference.Nationalities (Quốc tịch)
-- Mô tả: Lưu trữ danh sách các quốc tịch
IF OBJECT_ID('Reference.Nationalities', 'U') IS NOT NULL DROP TABLE [Reference].[Nationalities];
GO
CREATE TABLE [Reference].[Nationalities] (
    [nationality_id] SMALLINT PRIMARY KEY,
    [nationality_code] VARCHAR(10) NOT NULL UNIQUE,
    [iso_code_alpha2] VARCHAR(2) NULL UNIQUE,       -- Mã ISO 3166-1 alpha-2
    [iso_code_alpha3] VARCHAR(3) NULL UNIQUE,       -- Mã ISO 3166-1 alpha-3
    [nationality_name] NVARCHAR(100) NOT NULL,
    [country_name] NVARCHAR(100) NOT NULL,          -- Tên quốc gia tương ứng
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 8. Reference.Occupations (Nghề nghiệp)
-- Mô tả: Lưu trữ danh mục các ngành nghề
IF OBJECT_ID('Reference.Occupations', 'U') IS NOT NULL DROP TABLE [Reference].[Occupations];
GO
CREATE TABLE [Reference].[Occupations] (
    [occupation_id] INT PRIMARY KEY,
    [occupation_code] VARCHAR(20) NOT NULL UNIQUE,
    [occupation_name] NVARCHAR(255) NOT NULL,
    [occupation_group_id] INT NULL,                 -- ID nhóm nghề (tự tham chiếu)
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- III. BẢNG THÔNG TIN CÁ NHÂN
--------------------------------------------------------------------------------

-- 9. Reference.Genders (Giới tính)
-- Mô tả: Danh mục giới tính
IF OBJECT_ID('Reference.Genders', 'U') IS NOT NULL DROP TABLE [Reference].[Genders];
GO
CREATE TABLE [Reference].[Genders] (
    [gender_id] SMALLINT PRIMARY KEY,
    [gender_code] VARCHAR(10) UNIQUE,
    [gender_name_vi] NVARCHAR(20) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 10. Reference.MaritalStatuses (Tình trạng hôn nhân)
-- Mô tả: Danh mục các trạng thái hôn nhân
IF OBJECT_ID('Reference.MaritalStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[MaritalStatuses];
GO
CREATE TABLE [Reference].[MaritalStatuses] (
    [marital_status_id] SMALLINT PRIMARY KEY,
    [marital_status_code] VARCHAR(20) UNIQUE,
    [marital_status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 11. Reference.EducationLevels (Trình độ học vấn)
-- Mô tả: Danh mục các trình độ học vấn
IF OBJECT_ID('Reference.EducationLevels', 'U') IS NOT NULL DROP TABLE [Reference].[EducationLevels];
GO
CREATE TABLE [Reference].[EducationLevels] (
    [education_level_id] SMALLINT PRIMARY KEY,
    [education_level_code] VARCHAR(30) UNIQUE,
    [education_level_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 12. Reference.BloodTypes (Nhóm máu)
-- Mô tả: Danh mục các nhóm máu
IF OBJECT_ID('Reference.BloodTypes', 'U') IS NOT NULL DROP TABLE [Reference].[BloodTypes];
GO
CREATE TABLE [Reference].[BloodTypes] (
    [blood_type_id] SMALLINT PRIMARY KEY,
    [blood_type_code] VARCHAR(10) UNIQUE,
    [blood_type_name_vi] NVARCHAR(20) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- IV. BẢNG CƠ QUAN VÀ TỔ CHỨC
--------------------------------------------------------------------------------

-- 13. Reference.Authorities (Cơ quan có thẩm quyền/Đơn vị cấp phát)
-- Mô tả: Lưu trữ thông tin về các cơ quan, đơn vị có thẩm quyền
IF OBJECT_ID('Reference.Authorities', 'U') IS NOT NULL DROP TABLE [Reference].[Authorities];
GO
CREATE TABLE [Reference].[Authorities] (
    [authority_id] INT PRIMARY KEY,
    [authority_code] VARCHAR(30) NOT NULL UNIQUE,
    [authority_name] NVARCHAR(255) NOT NULL,
    [authority_type] NVARCHAR(100) NOT NULL,        -- Loại cơ quan
    [address_detail] NVARCHAR(MAX) NULL,
    [ward_id] INT NULL,                             -- FK to Reference.Wards
    [district_id] INT NULL,                         -- FK to Reference.Districts
    [province_id] INT NULL,                         -- FK to Reference.Provinces
    [phone] VARCHAR(50) NULL,
    [email] VARCHAR(100) NULL,
    [website] VARCHAR(255) NULL,
    [parent_authority_id] INT NULL,                 -- Tự tham chiếu phân cấp
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 14. Reference.PrisonFacilities (Cơ sở giam giữ)
-- Mô tả: Lưu trữ thông tin về các trại giam, cơ sở giáo dục bắt buộc
IF OBJECT_ID('Reference.PrisonFacilities', 'U') IS NOT NULL DROP TABLE [Reference].[PrisonFacilities];
GO
CREATE TABLE [Reference].[PrisonFacilities] (
    [prison_facility_id] INT IDENTITY(1,1) PRIMARY KEY,
    [facility_code] VARCHAR(30) NULL UNIQUE,
    [facility_name] NVARCHAR(255) NOT NULL,
    [facility_type] NVARCHAR(100) NULL,             -- Loại cơ sở
    [address_detail] NVARCHAR(MAX) NULL,
    [ward_id] INT NULL,                             -- FK to Reference.Wards
    [district_id] INT NULL,                         -- FK to Reference.Districts
    [province_id] INT NOT NULL,                     -- FK to Reference.Provinces
    [capacity] INT NULL,                            -- Sức chứa
    [managing_authority_id] INT NULL,               -- FK to Reference.Authorities
    [phone_number] VARCHAR(50) NULL,
    [is_active] BIT DEFAULT 1,
    [notes] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- V. BẢNG GIẤY TỜ VÀ TÀI LIỆU
--------------------------------------------------------------------------------

-- 15. Reference.DocumentTypes (Loại giấy tờ) - BẢNG MỚI
-- Mô tả: Danh mục các loại giấy tờ sử dụng trong di chuyển, thủ tục pháp lý
IF OBJECT_ID('Reference.DocumentTypes', 'U') IS NOT NULL DROP TABLE [Reference].[DocumentTypes];
GO
CREATE TABLE [Reference].[DocumentTypes] (
    [document_type_id] SMALLINT PRIMARY KEY,
    [document_type_code] VARCHAR(20) UNIQUE,
    [document_type_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 16. Reference.IdentificationCardTypes (Loại thẻ CCCD/CMND)
-- Mô tả: Danh mục các loại thẻ căn cước, chứng minh nhân dân
IF OBJECT_ID('Reference.IdentificationCardTypes', 'U') IS NOT NULL DROP TABLE [Reference].[IdentificationCardTypes];
GO
CREATE TABLE [Reference].[IdentificationCardTypes] (
    [card_type_id] SMALLINT PRIMARY KEY,
    [card_type_code] VARCHAR(20) UNIQUE,
    [card_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 17. Reference.IdentificationCardStatuses (Trạng thái thẻ CCCD/CMND)
-- Mô tả: Danh mục các trạng thái của thẻ căn cước, chứng minh nhân dân
IF OBJECT_ID('Reference.IdentificationCardStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[IdentificationCardStatuses];
GO
CREATE TABLE [Reference].[IdentificationCardStatuses] (
    [card_status_id] SMALLINT PRIMARY KEY,
    [card_status_code] VARCHAR(20) UNIQUE,
    [card_status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- VI. BẢNG CƯ TRÚ VÀ DI CHUYỂN
--------------------------------------------------------------------------------

-- 18. Reference.ResidenceTypes (Loại cư trú)
-- Mô tả: Danh mục các loại hình cư trú (thường trú, tạm trú)
IF OBJECT_ID('Reference.ResidenceTypes', 'U') IS NOT NULL DROP TABLE [Reference].[ResidenceTypes];
GO
CREATE TABLE [Reference].[ResidenceTypes] (
    [residence_type_id] SMALLINT PRIMARY KEY,
    [residence_type_code] VARCHAR(20) UNIQUE,
    [residence_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 19. Reference.ResidenceRegistrationStatuses (Trạng thái đăng ký cư trú)
-- Mô tả: Danh mục các trạng thái đăng ký cư trú
IF OBJECT_ID('Reference.ResidenceRegistrationStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[ResidenceRegistrationStatuses];
GO
CREATE TABLE [Reference].[ResidenceRegistrationStatuses] (
    [res_reg_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 20. Reference.TemporaryAbsenceStatuses (Trạng thái tạm vắng)
-- Mô tả: Danh mục các trạng thái tạm vắng
IF OBJECT_ID('Reference.TemporaryAbsenceStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[TemporaryAbsenceStatuses];
GO
CREATE TABLE [Reference].[TemporaryAbsenceStatuses] (
    [temp_abs_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 21. Reference.CitizenMovementTypes (Loại di biến động dân cư)
-- Mô tả: Danh mục các loại di chuyển dân cư
IF OBJECT_ID('Reference.CitizenMovementTypes', 'U') IS NOT NULL DROP TABLE [Reference].[CitizenMovementTypes];
GO
CREATE TABLE [Reference].[CitizenMovementTypes] (
    [movement_type_id] SMALLINT PRIMARY KEY,
    [movement_type_code] VARCHAR(20) UNIQUE,
    [movement_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 22. Reference.CitizenMovementStatuses (Trạng thái di biến động dân cư)
-- Mô tả: Danh mục các trạng thái của di chuyển dân cư
IF OBJECT_ID('Reference.CitizenMovementStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[CitizenMovementStatuses];
GO
CREATE TABLE [Reference].[CitizenMovementStatuses] (
    [movement_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 23. Reference.AddressTypes (Loại địa chỉ)
-- Mô tả: Danh mục các loại địa chỉ
IF OBJECT_ID('Reference.AddressTypes', 'U') IS NOT NULL DROP TABLE [Reference].[AddressTypes];
GO
CREATE TABLE [Reference].[AddressTypes] (
    [address_type_id] SMALLINT PRIMARY KEY,
    [address_type_code] VARCHAR(20) UNIQUE,
    [address_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- VII. BẢNG TRẠNG THÁI CÔNG DÂN
--------------------------------------------------------------------------------

-- 24. Reference.CitizenStatusTypes (Loại trạng thái công dân) - CẢI TIẾN
-- Mô tả: Danh mục các trạng thái của công dân (đã hợp nhất với CitizenDeathStatuses)
IF OBJECT_ID('Reference.CitizenStatusTypes', 'U') IS NOT NULL DROP TABLE [Reference].[CitizenStatusTypes];
GO
CREATE TABLE [Reference].[CitizenStatusTypes] (
    [citizen_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [affects_death_status] BIT DEFAULT 0,           -- Cờ đánh dấu ảnh hưởng đến trạng thái sống/chết
    [requires_cause] BIT DEFAULT 0,                 -- Cờ đánh dấu yêu cầu lý do
    [requires_location] BIT DEFAULT 0,              -- Cờ đánh dấu yêu cầu địa điểm
    [requires_document] BIT DEFAULT 0,              -- Cờ đánh dấu yêu cầu giấy tờ chứng minh
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- VIII. BẢNG QUAN HỆ
--------------------------------------------------------------------------------

-- 25. Reference.RelationshipTypes (Loại quan hệ gia đình/thân nhân)
-- Mô tả: Định nghĩa các loại mối quan hệ (Cha-Con, Vợ-Chồng)
IF OBJECT_ID('Reference.RelationshipTypes', 'U') IS NOT NULL DROP TABLE [Reference].[RelationshipTypes];
GO
CREATE TABLE [Reference].[RelationshipTypes] (
    [relationship_type_id] SMALLINT PRIMARY KEY,
    [relationship_code] VARCHAR(20) NOT NULL UNIQUE,
    [relationship_name] NVARCHAR(100) NOT NULL,
    [inverse_relationship_type_id] SMALLINT NULL,   -- Tự tham chiếu đến quan hệ đối ứng
    [description] NVARCHAR(MAX) NULL,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 26. Reference.RelationshipWithHeadTypes (Quan hệ với chủ hộ)
-- Mô tả: Danh mục các loại quan hệ với chủ hộ trong hộ khẩu
IF OBJECT_ID('Reference.RelationshipWithHeadTypes', 'U') IS NOT NULL DROP TABLE [Reference].[RelationshipWithHeadTypes];
GO
CREATE TABLE [Reference].[RelationshipWithHeadTypes] (
    [rel_with_head_id] SMALLINT PRIMARY KEY,
    [rel_code] VARCHAR(30) UNIQUE,
    [rel_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- IX. BẢNG HỘ KHẨU
--------------------------------------------------------------------------------

-- 27. Reference.HouseholdTypes (Loại hộ khẩu)
-- Mô tả: Danh mục các loại hộ khẩu
IF OBJECT_ID('Reference.HouseholdTypes', 'U') IS NOT NULL DROP TABLE [Reference].[HouseholdTypes];
GO
CREATE TABLE [Reference].[HouseholdTypes] (
    [household_type_id] SMALLINT PRIMARY KEY,
    [household_type_code] VARCHAR(20) UNIQUE,
    [household_type_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 28. Reference.HouseholdStatuses (Trạng thái hộ khẩu)
-- Mô tả: Danh mục các trạng thái của hộ khẩu
IF OBJECT_ID('Reference.HouseholdStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[HouseholdStatuses];
GO
CREATE TABLE [Reference].[HouseholdStatuses] (
    [household_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(30) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 29. Reference.HouseholdMemberStatuses (Trạng thái thành viên hộ)
-- Mô tả: Danh mục các trạng thái của thành viên trong hộ khẩu
IF OBJECT_ID('Reference.HouseholdMemberStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[HouseholdMemberStatuses];
GO
CREATE TABLE [Reference].[HouseholdMemberStatuses] (
    [member_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 30. Reference.FamilyRelationshipStatuses (Trạng thái quan hệ gia đình)
-- Mô tả: Danh mục các trạng thái của quan hệ gia đình trong BTP.FamilyRelationship
IF OBJECT_ID('Reference.FamilyRelationshipStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[FamilyRelationshipStatuses];
GO
CREATE TABLE [Reference].[FamilyRelationshipStatuses] (
    [family_rel_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- X. BẢNG AN NINH VÀ PHÁP LÝ
--------------------------------------------------------------------------------

-- 31. Reference.CrimeTypes (Loại tội phạm)
-- Mô tả: Danh mục các loại tội phạm
IF OBJECT_ID('Reference.CrimeTypes', 'U') IS NOT NULL DROP TABLE [Reference].[CrimeTypes];
GO
CREATE TABLE [Reference].[CrimeTypes] (
    [crime_type_id] INT PRIMARY KEY,
    [crime_type_code] VARCHAR(50) UNIQUE,
    [crime_type_name_vi] NVARCHAR(150) NOT NULL,
    [description_vi] NVARCHAR(500) NULL,
    [severity_level] SMALLINT NULL,                 -- Mức độ nghiêm trọng
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 32. Reference.ExecutionStatuses (Trạng thái thi hành án) - BẢNG MỚI
-- Mô tả: Danh mục các trạng thái chấp hành án phạt/quyết định
IF OBJECT_ID('Reference.ExecutionStatuses', 'U') IS NOT NULL DROP TABLE [Reference].[ExecutionStatuses];
GO
CREATE TABLE [Reference].[ExecutionStatuses] (
    [execution_status_id] SMALLINT PRIMARY KEY,
    [status_code] VARCHAR(20) UNIQUE,
    [status_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- 33. Reference.DataSensitivityLevels (Mức độ nhạy cảm dữ liệu)
-- Mô tả: Danh mục các mức độ nhạy cảm của dữ liệu
IF OBJECT_ID('Reference.DataSensitivityLevels', 'U') IS NOT NULL DROP TABLE [Reference].[DataSensitivityLevels];
GO
CREATE TABLE [Reference].[DataSensitivityLevels] (
    [sensitivity_level_id] SMALLINT PRIMARY KEY,
    [level_code] VARCHAR(20) UNIQUE,
    [level_name_vi] NVARCHAR(50) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- XI. BẢNG DÂN SỐ
--------------------------------------------------------------------------------

-- 34. Reference.PopulationChangeTypes (Loại thay đổi dân số)
-- Mô tả: Danh mục các loại thay đổi dân số dùng cho BTP.PopulationChange
IF OBJECT_ID('Reference.PopulationChangeTypes', 'U') IS NOT NULL DROP TABLE [Reference].[PopulationChangeTypes];
GO
CREATE TABLE [Reference].[PopulationChangeTypes] (
    [pop_change_type_id] INT PRIMARY KEY,
    [change_type_code] VARCHAR(50) UNIQUE,
    [change_type_name_vi] NVARCHAR(150) NOT NULL,
    [description_vi] NVARCHAR(500) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

PRINT N'Finished creating improved reference tables in DB_BCA.Reference schema.';

-- Dữ liệu mẫu cho DocumentTypes và ExecutionStatuses
-- Chú ý: Đây chỉ là mẫu, có thể mở rộng và điều chỉnh

-- Dữ liệu mẫu cho DocumentTypes
PRINT N'  Thêm dữ liệu mẫu cho Reference.DocumentTypes...';
INSERT INTO [Reference].[DocumentTypes] ([document_type_id], [document_type_code], [document_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'CMND', N'Chứng minh nhân dân', N'Chứng minh nhân dân các loại', 1),
    (2, 'CCCD', N'Căn cước công dân', N'Căn cước công dân các loại', 2),
    (3, 'HOCHIEU', N'Hộ chiếu', N'Hộ chiếu thông thường, công vụ, ngoại giao', 3),
    (4, 'GIAYTOKHAC', N'Giấy tờ khác', N'Giấy tờ tùy thân khác có giá trị', 4),
    (5, 'VISA', N'Thị thực', N'Thị thực nhập cảnh', 5),
    (6, 'GIAYDITACH', N'Giấy phép đi lại biên giới', N'Giấy phép đi lại biên giới cho cư dân biên giới', 6),
    (7, 'XUATNHAPCANH', N'Giấy tờ xuất nhập cảnh', N'Các loại giấy tờ xuất nhập cảnh khác', 7),
    (8, 'GCN_QSDĐ', N'Giấy chứng nhận Quyền sử dụng đất', N'Giấy chứng nhận quyền sử dụng đất', 8),
    (9, 'GCN_SHNĐ', N'Giấy chứng nhận Quyền sở hữu nhà ở', N'Giấy chứng nhận quyền sở hữu nhà ở', 9),
    (10, 'GCN_QSDĐ_SHNĐ', N'GCN QSDĐ, QSHNƠ và TSTGLVĐ', N'Giấy chứng nhận quyền sử dụng đất, quyền sở hữu nhà ở và tài sản khác gắn liền với đất (Sổ hồng)', 10),
    (11, 'HD_MUABAN_BĐS', N'Hợp đồng mua bán bất động sản', N'Hợp đồng chuyển nhượng quyền sử dụng đất/sở hữu nhà', 11),
    (12, 'QD_THUAKE', N'Quyết định/Văn bản thừa kế', N'Quyết định/văn bản xác nhận quyền thừa kế', 12);
GO


-- Dữ liệu mẫu cho ExecutionStatuses
PRINT N'  Thêm dữ liệu mẫu cho Reference.ExecutionStatuses...';
INSERT INTO [Reference].[ExecutionStatuses] ([execution_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
VALUES
    (1, 'DANGCHAPHANH', N'Đang chấp hành', N'Đang chấp hành án phạt', 1),
    (2, 'DAHOANTHANH', N'Đã hoàn thành', N'Đã hoàn thành việc chấp hành án phạt', 2),
    (3, 'DUOCTHAMONG', N'Được giảm án/tha tù', N'Được giảm án hoặc tha tù trước thời hạn', 3),
    (4, 'DUOCHUONG_ANTREO', N'Được hưởng án treo', N'Được hưởng án treo', 4),
    (5, 'CHUACHAPHANH', N'Chưa chấp hành', N'Chưa bắt đầu chấp hành án phạt', 5),
    (6, 'BOPHU_KHAC', N'Chấp hành hình phạt bổ sung', N'Đang chấp hành hình phạt bổ sung', 6),
    (7, 'TRON_HANH', N'Bỏ trốn', N'Bỏ trốn khỏi nơi chấp hành án', 7),
    (8, 'DUOC_DAOTAO', N'Giáo dục cải tạo', N'Đang được giáo dục cải tạo', 8),
    (9, 'HOANTHI_HANH', N'Tạm hoãn thi hành án', N'Được tạm hoãn chấp hành án', 9);
GO


-- Mô tả: Danh mục các loại giao dịch liên quan đến quyền sở hữu tài sản
IF OBJECT_ID('Reference.TransactionTypes', 'U') IS NOT NULL DROP TABLE [Reference].[TransactionTypes];
GO
CREATE TABLE [Reference].[TransactionTypes] (
    [transaction_type_id] SMALLINT PRIMARY KEY,
    [type_code] VARCHAR(50) UNIQUE,
    [type_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO


-- Reference.AccommodationFacilityTypes (Loại cơ sở lưu trú đặc biệt)
IF OBJECT_ID('Reference.AccommodationFacilityTypes', 'U') IS NOT NULL DROP TABLE [Reference].[AccommodationFacilityTypes];
GO
CREATE TABLE [Reference].[AccommodationFacilityTypes] (
    [facility_type_id] SMALLINT PRIMARY KEY,
    [type_code] VARCHAR(50) UNIQUE,
    [type_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO


-- Reference.VehicleTypes (Loại phương tiện)
IF OBJECT_ID('Reference.VehicleTypes', 'U') IS NOT NULL DROP TABLE [Reference].[VehicleTypes];
GO
CREATE TABLE [Reference].[VehicleTypes] (
    [vehicle_type_id] SMALLINT PRIMARY KEY,
    [type_code] VARCHAR(50) UNIQUE,
    [type_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Reference.TemporaryAbsenceTypes (Loại tạm vắng)
IF OBJECT_ID('Reference.TemporaryAbsenceTypes', 'U') IS NOT NULL DROP TABLE [Reference].[TemporaryAbsenceTypes];
GO
CREATE TABLE [Reference].[TemporaryAbsenceTypes] (
    [temp_abs_type_id] SMALLINT PRIMARY KEY,
    [type_code] VARCHAR(50) UNIQUE,
    [type_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Reference.ResidenceStatusChangeReasons (Lý do thay đổi trạng thái cư trú)
IF OBJECT_ID('Reference.ResidenceStatusChangeReasons', 'U') IS NOT NULL DROP TABLE [Reference].[ResidenceStatusChangeReasons];
GO
CREATE TABLE [Reference].[ResidenceStatusChangeReasons] (
    [reason_id] SMALLINT PRIMARY KEY,
    [reason_code] VARCHAR(50) UNIQUE,
    [reason_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO

-- Reference.ContractTypes (Loại hợp đồng thuê/mượn/ở nhờ)
IF OBJECT_ID('Reference.ContractTypes', 'U') IS NOT NULL DROP TABLE [Reference].[ContractTypes];
GO
CREATE TABLE [Reference].[ContractTypes] (
    [contract_type_id] SMALLINT PRIMARY KEY,
    [type_code] VARCHAR(50) UNIQUE,
    [type_name_vi] NVARCHAR(100) NOT NULL,
    [description_vi] NVARCHAR(255) NULL,
    [display_order] SMALLINT DEFAULT 0,
    [is_active] BIT DEFAULT 1,
    [created_at] DATETIME2(7) DEFAULT GETDATE(),
    [updated_at] DATETIME2(7) DEFAULT GETDATE()
);
GO
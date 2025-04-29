-- =========================================================================
-- Sample Data Insertion Script for Reference Tables
-- Ensures necessary data for the 5-citizen sample exists.
-- =========================================================================

-- ==================================
-- ==      DATA FOR DB_BCA         ==
-- ==================================
USE [DB_BCA];
GO

-- Clear existing data (use DELETE for FK safety)
DELETE FROM [Reference].[Wards];
DELETE FROM [Reference].[Districts];
DELETE FROM [Reference].[Provinces];
DELETE FROM [Reference].[Regions];
DELETE FROM [Reference].[Authorities];
DELETE FROM [Reference].[Ethnicities];
DELETE FROM [Reference].[Nationalities];
DELETE FROM [Reference].[Occupations];
DELETE FROM [Reference].[Religions];
DELETE FROM [Reference].[RelationshipTypes]; -- Uncommented as table exists
DELETE FROM [Reference].[PrisonFacilities]; -- Uncommented as table exists
GO

-- Insert data into Reference.Regions
INSERT INTO [Reference].[Regions] ([region_id], [region_code], [region_name]) VALUES
(1, 'BAC', N'Miền Bắc');
GO

-- Insert data into Reference.Provinces
INSERT INTO [Reference].[Provinces] ([province_id], [province_code], [province_name], [region_id], [gso_code], [is_city], [administrative_unit_id]) VALUES
(1, 'HNO', N'Hà Nội', 1, '01', 1, 1);
GO

-- Insert data into Reference.Districts
INSERT INTO [Reference].[Districts] ([district_id], [district_code], [district_name], [province_id], [gso_code], [is_urban], [administrative_unit_id]) VALUES
(101, 'BAD', N'Ba Đình', 1, '001', 1, 1);
GO

-- Insert data into Reference.Wards
INSERT INTO [Reference].[Wards] ([ward_id], [ward_code], [ward_name], [district_id], [gso_code], [is_urban], [administrative_unit_id]) VALUES
(10101, 'PHUCXA', N'Phúc Xá', 101, '00001', 1, 5);
GO

-- Insert data into Reference.Ethnicities
INSERT INTO [Reference].[Ethnicities] ([ethnicity_id], [ethnicity_code], [ethnicity_name]) VALUES
(1, 'KINH', N'Kinh');
-- Add other ethnicities if needed
GO

-- Insert data into Reference.Religions
INSERT INTO [Reference].[Religions] ([religion_id], [religion_code], [religion_name]) VALUES
(9, 'NONE', N'Không tôn giáo');
-- Add other religions if needed
GO

-- Insert data into Reference.Nationalities
INSERT INTO [Reference].[Nationalities] ([nationality_id], [nationality_code], [iso_code_alpha3], [nationality_name], [country_name]) VALUES
(1, 'VN', 'VNM', N'Việt Nam', N'Cộng hòa Xã hội Chủ nghĩa Việt Nam');
-- Add other nationalities if needed
GO

-- Insert data into Reference.Occupations
INSERT INTO [Reference].[Occupations] ([occupation_id], [occupation_code], [occupation_name]) VALUES
(3, 'TECH', N'Kỹ thuật và công nghệ'),
(4, 'ADMN', N'Hành chính và văn phòng'),
(5, 'SERV', N'Dịch vụ và bán hàng'),
(7, 'PROD', N'Sản xuất và chế biến'),
(9, 'TRAN', N'Vận tải và logistics');
-- Add other occupations if needed
GO

-- Insert data into Reference.Authorities
-- Need parent authorities first
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [is_active]) VALUES
(1, 'BCA', N'Bộ Công an', N'Bộ', NULL, 1), -- Bộ Công An
(10, 'CATP-HN', N'Công an thành phố Hà Nội', N'Công an tỉnh/thành phố', 1, 1), -- CA TP Hà Nội
(20, 'STP-HN', N'Sở Tư pháp thành phố Hà Nội', N'Sở Tư pháp', 1, 1); -- Sở Tư Pháp HN

-- Authorities used in sample data
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [district_id], [parent_authority_id], [is_active]) VALUES
(100, 'CAQ-BD', N'Công an quận Ba Đình', N'Công an quận/huyện', 1, 101, 10, 1),
(150, 'PTP-BD', N'Phòng Tư pháp quận Ba Đình', N'Phòng Tư pháp', 1, 101, 20, 1);

-- Assuming authority_id 500 for CAP Phuc Xa
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [district_id], [ward_id], [parent_authority_id], [is_active]) VALUES
(500, 'CAP-PX', N'Công an phường Phúc Xá', N'Công an phường/xã', 1, 101, 10101, 100, 1);
GO


-- ==================================
-- ==      DATA FOR DB_BTP         ==
-- ==================================
USE [DB_BTP];
GO

-- Clear existing data (use DELETE for FK safety)
DELETE FROM [Reference].[Wards];
DELETE FROM [Reference].[Districts];
DELETE FROM [Reference].[Provinces];
DELETE FROM [Reference].[Regions];
DELETE FROM [Reference].[Authorities];
DELETE FROM [Reference].[Ethnicities];
DELETE FROM [Reference].[Nationalities];
DELETE FROM [Reference].[Occupations];
DELETE FROM [Reference].[Religions];
DELETE FROM [Reference].[RelationshipTypes]; -- Uncommented as table exists
DELETE FROM [Reference].[PrisonFacilities]; -- Uncommented as table exists
GO

-- Insert data into Reference.Regions
INSERT INTO [Reference].[Regions] ([region_id], [region_code], [region_name]) VALUES
(1, 'BAC', N'Miền Bắc');
GO

-- Insert data into Reference.Provinces
INSERT INTO [Reference].[Provinces] ([province_id], [province_code], [province_name], [region_id], [gso_code], [is_city], [administrative_unit_id]) VALUES
(1, 'HNO', N'Hà Nội', 1, '01', 1, 1);
GO

-- Insert data into Reference.Districts
INSERT INTO [Reference].[Districts] ([district_id], [district_code], [district_name], [province_id], [gso_code], [is_urban], [administrative_unit_id]) VALUES
(101, 'BAD', N'Ba Đình', 1, '001', 1, 1);
GO

-- Insert data into Reference.Wards
INSERT INTO [Reference].[Wards] ([ward_id], [ward_code], [ward_name], [district_id], [gso_code], [is_urban], [administrative_unit_id]) VALUES
(10101, 'PHUCXA', N'Phúc Xá', 101, '00001', 1, 5);
GO

-- Insert data into Reference.Ethnicities
INSERT INTO [Reference].[Ethnicities] ([ethnicity_id], [ethnicity_code], [ethnicity_name]) VALUES
(1, 'KINH', N'Kinh');
GO

-- Insert data into Reference.Religions
INSERT INTO [Reference].[Religions] ([religion_id], [religion_code], [religion_name]) VALUES
(9, 'NONE', N'Không tôn giáo');
GO

-- Insert data into Reference.Nationalities
INSERT INTO [Reference].[Nationalities] ([nationality_id], [nationality_code], [iso_code_alpha3], [nationality_name], [country_name]) VALUES
(1, 'VN', 'VNM', N'Việt Nam', N'Cộng hòa Xã hội Chủ nghĩa Việt Nam');
GO

-- Insert data into Reference.Occupations
INSERT INTO [Reference].[Occupations] ([occupation_id], [occupation_code], [occupation_name]) VALUES
(3, 'TECH', N'Kỹ thuật và công nghệ'),
(4, 'ADMN', N'Hành chính và văn phòng'),
(5, 'SERV', N'Dịch vụ và bán hàng'),
(7, 'PROD', N'Sản xuất và chế biến'),
(9, 'TRAN', N'Vận tải và logistics');
GO

-- Insert data into Reference.Authorities
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [is_active]) VALUES
(1, 'BCA', N'Bộ Công an', N'Bộ', NULL, 1),
(10, 'CATP-HN', N'Công an thành phố Hà Nội', N'Công an tỉnh/thành phố', 1, 1),
(20, 'STP-HN', N'Sở Tư pháp thành phố Hà Nội', N'Sở Tư pháp', 1, 1);

INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [district_id], [parent_authority_id], [is_active]) VALUES
(100, 'CAQ-BD', N'Công an quận Ba Đình', N'Công an quận/huyện', 1, 101, 10, 1),
(150, 'PTP-BD', N'Phòng Tư pháp quận Ba Đình', N'Phòng Tư pháp', 1, 101, 20, 1);

INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [district_id], [ward_id], [parent_authority_id], [is_active]) VALUES
(500, 'CAP-PX', N'Công an phường Phúc Xá', N'Công an phường/xã', 1, 101, 10101, 100, 1);
GO

PRINT 'Sample reference data insertion complete for both databases.';

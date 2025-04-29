-- Sample Data for DB_BCA and DB_BTP
-- This script creates reference data for both databases and sample citizens

-- Switch to DB_BCA first to add reference data
USE [DB_BCA];
GO

-- 1. REFERENCE DATA for DB_BCA
-- ===========================

-- Reference.Regions
INSERT INTO [Reference].[Regions] ([region_id], [region_code], [region_name], [description])
VALUES 
(1, 'MB', N'Miền Bắc', N'Khu vực phía bắc Việt Nam'),
(2, 'MT', N'Miền Trung', N'Khu vực miền trung Việt Nam'),
(3, 'MN', N'Miền Nam', N'Khu vực phía nam Việt Nam');
GO

-- Reference.Provinces
INSERT INTO [Reference].[Provinces] ([province_id], [province_code], [province_name], [region_id], [administrative_unit_id], [is_city], [area], [population])
VALUES
(1, 'HN', N'Hà Nội', 1, 1, 1, 3359.82, 8246500),
(2, 'HP', N'Hải Phòng', 1, 1, 1, 1562.10, 2013500),
(3, 'DN', N'Đà Nẵng', 2, 1, 1, 1285.76, 1142000),
(4, 'HCM', N'Hồ Chí Minh', 3, 1, 1, 2095.60, 9038000),
(5, 'CT', N'Cần Thơ', 3, 1, 1, 1409.00, 1235000);
GO

-- Reference.Districts
INSERT INTO [Reference].[Districts] ([district_id], [district_code], [district_name], [province_id], [administrative_unit_id], [is_urban], [area], [population])
VALUES
(1, 'HBT', N'Hai Bà Trưng', 1, 2, 1, 10.09, 318000),
(2, 'HD', N'Hải An', 2, 2, 1, 55.39, 147000),
(3, 'HC', N'Hải Châu', 3, 2, 1, 23.29, 197000),
(4, 'Q1', N'Quận 1', 4, 2, 1, 7.72, 142000),
(5, 'NK', N'Ninh Kiều', 5, 2, 1, 29.00, 280000);
GO

-- Reference.Wards
INSERT INTO [Reference].[Wards] ([ward_id], [ward_code], [ward_name], [district_id], [administrative_unit_id], [is_urban], [area], [population])
VALUES
(1, 'BTD', N'Bách Khoa', 1, 3, 1, 2.23, 25000),
(2, 'TC', N'Tràng Cát', 2, 3, 1, 11.61, 6300),
(3, 'TN', N'Thanh Bình', 3, 3, 1, 0.85, 18000),
(4, 'BN', N'Bến Nghé', 4, 3, 1, 2.73, 11500),
(5, 'TH', N'Tân Hiệp', 5, 3, 1, 11.32, 17500);
GO

-- Reference.Ethnicities
INSERT INTO [Reference].[Ethnicities] ([ethnicity_id], [ethnicity_code], [ethnicity_name], [description], [population])
VALUES
(1, 'KINH', N'Kinh', N'Dân tộc Kinh là dân tộc chiếm đa số ở Việt Nam', 86210000),
(2, 'TAY', N'Tày', N'Dân tộc Tày là dân tộc thiểu số lớn thứ hai tại Việt Nam', 1850000),
(3, 'THAI', N'Thái', N'Dân tộc Thái phân bố chủ yếu ở vùng Tây Bắc Việt Nam', 1820000),
(4, 'MUONG', N'Mường', N'Dân tộc Mường có nhiều nét văn hóa tương đồng với người Kinh', 1450000),
(5, 'HOA', N'Hoa', N'Người Hoa tại Việt Nam là cộng đồng người gốc Trung Quốc', 823000);
GO

-- Reference.Religions
INSERT INTO [Reference].[Religions] ([religion_id], [religion_code], [religion_name], [description], [followers])
VALUES
(1, 'NONE', N'Không', N'Không theo tôn giáo nào cụ thể', NULL),
(2, 'PHAT', N'Phật giáo', N'Tôn giáo dựa trên lời dạy của Đức Phật Thích Ca', 14000000),
(3, 'CONG', N'Công giáo', N'Nhánh lớn của Kitô giáo dưới sự lãnh đạo của Giáo hoàng', 7000000),
(4, 'CAO', N'Cao Đài', N'Tôn giáo bản địa của Việt Nam, kết hợp nhiều tín ngưỡng', 4500000),
(5, 'TIN', N'Tin Lành', N'Nhánh của Kitô giáo bắt nguồn từ phong trào Cải cách Tin Lành', 1500000);
GO

-- Reference.Nationalities
INSERT INTO [Reference].[Nationalities] ([nationality_id], [nationality_code], [iso_code_alpha2], [iso_code_alpha3], [nationality_name], [country_name])
VALUES
(1, 'VN', 'VN', 'VNM', N'Việt Nam', N'Việt Nam'),
(2, 'US', 'US', 'USA', N'Hoa Kỳ', N'Hợp chủng quốc Hoa Kỳ'),
(3, 'CN', 'CN', 'CHN', N'Trung Quốc', N'Cộng hòa Nhân dân Trung Hoa'),
(4, 'JP', 'JP', 'JPN', N'Nhật Bản', N'Nhật Bản'),
(5, 'KR', 'KR', 'KOR', N'Hàn Quốc', N'Đại Hàn Dân Quốc');
GO

-- Reference.Occupations
INSERT INTO [Reference].[Occupations] ([occupation_id], [occupation_code], [occupation_name], [description])
VALUES
(1, 'TEACHER', N'Giáo viên', N'Người làm công tác giảng dạy tại các cơ sở giáo dục'),
(2, 'ENGINEER', N'Kỹ sư', N'Người có chuyên môn kỹ thuật trong lĩnh vực công nghệ, xây dựng'),
(3, 'DOCTOR', N'Bác sĩ', N'Người hành nghề y, chữa bệnh cho bệnh nhân'),
(4, 'BUSINESS', N'Kinh doanh', N'Người làm việc trong lĩnh vực kinh doanh, thương mại'),
(5, 'FARMER', N'Nông dân', N'Người làm nông nghiệp');
GO

-- Reference.Authorities
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [district_id], [ward_id], [parent_authority_id], [address_detail], [phone], [email], [website])
VALUES
(1, 'BCA', N'Bộ Công an', N'Bộ', NULL, NULL, NULL, NULL, N'47 Phạm Văn Đồng, Cầu Giấy, Hà Nội', '02438226602', 'vanthu@mps.gov.vn', 'bocongan.gov.vn'),
(2, 'BTP', N'Bộ Tư pháp', N'Bộ', NULL, NULL, NULL, NULL, N'58-60 Trần Phú, Ba Đình, Hà Nội', '02437336213', 'btp@moj.gov.vn', 'moj.gov.vn'),
(3, 'CATP-HN', N'Công an thành phố Hà Nội', N'Công an cấp tỉnh', 1, NULL, NULL, 1, N'55 Lý Thường Kiệt, Hoàn Kiếm, Hà Nội', '02439428644', 'catp@hanoi.gov.vn', NULL),
(4, 'SOTP-HN', N'Sở Tư pháp Hà Nội', N'Sở', 1, NULL, NULL, 2, N'1B Trần Phú, Ba Đình, Hà Nội', '02438253491', 'vanthu_stp@hanoi.gov.vn', 'sotuphap.hanoi.gov.vn'),
(5, 'CAQHBT', N'Công an quận Hai Bà Trưng', N'Công an cấp huyện', 1, 1, NULL, 3, N'1 Đại Cồ Việt, Hai Bà Trưng, Hà Nội', '02438696969', 'caq.hbt@hanoi.gov.vn', NULL),
(6, 'CATP-HCM', N'Công an thành phố Hồ Chí Minh', N'Công an cấp tỉnh', 4, NULL, NULL, 1, N'268 Trần Hưng Đạo, Quận 1, TP.HCM', '02839203232', 'catp@tphcm.gov.vn', NULL),
(7, 'CATP-DN', N'Công an thành phố Đà Nẵng', N'Công an cấp tỉnh', 3, NULL, NULL, 1, N'47 Lý Tự Trọng, Hải Châu, Đà Nẵng', '02363822233', 'catp@danang.gov.vn', NULL);
GO

-- Reference.RelationshipTypes
INSERT INTO [Reference].[RelationshipTypes] ([relationship_type_id], [relationship_code], [relationship_name], [description])
VALUES
(1, 'SPOUSE', N'Vợ/Chồng', N'Mối quan hệ kết hôn hợp pháp'),
(2, 'FATHER', N'Cha', N'Mối quan hệ giữa cha và con'),
(3, 'MOTHER', N'Mẹ', N'Mối quan hệ giữa mẹ và con'),
(4, 'CHILD', N'Con', N'Mối quan hệ giữa con và cha/mẹ'),
(5, 'SIBLING', N'Anh/Chị/Em', N'Mối quan hệ anh chị em ruột');
GO

-- Now update inverse relationships
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 1 WHERE [relationship_type_id] = 1; -- Spouse is symmetric
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 4 WHERE [relationship_type_id] = 2; -- Father->Child
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 4 WHERE [relationship_type_id] = 3; -- Mother->Child
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 2 WHERE [relationship_type_id] = 4 AND [relationship_code] = 'CHILD'; -- Child->Father/Mother (simplified)
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 5 WHERE [relationship_type_id] = 5; -- Sibling is symmetric
GO

-- Reference.PrisonFacilities
INSERT INTO [Reference].[PrisonFacilities] ([facility_code], [facility_name], [facility_type], [province_id], [district_id], [ward_id], [address_detail], [capacity], [managing_authority_id])
VALUES
('PRISON-HN1', N'Trại giam Hoà Bình', N'Trại giam', 1, NULL, NULL, N'Xã Đông Xuân, Huyện Sóc Sơn, Hà Nội', 1500, 3),
('PRISON-HCM1', N'Trại giam Chí Hoà', N'Trại giam', 4, NULL, NULL, N'Quận 10, TP. Hồ Chí Minh', 2000, 6);
GO

-- 2. CITIZEN DATA for DB_BCA
-- ==========================

-- BCA.Citizen - 5 sample citizens
INSERT INTO [BCA].[Citizen] 
([citizen_id], [full_name], [date_of_birth], [gender], [birth_province_id], [birth_district_id], [birth_ward_id], 
[nationality_id], [ethnicity_id], [religion_id], [marital_status], [education_level], [occupation_id])
VALUES
('010203000001', N'Nguyễn Văn An', '1980-05-15', N'Nam', 1, 1, 1, 1, 1, 2, N'Đã kết hôn', N'Đại học', 2),
('010203000002', N'Trần Thị Bình', '1985-08-22', N'Nữ', 1, 1, 1, 1, 1, 1, N'Đã kết hôn', N'Đại học', 1),
('010203000003', N'Nguyễn Văn Cường', '2005-01-10', N'Nam', 1, 1, 1, 1, 1, 2, N'Độc thân', N'Trung học phổ thông', NULL),
('040201000001', N'Lê Thị Dung', '1990-12-05', N'Nữ', 4, 4, 4, 1, 1, 3, N'Độc thân', N'Cao đẳng', 4),
('040201000002', N'Trần Văn Eo', '1975-03-25', N'Nam', 4, 4, 4, 1, 5, 2, N'Đã ly hôn', N'Trung cấp', 2);
GO

-- Update family relationships
UPDATE [BCA].[Citizen] SET 
    [spouse_citizen_id] = '010203000002',
    [current_province_id] = 1,
    [current_district_id] = 1,
    [current_ward_id] = 1,
    [current_address_detail] = N'Số 10, ngõ 55, phố Giải Phóng, Phường Bách Khoa'
WHERE [citizen_id] = '010203000001';

UPDATE [BCA].[Citizen] SET 
    [spouse_citizen_id] = '010203000001',
    [current_province_id] = 1,
    [current_district_id] = 1,
    [current_ward_id] = 1,
    [current_address_detail] = N'Số 10, ngõ 55, phố Giải Phóng, Phường Bách Khoa'
WHERE [citizen_id] = '010203000002';

UPDATE [BCA].[Citizen] SET 
    [father_citizen_id] = '010203000001',
    [mother_citizen_id] = '010203000002',
    [current_province_id] = 1,
    [current_district_id] = 1,
    [current_ward_id] = 1, 
    [current_address_detail] = N'Số 10, ngõ 55, phố Giải Phóng, Phường Bách Khoa'
WHERE [citizen_id] = '010203000003';

UPDATE [BCA].[Citizen] SET 
    [current_province_id] = 4,
    [current_district_id] = 4,
    [current_ward_id] = 4,
    [current_address_detail] = N'Số 15, Đường Nguyễn Huệ, Phường Bến Nghé'
WHERE [citizen_id] = '040201000001';

UPDATE [BCA].[Citizen] SET 
    [current_province_id] = 4,
    [current_district_id] = 4,
    [current_ward_id] = 4,
    [current_address_detail] = N'Số 22, Đường Lê Lợi, Phường Bến Nghé'
WHERE [citizen_id] = '040201000002';
GO

-- BCA.Address
INSERT INTO [BCA].[Address] ([address_detail], [ward_id], [district_id], [province_id], [postal_code])
VALUES
(N'Số 10, ngõ 55, phố Giải Phóng, Phường Bách Khoa', 1, 1, 1, '100000'),
(N'Số 15, Đường Nguyễn Huệ, Phường Bến Nghé', 4, 4, 4, '700000'),
(N'Số 22, Đường Lê Lợi, Phường Bến Nghé', 4, 4, 4, '700000');
GO

-- BCA.IdentificationCard
INSERT INTO [BCA].[IdentificationCard] ([citizen_id], [card_number], [card_type], [issue_date], [expiry_date], [issuing_authority_id])
VALUES
('010203000001', '001080005150', 'CCCD', '2020-01-15', '2035-01-15', 5),
('010203000002', '001085008220', 'CCCD', '2020-02-20', '2035-02-20', 5),
('010203000003', '001005001100', 'CCCD', '2023-01-20', '2038-01-20', 5),
('040201000001', '079090012050', 'CCCD', '2021-05-10', '2036-05-10', 6),
('040201000002', '079075003250', 'CCCD', '2022-06-15', '2037-06-15', 6);
GO

-- BCA.ResidenceHistory
INSERT INTO [BCA].[ResidenceHistory] ([citizen_id], [address_id], [residence_type], [registration_date], [issuing_authority_id], [status])
VALUES
('010203000001', 1, N'Thường trú', '2015-07-10', 5, 'Active'),
('010203000002', 1, N'Thường trú', '2015-07-10', 5, 'Active'),
('010203000003', 1, N'Thường trú', '2015-07-10', 5, 'Active'),
('040201000001', 2, N'Thường trú', '2018-05-22', 6, 'Active'),
('040201000002', 3, N'Thường trú', '2020-11-15', 6, 'Active');
GO

-- 3. Now let's create the same reference data in DB_BTP
-- ================================================
USE [DB_BTP];
GO

-- Reference.Regions
INSERT INTO [Reference].[Regions] ([region_id], [region_code], [region_name], [description])
VALUES 
(1, 'MB', N'Miền Bắc', N'Khu vực phía bắc Việt Nam'),
(2, 'MT', N'Miền Trung', N'Khu vực miền trung Việt Nam'),
(3, 'MN', N'Miền Nam', N'Khu vực phía nam Việt Nam');
GO

-- Reference.Provinces
INSERT INTO [Reference].[Provinces] ([province_id], [province_code], [province_name], [region_id], [administrative_unit_id], [is_city], [area], [population])
VALUES
(1, 'HN', N'Hà Nội', 1, 1, 1, 3359.82, 8246500),
(2, 'HP', N'Hải Phòng', 1, 1, 1, 1562.10, 2013500),
(3, 'DN', N'Đà Nẵng', 2, 1, 1, 1285.76, 1142000),
(4, 'HCM', N'Hồ Chí Minh', 3, 1, 1, 2095.60, 9038000),
(5, 'CT', N'Cần Thơ', 3, 1, 1, 1409.00, 1235000);
GO

-- Reference.Districts
INSERT INTO [Reference].[Districts] ([district_id], [district_code], [district_name], [province_id], [administrative_unit_id], [is_urban], [area], [population])
VALUES
(1, 'HBT', N'Hai Bà Trưng', 1, 2, 1, 10.09, 318000),
(2, 'HD', N'Hải An', 2, 2, 1, 55.39, 147000),
(3, 'HC', N'Hải Châu', 3, 2, 1, 23.29, 197000),
(4, 'Q1', N'Quận 1', 4, 2, 1, 7.72, 142000),
(5, 'NK', N'Ninh Kiều', 5, 2, 1, 29.00, 280000);
GO

-- Reference.Wards
INSERT INTO [Reference].[Wards] ([ward_id], [ward_code], [ward_name], [district_id], [administrative_unit_id], [is_urban], [area], [population])
VALUES
(1, 'BTD', N'Bách Khoa', 1, 3, 1, 2.23, 25000),
(2, 'TC', N'Tràng Cát', 2, 3, 1, 11.61, 6300),
(3, 'TN', N'Thanh Bình', 3, 3, 1, 0.85, 18000),
(4, 'BN', N'Bến Nghé', 4, 3, 1, 2.73, 11500),
(5, 'TH', N'Tân Hiệp', 5, 3, 1, 11.32, 17500);
GO

-- Reference.Ethnicities
INSERT INTO [Reference].[Ethnicities] ([ethnicity_id], [ethnicity_code], [ethnicity_name], [description], [population])
VALUES
(1, 'KINH', N'Kinh', N'Dân tộc Kinh là dân tộc chiếm đa số ở Việt Nam', 86210000),
(2, 'TAY', N'Tày', N'Dân tộc Tày là dân tộc thiểu số lớn thứ hai tại Việt Nam', 1850000),
(3, 'THAI', N'Thái', N'Dân tộc Thái phân bố chủ yếu ở vùng Tây Bắc Việt Nam', 1820000),
(4, 'MUONG', N'Mường', N'Dân tộc Mường có nhiều nét văn hóa tương đồng với người Kinh', 1450000),
(5, 'HOA', N'Hoa', N'Người Hoa tại Việt Nam là cộng đồng người gốc Trung Quốc', 823000);
GO

-- Reference.Religions
INSERT INTO [Reference].[Religions] ([religion_id], [religion_code], [religion_name], [description], [followers])
VALUES
(1, 'NONE', N'Không', N'Không theo tôn giáo nào cụ thể', NULL),
(2, 'PHAT', N'Phật giáo', N'Tôn giáo dựa trên lời dạy của Đức Phật Thích Ca', 14000000),
(3, 'CONG', N'Công giáo', N'Nhánh lớn của Kitô giáo dưới sự lãnh đạo của Giáo hoàng', 7000000),
(4, 'CAO', N'Cao Đài', N'Tôn giáo bản địa của Việt Nam, kết hợp nhiều tín ngưỡng', 4500000),
(5, 'TIN', N'Tin Lành', N'Nhánh của Kitô giáo bắt nguồn từ phong trào Cải cách Tin Lành', 1500000);
GO

-- Reference.Nationalities
INSERT INTO [Reference].[Nationalities] ([nationality_id], [nationality_code], [iso_code_alpha2], [iso_code_alpha3], [nationality_name], [country_name])
VALUES
(1, 'VN', 'VN', 'VNM', N'Việt Nam', N'Việt Nam'),
(2, 'US', 'US', 'USA', N'Hoa Kỳ', N'Hợp chủng quốc Hoa Kỳ'),
(3, 'CN', 'CN', 'CHN', N'Trung Quốc', N'Cộng hòa Nhân dân Trung Hoa'),
(4, 'JP', 'JP', 'JPN', N'Nhật Bản', N'Nhật Bản'),
(5, 'KR', 'KR', 'KOR', N'Hàn Quốc', N'Đại Hàn Dân Quốc');
GO

-- Reference.Occupations
INSERT INTO [Reference].[Occupations] ([occupation_id], [occupation_code], [occupation_name], [description])
VALUES
(1, 'TEACHER', N'Giáo viên', N'Người làm công tác giảng dạy tại các cơ sở giáo dục'),
(2, 'ENGINEER', N'Kỹ sư', N'Người có chuyên môn kỹ thuật trong lĩnh vực công nghệ, xây dựng'),
(3, 'DOCTOR', N'Bác sĩ', N'Người hành nghề y, chữa bệnh cho bệnh nhân'),
(4, 'BUSINESS', N'Kinh doanh', N'Người làm việc trong lĩnh vực kinh doanh, thương mại'),
(5, 'FARMER', N'Nông dân', N'Người làm nông nghiệp');
GO

-- Reference.Authorities
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [district_id], [ward_id], [parent_authority_id], [address_detail], [phone], [email], [website])
VALUES
(1, 'BCA', N'Bộ Công an', N'Bộ', NULL, NULL, NULL, NULL, N'47 Phạm Văn Đồng, Cầu Giấy, Hà Nội', '02438226602', 'vanthu@mps.gov.vn', 'bocongan.gov.vn'),
(2, 'BTP', N'Bộ Tư pháp', N'Bộ', NULL, NULL, NULL, NULL, N'58-60 Trần Phú, Ba Đình, Hà Nội', '02437336213', 'btp@moj.gov.vn', 'moj.gov.vn'),
(3, 'CATP-HN', N'Công an thành phố Hà Nội', N'Công an cấp tỉnh', 1, NULL, NULL, 1, N'55 Lý Thường Kiệt, Hoàn Kiếm, Hà Nội', '02439428644', 'catp@hanoi.gov.vn', NULL),
(4, 'SOTP-HN', N'Sở Tư pháp Hà Nội', N'Sở', 1, NULL, NULL, 2, N'1B Trần Phú, Ba Đình, Hà Nội', '02438253491', 'vanthu_stp@hanoi.gov.vn', 'sotuphap.hanoi.gov.vn'),
(5, 'CAQHBT', N'Công an quận Hai Bà Trưng', N'Công an cấp huyện', 1, 1, NULL, 3, N'1 Đại Cồ Việt, Hai Bà Trưng, Hà Nội', '02438696969', 'caq.hbt@hanoi.gov.vn', NULL),
(6, 'CATP-HCM', N'Công an thành phố Hồ Chí Minh', N'Công an cấp tỉnh', 4, NULL, NULL, 1, N'268 Trần Hưng Đạo, Quận 1, TP.HCM', '02839203232', 'catp@tphcm.gov.vn', NULL),
(7, 'CATP-DN', N'Công an thành phố Đà Nẵng', N'Công an cấp tỉnh', 3, NULL, NULL, 1, N'47 Lý Tự Trọng, Hải Châu, Đà Nẵng', '02363822233', 'catp@danang.gov.vn', NULL);
GO

-- Reference.RelationshipTypes
INSERT INTO [Reference].[RelationshipTypes] ([relationship_type_id], [relationship_code], [relationship_name], [description])
VALUES
(1, 'SPOUSE', N'Vợ/Chồng', N'Mối quan hệ kết hôn hợp pháp'),
(2, 'FATHER', N'Cha', N'Mối quan hệ giữa cha và con'),
(3, 'MOTHER', N'Mẹ', N'Mối quan hệ giữa mẹ và con'),
(4, 'CHILD', N'Con', N'Mối quan hệ giữa con và cha/mẹ'),
(5, 'SIBLING', N'Anh/Chị/Em', N'Mối quan hệ anh chị em ruột');
GO

-- Now update inverse relationships
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 1 WHERE [relationship_type_id] = 1; -- Spouse is symmetric
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 4 WHERE [relationship_type_id] = 2; -- Father->Child
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 4 WHERE [relationship_type_id] = 3; -- Mother->Child
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 2 WHERE [relationship_type_id] = 4 AND [relationship_code] = 'CHILD'; -- Child->Father/Mother (simplified)
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 5 WHERE [relationship_type_id] = 5; -- Sibling is symmetric
GO

-- Reference.PrisonFacilities
INSERT INTO [Reference].[PrisonFacilities] ([facility_code], [facility_name], [facility_type], [province_id], [district_id], [ward_id], [address_detail], [capacity], [managing_authority_id])
VALUES
('PRISON-HN1', N'Trại giam Hoà Bình', N'Trại giam', 1, NULL, NULL, N'Xã Đông Xuân, Huyện Sóc Sơn, Hà Nội', 1500, 3),
('PRISON-HCM1', N'Trại giam Chí Hoà', N'Trại giam', 4, NULL, NULL, N'Quận 10, TP. Hồ Chí Minh', 2000, 6);
GO

-- 4. JUSTICE MINISTRY DATA for DB_BTP
-- ===============================

-- BTP.BirthCertificate
INSERT INTO [BTP].[BirthCertificate] 
([citizen_id], [birth_certificate_no], [registration_date], [book_id], [page_no], [issuing_authority_id],
[place_of_birth], [date_of_birth], [gender_at_birth], 
[father_full_name], [father_citizen_id], [father_date_of_birth], [father_nationality_id],
[mother_full_name], [mother_citizen_id], [mother_date_of_birth], [mother_nationality_id],
[declarant_name], [declarant_citizen_id], [declarant_relationship])
VALUES
('010203000001', 'BC-HN-20180515-0001', '1980-06-10', 'BK-HN-1980', '15', 2,
N'Bệnh viện Bạch Mai, Hà Nội', '1980-05-15', N'Nam',
N'Nguyễn Văn Xã', NULL, '1955-03-10', 1,
N'Phạm Thị Yến', NULL, '1958-07-22', 1,
N'Nguyễn Văn Xã', NULL, N'Cha'),

('010203000002', 'BC-HN-20180822-0002', '1985-09-05', 'BK-HN-1985', '22', 2,
N'Bệnh viện Phụ sản Hà Nội', '1985-08-22', N'Nữ',
N'Trần Văn Cao', NULL, '1960-02-15', 1,
N'Lê Thị Diệu', NULL, '1962-11-30', 1,
N'Trần Văn Cao', NULL, N'Cha'),

('010203000003', 'BC-HN-20050110-0003', '2005-01-20', 'BK-HN-2005', '05', 2,
N'Bệnh viện Phụ sản Hà Nội', '2005-01-10', N'Nam',
N'Nguyễn Văn An', '010203000001', '1980-05-15', 1,
N'Trần Thị Bình', '010203000002', '1985-08-22', 1,
N'Nguyễn Văn An', '010203000001', N'Cha'),

('040201000001', 'BC-HCM-19901205-0001', '1990-12-20', 'BK-HCM-1990', '45', 2,
N'Bệnh viện Từ Dũ, Hồ Chí Minh', '1990-12-05', N'Nữ',
N'Lê Văn Fong', NULL, '1965-05-20', 1,
N'Huỳnh Thị Giáng', NULL, '1968-08-15', 1,
N'Lê Văn Fong', NULL, N'Cha'),

('040201000002', 'BC-HCM-19750325-0002', '1975-04-10', 'BK-HCM-1975', '18', 2,
N'Bệnh viện Chợ Rẫy, Hồ Chí Minh', '1975-03-25', N'Nam',
N'Trần Văn Dzung', NULL, '1950-11-05', 1,
N'Ngô Thị Hồng', NULL, '1952-12-28', 1,
N'Trần Văn Dzung', NULL, N'Cha');
GO

-- Kiểm tra các authority_id đã được chèn vào trong Reference.Authorities
SELECT * FROM [Reference].[Authorities];
GO

-- BTP.MarriageCertificate
INSERT INTO [BTP].[MarriageCertificate]
([marriage_certificate_no], [book_id], [page_no], 
[husband_id], [husband_full_name], [husband_date_of_birth], [husband_nationality_id], [husband_previous_marriage_status],
[wife_id], [wife_full_name], [wife_date_of_birth], [wife_nationality_id], [wife_previous_marriage_status],
[marriage_date], [registration_date], [issuing_authority_id], [issuing_place],
[witness1_name], [witness2_name])
VALUES
('MC-HN-20100620-0001', 'MK-HN-2010', '10', 
'010203000001', N'Nguyễn Văn An', '1980-05-15', 1, N'Chưa kết hôn',
'010203000002', N'Trần Thị Bình', '1985-08-22', 1, N'Chưa kết hôn',
'2010-06-20', '2010-06-25', 2, N'Phòng Tư pháp Quận Hai Bà Trưng',
N'Nguyễn Văn Xã', N'Lê Thị Diệu');
GO

-- BTP.Household
INSERT INTO [BTP].[Household]
([household_book_no], [head_of_household_id], [address_id], [registration_date], [issuing_authority_id], 
[area_code], [household_type])
VALUES
('HK-HN-001-2010', '010203000001', 1, '2010-07-15', 2, 'HBT-BK', N'Hộ gia đình'),
('HK-HCM-001-2018', '040201000001', 2, '2018-06-10', 2, 'Q1-BN', N'Hộ gia đình'),
('HK-HCM-002-2020', '040201000002', 3, '2020-12-01', 2, 'Q1-BN', N'Hộ gia đình');
GO

-- BTP.HouseholdMember
INSERT INTO [BTP].[HouseholdMember]
([household_id], [citizen_id], [relationship_with_head], [join_date], [order_in_household])
VALUES
(1, '010203000001', N'Chủ hộ', '2010-07-15', 1),
(1, '010203000002', N'Vợ', '2010-07-15', 2),
(1, '010203000003', N'Con đẻ', '2010-07-15', 3),
(2, '040201000001', N'Chủ hộ', '2018-06-10', 1),
(3, '040201000002', N'Chủ hộ', '2020-12-01', 1);
GO

-- BTP.FamilyRelationship
INSERT INTO [BTP].[FamilyRelationship]
([citizen_id], [related_citizen_id], [relationship_type], [start_date], [status])
VALUES
('010203000001', '010203000002', N'Vợ-Chồng', '2010-06-20', N'Active'),
('010203000002', '010203000001', N'Vợ-Chồng', '2010-06-20', N'Active'),
('010203000001', '010203000003', N'Cha đẻ-Con đẻ', '2005-01-10', N'Active'),
('010203000002', '010203000003', N'Mẹ đẻ-Con đẻ', '2005-01-10', N'Active'),
('010203000003', '010203000001', N'Cha đẻ-Con đẻ', '2005-01-10', N'Active'),
('010203000003', '010203000002', N'Mẹ đẻ-Con đẻ', '2005-01-10', N'Active');
GO

-- BTP.PopulationChange
INSERT INTO [BTP].[PopulationChange]
([citizen_id], [change_type], [change_date], [reason], [processing_authority_id])
VALUES
('010203000001', N'Đăng ký khai sinh', '1980-06-10', N'Khai sinh lần đầu', 2),
('010203000002', N'Đăng ký khai sinh', '1985-09-05', N'Khai sinh lần đầu', 2),
('010203000003', N'Đăng ký khai sinh', '2005-01-20', N'Khai sinh lần đầu', 2),
('010203000001', N'Đăng ký kết hôn', '2010-06-25', N'Kết hôn lần đầu', 2),
('010203000002', N'Đăng ký kết hôn', '2010-06-25', N'Kết hôn lần đầu', 2),
('040201000001', N'Đăng ký khai sinh', '1990-12-20', N'Khai sinh lần đầu', 2),
('040201000002', N'Đăng ký khai sinh', '1975-04-10', N'Khai sinh lần đầu', 2);
GO
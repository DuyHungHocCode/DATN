-- Insert reference data into DB_BCA
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
-- Add DELETE for other reference tables if they exist (e.g., RelationshipTypes, PrisonFacilities)
-- DELETE FROM [Reference].[RelationshipTypes];
-- DELETE FROM [Reference].[PrisonFacilities];
GO

-- Insert data into Reference.Regions
INSERT INTO [Reference].[Regions] ([region_id], [region_code], [region_name], [description]) VALUES
(1, 'BAC', N'Miền Bắc', N'Bao gồm các tỉnh/thành phố từ Hà Tĩnh trở ra, với trung tâm là Thủ đô Hà Nội. Gồm các vùng: Đồng bằng sông Hồng, Đông Bắc, Tây Bắc và Bắc Trung Bộ'),
(2, 'TRU', N'Miền Trung', N'Bao gồm các tỉnh/thành phố từ Quảng Bình đến Bình Thuận, với trung tâm là thành phố Đà Nẵng. Gồm các vùng: Duyên hải Nam Trung Bộ và Tây Nguyên'),
(3, 'NAM', N'Miền Nam', N'Bao gồm các tỉnh/thành phố từ Bà Rịa - Vũng Tàu trở vào, với trung tâm là TP. Hồ Chí Minh. Gồm các vùng: Đông Nam Bộ và Đồng bằng sông Cửu Long');
GO

-- Insert data into Reference.Provinces
INSERT INTO [Reference].[Provinces] ([province_id], [province_code], [province_name], [region_id], [area], [population], [gso_code], [is_city], [administrative_unit_id], [administrative_region_id]) VALUES
-- Miền Bắc (region_id = 1)
-- Đồng bằng sông Hồng (administrative_region_id = 1)
(1, 'HNO', N'Hà Nội', 1, 3358.6, 8418600, '01', 1, 1, 1),
(2, 'HPH', N'Hải Phòng', 1, 1561.8, 2029500, '31', 1, 1, 1),
(3, 'BNI', N'Bắc Ninh', 1, 822.7, 1368000, '27', 0, 2, 1),
(4, 'HDG', N'Hải Dương', 1, 1656.0, 1892100, '30', 0, 2, 1),
(5, 'HNG', N'Hưng Yên', 1, 926.0, 1252700, '33', 0, 2, 1),
(6, 'NDH', N'Nam Định', 1, 1652.6, 1780000, '36', 0, 2, 1),
(7, 'TBH', N'Thái Bình', 1, 1570.5, 1860000, '34', 0, 2, 1),
(8, 'VPC', N'Vĩnh Phúc', 1, 1236.5, 1154000, '26', 0, 2, 1),
(9, 'HNA', N'Hà Nam', 1, 860.5, 854000, '35', 0, 2, 1),
(63, 'NBI', N'Ninh Bình', 1, 1329.0,  974600, '37', 0, 2, 1), -- Moved Ninh Bình to Đồng bằng sông Hồng based on GSO classification if region_id = 1 corresponds to Bắc
-- Đông Bắc (administrative_region_id = 2)
(10, 'HGG', N'Hà Giang', 1, 7914.9, 854679, '02', 0, 2, 2),
(11, 'CAB', N'Cao Bằng', 1, 6707.9, 530341, '04', 0, 2, 2),
(12, 'BKN', N'Bắc Kạn', 1, 4860.0, 313905, '06', 0, 2, 2),
(13, 'LCA', N'Lào Cai', 1, 6383.9, 730000, '10', 0, 2, 2),
(14, 'YBA', N'Yên Bái', 1, 6886.3, 821000, '15', 0, 2, 2),
(15, 'TNG', N'Thái Nguyên', 1, 3534.7, 1294000, '19', 0, 2, 2),
(16, 'LGS', N'Lạng Sơn', 1, 8320.8, 781000, '20', 0, 2, 2),
(17, 'QNH', N'Quảng Ninh', 1, 6102.3, 1320300, '22', 0, 2, 2),
(18, 'BGG', N'Bắc Giang', 1, 3848.9, 1803950, '24', 0, 2, 2),
(19, 'PTO', N'Phú Thọ', 1, 3533.3, 1466800, '25', 0, 2, 2),
(20, 'TQA', N'Tuyên Quang', 1, 5867.3, 786800, '08', 0, 2, 2),
-- Tây Bắc (administrative_region_id = 3)
(21, 'DBO', N'Điện Biên', 1, 9562.9, 598856, '11', 0, 2, 3),
(22, 'LAC', N'Lai Châu', 1, 9068.8, 460196, '12', 0, 2, 3),
(23, 'SLA', N'Sơn La', 1, 14174.4, 1248904, '14', 0, 2, 3),
(24, 'HBH', N'Hòa Bình', 1, 4608.7, 854131, '17', 0, 2, 3),
-- Miền Trung (region_id = 2)
-- Bắc Trung Bộ (administrative_region_id = 4)
(25, 'THA', N'Thanh Hóa', 2, 11132.2, 3645800, '38', 0, 2, 4),
(26, 'NAN', N'Nghệ An', 2, 16490.9, 3327791, '40', 0, 2, 4),
(27, 'HTH', N'Hà Tĩnh', 2, 5997.8, 1288866, '42', 0, 2, 4),
(28, 'QBH', N'Quảng Bình', 2, 8065.3, 896599, '44', 0, 2, 4),
(29, 'QTR', N'Quảng Trị', 2, 4739.8, 628789, '45', 0, 2, 4),
(30, 'TTH', N'Thừa Thiên Huế', 2, 5033.2, 1163591, '46', 0, 2, 4), -- GSO lists as Thành phố Huế, code 46 is correct
-- Nam Trung Bộ (administrative_region_id = 5)
(31, 'DNG', N'Đà Nẵng', 2, 1285.4, 1134310, '48', 1, 1, 5), -- GSO lists as Thành phố Đà Nẵng, code 48 is correct
(32, 'QNM', N'Quảng Nam', 2, 10574.7, 1493843, '49', 0, 2, 5),
(33, 'QNI', N'Quảng Ngãi', 2, 5153.0, 1231697, '51', 0, 2, 5),
(34, 'BDH', N'Bình Định', 2, 6050.6, 1529141, '52', 0, 2, 5),
(35, 'PYN', N'Phú Yên', 2, 5060.6, 868961, '54', 0, 2, 5),
(36, 'KHA', N'Khánh Hòa', 2, 5217.7, 1232844, '56', 0, 2, 5),
(37, 'NTN', N'Ninh Thuận', 2, 3358.3, 576739, '58', 0, 2, 5),
(38, 'BTN', N'Bình Thuận', 2, 7812.8, 1230408, '60', 0, 2, 5),
-- Tây Nguyên (administrative_region_id = 6)
(39, 'KTM', N'Kon Tum', 2, 9689.6, 540438, '62', 0, 2, 6),
(40, 'GLI', N'Gia Lai', 2, 15536.9, 1513847, '64', 0, 2, 6),
(41, 'DLK', N'Đắk Lắk', 2, 13125.4, 1869322, '66', 0, 2, 6),
(42, 'DNO', N'Đắk Nông', 2, 6515.6, 645413, '67', 0, 2, 6),
(43, 'LDG', N'Lâm Đồng', 2, 9773.5, 1298145, '68', 0, 2, 6),
-- Miền Nam (region_id = 3)
-- Đông Nam Bộ (administrative_region_id = 7)
(44, 'BPC', N'Bình Phước', 3, 6871.5, 994679, '70', 0, 2, 7),
(45, 'TNH', N'Tây Ninh', 3, 4041.4, 1169165, '72', 0, 2, 7),
(46, 'BDG', N'Bình Dương', 3, 2694.4, 2426561, '74', 0, 2, 7),
(47, 'DNI', N'Đồng Nai', 3, 5907.2, 3097107, '75', 0, 2, 7),
(48, 'BRV', N'Bà Rịa - Vũng Tàu', 3, 1989.5, 1148313, '77', 0, 2, 7),
(49, 'HCM', N'Hồ Chí Minh', 3, 2061.4, 9038600, '79', 1, 1, 7), -- GSO lists as Thành phố Hồ Chí Minh, code 79 is correct
-- Đồng bằng sông Cửu Long (administrative_region_id = 8)
(50, 'LAN', N'Long An', 3, 4492.4, 1688547, '80', 0, 2, 8),
(51, 'TGG', N'Tiền Giang', 3, 2484.2, 1764185, '82', 0, 2, 8),
(52, 'BTE', N'Bến Tre', 3, 2360.6, 1288463, '83', 0, 2, 8),
(53, 'TVH', N'Trà Vinh', 3, 2341.2, 1009168, '84', 0, 2, 8),
(54, 'VLG', N'Vĩnh Long', 3, 1504.9, 1022791, '86', 0, 2, 8),
(55, 'DTP', N'Đồng Tháp', 3, 3377.0, 1599504, '87', 0, 2, 8),
(56, 'AGG', N'An Giang', 3, 3536.7, 1907403, '89', 0, 2, 8),
(57, 'KGG', N'Kiên Giang', 3, 6348.5, 1726188, '91', 0, 2, 8),
(58, 'CTO', N'Cần Thơ', 3, 1409.0, 1235171, '92', 1, 1, 8), -- GSO lists as Thành phố Cần Thơ, code 92 is correct
(59, 'HAG', N'Hậu Giang', 3, 1602.0, 733017, '93', 0, 2, 8),
(60, 'STG', N'Sóc Trăng', 3, 3311.9, 1199653, '94', 0, 2, 8),
(61, 'BLU', N'Bạc Liêu', 3, 2468.7, 873400, '95', 0, 2, 8),
(62, 'CMU', N'Cà Mau', 3, 5294.9, 1191999, '96', 0, 2, 8);
GO

-- Insert data into Reference.Districts (Example for Hanoi)
INSERT INTO [Reference].[Districts] ([district_id], [district_code], [district_name], [province_id], [area], [population], [gso_code], [is_urban], [administrative_unit_id]) VALUES

(101, 'BAD', N'Ba Đình', 1, 9.25, 247100, '001', 1, 1),
(102, 'HKM', N'Hoàn Kiếm', 1, 5.29, 147300, '002', 1, 1),
(103, 'THO', N'Tây Hồ', 1, 24.01, 168300, '003', 1, 1),
(104, 'LBI', N'Long Biên', 1, 60.38, 318000, '004', 1, 1),
(105, 'CGI', N'Cầu Giấy', 1, 12.04, 266800, '005', 1, 1),
(106, 'DDA', N'Đống Đa', 1, 9.95, 410000, '006', 1, 1),
(107, 'HBT', N'Hai Bà Trưng', 1, 10.09, 318400, '007', 1, 1),
(108, 'HMA', N'Hoàng Mai', 1, 40.32, 411500, '008', 1, 1),
(109, 'TXU', N'Thanh Xuân', 1, 9.11, 285400, '009', 1, 1),
(110, 'BTL', N'Bắc Từ Liêm', 1, 43.35, 333000, '010', 1, 1),
(111, 'NTL', N'Nam Từ Liêm', 1, 32.19, 236000, '019', 1, 1),
(112, 'HDO', N'Hà Đông', 1, 49.64, 382637, '268', 1, 1),
(113, 'SSO', N'Sóc Sơn', 1, 306.51, 322200, '016', 0, 2),
(114, 'DAN', N'Đông Anh', 1, 182.30, 381000, '017', 0, 2),
(115, 'GLA', N'Gia Lâm', 1, 114.17, 276000, '018', 0, 2),
(116, 'THT', N'Thanh Trì', 1, 63.43, 247300, '020', 0, 2),
(117, 'BAV', N'Ba Vì', 1, 424.14, 282800, '250', 0, 2),
(118, 'PTH', N'Phúc Thọ', 1, 113.23, 182400, '251', 0, 2),
(119, 'DTI', N'Đan Phượng', 1, 76.80, 162900, '252', 0, 2),
(120, 'HOA', N'Hoài Đức', 1, 82.70, 229800, '253', 0, 2),
(121, 'QUO', N'Quốc Oai', 1, 147.00, 175800, '254', 0, 2),
(122, 'THA', N'Thạch Thất', 1, 128.10, 207500, '255', 0, 2),
(123, 'CPA', N'Chương Mỹ', 1, 232.40, 320000, '256', 0, 2),
(124, 'TNH', N'Thanh Oai', 1, 129.60, 184900, '257', 0, 2),
(125, 'TDU', N'Thường Tín', 1, 130.70, 247400, '258', 0, 2),
(126, 'PHX', N'Phú Xuyên', 1, 171.10, 189400, '259', 0, 2),
(127, 'UHG', N'Ứng Hòa', 1, 184.60, 204000, '260', 0, 2),
(128, 'MYD', N'Mỹ Đức', 1, 230.00, 180000, '261', 0, 2),
(129, 'MDC', N'Mê Linh', 1, 141.90, 202700, '262', 0, 2);

(201, 'HBG', N'Hồng Bàng', 2, 14.5, 105000, '303', 1, 1), -- Example area/population
(202, 'NQY', N'Ngô Quyền', 2, 11.3, 165000, '304', 1, 1), -- Example area/population
(203, 'LCH', N'Lê Chân', 2, 11.9, 220000, '305', 1, 1), -- Example area/population
(204, 'HAI', N'Hải An', 2, 105.0, 135000, '306', 1, 1), -- Example area/population
(205, 'KAI', N'Kiến An', 2, 29.6, 110000, '307', 1, 1), -- Example area/population
(206, 'DSO', N'Đồ Sơn', 2, 42.3, 55000, '308', 1, 1),  -- Example area/population
(207, 'DAN', N'Dương Kinh', 2, 46.8, 65000, '309', 1, 1), -- Example area/population

-- Huyện (Rural Districts) - administrative_unit_id = 2, is_urban = 0
(208, 'TAN', N'Thủy Nguyên', 2, 261.9, 350000, '311', 0, 2), -- Example area/population
(209, 'ADG', N'An Dương', 2, 98.3, 200000, '312', 0, 2), -- Example area/population
(210, 'ALA', N'An Lão', 2, 114.5, 160000, '313', 0, 2), -- Example area/population
(211, 'KTH', N'Kiến Thụy', 2, 107.5, 150000, '314', 0, 2), -- Example area/population
(212, 'TLA', N'Tiên Lãng', 2, 191.1, 170000, '315', 0, 2), -- Example area/population
(213, 'VBA', N'Vĩnh Bảo', 2, 183.3, 200000, '316', 0, 2), -- Example area/population
(214, 'CLO', N'Cát Hải', 2, 323.3, 32000, '317', 0, 2),  -- Example area/population
(215, 'BLY', N'Bạch Long Vĩ', 2, 3.1, 700, '318', 0, 2);    -- Example area/population

GO

-- Insert data into Reference.Wards (Example for Ba Dinh District, Hanoi)
INSERT INTO [Reference].[Wards] ([ward_id], [ward_code], [ward_name], [district_id], [area], [population], [gso_code], [is_urban], [administrative_unit_id]) VALUES
(10101, 'PHUCXA', N'Phúc Xá', 101, 0.95, 18500, '00001', 1, 5),
(10102, 'TRUCBACH', N'Trúc Bạch', 101, 0.54, 11200, '00002', 1, 5),
(10103, 'VINHPHUC', N'Vĩnh Phúc', 101, 0.63, 14800, '00003', 1, 5),
(10104, 'CONGVI', N'Cống Vị', 101, 0.82, 24600, '00004', 1, 5),
(10105, 'LIEUGIAI', N'Liễu Giai', 101, 0.76, 22100, '00005', 1, 5),
(10106, 'NGUYENTT', N'Nguyễn Trung Trực', 101, 0.41, 13300, '00006', 1, 5),
(10107, 'QUANTHANH', N'Quán Thánh', 101, 0.61, 16900, '00007', 1, 5),
(10108, 'DOICAN', N'Đội Cấn', 101, 0.85, 25400, '00008', 1, 5),
(10109, 'NGOCHA', N'Ngọc Hà', 101, 0.74, 20700, '00009', 1, 5),
(10110, 'KIMMA', N'Kim Mã', 101, 0.58, 19800, '00010', 1, 5),
(10111, 'GIANGVO', N'Giảng Võ', 101, 0.72, 23500, '00011', 1, 5),
(10112, 'THANHCONG', N'Thành Công', 101, 0.88, 26100, '00012', 1, 5);
-- Add other wards for other districts...
GO

-- Insert data into Reference.Ethnicities
INSERT INTO [Reference].[Ethnicities] ([ethnicity_id], [ethnicity_code], [ethnicity_name], [description], [population]) VALUES
(1, 'KINH', N'Kinh', N'Dân tộc đa số của Việt Nam...', 85320000),
(2, 'TAY', N'Tày', N'Cư trú chủ yếu ở vùng Đông Bắc...', 1850000),
(3, 'THAI', N'Thái', N'Tập trung chủ yếu ở Tây Bắc...', 1820000),
(4, 'MUONG', N'Mường', N'Sinh sống tập trung tại vùng Tây Bắc...', 1450000),
(5, 'HMONG', N'H''Mông', N'Cư trú chủ yếu ở vùng núi cao...', 1280000),
(6, 'KHMER', N'Khơ-me', N'Tập trung chủ yếu ở đồng bằng sông Cửu Long...', 1260000),
(7, 'NUNG', N'Nùng', N'Sinh sống chủ yếu ở các tỉnh Đông Bắc...', 1080000),
(8, 'HOA', N'Hoa', N'Phân bố rải rác khắp cả nước...', 823000),
(9, 'DAO', N'Dao', N'Cư trú rải rác ở vùng núi phía Bắc...', 796000),
(10, 'GIARAI', N'Gia-rai', N'Sinh sống chủ yếu ở Tây Nguyên...', 497000),
-- Add other ethnicities...
(54, 'MLAO', N'MLao', N'Cư trú tại các tỉnh Tây Nguyên...', 400);
GO

-- Insert data into Reference.Religions
INSERT INTO [Reference].[Religions] ([religion_id], [religion_code], [religion_name], [description], [followers]) VALUES
(1, 'BUDD', N'Phật giáo', N'Tôn giáo lớn nhất tại Việt Nam...', 14800000),
(2, 'CATH', N'Công giáo', N'Du nhập từ thế kỷ XVI...', 7200000),
(3, 'CAOD', N'Cao Đài', N'Tôn giáo bản địa ra đời năm 1926...', 4400000),
(4, 'HOAH', N'Phật giáo Hòa Hảo', N'Được sáng lập năm 1939...', 2000000),
(5, 'PROT', N'Tin Lành', N'Du nhập vào Việt Nam từ đầu thế kỷ XX...', 1000000),
(6, 'ISLM', N'Hồi giáo', N'Chủ yếu theo hệ phái Sunni...', 75000),
(7, 'HIND', N'Ấn Độ giáo', N'Còn tồn tại trong cộng đồng người Chăm...', 50000),
(8, 'DAOM', N'Đạo Mẫu', N'Tín ngưỡng dân gian thờ Mẫu...', 200000),
(9, 'NONE', N'Không tôn giáo', N'Nhóm người không theo tôn giáo cụ thể...', 70000000),
(10, 'OTHR', N'Tôn giáo khác', N'Bao gồm các tín ngưỡng bản địa...', 275000);
GO

-- Insert data into Reference.Nationalities
INSERT INTO [Reference].[Nationalities] ([nationality_id], [nationality_code], [iso_code_alpha3], [nationality_name], [country_name]) VALUES
(1, 'VN', 'VNM', N'Việt Nam', N'Cộng hòa Xã hội Chủ nghĩa Việt Nam'),
(2, 'BN', 'BRN', N'Brunei', N'Quốc gia Brunei Darussalam'),
(3, 'KH', 'KHM', N'Campuchia', N'Vương quốc Campuchia'),
(4, 'ID', 'IDN', N'Indonesia', N'Cộng hòa Indonesia'),
(5, 'LA', 'LAO', N'Lào', N'Cộng hòa Dân chủ Nhân dân Lào'),
(6, 'MY', 'MYS', N'Malaysia', N'Malaysia'),
(7, 'MM', 'MMR', N'Myanmar', N'Cộng hòa Liên bang Myanmar'),
(8, 'PH', 'PHL', N'Philippines', N'Cộng hòa Philippines'),
(9, 'SG', 'SGP', N'Singapore', N'Cộng hòa Singapore'),
(10, 'TH', 'THA', N'Thái Lan', N'Vương quốc Thái Lan'),
(11, 'TL', 'TLS', N'Đông Timor', N'Cộng hòa Dân chủ Đông Timor'),
(12, 'US', 'USA', N'Hoa Kỳ', N'Hợp chủng quốc Hoa Kỳ'),
(13, 'CN', 'CHN', N'Trung Quốc', N'Cộng hòa Nhân dân Trung Hoa'),
(14, 'JP', 'JPN', N'Nhật Bản', N'Nhật Bản'),
(15, 'KR', 'KOR', N'Hàn Quốc', N'Đại Hàn Dân Quốc'),
(16, 'RU', 'RUS', N'Nga', N'Liên bang Nga'),
(17, 'DE', 'DEU', N'Đức', N'Cộng hòa Liên bang Đức'),
(18, 'FR', 'FRA', N'Pháp', N'Cộng hòa Pháp'),
(19, 'GB', 'GBR', N'Anh', N'Vương quốc Anh'),
(20, 'IN', 'IND', N'Ấn Độ', N'Cộng hòa Ấn Độ'),
(21, 'TW', 'TWN', N'Đài Loan', N'Đài Loan'),
(22, 'HK', 'HKG', N'Hồng Kông', N'Đặc khu hành chính Hồng Kông'),
(23, 'MO', 'MAC', N'Ma Cao', N'Đặc khu hành chính Ma Cao'),
(24, 'KP', 'PRK', N'Triều Tiên', N'Cộng hòa Dân chủ Nhân dân Triều Tiên'),
(25, 'AU', 'AUS', N'Úc', N'Liên bang Úc'),
(26, 'CA', 'CAN', N'Canada', N'Canada'),
(27, 'BR', 'BRA', N'Brazil', N'Cộng hòa Liên bang Brazil'),
(28, 'UA', 'UKR', N'Ukraine', N'Ukraine'),
(29, 'AE', 'ARE', N'Các Tiểu Vương quốc Ả Rập Thống nhất', N'Các Tiểu Vương quốc Ả Rập Thống nhất'),
(30, 'SA', 'SAU', N'Ả Rập Xê Út', N'Vương quốc Ả Rập Xê Út'),
(31, 'TR', 'TUR', N'Thổ Nhĩ Kỳ', N'Cộng hòa Thổ Nhĩ Kỳ'),
(32, 'ZA', 'ZAF', N'Nam Phi', N'Cộng hòa Nam Phi'),
(33, 'NG', 'NGA', N'Nigeria', N'Cộng hòa Liên bang Nigeria'),
(34, 'MX', 'MEX', N'Mexico', N'Hợp chủng quốc Mexico'),
(35, 'AR', 'ARG', N'Argentina', N'Cộng hòa Argentina');
GO

-- Insert data into Reference.Occupations
INSERT INTO [Reference].[Occupations] ([occupation_id], [occupation_code], [occupation_name], [description]) VALUES
(1, 'MGMT', N'Quản lý và lãnh đạo', N'Các vị trí quản lý cấp cao và lãnh đạo trong tổ chức'),
(2, 'PROF', N'Chuyên gia và chuyên môn', N'Các nghề đòi hỏi trình độ chuyên môn cao'),
(3, 'TECH', N'Kỹ thuật và công nghệ', N'Các nghề liên quan đến kỹ thuật và công nghệ'),
(4, 'ADMN', N'Hành chính và văn phòng', N'Các công việc hành chính, văn phòng'),
(5, 'SERV', N'Dịch vụ và bán hàng', N'Các nghề trong lĩnh vực dịch vụ và bán hàng'),
(6, 'AGRI', N'Nông lâm ngư nghiệp', N'Các nghề trong lĩnh vực nông, lâm, ngư nghiệp'),
(7, 'PROD', N'Sản xuất và chế biến', N'Các nghề trong lĩnh vực sản xuất và chế biến'),
(8, 'CONS', N'Xây dựng và lắp đặt', N'Các nghề trong lĩnh vực xây dựng'),
(9, 'TRAN', N'Vận tải và logistics', N'Các nghề trong lĩnh vực vận tải và logistics'),
(10, 'OTHR', N'Khác', N'Các nghề khác không thuộc các nhóm trên');
GO

-- Insert data into Reference.Authorities (Example data)
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [address_detail], [phone], [email], [province_id], [district_id], [ward_id], [parent_authority_id], [is_active]) VALUES
(1, 'BCA', N'Bộ Công an', N'Bộ', N'Số 44 Yết Kiêu, Hoàn Kiếm, Hà Nội', '024 3825 6255', 'bocongan@mps.gov.vn', 1, 102, NULL, NULL, 1),
(2, 'BTP', N'Bộ Tư pháp', N'Bộ', N'Số 58-60 Trần Phú, Ba Đình, Hà Nội', '024 6273 9718', 'btp@moj.gov.vn', 1, 101, NULL, NULL, 1),
(3, 'TCCS', N'Tổng cục Cảnh sát', N'Tổng cục', N'Số 47 Phạm Văn Đồng, Cầu Giấy, Hà Nội', '024 3694 2593', 'canhsat@mps.gov.vn', 1, 105, NULL, 1, 1),
(4, 'C06', N'Cục Cảnh sát quản lý hành chính về trật tự xã hội', N'Cục', N'Số 47 Phạm Văn Đồng, Cầu Giấy, Hà Nội', '024 3556 3308', 'c06@mps.gov.vn', 1, 105, NULL, 3, 1),
(5, 'HTQT', N'Cục Hộ tịch, quốc tịch, chứng thực', N'Cục', N'Số 58-60 Trần Phú, Ba Đình, Hà Nội', '024 6273 9538', 'hotich@moj.gov.vn', 1, 101, NULL, 2, 1),
(10, 'CATP-HN', N'Công an thành phố Hà Nội', N'Công an tỉnh/thành phố', N'Số 87 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội', '024 3826 9118', 'catp@hanoi.gov.vn', 1, 102, NULL, 1, 1),
(20, 'STP-HN', N'Sở Tư pháp thành phố Hà Nội', N'Sở Tư pháp', N'Số 1B Trần Phú, Ba Đình, Hà Nội', '024 3733 0836', 'sotuphap@hanoi.gov.vn', 1, 101, NULL, 2, 1),
(30, 'UBND-HN', N'Ủy ban nhân dân thành phố Hà Nội', N'UBND cấp tỉnh', N'Số 12 Lê Lai, Hoàn Kiếm, Hà Nội', '024 3825 3536', 'ubnd@hanoi.gov.vn', 1, 102, NULL, NULL, 1),
(100, 'CAQ-BD', N'Công an quận Ba Đình', N'Công an quận/huyện', N'37A Điện Biên Phủ, Ba Đình, Hà Nội', '024 3845 3267', 'caqbadinh@hanoi.gov.vn', 1, 101, NULL, 10, 1),
(150, 'PTP-BD', N'Phòng Tư pháp quận Ba Đình', N'Phòng Tư pháp', N'10 Trần Phú, Ba Đình, Hà Nội', '024 3823 4512', 'tuphapbadinh@hanoi.gov.vn', 1, 101, NULL, 20, 1),
(200, 'UBND-BD', N'UBND quận Ba Đình', N'UBND cấp quận/huyện', N'18 Trần Phú, Ba Đình, Hà Nội', '024 3823 1234', 'ubndbadinh@hanoi.gov.vn', 1, 101, NULL, 30, 1);
-- Add other authorities...
GO


-- Insert reference data into DB_BTP
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
-- Add DELETE for other reference tables if they exist
-- DELETE FROM [Reference].[RelationshipTypes];
-- DELETE FROM [Reference].[PrisonFacilities];
GO

-- Insert data into Reference.Regions
INSERT INTO [Reference].[Regions] ([region_id], [region_code], [region_name], [description]) VALUES
(1, 'BAC', N'Miền Bắc', N'Bao gồm các tỉnh/thành phố từ Hà Tĩnh trở ra, với trung tâm là Thủ đô Hà Nội. Gồm các vùng: Đồng bằng sông Hồng, Đông Bắc, Tây Bắc và Bắc Trung Bộ'),
(2, 'TRU', N'Miền Trung', N'Bao gồm các tỉnh/thành phố từ Quảng Bình đến Bình Thuận, với trung tâm là thành phố Đà Nẵng. Gồm các vùng: Duyên hải Nam Trung Bộ và Tây Nguyên'),
(3, 'NAM', N'Miền Nam', N'Bao gồm các tỉnh/thành phố từ Bà Rịa - Vũng Tàu trở vào, với trung tâm là TP. Hồ Chí Minh. Gồm các vùng: Đông Nam Bộ và Đồng bằng sông Cửu Long');
GO

-- Insert data into Reference.Provinces (Same as DB_BCA)
INSERT INTO [Reference].[Provinces] ([province_id], [province_code], [province_name], [region_id], [area], [population], [gso_code], [is_city], [administrative_unit_id], [administrative_region_id]) VALUES
(1, 'HNO', N'Hà Nội', 1, 3358.6, 8418600, '01', 1, 1, 1),
(2, 'HPH', N'Hải Phòng', 1, 1561.8, 2029500, '31', 1, 1, 1),
-- ... (Copy all province inserts from DB_BCA section above) ...
(62, 'CMU', N'Cà Mau', 3, 5294.9, 1191999, '96', 0, 2, 8);
GO

-- Insert data into Reference.Districts (Same as DB_BCA - Example for Hanoi)
INSERT INTO [Reference].[Districts] ([district_id], [district_code], [district_name], [province_id], [area], [population], [gso_code], [is_urban], [administrative_unit_id]) VALUES
(101, 'BAD', N'Ba Đình', 1, 9.25, 247100, '001', 1, 1),
(102, 'HKM', N'Hoàn Kiếm', 1, 5.29, 147300, '002', 1, 1),
-- ... (Copy all district inserts from DB_BCA section above) ...
(129, 'MDC', N'Mê Linh', 1, 141.90, 202700, '262', 0, 2);
GO

-- Insert data into Reference.Wards (Same as DB_BCA - Example for Ba Dinh)
INSERT INTO [Reference].[Wards] ([ward_id], [ward_code], [ward_name], [district_id], [area], [population], [gso_code], [is_urban], [administrative_unit_id]) VALUES
(10101, 'PHUCXA', N'Phúc Xá', 101, 0.95, 18500, '00001', 1, 5),
(10102, 'TRUCBACH', N'Trúc Bạch', 101, 0.54, 11200, '00002', 1, 5),
-- ... (Copy all ward inserts from DB_BCA section above) ...
(10112, 'THANHCONG', N'Thành Công', 101, 0.88, 26100, '00012', 1, 5);
GO

-- Insert data into Reference.Ethnicities (Same as DB_BCA)
INSERT INTO [Reference].[Ethnicities] ([ethnicity_id], [ethnicity_code], [ethnicity_name], [description], [population]) VALUES
(1, 'KINH', N'Kinh', N'Dân tộc đa số của Việt Nam...', 85320000),
-- ... (Copy all ethnicity inserts from DB_BCA section above) ...
(54, 'MLAO', N'MLao', N'Cư trú tại các tỉnh Tây Nguyên...', 400);
GO

-- Insert data into Reference.Religions (Same as DB_BCA)
INSERT INTO [Reference].[Religions] ([religion_id], [religion_code], [religion_name], [description], [followers]) VALUES
(1, 'BUDD', N'Phật giáo', N'Tôn giáo lớn nhất tại Việt Nam...', 14800000),
-- ... (Copy all religion inserts from DB_BCA section above) ...
(10, 'OTHR', N'Tôn giáo khác', N'Bao gồm các tín ngưỡng bản địa...', 275000);
GO

-- Insert data into Reference.Nationalities (Same as DB_BCA)
INSERT INTO [Reference].[Nationalities] ([nationality_id], [nationality_code], [iso_code_alpha3], [nationality_name], [country_name]) VALUES
(1, 'VN', 'VNM', N'Việt Nam', N'Cộng hòa Xã hội Chủ nghĩa Việt Nam'),
-- ... (Copy all nationality inserts from DB_BCA section above) ...
(35, 'AR', 'ARG', N'Argentina', N'Cộng hòa Argentina');
GO

-- Insert data into Reference.Occupations (Same as DB_BCA)
INSERT INTO [Reference].[Occupations] ([occupation_id], [occupation_code], [occupation_name], [description]) VALUES
(1, 'MGMT', N'Quản lý và lãnh đạo', N'Các vị trí quản lý cấp cao và lãnh đạo trong tổ chức'),
-- ... (Copy all occupation inserts from DB_BCA section above) ...
(10, 'OTHR', N'Khác', N'Các nghề khác không thuộc các nhóm trên');
GO

-- Insert data into Reference.Authorities (Same as DB_BCA - Example data)
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [address_detail], [phone], [email], [province_id], [district_id], [ward_id], [parent_authority_id], [is_active]) VALUES
(1, 'BCA', N'Bộ Công an', N'Bộ', N'Số 44 Yết Kiêu, Hoàn Kiếm, Hà Nội', '024 3825 6255', 'bocongan@mps.gov.vn', 1, 102, NULL, NULL, 1),
-- ... (Copy all authority inserts from DB_BCA section above) ...
(200, 'UBND-BD', N'UBND quận Ba Đình', N'UBND cấp quận/huyện', N'18 Trần Phú, Ba Đình, Hà Nội', '024 3823 1234', 'ubndbadinh@hanoi.gov.vn', 1, 101, NULL, 30, 1);
GO


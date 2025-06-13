-- Script để thêm dữ liệu mẫu cho các bảng tham chiếu trong DB_Reference
-- Script này nên được chạy sau khi đã tạo tất cả các bảng và ràng buộc

USE [DB_BCA];
GO

PRINT N'Thêm dữ liệu mẫu cho các bảng tham chiếu trong DB_Reference...';

--------------------------------------------------------------------------------
-- 1. Reference.Regions (Vùng/Miền địa lý)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.Regions...';
INSERT INTO [Reference].[Regions] ([region_id], [region_code], [region_name], [description])
VALUES 
    (1, 'DBSH', N'Đồng bằng sông Hồng', N'Vùng đồng bằng sông Hồng, Bắc Bộ'),
    (2, 'TDMNPB', N'Trung du và miền núi phía Bắc', N'Vùng trung du và miền núi phía Bắc'),
    (3, 'BTB', N'Bắc Trung Bộ', N'Vùng Bắc Trung Bộ'),
    (4, 'DHNTB', N'Duyên hải Nam Trung Bộ', N'Vùng duyên hải Nam Trung Bộ'),
    (5, 'TNGUYÊN', N'Tây Nguyên', N'Vùng Tây Nguyên'),
    (6, 'ĐNBỘ', N'Đông Nam Bộ', N'Vùng Đông Nam Bộ'),
    (7, 'ĐBSCL', N'Đồng bằng sông Cửu Long', N'Vùng đồng bằng sông Cửu Long');
GO

--------------------------------------------------------------------------------
-- 2. Reference.Provinces (Tỉnh/Thành phố trực thuộc trung ương)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.Provinces...';
INSERT INTO [Reference].[Provinces] ([province_id], [province_code], [province_name], [region_id], [is_city], [gso_code])
VALUES 
    -- Đồng bằng sông Hồng
    (1, 'HNO', N'Thành phố Hà Nội', 1, 1, '01'),
    (2, 'VPC', N'Tỉnh Vĩnh Phúc', 1, 0, '26'),
    (3, 'BNI', N'Tỉnh Bắc Ninh', 1, 0, '27'),
    (4, 'QNI', N'Tỉnh Quảng Ninh', 1, 0, '22'),
    (5, 'HDG', N'Tỉnh Hải Dương', 1, 0, '30'),
    (6, 'HPG', N'Thành phố Hải Phòng', 1, 1, '31'),
    (7, 'HPH', N'Tỉnh Hưng Yên', 1, 0, '33'),
    (8, 'TBH', N'Tỉnh Thái Bình', 1, 0, '34'),
    (9, 'HNM', N'Tỉnh Hà Nam', 1, 0, '35'),
    (10, 'NDH', N'Tỉnh Nam Định', 1, 0, '36'),
    (11, 'NBH', N'Tỉnh Ninh Bình', 1, 0, '37'),
    
    -- Trung du và miền núi phía Bắc
    (12, 'HG1', N'Tỉnh Hà Giang', 2, 0, '02'),
    (13, 'CAB', N'Tỉnh Cao Bằng', 2, 0, '04'),
    (14, 'BKN', N'Tỉnh Bắc Kạn', 2, 0, '06'),
    (15, 'TQG', N'Tỉnh Tuyên Quang', 2, 0, '08'),
    (16, 'LCU', N'Tỉnh Lào Cai', 2, 0, '10'),
    (17, 'YBI', N'Tỉnh Yên Bái', 2, 0, '15'),
    (18, 'TNG', N'Tỉnh Thái Nguyên', 2, 0, '19'),
    (19, 'LGS', N'Tỉnh Lạng Sơn', 2, 0, '20'),
    (20, 'BCC', N'Tỉnh Bắc Giang', 2, 0, '24'),
    (21, 'PKU', N'Tỉnh Phú Thọ', 2, 0, '25'),
    (22, 'DBI', N'Tỉnh Điện Biên', 2, 0, '11'),
    (23, 'LAC', N'Tỉnh Lai Châu', 2, 0, '12'),
    (24, 'SLU', N'Tỉnh Sơn La', 2, 0, '14'),
    (25, 'HBH', N'Tỉnh Hoà Bình', 2, 0, '17'),
    
    -- Bắc Trung Bộ
    (26, 'THH', N'Tỉnh Thanh Hóa', 3, 0, '38'),
    (27, 'NAN', N'Tỉnh Nghệ An', 3, 0, '40'),
    (28, 'HTH', N'Tỉnh Hà Tĩnh', 3, 0, '42'),
    (29, 'QBH', N'Tỉnh Quảng Bình', 3, 0, '44'),
    (30, 'QTR', N'Tỉnh Quảng Trị', 3, 0, '45'),
    (31, 'TTH', N'Tỉnh Thừa Thiên Huế', 3, 0, '46'),
    
    -- Duyên hải Nam Trung Bộ
    (32, 'DNG', N'Thành phố Đà Nẵng', 4, 1, '48'),
    (33, 'QNM', N'Tỉnh Quảng Nam', 4, 0, '49'),
    (34, 'QNG', N'Tỉnh Quảng Ngãi', 4, 0, '51'), -- Đã sửa QNI thành QNG
    (35, 'BDH', N'Tỉnh Bình Định', 4, 0, '52'),
    (36, 'PHYN', N'Tỉnh Phú Yên', 4, 0, '54'),
    (37, 'KHA', N'Tỉnh Khánh Hòa', 4, 0, '56'),
    (38, 'NTN', N'Tỉnh Ninh Thuận', 4, 0, '58'),
    (39, 'BTN', N'Tỉnh Bình Thuận', 4, 0, '60'),
    
    -- Tây Nguyên
    (40, 'KTM', N'Tỉnh Kon Tum', 5, 0, '62'),
    (41, 'GLI', N'Tỉnh Gia Lai', 5, 0, '64'),
    (42, 'DLK', N'Tỉnh Đắk Lắk', 5, 0, '66'),
    (43, 'DKN', N'Tỉnh Đắk Nông', 5, 0, '67'),
    (44, 'LDG', N'Tỉnh Lâm Đồng', 5, 0, '68'),
    
    -- Đông Nam Bộ
    (45, 'HCM', N'Thành phố Hồ Chí Minh', 6, 1, '79'),
    (46, 'BDG', N'Tỉnh Bình Dương', 6, 0, '74'),
    (47, 'BPC', N'Tỉnh Bình Phước', 6, 0, '70'),
    (48, 'DNI', N'Tỉnh Đồng Nai', 6, 0, '75'),
    (49, 'TNI', N'Tỉnh Tây Ninh', 6, 0, '72'),
    (50, 'VTU', N'Tỉnh Bà Rịa - Vũng Tàu', 6, 0, '77'),
    
    -- Đồng bằng sông Cửu Long
    (51, 'LAN', N'Tỉnh Long An', 7, 0, '80'),
    (52, 'TGG', N'Tỉnh Tiền Giang', 7, 0, '82'),
    (53, 'BTE', N'Tỉnh Bến Tre', 7, 0, '83'),
    (54, 'TVH', N'Tỉnh Trà Vinh', 7, 0, '84'),
    (55, 'VLG', N'Tỉnh Vĩnh Long', 7, 0, '86'),
    (56, 'DTP', N'Tỉnh Đồng Tháp', 7, 0, '87'),
    (57, 'AGG', N'Tỉnh An Giang', 7, 0, '89'),
    (58, 'KGG', N'Tỉnh Kiên Giang', 7, 0, '91'),
    (59, 'CTH', N'Thành phố Cần Thơ', 7, 1, '92'),
    (60, 'HGG', N'Tỉnh Hậu Giang', 7, 0, '93'),
    (61, 'STG', N'Tỉnh Sóc Trăng', 7, 0, '94'),
    (62, 'BMU', N'Tỉnh Bạc Liêu', 7, 0, '95'),
    (63, 'CMU', N'Tỉnh Cà Mau', 7, 0, '96');
GO

--------------------------------------------------------------------------------
-- Một vài quận/huyện và phường/xã của Hà Nội làm mẫu
-- 3. Reference.Districts (Quận/Huyện/Thị xã)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu mẫu cho Reference.Districts (Hà Nội)...';
INSERT INTO [Reference].[Districts] ([district_id], [district_code], [district_name], [province_id], [is_urban], [gso_code])
VALUES 
    (101, 'HN-QBA', N'Quận Ba Đình', 1, 1, '001'),
    (102, 'HN-QHK', N'Quận Hoàn Kiếm', 1, 1, '002'),
    (103, 'HN-QTX', N'Quận Tây Hồ', 1, 1, '003'),
    (104, 'HN-QLC', N'Quận Long Biên', 1, 1, '004'),
    (105, 'HN-QCG', N'Quận Cầu Giấy', 1, 1, '005'),
    (106, 'HN-QDK', N'Quận Đống Đa', 1, 1, '006'),
    (107, 'HN-QHM', N'Quận Hai Bà Trưng', 1, 1, '007'),
    (108, 'HN-QHD', N'Quận Hoàng Mai', 1, 1, '008'),
    (109, 'HN-QTL', N'Quận Thanh Xuân', 1, 1, '009'),
    (110, 'HN-HBV', N'Huyện Ba Vì', 1, 0, '016'),
    (111, 'HN-HCL', N'Huyện Chương Mỹ', 1, 0, '020'),
    (112, 'HN-HPX', N'Huyện Phúc Thọ', 1, 0, '017'),
    (113, 'HN-HDD', N'Huyện Đan Phượng', 1, 0, '018'),
    (114, 'HN-HSO', N'Huyện Sóc Sơn', 1, 0, '012');
GO

--------------------------------------------------------------------------------
-- 4. Reference.Wards (Phường/Xã)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu mẫu cho Reference.Wards (Ba Đình, Hà Nội)...';
INSERT INTO [Reference].[Wards] ([ward_id], [ward_code], [ward_name], [district_id], [is_urban], [gso_code])
VALUES 
    (1001, 'HN-BA-PX', N'Phường Phúc Xá', 101, 1, '00001'),
    (1002, 'HN-BA-TX', N'Phường Trúc Bạch', 101, 1, '00004'),
    (1003, 'HN-BA-VH', N'Phường Vĩnh Phúc', 101, 1, '00006'),
    (1004, 'HN-BA-CT', N'Phường Cống Vị', 101, 1, '00007'),
    (1005, 'HN-BA-LX', N'Phường Liễu Giai', 101, 1, '00008'),
    (1006, 'HN-BA-DCA', N'Phường Đội Cấn', 101, 1, '00010'),
    (1007, 'HN-BA-NTB', N'Phường Ngọc Khánh', 101, 1, '00013'),
    (1008, 'HN-BA-KMA', N'Phường Kim Mã', 101, 1, '00016'),
    (1009, 'HN-BA-GVC', N'Phường Giảng Võ', 101, 1, '00019'),
    (1010, 'HN-BA-THL', N'Phường Thành Công', 101, 1, '00022');
GO

--------------------------------------------------------------------------------
-- 5. Reference.Ethnicities (Dân tộc)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.Ethnicities...';
INSERT INTO [Reference].[Ethnicities] ([ethnicity_id], [ethnicity_code], [ethnicity_name], [description], [population])
VALUES 
    (1, 'KINH', N'Kinh', N'Dân tộc Kinh (người Việt)', 85320000),
    (2, 'TAY', N'Tày', N'Dân tộc Tày', 1851000),
    (3, 'THAI', N'Thái', N'Dân tộc Thái', 1840000),
    (4, 'MUONG', N'Mường', N'Dân tộc Mường', 1450000),
    (5, 'KHMER', N'Khmer', N'Dân tộc Khmer', 1320000),
    (6, 'HMONG', N'H`Mông', N'Dân tộc H`Mông', 1250000),
    (7, 'NUG', N'Nùng', N'Dân tộc Nùng', 1080000),
    (8, 'HOA', N'Hoa', N'Dân tộc Hoa', 820000),
    (9, 'DAO', N'Dao', N'Dân tộc Dao', 850000),
    (10, 'GIA-RAI', N'Gia Rai', N'Dân tộc Gia Rai', 500000),
    (11, 'EDE', N'Ê Đê', N'Dân tộc Ê Đê', 398000),
    (12, 'BA-NA', N'Ba Na', N'Dân tộc Ba Na', 250000),
    (13, 'XƠĐĂNG', N'Xơ Đăng', N'Dân tộc Xơ Đăng', 195000),
    (14, 'SAN-DIU', N'Sán Dìu', N'Dân tộc Sán Dìu', 176000),
    (15, 'CHAM', N'Chăm', N'Dân tộc Chăm', 167000);
GO

--------------------------------------------------------------------------------
-- 6. Reference.Religions (Tôn giáo)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.Religions...';
INSERT INTO [Reference].[Religions] ([religion_id], [religion_code], [religion_name], [description], [followers])
VALUES 
    (1, 'KHONG', N'Không', N'Không theo tôn giáo', NULL),
    (2, 'PHAT', N'Phật giáo', N'Phật giáo', 14000000),
    (3, 'CONG', N'Công giáo', N'Công giáo Roma', 7000000),
    (4, 'TIN', N'Tin Lành', N'Tin Lành các hệ phái', 1000000),
    (5, 'CAO-DAI', N'Cao Đài', N'Đạo Cao Đài', 2500000),
    (6, 'HOA-HAO', N'Phật giáo Hòa Hảo', N'Phật giáo Hòa Hảo', 1500000),
    (7, 'HOI', N'Hồi giáo', N'Hồi giáo', 75000),
    (8, 'BA-HAI', N'Baha''i', N'Tôn giáo Baha''i', 7000),
    (9, 'TU-AN', N'Tứ Ân Hiếu Nghĩa', N'Tứ Ân Hiếu Nghĩa', 70000),
    (10, 'TINH-DO', N'Tịnh Độ Cư Sĩ Phật Hội', N'Tịnh Độ Cư Sĩ Phật Hội', 65000);
GO

--------------------------------------------------------------------------------
-- 7. Reference.Nationalities (Quốc tịch)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.Nationalities...';
INSERT INTO [Reference].[Nationalities] ([nationality_id], [nationality_code], [iso_code_alpha2], [iso_code_alpha3], [nationality_name], [country_name])
VALUES 
    (1, 'VNM', 'VN', 'VNM', N'Việt Nam', N'Việt Nam'),
    (2, 'USA', 'US', 'USA', N'Hoa Kỳ', N'Hoa Kỳ'),
    (3, 'CHN', 'CN', 'CHN', N'Trung Quốc', N'Trung Quốc'),
    (4, 'KOR', 'KR', 'KOR', N'Hàn Quốc', N'Hàn Quốc'),
    (5, 'JPN', 'JP', 'JPN', N'Nhật Bản', N'Nhật Bản'),
    (6, 'LAO', 'LA', 'LAO', N'Lào', N'Cộng hòa Dân chủ Nhân dân Lào'),
    (7, 'KHM', 'KH', 'KHM', N'Campuchia', N'Campuchia'),
    (8, 'THA', 'TH', 'THA', N'Thái Lan', N'Thái Lan'),
    (9, 'MYS', 'MY', 'MYS', N'Malaysia', N'Malaysia'),
    (10, 'SGP', 'SG', 'SGP', N'Singapore', N'Singapore'),
    (11, 'PHL', 'PH', 'PHL', N'Philippines', N'Philippines'),
    (12, 'IDN', 'ID', 'IDN', N'Indonesia', N'Indonesia'),
    (13, 'GBR', 'GB', 'GBR', N'Vương quốc Anh', N'Vương quốc Anh'),
    (14, 'FRA', 'FR', 'FRA', N'Pháp', N'Pháp'),
    (15, 'DEU', 'DE', 'DEU', N'Đức', N'Đức'),
    (16, 'ITA', 'IT', 'ITA', N'Ý', N'Ý'),
    (17, 'RUS', 'RU', 'RUS', N'Nga', N'Liên bang Nga'),
    (18, 'CAN', 'CA', 'CAN', N'Canada', N'Canada'),
    (19, 'AUS', 'AU', 'AUS', N'Úc', N'Úc'),
    (20, 'NZL', 'NZ', 'NZL', N'New Zealand', N'New Zealand');
GO

--------------------------------------------------------------------------------
-- 8. Reference.Occupations (Nghề nghiệp)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.Occupations...';
INSERT INTO [Reference].[Occupations] ([occupation_id], [occupation_code], [occupation_name], [description])
VALUES 
    (1, 'NN001', N'Nông dân', N'Người làm nông nghiệp'),
    (2, 'CN001', N'Công nhân', N'Người lao động trong các ngành công nghiệp'),
    (3, 'CBCC001', N'Cán bộ, công chức nhà nước', N'Người làm việc trong cơ quan nhà nước'),
    (4, 'GVIEN001', N'Giáo viên', N'Giáo viên các cấp'),
    (5, 'BSSI001', N'Bác sĩ', N'Bác sĩ y khoa'),
    (6, 'KYTHUAT001', N'Kỹ sư', N'Kỹ sư các ngành'),
    (7, 'NVVP001', N'Nhân viên văn phòng', N'Nhân viên hành chính, văn phòng'),
    (8, 'KDOANH001', N'Kinh doanh', N'Người làm kinh doanh, buôn bán'),
    (9, 'LUATSU001', N'Luật sư', N'Người hành nghề luật'),
    (10, 'NGHE001', N'Nghệ sĩ', N'Người hoạt động nghệ thuật'),
    (11, 'HOCSINH001', N'Học sinh', N'Học sinh các cấp'),
    (12, 'SINHVIEN001', N'Sinh viên', N'Sinh viên đại học, cao đẳng'),
    (13, 'QUANDOI001', N'Quân nhân', N'Người phục vụ trong quân đội'),
    (14, 'CONG001', N'Công an', N'Người phục vụ trong ngành công an'),
    (15, 'HUUTRI001', N'Nghỉ hưu', N'Người đã nghỉ hưu'),
    (16, 'DULICH001', N'Hướng dẫn viên du lịch', N'Người làm hướng dẫn viên du lịch'),
    (17, 'GIAOVIEN001', N'Giảng viên đại học', N'Giảng viên tại các trường đại học, cao đẳng'),
    (18, 'CNTT001', N'Lập trình viên', N'Người làm lập trình, phát triển phần mềm'),
    (19, 'TAICHINH001', N'Nhân viên tài chính', N'Người làm trong lĩnh vực tài chính, ngân hàng'),
    (20, 'KHAC001', N'Nghề khác', N'Các nghề khác chưa phân loại');
GO

--------------------------------------------------------------------------------
-- 9. Reference.Authorities (Cơ quan có thẩm quyền)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu mẫu cho Reference.Authorities...';
INSERT INTO [Reference].[Authorities] ([authority_id], [authority_code], [authority_name], [authority_type], [province_id], [is_active])
VALUES 
    -- Cấp Bộ
    (1, 'BCA', N'Bộ Công an', N'Bộ', 1, 1),
    (2, 'BTP', N'Bộ Tư pháp', N'Bộ', 1, 1),
    (3, 'BQP', N'Bộ Quốc phòng', N'Bộ', 1, 1),
    (4, 'BYT', N'Bộ Y tế', N'Bộ', 1, 1),
    (5, 'BGDDT', N'Bộ Giáo dục và Đào tạo', N'Bộ', 1, 1),
    
    -- Cấp Cục
    (11, 'CSCD', N'Cục Cảnh sát quản lý hành chính về trật tự xã hội', N'Cục', 1, 1),
    (12, 'CSGT', N'Cục Cảnh sát giao thông', N'Cục', 1, 1),
    (13, 'ANNINH', N'Cục An ninh nội địa', N'Cục', 1, 1),
    (14, 'CSHS', N'Cục Cảnh sát hình sự', N'Cục', 1, 1),
    
    -- Cấp Tỉnh/Thành phố (Công an tỉnh/thành phố)
    (101, 'CA-HNO', N'Công an thành phố Hà Nội', N'Công an Tỉnh/Thành phố', 1, 1),
    (102, 'CA-HCM', N'Công an thành phố Hồ Chí Minh', N'Công an Tỉnh/Thành phố', 45, 1),
    (103, 'CA-DNG', N'Công an thành phố Đà Nẵng', N'Công an Tỉnh/Thành phố', 32, 1),
    
    -- Sở Tư pháp
    (201, 'STP-HNO', N'Sở Tư pháp thành phố Hà Nội', N'Sở', 1, 1),
    (202, 'STP-HCM', N'Sở Tư pháp thành phố Hồ Chí Minh', N'Sở', 45, 1),
    (203, 'STP-DNG', N'Sở Tư pháp thành phố Đà Nẵng', N'Sở', 32, 1),
    
    -- UBND Quận/Huyện (ví dụ một số quận ở Hà Nội)
    (301, 'UBND-Q-BD', N'UBND quận Ba Đình', N'UBND Quận', 1, 1),
    (302, 'UBND-Q-HK', N'UBND quận Hoàn Kiếm', N'UBND Quận', 1, 1),
    (303, 'UBND-Q-CG', N'UBND quận Cầu Giấy', N'UBND Quận', 1, 1),
    (304, 'UBND-Q-DD', N'UBND quận Đống Đa', N'UBND Quận', 1, 1),
    
    -- Công an Quận/Huyện (ví dụ một số quận ở Hà Nội)
    (401, 'CA-Q-BD', N'Công an quận Ba Đình', N'Công an Quận', 1, 1),
    (402, 'CA-Q-HK', N'Công an quận Hoàn Kiếm', N'Công an Quận', 1, 1),
    (403, 'CA-Q-CG', N'Công an quận Cầu Giấy', N'Công an Quận', 1, 1),
    (404, 'CA-Q-DD', N'Công an quận Đống Đa', N'Công an Quận', 1, 1);
GO
-- Cập nhật quan hệ parent_authority_id
UPDATE [Reference].[Authorities] SET [parent_authority_id] = 1 WHERE [authority_id] IN (11, 12, 13, 14);
UPDATE [Reference].[Authorities] SET [parent_authority_id] = 1 WHERE [authority_id] IN (101, 102, 103);
UPDATE [Reference].[Authorities] SET [parent_authority_id] = 2 WHERE [authority_id] IN (201, 202, 203);
UPDATE [Reference].[Authorities] SET [parent_authority_id] = 101 WHERE [authority_id] IN (401, 402, 403, 404);
GO

--------------------------------------------------------------------------------
-- 10. Reference.RelationshipTypes (Loại quan hệ gia đình/thân nhân)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.RelationshipTypes...';
INSERT INTO [Reference].[RelationshipTypes] ([relationship_type_id], [relationship_code], [relationship_name], [description])
VALUES 
    (1, 'CHA', N'Cha', N'Cha đẻ'),
    (2, 'ME', N'Mẹ', N'Mẹ đẻ'),
    (3, 'CON', N'Con', N'Con đẻ'),
    (4, 'VO', N'Vợ', N'Vợ'),
    (5, 'CHONG', N'Chồng', N'Chồng'),
    (6, 'ANH', N'Anh', N'Anh ruột'),
    (7, 'CHI', N'Chị', N'Chị ruột'),
    (8, 'EM', N'Em', N'Em ruột'),
    (9, 'ONG', N'Ông', N'Ông nội/ngoại'),
    (10, 'BA', N'Bà', N'Bà nội/ngoại'),
    (11, 'CHAU', N'Cháu', N'Cháu nội/ngoại'),
    (12, 'CHA_NUOI', N'Cha nuôi', N'Cha nuôi'),
    (13, 'ME_NUOI', N'Mẹ nuôi', N'Mẹ nuôi'),
    (14, 'CON_NUOI', N'Con nuôi', N'Con nuôi'),
    (15, 'BACSI', N'Bác/Chú/Cậu/Dượng', N'Bác trai/Chú/Cậu/Dượng'),
    (16, 'CO_DI_THIM', N'Cô/Dì/Thím/Mợ', N'Cô/Dì/Thím/Mợ'),
    (17, 'NGUOI_GIAM_HO', N'Người giám hộ', N'Người giám hộ hợp pháp'),
    (18, 'NGUOI_DUOC_GIAM_HO', N'Người được giám hộ', N'Người được giám hộ');
GO
-- Cập nhật inverse_relationship_type_id
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 3 WHERE [relationship_type_id] = 1; -- Cha -> Con
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 3 WHERE [relationship_type_id] = 2; -- Mẹ -> Con
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 1 WHERE [relationship_type_id] = 3 AND [relationship_code] = 'CON'; -- Con -> Cha
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 5 WHERE [relationship_type_id] = 4; -- Vợ -> Chồng
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 4 WHERE [relationship_type_id] = 5; -- Chồng -> Vợ
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 8 WHERE [relationship_type_id] = 6; -- Anh -> Em
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 8 WHERE [relationship_type_id] = 7; -- Chị -> Em
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 6 WHERE [relationship_type_id] = 8; -- Em -> Anh
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 11 WHERE [relationship_type_id] = 9; -- Ông -> Cháu
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 11 WHERE [relationship_type_id] = 10; -- Bà -> Cháu
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 9 WHERE [relationship_type_id] = 11; -- Cháu -> Ông
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 14 WHERE [relationship_type_id] = 12; -- Cha nuôi -> Con nuôi
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 14 WHERE [relationship_type_id] = 13; -- Mẹ nuôi -> Con nuôi
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 12 WHERE [relationship_type_id] = 14; -- Con nuôi -> Cha nuôi
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 18 WHERE [relationship_type_id] = 17; -- Người giám hộ -> Người được giám hộ
UPDATE [Reference].[RelationshipTypes] SET [inverse_relationship_type_id] = 17 WHERE [relationship_type_id] = 18; -- Người được giám hộ -> Người giám hộ
GO

--------------------------------------------------------------------------------
-- 11. Reference.PrisonFacilities (Cơ sở giam giữ)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu mẫu cho Reference.PrisonFacilities...';
SET IDENTITY_INSERT [Reference].[PrisonFacilities] ON;
INSERT INTO [Reference].[PrisonFacilities] ([prison_facility_id], [facility_code], [facility_name], [facility_type], [province_id], [managing_authority_id], [is_active])
VALUES 
    (1, 'TG-HOABINH', N'Trại giam Hòa Bình', N'Trại giam', 25, 1, 1),
    (2, 'TG-NINHBINH', N'Trại giam Ninh Bình', N'Trại giam', 11, 1, 1),
    (3, 'TG-THANHHOA', N'Trại giam Thanh Hóa', N'Trại giam', 26, 1, 1),
    (4, 'TG-DAKLAK', N'Trại giam Đắk Lắk', N'Trại giam', 42, 1, 1),
    (5, 'TG-DONGNAI', N'Trại giam Đồng Nai', N'Trại giam', 48, 1, 1),
    (6, 'TTGIAM-HNO', N'Trại tạm giam số 1 - Công an TP. Hà Nội', N'Trại tạm giam', 1, 101, 1),
    (7, 'TTGIAM-HCM', N'Trại tạm giam Chí Hòa - Công an TP. HCM', N'Trại tạm giam', 45, 102, 1),
    (8, 'CSGDBB-1', N'Cơ sở giáo dục bắt buộc số 1', N'Cơ sở giáo dục bắt buộc', 8, 1, 1),
    (9, 'CSGDBB-2', N'Cơ sở giáo dục bắt buộc số 2', N'Cơ sở giáo dục bắt buộc', 51, 1, 1),
    (10, 'CSGDBB-3', N'Cơ sở giáo dục bắt buộc số 3', N'Cơ sở giáo dục bắt buộc', 29, 1, 1);
SET IDENTITY_INSERT [Reference].[PrisonFacilities] OFF;
GO

--------------------------------------------------------------------------------
-- 12. Reference.Genders (Giới tính)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.Genders...';
INSERT INTO [Reference].[Genders] ([gender_id], [gender_code], [gender_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'NAM', N'Nam', N'Giới tính nam', 1),
    (2, 'NU', N'Nữ', N'Giới tính nữ', 2),
    (3, 'KHAC', N'Khác', N'Giới tính khác', 3);
GO

--------------------------------------------------------------------------------
-- 13. Reference.MaritalStatuses (Tình trạng hôn nhân)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.MaritalStatuses...';
INSERT INTO [Reference].[MaritalStatuses] ([marital_status_id], [marital_status_code], [marital_status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'DOCTHAN', N'Độc thân', N'Chưa kết hôn', 1),
    (2, 'DAKETHON', N'Đã kết hôn', N'Đã đăng ký kết hôn và hiện đang trong hôn nhân', 2),
    (3, 'LYHON', N'Ly hôn', N'Đã ly hôn và chưa tái hôn', 3),
    (4, 'GOAVO', N'Góa vợ/chồng', N'Vợ/chồng đã mất và chưa tái hôn', 4);
GO

--------------------------------------------------------------------------------
-- 14. Reference.EducationLevels (Trình độ học vấn)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.EducationLevels...';
INSERT INTO [Reference].[EducationLevels] ([education_level_id], [education_level_code], [education_level_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'MG', N'Mầm non', N'Mầm non', 1),
    (2, 'TH', N'Tiểu học', N'Tiểu học (Cấp 1)', 2),
    (3, 'THCS', N'Trung học cơ sở', N'Trung học cơ sở (Cấp 2)', 3),
    (4, 'THPT', N'Trung học phổ thông', N'Trung học phổ thông (Cấp 3)', 4),
    (5, 'TC', N'Trung cấp', N'Trung cấp nghề/chuyên nghiệp', 5),
    (6, 'CD', N'Cao đẳng', N'Cao đẳng', 6),
    (7, 'DH', N'Đại học', N'Đại học', 7),
    (8, 'THACSI', N'Thạc sĩ', N'Thạc sĩ', 8),
    (9, 'TIENSI', N'Tiến sĩ', N'Tiến sĩ', 9),
    (10, 'KHONGBANGCAP', N'Không có bằng cấp', N'Không đi học hoặc chưa tốt nghiệp tiểu học', 10);
GO

-- Xóa bỏ phần chèn dữ liệu vào bảng Reference.CitizenDeathStatuses đã bị loại bỏ
-- --------------------------------------------------------------------------------
-- -- 15. Reference.CitizenDeathStatuses (Trạng thái tử vong)
-- --------------------------------------------------------------------------------
-- PRINT N'  Thêm dữ liệu cho Reference.CitizenDeathStatuses...';
-- INSERT INTO [Reference].[CitizenDeathStatuses] ([citizen_death_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
-- VALUES 
--     (1, 'CONSONG', N'Còn sống', N'Công dân còn sống', 1),
--     (2, 'DAMAT', N'Đã mất', N'Công dân đã mất và có giấy chứng tử', 2),
--     (3, 'MATTICH', N'Mất tích', N'Công dân mất tích theo quyết định của tòa án', 3);
-- GO

--------------------------------------------------------------------------------
-- 16. Reference.BloodTypes (Nhóm máu)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.BloodTypes...';
INSERT INTO [Reference].[BloodTypes] ([blood_type_id], [blood_type_code], [blood_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'A_PLUS', N'A+', N'Nhóm máu A dương tính', 1),
    (2, 'A_MINUS', N'A-', N'Nhóm máu A âm tính', 2),
    (3, 'B_PLUS', N'B+', N'Nhóm máu B dương tính', 3),
    (4, 'B_MINUS', N'B-', N'Nhóm máu B âm tính', 4),
    (5, 'AB_PLUS', N'AB+', N'Nhóm máu AB dương tính', 5),
    (6, 'AB_MINUS', N'AB-', N'Nhóm máu AB âm tính', 6),
    (7, 'O_PLUS', N'O+', N'Nhóm máu O dương tính', 7),
    (8, 'O_MINUS', N'O-', N'Nhóm máu O âm tính', 8),
    (9, 'KHONGBIET', N'Không biết', N'Chưa xác định nhóm máu', 9);
GO

--------------------------------------------------------------------------------
-- 17. Reference.IdentificationCardTypes (Loại thẻ CCCD/CMND)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.IdentificationCardTypes...';
INSERT INTO [Reference].[IdentificationCardTypes] ([card_type_id], [card_type_code], [card_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'CMND9', N'CMND 9 số', N'Chứng minh nhân dân 9 số (cũ)', 1),
    (2, 'CMND12', N'CMND 12 số', N'Chứng minh nhân dân 12 số', 2),
    (3, 'CCCD_CHIP', N'CCCD gắn chip', N'Căn cước công dân gắn chip điện tử', 3),
    (4, 'CCCD_KHONGCHIP', N'CCCD không chip', N'Căn cước công dân không gắn chip', 4),
    (5, 'HC', N'Hộ chiếu', N'Hộ chiếu', 5);
GO

--------------------------------------------------------------------------------
-- 18. Reference.IdentificationCardStatuses (Trạng thái thẻ CCCD/CMND)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.IdentificationCardStatuses...';
INSERT INTO [Reference].[IdentificationCardStatuses] ([card_status_id], [card_status_code], [card_status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'DANGSUDUNG', N'Đang sử dụng', N'Thẻ đang được sử dụng', 1),
    (2, 'HETHAN', N'Hết hạn', N'Thẻ đã hết hạn', 2),
    (3, 'DAHUYHUY', N'Đã hủy', N'Thẻ đã bị hủy (khi cấp đổi hoặc cấp lại)', 3),
    (4, 'BITHUHOI', N'Bị thu hồi', N'Thẻ bị thu hồi do vi phạm', 4),
    (5, 'MATCAP', N'Mất cắp/thất lạc', N'Thẻ bị mất cắp hoặc thất lạc', 5),
    (6, 'HONG', N'Hỏng', N'Thẻ bị hỏng, không sử dụng được', 6);
GO

--------------------------------------------------------------------------------
-- 19. Reference.ResidenceTypes (Loại cư trú)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.ResidenceTypes...';
INSERT INTO [Reference].[ResidenceTypes] ([residence_type_id], [residence_type_code], [residence_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'THUONGTRU', N'Thường trú', N'Cư trú ổn định, lâu dài tại một địa phương', 1),
    (2, 'TAMTRU', N'Tạm trú', N'Cư trú có thời hạn tại một địa phương không phải nơi thường trú', 2),
    (3, 'NGOAITRU', N'Ngoại trú', N'Người nước ngoài tạm trú tại Việt Nam', 3);
GO

--------------------------------------------------------------------------------
-- 20. Reference.ResidenceRegistrationStatuses (Trạng thái đăng ký cư trú)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.ResidenceRegistrationStatuses...';
INSERT INTO [Reference].[ResidenceRegistrationStatuses] ([res_reg_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'ACTIVE', N'Đang hiệu lực', N'Đăng ký cư trú đang có hiệu lực', 1),
    (2, 'EXPIRED', N'Hết hạn', N'Đăng ký cư trú đã hết hạn (áp dụng cho tạm trú)', 2),
    (3, 'CANCELLED', N'Đã hủy', N'Đăng ký cư trú đã bị hủy', 3),
    (4, 'PENDING', N'Đang xử lý', N'Đăng ký cư trú đang trong quá trình xử lý', 4),
    (5, 'TRANSFERRING', N'Đang chuyển', N'Đang trong quá trình chuyển đi nơi khác', 5);
GO

--------------------------------------------------------------------------------
-- 21. Reference.TemporaryAbsenceStatuses (Trạng thái tạm vắng)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.TemporaryAbsenceStatuses...';
INSERT INTO [Reference].[TemporaryAbsenceStatuses] ([temp_abs_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'ACTIVE', N'Đang tạm vắng', N'Hiện đang trong thời gian tạm vắng', 1),
    (2, 'RETURNED', N'Đã trở về', N'Đã trở về từ tạm vắng', 2),
    (3, 'EXPIRED', N'Hết hạn', N'Đã hết thời hạn tạm vắng nhưng chưa xác nhận trở về', 3),
    (4, 'CANCELLED', N'Đã hủy', N'Đã hủy đăng ký tạm vắng', 4),
    (5, 'EXTENDED', N'Đã gia hạn', N'Đã gia hạn thời gian tạm vắng', 5);
GO

--------------------------------------------------------------------------------
-- 22. Reference.DataSensitivityLevels (Mức độ nhạy cảm dữ liệu)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.DataSensitivityLevels...';
INSERT INTO [Reference].[DataSensitivityLevels] ([sensitivity_level_id], [level_code], [level_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'CONGKHAI', N'Công khai', N'Dữ liệu công khai, có thể chia sẻ rộng rãi', 1),
    (2, 'HANCHE', N'Hạn chế', N'Dữ liệu hạn chế, chỉ một số đơn vị được phép truy cập', 2),
    (3, 'BAOMAT', N'Bảo mật', N'Dữ liệu bảo mật, cần xác thực và phân quyền', 3),
    (4, 'TOIBAOLMAT', N'Tối bảo mật', N'Dữ liệu tối bảo mật, hạn chế tối đa truy cập', 4);
GO

--------------------------------------------------------------------------------
-- 23. Reference.CitizenStatusTypes (Loại trạng thái công dân)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.CitizenStatusTypes...';
INSERT INTO [Reference].[CitizenStatusTypes] ([citizen_status_id], [status_code], [status_name_vi], [description_vi], [display_order]) -- Đã sửa tên cột
VALUES 
    (1, 'CONSONG', N'Còn sống', N'Công dân còn sống', 1),
    (2, 'DAMAT', N'Đã mất', N'Công dân đã mất', 2),
    (3, 'MATTICH', N'Mất tích', N'Công dân mất tích', 3),
    (4, 'HANCHE_NLPL', N'Hạn chế năng lực pháp luật', N'Hạn chế năng lực hành vi dân sự', 4),
    (5, 'MATPLCD', N'Mất năng lực hành vi dân sự', N'Mất năng lực hành vi dân sự theo quyết định của tòa án', 5);
GO

--------------------------------------------------------------------------------
-- 24. Reference.CitizenMovementTypes (Loại di biến động dân cư)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.CitizenMovementTypes...';
INSERT INTO [Reference].[CitizenMovementTypes] ([movement_type_id], [movement_type_code], [movement_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'TRONGNUOC', N'Di chuyển trong nước', N'Di chuyển giữa các địa phương trong nước', 1),
    (2, 'XUATCANH', N'Xuất cảnh', N'Rời Việt Nam đi nước ngoài', 2),
    (3, 'NHAPCANH', N'Nhập cảnh', N'Từ nước ngoài vào Việt Nam', 3),
    (4, 'TAINHAPCANH', N'Tái nhập cảnh', N'Công dân Việt Nam trở về từ nước ngoài', 4),
    (5, 'DINUOCNGOAI', N'Định cư nước ngoài', N'Định cư lâu dài ở nước ngoài', 5),
    (6, 'HOIHUONG', N'Hồi hương', N'Người Việt định cư nước ngoài trở về Việt Nam', 6);
GO

--------------------------------------------------------------------------------
-- 25. Reference.CitizenMovementStatuses (Trạng thái di biến động dân cư)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.CitizenMovementStatuses...';
INSERT INTO [Reference].[CitizenMovementStatuses] ([movement_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'HOATDONG', N'Đang diễn ra', N'Di chuyển đang diễn ra', 1),
    (2, 'HOANTHANH', N'Đã hoàn thành', N'Di chuyển đã hoàn thành', 2),
    (3, 'DAHUY', N'Đã hủy', N'Di chuyển đã bị hủy', 3),
    (4, 'TAMHOAN', N'Tạm hoãn', N'Di chuyển đang tạm hoãn', 4),
    (5, 'CHOXULY', N'Chờ xử lý', N'Hồ sơ di chuyển đang chờ xử lý', 5);
GO

--------------------------------------------------------------------------------
-- 26. Reference.CrimeTypes (Loại tội phạm)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.CrimeTypes...';
INSERT INTO [Reference].[CrimeTypes] ([crime_type_id], [crime_type_code], [crime_type_name_vi], [description_vi], [severity_level])
VALUES 
    (1, 'ITNT', N'Tội phạm ít nghiêm trọng', N'Tội phạm ít nghiêm trọng theo BLHS', 1),
    (2, 'NGHIEMTRONG', N'Tội phạm nghiêm trọng', N'Tội phạm nghiêm trọng theo BLHS', 2),
    (3, 'RATNGHIEMTRONG', N'Tội phạm rất nghiêm trọng', N'Tội phạm rất nghiêm trọng theo BLHS', 3),
    (4, 'DACBIETNGHIEMTRONG', N'Tội phạm đặc biệt nghiêm trọng', N'Tội phạm đặc biệt nghiêm trọng theo BLHS', 4),
    (101, 'XPVPHC', N'Vi phạm hành chính', N'Xử phạt vi phạm hành chính', 0),
    -- Các tội phạm cụ thể
    (201, 'TP_CTNH', N'Tội cố ý gây thương tích hoặc gây tổn hại cho sức khỏe của người khác', N'Điều 134 BLHS', 2),
    (202, 'TP_GIETNGUOI', N'Tội giết người', N'Điều 123 BLHS', 4),
    (203, 'TP_TROMCAP', N'Tội trộm cắp tài sản', N'Điều 173 BLHS', 2),
    (204, 'TP_CUOPGIATTAISAN', N'Tội cướp giật tài sản', N'Điều 171 BLHS', 3),
    (205, 'TP_CUOPTAISAN', N'Tội cướp tài sản', N'Điều 168 BLHS', 3),
    (206, 'TP_LUADAO', N'Tội lừa đảo chiếm đoạt tài sản', N'Điều 174 BLHS', 2),
    (207, 'TP_BUONTHUOCTERILAC', N'Tội buôn bán trái phép chất ma túy', N'Điều 251 BLHS', 4),
    (208, 'TP_TANGTRUCHATTHUOC', N'Tội tàng trữ trái phép chất ma túy', N'Điều 249 BLHS', 3),
    (209, 'TP_MOSANXUAT', N'Tội mở sòng bạc hoặc tổ chức đánh bạc', N'Điều 322 BLHS', 2),
    (210, 'TP_TRACHNHIEMGAYTHIETHAI', N'Tội thiếu trách nhiệm gây hậu quả nghiêm trọng', N'Điều 360 BLHS', 2);
GO

--------------------------------------------------------------------------------
-- 27. Reference.AddressTypes (Loại địa chỉ)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.AddressTypes...';
INSERT INTO [Reference].[AddressTypes] ([address_type_id], [address_type_code], [address_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'THUONGTRU', N'Nơi thường trú', N'Địa chỉ thường trú', 1),
    (2, 'TAMTRU', N'Nơi tạm trú', N'Địa chỉ tạm trú', 2),
    (3, 'NOIOHIENTAI', N'Nơi ở hiện tại', N'Địa chỉ đang sinh sống hiện tại', 3),
    (4, 'NOILAMVIEC', N'Nơi làm việc', N'Địa chỉ nơi làm việc', 4),
    (5, 'QUEQUAN', N'Quê quán', N'Địa chỉ quê quán', 5),
    (6, 'NOISINH', N'Nơi sinh', N'Địa chỉ nơi sinh', 6);
GO

--------------------------------------------------------------------------------
-- 28. Reference.HouseholdTypes (Loại hộ khẩu)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.HouseholdTypes...';
INSERT INTO [Reference].[HouseholdTypes] ([household_type_id], [household_type_code], [household_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'HOGIADINH', N'Hộ gia đình', N'Hộ khẩu gia đình', 1),
    (2, 'HOTAPTHE', N'Hộ tập thể', N'Hộ khẩu tập thể (ký túc xá, doanh trại...)', 2),
    (3, 'HOTUCHUC', N'Hộ tổ chức', N'Hộ khẩu của tổ chức, cơ quan', 3),
    (4, 'HOCANSA', N'Hộ cá nhân', N'Hộ khẩu của cá nhân sống một mình', 4),
    (5, 'HOTONGIAO', N'Hộ tôn giáo', N'Hộ khẩu của cơ sở tôn giáo', 5);
GO

--------------------------------------------------------------------------------
-- 29. Reference.HouseholdStatuses (Trạng thái hộ khẩu)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.HouseholdStatuses...';
INSERT INTO [Reference].[HouseholdStatuses] ([household_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'DANGHOATDONG', N'Đang hoạt động', N'Hộ khẩu đang hoạt động bình thường', 1),
    (2, 'DACHUYENDI', N'Đã chuyển đi', N'Hộ khẩu đã chuyển đi nơi khác', 2),
    (3, 'DAGIAITAN', N'Đã giải tán', N'Hộ khẩu đã giải tán', 3),
    (4, 'TAMNGUNG', N'Tạm ngừng', N'Hộ khẩu tạm ngừng hoạt động', 4),
    (5, 'DADOICHU', N'Đã đổi chủ hộ', N'Hộ khẩu đã đổi chủ hộ', 5);
GO

--------------------------------------------------------------------------------
-- 30. Reference.RelationshipWithHeadTypes (Quan hệ với chủ hộ)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.RelationshipWithHeadTypes...';
INSERT INTO [Reference].[RelationshipWithHeadTypes] ([rel_with_head_id], [rel_code], [rel_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'CHUHO', N'Chủ hộ', N'Người đứng tên chủ hộ', 1),
    (2, 'VO', N'Vợ', N'Vợ của chủ hộ', 2),
    (3, 'CHONG', N'Chồng', N'Chồng của chủ hộ', 3),
    (4, 'CON', N'Con', N'Con đẻ của chủ hộ', 4),
    (5, 'CON_NUOI', N'Con nuôi', N'Con nuôi của chủ hộ', 5),
    (6, 'CHA', N'Cha', N'Cha đẻ của chủ hộ', 6),
    (7, 'ME', N'Mẹ', N'Mẹ đẻ của chủ hộ', 7),
    (8, 'CHA_NUOI', N'Cha nuôi', N'Cha nuôi của chủ hộ', 8),
    (9, 'ME_NUOI', N'Mẹ nuôi', N'Mẹ nuôi của chủ hộ', 9),
    (10, 'ONG', N'Ông', N'Ông nội/ngoại của chủ hộ', 10),
    (11, 'BA', N'Bà', N'Bà nội/ngoại của chủ hộ', 11),
    (12, 'ANH_CHI_EM', N'Anh/Chị/Em', N'Anh/Chị/Em ruột của chủ hộ', 12),
    (13, 'CHAU', N'Cháu', N'Cháu của chủ hộ', 13),
    (14, 'OTHER', N'Khác', N'Quan hệ khác', 14);
GO

--------------------------------------------------------------------------------
-- 31. Reference.HouseholdMemberStatuses (Trạng thái thành viên hộ)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.HouseholdMemberStatuses...';
INSERT INTO [Reference].[HouseholdMemberStatuses] ([member_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'ACTIVE', N'Đang cư trú', N'Thành viên đang cư trú tại hộ', 1),
    (2, 'LEFT', N'Đã chuyển đi', N'Thành viên đã chuyển đi', 2),
    (3, 'TEMPORARY_ABSENT', N'Tạm vắng', N'Thành viên tạm vắng', 3),
    (4, 'DECEASED', N'Đã mất', N'Thành viên đã mất', 4),
    (5, 'NEWBORN', N'Mới sinh', N'Thành viên mới sinh', 5);
GO

--------------------------------------------------------------------------------
-- 32. Reference.FamilyRelationshipStatuses (Trạng thái quan hệ gia đình)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.FamilyRelationshipStatuses...';
INSERT INTO [Reference].[FamilyRelationshipStatuses] ([family_rel_status_id], [status_code], [status_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'ACTIVE', N'Đang hiệu lực', N'Quan hệ đang hiệu lực', 1),
    (2, 'INACTIVE', N'Không hiệu lực', N'Quan hệ không còn hiệu lực', 2),
    (3, 'PENDING', N'Đang xử lý', N'Quan hệ đang trong quá trình xử lý', 3),
    (4, 'DISPUTED', N'Đang tranh chấp', N'Quan hệ đang tranh chấp', 4),
    (5, 'TEMPORARY', N'Tạm thời', N'Quan hệ tạm thời', 5),
    (6, 'PARTY_DECEASED', N'Bên liên quan đã mất', N'Quan hệ mà một bên đã qua đời', 6);
GO

--------------------------------------------------------------------------------
-- 33. Reference.PopulationChangeTypes (Loại thay đổi dân số)
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu cho Reference.PopulationChangeTypes...';
INSERT INTO [Reference].[PopulationChangeTypes] ([pop_change_type_id], [change_type_code], [change_type_name_vi], [description_vi], [display_order])
VALUES 
    (1, 'KHAISINH', N'Khai sinh', N'Đăng ký khai sinh', 1),
    (2, 'KHAITU', N'Khai tử', N'Đăng ký khai tử', 2),
    (3, 'KETHON', N'Kết hôn', N'Đăng ký kết hôn', 3),
    (4, 'LYHON', N'Ly hôn', N'Đăng ký ly hôn', 4),
    (5, 'NHANUOI', N'Nhận con nuôi', N'Đăng ký nhận con nuôi', 5),
    (6, 'CHUYENHUKHAU', N'Chuyển hộ khẩu', N'Chuyển hộ khẩu', 6),
    (7, 'TACHHO', N'Tách hộ', N'Tách hộ khẩu', 7),
    (8, 'NHAPHO', N'Nhập hộ', N'Nhập hộ khẩu', 8),
    (9, 'XUATCANH', N'Xuất cảnh', N'Xuất cảnh ra nước ngoài', 9),
    (10, 'NHAPCANH', N'Nhập cảnh', N'Nhập cảnh vào Việt Nam', 10),
    (11, 'DANGKYKHAIBAOTU', N'Đăng ký báo tử', N'Đăng ký báo tử', 11),
    (12, 'THAYDOITHONGTINCANHAN', N'Thay đổi thông tin cá nhân', N'Thay đổi thông tin cá nhân', 12);
GO

PRINT N'Hoàn thành thêm dữ liệu mẫu cho các bảng tham chiếu trong DB_Reference.';

PRINT N'  Thêm dữ liệu mẫu cho Reference.TransactionTypes...';
INSERT INTO [Reference].[TransactionTypes] ([transaction_type_id], [type_code], [type_name_vi], [description_vi], [display_order])
VALUES
    (1, 'MUA_BAN', N'Mua bán', N'Giao dịch mua bán tài sản', 1),
    (2, 'THUA_KE', N'Thừa kế', N'Giao dịch thừa kế tài sản', 2),
    (3, 'TANG_CHO', N'Tặng cho', N'Giao dịch tặng cho tài sản', 3),
    (4, 'CHUYEN_NHUONG_KHAC', N'Chuyển nhượng khác', N'Các hình thức chuyển nhượng khác (không phải mua bán, thừa kế, tặng cho)', 4);
GO


PRINT N'  Thêm dữ liệu mẫu cho Reference.AccommodationFacilityTypes...';
INSERT INTO [Reference].[AccommodationFacilityTypes] ([facility_type_id], [type_code], [type_name_vi], [description_vi], [display_order])
VALUES
    (1, 'CO_SO_TIN_NGUONG', N'Cơ sở tín ngưỡng', N'Chùa, đền, miếu, nhà thờ, thánh thất...', 1),
    (2, 'CO_SO_TON_GIAO', N'Cơ sở tôn giáo', N'Tu viện, tịnh xá, trụ sở giáo hội...', 2),
    (3, 'TRAI_GIAM', N'Trại giam', N'Cơ sở giam giữ phạm nhân', 3),
    (4, 'DON_VI_QUAN_DOI', N'Đơn vị Quân đội', N'Doanh trại quân đội, đơn vị đóng quân', 4),
    (5, 'CO_SO_TRO_GIUP_XH', N'Cơ sở trợ giúp xã hội', N'Trung tâm bảo trợ xã hội, mái ấm...', 5),
    (6, 'NHA_O_CONG_VU', N'Nhà ở công vụ', N'Nhà ở do nhà nước cấp cho cán bộ công chức', 6),
    (7, 'KY_TUC_XA', N'Ký túc xá', N'Ký túc xá học sinh, sinh viên', 7),
    (8, 'BENH_VIEN', N'Bệnh viện', N'Cơ sở y tế, bệnh viện', 8);
GO


PRINT N'  Thêm dữ liệu mẫu cho Reference.VehicleTypes...';
INSERT INTO [Reference].[VehicleTypes] ([vehicle_type_id], [type_code], [type_name_vi], [description_vi], [display_order])
VALUES
    (1, 'TAU_THUY', N'Tàu thủy', N'Tàu thuyền lớn hoạt động trên sông, biển', 1),
    (2, 'THUYEN', N'Thuyền', N'Thuyền nhỏ, ghe', 2),
    (3, 'O_TO_NHA_O', N'Ô tô nhà ở', N'Xe ô tô được thiết kế để ở (motorhome)', 3),
    (4, 'PHUONG_TIEN_KHAC', N'Phương tiện khác', N'Các loại phương tiện khác dùng để ở', 4);
GO


PRINT N'  Thêm dữ liệu mẫu cho Reference.TemporaryAbsenceTypes...';
INSERT INTO [Reference].[TemporaryAbsenceTypes] ([temp_abs_type_id], [type_code], [type_name_vi], [description_vi], [display_order])
VALUES
    (1, 'CONG_TAC', N'Công tác', N'Tạm vắng để công tác', 1),
    (2, 'HOC_TAP', N'Học tập', N'Tạm vắng để học tập', 2),
    (3, 'CHUA_BENH', N'Chữa bệnh', N'Tạm vắng để chữa bệnh', 3),
    (4, 'CHAP_HANH_AN', N'Chấp hành án', N'Tạm vắng để chấp hành án phạt tù', 4),
    (5, 'THAM_THAN', N'Thăm thân', N'Tạm vắng để thăm người thân', 5),
    (6, 'DU_LICH', N'Du lịch', N'Tạm vắng để du lịch', 6),
    (7, 'LY_DO_KHAC', N'Lý do khác', N'Các lý do tạm vắng khác', 7);
GO

PRINT N'  Thêm dữ liệu mẫu cho Reference.ResidenceStatusChangeReasons...';
INSERT INTO [Reference].[ResidenceStatusChangeReasons] ([reason_id], [reason_code], [reason_name_vi], [description_vi], [display_order])
VALUES
    (1, 'KHAISINH', N'Khai sinh', N'Đăng ký thường trú do khai sinh', 1),
    (2, 'KHAITU', N'Khai tử', N'Chấm dứt thường trú do khai tử', 2),
    (3, 'KETHON', N'Kết hôn', N'Thay đổi thường trú do kết hôn', 3),
    (4, 'LYHON', N'Ly hôn', N'Thay đổi thường trú do ly hôn', 4),
    (5, 'NHAN_NUOI', N'Nhận nuôi', N'Đăng ký thường trú do nhận con nuôi', 5),
    (6, 'CHUYEN_DEN', N'Chuyển đến', N'Đăng ký thường trú do chuyển đến', 6),
    (7, 'CHUYEN_DI', N'Chuyển đi', N'Chấm dứt thường trú do chuyển đi nơi khác', 7),
    (8, 'TACH_HO', N'Tách hộ', N'Đăng ký thường trú do tách hộ', 8),
    (9, 'NHAP_HO', N'Nhập hộ', N'Đăng ký thường trú do nhập hộ', 9),
    (10, 'HOI_HUONG', N'Hồi hương', N'Đăng ký thường trú do hồi hương', 10),
    (11, 'DINH_CU_NN', N'Định cư nước ngoài', N'Chấm dứt thường trú do định cư nước ngoài', 11);
GO

PRINT N'  Thêm dữ liệu mẫu cho Reference.ContractTypes...';
INSERT INTO [Reference].[ContractTypes] ([contract_type_id], [type_code], [type_name_vi], [description_vi], [display_order])
VALUES
    (1, 'HD_THUE_NHA', N'Hợp đồng thuê nhà', N'Hợp đồng cho thuê nhà ở', 1),
    (2, 'HD_MUON_NHA', N'Hợp đồng mượn nhà', N'Hợp đồng cho mượn nhà ở', 2),
    (3, 'VB_O_NHO', N'Văn bản cho ở nhờ', N'Văn bản đồng ý cho ở nhờ chỗ ở hợp pháp', 3);
GO

PRINT 'Insert sample data for Reference.HouseholdChangeType'
GO

INSERT INTO Reference.HouseholdChangeType (id, name, description) VALUES
(1, N'Nhập hộ - Mới sinh', N'Nhập hộ khẩu cho công dân mới sinh'),
(2, N'Nhập hộ - Chuyển đến', N'Nhập hộ khẩu cho công dân đã cắt khẩu từ nơi khác hoặc chưa có hộ khẩu'),
(3, N'Chuyển hộ khẩu', N'Chuyển trực tiếp từ hộ khẩu này sang hộ khẩu khác'),
(4, N'Tách hộ khẩu', N'Tách ra từ một hộ khẩu đã có để tạo hộ khẩu mới'),
(5, N'Xóa HK - Đã mất', N'Xóa đăng ký thường trú do công dân đã qua đời'),
(6, N'Xóa HK - Định cư nước ngoài', N'Xóa đăng ký thường trú do công dân đã định cư ở nước ngoài'),
(7, N'Xóa HK - Hủy đăng ký', N'Xóa đăng ký thường trú do công dân không còn cư trú tại địa chỉ và đã được xác minh'),
(8, N'Xóa HK - Theo quyết định', N'Xóa đăng ký thường trú theo quyết định của cơ quan có thẩm quyền'),
(9, N'Thay đổi chủ hộ', N'Thay đổi người làm chủ hộ trong một hộ khẩu'),
(10, N'Cập nhật thông tin hộ khẩu', N'Cập nhật các thông tin khác của hộ khẩu như địa chỉ');
GO

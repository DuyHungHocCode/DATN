-- Script tạo dữ liệu mẫu cho hệ thống quản lý công dân
-- Bao gồm các trường hợp để kiểm thử chức năng đăng ký kết hôn

USE [DB_BCA];
GO

-- ===================================================
-- 1. DỮ LIỆU THAM CHIẾU (REFERENCE DATA)
-- ===================================================

-- Thêm dữ liệu Quốc tịch
INSERT INTO [Reference].[Nationalities] 
    ([nationality_id], [nationality_code], [iso_code_alpha2], [iso_code_alpha3], [nationality_name], [country_name])
VALUES
    (1, 'VN', 'VN', 'VNM', N'Việt Nam', N'Việt Nam'),
    (2, 'CN', 'CN', 'CHN', N'Trung Quốc', N'Trung Quốc'),
    (3, 'US', 'US', 'USA', N'Hoa Kỳ', N'Hoa Kỳ'),
    (4, 'KR', 'KR', 'KOR', N'Hàn Quốc', N'Hàn Quốc'),
    (5, 'JP', 'JP', 'JPN', N'Nhật Bản', N'Nhật Bản');

-- Thêm dữ liệu Dân tộc
INSERT INTO [Reference].[Ethnicities]
    ([ethnicity_id], [ethnicity_code], [ethnicity_name])
VALUES
    (1, 'KINH', N'Kinh'),
    (2, 'TAY', N'Tày'),
    (3, 'THAI', N'Thái'),
    (4, 'MUONG', N'Mường'),
    (5, 'KHMER', N'Khmer');

-- Thêm dữ liệu Tôn giáo
INSERT INTO [Reference].[Religions]
    ([religion_id], [religion_code], [religion_name])
VALUES
    (1, 'NONE', N'Không'),
    (2, 'BUDDHA', N'Phật giáo'),
    (3, 'CATHOLIC', N'Công giáo'),
    (4, 'PROTESTANT', N'Tin lành'),
    (5, 'CAO-DAI', N'Cao Đài');

-- Thêm dữ liệu Vùng
INSERT INTO [Reference].[Regions]
    ([region_id], [region_code], [region_name])
VALUES
    (1, 'NB', N'Miền Bắc'),
    (2, 'NT', N'Miền Trung'),
    (3, 'NM', N'Miền Nam');

-- Thêm dữ liệu Tỉnh/Thành phố
INSERT INTO [Reference].[Provinces]
    ([province_id], [province_code], [province_name], [region_id], [is_city])
VALUES
    (1, 'HN', N'Hà Nội', 1, 1),
    (2, 'HCM', N'Hồ Chí Minh', 3, 1),
    (3, 'HP', N'Hải Phòng', 1, 1),
    (4, 'DN', N'Đà Nẵng', 2, 1),
    (5, 'NA', N'Nghệ An', 2, 0);

-- Thêm dữ liệu Quận/Huyện (cho Hà Nội)
INSERT INTO [Reference].[Districts]
    ([district_id], [district_code], [district_name], [province_id], [is_urban])
VALUES
    (1, 'HBT', N'Hai Bà Trưng', 1, 1),
    (2, 'HK', N'Hoàn Kiếm', 1, 1),
    (3, 'TX', N'Thanh Xuân', 1, 1),
    (4, 'CG', N'Cầu Giấy', 1, 1),
    (5, 'TD', N'Thạch Đà', 1, 0);

-- Thêm dữ liệu Phường/Xã (cho Hai Bà Trưng)
INSERT INTO [Reference].[Wards]
    ([ward_id], [ward_code], [ward_name], [district_id], [is_urban])
VALUES
    (1, 'BCT', N'Bạch Mai', 1, 1),
    (2, 'QB', N'Quỳnh Lôi', 1, 1),
    (3, 'BT', N'Bách Khoa', 1, 1),
    (4, 'VT', N'Vĩnh Tuy', 1, 1),
    (5, 'MD', N'Minh Khai', 1, 1);

-- Thêm dữ liệu Cơ quan cấp
INSERT INTO [Reference].[Authorities]
    ([authority_id], [authority_code], [authority_name], [authority_type], [province_id])
VALUES
    (1, 'CA-HN', N'Công an TP Hà Nội', N'Công an', 1),
    (2, 'BTP-HN', N'Phòng Tư pháp TP Hà Nội', N'Tư pháp', 1),
    (3, 'UBND-HBT', N'UBND Quận Hai Bà Trưng', N'Hành chính', 1),
    (4, 'BTP-UBND-HBT', N'Phòng Tư pháp UBND Quận Hai Bà Trưng', N'Tư pháp', 1),
    (5, 'BTP-UBND-HK', N'Phòng Tư pháp UBND Quận Hoàn Kiếm', N'Tư pháp', 1);

-- ===================================================
-- 2. DỮ LIỆU CÔNG DÂN (CHUẨN BỊ CHO KIỂM THỬ KẾT HÔN)
-- ===================================================

-- Trường hợp 1: Cặp đôi hợp lệ - đủ tuổi, đang độc thân
-- Nam: Nguyễn Văn An, 30 tuổi
-- Nữ: Trần Thị Bình, 28 tuổi
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number])
VALUES
    ('001093000001', N'Nguyễn Văn An', '1995-03-15', N'Nam', 1, 1, 1, N'Độc thân', 1,
     N'Số 15 Tạ Quang Bửu', 3, 1, 1, '0901234567'),
    ('001294000002', N'Trần Thị Bình', '1997-06-20', N'Nữ', 1, 1, 1, N'Độc thân', 1,
     N'Số 25 Lò Đúc', 1, 1, 1, '0912345678');

-- Trường hợp 2: Nam chưa đủ tuổi (19 tuổi)
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number])
VALUES
    ('001206000003', N'Lê Minh Cường', '2006-12-05', N'Nam', 1, 1, 1, N'Độc thân', 1,
     N'Số 7 Tây Sơn', 2, 2, 1, '0934567890');

-- Trường hợp 3: Nữ chưa đủ tuổi (17 tuổi)
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number])
VALUES
    ('001207000004', N'Phạm Thị Dung', '2008-04-10', N'Nữ', 1, 1, 1, N'Độc thân', 1,
     N'Số 42 Đại Cồ Việt', 3, 1, 1, '0945678901');

-- Trường hợp 4: Nam đã có vợ
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number],
     [spouse_citizen_id])
VALUES
    ('001085000005', N'Hoàng Minh Đức', '1985-09-25', N'Nam', 1, 1, 1, N'Đã kết hôn', 1,
     N'Số 56 Lê Thanh Nghị', 3, 1, 1, '0956789012', '001088000006');

-- Vợ của Hoàng Minh Đức
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number],
     [spouse_citizen_id])
VALUES
    ('001088000006', N'Vũ Thị Em', '1988-11-30', N'Nữ', 1, 1, 1, N'Đã kết hôn', 1,
     N'Số 56 Lê Thanh Nghị', 3, 1, 1, '0967890123', '001085000005');

-- Trường hợp 5: Nữ đã có chồng
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number],
     [spouse_citizen_id])
VALUES
    ('001090000007', N'Ngô Thị Hoa', '1990-07-15', N'Nữ', 1, 1, 1, N'Đã kết hôn', 1,
     N'Số 78 Giải Phóng', 4, 1, 1, '0978901234', '001087000008');

-- Chồng của Ngô Thị Hoa
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number],
     [spouse_citizen_id])
VALUES
    ('001087000008', N'Đỗ Văn Giang', '1987-02-20', N'Nam', 1, 1, 1, N'Đã kết hôn', 1,
     N'Số 78 Giải Phóng', 4, 1, 1, '0989012345', '001090000007');

-- Trường hợp 6: Nam đã mất
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number],
     [death_status], [date_of_death])
VALUES
    ('001080000009', N'Lương Văn Huy', '1980-08-10', N'Nam', 1, 1, 1, N'Độc thân', 1,
     N'Số 90 Nguyễn Hiền', 5, 1, 1, '0990123456', N'Đã mất', '2023-12-15');

-- Trường hợp 7: Quan hệ gia đình (cha và con gái để kiểm thử quan hệ huyết thống)
-- Cha
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number])
VALUES
    ('001070000010', N'Trần Văn Khánh', '1970-04-05', N'Nam', 1, 1, 1, N'Đã kết hôn', 1,
     N'Số 123 Trần Đại Nghĩa', 3, 1, 1, '0901234568');

-- Con gái (21 tuổi - đủ tuổi kết hôn)
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number],
     [father_citizen_id])
VALUES
    ('001204000011', N'Trần Thị Ly', '2004-07-22', N'Nữ', 1, 1, 1, N'Độc thân', 1,
     N'Số 123 Trần Đại Nghĩa', 3, 1, 1, '0912345680', '001070000010');

-- Trường hợp 8: Công dân nước ngoài
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number])
VALUES
    ('AC1234567', N'David Smith', '1990-10-15', N'Nam', 3, NULL, 3, N'Độc thân', NULL,
     N'Số 45 Phố Huế', 2, 2, 1, '0923456789');

-- Trường hợp 9: Cặp đôi vừa đủ tuổi
-- Nam: 20 tuổi
-- Nữ: 18 tuổi
INSERT INTO [BCA].[Citizen]
    ([citizen_id], [full_name], [date_of_birth], [gender], [nationality_id], [ethnicity_id], 
     [religion_id], [marital_status], [birth_province_id], [current_address_detail], 
     [current_ward_id], [current_district_id], [current_province_id], [phone_number])
VALUES
    ('001205000012', N'Lê Đình Mạnh', '2005-05-01', N'Nam', 1, 1, 1, N'Độc thân', 1,
     N'Số 67 Đường Nguyễn Trãi', 3, 3, 1, '0934567891'),
    ('001207000013', N'Nguyễn Thu Ngân', '2007-03-15', N'Nữ', 1, 1, 1, N'Độc thân', 1,
     N'Số 89 Đường Nguyễn Trãi', 3, 3, 1, '0945678902');

-- ===================================================
-- 3. DỮ LIỆU CHO DB_BTP (DATABASE BỘ TƯ PHÁP)
-- ===================================================

USE [DB_BTP];
GO

-- Đảm bảo dữ liệu tham chiếu tương tự với DB_BCA

-- Thêm dữ liệu Quốc tịch
INSERT INTO [Reference].[Nationalities] 
    ([nationality_id], [nationality_code], [iso_code_alpha2], [iso_code_alpha3], [nationality_name], [country_name])
VALUES
    (1, 'VN', 'VN', 'VNM', N'Việt Nam', N'Việt Nam'),
    (2, 'CN', 'CN', 'CHN', N'Trung Quốc', N'Trung Quốc'),
    (3, 'US', 'US', 'USA', N'Hoa Kỳ', N'Hoa Kỳ'),
    (4, 'KR', 'KR', 'KOR', N'Hàn Quốc', N'Hàn Quốc'),
    (5, 'JP', 'JP', 'JPN', N'Nhật Bản', N'Nhật Bản');

-- Thêm dữ liệu Vùng
INSERT INTO [Reference].[Regions]
    ([region_id], [region_code], [region_name])
VALUES
    (1, 'NB', N'Miền Bắc'),
    (2, 'NT', N'Miền Trung'),
    (3, 'NM', N'Miền Nam');

-- Thêm dữ liệu Tỉnh/Thành phố
INSERT INTO [Reference].[Provinces]
    ([province_id], [province_code], [province_name], [region_id], [is_city])
VALUES
    (1, 'HN', N'Hà Nội', 1, 1),
    (2, 'HCM', N'Hồ Chí Minh', 3, 1),
    (3, 'HP', N'Hải Phòng', 1, 1),
    (4, 'DN', N'Đà Nẵng', 2, 1),
    (5, 'NA', N'Nghệ An', 2, 0);

-- Thêm dữ liệu Cơ quan cấp
INSERT INTO [Reference].[Authorities]
    ([authority_id], [authority_code], [authority_name], [authority_type], [province_id])
VALUES
    (1, 'CA-HN', N'Công an TP Hà Nội', N'Công an', 1),
    (2, 'BTP-HN', N'Phòng Tư pháp TP Hà Nội', N'Tư pháp', 1),
    (3, 'UBND-HBT', N'UBND Quận Hai Bà Trưng', N'Hành chính', 1),
    (4, 'BTP-UBND-HBT', N'Phòng Tư pháp UBND Quận Hai Bà Trưng', N'Tư pháp', 1),
    (5, 'BTP-UBND-HK', N'Phòng Tư pháp UBND Quận Hoàn Kiếm', N'Tư pháp', 1);

-- Tạo một số giấy chứng nhận kết hôn mẫu cho các cặp đôi đã kết hôn
INSERT INTO [BTP].[MarriageCertificate]
    ([marriage_certificate_no], [book_id], [page_no], 
     [husband_id], [husband_full_name], [husband_date_of_birth], [husband_nationality_id], 
     [wife_id], [wife_full_name], [wife_date_of_birth], [wife_nationality_id],
     [marriage_date], [registration_date], [issuing_authority_id], [issuing_place], [status])
VALUES
    ('MC-HN-2023-00001', 'KH-2023', '01', 
     '001085000005', N'Hoàng Minh Đức', '1985-09-25', 1, 
     '001088000006', N'Vũ Thị Em', '1988-11-30', 1,
     '2023-03-15', '2023-03-20', 4, N'Phòng Tư pháp UBND Quận Hai Bà Trưng, Hà Nội', 1),
    
    ('MC-HN-2023-00002', 'KH-2023', '02', 
     '001087000008', N'Đỗ Văn Giang', '1987-02-20', 1, 
     '001090000007', N'Ngô Thị Hoa', '1990-07-15', 1,
     '2023-05-10', '2023-05-15', 5, N'Phòng Tư pháp UBND Quận Hoàn Kiếm, Hà Nội', 1);

-- ===================================================
-- 4. DỮ LIỆU CHO BẢNG OUTBOX (ĐỂ KIỂM TRA PATTERN OUTBOX)
-- ===================================================

-- Tạo bản ghi mẫu cho OutboxMessage nếu cần
INSERT INTO [BTP].[EventOutbox]
    ([aggregate_type], [aggregate_id], [event_type], [payload], [created_at])
VALUES
    ('MarriageCertificate', 1, 'citizen_married', 
     N'{"marriage_certificate_id":1,"marriage_certificate_no":"MC-HN-2023-00001","husband_id":"001085000005","wife_id":"001088000006","marriage_date":"2023-03-15","registration_date":"2023-03-20","issuing_authority_id":4,"status":true}',
     GETDATE());
-- sample_data.sql (đã sửa phần biến)
-- Script tạo dữ liệu mẫu cho hệ thống quản lý công dân và hộ tịch
-- Sử dụng cho cả 2 database: DB_BCA và DB_BTP

-- ========================================================================
-- PHẦN 1: DỮ LIỆU MẪU CHO BỘ CÔNG AN (DB_BCA)
-- ========================================================================
USE [DB_BCA];
GO

PRINT N'Đang tạo dữ liệu mẫu cho DB_BCA...';

-- Xóa dữ liệu cũ nếu có (ngược thứ tự của foreign key references)
DELETE FROM [BCA].[CitizenStatus];
DELETE FROM [BCA].[TemporaryAbsence];
DELETE FROM [BCA].[CitizenAddress];
DELETE FROM [BCA].[ResidenceHistory];
DELETE FROM [BCA].[CriminalRecord];
DELETE FROM [BCA].[IdentificationCard];
DELETE FROM [BCA].[Citizen];
DELETE FROM [BCA].[Address];
GO

-- Chèn mẫu địa chỉ
PRINT N'Chèn dữ liệu địa chỉ...';
-- Sử dụng OUTPUT để lấy ID vừa chèn
DECLARE @AddressTable TABLE (
    id INT IDENTITY(1,1), 
    address_id BIGINT
);

INSERT INTO [BCA].[Address] (
    [address_detail], [ward_id], [district_id], [province_id], [postal_code], [status]
) 
OUTPUT inserted.address_id INTO @AddressTable(address_id)
VALUES
(N'Số 123 Đường Trần Phú', 10101, 101, 1, '100000', 1),
(N'Số 45 Đường Lý Thường Kiệt', 10101, 101, 1, '100000', 1),
(N'Số 67 Đường Nguyễn Huệ', 10101, 101, 1, '100000', 1),
(N'Số 89 Đường Lê Lợi', 10101, 101, 1, '100000', 1),
(N'Số 12 Đường Hùng Vương', 10101, 101, 1, '100000', 1);

-- Lấy các địa chỉ id từ bảng tạm thời
DECLARE @address1 BIGINT, @address2 BIGINT, @address3 BIGINT, @address4 BIGINT, @address5 BIGINT;
SELECT @address1 = address_id FROM @AddressTable WHERE id = 1;
SELECT @address2 = address_id FROM @AddressTable WHERE id = 2;
SELECT @address3 = address_id FROM @AddressTable WHERE id = 3;
SELECT @address4 = address_id FROM @AddressTable WHERE id = 4;
SELECT @address5 = address_id FROM @AddressTable WHERE id = 5;

-- Chèn dữ liệu công dân
PRINT N'Chèn dữ liệu công dân...';
INSERT INTO [BCA].[Citizen] (
    [citizen_id], [full_name], [date_of_birth], [gender], 
    [birth_ward_id], [birth_district_id], [birth_province_id], [nationality_id], 
    [ethnicity_id], [religion_id], [marital_status], [education_level], 
    [occupation_id], [current_address_detail], [current_ward_id], [current_district_id], 
    [current_province_id], [death_status], [phone_number], [email]
) VALUES
-- 5 công dân còn sống
('123456789012', N'Nguyễn Văn An', '1980-05-15', N'Nam', 
 10101, 101, 1, 1, 
 1, 9, N'Đã kết hôn', N'Đại học', 
 3, N'Số 123 Đường Trần Phú', 10101, 101, 
 1, N'Còn sống', '0912345678', 'nguyenvana@example.com'),

('234567890123', N'Trần Thị Bình', '1985-10-20', N'Nữ', 
 10101, 101, 1, 1, 
 1, 9, N'Đã kết hôn', N'Thạc sĩ', 
 4, N'Số 123 Đường Trần Phú', 10101, 101, 
 1, N'Còn sống', '0923456789', 'tranthib@example.com'),

('345678901234', N'Lê Văn Cường', '1975-03-25', N'Nam', 
 10101, 101, 1, 1, 
 1, 2, N'Đã kết hôn', N'Trung học phổ thông', 
 5, N'Số 45 Đường Lý Thường Kiệt', 10101, 101, 
 1, N'Còn sống', '0934567890', 'levanc@example.com'),

('456789012345', N'Phạm Thị Dung', '1990-12-10', N'Nữ', 
 10101, 101, 1, 1, 
 1, 9, N'Độc thân', N'Đại học', 
 3, N'Số 67 Đường Nguyễn Huệ', 10101, 101, 
 1, N'Còn sống', '0945678901', 'phamthid@example.com'),

('567890123456', N'Hoàng Văn Eo', '1978-07-30', N'Nam', 
 10101, 101, 1, 1, 
 1, 9, N'Đã kết hôn', N'Cao đẳng', 
 7, N'Số 89 Đường Lê Lợi', 10101, 101, 
 1, N'Còn sống', '0956789012', 'hoangvane@example.com'),

-- 2 công dân đã mất
('678901234567', N'Ngô Thị Phương', '1965-04-12', N'Nữ', 
 10101, 101, 1, 1, 
 1, 2, N'Góa', N'Trung học cơ sở', 
 9, N'Số 12 Đường Hùng Vương', 10101, 101, 
 1, N'Đã mất', '0967890123', null),

('789012345678', N'Đỗ Văn Giang', '1950-09-05', N'Nam', 
 10101, 101, 1, 1, 
 1, 9, N'Đã kết hôn', N'Tiểu học', 
 9, N'Số 12 Đường Hùng Vương', 10101, 101, 
 1, N'Đã mất', null, null);

-- Cập nhật thông tin người đã mất
UPDATE [BCA].[Citizen]
SET [date_of_death] = '2023-11-15'
WHERE [citizen_id] = '678901234567';

UPDATE [BCA].[Citizen]
SET [date_of_death] = '2024-01-20'
WHERE [citizen_id] = '789012345678';

-- Chèn dữ liệu thẻ CCCD/CMND
PRINT N'Chèn dữ liệu thẻ căn cước...';
INSERT INTO [BCA].[IdentificationCard] (
    [citizen_id], [card_number], [card_type], [issue_date], [expiry_date], 
    [issuing_authority_id], [card_status]
) VALUES
-- Thẻ của người còn sống
('123456789012', '012345678901', N'CCCD gắn chip', '2020-05-15', '2030-05-15', 100, N'Đang sử dụng'),
('234567890123', '023456789012', N'CCCD gắn chip', '2021-10-20', '2031-10-20', 100, N'Đang sử dụng'),
('345678901234', '034567890123', N'CCCD', '2019-03-25', '2029-03-25', 100, N'Đang sử dụng'),
('456789012345', '045678901234', N'CCCD gắn chip', '2022-12-10', '2032-12-10', 100, N'Đang sử dụng'),
('567890123456', '056789012345', N'CCCD', '2018-07-30', '2028-07-30', 100, N'Đang sử dụng'),

-- Thẻ của người đã mất (sẽ ở trạng thái "Thu hồi")
('678901234567', '067890123456', N'CMND 9 số', '2010-04-12', '2020-04-12', 100, N'Thu hồi'),
('789012345678', '078901234567', N'CMND 9 số', '2008-09-05', '2018-09-05', 100, N'Thu hồi');

-- Chèn dữ liệu lịch sử cư trú
PRINT N'Chèn dữ liệu lịch sử cư trú...';
INSERT INTO [BCA].[ResidenceHistory] (
    [citizen_id], [address_id], [residence_type], [registration_date],
    [registration_reason], [issuing_authority_id], [status]
) VALUES
('123456789012', @address1, N'Thường trú', '2015-01-15', N'Chuyển đến', 100, 'Active'),
('234567890123', @address1, N'Thường trú', '2015-01-15', N'Kết hôn', 100, 'Active'),
('345678901234', @address2, N'Thường trú', '2010-05-20', N'Chuyển đến', 100, 'Active'),
('456789012345', @address3, N'Thường trú', '2020-11-30', N'Chuyển đến', 100, 'Active'),
('567890123456', @address4, N'Thường trú', '2018-03-10', N'Chuyển đến', 100, 'Active'),
('678901234567', @address5, N'Thường trú', '2005-07-25', N'Chuyển đến', 100, 'Moved'),
('789012345678', @address5, N'Thường trú', '2005-07-25', N'Chuyển đến', 100, 'Moved');

-- Chèn dữ liệu địa chỉ hiện tại của công dân
PRINT N'Chèn dữ liệu địa chỉ hiện tại...';
INSERT INTO [BCA].[CitizenAddress] (
    [citizen_id], [address_id], [address_type], [from_date], 
    [is_primary], [status]
) VALUES
('123456789012', @address1, N'Thường trú', '2015-01-15', 1, 1),
('234567890123', @address1, N'Thường trú', '2015-01-15', 1, 1),
('345678901234', @address2, N'Thường trú', '2010-05-20', 1, 1),
('456789012345', @address3, N'Thường trú', '2020-11-30', 1, 1),
('567890123456', @address4, N'Thường trú', '2018-03-10', 1, 1),
('678901234567', @address5, N'Thường trú', '2005-07-25', 1, 0),
('789012345678', @address5, N'Thường trú', '2005-07-25', 1, 0);

-- Chèn dữ liệu trạng thái công dân
PRINT N'Chèn dữ liệu trạng thái công dân...';
INSERT INTO [BCA].[CitizenStatus] (
    [citizen_id], [status_type], [status_date], [description], [is_current]
) VALUES
('123456789012', N'Còn sống', '1980-05-15', N'Mặc định khi khai sinh', 1),
('234567890123', N'Còn sống', '1985-10-20', N'Mặc định khi khai sinh', 1),
('345678901234', N'Còn sống', '1975-03-25', N'Mặc định khi khai sinh', 1),
('456789012345', N'Còn sống', '1990-12-10', N'Mặc định khi khai sinh', 1),
('567890123456', N'Còn sống', '1978-07-30', N'Mặc định khi khai sinh', 1),
('678901234567', N'Còn sống', '1965-04-12', N'Mặc định khi khai sinh', 0),
('678901234567', N'Đã mất', '2023-11-15', N'Theo giấy chứng tử', 1),
('789012345678', N'Còn sống', '1950-09-05', N'Mặc định khi khai sinh', 0),
('789012345678', N'Đã mất', '2024-01-20', N'Theo giấy chứng tử', 1);
GO

PRINT N'Đã tạo xong dữ liệu mẫu cho DB_BCA.'

-- ========================================================================
-- PHẦN 2: DỮ LIỆU MẪU CHO BỘ TƯ PHÁP (DB_BTP)
-- ========================================================================
USE [DB_BTP];
GO

PRINT N'Đang tạo dữ liệu mẫu cho DB_BTP...';

-- Xóa dữ liệu cũ nếu có (ngược thứ tự của foreign key references)
DELETE FROM [BTP].[PopulationChange];
DELETE FROM [BTP].[FamilyRelationship];
DELETE FROM [BTP].[HouseholdMember];
DELETE FROM [BTP].[Household];
DELETE FROM [BTP].[DeathCertificate];
DELETE FROM [BTP].[MarriageCertificate];
DELETE FROM [BTP].[BirthCertificate];
GO

-- Chèn dữ liệu giấy khai sinh
PRINT N'Chèn dữ liệu giấy khai sinh...';
INSERT INTO [BTP].[BirthCertificate] (
    [citizen_id], [birth_certificate_no], [registration_date],
    [book_id], [page_no], [issuing_authority_id], [place_of_birth],
    [date_of_birth], [gender_at_birth], [father_full_name],
    [mother_full_name], [declarant_name]
) VALUES
('123456789012', 'BC123456', '1980-05-20', 'BC1980', '15', 150,
 N'Bệnh viện Bạch Mai, Hà Nội', '1980-05-15', N'Nam', N'Nguyễn Văn Sáu',
 N'Lê Thị Bảy', N'Nguyễn Văn Sáu'),

('234567890123', 'BC234567', '1985-10-25', 'BC1985', '20', 150,
 N'Bệnh viện Phụ sản Hà Nội', '1985-10-20', N'Nữ', N'Trần Văn Tám',
 N'Phạm Thị Chín', N'Trần Văn Tám'),

('345678901234', 'BC345678', '1975-04-01', 'BC1975', '25', 150,
 N'Trạm y tế Phúc Xá', '1975-03-25', N'Nam', N'Lê Văn Mười',
 N'Hoàng Thị Mười Một', N'Lê Văn Mười'),

('456789012345', 'BC456789', '1990-12-15', 'BC1990', '30', 150,
 N'Bệnh viện Phụ sản Hà Nội', '1990-12-10', N'Nữ', N'Phạm Văn Mười Hai',
 N'Đặng Thị Mười Ba', N'Phạm Văn Mười Hai'),

('567890123456', 'BC567890', '1978-08-05', 'BC1978', '35', 150,
 N'Trạm y tế Phúc Xá', '1978-07-30', N'Nam', N'Hoàng Văn Mười Bốn',
 N'Vũ Thị Mười Lăm', N'Hoàng Văn Mười Bốn'),

('678901234567', 'BC678901', '1965-04-17', 'BC1965', '40', 150,
 N'Nhà hộ sinh Hà Nội', '1965-04-12', N'Nữ', N'Ngô Văn Mười Sáu',
 N'Trịnh Thị Mười Bảy', N'Ngô Văn Mười Sáu'),

('789012345678', 'BC789012', '1950-09-10', 'BC1950', '45', 150,
 N'Tại nhà', '1950-09-05', N'Nam', N'Đỗ Văn Mười Tám',
 N'Bùi Thị Mười Chín', N'Đỗ Văn Mười Tám');
GO

-- Chèn dữ liệu giấy chứng tử
PRINT N'Chèn dữ liệu giấy chứng tử...';
INSERT INTO [BTP].[DeathCertificate] (
    [citizen_id], [death_certificate_no], [book_id], [page_no],
    [date_of_death], [time_of_death], [place_of_death_detail],
    [place_of_death_ward_id], [cause_of_death], [declarant_name],
    [declarant_relationship], [registration_date], [issuing_authority_id]
) VALUES
('678901234567', 'DC123456', 'DC2023', '15', '2023-11-15', '14:30:00',
 N'Bệnh viện Bạch Mai', 10101, N'Bệnh lý tuổi già', N'Ngô Văn Con',
 N'Con trai', '2023-11-17', 150),

('789012345678', 'DC234567', 'DC2024', '20', '2024-01-20', '10:45:00',
 N'Tại nhà riêng', 10101, N'Đột quỵ', N'Đỗ Thị Cháu',
 N'Con gái', '2024-01-22', 150);
GO

-- Chèn dữ liệu giấy kết hôn
PRINT N'Chèn dữ liệu giấy kết hôn...';
INSERT INTO [BTP].[MarriageCertificate] (
    [marriage_certificate_no], [book_id], [page_no],
    [husband_id], [husband_full_name], [husband_date_of_birth], [husband_nationality_id],
    [wife_id], [wife_full_name], [wife_date_of_birth], [wife_nationality_id],
    [marriage_date], [registration_date], [issuing_authority_id], [issuing_place]
) VALUES
('MC123456', 'MC2015', '10',
 '123456789012', N'Nguyễn Văn An', '1980-05-15', 1,
 '234567890123', N'Trần Thị Bình', '1985-10-20', 1,
 '2015-01-10', '2015-01-12', 150, N'UBND Phường Phúc Xá');
GO

-- Chèn dữ liệu hộ khẩu
PRINT N'Chèn dữ liệu hộ khẩu...';
-- Lấy ra các địa chỉ ID từ BCA
DECLARE @address_ids TABLE (
    address_detail NVARCHAR(MAX), 
    address_id BIGINT
);

INSERT INTO @address_ids
SELECT address_detail, address_id FROM [DB_BCA].[BCA].[Address]
WHERE address_detail IN (
    N'Số 123 Đường Trần Phú',
    N'Số 45 Đường Lý Thường Kiệt',
    N'Số 67 Đường Nguyễn Huệ',
    N'Số 89 Đường Lê Lợi',
    N'Số 12 Đường Hùng Vương'
);

DECLARE @addr1 BIGINT, @addr2 BIGINT, @addr3 BIGINT, @addr4 BIGINT, @addr5 BIGINT;
SELECT @addr1 = address_id FROM @address_ids WHERE address_detail = N'Số 123 Đường Trần Phú';
SELECT @addr2 = address_id FROM @address_ids WHERE address_detail = N'Số 45 Đường Lý Thường Kiệt';
SELECT @addr3 = address_id FROM @address_ids WHERE address_detail = N'Số 67 Đường Nguyễn Huệ';
SELECT @addr4 = address_id FROM @address_ids WHERE address_detail = N'Số 89 Đường Lê Lợi';
SELECT @addr5 = address_id FROM @address_ids WHERE address_detail = N'Số 12 Đường Hùng Vương';

INSERT INTO [BTP].[Household] (
    [household_book_no], [head_of_household_id], [address_id],
    [registration_date], [issuing_authority_id], [household_type]
) VALUES
('HK123456', '123456789012', @addr1, '2015-01-15', 150, N'Hộ gia đình'),
('HK234567', '345678901234', @addr2, '2010-05-20', 150, N'Hộ gia đình'),
('HK345678', '456789012345', @addr3, '2020-11-30', 150, N'Hộ gia đình'),
('HK456789', '567890123456', @addr4, '2018-03-10', 150, N'Hộ gia đình'),
('HK567890', '789012345678', @addr5, '2005-07-25', 150, N'Hộ gia đình');

-- Chèn dữ liệu thành viên hộ
PRINT N'Chèn dữ liệu thành viên hộ...';
-- Lấy ID hộ từ bảng Household
DECLARE @household_ids TABLE (
    household_book_no VARCHAR(20),
    household_id BIGINT
);

INSERT INTO @household_ids
SELECT household_book_no, household_id FROM [BTP].[Household];

DECLARE @hh1 BIGINT, @hh2 BIGINT, @hh3 BIGINT, @hh4 BIGINT, @hh5 BIGINT;
SELECT @hh1 = household_id FROM @household_ids WHERE household_book_no = 'HK123456';
SELECT @hh2 = household_id FROM @household_ids WHERE household_book_no = 'HK234567';
SELECT @hh3 = household_id FROM @household_ids WHERE household_book_no = 'HK345678';
SELECT @hh4 = household_id FROM @household_ids WHERE household_book_no = 'HK456789';
SELECT @hh5 = household_id FROM @household_ids WHERE household_book_no = 'HK567890';

INSERT INTO [BTP].[HouseholdMember] (
    [household_id], [citizen_id], [relationship_with_head],
    [join_date], [order_in_household], [status]
) VALUES
(@hh1, '123456789012', N'Chủ hộ', '2015-01-15', 1, N'Active'),
(@hh1, '234567890123', N'Vợ', '2015-01-15', 2, N'Active'),
(@hh2, '345678901234', N'Chủ hộ', '2010-05-20', 1, N'Active'),
(@hh3, '456789012345', N'Chủ hộ', '2020-11-30', 1, N'Active'),
(@hh4, '567890123456', N'Chủ hộ', '2018-03-10', 1, N'Active'),
(@hh5, '678901234567', N'Vợ', '2005-07-25', 2, N'Deceased'),
(@hh5, '789012345678', N'Chủ hộ', '2005-07-25', 1, N'Deceased');

-- Chèn dữ liệu quan hệ gia đình
PRINT N'Chèn dữ liệu quan hệ gia đình...';
INSERT INTO [BTP].[FamilyRelationship] (
    [citizen_id], [related_citizen_id], [relationship_type],
    [start_date], [status]
) VALUES
('123456789012', '234567890123', N'Vợ-Chồng', '2015-01-10', N'Active'),
('234567890123', '123456789012', N'Vợ-Chồng', '2015-01-10', N'Active'),
('789012345678', '678901234567', N'Vợ-Chồng', '1970-05-20', N'Active');

-- Chèn dữ liệu thay đổi dân số
PRINT N'Chèn dữ liệu thay đổi dân số...';
INSERT INTO [BTP].[PopulationChange] (
    [citizen_id], [change_type], [change_date],
    [reason], [related_document_no], [processing_authority_id]
) VALUES
('123456789012', N'Đăng ký khai sinh', '1980-05-20', 
 N'Khai sinh lần đầu', 'BC123456', 150),
('234567890123', N'Đăng ký khai sinh', '1985-10-25', 
 N'Khai sinh lần đầu', 'BC234567', 150),
('345678901234', N'Đăng ký khai sinh', '1975-04-01', 
 N'Khai sinh lần đầu', 'BC345678', 150),
('456789012345', N'Đăng ký khai sinh', '1990-12-15', 
 N'Khai sinh lần đầu', 'BC456789', 150),
('567890123456', N'Đăng ký khai sinh', '1978-08-05', 
 N'Khai sinh lần đầu', 'BC567890', 150),
('678901234567', N'Đăng ký khai sinh', '1965-04-17', 
 N'Khai sinh lần đầu', 'BC678901', 150),
('789012345678', N'Đăng ký khai sinh', '1950-09-10', 
 N'Khai sinh lần đầu', 'BC789012', 150),

('123456789012', N'Đăng ký kết hôn', '2015-01-12', 
 N'Kết hôn với Trần Thị Bình', 'MC123456', 150),
('234567890123', N'Đăng ký kết hôn', '2015-01-12', 
 N'Kết hôn với Nguyễn Văn An', 'MC123456', 150),

('678901234567', N'Đăng ký khai tử', '2023-11-17', 
 N'Khai tử', 'DC123456', 150),
('789012345678', N'Đăng ký khai tử', '2024-01-22', 
 N'Khai tử', 'DC234567', 150);
GO

PRINT N'Đã tạo xong dữ liệu mẫu cho DB_BTP.'
PRINT N'Hoàn thành tạo dữ liệu mẫu cho hệ thống!'
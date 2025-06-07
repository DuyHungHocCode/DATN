USE [DB_BCA];
GO

-- Xóa dữ liệu hiện có (nếu cần) để tránh xung đột
DELETE FROM [BCA].[TemporaryAbsence] WHERE [citizen_id] IN ('010203000001', '010203000002', '010203000003');
DELETE FROM [BCA].[CitizenAddress] WHERE [citizen_id] IN ('010203000001', '010203000002', '010203000003');
DELETE FROM [BCA].[ResidenceHistory] WHERE [citizen_id] IN ('010203000001', '010203000002', '010203000003');
DELETE FROM [BCA].[Address] WHERE [address_detail] LIKE N'%Dữ liệu mẫu%';

-- 1. Thêm các địa chỉ mẫu
INSERT INTO [BCA].[Address] ([address_detail], [ward_id], [district_id], [province_id], [postal_code], [status])
VALUES 
-- Địa chỉ cho công dân 1 - Nguyễn Văn An
(N'Số 10, Ngõ 55, Phố Giải Phóng, Dữ liệu mẫu 1', 10101, 101, 1, '100000', 1),
(N'Số 15, Ngõ 76, Phố Trương Định, Dữ liệu mẫu 2', 10101, 101, 1, '100000', 1),
(N'Số 23, Ngõ 44, Phố Tôn Đức Thắng, Dữ liệu mẫu 3', 10102, 101, 1, '100000', 1),
(N'Số 7, Ngõ 120, Phố Hoàng Quốc Việt, Dữ liệu mẫu 4', 10103, 101, 1, '100000', 1),
-- Địa chỉ cho công dân 2 - Trần Thị Bình
(N'Số 30, Đường Lê Duẩn, Dữ liệu mẫu 5', 10102, 101, 1, '100000', 1),
-- Địa chỉ cho công dân 3 - Lê Văn Cường
(N'Số 45, Đường Tố Hữu, Dữ liệu mẫu 6', 10103, 101, 1, '100000', 1),
(N'Số 78, Đường Vạn Phúc, Dữ liệu mẫu 7', 10104, 101, 1, '100000', 1),
(N'Khu tập thể B3, Quận Cầu Giấy, Dữ liệu mẫu 8', 10105, 101, 1, '100000', 1);

-- Lấy ID của các địa chỉ đã thêm vào
DECLARE @address1 BIGINT, @address2 BIGINT, @address3 BIGINT, @address4 BIGINT, @address5 BIGINT, @address6 BIGINT, @address7 BIGINT, @address8 BIGINT;

SELECT @address1 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Số 10, Ngõ 55, Phố Giải Phóng, Dữ liệu mẫu 1';
SELECT @address2 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Số 15, Ngõ 76, Phố Trương Định, Dữ liệu mẫu 2';
SELECT @address3 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Số 23, Ngõ 44, Phố Tôn Đức Thắng, Dữ liệu mẫu 3';
SELECT @address4 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Số 7, Ngõ 120, Phố Hoàng Quốc Việt, Dữ liệu mẫu 4';
SELECT @address5 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Số 30, Đường Lê Duẩn, Dữ liệu mẫu 5';
SELECT @address6 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Số 45, Đường Tố Hữu, Dữ liệu mẫu 6';
SELECT @address7 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Số 78, Đường Vạn Phúc, Dữ liệu mẫu 7';
SELECT @address8 = [address_id] FROM [BCA].[Address] WHERE [address_detail] = N'Khu tập thể B3, Quận Cầu Giấy, Dữ liệu mẫu 8';

-- 2. Thêm lịch sử cư trú cho công dân 1 - Nguyễn Văn An (người với nhiều lịch sử)
-- Thường trú cũ
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [status])
VALUES
('010203000001', @address1, N'Thường trú', '2010-01-15', NULL, N'Đăng ký lần đầu', NULL, 100, 'PT100001', 'Moved');

-- Thường trú hiện tại
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [status])
VALUES
('010203000001', @address2, N'Thường trú', '2018-05-20', NULL, N'Chuyển từ nơi thường trú cũ', @address1, 100, 'PT100054', 'Active');

-- Tạm trú cũ (đã hết hạn)
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [host_name], [status])
VALUES
('010203000001', @address3, N'Tạm trú', '2015-03-10', '2016-03-10', N'Công tác', NULL, 100, 'TT100022', N'Hoàng Văn Chủ', 'Expired');

-- Tạm trú hiện tại 
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [host_name], [host_citizen_id], [host_relationship], [status])
VALUES
('010203000001', @address4, N'Tạm trú', '2023-08-15', '2024-08-15', N'Công tác dài hạn', NULL, 100, 'TT100087', N'Đỗ Thị Chủ Nhà', '040201000002', N'Không có quan hệ', 'Active');

-- 3. Thêm dữ liệu tạm vắng cho công dân 1
INSERT INTO [BCA].[TemporaryAbsence]
([citizen_id], [from_date], [to_date], [reason], [destination_address_id], [destination_detail], [contact_information], [registration_authority_id], [registration_number], [status])
VALUES
('010203000001', '2022-12-01', '2023-02-28', N'Du lịch nước ngoài', NULL, N'Singapore', N'Phone: +6512345678', 100, 'TV100012', 'Returned'),
('010203000001', '2024-04-10', '2024-07-15', N'Công tác nước ngoài', NULL, N'Tokyo, Nhật Bản', N'Email: nguyenvanan@example.com', 100, 'TV100034', 'Active');

-- 4. Thêm các địa chỉ hiện tại cho công dân 1
INSERT INTO [BCA].[CitizenAddress]
([citizen_id], [address_id], [address_type], [from_date], [to_date], [is_primary], [status], [registration_document_no], [registration_date], [issuing_authority_id])
VALUES
('010203000001', @address2, N'Thường trú', '2018-05-20', NULL, 1, 1, 'HK100045', '2018-05-20', 100),
('010203000001', @address4, N'Tạm trú', '2023-08-15', '2024-08-15', 0, 1, 'TT100087', '2023-08-15', 100),
('010203000001', @address3, N'Công ty', '2022-01-10', NULL, 0, 1, NULL, NULL, NULL);

-- 5. Thêm lịch sử cư trú cho công dân 2 - Trần Thị Bình (chỉ có thường trú)
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [status])
VALUES
('010203000002', @address5, N'Thường trú', '2005-07-22', NULL, N'Đăng ký lần đầu', NULL, 100, 'PT100123', 'Active');

-- Thêm địa chỉ hiện tại
INSERT INTO [BCA].[CitizenAddress]
([citizen_id], [address_id], [address_type], [from_date], [to_date], [is_primary], [status], [registration_document_no], [registration_date], [issuing_authority_id])
VALUES
('010203000002', @address5, N'Thường trú', '2005-07-22', NULL, 1, 1, 'HK100187', '2005-07-22', 100);

-- 6. Thêm lịch sử cư trú cho công dân 3 - Lê Văn Cường (nhiều lần thay đổi)
-- Thường trú 1
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [status])
VALUES
('010203000003', @address6, N'Thường trú', '2000-03-18', NULL, N'Đăng ký lần đầu', NULL, 100, 'PT100234', 'Moved');

-- Thường trú 2
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [status])
VALUES
('010203000003', @address7, N'Thường trú', '2010-05-30', NULL, N'Chuyển từ nơi thường trú cũ', @address6, 100, 'PT100456', 'Moved');

-- Thường trú 3 (hiện tại)
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [status])
VALUES
('010203000003', @address8, N'Thường trú', '2019-11-12', NULL, N'Chuyển từ nơi thường trú cũ', @address7, 100, 'PT100789', 'Active');

-- Thêm nhiều lần tạm trú khác nhau
INSERT INTO [BCA].[ResidenceHistory] 
([citizen_id], [address_id], [residence_type], [registration_date], [expiry_date], [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number], [host_name], [status])
VALUES
('010203000003', @address1, N'Tạm trú', '2008-02-15', '2009-02-15', N'Học tập', NULL, 100, 'TT100321', N'Nguyễn Văn An', 'Expired'),
('010203000003', @address3, N'Tạm trú', '2012-09-01', '2015-07-30', N'Học tập', NULL, 100, 'TT100432', N'Đặng Văn Quản Lý', 'Expired'),
('010203000003', @address4, N'Tạm trú', '2017-01-20', '2018-01-20', N'Công tác', NULL, 100, 'TT100567', N'Đỗ Thị Chủ Nhà', 'Expired');

-- Thêm dữ liệu tạm vắng
INSERT INTO [BCA].[TemporaryAbsence]
([citizen_id], [from_date], [to_date], [reason], [destination_address_id], [destination_detail], [contact_information], [registration_authority_id], [registration_number], [status])
VALUES
('010203000003', '2019-03-15', '2019-06-15', N'Thực tập nước ngoài', NULL, N'Thượng Hải, Trung Quốc', N'WeChat: levan123', 100, 'TV100045', 'Returned');

-- Thêm địa chỉ hiện tại
INSERT INTO [BCA].[CitizenAddress]
([citizen_id], [address_id], [address_type], [from_date], [to_date], [is_primary], [status], [registration_document_no], [registration_date], [issuing_authority_id])
VALUES
('010203000003', @address8, N'Thường trú', '2019-11-12', NULL, 1, 1, 'HK100356', '2019-11-12', 100),
('010203000003', @address3, N'Công ty', '2020-06-01', NULL, 0, 1, NULL, NULL, NULL),
('010203000003', @address1, N'Khác', '2023-05-01', NULL, 0, 1, NULL, NULL, NULL);

-- 7. Cập nhật thông tin liên hệ trong bảng Citizen
UPDATE [BCA].[Citizen]
SET [phone_number] = '0901234567', [email] = 'nguyenvanan@example.com'
WHERE [citizen_id] = '010203000001';

UPDATE [BCA].[Citizen]
SET [phone_number] = '0912345678', [email] = 'tranthib@example.com'
WHERE [citizen_id] = '010203000002';

UPDATE [BCA].[Citizen]
SET [phone_number] = '0987654321', [email] = 'levanc@example.com'
WHERE [citizen_id] = '010203000003';

PRINT N'Đã thêm dữ liệu mẫu cho 3 công dân với lịch sử cư trú khác nhau';
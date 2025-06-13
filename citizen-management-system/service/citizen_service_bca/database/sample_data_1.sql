-- Sample data for DB_BCA (Bộ Công An)
USE [DB_BCA];
GO

PRINT N'Adding sample data to BCA schema tables...';

--------------------------------------------------------------------------------
-- 1. BCA.Address (Sample addresses for citizens)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.Address...';

SET IDENTITY_INSERT [BCA].[Address] ON;
INSERT INTO [BCA].[Address] (
    [address_id], [address_detail], [ward_id], [district_id], [province_id], 
    [postal_code], [latitude], [longitude], [status], [notes], [created_at], [updated_at]
) VALUES 
    (1, N'Số 15, Ngõ 76, Phố Phúc Xá', 1001, 101, 1, '100000', 21.043480, 105.848200, 1, NULL, GETDATE(), GETDATE()),
    (2, N'Số 42, Ngõ 128, Giảng Võ', 1009, 101, 1, '100000', 21.027640, 105.829200, 1, NULL, GETDATE(), GETDATE()),
    (3, N'Số 78, Ngách 281/24, Trúc Bạch', 1002, 101, 1, '100000', 21.045720, 105.841900, 1, NULL, GETDATE(), GETDATE()),
    (4, N'Số 234, Đội Cấn', 1006, 101, 1, '100000', 21.035230, 105.835700, 1, NULL, GETDATE(), GETDATE()),
    (5, N'Số 67, Thành Công', 1010, 101, 1, '100000', 21.023100, 105.823500, 1, NULL, GETDATE(), GETDATE()),
    (6, N'Số 105, Ngách 12, Ngõ 4, Thổ Quan', 107, 106, 1, '100000', 21.012340, 105.832100, 1, NULL, GETDATE(), GETDATE()),
    (7, N'Số 9, Ngõ 376, Phố Bưởi', 105, 105, 1, '100000', 21.032560, 105.807800, 1, NULL, GETDATE(), GETDATE()),
    (8, N'Số 221, Đường Nguyễn Thái Học', 103, 103, 1, '100000', 21.036789, 105.837400, 1, NULL, GETDATE(), GETDATE()),
    (9, N'Tổ 5, Thôn Đại Phùng', 112, 111, 1, '100000', 21.087654, 105.654321, 1, NULL, GETDATE(), GETDATE()),
    (10, N'Số 56, Thôn An Trạch', 110, 110, 1, '100000', 21.098765, 105.543210, 1, NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[Address] OFF;
GO

--------------------------------------------------------------------------------
-- 2. BCA.Citizen (Core citizen information)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.Citizen...';

-- Using citizen_id format: 12 digits where first 3 represent province code
INSERT INTO [BCA].[Citizen] (
    [citizen_id], [full_name], [date_of_birth], [gender_id], 
    [birth_province_id], [birth_district_id], [birth_ward_id],
    [native_province_id], [native_district_id], [native_ward_id],
    [primary_address_id], [nationality_id], [ethnicity_id], [religion_id],
    [marital_status_id], [education_level_id], [occupation_id],
    [father_citizen_id], [mother_citizen_id], [spouse_citizen_id],
    [citizen_status_id], [status_change_date], [phone_number], [email],
    [blood_type_id], [tax_code], [created_at], [updated_at]
) VALUES
-- Family 1: Nguyễn Family
    ('001089123456', N'Nguyễn Văn Minh', '1975-05-10', 1, -- Male
        1, 101, 1001, 1, 101, 1001, 1, 1, 1, 1, -- Born and native to Hanoi
        2, 7, 3, -- Married, Education: University, Occupation: Government employee
        NULL, NULL, '001091345612', -- Parents unknown, has spouse
        1, NULL, '0912345678', 'minh.nguyenvan@email.com',
        7, '8762345127', GETDATE(), GETDATE()),
        
    ('001091345612', N'Nguyễn Thị Hương', '1979-08-15', 2, -- Female
        1, 101, 1002, 26, 101, 1002, 1, 1, 1, 2, -- Born Hanoi, native to Thanh Hóa
        2, 7, 4, -- Married, Education: University, Occupation: Teacher
        NULL, NULL, '001089123456', -- Parents unknown, spouse is Minh
        1, NULL, '0923456789', 'huong.nguyenthi@email.com',
        5, '8762345128', GETDATE(), GETDATE()),
        
    ('001299876543', N'Nguyễn Đức Anh', '2005-03-20', 1, -- Male, child of family 1
        1, 101, 1001, 1, 101, 1001, 1, 1, 1, 1,
        1, 4, 11, -- Single, Education: High school, Occupation: Student
        '001089123456', '001091345612', NULL, -- Son of Minh and Hương
        1, NULL, '0934567890', 'anh.nguyenduc@email.com',
        7, NULL, GETDATE(), GETDATE()),
        
    ('001209861234', N'Nguyễn Thị Mai Anh', '2010-12-05', 2, -- Female, child of family 1
        1, 101, 1001, 1, 101, 1001, 1, 1, 1, 1,
        1, 3, 11, -- Single, Education: Middle school, Occupation: Student
        '001089123456', '001091345612', NULL, -- Daughter of Minh and Hương
        1, NULL, NULL, NULL,
        5, NULL, GETDATE(), GETDATE()),

-- Family 2: Trần Family
    ('001074853214', N'Trần Đình Phúc', '1968-11-22', 1, -- Male
        1, 101, 1006, 1, 101, 1006, 2, 1, 1, 1,
        2, 6, 6, -- Married, Education: College, Occupation: Engineer
        NULL, NULL, '001076831495', -- Parents unknown, has spouse
        1, NULL, '0945678901', 'phuc.trandinh@email.com',
        1, '8762345129', GETDATE(), GETDATE()),
        
    ('001076831495', N'Trần Thị Lan', '1972-04-18', 2, -- Female
        1, 101, 1010, 1, 101, 1010, 2, 1, 1, 1,
        2, 6, 7, -- Married, Education: College, Occupation: Office worker
        NULL, NULL, '001074853214', -- Parents unknown, spouse is Phúc
        1, NULL, '0956789012', 'lan.tranthi@email.com',
        3, '8762345130', GETDATE(), GETDATE()),
        
    ('001201786523', N'Trần Đình Quang', '2000-07-07', 1, -- Male, child of family 2
        1, 101, 1010, 1, 101, 1010, 2, 1, 1, 1,
        1, 7, 12, -- Single, Education: University, Occupation: College student
        '001074853214', '001076831495', NULL, -- Son of Phúc and Lan
        1, NULL, '0967890123', 'quang.trandinh@email.com',
        1, NULL, GETDATE(), GETDATE()),

-- Family 3: Lê Family
    ('001062415789', N'Lê Văn Tùng', '1950-02-15', 1, -- Male, elderly
        1, 101, 1002, 1, 101, 1002, 3, 1, 1, 1,
        4, 4, 15, -- Widowed, Education: High school, Occupation: Retired
        NULL, NULL, NULL, -- Parents unknown, spouse deceased
        1, NULL, '0978901234', NULL,
        4, '8762345131', GETDATE(), GETDATE()),
        
    ('001067218934', N'Lê Thị Hiền', '1948-09-30', 2, -- Female, deceased spouse of Tùng
        1, 101, 1006, 1, 101, 1006, 3, 1, 1, 1,
        4, 3, 15, -- Widowed, Education: Middle school, Occupation: Retired
        NULL, NULL, '001062415789', -- Parents unknown, spouse is Tùng
        2, '2020-08-12', NULL, NULL, -- Deceased
        3, '8762345132', GETDATE(), GETDATE()),
        
    ('001187654321', N'Lê Văn Hùng', '1978-06-20', 1, -- Male, son of family 3
        1, 101, 1002, 1, 101, 1002, 4, 1, 1, 1,
        3, 7, 6, -- Divorced, Education: University, Occupation: Engineer
        '001062415789', '001067218934', NULL, -- Son of Tùng and Hiền
        1, NULL, '0989012345', 'hung.levan@email.com',
        4, '8762345133', GETDATE(), GETDATE()),
        
-- Independent citizens
    ('001196325874', N'Phạm Thị Thảo', '1985-11-11', 2, -- Female, independent
        28, 101, 1002, 28, 101, 1002, 5, 1, 1, 1,
        1, 8, 9, -- Single, Education: Master, Occupation: Lawyer
        NULL, NULL, NULL, -- No parents or spouse registered
        1, NULL, '0990123456', 'thao.phamthi@email.com',
        7, '8762345134', GETDATE(), GETDATE()),
        
    ('001198752461', N'Vũ Đức Thắng', '1982-03-25', 1, -- Male, independent
        45, 101, 1010, 45, 101, 1010, 6, 1, 1, 1,
        3, 7, 18, -- Divorced, Education: University, Occupation: Programmer
        NULL, NULL, NULL, -- No parents or spouse registered
        1, NULL, '0901234567', 'thang.vuduc@email.com',
        8, '8762345135', GETDATE(), GETDATE()),
        
    ('045198745632', N'Hoàng Minh Tuấn', '1990-12-01', 1, -- Male from HCMC
        45, 101, 1001, 45, 101, 1001, 7, 1, 1, 1,
        2, 7, 8, -- Married, Education: University, Occupation: Business
        NULL, NULL, '001293156482', -- Parents unknown, has spouse
        1, NULL, '0912123434', 'tuan.hoangminh@email.com',
        1, '8762345136', GETDATE(), GETDATE()),
        
    ('001293156482', N'Hoàng Thị Thu Nga', '1992-05-15', 2, -- Female, spouse from Hanoi
        1, 106, 1002, 1, 106, 1002, 7, 1, 1, 1,
        2, 7, 19, -- Married, Education: University, Occupation: Finance
        NULL, NULL, '045198745632', -- Parents unknown, spouse is Tuấn
        1, NULL, '0934343434', 'nga.hoangthi@email.com',
        3, '8762345137', GETDATE(), GETDATE()),
        
    ('001191357924', N'Trương Văn Đạt', '1995-08-30', 1, -- Male, with criminal record
        1, 104, 1008, 1, 104, 1008, 8, 1, 1, 1,
        1, 5, 20, -- Single, Education: Vocational, Occupation: Other
        NULL, NULL, NULL, -- No parents or spouse registered
        1, NULL, '0923232323', NULL,
        9, '8762345138', GETDATE(), GETDATE());
GO

--------------------------------------------------------------------------------
-- 3. BCA.IdentificationCard (ID cards for citizens)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.IdentificationCard...';

SET IDENTITY_INSERT [BCA].[IdentificationCard] ON;
INSERT INTO [BCA].[IdentificationCard] (
    [id_card_id], [citizen_id], [card_number], [card_type_id], 
    [issue_date], [expiry_date], [issuing_authority_id], [issuing_place],
    [card_status_id], [previous_card_number], [notes], [created_at], [updated_at]
) VALUES
    -- Family 1
    (1, '001089123456', '001089123456', 3, -- CCCD with chip
        '2021-06-15', '2036-06-15', 101, N'Công an thành phố Hà Nội',
        1, '123456789', NULL, GETDATE(), GETDATE()),
        
    (2, '001091345612', '001091345612', 3, -- CCCD with chip
        '2021-06-20', '2036-06-20', 101, N'Công an thành phố Hà Nội',
        1, '123456790', NULL, GETDATE(), GETDATE()),
        
    (3, '001299876543', '001299876543', 3, -- CCCD with chip
        '2023-04-10', '2038-04-10', 101, N'Công an thành phố Hà Nội',
        1, NULL, NULL, GETDATE(), GETDATE()),
        
    -- Family 2
    (4, '001074853214', '001074853214', 3, -- CCCD with chip
        '2022-03-15', '2037-03-15', 101, N'Công an thành phố Hà Nội',
        1, '123456791', NULL, GETDATE(), GETDATE()),
        
    (5, '001076831495', '001076831495', 3, -- CCCD with chip
        '2022-03-20', '2037-03-20', 101, N'Công an thành phố Hà Nội',
        1, '123456792', NULL, GETDATE(), GETDATE()),
        
    (6, '001201786523', '001201786523', 3, -- CCCD with chip
        '2022-08-05', '2037-08-05', 101, N'Công an thành phố Hà Nội',
        1, NULL, NULL, GETDATE(), GETDATE()),
        
    -- Family 3
    (7, '001062415789', '001062415789', 3, -- CCCD with chip
        '2021-05-10', '2036-05-10', 101, N'Công an thành phố Hà Nội',
        1, '123456793', NULL, GETDATE(), GETDATE()),
        
    (8, '001067218934', '001067218934', 3, -- CCCD with chip
        '2019-06-12', '2034-06-12', 101, N'Công an thành phố Hà Nội',
        4, '123456794', N'Thu hồi do công dân đã mất ngày 12/08/2020', GETDATE(), GETDATE()),
        
    (9, '001187654321', '001187654321', 3, -- CCCD with chip
        '2021-07-25', '2036-07-25', 101, N'Công an thành phố Hà Nội',
        1, '123456795', NULL, GETDATE(), GETDATE()),
        
    -- Independent citizens
    (10, '001196325874', '001196325874', 3, -- CCCD with chip
        '2022-10-17', '2037-10-17', 101, N'Công an thành phố Hà Nội',
        1, '123456796', NULL, GETDATE(), GETDATE()),
        
    (11, '001198752461', '001198752461', 3, -- CCCD with chip
        '2022-09-15', '2037-09-15', 101, N'Công an thành phố Hà Nội',
        1, '123456797', NULL, GETDATE(), GETDATE()),
        
    (12, '045198745632', '045198745632', 3, -- CCCD with chip
        '2021-12-20', '2036-12-20', 102, N'Công an thành phố Hồ Chí Minh',
        1, '123456798', NULL, GETDATE(), GETDATE()),
        
    (13, '001293156482', '001293156482', 3, -- CCCD with chip
        '2022-05-18', '2037-05-18', 101, N'Công an thành phố Hà Nội',
        1, '123456799', NULL, GETDATE(), GETDATE()),
        
    (14, '001191357924', '001191357924', 3, -- CCCD with chip
        '2022-11-05', '2037-11-05', 101, N'Công an thành phố Hà Nội',
        1, '123456800', NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[IdentificationCard] OFF;
GO

--------------------------------------------------------------------------------
-- 4. BCA.ResidenceHistory (Residence registration)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.ResidenceHistory...';

SET IDENTITY_INSERT [BCA].[ResidenceHistory] ON;
INSERT INTO [BCA].[ResidenceHistory] (
    [residence_history_id], [citizen_id], [address_id], [residence_type_id], 
    [registration_date], [expiry_date], [registration_reason], [previous_address_id],
    [issuing_authority_id], [registration_number], [host_name], [host_citizen_id],
    [host_relationship], [res_reg_status_id], [notes], [created_at], [updated_at]
) VALUES
    -- Family 1 - Permanent residence
    (1, '001089123456', 1, 1, -- Permanent residence
        '2015-04-10', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2015-001', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (2, '001091345612', 1, 1, -- Permanent residence
        '2015-04-10', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2015-002', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (3, '001299876543', 1, 1, -- Permanent residence
        '2015-04-10', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2015-003', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (4, '001209861234', 1, 1, -- Permanent residence
        '2015-04-10', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2015-004', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    -- Family 2 - Permanent residence
    (5, '001074853214', 2, 1, -- Permanent residence
        '2010-08-15', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2010-005', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (6, '001076831495', 2, 1, -- Permanent residence
        '2010-08-15', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2010-006', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (7, '001201786523', 2, 1, -- Permanent residence
        '2010-08-15', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2010-007', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    -- Family 3 - Permanent residence
    (8, '001062415789', 3, 1, -- Permanent residence
        '2005-06-20', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2005-008', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (9, '001067218934', 3, 1, -- Permanent residence (deceased)
        '2005-06-20', '2020-08-12', N'Đăng ký thường trú mới', NULL,
        401, 'TT-2005-009', NULL, NULL,
        NULL, 3, N'Đã chấm dứt đăng ký thường trú do qua đời', GETDATE(), GETDATE()),
        
    -- Independent Người in different addresses
    (10, '001187654321', 4, 1, -- Permanent residence
        '2018-05-12', NULL, N'Chuyển đến từ địa chỉ khác', 3,
        401, 'TT-2018-010', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (11, '001196325874', 5, 1, -- Permanent residence
        '2019-09-10', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2019-011', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (12, '001198752461', 6, 1, -- Permanent residence
        '2020-01-15', NULL, N'Đăng ký thường trú mới', NULL,
        404, 'TT-2020-012', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    -- Married couple from different cities
    (13, '045198745632', 7, 1, -- Permanent residence
        '2022-01-20', NULL, N'Chuyển từ TP HCM', NULL,
        401, 'TT-2022-013', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    (14, '001293156482', 7, 1, -- Permanent residence
        '2022-01-20', NULL, N'Đăng ký thường trú mới', NULL,
        401, 'TT-2022-014', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE()),
        
    -- Criminal record Người
    (15, '001191357924', 8, 1, -- Permanent residence
        '2021-03-15', NULL, N'Đăng ký thường trú mới', NULL,
        403, 'TT-2021-015', NULL, NULL,
        NULL, 1, NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[ResidenceHistory] OFF;
GO

--------------------------------------------------------------------------------
-- 5. BCA.CitizenStatus (Status changes for citizens)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.CitizenStatus...';

SET IDENTITY_INSERT [BCA].[CitizenStatus] ON;
INSERT INTO [BCA].[CitizenStatus] (
    [status_id], [citizen_id], [citizen_status_id], [status_date], 
    [description], [cause], [location], [authority_id],
    [document_number], [document_date], [certificate_id], [is_current],
    [notes], [created_at], [updated_at]
) VALUES
    -- Normal status for most citizens
    (1, '001089123456', 1, '1975-05-10', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (2, '001091345612', 1, '1979-08-15', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (3, '001299876543', 1, '2005-03-20', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (4, '001209861234', 1, '2010-12-05', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (5, '001074853214', 1, '1968-11-22', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (6, '001076831495', 1, '1972-04-18', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (7, '001201786523', 1, '2000-07-07', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (8, '001062415789', 1, '1950-02-15', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    -- Deceased citizen
    (9, '001067218934', 1, '1948-09-30', -- Initially alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 0, -- Not current anymore
        NULL, GETDATE(), GETDATE()),
        
    (10, '001067218934', 2, '2020-08-12', -- Deceased
        N'Công dân đã mất', N'Bệnh lý', N'Bệnh viện Bạch Mai, Hà Nội', 101,
        'CT-2020-001', '2020-08-13', 'DC-2020-001', 1, -- Current status
        NULL, GETDATE(), GETDATE()),
        
    -- Other citizens
    (11, '001187654321', 1, '1978-06-20', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (12, '001196325874', 1, '1985-11-11', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (13, '001198752461', 1, '1982-03-25', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (14, '045198745632', 1, '1990-12-01', -- Alive
        N'Công dân còn sống', NULL, NULL, 102,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (15, '001293156482', 1, '1992-05-15', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE()),
        
    (16, '001191357924', 1, '1995-08-30', -- Alive
        N'Công dân còn sống', NULL, NULL, 101,
        NULL, NULL, NULL, 1,
        NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[CitizenStatus] OFF;
GO

--------------------------------------------------------------------------------
-- 6. BCA.TemporaryAbsence (Temporary absence records)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.TemporaryAbsence...';

SET IDENTITY_INSERT [BCA].[TemporaryAbsence] ON;
INSERT INTO [BCA].[TemporaryAbsence] (
    [temporary_absence_id], [citizen_id], [from_date], [to_date], 
    [reason], [destination_detail], [contact_information],
    [registration_authority_id], [registration_number],
    [return_date], [return_confirmed], [temp_abs_status_id], 
    [sensitivity_level_id], [created_at], [updated_at]
) VALUES
    (1, '001201786523', '2023-06-15', '2023-08-20', -- Student summer internship
        N'Thực tập hè', N'Công ty ABC, 123 Nguyễn Huệ, Quận 1, TP.HCM', 
        N'0967890123, quang.trandinh@email.com',
        401, 'TV-2023-001', 
        '2023-08-19', 1, 2, -- Returned, status RETURNED
        1, GETDATE(), GETDATE()),
        
    (2, '001196325874', '2023-10-01', '2024-03-31', -- Work assignment
        N'Công tác nước ngoài', N'Tokyo, Nhật Bản', 
        N'0990123456, thao.phamthi@email.com',
        401, 'TV-2023-002', 
        NULL, 0, 1, -- Not yet returned, status ACTIVE
        2, GETDATE(), GETDATE()),
        
    (3, '001191357924', '2022-05-10', '2022-08-15', -- prison
        N'Chấp hành án phạt tù', N'Trại giam Hòa Bình', 
        NULL,
        401, 'TV-2022-003', 
        '2022-08-15', 1, 2, -- Returned, status RETURNED
        3, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[TemporaryAbsence] OFF;
GO

--------------------------------------------------------------------------------
-- 7. BCA.CitizenMovement (Movement records)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.CitizenMovement...';

SET IDENTITY_INSERT [BCA].[CitizenMovement] ON;
INSERT INTO [BCA].[CitizenMovement] (
    [movement_id], [citizen_id], [movement_type_id], 
    [from_address_id], [to_address_id], [from_country_id], [to_country_id],
    [departure_date], [arrival_date], [purpose], [document_no],
    [document_type_id], [movement_status_id], [created_at], [updated_at]
) VALUES
    (1, '001089123456', 2, -- Xuất cảnh (Exit from Vietnam)
        1, NULL, 1, 5, -- From address 1 to Japan
        '2023-03-15', '2023-03-20', N'Công tác', 'A12345678',
        3, 2, -- Status: Completed
        GETDATE(), GETDATE()),
        
    (2, '001089123456', 4, -- Tái nhập cảnh (Return to Vietnam)
        NULL, 1, 5, 1, -- From Japan to address 1
        '2023-03-30', '2023-03-30', N'Về nước', 'A12345678',
        3, 2, -- Status: Completed
        GETDATE(), GETDATE()),
        
    (3, '001201786523', 1, -- Di chuyển trong nước (Domestic movement)
        2, 9, 1, 1, -- From address 2 to address 9
        '2023-01-10', '2023-01-10', N'Thăm người thân', NULL,
        NULL, 2, -- Status: Completed
        GETDATE(), GETDATE()),
        
    (4, '045198745632', 1, -- Di chuyển trong nước (Domestic movement - relocation)
        NULL, 7, 1, 1, -- From unknown to address 7 (moved from HCMC to Hanoi)
        '2022-01-15', '2022-01-15', N'Chuyển nơi cư trú', NULL,
        NULL, 2, -- Status: Completed
        GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[CitizenMovement] OFF;
GO

--------------------------------------------------------------------------------
-- 8. BCA.CriminalRecord (Criminal records)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.CriminalRecord...';

SET IDENTITY_INSERT [BCA].[CriminalRecord] ON;
INSERT INTO [BCA].[CriminalRecord] (
    [record_id], [citizen_id], [crime_type_id], [crime_description], 
    [crime_date], [court_name], [judgment_no], [judgment_date],
    [sentence_description], [sentence_start_date], [sentence_end_date],
    [prison_facility_id], [execution_status_id], [sensitivity_level_id],
    [created_at], [updated_at]
) VALUES
    (1, '001191357924', 203, -- Trộm cắp tài sản (Theft)
        N'Trộm cắp tài sản có giá trị 20 triệu đồng',
        '2022-02-15', N'Tòa án nhân dân quận Tây Hồ', 'TA-2022-125', '2022-04-20',
        N'Phạt tù 3 tháng',
        '2022-05-10', '2022-08-09',
        1, 2, -- Prison facility: Trại giam Hòa Bình, Status: Completed
        3, -- Sensitivity: Confidential
        GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[CriminalRecord] OFF;
GO

--------------------------------------------------------------------------------
-- 9. BCA.CitizenAddress (Citizen addresses of various types)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BCA.CitizenAddress...';

SET IDENTITY_INSERT [BCA].[CitizenAddress] ON;
INSERT INTO [BCA].[CitizenAddress] (
    [citizen_address_id], [citizen_id], [address_id], [address_type_id], 
    [from_date], [to_date], [is_primary], [status],
    [verification_status], [notes], [created_at], [updated_at]
) VALUES
    -- Family 1
    (1, '001089123456', 1, 1, -- Permanent address
        '2015-04-10', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (2, '001091345612', 1, 1, -- Permanent address
        '2015-04-10', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (3, '001299876543', 1, 1, -- Permanent address
        '2015-04-10', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (4, '001209861234', 1, 1, -- Permanent address
        '2015-04-10', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    -- Family 2
    (5, '001074853214', 2, 1, -- Permanent address
        '2010-08-15', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (6, '001076831495', 2, 1, -- Permanent address
        '2010-08-15', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (7, '001201786523', 2, 1, -- Permanent address
        '2010-08-15', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    -- Special case: work address for a citizen
    (8, '001201786523', 8, 4, -- Work address
        '2022-06-01', NULL, 0, 1,
        N'Đã xác minh', N'Địa chỉ công ty làm việc', GETDATE(), GETDATE()),
        
    -- Independent citizens and others
    (9, '001062415789', 3, 1, -- Permanent address
        '2005-06-20', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (10, '001067218934', 3, 1, -- Permanent address (deceased)
        '2005-06-20', '2020-08-12', 1, 0,
        N'Đã xác minh', N'Đã chấm dứt do qua đời', GETDATE(), GETDATE()),
        
    (11, '001187654321', 4, 1, -- Permanent address
        '2018-05-12', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (12, '001196325874', 5, 1, -- Permanent address
        '2019-09-10', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    -- Address abroad for temporary work
    (13, '001196325874', 10, 4, -- Work address abroad (temporary)
        '2023-10-01', '2024-03-31', 0, 1,
        N'Đã xác minh', N'Địa chỉ công tác tại nước ngoài', GETDATE(), GETDATE()),
        
    (14, '001198752461', 6, 1, -- Permanent address
        '2020-01-15', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (15, '045198745632', 7, 1, -- Permanent address
        '2022-01-20', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (16, '001293156482', 7, 1, -- Permanent address
        '2022-01-20', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE()),
        
    (17, '001191357924', 8, 1, -- Permanent address
        '2021-03-15', NULL, 1, 1,
        N'Đã xác minh', NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[CitizenAddress] OFF;
GO

PRINT N'Sample data has been added to BCA schema tables successfully.';


--------------------------------------------------------------------------------
-- 5. BTP.Household (Household registration)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.Household...';

SET IDENTITY_INSERT [BCA].[Household] ON;
INSERT INTO [BCA].[Household] (
    [household_id], [household_book_no], [head_of_household_id], 
    [address_id], [registration_date], [issuing_authority_id],
    [area_code], [household_type_id], [household_status_id],
    [notes], [created_at], [updated_at]
) VALUES
    -- Family 1
    (1, 'HK-2015-00123', '001089123456', 
        1, '2015-04-15', 401,
        'BA_DINH_01', 1, 1,
        NULL, GETDATE(), GETDATE()),
        
    -- Family 2
    (2, 'HK-2010-00678', '001074853214', 
        2, '2010-08-20', 401,
        'BA_DINH_02', 1, 1,
        NULL, GETDATE(), GETDATE()),
        
    -- Family 3
    (3, 'HK-2005-00456', '001062415789', 
        3, '2005-07-01', 401,
        'BA_DINH_03', 1, 1,
        NULL, GETDATE(), GETDATE()),
        
    -- Independent son of Family 3
    (4, 'HK-2018-01234', '001187654321', 
        4, '2018-05-15', 401,
        'BA_DINH_04', 4, 1, -- Family type: Individual
        NULL, GETDATE(), GETDATE()),
        
    -- Independent woman
    (5, 'HK-2019-01567', '001196325874', 
        5, '2019-09-15', 401,
        'BA_DINH_05', 4, 1, -- Family type: Individual
        NULL, GETDATE(), GETDATE()),
        
    -- Independent man
    (6, 'HK-2020-02345', '001198752461', 
        6, '2020-01-20', 401,
        'DONG_DA_01', 4, 1, -- Family type: Individual
        NULL, GETDATE(), GETDATE()),
        
    -- Couple from different cities
    (7, 'HK-2022-00789', '045198745632', 
        7, '2022-01-25', 401,
        'CAU_GIAY_01', 1, 1,
        NULL, GETDATE(), GETDATE()),
        
    -- Criminal record person
    (8, 'HK-2021-03456', '001191357924', 
        8, '2021-03-20', 401,
        'TAY_HO_01', 4, 1, -- Family type: Individual
        NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[Household] OFF;
GO

--------------------------------------------------------------------------------
-- 6. BTP.HouseholdMember (Household members)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.HouseholdMember...';

SET IDENTITY_INSERT [BCA].[HouseholdMember] ON;
INSERT INTO [BCA].[HouseholdMember] (
    [household_member_id], [household_id], [citizen_id], 
    [rel_with_head_id], [join_date], [leave_date], [leave_reason],
    [previous_household_id], [member_status_id], [order_in_household],
    [created_at], [updated_at]
) VALUES
    -- Family 1
    (1, 1, '001089123456', 
        1, '2015-04-15', NULL, NULL, -- Head of household
        NULL, 1, 1, -- Status: Active
        GETDATE(), GETDATE()),
        
    (2, 1, '001091345612', 
        2, '2015-04-15', NULL, NULL, -- Wife of head
        NULL, 1, 2, -- Status: Active
        GETDATE(), GETDATE()),
        
    (3, 1, '001299876543', 
        4, '2015-04-15', NULL, NULL, -- Son
        NULL, 1, 3, -- Status: Active
        GETDATE(), GETDATE()),
        
    (4, 1, '001209861234', 
        4, '2015-04-15', NULL, NULL, -- Daughter
        NULL, 1, 4, -- Status: Active
        GETDATE(), GETDATE()),
        
    -- Family 2
    (5, 2, '001074853214', 
        1, '2010-08-20', NULL, NULL, -- Head of household
        NULL, 1, 1, -- Status: Active
        GETDATE(), GETDATE()),
        
    (6, 2, '001076831495', 
        2, '2010-08-20', NULL, NULL, -- Wife of head
        NULL, 1, 2, -- Status: Active
        GETDATE(), GETDATE()),
        
    (7, 2, '001201786523', 
        4, '2010-08-20', NULL, NULL, -- Son
        NULL, 1, 3, -- Status: Active
        GETDATE(), GETDATE()),
        
    -- Family 3
    (8, 3, '001062415789', 
        1, '2005-07-01', NULL, NULL, -- Head of household
        NULL, 1, 1, -- Status: Active
        GETDATE(), GETDATE()),
        
    (9, 3, '001067218934', 
        2, '2005-07-01', '2020-08-12', N'Đã mất', -- Wife of head (deceased)
        NULL, 4, 2, -- Status: Deceased
        GETDATE(), GETDATE()),
        
    (10, 3, '001187654321', 
        4, '2005-07-01', '2018-05-12', N'Tách hộ', -- Son (moved out)
        NULL, 2, 3, -- Status: Left
        GETDATE(), GETDATE()),
        
    -- Independent son of Family 3 - now head of his own household
    (11, 4, '001187654321', 
        1, '2018-05-15', NULL, NULL, -- Head of household
        3, 1, 1, -- Status: Active, previous household: 3
        GETDATE(), GETDATE()),
        
    -- Independent woman
    (12, 5, '001196325874', 
        1, '2019-09-15', NULL, NULL, -- Head of household
        NULL, 1, 1, -- Status: Active
        GETDATE(), GETDATE()),
        
    -- Independent man
    (13, 6, '001198752461', 
        1, '2020-01-20', NULL, NULL, -- Head of household
        NULL, 1, 1, -- Status: Active
        GETDATE(), GETDATE()),
        
    -- Couple from different cities
    (14, 7, '045198745632', 
        1, '2022-01-25', NULL, NULL, -- Head of household
        NULL, 1, 1, -- Status: Active
        GETDATE(), GETDATE()),
        
    (15, 7, '001293156482', 
        2, '2022-01-25', NULL, NULL, -- Wife of head
        NULL, 1, 2, -- Status: Active
        GETDATE(), GETDATE()),
        
    -- Criminal record person
    (16, 8, '001191357924', 
        1, '2021-03-20', NULL, NULL, -- Head of household
        NULL, 1, 1, -- Status: Active
        GETDATE(), GETDATE());
SET IDENTITY_INSERT [BCA].[HouseholdMember] OFF;
GO

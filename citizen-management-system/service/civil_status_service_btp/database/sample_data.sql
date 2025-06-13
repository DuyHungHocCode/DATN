-- Sample data for DB_BTP (Bộ Tư pháp)
USE [DB_BTP];
GO

PRINT N'Adding sample data to BTP schema tables...';

--------------------------------------------------------------------------------
-- 1. BTP.BirthCertificate (Birth certificates)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.BirthCertificate...';

SET IDENTITY_INSERT [BTP].[BirthCertificate] ON;
INSERT INTO [BTP].[BirthCertificate] (
    [birth_certificate_id], [citizen_id], [birth_certificate_no], 
    [registration_date], [book_id], [page_no], [issuing_authority_id],
    [place_of_birth], [date_of_birth], [gender_id],
    [father_full_name], [father_citizen_id], [father_date_of_birth], [father_nationality_id],
    [mother_full_name], [mother_citizen_id], [mother_date_of_birth], [mother_nationality_id],
    [declarant_name], [declarant_citizen_id], [declarant_relationship], 
    [birth_notification_no], [status], [created_at], [updated_at]
) VALUES
    -- Family 1 children
    (1, '001299876543', 'GKS-2005-00015', 
        '2005-03-25', 'KS-2005-A', '12', 201,
        N'Bệnh viện Phụ sản Hà Nội', '2005-03-20', 1,
        N'Nguyễn Văn Minh', '001089123456', '1975-05-10', 1,
        N'Nguyễn Thị Hương', '001091345612', '1979-08-15', 1,
        N'Nguyễn Văn Minh', '001089123456', N'Cha', 
        'TTBN-2005-031', 1, GETDATE(), GETDATE()),
        
    (2, '001209861234', 'GKS-2010-02187', 
        '2010-12-10', 'KS-2010-B', '45', 201,
        N'Bệnh viện Phụ sản Hà Nội', '2010-12-05', 2,
        N'Nguyễn Văn Minh', '001089123456', '1975-05-10', 1,
        N'Nguyễn Thị Hương', '001091345612', '1979-08-15', 1,
        N'Nguyễn Thị Hương', '001091345612', N'Mẹ', 
        'TTBN-2010-142', 1, GETDATE(), GETDATE()),
        
    -- Family 2 child
    (3, '001201786523', 'GKS-2000-01243', 
        '2000-07-12', 'KS-2000-A', '78', 201,
        N'Bệnh viện Bạch Mai', '2000-07-07', 1,
        N'Trần Đình Phúc', '001074853214', '1968-11-22', 1,
        N'Trần Thị Lan', '001076831495', '1972-04-18', 1,
        N'Trần Đình Phúc', '001074853214', N'Cha', 
        'TTBN-2000-087', 1, GETDATE(), GETDATE()),
        
    -- Family 3 son
    (4, '001187654321', 'GKS-1978-00785', 
        '1978-06-25', 'KS-1978-A', '15', 201,
        N'Bệnh viện Đa khoa Đống Đa', '1978-06-20', 1,
        N'Lê Văn Tùng', '001062415789', '1950-02-15', 1,
        N'Lê Thị Hiền', '001067218934', '1948-09-30', 1,
        N'Lê Văn Tùng', '001062415789', N'Cha', 
        'TTBN-1978-053', 1, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BTP].[BirthCertificate] OFF;
GO

--------------------------------------------------------------------------------
-- 2. BTP.DeathCertificate (Death certificates)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.DeathCertificate...';

SET IDENTITY_INSERT [BTP].[DeathCertificate] ON;
INSERT INTO [BTP].[DeathCertificate] (
    [death_certificate_id], [citizen_id], [death_certificate_no], 
    [book_id], [page_no], [date_of_death], [time_of_death],
    [place_of_death_detail], [place_of_death_ward_id], 
    [place_of_death_district_id], [place_of_death_province_id],
    [cause_of_death], [declarant_name], [declarant_citizen_id], 
    [declarant_relationship], [registration_date], [issuing_authority_id],
    [death_notification_no], [status], [created_at], [updated_at]
) VALUES
    (1, '001067218934', 'GCT-2020-00423', 
        'CT-2020-A', '17', '2020-08-12', '15:30',
        N'Bệnh viện Bạch Mai', 1008, 107, 1,
        N'Suy tim cấp', N'Lê Văn Tùng', '001062415789', 
        N'Chồng', '2020-08-13', 201,
        'TTBN-2020-423', 1, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BTP].[DeathCertificate] OFF;
GO

--------------------------------------------------------------------------------
-- 3. BTP.MarriageCertificate (Marriage certificates)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.MarriageCertificate...';

SET IDENTITY_INSERT [BTP].[MarriageCertificate] ON;
INSERT INTO [BTP].[MarriageCertificate] (
    [marriage_certificate_id], [marriage_certificate_no], [book_id], [page_no],
    [husband_id], [husband_full_name], [husband_date_of_birth], 
    [husband_nationality_id], [husband_previous_marital_status_id],
    [wife_id], [wife_full_name], [wife_date_of_birth], 
    [wife_nationality_id], [wife_previous_marital_status_id],
    [marriage_date], [registration_date], [issuing_authority_id], 
    [issuing_place], [status], [created_at], [updated_at]
) VALUES
    -- Family 1
    (1, 'GCN-KH-2003-00156', 'KH-2003-A', '12',
        '001089123456', N'Nguyễn Văn Minh', '1975-05-10', 
        1, 1, -- Vietnamese, previously single
        '001091345612', N'Nguyễn Thị Hương', '1979-08-15', 
        1, 1, -- Vietnamese, previously single
        '2003-06-15', '2003-06-20', 201, 
        N'UBND Phường Phúc Xá, Quận Ba Đình, Hà Nội', 1, GETDATE(), GETDATE()),
        
    -- Family 2
    (2, 'GCN-KH-1997-00087', 'KH-1997-A', '34',
        '001074853214', N'Trần Đình Phúc', '1968-11-22', 
        1, 1, -- Vietnamese, previously single
        '001076831495', N'Trần Thị Lan', '1972-04-18', 
        1, 1, -- Vietnamese, previously single
        '1997-10-10', '1997-10-15', 201, 
        N'UBND Phường Thành Công, Quận Ba Đình, Hà Nội', 1, GETDATE(), GETDATE()),
        
    -- Family 3 (older couple, one deceased)
    (3, 'GCN-KH-1970-00023', 'KH-1970-A', '8',
        '001062415789', N'Lê Văn Tùng', '1950-02-15', 
        1, 1, -- Vietnamese, previously single
        '001067218934', N'Lê Thị Hiền', '1948-09-30', 
        1, 1, -- Vietnamese, previously single
        '1970-05-20', '1970-05-25', 201, 
        N'UBND Phường Trúc Bạch, Quận Ba Đình, Hà Nội', 1, GETDATE(), GETDATE()),
        
    -- Couple from different cities
    (4, 'GCN-KH-2021-01254', 'KH-2021-B', '43',
        '045198745632', N'Hoàng Minh Tuấn', '1990-12-01', 
        1, 1, -- Vietnamese, previously single
        '001293156482', N'Hoàng Thị Thu Nga', '1992-05-15', 
        1, 1, -- Vietnamese, previously single
        '2021-09-15', '2021-09-20', 201, 
        N'UBND Quận Cầu Giấy, Hà Nội', 1, GETDATE(), GETDATE()),
        
    -- Divorced couple
    (5, 'GCN-KH-2010-00789', 'KH-2010-A', '54',
        '001187654321', N'Lê Văn Hùng', '1978-06-20', 
        1, 1, -- Vietnamese, previously single
        '001196325874', N'Phạm Thị Thảo', '1985-11-11', 
        1, 1, -- Vietnamese, previously single
        '2010-11-20', '2010-11-25', 201, 
        N'UBND Quận Hai Bà Trưng, Hà Nội', 0, GETDATE(), GETDATE()); -- status 0 = dissolved
SET IDENTITY_INSERT [BTP].[MarriageCertificate] OFF;
GO

--------------------------------------------------------------------------------
-- 4. BTP.DivorceRecord (Divorce records)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.DivorceRecord...';

SET IDENTITY_INSERT [BTP].[DivorceRecord] ON;
INSERT INTO [BTP].[DivorceRecord] (
    [divorce_record_id], [divorce_certificate_no], [book_id], [page_no],
    [marriage_certificate_id], [divorce_date], [registration_date],
    [court_name], [judgment_no], [judgment_date], [issuing_authority_id],
    [reason], [child_custody], [property_division], 
    [status], [notes], [created_at], [updated_at]
) VALUES
    (1, 'GCN-LH-2015-00042', 'LH-2015-A', '12',
        5, '2015-03-15', '2015-03-20',
        N'Tòa án nhân dân quận Hai Bà Trưng', 'QĐTA-2015-078', '2015-03-10', 201,
        N'Không thể hòa hợp trong cuộc sống hôn nhân', NULL, N'Tài sản đã được phân chia theo thỏa thuận', 
        1, NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BTP].[DivorceRecord] OFF;
GO

--------------------------------------------------------------------------------
-- 5. BTP.Household (Household registration)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.Household...';

SET IDENTITY_INSERT [BTP].[Household] ON;
INSERT INTO [BTP].[Household] (
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
SET IDENTITY_INSERT [BTP].[Household] OFF;
GO

--------------------------------------------------------------------------------
-- 6. BTP.HouseholdMember (Household members)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.HouseholdMember...';

SET IDENTITY_INSERT [BTP].[HouseholdMember] ON;
INSERT INTO [BTP].[HouseholdMember] (
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
SET IDENTITY_INSERT [BTP].[HouseholdMember] OFF;
GO

--------------------------------------------------------------------------------
-- 7. BTP.FamilyRelationship (Family relationships)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.FamilyRelationship...';

SET IDENTITY_INSERT [BTP].[FamilyRelationship] ON;
INSERT INTO [BTP].[FamilyRelationship] (
    [relationship_id], [citizen_id], [related_citizen_id], 
    [relationship_type_id], [start_date], [end_date],
    [family_rel_status_id], [document_proof], [document_no],
    [notes], [created_at], [updated_at]
) VALUES
    -- Family 1 relationships
    (1, '001089123456', '001091345612', 
        5, '2003-06-15', NULL, -- Husband-Wife relationship
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-2003-00156',
        NULL, GETDATE(), GETDATE()),
        
    (2, '001091345612', '001089123456', 
        4, '2003-06-15', NULL, -- Wife-Husband relationship
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-2003-00156',
        NULL, GETDATE(), GETDATE()),
        
    (3, '001089123456', '001299876543', 
        1, '2005-03-20', NULL, -- Father-Son relationship
        1, N'Giấy khai sinh', 'GKS-2005-00015',
        NULL, GETDATE(), GETDATE()),
        
    (4, '001299876543', '001089123456', 
        3, '2005-03-20', NULL, -- Son-Father relationship
        1, N'Giấy khai sinh', 'GKS-2005-00015',
        NULL, GETDATE(), GETDATE()),
        
    (5, '001091345612', '001299876543', 
        2, '2005-03-20', NULL, -- Mother-Son relationship
        1, N'Giấy khai sinh', 'GKS-2005-00015',
        NULL, GETDATE(), GETDATE()),
        
    (6, '001299876543', '001091345612', 
        3, '2005-03-20', NULL, -- Son-Mother relationship
        1, N'Giấy khai sinh', 'GKS-2005-00015',
        NULL, GETDATE(), GETDATE()),
        
    (7, '001089123456', '001209861234', 
        1, '2010-12-05', NULL, -- Father-Daughter relationship
        1, N'Giấy khai sinh', 'GKS-2010-02187',
        NULL, GETDATE(), GETDATE()),
        
    (8, '001209861234', '001089123456', 
        3, '2010-12-05', NULL, -- Daughter-Father relationship
        1, N'Giấy khai sinh', 'GKS-2010-02187',
        NULL, GETDATE(), GETDATE()),
        
    (9, '001091345612', '001209861234', 
        2, '2010-12-05', NULL, -- Mother-Daughter relationship
        1, N'Giấy khai sinh', 'GKS-2010-02187',
        NULL, GETDATE(), GETDATE()),
        
    (10, '001209861234', '001091345612', 
        3, '2010-12-05', NULL, -- Daughter-Mother relationship
        1, N'Giấy khai sinh', 'GKS-2010-02187',
        NULL, GETDATE(), GETDATE()),
        
    (11, '001299876543', '001209861234', 
        6, '2010-12-05', NULL, -- Brother-Sister relationship
        1, NULL, NULL,
        NULL, GETDATE(), GETDATE()),
        
    (12, '001209861234', '001299876543', 
        8, '2010-12-05', NULL, -- Sister-Brother relationship
        1, NULL, NULL,
        NULL, GETDATE(), GETDATE()),
        
    -- Family 2 relationships
    (13, '001074853214', '001076831495', 
        5, '1997-10-10', NULL, -- Husband-Wife relationship
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-1997-00087',
        NULL, GETDATE(), GETDATE()),
        
    (14, '001076831495', '001074853214', 
        4, '1997-10-10', NULL, -- Wife-Husband relationship
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-1997-00087',
        NULL, GETDATE(), GETDATE()),
        
    (15, '001074853214', '001201786523', 
        1, '2000-07-07', NULL, -- Father-Son relationship
        1, N'Giấy khai sinh', 'GKS-2000-01243',
        NULL, GETDATE(), GETDATE()),
        
    (16, '001201786523', '001074853214', 
        3, '2000-07-07', NULL, -- Son-Father relationship
        1, N'Giấy khai sinh', 'GKS-2000-01243',
        NULL, GETDATE(), GETDATE()),
        
    (17, '001076831495', '001201786523', 
        2, '2000-07-07', NULL, -- Mother-Son relationship
        1, N'Giấy khai sinh', 'GKS-2000-01243',
        NULL, GETDATE(), GETDATE()),
        
    (18, '001201786523', '001076831495', 
        3, '2000-07-07', NULL, -- Son-Mother relationship
        1, N'Giấy khai sinh', 'GKS-2000-01243',
        NULL, GETDATE(), GETDATE()),
        
    -- Family 3 relationships
    (19, '001062415789', '001067218934', 
        5, '1970-05-20', '2020-08-12', -- Husband-Wife relationship (wife deceased)
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-1970-00023',
        NULL, GETDATE(), GETDATE()),
        
    (20, '001067218934', '001062415789', 
        4, '1970-05-20', '2020-08-12', -- Wife-Husband relationship (wife deceased)
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-1970-00023',
        NULL, GETDATE(), GETDATE()),
        
    (21, '001062415789', '001187654321', 
        1, '1978-06-20', NULL, -- Father-Son relationship
        1, N'Giấy khai sinh', 'GKS-1978-00785',
        NULL, GETDATE(), GETDATE()),
        
    (22, '001187654321', '001062415789', 
        3, '1978-06-20', NULL, -- Son-Father relationship
        1, N'Giấy khai sinh', 'GKS-1978-00785',
        NULL, GETDATE(), GETDATE()),
        
    (23, '001067218934', '001187654321', 
        2, '1978-06-20', '2020-08-12', -- Mother-Son relationship (mother deceased)
        1, N'Giấy khai sinh', 'GKS-1978-00785',
        NULL, GETDATE(), GETDATE()),
        
    (24, '001187654321', '001067218934', 
        3, '1978-06-20', '2020-08-12', -- Son-Mother relationship (mother deceased)
        1, N'Giấy khai sinh', 'GKS-1978-00785',
        NULL, GETDATE(), GETDATE()),
        
    -- Divorced couple relationship
    (25, '001187654321', '001196325874', 
        5, '2010-11-20', '2015-03-15', -- Husband-Wife relationship (divorced)
        2, N'Giấy chứng nhận kết hôn', 'GCN-KH-2010-00789',
        NULL, GETDATE(), GETDATE()),
        
    (26, '001196325874', '001187654321', 
        4, '2010-11-20', '2015-03-15', -- Wife-Husband relationship (divorced)
        2, N'Giấy chứng nhận kết hôn', 'GCN-KH-2010-00789',
        NULL, GETDATE(), GETDATE()),
        
    -- Couple from different cities
    (27, '045198745632', '001293156482', 
        5, '2021-09-15', NULL, -- Husband-Wife relationship
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-2021-01254',
        NULL, GETDATE(), GETDATE()),
        
    (28, '001293156482', '045198745632', 
        4, '2021-09-15', NULL, -- Wife-Husband relationship
        1, N'Giấy chứng nhận kết hôn', 'GCN-KH-2021-01254',
        NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BTP].[FamilyRelationship] OFF;
GO

--------------------------------------------------------------------------------
-- 8. BTP.PopulationChange (Population/civil status changes)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.PopulationChange...';

SET IDENTITY_INSERT [BTP].[PopulationChange] ON;
INSERT INTO [BTP].[PopulationChange] (
    [change_id], [citizen_id], [pop_change_type_id], 
    [change_date], [source_location_id], [destination_location_id],
    [reason], [related_document_no], [processing_authority_id], 
    [status], [notes], [created_at], [updated_at]
) VALUES
    -- Birth registrations
    (1, '001299876543', 1, -- Birth registration
        '2005-03-25', NULL, 1001, -- Birth in Ward 1001 (Phúc Xá)
        N'Đăng ký khai sinh', 'GKS-2005-00015', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (2, '001209861234', 1, -- Birth registration
        '2010-12-10', NULL, 1001, -- Birth in Ward 1001 (Phúc Xá)
        N'Đăng ký khai sinh', 'GKS-2010-02187', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (3, '001201786523', 1, -- Birth registration
        '2000-07-12', NULL, 1010, -- Birth in Ward 1010 (Thành Công)
        N'Đăng ký khai sinh', 'GKS-2000-01243', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (4, '001187654321', 1, -- Birth registration
        '1978-06-25', NULL, 1002, -- Birth in Ward 1002 (Trúc Bạch)
        N'Đăng ký khai sinh', 'GKS-1978-00785', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    -- Death registration
    (5, '001067218934', 2, -- Death registration
        '2020-08-13', 1002, NULL, -- Death in Ward 1002 (Trúc Bạch)
        N'Đăng ký khai tử', 'GCT-2020-00423', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    -- Marriage registrations
    (6, '001089123456', 3, -- Marriage registration
        '2003-06-20', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-2003-00156', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (7, '001091345612', 3, -- Marriage registration
        '2003-06-20', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-2003-00156', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (8, '001074853214', 3, -- Marriage registration
        '1997-10-15', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-1997-00087', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (9, '001076831495', 3, -- Marriage registration
        '1997-10-15', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-1997-00087', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (10, '001062415789', 3, -- Marriage registration
        '1970-05-25', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-1970-00023', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (11, '001067218934', 3, -- Marriage registration
        '1970-05-25', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-1970-00023', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (12, '001187654321', 3, -- Marriage registration
        '2010-11-25', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-2010-00789', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (13, '001196325874', 3, -- Marriage registration
        '2010-11-25', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-2010-00789', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (14, '045198745632', 3, -- Marriage registration
        '2021-09-20', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-2021-01254', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (15, '001293156482', 3, -- Marriage registration
        '2021-09-20', NULL, NULL,
        N'Đăng ký kết hôn', 'GCN-KH-2021-01254', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    -- Divorce registration
    (16, '001187654321', 4, -- Divorce registration
        '2015-03-20', NULL, NULL,
        N'Đăng ký ly hôn', 'GCN-LH-2015-00042', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    (17, '001196325874', 4, -- Divorce registration
        '2015-03-20', NULL, NULL,
        N'Đăng ký ly hôn', 'GCN-LH-2015-00042', 201, 
        1, NULL, GETDATE(), GETDATE()),
        
    -- Household registration changes
    (18, '001187654321', 7, -- Household separation
        '2018-05-15', 1002, 1008, -- From Ward 1002 (Trúc Bạch) to Ward 1008 (Ngọc Khánh)
        N'Tách hộ', 'HK-2018-01234', 401, 
        1, NULL, GETDATE(), GETDATE()),
        
    (19, '045198745632', 6, -- Household transfer
        '2022-01-20', 45, 1, -- From HCM City to Hanoi
        N'Chuyển hộ khẩu', 'HK-2022-00789', 401, 
        1, NULL, GETDATE(), GETDATE()),
        
    (20, '001293156482', 8, -- Household addition
        '2022-01-20', NULL, NULL,
        N'Nhập vào hộ khẩu mới', 'HK-2022-00789', 401, 
        1, NULL, GETDATE(), GETDATE());
SET IDENTITY_INSERT [BTP].[PopulationChange] OFF;
GO

--------------------------------------------------------------------------------
-- 9. BTP.EventOutbox (Event notifications)
--------------------------------------------------------------------------------
PRINT N'  Adding sample data to BTP.EventOutbox...';

SET IDENTITY_INSERT [BTP].[EventOutbox] ON;
INSERT INTO [BTP].[EventOutbox] (
    [outbox_id], [aggregate_type], [aggregate_id], [event_type], 
    [payload], [created_at], [processed], [processed_at], [retry_count]
) VALUES
    (1, 'DeathCertificate', '1', 'CitizenDied',
        N'{"citizen_id":"001067218934","death_certificate_id":1,"death_date":"2020-08-12","death_certificate_no":"GCT-2020-00423"}',
        '2020-08-13 15:45:22', 1, '2020-08-13 15:46:05', 0),
        
    (2, 'MarriageCertificate', '4', 'CitizenMarried',
        N'{"marriage_certificate_id":4,"husband_id":"045198745632","wife_id":"001293156482","marriage_date":"2021-09-15","registration_date":"2021-09-20"}',
        '2021-09-20 11:32:18', 1, '2021-09-20 11:33:01', 0),
        
    (3, 'DivorceRecord', '1', 'CitizenDivorced',
        N'{"divorce_record_id":1,"marriage_certificate_id":5,"husband_id":"001187654321","wife_id":"001196325874","divorce_date":"2015-03-15","registration_date":"2015-03-20"}',
        '2015-03-20 13:15:42', 1, '2015-03-20 13:16:20', 0),
        
    (4, 'BirthCertificate', '1', 'CitizenBirthRegistered',
        N'{"citizen_id":"001299876543","birth_certificate_id":1,"birth_date":"2005-03-20","father_id":"001089123456","mother_id":"001091345612"}',
        '2005-03-25 09:25:31', 1, '2005-03-25 09:26:10', 0);
SET IDENTITY_INSERT [BTP].[EventOutbox] OFF;
GO

PRINT N'Sample data has been added to BTP schema tables successfully.';
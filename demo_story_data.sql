-- =============================================================================
-- == SCRIPT DỮ LIỆU MẪU CHO KỊCH BẢN DEMO "VÒNG ĐỜI CÔNG DÂN" ==
-- =============================================================================
-- Hướng dẫn: Chạy script này SAU KHI đã chạy các script sample_data khác.
-- Mục đích: Tạo ra các nhân vật và trạng thái ban đầu cho câu chuyện demo,
--          bao gồm cả các trường hợp thành công và thất bại.
-- =============================================================================


-- =============================================================================
-- == PHẦN 1: DỮ LIỆU CHO CSDL BỘ CÔNG AN (DB_BCA) ==
-- =============================================================================
USE [DB_BCA];
GO

PRINT N'Bắt đầu thêm dữ liệu cho kịch bản demo vào DB_BCA...';

--------------------------------------------------------------------------------
-- 1. Thêm địa chỉ mới cho các nhân vật trong câu chuyện
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu vào BCA.Address cho các nhân vật demo...';
SET IDENTITY_INSERT [BCA].[Address] ON;
INSERT INTO [BCA].[Address] 
    ([address_id], [address_detail], [ward_id], [district_id], [province_id], [postal_code], [status])
VALUES 
    (21, N'Số 123, Đường Láng', 106, 106, 1, '100000', 1), -- Địa chỉ nhà Bùi Tiến Dũng
    (22, N'Số 45, Phố Chùa Bộc', 106, 106, 1, '100000', 1), -- Địa chỉ nhà Vũ Mai Phương
    (23, N'Chung cư Royal City, 72A Nguyễn Trãi', 109, 109, 1, '100000', 1); -- Địa chỉ nhà Lê Thu Thảo & chồng
SET IDENTITY_INSERT [BCA].[Address] OFF;
GO

--------------------------------------------------------------------------------
-- 2. Tạo các nhân vật cho câu chuyện
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu vào BCA.Citizen cho các nhân vật demo...';
INSERT INTO [BCA].[Citizen] (
    [citizen_id], [full_name], [date_of_birth], [gender_id], 
    [birth_province_id], [native_province_id], [primary_address_id], 
    [nationality_id], [ethnicity_id], [religion_id],
    [marital_status_id], [education_level_id], [occupation_id],
    [spouse_citizen_id], [citizen_status_id]
) VALUES
-- Nhân vật chính
    ('001199011122', N'Bùi Tiến Dũng', '1999-01-15', 1, 1, 1, 21, 1, 1, 1, 
        1, 7, 18, -- 1: Độc thân, 7: Đại học, 18: Lập trình viên
        NULL, 1), -- 1: Còn sống

    ('001201022233', N'Vũ Mai Phương', '2001-02-20', 2, 1, 1, 22, 1, 1, 1, 
        1, 7, 7, -- 1: Độc thân, 7: Đại học, 7: Nhân viên văn phòng
        NULL, 1),

-- "Chướng ngại vật" cho kịch bản thất bại
    ('001198033344', N'Lê Thu Thảo', '1998-03-25', 2, 1, 1, 23, 1, 1, 1,
        2, 7, 8, -- 2: Đã kết hôn
        '001197044455', 1),

    ('001197044455', N'Đỗ Gia Bảo', '1997-04-30', 1, 1, 1, 23, 1, 1, 1,
        2, 7, 8, -- 2: Đã kết hôn
        '001198033344', 1);
GO

--------------------------------------------------------------------------------
-- 3. Cấp thẻ CCCD cho các nhân vật mới
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu vào BCA.IdentificationCard...';
SET IDENTITY_INSERT [BCA].[IdentificationCard] ON;
INSERT INTO [BCA].[IdentificationCard] (
    [id_card_id], [citizen_id], [card_number], [card_type_id], 
    [issue_date], [expiry_date], [issuing_authority_id], [card_status_id]
) VALUES
    (21, '001199011122', '001199011122', 3, '2023-01-15', '2038-01-15', 101, 1),
    (22, '001201022233', '001201022233', 3, '2023-02-20', '2038-02-20', 101, 1),
    (23, '001198033344', '001198033344', 3, '2022-03-25', '2037-03-25', 101, 1),
    (24, '001197044455', '001197044455', 3, '2021-04-30', '2036-04-30', 101, 1);
SET IDENTITY_INSERT [BCA].[IdentificationCard] OFF;
GO

--------------------------------------------------------------------------------
-- 4. Tạo hộ khẩu ban đầu cho các nhân vật
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu vào BCA.Household...';
SET IDENTITY_INSERT [BCA].[Household] ON;
INSERT INTO [BCA].[Household] (
    [household_id], [household_book_no], [head_of_household_id], 
    [address_id], [registration_date], [issuing_authority_id],
    [household_type_id], [household_status_id]
) VALUES
    (11, 'HK-DEMO-DUNG-001', '001199011122', 21, '2022-01-01', 401, 4, 1), -- Hộ cá nhân cho Dũng
    (12, 'HK-DEMO-PHUONG-002', '001201022233', 22, '2022-01-01', 401, 4, 1), -- Hộ cá nhân cho Phương
    (13, 'HK-DEMO-THAO-003', '001197044455', 23, '2020-05-05', 401, 1, 1); -- Hộ gia đình cho Thảo và Bảo
SET IDENTITY_INSERT [BCA].[Household] OFF;
GO

PRINT N'  Thêm dữ liệu vào BCA.HouseholdMember...';
SET IDENTITY_INSERT [BCA].[HouseholdMember] ON;
INSERT INTO [BCA].[HouseholdMember] (
    [household_member_id], [household_id], [citizen_id], [rel_with_head_id], [join_date], [member_status_id]
) VALUES
    -- Hộ của Dũng
    (21, 11, '001199011122', 1, '2022-01-01', 1), -- Dũng là chủ hộ
    -- Hộ của Phương
    (22, 12, '001201022233', 1, '2022-01-01', 1), -- Phương là chủ hộ
    -- Hộ của Thảo và Bảo
    (23, 13, '001197044455', 1, '2020-05-05', 1), -- Bảo là chủ hộ
    (24, 13, '001198033344', 2, '2020-05-05', 1); -- Thảo là vợ
SET IDENTITY_INSERT [BCA].[HouseholdMember] OFF;
GO

PRINT N'Hoàn tất thêm dữ liệu demo vào DB_BCA.';
GO

-- =============================================================================
-- == PHẦN 2: DỮ LIỆU CHO CSDL BỘ TƯ PHÁP (DB_BTP) ==
-- =============================================================================
USE [DB_BTP];
GO

PRINT N'Bắt đầu thêm dữ liệu cho kịch bản demo vào DB_BTP...';

--------------------------------------------------------------------------------
-- 1. Thêm Giấy kết hôn đã tồn tại cho cặp đôi "chướng ngại vật"
--    Đây là dữ liệu MẤU CHỐT để demo kịch bản đăng ký kết hôn thất bại.
--------------------------------------------------------------------------------
PRINT N'  Thêm dữ liệu vào BTP.MarriageCertificate...';

SET IDENTITY_INSERT [BTP].[MarriageCertificate] ON;
INSERT INTO [BTP].[MarriageCertificate] (
    [marriage_certificate_id], [marriage_certificate_no], [book_id],
    [husband_id], [husband_full_name], [husband_date_of_birth], [husband_nationality_id], [husband_previous_marital_status_id],
    [wife_id], [wife_full_name], [wife_date_of_birth], [wife_nationality_id], [wife_previous_marital_status_id],
    [marriage_date], [registration_date], [issuing_authority_id], [issuing_place], [status]
) VALUES
    (101, 'GCN-KH-DEMO-001', 'KH-2020-DEMO',
    '001197044455', N'Đỗ Gia Bảo', '1997-04-30', 1, 1,
    '001198033344', N'Lê Thu Thảo', '1998-03-25', 1, 1,
    '2020-04-20', '2020-04-22', 303, N'UBND quận Cầu Giấy, Hà Nội', 1);
SET IDENTITY_INSERT [BTP].[MarriageCertificate] OFF;
GO

-- Giả sử BTP cũng có bảng FamilyRelationship để ghi lại quan hệ pháp lý
-- Nếu cấu trúc CSDL của bạn khác, bạn có thể điều chỉnh hoặc bỏ qua phần này.
PRINT N'  Thêm dữ liệu vào BTP.FamilyRelationship...';
SET IDENTITY_INSERT [BTP].[FamilyRelationship] ON;
INSERT INTO [BTP].[FamilyRelationship] (
    [relationship_id], [citizen_id], [related_citizen_id], 
    [relationship_type_id], [start_date], [family_rel_status_id], [document_proof], [document_no]
) VALUES
    (101, '001197044455', '001198033344', 5, '2020-04-20', 1, N'Giấy chứng nhận kết hôn', 'GCN-KH-DEMO-001'), -- Chồng -> Vợ
    (102, '001198033344', '001197044455', 4, '2020-04-20', 1, N'Giấy chứng nhận kết hôn', 'GCN-KH-DEMO-001'); -- Vợ -> Chồng
SET IDENTITY_INSERT [BTP].[FamilyRelationship] OFF;
GO


PRINT N'Hoàn tất thêm dữ liệu demo vào DB_BTP.';
GO

PRINT N'TOÀN BỘ DỮ LIỆU CHO KỊCH BẢN DEMO ĐÃ SẴN SÀNG!';
GO 
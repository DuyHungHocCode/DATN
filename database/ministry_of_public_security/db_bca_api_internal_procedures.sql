USE [DB_BCA];
GO

-- Drop the function if it already exists
IF OBJECT_ID('[API_Internal].[GetCitizenDetails]', 'IF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetCitizenDetails];
GO

-- Create the Inline Table-Valued Function (iTVF) to get citizen details
CREATE FUNCTION [API_Internal].[GetCitizenDetails] (
    @citizen_id VARCHAR(12) -- Input: Citizen ID (CCCD)
)
RETURNS TABLE
AS
RETURN
(
    -- Select detailed citizen information by joining with reference tables
    SELECT
        -- Core Citizen Info
        c.[citizen_id],
        c.[full_name],
        c.[date_of_birth],
        c.[gender],

        -- Birth Place Info
        c.[birth_ward_id],
        bw.[ward_name] AS birth_ward_name,
        c.[birth_district_id],
        bd.[district_name] AS birth_district_name,
        c.[birth_province_id],
        bp.[province_name] AS birth_province_name,
        c.[birth_country_id],
        bc.[nationality_name] AS birth_country_name,
        c.[place_of_birth_code], -- Added from revised structure
        c.[place_of_birth_detail], -- Added from revised structure

        -- Native Place Info
        c.[native_ward_id],
        nw.[ward_name] AS native_ward_name,
        c.[native_district_id],
        nd.[district_name] AS native_district_name,
        c.[native_province_id],
        np.[province_name] AS native_province_name,

        -- Demographic Info
        c.[nationality_id],
        nat.[nationality_name],
        c.[ethnicity_id],
        eth.[ethnicity_name],
        c.[religion_id],
        rel.[religion_name],
        c.[blood_type], -- Added from revised structure

        -- Social/Economic Info
        c.[marital_status],
        c.[education_level],
        c.[occupation_id],
        occ.[occupation_name],
        c.[tax_code], -- Added from revised structure
        c.[social_insurance_no], -- Added from revised structure
        c.[health_insurance_no], -- Added from revised structure

        -- Current Address Info
        c.[current_address_detail],
        c.[current_ward_id],
        cw.[ward_name] AS current_ward_name,
        c.[current_district_id],
        cd.[district_name] AS current_district_name,
        c.[current_province_id],
        cp.[province_name] AS current_province_name,

        -- Family Info
        c.[father_citizen_id],
        c.[mother_citizen_id],
        c.[spouse_citizen_id],
        c.[representative_citizen_id],

        -- Status Info
        c.[death_status],
        c.[date_of_death],

        -- Contact Info
        c.[phone_number],
        c.[email],

        -- Metadata
        c.[created_at],
        c.[updated_at],
        c.[created_by], -- Added from revised structure
        c.[updated_by]  -- Added from revised structure

    FROM [BCA].[Citizen] c
    -- Joins for Birth Place
    LEFT JOIN [Reference].[Wards] bw ON c.birth_ward_id = bw.ward_id
    LEFT JOIN [Reference].[Districts] bd ON c.birth_district_id = bd.district_id
    LEFT JOIN [Reference].[Provinces] bp ON c.birth_province_id = bp.province_id
    LEFT JOIN [Reference].[Nationalities] bc ON c.birth_country_id = bc.nationality_id
    -- Joins for Native Place
    LEFT JOIN [Reference].[Wards] nw ON c.native_ward_id = nw.ward_id
    LEFT JOIN [Reference].[Districts] nd ON c.native_district_id = nd.district_id
    LEFT JOIN [Reference].[Provinces] np ON c.native_province_id = np.province_id
    -- Joins for Demographic Info
    LEFT JOIN [Reference].[Nationalities] nat ON c.nationality_id = nat.nationality_id
    LEFT JOIN [Reference].[Ethnicities] eth ON c.ethnicity_id = eth.ethnicity_id
    LEFT JOIN [Reference].[Religions] rel ON c.religion_id = rel.religion_id
    -- Join for Occupation
    LEFT JOIN [Reference].[Occupations] occ ON c.occupation_id = occ.occupation_id
    -- Joins for Current Address
    LEFT JOIN [Reference].[Wards] cw ON c.current_ward_id = cw.ward_id
    LEFT JOIN [Reference].[Districts] cd ON c.current_district_id = cd.district_id
    LEFT JOIN [Reference].[Provinces] cp ON c.current_province_id = cp.province_id
    -- Filter by the input citizen_id
    WHERE c.[citizen_id] = @citizen_id
);
GO

--====================================================================================

-- Drop the function if it already exists
IF OBJECT_ID('[API_Internal].[GetResidenceHistory]', 'IF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetResidenceHistory];
GO

-- Create the Inline Table-Valued Function (iTVF) to get comprehensive residence history
CREATE FUNCTION [API_Internal].[GetResidenceHistory] (
    @citizen_id VARCHAR(12) -- Input: Citizen ID (CCCD)
)
RETURNS TABLE
AS
RETURN
(
    -- Combine results from multiple queries using UNION ALL
    
    -- 1. Permanent and Temporary Residence History
    SELECT
        'ResidenceHistory' AS record_type,
        rh.[residence_type], -- 'Thường trú' or 'Tạm trú'
        rh.[residence_history_id] AS record_id,
        a.[address_detail],
        w.[ward_name],
        d.[district_name],
        p.[province_name],
        NULL AS destination_detail, -- Only for temporary absence
        rh.[registration_date] AS start_date,
        rh.[expiry_date] AS end_date,
        CASE 
            WHEN rh.[status] = 'Active' AND rh.[residence_type] = N'Thường trú' THEN 1
            ELSE 0
        END AS is_current_permanent_residence,
        CASE 
            WHEN rh.[status] = 'Active' AND rh.[residence_type] = N'Tạm trú' THEN 1
            ELSE 0
        END AS is_current_temporary_residence,
        0 AS is_temporary_absence,
        0 AS is_current_address,
        0 AS is_accommodation,
        rh.[registration_reason] AS reason,
        CASE
            WHEN rh.[status] = 'Moved' OR rh.[status] = 'Cancelled' THEN rh.[updated_at]
            WHEN rh.[status] = 'Expired' THEN rh.[expiry_date]
            ELSE NULL
        END AS deregistration_date,
        rh.[status] AS record_status,
        rh.[host_name],
        rh.[host_citizen_id],
        rh.[host_relationship],
        auth.[authority_name] AS issuing_authority,
        rh.[verification_status],
        rh.[notes],
        rh.[created_at],
        rh.[updated_at]
    FROM [BCA].[ResidenceHistory] rh
    INNER JOIN [BCA].[Address] a ON rh.address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN [Reference].[Authorities] auth ON rh.issuing_authority_id = auth.authority_id
    WHERE rh.[citizen_id] = @citizen_id
    
    UNION ALL
    
    -- 2. Temporary Absence Records
    SELECT
        'TemporaryAbsence' AS record_type,
        N'Tạm vắng' AS residence_type,
        ta.[temporary_absence_id] AS record_id,
        CASE 
            WHEN a.address_id IS NOT NULL THEN a.address_detail 
            ELSE NULL 
        END AS address_detail,
        CASE 
            WHEN a.address_id IS NOT NULL THEN w.ward_name 
            ELSE NULL 
        END AS ward_name,
        CASE 
            WHEN a.address_id IS NOT NULL THEN d.district_name 
            ELSE NULL 
        END AS district_name,
        CASE 
            WHEN a.address_id IS NOT NULL THEN p.province_name 
            ELSE NULL 
        END AS province_name,
        ta.[destination_detail],
        ta.[from_date] AS start_date,
        ta.[to_date] AS end_date,
        0 AS is_current_permanent_residence,
        0 AS is_current_temporary_residence,
        1 AS is_temporary_absence,
        0 AS is_current_address,
        0 AS is_accommodation,
        ta.[reason],
        ta.[return_date] AS deregistration_date,
        ta.[status] AS record_status,
        NULL AS host_name,
        NULL AS host_citizen_id,
        NULL AS host_relationship,
        auth.[authority_name] AS issuing_authority,
        ta.[verification_status],
        ta.[notes],
        ta.[created_at],
        ta.[updated_at]
    FROM [BCA].[TemporaryAbsence] ta
    LEFT JOIN [BCA].[Address] a ON ta.destination_address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN [Reference].[Authorities] auth ON ta.registration_authority_id = auth.authority_id
    WHERE ta.[citizen_id] = @citizen_id
    
    UNION ALL
    
    -- 3. Current Residence and Other Address Types (from CitizenAddress)
    SELECT
        'CitizenAddress' AS record_type,
        ca.[address_type] AS residence_type,
        ca.[citizen_address_id] AS record_id,
        a.[address_detail],
        w.[ward_name],
        d.[district_name],
        p.[province_name],
        NULL AS destination_detail,
        ca.[from_date] AS start_date,
        ca.[to_date] AS end_date,
        0 AS is_current_permanent_residence,
        0 AS is_current_temporary_residence,
        0 AS is_temporary_absence,
        CASE 
            WHEN ca.[address_type] = N'Nơi ở hiện tại' AND ca.[status] = 1 THEN 1
            ELSE 0
        END AS is_current_address,
        CASE 
            WHEN ca.[address_type] = N'Khác' AND ca.[status] = 1 THEN 1
            ELSE 0
        END AS is_accommodation,
        NULL AS reason,
        CASE
            WHEN ca.[status] = 0 THEN ca.[updated_at]
            WHEN ca.[to_date] IS NOT NULL THEN ca.[to_date]
            ELSE NULL
        END AS deregistration_date,
        CASE 
            WHEN ca.[status] = 1 THEN 'Active' 
            ELSE 'Inactive' 
        END AS record_status,
        NULL AS host_name,
        NULL AS host_citizen_id,
        NULL AS host_relationship,
        auth.[authority_name] AS issuing_authority,
        ca.[verification_status],
        ca.[notes],
        ca.[created_at],
        ca.[updated_at]
    FROM [BCA].[CitizenAddress] ca
    INNER JOIN [BCA].[Address] a ON ca.address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN [Reference].[Authorities] auth ON ca.issuing_authority_id = auth.authority_id
    WHERE ca.[citizen_id] = @citizen_id
)
GO

-- Create a complementary function to get citizen contact information
IF OBJECT_ID('[API_Internal].[GetCitizenContactInfo]', 'IF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetCitizenContactInfo];
GO

CREATE FUNCTION [API_Internal].[GetCitizenContactInfo] (
    @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        c.[citizen_id],
        c.[phone_number],
        c.[email],
        c.[full_name],
        c.[current_address_detail],
        w.[ward_name] AS current_ward_name,
        d.[district_name] AS current_district_name,
        p.[province_name] AS current_province_name
    FROM [BCA].[Citizen] c
    LEFT JOIN [Reference].[Wards] w ON c.current_ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON c.current_district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON c.current_province_id = p.province_id
    WHERE c.[citizen_id] = @citizen_id
)
GO

USE [DB_BCA];
GO

-- Kiểm tra và xóa function nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[ValidateCitizenStatus]', 'IF') IS NOT NULL
    DROP FUNCTION [API_Internal].[ValidateCitizenStatus];
GO

-- Tạo Inline Table-Valued Function để xác thực trạng thái công dân
CREATE FUNCTION [API_Internal].[ValidateCitizenStatus] (
    @citizen_id VARCHAR(12) -- Input: Citizen ID (CCCD)
)
RETURNS TABLE
AS
RETURN
(
    -- Chọn citizen_id và death_status từ bảng Citizen
    -- Hàm sẽ trả về một dòng nếu citizen_id tồn tại, và không trả về dòng nào nếu không tồn tại.
    SELECT
        c.[citizen_id],
        c.[death_status] -- Trạng thái: 'Còn sống', 'Đã mất', 'Mất tích'
    FROM
        [BCA].[Citizen] c
    WHERE
        c.[citizen_id] = @citizen_id
);
GO

-- Cấp quyền thực thi cho user/role của API service (ví dụ: api_service_user)
-- Quyền này đã được cấp trên toàn schema API_Internal trong file 01_roles_permission.sql
-- GRANT SELECT ON OBJECT::[API_Internal].[ValidateCitizenStatus] TO [api_service_user]; -- iTVF dùng quyền SELECT
-- GO

PRINT 'Function [API_Internal].[ValidateCitizenStatus] đã được tạo thành công.';


USE [DB_BCA];
GO

USE [DB_BCA];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[UpdateCitizenDeathStatus]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[UpdateCitizenDeathStatus];
GO

-- Tạo Stored Procedure đơn giản hóa để cập nhật trạng thái công dân khi mất
CREATE PROCEDURE [API_Internal].[UpdateCitizenDeathStatus]
    @citizen_id VARCHAR(12),           -- ID CCCD/CMND của công dân
    @date_of_death DATE,               -- Ngày mất
    @updated_by VARCHAR(50) = 'SYSTEM' -- Người/hệ thống cập nhật (mặc định là SYSTEM)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Biến để lưu số dòng bị ảnh hưởng
    DECLARE @affected_rows INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Cập nhật trạng thái công dân thành "Đã mất" và ngày mất
        -- Không cần kiểm tra trạng thái trước đó
        UPDATE [BCA].[Citizen]
        SET [death_status] = N'Đã mất',
            [date_of_death] = @date_of_death,
            [updated_at] = GETDATE(),
            [updated_by] = @updated_by
        WHERE [citizen_id] = @citizen_id;
        
        SET @affected_rows = @@ROWCOUNT;
        
        -- Nếu cập nhật thành công, cập nhật các bảng liên quan
        IF @affected_rows > 0
        BEGIN
            -- 1. Cập nhật tất cả trạng thái hiện tại thành không hiện tại
            UPDATE [BCA].[CitizenStatus]
            SET [is_current] = 0,
                [updated_at] = GETDATE(),
                [updated_by] = @updated_by
            WHERE [citizen_id] = @citizen_id 
            AND [is_current] = 1;
            
            -- 2. Thêm mới trạng thái "Đã mất"
            INSERT INTO [BCA].[CitizenStatus]
            ([citizen_id], [status_type], [status_date], 
             [description], [cause], [is_current], 
             [created_by], [updated_by])
            VALUES
            (@citizen_id, N'Đã mất', @date_of_death, 
             N'Cập nhật từ thông tin khai tử của Bộ Tư pháp', N'Thông báo từ BTP', 1, 
             @updated_by, @updated_by);
             
            -- 3. Thu hồi tất cả thẻ CCCD/CMND đang sử dụng
            UPDATE [BCA].[IdentificationCard]
            SET [card_status] = N'Thu hồi',
                [updated_at] = GETDATE(),
                [updated_by] = @updated_by,
                [notes] = ISNULL([notes] + N' | ', N'') + N'Thu hồi do công dân đã mất ngày ' + 
                          CONVERT(NVARCHAR, @date_of_death, 103)
            WHERE [citizen_id] = @citizen_id
            AND [card_status] = N'Đang sử dụng';
        END
        
        COMMIT TRANSACTION;
        
        -- Trả về số dòng bị ảnh hưởng
        SELECT @affected_rows AS affected_rows;
        
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Ném lại lỗi
        THROW;
    END CATCH
END;
GO

-----------------------------------------------------
-----------------------------------------------------

-- hàm GetCitizenFamilyTree sử dụng CTE đệ quy để lấy thông tin phả hệ 3 đời của công dân
-- Cây phả hệ sẽ bao gồm thông tin về bố, mẹ, ông bà nội, ông bà ngoại, cụ nội, cụ ngoại

-- hàm này sẽ trả về cây gia đình của công dân
USE [DB_BCA];
GO

-- Kiểm tra và xóa function nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[GetCitizenFamilyTree]', 'TF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetCitizenFamilyTree];
GO

-- Tạo Table-Valued Function để lấy thông tin phả hệ 3 đời của công dân sử dụng CTE đệ quy
CREATE FUNCTION [API_Internal].[GetCitizenFamilyTree] (
    @citizen_id VARCHAR(12) -- CCCD/CMND của công dân cần tra cứu
)
RETURNS @FamilyTree TABLE (
    level_id INT,                    -- Cấp bậc trong phả hệ
    relationship_path NVARCHAR(100), -- Đường dẫn quan hệ
    citizen_id VARCHAR(12),          -- ID CCCD/CMND
    full_name NVARCHAR(100),         -- Họ tên đầy đủ
    date_of_birth DATE,              -- Ngày sinh
    gender NVARCHAR(10),             -- Giới tính
    id_card_number VARCHAR(12),      -- Số CCCD/CMND hiện tại
    id_card_type NVARCHAR(20),       -- Loại giấy tờ
    id_card_issue_date DATE,         -- Ngày cấp
    id_card_expiry_date DATE,        -- Ngày hết hạn
    id_card_issuing_authority NVARCHAR(255), -- Nơi cấp
    id_card_status NVARCHAR(20),     -- Trạng thái thẻ
    nationality_name NVARCHAR(100),  -- Quốc tịch
    ethnicity_name NVARCHAR(100),    -- Dân tộc
    religion_name NVARCHAR(100),     -- Tôn giáo
    marital_status NVARCHAR(20)      -- Tình trạng hôn nhân
)
AS
BEGIN
    -- Sử dụng CTE đệ quy để duyệt qua cây phả hệ
    WITH FamilyTreeCTE AS (
        -- Trường hợp cơ sở: công dân gốc (level 1)
        SELECT
            1 AS level_id,
            -- SỬA LỖI: CAST cột relationship_path sang NVARCHAR với độ dài đủ lớn
            CAST(N'Công dân' AS NVARCHAR(100)) AS relationship_path,
            c.citizen_id,
            c.full_name,
            c.date_of_birth,
            c.gender,
            c.father_citizen_id,
            c.mother_citizen_id
        FROM [BCA].[Citizen] c
        WHERE c.citizen_id = @citizen_id

        UNION ALL

        -- Trường hợp đệ quy: tìm bố
        SELECT
            ft.level_id + 1,
            CAST( -- Đảm bảo kết quả CASE cũng là NVARCHAR(100)
                CASE
                    WHEN ft.relationship_path = N'Công dân' THEN N'Bố'
                    WHEN ft.relationship_path = N'Bố' THEN N'Ông Nội (Bố của Bố)'
                    WHEN ft.relationship_path = N'Mẹ' THEN N'Ông Ngoại (Bố của Mẹ)'
                    WHEN ft.relationship_path = N'Ông Nội (Bố của Bố)' THEN N'Cụ Nội (Bố của Ông Nội)'
                    WHEN ft.relationship_path = N'Bà Nội (Mẹ của Bố)' THEN N'Cụ Ông Nội (Bố của Bà Nội)'
                    WHEN ft.relationship_path = N'Ông Ngoại (Bố của Mẹ)' THEN N'Cụ Ngoại (Bố của Ông Ngoại)'
                    WHEN ft.relationship_path = N'Bà Ngoại (Mẹ của Mẹ)' THEN N'Cụ Ông Ngoại (Bố của Bà Ngoại)'
                    ELSE N'Không xác định' -- Thêm một giá trị mặc định nếu cần
                END AS NVARCHAR(100)
            ),
            c.citizen_id,
            c.full_name,
            c.date_of_birth,
            c.gender,
            c.father_citizen_id,
            c.mother_citizen_id
        FROM FamilyTreeCTE ft
        JOIN [BCA].[Citizen] c ON c.citizen_id = ft.father_citizen_id
        WHERE ft.level_id < 3  -- Giới hạn đến 3 đời (level 1, 2, 3)

        UNION ALL

        -- Trường hợp đệ quy: tìm mẹ
        SELECT
            ft.level_id + 1,
            CAST( -- Đảm bảo kết quả CASE cũng là NVARCHAR(100)
                CASE
                    WHEN ft.relationship_path = N'Công dân' THEN N'Mẹ'
                    WHEN ft.relationship_path = N'Bố' THEN N'Bà Nội (Mẹ của Bố)'
                    WHEN ft.relationship_path = N'Mẹ' THEN N'Bà Ngoại (Mẹ của Mẹ)'
                    WHEN ft.relationship_path = N'Ông Nội (Bố của Bố)' THEN N'Cụ Bà Nội (Mẹ của Ông Nội)'
                    WHEN ft.relationship_path = N'Bà Nội (Mẹ của Bố)' THEN N'Cụ Bà Nội (Mẹ của Bà Nội)'
                    WHEN ft.relationship_path = N'Ông Ngoại (Bố của Mẹ)' THEN N'Cụ Bà Ngoại (Mẹ của Ông Ngoại)'
                    WHEN ft.relationship_path = N'Bà Ngoại (Mẹ của Mẹ)' THEN N'Cụ Bà Ngoại (Mẹ của Bà Ngoại)'
                    ELSE N'Không xác định' -- Thêm một giá trị mặc định nếu cần
                END AS NVARCHAR(100)
            ),
            c.citizen_id,
            c.full_name,
            c.date_of_birth,
            c.gender,
            c.father_citizen_id,
            c.mother_citizen_id
        FROM FamilyTreeCTE ft
        JOIN [BCA].[Citizen] c ON c.citizen_id = ft.mother_citizen_id
        WHERE ft.level_id < 3  -- Giới hạn đến 3 đời (level 1, 2, 3)
    )

    -- Chèn kết quả từ CTE vào bảng trả về, kết hợp với thông tin ID và dữ liệu từ bảng khác
    INSERT INTO @FamilyTree
    SELECT
        cte.level_id,
        cte.relationship_path,
        cte.citizen_id,
        cte.full_name,
        cte.date_of_birth,
        cte.gender,
        ic.card_number AS id_card_number,
        ic.card_type AS id_card_type,
        ic.issue_date AS id_card_issue_date,
        ic.expiry_date AS id_card_expiry_date,
        auth.authority_name AS id_card_issuing_authority,
        ic.card_status AS id_card_status,
        nat.nationality_name,
        eth.ethnicity_name,
        rel.religion_name,
        c.marital_status
    FROM FamilyTreeCTE cte
    JOIN [BCA].[Citizen] c ON cte.citizen_id = c.citizen_id
    LEFT JOIN (
        -- Lấy thẻ CCCD/CMND mới nhất hoặc đang sử dụng (cải thiện để xử lý trường hợp ngày cấp giống nhau)
        SELECT ic1.*,
               ROW_NUMBER() OVER(PARTITION BY ic1.citizen_id ORDER BY ic1.issue_date DESC, ic1.id_card_id DESC) as rn
        FROM [BCA].[IdentificationCard] ic1
    ) ic ON c.citizen_id = ic.citizen_id AND ic.rn = 1 -- Chỉ lấy thẻ mới nhất
    LEFT JOIN [Reference].[Authorities] auth ON ic.issuing_authority_id = auth.authority_id
    LEFT JOIN [Reference].[Nationalities] nat ON c.nationality_id = nat.nationality_id
    LEFT JOIN [Reference].[Ethnicities] eth ON c.ethnicity_id = eth.ethnicity_id
    LEFT JOIN [Reference].[Religions] rel ON c.religion_id = rel.religion_id;

    RETURN;
END;
GO

-- Cấp quyền thực thi nếu cần
-- GRANT SELECT ON [API_Internal].[GetCitizenFamilyTree] TO [api_service_user];
-- GO

PRINT 'Function [API_Internal].[GetCitizenFamilyTree] đã được sửa lỗi và tạo lại thành công.';



--====================================================================================

USE [DB_BCA];
GO

-- Xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[UpdateCitizenMarriageStatus]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[UpdateCitizenMarriageStatus];
GO

CREATE PROCEDURE [API_Internal].[UpdateCitizenMarriageStatus]
    @citizen_id VARCHAR(12),
    @spouse_citizen_id VARCHAR(12),
    @marriage_date DATE,
    @marriage_certificate_no VARCHAR(20),
    @updated_by VARCHAR(50) = 'SYSTEM'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @affected_rows INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Cập nhật trạng thái kết hôn
        UPDATE [BCA].[Citizen]
        SET 
            [marital_status] = N'Đã kết hôn',
            [spouse_citizen_id] = @spouse_citizen_id,
            [updated_at] = GETDATE(),
            [updated_by] = @updated_by
        WHERE 
            [citizen_id] = @citizen_id
            AND ([marital_status] IS NULL OR [marital_status] = N'Độc thân');

        SET @affected_rows = @@ROWCOUNT;

        IF @affected_rows > 0
        BEGIN
            INSERT INTO [Audit].[AuditLog]
            (
                [action_tstamp],
                [schema_name],
                [table_name],
                [operation],
                [session_user_name],
                [application_name],
                [client_net_address],
                [host_name],
                [statement_only],
                [row_data],
                [changed_fields]
            )
            VALUES
            (
                GETDATE(),
                'BCA',
                'Citizen',
                'UPDATE',
                @updated_by,
                'API_Internal.UpdateCitizenMarriageStatus',
                NULL,
                HOST_NAME(),
                0,
                'Citizen ID: ' + @citizen_id + ', Spouse ID: ' + @spouse_citizen_id,
                'marital_status: Độc thân -> Đã kết hôn, spouse_citizen_id: NULL -> ' + @spouse_citizen_id
            );
        END

        COMMIT TRANSACTION;

        SELECT @affected_rows AS affected_rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        INSERT INTO [Audit].[AuditLog]
        (
            [action_tstamp],
            [schema_name],
            [table_name],
            [operation],
            [session_user_name],
            [statement_only],
            [row_data]
        )
        VALUES
        (
            GETDATE(),
            'BCA',
            'Citizen',
            'ERROR',
            @updated_by,
            1,
            'Error updating marriage status: ' + @ErrorMessage
        );

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

GRANT EXECUTE ON [API_Internal].[UpdateCitizenMarriageStatus] TO [api_service_user];
GO

PRINT 'Stored procedure [API_Internal].[UpdateCitizenMarriageStatus] đã được tạo thành công.';

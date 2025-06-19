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
        g.[gender_name_vi] AS gender,

        -- Birth Place Info
        c.[birth_ward_id],
        bw.[ward_name] AS birth_ward_name,
        c.[birth_district_id],
        bd.[district_name] AS birth_district_name,
        c.[birth_province_id],
        bp.[province_name] AS birth_province_name,
        c.[birth_country_id],
        bc.[nationality_name] AS birth_country_name,
        c.[place_of_birth_code],
        c.[place_of_birth_detail],

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
        bt.[blood_type_name_vi] AS blood_type,

        -- Social/Economic Info
        ms.[marital_status_name_vi] AS marital_status,
        el.[education_level_name_vi] AS education_level,
        c.[occupation_id],
        occ.[occupation_name],
        c.[tax_code],
        c.[social_insurance_no],
        c.[health_insurance_no],

        -- Current Address Info (through primary_address_id)
        a.[address_detail] AS current_address_detail,
        a.[ward_id] AS current_ward_id,
        cw.[ward_name] AS current_ward_name,
        a.[district_id] AS current_district_id,
        cd.[district_name] AS current_district_name,
        a.[province_id] AS current_province_id,
        cp.[province_name] AS current_province_name,

        -- Family Info
        c.[father_citizen_id],
        c.[mother_citizen_id],
        c.[spouse_citizen_id],
        c.[representative_citizen_id],

        -- Status Info
        st.[status_name_vi] AS citizen_status,
        c.[status_change_date],

        -- Contact Info
        c.[phone_number],
        c.[email],

        -- Metadata
        c.[created_at],
        c.[updated_at],
        c.[created_by],
        c.[updated_by]

    FROM [BCA].[Citizen] c
    -- Join for Gender
    LEFT JOIN [Reference].[Genders] g ON c.gender_id = g.gender_id
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
    LEFT JOIN [Reference].[BloodTypes] bt ON c.blood_type_id = bt.blood_type_id
    -- Join for Social/Economic Info
    LEFT JOIN [Reference].[MaritalStatuses] ms ON c.marital_status_id = ms.marital_status_id
    LEFT JOIN [Reference].[EducationLevels] el ON c.education_level_id = el.education_level_id
    LEFT JOIN [Reference].[Occupations] occ ON c.occupation_id = occ.occupation_id
    -- Join for Status Info
    LEFT JOIN [Reference].[CitizenStatusTypes] st ON c.citizen_status_id = st.citizen_status_id
    -- Joins for Current Address (through primary_address_id)
    LEFT JOIN [BCA].[Address] a ON c.primary_address_id = a.address_id
    LEFT JOIN [Reference].[Wards] cw ON a.ward_id = cw.ward_id
    LEFT JOIN [Reference].[Districts] cd ON a.district_id = cd.district_id
    LEFT JOIN [Reference].[Provinces] cp ON a.province_id = cp.province_id
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
        rt.[residence_type_name_vi] AS residence_type,
        rh.[residence_history_id] AS record_id,
        a.[address_detail],
        w.[ward_name],
        d.[district_name],
        p.[province_name],
        NULL AS destination_detail, -- Only for temporary absence
        rh.[registration_date] AS start_date,
        rh.[expiry_date] AS end_date,
        CASE 
            WHEN rs.[status_code] = 'ACTIVE' AND rt.[residence_type_code] = 'THUONGTRU' THEN 1
            ELSE 0
        END AS is_current_permanent_residence,
        CASE 
            WHEN rs.[status_code] = 'ACTIVE' AND rt.[residence_type_code] = 'TAMTRU' THEN 1
            ELSE 0
        END AS is_current_temporary_residence,
        0 AS is_temporary_absence,
        0 AS is_current_address,
        0 AS is_accommodation,
        rh.[registration_reason] AS reason,
        CASE
            WHEN rs.[status_code] IN ('TRANSFERRING', 'CANCELLED') THEN rh.[updated_at]
            WHEN rs.[status_code] = 'EXPIRED' THEN rh.[expiry_date]
            ELSE NULL
        END AS deregistration_date,
        rs.[status_name_vi] AS record_status,
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
    LEFT JOIN [Reference].[ResidenceTypes] rt ON rh.residence_type_id = rt.residence_type_id
    LEFT JOIN [Reference].[ResidenceRegistrationStatuses] rs ON rh.res_reg_status_id = rs.res_reg_status_id
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
        tas.[status_name_vi] AS record_status,
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
    LEFT JOIN [Reference].[TemporaryAbsenceStatuses] tas ON ta.temp_abs_status_id = tas.temp_abs_status_id
    WHERE ta.[citizen_id] = @citizen_id
    
    UNION ALL
    
    -- 3. Current Residence and Other Address Types (from CitizenAddress)
    SELECT
        'CitizenAddress' AS record_type,
        at.[address_type_name_vi] AS residence_type,
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
            WHEN at.[address_type_code] = 'NOIOHIENTAI' AND ca.[status] = 1 THEN 1
            ELSE 0
        END AS is_current_address,
        CASE 
            WHEN at.[address_type_code] = 'KHAC' AND ca.[status] = 1 THEN 1
            ELSE 0
        END AS is_accommodation,
        NULL AS reason,
        CASE
            WHEN ca.[status] = 0 THEN ca.[updated_at]
            WHEN ca.[to_date] IS NOT NULL THEN ca.[to_date]
            ELSE NULL
        END AS deregistration_date,
        CASE 
            WHEN ca.[status] = 1 THEN N'Đang hiệu lực' 
            ELSE N'Không hiệu lực' 
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
    LEFT JOIN [Reference].[AddressTypes] at ON ca.address_type_id = at.address_type_id
    WHERE ca.[citizen_id] = @citizen_id
)
GO

--====================================================================================

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
        a.[address_detail] AS current_address_detail,
        w.[ward_name] AS current_ward_name,
        d.[district_name] AS current_district_name,
        p.[province_name] AS current_province_name
    FROM [BCA].[Citizen] c
    LEFT JOIN [BCA].[Address] a ON c.primary_address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    WHERE c.[citizen_id] = @citizen_id
)
GO

--====================================================================================

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
    -- Chọn citizen_id và trạng thái từ bảng Citizen
    SELECT
        c.[citizen_id],
        st.[status_code] AS citizen_status_code,
        st.[status_name_vi] AS citizen_status_name
    FROM
        [BCA].[Citizen] c
    LEFT JOIN
        [Reference].[CitizenStatusTypes] st ON c.citizen_status_id = st.citizen_status_id
    WHERE
        c.[citizen_id] = @citizen_id
);
GO

--====================================================================================

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[UpdateCitizenDeathStatus]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[UpdateCitizenDeathStatus];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[UpdateCitizenDeathStatus]...';
GO

CREATE PROCEDURE [API_Internal].[UpdateCitizenDeathStatus]
    @citizen_id VARCHAR(12),           -- ID CCCD/CMND của công dân
    @date_of_death DATE,               -- Ngày mất
    @cause_of_death NVARCHAR(MAX) = NULL, -- Nguyên nhân mất (tùy chọn)
    @place_of_death_detail NVARCHAR(MAX) = NULL, -- Nơi mất chi tiết (tùy chọn)
    @death_certificate_no VARCHAR(50) = NULL, -- Số giấy chứng tử từ BTP (tùy chọn)
    @issuing_authority_id_btp INT = NULL, -- ID cơ quan cấp giấy chứng tử của BTP (tùy chọn)
    @updated_by VARCHAR(50) = 'KAFKA_CONSUMER' -- Người/hệ thống cập nhật
AS
BEGIN
    SET NOCOUNT ON;

    -- Sử dụng trực tiếp các ID từ dữ liệu mẫu
    -- Tham khảo từ file sample_data.sql cho DB_BCA/Reference
    -- Reference.CitizenStatusTypes: 1='Còn sống', 2='Đã mất'
    -- Reference.IdentificationCardStatuses: 1='Đang sử dụng', 3='Đã hủy' (hoặc 4='Bị thu hồi' tùy ngữ cảnh)
    -- Reference.MaritalStatuses: 1='Độc thân', 2='Đã kết hôn', 3='Ly hôn', 4='Góa vợ/chồng'
    DECLARE @citizen_status_id_deceased SMALLINT = 2; -- 'Đã mất'
    DECLARE @citizen_status_id_alive SMALLINT = 1;    -- 'Còn sống'
    DECLARE @card_status_id_recalled SMALLINT = 3;    -- 'Đã hủy' (hoặc 4 'Bị thu hồi' tùy nghiệp vụ)
    DECLARE @marital_status_id_married SMALLINT = 2;  -- 'Đã kết hôn'
    DECLARE @marital_status_id_widowed SMALLINT = 4;  -- 'Góa vợ/chồng'

    DECLARE @affected_rows INT = 0;
    DECLARE @current_spouse_id VARCHAR(12);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra xem công dân có tồn tại không.
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id)
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Công dân với ID cung cấp không tồn tại.', 16, 1);
            SELECT 0 AS affected_rows; RETURN;
        END

        -- Lấy thông tin người phối ngẫu hiện tại (nếu có) TRƯỚC KHI cập nhật người đã mất
        -- Chỉ lấy nếu tình trạng hôn nhân của người mất là 'Đã kết hôn'
        SELECT @current_spouse_id = [spouse_citizen_id]
        FROM [BCA].[Citizen]
        WHERE [citizen_id] = @citizen_id AND [marital_status_id] = @marital_status_id_married;

        -- 1. Cập nhật bảng [BCA].[Citizen]
        UPDATE [BCA].[Citizen]
        SET [citizen_status_id] = @citizen_status_id_deceased,
            [status_change_date] = @date_of_death,
            [updated_at] = SYSDATETIME(),
            [updated_by] = @updated_by
        WHERE [citizen_id] = @citizen_id;

        SET @affected_rows = @@ROWCOUNT;

        -- Nếu cập nhật thành công (công dân tồn tại)
        IF @affected_rows > 0
        BEGIN
            -- 2. Cập nhật tất cả trạng thái hiện tại (is_current = 1) của công dân này thành không hiện tại (is_current = 0)
            UPDATE [BCA].[CitizenStatus]
            SET [is_current] = 0,
                [updated_at] = SYSDATETIME(),
                [updated_by] = @updated_by
            WHERE [citizen_id] = @citizen_id
              AND [is_current] = 1;

            -- 3. Thêm mới trạng thái "Đã mất" vào [BCA].[CitizenStatus]
            INSERT INTO [BCA].[CitizenStatus] (
                [citizen_id], [citizen_status_id], [status_date], [description], [cause], [location],
                [certificate_id], [document_number], [document_date], [authority_id],
                [is_current], [created_at], [updated_at], [created_by], [updated_by]
            )
            VALUES (
                @citizen_id, @citizen_status_id_deceased, @date_of_death,
                N'Cập nhật từ thông tin khai tử của Bộ Tư pháp.',
                @cause_of_death, @place_of_death_detail, @death_certificate_no, @death_certificate_no, @date_of_death,
                @issuing_authority_id_btp, -- Sử dụng authority_id từ BTP nếu có
                1, -- Đây là trạng thái hiện tại
                SYSDATETIME(), SYSDATETIME(), @updated_by, @updated_by
            );

            -- 4. Thu hồi tất cả thẻ CCCD/CMND đang sử dụng của công dân đã mất
            UPDATE [BCA].[IdentificationCard]
            SET [card_status_id] = @card_status_id_recalled,
                [updated_at] = SYSDATETIME(),
                [updated_by] = @updated_by,
                [notes] = ISNULL(RTRIM([notes]) + N' | ', N'') + N'Thu hồi do công dân đã mất ngày ' + CONVERT(NVARCHAR, @date_of_death, 103) -- dd/mm/yyyy
            WHERE [citizen_id] = @citizen_id
              AND [card_status_id] NOT IN (@card_status_id_recalled, (SELECT cs.card_status_id FROM [Reference].[IdentificationCardStatuses] cs WHERE cs.card_status_code = 'HETHAN')); -- Chỉ cập nhật nếu chưa bị thu hồi/hủy hoặc hết hạn

            -- 5. Cập nhật trạng thái người phối ngẫu (nếu có và còn sống) thành "Góa"
            IF @current_spouse_id IS NOT NULL
            BEGIN
                -- Kiểm tra xem người phối ngẫu có còn sống không
                IF EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @current_spouse_id AND [citizen_status_id] = @citizen_status_id_alive)
                BEGIN
                    UPDATE [BCA].[Citizen]
                    SET [marital_status_id] = @marital_status_id_widowed,
                        -- [spouse_citizen_id] = NULL, -- Cân nhắc nghiệp vụ: có nên xóa spouse_id của người còn sống?
                                                    -- Hiện tại để không xóa, chỉ cập nhật tình trạng hôn nhân.
                        [updated_at] = SYSDATETIME(),
                        [updated_by] = @updated_by
                    WHERE [citizen_id] = @current_spouse_id;

                    -- Ghi nhận sự thay đổi tình trạng hôn nhân cho người phối ngẫu vào CitizenStatus
                    IF @@ROWCOUNT > 0 -- Chỉ thêm nếu có cập nhật trên bảng Citizen của người phối ngẫu
                    BEGIN
                        -- Đặt is_current của trạng thái cũ của người phối ngẫu thành 0
                        UPDATE [BCA].[CitizenStatus]
                        SET [is_current] = 0,
                            [updated_at] = SYSDATETIME(),
                            [updated_by] = @updated_by
                        WHERE [citizen_id] = @current_spouse_id AND [is_current] = 1;

                        -- Thêm trạng thái mới cho người phối ngẫu
                        INSERT INTO [BCA].[CitizenStatus] (
                            [citizen_id], [citizen_status_id], [status_date], [description],
                            [is_current], [created_at], [updated_at], [created_by], [updated_by]
                        )
                        VALUES (
                            @current_spouse_id,
                            @citizen_status_id_alive, -- Trạng thái chính của họ vẫn là "Còn sống"
                            SYSDATETIME(), -- Ngày ghi nhận thay đổi tình trạng hôn nhân
                            N'Cập nhật tình trạng hôn nhân thành góa do người phối ngẫu (' + @citizen_id + N') qua đời.',
                            1, -- Đây là trạng thái hiện tại
                            SYSDATETIME(), SYSDATETIME(), @updated_by, @updated_by
                        );
                    END
                END
            END
        END

        COMMIT TRANSACTION;
        SELECT @affected_rows AS affected_rows;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT ERROR_MESSAGE(); -- In ra thông báo lỗi SQL Server
        THROW; -- Ném lại lỗi để lớp gọi xử lý
    END CATCH
END;
GO

PRINT 'Stored procedure [API_Internal].[UpdateCitizenDeathStatus] đã được tạo/cập nhật thành công.';
GO

--====================================================================================

-- hàm GetCitizenFamilyTree sử dụng CTE đệ quy để lấy thông tin phả hệ 3 đời của công dân
-- Kiểm tra và xóa function nếu đã tồn tại
-- Xóa function cũ nếu tồn tại
IF OBJECT_ID('[API_Internal].[GetCitizenFamilyTree]', 'TF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetCitizenFamilyTree];
GO

-- Tạo lại Table-Valued Function để lấy thông tin phả hệ 3 đời của công dân
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
    id_card_type NVARCHAR(50),       -- Loại giấy tờ
    id_card_issue_date DATE,         -- Ngày cấp
    id_card_expiry_date DATE,        -- Ngày hết hạn
    id_card_issuing_authority NVARCHAR(255), -- Nơi cấp
    id_card_status NVARCHAR(50),     -- Trạng thái thẻ
    nationality_name NVARCHAR(100),  -- Quốc tịch
    ethnicity_name NVARCHAR(100),    -- Dân tộc
    religion_name NVARCHAR(100),     -- Tôn giáo
    marital_status NVARCHAR(50)      -- Tình trạng hôn nhân
)
AS
BEGIN
    -- Sử dụng CTE đệ quy để duyệt qua cây phả hệ (chỉ với INNER JOIN)
    WITH FamilyTreeCTE AS (
        -- Trường hợp cơ sở: công dân gốc (level 1)
        SELECT
            1 AS level_id,
            CAST(N'Công dân' AS NVARCHAR(100)) AS relationship_path,
            c.citizen_id,
            c.full_name,
            c.date_of_birth,
            c.gender_id,  -- Lưu gender_id thay vì join ngay
            c.father_citizen_id,
            c.mother_citizen_id
        FROM [BCA].[Citizen] c
        WHERE c.citizen_id = @citizen_id

        UNION ALL

        -- Trường hợp đệ quy: tìm bố (chỉ dùng INNER JOIN)
        SELECT
            ft.level_id + 1,
            CAST(
                CASE
                    WHEN ft.relationship_path = N'Công dân' THEN N'Bố'
                    WHEN ft.relationship_path = N'Bố' THEN N'Ông Nội (Bố của Bố)'
                    WHEN ft.relationship_path = N'Mẹ' THEN N'Ông Ngoại (Bố của Mẹ)'
                    WHEN ft.relationship_path = N'Ông Nội (Bố của Bố)' THEN N'Cụ Nội (Bố của Ông Nội)'
                    WHEN ft.relationship_path = N'Bà Nội (Mẹ của Bố)' THEN N'Cụ Ông Nội (Bố của Bà Nội)'
                    WHEN ft.relationship_path = N'Ông Ngoại (Bố của Mẹ)' THEN N'Cụ Ngoại (Bố của Ông Ngoại)'
                    WHEN ft.relationship_path = N'Bà Ngoại (Mẹ của Mẹ)' THEN N'Cụ Ông Ngoại (Bố của Bà Ngoại)'
                    ELSE N'Không xác định'
                END AS NVARCHAR(100)
            ),
            c.citizen_id,
            c.full_name,
            c.date_of_birth,
            c.gender_id,  -- Lưu gender_id thay vì join ngay
            c.father_citizen_id,
            c.mother_citizen_id
        FROM FamilyTreeCTE ft
        INNER JOIN [BCA].[Citizen] c ON c.citizen_id = ft.father_citizen_id
        WHERE ft.level_id < 3 AND ft.father_citizen_id IS NOT NULL

        UNION ALL

        -- Trường hợp đệ quy: tìm mẹ (chỉ dùng INNER JOIN)
        SELECT
            ft.level_id + 1,
            CAST(
                CASE
                    WHEN ft.relationship_path = N'Công dân' THEN N'Mẹ'
                    WHEN ft.relationship_path = N'Bố' THEN N'Bà Nội (Mẹ của Bố)'
                    WHEN ft.relationship_path = N'Mẹ' THEN N'Bà Ngoại (Mẹ của Mẹ)'
                    WHEN ft.relationship_path = N'Ông Nội (Bố của Bố)' THEN N'Cụ Bà Nội (Mẹ của Ông Nội)'
                    WHEN ft.relationship_path = N'Bà Nội (Mẹ của Bố)' THEN N'Cụ Bà Nội (Mẹ của Bà Nội)'
                    WHEN ft.relationship_path = N'Ông Ngoại (Bố của Mẹ)' THEN N'Cụ Bà Ngoại (Mẹ của Ông Ngoại)'
                    WHEN ft.relationship_path = N'Bà Ngoại (Mẹ của Mẹ)' THEN N'Cụ Bà Ngoại (Mẹ của Bà Ngoại)'
                    ELSE N'Không xác định'
                END AS NVARCHAR(100)
            ),
            c.citizen_id,
            c.full_name,
            c.date_of_birth,
            c.gender_id,  -- Lưu gender_id thay vì join ngay
            c.father_citizen_id,
            c.mother_citizen_id
        FROM FamilyTreeCTE ft
        INNER JOIN [BCA].[Citizen] c ON c.citizen_id = ft.mother_citizen_id
        WHERE ft.level_id < 3 AND ft.mother_citizen_id IS NOT NULL
    )

    -- Chèn kết quả từ CTE vào bảng trả về, join với các bảng reference ở đây
    INSERT INTO @FamilyTree
    SELECT
        cte.level_id,
        cte.relationship_path,
        cte.citizen_id,
        cte.full_name,
        cte.date_of_birth,
        ISNULL(g.gender_name_vi, N'Không xác định') AS gender,
        ic.card_number AS id_card_number,
        ict.card_type_name_vi AS id_card_type,
        ic.issue_date AS id_card_issue_date,
        ic.expiry_date AS id_card_expiry_date,
        auth.authority_name AS id_card_issuing_authority,
        ics.card_status_name_vi AS id_card_status,
        nat.nationality_name,
        eth.ethnicity_name,
        rel.religion_name,
        ms.marital_status_name_vi AS marital_status
    FROM FamilyTreeCTE cte
    INNER JOIN [BCA].[Citizen] c ON cte.citizen_id = c.citizen_id
    LEFT JOIN [Reference].[Genders] g ON cte.gender_id = g.gender_id
    LEFT JOIN (
        -- Lấy thẻ CCCD/CMND mới nhất hoặc đang sử dụng
        SELECT ic1.*,
               ROW_NUMBER() OVER(PARTITION BY ic1.citizen_id ORDER BY ic1.issue_date DESC, ic1.id_card_id DESC) as rn
        FROM [BCA].[IdentificationCard] ic1
    ) ic ON c.citizen_id = ic.citizen_id AND ic.rn = 1 -- Chỉ lấy thẻ mới nhất
    LEFT JOIN [Reference].[IdentificationCardTypes] ict ON ic.card_type_id = ict.card_type_id
    LEFT JOIN [Reference].[IdentificationCardStatuses] ics ON ic.card_status_id = ics.card_status_id
    LEFT JOIN [Reference].[Authorities] auth ON ic.issuing_authority_id = auth.authority_id
    LEFT JOIN [Reference].[Nationalities] nat ON c.nationality_id = nat.nationality_id
    LEFT JOIN [Reference].[Ethnicities] eth ON c.ethnicity_id = eth.ethnicity_id
    LEFT JOIN [Reference].[Religions] rel ON c.religion_id = rel.religion_id
    LEFT JOIN [Reference].[MaritalStatuses] ms ON c.marital_status_id = ms.marital_status_id;

    RETURN;
END;
GO

PRINT 'Function [API_Internal].[GetCitizenFamilyTree] đã được tạo lại thành công.';
GO

--====================================================================================

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
    DECLARE @marital_status_id_single SMALLINT = 1;  -- 'Độc thân'
    DECLARE @marital_status_id_married SMALLINT = 2; -- 'Đã kết hôn'
    DECLARE @previous_marital_status_id SMALLINT;
    DECLARE @previous_spouse_id VARCHAR(12);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lấy thông tin tình trạng hôn nhân hiện tại
        SELECT @previous_marital_status_id = marital_status_id,
               @previous_spouse_id = spouse_citizen_id
        FROM [BCA].[Citizen]
        WHERE [citizen_id] = @citizen_id;

        -- Cập nhật trạng thái kết hôn
        UPDATE [BCA].[Citizen]
        SET 
            [marital_status_id] = @marital_status_id_married,
            [spouse_citizen_id] = @spouse_citizen_id,
            [updated_at] = GETDATE(),
            [updated_by] = @updated_by
        WHERE 
            [citizen_id] = @citizen_id
            AND ([marital_status_id] IS NULL OR [marital_status_id] = @marital_status_id_single);

        SET @affected_rows = @@ROWCOUNT;

        IF @affected_rows > 0
        BEGIN
            -- Ghi log vào Audit nếu có schema Audit
            IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'Audit')
            BEGIN
                -- Insert audit log here if Audit.AuditLog table exists
                DECLARE @sql NVARCHAR(MAX) = N'
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
                    ''BCA'',
                    ''Citizen'',
                    ''UPDATE'',
                    @updated_by,
                    ''API_Internal.UpdateCitizenMarriageStatus'',
                    NULL,
                    HOST_NAME(),
                    0,
                    ''Citizen ID: '' + @citizen_id + '', Spouse ID: '' + @spouse_citizen_id,
                    ''marital_status_id: '' + ISNULL(CAST(@previous_marital_status_id AS VARCHAR), ''NULL'') + 
                    '' -> '' + CAST(@marital_status_id_married AS VARCHAR) + 
                    '', spouse_citizen_id: '' + ISNULL(@previous_spouse_id, ''NULL'') + '' -> '' + @spouse_citizen_id
                )';
                
                EXEC sp_executesql @sql, 
                    N'@updated_by VARCHAR(50), @citizen_id VARCHAR(12), @spouse_citizen_id VARCHAR(12), @previous_marital_status_id SMALLINT, @marital_status_id_married SMALLINT, @previous_spouse_id VARCHAR(12)',
                    @updated_by, @citizen_id, @spouse_citizen_id, @previous_marital_status_id, @marital_status_id_married, @previous_spouse_id;
            END
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

        -- Log error if Audit schema exists
        IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'Audit')
        BEGIN
            DECLARE @sql_error NVARCHAR(MAX) = N'
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
                ''BCA'',
                ''Citizen'',
                ''ERROR'',
                @updated_by,
                1,
                ''Error updating marriage status: '' + @ErrorMessage
            )';
            
            EXEC sp_executesql @sql_error, 
                N'@updated_by VARCHAR(50), @ErrorMessage NVARCHAR(4000)',
                @updated_by, @ErrorMessage;
        END

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

GRANT EXECUTE ON [API_Internal].[UpdateCitizenMarriageStatus] TO [api_service_user];
GO

PRINT 'Stored procedure [API_Internal].[UpdateCitizenMarriageStatus] đã được tạo thành công.';
GO



-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[UpdateCitizenDivorceStatus]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[UpdateCitizenDivorceStatus];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[UpdateCitizenDivorceStatus]...';
GO





CREATE PROCEDURE [API_Internal].[UpdateCitizenDivorceStatus]
    @citizen_id VARCHAR(12),
    @former_spouse_citizen_id VARCHAR(12), -- ID của người phối ngẫu cũ
    @divorce_date DATE,
    @judgment_no VARCHAR(50),
    @updated_by VARCHAR(50) = 'KAFKA_CONSUMER'
AS
BEGIN
    SET NOCOUNT ON;

    -- Tham chiếu từ Reference.MaritalStatuses: 1='Độc thân', 2='Đã kết hôn', 3='Ly hôn', 4='Góa vợ/chồng'
    DECLARE @marital_status_id_divorced SMALLINT = 3;
    DECLARE @affected_rows INT = 0;
    DECLARE @current_marital_status_id SMALLINT;
    DECLARE @current_spouse_citizen_id VARCHAR(12);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lấy trạng thái hôn nhân và người phối ngẫu hiện tại
        SELECT @current_marital_status_id = marital_status_id,
               @current_spouse_citizen_id = spouse_citizen_id
        FROM [BCA].[Citizen]
        WHERE [citizen_id] = @citizen_id;

        -- Chỉ cập nhật nếu trạng thái hiện tại là 'Đã kết hôn' và spouse_citizen_id khớp
        IF @current_marital_status_id = 2 AND @current_spouse_citizen_id = @former_spouse_citizen_id
        BEGIN
            -- 1. Cập nhật bảng [BCA].[Citizen]
            UPDATE [BCA].[Citizen]
            SET [marital_status_id] = @marital_status_id_divorced,
                [spouse_citizen_id] = NULL, -- Xóa liên kết người phối ngẫu
                [updated_at] = SYSDATETIME(),
                [updated_by] = @updated_by
            WHERE [citizen_id] = @citizen_id;

            SET @affected_rows = @@ROWCOUNT;

            IF @affected_rows > 0
            BEGIN
                -- 2. Cập nhật tất cả trạng thái hiện tại (is_current = 1) của công dân này thành không hiện tại (is_current = 0)
                UPDATE [BCA].[CitizenStatus]
                SET [is_current] = 0,
                    [updated_at] = SYSDATETIME(),
                    [updated_by] = @updated_by
                WHERE [citizen_id] = @citizen_id
                  AND [is_current] = 1;

                -- 3. Thêm mới trạng thái vào [BCA].[CitizenStatus]
                INSERT INTO [BCA].[CitizenStatus] (
                    [citizen_id], [citizen_status_id], [status_date], [description], [document_number],
                    [document_date], [is_current], [created_at], [updated_at], [created_by], [updated_by]
                )
                VALUES (
                    @citizen_id,
                    (SELECT citizen_status_id FROM [Reference].[CitizenStatusTypes] WHERE status_code = 'CONSONG'), -- Trạng thái chính vẫn là 'Còn sống'
                    @divorce_date,
                    N'Cập nhật tình trạng hôn nhân thành Ly hôn theo quyết định tòa án số ' + @judgment_no,
                    @judgment_no,
                    @divorce_date,
                    1, -- Đây là trạng thái hiện tại
                    SYSDATETIME(), SYSDATETIME(), @updated_by, @updated_by
                );
            END
        END
        ELSE
        BEGIN
            -- Log cảnh báo nếu trạng thái hiện tại không phải 'Đã kết hôn' hoặc spouse_citizen_id không khớp
            PRINT N'Cảnh báo: Không thể cập nhật trạng thái ly hôn cho công dân ' + @citizen_id +
                  N'. Trạng thái hiện tại: ' + ISNULL(CAST(@current_marital_status_id AS NVARCHAR), 'NULL') +
                  N', Người phối ngẫu hiện tại: ' + ISNULL(@current_spouse_citizen_id, 'NULL') +
                  N'. Cần là "Đã kết hôn" và khớp người phối ngẫu.';
        END

        COMMIT TRANSACTION;
        SELECT @affected_rows AS affected_rows;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

GRANT EXECUTE ON [API_Internal].[UpdateCitizenDivorceStatus] TO [api_service_user];
GO

PRINT 'Stored procedure [API_Internal].[UpdateCitizenDivorceStatus] đã được tạo/cập nhật thành công.';
GO


USE [DB_BCA];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[InsertNewbornCitizen]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertNewbornCitizen];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[InsertNewbornCitizen]...';
GO

-- Tạo Stored Procedure để thêm mới một công dân (đặc biệt cho trẻ sơ sinh)
CREATE PROCEDURE [API_Internal].[InsertNewbornCitizen]
    @citizen_id VARCHAR(12),
    @full_name NVARCHAR(100),
    @date_of_birth DATE,
    @gender_id SMALLINT,
    @birth_ward_id INT = NULL,
    @birth_district_id INT = NULL,
    @birth_province_id INT = NULL,
    @birth_country_id SMALLINT = 1, -- Mặc định là Việt Nam
    @native_ward_id INT = NULL,
    @native_district_id INT = NULL,
    @native_province_id INT = NULL,
    @father_citizen_id VARCHAR(12) = NULL,
    @mother_citizen_id VARCHAR(12) = NULL,
    @place_of_birth_code VARCHAR(10) = NULL,
    @place_of_birth_detail NVARCHAR(MAX) = NULL,
    @created_by VARCHAR(50) = 'BTP_SERVICE',
    @new_citizen_id VARCHAR(12) OUTPUT -- Output parameter for the new citizen_id
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra các tham số bắt buộc
    IF @citizen_id IS NULL OR 
       @full_name IS NULL OR 
       @date_of_birth IS NULL OR 
       @gender_id IS NULL
    BEGIN
        RAISERROR('Thiếu thông tin bắt buộc để tạo công dân mới (citizen_id, full_name, date_of_birth, gender_id).', 16, 1);
        RETURN;
    END

    -- Kiểm tra xem citizen_id đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id)
    BEGIN
        RAISERROR('Citizen ID đã tồn tại. Không thể tạo công dân mới với ID trùng lặp.', 16, 1);
        RETURN;
    END

    -- Lấy citizen_status_id cho 'Còn sống' (giả định ID là 1 từ Reference.CitizenStatusTypes)
    DECLARE @citizen_status_id_alive SMALLINT = (SELECT citizen_status_id FROM [Reference].[CitizenStatusTypes] WHERE status_code = 'CONSONG');
    IF @citizen_status_id_alive IS NULL
    BEGIN
        RAISERROR('Không tìm thấy ID cho trạng thái công dân "Còn sống". Vui lòng kiểm tra bảng Reference.CitizenStatusTypes.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Thực hiện INSERT vào bảng BCA.Citizen
        INSERT INTO [BCA].[Citizen] (
            [citizen_id],
            [full_name],
            [date_of_birth],
            [gender_id],
            [birth_ward_id],
            [birth_district_id],
            [birth_province_id],
            [birth_country_id],
            [native_ward_id],
            [native_district_id],
            [native_province_id],
            [nationality_id], -- Mặc định là quốc tịch của nơi sinh hoặc Việt Nam
            [ethnicity_id], -- Có thể để NULL hoặc mặc định nếu không có thông tin
            [religion_id],  -- Có thể để NULL hoặc mặc định
            [marital_status_id], -- Mặc định là độc thân (1)
            [education_level_id], -- Có thể để NULL hoặc mặc định
            [occupation_id], -- Có thể để NULL hoặc mặc định
            [father_citizen_id],
            [mother_citizen_id],
            [citizen_status_id], -- Mặc định là 'Còn sống'
            [status_change_date],
            [place_of_birth_code],
            [place_of_birth_detail],
            [created_at],
            [updated_at],
            [created_by],
            [updated_by]
        )
        VALUES (
            @citizen_id,
            @full_name,
            @date_of_birth,
            @gender_id,
            @birth_ward_id,
            @birth_district_id,
            @birth_province_id,
            @birth_country_id,
            @native_ward_id,
            @native_district_id,
            @native_province_id,
            @birth_country_id, -- Sử dụng birth_country_id làm nationality_id ban đầu
            NULL, -- ethnicity_id (có thể cập nhật sau)
            NULL, -- religion_id (có thể cập nhật sau)
            1, -- marital_status_id: Mặc định là Độc thân
            NULL, -- education_level_id (có thể cập nhật sau)
            NULL, -- occupation_id (có thể cập nhật sau)
            @father_citizen_id,
            @mother_citizen_id,
            @citizen_status_id_alive,
            @date_of_birth, -- Ngày thay đổi trạng thái là ngày sinh
            @place_of_birth_code,
            @place_of_birth_detail,
            SYSDATETIME(),
            SYSDATETIME(),
            @created_by,
            @created_by
        );

        -- Gán giá trị citizen_id cho output parameter
        SET @new_citizen_id = @citizen_id;

        -- Thêm bản ghi vào BCA.CitizenStatus để ghi nhận trạng thái ban đầu
        INSERT INTO [BCA].[CitizenStatus] (
            [citizen_id],
            [citizen_status_id],
            [status_date],
            [description],
            [is_current],
            [created_at],
            [updated_at],
            [created_by],
            [updated_by]
        )
        VALUES (
            @citizen_id,
            @citizen_status_id_alive,
            @date_of_birth,
            N'Trạng thái ban đầu: Công dân mới sinh',
            1, -- Là trạng thái hiện tại
            SYSDATETIME(),
            SYSDATETIME(),
            @created_by,
            @created_by
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Ném lại lỗi để tầng ứng dụng xử lý
        THROW;
    END CATCH
END;
GO

PRINT 'Stored procedure [API_Internal].[InsertNewbornCitizen] đã được tạo/cập nhật thành công.';
GO

USE [DB_BCA];
GO

-- Drop the stored procedure if it already exists
IF OBJECT_ID('[API_Internal].[GetReferenceTableData]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[GetReferenceTableData];
GO

-- Create a stored procedure that retrieves data from specified reference tables
CREATE PROCEDURE [API_Internal].[GetReferenceTableData]
    @tableNames NVARCHAR(MAX) -- Comma-separated list of table names
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Table variable to hold the parsed table names
    DECLARE @Tables TABLE (
        TableName NVARCHAR(128),
        ProcessOrder INT IDENTITY(1,1)
    );
    
    -- Parse the comma-separated list of table names
    WITH Splitter AS (
        SELECT 
            LTRIM(RTRIM(Split.a.value('.', 'NVARCHAR(128)'))) AS TableName
        FROM (
            SELECT CAST('<X>' + REPLACE(@tableNames, ',', '</X><X>') + '</X>' AS XML) AS TableList
        ) AS TableSource
        CROSS APPLY TableList.nodes('/X') AS Split(a)
    )
    INSERT INTO @Tables (TableName)
    SELECT TableName 
    FROM Splitter
    WHERE TableName <> '';
    
    -- Variable to store the dynamic SQL
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Get the total number of tables to process
    DECLARE @TotalTables INT = (SELECT COUNT(*) FROM @Tables);
    DECLARE @CurrentTable INT = 1;
    
    -- Process each table
    WHILE @CurrentTable <= @TotalTables
    BEGIN
        DECLARE @TableName NVARCHAR(128);
        
        -- Get the current table name
        SELECT @TableName = TableName
        FROM @Tables
        WHERE ProcessOrder = @CurrentTable;
        
        -- Check if the table exists in the Reference schema
        IF EXISTS (
            SELECT 1 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'Reference' AND TABLE_NAME = @TableName
        )
        BEGIN
            -- Construct the dynamic SQL to retrieve all data from the table
            SET @SQL = N'
                SELECT 
                    ''' + @TableName + ''' AS TableName, 
                    * 
                FROM [Reference].[' + @TableName + ']';
            
            -- Execute the dynamic SQL
            EXEC sp_executesql @SQL;
        END
        ELSE
        BEGIN
            -- Return an error message if the table doesn't exist
            SELECT 
                @TableName AS TableName,
                'ERROR: Table not found in Reference schema' AS ErrorMessage;
        END
        
        -- Move to the next table
        SET @CurrentTable = @CurrentTable + 1;
    END
END;
GO

-- Grant execute permission to API service user


PRINT 'Stored procedure [API_Internal].[GetReferenceTableData] created successfully.';



USE [DB_BCA];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[RegisterPermanentResidence_OwnedProperty_DataOnly]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[RegisterPermanentResidence_OwnedProperty_DataOnly];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[RegisterPermanentResidence_OwnedProperty_DataOnly] (Chi tiết hơn)...';
GO

CREATE PROCEDURE [API_Internal].[RegisterPermanentResidence_OwnedProperty_DataOnly]
    -- Thông tin công dân và địa chỉ mới
    @citizen_id VARCHAR(12),
    @address_detail NVARCHAR(MAX),
    @ward_id INT,
    @district_id INT,
    @province_id INT,
    @postal_code VARCHAR(10) = NULL,
    @latitude DECIMAL(9,6) = NULL,
    @longitude DECIMAL(9,6) = NULL,

    -- Thông tin quyền sở hữu
    @ownership_certificate_id BIGINT,

    -- Thông tin đăng ký cư trú
    @registration_date DATE,
    @issuing_authority_id INT, -- Cơ quan đăng ký (CA Quận/Phường)
    @registration_number VARCHAR(50) = NULL, -- Số đăng ký thường trú (nếu có, có thể do hệ thống cấp)
    @registration_reason NVARCHAR(MAX) = NULL,
    @residence_expiry_date DATE = NULL, -- Ngày hết hạn cư trú (thường NULL cho thường trú)
    @previous_address_id BIGINT = NULL, -- ID địa chỉ cũ (nếu có chuyển đi)
    @residence_status_change_reason_id SMALLINT = NULL, -- ID lý do thay đổi trạng thái cư trú
    @document_url VARCHAR(255) = NULL, -- URL tài liệu đính kèm
    @rh_verification_status NVARCHAR(50) = N'Đã xác minh', -- Trạng thái xác minh của ResidenceHistory
    @rh_verification_date DATE = NULL,
    @rh_verified_by NVARCHAR(100) = NULL,
    @registration_case_type NVARCHAR(50), -- Loại trường hợp đăng ký (ví dụ: 'OwnedProperty')
    @supporting_document_info NVARCHAR(MAX) = NULL, -- Thông tin chi tiết tài liệu hỗ trợ

    -- Ghi chú chung cho các bản ghi
    @notes NVARCHAR(MAX) = NULL,
    @updated_by VARCHAR(50) = 'SYSTEM',

    -- Thông tin cho bảng CitizenStatus (nếu có thay đổi trạng thái kèm theo)
    @cs_description NVARCHAR(MAX) = NULL,
    @cs_cause NVARCHAR(200) = NULL,
    @cs_location NVARCHAR(200) = NULL,
    @cs_authority_id INT = NULL,
    @cs_document_number VARCHAR(50) = NULL,
    @cs_document_date DATE = NULL,
    @cs_certificate_id VARCHAR(50) = NULL,
    @cs_reported_by NVARCHAR(100) = NULL,
    @cs_relationship NVARCHAR(50) = NULL,
    @cs_verification_status NVARCHAR(50) = N'Đã xác minh',

    -- Thêm các tham số cho CitizenAddress (ÁNH XẠ TỪ SCHEMA)
    @ca_verification_status NVARCHAR(50) = N'Đã xác minh',
    @ca_verification_date DATE = NULL,
    @ca_verified_by NVARCHAR(100) = NULL,
    @ca_notes NVARCHAR(MAX) = NULL,

    -- Output parameter
    @new_residence_history_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Định nghĩa các ID tham chiếu cứng (dựa trên sample_data và structure scripts)
    DECLARE @residence_type_id_permanent_residence SMALLINT = 1; -- ID cho 'Thường trú'
    DECLARE @res_reg_status_id_active SMALLINT = 1;             -- ID cho 'Đang hiệu lực'
    DECLARE @citizen_status_id_alive SMALLINT = 1;              -- ID cho 'Còn sống'
    DECLARE @address_type_id_permanent_residence SMALLINT = 1;  -- ID cho 'Nơi thường trú'
    DECLARE @address_status_active BIT = 1;                     -- Trạng thái địa chỉ: Hoạt động

    DECLARE @current_address_id BIGINT;
    DECLARE @existing_address_id BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Xử lý địa chỉ: Tìm kiếm địa chỉ hiện có hoặc tạo mới
        SELECT @existing_address_id = address_id
        FROM [BCA].[Address]
        WHERE [address_detail] = @address_detail
          AND [ward_id] = @ward_id
          AND [district_id] = @district_id
          AND [province_id] = @province_id;

        IF @existing_address_id IS NOT NULL
        BEGIN
            SET @current_address_id = @existing_address_id;
            UPDATE [BCA].[Address]
            SET
                [postal_code] = ISNULL(@postal_code, [postal_code]),
                [latitude] = ISNULL(@latitude, [latitude]),
                [longitude] = ISNULL(@longitude, [longitude]),
                [updated_at] = SYSDATETIME(),
                [updated_by] = @updated_by
            WHERE [address_id] = @current_address_id;
        END
        ELSE
        BEGIN
            INSERT INTO [BCA].[Address] (
                [address_detail], [ward_id], [district_id], [province_id],
                [postal_code], [latitude], [longitude], [status], [notes],
                [created_by], [updated_by]
            )
            VALUES (
                @address_detail, @ward_id, @district_id, @province_id,
                @postal_code, @latitude, @longitude, @address_status_active, @notes, -- Sử dụng @notes chung cho địa chỉ mới
                @updated_by, @updated_by
            );
            SET @current_address_id = SCOPE_IDENTITY();
        END

        -- 2. Cập nhật bảng BCA.Citizen (primary_address_id)
        UPDATE [BCA].[Citizen]
        SET
            [primary_address_id] = @current_address_id,
            [updated_at] = SYSDATETIME(),
            [updated_by] = @updated_by
        WHERE [citizen_id] = @citizen_id;

        -- 3. Thêm bản ghi vào BCA.ResidenceHistory
        INSERT INTO [BCA].[ResidenceHistory] (
            [citizen_id], [address_id], [residence_type_id], [registration_date], [expiry_date],
            [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number],
            [ownership_certificate_id], [residence_status_change_reason_id], [document_url],
            [verification_status], [verification_date], [verified_by], [res_reg_status_id],
            [registration_case_type], [supporting_document_info], [notes],
            [created_at], [updated_at], [created_by], [updated_by]
        )
        VALUES (
            @citizen_id, @current_address_id, @residence_type_id_permanent_residence, @registration_date, @residence_expiry_date,
            ISNULL(@registration_reason, N'Đăng ký thường trú theo quyền sở hữu chỗ ở'), @previous_address_id, @issuing_authority_id, @registration_number,
            @ownership_certificate_id, @residence_status_change_reason_id, @document_url,
            @rh_verification_status, ISNULL(@rh_verification_date, SYSDATETIME()), @rh_verified_by, @res_reg_status_id_active,
            @registration_case_type, @supporting_document_info, @notes, -- Sử dụng @notes chung
            SYSDATETIME(), SYSDATETIME(), @updated_by, @updated_by
        );
        SET @new_residence_history_id = SCOPE_IDENTITY();

        -- 4. Cập nhật BCA.CitizenAddress
        UPDATE [BCA].[CitizenAddress]
        SET
            [is_primary] = 0,
            [is_permanent_residence] = 0,
            [to_date] = @registration_date,
            [status] = 0,
            [notes] = ISNULL(RTRIM([notes]) + N' | ', N'') + N'Chấm dứt do đăng ký thường trú mới.',
            [updated_at] = SYSDATETIME(),
            [updated_by] = @updated_by
        WHERE [citizen_id] = @citizen_id
          AND ([is_primary] = 1 OR [is_permanent_residence] = 1)
          AND [status] = 1;

        INSERT INTO [BCA].[CitizenAddress] (
            [citizen_id], [address_id], [address_type_id], [from_date], [to_date],
            [is_primary], [is_permanent_residence], [status],
            [registration_document_no], [registration_date], [issuing_authority_id],
            [verification_status], [verification_date], [verified_by], [notes],
            [related_residence_history_id],
            [created_at], [updated_at], [created_by], [updated_by]
        )
        VALUES (
            @citizen_id, @current_address_id, @address_type_id_permanent_residence, @registration_date, NULL,
            1, 1, 1, -- Là địa chỉ chính, thường trú, đang hoạt động
            @registration_number, @registration_date, @issuing_authority_id,
            @ca_verification_status, ISNULL(@ca_verification_date, SYSDATETIME()), @ca_verified_by, @ca_notes, -- Sử dụng các tham số @ca_...
            @new_residence_history_id,
            SYSDATETIME(), SYSDATETIME(), @updated_by, @updated_by
        );

        -- 5. Cập nhật trạng thái công dân trong BCA.CitizenStatus
        UPDATE [BCA].[CitizenStatus]
        SET [is_current] = 0,
            [updated_at] = SYSDATETIME(),
            [updated_by] = @updated_by
        WHERE [citizen_id] = @citizen_id
          AND [is_current] = 1;

        INSERT INTO [BCA].[CitizenStatus] (
            [citizen_id], [citizen_status_id], [status_date], [description], [cause], [location],
            [authority_id], [document_number], [document_date], [certificate_id],
            [reported_by], [relationship], [verification_status], [is_current], [notes],
            [created_at], [updated_at], [created_by], [updated_by]
        )
        VALUES (
            @citizen_id, @citizen_status_id_alive, @registration_date,
            ISNULL(@cs_description, N'Đăng ký thường trú mới tại ' + @address_detail), @cs_cause, @cs_location,
            @cs_authority_id, @cs_document_number, @cs_document_date, @cs_certificate_id,
            @cs_reported_by, @cs_relationship, @cs_verification_status, 1, @notes, -- Sử dụng @notes chung
            SYSDATETIME(), SYSDATETIME(), @updated_by, @updated_by
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

PRINT 'Stored Procedure [API_Internal].[RegisterPermanentResidence_OwnedProperty_DataOnly] đã được tạo/cập nhật thành công.';
GO


IF OBJECT_ID('[API_Internal].[MatchPropertyAndRegistrationAddress]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[MatchPropertyAndRegistrationAddress];
GO

PRINT N'Tạo Function [API_Internal].[MatchPropertyAndRegistrationAddress]...';
GO

CREATE FUNCTION [API_Internal].[MatchPropertyAndRegistrationAddress] (
    @gcnqs_property_address_id BIGINT, -- address_id của tài sản trên GCNQS
    @registration_address_detail NVARCHAR(MAX),
    @registration_ward_id INT,
    @registration_district_id INT,
    @registration_province_id INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @registration_address_id BIGINT;
    DECLARE @matchResult BIT;

    -- Bước 1: Tìm address_id cho địa chỉ đang đăng ký
    -- Cố gắng tìm một địa chỉ đã tồn tại khớp chính xác với thông tin đăng ký
    SELECT TOP 1 @registration_address_id = address_id
    FROM [BCA].[Address]
    WHERE 
        [address_detail] = @registration_address_detail
        AND [ward_id] = @registration_ward_id
        AND [district_id] = @registration_district_id
        AND [province_id] = @registration_province_id
    ORDER BY [address_id]; -- Lấy bản ghi cũ nhất nếu có nhiều bản ghi trùng (ít khả năng)

    -- Bước 2: So sánh
    -- Nếu không tìm thấy địa chỉ đăng ký trong bảng BCA.Address,
    -- điều đó có nghĩa là địa chỉ này sẽ là một địa chỉ mới được tạo bởi SP chính.
    -- Trong trường hợp này, nó không thể khớp với một @gcnqs_property_address_id đã có.
    -- Chỉ coi là khớp nếu cả hai address_id đều trỏ đến cùng một bản ghi trong BCA.Address.
    IF @registration_address_id IS NOT NULL AND @registration_address_id = @gcnqs_property_address_id
        SET @matchResult = 1; -- Khớp
    ELSE
        SET @matchResult = 0; -- Không khớp

    RETURN @matchResult;
END;
GO

PRINT 'Function [API_Internal].[MatchPropertyAndRegistrationAddress] đã được tạo thành công.';
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[GetHouseholdDetails]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[GetHouseholdDetails];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[GetHouseholdDetails]...';
GO

CREATE PROCEDURE [API_Internal].[GetHouseholdDetails]
    @household_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Lấy thông tin chi tiết Hộ khẩu
    SELECT
        h.[household_id],
        h.[household_book_no],
        h.[head_of_household_id],
        head_citizen.[full_name] AS head_of_household_full_name,
        a.[address_detail],
        w.[ward_name],
        d.[district_name],
        p.[province_name],
        h.[registration_date],
        auth.[authority_name] AS issuing_authority_name,
        ht.[household_type_name_vi] AS household_type_name,
        hs.[status_name_vi] AS household_status_name,
        h.[ownership_certificate_id],
        h.[rental_contract_id],
        h.[notes],
        h.[created_at],
        h.[updated_at]
    FROM
        [BCA].[Household] h
    INNER JOIN
        [BCA].[Citizen] head_citizen ON h.head_of_household_id = head_citizen.citizen_id
    INNER JOIN
        [BCA].[Address] a ON h.address_id = a.address_id
    INNER JOIN
        [Reference].[Wards] w ON a.ward_id = w.ward_id
    INNER JOIN
        [Reference].[Districts] d ON a.district_id = d.district_id
    INNER JOIN
        [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN
        [Reference].[Authorities] auth ON h.issuing_authority_id = auth.authority_id
    INNER JOIN
        [Reference].[HouseholdTypes] ht ON h.household_type_id = ht.household_type_id
    INNER JOIN
        [Reference].[HouseholdStatuses] hs ON h.household_status_id = hs.household_status_id
    WHERE
        h.[household_id] = @household_id;

    -- 2. Lấy danh sách thành viên trong hộ khẩu
    SELECT
        hm.[citizen_id],
        member_citizen.[full_name],
        rwh.[rel_name_vi] AS relationship_with_head,
        hm.[join_date],
        hms.[status_name_vi] AS member_status,
        member_citizen.[date_of_birth],
        g.[gender_name_vi] AS gender
        -- Thêm các trường khác của thành viên nếu cần thiết
    FROM
        [BCA].[HouseholdMember] hm
    INNER JOIN
        [BCA].[Citizen] member_citizen ON hm.citizen_id = member_citizen.citizen_id
    INNER JOIN
        [Reference].[RelationshipWithHeadTypes] rwh ON hm.rel_with_head_id = rwh.rel_with_head_id
    INNER JOIN
        [Reference].[HouseholdMemberStatuses] hms ON hm.member_status_id = hms.member_status_id
    LEFT JOIN
        [Reference].[Genders] g ON member_citizen.gender_id = g.gender_id
    WHERE
        hm.[household_id] = @household_id
    ORDER BY
        hm.[order_in_household] ASC, hm.[join_date] ASC;

END;
GO

PRINT 'Stored Procedure [API_Internal].[GetHouseholdDetails] đã được tạo thành công.';
GO
-- END OF MORE CODE

-- ... existing code ...
PRINT 'Stored Procedure [API_Internal].[GetHouseholdDetails] đã được tạo thành công.';
GO

-- ====================================================================================
-- Stored Procedure: AddHouseholdMember
-- Description: Thực hiện nghiệp vụ nhập hộ khẩu cho một công dân (chưa có hộ khẩu).
--              Bao gồm việc thêm thành viên, cập nhật địa chỉ chính, ghi lịch sử
--              cư trú và ghi nhật ký thay đổi trong một transaction.
-- Author: Gemini
-- Date: [Current Date]
-- ====================================================================================

IF OBJECT_ID('[API_Internal].[AddHouseholdMember]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[AddHouseholdMember];
GO

CREATE PROCEDURE [API_Internal].[AddHouseholdMember]
    -- Input parameters
    @citizen_id VARCHAR(12),
    @to_household_id BIGINT,
    @relationship_with_head_id SMALLINT,
    @effective_date DATE,
    @reason_id INT,
    @issuing_authority_id INT, -- Cơ quan cấp (cho lịch sử cư trú)
    @created_by_user_id NVARCHAR(100) = NULL,
    @notes NVARCHAR(500) = NULL,

    -- Output parameters
    @new_household_member_id BIGINT OUTPUT,
    @new_log_id INT OUTPUT,
    @new_residence_history_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Đảm bảo transaction sẽ rollback nếu có lỗi

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Lấy address_id từ hộ khẩu đích
        DECLARE @address_id BIGINT;
        SELECT @address_id = [address_id]
        FROM [BCA].[Household]
        WHERE [household_id] = @to_household_id;

        -- Nếu không tìm thấy hộ khẩu hoặc địa chỉ, gây ra lỗi để rollback
        IF @address_id IS NULL
        BEGIN
            THROW 50001, 'Hộ khẩu đích không tồn tại hoặc không có địa chỉ hợp lệ.', 1;
        END

        -- 2. Thêm thành viên mới vào hộ khẩu
        -- Giả định member_status_id = 1 là 'Đang cư trú'
        INSERT INTO [BCA].[HouseholdMember] (
            [household_id], [citizen_id], [rel_with_head_id], 
            [join_date], [member_status_id], [created_at], [updated_at]
        )
        VALUES (
            @to_household_id, @citizen_id, @relationship_with_head_id,
            @effective_date, 1, -- 1: 'Đang cư trú'
            GETDATE(), GETDATE()
        );
        SET @new_household_member_id = SCOPE_IDENTITY();

        -- 3. Cập nhật địa chỉ chính (primary_address_id) cho công dân
        UPDATE [BCA].[Citizen]
        SET [primary_address_id] = @address_id,
            [updated_at] = GETDATE()
        WHERE [citizen_id] = @citizen_id;

        -- 4. Ghi lịch sử cư trú mới
        -- Giả định residence_type_id = 1 là 'Thường trú'
        -- Giả định res_reg_status_id = 1 là 'Đang hiệu lực'
        INSERT INTO [BCA].[ResidenceHistory] (
            [citizen_id], [address_id], [residence_type_id], [registration_date],
            [registration_reason], [issuing_authority_id], [res_reg_status_id],
            [notes], [created_at], [updated_at]
        )
        VALUES (
            @citizen_id, @address_id, 1, @effective_date, -- 1: Thường trú
            N'Nhập hộ khẩu mới', @issuing_authority_id, 1, -- 1: Đang hiệu lực
            @notes, GETDATE(), GETDATE()
        );
        SET @new_residence_history_id = SCOPE_IDENTITY();

        -- 5. Ghi vào sổ nhật ký thay đổi hộ khẩu
        INSERT INTO [BCA].[HouseholdChangeLog] (
            [citizen_id], [reason_id], [from_household_id], [to_household_id],
            [effective_date], [notes], [created_by_user_id], [created_at]
        )
        VALUES (
            @citizen_id, @reason_id, NULL, @to_household_id,
            @effective_date, @notes, @created_by_user_id, GETDATE()
        );
        SET @new_log_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback toàn bộ transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Ném lại lỗi để tầng ứng dụng có thể bắt được
        THROW;
    END CATCH;
END;
GO

PRINT 'Stored Procedure [API_Internal].[AddHouseholdMember] đã được tạo thành công.';
GO

-- ====================================================================================
-- Stored Procedure: TransferHouseholdMember
-- Description: Thực hiện nghiệp vụ chuyển hộ khẩu cho một công dân (đang có hộ khẩu).
--              Bao gồm việc cắt khẩu cũ, nhập khẩu mới, cập nhật địa chỉ chính, 
--              ghi lịch sử cư trú và ghi nhật ký thay đổi trong một transaction.
-- Author: Gemini
-- Date: [Current Date]
-- ====================================================================================

IF OBJECT_ID('[API_Internal].[TransferHouseholdMember]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[TransferHouseholdMember];
GO

CREATE PROCEDURE [API_Internal].[TransferHouseholdMember]
    -- Input parameters
    @citizen_id VARCHAR(12),
    @from_household_id BIGINT,
    @to_household_id BIGINT,
    @relationship_with_head_id SMALLINT,
    @effective_date DATE,
    @reason_id INT,
    @issuing_authority_id INT, -- Cơ quan cấp (cho lịch sử cư trú)
    @created_by_user_id NVARCHAR(100) = NULL,
    @notes NVARCHAR(500) = NULL,

    -- Output parameters
    @old_household_member_id BIGINT OUTPUT,
    @new_household_member_id BIGINT OUTPUT,
    @new_log_id INT OUTPUT,
    @new_residence_history_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Đảm bảo transaction sẽ rollback nếu có lỗi

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Tìm bản ghi thành viên hiện tại trong hộ khẩu nguồn
        SELECT @old_household_member_id = [household_member_id]
        FROM [BCA].[HouseholdMember]
        WHERE [citizen_id] = @citizen_id 
          AND [household_id] = @from_household_id 
          AND [member_status_id] = 1; -- 1: ACTIVE (Đang cư trú)

        -- Nếu không tìm thấy thành viên trong hộ khẩu nguồn, gây ra lỗi
        IF @old_household_member_id IS NULL
        BEGIN
            THROW 50002, 'Không tìm thấy công dân trong hộ khẩu nguồn hoặc công dân không đang ở trạng thái cư trú.', 1;
        END

        -- 2. Lấy address_id từ hộ khẩu đích
        DECLARE @new_address_id BIGINT;
        SELECT @new_address_id = [address_id]
        FROM [BCA].[Household]
        WHERE [household_id] = @to_household_id;

        -- Nếu không tìm thấy hộ khẩu đích, gây ra lỗi
        IF @new_address_id IS NULL
        BEGIN
            THROW 50003, 'Hộ khẩu đích không tồn tại hoặc không có địa chỉ hợp lệ.', 1;
        END

        -- 3. Cắt khẩu cũ: Cập nhật trạng thái thành viên cũ thành "Đã chuyển đi"
        UPDATE [BCA].[HouseholdMember]
        SET [member_status_id] = 2, -- 2: LEFT (Đã chuyển đi)
            [leave_date] = @effective_date,
            [leave_reason] = N'Chuyển hộ khẩu',
            [updated_at] = GETDATE()
        WHERE [household_member_id] = @old_household_member_id;

        -- 4. Nhập khẩu mới: Thêm thành viên mới vào hộ khẩu đích
        INSERT INTO [BCA].[HouseholdMember] (
            [household_id], [citizen_id], [rel_with_head_id], 
            [join_date], [member_status_id], [previous_household_id],
            [created_at], [updated_at]
        )
        VALUES (
            @to_household_id, @citizen_id, @relationship_with_head_id,
            @effective_date, 1, @from_household_id, -- 1: ACTIVE (Đang cư trú)
            GETDATE(), GETDATE()
        );
        SET @new_household_member_id = SCOPE_IDENTITY();

        -- 5. Cập nhật địa chỉ chính (primary_address_id) cho công dân
        UPDATE [BCA].[Citizen]
        SET [primary_address_id] = @new_address_id,
            [updated_at] = GETDATE()
        WHERE [citizen_id] = @citizen_id;

        -- 6. Ghi lịch sử cư trú mới
        INSERT INTO [BCA].[ResidenceHistory] (
            [citizen_id], [address_id], [residence_type_id], [registration_date],
            [registration_reason], [issuing_authority_id], [res_reg_status_id],
            [notes], [created_at], [updated_at]
        )
        VALUES (
            @citizen_id, @new_address_id, 1, @effective_date, -- 1: THUONGTRU (Thường trú)
            N'Chuyển hộ khẩu', @issuing_authority_id, 1, -- 1: ACTIVE (Đang hiệu lực)
            @notes, GETDATE(), GETDATE()
        );
        SET @new_residence_history_id = SCOPE_IDENTITY();

        -- 7. Ghi vào sổ nhật ký thay đổi hộ khẩu
        INSERT INTO [BCA].[HouseholdChangeLog] (
            [citizen_id], [reason_id], [from_household_id], [to_household_id],
            [effective_date], [notes], [created_by_user_id], [created_at]
        )
        VALUES (
            @citizen_id, @reason_id, @from_household_id, @to_household_id,
            @effective_date, @notes, @created_by_user_id, GETDATE()
        );
        SET @new_log_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback toàn bộ transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Ném lại lỗi để tầng ứng dụng có thể bắt được
        THROW;
    END CATCH;
END;
GO

PRINT 'Stored Procedure [API_Internal].[TransferHouseholdMember] đã được tạo thành công.';
GO



IF OBJECT_ID('[API_Internal].[RemoveHouseholdMember]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[RemoveHouseholdMember];
GO

CREATE PROCEDURE [API_Internal].[RemoveHouseholdMember]
    -- Input parameters
    @household_id BIGINT,
    @citizen_id VARCHAR(12),
    @reason_id INT,
    @issuing_authority_id INT, -- Cơ quan cấp
    @created_by_user_id NVARCHAR(100) = NULL,
    @notes NVARCHAR(500) = NULL,

    -- Output parameters
    @removed_household_member_id BIGINT OUTPUT,
    @new_log_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Đảm bảo transaction sẽ rollback nếu có lỗi

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Tìm bản ghi thành viên hiện tại trong hộ khẩu
        SELECT @removed_household_member_id = [household_member_id]
        FROM [BCA].[HouseholdMember]
        WHERE [citizen_id] = @citizen_id 
          AND [household_id] = @household_id 
          AND [member_status_id] = 1; -- 1: ACTIVE (Đang cư trú)

        -- Nếu không tìm thấy thành viên trong hộ khẩu, gây ra lỗi
        IF @removed_household_member_id IS NULL
        BEGIN
            THROW 50001, 'Không tìm thấy công dân trong hộ khẩu hoặc công dân không đang ở trạng thái cư trú.', 1;
        END

        -- 2. Xóa mềm: Cập nhật trạng thái thành viên thành "Đã chuyển đi"
        UPDATE [BCA].[HouseholdMember]
        SET [member_status_id] = 2, -- 2: LEFT (Đã chuyển đi)
            [leave_date] = GETDATE(), -- Sử dụng ngày hiện tại làm effective_date
            [leave_reason] = N'Xóa khỏi hộ khẩu',
            [updated_at] = GETDATE()
        WHERE [household_member_id] = @removed_household_member_id;

        -- 3. Ghi vào sổ nhật ký thay đổi hộ khẩu
        INSERT INTO [BCA].[HouseholdChangeLog] (
            [citizen_id], [reason_id], [from_household_id], [to_household_id],
            [effective_date], [notes], [created_by_user_id], [created_at]
        )
        VALUES (
            @citizen_id, @reason_id, @household_id, NULL, -- to_household_id = NULL vì đây là xóa
            GETDATE(), @notes, @created_by_user_id, GETDATE()
        );
        SET @new_log_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback toàn bộ transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Ném lại lỗi để tầng ứng dụng có thể bắt được
        THROW;
    END CATCH;
END;
GO

PRINT 'Stored Procedure [API_Internal].[RemoveHouseholdMember] đã được tạo thành công.';
GO


IF OBJECT_ID('[API_Internal].[SearchCitizens]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[SearchCitizens];
GO

CREATE PROCEDURE [API_Internal].[SearchCitizens]
    @FullName NVARCHAR(255) = NULL,
    @DateOfBirth DATE = NULL,
    @Limit INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    -- Basic validation for limit to prevent fetching too much data
    IF @Limit IS NULL OR @Limit <= 0 OR @Limit > 100
    BEGIN
        SET @Limit = 20; -- Set to a default safe value
    END

    SELECT TOP (@Limit)
        c.[citizen_id],
        c.[full_name],
        c.[date_of_birth],
        g.[gender_name_vi] AS gender,
        ms.[marital_status_name_vi] AS marital_status,
        st.[status_name_vi] AS citizen_status,
        c.[spouse_citizen_id],

        -- Current Address Info
        a.[address_detail] AS current_address_detail,
        cw.[ward_name] AS current_ward_name,
        cd.[district_name] AS current_district_name,
        cp.[province_name] AS current_province_name
        
    FROM [BCA].[Citizen] c
    -- Joins for essential information
    LEFT JOIN [Reference].[Genders] g ON c.gender_id = g.gender_id
    LEFT JOIN [Reference].[MaritalStatuses] ms ON c.marital_status_id = ms.marital_status_id
    LEFT JOIN [Reference].[CitizenStatusTypes] st ON c.citizen_status_id = st.citizen_status_id
    -- Join for Current Address
    LEFT JOIN [BCA].[Address] a ON c.primary_address_id = a.address_id
    LEFT JOIN [Reference].[Wards] cw ON a.ward_id = cw.ward_id
    LEFT JOIN [Reference].[Districts] cd ON a.district_id = cd.district_id
    LEFT JOIN [Reference].[Provinces] cp ON a.province_id = cp.province_id

    WHERE
        -- Search logic: matches if parameters are NULL or if they match the citizen's data.
        -- Using LIKE for partial name matching with proper Unicode handling
        (@FullName IS NULL OR c.full_name LIKE N'%' + @FullName + N'%')
        AND (@DateOfBirth IS NULL OR c.date_of_birth = @DateOfBirth)
        -- Search for living citizens - flexible status check
        AND (st.status_code IN ('ALIVE', 'CONSONG') OR st.status_name_vi LIKE N'%Còn sống%')
    ORDER BY
        -- Order results by name for consistency
        c.full_name, c.date_of_birth;

END
GO
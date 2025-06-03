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

======================================================================================
======================================================================================



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

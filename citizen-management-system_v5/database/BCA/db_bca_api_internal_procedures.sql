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

USE [DB_BCA];
GO

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

---------------------------------------------------------------------------


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
GRANT EXECUTE ON [API_Internal].[GetReferenceTableData] TO [api_service_user];
GO

PRINT 'Stored procedure [API_Internal].[GetReferenceTableData] created successfully.';


/*
============================================================================================
============================================================================================
*/

USE [DB_BCA];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[UpdateCitizenDeathStatus_v2]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[UpdateCitizenDeathStatus_v2];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[UpdateCitizenDeathStatus_v2]...';
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
        -- IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id)
        -- BEGIN
        --     ROLLBACK TRANSACTION;
        --     RAISERROR('Công dân với ID cung cấp không tồn tại.', 16, 1);
        --     SELECT 0 AS affected_rows; RETURN;
        -- END

        -- Lấy thông tin người phối ngẫu hiện tại (nếu có) TRƯỚC KHI cập nhật người đã mất
        -- Chỉ lấy nếu tình trạng hôn nhân của người mất là 'Đã kết hôn'
        SELECT @current_spouse_id = [spouse_citizen_id]
        FROM [BCA].[Citizen]
        WHERE [citizen_id] = @citizen_id AND [marital_status_id] = @marital_status_id_married;

        -- 1. Cập nhật bảng [BCA].[Citizen]
        UPDATE [BCA].[Citizen]
        SET [citizen_status_id] = @citizen_status_id_deceased,
            [status_change_date] = @date_of_death,
            -- [marital_status_id] = CASE
            --                         WHEN [marital_status_id] = @marital_status_id_married THEN @marital_status_id_widowed
            --                         ELSE [marital_status_id] -- Giữ nguyên nếu không phải "Đã kết hôn"
            --                       END,
            -- [spouse_citizen_id] -- Giữ nguyên spouse_citizen_id của người đã mất để tham chiếu
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

PRINT 'Stored procedure [API_Internal].[UpdateCitizenDeathStatus_v2] đã được tạo/cập nhật thành công.';
GO
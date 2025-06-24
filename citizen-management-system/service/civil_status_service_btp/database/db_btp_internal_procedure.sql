USE [DB_BTP];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[InsertDeathCertificate]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertDeathCertificate];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[InsertDeathCertificate]...';
GO

-- Tạo Stored Procedure để thêm mới Giấy chứng tử
CREATE PROCEDURE [API_Internal].[InsertDeathCertificate]
    -- Input parameters matching BTP.DeathCertificate columns
    @citizen_id VARCHAR(12),
    @death_certificate_no VARCHAR(20),
    @book_id VARCHAR(20) = NULL,
    @page_no VARCHAR(10) = NULL,
    @date_of_death DATE,
    @time_of_death TIME = NULL,
    @place_of_death_detail NVARCHAR(MAX),
    @place_of_death_ward_id INT = NULL,
    @place_of_death_district_id INT = NULL,
    @place_of_death_province_id INT = NULL,
    @cause_of_death NVARCHAR(MAX) = NULL,
    @declarant_name NVARCHAR(100),
    @declarant_citizen_id VARCHAR(12) = NULL,
    @declarant_relationship NVARCHAR(50) = NULL,
    @registration_date DATE,
    @issuing_authority_id INT = NULL,
    @death_notification_no VARCHAR(50) = NULL,
    @witness1_name NVARCHAR(100) = NULL,
    @witness2_name NVARCHAR(100) = NULL,
    @notes NVARCHAR(MAX) = NULL,
    -- Output parameter for the new ID
    @new_death_certificate_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @citizen_id IS NULL OR 
       @death_certificate_no IS NULL OR 
       @date_of_death IS NULL OR 
       @place_of_death_detail IS NULL OR 
       @declarant_name IS NULL OR 
       @registration_date IS NULL
    BEGIN
        RAISERROR('Thiếu thông tin bắt buộc để đăng ký khai tử. Vui lòng cung cấp citizen_id, death_certificate_no, date_of_death, place_of_death_detail, declarant_name, registration_date.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Thực hiện INSERT vào bảng BTP.DeathCertificate
        INSERT INTO [BTP].[DeathCertificate] (
            [citizen_id], [death_certificate_no], [book_id], [page_no], [date_of_death],
            [time_of_death], [place_of_death_detail], [place_of_death_ward_id],
            [place_of_death_district_id], [place_of_death_province_id], [cause_of_death],
            [declarant_name], [declarant_citizen_id], [declarant_relationship],
            [registration_date], [issuing_authority_id], [death_notification_no],
            [witness1_name], [witness2_name], [status], [notes], [created_at], [updated_at]
        )
        VALUES (
            @citizen_id, @death_certificate_no, @book_id, @page_no, @date_of_death,
            @time_of_death, @place_of_death_detail, @place_of_death_ward_id,
            @place_of_death_district_id, @place_of_death_province_id, @cause_of_death,
            @declarant_name, @declarant_citizen_id, @declarant_relationship,
            @registration_date, @issuing_authority_id, @death_notification_no,
            @witness1_name, @witness2_name, 1, @notes, SYSDATETIME(), SYSDATETIME()
        );

        SET @new_death_certificate_id = SCOPE_IDENTITY();

        -- Thêm bản ghi vào PopulationChange
        DECLARE @pop_change_type_id_for_death INT = 2; -- 'Khai tử'

        INSERT INTO [BTP].[PopulationChange] (
            [citizen_id], [pop_change_type_id], [change_date], [reason],
            [related_document_no], [processing_authority_id], [status], [created_at], [updated_at]
        )
        VALUES (
            @citizen_id, @pop_change_type_id_for_death, @registration_date,
            N'Đăng ký khai tử theo giấy chứng tử số ' + @death_certificate_no,
            @death_certificate_no, @issuing_authority_id, 1, SYSDATETIME(), SYSDATETIME()
        );

        -- ==========================================================
        -- LOGIC MỚI: Cập nhật bảng BTP.FamilyRelationship theo CÁCH B
        -- ==========================================================
        -- Giả định các ID từ Reference.RelationshipTypes và Reference.FamilyRelationshipStatuses trong DB_BCA
        -- (Cần đảm bảo các ID này trùng khớp với dữ liệu thực tế)
        DECLARE @relationship_type_id_husband INT = 5;    -- ID cho 'Chồng'
        DECLARE @relationship_type_id_wife INT = 4;       -- ID cho 'Vợ'
        
        DECLARE @family_rel_status_id_active SMALLINT = 1;     -- 'Đang hiệu lực'
        DECLARE @family_rel_status_id_inactive SMALLINT = 2;   -- 'Không hiệu lực'
        -- Giả định thêm ID cho trạng thái "Bên liên quan đã mất". Nếu chưa có, cần thêm vào Reference.FamilyRelationshipStatuses
        -- Ví dụ: INSERT INTO [Reference].[FamilyRelationshipStatuses] ([family_rel_status_id], [status_code], [status_name_vi], [description_vi], [display_order]) VALUES (5, 'PARTY_DECEASED', N'Bên liên quan đã mất', N'Quan hệ mà một bên đã qua đời', 5);
        DECLARE @family_rel_status_id_party_deceased SMALLINT = 6; -- Giả định ID 5 cho trạng thái này

        -- Cập nhật mối quan hệ hôn nhân
        UPDATE FR
        SET
            FR.[end_date] = @date_of_death,
            FR.[family_rel_status_id] = @family_rel_status_id_inactive,
            FR.[notes] = ISNULL(RTRIM(FR.[notes]) + N' | ', N'') + N'Quan hệ hôn nhân chấm dứt do công dân ' + @citizen_id + N' qua đời vào ngày ' + CONVERT(NVARCHAR, @date_of_death, 103),
            FR.[updated_at] = SYSDATETIME()
        FROM [BTP].[FamilyRelationship] AS FR
        WHERE
            (FR.[citizen_id] = @citizen_id OR FR.[related_citizen_id] = @citizen_id)
            AND (FR.[relationship_type_id] = @relationship_type_id_husband OR FR.[relationship_type_id] = @relationship_type_id_wife)
            AND FR.[family_rel_status_id] = @family_rel_status_id_active -- Chỉ cập nhật các mối quan hệ đang hoạt động
            AND FR.[end_date] IS NULL; -- Đảm bảo chưa có ngày kết thúc

        -- Cập nhật mối quan hệ huyết thống và các mối quan hệ khác (không phải hôn nhân)
        UPDATE FR
        SET
            -- Không cập nhật end_date ở đây, vì mối quan hệ huyết thống là vĩnh viễn
            FR.[family_rel_status_id] = @family_rel_status_id_party_deceased,
            FR.[notes] = ISNULL(RTRIM(FR.[notes]) + N' | ', N'') + N'Bên liên quan (' + @citizen_id + N') qua đời vào ngày ' + CONVERT(NVARCHAR, @date_of_death, 103),
            FR.[updated_at] = SYSDATETIME()
        FROM [BTP].[FamilyRelationship] AS FR
        WHERE
            (FR.[citizen_id] = @citizen_id OR FR.[related_citizen_id] = @citizen_id)
            AND (FR.[relationship_type_id] NOT IN (@relationship_type_id_husband, @relationship_type_id_wife)) -- Không phải quan hệ hôn nhân
            AND FR.[family_rel_status_id] = @family_rel_status_id_active -- Chỉ cập nhật các mối quan hệ đang hoạt động
            AND FR.[end_date] IS NULL; -- Đảm bảo chưa có ngày kết thúc (chỉ áp dụng nếu có thể có end_date cho loại quan hệ này trong tương lai)

        -- ==========================================================
        -- KẾT THÚC LOGIC MỚI
        -- ==========================================================

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT 'Stored procedure [API_Internal].[InsertDeathCertificate] đã được tạo/cập nhật thành công.';
GO

-- Example of how to grant execute permission if needed (assuming api_service_user exists)
-- IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'api_service_user')
-- BEGIN
--     PRINT N'Cấp quyền EXECUTE cho [api_service_user] trên [API_Internal].[InsertDeathCertificate_v2]...';
--     GRANT EXECUTE ON [API_Internal].[InsertDeathCertificate_v2] TO [api_service_user];
-- END
-- GO

USE [DB_BTP];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[InsertMarriageCertificate]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertMarriageCertificate];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[InsertMarriageCertificate]...';
GO

-- Tạo Stored Procedure để đăng ký kết hôn
-- Lưu ý: Tất cả các logic nghiệp vụ phức tạp (ví dụ: kiểm tra tuổi, tình trạng hôn nhân trước đó,
-- quan hệ huyết thống thông qua việc gọi DB_BCA) được giả định đã xử lý ở tầng ứng dụng.
-- Stored procedure này tập trung vào việc ghi dữ liệu vào các bảng của DB_BTP.
CREATE PROCEDURE [API_Internal].[InsertMarriageCertificate]
    -- Thông tin giấy chứng nhận kết hôn
    @marriage_certificate_no VARCHAR(20),
    @book_id VARCHAR(20) = NULL,
    @page_no VARCHAR(10) = NULL,

    -- Thông tin chồng
    @husband_id VARCHAR(12),
    @husband_full_name NVARCHAR(100),
    @husband_date_of_birth DATE,
    @husband_nationality_id SMALLINT, -- FK logic tới DB_Reference.Reference.Nationalities
    @husband_previous_marital_status_id SMALLINT = NULL, -- FK logic tới DB_Reference.Reference.MaritalStatuses

    -- Thông tin vợ
    @wife_id VARCHAR(12),
    @wife_full_name NVARCHAR(100),
    @wife_date_of_birth DATE,
    @wife_nationality_id SMALLINT, -- FK logic tới DB_Reference.Reference.Nationalities
    @wife_previous_marital_status_id SMALLINT = NULL, -- FK logic tới DB_Reference.Reference.MaritalStatuses

    -- Thông tin đăng ký
    @marriage_date DATE,
    @registration_date DATE,
    @issuing_authority_id INT, -- FK logic tới DB_Reference.Reference.Authorities
    @issuing_place NVARCHAR(MAX),

    -- Thông tin bổ sung
    @witness1_name NVARCHAR(100) = NULL,
    @witness2_name NVARCHAR(100) = NULL,
    @notes NVARCHAR(MAX) = NULL,

    -- Output parameter
    @new_marriage_certificate_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra các tham số bắt buộc cơ bản
    IF @marriage_certificate_no IS NULL OR
       @husband_id IS NULL OR @husband_full_name IS NULL OR @husband_date_of_birth IS NULL OR @husband_nationality_id IS NULL OR
       @wife_id IS NULL OR @wife_full_name IS NULL OR @wife_date_of_birth IS NULL OR @wife_nationality_id IS NULL OR
       @marriage_date IS NULL OR @registration_date IS NULL OR @issuing_authority_id IS NULL OR @issuing_place IS NULL
    BEGIN
        RAISERROR('Thiếu thông tin bắt buộc để đăng ký kết hôn. Vui lòng kiểm tra lại các trường: marriage_certificate_no, thông tin vợ chồng (ID, tên, ngày sinh, quốc tịch), ngày kết hôn, ngày đăng ký, cơ quan cấp, nơi cấp.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        -- Bắt đầu transaction
        BEGIN TRANSACTION;

        -- Thực hiện INSERT vào bảng BTP.MarriageCertificate
        INSERT INTO [BTP].[MarriageCertificate] (
            [marriage_certificate_no], [book_id], [page_no],
            [husband_id], [husband_full_name], [husband_date_of_birth], [husband_nationality_id], [husband_previous_marital_status_id],
            [wife_id], [wife_full_name], [wife_date_of_birth], [wife_nationality_id], [wife_previous_marital_status_id],
            [marriage_date], [registration_date], [issuing_authority_id], [issuing_place],
            [witness1_name], [witness2_name], 
            [status], -- Mặc định là Valid (1)
            [notes],
            [created_at], 
            [updated_at]
        )
        VALUES (
            @marriage_certificate_no, @book_id, @page_no,
            @husband_id, @husband_full_name, @husband_date_of_birth, @husband_nationality_id, @husband_previous_marital_status_id,
            @wife_id, @wife_full_name, @wife_date_of_birth, @wife_nationality_id, @wife_previous_marital_status_id,
            @marriage_date, @registration_date, @issuing_authority_id, @issuing_place,
            @witness1_name, @witness2_name, 
            1, -- Status mặc định là Valid (hôn nhân có hiệu lực)
            @notes,
            SYSDATETIME(), -- created_at
            SYSDATETIME()  -- updated_at
        );

        -- Lấy ID của bản ghi vừa được chèn
        SET @new_marriage_certificate_id = SCOPE_IDENTITY();

        -- Thêm bản ghi vào PopulationChange cho chồng
        -- Giả sử pop_change_type_id cho 'Đăng ký kết hôn' là 3 (tham khảo từ sample_data.sql)
        DECLARE @pop_change_type_id_for_marriage INT = 3;

        INSERT INTO [BTP].[PopulationChange] (
            [citizen_id], 
            [pop_change_type_id], 
            [change_date], 
            [reason], 
            [related_document_no], 
            [processing_authority_id],
            [status],
            [created_at],
            [updated_at]
        )
        VALUES (
            @husband_id, 
            @pop_change_type_id_for_marriage, 
            @registration_date, 
            N'Đăng ký kết hôn với công dân có ID ' + @wife_id + N' theo giấy CNKH số ' + @marriage_certificate_no, 
            @marriage_certificate_no, 
            @issuing_authority_id,
            1,
            SYSDATETIME(),
            SYSDATETIME()
        );

        -- Thêm bản ghi vào PopulationChange cho vợ
        INSERT INTO [BTP].[PopulationChange] (
            [citizen_id], 
            [pop_change_type_id], 
            [change_date], 
            [reason], 
            [related_document_no], 
            [processing_authority_id],
            [status],
            [created_at],
            [updated_at]
        )
        VALUES (
            @wife_id, 
            @pop_change_type_id_for_marriage, 
            @registration_date, 
            N'Đăng ký kết hôn với công dân có ID ' + @husband_id + N' theo giấy CNKH số ' + @marriage_certificate_no, 
            @marriage_certificate_no, 
            @issuing_authority_id,
            1,
            SYSDATETIME(),
            SYSDATETIME()
        );

        -- ==========================================================
        -- LOGIC MỚI: Cập nhật bảng BTP.FamilyRelationship
        -- ==========================================================
        DECLARE @relationship_type_id_husband_rel INT = 5; -- ID cho 'Chồng' (theo sample_data của BCA)
        DECLARE @relationship_type_id_wife_rel SMALLINT = 4;    -- ID cho 'Vợ' (theo sample_data của BCA)
        DECLARE @family_rel_status_id_active SMALLINT = 1; -- Giả định ID cho trạng thái 'Active' là 1

        -- Chèn mối quan hệ Chồng -> Vợ
        INSERT INTO [BTP].[FamilyRelationship] (
            [citizen_id],
            [related_citizen_id],
            [relationship_type_id],
            [start_date],
            [family_rel_status_id],
            [document_proof],
            [document_no],
            [issuing_authority_id],
            [notes],
            [created_at],
            [updated_at]
        )
        VALUES (
            @husband_id,          -- citizen_id là Chồng
            @wife_id,             -- related_citizen_id là Vợ
            @relationship_type_id_husband_rel, -- Loại quan hệ là Chồng
            @marriage_date,       -- Ngày bắt đầu quan hệ (ngày kết hôn)
            @family_rel_status_id_active, -- Trạng thái hoạt động
            N'Giấy chứng nhận kết hôn', -- Giấy tờ chứng minh
            @marriage_certificate_no, -- Số giấy chứng nhận kết hôn
            @issuing_authority_id, -- Cơ quan cấp
            N'Quan hệ phát sinh từ đăng ký kết hôn',
            SYSDATETIME(),
            SYSDATETIME()
        );

        -- Chèn mối quan hệ đối ứng Vợ -> Chồng
        INSERT INTO [BTP].[FamilyRelationship] (
            [citizen_id],
            [related_citizen_id],
            [relationship_type_id],
            [start_date],
            [family_rel_status_id],
            [document_proof],
            [document_no],
            [issuing_authority_id],
            [notes],
            [created_at],
            [updated_at]
        )
        VALUES (
            @wife_id,             -- citizen_id là Vợ
            @husband_id,          -- related_citizen_id là Chồng
            @relationship_type_id_wife_rel, -- Loại quan hệ là Vợ
            @marriage_date,
            @family_rel_status_id_active,
            N'Giấy chứng nhận kết hôn',
            @marriage_certificate_no,
            @issuing_authority_id,
            N'Quan hệ phát sinh từ đăng ký kết hôn (đối ứng)',
            SYSDATETIME(),
            SYSDATETIME()
        );
        -- ==========================================================
        -- KẾT THÚC LOGIC MỚI
        -- ==========================================================

        -- Commit transaction nếu thành công
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Ném lại lỗi để tầng ứng dụng xử lý
        THROW;
    END CATCH
END;
GO

PRINT 'Stored procedure [API_Internal].[InsertMarriageCertificate] đã được tạo/cập nhật thành công.';
GO

-- Example of how to grant execute permission if needed (assuming api_service_user exists)
-- IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'api_service_user')
-- BEGIN
--     PRINT N'Cấp quyền EXECUTE cho [api_service_user] trên [API_Internal].[InsertMarriageCertificate_v2]...';
--     GRANT EXECUTE ON [API_Internal].[InsertMarriageCertificate_v2] TO [api_service_user];
-- END
-- GO


USE [DB_BTP];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[InsertDivorceRecord]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertDivorceRecord];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[InsertDivorceRecord]...';
GO

CREATE PROCEDURE [API_Internal].[InsertDivorceRecord]
    @divorce_certificate_no VARCHAR(20) = NULL,
    @book_id VARCHAR(20) = NULL,
    @page_no VARCHAR(10) = NULL,
    @marriage_certificate_id BIGINT,
    @divorce_date DATE,
    @registration_date DATE,
    @court_name NVARCHAR(200),
    @judgment_no VARCHAR(50),
    @judgment_date DATE,
    @issuing_authority_id INT = NULL,
    @reason NVARCHAR(MAX) = NULL,
    @child_custody NVARCHAR(MAX) = NULL,
    @property_division NVARCHAR(MAX) = NULL,
    @new_divorce_record_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Biến để lưu trữ citizen_id của chồng và vợ
    DECLARE @husband_id VARCHAR(12);
    DECLARE @wife_id VARCHAR(12);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Lấy husband_id và wife_id từ MarriageCertificate
        SELECT @husband_id = husband_id, @wife_id = wife_id
        FROM [BTP].[MarriageCertificate]
        WHERE marriage_certificate_id = @marriage_certificate_id;

        IF @husband_id IS NULL OR @wife_id IS NULL
        BEGIN
            RAISERROR('Không tìm thấy giấy chứng nhận kết hôn hoặc thông tin vợ/chồng không hợp lệ.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Thực hiện INSERT vào bảng BTP.DivorceRecord
        INSERT INTO [BTP].[DivorceRecord] (
            [divorce_certificate_no],
            [book_id],
            [page_no],
            [marriage_certificate_id],
            [divorce_date],
            [registration_date],
            [court_name],
            [judgment_no],
            [judgment_date],
            [issuing_authority_id],
            [reason],
            [child_custody],
            [property_division],
            [status], -- Mặc định là Valid (1)
            [notes],
            [created_at],
            [updated_at]
        )
        VALUES (
            @divorce_certificate_no,
            @book_id,
            @page_no,
            @marriage_certificate_id,
            @divorce_date,
            @registration_date,
            @court_name,
            @judgment_no,
            @judgment_date,
            @issuing_authority_id,
            @reason,
            @child_custody,
            @property_division,
            1, -- Status mặc định là Valid (giấy ly hôn có hiệu lực)
            NULL, -- Notes
            SYSDATETIME(),
            SYSDATETIME()
        );

        -- Lấy ID của bản ghi vừa được chèn
        SET @new_divorce_record_id = SCOPE_IDENTITY();

        -- 3. Cập nhật trạng thái của MarriageCertificate thành Dissolved (0)
        UPDATE [BTP].[MarriageCertificate]
        SET
            [status] = 0, -- 0 = Dissolved/Annulled
            [updated_at] = SYSDATETIME()
        WHERE
            [marriage_certificate_id] = @marriage_certificate_id;

        -- 4. Thêm bản ghi vào PopulationChange cho chồng
        -- Giả sử pop_change_type_id cho 'Ly hôn' là 4 (tham khảo từ sample_data)
        DECLARE @pop_change_type_id_for_divorce INT = 4;

        INSERT INTO [BTP].[PopulationChange] (
            [citizen_id],
            [pop_change_type_id],
            [change_date],
            [reason],
            [related_document_no],
            [processing_authority_id],
            [status],
            [created_at],
            [updated_at]
        )
        VALUES (
            @husband_id,
            @pop_change_type_id_for_divorce,
            @registration_date,
            N'Đăng ký ly hôn với công dân có ID ' + @wife_id + N' theo quyết định số ' + @judgment_no,
            @judgment_no,
            @issuing_authority_id,
            1, -- Status mặc định của bản ghi biến động
            SYSDATETIME(),
            SYSDATETIME()
        );

        -- 5. Thêm bản ghi vào PopulationChange cho vợ
        INSERT INTO [BTP].[PopulationChange] (
            [citizen_id],
            [pop_change_type_id],
            [change_date],
            [reason],
            [related_document_no],
            [processing_authority_id],
            [status],
            [created_at],
            [updated_at]
        )
        VALUES (
            @wife_id,
            @pop_change_type_id_for_divorce,
            @registration_date,
            N'Đăng ký ly hôn với công dân có ID ' + @husband_id + N' theo quyết định số ' + @judgment_no,
            @judgment_no,
            @issuing_authority_id,
            1, -- Status mặc định của bản ghi biến động
            SYSDATETIME(),
            SYSDATETIME()
        );

        -- ==========================================================
        -- LOGIC MỚI: Cập nhật bảng BTP.FamilyRelationship
        -- ==========================================================
        DECLARE @relationship_type_id_husband_rel SMALLINT = 5; -- ID cho 'Chồng'
        DECLARE @relationship_type_id_wife_rel SMALLINT = 4;    -- ID cho 'Vợ'
        DECLARE @family_rel_status_id_active SMALLINT = 1;     -- 'Đang hiệu lực'
        DECLARE @family_rel_status_id_inactive SMALLINT = 2;   -- 'Không hiệu lực'

        -- Cập nhật mối quan hệ Chồng -> Vợ
        UPDATE [BTP].[FamilyRelationship]
        SET
            [end_date] = @divorce_date, -- Ngày ly hôn là ngày kết thúc quan hệ
            [family_rel_status_id] = @family_rel_status_id_inactive, -- Chuyển sang trạng thái không hiệu lực
            [notes] = ISNULL(RTRIM([notes]) + N' | ', N'') + N'Quan hệ hôn nhân chấm dứt do ly hôn theo quyết định số ' + @judgment_no,
            [updated_at] = SYSDATETIME()
        WHERE
            [citizen_id] = @husband_id
            AND [related_citizen_id] = @wife_id
            AND [relationship_type_id] = @relationship_type_id_husband_rel
            AND [family_rel_status_id] = @family_rel_status_id_active;

        -- Cập nhật mối quan hệ đối ứng Vợ -> Chồng
        UPDATE [BTP].[FamilyRelationship]
        SET
            [end_date] = @divorce_date,
            [family_rel_status_id] = @family_rel_status_id_inactive,
            [notes] = ISNULL(RTRIM([notes]) + N' | ', N'') + N'Quan hệ hôn nhân chấm dứt do ly hôn theo quyết định số ' + @judgment_no,
            [updated_at] = SYSDATETIME()
        WHERE
            [citizen_id] = @wife_id
            AND [related_citizen_id] = @husband_id
            AND [relationship_type_id] = @relationship_type_id_wife_rel
            AND [family_rel_status_id] = @family_rel_status_id_active;
            
        -- ==========================================================
        -- KẾT THÚC LOGIC MỚI
        -- ==========================================================

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

PRINT 'Stored procedure [API_Internal].[InsertDivorceRecord] đã được tạo/cập nhật thành công.';
GO




USE [DB_BTP];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[InsertBirthCertificate]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertBirthCertificate];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[InsertBirthCertificate]...';
GO

-- Tạo Stored Procedure để thêm mới Giấy khai sinh
CREATE PROCEDURE [API_Internal].[InsertBirthCertificate]
    -- Input parameters matching BTP.BirthCertificate columns
    @citizen_id VARCHAR(12),
    @full_name NVARCHAR(100),
    @birth_certificate_no VARCHAR(20),
    @registration_date DATE,
    @book_id VARCHAR(20) = NULL,
    @page_no VARCHAR(10) = NULL,
    @issuing_authority_id INT,
    @place_of_birth NVARCHAR(MAX),
    @date_of_birth DATE,
    @gender_id SMALLINT,
    @father_full_name NVARCHAR(100) = NULL,
    @father_citizen_id VARCHAR(12) = NULL,
    @father_date_of_birth DATE = NULL,
    @father_nationality_id SMALLINT = NULL,
    @mother_full_name NVARCHAR(100) = NULL,
    @mother_citizen_id VARCHAR(12) = NULL,
    @mother_date_of_birth DATE = NULL,
    @mother_nationality_id SMALLINT = NULL,
    @declarant_name NVARCHAR(100),
    @declarant_citizen_id VARCHAR(12) = NULL,
    @declarant_relationship NVARCHAR(50) = NULL,
    @witness1_name NVARCHAR(100) = NULL,
    @witness2_name NVARCHAR(100) = NULL,
    @birth_notification_no VARCHAR(50) = NULL,
    @notes NVARCHAR(MAX) = NULL,
    -- Output parameter for the new ID
    @new_birth_certificate_id BIGINT OUTPUT
AS
BEGIN
    -- SET NOCOUNT ON để ngăn chặn thông báo số dòng bị ảnh hưởng
    SET NOCOUNT ON;

    -- Kiểm tra các tham số bắt buộc cơ bản
    IF @citizen_id IS NULL OR 
       @full_name IS NULL OR 
       @birth_certificate_no IS NULL OR 
       @registration_date IS NULL OR 
       @issuing_authority_id IS NULL OR 
       @place_of_birth IS NULL OR 
       @date_of_birth IS NULL OR 
       @gender_id IS NULL OR 
       @declarant_name IS NULL
    BEGIN
        RAISERROR('Thiếu thông tin bắt buộc để đăng ký khai sinh. Vui lòng cung cấp citizen_id, full_name, birth_certificate_no, registration_date, issuing_authority_id, place_of_birth, date_of_birth, gender_id, declarant_name.', 16, 1);
        RETURN; -- Kết thúc procedure
    END

    -- Bắt đầu khối TRY để xử lý lỗi
    BEGIN TRY
        -- Bắt đầu transaction
        BEGIN TRANSACTION;

        -- Thực hiện INSERT vào bảng BTP.BirthCertificate
        INSERT INTO [BTP].[BirthCertificate] (
            [citizen_id],
            [full_name],
            [birth_certificate_no],
            [registration_date],
            [book_id],
            [page_no],
            [issuing_authority_id],
            [place_of_birth],
            [date_of_birth],
            [gender_id],
            [father_full_name],
            [father_citizen_id],
            [father_date_of_birth],
            [father_nationality_id],
            [mother_full_name],
            [mother_citizen_id],
            [mother_date_of_birth],
            [mother_nationality_id],
            [declarant_name],
            [declarant_citizen_id],
            [declarant_relationship],
            [witness1_name],
            [witness2_name],
            [birth_notification_no],
            [status], -- Mặc định là Active (1)
            [notes],
            [created_at],
            [updated_at]
        )
        VALUES (
            @citizen_id,
            @full_name,
            @birth_certificate_no,
            @registration_date,
            @book_id,
            @page_no,
            @issuing_authority_id,
            @place_of_birth,
            @date_of_birth,
            @gender_id,
            @father_full_name,
            @father_citizen_id,
            @father_date_of_birth,
            @father_nationality_id,
            @mother_full_name,
            @mother_citizen_id,
            @mother_date_of_birth,
            @mother_nationality_id,
            @declarant_name,
            @declarant_citizen_id,
            @declarant_relationship,
            @witness1_name,
            @witness2_name,
            @birth_notification_no,
            1, -- Status mặc định là Active
            @notes,
            SYSDATETIME(), -- created_at
            SYSDATETIME()  -- updated_at
        );

        -- Lấy ID của bản ghi vừa được chèn
        SET @new_birth_certificate_id = SCOPE_IDENTITY();

        -- Thêm bản ghi vào PopulationChange
        -- pop_change_type_id cho 'Khai sinh' là 1 (tham khảo từ sample_data.sql)
        DECLARE @pop_change_type_id_for_birth INT = 1;

        INSERT INTO [BTP].[PopulationChange] (
            [citizen_id], 
            [pop_change_type_id], 
            [change_date], 
            [reason], 
            [related_document_no], 
            [processing_authority_id],
            [status],
            [created_at],
            [updated_at]
        )
        VALUES (
            @citizen_id, 
            @pop_change_type_id_for_birth, -- Loại biến động: Khai sinh
            @registration_date, 
            N'Đăng ký khai sinh theo giấy khai sinh số ' + @birth_certificate_no, 
            @birth_certificate_no, 
            @issuing_authority_id,
            1, -- Status mặc định của bản ghi biến động
            SYSDATETIME(),
            SYSDATETIME()
        );

        -- ==========================================================
        -- LOGIC MỚI: Cập nhật bảng BTP.FamilyRelationship
        -- ==========================================================
        DECLARE @relationship_type_id_father INT;
        DECLARE @relationship_type_id_mother INT;
        DECLARE @relationship_type_id_child INT;
        DECLARE @family_rel_status_id_active SMALLINT = 1; -- Giả định ID cho trạng thái 'Active' là 1
        
        
        SET @relationship_type_id_father = 1; -- ID cho 'Cha'
        SET @relationship_type_id_mother = 2; -- ID cho 'Mẹ'
        SET @relationship_type_id_child = 3;  -- ID cho 'Con'

        -- Mối quan hệ Cha-Con
        IF @father_citizen_id IS NOT NULL
        BEGIN
            -- Chèn mối quan hệ Cha -> Con
            INSERT INTO [BTP].[FamilyRelationship] (
                [citizen_id],
                [related_citizen_id],
                [relationship_type_id],
                [start_date],
                [family_rel_status_id],
                [document_proof],
                [document_no],
                [issuing_authority_id],
                [notes],
                [created_at],
                [updated_at]
            )
            VALUES (
                @father_citizen_id,          -- citizen_id là Cha
                @citizen_id,                 -- related_citizen_id là Con
                @relationship_type_id_father, -- Loại quan hệ là Cha
                @registration_date,          -- Ngày bắt đầu quan hệ (ngày đăng ký khai sinh)
                @family_rel_status_id_active, -- Trạng thái hoạt động
                N'Giấy khai sinh',           -- Giấy tờ chứng minh
                @birth_certificate_no,       -- Số giấy khai sinh
                @issuing_authority_id,       -- Cơ quan cấp
                N'Quan hệ phát sinh từ đăng ký khai sinh',
                SYSDATETIME(),
                SYSDATETIME()
            );

            -- Chèn mối quan hệ đối ứng Con -> Cha
            INSERT INTO [BTP].[FamilyRelationship] (
                [citizen_id],
                [related_citizen_id],
                [relationship_type_id],
                [start_date],
                [family_rel_status_id],
                [document_proof],
                [document_no],
                [issuing_authority_id],
                [notes],
                [created_at],
                [updated_at]
            )
            VALUES (
                @citizen_id,                 -- citizen_id là Con
                @father_citizen_id,          -- related_citizen_id là Cha
                @relationship_type_id_child,  -- Loại quan hệ là Con
                @registration_date,
                @family_rel_status_id_active,
                N'Giấy khai sinh',
                @birth_certificate_no,
                @issuing_authority_id,
                N'Quan hệ phát sinh từ đăng ký khai sinh (đối ứng)',
                SYSDATETIME(),
                SYSDATETIME()
            );
        END;

        -- Mối quan hệ Mẹ-Con
        IF @mother_citizen_id IS NOT NULL
        BEGIN
            -- Chèn mối quan hệ Mẹ -> Con
            INSERT INTO [BTP].[FamilyRelationship] (
                [citizen_id],
                [related_citizen_id],
                [relationship_type_id],
                [start_date],
                [family_rel_status_id],
                [document_proof],
                [document_no],
                [issuing_authority_id],
                [notes],
                [created_at],
                [updated_at]
            )
            VALUES (
                @mother_citizen_id,          -- citizen_id là Mẹ
                @citizen_id,                 -- related_citizen_id là Con
                @relationship_type_id_mother, -- Loại quan hệ là Mẹ
                @registration_date,
                @family_rel_status_id_active,
                N'Giấy khai sinh',
                @birth_certificate_no,
                @issuing_authority_id,
                N'Quan hệ phát sinh từ đăng ký khai sinh',
                SYSDATETIME(),
                SYSDATETIME()
            );

            -- Chèn mối quan hệ đối ứng Con -> Mẹ
            INSERT INTO [BTP].[FamilyRelationship] (
                [citizen_id],
                [related_citizen_id],
                [relationship_type_id],
                [start_date],
                [family_rel_status_id],
                [document_proof],
                [document_no],
                [issuing_authority_id],
                [notes],
                [created_at],
                [updated_at]
            )
            VALUES (
                @citizen_id,                 -- citizen_id là Con
                @mother_citizen_id,          -- related_citizen_id là Mẹ
                @relationship_type_id_child,  -- Loại quan hệ là Con
                @registration_date,
                @family_rel_status_id_active,
                N'Giấy khai sinh',
                @birth_certificate_no,
                @issuing_authority_id,
                N'Quan hệ phát sinh từ đăng ký khai sinh (đối ứng)',
                SYSDATETIME(),
                SYSDATETIME()
            );
        END;
        -- ==========================================================
        -- KẾT THÚC LOGIC MỚI
        -- ==========================================================

        -- Commit transaction nếu thành công
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Nếu có lỗi, rollback transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Ném lại lỗi để tầng ứng dụng xử lý
        THROW;
    END CATCH
END;
GO

PRINT 'Stored procedure [API_Internal].[InsertBirthCertificate] đã được tạo/cập nhật thành công.';
GO


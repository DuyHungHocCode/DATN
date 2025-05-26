USE [DB_BTP];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[InsertDeathCertificate_v2]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertDeathCertificate_v2];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[InsertDeathCertificate_v2]...';
GO

-- Tạo Stored Procedure để thêm mới Giấy chứng tử
-- Lưu ý: Các logic nghiệp vụ phức tạp, bao gồm cả việc lấy place_of_death_district_id và place_of_death_province_id
-- từ place_of_death_ward_id (nếu ward_id thuộc DB khác), được giả định đã xử lý ở tầng ứng dụng.
-- Stored procedure này tập trung vào việc ghi dữ liệu vào các bảng của DB_BTP.
CREATE PROCEDURE [API_Internal].[InsertDeathCertificate_v2]
    -- Input parameters matching BTP.DeathCertificate columns
    @citizen_id VARCHAR(12),
    @death_certificate_no VARCHAR(20),
    @book_id VARCHAR(20) = NULL,
    @page_no VARCHAR(10) = NULL,
    @date_of_death DATE,
    @time_of_death TIME = NULL,
    @place_of_death_detail NVARCHAR(MAX),
    @place_of_death_ward_id INT = NULL,        -- ID Phường/Xã nơi mất (FK logic tới DB_Reference/DB_BCA)
    @place_of_death_district_id INT = NULL,  -- ID Quận/Huyện nơi mất (FK logic tới DB_Reference/DB_BCA, ứng dụng tự điền)
    @place_of_death_province_id INT = NULL,  -- ID Tỉnh/Thành phố nơi mất (FK logic tới DB_Reference/DB_BCA, ứng dụng tự điền)
    @cause_of_death NVARCHAR(MAX) = NULL,
    @declarant_name NVARCHAR(100),
    @declarant_citizen_id VARCHAR(12) = NULL, -- ID CCCD/CMND người khai
    @declarant_relationship NVARCHAR(50) = NULL,
    @registration_date DATE,
    @issuing_authority_id INT = NULL,        -- ID cơ quan đăng ký (FK logic tới DB_Reference/DB_BCA)
    @death_notification_no VARCHAR(50) = NULL,
    @witness1_name NVARCHAR(100) = NULL,
    @witness2_name NVARCHAR(100) = NULL,
    @notes NVARCHAR(MAX) = NULL,
    -- Output parameter for the new ID
    @new_death_certificate_id BIGINT OUTPUT
AS
BEGIN
    -- SET NOCOUNT ON để ngăn chặn thông báo số dòng bị ảnh hưởng
    SET NOCOUNT ON;

    -- Kiểm tra các tham số bắt buộc cơ bản
    IF @citizen_id IS NULL OR 
       @death_certificate_no IS NULL OR 
       @date_of_death IS NULL OR 
       @place_of_death_detail IS NULL OR 
       @declarant_name IS NULL OR 
       @registration_date IS NULL
    BEGIN
        RAISERROR('Thiếu thông tin bắt buộc để đăng ký khai tử. Vui lòng cung cấp citizen_id, death_certificate_no, date_of_death, place_of_death_detail, declarant_name, registration_date.', 16, 1);
        RETURN; -- Kết thúc procedure
    END

    -- Bắt đầu khối TRY để xử lý lỗi
    BEGIN TRY
        -- Bắt đầu transaction
        BEGIN TRANSACTION;

        -- Thực hiện INSERT vào bảng BTP.DeathCertificate
        INSERT INTO [BTP].[DeathCertificate] (
            [citizen_id],
            [death_certificate_no],
            [book_id],
            [page_no],
            [date_of_death],
            [time_of_death],
            [place_of_death_detail],
            [place_of_death_ward_id],
            [place_of_death_district_id], -- Được cung cấp từ ứng dụng
            [place_of_death_province_id], -- Được cung cấp từ ứng dụng
            [cause_of_death],
            [declarant_name],
            [declarant_citizen_id],
            [declarant_relationship],
            [registration_date],
            [issuing_authority_id],
            [death_notification_no],
            [witness1_name],
            [witness2_name],
            [status], -- Mặc định là Active (1)
            [notes],
            [created_at],
            [updated_at]
        )
        VALUES (
            @citizen_id,
            @death_certificate_no,
            @book_id,
            @page_no,
            @date_of_death,
            @time_of_death,
            @place_of_death_detail,
            @place_of_death_ward_id,
            @place_of_death_district_id, -- Sử dụng giá trị từ tham số
            @place_of_death_province_id, -- Sử dụng giá trị từ tham số
            @cause_of_death,
            @declarant_name,
            @declarant_citizen_id,
            @declarant_relationship,
            @registration_date,
            @issuing_authority_id,
            @death_notification_no,
            @witness1_name,
            @witness2_name,
            1, -- Status mặc định là Active
            @notes,
            SYSDATETIME(), -- created_at
            SYSDATETIME()  -- updated_at
        );

        -- Lấy ID của bản ghi vừa được chèn
        SET @new_death_certificate_id = SCOPE_IDENTITY();

        -- Thêm bản ghi vào PopulationChange
        -- Giả sử pop_change_type_id cho 'Đăng ký khai tử' được ứng dụng xác định và truyền vào,
        -- hoặc có một cơ chế khác để lấy ID này. Trong ví dụ này, ta sử dụng một giá trị cố định (ví dụ 2)
        -- hoặc ứng dụng sẽ phải cung cấp pop_change_type_id.
        -- Trong file sample_data.sql, 'Khai tử' có pop_change_type_id là 2.
        DECLARE @pop_change_type_id_for_death INT = 2; -- ID cho 'Đăng ký khai tử' (tham khảo từ sample_data)

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
            @pop_change_type_id_for_death, -- Loại biến động: Đăng ký khai tử
            @registration_date, 
            N'Đăng ký khai tử theo giấy chứng tử số ' + @death_certificate_no, 
            @death_certificate_no, 
            @issuing_authority_id,
            1, -- Status mặc định của bản ghi biến động
            SYSDATETIME(),
            SYSDATETIME()
        );

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

PRINT 'Stored procedure [API_Internal].[InsertDeathCertificate_v2] đã được tạo/cập nhật thành công.';
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
IF OBJECT_ID('[API_Internal].[InsertMarriageCertificate_v2]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertMarriageCertificate_v2];
GO

PRINT N'Tạo Stored Procedure [API_Internal].[InsertMarriageCertificate_v2]...';
GO

-- Tạo Stored Procedure để đăng ký kết hôn
-- Lưu ý: Tất cả các logic nghiệp vụ phức tạp (ví dụ: kiểm tra tuổi, tình trạng hôn nhân trước đó,
-- quan hệ huyết thống thông qua việc gọi DB_BCA) được giả định đã xử lý ở tầng ứng dụng.
-- Stored procedure này tập trung vào việc ghi dữ liệu vào các bảng của DB_BTP.
CREATE PROCEDURE [API_Internal].[InsertMarriageCertificate_v2]
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

PRINT 'Stored procedure [API_Internal].[InsertMarriageCertificate_v2] đã được tạo/cập nhật thành công.';
GO

-- Example of how to grant execute permission if needed (assuming api_service_user exists)
-- IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'api_service_user')
-- BEGIN
--     PRINT N'Cấp quyền EXECUTE cho [api_service_user] trên [API_Internal].[InsertMarriageCertificate_v2]...';
--     GRANT EXECUTE ON [API_Internal].[InsertMarriageCertificate_v2] TO [api_service_user];
-- END
-- GO



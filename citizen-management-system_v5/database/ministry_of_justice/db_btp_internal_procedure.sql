USE [DB_BTP];
GO

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('[API_Internal].[InsertDeathCertificate]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[InsertDeathCertificate];
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
    -- SET NOCOUNT ON để ngăn chặn thông báo số dòng bị ảnh hưởng
    SET NOCOUNT ON;

    -- Kiểm tra các tham số bắt buộc (có thể thêm logic kiểm tra phức tạp hơn nếu cần)
    IF @citizen_id IS NULL OR @death_certificate_no IS NULL OR @date_of_death IS NULL OR @place_of_death_detail IS NULL OR @declarant_name IS NULL OR @registration_date IS NULL
    BEGIN
        -- Raiserror để báo lỗi nếu thiếu thông tin bắt buộc
        RAISERROR('Thiếu thông tin bắt buộc để đăng ký khai tử.', 16, 1);
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
            -- Suy luận district_id và province_id từ ward_id nếu có
            [place_of_death_district_id],
            [place_of_death_province_id],
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
            [created_at], -- Tự động lấy giờ hệ thống
            [updated_at]  -- Tự động lấy giờ hệ thống
        )
        SELECT
            @citizen_id,
            @death_certificate_no,
            @book_id,
            @page_no,
            @date_of_death,
            @time_of_death,
            @place_of_death_detail,
            @place_of_death_ward_id,
            -- Lấy district_id và province_id từ Reference.Wards
            (SELECT w.district_id FROM [Reference].[Wards] w WHERE w.ward_id = @place_of_death_ward_id),
            (SELECT d.province_id FROM [Reference].[Districts] d JOIN [Reference].[Wards] w ON d.district_id = w.district_id WHERE w.ward_id = @place_of_death_ward_id),
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
        ;

        -- Lấy ID của bản ghi vừa được chèn
        SET @new_death_certificate_id = SCOPE_IDENTITY();

        -- Thêm bản ghi vào PopulationChange
        INSERT INTO [BTP].[PopulationChange]
            ([citizen_id], [change_type], [change_date], [reason], 
            [related_document_no], [processing_authority_id])
        VALUES
            (@citizen_id, N'Đăng ký khai tử', @registration_date, 
            N'Khai tử theo giấy chứng tử ' + @death_certificate_no, 
            @death_certificate_no, @issuing_authority_id);

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

-- Cấp quyền thực thi cho user/role của API service (ví dụ: api_service_user)
-- Quyền này đã được cấp trên toàn schema API_Internal trong file 01_roles_permission.sql
-- GRANT EXECUTE ON [API_Internal].[InsertDeathCertificate] TO [api_service_user];
-- GO

PRINT 'Stored procedure [API_Internal].[InsertDeathCertificate] đã được tạo thành công.';
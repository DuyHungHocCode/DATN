-- Stored Procedure: Xác minh mối quan hệ với chủ hộ
-- File: sp_validate_household_relationship.sql
-- Thực hiện validation 3 cấp độ: Data Integrity -> Business Logic -> Genealogical Cross-Check

USE [DB_BCA];
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ValidateHouseholdRelationship')
    DROP PROCEDURE [API_Internal].[ValidateHouseholdRelationship];
GO

CREATE PROCEDURE [API_Internal].[ValidateHouseholdRelationship]
    @citizen_id VARCHAR(12),
    @to_household_id INT,
    @relationship_with_head_id SMALLINT,
    @validation_result BIT OUTPUT,           -- 1 = Pass, 0 = Fail
    @error_code VARCHAR(20) OUTPUT,          -- Mã lỗi để frontend xử lý
    @error_message NVARCHAR(500) OUTPUT,     -- Thông báo lỗi chi tiết
    @warning_message NVARCHAR(500) OUTPUT    -- Cảnh báo (nếu có)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Khởi tạo output parameters
    SET @validation_result = 0;
    SET @error_code = NULL;
    SET @error_message = NULL;
    SET @warning_message = NULL;
    
    -- Variables for validation logic
    DECLARE @head_of_household_id VARCHAR(12);
    DECLARE @head_gender_id SMALLINT;
    DECLARE @head_marital_status_id SMALLINT;
    DECLARE @citizen_gender_id SMALLINT;
    DECLARE @citizen_marital_status_id SMALLINT;
    DECLARE @citizen_father_id VARCHAR(12);
    DECLARE @citizen_mother_id VARCHAR(12);
    DECLARE @citizen_spouse_id VARCHAR(12);
    DECLARE @head_father_id VARCHAR(12);
    DECLARE @head_mother_id VARCHAR(12);
    DECLARE @head_spouse_id VARCHAR(12);
    DECLARE @citizen_birth_date DATE;
    DECLARE @head_birth_date DATE;
    DECLARE @relationship_code VARCHAR(30);
    DECLARE @relationship_name NVARCHAR(50);
    DECLARE @existing_spouse_count INT;
    
    BEGIN TRY
        -- ================================================================
        -- CẤP ĐỘ 1: DATA INTEGRITY CHECK
        -- ================================================================
        
        -- Kiểm tra relationship_with_head_id có tồn tại và active
        SELECT @relationship_code = rel_code, @relationship_name = rel_name_vi
        FROM [Reference].[RelationshipWithHeadTypes]
        WHERE rel_with_head_id = @relationship_with_head_id 
          AND is_active = 1;
        
        IF @relationship_code IS NULL
        BEGIN
            SET @error_code = 'INVALID_RELATIONSHIP_ID';
            SET @error_message = N'Mã quan hệ với chủ hộ không hợp lệ.';
            RETURN;
        END
        
        -- Kiểm tra household có tồn tại và active
        SELECT @head_of_household_id = head_of_household_id
        FROM [BCA].[Household]
        WHERE household_id = @to_household_id 
          AND household_status_id IN (SELECT household_status_id 
                                     FROM [Reference].[HouseholdStatuses] 
                                     WHERE status_code = 'DANGHOATDONG');
        
        IF @head_of_household_id IS NULL
        BEGIN
            SET @error_code = 'INVALID_HOUSEHOLD';
            SET @error_message = N'Hộ khẩu không tồn tại hoặc không hoạt động.';
            RETURN;
        END
        
        -- Kiểm tra citizen có tồn tại
        SELECT @citizen_gender_id = gender_id,
               @citizen_marital_status_id = marital_status_id,
               @citizen_father_id = father_citizen_id,
               @citizen_mother_id = mother_citizen_id,
               @citizen_spouse_id = spouse_citizen_id,
               @citizen_birth_date = date_of_birth
        FROM [BCA].[Citizen]
        WHERE citizen_id = @citizen_id;
        
        IF @citizen_gender_id IS NULL
        BEGIN
            SET @error_code = 'INVALID_CITIZEN';
            SET @error_message = N'Công dân không tồn tại trong hệ thống.';
            RETURN;
        END
        
        -- Lấy thông tin chủ hộ
        SELECT @head_gender_id = gender_id,
               @head_marital_status_id = marital_status_id,
               @head_father_id = father_citizen_id,
               @head_mother_id = mother_citizen_id,
               @head_spouse_id = spouse_citizen_id,
               @head_birth_date = date_of_birth
        FROM [BCA].[Citizen]
        WHERE citizen_id = @head_of_household_id;
        
        -- ================================================================
        -- CẤP ĐỘ 2: BUSINESS LOGIC CHECK
        -- ================================================================
        
        -- Quy tắc 1: Một chủ hộ duy nhất
        IF @relationship_code = 'CHUHO'
        BEGIN
            SET @error_code = 'DUPLICATE_HEAD_OF_HOUSEHOLD';
            SET @error_message = N'Mỗi hộ khẩu chỉ có một chủ hộ duy nhất.';
            RETURN;
        END
        
        -- Quy tắc 2: Một vợ/chồng duy nhất
        IF @relationship_code IN ('VO', 'CHONG')
        BEGIN
            -- Kiểm tra đã có vợ/chồng trong hộ khẩu chưa
            SELECT @existing_spouse_count = COUNT(*)
            FROM [BCA].[HouseholdMember] hm
            INNER JOIN [Reference].[RelationshipWithHeadTypes] rwh 
                ON hm.rel_with_head_id = rwh.rel_with_head_id
            INNER JOIN [Reference].[HouseholdMemberStatuses] hms 
                ON hm.member_status_id = hms.member_status_id
            WHERE hm.household_id = @to_household_id
              AND rwh.rel_code IN ('VO', 'CHONG')
              AND hms.status_code = 'ACTIVE';
            
            IF @existing_spouse_count > 0
            BEGIN
                SET @error_code = 'DUPLICATE_SPOUSE';
                SET @error_message = N'Hộ khẩu đã có vợ/chồng của chủ hộ.';
                RETURN;
            END
        END
        
        -- Quy tắc 3: Giới tính phù hợp
        IF @relationship_code = 'CHONG' AND @head_gender_id = (SELECT gender_id FROM [Reference].[Genders] WHERE gender_code = 'NAM')
        BEGIN
            SET @error_code = 'INVALID_GENDER_RELATIONSHIP';
            SET @error_message = N'Chủ hộ nam không thể có quan hệ "Chồng".';
            RETURN;
        END
        
        IF @relationship_code = 'VO' AND @head_gender_id = (SELECT gender_id FROM [Reference].[Genders] WHERE gender_code = 'NU')
        BEGIN
            SET @error_code = 'INVALID_GENDER_RELATIONSHIP';
            SET @error_message = N'Chủ hộ nữ không thể có quan hệ "Vợ".';
            RETURN;
        END
        
        -- ================================================================
        -- CẤP ĐỘ 3: GENEALOGICAL & MARITAL STATUS CROSS-CHECK
        -- ================================================================
        
        -- Kiểm tra quan hệ Con - Cha/Mẹ
        IF @relationship_code = 'CON'
        BEGIN
            IF NOT (@citizen_father_id = @head_of_household_id OR @citizen_mother_id = @head_of_household_id)
            BEGIN
                SET @warning_message = N'Cảnh báo: Mối quan hệ "Con" không khớp với dữ liệu hộ tịch đã đăng ký (father_citizen_id/mother_citizen_id).';
            END
            
            -- Kiểm tra tuổi tác hợp lý (con phải nhỏ tuổi hơn)
            IF @citizen_birth_date <= @head_birth_date
            BEGIN
                SET @warning_message = ISNULL(@warning_message + N' ', N'') + N'Cảnh báo: Tuổi tác không hợp lý (con lớn tuổi hơn hoặc bằng cha/mẹ).';
            END
        END
        
        -- Kiểm tra quan hệ Cha
        IF @relationship_code = 'CHA'
        BEGIN
            IF NOT (@head_father_id = @citizen_id)
            BEGIN
                SET @warning_message = N'Cảnh báo: Mối quan hệ "Cha" không khớp với dữ liệu hộ tịch (father_citizen_id của chủ hộ).';
            END
            
            -- Kiểm tra tuổi tác hợp lý (cha phải lớn tuổi hơn)
            IF @citizen_birth_date >= @head_birth_date
            BEGIN
                SET @warning_message = ISNULL(@warning_message + N' ', N'') + N'Cảnh báo: Tuổi tác không hợp lý (cha nhỏ tuổi hơn hoặc bằng con).';
            END
        END
        
        -- Kiểm tra quan hệ Mẹ
        IF @relationship_code = 'ME'
        BEGIN
            IF NOT (@head_mother_id = @citizen_id)
            BEGIN
                SET @warning_message = N'Cảnh báo: Mối quan hệ "Mẹ" không khớp với dữ liệu hộ tịch (mother_citizen_id của chủ hộ).';
            END
            
            -- Kiểm tra tuổi tác hợp lý (mẹ phải lớn tuổi hơn)
            IF @citizen_birth_date >= @head_birth_date
            BEGIN
                SET @warning_message = ISNULL(@warning_message + N' ', N'') + N'Cảnh báo: Tuổi tác không hợp lý (mẹ nhỏ tuổi hơn hoặc bằng con).';
            END
        END
        
        -- Kiểm tra quan hệ Vợ/Chồng
        IF @relationship_code IN ('VO', 'CHONG')
        BEGIN
            -- Kiểm tra spouse_citizen_id của cả hai phải trỏ đến nhau
            IF NOT (@citizen_spouse_id = @head_of_household_id AND @head_spouse_id = @citizen_id)
            BEGIN
                SET @warning_message = N'Cảnh báo: Mối quan hệ vợ/chồng không khớp với dữ liệu hộ tịch (spouse_citizen_id).';
            END
            
            -- Kiểm tra tình trạng hôn nhân
            DECLARE @married_status_id SMALLINT = (SELECT marital_status_id FROM [Reference].[MaritalStatuses] WHERE marital_status_code = 'DAKETHON');
            
            IF NOT (@citizen_marital_status_id = @married_status_id AND @head_marital_status_id = @married_status_id)
            BEGIN
                SET @warning_message = ISNULL(@warning_message + N' ', N'') + N'Cảnh báo: Tình trạng hôn nhân không phù hợp (một hoặc cả hai chưa có tình trạng "Đã kết hôn").';
            END
        END
        
        -- ================================================================
        -- KẾT LUẬN VALIDATION
        -- ================================================================
        
        -- Nếu đến đây mà không có error_code thì validation pass
        SET @validation_result = 1;
        
    END TRY
    BEGIN CATCH
        SET @validation_result = 0;
        SET @error_code = 'VALIDATION_ERROR';
        SET @error_message = N'Lỗi hệ thống khi xác minh mối quan hệ: ' + ERROR_MESSAGE();
    END CATCH
END
GO

PRINT N'Stored procedure [API_Internal].[ValidateHouseholdRelationship] đã được tạo thành công.'; 
USE [DB_BCA];
GO

-- Drop existing procedures/functions in API_Internal schema if they exist
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += 'DROP PROCEDURE [API_Internal].' + QUOTENAME(ROUTINE_NAME) + ';' + CHAR(13) + CHAR(10)
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'API_Internal' AND ROUTINE_TYPE = 'PROCEDURE';

SELECT @sql += 'DROP FUNCTION [API_Internal].' + QUOTENAME(ROUTINE_NAME) + ';' + CHAR(13) + CHAR(10)
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'API_Internal' AND ROUTINE_TYPE LIKE '%FUNCTION%';

EXEC sp_executesql @sql;
GO

--------------------------------------------------------------------------
-- 1. Citizen Information Management
--------------------------------------------------------------------------

-- Function to get citizen details (Table-Valued Function for flexibility)
CREATE FUNCTION [API_Internal].[GetCitizenDetails] (
    @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        c.[citizen_id], c.[full_name], c.[date_of_birth], c.[gender],
        c.[birth_ward_id], bw.[ward_name] AS birth_ward_name,
        c.[birth_district_id], bd.[district_name] AS birth_district_name,
        c.[birth_province_id], bp.[province_name] AS birth_province_name,
        c.[birth_country_id], bc.[nationality_name] AS birth_country_name,
        c.[native_ward_id], nw.[ward_name] AS native_ward_name,
        c.[native_district_id], nd.[district_name] AS native_district_name,
        c.[native_province_id], np.[province_name] AS native_province_name,
        c.[nationality_id], nat.[nationality_name],
        c.[ethnicity_id], eth.[ethnicity_name],
        c.[religion_id], rel.[religion_name],
        c.[marital_status],
        c.[education_level],
        c.[occupation_id], occ.[occupation_name],
        c.[current_address_detail],
        c.[current_ward_id], cw.[ward_name] AS current_ward_name,
        c.[current_district_id], cd.[district_name] AS current_district_name,
        c.[current_province_id], cp.[province_name] AS current_province_name,
        c.[father_citizen_id],
        c.[mother_citizen_id],
        c.[spouse_citizen_id],
        c.[representative_citizen_id],
        c.[death_status],
        c.[date_of_death],
        c.[phone_number],
        c.[email],
        c.[created_at],
        c.[updated_at]
    FROM [BCA].[Citizen] c
    LEFT JOIN [Reference].[Wards] bw ON c.birth_ward_id = bw.ward_id
    LEFT JOIN [Reference].[Districts] bd ON c.birth_district_id = bd.district_id
    LEFT JOIN [Reference].[Provinces] bp ON c.birth_province_id = bp.province_id
    LEFT JOIN [Reference].[Nationalities] bc ON c.birth_country_id = bc.nationality_id
    LEFT JOIN [Reference].[Wards] nw ON c.native_ward_id = nw.ward_id
    LEFT JOIN [Reference].[Districts] nd ON c.native_district_id = nd.district_id
    LEFT JOIN [Reference].[Provinces] np ON c.native_province_id = np.province_id
    LEFT JOIN [Reference].[Nationalities] nat ON c.nationality_id = nat.nationality_id
    LEFT JOIN [Reference].[Ethnicities] eth ON c.ethnicity_id = eth.ethnicity_id
    LEFT JOIN [Reference].[Religions] rel ON c.religion_id = rel.religion_id
    LEFT JOIN [Reference].[Occupations] occ ON c.occupation_id = occ.occupation_id
    LEFT JOIN [Reference].[Wards] cw ON c.current_ward_id = cw.ward_id
    LEFT JOIN [Reference].[Districts] cd ON c.current_district_id = cd.district_id
    LEFT JOIN [Reference].[Provinces] cp ON c.current_province_id = cp.province_id
    WHERE c.[citizen_id] = @citizen_id
);
GO

-- Procedure to update non-core citizen info (e.g., education, occupation, contact)
CREATE PROCEDURE [API_Internal].[UpdateCitizenNonCoreInfo]
    @citizen_id VARCHAR(12),
    @education_level NVARCHAR(50) = NULL,
    @occupation_id INT = NULL,
    @phone_number VARCHAR(15) = NULL,
    @email VARCHAR(100) = NULL,
    @updated_by NVARCHAR(128) = NULL -- User performing the update (from API Service context)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id)
        BEGIN
            RAISERROR('Citizen not found.', 16, 1);
            RETURN -1; -- Indicate citizen not found
        END

        UPDATE [BCA].[Citizen]
        SET
            [education_level] = COALESCE(@education_level, [education_level]),
            [occupation_id] = COALESCE(@occupation_id, [occupation_id]),
            [phone_number] = COALESCE(@phone_number, [phone_number]),
            [email] = COALESCE(@email, [email]),
            [updated_at] = SYSDATETIME()
            -- Consider adding updated_by if the table has such a column
        WHERE [citizen_id] = @citizen_id;

        RETURN 1; -- Success
    END TRY
    BEGIN CATCH
        -- Log error details (implement proper logging)
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Indicate error
    END CATCH
END;
GO

-- Procedure to add a new citizen or update existing one based on birth registration info from BTP
-- Called by API Service after BTP registers a birth
CREATE PROCEDURE [API_Internal].[AddNewCitizenOrUpdateFromBirth]
    @citizen_id VARCHAR(12),
    @full_name NVARCHAR(100),
    @date_of_birth DATE,
    @gender NVARCHAR(10),
    @birth_ward_id INT,
    @birth_district_id INT,
    @birth_province_id INT,
    @birth_country_id SMALLINT,
    @nationality_id SMALLINT,
    @ethnicity_id SMALLINT = NULL,
    @father_citizen_id VARCHAR(12) = NULL,
    @mother_citizen_id VARCHAR(12) = NULL,
    @created_by NVARCHAR(128) = 'API_Service_BirthReg'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id)
        BEGIN
            -- Citizen exists, potentially update some core info if needed (e.g., if initial record was partial)
            UPDATE [BCA].[Citizen]
            SET
                [full_name] = COALESCE([full_name], @full_name), -- Only update if current is NULL? Or always overwrite? Decide policy.
                [date_of_birth] = COALESCE([date_of_birth], @date_of_birth),
                [gender] = COALESCE([gender], @gender),
                [birth_ward_id] = COALESCE([birth_ward_id], @birth_ward_id),
                [birth_district_id] = COALESCE([birth_district_id], @birth_district_id),
                [birth_province_id] = COALESCE([birth_province_id], @birth_province_id),
                [birth_country_id] = COALESCE([birth_country_id], @birth_country_id),
                [nationality_id] = COALESCE([nationality_id], @nationality_id),
                [ethnicity_id] = COALESCE([ethnicity_id], @ethnicity_id),
                [father_citizen_id] = COALESCE([father_citizen_id], @father_citizen_id),
                [mother_citizen_id] = COALESCE([mother_citizen_id], @mother_citizen_id),
                [updated_at] = SYSDATETIME()
                -- [updated_by] = @created_by -- If column exists
            WHERE [citizen_id] = @citizen_id;
        END
        ELSE
        BEGIN
            -- Citizen does not exist, insert new record
            INSERT INTO [BCA].[Citizen] (
                [citizen_id], [full_name], [date_of_birth], [gender],
                [birth_ward_id], [birth_district_id], [birth_province_id], [birth_country_id],
                [nationality_id], [ethnicity_id],
                [father_citizen_id], [mother_citizen_id],
                [marital_status], [death_status], -- Default values
                [created_at], [updated_at] --, [created_by], [updated_by]
            ) VALUES (
                @citizen_id, @full_name, @date_of_birth, @gender,
                @birth_ward_id, @birth_district_id, @birth_province_id, @birth_country_id,
                @nationality_id, @ethnicity_id,
                @father_citizen_id, @mother_citizen_id,
                N'Độc thân', N'Còn sống', -- Sensible defaults
                SYSDATETIME(), SYSDATETIME() --, @created_by, @created_by
            );
        END

        COMMIT TRANSACTION;
        RETURN 1; -- Success
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

-- Procedure to update citizen's marital status (Called by API Service)
CREATE PROCEDURE [API_Internal].[UpdateCitizenMaritalStatus]
    @citizen_id VARCHAR(12),
    @marital_status NVARCHAR(20),
    @spouse_citizen_id VARCHAR(12) = NULL, -- NULL if divorced/widowed
    @updated_by NVARCHAR(128) = 'API_Service_CivilStatus'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id)
        BEGIN
            RAISERROR('Citizen not found.', 16, 1);
            RETURN -1;
        END

        -- Validate status
        IF @marital_status NOT IN (N'Độc thân', N'Đã kết hôn', N'Đã ly hôn', N'Góa', N'Ly thân')
        BEGIN
             RAISERROR('Invalid marital status.', 16, 1);
             RETURN -3;
        END

        UPDATE [BCA].[Citizen]
        SET
            [marital_status] = @marital_status,
            [spouse_citizen_id] = @spouse_citizen_id, -- Update spouse ID
            [updated_at] = SYSDATETIME()
            -- [updated_by] = @updated_by
        WHERE [citizen_id] = @citizen_id;

        RETURN 1; -- Success
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

-- Procedure to update citizen's death status (Called by API Service)
CREATE PROCEDURE [API_Internal].[UpdateCitizenDeathStatus]
    @citizen_id VARCHAR(12),
    @date_of_death DATE,
    @updated_by NVARCHAR(128) = 'API_Service_CivilStatus'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id)
        BEGIN
            RAISERROR('Citizen not found.', 16, 1);
            RETURN -1;
        END

        IF @date_of_death IS NULL OR @date_of_death > GETDATE()
        BEGIN
             RAISERROR('Invalid date of death.', 16, 1);
             RETURN -3;
        END

        -- Update status and date
        UPDATE [BCA].[Citizen]
        SET
            [death_status] = N'Đã mất',
            [date_of_death] = @date_of_death,
            [updated_at] = SYSDATETIME()
            -- [updated_by] = @updated_by
        WHERE [citizen_id] = @citizen_id;

        -- Optionally: Update related records (e.g., mark residence as inactive) - Requires more complex logic

        RETURN 1; -- Success
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

-- Function/Procedure to get citizen status history
CREATE FUNCTION [API_Internal].[GetCitizenStatusHistory] (
    @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [status_id],
        [citizen_id],
        [status_type],
        [status_date],
        [description],
        [cause],
        [location],
        [authority_id],
        [document_number],
        [document_date],
        [certificate_id],
        [is_current],
        [created_at]
    FROM [BCA].[CitizenStatus]
    WHERE [citizen_id] = @citizen_id
    ORDER BY [status_date] DESC, [created_at] DESC
);
GO

--------------------------------------------------------------------------
-- 2. Identification Card Management
--------------------------------------------------------------------------

-- Function to get ID card history
CREATE FUNCTION [API_Internal].[GetIdentificationCardHistory] (
     @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        ic.[id_card_id],
        ic.[citizen_id],
        ic.[card_number],
        ic.[card_type],
        ic.[issue_date],
        ic.[expiry_date],
        ic.[issuing_authority_id],
        auth.[authority_name] AS issuing_authority_name,
        ic.[issuing_place],
        ic.[card_status],
        ic.[previous_card_number],
        ic.[chip_id],
        ic.[notes],
        ic.[created_at]
    FROM [BCA].[IdentificationCard] ic
    LEFT JOIN [Reference].[Authorities] auth ON ic.issuing_authority_id = auth.authority_id
    WHERE ic.[citizen_id] = @citizen_id
    ORDER BY ic.[issue_date] DESC, ic.[created_at] DESC
);
GO

-- Procedure to issue a new ID card
CREATE PROCEDURE [API_Internal].[IssueNewIdCard]
    @citizen_id VARCHAR(12),
    @card_number VARCHAR(12),
    @card_type NVARCHAR(20),
    @issue_date DATE,
    @expiry_date DATE = NULL,
    @issuing_authority_id INT,
    @issuing_place NVARCHAR(255) = NULL,
    @previous_card_number VARCHAR(12) = NULL,
    @chip_id VARCHAR(50) = NULL,
    @notes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @new_id_card_id BIGINT;

    BEGIN TRY
        -- Validate input
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id) BEGIN RAISERROR('Citizen not found.', 16, 1); RETURN -1; END
        IF @card_type NOT IN (N'CMND 9 số', N'CMND 12 số', N'CCCD', N'CCCD gắn chip') BEGIN RAISERROR('Invalid card type.', 16, 1); RETURN -3; END
        IF @issue_date > GETDATE() BEGIN RAISERROR('Issue date cannot be in the future.', 16, 1); RETURN -3; END
        IF @expiry_date IS NOT NULL AND @expiry_date <= @issue_date BEGIN RAISERROR('Expiry date must be after issue date.', 16, 1); RETURN -3; END
        IF EXISTS (SELECT 1 FROM [BCA].[IdentificationCard] WHERE [card_number] = @card_number) BEGIN RAISERROR('Card number already exists.', 16, 1); RETURN -4; END -- Basic check, might need more complex logic for reissues

        BEGIN TRANSACTION;

        -- Deactivate previous active cards for this citizen (if any)
        UPDATE [BCA].[IdentificationCard]
        SET [card_status] = N'Đã thay thế',
            [updated_at] = SYSDATETIME()
        WHERE [citizen_id] = @citizen_id AND [card_status] = N'Đang sử dụng';

        -- Insert the new card record
        INSERT INTO [BCA].[IdentificationCard] (
            [citizen_id], [card_number], [card_type], [issue_date], [expiry_date],
            [issuing_authority_id], [issuing_place], [card_status], [previous_card_number],
            [chip_id], [notes], [created_at], [updated_at] --, [created_by], [updated_by]
        ) VALUES (
            @citizen_id, @card_number, @card_type, @issue_date, @expiry_date,
            @issuing_authority_id, @issuing_place, N'Đang sử dụng', @previous_card_number,
            @chip_id, @notes, SYSDATETIME(), SYSDATETIME() --, @created_by, @created_by
        );

        SET @new_id_card_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        SELECT @new_id_card_id AS NewIdCardId; -- Return the new ID
        RETURN 1; -- Success

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

-- Procedure to update ID card status
CREATE PROCEDURE [API_Internal].[UpdateIdCardStatus]
    @id_card_id BIGINT,
    @new_status NVARCHAR(20),
    @updated_by NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [BCA].[IdentificationCard] WHERE [id_card_id] = @id_card_id) BEGIN RAISERROR('ID Card not found.', 16, 1); RETURN -1; END
        IF @new_status NOT IN (N'Đang sử dụng', N'Hết hạn', N'Mất', N'Hỏng', N'Thu hồi', N'Đã thay thế', N'Tạm giữ') BEGIN RAISERROR('Invalid card status.', 16, 1); RETURN -3; END

        UPDATE [BCA].[IdentificationCard]
        SET [card_status] = @new_status,
            [updated_at] = SYSDATETIME()
            -- [updated_by] = @updated_by
        WHERE [id_card_id] = @id_card_id;

        RETURN 1; -- Success
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

--------------------------------------------------------------------------
-- 3. Residence Management
--------------------------------------------------------------------------

-- Function to get residence history
CREATE FUNCTION [API_Internal].[GetResidenceHistory] (
     @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        rh.[residence_history_id],
        rh.[citizen_id],
        rh.[address_id],
        a.[address_detail],
        w.[ward_name],
        d.[district_name],
        p.[province_name],
        rh.[residence_type],
        rh.[registration_date],
        rh.[expiry_date],
        rh.[registration_reason],
        rh.[previous_address_id],
        rh.[issuing_authority_id],
        auth.[authority_name] AS issuing_authority_name,
        rh.[registration_number],
        rh.[status],
        rh.[notes],
        rh.[created_at]
    FROM [BCA].[ResidenceHistory] rh
    JOIN [BCA].[Address] a ON rh.address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN [Reference].[Authorities] auth ON rh.issuing_authority_id = auth.authority_id
    WHERE rh.[citizen_id] = @citizen_id
    ORDER BY rh.[registration_date] DESC, rh.[created_at] DESC
);
GO

-- Procedure to register new residence (Permanent or Temporary)
CREATE PROCEDURE [API_Internal].[RegisterResidence]
    @citizen_id VARCHAR(12),
    @address_id BIGINT,
    @residence_type NVARCHAR(20),
    @registration_date DATE,
    @expiry_date DATE = NULL, -- Required for Temporary
    @registration_reason NVARCHAR(MAX) = NULL,
    @previous_address_id BIGINT = NULL,
    @issuing_authority_id INT,
    @registration_number VARCHAR(50) = NULL, -- Required for Temporary
    @created_by NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @new_residence_id BIGINT;

    BEGIN TRY
        -- Validate input
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id) BEGIN RAISERROR('Citizen not found.', 16, 1); RETURN -1; END
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Address] WHERE [address_id] = @address_id) BEGIN RAISERROR('Address not found.', 16, 1); RETURN -1; END
        IF @residence_type NOT IN (N'Thường trú', N'Tạm trú') BEGIN RAISERROR('Invalid residence type.', 16, 1); RETURN -3; END
        IF @residence_type = N'Tạm trú' AND @expiry_date IS NULL BEGIN RAISERROR('Expiry date is required for temporary residence.', 16, 1); RETURN -3; END
        IF @registration_date > GETDATE() BEGIN RAISERROR('Registration date cannot be in the future.', 16, 1); RETURN -3; END
        IF @expiry_date IS NOT NULL AND @expiry_date < @registration_date BEGIN RAISERROR('Expiry date cannot be before registration date.', 16, 1); RETURN -3; END

        BEGIN TRANSACTION;

        -- Deactivate previous active residence records of the same type for this citizen
        UPDATE [BCA].[ResidenceHistory]
        SET [status] = N'Moved', -- Or 'Cancelled' depending on policy
            [updated_at] = SYSDATETIME()
        WHERE [citizen_id] = @citizen_id
          AND [residence_type] = @residence_type
          AND [status] = N'Active';

        -- Insert the new residence record
        INSERT INTO [BCA].[ResidenceHistory] (
            [citizen_id], [address_id], [residence_type], [registration_date], [expiry_date],
            [registration_reason], [previous_address_id], [issuing_authority_id], [registration_number],
            [status], [created_at], [updated_at] --, [created_by], [updated_by]
        ) VALUES (
            @citizen_id, @address_id, @residence_type, @registration_date, @expiry_date,
            @registration_reason, @previous_address_id, @issuing_authority_id, @registration_number,
            N'Active', SYSDATETIME(), SYSDATETIME() --, @created_by, @created_by
        );

        SET @new_residence_id = SCOPE_IDENTITY();

        -- Update current address in BCA.Citizen (if permanent residence)
        IF @residence_type = N'Thường trú'
        BEGIN
            DECLARE @ward_id INT, @district_id INT, @province_id INT, @address_detail NVARCHAR(MAX);
            SELECT @address_detail = a.address_detail, @ward_id = a.ward_id, @district_id = a.district_id, @province_id = a.province_id
            FROM [BCA].[Address] a WHERE a.address_id = @address_id;

            UPDATE [BCA].[Citizen]
            SET [current_address_detail] = @address_detail,
                [current_ward_id] = @ward_id,
                [current_district_id] = @district_id,
                [current_province_id] = @province_id,
                [updated_at] = SYSDATETIME()
            WHERE [citizen_id] = @citizen_id;
        END

        COMMIT TRANSACTION;
        SELECT @new_residence_id AS NewResidenceHistoryId; -- Return the new ID
        RETURN 1; -- Success

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

-- Procedure to update residence record (status, expiry date, etc.)
CREATE PROCEDURE [API_Internal].[UpdateResidenceRecord]
    @residence_history_id BIGINT,
    @new_status NVARCHAR(20) = NULL,
    @new_expiry_date DATE = NULL,
    @notes NVARCHAR(MAX) = NULL,
    @updated_by NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @current_status NVARCHAR(20);
        DECLARE @reg_date DATE;

        SELECT @current_status = [status], @reg_date = [registration_date]
        FROM [BCA].[ResidenceHistory]
        WHERE [residence_history_id] = @residence_history_id;

        IF @current_status IS NULL BEGIN RAISERROR('Residence record not found.', 16, 1); RETURN -1; END
        IF @new_status IS NOT NULL AND @new_status NOT IN (N'Active', N'Expired', N'Cancelled', N'Moved') BEGIN RAISERROR('Invalid status.', 16, 1); RETURN -3; END
        IF @new_expiry_date IS NOT NULL AND @new_expiry_date < @reg_date BEGIN RAISERROR('New expiry date cannot be before registration date.', 16, 1); RETURN -3; END

        UPDATE [BCA].[ResidenceHistory]
        SET
            [status] = COALESCE(@new_status, [status]),
            [expiry_date] = COALESCE(@new_expiry_date, [expiry_date]),
            [notes] = COALESCE(@notes, [notes]),
            [updated_at] = SYSDATETIME()
            -- [updated_by] = @updated_by
        WHERE [residence_history_id] = @residence_history_id;

        RETURN 1; -- Success
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

--------------------------------------------------------------------------
-- 4. Temporary Absence Management (Placeholder - Requires Table)
--------------------------------------------------------------------------
/*
-- Placeholder: Procedure to register temporary absence
CREATE PROCEDURE [API_Internal].[RegisterTemporaryAbsence]
    -- Parameters: citizen_id, from_date, to_date, reason, destination_address_id, etc.
AS
BEGIN
    -- Logic to insert into BCA.TemporaryAbsence table (if created)
    PRINT 'Placeholder: RegisterTemporaryAbsence';
    RETURN 1;
END;
GO

-- Placeholder: Procedure to confirm return from absence
CREATE PROCEDURE [API_Internal].[ConfirmReturnFromAbsence]
    -- Parameters: temporary_absence_id, return_date, etc.
AS
BEGIN
    -- Logic to update BCA.TemporaryAbsence table
    PRINT 'Placeholder: ConfirmReturnFromAbsence';
    RETURN 1;
END;
GO

-- Placeholder: Function to get temporary absence history
CREATE FUNCTION [API_Internal].[GetTemporaryAbsenceHistory] (
     @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    -- Logic to select from BCA.TemporaryAbsence table
    SELECT 'Placeholder' AS Result WHERE 1=0 -- Return empty table structure
);
GO
*/
--------------------------------------------------------------------------
-- 5. Citizen Movement Management (Placeholder - Requires Table)
--------------------------------------------------------------------------
/*
-- Placeholder: Procedure to record citizen movement
CREATE PROCEDURE [API_Internal].[RecordCitizenMovement]
    -- Parameters: citizen_id, movement_type, from_address_id, to_address_id, departure_date, etc.
AS
BEGIN
    -- Logic to insert into BCA.CitizenMovement table (if created)
    PRINT 'Placeholder: RecordCitizenMovement';
    RETURN 1;
END;
GO

-- Placeholder: Function to get citizen movement history
CREATE FUNCTION [API_Internal].[GetCitizenMovementHistory] (
     @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    -- Logic to select from BCA.CitizenMovement table
    SELECT 'Placeholder' AS Result WHERE 1=0 -- Return empty table structure
);
GO
*/
--------------------------------------------------------------------------
-- 6. Criminal Record Management
--------------------------------------------------------------------------

-- Function to get criminal record history
CREATE FUNCTION [API_Internal].[GetCriminalRecordHistory] (
     @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        [record_id],
        [citizen_id],
        [crime_type],
        [crime_description],
        [crime_date],
        [court_name],
        [judgment_no],
        [judgment_date],
        [sentence_description],
        [sentence_start_date],
        [sentence_end_date],
        [execution_status],
        [notes],
        [created_at]
    FROM [BCA].[CriminalRecord]
    WHERE [citizen_id] = @citizen_id
    ORDER BY [judgment_date] DESC, [created_at] DESC
);
GO

-- Procedure to manage criminal records (Add/Update)
CREATE PROCEDURE [API_Internal].[ManageCriminalRecord]
    @record_id BIGINT = NULL, -- NULL for new record, provide ID to update
    @citizen_id VARCHAR(12),
    @crime_type NVARCHAR(100) = NULL,
    @crime_description NVARCHAR(MAX) = NULL,
    @crime_date DATE = NULL,
    @court_name NVARCHAR(200) = NULL,
    @judgment_no VARCHAR(50),
    @judgment_date DATE,
    @sentence_description NVARCHAR(MAX) = NULL,
    @sentence_start_date DATE = NULL,
    @sentence_end_date DATE = NULL,
    @execution_status NVARCHAR(50) = NULL,
    @notes NVARCHAR(MAX) = NULL,
    @created_by NVARCHAR(128) = NULL -- Or updated_by
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @new_record_id BIGINT;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [BCA].[Citizen] WHERE [citizen_id] = @citizen_id) BEGIN RAISERROR('Citizen not found.', 16, 1); RETURN -1; END
        -- Add other validations as needed

        BEGIN TRANSACTION;

        IF @record_id IS NULL -- Insert new record
        BEGIN
            IF EXISTS (SELECT 1 FROM [BCA].[CriminalRecord] WHERE [judgment_no] = @judgment_no) BEGIN RAISERROR('Judgment number already exists.', 16, 1); ROLLBACK; RETURN -4; END

            INSERT INTO [BCA].[CriminalRecord] (
                [citizen_id], [crime_type], [crime_description], [crime_date], [court_name],
                [judgment_no], [judgment_date], [sentence_description], [sentence_start_date],
                [sentence_end_date], [execution_status], [notes], [created_at], [updated_at] --, [created_by], [updated_by]
            ) VALUES (
                @citizen_id, @crime_type, @crime_description, @crime_date, @court_name,
                @judgment_no, @judgment_date, @sentence_description, @sentence_start_date,
                @sentence_end_date, @execution_status, @notes, SYSDATETIME(), SYSDATETIME() --, @created_by, @created_by
            );
            SET @new_record_id = SCOPE_IDENTITY();
        END
        ELSE -- Update existing record
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM [BCA].[CriminalRecord] WHERE [record_id] = @record_id AND [citizen_id] = @citizen_id) BEGIN RAISERROR('Criminal record not found for this citizen.', 16, 1); ROLLBACK; RETURN -1; END
            -- Ensure judgment number uniqueness if it's changed
            IF EXISTS (SELECT 1 FROM [BCA].[CriminalRecord] WHERE [judgment_no] = @judgment_no AND [record_id] <> @record_id) BEGIN RAISERROR('Judgment number already exists for another record.', 16, 1); ROLLBACK; RETURN -4; END

            UPDATE [BCA].[CriminalRecord]
            SET
                [crime_type] = COALESCE(@crime_type, [crime_type]),
                [crime_description] = COALESCE(@crime_description, [crime_description]),
                [crime_date] = COALESCE(@crime_date, [crime_date]),
                [court_name] = COALESCE(@court_name, [court_name]),
                [judgment_no] = COALESCE(@judgment_no, [judgment_no]),
                [judgment_date] = COALESCE(@judgment_date, [judgment_date]),
                [sentence_description] = COALESCE(@sentence_description, [sentence_description]),
                [sentence_start_date] = COALESCE(@sentence_start_date, [sentence_start_date]),
                [sentence_end_date] = COALESCE(@sentence_end_date, [sentence_end_date]),
                [execution_status] = COALESCE(@execution_status, [execution_status]),
                [notes] = COALESCE(@notes, [notes]),
                [updated_at] = SYSDATETIME()
                -- [updated_by] = @created_by
            WHERE [record_id] = @record_id;
            SET @new_record_id = @record_id;
        END

        COMMIT TRANSACTION;
        SELECT @new_record_id AS RecordId;
        RETURN 1; -- Success

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
        RETURN -2; -- Error
    END CATCH
END;
GO

--------------------------------------------------------------------------
-- 7. Internal API Processing
--------------------------------------------------------------------------

-- Function or Procedure to verify citizen existence and basic info
CREATE FUNCTION [API_Internal].[VerifyCitizen] (
    @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1
        [citizen_id],
        [full_name],
        [date_of_birth],
        [gender],
        1 AS ExistsFlag -- Return 1 if exists
    FROM [BCA].[Citizen]
    WHERE [citizen_id] = @citizen_id
);
GO
-- Note: Procedures for receiving events (death, marriage) are already defined above
-- (UpdateCitizenDeathStatus, UpdateCitizenMaritalStatus)
-- Procedure for handling birth event is AddNewCitizenOrUpdateFromBirth


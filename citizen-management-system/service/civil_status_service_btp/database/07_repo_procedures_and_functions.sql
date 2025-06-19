-- File: 07_repo_procedures_and_functions.sql
-- Description: Contains stored procedures and functions refactored from raw SQL in civil_status_repo.py and outbox_repo.py.

USE [DB_BTP];
GO

--------------------------------------------------------------------------------
-- Stored Procedures/Functions from civil_status_repo.py
--------------------------------------------------------------------------------

-- 1. Get Death Certificate by ID
IF OBJECT_ID('[API_Internal].[GetDeathCertificateById]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[GetDeathCertificateById];
GO
CREATE PROCEDURE [API_Internal].[GetDeathCertificateById]
    @certificate_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [BTP].[DeathCertificate]
    WHERE death_certificate_id = @certificate_id;
END;
GO
PRINT N'Stored Procedure [API_Internal].[GetDeathCertificateById] created.';
GO

-- 2. Check for existing Death Certificate
IF OBJECT_ID('[API_Internal].[CheckExistingDeathCertificate]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[CheckExistingDeathCertificate];
GO
CREATE FUNCTION [API_Internal].[CheckExistingDeathCertificate] (
    @citizen_id VARCHAR(12)
)
RETURNS BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM [BTP].[DeathCertificate] WHERE [citizen_id] = @citizen_id)
        RETURN 1;
    RETURN 0;
END;
GO
PRINT N'Function [API_Internal].[CheckExistingDeathCertificate] created.';
GO

-- 3. Get Marriage Certificate Details
IF OBJECT_ID('[API_Internal].[GetMarriageCertificateDetails]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[GetMarriageCertificateDetails];
GO
CREATE PROCEDURE [API_Internal].[GetMarriageCertificateDetails]
    @marriage_certificate_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        marriage_certificate_id, husband_id, wife_id, status
    FROM [BTP].[MarriageCertificate]
    WHERE marriage_certificate_id = @marriage_certificate_id;
END;
GO
PRINT N'Stored Procedure [API_Internal].[GetMarriageCertificateDetails] created.';
GO

-- 4. Get Birth Certificate by ID
IF OBJECT_ID('[API_Internal].[GetBirthCertificateById]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[GetBirthCertificateById];
GO
CREATE PROCEDURE [API_Internal].[GetBirthCertificateById]
    @certificate_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM [BTP].[BirthCertificate]
    WHERE birth_certificate_id = @certificate_id;
END;
GO
PRINT N'Stored Procedure [API_Internal].[GetBirthCertificateById] created.';
GO

-- 5. Check for existing Birth Certificate
IF OBJECT_ID('[API_Internal].[CheckExistingBirthCertificateForCitizen]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[CheckExistingBirthCertificateForCitizen];
GO
CREATE FUNCTION [API_Internal].[CheckExistingBirthCertificateForCitizen] (
    @citizen_id VARCHAR(12)
)
RETURNS BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM [BTP].[BirthCertificate] WHERE citizen_id = @citizen_id)
        RETURN 1;
    RETURN 0;
END;
GO
PRINT N'Function [API_Internal].[CheckExistingBirthCertificateForCitizen] created.';
GO

--------------------------------------------------------------------------------
-- Stored Procedures/Functions from outbox_repo.py
--------------------------------------------------------------------------------

-- 1. Create Outbox Message
IF OBJECT_ID('[API_Internal].[CreateOutboxMessage]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[CreateOutboxMessage];
GO
CREATE PROCEDURE [API_Internal].[CreateOutboxMessage]
    @aggregate_type NVARCHAR(255),
    @aggregate_id VARCHAR(255),
    @event_type NVARCHAR(255),
    @payload NVARCHAR(MAX),
    @outbox_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [BTP].[EventOutbox]
        ([aggregate_type], [aggregate_id], [event_type], [payload], [created_at])
    VALUES
        (@aggregate_type, @aggregate_id, @event_type, @payload, GETDATE());
    
    SET @outbox_id = SCOPE_IDENTITY();
END;
GO
PRINT N'Stored Procedure [API_Internal].[CreateOutboxMessage] created.';
GO 
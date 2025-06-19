-- ==============================================================================
-- Script to Set Up SQL Server Audit for DB_BCA
-- ==============================================================================
-- This script creates a server-level audit and database-level audit specifications
-- to monitor key activities for security purposes.

-- Step 1: Create the Server Audit object
-- This defines where the audit logs will be stored.
-- We are using the volume mapped in docker-compose.yml.
PRINT N'Step 1: Creating Server Audit [Audit_All_Actions]...';
USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = 'Audit_All_Actions')
BEGIN
    CREATE SERVER AUDIT [Audit_All_Actions]
    TO FILE (
        FILEPATH = '/var/opt/mssql/audit/', -- Path inside the Docker container
        MAXSIZE = 100 MB,
        MAX_ROLLOVER_FILES = 5,
        RESERVE_DISK_SPACE = OFF
    )
    WITH (
        QUEUE_DELAY = 1000,
        ON_FAILURE = CONTINUE
    );
    PRINT N'  Server Audit [Audit_All_Actions] created.';
END
ELSE
BEGIN
    PRINT N'  Server Audit [Audit_All_Actions] already exists.';
END
GO

-- Enable the Server Audit
IF (SELECT is_state_enabled FROM sys.server_audits WHERE name = 'Audit_All_Actions') = 0
BEGIN
    ALTER SERVER AUDIT [Audit_All_Actions] WITH (STATE = ON);
    PRINT N'  Server Audit [Audit_All_Actions] has been enabled.';
END
GO

-- Step 2: Create a Server Audit Specification for logins
-- This monitors login attempts on the SQL Server instance.
PRINT N'Step 2: Creating Server Audit Specification for Logins...';
IF NOT EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'ServerAuditSpec_Login')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpec_Login]
    FOR SERVER AUDIT [Audit_All_Actions]
    ADD (SUCCESSFUL_LOGIN_GROUP),
    ADD (FAILED_LOGIN_GROUP)
    WITH (STATE = ON);
    PRINT N'  Server Audit Specification [ServerAuditSpec_Login] created and enabled.';
END
ELSE
BEGIN
    PRINT N'  Server Audit Specification [ServerAuditSpec_Login] already exists.';
END
GO

-- Step 3: Create a Database Audit Specification for DB_BCA
-- This monitors specific actions within the DB_BCA database.
PRINT N'Step 3: Creating Database Audit Specification for DB_BCA...';
USE DB_BCA;
GO

IF NOT EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = 'DatabaseAuditSpec_BCA_Sensitive')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec_BCA_Sensitive]
    FOR SERVER AUDIT [Audit_All_Actions]
    -- Audit SELECT and DML on critical tables
    ADD (SELECT, INSERT, UPDATE, DELETE ON OBJECT::BCA.Citizen BY public),
    ADD (SELECT, INSERT, UPDATE, DELETE ON OBJECT::BCA.IdentificationCard BY public),
    ADD (SELECT, INSERT, UPDATE, DELETE ON OBJECT::BCA.CriminalRecord BY public),
    -- Audit changes to permissions
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),
    -- Audit execution of sensitive stored procedures (add more as needed)
    ADD (EXECUTE ON OBJECT::API_Internal.GetCitizenFamilyTree BY public),
    ADD (EXECUTE ON OBJECT::API_Internal.RemoveHouseholdMember BY public)
    WITH (STATE = ON);
    PRINT N'  Database Audit Specification [DatabaseAuditSpec_BCA_Sensitive] created and enabled.';
END
ELSE
BEGIN
    PRINT N'  Database Audit Specification [DatabaseAuditSpec_BCA_Sensitive] already exists.';
END
GO

PRINT N'Auditing setup script for DB_BCA completed.';
GO 
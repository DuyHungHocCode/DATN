-- ==============================================================================
-- Script to Set Up SQL Server Audit for DB_BTP (Standalone Instance)
-- ==============================================================================
-- This script creates a full, independent set of server-level and database-level
-- audit specifications for the BTP SQL Server instance.

-- Step 1: Create the Server Audit object for the BTP instance
-- This defines where the audit logs for this instance will be stored.
PRINT N'Step 1: Creating Server Audit [Audit_All_Actions_BTP]...';
USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = 'Audit_All_Actions_BTP')
BEGIN
    CREATE SERVER AUDIT [Audit_All_Actions_BTP]
    TO FILE (
        FILEPATH = '/var/opt/mssql/audit/', -- Path inside the BTP Docker container
        MAXSIZE = 100 MB,
        MAX_ROLLOVER_FILES = 5,
        RESERVE_DISK_SPACE = OFF
    )
    WITH (
        QUEUE_DELAY = 1000,
        ON_FAILURE = CONTINUE
    );
    PRINT N'  Server Audit [Audit_All_Actions_BTP] created.';
END
ELSE
BEGIN
    PRINT N'  Server Audit [Audit_All_Actions_BTP] already exists.';
END
GO

-- Enable the Server Audit
IF (SELECT is_state_enabled FROM sys.server_audits WHERE name = 'Audit_All_Actions_BTP') = 0
BEGIN
    ALTER SERVER AUDIT [Audit_All_Actions_BTP] WITH (STATE = ON);
    PRINT N'  Server Audit [Audit_All_Actions_BTP] has been enabled.';
END
GO

-- Step 2: Create a Server Audit Specification for logins on the BTP instance
-- This monitors login attempts on this specific SQL Server instance.
PRINT N'Step 2: Creating Server Audit Specification for Logins on BTP instance...';
IF NOT EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'ServerAuditSpec_Login_BTP')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpec_Login_BTP]
    FOR SERVER AUDIT [Audit_All_Actions_BTP]
    ADD (SUCCESSFUL_LOGIN_GROUP),
    ADD (FAILED_LOGIN_GROUP)
    WITH (STATE = ON);
    PRINT N'  Server Audit Specification [ServerAuditSpec_Login_BTP] created and enabled.';
END
ELSE
BEGIN
    PRINT N'  Server Audit Specification [ServerAuditSpec_Login_BTP] already exists.';
END
GO

-- Step 3: Create a Database Audit Specification for DB_BTP
-- This monitors specific actions within the DB_BTP database.
PRINT N'Step 3: Creating Database Audit Specification for DB_BTP...';
USE DB_BTP;
GO

IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = 'DatabaseAuditSpec_BTP_Sensitive')
BEGIN
    -- Drop the old spec if it exists, as it might point to a non-existent audit
    ALTER DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec_BTP_Sensitive] WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec_BTP_Sensitive];
    PRINT N'  Dropped existing Database Audit Specification for recreation.';
END

CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpec_BTP_Sensitive]
FOR SERVER AUDIT [Audit_All_Actions_BTP] -- <-- Point to the BTP-specific server audit
-- Audit DML on all civil status tables
ADD (INSERT, UPDATE, DELETE ON SCHEMA::BTP BY public),
-- Audit SELECT on specific sensitive tables
ADD (SELECT ON OBJECT::BTP.BirthCertificate BY public),
ADD (SELECT ON OBJECT::BTP.DeathCertificate BY public),
ADD (SELECT ON OBJECT::BTP.MarriageCertificate BY public),
-- Audit changes to permissions
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
-- Audit execution of sensitive stored procedures (add more as needed)
ADD (EXECUTE ON OBJECT::API_Internal.RegisterDeathCertificate BY public),
ADD (EXECUTE ON OBJECT::API_Internal.RegisterMarriageCertificate BY public)
WITH (STATE = ON);
PRINT N'  Database Audit Specification [DatabaseAuditSpec_BTP_Sensitive] created and enabled.';
GO

PRINT N'Auditing setup script for DB_BTP completed.';
GO 
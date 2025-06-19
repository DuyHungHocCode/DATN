-- File: 06_setup_permissions.sql
-- Description: Sets up logins, users, roles, and permissions for civil_status_service_btp.
-- Principle: Least Privilege. The service gets only the permissions it absolutely needs.

-- This script should be run by a system administrator (like 'sa') on the SQL Server instance.

--------------------------------------------------------------------------------
-- SCRIPT CONFIGURATION
--------------------------------------------------------------------------------
-- Use the master database to create server-level logins
USE master;
GO

-- Define variables for names to ensure consistency
DECLARE @BTP_LoginName SYSNAME = 'btp_service_login';
DECLARE @BTP_UserName SYSNAME = 'btp_service_user';
DECLARE @BTP_RoleName SYSNAME = 'btp_api_role';
DECLARE @BTPDatabaseName SYSNAME = 'DB_BTP';
DECLARE @Password NVARCHAR(256) = 'STRONG_BTP_PASSWORD_HERE'; -- !! IMPORTANT: Replace with a strong, unique password !!

--------------------------------------------------------------------------------
-- STEP 1: CREATE SERVER LOGIN for civil_status_service_btp
--------------------------------------------------------------------------------
PRINT N'STEP 1: Creating Server Login [' + @BTP_LoginName + ']...';

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @BTP_LoginName)
BEGIN
    PRINT N'  Login [' + @BTP_LoginName + '] does not exist. Creating...';
    -- Create the server login with the specified password
    EXEC('CREATE LOGIN [' + @BTP_LoginName + '] WITH PASSWORD = ''' + @Password + ''', DEFAULT_DATABASE = [' + @BTPDatabaseName + ']');
    PRINT N'  Login [' + @BTP_LoginName + '] created successfully.';
END
ELSE
BEGIN
    PRINT N'  Login [' + @BTP_LoginName + '] already exists. Skipping creation.';
END
GO

--------------------------------------------------------------------------------
-- SWITCH TO THE TARGET DATABASE for the next steps
--------------------------------------------------------------------------------
USE [DB_BTP];
GO

-- Re-declare variables for use within this database context
DECLARE @BTP_LoginName SYSNAME = 'btp_service_login';
DECLARE @BTP_UserName SYSNAME = 'btp_service_user';
DECLARE @BTP_RoleName SYSNAME = 'btp_api_role';

--------------------------------------------------------------------------------
-- STEP 2 & 3: CREATE DATABASE USER and ROLE
--------------------------------------------------------------------------------
PRINT N'STEP 2: Creating Database User [' + @BTP_UserName + '] for Login [' + @BTP_LoginName + ']...';

-- STEP 2: Create a database user and link it to the server login
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @BTP_UserName)
BEGIN
    PRINT N'  User [' + @BTP_UserName + '] does not exist. Creating and linking to login [' + @BTP_LoginName + ']...';
    EXEC('CREATE USER [' + @BTP_UserName + '] FOR LOGIN [' + @BTP_LoginName + ']');
    PRINT N'  User [' + @BTP_UserName + '] created successfully.';
END
ELSE
BEGIN
    PRINT N'  User [' + @BTP_UserName + '] already exists. Skipping creation.';
END
GO

PRINT N'STEP 3: Creating Database Role [' + @BTP_RoleName + ']...';

-- STEP 3: Create a custom database role for the API service
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @BTP_RoleName AND type = 'R')
BEGIN
    PRINT N'  Role [' + @BTP_RoleName + '] does not exist. Creating...';
    EXEC('CREATE ROLE [' + @BTP_RoleName + ']');
    PRINT N'  Role [' + @BTP_RoleName + '] created successfully.';
END
ELSE
BEGIN
    PRINT N'  Role [' + @BTP_RoleName + '] already exists. Skipping creation.';
END
GO

--------------------------------------------------------------------------------
-- STEP 4: GRANT SPECIFIC PERMISSIONS TO THE ROLE (PRINCIPLE OF LEAST PRIVILEGE)
--------------------------------------------------------------------------------
PRINT N'STEP 4: Granting specific permissions to Role [' + @BTP_RoleName + ']...';

-- Grant EXECUTE permission on specific stored procedures in API_Internal schema.
-- This service only writes civil status events and creates outbox records.
-- All data modification is encapsulated within these specific stored procedures.
PRINT N'  Granting EXECUTE permissions on specific API_Internal stored procedures...';

GRANT EXECUTE ON [API_Internal].[InsertBirthCertificate] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[InsertDeathCertificate] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[InsertMarriageCertificate] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[InsertDivorceRecord] TO [btp_api_role];

-- Grant EXECUTE on newly created procedures and functions
GRANT EXECUTE ON [API_Internal].[GetDeathCertificateById] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[CheckExistingDeathCertificate] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[GetMarriageCertificateDetails] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[GetBirthCertificateById] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[CheckExistingBirthCertificateForCitizen] TO [btp_api_role];
GRANT EXECUTE ON [API_Internal].[CreateOutboxMessage] TO [btp_api_role];

PRINT N'  EXECUTE permissions granted on specific stored procedures.';
PRINT N'  Note: This role has NO other permissions - maximum security isolation.';
GO

--------------------------------------------------------------------------------
-- STEP 5: ASSIGN THE USER TO THE ROLE
--------------------------------------------------------------------------------
PRINT N'STEP 5: Assigning User [' + @BTP_UserName + '] to Role [' + @BTP_RoleName + ']...';

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals role ON drm.role_principal_id = role.principal_id
    JOIN sys.database_principals member ON drm.member_principal_id = member.principal_id
    WHERE role.name = 'btp_api_role' AND member.name = 'btp_service_user'
)
BEGIN
    PRINT N'  Adding user [' + @BTP_UserName + '] to role [' + @BTP_RoleName + ']...';
    ALTER ROLE [btp_api_role] ADD MEMBER [btp_service_user];
    PRINT N'  User assigned to role successfully.';
END
ELSE
BEGIN
    PRINT N'  User [' + @BTP_UserName + '] is already a member of role [' + @BTP_RoleName + '].';
END
GO

PRINT N'--------------------------------------------------------------------------------';
PRINT N'Security setup for civil_status_service_btp completed successfully.';
PRINT N'IMPORTANT: Remember to replace the placeholder password in this script and update your application''s connection string.';
PRINT N'--------------------------------------------------------------------------------'; 
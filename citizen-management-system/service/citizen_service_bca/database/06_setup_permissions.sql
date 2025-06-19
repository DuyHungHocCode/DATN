-- File: 06_setup_permissions.sql
-- Description: Sets up logins, users, roles, and permissions for citizen_service_bca.
-- Principle: Least Privilege. The service gets only the permissions it absolutely needs.

-- This script should be run by a system administrator (like 'sa') on the SQL Server instance.

--------------------------------------------------------------------------------
-- SCRIPT CONFIGURATION
--------------------------------------------------------------------------------
-- Use the master database to create server-level logins
USE master;
GO

-- Define variables for names to ensure consistency
DECLARE @BCA_LoginName SYSNAME = 'bca_service_login';
DECLARE @BCA_UserName SYSNAME = 'bca_service_user';
DECLARE @BCA_RoleName SYSNAME = 'bca_api_role';
DECLARE @BCADatabaseName SYSNAME = 'DB_BCA';
DECLARE @Password NVARCHAR(256) = '#Hug@12a3b45'; 

--------------------------------------------------------------------------------
-- STEP 1: CREATE SERVER LOGIN for citizen_service_bca
--------------------------------------------------------------------------------
PRINT N'STEP 1: Creating Server Login [' + @BCA_LoginName + ']...';

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @BCA_LoginName)
BEGIN
    PRINT N'  Login [' + @BCA_LoginName + '] does not exist. Creating...';
    -- Create the server login with the specified password
    EXEC('CREATE LOGIN [' + @BCA_LoginName + '] WITH PASSWORD = ''' + @Password + ''', DEFAULT_DATABASE = [' + @BCADatabaseName + ']');
    PRINT N'  Login [' + @BCA_LoginName + '] created successfully.';
END
ELSE
BEGIN
    PRINT N'  Login [' + @BCA_LoginName + '] already exists. Skipping creation.';
END
GO

--------------------------------------------------------------------------------
-- SWITCH TO THE TARGET DATABASE for the next steps
--------------------------------------------------------------------------------
USE [DB_BCA];
GO

-- Re-declare variables for use within this database context
DECLARE @BCA_LoginName SYSNAME = 'bca_service_login';
DECLARE @BCA_UserName SYSNAME = 'bca_service_user';
DECLARE @BCA_RoleName SYSNAME = 'bca_api_role';

--------------------------------------------------------------------------------
-- STEP 2 & 3: CREATE DATABASE USER and ROLE
--------------------------------------------------------------------------------
PRINT N'STEP 2: Creating Database User [' + @BCA_UserName + '] for Login [' + @BCA_LoginName + ']...';

-- STEP 2: Create a database user and link it to the server login
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @BCA_UserName)
BEGIN
    PRINT N'  User [' + @BCA_UserName + '] does not exist. Creating and linking to login [' + @BCA_LoginName + ']...';
    EXEC('CREATE USER [' + @BCA_UserName + '] FOR LOGIN [' + @BCA_LoginName + ']');
    PRINT N'  User [' + @BCA_UserName + '] created successfully.';
END
ELSE
BEGIN
    PRINT N'  User [' + @BCA_UserName + '] already exists. Skipping creation.';
END;

PRINT N'STEP 3: Creating Database Role [' + @BCA_RoleName + ']...';

-- STEP 3: Create a custom database role for the API service
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @BCA_RoleName AND type = 'R')
BEGIN
    PRINT N'  Role [' + @BCA_RoleName + '] does not exist. Creating...';
    EXEC('CREATE ROLE [' + @BCA_RoleName + ']');
    PRINT N'  Role [' + @BCA_RoleName + '] created successfully.';
END
ELSE
BEGIN
    PRINT N'  Role [' + @BCA_RoleName + '] already exists. Skipping creation.';
END;

--------------------------------------------------------------------------------
-- STEP 4: GRANT SPECIFIC PERMISSIONS TO THE ROLE (PRINCIPLE OF LEAST PRIVILEGE)
--------------------------------------------------------------------------------
PRINT N'STEP 4: Granting specific permissions to Role [' + @BCA_RoleName + ']...';

-- Grant EXECUTE permission on specific stored procedures and functions in API_Internal schema
PRINT N'  Granting EXECUTE permissions on specific API_Internal objects...';

-- Functions (Table-Valued Functions need SELECT permission)
PRINT N'  Granting SELECT on Table-Valued Functions...';
GRANT SELECT ON [API_Internal].[GetCitizenDetails] TO [bca_api_role];
GRANT SELECT ON [API_Internal].[GetResidenceHistory] TO [bca_api_role];
GRANT SELECT ON [API_Internal].[GetCitizenContactInfo] TO [bca_api_role];
GRANT SELECT ON [API_Internal].[GetCitizenFamilyTree] TO [bca_api_role];
GRANT SELECT ON [API_Internal].[ValidateCitizenStatus] TO [bca_api_role];

-- Scalar Functions & Stored Procedures (need EXECUTE permission)
PRINT N'  Granting EXECUTE on Stored Procedures and Scalar Functions...';
GRANT EXECUTE ON [API_Internal].[MatchPropertyAndRegistrationAddress] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[FindHouseholdById] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[SearchCitizens] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[UpdateCitizenDeathStatus] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[UpdateCitizenMarriageStatus] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[UpdateCitizenDivorceStatus] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[InsertNewbornCitizen] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[GetReferenceTableData] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[RegisterPermanentResidence_OwnedProperty_DataOnly] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[GetHouseholdDetails] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[AddHouseholdMember] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[RemoveHouseholdMember] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[ValidateHouseholdRelationship] TO [bca_api_role];

-- Grant EXECUTE on newly created procedures and functions from citizen_repo.py
GRANT EXECUTE ON [API_Internal].[MapReasonCodeToId] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[ValidateAuthorityId] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[TransferHouseholdMember] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[IsCitizenInActiveHousehold] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[IsCitizenMemberOfHousehold] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[IsCitizenHeadOfHousehold] TO [bca_api_role];
GRANT EXECUTE ON [API_Internal].[CountActiveHouseholdMembersExcludingCitizen] TO [bca_api_role];

PRINT N'  EXECUTE permissions granted on specific API_Internal objects.';

-- Grant SELECT permission on the Reference schema (required for ReferenceRepository cache functionality)
PRINT N'  Granting SELECT on schema [Reference] (required for cache miss scenarios)...';
GRANT SELECT ON SCHEMA::[Reference] TO [bca_api_role];
PRINT N'  SELECT permission granted on Reference schema.';

-- Explicitly DENY direct access to core data tables to enforce the use of stored procedures
PRINT N'  Denying direct access to core data schema [BCA]...';
DENY SELECT ON SCHEMA::[BCA] TO [bca_api_role];
DENY INSERT ON SCHEMA::[BCA] TO [bca_api_role];
DENY UPDATE ON SCHEMA::[BCA] TO [bca_api_role];
DENY DELETE ON SCHEMA::[BCA] TO [bca_api_role];
PRINT N'  Direct access to [BCA] schema denied (enforcing stored procedure usage).';

--------------------------------------------------------------------------------
-- STEP 5: ASSIGN THE USER TO THE ROLE
--------------------------------------------------------------------------------
PRINT N'STEP 5: Assigning User [' + @BCA_UserName + '] to Role [' + @BCA_RoleName + ']...';

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals role ON drm.role_principal_id = role.principal_id
    JOIN sys.database_principals member ON drm.member_principal_id = member.principal_id
    WHERE role.name = 'bca_api_role' AND member.name = 'bca_service_user'
)
BEGIN
    PRINT N'  Adding user [' + @BCA_UserName + '] to role [' + @BCA_RoleName + ']...';
    ALTER ROLE [bca_api_role] ADD MEMBER [bca_service_user];
    PRINT N'  User assigned to role successfully.';
END
ELSE
BEGIN
    PRINT N'  User [' + @BCA_UserName + '] is already a member of role [' + @BCA_RoleName + '].';
END
GO

PRINT N'--------------------------------------------------------------------------------';
PRINT N'Security setup for citizen_service_bca completed successfully.';
PRINT N'IMPORTANT: Remember to replace the placeholder password in this script and update your application''s connection string.';
PRINT N'--------------------------------------------------------------------------------'; 
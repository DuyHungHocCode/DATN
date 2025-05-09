-- Script to create database users and assign permissions in DB_BCA (Bộ Công an)
-- This script should be run on the SQL Server instance dedicated to DB_BCA,
-- after DB_BCA and its schemas have been created,
-- and after server logins (bca_admin_login, bca_reader_login, etc.) have been created on the instance.

USE [DB_BCA];
GO

PRINT N'Setting up users and permissions in DB_BCA...';

--------------------------------------------------------------------------------
-- CREATE DATABASE USERS FROM SERVER LOGINS
--------------------------------------------------------------------------------
PRINT N'Creating database users if they do not exist...';

-- User for bca_admin_login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_admin_user')
BEGIN
    PRINT N'  Creating user: bca_admin_user for login bca_admin_login...';
    CREATE USER [bca_admin_user] FOR LOGIN [bca_admin_login];
    PRINT N'  User bca_admin_user created.';
END
ELSE
    PRINT N'  User bca_admin_user already exists in DB_BCA.';
GO

-- User for bca_reader_login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_reader_user')
BEGIN
    PRINT N'  Creating user: bca_reader_user for login bca_reader_login...';
    CREATE USER [bca_reader_user] FOR LOGIN [bca_reader_login];
    PRINT N'  User bca_reader_user created.';
END
ELSE
    PRINT N'  User bca_reader_user already exists in DB_BCA.';
GO

-- User for bca_writer_login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_writer_user')
BEGIN
    PRINT N'  Creating user: bca_writer_user for login bca_writer_login...';
    CREATE USER [bca_writer_user] FOR LOGIN [bca_writer_login];
    PRINT N'  User bca_writer_user created.';
END
ELSE
    PRINT N'  User bca_writer_user already exists in DB_BCA.';
GO

-- User for api_service_login (shared login, specific user for this DB)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'api_service_user')
BEGIN
    PRINT N'  Creating user: api_service_user for login api_service_login...';
    CREATE USER [api_service_user] FOR LOGIN [api_service_login];
    PRINT N'  User api_service_user created.';
END
ELSE
    PRINT N'  User api_service_user already exists in DB_BCA.';
GO

--------------------------------------------------------------------------------
-- ASSIGN PERMISSIONS TO DATABASE USERS
--------------------------------------------------------------------------------
/*
PRINT N'Assigning permissions to users in DB_BCA...';

-- Permissions for bca_admin_user (Full control over DB_BCA)
PRINT N'  Setting admin permissions for bca_admin_user...';
ALTER ROLE db_owner ADD MEMBER [bca_admin_user];
PRINT N'  Admin permissions set for bca_admin_user.';
GO

-- Permissions for bca_reader_user (Read-only access)
PRINT N'  Setting reader permissions for bca_reader_user...';
GRANT SELECT ON SCHEMA :: [BCA] TO [bca_reader_user];
-- GRANT SELECT ON SCHEMA :: [Reference] TO [bca_reader_user]; -- Schema Reference is now in DB_Reference
GRANT SELECT ON SCHEMA :: [Audit] TO [bca_reader_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [bca_reader_user]; -- Allow executing API functions/procs
PRINT N'  Reader permissions set for bca_reader_user.';
GO

-- Permissions for bca_writer_user (Read/Write access on specific schemas)
PRINT N'  Setting writer permissions for bca_writer_user...';
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [BCA] TO [bca_writer_user];
-- GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [bca_writer_user]; -- Schema Reference is now in DB_Reference
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [bca_writer_user]; -- Allow executing API functions/procs
-- Note: Typically, writers might also need select on Audit if they read audit logs,
-- or specific insert permissions if they are allowed to write to certain audit tables (less common).
PRINT N'  Writer permissions set for bca_writer_user.';
GO

-- Permissions for api_service_user (Specific permissions needed by the API service)
PRINT N'  Setting API service permissions for api_service_user...';
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [api_service_user]; -- Primary permission: execute internal APIs

-- API service might need to read data from BCA schema
GRANT SELECT ON SCHEMA :: [BCA] TO [api_service_user];
-- GRANT SELECT ON SCHEMA :: [Reference] TO [api_service_user]; -- Schema Reference is now in DB_Reference

-- API service might need to write data to BCA schema (e.g., updates triggered by other services)
GRANT INSERT, UPDATE, DELETE ON SCHEMA :: [BCA] TO [api_service_user];
-- Consider if API needs access to Audit schema (e.g., to write audit entries if not handled by triggers)
-- GRANT SELECT, INSERT ON SCHEMA :: [Audit] TO [api_service_user];
PRINT N'  API service permissions set for api_service_user.';
GO

PRINT N'Successfully completed setting up users and permissions in DB_BCA.';
*/
-- Script to create database users and assign permissions in DB_BTP (Bộ Tư pháp)
-- This script should be run on the SQL Server instance dedicated to DB_BTP,
-- after DB_BTP and its schemas have been created,
-- and after server logins (btp_admin_login, btp_reader_login, etc.) have been created on the instance.

USE [DB_BTP];
GO

PRINT N'Setting up users and permissions in DB_BTP...';

--------------------------------------------------------------------------------
-- CREATE DATABASE USERS FROM SERVER LOGINS
--------------------------------------------------------------------------------
PRINT N'Creating database users if they do not exist...';

-- User for btp_admin_login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_admin_user')
BEGIN
    PRINT N'  Creating user: btp_admin_user for login btp_admin_login...';
    CREATE USER [btp_admin_user] FOR LOGIN [btp_admin_login];
    PRINT N'  User btp_admin_user created.';
END
ELSE
    PRINT N'  User btp_admin_user already exists in DB_BTP.';
GO

-- User for btp_reader_login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_reader_user')
BEGIN
    PRINT N'  Creating user: btp_reader_user for login btp_reader_login...';
    CREATE USER [btp_reader_user] FOR LOGIN [btp_reader_login];
    PRINT N'  User btp_reader_user created.';
END
ELSE
    PRINT N'  User btp_reader_user already exists in DB_BTP.';
GO

-- User for btp_writer_login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_writer_user')
BEGIN
    PRINT N'  Creating user: btp_writer_user for login btp_writer_login...';
    CREATE USER [btp_writer_user] FOR LOGIN [btp_writer_login];
    PRINT N'  User btp_writer_user created.';
END
ELSE
    PRINT N'  User btp_writer_user already exists in DB_BTP.';
GO

-- User for api_service_login (shared login, specific user for this DB)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'api_service_user')
BEGIN
    PRINT N'  Creating user: api_service_user for login api_service_login...';
    CREATE USER [api_service_user] FOR LOGIN [api_service_login];
    PRINT N'  User api_service_user created.';
END
ELSE
    PRINT N'  User api_service_user already exists in DB_BTP.';
GO

--------------------------------------------------------------------------------
-- ASSIGN PERMISSIONS TO DATABASE USERS
--------------------------------------------------------------------------------
-- PRINT N'Assigning permissions to users in DB_BTP...';

-- -- Permissions for btp_admin_user (Full control over DB_BTP)
-- PRINT N'  Setting admin permissions for btp_admin_user...';
-- ALTER ROLE db_owner ADD MEMBER [btp_admin_user];
-- PRINT N'  Admin permissions set for btp_admin_user.';
-- GO

-- -- Permissions for btp_reader_user (Read-only access)
-- PRINT N'  Setting reader permissions for btp_reader_user...';
-- GRANT SELECT ON SCHEMA :: [BTP] TO [btp_reader_user];
-- -- GRANT SELECT ON SCHEMA :: [Reference] TO [btp_reader_user]; -- Schema Reference is now in DB_Reference
-- GRANT SELECT ON SCHEMA :: [Audit] TO [btp_reader_user];
-- GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [btp_reader_user]; -- Allow executing API functions/procs
-- PRINT N'  Reader permissions set for btp_reader_user.';
-- GO

-- -- Permissions for btp_writer_user (Read/Write access on specific schemas)
-- PRINT N'  Setting writer permissions for btp_writer_user...';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [BTP] TO [btp_writer_user];
-- -- GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [btp_writer_user]; -- Schema Reference is now in DB_Reference
-- GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [btp_writer_user]; -- Allow executing API functions/procs
-- -- Consider SELECT on Audit if needed
-- PRINT N'  Writer permissions set for btp_writer_user.';
-- GO

-- -- Permissions for api_service_user (Specific permissions needed by the API service)
-- PRINT N'  Setting API service permissions for api_service_user...';
-- GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [api_service_user]; -- Primary permission: execute internal APIs

-- -- API service might need to read data from BTP schema
-- GRANT SELECT ON SCHEMA :: [BTP] TO [api_service_user];
-- -- GRANT SELECT ON SCHEMA :: [Reference] TO [api_service_user]; -- Schema Reference is now in DB_Reference

-- -- API service might need to write data to BTP schema (e.g., creating certificates, household info)
-- GRANT INSERT, UPDATE, DELETE ON SCHEMA :: [BTP] TO [api_service_user];

-- -- API service might need access to the Outbox table (assuming it's in BTP schema or its own schema)
-- -- If EventOutbox is in BTP schema:
-- GRANT SELECT, INSERT, DELETE ON [BTP].[EventOutbox] TO [api_service_user];
-- -- If EventOutbox is in its own schema (e.g., Outbox):
-- -- GRANT SELECT, INSERT, DELETE ON SCHEMA :: [Outbox] TO [api_service_user];

-- -- Consider if API needs access to Audit schema
-- -- GRANT SELECT, INSERT ON SCHEMA :: [Audit] TO [api_service_user];
-- PRINT N'  API service permissions set for api_service_user.';
-- GO

-- PRINT N'Successfully completed setting up users and permissions in DB_BTP.';


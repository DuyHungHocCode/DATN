-- -- Script to create database users and assign permissions in DB_Reference (CSDL Tham chiếu Dùng chung)
-- -- This script should be run on the SQL Server instance dedicated to DB_Reference,
-- -- after DB_Reference and its schemas have been created,
-- -- and after the relevant server logins (e.g., api_service_login) have been created on the instance.

-- USE [DB_Reference];
-- GO

-- PRINT N'Setting up users and permissions in DB_Reference...';

-- --------------------------------------------------------------------------------
-- -- CREATE DATABASE USERS FROM SERVER LOGINS
-- --------------------------------------------------------------------------------
-- PRINT N'Creating database users if they do not exist...';

-- -- User for api_service_login (This service needs to read reference data)
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'api_service_user')
-- BEGIN
--     PRINT N'  Creating user: api_service_user for login api_service_login...';
--     -- Ensure the login [api_service_login] exists on this SQL Server instance first!
--     CREATE USER [api_service_user] FOR LOGIN [api_service_login];
--     PRINT N'  User api_service_user created.';
-- END
-- ELSE
--     PRINT N'  User api_service_user already exists in DB_Reference.';
-- GO

-- -- Optional: Consider creating users for direct access if needed (less common for reference DB)
-- /*
-- -- User for bca_reader_login (If direct read access from BCA app is needed)
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_reader_user')
-- BEGIN
--     PRINT N'  Creating user: bca_reader_user for login bca_reader_login...';
--     CREATE USER [bca_reader_user] FOR LOGIN [bca_reader_login];
--     PRINT N'  User bca_reader_user created.';
-- END
-- ELSE
--     PRINT N'  User bca_reader_user already exists in DB_Reference.';
-- GO

-- -- User for btp_reader_user (If direct read access from BTP app is needed)
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_reader_user')
-- BEGIN
--     PRINT N'  Creating user: btp_reader_user for login btp_reader_login...';
--     CREATE USER [btp_reader_user] FOR LOGIN [btp_reader_login];
--     PRINT N'  User btp_reader_user created.';
-- END
-- ELSE
--     PRINT N'  User btp_reader_user already exists in DB_Reference.';
-- GO
-- */

-- -- Consider a dedicated user/role for managing reference data (inserts/updates)
-- /*
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'reference_admin_user')
-- BEGIN
--     PRINT N'  Creating user: reference_admin_user for login reference_admin_login...';
--     -- Ensure the login [reference_admin_login] exists
--     CREATE USER [reference_admin_user] FOR LOGIN [reference_admin_login];
--     PRINT N'  User reference_admin_user created.';
-- END
-- ELSE
--     PRINT N'  User reference_admin_user already exists in DB_Reference.';
-- GO
-- */

-- --------------------------------------------------------------------------------
-- -- ASSIGN PERMISSIONS TO DATABASE USERS
-- --------------------------------------------------------------------------------
-- PRINT N'Assigning permissions to users in DB_Reference...';

-- -- Permissions for api_service_user (Read access to reference data)
-- PRINT N'  Setting read permissions for api_service_user on Schema [Reference]...';
-- GRANT SELECT ON SCHEMA :: [Reference] TO [api_service_user];
-- -- DENY INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [api_service_user]; -- Explicitly deny writes if needed
-- PRINT N'  Read permissions set for api_service_user.';
-- GO

-- -- Optional: Grant permissions for direct access users if created
-- /*
-- PRINT N'  Setting read permissions for bca_reader_user on Schema [Reference]...';
-- GRANT SELECT ON SCHEMA :: [Reference] TO [bca_reader_user];
-- PRINT N'  Read permissions set for bca_reader_user.';
-- GO

-- PRINT N'  Setting read permissions for btp_reader_user on Schema [Reference]...';
-- GRANT SELECT ON SCHEMA :: [Reference] TO [btp_reader_user];
-- PRINT N'  Read permissions set for btp_reader_user.';
-- GO
-- */

-- -- Optional: Grant permissions for reference data management user
-- /*
-- PRINT N'  Setting admin permissions for reference_admin_user on Schema [Reference]...';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [reference_admin_user];
-- -- Or potentially add to db_datareader, db_datawriter roles
-- -- ALTER ROLE db_datareader ADD MEMBER [reference_admin_user];
-- -- ALTER ROLE db_datawriter ADD MEMBER [reference_admin_user];
-- PRINT N'  Admin permissions set for reference_admin_user.';
-- GO
-- */

-- PRINT N'Successfully completed setting up users and permissions in DB_Reference.';


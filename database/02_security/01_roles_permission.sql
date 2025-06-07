-- Execute on the master database to ensure logins exist
USE master;
GO

PRINT 'Checking server logins...';

-- Check and create server logins if they don't exist
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bca_admin_login')
BEGIN
    PRINT 'Creating login: bca_admin_login';
    CREATE LOGIN [bca_admin_login] WITH PASSWORD = 'Duyhung12345';
END
ELSE
    PRINT 'Login bca_admin_login already exists';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'btp_admin_login')
BEGIN
    PRINT 'Creating login: btp_admin_login';
    CREATE LOGIN [btp_admin_login] WITH PASSWORD = 'Duyhung12345';
END
ELSE
    PRINT 'Login btp_admin_login already exists';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bca_reader_login')
BEGIN
    PRINT 'Creating login: bca_reader_login';
    CREATE LOGIN [bca_reader_login] WITH PASSWORD = 'Duyhung12345';
END
ELSE
    PRINT 'Login bca_reader_login already exists';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'btp_reader_login')
BEGIN
    PRINT 'Creating login: btp_reader_login';
    CREATE LOGIN [btp_reader_login] WITH PASSWORD = 'Duyhung12345';
END
ELSE
    PRINT 'Login btp_reader_login already exists';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bca_writer_login')
BEGIN
    PRINT 'Creating login: bca_writer_login';
    CREATE LOGIN [bca_writer_login] WITH PASSWORD = 'Duyhung12345';
END
ELSE
    PRINT 'Login bca_writer_login already exists';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'btp_writer_login')
BEGIN
    PRINT 'Creating login: btp_writer_login';
    CREATE LOGIN [btp_writer_login] WITH PASSWORD = 'Duyhung12345';
END
ELSE
    PRINT 'Login btp_writer_login already exists';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'api_service_login')
BEGIN
    PRINT 'Creating login: api_service_login';
    CREATE LOGIN [api_service_login] WITH PASSWORD = 'Duyhung12345';
END
ELSE
    PRINT 'Login api_service_login already exists';

GO

-- Now set up DB_BCA users and permissions
PRINT 'Setting up DB_BCA users and permissions...';
USE [DB_BCA];
GO

-- First, make sure all users exist
PRINT 'Creating users in DB_BCA if they do not exist...';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_admin_user')
BEGIN
    PRINT 'Creating user: bca_admin_user';
    CREATE USER [bca_admin_user] FOR LOGIN [bca_admin_login];
END
ELSE
    PRINT 'User bca_admin_user already exists in DB_BCA';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_reader_user')
BEGIN
    PRINT 'Creating user: bca_reader_user';
    CREATE USER [bca_reader_user] FOR LOGIN [bca_reader_login];
END
ELSE
    PRINT 'User bca_reader_user already exists in DB_BCA';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_writer_user')
BEGIN
    PRINT 'Creating user: bca_writer_user';
    CREATE USER [bca_writer_user] FOR LOGIN [bca_writer_login];
END
ELSE
    PRINT 'User bca_writer_user already exists in DB_BCA';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'api_service_user')
BEGIN
    PRINT 'Creating user: api_service_user';
    CREATE USER [api_service_user] FOR LOGIN [api_service_login];
END
ELSE
    PRINT 'User api_service_user already exists in DB_BCA';

GO

-- Now set up DB_BTP users and permissions
PRINT 'Setting up DB_BTP users and permissions...';
USE [DB_BTP];
GO

-- First, make sure all users exist
PRINT 'Creating users in DB_BTP if they do not exist...';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_admin_user')
BEGIN
    PRINT 'Creating user: btp_admin_user';
    CREATE USER [btp_admin_user] FOR LOGIN [btp_admin_login];
END
ELSE
    PRINT 'User btp_admin_user already exists in DB_BTP';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_reader_user')
BEGIN
    PRINT 'Creating user: btp_reader_user';
    CREATE USER [btp_reader_user] FOR LOGIN [btp_reader_login];
END
ELSE
    PRINT 'User btp_reader_user already exists in DB_BTP';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_writer_user')
BEGIN
    PRINT 'Creating user: btp_writer_user';
    CREATE USER [btp_writer_user] FOR LOGIN [btp_writer_login];
END
ELSE
    PRINT 'User btp_writer_user already exists in DB_BTP';

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'api_service_user')
BEGIN
    PRINT 'Creating user: api_service_user';
    CREATE USER [api_service_user] FOR LOGIN [api_service_login];
END
ELSE
    PRINT 'User api_service_user already exists in DB_BTP';

GO

-- Now assign permissions in DB_BCA
PRINT 'Assigning permissions in DB_BCA...';
USE [DB_BCA];
GO

-- Permissions for bca_admin_user (Full control)
PRINT 'Setting admin permissions in DB_BCA...';
ALTER ROLE db_owner ADD MEMBER [bca_admin_user];
GO

-- Permissions for bca_reader_user (Read-only access)
PRINT 'Setting reader permissions in DB_BCA...';
GRANT SELECT ON SCHEMA :: [BCA] TO [bca_reader_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [bca_reader_user];
GRANT SELECT ON SCHEMA :: [Audit] TO [bca_reader_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [bca_reader_user];
GO

-- Permissions for bca_writer_user (Read/Write access)
PRINT 'Setting writer permissions in DB_BCA...';
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [BCA] TO [bca_writer_user];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [bca_writer_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [bca_writer_user];
GO

-- Permissions for api_service_user (Execute internal APIs, Select data)
PRINT 'Setting API service permissions in DB_BCA...';
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [BCA] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [api_service_user];
GRANT INSERT, UPDATE, DELETE ON SCHEMA :: [BCA] TO [api_service_user];
GO

-- Now assign permissions in DB_BTP
PRINT 'Assigning permissions in DB_BTP...';
USE [DB_BTP];
GO

-- Permissions for btp_admin_user (Full control)
PRINT 'Setting admin permissions in DB_BTP...';
ALTER ROLE db_owner ADD MEMBER [btp_admin_user];
GO

-- Permissions for btp_reader_user (Read-only access)
PRINT 'Setting reader permissions in DB_BTP...';
GRANT SELECT ON SCHEMA :: [BTP] TO [btp_reader_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [btp_reader_user];
GRANT SELECT ON SCHEMA :: [Audit] TO [btp_reader_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [btp_reader_user];
GO

-- Permissions for btp_writer_user (Read/Write access)
PRINT 'Setting writer permissions in DB_BTP...';
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [BTP] TO [btp_writer_user];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [btp_writer_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [btp_writer_user];
GO

-- Permissions for api_service_user (Execute internal APIs, Select data)
PRINT 'Setting API service permissions in DB_BTP...';
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [BTP] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [api_service_user];
GRANT INSERT, UPDATE, DELETE ON SCHEMA :: [BTP] TO [api_service_user];
GO

PRINT 'Successfully completed all permission assignments';
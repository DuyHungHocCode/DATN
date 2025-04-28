-- Execute on the master database to manage logins
USE master;
GO

-- Drop existing logins if they exist
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bca_admin_login') DROP LOGIN [bca_admin_login];
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'btp_admin_login') DROP LOGIN [btp_admin_login];
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bca_reader_login') DROP LOGIN [bca_reader_login];
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'btp_reader_login') DROP LOGIN [btp_reader_login];
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'bca_writer_login') DROP LOGIN [bca_writer_login];
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'btp_writer_login') DROP LOGIN [btp_writer_login];
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'api_service_login') DROP LOGIN [api_service_login];
GO

-- Create new logins
CREATE LOGIN [bca_admin_login] WITH PASSWORD = '123';
CREATE LOGIN [btp_admin_login] WITH PASSWORD = '123';
CREATE LOGIN [bca_reader_login] WITH PASSWORD = '123';
CREATE LOGIN [btp_reader_login] WITH PASSWORD = '123';
CREATE LOGIN [bca_writer_login] WITH PASSWORD = '123';
CREATE LOGIN [btp_writer_login] WITH PASSWORD = '123';
CREATE LOGIN [api_service_login] WITH PASSWORD = '123';
GO

-- Create users in DB_BCA
USE [DB_BCA];
GO

-- Drop existing users if they exist
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_admin_user') DROP USER [bca_admin_user];
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_reader_user') DROP USER [bca_reader_user];
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'bca_writer_user') DROP USER [bca_writer_user];
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'api_service_user') DROP USER [api_service_user];
GO

-- Create users mapped to logins
CREATE USER [bca_admin_user] FOR LOGIN [bca_admin_login];
CREATE USER [bca_reader_user] FOR LOGIN [bca_reader_login];
CREATE USER [bca_writer_user] FOR LOGIN [bca_writer_login];
CREATE USER [api_service_user] FOR LOGIN [api_service_login];
GO

-- Create users in DB_BTP
USE [DB_BTP];
GO

-- Drop existing users if they exist
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_admin_user') DROP USER [btp_admin_user];
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_reader_user') DROP USER [btp_reader_user];
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'btp_writer_user') DROP USER [btp_writer_user];
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'api_service_user') DROP USER [api_service_user];
GO

-- Create users mapped to logins
CREATE USER [btp_admin_user] FOR LOGIN [btp_admin_login];
CREATE USER [btp_reader_user] FOR LOGIN [btp_reader_login];
CREATE USER [btp_writer_user] FOR LOGIN [btp_writer_login];
CREATE USER [api_service_user] FOR LOGIN [api_service_login];
GO


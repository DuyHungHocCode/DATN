-- Create schemas for DB_BCA
USE [DB_BCA];
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Reference')
BEGIN
    EXEC('CREATE SCHEMA [Reference]');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'BCA')
BEGIN
    EXEC('CREATE SCHEMA [BCA]');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Audit')
BEGIN
    EXEC('CREATE SCHEMA [Audit]');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'API_Internal')
BEGIN
    EXEC('CREATE SCHEMA [API_Internal]');
END
GO


-- Create schemas for DB_BTP
USE [DB_BTP];
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Reference')
BEGIN
    EXEC('CREATE SCHEMA [Reference]');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'BTP')
BEGIN
    EXEC('CREATE SCHEMA [BTP]');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Audit')
BEGIN
    EXEC('CREATE SCHEMA [Audit]');
END
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'API_Internal')
BEGIN
    EXEC('CREATE SCHEMA [API_Internal]');
END
GO


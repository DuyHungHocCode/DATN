-- Script to create schemas for database DB_BTP (Bộ Tư pháp)
-- This script should be run on the SQL Server instance dedicated to DB_BTP,
-- after DB_BTP has been created.

USE [DB_BTP];
GO

PRINT N'Creating schemas in DB_BTP...';

-- Schema: BTP (for core Ministry of Justice tables)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'BTP')
BEGIN
    PRINT N'  Creating schema [BTP]...';
    EXEC('CREATE SCHEMA [BTP]');
    PRINT N'  Schema [BTP] created.';
END
ELSE
    PRINT N'  Schema [BTP] already exists.';
GO

-- Schema: Audit (for audit logging tables)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Audit')
BEGIN
    PRINT N'  Creating schema [Audit]...';
    EXEC('CREATE SCHEMA [Audit]');
    PRINT N'  Schema [Audit] created.';
END
ELSE
    PRINT N'  Schema [Audit] already exists.';
GO

-- Schema: API_Internal (for internal stored procedures and functions)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'API_Internal')
BEGIN
    PRINT N'  Creating schema [API_Internal]...';
    EXEC('CREATE SCHEMA [API_Internal]');
    PRINT N'  Schema [API_Internal] created.';
END
ELSE
    PRINT N'  Schema [API_Internal] already exists.';
GO

PRINT N'Finished creating schemas in DB_BTP.';


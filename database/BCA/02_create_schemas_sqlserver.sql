-- Script to create schemas for database DB_BCA (Bộ Công an)
-- This script should be run on the SQL Server instance dedicated to DB_BCA,
-- after DB_BCA has been created.

USE [DB_BCA];
GO

PRINT N'Creating schemas in DB_BCA...';

-- Schema: BCA (for core Ministry of Public Security tables)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'BCA')
BEGIN
    PRINT N'  Creating schema [BCA]...';
    EXEC('CREATE SCHEMA [BCA]');
    PRINT N'  Schema [BCA] created.';
END
ELSE
    PRINT N'  Schema [BCA] already exists.';
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

PRINT N'Finished creating schemas in DB_BCA.';
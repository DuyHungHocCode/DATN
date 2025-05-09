-- Script to create schemas for database DB_Reference (CSDL Tham chiếu Dùng chung)
-- This script should be run on the SQL Server instance dedicated to DB_Reference,
-- after DB_Reference has been created.

USE [DB_Reference];
GO

PRINT N'Creating schemas in DB_Reference...';

-- Schema: Reference (to hold all common lookup/reference tables)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Reference')
BEGIN
    PRINT N'  Creating schema [Reference]...';
    EXEC('CREATE SCHEMA [Reference]');
    PRINT N'  Schema [Reference] created.';
END
ELSE
    PRINT N'  Schema [Reference] already exists.';
GO

-- Add other schemas here if needed for DB_Reference in the future
-- e.g., CREATE SCHEMA [Admin];

PRINT N'Finished creating schemas in DB_Reference.';


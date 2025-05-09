-- Script to create database DB_Reference (CSDL Tham chiếu Dùng chung)
-- This script should be run on the SQL Server instance dedicated to DB_Reference.
-- Ensure you are connected to the 'master' database or have appropriate permissions.

USE master;
GO

PRINT N'Checking and creating database DB_Reference...';

-- Drop DB_Reference if it exists to ensure a clean setup (optional, use with caution in non-dev environments)
IF DB_ID('DB_Reference') IS NOT NULL
BEGIN
    PRINT N'  DB_Reference exists. Dropping it...';
    ALTER DATABASE [DB_Reference] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DB_Reference];
    PRINT N'  DB_Reference dropped.';
END
GO

-- Create DB_Reference database
PRINT N'  Creating database DB_Reference...';
CREATE DATABASE [DB_Reference]
COLLATE Vietnamese_CI_AS; -- Using Vietnamese case-insensitive, accent-sensitive collation
GO

IF DB_ID('DB_Reference') IS NOT NULL
    PRINT N'  Database DB_Reference created successfully with collation Vietnamese_CI_AS.';
ELSE
    PRINT N'  ERROR: Database DB_Reference could not be created.';
GO

PRINT N'Finished script for DB_Reference creation.';


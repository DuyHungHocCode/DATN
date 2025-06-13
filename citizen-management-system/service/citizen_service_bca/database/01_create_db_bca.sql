-- Script to create database DB_BCA (Bộ Công an)
-- This script should be run on the SQL Server instance dedicated to DB_BCA.
-- Ensure you are connected to the 'master' database or have appropriate permissions.

USE master;
GO

PRINT N'Checking and creating database DB_BCA...';

-- Drop DB_BCA if it exists to ensure a clean setup (optional, use with caution in non-dev environments)
IF DB_ID('DB_BCA') IS NOT NULL
BEGIN
    PRINT N'  DB_BCA exists. Dropping it...';
    ALTER DATABASE [DB_BCA] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DB_BCA];
    PRINT N'  DB_BCA dropped.';
END
GO

-- Create DB_BCA database
PRINT N'  Creating database DB_BCA...';
CREATE DATABASE [DB_BCA]
COLLATE Vietnamese_CI_AS; -- Using Vietnamese case-insensitive, accent-sensitive collation
GO

IF DB_ID('DB_BCA') IS NOT NULL
    PRINT N'  Database DB_BCA created successfully with collation Vietnamese_CI_AS.';
ELSE
    PRINT N'  ERROR: Database DB_BCA could not be created.';
GO

PRINT N'Finished script for DB_BCA creation.';
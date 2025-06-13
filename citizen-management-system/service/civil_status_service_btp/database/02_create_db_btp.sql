-- Script to create database DB_BTP (Bộ Tư pháp)
-- This script should be run on the SQL Server instance dedicated to DB_BTP.
-- Ensure you are connected to the 'master' database or have appropriate permissions.

USE master;
GO

PRINT N'Checking and creating database DB_BTP...';

-- Drop DB_BTP if it exists
IF DB_ID('DB_BTP') IS NOT NULL
BEGIN
    PRINT N'  DB_BTP exists. Dropping it...';
    ALTER DATABASE [DB_BTP] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DB_BTP];
    PRINT N'  DB_BTP dropped.';
END
GO

-- Create DB_BTP database
PRINT N'  Creating database DB_BTP...';
CREATE DATABASE [DB_BTP]
COLLATE Vietnamese_CI_AS;
GO

IF DB_ID('DB_BTP') IS NOT NULL
    PRINT N'  Database DB_BTP created successfully with collation Vietnamese_CI_AS.';
ELSE
    PRINT N'  ERROR: Database DB_BTP could not be created.';
GO

PRINT N'Finished script for DB_BTP creation.';
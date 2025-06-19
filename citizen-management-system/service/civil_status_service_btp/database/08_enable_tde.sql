-- This script enables Transparent Data Encryption (TDE) for the DB_BTP database.
-- It should be run by a user with administrative privileges (e.g., sysadmin).

-- IMPORTANT: The master key password should be the same as the one used for DB_BCA
-- if they are on the same SQL Server instance.
-- Replace 'YourStrongPasswordHere' with the same strong, securely stored password.

-- Step 1: Switch to the master database context
USE master;
GO

-- Create a master key if it doesn't already exist.
-- This step might be redundant if the script for DB_BCA has already been run on the same instance.
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##TDE_MasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourStrongPasswordHere';
END
GO

-- Step 2: Create a certificate protected by the master key for BTP.
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'TdeCertificateBTP')
BEGIN
    CREATE CERTIFICATE TdeCertificateBTP
    WITH SUBJECT = 'BTP Database Encryption Certificate';
END
GO

-- Step 3: Switch to the target database context
USE DB_BTP;
GO

-- Create a Database Encryption Key (DEK) and protect it with the server certificate.
IF NOT EXISTS (SELECT * FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('DB_BTP'))
BEGIN
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE TdeCertificateBTP;
END
GO

-- Step 4: Enable TDE on the database
ALTER DATABASE DB_BTP
SET ENCRYPTION ON;
GO

-- Step 5: Verify that encryption is enabled and check the status
SELECT
    db.name,
    db.is_encrypted,
    keys.encryption_state,
    keys.encryption_state_desc,
    keys.percent_complete
FROM
    sys.databases db
LEFT JOIN
    sys.dm_database_encryption_keys keys ON db.database_id = keys.database_id
WHERE
    db.name = 'DB_BTP';
GO 
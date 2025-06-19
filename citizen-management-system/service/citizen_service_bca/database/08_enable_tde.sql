-- This script enables Transparent Data Encryption (TDE) for the DB_BCA database.
-- It should be run by a user with administrative privileges (e.g., sysadmin).

-- IMPORTANT: Replace 'YourStrongPasswordHere' with a strong, securely stored password.
-- This password protects the Database Master Key.

-- Step 1: Switch to the master database context to create the master key and certificate
USE master;
GO

-- Create a master key if it doesn't already exist.
-- The master key is encrypted by the service master key.
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##TDE_MasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '#Hug@12a3b45';
END
GO

-- Step 2: Create a certificate protected by the master key.
-- This certificate will be used to protect the Database Encryption Key (DEK).
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'TdeCertificateBCA')
BEGIN
    CREATE CERTIFICATE TdeCertificateBCA
    WITH SUBJECT = 'BCA Database Encryption Certificate';
END
GO

-- Step 3: Switch to the target database context
USE DB_BCA;
GO

-- Create a Database Encryption Key (DEK) and protect it with the server certificate.
IF NOT EXISTS (SELECT * FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('DB_BCA'))
BEGIN
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE TdeCertificateBCA;
END
GO

-- Step 4: Enable TDE on the database
-- This will start the encryption scan in the background.
ALTER DATABASE DB_BCA
SET ENCRYPTION ON;
GO

-- Step 5: Verify that encryption is enabled and check the status
-- The encryption_state_desc will show 'ENCRYPTED' once the process is complete.
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
    db.name = 'DB_BCA';
GO 
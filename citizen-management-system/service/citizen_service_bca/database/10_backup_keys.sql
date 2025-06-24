-- ==============================================================================
-- Script to Back Up Encryption Keys and Certificates for DB_BCA
-- ==============================================================================
-- This is a critical disaster recovery step. Without these backups, you CANNOT
-- restore a TDE-enabled database or an Always Encrypted database on a new server.
-- These backups should be stored in a highly secure, separate location from
-- the database backups.

-- IMPORTANT: Replace 'YourStrongPasswordHere' with the password used to create the
-- master key and a new password for the certificate private key.

USE master;
GO

PRINT N'Step 1: Backing up the Service Master Key (SMK)...';
-- The Service Master Key (SMK) is the root of the encryption hierarchy.
-- It's backed up to a file and protected by a password.
BACKUP SERVICE MASTER KEY
TO FILE = '/var/opt/mssql/backups/SMK_Backup.key' -- <-- Path inside the container
ENCRYPTION BY PASSWORD = 'H1u@2025';
PRINT N'  Service Master Key backed up.';
GO

PRINT N'Step 2: Backing up the Database Master Key (DMK)...';
-- The Database Master Key (DMK) is used for TDE.
BACKUP MASTER KEY
TO FILE = '/var/opt/mssql/backups/DMK_Backup_BCA.key' -- <-- Path inside the container
ENCRYPTION BY PASSWORD = 'H1u@2025';
PRINT N'  Database Master Key for BCA backed up.';
GO


PRINT N'Step 3: Backing up the TDE Certificate...';
-- The certificate used for TDE must be backed up.
BACKUP CERTIFICATE TdeCertificateBCA
TO FILE = '/var/opt/mssql/backups/TdeCertificateBCA.cer' -- <-- Path inside the container
WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/backups/TdeCertificateBCA_PrivateKey.pvk', -- <-- Path inside the container
    ENCRYPTION BY PASSWORD = 'H1u@2025' -- <-- Use a new, strong password
);
PRINT N'  TDE Certificate for BCA backed up.';
GO

PRINT N'Step 4: Backing up the Always Encrypted Column Master Key (CMK)...';
-- The CMK is stored in Azure Key Vault. Backing it up is a function of
-- Azure's disaster recovery features.
--
-- Instructions for DBA / Cloud Administrator:
-- 1. Ensure "Soft Delete" and "Purge Protection" are enabled on your Azure Key Vault.
--    This is the most critical step for preventing accidental key loss.
-- 2. Regularly back up the key metadata and versions from the vault if needed:
--    `az keyvault key backup --vault-name "your-vault-name" --name "AlwaysEncryptedCMK" --file-path "/path/to/backup/AlwaysEncryptedCMK.backup"`
-- 3. Store the backup file in a secure, separate location (e.g., different storage account).
PRINT N'  Reminder: The Always Encrypted CMK is managed and backed up via Azure Key Vault policies and procedures.';
GO

PRINT N'All key backup operations are defined. Store these files securely!';
GO 
-- ==============================================================================
-- Script to Back Up Encryption Keys and Certificates for DB_BTP
-- ==============================================================================
-- This script mirrors the backup procedure for DB_BCA. It is critical for
-- disaster recovery. Store these backups securely and separately.

-- IMPORTANT: Replace passwords with the actual secure passwords used.

USE master;
GO

PRINT N'Step 1: Backing up the Service Master Key (SMK)...';
-- This is the same SMK as for DB_BCA if on the same SQL instance.
-- Running this again will just create another backup.
BACKUP SERVICE MASTER KEY
TO FILE = '/var/opt/mssql/backups/SMK_Backup.key' -- <-- Path inside the container
ENCRYPTION BY PASSWORD = 'YourStrongPasswordHere';
PRINT N'  Service Master Key backed up (or re-backed up).';
GO

PRINT N'Step 2: Backing up the Database Master Key (DMK)...';
-- The Database Master Key for DB_BTP.
BACKUP MASTER KEY
TO FILE = '/var/opt/mssql/backups/DMK_Backup_BTP.key' -- <-- Path inside the container
ENCRYPTION BY PASSWORD = 'YourStrongPasswordHere';
PRINT N'  Database Master Key for BTP backed up.';
GO


PRINT N'Step 3: Backing up the TDE Certificate...';
-- The certificate used for TDE on DB_BTP.
BACKUP CERTIFICATE TdeCertificateBTP
TO FILE = '/var/opt/mssql/backups/TdeCertificateBTP.cer' -- <-- Path inside the container
WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/backups/TdeCertificateBTP_PrivateKey.pvk', -- <-- Path inside the container
    ENCRYPTION BY PASSWORD = 'NewStrongPasswordForBTPCertificate' -- <-- Use a new, strong password
);
PRINT N'  TDE Certificate for BTP backed up.';
GO

PRINT N'Step 4: Backing up the Always Encrypted Column Master Key (CMK)...';
-- The CMK is stored in Azure Key Vault and is shared with DB_BCA.
-- Backup procedures are handled through Azure.
--
-- Instructions for DBA / Cloud Administrator:
-- 1. Ensure "Soft Delete" and "Purge Protection" are enabled on your Azure Key Vault.
-- 2. The backup command (az keyvault key backup) only needs to be run once for the shared key.
-- 3. Refer to the corresponding backup script for DB_BCA for details.
PRINT N'  Reminder: The Always Encrypted CMK is managed and backed up via Azure Key Vault policies.';
GO

PRINT N'All key backup operations are defined. Store these files securely!';
GO 
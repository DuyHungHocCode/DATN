-- ==============================================================================
-- Script to set up Always Encrypted for sensitive columns in DB_BTP (Linux/Cross-Platform)
-- ==============================================================================
-- This script uses Azure Key Vault, the recommended approach for cross-platform environments.
-- It should be run by a DBA using an Azure-authenticated client like SSMS or Azure Data Studio.

-- ------------------------------------------------------------------------------
-- PRE-REQUISITE: Use the SAME Azure Key Vault Key as DB_BCA
-- ------------------------------------------------------------------------------
-- For consistency and easier management, both databases should use the same
-- Column Master Key stored in Azure Key Vault.
--
-- Refer to the prerequisite steps in `citizen_service_bca/database/09_setup_always_encrypted.sql`.
-- You will need the Key Identifier (URI) for the key in your vault.
-- ------------------------------------------------------------------------------

USE [DB_BTP];
GO

-- Step 1: Create the Column Master Key (CMK) definition.
-- IMPORTANT: Replace the KEY_PATH with your actual Azure Key Vault Key Identifier.
PRINT N'Step 1: Creating Column Master Key (CMK) pointing to Azure Key Vault...';

IF NOT EXISTS (SELECT * FROM sys.column_master_keys WHERE name = 'CMK_AKV_Auto')
BEGIN
    CREATE COLUMN MASTER KEY [CMK_AKV_Auto]
    WITH (
        KEY_STORE_PROVIDER_NAME = 'AZURE_KEY_VAULT',
        KEY_PATH = 'https://your-vault-name.vault.azure.net/keys/AlwaysEncryptedCMK/your-key-version' -- <-- REPLACE WITH YOUR KEY VAULT KEY IDENTIFIER
    );
    PRINT N'  Column Master Key [CMK_AKV_Auto] created.';
END
ELSE
BEGIN
    PRINT N'  Column Master Key [CMK_AKV_Auto] already exists.';
END
GO

-- Step 2: Create the Column Encryption Key (CEK).
-- This can be the same CEK definition as in DB_BCA.
PRINT N'Step 2: Creating Column Encryption Key (CEK)...';

IF NOT EXISTS (SELECT * FROM sys.column_encryption_keys WHERE name = 'CEK_Auto')
BEGIN
    CREATE COLUMN ENCRYPTION KEY [CEK_Auto]
    WITH VALUES (
        COLUMN_MASTER_KEY = [CMK_AKV_Auto],
        ALGORITHM = 'RSA_OAEP'
    );
    PRINT N'  Column Encryption Key [CEK_Auto] created.';
END
ELSE
BEGIN
    PRINT N'  Column Encryption Key [CEK_Auto] already exists.';
END
GO

-- Step 3: Encrypt the target columns.
-- These templates should be executed by a DBA during a maintenance window.
PRINT N'Step 3: Altering tables in BTP to encrypt sensitive columns...';

/*
-- Example: Encrypting `father_full_name` in BirthCertificate table
-- RANDOMIZED encryption is best for data not used in lookups.
ALTER TABLE [BTP].[BirthCertificate]
ALTER COLUMN [father_full_name] NVARCHAR(100)
    ENCRYPTED WITH (
        ENCRYPTION_TYPE = RANDOMIZED,
        ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256',
        COLUMN_ENCRYPTION_KEY = [CEK_Auto]
    ) NULL;
PRINT N'  Column [father_full_name] in [BTP].[BirthCertificate] configured for encryption.';
GO
*/

PRINT N'Script finished. Please review the commented-out ALTER TABLE statements.';
PRINT N'These should be executed carefully by a DBA from an Azure-authenticated client.';
GO 
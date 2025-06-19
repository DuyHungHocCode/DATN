-- ==============================================================================
-- Script to set up Always Encrypted for sensitive columns in DB_BCA (Linux/Cross-Platform)
-- ==============================================================================
-- This script uses Azure Key Vault to store the Column Master Key (CMK), which is
-- the recommended approach for cross-platform environments (Linux, macOS, Windows).

-- ------------------------------------------------------------------------------
-- PRE-REQUISITE: Create a Key in Azure Key Vault (AKV)
-- ------------------------------------------------------------------------------
-- This step must be performed using the Azure CLI (`az`) or Azure Portal.
-- You must have an Azure Subscription.
--
-- 1. Install Azure CLI on your Ubuntu machine.
-- 2. Login to Azure: `az login`
-- 3. Create a Key Vault (or use an existing one).
--    `az keyvault create --name "your-vault-name" --resource-group "your-rg" --location "East US"`
-- 4. Create a key within the vault. This will be your CMK.
--    `az keyvault key create --vault-name "your-vault-name" --name "AlwaysEncryptedCMK" --protection rsa`
-- 5. Grant your user account and the application's service principal permissions
--    (get, wrapKey, unwrapKey) to the key in the vault's Access Policies.
--
-- 6. Note the Key's URI (also called Key Identifier) from the output. It will look like:
--    https://your-vault-name.vault.azure.net/keys/AlwaysEncryptedCMK/xxxxxxxxxxxx
-- ------------------------------------------------------------------------------

USE [DB_BCA];
GO

-- Step 1: Create the Column Master Key (CMK) definition in the database.
-- This definition points to the key you created in Azure Key Vault.
--
-- IMPORTANT: Replace the KEY_PATH with the Key Identifier from your Azure Key Vault.
--
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
-- This key is encrypted by the CMK stored in Azure Key Vault.
PRINT N'Step 2: Creating Column Encryption Key (CEK)...';

IF NOT EXISTS (SELECT * FROM sys.column_encryption_keys WHERE name = 'CEK_Auto')
BEGIN
    -- This command must be run from a client that can authenticate to Azure Key Vault.
    -- SSMS running on a machine where you have run `az login` can execute this.
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
-- This process remains the same, but the tool running the query (e.g., SSMS, Azure Data Studio)
-- must be able to authenticate to Azure Key Vault to access the CMK for encrypting the CEK.
-- It's highly recommended to perform this during a maintenance window.

PRINT N'Step 3: Altering table BCA.IdentificationCard to encrypt [card_number]...';

-- For a column like 'card_number' that will be used in lookups (WHERE clauses),
-- we use DETERMINISTIC encryption.

/*
ALTER TABLE [BCA].[IdentificationCard]
ALTER COLUMN [card_number] VARCHAR(12)
    ENCRYPTED WITH (
        ENCRYPTION_TYPE = DETERMINISTIC,
        ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256',
        COLUMN_ENCRYPTION_KEY = [CEK_Auto]
    ) NOT NULL;

PRINT N'  Column [card_number] in [BCA].[IdentificationCard] has been configured for encryption.';
GO
*/

PRINT N'Script finished. Please review the commented-out ALTER TABLE statements.';
PRINT N'These should be executed carefully by a DBA from an Azure-authenticated client.';
GO 
-- =============================================================================
-- File: database/schemas/public_security/user_account.sql
-- Description: Creates the user_account table in the public_security schema
-- =============================================================================

\echo 'Creating user_account table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.user_account CASCADE;

-- Create the user_account table
CREATE TABLE public_security.user_account (
    user_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12), -- References public_security.citizen
    username VARCHAR(50) NOT NULL, -- Unique username for login
    password_hash VARCHAR(255) NOT NULL, -- Securely stored password hash
    user_type user_type NOT NULL, -- Type of user (Công dân, Cán bộ)
    status VARCHAR(20) NOT NULL DEFAULT 'Active', -- Current status of the account
    last_login_date TIMESTAMP WITH TIME ZONE, -- Time of last successful login
    last_login_ip VARCHAR(45), -- IP address of last login
    two_factor_enabled BOOLEAN DEFAULT FALSE, -- Whether 2FA is enabled
    locked_until TIMESTAMP WITH TIME ZONE, -- Account locked until this time
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Primary key constraint:
   - user_id as primary key

2. Unique constraints:
   - username must be unique
   - citizen_id must be unique when not NULL (one account per citizen)

3. Foreign key constraints:
   - citizen_id -> public_security.citizen

4. Indexes:
   - user_id (primary key index)
   - username (for login lookups)
   - citizen_id (for citizen account lookups)
   - user_type (for filtering by type)
   - status (for active account filtering)
   - last_login_date (for inactivity monitoring)

5. Triggers:
   - Update updated_at timestamp on record modification
*/
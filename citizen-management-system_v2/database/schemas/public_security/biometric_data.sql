-- =============================================================================
-- File: database/schemas/public_security/biometric_data.sql
-- Description: Creates the biometric_data table in the public_security schema
-- =============================================================================

\echo 'Creating biometric_data table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.biometric_data CASCADE;

-- Create the biometric_data table
CREATE TABLE public_security.biometric_data (
    biometric_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    biometric_type biometric_type NOT NULL, -- Type of biometric data (fingerprint, face, iris, voice, DNA)
    biometric_sub_type VARCHAR(50), -- Specific subtype (e.g., which finger, left/right eye)
    biometric_data BYTEA NOT NULL, -- Raw biometric data in binary format
    biometric_format VARCHAR(50) NOT NULL, -- Data format (JPG, WSQ, ISO, etc.)
    biometric_template BYTEA, -- Processed template for matching
    capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- When the biometric was captured
    quality SMALLINT, -- Quality score (0-100)
    device_id VARCHAR(50), -- ID of capture device
    device_model VARCHAR(100), -- Model of capture device
    status BOOLEAN DEFAULT TRUE, -- Whether this biometric is active/current
    reason TEXT, -- Reason for update or quality issues
    region_id SMALLINT, -- References reference.regions
    province_id INT, -- References reference.provinces
    geographical_region VARCHAR(20), -- Used for partitioning (Bắc, Trung, Nam)
    encryption_type VARCHAR(50), -- Method used to encrypt the biometric data
    hash_value VARCHAR(128), -- Hash value for data integrity verification
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);

COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Foreign Data Wrapper configuration:
   - Create foreign table definitions in Ministry of Justice database and Central Server
   - Configure appropriate user mappings and permissions

2. Primary key constraint:
   - biometric_id as primary key

3. Unique constraints:
   - No duplicate biometric types for the same citizen
     (citizen_id, biometric_type, biometric_sub_type) must be unique

4. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Indexes:
   - biometric_id (primary key index)
   - citizen_id (for citizen lookups)
   - biometric_type, biometric_sub_type (for specific biometric queries)
   - capture_date (for timeline queries)
   - quality (for filtering by quality)
   - geographical_region (for partitioning)
   - status (for active biometric records)

6. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

7. Check constraints:
   - Validate quality is between 0 and 100
   - Validate biometric_format based on biometric_type
   - Validate appropriate sub_types for each biometric_type

8. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for all biometric data access and changes
   - Verify hash integrity before updates
   - Handle partitioning logic

9. Security measures:
   - Row-level security policies for biometric data access
   - Encryption and decryption functions for biometric_data field
   - Access logging for all queries to this table
*/
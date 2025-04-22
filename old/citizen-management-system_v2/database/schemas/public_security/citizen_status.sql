-- =============================================================================
-- File: database/schemas/public_security/citizen_status.sql
-- Description: Creates the citizen_status table in the public_security schema
-- Version: 1.0
-- 
-- This file only creates the table structure. Constraints and indexes will be
-- defined in separate files to maintain clean separation of concerns.
-- Since FDW will be used for cross-database access, the table is only created
-- in the Ministry of Public Security database.
-- =============================================================================

\echo 'Creating citizen_status table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_status CASCADE;

-- Create the citizen_status table
CREATE TABLE public_security.citizen_status (
    status_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    status_type death_status NOT NULL DEFAULT 'Còn sống', -- Current status (alive, deceased, missing)
    status_date DATE NOT NULL, -- When the status change occurred
    description TEXT, -- Detailed description of status change
    cause VARCHAR(200), -- Cause of death or disappearance if applicable
    location VARCHAR(200), -- Where the status change occurred
    authority_id SMALLINT, -- References reference.authorities (authority that certified status)
    document_number VARCHAR(50), -- Reference number of official document
    document_date DATE, -- Date of official document
    certificate_id VARCHAR(50), -- ID of related certificate (e.g., death certificate)
    reported_by VARCHAR(100), -- Person who reported the status change
    relationship VARCHAR(50), -- Relationship of reporter to citizen
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Verification status of this record
    status BOOLEAN DEFAULT TRUE, -- Whether this record is active/current
    notes TEXT, -- Additional information
    region_id SMALLINT, -- References reference.regions
    province_id INT, -- References reference.provinces
    geographical_region VARCHAR(20), -- Used for partitioning (Bắc, Trung, Nam)
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
   - status_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - status_id (primary key index)
   - citizen_id (for citizen lookups)
   - status_type (for filtering by status type)
   - status_date (for timeline queries)
   - document_number (for document lookups)
   - geographical_region (for partitioning)

5. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

6. Check constraints:
   - Validate status_date is not in the future
   - Validate document_date is not in the future
   - Validate document_date is not before status_date
   - Require cause and location when status_type is 'Đã mất' or 'Mất tích'

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for status changes
   - Update the main citizen record's death_status when this table changes
   - Notify relevant authorities when a death or missing status is recorded
   - Handle partitioning logic

8. Views:
   - Current status view showing only the latest status for each citizen
   - Death registry view for mortality statistics
   - Missing persons view for active missing person cases
*/
-- =============================================================================
-- File: database/schemas/public_security/citizen_address.sql
-- Description: Creates the citizen_address table in the public_security schema
-- Version: 1.0
-- =============================================================================

\echo 'Creating citizen_address table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_address CASCADE;

-- Create the citizen_address table
CREATE TABLE public_security.citizen_address (
    citizen_address_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    address_id INT NOT NULL, -- References public_security.address
    address_type address_type NOT NULL, -- Type of address (permanent, temporary, current, etc.)
    from_date DATE NOT NULL, -- Date from which this address is valid
    to_date DATE, -- Date until which this address is valid (NULL for current addresses)
    is_primary BOOLEAN DEFAULT FALSE, -- Whether this is the primary address
    status BOOLEAN DEFAULT TRUE, -- Whether this address association is active
    registration_document_no VARCHAR(50), -- Reference number of registration document
    registration_date DATE, -- Date of address registration
    issuing_authority_id SMALLINT, -- References reference.authorities
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Status of address verification
    verification_date DATE, -- Date of address verification
    verified_by VARCHAR(100), -- Person who verified the address
    residential_status VARCHAR(50), -- Status of residency (owner, tenant, etc.)
    household_id VARCHAR(50), -- ID of household at this address (if applicable)
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
   - citizen_address_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - address_id -> public_security.address
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - citizen_address_id (primary key index)
   - citizen_id (for citizen lookups)
   - address_id (for address lookups)
   - address_type (for filtering by address type)
   - from_date, to_date (for timeline queries)
   - status (for active address records)
   - geographical_region (for partitioning)

5. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

6. Check constraints:
   - Validate from_date is not in the future
   - Validate to_date is after from_date when provided
   - Validate address_type is appropriate for the registration document
   - Ensure only one primary address per citizen at any given time

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for address changes
   - Enforce constraints between permanent_residence, temporary_residence and this table
   - Update to_date on existing primary address when a new primary is set
   - Handle partitioning logic

8. Views:
   - Current address view showing only active addresses for each citizen
   - Address history view showing all addresses with timeline
   - Permanent residence view filtered by address_type
*/
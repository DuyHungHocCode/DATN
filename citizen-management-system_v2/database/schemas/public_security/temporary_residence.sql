-- =============================================================================
-- File: database/schemas/public_security/temporary_residence.sql
-- Description: Creates the temporary_residence table in the public_security schema
-- =============================================================================

\echo 'Creating temporary_residence table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.temporary_residence CASCADE;

-- Create the temporary_residence table
CREATE TABLE public_security.temporary_residence (
    temporary_residence_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    address_id INT NOT NULL, -- References public_security.address
    registration_date DATE NOT NULL, -- Date of registration
    expiry_date DATE, -- Expiration date of temporary residence
    purpose TEXT, -- Purpose of temporary residence
    issuing_authority_id SMALLINT, -- References reference.authorities
    registration_number VARCHAR(50), -- Official registration number
    status VARCHAR(50) DEFAULT 'Active', -- Current status (Active, Expired, Cancelled, etc.)
    permanent_address_id INT, -- References public_security.address
    host_name VARCHAR(100), -- Name of the residence host
    host_citizen_id VARCHAR(12), -- References public_security.citizen
    host_relationship VARCHAR(50), -- Relationship to the host
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Verification status
    verified_by VARCHAR(100), -- Who verified the registration
    verification_date DATE, -- When the registration was verified
    extension_count SMALLINT DEFAULT 0, -- Number of times this registration has been extended
    last_extension_date DATE, -- Date of the most recent extension
    household_id VARCHAR(50), -- Reference to household (if applicable)
    region_id SMALLINT, -- References reference.regions
    province_id INT, -- References reference.provinces
    geographical_region VARCHAR(20), -- Used for partitioning (Bắc, Trung, Nam)
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế', -- Sensitivity level
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
   - temporary_residence_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - address_id -> public_security.address
   - permanent_address_id -> public_security.address
   - host_citizen_id -> public_security.citizen
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - temporary_residence_id (primary key index)
   - citizen_id (for citizen lookups)
   - address_id (for address lookups)
   - registration_date, expiry_date (for date range queries)
   - status (for active residence records)
   - registration_number (for document lookups)
   - host_citizen_id (for host lookups)
   - geographical_region (for partitioning)

5. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

6. Check constraints:
   - Validate registration_date is not in the future
   - Validate expiry_date is after registration_date
   - Validate address_id != permanent_address_id (temporary residence must be different from permanent)

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for temporary residence registrations
   - Automatically update status when expiry_date is reached
   - Notify relevant authorities when a registration is about to expire
   - Update extension_count and last_extension_date when extended
   - Handle partitioning logic

8. Views:
   - Current residences view showing only active temporary residences
   - Residence history view showing complete temporary residence timeline
   - Expired residences view for follow-up and enforcement
   - Statistics view for reporting on temporary residence patterns
   - Host view showing all citizens hosted by a specific individual
*/
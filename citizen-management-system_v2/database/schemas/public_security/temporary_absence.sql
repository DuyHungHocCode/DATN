-- =============================================================================
-- File: database/schemas/public_security/temporary_absence.sql
-- Description: Creates the temporary_absence table in the public_security schema
-- =============================================================================

\echo 'Creating temporary_absence table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.temporary_absence CASCADE;

-- Create the temporary_absence table
CREATE TABLE public_security.temporary_absence (
    temporary_absence_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    from_date DATE NOT NULL, -- Start date of absence
    to_date DATE, -- End date of absence (can be NULL for indefinite absence)
    reason TEXT, -- Detailed reason for temporary absence
    destination_address_id INT, -- References public_security.address
    destination_detail TEXT, -- Additional details about the destination
    contact_information TEXT, -- How to contact the citizen during absence
    registration_authority_id SMALLINT, -- References reference.authorities
    registration_number VARCHAR(50), -- Official registration number
    status VARCHAR(50) DEFAULT 'Active', -- Current status (Active, Expired, Cancelled, etc.)
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Verification status
    verified_by VARCHAR(100), -- Who verified the registration
    verification_date DATE, -- When the registration was verified
    return_date DATE, -- Actual date of return (if different from to_date)
    return_status VARCHAR(50), -- Status upon return (if applicable)
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
   - temporary_absence_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - destination_address_id -> public_security.address
   - registration_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - temporary_absence_id (primary key index)
   - citizen_id (for citizen lookups)
   - from_date, to_date (for date range queries)
   - status (for active absence records)
   - registration_number (for document lookups)
   - geographical_region (for partitioning)

5. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

6. Check constraints:
   - Validate from_date is not in the future
   - Validate to_date is after from_date when provided
   - Validate return_date is not before from_date when provided

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for temporary absence registrations
   - Automatically update status when to_date or return_date is reached
   - Notify relevant authorities when a registration is about to expire
   - Handle partitioning logic

8. Views:
   - Current absences view showing only active absences
   - Absence history view showing complete absence timeline
   - Expired absences without return_date for follow-up
   - Statistics view for reporting on temporary absence patterns
*/
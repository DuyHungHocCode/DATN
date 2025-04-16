-- =============================================================================
-- File: database/schemas/public_security/citizen.sql
-- Description: Creates the citizen table in the public_security schema
-- =============================================================================

\echo 'Creating citizen table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen CASCADE;

-- Create the citizen table
CREATE TABLE public_security.citizen (
    citizen_id VARCHAR(12), -- Primary key will be defined in constraints file
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    place_of_birth TEXT NOT NULL,
    gender gender_type NOT NULL,
    ethnicity_id SMALLINT, -- References reference.ethnicities
    religion_id SMALLINT, -- References reference.religions
    nationality_id SMALLINT, -- References reference.nationalities 
    blood_type blood_type DEFAULT 'Không xác định',
    death_status death_status DEFAULT 'Còn sống',
    birth_certificate_no VARCHAR(20), -- Will reference justice.birth_certificate
    marital_status marital_status DEFAULT 'Độc thân',
    education_level education_level DEFAULT 'Chưa đi học',
    occupation_id SMALLINT, -- References reference.occupations
    occupation_detail TEXT,
    tax_code VARCHAR(13), -- Tax identification number
    social_insurance_no VARCHAR(13), -- Social insurance number
    health_insurance_no VARCHAR(15), -- Health insurance number
    father_citizen_id VARCHAR(12), -- References public_security.citizen
    mother_citizen_id VARCHAR(12), -- References public_security.citizen
    region_id SMALLINT, -- References reference.regions
    province_id INT, -- References reference.provinces
    geographical_region VARCHAR(20), -- Used for partitioning (Bắc, Trung, Nam)
    avatar BYTEA, -- Base profile image
    notes TEXT,
    status BOOLEAN DEFAULT TRUE, -- Active status
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
   - citizen_id as primary key

3. Foreign key constraints:
   - ethnicity_id -> reference.ethnicities
   - religion_id -> reference.religions
   - nationality_id -> reference.nationalities
   - occupation_id -> reference.occupations
   - father_citizen_id -> public_security.citizen
   - mother_citizen_id -> public_security.citizen
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - citizen_id (primary key index)
   - father_citizen_id, mother_citizen_id (for family lookups)
   - full_name (for name searches)
   - date_of_birth (for age queries)
   - region_id, province_id (for geographic queries)
   - geographical_region (for partitioning)
   - status (for active record queries)

5. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

6. Check constraints:
   - Validate citizen_id format (12 digits)
   - Validate tax_code format
   - Validate social_insurance_no format
   - Validate date_of_birth is valid and not in future

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging on record changes
   - Handle partitioning logic
*/
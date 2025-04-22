-- =============================================================================
-- File: database/schemas/justice/birth_certificate.sql
-- Description: Creates the birth_certificate table in the justice schema
-- Version: 1.0
-- 
-- This file only creates the table structure. Constraints and indexes will be
-- defined in separate files to maintain clean separation of concerns.
-- =============================================================================

\echo 'Creating birth_certificate table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.birth_certificate CASCADE;

-- Create the birth_certificate table
CREATE TABLE justice.birth_certificate (
    birth_certificate_id SERIAL,
    citizen_id VARCHAR(12) NOT NULL,
    birth_certificate_no VARCHAR(20) NOT NULL,
    registration_date DATE NOT NULL,
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    issuing_authority_id SMALLINT,
    place_of_birth TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender_at_birth gender_type NOT NULL,
    father_full_name VARCHAR(100),
    father_citizen_id VARCHAR(12),
    father_date_of_birth DATE,
    father_nationality_id SMALLINT,
    mother_full_name VARCHAR(100),
    mother_citizen_id VARCHAR(12),
    mother_date_of_birth DATE,
    mother_nationality_id SMALLINT,
    declarant_name VARCHAR(100) NOT NULL,
    declarant_citizen_id VARCHAR(12),
    declarant_relationship VARCHAR(50),
    witness1_name VARCHAR(100),
    witness2_name VARCHAR(100),
    birth_notification_no VARCHAR(50),
    status BOOLEAN DEFAULT TRUE,
    notes TEXT,
    region_id SMALLINT,
    province_id INT,
    geographical_region VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);

-- -- Create indexes for birth_certificate table
-- CREATE INDEX idx_birth_certificate_citizen_id ON justice.birth_certificate(citizen_id);
-- CREATE INDEX idx_birth_certificate_birth_certificate_no ON justice.birth_certificate(birth_certificate_no);
-- CREATE INDEX idx_birth_certificate_registration_date ON justice.birth_certificate(registration_date);
-- CREATE INDEX idx_birth_certificate_date_of_birth ON justice.birth_certificate(date_of_birth);
-- CREATE INDEX idx_birth_certificate_father_citizen_id ON justice.birth_certificate(father_citizen_id);
-- CREATE INDEX idx_birth_certificate_mother_citizen_id ON justice.birth_certificate(mother_citizen_id);
-- CREATE INDEX idx_birth_certificate_geographical_region ON justice.birth_certificate(geographical_region);

COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Foreign Data Wrapper configuration:
   - Configure FDW for cross-database access to public_security.citizen

2. Primary key constraint:
   - birth_certificate_id as primary key

3. Unique constraints:
   - birth_certificate_no must be unique
   - Each citizen can only have one birth certificate

4. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - father_citizen_id -> public_security.citizen
   - mother_citizen_id -> public_security.citizen
   - declarant_citizen_id -> public_security.citizen
   - father_nationality_id -> reference.nationalities
   - mother_nationality_id -> reference.nationalities
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Check constraints:
   - date_of_birth cannot be in the future
   - registration_date must be on or after date_of_birth

6. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for birth certificate changes
   - Validation of parent-child relationships
   - Handle partitioning logic

7. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)
*/
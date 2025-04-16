-- =============================================================================
-- File: database/schemas/justice/marriage.sql
-- Description: Creates the marriage table in the justice schema
-- Version: 1.0
-- =============================================================================

\echo 'Creating marriage table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.marriage CASCADE;

-- Create the marriage table
CREATE TABLE justice.marriage (
    marriage_id SERIAL,
    marriage_certificate_no VARCHAR(20) NOT NULL,
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    husband_id VARCHAR(12) NOT NULL,
    husband_full_name VARCHAR(100) NOT NULL,
    husband_date_of_birth DATE NOT NULL,
    husband_nationality_id SMALLINT NOT NULL,
    husband_previous_marriage_status VARCHAR(50),
    wife_id VARCHAR(12) NOT NULL,
    wife_full_name VARCHAR(100) NOT NULL,
    wife_date_of_birth DATE NOT NULL,
    wife_nationality_id SMALLINT NOT NULL,
    wife_previous_marriage_status VARCHAR(50),
    marriage_date DATE NOT NULL,
    registration_date DATE NOT NULL,
    issuing_authority_id SMALLINT,
    issuing_place TEXT,
    witness1_name VARCHAR(100),
    witness2_name VARCHAR(100),
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

-- Create indexes for marriage table
-- CREATE INDEX idx_marriage_marriage_certificate_no ON justice.marriage(marriage_certificate_no);
-- CREATE INDEX idx_marriage_husband_id ON justice.marriage(husband_id);
-- CREATE INDEX idx_marriage_wife_id ON justice.marriage(wife_id);
-- CREATE INDEX idx_marriage_marriage_date ON justice.marriage(marriage_date);
-- CREATE INDEX idx_marriage_registration_date ON justice.marriage(registration_date);
-- CREATE INDEX idx_marriage_geographical_region ON justice.marriage(geographical_region);

COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Foreign Data Wrapper configuration:
   - Configure FDW for cross-database access to public_security.citizen

2. Primary key constraint:
   - marriage_id as primary key

3. Unique constraints:
   - marriage_certificate_no must be unique
   - A citizen can only be a husband or wife in one active marriage at a time

4. Foreign key constraints:
   - husband_id -> public_security.citizen
   - wife_id -> public_security.citizen
   - husband_nationality_id -> reference.nationalities
   - wife_nationality_id -> reference.nationalities
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Check constraints:
   - husband_date_of_birth and wife_date_of_birth must make them at least legal age
   - marriage_date cannot be in the future
   - registration_date must be on or after marriage_date
   - husband_id and wife_id cannot be the same person

6. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for marriage certificate changes
   - Automatic update of marital_status in public_security.citizen
   - Handle partitioning logic

7. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)
*/
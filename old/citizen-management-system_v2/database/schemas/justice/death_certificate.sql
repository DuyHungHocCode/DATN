-- =============================================================================
-- File: database/schemas/justice/death_certificate.sql
-- Description: Creates the death_certificate table in the justice schema
-- Version: 1.0
-- =============================================================================

\echo 'Creating death_certificate table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.death_certificate CASCADE;

-- Create the death_certificate table
CREATE TABLE justice.death_certificate (
    death_certificate_id SERIAL,
    citizen_id VARCHAR(12) NOT NULL,
    death_certificate_no VARCHAR(20) NOT NULL,
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    date_of_death DATE NOT NULL,
    time_of_death TIME,
    place_of_death TEXT NOT NULL,
    cause_of_death TEXT,
    declarant_name VARCHAR(100) NOT NULL,
    declarant_citizen_id VARCHAR(12),
    declarant_relationship VARCHAR(50),
    registration_date DATE NOT NULL,
    issuing_authority_id SMALLINT,
    death_notification_no VARCHAR(50),
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

-- Create indexes for death_certificate table
-- CREATE INDEX idx_death_certificate_citizen_id ON justice.death_certificate(citizen_id);
-- CREATE INDEX idx_death_certificate_death_certificate_no ON justice.death_certificate(death_certificate_no);
-- CREATE INDEX idx_death_certificate_date_of_death ON justice.death_certificate(date_of_death);
-- CREATE INDEX idx_death_certificate_registration_date ON justice.death_certificate(registration_date);
-- CREATE INDEX idx_death_certificate_declarant_citizen_id ON justice.death_certificate(declarant_citizen_id);
-- CREATE INDEX idx_death_certificate_geographical_region ON justice.death_certificate(geographical_region);

COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Foreign Data Wrapper configuration:
   - Configure FDW for cross-database access to public_security.citizen

2. Primary key constraint:
   - death_certificate_id as primary key

3. Unique constraints:
   - death_certificate_no must be unique
   - Each citizen can only have one death certificate

4. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - declarant_citizen_id -> public_security.citizen
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Check constraints:
   - date_of_death cannot be in the future
   - registration_date must be on or after date_of_death

6. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for death certificate changes
   - Automatic update of citizen status in public_security.citizen_status
   - Handle partitioning logic

7. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)
*/
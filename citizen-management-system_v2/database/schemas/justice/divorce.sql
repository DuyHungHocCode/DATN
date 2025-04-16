-- =============================================================================
-- File: database/schemas/justice/divorce.sql
-- Description: Creates the divorce table in the justice schema
-- Version: 1.0
-- =============================================================================

\echo 'Creating divorce table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.divorce CASCADE;

-- Create the divorce table
CREATE TABLE justice.divorce (
    divorce_id SERIAL,
    divorce_certificate_no VARCHAR(20) NOT NULL,
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    marriage_id INT NOT NULL,
    divorce_date DATE NOT NULL,
    registration_date DATE NOT NULL,
    court_name VARCHAR(200) NOT NULL,
    judgment_no VARCHAR(50) NOT NULL,
    judgment_date DATE NOT NULL,
    issuing_authority_id SMALLINT,
    reason TEXT,
    child_custody TEXT,
    property_division TEXT,
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

-- Create indexes for divorce table
-- CREATE INDEX idx_divorce_divorce_certificate_no ON justice.divorce(divorce_certificate_no);
-- CREATE INDEX idx_divorce_marriage_id ON justice.divorce(marriage_id);
-- CREATE INDEX idx_divorce_divorce_date ON justice.divorce(divorce_date);
-- CREATE INDEX idx_divorce_registration_date ON justice.divorce(registration_date);
-- CREATE INDEX idx_divorce_judgment_no ON justice.divorce(judgment_no);
-- CREATE INDEX idx_divorce_geographical_region ON justice.divorce(geographical_region);

COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Foreign Data Wrapper configuration:
   - Configure FDW for cross-database access if needed

2. Primary key constraint:
   - divorce_id as primary key

3. Unique constraints:
   - divorce_certificate_no must be unique
   - judgment_no must be unique
   - Only one divorce record per marriage (marriage_id must be unique)

4. Foreign key constraints:
   - marriage_id -> justice.marriage
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Check constraints:
   - divorce_date cannot be in the future
   - registration_date must be on or after divorce_date
   - judgment_date must be on or before registration_date
   - divorce_date must be after the marriage date (requires join with marriage table)

6. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for divorce certificate changes
   - Automatic update of marital_status in public_security.citizen for both parties
   - Update the status of the related marriage record
   - Handle partitioning logic

7. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)
*/
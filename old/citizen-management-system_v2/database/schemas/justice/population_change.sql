-- =============================================================================
-- File: database/schemas/justice/population_change.sql
-- Description: Creates the population_change table in the justice schema
-- Version: 1.0
-- =============================================================================

\echo 'Creating population_change table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.population_change CASCADE;

-- Create the population_change table
CREATE TABLE justice.population_change (
    change_id SERIAL,
    citizen_id VARCHAR(12) NOT NULL,
    change_type population_change_type NOT NULL,
    change_date DATE NOT NULL,
    source_location_id INT,
    destination_location_id INT,
    reason TEXT,
    related_document_no VARCHAR(50),
    processing_authority_id SMALLINT,
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

-- Create indexes for population_change table
CREATE INDEX idx_population_change_citizen_id ON justice.population_change(citizen_id);
CREATE INDEX idx_population_change_change_type ON justice.population_change(change_type);
CREATE INDEX idx_population_change_change_date ON justice.population_change(change_date);
CREATE INDEX idx_population_change_source_location_id ON justice.population_change(source_location_id);
CREATE INDEX idx_population_change_destination_location_id ON justice.population_change(destination_location_id);
CREATE INDEX idx_population_change_geographical_region ON justice.population_change(geographical_region);

COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Foreign Data Wrapper configuration:
   - Configure FDW for cross-database access to public_security.citizen

2. Primary key constraint:
   - change_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - source_location_id -> public_security.address
   - destination_location_id -> public_security.address
   - processing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Check constraints:
   - change_date cannot be in the future
   - Validate that source_location_id is not NULL for certain change_types (e.g., 'Chuyển đi')
   - Validate that destination_location_id is not NULL for certain change_types (e.g., 'Chuyển đến')

5. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for population changes
   - Automatic updates to related tables based on change_type
   - Handle partitioning logic

6. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

7. Views:
   - Population movement statistics view
   - Migration patterns view
   - Population growth/decline by region view
*/
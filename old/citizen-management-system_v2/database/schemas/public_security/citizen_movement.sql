-- =============================================================================
-- File: database/schemas/public_security/citizen_movement.sql
-- Description: Creates the citizen_movement table in the public_security schema
-- Version: 1.0
-- 
-- This file only creates the table structure. Constraints and indexes will be
-- defined in separate files to maintain clean separation of concerns.
-- Since FDW will be used for cross-database access, the table is only created
-- in the Ministry of Public Security database.
-- =============================================================================

\echo 'Creating citizen_movement table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_movement CASCADE;

-- Create the citizen_movement table
CREATE TABLE public_security.citizen_movement (
    movement_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    movement_type movement_type NOT NULL, -- Type of movement (domestic/exit/entry/re-entry)
    from_address_id INT, -- References public_security.address (source address)
    to_address_id INT, -- References public_security.address (destination address)
    from_country_id SMALLINT, -- References reference.nationalities (for international movement)
    to_country_id SMALLINT, -- References reference.nationalities (for international movement)
    departure_date DATE NOT NULL, -- Date of departure
    arrival_date DATE, -- Date of arrival (NULL for ongoing movements)
    purpose VARCHAR(200), -- Purpose of movement
    document_no VARCHAR(50), -- Reference number of related document
    document_type VARCHAR(50), -- Type of document (passport, visa, etc.)
    document_issue_date DATE, -- Date the document was issued
    document_expiry_date DATE, -- Date the document expires
    carrier VARCHAR(100), -- Transportation carrier (airline, etc.)
    border_checkpoint VARCHAR(100), -- Border or checkpoint crossed
    description TEXT, -- Detailed description
    status VARCHAR(50) DEFAULT 'Active', -- Status of movement record
    source_region_id SMALLINT, -- References reference.regions (source region)
    target_region_id SMALLINT, -- References reference.regions (target region)
    province_id INT, -- Province ID for administrative grouping
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
   - movement_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - from_address_id -> public_security.address
   - to_address_id -> public_security.address
   - from_country_id -> reference.nationalities
   - to_country_id -> reference.nationalities
   - source_region_id -> reference.regions
   - target_region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - movement_id (primary key index)
   - citizen_id (for citizen lookups)
   - movement_type (for filtering by movement type)
   - departure_date, arrival_date (for timeline queries)
   - document_no (for document lookups)
   - status (for active movement records)
   - geographical_region (for partitioning)

5. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

6. Check constraints:
   - Validate departure_date is not in the future
   - Validate arrival_date is after departure_date when provided
   - Validate document_expiry_date is after document_issue_date
   - Require border_checkpoint for international movements
   - Require from_country_id and to_country_id for international movements

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for movement tracking
   - Auto-close previous open movements when a new one is recorded
   - Notify border control of international movements
   - Handle partitioning logic

8. Views:
   - Current movement view showing only active/ongoing movements
   - Movement history view showing complete movement timeline
   - International travel view for immigration statistics
   - Domestic migration view for population movement analysis
*/
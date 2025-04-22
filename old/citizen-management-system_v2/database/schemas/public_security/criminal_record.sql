-- =============================================================================
-- File: database/schemas/public_security/criminal_record.sql
-- Description: Creates the criminal_record table in the public_security schema
-- =============================================================================

\echo 'Creating criminal_record table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.criminal_record CASCADE;
-- Create the criminal_record table

CREATE TABLE public_security.criminal_record (
    record_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,
    crime_type VARCHAR(100) NOT NULL,
    crime_date DATE NOT NULL,
    court_name VARCHAR(200) NOT NULL,
    sentence_date DATE NOT NULL,
    sentence_length VARCHAR(100) NOT NULL, -- "5 năm", "Chung thân"
    prison_facility_id INT,
    prison_facility_name VARCHAR(200),
    release_date DATE,
    status VARCHAR(50) NOT NULL, -- Đang thụ án/Đã mãn hạn/Ân xá
    decision_number VARCHAR(50) NOT NULL,
    decision_date DATE NOT NULL,
    note TEXT,
    region_id SMALLINT,
    province_id INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMIT;

/*
TODO: The following will be implemented in separate files:
1. Foreign Data Wrapper configuration:
   - Create foreign table definitions in Ministry of Justice database and Central Server
   - Configure appropriate user mappings and permissions
2. Primary key constraint:
    - record_id as primary key
3. Foreign key constraints:
    - citizen_id -> public_security.citizen
    - prison_facility_id -> reference.prison_facilities
    - region_id -> reference.regions
    - province_id -> reference.provinces
4. Indexes: 
    - record_id (primary key index)
    - citizen_id (for citizen lookups)
    - crime_type (for filtering by crime type)
    - status (for filtering by status)

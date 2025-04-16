-- =============================================================================
-- File: database/schemas/public_security/identification_card.sql
-- Description: Creates the identification_card table in the public_security schema
-- Version: 1.0
-- 
-- This file only creates the table structure. Constraints and indexes will be
-- defined in separate files to maintain clean separation of concerns.
-- Since FDW will be used for cross-database access, the table is only created
-- in the Ministry of Public Security database.
-- =============================================================================

\echo 'Creating identification_card table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.identification_card CASCADE;

-- Create the identification_card table
CREATE TABLE public_security.identification_card (
    card_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    card_number VARCHAR(12) NOT NULL, -- Unique ID card number
    issue_date DATE NOT NULL, -- Date the card was issued
    expiry_date DATE, -- Date the card expires
    issuing_authority_id SMALLINT, -- References reference.authorities
    card_type card_type NOT NULL, -- Type of ID card (CMND 9 số, CMND 12 số, CCCD, CCCD gắn chip)
    fingerprint_left_index BYTEA, -- Biometric data for left index finger
    fingerprint_right_index BYTEA, -- Biometric data for right index finger
    fingerprint_left_thumb BYTEA, -- Biometric data for left thumb
    fingerprint_right_thumb BYTEA, -- Biometric data for right thumb
    facial_biometric BYTEA, -- Facial recognition data
    iris_data BYTEA, -- Iris scan data
    chip_serial_number VARCHAR(50), -- Serial number of embedded chip (for smart cards)
    card_status card_status NOT NULL DEFAULT 'Đang sử dụng', -- Current status of the card
    previous_card_number VARCHAR(12), -- Number of previous card if this is a replacement
    notes TEXT, -- Additional information
    region_id SMALLINT, -- References reference.regions
    province_id INT, -- References reference.provinces
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
   - card_id as primary key

3. Unique constraints:
   - card_number must be unique
   - Only one active card per citizen (citizen_id, card_status = 'Đang sử dụng')

4. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Indexes:
   - card_id (primary key index)
   - citizen_id (for citizen lookups)
   - card_number (for card lookups)
   - card_status (for filtering active cards)
   - issue_date, expiry_date (for date range queries)
   - geographical_region (for partitioning)

6. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

7. Check constraints:
   - Validate card_number format based on card_type
   - Validate expiry_date is after issue_date
   - Validate chip_serial_number is not null when card_type is 'CCCD gắn chip'

8. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging on record changes
   - Automatically set previous card as inactive when creating a new card for a citizen
   - Handle partitioning logic
*/
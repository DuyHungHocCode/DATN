-- =============================================================================
-- File: database/schemas/justice/household.sql
-- Description: Creates the household table in the justice schema
-- =============================================================================

\echo 'Creating household table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.household CASCADE;

-- Create the household table
CREATE TABLE justice.household (
    household_id SERIAL, -- Primary key will be defined in constraints file
    household_book_no VARCHAR(20) NOT NULL, -- Official household registration book number
    head_of_household_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    address_id INT NOT NULL, -- References public_security.address
    registration_date DATE NOT NULL, -- Date of household registration
    issuing_authority_id SMALLINT, -- References reference.authorities
    area_code VARCHAR(10), -- Administrative area code
    household_type household_type NOT NULL, -- Type of household (Thường trú, Tạm trú, etc.)
    status BOOLEAN DEFAULT TRUE, -- Whether this household registration is active
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
   - Configure FDW for cross-database access to public_security.citizen

2. Primary key constraint:
   - household_id as primary key

3. Unique constraints:
   - household_book_no must be unique

4. Foreign key constraints:
   - head_of_household_id -> public_security.citizen
   - address_id -> public_security.address
   - issuing_authority_id -> reference.authorities
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Indexes:
   - household_id (primary key index)
   - household_book_no (for book number lookups)
   - head_of_household_id (for citizen household lookups)
   - address_id (for address lookups)
   - household_type (for filtering by type)
   - status (for active household filtering)
   - geographical_region (for partitioning)

6. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for household changes
   - Handle partitioning logic

8. Views:
   - Current households view showing only active households
   - Household members view joining with household_member table
   - Households by region/province for statistical reporting
*/
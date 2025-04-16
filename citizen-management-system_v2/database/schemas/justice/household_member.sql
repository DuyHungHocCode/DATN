-- =============================================================================
-- File: database/schemas/justice/household_member.sql
-- Description: Creates the household_member table in the justice schema
-- =============================================================================

\echo 'Creating household_member table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.household_member CASCADE;

-- Create the household_member table
CREATE TABLE justice.household_member (
    household_member_id SERIAL, -- Primary key will be defined in constraints file
    household_id INT NOT NULL, -- References justice.household
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    relationship_with_head VARCHAR(50) NOT NULL, -- Relationship to head of household
    join_date DATE NOT NULL, -- Date citizen joined the household
    leave_date DATE, -- Date citizen left the household (NULL if still a member)
    leave_reason TEXT, -- Reason for leaving the household
    previous_household_id INT, -- References justice.household (previous household)
    status VARCHAR(50) DEFAULT 'Active', -- Current status of household membership
    order_in_household SMALLINT, -- Order in the household (for sorting)
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
   - household_member_id as primary key

3. Unique constraints:
   - (household_id, citizen_id, join_date) must be unique
     (one person can only join a specific household once on a specific date)

4. Foreign key constraints:
   - household_id -> justice.household
   - citizen_id -> public_security.citizen
   - previous_household_id -> justice.household
   - region_id -> reference.regions
   - province_id -> reference.provinces

5. Indexes:
   - household_member_id (primary key index)
   - household_id (for household lookups)
   - citizen_id (for citizen lookups)
   - join_date, leave_date (for date range queries)
   - status (for active member filtering)
   - geographical_region (for partitioning)

6. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

7. Check constraints:
   - Validate join_date is not in the future
   - Validate leave_date is after join_date when provided
   - Validate order_in_household is positive

8. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for household member changes
   - Automatic status update when leave_date is reached
   - Validation to ensure head of household is also a member
   - Handle partitioning logic

9. Views:
   - Current members view showing only active household members
   - Member history view showing complete membership timeline
   - Household composition view for demographic reporting
*/
-- =============================================================================
-- File: database/schemas/justice/family_relationship.sql
-- Description: Creates the family relationship table in the justice schema
-- =============================================================================

\echo 'Creating family_relationship table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.family_relationship CASCADE;

-- Create the family relationship table
CREATE TABLE justice.family_relationship (
    relationship_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References citizen table via FDW
    related_citizen_id VARCHAR(12) NOT NULL, -- References citizen table via FDW
    relationship_type family_relationship_type NOT NULL, -- ENUM: Vợ-Chồng, Cha-Con, etc.
    start_date DATE NOT NULL,
    end_date DATE,
    status record_status DEFAULT 'Đang xử lý', -- ENUM: Đang xử lý, Đã duyệt, etc.
    document_proof TEXT, -- Văn bản chứng minh
    document_no VARCHAR(50), -- Số văn bản
    issuing_authority VARCHAR(200), -- Cơ quan cấp
    notes TEXT,
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
   - Create foreign table definitions to access citizen data from Ministry of Public Security
   - Configure appropriate user mappings and permissions

2. Primary key constraint:
   - relationship_id as primary key

3. Foreign key constraints:
   - citizen_id -> foreign table referencing public_security.citizen
   - related_citizen_id -> foreign table referencing public_security.citizen
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - relationship_id (primary key index)
   - citizen_id (for citizen lookups)
   - related_citizen_id (for related citizen lookups)
   - relationship_type (for relationship type queries)
   - start_date (for date-based queries)
   - province_id (for geographical queries)

5. Check constraints:
   - Ensure start_date <= end_date when end_date is not null
   - Validate document_no format
   - Prevent self-relationships (citizen_id != related_citizen_id)
   - Validate relationship_type based on business rules

6. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for relationship changes
   - Validate relationship consistency
   - Update related family records when needed
   - Notify relevant authorities on status changes

7. Views:
   - Active relationships view
   - Family tree view
   - Relationship history view
   - Statistical views by region/province

8. Security Policies:
   - Row-level security for access control
   - Audit trail for all modifications
   - Access logging and monitoring

9. Data Validation:
   - Relationship validity checks
   - Document verification rules
   - Authority jurisdiction validation
*/

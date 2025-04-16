-- =============================================================================
-- File: database/schemas/public_security/permanent_residence.sql
-- Description: Creates the permanent_residence table in the public_security schema
-- =============================================================================

\echo 'Creating permanent_residence table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.permanent_residence CASCADE;

-- Create the permanent_residence table
CREATE TABLE public_security.permanent_residence (
    permanent_residence_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    address_id INT NOT NULL, -- References reference.addresses
    registration_date DATE NOT NULL, -- Ngày đăng ký
    decision_no VARCHAR(50) NOT NULL, -- Số quyết định
    issuing_authority VARCHAR(200) NOT NULL, -- Cơ quan cấp
    previous_address_id INT, -- References reference.addresses (Mã địa chỉ trước đó)
    change_reason TEXT, -- Lý do thay đổi
    status BOOLEAN DEFAULT TRUE, -- Trạng thái (active/inactive)
    region_id SMALLINT, -- References reference.regions
    province_id INT, -- References reference.provinces
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
   - permanent_residence_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - address_id -> reference.addresses
   - previous_address_id -> reference.addresses
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - permanent_residence_id (primary key index)
   - citizen_id (for citizen lookups)
   - address_id (for address lookups)
   - registration_date (for date-based queries)
   - decision_no (for document lookups)
   - province_id (for geographical queries)

5. Check constraints:
   - Validate registration_date is not in the future
   - Validate decision_no format
   - Ensure previous_address_id is different from address_id
   - Validate province_id matches with address location

6. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for residence changes
   - Update citizen's current address when residence changes
   - Notify relevant authorities on residence registration
   - Validate address changes within same province/region

7. Views:
   - Current residence view showing only active residences
   - Historical residence changes view
   - Residence statistics by region/province
   - Address change patterns view

8. Security Policies:
   - Row-level security for access control
   - Audit trail for all modifications
   - Access logging and monitoring

9. Data Validation:
   - Address consistency validation
   - Authority jurisdiction validation
   - Document number format validation
*/

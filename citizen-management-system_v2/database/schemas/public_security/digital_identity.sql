-- =============================================================================
-- File: database/schemas/public_security/digital_identity.sql
-- Description: Creates the digital_identity table in the public_security schema
-- Version: 1.0
-- 
-- This file only creates the table structure. Constraints and indexes will be
-- defined in separate files to maintain clean separation of concerns.
-- Since FDW will be used for cross-database access, the table is only created
-- in the Ministry of Public Security database.
-- =============================================================================

\echo 'Creating digital_identity table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.digital_identity CASCADE;

-- Create the digital_identity table
CREATE TABLE public_security.digital_identity (
    digital_identity_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    digital_id VARCHAR(50) NOT NULL, -- Mã định danh điện tử
    activation_date TIMESTAMP WITH TIME ZONE NOT NULL,
    verification_level verification_level NOT NULL, -- Security level of identity verification
    status BOOLEAN DEFAULT TRUE, -- Whether this record is active/current
    device_info TEXT, -- Thông tin thiết bị
    last_login_date TIMESTAMP WITH TIME ZONE, -- Last login timestamp
    last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
    otp_method VARCHAR(50), -- Phương thức OTP
    phone_number VARCHAR(15), -- Phone number for OTP
    email VARCHAR(100), -- Email for notifications
    security_question TEXT, -- Encrypted security question response
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50), -- User who created the record
    updated_by VARCHAR(50) -- User who last updated the record
);

COMMIT;

/*
TODO: The following will be implemented in separate files:

1. Foreign Data Wrapper configuration:
   - Create foreign table definitions in Ministry of Justice database and Central Server
   - Configure appropriate user mappings and permissions

2. Primary key constraint:
   - digital_identity_id as primary key

3. Unique constraints:
   - digital_id must be unique

4. Foreign key constraints:
   - citizen_id -> public_security.citizen

5. Check constraints:
   - Validate phone_number format (^\+?[0-9]{10,14}$)
   - Validate email format (^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$)
   - Validate digital_id format (^[A-Za-z0-9-]+$)
   - Validate activation_date is not in the future

6. Indexes:
   - digital_identity_id (primary key index)
   - citizen_id (for citizen lookups)
   - digital_id (unique index)
   - phone_number (partial index where not null)
   - email (partial index where not null)

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for identity changes
   - Notify relevant authorities on verification level changes
   - Security logging for login attempts
   - Device tracking updates

8. Views:
   - Active digital identities view
   - Failed login attempts view
   - Identity verification status view
   - Device usage statistics view

9. Security Policies:
   - Row-level security for access control
   - Encryption policies for security_question
   - Access logging and monitoring
   - Rate limiting for login attempts

10. Data Validation:
    - OTP method validation
    - Device info JSON structure validation
    - IP address format validation
*/

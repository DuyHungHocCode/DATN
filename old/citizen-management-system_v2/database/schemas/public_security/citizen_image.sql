-- =============================================================================
-- File: database/schemas/public_security/citizen_image.sql
-- Description: Creates the citizen_image table in the public_security schema
-- =============================================================================

\echo 'Creating citizen_image table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_image CASCADE;

-- Create the citizen_image table
CREATE TABLE public_security.citizen_image (
    image_id SERIAL, -- Primary key will be defined in constraints file
    citizen_id VARCHAR(12) NOT NULL, -- References public_security.citizen
    image_type VARCHAR(50) NOT NULL, -- Type of image (portrait, full body, other)
    image_data BYTEA NOT NULL, -- Image data in binary format
    image_format VARCHAR(20) NOT NULL, -- Image format (JPG, PNG, etc.)
    image_size INTEGER, -- Size of image in bytes
    width INTEGER, -- Image width in pixels
    height INTEGER, -- Image height in pixels
    dpi INTEGER, -- Image resolution (dots per inch)
    capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- When the image was captured
    expiry_date DATE, -- When the image should be renewed (if applicable)
    status BOOLEAN DEFAULT TRUE, -- Whether this image is active/current
    purpose VARCHAR(100), -- Purpose or context of the image
    device_id VARCHAR(50), -- ID of capture device
    photographer VARCHAR(100), -- Person who took the photo
    location_taken VARCHAR(200), -- Where the photo was taken
    region_id SMALLINT, -- References reference.regions
    province_id INT, -- References reference.provinces
    geographical_region VARCHAR(20), -- Used for partitioning (Bắc, Trung, Nam)
    hash_value VARCHAR(128), -- Hash value for data integrity verification
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
   - image_id as primary key

3. Foreign key constraints:
   - citizen_id -> public_security.citizen
   - region_id -> reference.regions
   - province_id -> reference.provinces

4. Indexes:
   - image_id (primary key index)
   - citizen_id (for citizen lookups)
   - image_type (for specific image type queries)
   - capture_date (for timeline queries)
   - status (for active image records)
   - geographical_region (for partitioning)

5. Partitioning:
   - Partition by geographical_region (Bắc, Trung, Nam)

6. Check constraints:
   - Validate image_format values (JPG, PNG, etc.)
   - Validate width, height, and dpi are positive integers
   - Validate expiry_date is after capture_date if provided

7. Triggers:
   - Update updated_at timestamp on record modification
   - Audit logging for image access and changes
   - Verify hash integrity before updates
   - Handle partitioning logic
   - Calculate image_size, width, height automatically from image_data when possible

8. Security measures:
   - Row-level security policies for image data access
   - Access logging for all queries to this table
   - Thumbnail generation for reduced data transfer in listing views
*/
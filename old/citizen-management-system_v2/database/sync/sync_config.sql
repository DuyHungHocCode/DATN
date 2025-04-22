-- =============================================================================
-- File: database/schemas/central_server/sync_config.sql
-- Description: Cấu hình đồng bộ dữ liệu chi tiết giữa các hệ thống
-- Version: 1.0
-- 
-- Tệp này cấu hình:
-- 1. Chi tiết ánh xạ cột giữa các bảng nguồn và đích
-- 2. Khai báo cấu hình connector Kafka CDC
-- 3. Thiết lập lịch đồng bộ
-- 4. Cấu hình xử lý xung đột dữ liệu
-- =============================================================================

\echo 'Thiết lập cấu hình đồng bộ dữ liệu chi tiết...'
\connect national_citizen_central_server

BEGIN;

-- =============================================================================
-- 1. KHAI BÁO CẤU HÌNH ĐỒNG BỘ CHI TIẾT
-- =============================================================================
-- Xóa dữ liệu cấu hình cũ (nếu có)
TRUNCATE TABLE central.sync_config CASCADE;

-- Nhập cấu hình đồng bộ chính
INSERT INTO central.sync_config (
    source_system, target_system, source_schema, source_table, 
    target_schema, target_table, primary_key_columns, 
    conflict_resolution_strategy, sync_priority, sync_frequency, 
    batch_size, description, bidirectional, enabled
) VALUES
-- 1. Đồng bộ CITIZEN - THÔNG TIN CÔNG DÂN
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'citizen',
    'central', 'integrated_citizen', 'citizen_id',
    'SOURCE_WINS', 'Cao', '15 minutes',
    1000, 'Đồng bộ thông tin công dân từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 2. Đồng bộ IDENTIFICATION_CARD - CCCD
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'identification_card',
    'central', 'integrated_citizen', 'card_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    1000, 'Đồng bộ thông tin CCCD từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 3. Đồng bộ BIOMETRIC_DATA - DỮ LIỆU SINH TRẮC HỌC
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'biometric_data',
    'central', 'integrated_citizen', 'biometric_id',
    'SOURCE_WINS', 'Trung bình', '1 hour',
    500, 'Đồng bộ dữ liệu sinh trắc học từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 4. Đồng bộ CITIZEN_ADDRESS - ĐỊA CHỈ CÔNG DÂN
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'citizen_address',
    'central', 'integrated_citizen', 'citizen_address_id',
    'NEWER_WINS', 'Trung bình', '30 minutes',
    1000, 'Đồng bộ thông tin địa chỉ công dân từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 5. Đồng bộ PERMANENT_RESIDENCE - CƯ TRÚ THƯỜNG TRÚ
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'permanent_residence',
    'central', 'integrated_citizen', 'permanent_residence_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    1000, 'Đồng bộ thông tin đăng ký thường trú từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 6. Đồng bộ TEMPORARY_RESIDENCE - CƯ TRÚ TẠM TRÚ
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'temporary_residence',
    'central', 'integrated_citizen', 'temporary_residence_id',
    'SOURCE_WINS', 'Trung bình', '1 hour',
    1000, 'Đồng bộ thông tin đăng ký tạm trú từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 7. Đồng bộ TEMPORARY_ABSENCE - TẠM VẮNG
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'temporary_absence',
    'central', 'integrated_citizen', 'temporary_absence_id',
    'SOURCE_WINS', 'Thấp', '2 hours',
    500, 'Đồng bộ thông tin đăng ký tạm vắng từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 8. Đồng bộ CITIZEN_STATUS - TRẠNG THÁI CÔNG DÂN
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'citizen_status',
    'central', 'integrated_citizen', 'status_id',
    'SOURCE_WINS', 'Cao', '15 minutes',
    500, 'Đồng bộ trạng thái công dân từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 9. Đồng bộ CITIZEN_MOVEMENT - DI CHUYỂN
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'citizen_movement',
    'central', 'integrated_citizen', 'movement_id',
    'SOURCE_WINS', 'Trung bình', '1 hour',
    500, 'Đồng bộ thông tin di chuyển công dân từ Bộ Công an lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 10. Đồng bộ BIRTH_CERTIFICATE - KHAI SINH
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'birth_certificate',
    'central', 'integrated_citizen', 'birth_certificate_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    500, 'Đồng bộ thông tin khai sinh từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 11. Đồng bộ DEATH_CERTIFICATE - KHAI TỬ
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'death_certificate',
    'central', 'integrated_citizen', 'death_certificate_id',
    'SOURCE_WINS', 'Khẩn cấp', '15 minutes',
    200, 'Đồng bộ thông tin khai tử từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 12. Đồng bộ MARRIAGE - KẾT HÔN
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'marriage',
    'central', 'integrated_citizen', 'marriage_id',
    'SOURCE_WINS', 'Cao', '1 hour',
    500, 'Đồng bộ thông tin kết hôn từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 13. Đồng bộ DIVORCE - LY HÔN
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'divorce',
    'central', 'integrated_citizen', 'divorce_id',
    'SOURCE_WINS', 'Cao', '1 hour',
    200, 'Đồng bộ thông tin ly hôn từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 14. Đồng bộ HOUSEHOLD - HỘ KHẨU
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'household',
    'central', 'integrated_household', 'household_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    500, 'Đồng bộ thông tin hộ khẩu từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 15. Đồng bộ HOUSEHOLD_MEMBER - THÀNH VIÊN HỘ KHẨU
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'household_member',
    'central', 'integrated_household', 'household_member_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    1000, 'Đồng bộ thông tin thành viên hộ khẩu từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 16. Đồng bộ FAMILY_RELATIONSHIP - QUAN HỆ GIA ĐÌNH
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'family_relationship',
    'central', 'integrated_citizen', 'relationship_id',
    'SOURCE_WINS', 'Trung bình', '1 hour',
    500, 'Đồng bộ thông tin quan hệ gia đình từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 17. Đồng bộ POPULATION_CHANGE - BIẾN ĐỘNG DÂN CƯ
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'population_change',
    'central', 'integrated_citizen', 'change_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    1000, 'Đồng bộ thông tin biến động dân cư từ Bộ Tư pháp lên máy chủ trung tâm',
    FALSE, TRUE
),
-- 18. Đồng bộ KHAI TỬ -> BỘ CÔNG AN (Đồng bộ ngược)
(
    'Bộ Tư pháp', 'Bộ Công an', 'justice', 'death_certificate',
    'public_security', 'citizen_status', 'death_certificate_id',
    'SOURCE_WINS', 'Khẩn cấp', '15 minutes',
    100, 'Đồng bộ thông tin khai tử từ Bộ Tư pháp sang Bộ Công an để cập nhật trạng thái công dân',
    FALSE, TRUE
),
-- 19. Đồng bộ KHAI SINH -> BỘ CÔNG AN (Đồng bộ ngược)
(
    'Bộ Tư pháp', 'Bộ Công an', 'justice', 'birth_certificate',
    'public_security', 'citizen', 'birth_certificate_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    200, 'Đồng bộ thông tin khai sinh từ Bộ Tư pháp sang Bộ Công an',
    FALSE, TRUE
),
-- 20. Đồng bộ KẾT HÔN/LY HÔN -> BỘ CÔNG AN (Đồng bộ ngược)
(
    'Bộ Tư pháp', 'Bộ Công an', 'justice', 'marriage',
    'public_security', 'citizen', 'marriage_id',
    'SOURCE_WINS', 'Cao', '1 hour',
    200, 'Đồng bộ thông tin kết hôn/ly hôn từ Bộ Tư pháp sang Bộ Công an để cập nhật trạng thái hôn nhân',
    FALSE, TRUE
);

-- =============================================================================
-- 2. KHAI BÁO ÁNH XẠ CỘT CHI TIẾT
-- =============================================================================
-- Xóa dữ liệu ánh xạ cũ (nếu có)
TRUNCATE TABLE central.sync_mapping CASCADE;

-- Lấy ID của cấu hình đồng bộ CITIZEN
DO $$
DECLARE
    config_id_citizen INTEGER;
    config_id_birth_cert INTEGER;
    config_id_death_cert INTEGER;
    config_id_marriage INTEGER;
    config_id_household INTEGER;
BEGIN
    -- Lấy ID của cấu hình đồng bộ Citizen
    SELECT config_id INTO config_id_citizen FROM central.sync_config 
    WHERE source_system = 'Bộ Công an' AND source_table = 'citizen' AND target_system = 'Trung tâm';
    
    -- Thêm ánh xạ cột cho CITIZEN -> INTEGRATED_CITIZEN
    IF config_id_citizen IS NOT NULL THEN
        INSERT INTO central.sync_mapping (config_id, source_column, target_column, is_key_column, is_updated_at_column)
        VALUES
        (config_id_citizen, 'citizen_id', 'citizen_id', TRUE, FALSE),
        (config_id_citizen, 'full_name', 'full_name', FALSE, FALSE),
        (config_id_citizen, 'date_of_birth', 'date_of_birth', FALSE, FALSE),
        (config_id_citizen, 'place_of_birth', 'place_of_birth', FALSE, FALSE),
        (config_id_citizen, 'gender', 'gender', FALSE, FALSE),
        (config_id_citizen, 'ethnicity_id', 'ethnicity_id', FALSE, FALSE),
        (config_id_citizen, 'religion_id', 'religion_id', FALSE, FALSE),
        (config_id_citizen, 'nationality_id', 'nationality_id', FALSE, FALSE),
        (config_id_citizen, 'blood_type', 'blood_type', FALSE, FALSE),
        (config_id_citizen, 'death_status', 'death_status', FALSE, FALSE),
        (config_id_citizen, 'birth_certificate_no', 'birth_certificate_no', FALSE, FALSE),
        (config_id_citizen, 'marital_status', 'marital_status', FALSE, FALSE),
        (config_id_citizen, 'education_level', 'education_level', FALSE, FALSE),
        (config_id_citizen, 'occupation_id', 'occupation_id', FALSE, FALSE),
        (config_id_citizen, 'occupation_detail', 'occupation_detail', FALSE, FALSE),
        (config_id_citizen, 'tax_code', 'tax_code', FALSE, FALSE),
        (config_id_citizen, 'social_insurance_no', 'social_insurance_no', FALSE, FALSE),
        (config_id_citizen, 'health_insurance_no', 'health_insurance_no', FALSE, FALSE),
        (config_id_citizen, 'father_citizen_id', 'father_citizen_id', FALSE, FALSE),
        (config_id_citizen, 'mother_citizen_id', 'mother_citizen_id', FALSE, FALSE),
        (config_id_citizen, 'region_id', 'region_id', FALSE, FALSE),
        (config_id_citizen, 'province_id', 'province_id', FALSE, FALSE),
        (config_id_citizen, 'geographical_region', 'geographical_region', FALSE, FALSE),
        (config_id_citizen, 'avatar', 'avatar', FALSE, FALSE),
        (config_id_citizen, 'notes', 'notes', FALSE, FALSE),
        (config_id_citizen, 'status', 'status', FALSE, FALSE),
        (config_id_citizen, 'created_at', 'created_at', FALSE, FALSE),
        (config_id_citizen, 'updated_at', 'updated_at', FALSE, TRUE),
        (config_id_citizen, 'created_by', 'created_by', FALSE, FALSE),
        (config_id_citizen, 'updated_by', 'updated_by', FALSE, FALSE);
    END IF;
    
    -- Lấy ID của cấu hình đồng bộ Birth Certificate
    SELECT config_id INTO config_id_birth_cert FROM central.sync_config 
    WHERE source_system = 'Bộ Tư pháp' AND source_table = 'birth_certificate' AND target_system = 'Trung tâm';
    
    -- Thêm ánh xạ cột cho BIRTH_CERTIFICATE -> INTEGRATED_CITIZEN
    IF config_id_birth_cert IS NOT NULL THEN
        INSERT INTO central.sync_mapping (config_id, source_column, target_column, is_key_column, is_updated_at_column)
        VALUES
        (config_id_birth_cert, 'birth_certificate_id', 'birth_certificate_id', TRUE, FALSE),
        (config_id_birth_cert, 'citizen_id', 'citizen_id', TRUE, FALSE),
        (config_id_birth_cert, 'birth_certificate_no', 'birth_cert_no', FALSE, FALSE),
        (config_id_birth_cert, 'registration_date', 'birth_registration_date', FALSE, FALSE),
        (config_id_birth_cert, 'place_of_birth', 'birth_place', FALSE, FALSE),
        (config_id_birth_cert, 'date_of_birth', 'birth_date', FALSE, FALSE),
        (config_id_birth_cert, 'gender_at_birth', 'birth_gender', FALSE, FALSE),
        (config_id_birth_cert, 'father_citizen_id', 'birth_father_id', FALSE, FALSE),
        (config_id_birth_cert, 'mother_citizen_id', 'birth_mother_id', FALSE, FALSE),
        (config_id_birth_cert, 'issuing_authority_id', 'birth_issuing_authority_id', FALSE, FALSE),
        (config_id_birth_cert, 'updated_at', 'birth_cert_updated_at', FALSE, TRUE);
    END IF;
    
    -- Lấy ID của cấu hình đồng bộ Death Certificate
    SELECT config_id INTO config_id_death_cert FROM central.sync_config 
    WHERE source_system = 'Bộ Tư pháp' AND source_table = 'death_certificate' AND target_system = 'Trung tâm';
    
    -- Thêm ánh xạ cột cho DEATH_CERTIFICATE -> INTEGRATED_CITIZEN
    IF config_id_death_cert IS NOT NULL THEN
        INSERT INTO central.sync_mapping (config_id, source_column, target_column, is_key_column, is_updated_at_column)
        VALUES
        (config_id_death_cert, 'death_certificate_id', 'death_certificate_id', TRUE, FALSE),
        (config_id_death_cert, 'citizen_id', 'citizen_id', TRUE, FALSE),
        (config_id_death_cert, 'death_certificate_no', 'death_cert_no', FALSE, FALSE),
        (config_id_death_cert, 'date_of_death', 'death_date', FALSE, FALSE),
        (config_id_death_cert, 'time_of_death', 'death_time', FALSE, FALSE),
        (config_id_death_cert, 'place_of_death', 'death_place', FALSE, FALSE),
        (config_id_death_cert, 'cause_of_death', 'death_cause', FALSE, FALSE),
        (config_id_death_cert, 'registration_date', 'death_registration_date', FALSE, FALSE),
        (config_id_death_cert, 'issuing_authority_id', 'death_issuing_authority_id', FALSE, FALSE),
        (config_id_death_cert, 'updated_at', 'death_cert_updated_at', FALSE, TRUE);
    END IF;
    
    -- Lấy ID của cấu hình đồng bộ Marriage
    SELECT config_id INTO config_id_marriage FROM central.sync_config 
    WHERE source_system = 'Bộ Tư pháp' AND source_table = 'marriage' AND target_system = 'Trung tâm';
    
    -- Thêm ánh xạ cột cho MARRIAGE -> INTEGRATED_CITIZEN
    IF config_id_marriage IS NOT NULL THEN
        INSERT INTO central.sync_mapping (config_id, source_column, target_column, is_key_column, is_updated_at_column)
        VALUES
        (config_id_marriage, 'marriage_id', 'marriage_id', TRUE, FALSE),
        (config_id_marriage, 'marriage_certificate_no', 'marriage_cert_no', FALSE, FALSE),
        (config_id_marriage, 'husband_id', 'husband_id', FALSE, FALSE),
        (config_id_marriage, 'wife_id', 'wife_id', FALSE, FALSE),
        (config_id_marriage, 'marriage_date', 'marriage_date', FALSE, FALSE),
        (config_id_marriage, 'registration_date', 'marriage_registration_date', FALSE, FALSE),
        (config_id_marriage, 'issuing_authority_id', 'marriage_issuing_authority_id', FALSE, FALSE),
        (config_id_marriage, 'updated_at', 'marriage_updated_at', FALSE, TRUE);
    END IF;
    
    -- Lấy ID của cấu hình đồng bộ Household
    SELECT config_id INTO config_id_household FROM central.sync_config 
    WHERE source_system = 'Bộ Tư pháp' AND source_table = 'household' AND target_system = 'Trung tâm';
    
    -- Thêm ánh xạ cột cho HOUSEHOLD -> INTEGRATED_HOUSEHOLD
    IF config_id_household IS NOT NULL THEN
        INSERT INTO central.sync_mapping (config_id, source_column, target_column, is_key_column, is_updated_at_column)
        VALUES
        (config_id_household, 'household_id', 'household_id', TRUE, FALSE),
        (config_id_household, 'household_book_no', 'household_book_no', FALSE, FALSE),
        (config_id_household, 'head_of_household_id', 'head_of_household_id', FALSE, FALSE),
        (config_id_household, 'address_id', 'household_address_id', FALSE, FALSE),
        (config_id_household, 'registration_date', 'household_registration_date', FALSE, FALSE),
        (config_id_household, 'issuing_authority_id', 'household_issuing_authority_id', FALSE, FALSE),
        (config_id_household, 'household_type', 'household_type', FALSE, FALSE),
        (config_id_household, 'status', 'household_status', FALSE, FALSE),
        (config_id_household, 'notes', 'household_notes', FALSE, FALSE),
        (config_id_household, 'region_id', 'household_region_id', FALSE, FALSE),
        (config_id_household, 'province_id', 'household_province_id', FALSE, FALSE),
        (config_id_household, 'geographical_region', 'household_geographical_region', FALSE, FALSE),
        (config_id_household, 'updated_at', 'household_updated_at', FALSE, TRUE);
    END IF;
    
END $$;

-- =============================================================================
-- 3. KHỞI TẠO LỊCH ĐỒNG BỘ TỰ ĐỘNG
-- =============================================================================
-- Xóa lịch trình đồng bộ cũ (nếu có)
TRUNCATE TABLE central.sync_schedule CASCADE;

-- Thêm lịch trình đồng bộ tự động
INSERT INTO central.sync_schedule (
    config_id, schedule_name, cron_expression, enabled
)
SELECT 
    config_id,
    'Đồng bộ tự động ' || source_table || ' từ ' || source_system,
    CASE
        WHEN sync_priority = 'Khẩn cấp' THEN '*/10 * * * *'  -- 10 phút một lần
        WHEN sync_priority = 'Cao' THEN '*/30 * * * *'       -- 30 phút một lần
        WHEN sync_priority = 'Trung bình' THEN '0 */1 * * *' -- 1 giờ một lần
        WHEN sync_priority = 'Thấp' THEN '0 */4 * * *'       -- 4 giờ một lần
        ELSE '0 0 * * *'                                     -- 1 ngày một lần
    END,
    TRUE
FROM 
    central.sync_config
WHERE
    enabled = TRUE;

-- =============================================================================
-- 4. KHỞI TẠO TRẠNG THÁI CONNECTOR KAFKA
-- =============================================================================
-- Xóa trạng thái connector cũ (nếu có)
TRUNCATE TABLE central.kafka_connector_status CASCADE;

-- Thêm các connector Kafka
INSERT INTO central.kafka_connector_status (
    connector_name, connector_type, connector_status, 
    source_system, target_system, config, topics, monitored
) VALUES
-- Connectors cho Bộ Công an
(
    'debezium-connector-ministry-public-security', 
    'Debezium PostgreSQL', 
    'Đang chạy',
    'Bộ Công an', 
    'Trung tâm',
    '{
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "database.hostname": "ministry_of_public_security_db",
        "database.port": "5432",
        "database.user": "sync_user",
        "database.password": "SyncData@2025",
        "database.dbname": "ministry_of_public_security",
        "database.server.name": "mps",
        "table.include.list": "public_security.citizen,public_security.identification_card,public_security.biometric_data,public_security.citizen_address,public_security.permanent_residence,public_security.temporary_residence,public_security.temporary_absence,public_security.citizen_status,public_security.citizen_movement",
        "plugin.name": "pgoutput",
        "publication.name": "public_security_pub",
        "slot.name": "public_security_slot",
        "snapshot.mode": "initial"
    }'::jsonb,
    ARRAY['mps.public_security.citizen', 'mps.public_security.identification_card', 'mps.public_security.biometric_data'],
    TRUE
),
-- Connectors cho Bộ Tư pháp
(
    'debezium-connector-ministry-justice', 
    'Debezium PostgreSQL', 
    'Đang chạy',
    'Bộ Tư pháp', 
    'Trung tâm',
    '{
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "database.hostname": "ministry_of_justice_db",
        "database.port": "5432",
        "database.user": "sync_user",
        "database.password": "SyncData@2025",
        "database.dbname": "ministry_of_justice",
        "database.server.name": "moj",
        "table.include.list": "justice.birth_certificate,justice.death_certificate,justice.marriage,justice.divorce,justice.household,justice.household_member,justice.family_relationship,justice.population_change",
        "plugin.name": "pgoutput",
        "publication.name": "justice_pub",
        "slot.name": "justice_slot",
        "snapshot.mode": "initial"
    }'::jsonb,
    ARRAY['moj.justice.birth_certificate', 'moj.justice.death_certificate', 'moj.justice.marriage', 'moj.justice.household'],
    TRUE
),
-- Connectors từ Trung tâm đến Bộ Công an (để đồng bộ ngược)
(
    'central-to-ministry-public-security-connector', 
    'Debezium PostgreSQL', 
    'Đang chạy',
    'Trung tâm', 
    'Bộ Công an',
    '{
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "database.hostname": "national_citizen_central_server_db",
        "database.port": "5432",
        "database.user": "sync_user",
        "database.password": "SyncData@2025",
        "database.dbname": "national_citizen_central_server",
        "database.server.name": "central",
        "table.include.list": "central.integrated_citizen,central.integrated_household",
        "plugin.name": "pgoutput",
        "publication.name": "central_pub",
        "slot.name": "central_slot",
        "snapshot.mode": "initial_only"
    }'::jsonb,
    ARRAY['central.central.integrated_citizen', 'central.central.integrated_household'],
    TRUE
),
-- Connectors Sink từ Kafka đến MongoDB
(
    'mongodb-sink-connector', 
    'MongoDB Sink', 
    'Đang chạy',
    'Trung tâm', 
    'MongoDB',
    '{
        "connector.class": "com.mongodb.kafka.connect.MongoSinkConnector",
        "connection.uri": "mongodb://mongodb_user:mongodb_password@mongodb:27017",
        "database": "citizen_management",
        "collection": "citizens",
        "topics": "central.central.integrated_citizen",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "key.converter.schemas.enable": "false",
        "value.converter.schemas.enable": "false",
        "document.id.strategy": "com.mongodb.kafka.connect.sink.processor.id.strategy.PartialValueStrategy",
        "document.id.strategy.partial.value.projection": "citizen_id",
        "delete.on.null.values": "true",
        "writemodel.strategy": "com.mongodb.kafka.connect.sink.writemodel.strategy.ReplaceOneDefaultStrategy"
    }'::jsonb,
    ARRAY['central.central.integrated_citizen'],
    TRUE
),
-- Connector cho Elasticsearch
(
    'elasticsearch-sink-connector', 
    'Elasticsearch Sink', 
    'Đang chạy',
    'Trung tâm', 
    'Elasticsearch',
    '{
        "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
        "connection.url": "http://elasticsearch:9200",
        "topics": "central.central.integrated_citizen",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "key.converter.schemas.enable": "false",
        "value.converter.schemas.enable": "false",
        "type.name": "_doc",
        "key.ignore": "false",
        "schema.ignore": "true",
        "behavior.on.null.values": "delete"
    }'::jsonb,
    ARRAY['central.central.integrated_citizen'],
    TRUE
);

-- =============================================================================
-- 5. KHỞI TẠO TRẠNG THÁI TOPIC KAFKA
-- =============================================================================
-- Xóa trạng thái topic cũ (nếu có)
TRUNCATE TABLE central.kafka_topic_status CASCADE;

-- Thêm các topic Kafka
INSERT INTO central.kafka_topic_status (
    topic_name, topic_type, partition_count, replication_factor,
    retention_bytes, retention_ms, cleanup_policy, is_compacted, monitored
) VALUES
-- Topic CDC từ Bộ Công an
('mps.public_security.citizen', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.identification_card', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.biometric_data', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.citizen_address', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.permanent_residence', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.temporary_residence', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.temporary_absence', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.citizen_status', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('mps.public_security.citizen_movement', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),

-- Topic CDC từ Bộ Tư pháp
('moj.justice.birth_certificate', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('moj.justice.death_certificate', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('moj.justice.marriage', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('moj.justice.divorce', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('moj.justice.household', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('moj.justice.household_member', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('moj.justice.family_relationship', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('moj.justice.population_change', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),

-- Topic CDC từ Trung tâm (đồng bộ ngược)
('central.central.integrated_citizen', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('central.central.integrated_household', 'CDC-Source', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),

-- Topic chuyển đổi và làm giàu dữ liệu
('citizen.transformed', 'Transformation', 3, 3, 10737418240, 604800000, 'delete', FALSE, TRUE),
('citizen.enriched', 'Enriched', 3, 3, 10737418240, 604800000, 'delete', FALSE, TRUE),

-- Topic MongoDB và Elasticsearch
('citizen.mongodb.sink', 'MongoDB-Sink', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),
('citizen.elasticsearch.sink', 'Elasticsearch-Sink', 3, 3, 5368709120, 604800000, 'delete', FALSE, TRUE),

-- Topic Dead Letter Queue (DLQ) cho xử lý lỗi
('citizen.dlq', 'DLQ', 3, 3, 10737418240, 2592000000, 'compact,delete', TRUE, TRUE),

-- Topic kiểm soát và giám sát
('sync.control', 'Control', 1, 3, 1073741824, 2592000000, 'compact', TRUE, TRUE),
('sync.metrics', 'Metrics', 3, 3, 5368709120, 2592000000, 'compact,delete', TRUE, TRUE);

COMMIT;

\echo 'Hoàn thành thiết lập cấu hình đồng bộ dữ liệu'
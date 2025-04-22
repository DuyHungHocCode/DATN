-- Script tạo schemas cho hệ thống quản lý dân cư quốc gia
-- File: database/init/create_schemas.sql

-- ============================================================================
-- 1. TẠO SCHEMAS CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo 'Đang tạo schemas cho database Bộ Công an...'
\connect ministry_of_public_security

-- Schema chính - Quản lý dữ liệu công dân thuộc Bộ Công an
CREATE SCHEMA IF NOT EXISTS public_security;
COMMENT ON SCHEMA public_security IS 'Schema chứa dữ liệu quản lý dân cư thuộc Bộ Công an';

-- Schema tham chiếu - Chứa dữ liệu tham chiếu dùng chung
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS 'Schema chứa dữ liệu tham chiếu dùng chung';

-- Schema audit - Ghi nhật ký theo dõi thay đổi dữ liệu
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Schema chứa dữ liệu nhật ký thay đổi';

-- Schema CDC - Cấu hình cho Change Data Capture
CREATE SCHEMA IF NOT EXISTS cdc;
COMMENT ON SCHEMA cdc IS 'Schema chứa cấu hình và dữ liệu CDC (Change Data Capture)';

-- Schema API - Chứa các function, procedure cung cấp API
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS 'Schema chứa các function, procedure cung cấp API';

-- Schema phân vùng - Quản lý phân vùng dữ liệu theo địa lý
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS 'Schema chứa cấu hình và các hàm phân vùng dữ liệu theo địa lý';

-- Schema báo cáo - Chứa các view báo cáo thống kê
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo, thống kê';

-- Schema staging - Dữ liệu tạm thời cho quá trình ETL/đồng bộ
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS 'Schema chứa dữ liệu tạm thời phục vụ ETL và đồng bộ hóa';

-- Schema hàm tiện ích
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS 'Schema chứa các hàm tiện ích chung';

-- Phân quyền chi tiết cho schemas
-- ADMIN - Toàn quyền trên tất cả schemas
GRANT ALL PRIVILEGES ON SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility TO security_admin;

-- READER - Quyền đọc trên các schemas nghiệp vụ và tham chiếu
GRANT USAGE ON SCHEMA public_security, reference, audit, api, reports TO security_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference, audit, api, reports TO security_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference, audit, api, reports GRANT SELECT ON TABLES TO security_reader;

-- WRITER - Quyền đọc/ghi trên các schemas nghiệp vụ và tham chiếu
GRANT USAGE ON SCHEMA public_security, reference, api TO security_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public_security, reference TO security_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO security_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO security_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT SELECT ON TABLES TO security_writer;

-- SYNC_USER - Quyền đặc biệt cho đồng bộ và CDC
GRANT USAGE ON SCHEMA public_security, reference, cdc, staging TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference TO sync_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cdc, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT ON TABLES TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cdc, staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;

-- Thiết lập mặc định search_path
ALTER USER security_admin SET search_path TO public_security, reference, audit, cdc, api, partitioning, reports, staging, utility, public;
ALTER USER security_reader SET search_path TO public_security, reference, audit, api, reports, public;
ALTER USER security_writer SET search_path TO public_security, reference, api, public;
ALTER USER sync_user SET search_path TO public_security, reference, cdc, staging, public;

-- ============================================================================
-- 2. TẠO SCHEMAS CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Đang tạo schemas cho database Bộ Tư pháp...'
\connect ministry_of_justice

-- Schema chính - Quản lý dữ liệu hộ tịch thuộc Bộ Tư pháp
CREATE SCHEMA IF NOT EXISTS justice;
COMMENT ON SCHEMA justice IS 'Schema chứa dữ liệu quản lý hộ tịch thuộc Bộ Tư pháp';

-- Schema tham chiếu - Chứa dữ liệu tham chiếu dùng chung
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS 'Schema chứa dữ liệu tham chiếu dùng chung';

-- Schema audit - Ghi nhật ký theo dõi thay đổi dữ liệu
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Schema chứa dữ liệu nhật ký thay đổi';

-- Schema CDC - Cấu hình cho Change Data Capture
CREATE SCHEMA IF NOT EXISTS cdc;
COMMENT ON SCHEMA cdc IS 'Schema chứa cấu hình và dữ liệu CDC (Change Data Capture)';

-- Schema API - Chứa các function, procedure cung cấp API
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS 'Schema chứa các function, procedure cung cấp API';

-- Schema phân vùng - Quản lý phân vùng dữ liệu theo địa lý
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS 'Schema chứa cấu hình và các hàm phân vùng dữ liệu theo địa lý';

-- Schema báo cáo - Chứa các view báo cáo thống kê
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo, thống kê';

-- Schema staging - Dữ liệu tạm thời cho quá trình ETL/đồng bộ
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS 'Schema chứa dữ liệu tạm thời phục vụ ETL và đồng bộ hóa';

-- Schema hàm tiện ích
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS 'Schema chứa các hàm tiện ích chung';

-- Phân quyền chi tiết cho schemas
-- ADMIN - Toàn quyền trên tất cả schemas
GRANT ALL PRIVILEGES ON SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility TO justice_admin;

-- READER - Quyền đọc trên các schemas nghiệp vụ và tham chiếu
GRANT USAGE ON SCHEMA justice, reference, audit, api, reports TO justice_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference, audit, api, reports TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference, audit, api, reports GRANT SELECT ON TABLES TO justice_reader;

-- WRITER - Quyền đọc/ghi trên các schemas nghiệp vụ và tham chiếu
GRANT USAGE ON SCHEMA justice, reference, api TO justice_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA justice, reference TO justice_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT SELECT ON TABLES TO justice_writer;

-- SYNC_USER - Quyền đặc biệt cho đồng bộ và CDC
GRANT USAGE ON SCHEMA justice, reference, cdc, staging TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference TO sync_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cdc, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT ON TABLES TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cdc, staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;

-- Thiết lập mặc định search_path
ALTER USER justice_admin SET search_path TO justice, reference, audit, cdc, api, partitioning, reports, staging, utility, public;
ALTER USER justice_reader SET search_path TO justice, reference, audit, api, reports, public;
ALTER USER justice_writer SET search_path TO justice, reference, api, public;
ALTER USER sync_user SET search_path TO justice, reference, cdc, staging, public;

-- ============================================================================
-- 3. TẠO SCHEMAS CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Đang tạo schemas cho database Máy chủ trung tâm...'
\connect national_citizen_central_server

-- Schema trung tâm - Quản lý dữ liệu tích hợp từ các nguồn
CREATE SCHEMA IF NOT EXISTS central;
COMMENT ON SCHEMA central IS 'Schema chứa dữ liệu tích hợp từ các nguồn';

-- Schema tham chiếu - Chứa dữ liệu tham chiếu dùng chung
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS 'Schema chứa dữ liệu tham chiếu dùng chung';

-- Schema audit - Ghi nhật ký theo dõi thay đổi dữ liệu
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Schema chứa dữ liệu nhật ký thay đổi';

-- Schema cdc - Cấu hình cho Change Data Capture
CREATE SCHEMA IF NOT EXISTS cdc;
COMMENT ON SCHEMA cdc IS 'Schema chứa cấu hình và dữ liệu CDC (Change Data Capture)';

-- Schema sync - Quản lý đồng bộ hóa dữ liệu
CREATE SCHEMA IF NOT EXISTS sync;
COMMENT ON SCHEMA sync IS 'Schema chứa cấu hình và dữ liệu đồng bộ hóa';

-- Schema public_security_mirror - Phản chiếu dữ liệu từ Bộ Công an
CREATE SCHEMA IF NOT EXISTS public_security_mirror;
COMMENT ON SCHEMA public_security_mirror IS 'Schema chứa dữ liệu phản chiếu từ Bộ Công an';

-- Schema justice_mirror - Phản chiếu dữ liệu từ Bộ Tư pháp
CREATE SCHEMA IF NOT EXISTS justice_mirror;
COMMENT ON SCHEMA justice_mirror IS 'Schema chứa dữ liệu phản chiếu từ Bộ Tư pháp';

-- Schema API - Chứa các function, procedure cung cấp API tích hợp
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS 'Schema chứa các function, procedure cung cấp API tích hợp';

-- Schema phân vùng - Quản lý phân vùng dữ liệu theo địa lý
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS 'Schema chứa cấu hình và các hàm phân vùng dữ liệu theo địa lý';

-- Schema báo cáo - Chứa các view báo cáo thống kê
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo, thống kê tổng hợp';

-- Schema staging - Dữ liệu tạm thời cho quá trình ETL/đồng bộ
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS 'Schema chứa dữ liệu tạm thời phục vụ ETL và đồng bộ hóa';

-- Schema analytics - Dữ liệu phân tích
CREATE SCHEMA IF NOT EXISTS analytics;
COMMENT ON SCHEMA analytics IS 'Schema chứa dữ liệu và hàm phục vụ phân tích dữ liệu';

-- Schema hàm tiện ích
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS 'Schema chứa các hàm tiện ích chung';

-- Schema kafka_connect - Cấu hình cho Kafka Connect
CREATE SCHEMA IF NOT EXISTS kafka_connect;
COMMENT ON SCHEMA kafka_connect IS 'Schema chứa cấu hình và dữ liệu phục vụ Kafka Connect';

-- Phân quyền chi tiết cho schemas
-- ADMIN - Toàn quyền trên tất cả schemas
GRANT ALL PRIVILEGES ON SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, 
    partitioning, reports, staging, analytics, utility, kafka_connect TO central_server_admin;

-- READER - Quyền đọc trên các schemas dữ liệu và báo cáo
GRANT USAGE ON SCHEMA central, public_security_mirror, justice_mirror, reference, audit, api, reports, analytics TO central_server_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA central, public_security_mirror, justice_mirror, reference, audit, api, reports, analytics TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, public_security_mirror, justice_mirror, reference, audit, api, reports, analytics GRANT SELECT ON TABLES TO central_server_reader;

-- SYNC_USER - Quyền đặc biệt cho đồng bộ và CDC
GRANT USAGE ON SCHEMA central, public_security_mirror, justice_mirror, reference, cdc, sync, staging, kafka_connect TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA central, public_security_mirror, justice_mirror, reference TO sync_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cdc, sync, staging, kafka_connect TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, public_security_mirror, justice_mirror, reference GRANT SELECT ON TABLES TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cdc, sync, staging, kafka_connect GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;

-- Thiết lập mặc định search_path
ALTER USER central_server_admin SET search_path TO central, public_security_mirror, justice_mirror, sync, reference, audit, 
    cdc, api, partitioning, reports, staging, analytics, utility, kafka_connect, public;
ALTER USER central_server_reader SET search_path TO central, public_security_mirror, justice_mirror, reference, audit, api, reports, analytics, public;
ALTER USER sync_user SET search_path TO central, public_security_mirror, justice_mirror, sync, reference, cdc, staging, kafka_connect, public;

-- ============================================================================
-- 4. CẤU HÌNH CHO CDC (CHANGE DATA CAPTURE)
-- ============================================================================
\echo 'Cấu hình các tham số cho CDC...'

-- Cấu hình cho Bộ Công an
\connect ministry_of_public_security
-- Đảm bảo WAL level đã được thiết lập ở mức 'logical' cho CDC
ALTER SYSTEM SET wal_level = logical;
-- Thiết lập số lượng slot replication tối đa
ALTER SYSTEM SET max_replication_slots = 10;
-- Thiết lập số lượng WAL sender tối đa
ALTER SYSTEM SET max_wal_senders = 10;
-- Đảm bảo track commit timestamp được bật
ALTER SYSTEM SET track_commit_timestamp = on;
-- Thiết lập kích thước WAL hợp lý
ALTER SYSTEM SET wal_sender_timeout = '60s';
ALTER SYSTEM SET max_slot_wal_keep_size = '4GB';

-- Tạo publication cho CDC
CREATE PUBLICATION public_security_pub FOR TABLE 
    public_security.citizen,
    public_security.identification_card,
    public_security.biometric_data,
    public_security.residence,
    public_security.citizen_status,
    public_security.criminal_record,
    public_security.digital_identity,
    public_security.citizen_movement,
    public_security.citizen_image,
    public_security.user_account;

-- Cấu hình cho Bộ Tư pháp
\connect ministry_of_justice
-- Đảm bảo WAL level đã được thiết lập ở mức 'logical' cho CDC
ALTER SYSTEM SET wal_level = logical;
-- Thiết lập số lượng slot replication tối đa
ALTER SYSTEM SET max_replication_slots = 10;
-- Thiết lập số lượng WAL sender tối đa
ALTER SYSTEM SET max_wal_senders = 10;
-- Đảm bảo track commit timestamp được bật
ALTER SYSTEM SET track_commit_timestamp = on;
-- Thiết lập kích thước WAL hợp lý
ALTER SYSTEM SET wal_sender_timeout = '60s';
ALTER SYSTEM SET max_slot_wal_keep_size = '4GB';

-- Tạo publication cho CDC
CREATE PUBLICATION justice_pub FOR TABLE 
    justice.birth_certificate,
    justice.death_certificate,
    justice.marriage,
    justice.divorce,
    justice.household,
    justice.household_member,
    justice.family_relationship,
    justice.guardian_relationship,
    justice.population_change;

-- Cấu hình cho máy chủ trung tâm
\connect national_citizen_central_server
-- Đảm bảo WAL level đã được thiết lập ở mức 'logical' cho CDC
ALTER SYSTEM SET wal_level = logical;
-- Thiết lập số lượng slot replication tối đa
ALTER SYSTEM SET max_replication_slots = 20;
-- Thiết lập số lượng WAL sender tối đa
ALTER SYSTEM SET max_wal_senders = 20;
-- Đảm bảo track commit timestamp được bật
ALTER SYSTEM SET track_commit_timestamp = on;
-- Thiết lập kích thước WAL hợp lý
ALTER SYSTEM SET wal_sender_timeout = '120s';
ALTER SYSTEM SET max_slot_wal_keep_size = '8GB';

-- Tạo publication cho CDC
CREATE PUBLICATION central_pub FOR TABLE 
    central.citizen_complete_info,
    central.household_complete_info;

-- ============================================================================
-- 5. CẤU HÌNH BỔ SUNG CHO KAFKA CONNECT VÀ DEBEZIUM
-- ============================================================================
\echo 'Cấu hình các thành phần bổ sung cho Kafka Connect và Debezium...'

-- Cấu hình Debezium cho Bộ Công an
\connect ministry_of_public_security
-- Tạo bảng theo dõi trạng thái Debezium
CREATE TABLE IF NOT EXISTS cdc.debezium_status (
    connector_id VARCHAR(100) PRIMARY KEY,
    connector_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL,
    last_snapshot_time TIMESTAMP WITH TIME ZONE,
    last_streaming_time TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Cấu hình Debezium cho Bộ Tư pháp
\connect ministry_of_justice
-- Tạo bảng theo dõi trạng thái Debezium
CREATE TABLE IF NOT EXISTS cdc.debezium_status (
    connector_id VARCHAR(100) PRIMARY KEY,
    connector_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL,
    last_snapshot_time TIMESTAMP WITH TIME ZONE,
    last_streaming_time TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Cấu hình cho Máy chủ trung tâm
\connect national_citizen_central_server
-- Tạo bảng theo dõi các kết nối Kafka Connect
CREATE TABLE IF NOT EXISTS kafka_connect.connector_config (
    connector_id VARCHAR(100) PRIMARY KEY,
    connector_name VARCHAR(100) NOT NULL,
    connector_type VARCHAR(20) NOT NULL, -- 'source' hoặc 'sink'
    connector_class VARCHAR(200) NOT NULL,
    config JSONB NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tạo bảng theo dõi trạng thái luồng dữ liệu
CREATE TABLE IF NOT EXISTS kafka_connect.data_flow_status (
    flow_id VARCHAR(100) PRIMARY KEY,
    source_system VARCHAR(50) NOT NULL,
    target_system VARCHAR(50) NOT NULL,
    flow_description TEXT,
    status VARCHAR(20) NOT NULL,
    last_sync_time TIMESTAMP WITH TIME ZONE,
    records_processed BIGINT DEFAULT 0,
    error_count BIGINT DEFAULT 0,
    last_error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

\echo 'Quá trình tạo schemas đã hoàn tất'
\echo 'Đã tạo các schema cho Bộ Công an, Bộ Tư pháp và Máy chủ trung tâm'
\echo 'Đã cấu hình các tham số cần thiết cho CDC (Change Data Capture)'
\echo 'Đã tạo publications cho replication và CDC'
\echo 'Đã thiết lập cấu hình bổ sung cho Kafka Connect và Debezium'
\echo 'Tiếp theo là cài đặt extension, tạo các enum và thiết lập Foreign Data Wrapper...'
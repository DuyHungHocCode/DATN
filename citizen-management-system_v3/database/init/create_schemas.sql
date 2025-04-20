-- =============================================================================
-- File: database/init/create_schemas.sql
-- Description: Script tạo các schemas cho hệ thống QLDCQG
-- Version: 2.0 (Đã loại bỏ phần phân quyền, publication, tạo bảng giám sát)
--
-- Chức năng chính:
-- 1. Tạo các schemas cần thiết trong 3 database.
-- 2. Thiết lập các tham số hệ thống cần thiết cho CDC (Change Data Capture).
--
-- Lưu ý:
-- - Phân quyền chi tiết được thực hiện trong `security/permissions.sql`.
-- - Tạo Publications được thực hiện trong `cdc/publication_setup.sql`.
-- - Tạo bảng giám sát CDC/Kafka được thực hiện trong thư mục `cdc` và `kafka`.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO SCHEMAS VÀ CẤU HÌNH CDC ***'

-- ============================================================================
-- 1. TẠO SCHEMAS CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo 'Bước 1: Tạo schemas cho database Bộ Công an...'
\connect ministry_of_public_security

CREATE SCHEMA IF NOT EXISTS public_security;
COMMENT ON SCHEMA public_security IS '[QLDCQG-BCA] Schema chính quản lý dữ liệu dân cư';
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-BCA] Schema chứa dữ liệu tham chiếu dùng chung';
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BCA] Schema chứa dữ liệu nhật ký thay đổi';
CREATE SCHEMA IF NOT EXISTS cdc;
COMMENT ON SCHEMA cdc IS '[QLDCQG-BCA] Schema chứa cấu hình và dữ liệu CDC';
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-BCA] Schema chứa functions/procedures cung cấp API';
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BCA] Schema chứa cấu hình và hàm phân vùng dữ liệu';
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-BCA] Schema chứa views/functions báo cáo, thống kê';
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-BCA] Schema chứa dữ liệu tạm thời ETL/đồng bộ';
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-BCA] Schema chứa các hàm tiện ích chung';

\echo '-> Đã tạo schemas cho ministry_of_public_security.'

-- ============================================================================
-- 2. TẠO SCHEMAS CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Bước 2: Tạo schemas cho database Bộ Tư pháp...'
\connect ministry_of_justice

CREATE SCHEMA IF NOT EXISTS justice;
COMMENT ON SCHEMA justice IS '[QLDCQG-BTP] Schema chính quản lý dữ liệu hộ tịch';
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-BTP] Schema chứa dữ liệu tham chiếu dùng chung';
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BTP] Schema chứa dữ liệu nhật ký thay đổi';
CREATE SCHEMA IF NOT EXISTS cdc;
COMMENT ON SCHEMA cdc IS '[QLDCQG-BTP] Schema chứa cấu hình và dữ liệu CDC';
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-BTP] Schema chứa functions/procedures cung cấp API';
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BTP] Schema chứa cấu hình và hàm phân vùng dữ liệu';
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-BTP] Schema chứa views/functions báo cáo, thống kê';
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-BTP] Schema chứa dữ liệu tạm thời ETL/đồng bộ';
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-BTP] Schema chứa các hàm tiện ích chung';

\echo '-> Đã tạo schemas cho ministry_of_justice.'

-- ============================================================================
-- 3. TẠO SCHEMAS CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Bước 3: Tạo schemas cho database Máy chủ trung tâm...'
\connect national_citizen_central_server

CREATE SCHEMA IF NOT EXISTS central;
COMMENT ON SCHEMA central IS '[QLDCQG-TT] Schema chứa dữ liệu tích hợp từ các nguồn';
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-TT] Schema chứa dữ liệu tham chiếu dùng chung';
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-TT] Schema chứa dữ liệu nhật ký thay đổi';
CREATE SCHEMA IF NOT EXISTS cdc;
COMMENT ON SCHEMA cdc IS '[QLDCQG-TT] Schema chứa cấu hình và dữ liệu CDC (cho đồng bộ ngược)';
CREATE SCHEMA IF NOT EXISTS sync;
COMMENT ON SCHEMA sync IS '[QLDCQG-TT] Schema chứa cấu hình và bảng quản lý đồng bộ hóa';
CREATE SCHEMA IF NOT EXISTS public_security_mirror;
COMMENT ON SCHEMA public_security_mirror IS '[QLDCQG-TT] Schema chứa dữ liệu FDW/phản chiếu từ Bộ Công an';
CREATE SCHEMA IF NOT EXISTS justice_mirror;
COMMENT ON SCHEMA justice_mirror IS '[QLDCQG-TT] Schema chứa dữ liệu FDW/phản chiếu từ Bộ Tư pháp';
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-TT] Schema chứa functions/procedures cung cấp API tích hợp';
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-TT] Schema chứa cấu hình và hàm phân vùng dữ liệu';
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-TT] Schema chứa views/functions báo cáo, thống kê tổng hợp';
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-TT] Schema chứa dữ liệu tạm thời ETL/đồng bộ';
CREATE SCHEMA IF NOT EXISTS analytics;
COMMENT ON SCHEMA analytics IS '[QLDCQG-TT] Schema chứa dữ liệu và hàm phục vụ phân tích dữ liệu';
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-TT] Schema chứa các hàm tiện ích chung';
CREATE SCHEMA IF NOT EXISTS kafka;
COMMENT ON SCHEMA kafka IS '[QLDCQG-TT] Schema chứa cấu hình và bảng giám sát Kafka';
-- Đổi tên kafka_connect thành kafka cho ngắn gọn và bao quát hơn

\echo '-> Đã tạo schemas cho national_citizen_central_server.'

-- ============================================================================
-- 4. CẤU HÌNH THAM SỐ HỆ THỐNG CHO CDC (CHANGE DATA CAPTURE)
-- Lưu ý: Các lệnh ALTER SYSTEM yêu cầu quyền superuser và cần khởi động lại
--        PostgreSQL instance để có hiệu lực hoàn toàn.
--        Việc này thường được thực hiện ngoài script SQL trong môi trường production.
-- ============================================================================
\echo 'Bước 4: Cấu hình các tham số hệ thống cho CDC...'
\echo '        LƯU Ý: Yêu cầu superuser và khởi động lại PostgreSQL instance.'

-- Cấu hình cho Bộ Công an
\connect ministry_of_public_security
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 10; -- Số lượng slot tối đa (cho Debezium, standby...)
ALTER SYSTEM SET max_wal_senders = 10;      -- Số lượng tiến trình gửi WAL tối đa
ALTER SYSTEM SET track_commit_timestamp = on; -- Cần cho một số connector/công cụ
ALTER SYSTEM SET wal_sender_timeout = '60s';  -- Timeout cho sender
ALTER SYSTEM SET max_slot_wal_keep_size = '4GB'; -- Giới hạn dung lượng WAL giữ lại cho slot
\echo '   -> Đã cấu hình tham số CDC cho ministry_of_public_security (cần restart).'

-- Cấu hình cho Bộ Tư pháp
\connect ministry_of_justice
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 10;
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET track_commit_timestamp = on;
ALTER SYSTEM SET wal_sender_timeout = '60s';
ALTER SYSTEM SET max_slot_wal_keep_size = '4GB';
\echo '   -> Đã cấu hình tham số CDC cho ministry_of_justice (cần restart).'

-- Cấu hình cho Máy chủ trung tâm
\connect national_citizen_central_server
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 20; -- Có thể cần nhiều hơn cho đồng bộ ngược và các mục đích khác
ALTER SYSTEM SET max_wal_senders = 20;
ALTER SYSTEM SET track_commit_timestamp = on;
ALTER SYSTEM SET wal_sender_timeout = '120s';
ALTER SYSTEM SET max_slot_wal_keep_size = '8GB'; -- Trung tâm có thể cần lưu trữ nhiều hơn
\echo '   -> Đã cấu hình tham số CDC cho national_citizen_central_server (cần restart).'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO SCHEMAS VÀ CẤU HÌNH CDC ***'
\echo '-> Đã tạo các schemas cần thiết cho 3 database.'
\echo '-> Đã cấu hình các tham số hệ thống cho CDC (nhớ khởi động lại PostgreSQL).'
\echo '-> Bước tiếp theo: Chạy security/permissions.sql để cấp quyền trên schemas.'
\echo '->                 Chạy cdc/publication_setup.sql để tạo publications.'
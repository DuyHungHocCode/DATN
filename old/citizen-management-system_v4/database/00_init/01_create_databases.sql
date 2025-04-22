-- File: 00_init/01_create_databases.sql (Version 3.1 - No GRANT CONNECT)
-- Description: Script khởi tạo 3 cơ sở dữ liệu chính cho hệ thống QLDCQG
--              theo kiến trúc microservices. (Đã loại bỏ GRANT CONNECT)
-- Version: 3.1 (Removed GRANT CONNECT step)
--
-- Chức năng chính:
-- 1. Xóa các database cũ (nếu tồn tại) để đảm bảo môi trường sạch.
-- 2. Tạo 3 database: ministry_of_public_security, ministry_of_justice,
--    national_citizen_central_server với các cấu hình cơ bản.
-- 3. Thiết lập các tham số cấu hình quan trọng cho từng database.
--
-- Yêu cầu: Chạy script này với quyền superuser (ví dụ: user postgres).
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO CƠ SỞ DỮ LIỆU ***'

-- Kết nối đến PostgreSQL instance mặc định (ví dụ: postgres) với quyền superuser
\connect postgres

-- ============================================================================
-- 1. XÓA DATABASE CŨ (NẾU TỒN TẠI)
-- ============================================================================
\echo 'Bước 1: Xóa các database cũ (nếu tồn tại)...'

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname IN ('ministry_of_public_security', 'ministry_of_justice', 'national_citizen_central_server')
  AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS ministry_of_public_security WITH (FORCE);
DROP DATABASE IF EXISTS ministry_of_justice WITH (FORCE);
DROP DATABASE IF EXISTS national_citizen_central_server WITH (FORCE);

\echo '-> Đã xóa các database cũ (nếu có).'

-- ============================================================================
-- 2. TẠO DATABASE MỚI
-- ============================================================================
\echo 'Bước 2: Tạo các database mới...'

-- 2.1 Tạo database cho Bộ Công an (BCA)
\echo '   -> Tạo database ministry_of_public_security...'
CREATE DATABASE ministry_of_public_security
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
COMMENT ON DATABASE ministry_of_public_security IS '[QLDCQG-BCA] CSDL Quản lý dân cư - Bộ Công an';

-- 2.2 Tạo database cho Bộ Tư pháp (BTP)
\echo '   -> Tạo database ministry_of_justice...'
CREATE DATABASE ministry_of_justice
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
COMMENT ON DATABASE ministry_of_justice IS '[QLDCQG-BTP] CSDL Hộ tịch - Bộ Tư pháp';

-- 2.3 Tạo database cho Máy chủ trung tâm (TT)
\echo '   -> Tạo database national_citizen_central_server...'
CREATE DATABASE national_citizen_central_server
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
COMMENT ON DATABASE national_citizen_central_server IS '[QLDCQG-TT] CSDL Trung tâm Tích hợp Dữ liệu Dân cư Quốc gia';

\echo '-> Đã tạo thành công 3 database.'

-- ============================================================================
-- 3. THIẾT LẬP CẤU HÌNH CHO TỪNG DATABASE
-- ============================================================================
\echo 'Bước 3: Thiết lập cấu hình cho từng database...'

-- 3.1 Cấu hình cho Bộ Công an (BCA)
\echo '   -> Cấu hình ministry_of_public_security...'
\connect ministry_of_public_security
ALTER DATABASE ministry_of_public_security SET search_path TO public_security, reference, audit, api, partitioning, reports, staging, utility, public;
ALTER DATABASE ministry_of_public_security SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE ministry_of_public_security SET statement_timeout = '300s';
ALTER DATABASE ministry_of_public_security SET lock_timeout = '60s';
ALTER DATABASE ministry_of_public_security SET idle_in_transaction_session_timeout = '3600s';
ALTER DATABASE ministry_of_public_security SET default_statistics_target = 500;
ALTER DATABASE ministry_of_public_security SET standard_conforming_strings = on;

-- 3.2 Cấu hình cho Bộ Tư pháp (BTP)
\echo '   -> Cấu hình ministry_of_justice...'
\connect ministry_of_justice
ALTER DATABASE ministry_of_justice SET search_path TO justice, reference, audit, api, partitioning, reports, staging, utility, public;
ALTER DATABASE ministry_of_justice SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE ministry_of_justice SET statement_timeout = '300s';
ALTER DATABASE ministry_of_justice SET lock_timeout = '60s';
ALTER DATABASE ministry_of_justice SET idle_in_transaction_session_timeout = '3600s';
ALTER DATABASE ministry_of_justice SET default_statistics_target = 500;
ALTER DATABASE ministry_of_justice SET standard_conforming_strings = on;

-- 3.3 Cấu hình cho Máy chủ trung tâm (TT)
\echo '   -> Cấu hình national_citizen_central_server...'
\connect national_citizen_central_server
ALTER DATABASE national_citizen_central_server SET search_path TO central, sync, public_security_mirror, justice_mirror, reference, audit, api, partitioning, reports, staging, utility, public;
ALTER DATABASE national_citizen_central_server SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE national_citizen_central_server SET statement_timeout = '600s';
ALTER DATABASE national_citizen_central_server SET lock_timeout = '60s';
ALTER DATABASE national_citizen_central_server SET idle_in_transaction_session_timeout = '7200s';
ALTER DATABASE national_citizen_central_server SET default_statistics_target = 1000;
ALTER DATABASE national_citizen_central_server SET standard_conforming_strings = on;

\echo '-> Đã thiết lập cấu hình cơ bản cho các database.'

-- ============================================================================
-- BƯỚC 4 ĐÃ BỊ XÓA (GRANT CONNECT) - Sẽ được thực hiện trong 02_permissions.sql
-- ============================================================================

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO CƠ SỞ DỮ LIỆU ***'
\echo '-> Đã tạo và cấu hình 3 database.'
\echo '-> Bước tiếp theo: Chạy 00_init/02_create_schemas.sql để tạo các schema cơ bản.'
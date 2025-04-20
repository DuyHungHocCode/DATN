-- =============================================================================
-- File: database/init/create_database.sql
-- Description: Script khởi tạo các cơ sở dữ liệu cho hệ thống QLDCQG
-- Version: 2.0 (Tách phần tạo user/role sang security/roles.sql)
--
-- Chức năng chính:
-- 1. Xóa các database cũ (nếu tồn tại) để đảm bảo môi trường sạch.
-- 2. Tạo 3 database chính: ministry_of_public_security, ministry_of_justice,
--    national_citizen_central_server với các cấu hình cơ bản.
-- 3. Thiết lập các tham số cấu hình quan trọng cho từng database.
-- 4. Cấp quyền kết nối cơ bản cho các user (được tạo trong security/roles.sql).
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO CƠ SỞ DỮ LIỆU ***'

-- Kết nối đến PostgreSQL instance mặc định (ví dụ: postgres) với quyền superuser
\connect postgres

-- ============================================================================
-- 1. XÓA DATABASE CŨ (NẾU TỒN TẠI)
-- ============================================================================
\echo 'Bước 1: Xóa các database cũ (nếu tồn tại)...'

-- Ngắt kết nối người dùng khỏi các database trước khi xóa
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE datname IN ('ministry_of_public_security', 'ministry_of_justice', 'national_citizen_central_server');

DROP DATABASE IF EXISTS ministry_of_public_security;
DROP DATABASE IF EXISTS ministry_of_justice;
DROP DATABASE IF EXISTS national_citizen_central_server;

\echo '-> Đã xóa các database cũ (nếu có).'

-- ============================================================================
-- 2. TẠO DATABASE MỚI
-- ============================================================================
\echo 'Bước 2: Tạo các database mới...'

-- 2.1 Tạo database cho Bộ Công an
\echo '   -> Tạo database ministry_of_public_security...'
CREATE DATABASE ministry_of_public_security
    WITH
    OWNER = postgres -- Hoặc một user quản trị khác nếu muốn
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8' -- Sử dụng collation chuẩn để tránh lỗi sắp xếp
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1 -- Không giới hạn kết nối
    IS_TEMPLATE = False;

COMMENT ON DATABASE ministry_of_public_security IS '[QLDCQG] CSDL Quản lý dân cư - Bộ Công an';

-- 2.2 Tạo database cho Bộ Tư pháp
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

COMMENT ON DATABASE ministry_of_justice IS '[QLDCQG] CSDL Hộ tịch - Bộ Tư pháp';

-- 2.3 Tạo database cho Máy chủ trung tâm
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

COMMENT ON DATABASE national_citizen_central_server IS '[QLDCQG] CSDL Trung tâm Tích hợp Dữ liệu Dân cư Quốc gia';

\echo '-> Đã tạo thành công 3 database.'

-- ============================================================================
-- 3. THIẾT LẬP CẤU HÌNH CHO TỪNG DATABASE
-- ============================================================================
\echo 'Bước 3: Thiết lập cấu hình cho từng database...'

-- 3.1 Cấu hình cho Bộ Công an
\echo '   -> Cấu hình ministry_of_public_security...'
\connect ministry_of_public_security
-- Thiết lập search_path mặc định (quan trọng!)
ALTER DATABASE ministry_of_public_security SET search_path TO public_security, reference, public;
-- Thiết lập múi giờ
ALTER DATABASE ministry_of_public_security SET timezone TO 'Asia/Ho_Chi_Minh';
-- Thiết lập timeout cho câu lệnh (5 phút)
ALTER DATABASE ministry_of_public_security SET statement_timeout = '300000';
-- Thiết lập timeout cho khóa (1 phút)
ALTER DATABASE ministry_of_public_security SET lock_timeout = '60000';
-- Thiết lập timeout cho session không hoạt động trong transaction (1 giờ)
ALTER DATABASE ministry_of_public_security SET idle_in_transaction_session_timeout = '3600000';
-- Tăng mức độ chi tiết thống kê cho planner
ALTER DATABASE ministry_of_public_security SET default_statistics_target = 500;
-- Đảm bảo tuân thủ chuỗi chuẩn SQL
ALTER DATABASE ministry_of_public_security SET standard_conforming_strings = on;

-- 3.2 Cấu hình cho Bộ Tư pháp
\echo '   -> Cấu hình ministry_of_justice...'
\connect ministry_of_justice
ALTER DATABASE ministry_of_justice SET search_path TO justice, reference, public;
ALTER DATABASE ministry_of_justice SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE ministry_of_justice SET statement_timeout = '300000';
ALTER DATABASE ministry_of_justice SET lock_timeout = '60000';
ALTER DATABASE ministry_of_justice SET idle_in_transaction_session_timeout = '3600000';
ALTER DATABASE ministry_of_justice SET default_statistics_target = 500;
ALTER DATABASE ministry_of_justice SET standard_conforming_strings = on;

-- 3.3 Cấu hình cho Máy chủ trung tâm
\echo '   -> Cấu hình national_citizen_central_server...'
\connect national_citizen_central_server
ALTER DATABASE national_citizen_central_server SET search_path TO central, sync, public_security_mirror, justice_mirror, reference, kafka, cdc, public;
ALTER DATABASE national_citizen_central_server SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE national_citizen_central_server SET statement_timeout = '600000'; -- 10 phút (cho các tác vụ tổng hợp)
ALTER DATABASE national_citizen_central_server SET lock_timeout = '60000';
ALTER DATABASE national_citizen_central_server SET idle_in_transaction_session_timeout = '7200000'; -- 2 giờ
ALTER DATABASE national_citizen_central_server SET default_statistics_target = 1000; -- Thống kê chi tiết hơn
ALTER DATABASE national_citizen_central_server SET standard_conforming_strings = on;

\echo '-> Đã thiết lập cấu hình cơ bản cho các database.'

-- ============================================================================
-- 4. CẤP QUYỀN KẾT NỐI CƠ BẢN
-- (Lưu ý: User và Role được tạo trong security/roles.sql)
-- (Lưu ý: Quyền chi tiết trên schema/table được cấp trong security/permissions.sql)
-- ============================================================================
\echo 'Bước 4: Cấp quyền kết nối cơ bản (CONNECT) cho các roles...'
\echo '        (Giả định các roles đã được tạo trong security/roles.sql)'

-- Kết nối lại postgres để cấp quyền trên các database khác
\connect postgres

-- Cấp quyền CONNECT cho các role trên database Bộ Công an
GRANT CONNECT ON DATABASE ministry_of_public_security TO security_admin, security_reader, security_writer, sync_user;
\echo '   -> Đã cấp quyền CONNECT trên ministry_of_public_security.'

-- Cấp quyền CONNECT cho các role trên database Bộ Tư pháp
GRANT CONNECT ON DATABASE ministry_of_justice TO justice_admin, justice_reader, justice_writer, sync_user;
\echo '   -> Đã cấp quyền CONNECT trên ministry_of_justice.'

-- Cấp quyền CONNECT cho các role trên database Máy chủ trung tâm
GRANT CONNECT ON DATABASE national_citizen_central_server TO central_server_admin, central_server_reader, sync_user;
\echo '   -> Đã cấp quyền CONNECT trên national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO CƠ SỞ DỮ LIỆU ***'
\echo '-> Đã tạo và cấu hình 3 database.'
\echo '-> Bước tiếp theo: Chạy security/roles.sql để tạo người dùng/vai trò.'
\echo '->                 Sau đó chạy init/create_schemas.sql để tạo schemas.'
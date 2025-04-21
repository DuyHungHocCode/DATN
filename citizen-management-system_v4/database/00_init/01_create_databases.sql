-- =============================================================================
-- File: 00_init/01_create_databases.sql
-- Description: Script khởi tạo 3 cơ sở dữ liệu chính cho hệ thống QLDCQG
--              theo kiến trúc microservices.
-- Version: 3.0 (Refined for Microservices Structure)
--
-- Chức năng chính:
-- 1. Xóa các database cũ (nếu tồn tại) để đảm bảo môi trường sạch.
-- 2. Tạo 3 database: ministry_of_public_security, ministry_of_justice,
--    national_citizen_central_server với các cấu hình cơ bản.
-- 3. Thiết lập các tham số cấu hình quan trọng cho từng database.
-- 4. Cấp quyền kết nối cơ bản cho các roles (sẽ được tạo sau).
--
-- Yêu cầu: Chạy script này với quyền superuser (ví dụ: user postgres).
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO CƠ SỞ DỮ LIỆU ***'

-- Kết nối đến PostgreSQL instance mặc định (ví dụ: postgres) với quyền superuser
-- Đảm bảo bạn đang chạy psql hoặc công cụ tương tự hỗ trợ meta-commands (\connect, \echo)
\connect postgres

-- ============================================================================
-- 1. XÓA DATABASE CŨ (NẾU TỒN TẠI)
-- ============================================================================
\echo 'Bước 1: Xóa các database cũ (nếu tồn tại)...'

-- Ngắt kết nối người dùng đang hoạt động khỏi các database trước khi xóa
-- Cẩn thận khi chạy lệnh này trên môi trường production!
-- Lệnh này cố gắng ngắt các kết nối khác, trừ session hiện tại đang chạy script.
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname IN ('ministry_of_public_security', 'ministry_of_justice', 'national_citizen_central_server')
  AND pid <> pg_backend_pid(); -- Không ngắt chính session này

-- Chờ một chút để đảm bảo các backend đã được terminate (tùy chọn, có thể cần điều chỉnh)
-- SELECT pg_sleep(2);

-- Xóa databases nếu tồn tại. Sử dụng WITH (FORCE) nếu cần thiết và hiểu rõ hậu quả.
-- FORCE sẽ ngắt kết nối mạnh hơn nhưng có thể gây mất dữ liệu nếu có transaction đang chạy.
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
    OWNER = postgres -- Chủ sở hữu database, nên là một role quản trị riêng nếu có thể
    ENCODING = 'UTF8' -- Encoding chuẩn cho dữ liệu tiếng Việt và quốc tế
    LC_COLLATE = 'en_US.UTF-8' -- Quy tắc sắp xếp chuỗi (collation). 'en_US.UTF-8' thường ổn định.
                               -- Có thể dùng 'vi_VN.UTF-8' nếu OS hỗ trợ và muốn sắp xếp chuẩn tiếng Việt.
    LC_CTYPE = 'en_US.UTF-8'   -- Quy tắc phân loại ký tự (character type).
    TABLESPACE = pg_default -- Sử dụng tablespace mặc định
    CONNECTION LIMIT = -1 -- Không giới hạn số lượng kết nối đồng thời (-1 là không giới hạn)
    IS_TEMPLATE = False; -- Không phải là database mẫu

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
-- Kết nối vào DB BCA để thực hiện lệnh ALTER DATABASE
\connect ministry_of_public_security
-- Thiết lập search_path mặc định (quan trọng!) - Các schema này sẽ được tạo sau
-- Thứ tự schema quan trọng, PostgreSQL sẽ tìm đối tượng theo thứ tự này.
ALTER DATABASE ministry_of_public_security SET search_path TO public_security, reference, audit, api, partitioning, reports, staging, utility, public;
-- Thiết lập múi giờ Việt Nam
ALTER DATABASE ministry_of_public_security SET timezone TO 'Asia/Ho_Chi_Minh';
-- Thiết lập timeout cho câu lệnh (ví dụ: 5 phút = 300 giây)
ALTER DATABASE ministry_of_public_security SET statement_timeout = '300s';
-- Thiết lập timeout cho việc chờ khóa (ví dụ: 1 phút = 60 giây)
ALTER DATABASE ministry_of_public_security SET lock_timeout = '60s';
-- Thiết lập timeout cho session không hoạt động khi đang trong transaction (ví dụ: 1 giờ = 3600 giây)
ALTER DATABASE ministry_of_public_security SET idle_in_transaction_session_timeout = '3600s';
-- Tăng mức độ chi tiết thống kê cho planner (giúp tối ưu query tốt hơn cho các bảng lớn)
ALTER DATABASE ministry_of_public_security SET default_statistics_target = 500;
-- Đảm bảo cách xử lý chuỗi tuân thủ chuẩn SQL (tránh các vấn đề với escape ký tự)
ALTER DATABASE ministry_of_public_security SET standard_conforming_strings = on;

-- 3.2 Cấu hình cho Bộ Tư pháp (BTP)
\echo '   -> Cấu hình ministry_of_justice...'
-- Kết nối vào DB BTP
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
-- Kết nối vào DB TT
\connect national_citizen_central_server
-- Cập nhật search_path: Loại bỏ kafka, cdc. Thêm các schema mirror và sync.
ALTER DATABASE national_citizen_central_server SET search_path TO central, sync, public_security_mirror, justice_mirror, reference, audit, api, partitioning, reports, staging, utility, public;
ALTER DATABASE national_citizen_central_server SET timezone TO 'Asia/Ho_Chi_Minh';
-- Tăng timeout cho các tác vụ tổng hợp, đồng bộ (ví dụ: 10 phút = 600 giây)
ALTER DATABASE national_citizen_central_server SET statement_timeout = '600s';
ALTER DATABASE national_citizen_central_server SET lock_timeout = '60s';
-- Tăng timeout cho session không hoạt động trong transaction (ví dụ: 2 giờ = 7200 giây)
ALTER DATABASE national_citizen_central_server SET idle_in_transaction_session_timeout = '7200s';
-- Thống kê chi tiết hơn cho các bảng lớn, tích hợp
ALTER DATABASE national_citizen_central_server SET default_statistics_target = 1000;
ALTER DATABASE national_citizen_central_server SET standard_conforming_strings = on;

\echo '-> Đã thiết lập cấu hình cơ bản cho các database.'

-- ============================================================================
-- 4. CẤP QUYỀN KẾT NỐI CƠ BẢN
-- (Lưu ý: Các Roles được tạo trong 02_security/01_roles.sql)
-- (Lưu ý: Quyền chi tiết trên schema/table được cấp trong 02_security/02_permissions.sql)
-- ============================================================================
\echo 'Bước 4: Cấp quyền kết nối cơ bản (CONNECT) cho các roles (sẽ được tạo sau)...'

-- Kết nối lại postgres để có thể cấp quyền trên các database khác nhau
\connect postgres

-- Cấp quyền CONNECT cho các role trên database Bộ Công an
-- Giả định các role này sẽ được tạo trong script 02_security/01_roles.sql
-- Cần đảm bảo các role này tồn tại trước khi script permissions được chạy.
GRANT CONNECT ON DATABASE ministry_of_public_security TO security_admin, security_reader, security_writer, sync_user;
\echo '   -> Đã cấp quyền CONNECT trên ministry_of_public_security (cho các roles sẽ được tạo).'

-- Cấp quyền CONNECT cho các role trên database Bộ Tư pháp
GRANT CONNECT ON DATABASE ministry_of_justice TO justice_admin, justice_reader, justice_writer, sync_user;
\echo '   -> Đã cấp quyền CONNECT trên ministry_of_justice (cho các roles sẽ được tạo).'

-- Cấp quyền CONNECT cho các role trên database Máy chủ trung tâm
GRANT CONNECT ON DATABASE national_citizen_central_server TO central_server_admin, central_server_reader, sync_user;
\echo '   -> Đã cấp quyền CONNECT trên national_citizen_central_server (cho các roles sẽ được tạo).'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO CƠ SỞ DỮ LIỆU ***'
\echo '-> Đã tạo và cấu hình 3 database.'
\echo '-> Bước tiếp theo: Chạy 00_init/02_create_schemas.sql để tạo các schema cơ bản.'


-- =============================================================================
-- File: 00_init/01_create_databases.sql
-- Description: Khởi tạo 03 cơ sở dữ liệu chính cho Hệ thống Quản lý Dân cư Quốc gia (QLDCQG)
--              theo kiến trúc microservices.
-- Version: 3.2 (Refined comments and structure)
--
-- Databases được tạo:
-- 1. ministry_of_public_security: Dành cho nghiệp vụ Bộ Công an (BCA).
-- 2. ministry_of_justice: Dành cho nghiệp vụ Bộ Tư pháp (BTP).
-- 3. national_citizen_central_server: Máy chủ trung tâm tích hợp dữ liệu (TT).
-- =============================================================================

\echo '*** KHỞI TẠO CÁC CƠ SỞ DỮ LIỆU CHO HỆ THỐNG QLDCQG ***'

-- Lệnh CREATE DATABASE là cluster-level, không cần kết nối DB cụ thể.
\connect postgres

-- === 1. DỌN DẸP MÔI TRƯỜNG (XÓA DATABASE CŨ NẾU TỒN TẠI) ===

\echo '[Bước 1] Kiểm tra và xóa các database cũ...'

-- Ngắt các kết nối đang hoạt động đến các database này để có thể xóa
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname IN ('ministry_of_public_security', 'ministry_of_justice', 'national_citizen_central_server')
  AND pid <> pg_backend_pid(); -- Không ngắt chính phiên đang chạy script này

-- Xóa database nếu tồn tại, sử dụng FORCE để xử lý các kết nối còn sót lại (nếu có)
DROP DATABASE IF EXISTS ministry_of_public_security WITH (FORCE);
DROP DATABASE IF EXISTS ministry_of_justice WITH (FORCE);
DROP DATABASE IF EXISTS national_citizen_central_server WITH (FORCE);

\echo '   -> Hoàn thành xóa database cũ (nếu có).'

-- === 2. TẠO CÁC DATABASE MỚI ===

\echo '[Bước 2] Tạo các database mới...'

-- 2.1. Database Bộ Công an (BCA)
\echo '   -> Tạo database: ministry_of_public_security (BCA)...'
CREATE DATABASE ministry_of_public_security
    WITH
    OWNER = postgres -- Chủ sở hữu database (thường là superuser hoặc role quản trị)
    ENCODING = 'UTF8' -- Bảng mã khuyến nghị cho tiếng Việt
    LC_COLLATE = 'en_US.UTF-8' -- Quy tắc sắp xếp, 'en_US.UTF-8' thường tương thích rộng rãi
    LC_CTYPE = 'en_US.UTF-8' -- Quy tắc phân loại ký tự
    TABLESPACE = pg_default -- Sử dụng tablespace mặc định
    CONNECTION LIMIT = -1 -- Không giới hạn số kết nối đồng thời (-1)
    IS_TEMPLATE = False; -- Không phải là database mẫu
COMMENT ON DATABASE ministry_of_public_security
    IS '[QLDCQG-BCA] Cơ sở dữ liệu nghiệp vụ của Bộ Công an (Quản lý công dân, CCCD, cư trú...)';

-- 2.2. Database Bộ Tư pháp (BTP)
\echo '   -> Tạo database: ministry_of_justice (BTP)...'
CREATE DATABASE ministry_of_justice
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
COMMENT ON DATABASE ministry_of_justice
    IS '[QLDCQG-BTP] Cơ sở dữ liệu nghiệp vụ của Bộ Tư pháp (Hộ tịch: khai sinh, khai tử, kết hôn...)';

-- 2.3. Database Máy chủ Trung tâm (TT)
\echo '   -> Tạo database: national_citizen_central_server (TT)...'
CREATE DATABASE national_citizen_central_server
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
COMMENT ON DATABASE national_citizen_central_server
    IS '[QLDCQG-TT] Cơ sở dữ liệu Trung tâm Tích hợp Dữ liệu Dân cư Quốc gia';

\echo '   -> Hoàn thành tạo 3 database.'

-- === 3. THIẾT LẬP CẤU HÌNH CƠ BẢN CHO TỪNG DATABASE ===
-- Các cấu hình này có thể được ghi đè bởi cấu hình session hoặc role.

\echo '[Bước 3] Thiết lập cấu hình cơ bản cho các database...'

-- 3.1. Cấu hình cho ministry_of_public_security (BCA)
\echo '   -> Cấu hình ministry_of_public_security...'
\connect ministry_of_public_security
-- Thiết lập đường dẫn tìm kiếm schema mặc định
ALTER DATABASE ministry_of_public_security SET search_path TO public_security, reference, audit, api, partitioning, reports, staging, utility, public;
-- Thiết lập múi giờ Việt Nam
ALTER DATABASE ministry_of_public_security SET timezone TO 'Asia/Ho_Chi_Minh';
-- Giới hạn thời gian chạy tối đa cho một câu lệnh SQL (ví dụ: 5 phút)
ALTER DATABASE ministry_of_public_security SET statement_timeout = '300s';
-- Giới hạn thời gian chờ khóa tối đa (ví dụ: 1 phút)
ALTER DATABASE ministry_of_public_security SET lock_timeout = '60s';
-- Giới hạn thời gian một transaction có thể ở trạng thái idle (ví dụ: 1 giờ)
ALTER DATABASE ministry_of_public_security SET idle_in_transaction_session_timeout = '3600s';
-- Tăng mức độ chi tiết thống kê cho bộ tối ưu hóa truy vấn
ALTER DATABASE ministry_of_public_security SET default_statistics_target = 500;
-- Đảm bảo xử lý chuỗi theo chuẩn SQL
ALTER DATABASE ministry_of_public_security SET standard_conforming_strings = on;

-- 3.2. Cấu hình cho ministry_of_justice (BTP)
\echo '   -> Cấu hình ministry_of_justice...'
\connect ministry_of_justice
ALTER DATABASE ministry_of_justice SET search_path TO justice, reference, audit, api, partitioning, reports, staging, utility, public;
ALTER DATABASE ministry_of_justice SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE ministry_of_justice SET statement_timeout = '300s';
ALTER DATABASE ministry_of_justice SET lock_timeout = '60s';
ALTER DATABASE ministry_of_justice SET idle_in_transaction_session_timeout = '3600s';
ALTER DATABASE ministry_of_justice SET default_statistics_target = 500;
ALTER DATABASE ministry_of_justice SET standard_conforming_strings = on;

-- 3.3. Cấu hình cho national_citizen_central_server (TT)
\echo '   -> Cấu hình national_citizen_central_server...'
\connect national_citizen_central_server
-- Bao gồm cả các schema mirror cho FDW
ALTER DATABASE national_citizen_central_server SET search_path TO central, sync, public_security_mirror, justice_mirror, reference, audit, api, partitioning, reports, staging, utility, public;
ALTER DATABASE national_citizen_central_server SET timezone TO 'Asia/Ho_Chi_Minh';
-- Có thể cần timeout dài hơn cho các tác vụ đồng bộ hoặc báo cáo phức tạp
ALTER DATABASE national_citizen_central_server SET statement_timeout = '600s'; -- Ví dụ: 10 phút
ALTER DATABASE national_citizen_central_server SET lock_timeout = '60s';
ALTER DATABASE national_citizen_central_server SET idle_in_transaction_session_timeout = '7200s'; -- Ví dụ: 2 giờ
-- Mức thống kê cao hơn do dữ liệu tích hợp có thể phức tạp hơn
ALTER DATABASE national_citizen_central_server SET default_statistics_target = 1000;
ALTER DATABASE national_citizen_central_server SET standard_conforming_strings = on;

\echo '   -> Hoàn thành thiết lập cấu hình cơ bản.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH QUÁ TRÌNH KHỞI TẠO CƠ SỞ DỮ LIỆU ***'
\echo '-> Đã tạo và cấu hình 3 database: ministry_of_public_security, ministry_of_justice, national_citizen_central_server.'
\echo '-> Bước tiếp theo: Chạy script 00_init/02_create_schemas.sql để tạo các schema.'

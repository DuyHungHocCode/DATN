-- Script khởi tạo cơ sở dữ liệu cho hệ thống quản lý dân cư quốc gia

-- Kết nối đến PostgreSQL 
\connect postgres

--Xóa database nếu đã tồn tại
DROP DATABASE IF EXISTS ministry_of_public_security;
DROP DATABASE IF EXISTS ministry_of_justice;
DROP DATABASE IF EXISTS national_citizen_central_server;

-- 2. TẠO DATABASE CHO TỪNG BỘ NGÀNH

--Tạo database cho Bộ Công an
CREATE DATABASE ministry_of_public_security
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE ministry_of_public_security IS 'CSDL quản lý dân cư thuộc Bộ Công an';

-- Đặt các tham số cấu hình quan trọng cho Bộ Công an
\connect ministry_of_public_security
ALTER DATABASE ministry_of_public_security SET search_path TO public_security, reference, public;
ALTER DATABASE ministry_of_public_security SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE ministry_of_public_security SET statement_timeout = '300000'; -- 5 phút
ALTER DATABASE ministry_of_public_security SET lock_timeout = '60000'; -- 1 phút
ALTER DATABASE ministry_of_public_security SET idle_in_transaction_session_timeout = '3600000'; -- 1 giờ
ALTER DATABASE ministry_of_public_security SET default_statistics_target = 500; -- Giá trị thống kê cao hơn
ALTER DATABASE ministry_of_public_security SET standard_conforming_strings = on;

--Tạo database cho Bộ Tư pháp
CREATE DATABASE ministry_of_justice
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE ministry_of_justice IS 'CSDL quản lý dân cư thuộc Bộ Tư pháp';

-- Đặt các tham số cấu hình quan trọng cho Bộ Tư pháp
\connect ministry_of_justice
ALTER DATABASE ministry_of_justice SET search_path TO justice, reference, public;
ALTER DATABASE ministry_of_justice SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE ministry_of_justice SET statement_timeout = '300000'; -- 5 phút
ALTER DATABASE ministry_of_justice SET lock_timeout = '60000'; -- 1 phút
ALTER DATABASE ministry_of_justice SET idle_in_transaction_session_timeout = '3600000'; -- 1 giờ
ALTER DATABASE ministry_of_justice SET default_statistics_target = 500; -- Giá trị thống kê cao hơn
ALTER DATABASE ministry_of_justice SET standard_conforming_strings = on;

--Tạo database cho máy chủ trung tâm
CREATE DATABASE national_citizen_central_server
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE national_citizen_central_server IS 'CSDL trung tâm quản lý dân cư quốc gia';

-- Đặt các tham số cấu hình quan trọng cho máy chủ trung tâm
\connect national_citizen_central_server
ALTER DATABASE national_citizen_central_server SET search_path TO central, reference, public;
ALTER DATABASE national_citizen_central_server SET timezone TO 'Asia/Ho_Chi_Minh';
ALTER DATABASE national_citizen_central_server SET statement_timeout = '600000'; -- 10 phút
ALTER DATABASE national_citizen_central_server SET lock_timeout = '60000'; -- 1 phút
ALTER DATABASE national_citizen_central_server SET idle_in_transaction_session_timeout = '7200000'; -- 2 giờ
ALTER DATABASE national_citizen_central_server SET default_statistics_target = 1000; -- Giá trị thống kê cao hơn nhiều
ALTER DATABASE national_citizen_central_server SET standard_conforming_strings = on;

-- 3. TẠO CÁC NGƯỜI DÙNG VÀ PHÂN QUYỀN

-- Xóa các người dùng cũ nếu tồn tại
DROP USER IF EXISTS security_admin;
DROP USER IF EXISTS justice_admin;
DROP USER IF EXISTS central_server_admin;
DROP USER IF EXISTS security_reader;
DROP USER IF EXISTS justice_reader;
DROP USER IF EXISTS central_server_reader;
DROP USER IF EXISTS security_writer;
DROP USER IF EXISTS justice_writer;
DROP USER IF EXISTS sync_user;

-- A. Tạo người dùng quản trị cho từng hệ thống
CREATE USER security_admin WITH ENCRYPTED PASSWORD 'SecureMPS@2025';
CREATE USER justice_admin WITH ENCRYPTED PASSWORD 'SecureMOJ@2025';
CREATE USER central_server_admin WITH ENCRYPTED PASSWORD 'SecureCentralServer@2025';

-- B. Tạo người dùng chỉ đọc (cho các truy vấn và báo cáo)
CREATE USER security_reader WITH ENCRYPTED PASSWORD 'ReaderMPS@2025';
CREATE USER justice_reader WITH ENCRYPTED PASSWORD 'ReaderMOJ@2025';
CREATE USER central_server_reader WITH ENCRYPTED PASSWORD 'ReaderCentralServer@2025';

-- C. Tạo người dùng chỉ ghi (cho các ứng dụng nhập liệu)
CREATE USER security_writer WITH ENCRYPTED PASSWORD 'WriterMPS@2025';
CREATE USER justice_writer WITH ENCRYPTED PASSWORD 'WriterMOJ@2025';

-- D. Tạo người dùng đặc biệt cho đồng bộ dữ liệu
CREATE USER sync_user WITH ENCRYPTED PASSWORD 'SyncData@2025';

-- E. Cấp quyền cho các người dùng
-- Cho Bộ Công an
GRANT ALL PRIVILEGES ON DATABASE ministry_of_public_security TO security_admin;
GRANT CONNECT, TEMPORARY ON DATABASE ministry_of_public_security TO security_reader;
GRANT CONNECT, TEMPORARY ON DATABASE ministry_of_public_security TO security_writer;
GRANT CONNECT ON DATABASE ministry_of_public_security TO sync_user;

-- Cho Bộ Tư pháp
GRANT ALL PRIVILEGES ON DATABASE ministry_of_justice TO justice_admin;
GRANT CONNECT, TEMPORARY ON DATABASE ministry_of_justice TO justice_reader;
GRANT CONNECT, TEMPORARY ON DATABASE ministry_of_justice TO justice_writer;
GRANT CONNECT ON DATABASE ministry_of_justice TO sync_user;

-- Cho máy chủ trung tâm
GRANT ALL PRIVILEGES ON DATABASE national_citizen_central_server TO central_server_admin;
GRANT CONNECT, TEMPORARY ON DATABASE national_citizen_central_server TO central_server_reader;
GRANT CONNECT ON DATABASE national_citizen_central_server TO sync_user;

-----------------------------------------------------------------------------------
-- 4. THIẾT LẬP CẤU HÌNH KẾT NỐI GIỮA CÁC HỆ THỐNG
-----------------------------------------------------------------------------------

\echo 'Quá trình tạo database đã hoàn tất'
\echo 'Đã tạo các database: ministry_of_public_security, ministry_of_justice, national_citizen_central_server'
\echo 'Đã tạo các người dùng cho quản trị, đọc, ghi và đồng bộ'
\echo 'Tiếp theo là tạo schema, các bảng tham chiếu và cấu hình Foreign Data Wrapper...'

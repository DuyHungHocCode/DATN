-- File: national_citizen_central_server/fdw_and_sync/01_fdw_setup.sql
-- Description: Cấu hình Foreign Data Wrapper (FDW) trên Máy chủ Trung tâm (TT)
--              để cho phép đọc dữ liệu từ database Bộ Công an (BCA) và Bộ Tư pháp (BTP)
--              phục vụ cho quá trình đồng bộ hóa dữ liệu.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Extension 'postgres_fdw' đã được cài đặt trên DB Trung tâm.
-- - Các database BCA và BTP đã tồn tại và có thể truy cập từ Máy chủ Trung tâm.
-- - Role 'sync_user' và 'central_server_admin' đã được tạo (trong 02_security/01_roles.sql).
-- - Role 'sync_user' đã được cấp quyền SELECT cần thiết trên các bảng nguồn ở DB BCA và BTP.
-- =============================================================================

\echo '--> Bắt đầu cấu hình FDW trên national_citizen_central_server...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
\connect national_citizen_central_server

BEGIN;

-- ============================================================================
-- 1. ĐẢM BẢO EXTENSION FDW TỒN TẠI
-- ============================================================================
\echo '    -> Bước 1: Kiểm tra/Tạo extension postgres_fdw...'
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- ============================================================================
-- 2. TẠO FOREIGN SERVERS (Kết nối đến DB nguồn)
-- ============================================================================
\echo '    -> Bước 2: Tạo Foreign Servers...'

-- 2.1 Tạo server kết nối đến DB Bộ Công an (BCA)
\echo '       - Tạo server mps_server (kết nối đến DB BCA)...'
-- Xóa server cũ nếu tồn tại để tạo lại
DROP SERVER IF EXISTS mps_server CASCADE;
CREATE SERVER mps_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'mps_db_host',         -- **THAY THẾ** bằng hostname hoặc IP của DB BCA
        port '5432',                -- **THAY THẾ** bằng port của DB BCA (nếu khác 5432)
        dbname 'ministry_of_public_security' -- **THAY THẾ** bằng tên DB BCA nếu khác
        -- sslmode 'require'        -- Cân nhắc bật SSL nếu cần thiết
    );
COMMENT ON SERVER mps_server IS 'Foreign server kết nối đến database Bộ Công an (ministry_of_public_security)';

-- 2.2 Tạo server kết nối đến DB Bộ Tư pháp (BTP)
\echo '       - Tạo server moj_server (kết nối đến DB BTP)...'
-- Xóa server cũ nếu tồn tại để tạo lại
DROP SERVER IF EXISTS moj_server CASCADE;
CREATE SERVER moj_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'moj_db_host',         -- **THAY THẾ** bằng hostname hoặc IP của DB BTP
        port '5432',                -- **THAY THẾ** bằng port của DB BTP (nếu khác 5432)
        dbname 'ministry_of_justice' -- **THAY THẾ** bằng tên DB BTP nếu khác
        -- sslmode 'require'
    );
COMMENT ON SERVER moj_server IS 'Foreign server kết nối đến database Bộ Tư pháp (ministry_of_justice)';

-- ============================================================================
-- 3. TẠO USER MAPPINGS (Ánh xạ user cục bộ sang user trên server ngoại)
-- ============================================================================
\echo '    -> Bước 3: Tạo User Mappings...'

-- 3.1 Mapping cho sync_user (Role dùng để đồng bộ dữ liệu)
\echo '       - Tạo mapping cho sync_user...'
-- Xóa mapping cũ nếu có
DROP USER MAPPING IF EXISTS FOR sync_user SERVER mps_server;
DROP USER MAPPING IF EXISTS FOR sync_user SERVER moj_server;
-- Tạo mapping mới - **QUAN TRỌNG:** Mật khẩu phải khớp với mật khẩu của sync_user
CREATE USER MAPPING FOR sync_user
    SERVER mps_server
    OPTIONS (user 'sync_user', password 'SyncUser_ChangeMe!2025'); -- **THAY MẬT KHẨU**

CREATE USER MAPPING FOR sync_user
    SERVER moj_server
    OPTIONS (user 'sync_user', password 'SyncUser_ChangeMe!2025'); -- **THAY MẬT KHẨU**

-- 3.2 Mapping cho central_server_admin (Role quản trị TT - Tùy chọn, dùng để kiểm tra/gỡ lỗi)
\echo '       - Tạo mapping cho central_server_admin (tùy chọn)...'
-- Xóa mapping cũ nếu có
DROP USER MAPPING IF EXISTS FOR central_server_admin SERVER mps_server;
DROP USER MAPPING IF EXISTS FOR central_server_admin SERVER moj_server;
-- Tạo mapping mới - Người dùng này cũng cần tồn tại và có quyền trên DB nguồn
CREATE USER MAPPING FOR central_server_admin
    SERVER mps_server
    OPTIONS (user 'security_admin', password 'SecureMPS_ChangeMe!2025'); -- **THAY USER/MẬT KHẨU CỦA ADMIN BCA**

CREATE USER MAPPING FOR central_server_admin
    SERVER moj_server
    OPTIONS (user 'justice_admin', password 'SecureMOJ_ChangeMe!2025'); -- **THAY USER/MẬT KHẨU CỦA ADMIN BTP**

-- ============================================================================
-- 4. TẠO SCHEMA MIRROR VÀ IMPORT FOREIGN SCHEMA
-- ============================================================================
\echo '    -> Bước 4: Tạo schema mirror và import foreign schema...'

-- 4.1 Tạo schema mirror cho dữ liệu BCA
\echo '       - Tạo schema public_security_mirror...'
CREATE SCHEMA IF NOT EXISTS public_security_mirror;
COMMENT ON SCHEMA public_security_mirror IS '[QLDCQG-TT] Schema chứa các foreign tables phản chiếu dữ liệu từ Bộ Công an (qua FDW)';

-- Import các bảng cần thiết từ schema public_security của BCA vào public_security_mirror
\echo '       - Import foreign schema public_security vào public_security_mirror...'
IMPORT FOREIGN SCHEMA public_security
    LIMIT TO ( -- Chỉ import các bảng thực sự cần cho việc đồng bộ
        citizen,
        address,
        identification_card,
        permanent_residence,
        temporary_residence,
        temporary_absence,
        citizen_status,
        citizen_movement,
        criminal_record,
        digital_identity
        -- Thêm các bảng khác nếu cần
    )
    FROM SERVER mps_server INTO public_security_mirror;
\echo '          -> Đã import các bảng cần thiết từ public_security.';

-- 4.2 Tạo schema mirror cho dữ liệu BTP
\echo '       - Tạo schema justice_mirror...'
CREATE SCHEMA IF NOT EXISTS justice_mirror;
COMMENT ON SCHEMA justice_mirror IS '[QLDCQG-TT] Schema chứa các foreign tables phản chiếu dữ liệu từ Bộ Tư pháp (qua FDW)';

-- Import các bảng cần thiết từ schema justice của BTP vào justice_mirror
\echo '       - Import foreign schema justice vào justice_mirror...'
IMPORT FOREIGN SCHEMA justice
    LIMIT TO ( -- Chỉ import các bảng thực sự cần cho việc đồng bộ
        birth_certificate,
        death_certificate,
        marriage,
        divorce,
        household,
        household_member,
        family_relationship
        -- Thêm các bảng khác nếu cần
    )
    FROM SERVER moj_server INTO justice_mirror;
\echo '          -> Đã import các bảng cần thiết từ justice.';

-- ============================================================================
-- 5. CẤP QUYỀN TRÊN SCHEMA MIRROR VÀ FOREIGN TABLES
-- ============================================================================
\echo '    -> Bước 5: Cấp quyền trên schema mirror và foreign tables...'

-- 5.1 Cấp quyền cho sync_user
\echo '       - Cấp quyền USAGE, SELECT cho sync_user...'
GRANT USAGE ON SCHEMA public_security_mirror TO sync_user;
GRANT USAGE ON SCHEMA justice_mirror TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO sync_user;
-- Cấp quyền mặc định cho các foreign table có thể được tạo/import sau này
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO sync_user;

-- 5.2 Cấp quyền cho central_server_admin (để kiểm tra/gỡ lỗi)
\echo '       - Cấp quyền USAGE, SELECT cho central_server_admin...'
GRANT USAGE ON SCHEMA public_security_mirror TO central_server_admin;
GRANT USAGE ON SCHEMA justice_mirror TO central_server_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO central_server_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO central_server_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO central_server_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO central_server_admin;

-- 5.3 Cấp quyền cho central_server_reader (nếu cần đọc trực tiếp mirror để so sánh)
-- \echo '       - Cấp quyền USAGE, SELECT cho central_server_reader (tùy chọn)...'
-- GRANT USAGE ON SCHEMA public_security_mirror TO central_server_reader;
-- GRANT USAGE ON SCHEMA justice_mirror TO central_server_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO central_server_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO central_server_reader;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO central_server_reader;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO central_server_reader;

-- ============================================================================
-- 6. XÓA CÁC VIEW/TRIGGER LIÊN DATABASE (Đã bị loại bỏ khỏi đây)
-- ============================================================================
-- Các lệnh CREATE VIEW hoặc CREATE TRIGGER tham chiếu đến foreign table
-- đã được loại bỏ khỏi script này để phù hợp với kiến trúc microservices.
-- Việc phối hợp dữ liệu sẽ được thực hiện bởi logic đồng bộ hóa.

COMMIT;

\echo '-> Hoàn thành cấu hình FDW trên national_citizen_central_server.'
\echo '-> Đảm bảo rằng thông tin kết nối (host, port, dbname, password) là chính xác.'
\echo '-> Bước tiếp theo: Xây dựng logic đồng bộ (vd: trong sync_logic.sql hoặc Airflow) và cấu hình điều phối (trong 02_sync_orchestration.sql).'
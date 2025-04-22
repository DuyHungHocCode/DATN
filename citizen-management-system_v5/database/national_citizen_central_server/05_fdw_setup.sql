-- File: national_citizen_central_server/05_fdw_setup.sql
-- Description: Cấu hình Foreign Data Wrapper (FDW) trên Máy chủ Trung tâm (TT)
--              để cho phép đọc dữ liệu từ database Bộ Công an (BCA) và Bộ Tư pháp (BTP)
--              phục vụ cho quá trình đồng bộ hóa dữ liệu.
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
--
-- Dependencies:
-- - Extension 'postgres_fdw' đã được cài đặt trên DB Trung tâm (từ 01_common/01_extensions.sql).
-- - Các database BCA và BTP đã tồn tại và có thể truy cập từ Máy chủ Trung tâm.
-- - Roles 'sync_user' và 'central_server_admin' đã được tạo (từ 02_security/01_roles.sql).
-- - Role 'sync_user' đã được cấp quyền SELECT cần thiết trên các bảng nguồn ở DB BCA và BTP
--   (thông qua script 02_security/02_permissions.sql chạy trên BCA và BTP).
-- - Schemas 'public_security_mirror' và 'justice_mirror' đã được tạo (từ 00_init/02_create_schemas.sql).
-- =============================================================================

\echo '*** BẮT ĐẦU CẤU HÌNH FDW TRÊN national_citizen_central_server ***'
\connect national_citizen_central_server

BEGIN;

-- ============================================================================
-- 1. ĐẢM BẢO EXTENSION FDW TỒN TẠI
-- ============================================================================
\echo '--> 1. Kiểm tra/Tạo extension postgres_fdw...'
-- Lệnh này chỉ tạo nếu chưa có, an toàn để chạy lại.
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- ============================================================================
-- 2. TẠO FOREIGN SERVERS (Định nghĩa kết nối đến DB nguồn)
-- ============================================================================
\echo '--> 2. Tạo Foreign Servers...'

-- 2.1 Tạo server kết nối đến DB Bộ Công an (BCA)
\echo '    -> Tạo server mps_server (kết nối đến DB BCA)...'
-- Xóa server cũ nếu tồn tại để đảm bảo cấu hình mới nhất được áp dụng
DROP SERVER IF EXISTS mps_server CASCADE;
CREATE SERVER mps_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'mps_db_host',         -- *** THAY THẾ BẰNG HOSTNAME/IP CỦA DB BCA ***
        port '5432',                -- *** THAY THẾ BẰNG PORT CỦA DB BCA (NẾU KHÁC 5432) ***
        dbname 'ministry_of_public_security' -- *** THAY THẾ BẰNG TÊN DB BCA NẾU KHÁC ***
        -- , sslmode 'require'      -- Cân nhắc bật SSL nếu môi trường yêu cầu
    );
COMMENT ON SERVER mps_server IS '[QLDCQG-TT] Foreign server kết nối đến database Bộ Công an (ministry_of_public_security)';

-- 2.2 Tạo server kết nối đến DB Bộ Tư pháp (BTP)
\echo '    -> Tạo server moj_server (kết nối đến DB BTP)...'
-- Xóa server cũ nếu tồn tại
DROP SERVER IF EXISTS moj_server CASCADE;
CREATE SERVER moj_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'moj_db_host',         -- *** THAY THẾ BẰNG HOSTNAME/IP CỦA DB BTP ***
        port '5432',                -- *** THAY THẾ BẰNG PORT CỦA DB BTP (NẾU KHÁC 5432) ***
        dbname 'ministry_of_justice' -- *** THAY THẾ BẰNG TÊN DB BTP NẾU KHÁC ***
        -- , sslmode 'require'
    );
COMMENT ON SERVER moj_server IS '[QLDCQG-TT] Foreign server kết nối đến database Bộ Tư pháp (ministry_of_justice)';

-- ============================================================================
-- 3. TẠO USER MAPPINGS (Ánh xạ user cục bộ sang user trên server ngoại)
-- ============================================================================
\echo '--> 3. Tạo User Mappings...'

-- 3.1 Mapping cho sync_user (Role dùng để đồng bộ dữ liệu)
-- User này cần tồn tại và có quyền SELECT trên các bảng nguồn ở DB BCA/BTP.
\echo '    -> Tạo mapping cho sync_user...'
-- Xóa mapping cũ nếu có để tránh lỗi và đảm bảo mật khẩu đúng
DROP USER MAPPING IF EXISTS FOR sync_user SERVER mps_server;
DROP USER MAPPING IF EXISTS FOR sync_user SERVER moj_server;
-- Tạo mapping mới
CREATE USER MAPPING FOR sync_user
    SERVER mps_server
    OPTIONS (user 'sync_user', password 'SyncUser_ChangeMe!2025'); -- *** THAY MẬT KHẨU *** (phải khớp với sync_user trên DB BCA)

CREATE USER MAPPING FOR sync_user
    SERVER moj_server
    OPTIONS (user 'sync_user', password 'SyncUser_ChangeMe!2025'); -- *** THAY MẬT KHẨU *** (phải khớp với sync_user trên DB BTP)

-- 3.2 Mapping cho central_server_admin (Role quản trị TT - Tùy chọn, dùng để kiểm tra/gỡ lỗi)
-- User này cũng cần tồn tại và có quyền SELECT trên DB nguồn nếu muốn dùng mapping này.
\echo '    -> Tạo mapping cho central_server_admin (tùy chọn)...'
-- Xóa mapping cũ nếu có
DROP USER MAPPING IF EXISTS FOR central_server_admin SERVER mps_server;
DROP USER MAPPING IF EXISTS FOR central_server_admin SERVER moj_server;
-- Tạo mapping mới
CREATE USER MAPPING FOR central_server_admin
    SERVER mps_server
    OPTIONS (user 'security_admin', password 'SecureMPS_ChangeMe!2025'); -- *** THAY USER/MẬT KHẨU CỦA QUẢN TRỊ VIÊN BÊN DB BCA ***

CREATE USER MAPPING FOR central_server_admin
    SERVER moj_server
    OPTIONS (user 'justice_admin', password 'SecureMOJ_ChangeMe!2025'); -- *** THAY USER/MẬT KHẨU CỦA QUẢN TRỊ VIÊN BÊN DB BTP ***

-- ============================================================================
-- 4. IMPORT FOREIGN SCHEMA (Tạo Foreign Tables trong schema mirror)
-- ============================================================================
\echo '--> 4. Import foreign schema (tạo foreign tables)...'

-- 4.1 Import các bảng cần thiết từ schema public_security của BCA vào public_security_mirror
\echo '    -> Import schema public_security vào public_security_mirror...'
-- Xóa các foreign table cũ trong schema mirror trước khi import lại để cập nhật cấu trúc (nếu cần)
-- Lưu ý: Lệnh này có thể gây lỗi nếu view hoặc đối tượng khác đang phụ thuộc vào foreign table cũ.
-- Cân nhắc DROP CASCADE hoặc quản lý dependency cẩn thận hơn.
-- DO $$ BEGIN EXECUTE 'DROP FOREIGN TABLE ' || string_agg(quote_ident(table_name), ', ') FROM information_schema.tables WHERE table_schema = 'public_security_mirror'; END $$;

-- Thực hiện Import
IMPORT FOREIGN SCHEMA public_security
    LIMIT TO ( -- Chỉ import các bảng thực sự cần cho việc đồng bộ tại Trung tâm
        citizen,
        address,
        identification_card,
        permanent_residence,
        temporary_residence,
        temporary_absence,     -- Có thể cần để xác định vắng mặt
        citizen_status,        -- Quan trọng để lấy trạng thái sống/chết
        citizen_movement,      -- Có thể cần để theo dõi di chuyển
        criminal_record        -- Có thể cần nếu TT cần tổng hợp
        -- digital_identity    -- Có thể cần nếu TT cần liên kết VNeID
        -- user_account        -- Thường không cần đồng bộ
    )
    FROM SERVER mps_server INTO public_security_mirror;
\echo '       -> Đã import các bảng cần thiết từ public_security (BCA).'

-- 4.2 Import các bảng cần thiết từ schema justice của BTP vào justice_mirror
\echo '    -> Import schema justice vào justice_mirror...'
-- Xóa foreign table cũ (tương tự như trên)
-- DO $$ BEGIN EXECUTE 'DROP FOREIGN TABLE ' || string_agg(quote_ident(table_name), ', ') FROM information_schema.tables WHERE table_schema = 'justice_mirror'; END $$;

-- Thực hiện Import
IMPORT FOREIGN SCHEMA justice
    LIMIT TO ( -- Chỉ import các bảng thực sự cần cho việc đồng bộ tại Trung tâm
        birth_certificate,
        death_certificate,
        marriage,
        divorce,
        household,
        household_member,
        family_relationship,    -- Có thể cần để xây dựng cây gia đình
        population_change       -- Có thể cần để theo dõi lịch sử biến động
    )
    FROM SERVER moj_server INTO justice_mirror;
\echo '       -> Đã import các bảng cần thiết từ justice (BTP).'

-- ============================================================================
-- 5. CẤP QUYỀN TRÊN SCHEMA MIRROR VÀ FOREIGN TABLES
-- ============================================================================
\echo '--> 5. Cấp quyền trên schema mirror và foreign tables...'

-- 5.1 Cấp quyền cho sync_user (Bắt buộc)
\echo '    -> Cấp quyền USAGE, SELECT cho sync_user...'
GRANT USAGE ON SCHEMA public_security_mirror TO sync_user;
GRANT USAGE ON SCHEMA justice_mirror TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO sync_user;
-- Cấp quyền mặc định cho các foreign table có thể được import/refresh sau này
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO sync_user;

-- 5.2 Cấp quyền cho central_server_admin (Tùy chọn - để kiểm tra/gỡ lỗi)
\echo '    -> Cấp quyền USAGE, SELECT cho central_server_admin...'
GRANT USAGE ON SCHEMA public_security_mirror TO central_server_admin;
GRANT USAGE ON SCHEMA justice_mirror TO central_server_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO central_server_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO central_server_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO central_server_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO central_server_admin;

-- 5.3 Cấp quyền cho central_server_reader (Ít dùng, chỉ khi cần đọc trực tiếp mirror)
-- \echo '    -> Cấp quyền USAGE, SELECT cho central_server_reader (tùy chọn)...'
-- GRANT USAGE ON SCHEMA public_security_mirror TO central_server_reader;
-- GRANT USAGE ON SCHEMA justice_mirror TO central_server_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO central_server_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO central_server_reader;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO central_server_reader;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO central_server_reader;

COMMIT;

\echo '*** HOÀN THÀNH CẤU HÌNH FDW TRÊN national_citizen_central_server ***'
\echo '-> QUAN TRỌNG: Đảm bảo rằng thông tin kết nối (host, port, dbname) và mật khẩu trong USER MAPPING là chính xác và an toàn.'
\echo '-> Bước tiếp theo: Chạy script 06_sync_orchestration.sql để lập lịch đồng bộ (nếu dùng pg_cron).'
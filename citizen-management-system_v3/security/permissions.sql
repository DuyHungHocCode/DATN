-- =============================================================================
-- File: database/security/permissions.sql
-- Description: Cấp quyền chi tiết cho các vai trò (roles) trên các schema và đối tượng
-- Version: 1.0
--
-- Chức năng chính:
-- 1. Cấp quyền sử dụng (USAGE) trên các schema cho từng vai trò.
-- 2. Cấp quyền SELECT, INSERT, UPDATE, DELETE trên các bảng cho vai trò phù hợp.
-- 3. Cấp quyền USAGE, SELECT trên các sequences (cho khóa chính tự tăng).
-- 4. Cấp quyền EXECUTE trên các functions/procedures.
-- 5. Thiết lập quyền mặc định (ALTER DEFAULT PRIVILEGES) để các đối tượng mới
--    tạo ra tự động có quyền phù hợp.
--
-- Lưu ý: Script này nên được chạy SAU KHI đã tạo databases (create_database.sql),
--       tạo roles (roles.sql), tạo schemas (create_schemas.sql) và tạo các
--       bảng/views/functions/sequences.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CẤP QUYỀN CHI TIẾT ***'

-- ============================================================================
-- 1. PHÂN QUYỀN CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo 'Bước 1: Phân quyền cho database ministry_of_public_security...'
\connect ministry_of_public_security

-- 1.1 Quyền cho role security_admin (Quản trị)
\echo '   -> Cấp quyền cho security_admin...'
GRANT ALL PRIVILEGES ON SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, cdc, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO security_admin;

-- 1.2 Quyền cho role security_reader (Chỉ đọc)
\echo '   -> Cấp quyền cho security_reader...'
-- Quyền sử dụng schema
GRANT USAGE ON SCHEMA public_security, reference, reports, api, audit TO security_reader;
-- Quyền SELECT trên bảng hiện có
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference, reports, api, audit TO security_reader;
-- Quyền SELECT trên bảng mới sẽ được tạo
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference, reports, api, audit GRANT SELECT ON TABLES TO security_reader;
-- Quyền USAGE trên sequence (cần cho một số ORM)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public_security, reference TO security_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT USAGE, SELECT ON SEQUENCES TO security_reader;
-- Quyền thực thi function (nếu có function chỉ đọc)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA reports, api TO security_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA reports, api GRANT EXECUTE ON FUNCTIONS TO security_reader;

-- 1.3 Quyền cho role security_writer (Ghi dữ liệu)
\echo '   -> Cấp quyền cho security_writer...'
-- Quyền sử dụng schema
GRANT USAGE ON SCHEMA public_security, reference, api TO security_writer;
-- Quyền CRUD trên các bảng nghiệp vụ và tham chiếu
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public_security, reference TO security_writer;
-- Quyền mặc định cho bảng mới
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO security_writer;
-- Quyền sử dụng sequence
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public_security, reference TO security_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT USAGE, SELECT ON SEQUENCES TO security_writer;
-- Quyền thực thi function (nếu có function ghi dữ liệu)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api TO security_writer; -- Giả sử các hàm ghi nằm trong api
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT EXECUTE ON FUNCTIONS TO security_writer;

-- 1.4 Quyền cho role sync_user (Đồng bộ)
\echo '   -> Cấp quyền cho sync_user...'
-- Quyền sử dụng schema cần thiết
GRANT USAGE ON SCHEMA public_security, reference, cdc, staging TO sync_user;
-- Quyền đọc dữ liệu nguồn và tham chiếu
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT ON TABLES TO sync_user;
-- Quyền ghi vào schema cdc và staging (nếu cần)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cdc, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cdc, staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;
-- Quyền sử dụng sequence (nếu cần ghi vào bảng có sequence)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public_security, reference, cdc, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference, cdc, staging GRANT USAGE, SELECT ON SEQUENCES TO sync_user;
-- Quyền đặc biệt cho replication (đã cấp khi tạo role với thuộc tính REPLICATION)

-- ============================================================================
-- 2. PHÂN QUYỀN CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo 'Bước 2: Phân quyền cho database ministry_of_justice...'
\connect ministry_of_justice

-- 2.1 Quyền cho role justice_admin
\echo '   -> Cấp quyền cho justice_admin...'
GRANT ALL PRIVILEGES ON SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, cdc, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO justice_admin;

-- 2.2 Quyền cho role justice_reader
\echo '   -> Cấp quyền cho justice_reader...'
GRANT USAGE ON SCHEMA justice, reference, reports, api, audit TO justice_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference, reports, api, audit TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference, reports, api, audit GRANT SELECT ON TABLES TO justice_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA reports, api TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA reports, api GRANT EXECUTE ON FUNCTIONS TO justice_reader;

-- 2.3 Quyền cho role justice_writer
\echo '   -> Cấp quyền cho justice_writer...'
GRANT USAGE ON SCHEMA justice, reference, api TO justice_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA justice, reference TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO justice_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_writer;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT EXECUTE ON FUNCTIONS TO justice_writer;

-- 2.4 Quyền cho role sync_user
\echo '   -> Cấp quyền cho sync_user...'
GRANT USAGE ON SCHEMA justice, reference, cdc, staging TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT ON TABLES TO sync_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cdc, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cdc, staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference, cdc, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference, cdc, staging GRANT USAGE, SELECT ON SEQUENCES TO sync_user;

-- ============================================================================
-- 3. PHÂN QUYỀN CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo 'Bước 3: Phân quyền cho database national_citizen_central_server...'
\connect national_citizen_central_server

-- 3.1 Quyền cho role central_server_admin
\echo '   -> Cấp quyền cho central_server_admin...'
GRANT ALL PRIVILEGES ON SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility, kafka TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility, kafka TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility, kafka TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility, kafka TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility, kafka GRANT ALL PRIVILEGES ON TABLES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility, kafka GRANT ALL PRIVILEGES ON SEQUENCES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, cdc, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility, kafka GRANT ALL PRIVILEGES ON FUNCTIONS TO central_server_admin;

-- 3.2 Quyền cho role central_server_reader
\echo '   -> Cấp quyền cho central_server_reader...'
GRANT USAGE ON SCHEMA central, reference, reports, api, audit, analytics, public_security_mirror, justice_mirror TO central_server_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA central, reference, reports, api, audit, analytics, public_security_mirror, justice_mirror TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, reports, api, audit, analytics, public_security_mirror, justice_mirror GRANT SELECT ON TABLES TO central_server_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, reference, analytics, public_security_mirror, justice_mirror TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, analytics, public_security_mirror, justice_mirror GRANT USAGE, SELECT ON SEQUENCES TO central_server_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA reports, api, analytics TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA reports, api, analytics GRANT EXECUTE ON FUNCTIONS TO central_server_reader;

-- 3.3 Quyền cho role sync_user
\echo '   -> Cấp quyền cho sync_user...'
GRANT USAGE ON SCHEMA central, reference, cdc, sync, staging, kafka, public_security_mirror, justice_mirror TO sync_user;
-- Quyền đọc dữ liệu tham chiếu, mirror và dữ liệu tích hợp (để xử lý conflict)
GRANT SELECT ON ALL TABLES IN SCHEMA central, reference, public_security_mirror, justice_mirror TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, public_security_mirror, justice_mirror GRANT SELECT ON TABLES TO sync_user;
-- Quyền ghi vào các bảng quản lý sync, cdc, staging, kafka và dữ liệu tích hợp central
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA central, cdc, sync, staging, kafka TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, cdc, sync, staging, kafka GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;
-- Quyền trên sequence
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, reference, cdc, sync, staging, kafka, public_security_mirror, justice_mirror TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, cdc, sync, staging, kafka, public_security_mirror, justice_mirror GRANT USAGE, SELECT ON SEQUENCES TO sync_user;
-- Quyền thực thi các hàm/procedure đồng bộ
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA sync, utility TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA sync, utility GRANT EXECUTE ON FUNCTIONS TO sync_user;

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH CẤP QUYỀN CHI TIẾT ***'
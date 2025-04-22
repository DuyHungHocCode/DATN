-- =============================================================================
-- File: 02_security/02_permissions.sql
-- Description: Cấp quyền chi tiết cho các vai trò (roles) trên các schema và
--              đối tượng trong từng database.
-- Version: 3.1 (Refined comments, adjusted default privileges for admins)
--
-- Yêu cầu:
-- - Chạy script này SAU KHI đã tạo databases, roles, schemas, tables, functions...
-- - Cần quyền superuser hoặc quyền đủ để cấp các quyền này.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CẤP QUYỀN CHI TIẾT ***'

-- === 1. PHÂN QUYỀN CHO DATABASE BỘ CÔNG AN (ministry_of_public_security) ===

\echo '[Bước 1] Phân quyền cho database: ministry_of_public_security...'
\connect ministry_of_public_security

-- 1.1. Quyền cho role: security_admin (Quản trị BCA)
\echo '   -> Cấp quyền cho security_admin...'
-- Toàn quyền trên các schema quản lý bởi BCA
GRANT ALL PRIVILEGES ON SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
-- Toàn quyền trên các đối tượng hiện có trong các schema đó
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
-- Quyền mặc định cho các đối tượng MỚI được TẠO BỞI security_admin trong các schema này
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO security_admin;

-- 1.2. Quyền cho role: security_reader (Ứng dụng BCA - Chỉ đọc)
\echo '   -> Cấp quyền cho security_reader...'
GRANT USAGE ON SCHEMA public_security, reference, reports, api, audit TO security_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference, reports, api, audit TO security_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public_security, reference TO security_reader; -- SELECT cần thiết cho một số ORM
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, reports TO security_reader;
-- Quyền mặc định cho security_reader trên các đối tượng MỚI được tạo trong các schema này (thường bởi admin)
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference, reports, api, audit GRANT SELECT ON TABLES TO security_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT USAGE, SELECT ON SEQUENCES TO security_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, reports GRANT EXECUTE ON FUNCTIONS TO security_reader;

-- 1.3. Quyền cho role: security_writer (Ứng dụng BCA - Ghi dữ liệu)
\echo '   -> Cấp quyền cho security_writer...'
GRANT USAGE ON SCHEMA public_security, reference, api, utility TO security_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public_security, reference TO security_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public_security, reference TO security_writer;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, utility TO security_writer;
-- Quyền mặc định cho security_writer trên các đối tượng MỚI được tạo trong các schema này
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO security_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT USAGE, SELECT ON SEQUENCES TO security_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, utility GRANT EXECUTE ON FUNCTIONS TO security_writer;

-- 1.4. Quyền cho role: sync_user (Đồng bộ - Chỉ cần quyền đọc tại BCA)
\echo '   -> Cấp quyền cho sync_user (chỉ SELECT tại nguồn BCA)...'
GRANT USAGE ON SCHEMA public_security, reference TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference TO sync_user;
-- Quyền mặc định cho sync_user trên các đối tượng MỚI được tạo trong các schema này
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT ON TABLES TO sync_user;

\echo '   -> Hoàn thành phân quyền cho ministry_of_public_security.'


-- === 2. PHÂN QUYỀN CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice) ===

\echo '[Bước 2] Phân quyền cho database: ministry_of_justice...'
\connect ministry_of_justice

-- 2.1. Quyền cho role: justice_admin (Quản trị BTP)
\echo '   -> Cấp quyền cho justice_admin...'
GRANT ALL PRIVILEGES ON SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO justice_admin;

-- 2.2. Quyền cho role: justice_reader (Ứng dụng BTP - Chỉ đọc)
\echo '   -> Cấp quyền cho justice_reader...'
GRANT USAGE ON SCHEMA justice, reference, reports, api, audit TO justice_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference, reports, api, audit TO justice_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, reports TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference, reports, api, audit GRANT SELECT ON TABLES TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, reports GRANT EXECUTE ON FUNCTIONS TO justice_reader;

-- 2.3. Quyền cho role: justice_writer (Ứng dụng BTP - Ghi dữ liệu)
\echo '   -> Cấp quyền cho justice_writer...'
GRANT USAGE ON SCHEMA justice, reference, api, utility TO justice_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA justice, reference TO justice_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_writer;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, utility TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, utility GRANT EXECUTE ON FUNCTIONS TO justice_writer;

-- 2.4. Quyền cho role: sync_user (Đồng bộ - Chỉ cần quyền đọc tại BTP)
\echo '   -> Cấp quyền cho sync_user (chỉ SELECT tại nguồn BTP)...'
GRANT USAGE ON SCHEMA justice, reference TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT ON TABLES TO sync_user;

\echo '   -> Hoàn thành phân quyền cho ministry_of_justice.'


-- === 3. PHÂN QUYỀN CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server) ===

\echo '[Bước 3] Phân quyền cho database: national_citizen_central_server...'
\connect national_citizen_central_server

-- 3.1. Quyền cho role: central_server_admin (Quản trị TT)
\echo '   -> Cấp quyền cho central_server_admin...'
-- Bao gồm cả các schema mirror và sync
GRANT ALL PRIVILEGES ON SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO central_server_admin;

-- 3.2. Quyền cho role: central_server_reader (Ứng dụng TT - Chỉ đọc dữ liệu tích hợp)
\echo '   -> Cấp quyền cho central_server_reader...'
GRANT USAGE ON SCHEMA central, reference, reports, api, audit TO central_server_reader;
-- Cân nhắc cấp quyền đọc trên mirror schemas nếu cần thiết cho ứng dụng TT
-- GRANT USAGE ON SCHEMA public_security_mirror, justice_mirror TO central_server_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA central, reference, reports, api, audit TO central_server_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror, justice_mirror TO central_server_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, reference TO central_server_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, reports TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, reports, api, audit GRANT SELECT ON TABLES TO central_server_reader;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror, justice_mirror GRANT SELECT ON TABLES TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference GRANT USAGE, SELECT ON SEQUENCES TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, reports GRANT EXECUTE ON FUNCTIONS TO central_server_reader;

-- 3.3. Quyền cho role: sync_user (Đồng bộ - Thực thi tại TT)
\echo '   -> Cấp quyền chi tiết cho sync_user (thực thi đồng bộ tại Central Server)...'
-- Quyền USAGE trên các schema cần thiết
GRANT USAGE ON SCHEMA central, sync, staging, public_security_mirror, justice_mirror, reference, utility, partitioning TO sync_user;
-- Quyền SELECT trên dữ liệu nguồn (mirror) và tham chiếu
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror, justice_mirror, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror, justice_mirror, reference GRANT SELECT ON TABLES TO sync_user;
-- Quyền CRUD trên dữ liệu tích hợp (central), bảng quản lý sync, và bảng tạm staging
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA central, sync, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, sync, staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;
-- Quyền trên sequence của các bảng cần ghi
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, sync, staging, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, sync, staging, reference GRANT USAGE, SELECT ON SEQUENCES TO sync_user;
-- Quyền thực thi các hàm/procedure đồng bộ và phân vùng (QUAN TRỌNG)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA sync, utility, central, partitioning TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA sync, utility, central, partitioning GRANT EXECUTE ON FUNCTIONS TO sync_user;
-- Quyền đọc audit log nếu cần
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT ON TABLES TO sync_user;

\echo '   -> Hoàn thành phân quyền cho national_citizen_central_server.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH QUÁ TRÌNH CẤP QUYỀN CHI TIẾT ***'
\echo '-> Đã cấp quyền phù hợp cho các roles trên từng database.'
\echo '-> Bước tiếp theo: Thiết lập phân vùng và index cho các bảng nghiệp vụ.'



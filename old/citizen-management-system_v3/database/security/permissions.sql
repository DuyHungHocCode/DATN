-- =============================================================================
-- File: database/security/permissions.sql
-- Description: Cấp quyền chi tiết cho các vai trò (roles) trên các schema và đối tượng.
--              **PHIÊN BẢN ĐƠN GIẢN HÓA:** Loại bỏ quyền cho schema cdc, kafka
--              và điều chỉnh quyền cho sync_user phù hợp với đồng bộ FDW/PLpgSQL.
-- Version: 2.0
--
-- Chức năng chính:
-- 1. Cấp quyền sử dụng (USAGE) trên các schema cho từng vai trò.
-- 2. Cấp quyền SELECT, INSERT, UPDATE, DELETE trên các bảng cho vai trò phù hợp.
-- 3. Cấp quyền USAGE, SELECT trên các sequences (cho khóa chính tự tăng).
-- 4. Cấp quyền EXECUTE trên các functions/procedures.
-- 5. Thiết lập quyền mặc định (ALTER DEFAULT PRIVILEGES) để các đối tượng mới
--    tạo ra tự động có quyền phù hợp.
--
-- Lưu ý: Script này nên được chạy SAU KHI đã tạo databases, roles, schemas
--       và các bảng/views/functions/sequences.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CẤP QUYỀN CHI TIẾT (PHIÊN BẢN ĐƠN GIẢN HÓA) ***'

-- ============================================================================
-- 1. PHÂN QUYỀN CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo 'Bước 1: Phân quyền cho database ministry_of_public_security...'
\connect ministry_of_public_security

-- 1.1 Quyền cho role security_admin (Quản trị)
\echo '   -> Cấp quyền cho security_admin...'
-- Loại bỏ cdc, kafka khỏi danh sách schema
GRANT ALL PRIVILEGES ON SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO security_admin;

-- 1.2 Quyền cho role security_reader (Chỉ đọc - dùng cho FastAPI)
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

-- 1.3 Quyền cho role security_writer (Ghi dữ liệu - dùng cho FastAPI)
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
-- Chỉ cần quyền SELECT trên các bảng nguồn để FDW từ Central Server có thể đọc
\echo '   -> Cấp quyền cho sync_user (chỉ SELECT trên nguồn)...'
-- Quyền sử dụng schema cần thiết
GRANT USAGE ON SCHEMA public_security, reference TO sync_user;
-- Quyền đọc dữ liệu nguồn và tham chiếu
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT ON TABLES TO sync_user;
-- Không cần quyền ghi vào cdc, staging ở đây nữa
-- Không cần quyền đặc biệt cho replication

-- ============================================================================
-- 2. PHÂN QUYỀN CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo 'Bước 2: Phân quyền cho database ministry_of_justice...'
\connect ministry_of_justice

-- 2.1 Quyền cho role justice_admin
\echo '   -> Cấp quyền cho justice_admin...'
-- Loại bỏ cdc, kafka khỏi danh sách schema
GRANT ALL PRIVILEGES ON SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO justice_admin;

-- 2.2 Quyền cho role justice_reader (Chỉ đọc - dùng cho FastAPI)
\echo '   -> Cấp quyền cho justice_reader...'
GRANT USAGE ON SCHEMA justice, reference, reports, api, audit TO justice_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference, reports, api, audit TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference, reports, api, audit GRANT SELECT ON TABLES TO justice_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA reports, api TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA reports, api GRANT EXECUTE ON FUNCTIONS TO justice_reader;

-- 2.3 Quyền cho role justice_writer (Ghi dữ liệu - dùng cho FastAPI)
\echo '   -> Cấp quyền cho justice_writer...'
GRANT USAGE ON SCHEMA justice, reference, api TO justice_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA justice, reference TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO justice_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_writer;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT EXECUTE ON FUNCTIONS TO justice_writer;

-- 2.4 Quyền cho role sync_user (Đồng bộ)
-- Chỉ cần quyền SELECT trên các bảng nguồn để FDW từ Central Server có thể đọc
\echo '   -> Cấp quyền cho sync_user (chỉ SELECT trên nguồn)...'
GRANT USAGE ON SCHEMA justice, reference TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT ON TABLES TO sync_user;
-- Không cần quyền ghi vào cdc, staging ở đây nữa

-- ============================================================================
-- 3. PHÂN QUYỀN CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo 'Bước 3: Phân quyền cho database national_citizen_central_server...'
\connect national_citizen_central_server

-- 3.1 Quyền cho role central_server_admin
\echo '   -> Cấp quyền cho central_server_admin...'
-- Loại bỏ cdc, kafka khỏi danh sách schema
GRANT ALL PRIVILEGES ON SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility GRANT ALL PRIVILEGES ON TABLES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility GRANT ALL PRIVILEGES ON SEQUENCES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, analytics, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO central_server_admin;

-- 3.2 Quyền cho role central_server_reader (Chỉ đọc - dùng cho FastAPI)
\echo '   -> Cấp quyền cho central_server_reader...'
-- Loại bỏ cdc, kafka. Giữ lại analytics nếu cần.
GRANT USAGE ON SCHEMA central, reference, reports, api, audit, analytics, public_security_mirror, justice_mirror, sync TO central_server_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA central, reference, reports, api, audit, analytics, public_security_mirror, justice_mirror, sync TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, reports, api, audit, analytics, public_security_mirror, justice_mirror, sync GRANT SELECT ON TABLES TO central_server_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, reference, analytics, public_security_mirror, justice_mirror TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, analytics, public_security_mirror, justice_mirror GRANT USAGE, SELECT ON SEQUENCES TO central_server_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA reports, api, analytics TO central_server_reader; -- Cấp quyền EXECUTE trên hàm API, báo cáo, phân tích
ALTER DEFAULT PRIVILEGES IN SCHEMA reports, api, analytics GRANT EXECUTE ON FUNCTIONS TO central_server_reader;

-- 3.3 Quyền cho role sync_user (Đồng bộ - Thực thi job PL/pgSQL)
\echo '   -> Cấp quyền cho sync_user (thực thi đồng bộ tại Central Server)...'
-- Quyền USAGE trên các schema cần thiết
GRANT USAGE ON SCHEMA central, reference, sync, staging, public_security_mirror, justice_mirror, utility TO sync_user;
-- Quyền SELECT trên dữ liệu mirror và reference
GRANT SELECT ON ALL TABLES IN SCHEMA reference, public_security_mirror, justice_mirror TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA reference, public_security_mirror, justice_mirror GRANT SELECT ON TABLES TO sync_user;
-- Quyền SELECT, INSERT, UPDATE, DELETE trên dữ liệu tích hợp central và các bảng quản lý sync, staging
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA central, sync, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, sync, staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;
-- Quyền trên sequence
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, reference, sync, staging, public_security_mirror, justice_mirror TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, sync, staging, public_security_mirror, justice_mirror GRANT USAGE, SELECT ON SEQUENCES TO sync_user;
-- Quyền thực thi các hàm/procedure đồng bộ (QUAN TRỌNG)
-- Giả sử các hàm đồng bộ đặt trong schema 'sync' hoặc 'central' hoặc 'utility'
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA sync, utility, central TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA sync, utility, central GRANT EXECUTE ON FUNCTIONS TO sync_user;

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH CẤP QUYỀN CHI TIẾT (PHIÊN BẢN ĐƠN GIẢN HÓA) ***'
\echo '-> Đã loại bỏ các quyền liên quan đến schema cdc và kafka.'
\echo '-> Đã điều chỉnh quyền cho sync_user để thực thi job đồng bộ PL/pgSQL.'
\echo '-> Đảm bảo các role ứng dụng có quyền truy cập cần thiết.'

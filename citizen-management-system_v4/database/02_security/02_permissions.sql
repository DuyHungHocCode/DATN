-- File: 02_security/02_permissions.sql
-- Description: Cấp quyền chi tiết cho các vai trò (roles) trên các schema và đối tượng
--              trong từng database, phù hợp với kiến trúc microservices.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Chức năng chính:
-- 1. Cấp quyền sử dụng (USAGE) trên các schema cho từng vai trò.
-- 2. Cấp quyền SELECT, INSERT, UPDATE, DELETE trên các bảng cho vai trò phù hợp.
-- 3. Cấp quyền USAGE, SELECT trên các sequences.
-- 4. Cấp quyền EXECUTE trên các functions/procedures.
-- 5. Thiết lập quyền mặc định (ALTER DEFAULT PRIVILEGES) cho các đối tượng mới.
--
-- Yêu cầu: Chạy script này SAU KHI đã tạo databases, roles, schemas, tables, functions...
--          Cần quyền superuser hoặc quyền đủ để cấp các quyền này.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CẤP QUYỀN CHI TIẾT ***'

-- ============================================================================
-- 1. PHÂN QUYỀN CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo 'Bước 1: Phân quyền cho database ministry_of_public_security...'
\connect ministry_of_public_security

-- 1.1 Quyền cho role security_admin (Quản trị BCA)
\echo '   -> Cấp quyền cho security_admin...'
-- Cấp tất cả quyền trên các schema quản lý bởi BCA
GRANT ALL PRIVILEGES ON SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
-- Cấp tất cả quyền trên các đối tượng hiện có trong các schema đó
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility TO security_admin;
-- Cấp quyền mặc định cho các đối tượng mới sẽ được tạo bởi admin
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO security_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE security_admin IN SCHEMA public_security, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO security_admin;

-- 1.2 Quyền cho role security_reader (Ứng dụng BCA - Chỉ đọc)
\echo '   -> Cấp quyền cho security_reader...'
-- Quyền sử dụng các schema cần thiết để đọc
GRANT USAGE ON SCHEMA public_security, reference, reports, api, audit TO security_reader;
-- Quyền SELECT trên bảng hiện có
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference, reports, api, audit TO security_reader;
-- Quyền SELECT trên bảng mới sẽ được tạo trong tương lai
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference, reports, api, audit GRANT SELECT ON TABLES TO security_reader;
-- Quyền USAGE, SELECT trên sequence (cần cho một số ORM hoặc khi đọc giá trị currval/nextval)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public_security, reference TO security_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT USAGE, SELECT ON SEQUENCES TO security_reader;
-- Quyền thực thi function (nếu có function chỉ đọc trong schema api, reports)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, reports TO security_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, reports GRANT EXECUTE ON FUNCTIONS TO security_reader;
-- **Quan trọng:** Không cấp quyền trên schema FDW (justice_fdw, central_fdw nếu có) cho role ứng dụng.

-- 1.3 Quyền cho role security_writer (Ứng dụng BCA - Ghi dữ liệu)
\echo '   -> Cấp quyền cho security_writer...'
-- Quyền sử dụng các schema cần thiết để đọc/ghi
GRANT USAGE ON SCHEMA public_security, reference, api, utility TO security_writer;
-- Quyền CRUD trên các bảng nghiệp vụ và tham chiếu
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public_security, reference TO security_writer;
-- Quyền mặc định cho bảng mới
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO security_writer;
-- Quyền sử dụng sequence để tạo khóa chính tự tăng
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public_security, reference TO security_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT USAGE, SELECT ON SEQUENCES TO security_writer;
-- Quyền thực thi function (nếu có function nghiệp vụ trong schema api, utility)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, utility TO security_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, utility GRANT EXECUTE ON FUNCTIONS TO security_writer;
-- **Quan trọng:** Không cấp quyền trên schema FDW.

-- 1.4 Quyền cho role sync_user (Đồng bộ - Chỉ cần quyền đọc ở đây)
\echo '   -> Cấp quyền cho sync_user (chỉ SELECT trên nguồn)...'
-- Quyền sử dụng schema cần đọc để đồng bộ
GRANT USAGE ON SCHEMA public_security, reference TO sync_user;
-- Quyền đọc dữ liệu nguồn và tham chiếu
GRANT SELECT ON ALL TABLES IN SCHEMA public_security, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security, reference GRANT SELECT ON TABLES TO sync_user;
-- Không cần quyền ghi hay thực thi gì ở đây cho sync_user.

\echo '-> Hoàn thành phân quyền cho ministry_of_public_security.'

-- ============================================================================
-- 2. PHÂN QUYỀN CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo 'Bước 2: Phân quyền cho database ministry_of_justice...'
\connect ministry_of_justice

-- 2.1 Quyền cho role justice_admin (Quản trị BTP)
\echo '   -> Cấp quyền cho justice_admin...'
GRANT ALL PRIVILEGES ON SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO justice_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE justice_admin IN SCHEMA justice, reference, audit, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO justice_admin;

-- 2.2 Quyền cho role justice_reader (Ứng dụng BTP - Chỉ đọc)
\echo '   -> Cấp quyền cho justice_reader...'
GRANT USAGE ON SCHEMA justice, reference, reports, api, audit TO justice_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference, reports, api, audit TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference, reports, api, audit GRANT SELECT ON TABLES TO justice_reader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, reports TO justice_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, reports GRANT EXECUTE ON FUNCTIONS TO justice_reader;
-- **Quan trọng:** Không cấp quyền trên schema FDW (public_security_fdw nếu có).

-- 2.3 Quyền cho role justice_writer (Ứng dụng BTP - Ghi dữ liệu)
\echo '   -> Cấp quyền cho justice_writer...'
GRANT USAGE ON SCHEMA justice, reference, api, utility TO justice_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA justice, reference TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO justice_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA justice, reference TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT USAGE, SELECT ON SEQUENCES TO justice_writer;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, utility TO justice_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, utility GRANT EXECUTE ON FUNCTIONS TO justice_writer;
-- **Quan trọng:** Không cấp quyền trên schema FDW.

-- 2.4 Quyền cho role sync_user (Đồng bộ - Chỉ cần quyền đọc ở đây)
\echo '   -> Cấp quyền cho sync_user (chỉ SELECT trên nguồn)...'
GRANT USAGE ON SCHEMA justice, reference TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice, reference GRANT SELECT ON TABLES TO sync_user;
-- Không cần quyền ghi hay thực thi gì ở đây cho sync_user.

\echo '-> Hoàn thành phân quyền cho ministry_of_justice.'

-- ============================================================================
-- 3. PHÂN QUYỀN CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo 'Bước 3: Phân quyền cho database national_citizen_central_server...'
\connect national_citizen_central_server

-- 3.1 Quyền cho role central_server_admin (Quản trị TT)
\echo '   -> Cấp quyền cho central_server_admin...'
-- Bao gồm cả các schema mirror và sync
GRANT ALL PRIVILEGES ON SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON TABLES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON SEQUENCES TO central_server_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE central_server_admin IN SCHEMA central, reference, audit, sync, public_security_mirror, justice_mirror, api, partitioning, reports, staging, utility GRANT ALL PRIVILEGES ON FUNCTIONS TO central_server_admin;

-- 3.2 Quyền cho role central_server_reader (Ứng dụng TT - Chỉ đọc dữ liệu tích hợp)
\echo '   -> Cấp quyền cho central_server_reader...'
-- Chủ yếu đọc từ schema central, reference, reports, api, audit
GRANT USAGE ON SCHEMA central, reference, reports, api, audit TO central_server_reader;
-- Có thể cần đọc cả mirror schemas để so sánh hoặc gỡ lỗi, nhưng hạn chế nếu không cần thiết
-- GRANT USAGE ON SCHEMA public_security_mirror, justice_mirror TO central_server_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA central, reference, reports, api, audit TO central_server_reader;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror, justice_mirror TO central_server_reader; -- Cấp nếu cần
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference, reports, api, audit GRANT SELECT ON TABLES TO central_server_reader;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror, justice_mirror GRANT SELECT ON TABLES TO central_server_reader; -- Cấp nếu cần
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, reference TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, reference GRANT USAGE, SELECT ON SEQUENCES TO central_server_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA api, reports TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA api, reports GRANT EXECUTE ON FUNCTIONS TO central_server_reader;

-- 3.3 Quyền cho role sync_user (Đồng bộ - Thực thi tại TT)
\echo '   -> Cấp quyền chi tiết cho sync_user (thực thi đồng bộ tại Central Server)...'
-- Quyền USAGE trên các schema cần thiết cho quá trình đồng bộ
GRANT USAGE ON SCHEMA central, sync, staging, public_security_mirror, justice_mirror, reference, utility TO sync_user;
-- Quyền SELECT trên dữ liệu nguồn (mirror) và tham chiếu
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror, justice_mirror, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror, justice_mirror, reference GRANT SELECT ON TABLES TO sync_user;
-- Quyền ghi (CRUD) trên dữ liệu tích hợp (central), bảng quản lý sync, và bảng tạm staging
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA central, sync, staging TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, sync, staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sync_user;
-- Quyền trên sequence của các bảng cần ghi
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA central, sync, staging, reference TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA central, sync, staging, reference GRANT USAGE, SELECT ON SEQUENCES TO sync_user;
-- Quyền thực thi các hàm/procedure đồng bộ (QUAN TRỌNG)
-- Giả sử các hàm đồng bộ đặt trong schema 'sync', 'utility', hoặc 'central'
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA sync, utility, central TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA sync, utility, central GRANT EXECUTE ON FUNCTIONS TO sync_user;
-- Quyền đọc audit log nếu cần thiết cho logic đồng bộ
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT ON TABLES TO sync_user;

\echo '-> Hoàn thành phân quyền cho national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH CẤP QUYỀN CHI TIẾT ***'
\echo '-> Đã cấp quyền phù hợp cho các roles trên từng database theo kiến trúc microservices.'
\echo '-> Lưu ý quan trọng: Role ứng dụng (reader/writer) không được cấp quyền truy cập trực tiếp FDW schemas.'
\echo '-> Bước tiếp theo: Cài đặt các thành phần chung như extensions, enums, reference_tables (trong thư mục 01_common/).'
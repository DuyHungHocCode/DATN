-- =============================================================================
-- File: database/security/roles.sql
-- Description: Định nghĩa các vai trò (users) cho hệ thống QLDCQG
--              **PHIÊN BẢN ĐƠN GIẢN HÓA:** Điều chỉnh role sync_user.
-- Version: 2.1
--
-- Chức năng chính:
-- 1. Xóa các roles cũ (nếu tồn tại) để đảm bảo định nghĩa mới nhất được áp dụng.
-- 2. Tạo các roles quản trị (admin) cho từng hệ thống con.
-- 3. Tạo các roles chỉ đọc (reader) cho mục đích báo cáo, truy vấn.
-- 4. Tạo các roles ghi (writer) cho các ứng dụng nhập liệu, cập nhật.
-- 5. Tạo role đặc biệt cho mục đích đồng bộ dữ liệu (sync_user) bằng job định kỳ.
--
-- Lưu ý: Việc cấp quyền chi tiết cho các roles này được thực hiện trong
--       tệp `security/permissions.sql`.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO ROLES (USERS) (PHIÊN BẢN ĐƠN GIẢN HÓA) ***'

-- Kết nối đến PostgreSQL instance mặc định (ví dụ: postgres) với quyền superuser
-- Roles là đối tượng cluster-level, không cần kết nối database cụ thể
\connect postgres

-- ============================================================================
-- 1. XÓA ROLES CŨ (NẾU TỒN TẠI)
-- ============================================================================
\echo 'Bước 1: Xóa các roles cũ (nếu tồn tại)...'

DROP ROLE IF EXISTS security_admin;
DROP ROLE IF EXISTS justice_admin;
DROP ROLE IF EXISTS central_server_admin;
DROP ROLE IF EXISTS security_reader;
DROP ROLE IF EXISTS justice_reader;
DROP ROLE IF EXISTS central_server_reader;
DROP ROLE IF EXISTS security_writer;
DROP ROLE IF EXISTS justice_writer;
DROP ROLE IF EXISTS sync_user;
-- Thêm các role khác nếu có

\echo '-> Đã xóa các roles cũ (nếu có).'

-- ============================================================================
-- 2. TẠO CÁC ROLES MỚI
-- ============================================================================
\echo 'Bước 2: Tạo các roles mới...'

-- 2.1 Roles quản trị (Admin Roles)
-- Có quyền cao nhất trong database tương ứng, thường dùng để quản lý cấu trúc, user.
\echo '   -> Tạo roles quản trị...'
CREATE ROLE security_admin WITH LOGIN ENCRYPTED PASSWORD 'SecureMPS@2025' CREATEDB CREATEROLE;
COMMENT ON ROLE security_admin IS '[QLDCQG] Role quản trị cho database Bộ Công an';

CREATE ROLE justice_admin WITH LOGIN ENCRYPTED PASSWORD 'SecureMOJ@2025' CREATEDB CREATEROLE;
COMMENT ON ROLE justice_admin IS '[QLDCQG] Role quản trị cho database Bộ Tư pháp';

CREATE ROLE central_server_admin WITH LOGIN ENCRYPTED PASSWORD 'SecureCentralServer@2025' CREATEDB CREATEROLE;
COMMENT ON ROLE central_server_admin IS '[QLDCQG] Role quản trị cho database Máy chủ trung tâm';

-- 2.2 Roles chỉ đọc (Read-Only Roles)
-- Dùng cho các ứng dụng báo cáo, truy vấn dữ liệu, không có quyền thay đổi.
\echo '   -> Tạo roles chỉ đọc...'
CREATE ROLE security_reader WITH LOGIN ENCRYPTED PASSWORD 'ReaderMPS@2025';
COMMENT ON ROLE security_reader IS '[QLDCQG] Role chỉ đọc cho database Bộ Công an';

CREATE ROLE justice_reader WITH LOGIN ENCRYPTED PASSWORD 'ReaderMOJ@2025';
COMMENT ON ROLE justice_reader IS '[QLDCQG] Role chỉ đọc cho database Bộ Tư pháp';

CREATE ROLE central_server_reader WITH LOGIN ENCRYPTED PASSWORD 'ReaderCentralServer@2025';
COMMENT ON ROLE central_server_reader IS '[QLDCQG] Role chỉ đọc cho database Máy chủ trung tâm';

-- 2.3 Roles ghi (Write Roles)
-- Dùng cho các ứng dụng nghiệp vụ cần thêm/sửa/xóa dữ liệu.
\echo '   -> Tạo roles ghi...'
CREATE ROLE security_writer WITH LOGIN ENCRYPTED PASSWORD 'WriterMPS@2025';
COMMENT ON ROLE security_writer IS '[QLDCQG] Role ghi dữ liệu cho database Bộ Công an';

CREATE ROLE justice_writer WITH LOGIN ENCRYPTED PASSWORD 'WriterMOJ@2025';
COMMENT ON ROLE justice_writer IS '[QLDCQG] Role ghi dữ liệu cho database Bộ Tư pháp';
-- Lưu ý: Máy chủ trung tâm thường không có role ghi trực tiếp từ ứng dụng,
-- dữ liệu được đồng bộ đến bởi sync_user.

-- 2.4 Role đồng bộ dữ liệu (Synchronization Role)
-- Role đặc biệt dùng để chạy các job đồng bộ dữ liệu định kỳ (PL/pgSQL + pg_cron)
-- tại Central Server, đọc dữ liệu từ BCA và BTP qua FDW.
\echo '   -> Tạo role đồng bộ...'
-- **Thay đổi:** Đã loại bỏ thuộc tính REPLICATION vì không dùng logical replication CDC
CREATE ROLE sync_user WITH LOGIN ENCRYPTED PASSWORD 'SyncData@2025';
COMMENT ON ROLE sync_user IS '[QLDCQG - Simplified] Role dùng cho job đồng bộ dữ liệu định kỳ (qua FDW và PL/pgSQL)';

-- ============================================================================
-- 3. THIẾT LẬP THAM SỐ ROLE (TÙY CHỌN)
-- ============================================================================
\echo 'Bước 3: Thiết lập tham số mặc định cho roles (tùy chọn)...'
-- Ví dụ: Thiết lập search_path mặc định (có thể ghi đè bởi cấu hình database hoặc session)
-- ALTER ROLE security_reader SET search_path TO public_security, reference, public;
-- ALTER ROLE justice_reader SET search_path TO justice, reference, public;
-- ALTER ROLE central_server_reader SET search_path TO central, public_security_mirror, justice_mirror, reference, public;
-- ALTER ROLE sync_user SET search_path TO central, sync, public_security_mirror, justice_mirror, reference, public; -- Cần truy cập nhiều schema ở Central DB

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO ROLES (USERS) (PHIÊN BẢN ĐƠN GIẢN HÓA) ***'
\echo '-> Đã tạo các roles cần thiết cho hệ thống.'
\echo '-> Role sync_user đã được điều chỉnh (bỏ REPLICATION).'
\echo '-> Bước tiếp theo: Chạy security/permissions.sql để cấp quyền chi tiết.'

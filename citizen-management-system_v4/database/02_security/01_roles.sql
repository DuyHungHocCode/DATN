-- File: 02_security/01_roles.sql
-- Description: Định nghĩa các vai trò (roles/users) cho hệ thống QLDCQG
--              trong kiến trúc microservices.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Chức năng chính:
-- 1. Xóa các roles cũ (nếu tồn tại) để đảm bảo định nghĩa mới nhất được áp dụng.
-- 2. Tạo các roles quản trị (admin) cho từng hệ thống con (BCA, BTP, TT).
-- 3. Tạo các roles chỉ đọc (reader) cho ứng dụng truy vấn dữ liệu.
-- 4. Tạo các roles ghi (writer) cho ứng dụng cập nhật dữ liệu.
-- 5. Tạo role đặc biệt cho mục đích đồng bộ dữ liệu (sync_user) qua FDW.
--
-- Yêu cầu: Chạy script này với quyền superuser (ví dụ: user postgres).
--          Chạy sau khi các database đã được tạo (00_init/01_create_databases.sql).
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO ROLES (USERS) ***'

-- Kết nối đến PostgreSQL instance mặc định (ví dụ: postgres) với quyền superuser
-- Roles là đối tượng cluster-level, không cần kết nối database cụ thể để tạo role.
\connect postgres

-- ============================================================================
-- 1. XÓA ROLES CŨ (NẾU TỒN TẠI)
-- ============================================================================
\echo 'Bước 1: Xóa các roles cũ (nếu tồn tại)...'

-- Sử dụng DROP ROLE IF EXISTS để tránh lỗi nếu role chưa tồn tại.
DROP ROLE IF EXISTS security_admin;
DROP ROLE IF EXISTS justice_admin;
DROP ROLE IF EXISTS central_server_admin;
DROP ROLE IF EXISTS security_reader;
DROP ROLE IF EXISTS justice_reader;
DROP ROLE IF EXISTS central_server_reader;
DROP ROLE IF EXISTS security_writer;
DROP ROLE IF EXISTS justice_writer;
-- DROP ROLE IF EXISTS central_server_writer; -- Cân nhắc xem có cần role writer riêng cho App TT không
DROP ROLE IF EXISTS sync_user;
-- Thêm các role khác nếu có trong phiên bản cũ

\echo '-> Đã xóa các roles cũ (nếu có).'

-- ============================================================================
-- 2. TẠO CÁC ROLES MỚI
-- ============================================================================
\echo 'Bước 2: Tạo các roles mới...'

-- 2.1 Roles quản trị (Admin Roles)
-- Có quyền cao trong database tương ứng. Cân nhắc hạn chế CREATEDB/CREATEROLE trong môi trường production.
\echo '   -> Tạo roles quản trị...'
CREATE ROLE security_admin WITH
    LOGIN                   -- Cho phép role này đăng nhập
    ENCRYPTED PASSWORD 'SecureMPS_ChangeMe!2025' -- **THAY ĐỔI MẬT KHẨU NÀY!**
    CREATEDB                -- Cho phép tạo database (có thể hạn chế)
    CREATEROLE;             -- Cho phép tạo role khác (có thể hạn chế)
COMMENT ON ROLE security_admin IS '[QLDCQG] Role quản trị cho database Bộ Công an (ministry_of_public_security)';

CREATE ROLE justice_admin WITH
    LOGIN
    ENCRYPTED PASSWORD 'SecureMOJ_ChangeMe!2025' -- **THAY ĐỔI MẬT KHẨU NÀY!**
    CREATEDB
    CREATEROLE;
COMMENT ON ROLE justice_admin IS '[QLDCQG] Role quản trị cho database Bộ Tư pháp (ministry_of_justice)';

CREATE ROLE central_server_admin WITH
    LOGIN
    ENCRYPTED PASSWORD 'SecureCentral_ChangeMe!2025' -- **THAY ĐỔI MẬT KHẨU NÀY!**
    CREATEDB
    CREATEROLE;
COMMENT ON ROLE central_server_admin IS '[QLDCQG] Role quản trị cho database Máy chủ trung tâm (national_citizen_central_server)';

-- 2.2 Roles chỉ đọc (Read-Only Roles)
-- Dùng cho các ứng dụng/API chỉ cần truy vấn dữ liệu.
\echo '   -> Tạo roles chỉ đọc...'
CREATE ROLE security_reader WITH
    LOGIN
    ENCRYPTED PASSWORD 'ReaderMPS_ChangeMe!2025'; -- **THAY ĐỔI MẬT KHẨU NÀY!**
COMMENT ON ROLE security_reader IS '[QLDCQG] Role chỉ đọc dữ liệu cho ứng dụng Bộ Công an';

CREATE ROLE justice_reader WITH
    LOGIN
    ENCRYPTED PASSWORD 'ReaderMOJ_ChangeMe!2025'; -- **THAY ĐỔI MẬT KHẨU NÀY!**
COMMENT ON ROLE justice_reader IS '[QLDCQG] Role chỉ đọc dữ liệu cho ứng dụng Bộ Tư pháp';

CREATE ROLE central_server_reader WITH
    LOGIN
    ENCRYPTED PASSWORD 'ReaderCentral_ChangeMe!2025'; -- **THAY ĐỔI MẬT KHẨU NÀY!**
COMMENT ON ROLE central_server_reader IS '[QLDCQG] Role chỉ đọc dữ liệu cho ứng dụng Máy chủ trung tâm (dữ liệu tích hợp)';

-- 2.3 Roles ghi (Write Roles)
-- Dùng cho các ứng dụng/API cần quyền thêm/sửa/xóa dữ liệu nghiệp vụ.
\echo '   -> Tạo roles ghi...'
CREATE ROLE security_writer WITH
    LOGIN
    ENCRYPTED PASSWORD 'WriterMPS_ChangeMe!2025'; -- **THAY ĐỔI MẬT KHẨU NÀY!**
COMMENT ON ROLE security_writer IS '[QLDCQG] Role ghi dữ liệu cho ứng dụng Bộ Công an';

CREATE ROLE justice_writer WITH
    LOGIN
    ENCRYPTED PASSWORD 'WriterMOJ_ChangeMe!2025'; -- **THAY ĐỔI MẬT KHẨU NÀY!**
COMMENT ON ROLE justice_writer IS '[QLDCQG] Role ghi dữ liệu cho ứng dụng Bộ Tư pháp';

-- Cân nhắc tạo role writer cho TT nếu App TT có chức năng ghi dữ liệu trực tiếp
-- (ngoài việc đồng bộ do sync_user thực hiện).
-- CREATE ROLE central_server_writer WITH LOGIN ENCRYPTED PASSWORD 'WriterCentral_ChangeMe!2025';
-- COMMENT ON ROLE central_server_writer IS '[QLDCQG] Role ghi dữ liệu cho ứng dụng Máy chủ trung tâm (nếu cần)';

-- 2.4 Role đồng bộ dữ liệu (Synchronization Role)
-- Role dùng bởi quy trình đồng bộ (Airflow/pg_cron) chạy trên Máy chủ Trung tâm
-- để đọc dữ liệu từ BCA, BTP qua FDW và ghi dữ liệu vào DB Trung tâm.
\echo '   -> Tạo role đồng bộ...'
CREATE ROLE sync_user WITH
    LOGIN
    ENCRYPTED PASSWORD 'SyncUser_ChangeMe!2025'; -- **THAY ĐỔI MẬT KHẨU NÀY!**
    -- Không cần quyền REPLICATION trong mô hình FDW + Airflow/pg_cron
COMMENT ON ROLE sync_user IS '[QLDCQG] Role dùng cho quy trình đồng bộ dữ liệu (qua FDW và logic tại Máy chủ Trung tâm)';

-- ============================================================================
-- 3. THIẾT LẬP THAM SỐ ROLE (TÙY CHỌN)
-- ============================================================================
-- \echo 'Bước 3: Thiết lập tham số mặc định cho roles (tùy chọn)...'
-- Ví dụ: Thiết lập search_path mặc định cho từng role nếu cần ghi đè cấu hình database
-- ALTER ROLE security_reader SET search_path = public_security, reference, public;
-- ALTER ROLE justice_writer SET search_path = justice, reference, public;
-- ALTER ROLE sync_user SET search_path = central, sync, public_security_mirror, justice_mirror, reference, public;

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO ROLES (USERS) ***'
\echo '-> Đã tạo các roles cần thiết cho hệ thống theo kiến trúc microservices.'
\echo '-> Lưu ý: Hãy thay đổi các mật khẩu mặc định ngay lập tức!'
\echo '-> Bước tiếp theo: Chạy 01_common/01_extensions.sql để cài đặt extensions.'
-- =============================================================================
-- File: 02_security/01_roles.sql
-- Description: Định nghĩa các vai trò (roles/users) cho Hệ thống QLDCQG.
-- Version: 3.1 (Refined comments, added security note)
--
-- Chức năng chính:
-- 1. Xóa các roles cũ (nếu tồn tại).
-- 2. Tạo các roles quản trị (admin) cho từng hệ thống con (BCA, BTP, TT).
-- 3. Tạo các roles chỉ đọc (reader) cho ứng dụng truy vấn.
-- 4. Tạo các roles ghi (writer) cho ứng dụng cập nhật dữ liệu.
-- 5. Tạo role đặc biệt cho mục đích đồng bộ dữ liệu (sync_user).
--
-- Yêu cầu:
-- - Chạy script này với quyền superuser (ví dụ: user postgres).
-- - Chạy sau khi các database đã được tạo (00_init/01_create_databases.sql).
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO ROLES (USERS) ***'

-- Kết nối đến PostgreSQL instance mặc định (ví dụ: postgres) với quyền superuser
-- Roles là đối tượng cluster-level, không cần kết nối database cụ thể để tạo.
\connect postgres

-- === 1. XÓA ROLES CŨ (NẾU TỒN TẠI) ===
-- Đảm bảo định nghĩa mới nhất được áp dụng.

\echo '[Bước 1] Xóa các roles cũ (nếu tồn tại)...'

DROP ROLE IF EXISTS security_admin;
DROP ROLE IF EXISTS justice_admin;
DROP ROLE IF EXISTS central_server_admin;
DROP ROLE IF EXISTS security_reader;
DROP ROLE IF EXISTS justice_reader;
DROP ROLE IF EXISTS central_server_reader;
DROP ROLE IF EXISTS security_writer;
DROP ROLE IF EXISTS justice_writer;
-- DROP ROLE IF EXISTS central_server_writer; -- Cân nhắc nếu App TT cần quyền ghi riêng
DROP ROLE IF EXISTS sync_user;

\echo '   -> Hoàn thành xóa roles cũ (nếu có).'

-- === 2. TẠO CÁC ROLES MỚI ===

\echo '[Bước 2] Tạo các roles mới...'

-- ------------------------------------------
-- QUAN TRỌNG: AN TOÀN MẬT KHẨU
-- -> Đã thay đổi tất cả mật khẩu thành "123" theo yêu cầu
-- -> Lưu ý: Đây là mật khẩu yếu, chỉ nên dùng cho môi trường phát triển
-- ------------------------------------------

-- 2.1. Roles Quản trị (Admin Roles)
\echo '   -> Tạo roles quản trị...'
CREATE ROLE security_admin WITH
    LOGIN
    ENCRYPTED PASSWORD '123'
    CREATEDB                -- Có thể hạn chế quyền này trong production
    CREATEROLE;             -- Có thể hạn chế quyền này trong production
COMMENT ON ROLE security_admin IS '[QLDCQG] Role quản trị cho database Bộ Công an (ministry_of_public_security).';

CREATE ROLE justice_admin WITH
    LOGIN
    ENCRYPTED PASSWORD '123'
    CREATEDB
    CREATEROLE;
COMMENT ON ROLE justice_admin IS '[QLDCQG] Role quản trị cho database Bộ Tư pháp (ministry_of_justice).';

CREATE ROLE central_server_admin WITH
    LOGIN
    ENCRYPTED PASSWORD '123'
    CREATEDB
    CREATEROLE;
COMMENT ON ROLE central_server_admin IS '[QLDCQG] Role quản trị cho database Máy chủ trung tâm (national_citizen_central_server).';

-- 2.2. Roles Chỉ đọc (Read-Only Roles)
\echo '   -> Tạo roles chỉ đọc...'
CREATE ROLE security_reader WITH
    LOGIN
    ENCRYPTED PASSWORD '123';
COMMENT ON ROLE security_reader IS '[QLDCQG] Role chỉ đọc dữ liệu cho ứng dụng Bộ Công an.';

CREATE ROLE justice_reader WITH
    LOGIN
    ENCRYPTED PASSWORD '123';
COMMENT ON ROLE justice_reader IS '[QLDCQG] Role chỉ đọc dữ liệu cho ứng dụng Bộ Tư pháp.';

CREATE ROLE central_server_reader WITH
    LOGIN
    ENCRYPTED PASSWORD '123';
COMMENT ON ROLE central_server_reader IS '[QLDCQG] Role chỉ đọc dữ liệu cho ứng dụng Máy chủ trung tâm.';

-- 2.3. Roles Ghi (Write Roles)
\echo '   -> Tạo roles ghi...'
CREATE ROLE security_writer WITH
    LOGIN
    ENCRYPTED PASSWORD '123';
COMMENT ON ROLE security_writer IS '[QLDCQG] Role ghi dữ liệu cho ứng dụng Bộ Công an.';

CREATE ROLE justice_writer WITH
    LOGIN
    ENCRYPTED PASSWORD '123';
COMMENT ON ROLE justice_writer IS '[QLDCQG] Role ghi dữ liệu cho ứng dụng Bộ Tư pháp.';

-- Cân nhắc tạo role writer cho TT nếu cần
-- CREATE ROLE central_server_writer WITH LOGIN ENCRYPTED PASSWORD '123';
-- COMMENT ON ROLE central_server_writer IS '[QLDCQG] Role ghi dữ liệu cho ứng dụng Máy chủ trung tâm (nếu cần).';

-- 2.4. Role Đồng bộ dữ liệu (Synchronization Role)
\echo '   -> Tạo role đồng bộ...'
CREATE ROLE sync_user WITH
    LOGIN
    ENCRYPTED PASSWORD '123';
COMMENT ON ROLE sync_user IS '[QLDCQG] Role dùng cho quy trình đồng bộ dữ liệu (qua FDW và logic tại Máy chủ Trung tâm).';

\echo '   -> Hoàn thành tạo các roles mới.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO ROLES (USERS) ***'
\echo '-> Đã tạo các roles cần thiết cho hệ thống theo kiến trúc microservices.'
\echo '-> Lưu ý: Đã sử dụng mật khẩu đơn giản ("123") cho mọi role theo yêu cầu.'
\echo '-> Bước tiếp theo: Chạy script 01_common/01_extensions.sql để cài đặt extensions.'
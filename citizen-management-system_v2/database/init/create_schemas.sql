-- Script tạo các schema trong các database của hệ thống quản lý dân cư quốc gia

-----------------------------------------------------------------------------------
-- 1. TẠO CÁC SCHEMA TRONG DATABASE BỘ CÔNG AN
-----------------------------------------------------------------------------------
\connect ministry_of_public_security

-- Tạo các schema chính
CREATE SCHEMA IF NOT EXISTS public_security;
COMMENT ON SCHEMA public_security IS 'Schema chứa các bảng dữ liệu chính của Bộ Công an';

CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS 'Schema chứa các bảng tham chiếu dùng chung';

CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Schema chứa các bảng nhật ký hoạt động hệ thống';

CREATE SCHEMA IF NOT EXISTS sync;
COMMENT ON SCHEMA sync IS 'Schema chứa các bảng và function đồng bộ dữ liệu';

CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS 'Schema chứa các function và view phục vụ API';

CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo thống kê';

CREATE SCHEMA IF NOT EXISTS system;
COMMENT ON SCHEMA system IS 'Schema chứa các function và procedure hệ thống';

CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS 'Schema chứa các function và bảng hỗ trợ phân vùng';

-- Phân quyền trên các schema cho các người dùng
-- Người dùng quản trị
GRANT ALL ON SCHEMA public_security TO security_admin;
GRANT ALL ON SCHEMA reference TO security_admin;
GRANT ALL ON SCHEMA audit TO security_admin;
GRANT ALL ON SCHEMA sync TO security_admin;
GRANT ALL ON SCHEMA api TO security_admin;
GRANT ALL ON SCHEMA reports TO security_admin;
GRANT ALL ON SCHEMA system TO security_admin;
GRANT ALL ON SCHEMA partitioning TO security_admin;

-- Người dùng chỉ đọc
GRANT USAGE ON SCHEMA public_security TO security_reader;
GRANT USAGE ON SCHEMA reference TO security_reader;
GRANT USAGE ON SCHEMA api TO security_reader;
GRANT USAGE ON SCHEMA reports TO security_reader;

-- Người dùng chỉ ghi
GRANT USAGE ON SCHEMA public_security TO security_writer;
GRANT USAGE ON SCHEMA reference TO security_writer;
GRANT USAGE ON SCHEMA api TO security_writer;

-- Người dùng đồng bộ
GRANT USAGE ON SCHEMA public_security TO sync_user;
GRANT USAGE ON SCHEMA reference TO sync_user;
GRANT USAGE ON SCHEMA sync TO sync_user;

-- Thiết lập đường dẫn tìm kiếm mặc định
ALTER DATABASE ministry_of_public_security SET search_path TO public_security, reference, public;

-----------------------------------------------------------------------------------
-- 2. TẠO CÁC SCHEMA TRONG DATABASE BỘ TƯ PHÁP
-----------------------------------------------------------------------------------
\connect ministry_of_justice

-- Tạo các schema chính
CREATE SCHEMA IF NOT EXISTS justice;
COMMENT ON SCHEMA justice IS 'Schema chứa các bảng dữ liệu chính của Bộ Tư pháp';

CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS 'Schema chứa các bảng tham chiếu dùng chung';

CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS 'Schema chứa các bảng nhật ký hoạt động hệ thống';

CREATE SCHEMA IF NOT EXISTS sync;
COMMENT ON SCHEMA sync IS 'Schema chứa các bảng và function đồng bộ dữ liệu';

CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS 'Schema chứa các function và view phục vụ API';

CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo thống kê';

CREATE SCHEMA IF NOT EXISTS system;
COMMENT ON SCHEMA system IS 'Schema chứa các function và procedure hệ thống';

CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS 'Schema chứa các function và bảng hỗ trợ phân vùng';

-- Phân quyền trên các schema cho các người dùng
-- Người dùng quản trị
GRANT ALL ON SCHEMA justice TO justice_admin;
GRANT ALL ON SCHEMA reference TO justice_admin;
GRANT ALL ON SCHEMA audit TO justice_admin;
GRANT ALL ON SCHEMA sync TO justice_admin;
GRANT ALL ON SCHEMA api TO justice_admin;
GRANT ALL ON SCHEMA reports TO justice_admin;
GRANT ALL ON SCHEMA system TO justice_admin;
GRANT ALL ON SCHEMA partitioning TO justice_admin;

-- Người dùng chỉ đọc
GRANT USAGE ON SCHEMA justice TO justice_reader;
GRANT USAGE ON SCHEMA reference TO justice_reader;
GRANT USAGE ON SCHEMA api TO justice_reader;
GRANT USAGE ON SCHEMA reports TO justice_reader;

-- Người dùng chỉ ghi
GRANT USAGE ON SCHEMA justice TO justice_writer;
GRANT USAGE ON SCHEMA reference TO justice_writer;
GRANT USAGE ON SCHEMA api TO justice_writer;

-- Người dùng đồng bộ
GRANT USAGE ON SCHEMA justice TO sync_user;
GRANT USAGE ON SCHEMA reference TO sync_user;
GRANT USAGE ON SCHEMA sync TO sync_user;

-- Thiết lập đường dẫn tìm kiếm mặc định
ALTER DATABASE ministry_of_justice SET search_path TO justice, reference, public;
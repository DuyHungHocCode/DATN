-- =============================================================================
-- File: database/common/extensions.sql
-- Description: Cài đặt các extension cần thiết cho hệ thống QLDCQG
-- Version: 2.1 (Sửa lỗi định nghĩa hàm trong context database chính xác)
--
-- Lưu ý: Yêu cầu quyền superuser để thực thi CREATE EXTENSION.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'

-- ============================================================================
-- 1. CÀI ĐẶT CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo 'Bước 1: Cài đặt extensions cho ministry_of_public_security...'
\connect ministry_of_public_security

-- Định nghĩa hàm helper TRONG database này
CREATE OR REPLACE FUNCTION install_standard_extensions_mps() RETURNS void AS $$
BEGIN
    \echo '      -> Cài đặt các extension tiêu chuẩn cho BCA...';
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    CREATE EXTENSION IF NOT EXISTS "hstore";
    CREATE EXTENSION IF NOT EXISTS "ltree";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    CREATE EXTENSION IF NOT EXISTS "unaccent";
    CREATE EXTENSION IF NOT EXISTS "pg_partman";
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw";
    CREATE EXTENSION IF NOT EXISTS "dblink";
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    CREATE EXTENSION IF NOT EXISTS "pg_background";
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
    \echo '      -> Hoàn thành cài đặt extension tiêu chuẩn cho BCA.';
END;
$$ LANGUAGE plpgsql;

-- Gọi hàm helper
SELECT install_standard_extensions_mps();

-- Xóa hàm helper sau khi dùng xong
DROP FUNCTION IF EXISTS install_standard_extensions_mps();

-- Tạo text search configuration tiếng Việt (nếu chưa có)
DO $$ BEGIN
    CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
    ALTER TEXT SEARCH CONFIGURATION vietnamese
       ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
    \echo '      -> Đã tạo/cấu hình Text Search Configuration "vietnamese" cho BCA.';
EXCEPTION
    WHEN duplicate_object THEN
        \echo '      -> Text Search Configuration "vietnamese" đã tồn tại trong BCA.';
END $$;

\echo '-> Hoàn thành cài đặt extensions cho ministry_of_public_security.'

-- ============================================================================
-- 2. CÀI ĐẶT CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Bước 2: Cài đặt extensions cho ministry_of_justice...'
\connect ministry_of_justice

-- Định nghĩa hàm helper TRONG database này
CREATE OR REPLACE FUNCTION install_standard_extensions_moj() RETURNS void AS $$
BEGIN
    \echo '      -> Cài đặt các extension tiêu chuẩn cho BTP...';
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    CREATE EXTENSION IF NOT EXISTS "hstore";
    CREATE EXTENSION IF NOT EXISTS "ltree";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    CREATE EXTENSION IF NOT EXISTS "unaccent";
    CREATE EXTENSION IF NOT EXISTS "pg_partman";
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw";
    CREATE EXTENSION IF NOT EXISTS "dblink";
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    CREATE EXTENSION IF NOT EXISTS "pg_background";
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
     \echo '      -> Hoàn thành cài đặt extension tiêu chuẩn cho BTP.';
END;
$$ LANGUAGE plpgsql;

-- Gọi hàm helper
SELECT install_standard_extensions_moj();

-- Xóa hàm helper sau khi dùng xong
DROP FUNCTION IF EXISTS install_standard_extensions_moj();

-- Tạo text search configuration tiếng Việt (nếu chưa có)
DO $$ BEGIN
    CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
    ALTER TEXT SEARCH CONFIGURATION vietnamese
       ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
    \echo '      -> Đã tạo/cấu hình Text Search Configuration "vietnamese" cho BTP.';
EXCEPTION
    WHEN duplicate_object THEN
        \echo '      -> Text Search Configuration "vietnamese" đã tồn tại trong BTP.';
END $$;

\echo '-> Hoàn thành cài đặt extensions cho ministry_of_justice.'

-- ============================================================================
-- 3. CÀI ĐẶT CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Bước 3: Cài đặt extensions cho national_citizen_central_server...'
\connect national_citizen_central_server

-- Định nghĩa hàm helper TRONG database này
CREATE OR REPLACE FUNCTION install_standard_extensions_central() RETURNS void AS $$
BEGIN
    \echo '      -> Cài đặt các extension tiêu chuẩn cho TT...';
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    CREATE EXTENSION IF NOT EXISTS "hstore";
    CREATE EXTENSION IF NOT EXISTS "ltree";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    CREATE EXTENSION IF NOT EXISTS "unaccent";
    CREATE EXTENSION IF NOT EXISTS "pg_partman";
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw";
    CREATE EXTENSION IF NOT EXISTS "dblink";
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    CREATE EXTENSION IF NOT EXISTS "pg_background";
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
    \echo '      -> Hoàn thành cài đặt extension tiêu chuẩn cho TT.';
END;
$$ LANGUAGE plpgsql;

-- Gọi hàm helper
SELECT install_standard_extensions_central();

-- Cài đặt các extensions bổ sung cho máy chủ trung tâm
\echo '      -> Cài đặt các extension bổ sung cho máy chủ trung tâm...';
CREATE EXTENSION IF NOT EXISTS "pg_stat_monitor";   -- Giám sát nâng cao hơn pg_stat_statements
CREATE EXTENSION IF NOT EXISTS "pg_failover_slots"; -- Quản lý replication slots khi failover (quan trọng cho CDC HA)
-- CREATE EXTENSION IF NOT EXISTS "timescaledb"; -- Bỏ comment nếu thực sự cần xử lý dữ liệu chuỗi thời gian

\echo '      -> Hoàn thành cài đặt extension bổ sung.';

-- Xóa hàm helper sau khi dùng xong
DROP FUNCTION IF EXISTS install_standard_extensions_central();

-- Tạo text search configuration tiếng Việt (nếu chưa có)
DO $$ BEGIN
    CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
    ALTER TEXT SEARCH CONFIGURATION vietnamese
       ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
    \echo '      -> Đã tạo/cấu hình Text Search Configuration "vietnamese" cho TT.';
EXCEPTION
    WHEN duplicate_object THEN
        \echo '      -> Text Search Configuration "vietnamese" đã tồn tại trong TT.';
END $$;

\echo '-> Hoàn thành cài đặt extensions cho national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'
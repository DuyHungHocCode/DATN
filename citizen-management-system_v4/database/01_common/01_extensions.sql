-- File: 01_common/01_extensions.sql
-- Description: Cài đặt các PostgreSQL extensions cần thiết cho các database
--              trong hệ thống QLDCQG.
-- Version: 3.0 (Aligned with Microservices Structure and revised extension list)
--
-- Chức năng chính:
-- 1. Cài đặt bộ extensions chung cho cả 3 database (BCA, BTP, TT).
-- 2. Cài đặt extensions bổ sung chỉ dành cho database Trung tâm (TT).
-- 3. Tạo cấu hình tìm kiếm văn bản tiếng Việt (vietnamese text search configuration).
--
-- Yêu cầu: Chạy script này với quyền superuser (ví dụ: user postgres).
--          Chạy sau khi các database và schema cơ bản đã được tạo.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'

-- ============================================================================
-- 1. CÀI ĐẶT CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo 'Bước 1: Cài đặt extensions cho ministry_of_public_security...'
\connect ministry_of_public_security

DO $$
BEGIN
    \echo '   -> Cài đặt các extension tiêu chuẩn cho BCA...';
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";          -- Tạo UUIDs
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";           -- Hàm mã hóa (vd: hash mật khẩu)
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";            -- Hỗ trợ tìm kiếm mờ (fuzzy search) qua trigram
    CREATE EXTENSION IF NOT EXISTS "postgis";            -- Kiểu dữ liệu và hàm không gian địa lý
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";   -- Hỗ trợ topology cho PostGIS
    CREATE EXTENSION IF NOT EXISTS "hstore";             -- Kiểu dữ liệu key-value (có thể thay bằng JSONB)
    CREATE EXTENSION IF NOT EXISTS "ltree";              -- Kiểu dữ liệu cây phân cấp
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- Thống kê thực thi câu lệnh SQL
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";     -- Xem thông tin bộ đệm (buffer cache)
    CREATE EXTENSION IF NOT EXISTS "unaccent";           -- Loại bỏ dấu tiếng Việt và các dấu phụ khác
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw";       -- Foreign Data Wrapper cho kết nối PostgreSQL khác
    CREATE EXTENSION IF NOT EXISTS "dblink";             -- Kết nối đến DB khác trong câu lệnh SQL (ít dùng hơn FDW)
    CREATE EXTENSION IF NOT EXISTS "plpgsql";            -- Ngôn ngữ lập trình thủ tục mặc định (thường có sẵn)
    CREATE EXTENSION IF NOT EXISTS "tablefunc";          -- Hỗ trợ tạo bảng chéo (crosstab)
    CREATE EXTENSION IF NOT EXISTS "pg_repack";          -- Reorganize bảng online, giảm khóa
    CREATE EXTENSION IF NOT EXISTS "pgaudit";            -- Ghi log audit chi tiết
    CREATE EXTENSION IF NOT EXISTS "pg_cron";            -- Lập lịch chạy câu lệnh SQL/hàm
    \echo '   -> Hoàn thành cài đặt extension tiêu chuẩn cho BCA.';

    -- Tạo text search configuration tiếng Việt (nếu chưa có)
    \echo '   -> Tạo/Kiểm tra Text Search Configuration "vietnamese"...';
    IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'vietnamese') THEN
        CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
        ALTER TEXT SEARCH CONFIGURATION vietnamese
            ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
        \echo '      -> Đã tạo Text Search Configuration "vietnamese".';
    ELSE
        \echo '      -> Text Search Configuration "vietnamese" đã tồn tại.';
    END IF;

END $$;

\echo '-> Hoàn thành cài đặt extensions cho ministry_of_public_security.'

-- ============================================================================
-- 2. CÀI ĐẶT CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo 'Bước 2: Cài đặt extensions cho ministry_of_justice...'
\connect ministry_of_justice

DO $$
BEGIN
    \echo '   -> Cài đặt các extension tiêu chuẩn cho BTP...';
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
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw";
    CREATE EXTENSION IF NOT EXISTS "dblink";
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
    \echo '   -> Hoàn thành cài đặt extension tiêu chuẩn cho BTP.';

    -- Tạo text search configuration tiếng Việt (nếu chưa có)
    \echo '   -> Tạo/Kiểm tra Text Search Configuration "vietnamese"...';
     IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'vietnamese') THEN
        CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
        ALTER TEXT SEARCH CONFIGURATION vietnamese
            ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
        \echo '      -> Đã tạo Text Search Configuration "vietnamese".';
    ELSE
        \echo '      -> Text Search Configuration "vietnamese" đã tồn tại.';
    END IF;

END $$;

\echo '-> Hoàn thành cài đặt extensions cho ministry_of_justice.'

-- ============================================================================
-- 3. CÀI ĐẶT CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo 'Bước 3: Cài đặt extensions cho national_citizen_central_server...'
\connect national_citizen_central_server

DO $$
BEGIN
    \echo '   -> Cài đặt các extension tiêu chuẩn cho TT...';
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
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw"; -- Rất quan trọng cho TT
    CREATE EXTENSION IF NOT EXISTS "dblink";
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    CREATE EXTENSION IF NOT EXISTS "pg_cron";       -- Rất quan trọng nếu dùng pg_cron cho sync
    \echo '   -> Hoàn thành cài đặt extension tiêu chuẩn cho TT.';

    -- Cài đặt các extensions bổ sung chỉ dành cho máy chủ trung tâm
    \echo '   -> Cài đặt các extension bổ sung cho TT...';
    CREATE EXTENSION IF NOT EXISTS "pg_stat_monitor";   -- Giám sát câu lệnh nâng cao hơn pg_stat_statements
    -- CREATE EXTENSION IF NOT EXISTS "timescaledb"; -- Chỉ cài nếu thực sự cần xử lý dữ liệu chuỗi thời gian quy mô lớn
    \echo '   -> Hoàn thành cài đặt extension bổ sung cho TT.';

    -- Tạo text search configuration tiếng Việt (nếu chưa có)
    \echo '   -> Tạo/Kiểm tra Text Search Configuration "vietnamese"...';
     IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'vietnamese') THEN
        CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
        ALTER TEXT SEARCH CONFIGURATION vietnamese
            ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
        \echo '      -> Đã tạo Text Search Configuration "vietnamese".';
    ELSE
        \echo '      -> Text Search Configuration "vietnamese" đã tồn tại.';
    END IF;

END $$;

\echo '-> Hoàn thành cài đặt extensions cho national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'
\echo '-> Đã cài đặt các extensions cần thiết và cấu hình tìm kiếm tiếng Việt.'
\echo '-> Bước tiếp theo: Chạy 01_common/02_enum.sql để tạo các kiểu dữ liệu ENUM.'
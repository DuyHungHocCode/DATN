-- File: 01_common/01_extensions.sql
-- Description: Cài đặt các PostgreSQL extensions cần thiết cho các database
--              trong hệ thống QLDCQG. (Đã sửa lỗi \echo và pg_cron)
-- Version: 3.2 (Fixed pg_cron creation location)
--
-- Chức năng chính:
-- 1. Cài đặt bộ extensions chung cho cả 3 database (BCA, BTP, TT).
-- 2. Cài đặt extensions bổ sung chỉ dành cho database Trung tâm (TT).
-- 3. Tạo cấu hình tìm kiếm văn bản tiếng Việt (vietnamese text search configuration).
-- 4. **Lưu ý:** pg_cron chỉ được tạo ở DB Trung tâm (national_citizen_central_server).
--
-- Yêu cầu: Chạy script này với quyền superuser (ví dụ: user postgres).
--          Chạy sau khi các database và schema cơ bản đã được tạo.
--          Đảm bảo các gói OS cho extensions đã được cài đặt.
--          Đảm bảo các extension cần preload (pgaudit, pg_cron...) đã được thêm vào
--          shared_preload_libraries trong postgresql.conf và server đã được restart.
--          Đảm bảo cron.database_name được thiết lập trong postgresql.conf (vd: 'national_citizen_central_server').
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'

-- ============================================================================
-- 1. CÀI ĐẶT CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo 'Bước 1: Cài đặt extensions cho ministry_of_public_security...'
\connect ministry_of_public_security

DO $$
BEGIN
    RAISE NOTICE '   -> Cài đặt các extension tiêu chuẩn cho BCA...';
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
    -- **ĐÃ XÓA: CREATE EXTENSION IF NOT EXISTS "pg_cron";** (Chỉ tạo ở DB Trung tâm)
    RAISE NOTICE '   -> Hoàn thành cài đặt extension tiêu chuẩn cho BCA.';

    -- Tạo text search configuration tiếng Việt (nếu chưa có)
    RAISE NOTICE '   -> Tạo/Kiểm tra Text Search Configuration "vietnamese"...';
    IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'vietnamese') THEN
        CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
        ALTER TEXT SEARCH CONFIGURATION vietnamese
            ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
        RAISE NOTICE '      -> Đã tạo Text Search Configuration "vietnamese".';
    ELSE
        RAISE NOTICE '      -> Text Search Configuration "vietnamese" đã tồn tại.';
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
    RAISE NOTICE '   -> Cài đặt các extension tiêu chuẩn cho BTP...';
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
    -- **ĐÃ XÓA: CREATE EXTENSION IF NOT EXISTS "pg_cron";** (Chỉ tạo ở DB Trung tâm)
    RAISE NOTICE '   -> Hoàn thành cài đặt extension tiêu chuẩn cho BTP.';

    -- Tạo text search configuration tiếng Việt (nếu chưa có)
    RAISE NOTICE '   -> Tạo/Kiểm tra Text Search Configuration "vietnamese"...';
     IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'vietnamese') THEN
        CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
        ALTER TEXT SEARCH CONFIGURATION vietnamese
            ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
        RAISE NOTICE '      -> Đã tạo Text Search Configuration "vietnamese".';
    ELSE
        RAISE NOTICE '      -> Text Search Configuration "vietnamese" đã tồn tại.';
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
    RAISE NOTICE '   -> Cài đặt các extension tiêu chuẩn cho TT...';
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
    -- **GIỮ LẠI: CREATE EXTENSION IF NOT EXISTS "pg_cron";** (Chỉ tạo ở DB này)
    -- Lệnh này chỉ thành công nếu DB này được cấu hình trong cron.database_name
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
    RAISE NOTICE '   -> Hoàn thành cài đặt extension tiêu chuẩn cho TT.';

    -- Cài đặt các extensions bổ sung chỉ dành cho máy chủ trung tâm
    RAISE NOTICE '   -> Cài đặt các extension bổ sung cho TT...';
    CREATE EXTENSION IF NOT EXISTS "pg_stat_monitor";   -- Giám sát câu lệnh nâng cao hơn pg_stat_statements
    -- CREATE EXTENSION IF NOT EXISTS "timescaledb"; -- Chỉ cài nếu thực sự cần xử lý dữ liệu chuỗi thời gian quy mô lớn
    RAISE NOTICE '   -> Hoàn thành cài đặt extension bổ sung cho TT.';

    -- Tạo text search configuration tiếng Việt (nếu chưa có)
    RAISE NOTICE '   -> Tạo/Kiểm tra Text Search Configuration "vietnamese"...';
     IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'vietnamese') THEN
        CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
        ALTER TEXT SEARCH CONFIGURATION vietnamese
            ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
        RAISE NOTICE '      -> Đã tạo Text Search Configuration "vietnamese".';
    ELSE
        RAISE NOTICE '      -> Text Search Configuration "vietnamese" đã tồn tại.';
    END IF;

END $$;

\echo '-> Hoàn thành cài đặt extensions cho national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'
\echo '-> Đã cài đặt các extensions cần thiết và cấu hình tìm kiếm tiếng Việt.'
\echo '-> Lưu ý: pg_cron chỉ được tạo trong national_citizen_central_server.'
\echo '-> Bước tiếp theo: Chạy 01_common/02_enum.sql để tạo các kiểu dữ liệu ENUM.'
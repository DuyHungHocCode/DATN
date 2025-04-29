-- =============================================================================
-- File: 01_common/01_extensions.sql
-- Description: Cài đặt các PostgreSQL extensions cần thiết cho các database
--              trong Hệ thống QLDCQG. Script này cần chạy trên cả 3 database.
-- Version: 3.3 (Reviewed essential extensions, added prerequisite notes)
--
-- Yêu cầu:
-- - Chạy script này với quyền superuser (ví dụ: user postgres).
-- - Chạy sau khi các database và schema cơ bản đã được tạo.
-- - Đảm bảo các gói OS cho extensions (vd: postgresql-contrib, postgis) đã được cài đặt.
-- - Các extension cần preload (như pgaudit, pg_cron, pg_stat_statements) phải được
--   thêm vào 'shared_preload_libraries' trong postgresql.conf và server đã được restart.
-- - Đảm bảo 'cron.database_name' được thiết lập trong postgresql.conf nếu sử dụng pg_cron.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'

-- === 1. CÀI ĐẶT CHO DATABASE BỘ CÔNG AN (ministry_of_public_security) ===

\echo '[Bước 1] Cài đặt extensions cho database: ministry_of_public_security...'
\connect ministry_of_public_security

DO $$
BEGIN
    RAISE NOTICE '   -> Cài đặt các extension cơ bản và cần thiết...';
    -- Hỗ trợ tạo UUID
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    -- Các hàm mã hóa (vd: hash mật khẩu)
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    -- Hỗ trợ tìm kiếm văn bản mờ (fuzzy string matching) và tạo index GIN/GIST hiệu quả cho text
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    -- Hỗ trợ kiểu dữ liệu không gian và hàm xử lý địa lý (quan trọng nếu dùng tọa độ)
    CREATE EXTENSION IF NOT EXISTS "postgis";
    -- Hỗ trợ topology cho PostGIS
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    -- Hỗ trợ loại bỏ dấu tiếng Việt cho tìm kiếm
    CREATE EXTENSION IF NOT EXISTS "unaccent";
    -- Ngôn ngữ lập trình thủ tục mặc định của PostgreSQL
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    -- Foreign Data Wrapper (có thể cần nếu BCA đọc dữ liệu từ nguồn khác)
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw";

    RAISE NOTICE '   -> Cài đặt các extension giám sát và kiểm toán (yêu cầu cấu hình postgresql.conf)...';
    -- Theo dõi thống kê thực thi câu lệnh SQL (cần thêm vào shared_preload_libraries)
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    -- Cung cấp chức năng ghi log audit chi tiết (cần thêm vào shared_preload_libraries)
    CREATE EXTENSION IF NOT EXISTS "pgaudit";

    RAISE NOTICE '   -> Cài đặt các extension tiện ích/bảo trì...';
    -- Cho phép xem nội dung của shared buffer cache (hữu ích cho tuning)
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    -- Công cụ reorganize bảng online để giảm bloat (cần chạy thủ công sau này)
    CREATE EXTENSION IF NOT EXISTS "pg_repack";

    RAISE NOTICE '   -> Hoàn thành cài đặt extensions cơ bản cho BCA.';

    -- Tạo cấu hình tìm kiếm văn bản tiếng Việt (sử dụng unaccent)
    RAISE NOTICE '   -> Tạo/Kiểm tra Text Search Configuration "vietnamese"...';
    IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'vietnamese') THEN
        CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
        -- Ánh xạ các loại token với bộ lọc unaccent và từ điển simple
        ALTER TEXT SEARCH CONFIGURATION vietnamese
            ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;
        RAISE NOTICE '      -> Đã tạo Text Search Configuration "vietnamese".';
    ELSE
        RAISE NOTICE '      -> Text Search Configuration "vietnamese" đã tồn tại.';
    END IF;

END $$;
\echo '   -> Hoàn thành cài đặt và cấu hình cho ministry_of_public_security.'


-- === 2. CÀI ĐẶT CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice) ===

\echo '[Bước 2] Cài đặt extensions cho database: ministry_of_justice...'
\connect ministry_of_justice

DO $$
BEGIN
    RAISE NOTICE '   -> Cài đặt các extension cơ bản và cần thiết...';
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    CREATE EXTENSION IF NOT EXISTS "unaccent";
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw"; -- Có thể cần nếu BTP đọc dữ liệu từ nguồn khác

    RAISE NOTICE '   -> Cài đặt các extension giám sát và kiểm toán (yêu cầu cấu hình postgresql.conf)...';
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pgaudit";

    RAISE NOTICE '   -> Cài đặt các extension tiện ích/bảo trì...';
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    CREATE EXTENSION IF NOT EXISTS "pg_repack";

    RAISE NOTICE '   -> Hoàn thành cài đặt extensions cơ bản cho BTP.';

    -- Tạo cấu hình tìm kiếm văn bản tiếng Việt
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
\echo '   -> Hoàn thành cài đặt và cấu hình cho ministry_of_justice.'


-- === 3. CÀI ĐẶT CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server) ===

\echo '[Bước 3] Cài đặt extensions cho database: national_citizen_central_server...'
\connect national_citizen_central_server

DO $$
BEGIN
    RAISE NOTICE '   -> Cài đặt các extension cơ bản và cần thiết...';
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    CREATE EXTENSION IF NOT EXISTS "unaccent";
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    -- Rất quan trọng cho việc đồng bộ dữ liệu từ BCA và BTP
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw";

    RAISE NOTICE '   -> Cài đặt các extension giám sát và kiểm toán (yêu cầu cấu hình postgresql.conf)...';
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    CREATE EXTENSION IF NOT EXISTS "pgaudit";

    RAISE NOTICE '   -> Cài đặt các extension tiện ích/bảo trì...';
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    CREATE EXTENSION IF NOT EXISTS "pg_repack";

    RAISE NOTICE '   -> Cài đặt extension lập lịch (chỉ cho DB Trung tâm, yêu cầu cấu hình postgresql.conf)...';
    -- Dùng để lập lịch chạy các tác vụ đồng bộ tự động
    -- LƯU Ý: Cần cấu hình 'shared_preload_libraries' và 'cron.database_name' trong postgresql.conf
    CREATE EXTENSION IF NOT EXISTS "pg_cron";

    RAISE NOTICE '   -> Hoàn thành cài đặt extensions cơ bản cho TT.';

    -- Tạo cấu hình tìm kiếm văn bản tiếng Việt
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
\echo '   -> Hoàn thành cài đặt và cấu hình cho national_citizen_central_server.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH QUÁ TRÌNH CÀI ĐẶT EXTENSIONS ***'
\echo '-> Đã cài đặt các extensions cần thiết và cấu hình tìm kiếm tiếng Việt trên 3 database.'
\echo '-> LƯU Ý QUAN TRỌNG: Đảm bảo các extension yêu cầu preload (pgaudit, pg_stat_statements, pg_cron) đã được cấu hình đúng trong postgresql.conf và server đã được restart.'
\echo '-> Bước tiếp theo: Chạy script 01_common/02_enum.sql để tạo các kiểu dữ liệu ENUM.'

-- Script cài đặt các extension cần thiết cho hệ thống quản lý dân cư quốc gia
-- File: database/common/extensions.sql

-- ============================================================================
-- 1. CÀI ĐẶT EXTENSION CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo 'Cài đặt các extension cho database Bộ Công an...'
\connect ministry_of_public_security

-- Tạo function cài đặt extension dùng chung
CREATE OR REPLACE FUNCTION install_standard_extensions() RETURNS void AS $$
BEGIN
    -- UUID extension (tạo ID định danh duy nhất)
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- Mã hóa dữ liệu nhạy cảm
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    
    -- Tìm kiếm tương đối văn bản (fuzzy search) cho tên người, địa chỉ
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    
    -- Xử lý dữ liệu địa lý
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    
    -- Lưu trữ dữ liệu dạng key-value
    CREATE EXTENSION IF NOT EXISTS "hstore";
    
    -- Quản lý cấu trúc cây (phân cấp hành chính)
    CREATE EXTENSION IF NOT EXISTS "ltree";
    
    -- Giám sát hiệu suất truy vấn
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    
    -- Tối ưu hóa bộ nhớ đệm
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    
    -- Full-text search nâng cao cho tiếng Việt
    CREATE EXTENSION IF NOT EXISTS "unaccent"; -- Loại bỏ dấu tiếng Việt khi tìm kiếm
    
    -- Phân vùng dữ liệu tự động
    CREATE EXTENSION IF NOT EXISTS "pg_partman";
    
    -- Các extension cho đồng bộ dữ liệu phân tán
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw"; -- Truy cập dữ liệu từ xa
    CREATE EXTENSION IF NOT EXISTS "dblink"; -- Thực thi câu lệnh từ xa
    
    -- Extension cho JSON
    CREATE EXTENSION IF NOT EXISTS "jsonb_plperl";
    
    -- Extension hỗ trợ đa ngôn ngữ
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    
    -- Extension cho queue tác vụ nền
    CREATE EXTENSION IF NOT EXISTS "pg_background";

    -- Extension cho tính toán thống kê
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    
    -- Extension đặc biệt cho CDC
    CREATE EXTENSION IF NOT EXISTS "wal2json";
    
    -- Extension nén dữ liệu
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    
    -- Extension cho mục đích audit
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    
    -- Extension lập lịch tác vụ
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
END;
$$ LANGUAGE plpgsql;

-- Gọi function cài đặt extension
SELECT install_standard_extensions();

-- Tạo từ điển tìm kiếm tiếng Việt
CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION vietnamese
   ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;

\echo 'Đã cài đặt các extension cho database Bộ Công an'

-- ============================================================================
-- 2. CÀI ĐẶT EXTENSION CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Cài đặt các extension cho database Bộ Tư pháp...'
\connect ministry_of_justice

-- Gọi lại function cài đặt extension dùng chung
CREATE OR REPLACE FUNCTION install_standard_extensions() RETURNS void AS $$
BEGIN
    -- UUID extension (tạo ID định danh duy nhất)
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- Mã hóa dữ liệu nhạy cảm
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    
    -- Tìm kiếm tương đối văn bản (fuzzy search) cho tên người, địa chỉ
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    
    -- Xử lý dữ liệu địa lý
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    
    -- Lưu trữ dữ liệu dạng key-value
    CREATE EXTENSION IF NOT EXISTS "hstore";
    
    -- Quản lý cấu trúc cây (phân cấp hành chính)
    CREATE EXTENSION IF NOT EXISTS "ltree";
    
    -- Giám sát hiệu suất truy vấn
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    
    -- Tối ưu hóa bộ nhớ đệm
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    
    -- Full-text search nâng cao cho tiếng Việt
    CREATE EXTENSION IF NOT EXISTS "unaccent"; -- Loại bỏ dấu tiếng Việt khi tìm kiếm
    
    -- Phân vùng dữ liệu tự động
    CREATE EXTENSION IF NOT EXISTS "pg_partman";
    
    -- Các extension cho đồng bộ dữ liệu phân tán
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw"; -- Truy cập dữ liệu từ xa
    CREATE EXTENSION IF NOT EXISTS "dblink"; -- Thực thi câu lệnh từ xa
    
    -- Extension cho JSON
    CREATE EXTENSION IF NOT EXISTS "jsonb_plperl";
    
    -- Extension hỗ trợ đa ngôn ngữ
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    
    -- Extension cho queue tác vụ nền
    CREATE EXTENSION IF NOT EXISTS "pg_background";

    -- Extension cho tính toán thống kê
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    
    -- Extension đặc biệt cho CDC
    CREATE EXTENSION IF NOT EXISTS "wal2json";
    
    -- Extension nén dữ liệu
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    
    -- Extension cho mục đích audit
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    
    -- Extension lập lịch tác vụ
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
END;
$$ LANGUAGE plpgsql;

-- Gọi function cài đặt extension
SELECT install_standard_extensions();

-- Tạo từ điển tìm kiếm tiếng Việt
CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION vietnamese
   ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;

\echo 'Đã cài đặt các extension cho database Bộ Tư pháp'

-- ============================================================================
-- 3. CÀI ĐẶT EXTENSION CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Cài đặt các extension cho database Máy chủ trung tâm...'
\connect national_citizen_central_server

-- Gọi lại function cài đặt extension dùng chung
CREATE OR REPLACE FUNCTION install_standard_extensions() RETURNS void AS $$
BEGIN
    -- UUID extension (tạo ID định danh duy nhất)
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- Mã hóa dữ liệu nhạy cảm
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    
    -- Tìm kiếm tương đối văn bản (fuzzy search) cho tên người, địa chỉ
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    
    -- Xử lý dữ liệu địa lý
    CREATE EXTENSION IF NOT EXISTS "postgis";
    CREATE EXTENSION IF NOT EXISTS "postgis_topology";
    
    -- Lưu trữ dữ liệu dạng key-value
    CREATE EXTENSION IF NOT EXISTS "hstore";
    
    -- Quản lý cấu trúc cây (phân cấp hành chính)
    CREATE EXTENSION IF NOT EXISTS "ltree";
    
    -- Giám sát hiệu suất truy vấn
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
    
    -- Tối ưu hóa bộ nhớ đệm
    CREATE EXTENSION IF NOT EXISTS "pg_buffercache";
    
    -- Full-text search nâng cao cho tiếng Việt
    CREATE EXTENSION IF NOT EXISTS "unaccent"; -- Loại bỏ dấu tiếng Việt khi tìm kiếm
    
    -- Phân vùng dữ liệu tự động
    CREATE EXTENSION IF NOT EXISTS "pg_partman";
    
    -- Các extension cho đồng bộ dữ liệu phân tán
    CREATE EXTENSION IF NOT EXISTS "postgres_fdw"; -- Truy cập dữ liệu từ xa
    CREATE EXTENSION IF NOT EXISTS "dblink"; -- Thực thi câu lệnh từ xa
    
    -- Extension cho JSON
    CREATE EXTENSION IF NOT EXISTS "jsonb_plperl";
    
    -- Extension hỗ trợ đa ngôn ngữ
    CREATE EXTENSION IF NOT EXISTS "plpgsql";
    
    -- Extension cho queue tác vụ nền
    CREATE EXTENSION IF NOT EXISTS "pg_background";

    -- Extension cho tính toán thống kê
    CREATE EXTENSION IF NOT EXISTS "tablefunc";
    
    -- Extension đặc biệt cho CDC
    CREATE EXTENSION IF NOT EXISTS "wal2json";
    
    -- Extension nén dữ liệu
    CREATE EXTENSION IF NOT EXISTS "pg_repack";
    
    -- Extension cho mục đích audit
    CREATE EXTENSION IF NOT EXISTS "pgaudit";
    
    -- Extension lập lịch tác vụ
    CREATE EXTENSION IF NOT EXISTS "pg_cron";
    
    -- Extensions bổ sung cho máy chủ trung tâm
    CREATE EXTENSION IF NOT EXISTS "pg_stat_monitor"; -- Giám sát nâng cao
    CREATE EXTENSION IF NOT EXISTS "pg_failover_slots"; -- Quản lý failover cho replication slots
    CREATE EXTENSION IF NOT EXISTS "timescaledb"; -- Xử lý dữ liệu chuỗi thời gian
END;
$$ LANGUAGE plpgsql;

-- Gọi function cài đặt extension
SELECT install_standard_extensions();

-- Tạo từ điển tìm kiếm tiếng Việt
CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION vietnamese
   ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;

\echo 'Đã cài đặt các extension cho database Máy chủ trung tâm'
\echo 'Đã hoàn thành việc cài đặt các extension cho toàn bộ hệ thống'
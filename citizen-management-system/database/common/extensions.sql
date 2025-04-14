-- Cài đặt các extension cần thiết cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Hàm cài đặt các extension tiêu chuẩn cho tất cả database
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
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT install_standard_extensions();
\echo 'Đã cài đặt extension cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT install_standard_extensions();
\echo 'Đã cài đặt extension cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT install_standard_extensions();
\echo 'Đã cài đặt extension cho database miền Nam'

-- Kết nối đến database trung tâm và cài đặt thêm extension đặc biệt
\connect national_citizen_central_server
SELECT install_standard_extensions();

-- Extension bổ sung dành riêng cho máy chủ trung tâm
CREATE EXTENSION IF NOT EXISTS "pg_repack"; -- Tối ưu hóa lưu trữ trong hệ thống lớn
CREATE EXTENSION IF NOT EXISTS "pgaudit"; -- Kiểm toán chi tiết cho máy chủ trung tâm
CREATE EXTENSION IF NOT EXISTS "pg_cron"; -- Lên lịch các tác vụ đồng bộ tự động

\echo 'Đã cài đặt extension cho database trung tâm'

-- Tạo từ điển tìm kiếm tiếng Việt trên tất cả các database
\connect national_citizen_north
-- Tạo từ điển tìm kiếm tiếng Việt với hỗ trợ bỏ dấu
CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION vietnamese
   ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;

\connect national_citizen_central
CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION vietnamese
   ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;

\connect national_citizen_south
CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION vietnamese
   ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;

\connect national_citizen_central_server
CREATE TEXT SEARCH CONFIGURATION vietnamese (COPY = simple);
ALTER TEXT SEARCH CONFIGURATION vietnamese
   ALTER MAPPING FOR hword, hword_part, word WITH unaccent, simple;

-- Xóa hàm tạm sau khi sử dụng xong


-- In ra thông báo hoàn thành
\echo 'Đã cài đặt xong các extension cho hệ thống quản lý dân cư quốc gia.'
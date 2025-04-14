
-- Tạo schema trên các database vùng miền

-- Kết nối đến database miền Bắc
\connect national_citizen_north

-- Hàm để tạo các schema giống nhau trên tất cả các database
CREATE OR REPLACE FUNCTION create_standard_schemas() RETURNS void AS $$
BEGIN
    -- Schema cho Bộ Công an
    CREATE SCHEMA IF NOT EXISTS public_security;
    COMMENT ON SCHEMA public_security IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Công an';
    
    -- Schema cho Bộ Tư pháp
    CREATE SCHEMA IF NOT EXISTS justice;
    COMMENT ON SCHEMA justice IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Tư pháp';
    
    -- Schema cho quản lý đơn vị hành chính
    CREATE SCHEMA IF NOT EXISTS administrative;
    COMMENT ON SCHEMA administrative IS 'Schema chứa các bảng quản lý đơn vị hành chính';
    
    -- Schema cho các bảng tham chiếu
    CREATE SCHEMA IF NOT EXISTS reference;
    COMMENT ON SCHEMA reference IS 'Schema chứa các bảng tham chiếu dùng chung';
    
    -- Schema cho đồng bộ dữ liệu
    CREATE SCHEMA IF NOT EXISTS sync;
    COMMENT ON SCHEMA sync IS 'Schema chứa các bảng và function đồng bộ dữ liệu';
    
    -- Schema cho audit và nhật ký hệ thống
    CREATE SCHEMA IF NOT EXISTS audit;
    COMMENT ON SCHEMA audit IS 'Schema chứa các bảng nhật ký hoạt động hệ thống';
    
    -- Schema cho các chức năng hệ thống
    CREATE SCHEMA IF NOT EXISTS system;
    COMMENT ON SCHEMA system IS 'Schema chứa các function và procedure hệ thống';
    
    -- Schema cho các API
    CREATE SCHEMA IF NOT EXISTS api;
    COMMENT ON SCHEMA api IS 'Schema chứa các function và view phục vụ API';
    
    -- Schema cho các báo cáo thống kê
    CREATE SCHEMA IF NOT EXISTS reports;
    COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo thống kê';
END;
$$ LANGUAGE plpgsql;

SELECT create_standard_schemas();

-- Phân quyền trên database miền Bắc
GRANT USAGE ON SCHEMA public_security TO citizen_north_admin;
GRANT USAGE ON SCHEMA justice TO citizen_north_admin;
GRANT USAGE ON SCHEMA administrative TO citizen_north_admin;
GRANT USAGE ON SCHEMA reference TO citizen_north_admin;
GRANT USAGE ON SCHEMA sync TO citizen_north_admin;
GRANT USAGE ON SCHEMA audit TO citizen_north_admin;
GRANT USAGE ON SCHEMA system TO citizen_north_admin;
GRANT USAGE ON SCHEMA api TO citizen_north_admin;
GRANT USAGE ON SCHEMA reports TO citizen_north_admin;

-- Cấp quyền đọc cho người dùng reader
GRANT USAGE ON SCHEMA public_security TO citizen_north_reader;
GRANT USAGE ON SCHEMA justice TO citizen_north_reader;
GRANT USAGE ON SCHEMA administrative TO citizen_north_reader;
GRANT USAGE ON SCHEMA reference TO citizen_north_reader;
GRANT USAGE ON SCHEMA api TO citizen_north_reader;
GRANT USAGE ON SCHEMA reports TO citizen_north_reader;

-- Kết nối đến database miền Trung
\connect national_citizen_central

-- Hàm để tạo các schema giống nhau trên tất cả các database
CREATE OR REPLACE FUNCTION create_standard_schemas() RETURNS void AS $$
BEGIN
    -- Schema cho Bộ Công an
    CREATE SCHEMA IF NOT EXISTS public_security;
    COMMENT ON SCHEMA public_security IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Công an';
    
    -- Schema cho Bộ Tư pháp
    CREATE SCHEMA IF NOT EXISTS justice;
    COMMENT ON SCHEMA justice IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Tư pháp';
    
    -- Schema cho quản lý đơn vị hành chính
    CREATE SCHEMA IF NOT EXISTS administrative;
    COMMENT ON SCHEMA administrative IS 'Schema chứa các bảng quản lý đơn vị hành chính';
    
    -- Schema cho các bảng tham chiếu
    CREATE SCHEMA IF NOT EXISTS reference;
    COMMENT ON SCHEMA reference IS 'Schema chứa các bảng tham chiếu dùng chung';
    
    -- Schema cho đồng bộ dữ liệu
    CREATE SCHEMA IF NOT EXISTS sync;
    COMMENT ON SCHEMA sync IS 'Schema chứa các bảng và function đồng bộ dữ liệu';
    
    -- Schema cho audit và nhật ký hệ thống
    CREATE SCHEMA IF NOT EXISTS audit;
    COMMENT ON SCHEMA audit IS 'Schema chứa các bảng nhật ký hoạt động hệ thống';
    
    -- Schema cho các chức năng hệ thống
    CREATE SCHEMA IF NOT EXISTS system;
    COMMENT ON SCHEMA system IS 'Schema chứa các function và procedure hệ thống';
    
    -- Schema cho các API
    CREATE SCHEMA IF NOT EXISTS api;
    COMMENT ON SCHEMA api IS 'Schema chứa các function và view phục vụ API';
    
    -- Schema cho các báo cáo thống kê
    CREATE SCHEMA IF NOT EXISTS reports;
    COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo thống kê';
END;
$$ LANGUAGE plpgsql;

SELECT create_standard_schemas();

-- Phân quyền trên database miền Trung
GRANT USAGE ON SCHEMA public_security TO citizen_central_admin;
GRANT USAGE ON SCHEMA justice TO citizen_central_admin;
GRANT USAGE ON SCHEMA administrative TO citizen_central_admin;
GRANT USAGE ON SCHEMA reference TO citizen_central_admin;
GRANT USAGE ON SCHEMA sync TO citizen_central_admin;
GRANT USAGE ON SCHEMA audit TO citizen_central_admin;
GRANT USAGE ON SCHEMA system TO citizen_central_admin;
GRANT USAGE ON SCHEMA api TO citizen_central_admin;
GRANT USAGE ON SCHEMA reports TO citizen_central_admin;

-- Cấp quyền đọc cho người dùng reader
GRANT USAGE ON SCHEMA public_security TO citizen_central_reader;
GRANT USAGE ON SCHEMA justice TO citizen_central_reader;
GRANT USAGE ON SCHEMA administrative TO citizen_central_reader;
GRANT USAGE ON SCHEMA reference TO citizen_central_reader;
GRANT USAGE ON SCHEMA api TO citizen_central_reader;
GRANT USAGE ON SCHEMA reports TO citizen_central_reader;

-- Kết nối đến database miền Nam
\connect national_citizen_south

-- Hàm để tạo các schema giống nhau trên tất cả các database
CREATE OR REPLACE FUNCTION create_standard_schemas() RETURNS void AS $$
BEGIN
    -- Schema cho Bộ Công an
    CREATE SCHEMA IF NOT EXISTS public_security;
    COMMENT ON SCHEMA public_security IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Công an';
    
    -- Schema cho Bộ Tư pháp
    CREATE SCHEMA IF NOT EXISTS justice;
    COMMENT ON SCHEMA justice IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Tư pháp';
    
    -- Schema cho quản lý đơn vị hành chính
    CREATE SCHEMA IF NOT EXISTS administrative;
    COMMENT ON SCHEMA administrative IS 'Schema chứa các bảng quản lý đơn vị hành chính';
    
    -- Schema cho các bảng tham chiếu
    CREATE SCHEMA IF NOT EXISTS reference;
    COMMENT ON SCHEMA reference IS 'Schema chứa các bảng tham chiếu dùng chung';
    
    -- Schema cho đồng bộ dữ liệu
    CREATE SCHEMA IF NOT EXISTS sync;
    COMMENT ON SCHEMA sync IS 'Schema chứa các bảng và function đồng bộ dữ liệu';
    
    -- Schema cho audit và nhật ký hệ thống
    CREATE SCHEMA IF NOT EXISTS audit;
    COMMENT ON SCHEMA audit IS 'Schema chứa các bảng nhật ký hoạt động hệ thống';
    
    -- Schema cho các chức năng hệ thống
    CREATE SCHEMA IF NOT EXISTS system;
    COMMENT ON SCHEMA system IS 'Schema chứa các function và procedure hệ thống';
    
    -- Schema cho các API
    CREATE SCHEMA IF NOT EXISTS api;
    COMMENT ON SCHEMA api IS 'Schema chứa các function và view phục vụ API';
    
    -- Schema cho các báo cáo thống kê
    CREATE SCHEMA IF NOT EXISTS reports;
    COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo thống kê';
END;
$$ LANGUAGE plpgsql;

SELECT create_standard_schemas();

-- Phân quyền trên database miền Nam
GRANT USAGE ON SCHEMA public_security TO citizen_south_admin;
GRANT USAGE ON SCHEMA justice TO citizen_south_admin;
GRANT USAGE ON SCHEMA administrative TO citizen_south_admin;
GRANT USAGE ON SCHEMA reference TO citizen_south_admin;
GRANT USAGE ON SCHEMA sync TO citizen_south_admin;
GRANT USAGE ON SCHEMA audit TO citizen_south_admin;
GRANT USAGE ON SCHEMA system TO citizen_south_admin;
GRANT USAGE ON SCHEMA api TO citizen_south_admin;
GRANT USAGE ON SCHEMA reports TO citizen_south_admin;

-- Cấp quyền đọc cho người dùng reader
GRANT USAGE ON SCHEMA public_security TO citizen_south_reader;
GRANT USAGE ON SCHEMA justice TO citizen_south_reader;
GRANT USAGE ON SCHEMA administrative TO citizen_south_reader;
GRANT USAGE ON SCHEMA reference TO citizen_south_reader;
GRANT USAGE ON SCHEMA api TO citizen_south_reader;
GRANT USAGE ON SCHEMA reports TO citizen_south_reader;

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm để tạo các schema giống nhau trên tất cả các database
CREATE OR REPLACE FUNCTION create_standard_schemas() RETURNS void AS $$
BEGIN
    -- Schema cho Bộ Công an
    CREATE SCHEMA IF NOT EXISTS public_security;
    COMMENT ON SCHEMA public_security IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Công an';
    
    -- Schema cho Bộ Tư pháp
    CREATE SCHEMA IF NOT EXISTS justice;
    COMMENT ON SCHEMA justice IS 'Schema chứa các bảng dữ liệu quản lý của Bộ Tư pháp';
    
    -- Schema cho quản lý đơn vị hành chính
    CREATE SCHEMA IF NOT EXISTS administrative;
    COMMENT ON SCHEMA administrative IS 'Schema chứa các bảng quản lý đơn vị hành chính';
    
    -- Schema cho các bảng tham chiếu
    CREATE SCHEMA IF NOT EXISTS reference;
    COMMENT ON SCHEMA reference IS 'Schema chứa các bảng tham chiếu dùng chung';
    
    -- Schema cho đồng bộ dữ liệu
    CREATE SCHEMA IF NOT EXISTS sync;
    COMMENT ON SCHEMA sync IS 'Schema chứa các bảng và function đồng bộ dữ liệu';
    
    -- Schema cho audit và nhật ký hệ thống
    CREATE SCHEMA IF NOT EXISTS audit;
    COMMENT ON SCHEMA audit IS 'Schema chứa các bảng nhật ký hoạt động hệ thống';
    
    -- Schema cho các chức năng hệ thống
    CREATE SCHEMA IF NOT EXISTS system;
    COMMENT ON SCHEMA system IS 'Schema chứa các function và procedure hệ thống';
    
    -- Schema cho các API
    CREATE SCHEMA IF NOT EXISTS api;
    COMMENT ON SCHEMA api IS 'Schema chứa các function và view phục vụ API';
    
    -- Schema cho các báo cáo thống kê
    CREATE SCHEMA IF NOT EXISTS reports;
    COMMENT ON SCHEMA reports IS 'Schema chứa các view và function phục vụ báo cáo thống kê';
END;
$$ LANGUAGE plpgsql;

SELECT create_standard_schemas();

-- Tạo thêm schema đặc biệt cho máy chủ trung tâm
CREATE SCHEMA IF NOT EXISTS central_sync;
COMMENT ON SCHEMA central_sync IS 'Schema chứa các bảng và function đồng bộ trung tâm';

CREATE SCHEMA IF NOT EXISTS central_management;
COMMENT ON SCHEMA central_management IS 'Schema chứa các bảng và function quản lý hệ thống trung tâm';

-- Phân quyền trên database trung tâm
GRANT USAGE ON SCHEMA public_security TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA justice TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA administrative TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA reference TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA sync TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA audit TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA system TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA api TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA reports TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA central_sync TO citizen_central_server_admin;
GRANT USAGE ON SCHEMA central_management TO citizen_central_server_admin;

-- Cấp quyền đọc cho người dùng reader
GRANT USAGE ON SCHEMA public_security TO citizen_central_server_reader;
GRANT USAGE ON SCHEMA justice TO citizen_central_server_reader;
GRANT USAGE ON SCHEMA administrative TO citizen_central_server_reader;
GRANT USAGE ON SCHEMA reference TO citizen_central_server_reader;
GRANT USAGE ON SCHEMA api TO citizen_central_server_reader;
GRANT USAGE ON SCHEMA reports TO citizen_central_server_reader;

-- Xóa hàm tạm sau khi đã sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong các schema cho hệ thống quản lý dân cư quốc gia.'
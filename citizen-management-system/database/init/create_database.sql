-- Kết nối đến PostgreSQL 
\connect postgres

-- Xóa database cũ nếu tồn tại
DROP DATABASE IF EXISTS national_citizen_north;
DROP DATABASE IF EXISTS national_citizen_central;
DROP DATABASE IF EXISTS national_citizen_south;
DROP DATABASE IF EXISTS national_citizen_central_server;

-- Tạo các database riêng biệt cho từng vùng miền
-- Miền Bắc
CREATE DATABASE national_citizen_north
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE national_citizen_north IS 'CSDL quản lý dân cư vùng miền Bắc';

-- Miền Trung
CREATE DATABASE national_citizen_central
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE national_citizen_central IS 'CSDL quản lý dân cư vùng miền Trung';

-- Miền Nam
CREATE DATABASE national_citizen_south
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE national_citizen_south IS 'CSDL quản lý dân cư vùng miền Nam';

-- Máy chủ trung tâm quốc gia
CREATE DATABASE national_citizen_central_server
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

COMMENT ON DATABASE national_citizen_central_server IS 'CSDL trung tâm quản lý dân cư quốc gia';

-- Tạo các người dùng riêng biệt cho từng vùng miền
CREATE USER citizen_north_admin WITH ENCRYPTED PASSWORD 'SecureNorth#2025';
CREATE USER citizen_central_admin WITH ENCRYPTED PASSWORD 'SecureCentral#2025';
CREATE USER citizen_south_admin WITH ENCRYPTED PASSWORD 'SecureSouth#2025';
CREATE USER citizen_central_server_admin WITH ENCRYPTED PASSWORD 'SecureCentralServer#2025';

-- Cấp quyền cho các người dùng trên các database tương ứng
GRANT ALL PRIVILEGES ON DATABASE national_citizen_north TO citizen_north_admin;
GRANT ALL PRIVILEGES ON DATABASE national_citizen_central TO citizen_central_admin;
GRANT ALL PRIVILEGES ON DATABASE national_citizen_south TO citizen_south_admin;
GRANT ALL PRIVILEGES ON DATABASE national_citizen_central_server TO citizen_central_server_admin;

-- Tạo các người dùng chỉ được phép đọc
CREATE USER citizen_north_reader WITH ENCRYPTED PASSWORD 'ReadOnlyNorth#2025';
CREATE USER citizen_central_reader WITH ENCRYPTED PASSWORD 'ReadOnlyCentral#2025';
CREATE USER citizen_south_reader WITH ENCRYPTED PASSWORD 'ReadOnlySouth#2025';
CREATE USER citizen_central_server_reader WITH ENCRYPTED PASSWORD 'ReadOnlyCentralServer#2025';

-- Cấp quyền đọc cho các người dùng reader
GRANT CONNECT ON DATABASE national_citizen_north TO citizen_north_reader;
GRANT CONNECT ON DATABASE national_citizen_central TO citizen_central_reader;
GRANT CONNECT ON DATABASE national_citizen_south TO citizen_south_reader;
GRANT CONNECT ON DATABASE national_citizen_central_server TO citizen_central_server_reader;

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong các database và người dùng cho hệ thống quản lý dân cư quốc gia.'
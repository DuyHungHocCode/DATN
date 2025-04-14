-- Tạo bảng CitizenMovement (Di chuyển công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng CitizenMovement cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng CitizenMovement
CREATE OR REPLACE FUNCTION create_citizen_movement_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenMovement trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_movement (
        movement_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        movement_type movement_type NOT NULL,
        from_address_id INT,
        to_address_id INT,
        departure_date DATE NOT NULL,
        arrival_date DATE,
        purpose TEXT,
        document_no VARCHAR(50),
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng CitizenMovement
CREATE OR REPLACE FUNCTION create_citizen_movement_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenMovement trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_movement (
        movement_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        movement_type movement_type NOT NULL,
        from_address_id INT,
        to_address_id INT,
        departure_date DATE NOT NULL,
        arrival_date DATE,
        purpose TEXT,
        document_no VARCHAR(50),
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng CitizenMovement
CREATE OR REPLACE FUNCTION create_citizen_movement_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenMovement trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_movement (
        movement_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        movement_type movement_type NOT NULL,
        from_address_id INT,
        to_address_id INT,
        departure_date DATE NOT NULL,
        arrival_date DATE,
        purpose TEXT,
        document_no VARCHAR(50),
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng CitizenMovement
CREATE OR REPLACE FUNCTION create_citizen_movement_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng CitizenMovement trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen_movement (
        movement_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL,
        movement_type movement_type NOT NULL,
        from_address_id INT,
        to_address_id INT,
        departure_date DATE NOT NULL,
        arrival_date DATE,
        purpose TEXT,
        document_no VARCHAR(50),
        description TEXT,
        status BOOLEAN DEFAULT TRUE,
        source_region_id SMALLINT,
        target_region_id SMALLINT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_citizen_movement_table();
\echo 'Đã tạo bảng CitizenMovement cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng CitizenMovement cho tất cả các database.'
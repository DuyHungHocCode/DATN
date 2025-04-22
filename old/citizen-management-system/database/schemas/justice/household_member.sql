-- Tạo bảng HouseholdMember (Thành viên hộ khẩu) cho hệ thống CSDL phân tán quản lý dân cư quốc gia
-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng HouseholdMember cho các database vùng miền...'



-- Kết nối đến database miền Bắc
\connect national_citizen_north
-- Hàm tạo bảng HouseholdMember
CREATE OR REPLACE FUNCTION create_household_member_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng HouseholdMember trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household_member (
        household_member_id SERIAL PRIMARY KEY,
        household_id INT NOT NULL,
        citizen_id VARCHAR(12) NOT NULL,
        relationship_with_head household_relationship NOT NULL,
        join_date DATE NOT NULL,
        leave_date DATE,
        leave_reason TEXT,
        previous_household_id INT,
        status BOOLEAN DEFAULT TRUE,
        order_in_household SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
-- Hàm tạo bảng HouseholdMember
CREATE OR REPLACE FUNCTION create_household_member_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng HouseholdMember trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household_member (
        household_member_id SERIAL PRIMARY KEY,
        household_id INT NOT NULL,
        citizen_id VARCHAR(12) NOT NULL,
        relationship_with_head household_relationship NOT NULL,
        join_date DATE NOT NULL,
        leave_date DATE,
        leave_reason TEXT,
        previous_household_id INT,
        status BOOLEAN DEFAULT TRUE,
        order_in_household SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
-- Hàm tạo bảng HouseholdMember
CREATE OR REPLACE FUNCTION create_household_member_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng HouseholdMember trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household_member (
        household_member_id SERIAL PRIMARY KEY,
        household_id INT NOT NULL,
        citizen_id VARCHAR(12) NOT NULL,
        relationship_with_head household_relationship NOT NULL,
        join_date DATE NOT NULL,
        leave_date DATE,
        leave_reason TEXT,
        previous_household_id INT,
        status BOOLEAN DEFAULT TRUE,
        order_in_household SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
-- Hàm tạo bảng HouseholdMember
CREATE OR REPLACE FUNCTION create_household_member_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng HouseholdMember trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household_member (
        household_member_id SERIAL PRIMARY KEY,
        household_id INT NOT NULL,
        citizen_id VARCHAR(12) NOT NULL,
        relationship_with_head household_relationship NOT NULL,
        join_date DATE NOT NULL,
        leave_date DATE,
        leave_reason TEXT,
        previous_household_id INT,
        status BOOLEAN DEFAULT TRUE,
        order_in_household SMALLINT,
        region_id SMALLINT,
        province_id INT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng HouseholdMember cho tất cả các database.'
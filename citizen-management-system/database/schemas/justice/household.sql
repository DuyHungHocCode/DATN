-- Tạo bảng Household (Hộ khẩu) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng Household cho các database vùng miền...'

-- Hàm tạo bảng Household
CREATE OR REPLACE FUNCTION create_household_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Household trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household (
        household_id SERIAL PRIMARY KEY,
        household_book_no VARCHAR(20) NOT NULL UNIQUE,
        head_of_household_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        address_id INT NOT NULL REFERENCES public_security.address(address_id),
        registration_date DATE NOT NULL,
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        area_code VARCHAR(10),
        household_type VARCHAR(50) NOT NULL, -- X Thường trú/Tạm trú tham chieu den bang trong enum
        status BOOLEAN DEFAULT TRUE,
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE justice.household IS 'Bảng lưu trữ thông tin hộ khẩu';
    COMMENT ON COLUMN justice.household.household_id IS 'Mã hộ khẩu';
    COMMENT ON COLUMN justice.household.household_book_no IS 'Số sổ hộ khẩu';
    COMMENT ON COLUMN justice.household.head_of_household_id IS 'Mã định danh chủ hộ';
    COMMENT ON COLUMN justice.household.address_id IS 'Mã địa chỉ';
    COMMENT ON COLUMN justice.household.registration_date IS 'Ngày đăng ký';
    COMMENT ON COLUMN justice.household.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN justice.household.area_code IS 'Mã khu vực';
    COMMENT ON COLUMN justice.household.household_type IS 'Loại hộ khẩu (Thường trú/Tạm trú)';
    COMMENT ON COLUMN justice.household.status IS 'Trạng thái hoạt động của hộ khẩu';
    COMMENT ON COLUMN justice.household.notes IS 'Ghi chú';
    COMMENT ON COLUMN justice.household.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.household.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.household.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.household.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_household_table();
\echo 'Đã tạo bảng Household cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_household_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng Household cho tất cả các database.'
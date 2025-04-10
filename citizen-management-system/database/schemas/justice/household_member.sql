
-- Tạo bảng HouseholdMember (Thành viên hộ khẩu) cho hệ thống CSDL phân tán quản lý dân cư quốc gia


-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng HouseholdMember cho các database vùng miền...'

-- Hàm tạo bảng HouseholdMember
CREATE OR REPLACE FUNCTION create_household_member_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng HouseholdMember trong schema justice
    CREATE TABLE IF NOT EXISTS justice.household_member (
        household_member_id SERIAL PRIMARY KEY,
        household_id INT NOT NULL REFERENCES justice.household(household_id),
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        relationship_with_head household_relationship NOT NULL,
        join_date DATE NOT NULL,
        leave_date DATE,
        leave_reason TEXT,
        previous_household_id INT REFERENCES justice.household(household_id),
        status BOOLEAN DEFAULT TRUE,
        order_in_household SMALLINT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE justice.household_member IS 'Bảng lưu trữ thông tin thành viên hộ khẩu';
    COMMENT ON COLUMN justice.household_member.household_member_id IS 'Mã thành viên hộ khẩu';
    COMMENT ON COLUMN justice.household_member.household_id IS 'Mã hộ khẩu';
    COMMENT ON COLUMN justice.household_member.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN justice.household_member.relationship_with_head IS 'Quan hệ với chủ hộ';
    COMMENT ON COLUMN justice.household_member.join_date IS 'Ngày vào hộ khẩu';
    COMMENT ON COLUMN justice.household_member.leave_date IS 'Ngày rời hộ khẩu';
    COMMENT ON COLUMN justice.household_member.leave_reason IS 'Lý do rời hộ khẩu';
    COMMENT ON COLUMN justice.household_member.previous_household_id IS 'Mã hộ khẩu trước đó';
    COMMENT ON COLUMN justice.household_member.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN justice.household_member.order_in_household IS 'Thứ tự trong hộ khẩu';
    COMMENT ON COLUMN justice.household_member.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN justice.household_member.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN justice.household_member.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN justice.household_member.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_household_member_table();
\echo 'Đã tạo bảng HouseholdMember cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_household_member_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng HouseholdMember cho tất cả các database.'
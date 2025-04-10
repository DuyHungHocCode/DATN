-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng UserAccount cho các database vùng miền...'

-- Hàm tạo bảng UserAccount
CREATE OR REPLACE FUNCTION create_user_account_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng UserAccount trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.user_account (
        user_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        user_type user_type NOT NULL,
        role_id SMALLINT REFERENCES reference.user_role(role_id),
        status BOOLEAN DEFAULT TRUE,
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        two_factor_enabled BOOLEAN DEFAULT FALSE,
        locked_until TIMESTAMP WITH TIME ZONE,
        failed_login_attempts SMALLINT DEFAULT 0,
        password_change_required BOOLEAN DEFAULT FALSE,
        last_password_change TIMESTAMP WITH TIME ZONE,
        email VARCHAR(100),
        phone_number VARCHAR(15),
        agency_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE public_security.user_account IS 'Bảng lưu trữ thông tin tài khoản người dùng';
    COMMENT ON COLUMN public_security.user_account.user_id IS 'Mã người dùng';
    COMMENT ON COLUMN public_security.user_account.citizen_id IS 'Mã định danh công dân (nếu là tài khoản công dân)';
    COMMENT ON COLUMN public_security.user_account.username IS 'Tên đăng nhập';
    COMMENT ON COLUMN public_security.user_account.password_hash IS 'Mã băm mật khẩu';
    COMMENT ON COLUMN public_security.user_account.user_type IS 'Loại người dùng (Công dân/Cán bộ/Quản trị viên)';
    COMMENT ON COLUMN public_security.user_account.role_id IS 'Mã vai trò người dùng';
    COMMENT ON COLUMN public_security.user_account.status IS 'Trạng thái hoạt động của tài khoản';
    COMMENT ON COLUMN public_security.user_account.last_login_date IS 'Ngày đăng nhập cuối';
    COMMENT ON COLUMN public_security.user_account.last_login_ip IS 'IP đăng nhập cuối';
    COMMENT ON COLUMN public_security.user_account.two_factor_enabled IS 'Bật xác thực 2 lớp';
    COMMENT ON COLUMN public_security.user_account.locked_until IS 'Khóa đến ngày';
    COMMENT ON COLUMN public_security.user_account.failed_login_attempts IS 'Số lần đăng nhập thất bại';
    COMMENT ON COLUMN public_security.user_account.password_change_required IS 'Yêu cầu đổi mật khẩu';
    COMMENT ON COLUMN public_security.user_account.last_password_change IS 'Lần thay đổi mật khẩu cuối';
    COMMENT ON COLUMN public_security.user_account.email IS 'Email';
    COMMENT ON COLUMN public_security.user_account.phone_number IS 'Số điện thoại';
    COMMENT ON COLUMN public_security.user_account.agency_id IS 'Mã cơ quan';
    COMMENT ON COLUMN public_security.user_account.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN public_security.user_account.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN public_security.user_account.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.user_account.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_user_account_table();
\echo 'Đã tạo bảng UserAccount cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_user_account_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng UserAccount cho tất cả các database.'
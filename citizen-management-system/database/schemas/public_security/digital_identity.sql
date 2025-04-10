-- Tạo bảng DigitalIdentity (Định danh điện tử) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng DigitalIdentity cho các database vùng miền...'

-- Hàm tạo bảng DigitalIdentity
CREATE OR REPLACE FUNCTION create_digital_identity_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng DigitalIdentity trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.digital_identity (
        digital_identity_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        digital_id VARCHAR(50) NOT NULL UNIQUE, -- Mã định danh điện tử 
        activation_date TIMESTAMP WITH TIME ZONE NOT NULL,
        verification_level verification_level NOT NULL,
        status BOOLEAN DEFAULT TRUE,
        device_info TEXT, -- Thông tin thiết bị
        last_login_date TIMESTAMP WITH TIME ZONE,
        last_login_ip VARCHAR(45), -- Hỗ trợ cả IPv6
        otp_method VARCHAR(50), -- Phương thức OTP
        phone_number VARCHAR(15),
        email VARCHAR(100),
        security_question TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE public_security.digital_identity IS 'Bảng lưu trữ thông tin định danh điện tử của công dân';
    COMMENT ON COLUMN public_security.digital_identity.digital_identity_id IS 'Mã định danh điện tử';
    COMMENT ON COLUMN public_security.digital_identity.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN public_security.digital_identity.digital_id IS 'Mã định danh điện tử VNeID';
    COMMENT ON COLUMN public_security.digital_identity.activation_date IS 'Ngày kích hoạt';
    COMMENT ON COLUMN public_security.digital_identity.verification_level IS 'Mức xác thực (Mức 1/Mức 2)';
    COMMENT ON COLUMN public_security.digital_identity.status IS 'Trạng thái hoạt động của tài khoản';
    COMMENT ON COLUMN public_security.digital_identity.device_info IS 'Thông tin thiết bị';
    COMMENT ON COLUMN public_security.digital_identity.last_login_date IS 'Ngày đăng nhập cuối';
    COMMENT ON COLUMN public_security.digital_identity.last_login_ip IS 'IP đăng nhập cuối';
    COMMENT ON COLUMN public_security.digital_identity.otp_method IS 'Phương thức OTP';
    COMMENT ON COLUMN public_security.digital_identity.phone_number IS 'Số điện thoại';
    COMMENT ON COLUMN public_security.digital_identity.email IS 'Email';
    COMMENT ON COLUMN public_security.digital_identity.security_question IS 'Câu hỏi bảo mật';
    COMMENT ON COLUMN public_security.digital_identity.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.digital_identity.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_digital_identity_table();
\echo 'Đã tạo bảng DigitalIdentity cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_digital_identity_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng DigitalIdentity cho tất cả các database.'
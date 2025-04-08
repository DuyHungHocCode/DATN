
-- Định nghĩa các kiểu dữ liệu enum cho hệ thống CSDL phân tán quản lý dân cư quốc gia


-- Hàm kiểm tra kết nối đến tất cả các database và tạo enums
CREATE OR REPLACE FUNCTION create_standard_enums() RETURNS void AS $$
BEGIN
    -- Giới tính
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender_type') THEN
        CREATE TYPE gender_type AS ENUM ('Nam', 'Nữ', 'Khác');
    END IF;
    
    -- Nhóm máu
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'blood_type') THEN
        CREATE TYPE blood_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Không xác định');
    END IF;
    
    -- Trạng thái sống/mất
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'death_status') THEN
        CREATE TYPE death_status AS ENUM ('Còn sống', 'Đã mất', 'Mất tích');
    END IF;
    
    -- Tình trạng hôn nhân
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marital_status') THEN
        CREATE TYPE marital_status AS ENUM ('Độc thân', 'Đã kết hôn', 'Đã ly hôn', 'Góa', 'Ly thân');
    END IF;
    
    -- Loại thẻ CCCD
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'card_type') THEN
        CREATE TYPE card_type AS ENUM ('CMND 9 số', 'CMND 12 số', 'CCCD', 'CCCD gắn chip');
    END IF;
    
    -- Trạng thái CCCD
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'card_status') THEN
        CREATE TYPE card_status AS ENUM ('Đang sử dụng', 'Hết hạn', 'Mất', 'Hỏng', 'Thu hồi', 'Đã thay thế');
    END IF;
    
    -- Loại sinh trắc học
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'biometric_type') THEN
        CREATE TYPE biometric_type AS ENUM ('Vân tay', 'Khuôn mặt', 'Mống mắt', 'Giọng nói');
    END IF;
    
    -- Loại địa chỉ
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'address_type') THEN
        CREATE TYPE address_type AS ENUM ('Thường trú', 'Tạm trú', 'Nơi ở hiện tại', 'Công ty', 'Khác');
    END IF;
    
    -- Loại thay đổi
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'change_type') THEN
        CREATE TYPE change_type AS ENUM ('Thêm mới', 'Cập nhật', 'Xóa', 'Vô hiệu hóa', 'Khôi phục');
    END IF;
    
    -- Trạng thái đồng bộ
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sync_status') THEN
        CREATE TYPE sync_status AS ENUM ('Chưa đồng bộ', 'Đang đồng bộ', 'Đã đồng bộ', 'Lỗi đồng bộ', 'Xung đột');
    END IF;
    
    -- Loại di chuyển
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'movement_type') THEN
        CREATE TYPE movement_type AS ENUM ('Trong nước', 'Xuất cảnh', 'Nhập cảnh', 'Tái nhập cảnh');
    END IF;
    
    -- Mức xác thực định danh điện tử
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_level') THEN
        CREATE TYPE verification_level AS ENUM ('Mức 1', 'Mức 2');
    END IF;
    
    -- Loại người dùng
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type') THEN
        CREATE TYPE user_type AS ENUM ('Công dân', 'Cán bộ', 'Quản trị viên');
    END IF;
    
    -- Quan hệ với chủ hộ
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'household_relationship') THEN
        CREATE TYPE household_relationship AS ENUM (
            'Chủ hộ', 'Vợ', 'Chồng', 'Con', 'Bố', 'Mẹ', 'Ông', 'Bà', 
            'Anh', 'Chị', 'Em', 'Cháu', 'Chắt', 'Cô', 'Dì', 'Chú', 'Bác', 
            'Người giám hộ', 'Họ hàng khác', 'Không có quan hệ họ hàng'
        );
    END IF;
    
    -- Loại biến động dân cư
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'population_change_type') THEN
        CREATE TYPE population_change_type AS ENUM (
            'Sinh', 'Tử', 'Chuyển đến', 'Chuyển đi', 
            'Thay đổi HKTT', 'Kết hôn', 'Ly hôn', 
            'Thay đổi thông tin cá nhân', 'Khác'
        );
    END IF;
    
    -- Loại quan hệ gia đình
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'family_relationship_type') THEN
        CREATE TYPE family_relationship_type AS ENUM (
            'Vợ-Chồng', 'Cha-Con', 'Mẹ-Con', 'Ông-Cháu', 'Bà-Cháu',
            'Anh-Em', 'Chị-Em', 'Cô-Cháu', 'Dì-Cháu', 'Chú-Cháu', 'Bác-Cháu',
            'Giám hộ', 'Họ hàng khác'
        );
    END IF;
    
    -- Loại giám hộ
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guardianship_type') THEN
        CREATE TYPE guardianship_type AS ENUM (
            'Người chưa thành niên', 'Người mất năng lực hành vi'
        );
    END IF;
    
    -- Loại thao tác truy cập
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'access_type') THEN
        CREATE TYPE access_type AS ENUM ('Đọc', 'Ghi', 'Xóa', 'Cập nhật', 'Truy vấn đặc biệt');
    END IF;
    
    -- Loại thay đổi quốc tịch
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'nationality_change_type') THEN
        CREATE TYPE nationality_change_type AS ENUM ('Nhập quốc tịch', 'Thôi quốc tịch', 'Trở lại quốc tịch');
    END IF;
    
    -- Loại nhận cha/mẹ/con
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'recognition_type') THEN
        CREATE TYPE recognition_type AS ENUM ('Cha nhận con', 'Con nhận cha', 'Mẹ nhận con', 'Con nhận mẹ');
    END IF;
    
    -- Loại đơn vị hành chính
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'division_type') THEN
        CREATE TYPE division_type AS ENUM ('Tỉnh', 'Thành phố trực thuộc TW', 'Quận', 'Huyện', 'Thị xã', 'Thành phố thuộc tỉnh', 'Phường', 'Xã', 'Thị trấn');
    END IF;
    
    -- Loại thay đổi đơn vị hành chính
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_change_type') THEN
        CREATE TYPE admin_change_type AS ENUM ('Tách', 'Nhập', 'Đổi tên', 'Điều chỉnh địa giới');
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_standard_enums();
\echo 'Đã tạo xong enums cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_standard_enums();
\echo 'Đã tạo xong enums cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_standard_enums();
\echo 'Đã tạo xong enums cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_standard_enums();
\echo 'Đã tạo xong enums cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_standard_enums();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong tất cả các kiểu dữ liệu enum cho hệ thống quản lý dân cư quốc gia.'
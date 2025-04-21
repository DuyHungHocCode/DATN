-- File: ministry_of_public_security/schemas/public_security/digital_identity.sql
-- Description: Tạo bảng digital_identity (Định danh điện tử - VNeID)
--              trong schema public_security của database ministry_of_public_security.
-- Version: 3.0 (Aligned with Microservices Structure)
-- =============================================================================

\echo '--> Tạo bảng public_security.digital_identity (Định danh Điện tử)...'
\connect ministry_of_public_security

BEGIN;

-- Xóa bảng cũ nếu tồn tại để tạo lại
DROP TABLE IF EXISTS public_security.digital_identity CASCADE;

-- Tạo bảng digital_identity
-- Lưu ý: Bảng này hiện tại không được thiết kế để phân vùng theo địa lý.
CREATE TABLE public_security.digital_identity (
    digital_identity_id SERIAL PRIMARY KEY,              -- ID tự tăng, khóa chính
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân sở hữu định danh (FK logic tới public_security.citizen)
    digital_id VARCHAR(50) NOT NULL,                     -- Mã định danh điện tử duy nhất (VNeID)
    activation_date TIMESTAMP WITH TIME ZONE NOT NULL,   -- Ngày/giờ kích hoạt tài khoản
    verification_level verification_level NOT NULL,      -- Mức độ xác thực định danh (ENUM: Mức 1, Mức 2)
    status BOOLEAN NOT NULL DEFAULT TRUE,                -- Trạng thái định danh (TRUE = Đang hoạt động, FALSE = Đã hủy/khóa vĩnh viễn)
    device_info JSONB,                                   -- Thông tin thiết bị đã đăng ký/đăng nhập gần nhất (dạng JSONB, vd: { "os": "Android 13", "model": "Pixel 7", "app_version": "2.1.0", "last_seen": "..." })
    last_login_date TIMESTAMP WITH TIME ZONE,            -- Thời điểm đăng nhập thành công lần cuối
    last_login_ip VARCHAR(45),                           -- Địa chỉ IP đăng nhập lần cuối (Hỗ trợ IPv6)
    otp_method VARCHAR(50) DEFAULT 'SMS',                -- Phương thức OTP đang sử dụng (SMS, Email, SmartOTP App...)
    phone_number VARCHAR(15),                            -- Số điện thoại liên kết (thường dùng cho OTP, cần được xác thực)
    email VARCHAR(100),                                  -- Email liên kết (thường dùng cho thông báo/OTP, cần được xác thực)
    security_question_hash TEXT,                         -- Hash của câu trả lời cho câu hỏi bảo mật (Không lưu plain text!)

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by VARCHAR(50),                              -- User/Service tạo bản ghi
    updated_by VARCHAR(50),                              -- User/Service cập nhật lần cuối

    -- Ràng buộc Khóa ngoại (Intra-database)
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng về hiệu năng và cách hoạt động.
    CONSTRAINT fk_digital_identity_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Nếu xóa công dân thì xóa luôn định danh điện tử

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_digital_identity_digital_id UNIQUE (digital_id), -- Mã định danh điện tử là duy nhất

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_digital_id_phone_format CHECK (phone_number IS NULL OR phone_number ~ '^\+?[0-9]{10,14}$'), -- Kiểm tra định dạng SĐT cơ bản
    CONSTRAINT ck_digital_id_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'), -- Kiểm tra định dạng email cơ bản
    CONSTRAINT ck_digital_id_format CHECK (digital_id ~ '^[A-Za-z0-9.-]+$'), -- Kiểm tra định dạng mã định danh (có thể cần điều chỉnh)
    CONSTRAINT ck_digital_id_activation_date CHECK (activation_date <= CURRENT_TIMESTAMP) -- Ngày kích hoạt không thể ở tương lai
);

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE public_security.digital_identity IS '[BCA] Lưu trữ thông tin về tài khoản định danh điện tử (VNeID) của công dân.';
COMMENT ON COLUMN public_security.digital_identity.digital_identity_id IS 'ID tự tăng, khóa chính của bảng.';
COMMENT ON COLUMN public_security.digital_identity.citizen_id IS 'Số CCCD/ĐDCN 12 số của công dân sở hữu tài khoản.';
COMMENT ON COLUMN public_security.digital_identity.digital_id IS 'Mã định danh điện tử duy nhất do hệ thống VNeID cấp.';
COMMENT ON COLUMN public_security.digital_identity.verification_level IS 'Mức độ xác thực tài khoản (Mức 1, Mức 2) theo quy định.';
COMMENT ON COLUMN public_security.digital_identity.status IS 'Trạng thái hoạt động của tài khoản (TRUE: Active, FALSE: Inactive/Revoked).';
COMMENT ON COLUMN public_security.digital_identity.device_info IS 'Thông tin (dạng JSONB) về thiết bị liên kết/đăng nhập cuối.';
COMMENT ON COLUMN public_security.digital_identity.security_question_hash IS 'Hash (vd: bcrypt, Argon2) của câu trả lời bảo mật, không lưu dạng rõ.';

-- Indexes
-- Index trên khóa chính (digital_identity_id) và khóa unique (digital_id) được tạo tự động.
CREATE INDEX IF NOT EXISTS idx_digital_identity_citizen_id ON public_security.digital_identity(citizen_id); -- Tìm theo công dân
CREATE INDEX IF NOT EXISTS idx_digital_identity_phone ON public_security.digital_identity(phone_number) WHERE phone_number IS NOT NULL; -- Tìm theo SĐT (Partial index)
CREATE INDEX IF NOT EXISTS idx_digital_identity_email ON public_security.digital_identity(email) WHERE email IS NOT NULL; -- Tìm theo Email (Partial index)
CREATE INDEX IF NOT EXISTS idx_digital_identity_status ON public_security.digital_identity(status); -- Lọc theo trạng thái
CREATE INDEX IF NOT EXISTS idx_digital_identity_last_login ON public_security.digital_identity(last_login_date DESC NULLS LAST); -- Tìm login gần nhất

-- Chỉ mục unique đảm bảo mỗi công dân chỉ có một định danh điện tử đang hoạt động (status = TRUE)
-- Cần kiểm tra kỹ lưỡng trong môi trường có dữ liệu lớn.
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_digital_id_per_citizen
    ON public_security.digital_identity (citizen_id)
    WHERE status = TRUE;

COMMIT;

\echo '    - Đã tạo bảng public_security.digital_identity.'

-- TODO (Cần thực hiện ở tầng ứng dụng hoặc các script khác):
-- 1. Triggers: Cân nhắc trigger cập nhật `updated_at` tự động.
-- 2. Audit Log: Thiết lập trigger audit cho bảng này (sử dụng hàm `audit.if_modified_func`).
-- 3. Security: Triển khai Row-Level Security (RLS) nếu cần thiết để giới hạn quyền truy cập dữ liệu.
-- 4. Hashing: Logic hash và xác thực `security_question_hash` cần thực hiện ở tầng ứng dụng (App BCA).
-- 5. Data Validation: Quy tắc validate chi tiết cho `device_info` (có thể dùng JSON Schema validation).
-- 6. Partitioning FK Check: Xác nhận khóa ngoại `fk_digital_identity_citizen` hoạt động đúng với bảng `citizen` đã phân vùng.
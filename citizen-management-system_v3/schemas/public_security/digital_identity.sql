-- =============================================================================
-- File: database/schemas/public_security/digital_identity.sql
-- Description: Creates the digital_identity table (Định danh điện tử - VNeID)
--              in the public_security schema.
-- Version: 2.0 (Integrated constraints, indexes, removed comments)
-- =============================================================================

\echo 'Creating digital_identity table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.digital_identity CASCADE;

-- Create the digital_identity table
-- Lưu ý: Bảng này hiện tại không được thiết kế để phân vùng theo địa lý.
-- Cân nhắc phân vùng nếu số lượng bản ghi cực lớn và truy vấn thường theo vùng/tỉnh.
CREATE TABLE public_security.digital_identity (
    digital_identity_id SERIAL NOT NULL,                 -- ID tự tăng
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân sở hữu định danh (FK public_security.citizen)
    digital_id VARCHAR(50) NOT NULL,                     -- Mã định danh điện tử (VNeID, Unique)
    activation_date TIMESTAMP WITH TIME ZONE NOT NULL,   -- Ngày kích hoạt tài khoản
    verification_level verification_level NOT NULL,      -- Mức độ xác thực định danh (ENUM: Mức 1, Mức 2)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái định danh (TRUE = Active/Current)
    device_info JSONB,                                   -- Thông tin thiết bị đã đăng ký/đăng nhập (dạng JSONB)
    last_login_date TIMESTAMP WITH TIME ZONE,            -- Thời điểm đăng nhập thành công lần cuối
    last_login_ip VARCHAR(45),                           -- Địa chỉ IP đăng nhập lần cuối (Hỗ trợ IPv6)
    otp_method VARCHAR(50),                              -- Phương thức OTP đang sử dụng (SMS, Email, App)
    phone_number VARCHAR(15),                            -- Số điện thoại liên kết (thường dùng cho OTP)
    email VARCHAR(100),                                  -- Email liên kết (thường dùng cho thông báo/OTP)
    security_question_hash TEXT,                         -- Hash của câu trả lời cho câu hỏi bảo mật (không lưu plain text)

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính
    CONSTRAINT pk_digital_identity PRIMARY KEY (digital_identity_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_digital_identity_digital_id UNIQUE (digital_id),
    -- Đảm bảo mỗi công dân chỉ có một định danh điện tử đang hoạt động
    -- CONSTRAINT uq_active_digital_id_per_citizen UNIQUE (citizen_id) WHERE status = TRUE, -- Xem xét lại ràng buộc này nếu cần thiết

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) yêu cầu citizen_id phải là unique toàn cục hoặc có global unique index.
    CONSTRAINT fk_digital_identity_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_digital_id_phone_format CHECK (phone_number IS NULL OR phone_number ~ '^\+?[0-9]{10,14}$'),
    CONSTRAINT ck_digital_id_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_digital_id_format CHECK (digital_id ~ '^[A-Za-z0-9-]+$'), -- Kiểm tra định dạng mã định danh (điều chỉnh nếu cần)
    CONSTRAINT ck_digital_id_activation_date CHECK (activation_date <= CURRENT_TIMESTAMP) -- Ngày kích hoạt không thể ở tương lai
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_digital_identity_citizen_id ON public_security.digital_identity(citizen_id);
-- Index trên digital_id đã được tạo bởi ràng buộc UNIQUE
CREATE INDEX IF NOT EXISTS idx_digital_identity_phone ON public_security.digital_identity(phone_number) WHERE phone_number IS NOT NULL; -- Partial index
CREATE INDEX IF NOT EXISTS idx_digital_identity_email ON public_security.digital_identity(email) WHERE email IS NOT NULL; -- Partial index
CREATE INDEX IF NOT EXISTS idx_digital_identity_status ON public_security.digital_identity(status);
CREATE INDEX IF NOT EXISTS idx_digital_identity_last_login ON public_security.digital_identity(last_login_date);

-- Chỉ mục unique đảm bảo mỗi công dân chỉ có một định danh điện tử đang hoạt động
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_digital_id_per_citizen
    ON public_security.digital_identity (citizen_id)
    WHERE status = TRUE;

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger ghi nhật ký audit cho các thay đổi quan trọng (kích hoạt, đổi SĐT/email, thay đổi mức xác thực) (chuyển sang triggers/audit_triggers.sql).
--    - Trigger mã hóa/xác thực câu hỏi bảo mật.
-- 2. Security:
--    - Triển khai Row-Level Security (RLS).
--    - Chính sách mã hóa cho security_question_hash.
--    - Logging truy cập và các hành động nhạy cảm (đăng nhập, đổi thông tin).
-- 3. Data Validation: Quy tắc validate chi tiết cho device_info (JSONB schema).

COMMIT;

\echo 'digital_identity table created successfully with constraints and indexes.'
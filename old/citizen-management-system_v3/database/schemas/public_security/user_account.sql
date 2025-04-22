-- =============================================================================
-- File: database/schemas/public_security/user_account.sql
-- Description: Creates the user_account table in the public_security schema
--              for managing user login credentials and status.
-- Version: 2.0 (Integrated constraints, indexes, removed comments)
-- =============================================================================

\echo 'Creating user_account table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.user_account CASCADE;

-- Create the user_account table
CREATE TABLE public_security.user_account (
    user_id SERIAL NOT NULL,                            -- ID tự tăng, khóa chính
    citizen_id VARCHAR(12),                             -- Liên kết với công dân (nếu là tài khoản công dân) (FK public_security.citizen)
    username VARCHAR(50) NOT NULL,                      -- Tên đăng nhập (duy nhất)
    password_hash VARCHAR(255) NOT NULL,                -- Hash mật khẩu đã được mã hóa an toàn (vd: bcrypt, Argon2)
    user_type user_type NOT NULL,                       -- Loại tài khoản (ENUM: Công dân, Cán bộ, Quản trị viên)
    status VARCHAR(20) NOT NULL DEFAULT 'Active',       -- Trạng thái tài khoản ('Active', 'Inactive', 'Locked', 'PendingVerification')
    last_login_date TIMESTAMP WITH TIME ZONE,           -- Thời điểm đăng nhập thành công lần cuối
    last_login_ip VARCHAR(45),                          -- Địa chỉ IP đăng nhập lần cuối (hỗ trợ IPv6)
    failed_login_attempts SMALLINT DEFAULT 0,           -- Số lần đăng nhập thất bại liên tiếp
    two_factor_enabled BOOLEAN DEFAULT FALSE,           -- Đã bật xác thực 2 yếu tố chưa?
    two_factor_secret TEXT,                             -- Khóa bí mật cho 2FA (cần mã hóa nếu lưu)
    email VARCHAR(100),                                 -- Email liên kết (cho khôi phục, thông báo)
    phone_number VARCHAR(15),                           -- Số điện thoại liên kết (cho khôi phục, thông báo)
    locked_until TIMESTAMP WITH TIME ZONE,              -- Thời điểm tài khoản bị khóa đến (nếu bị khóa tạm thời)
    verification_token TEXT,                            -- Token dùng cho xác minh email/tài khoản
    verification_token_expires TIMESTAMP WITH TIME ZONE, -- Thời gian hết hạn token xác minh
    password_reset_token TEXT,                          -- Token dùng cho đặt lại mật khẩu
    password_reset_expires TIMESTAMP WITH TIME ZONE,    -- Thời gian hết hạn token đặt lại mật khẩu

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Ràng buộc Khóa chính
    CONSTRAINT pk_user_account PRIMARY KEY (user_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_user_account_username UNIQUE (username),
    CONSTRAINT uq_user_account_email UNIQUE (email) WHERE email IS NOT NULL, -- Email phải unique nếu có
    CONSTRAINT uq_user_account_phone UNIQUE (phone_number) WHERE phone_number IS NOT NULL, -- SĐT phải unique nếu có

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) yêu cầu citizen_id phải là unique toàn cục hoặc có global unique index.
    CONSTRAINT fk_user_account_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE SET NULL, -- Nếu citizen bị xóa, chỉ set null user_account

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_user_account_status CHECK (status IN ('Active', 'Inactive', 'Locked', 'PendingVerification')),
    CONSTRAINT ck_user_account_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_user_account_phone_format CHECK (phone_number IS NULL OR phone_number ~* '^\+?[0-9]{10,14}$')

);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_account_citizen_id ON public_security.user_account(citizen_id) WHERE citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_account_user_type ON public_security.user_account(user_type);
CREATE INDEX IF NOT EXISTS idx_user_account_status ON public_security.user_account(status);
CREATE INDEX IF NOT EXISTS idx_user_account_last_login ON public_security.user_account(last_login_date);
-- Index cho username đã được tạo tự động bởi ràng buộc UNIQUE
-- Index cho email và phone cũng được tạo tự động

-- Index unique đảm bảo mỗi công dân chỉ có 1 tài khoản (nếu citizen_id được cung cấp)
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_user_account_citizen_id_not_null
    ON public_security.user_account (citizen_id)
    WHERE citizen_id IS NOT NULL;

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger hash mật khẩu trước khi INSERT/UPDATE.
--    - Trigger xử lý khóa tài khoản khi đăng nhập sai nhiều lần.
--    - Trigger ghi nhật ký audit cho các thay đổi quan trọng (trạng thái, mật khẩu, thông tin liên hệ).
-- 2. Security:
--    - Quản lý việc hash và kiểm tra mật khẩu an toàn.
--    - Xử lý logic xác thực 2 yếu tố (2FA).
--    - Xử lý logic token xác minh và đặt lại mật khẩu.

COMMIT;

\echo 'user_account table created successfully with constraints and indexes.'
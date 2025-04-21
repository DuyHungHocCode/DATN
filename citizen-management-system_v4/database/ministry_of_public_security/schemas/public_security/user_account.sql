-- =============================================================================
-- File: ministry_of_public_security/schemas/public_security/user_account.sql
-- Description: Tạo bảng user_account quản lý tài khoản đăng nhập hệ thống
--              cho Cán bộ và Quản trị viên trong schema public_security.
-- Version: 3.1 (Clarified scope: Officials/Admins only)
--
-- Dependencies:
-- - Script tạo schema 'public_security'.
-- - Script tạo bảng 'public_security.citizen'.
-- - Script tạo ENUM 'user_type' (phải chứa 'Cán bộ', 'Quản trị viên').
-- =============================================================================

\echo '--> Tạo bảng public_security.user_account (Cán bộ/Quản trị viên)...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.user_account CASCADE;

-- Tạo bảng user_account
-- Lưu ý: Bảng này thường không cần phân vùng vì số lượng tài khoản hệ thống
-- (cán bộ, quản trị) thường không quá lớn.
CREATE TABLE public_security.user_account (
    user_id SERIAL PRIMARY KEY,                         -- ID tự tăng, khóa chính
    citizen_id VARCHAR(12) NOT NULL,                    -- Số CCCD/ĐDCN của Cán bộ/Quản trị viên. (FK đến public_security.citizen)
    username VARCHAR(50) NOT NULL,                      -- Tên đăng nhập (duy nhất)
    password_hash VARCHAR(255) NOT NULL,                -- Hash mật khẩu đã được mã hóa an toàn (vd: bcrypt, Argon2). **KHÔNG LƯU PLAIN TEXT!**
    user_type user_type NOT NULL                       -- Loại tài khoản (Chỉ 'Cán bộ' hoặc 'Quản trị viên')
        CHECK (user_type IN ('Cán bộ', 'Quản trị viên')), -- Ràng buộc chỉ cho phép 2 loại này
    status VARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (status IN ('Active', 'Inactive', 'Locked', 'PendingVerification')), -- Trạng thái tài khoản
    last_login_date TIMESTAMP WITH TIME ZONE,           -- Thời điểm đăng nhập thành công lần cuối
    last_login_ip VARCHAR(45),                          -- Địa chỉ IP đăng nhập lần cuối (hỗ trợ IPv4/IPv6)
    failed_login_attempts SMALLINT DEFAULT 0,           -- Số lần đăng nhập thất bại liên tiếp (dùng để khóa tài khoản)
    two_factor_enabled BOOLEAN DEFAULT FALSE,           -- Đã bật xác thực 2 yếu tố (2FA) chưa?
    two_factor_secret TEXT,                             -- Khóa bí mật cho 2FA (cần mã hóa hoặc lưu trữ an toàn)
    email VARCHAR(100),                                 -- Email liên kết (cho khôi phục, thông báo)
    phone_number VARCHAR(15),                           -- Số điện thoại liên kết (cho khôi phục, thông báo)
    locked_until TIMESTAMP WITH TIME ZONE,              -- Thời điểm tài khoản bị khóa đến (nếu bị khóa tạm thời)
    verification_token TEXT,                            -- Token dùng cho xác minh email/tài khoản
    verification_token_expires TIMESTAMP WITH TIME ZONE, -- Thời gian hết hạn token xác minh
    password_reset_token TEXT,                          -- Token dùng cho đặt lại mật khẩu
    password_reset_expires TIMESTAMP WITH TIME ZONE,    -- Thời gian hết hạn token đặt lại mật khẩu
    notes TEXT,                                         -- Ghi chú thêm

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Ràng buộc Duy nhấts
    CONSTRAINT uq_user_account_username UNIQUE (username),
    CONSTRAINT uq_user_account_email UNIQUE (email) WHERE email IS NOT NULL, -- Email phải unique nếu có
    CONSTRAINT uq_user_account_phone UNIQUE (phone_number) WHERE phone_number IS NOT NULL, -- SĐT phải unique nếu có
    -- Ràng buộc unique trên citizen_id được tạo bằng index bên dưới

    -- Ràng buộc Khóa ngoại (Cần kiểm tra với partitioning của bảng citizen)
    -- Liên kết tài khoản với bản ghi công dân của cán bộ/quản trị viên đó.
    -- Cân nhắc ON DELETE RESTRICT nếu không muốn xóa citizen khi đang có user_account active.
    CONSTRAINT fk_user_account_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE SET NULL, -- Nếu citizen bị xóa, chỉ set null user_account

    -- Ràng buộc Kiểm tra định dạng cơ bản
    CONSTRAINT ck_user_account_email_format CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_user_account_phone_format CHECK (phone_number IS NULL OR phone_number ~* '^\+?[0-9]{10,15}$') -- Điều chỉnh regex nếu cần cho SĐT Việt Nam

);

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE public_security.user_account IS 'Quản lý tài khoản đăng nhập vào hệ thống cho Cán bộ và Quản trị viên.';
COMMENT ON COLUMN public_security.user_account.citizen_id IS 'ID Công dân (CCCD/ĐDCN) của Cán bộ/Quản trị viên.';
COMMENT ON COLUMN public_security.user_account.username IS 'Tên đăng nhập duy nhất.';
COMMENT ON COLUMN public_security.user_account.password_hash IS 'Hash mật khẩu đã được mã hóa an toàn (vd: bcrypt). KHÔNG LƯU PLAIN TEXT.';
COMMENT ON COLUMN public_security.user_account.user_type IS 'Loại tài khoản (Chỉ cho phép: Cán bộ, Quản trị viên).';
COMMENT ON COLUMN public_security.user_account.status IS 'Trạng thái tài khoản: Active, Inactive, Locked, PendingVerification.';
COMMENT ON COLUMN public_security.user_account.failed_login_attempts IS 'Số lần đăng nhập thất bại liên tiếp, dùng để xử lý khóa tài khoản.';
COMMENT ON COLUMN public_security.user_account.two_factor_secret IS 'Khóa bí mật cho xác thực 2 yếu tố (cần bảo mật).';
COMMENT ON COLUMN public_security.user_account.locked_until IS 'Thời điểm tài khoản bị khóa đến (nếu có).';
COMMENT ON COLUMN public_security.user_account.verification_token IS 'Token dùng một lần để xác minh email/tài khoản.';
COMMENT ON COLUMN public_security.user_account.password_reset_token IS 'Token dùng một lần để đặt lại mật khẩu.';


-- Indexes
-- Index trên khóa ngoại và các cột thường dùng để lọc
CREATE INDEX IF NOT EXISTS idx_user_account_citizen_id ON public_security.user_account(citizen_id); -- citizen_id là NOT NULL
CREATE INDEX IF NOT EXISTS idx_user_account_user_type ON public_security.user_account(user_type);
CREATE INDEX IF NOT EXISTS idx_user_account_status ON public_security.user_account(status);
CREATE INDEX IF NOT EXISTS idx_user_account_last_login ON public_security.user_account(last_login_date);
-- Index cho username, email, phone đã được tạo tự động bởi ràng buộc UNIQUE

-- Index unique đảm bảo mỗi công dân (cán bộ/quản trị viên) chỉ có một tài khoản hệ thống.
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_user_account_citizen_id
    ON public_security.user_account (citizen_id); -- Không cần WHERE nữa vì cột là NOT NULL

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.user_account (Cán bộ/Quản trị viên).'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Security Implementation (Application Layer - App BCA):
--    - Implement secure password hashing (e.g., using passlib in Python) before INSERT/UPDATE.
--    - Implement logic for verifying passwords against the hash.
--    - Implement logic for generating and verifying 2FA codes (nếu two_factor_enabled = TRUE).
--    - Implement logic for generating, sending (email/SMS), and verifying email/password reset tokens.
--    - Implement account locking mechanism based on `failed_login_attempts` and `locked_until`.
-- 2. Triggers (Database Layer - BCA):
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger ghi nhật ký audit cho các thay đổi quan trọng (trạng thái, sự kiện đổi mật khẩu - không ghi hash, thay đổi email/SĐT) (trong thư mục `triggers/audit_triggers.sql`).
-- 3. Permissions: Đảm bảo các role (security_reader, security_writer, security_admin) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`). App BCA sẽ cần quyền đọc/ghi tùy chức năng quản lý tài khoản.
-- 4. Foreign Key Verification: Kiểm tra hoạt động của FK `fk_user_account_citizen` với bảng `citizen` đã phân vùng. Cân nhắc `ON DELETE RESTRICT` thay vì `SET NULL` nếu muốn ngăn xóa citizen khi còn user account.
-- 5. ENUM Update (Optional but Recommended): Xem xét cập nhật định nghĩa ENUM `user_type` trong file `01_common/02_enum.sql` để chỉ chứa 'Cán bộ', 'Quản trị viên' nếu giá trị 'Công dân' không được dùng ở bất kỳ đâu khác cho tài khoản hệ thống.

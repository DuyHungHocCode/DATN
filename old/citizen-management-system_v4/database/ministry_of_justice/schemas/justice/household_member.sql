-- =============================================================================
-- File: ministry_of_justice/schemas/justice/household_member.sql
-- Description: Tạo bảng household_member liên kết công dân với hộ khẩu
--              trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure - Removed Cross-DB FKs)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'justice.household'.
-- - Script tạo bảng 'reference.regions', 'reference.provinces'.
-- - Script tạo ENUM 'household_relationship'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.household_member...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.household_member CASCADE;

-- Tạo bảng household_member với cấu trúc phân vùng
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.household_member (
    household_member_id BIGSERIAL NOT NULL,                 -- ID tự tăng của bản ghi thành viên hộ khẩu (dùng BIGSERIAL)
    household_id INT NOT NULL,                           -- Hộ khẩu mà thành viên thuộc về (FK đến justice.household)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân là thành viên (Logic liên kết đến public_security.citizen)
    relationship_with_head household_relationship NOT NULL, -- Quan hệ với chủ hộ (ENUM)
    join_date DATE NOT NULL,                             -- Ngày công dân nhập hộ khẩu
    leave_date DATE,                                     -- Ngày công dân rời hộ khẩu (NULL nếu còn là thành viên)
    leave_reason TEXT,                                   -- Lý do rời hộ khẩu (vd: Chuyển đi, Tách khẩu, Mất...)
    previous_household_id INT,                           -- Hộ khẩu trước đó (FK đến justice.household) (nếu chuyển khẩu)
    status VARCHAR(50) DEFAULT 'Active',                 -- Trạng thái thành viên (Active, Left, Moved, Deceased, Cancelled)
    order_in_household SMALLINT,                         -- Thứ tự hiển thị trong sổ hộ khẩu (nếu có)

    -- Thông tin hành chính & Phân vùng (Thường lấy theo hộ khẩu)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User tạo bản ghi
    updated_by VARCHAR(50),                              -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_household_member PRIMARY KEY (household_member_id, geographical_region, province_id),

    -- Ràng buộc Duy nhất (Cần kiểm tra kỹ với partitioning)
    -- Đảm bảo một người không thể nhập vào cùng một hộ khẩu vào cùng một ngày nhiều lần.
    CONSTRAINT uq_household_member_join UNIQUE (household_id, citizen_id, join_date),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- Lưu ý: FK tới bảng household (đã phân vùng) cần kiểm tra kỹ lưỡng.
    -- **ĐÃ XÓA FK đến public_security.citizen**
    CONSTRAINT fk_household_member_household FOREIGN KEY (household_id) REFERENCES justice.household(household_id) ON DELETE CASCADE, -- Nếu xóa hộ khẩu thì xóa các thành viên liên quan
    CONSTRAINT fk_household_member_prev_household FOREIGN KEY (previous_household_id) REFERENCES justice.household(household_id) ON DELETE SET NULL, -- Nếu xóa hộ khẩu cũ thì chỉ set null
    CONSTRAINT fk_household_member_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_household_member_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_household_member_dates CHECK (join_date <= CURRENT_DATE AND (leave_date IS NULL OR leave_date >= join_date)), -- Ngày rời phải sau ngày nhập
    CONSTRAINT ck_household_member_order CHECK (order_in_household IS NULL OR order_in_household > 0), -- Thứ tự phải là số dương
    CONSTRAINT ck_household_member_status CHECK (status IN ('Active', 'Left', 'Moved', 'Deceased', 'Cancelled')), -- Các trạng thái hợp lệ
    CONSTRAINT ck_household_member_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- province_id là NOT NULL, nên region_id cũng phải NOT NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.household_member IS 'Lưu thông tin các thành viên thuộc một hộ khẩu.';
COMMENT ON COLUMN justice.household_member.household_id IS 'ID của hộ khẩu mà thành viên này thuộc về (FK đến justice.household).';
COMMENT ON COLUMN justice.household_member.citizen_id IS 'ID của công dân là thành viên (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.household_member.relationship_with_head IS 'Quan hệ của thành viên này với chủ hộ (ENUM household_relationship).';
COMMENT ON COLUMN justice.household_member.join_date IS 'Ngày công dân chính thức nhập vào hộ khẩu này.';
COMMENT ON COLUMN justice.household_member.leave_date IS 'Ngày công dân chính thức rời khỏi hộ khẩu này (NULL nếu vẫn đang là thành viên).';
COMMENT ON COLUMN justice.household_member.leave_reason IS 'Lý do rời hộ khẩu (Chuyển đi, Tách khẩu, Mất...).';
COMMENT ON COLUMN justice.household_member.status IS 'Trạng thái của thành viên trong hộ khẩu (Active, Left, Moved, Deceased, Cancelled).';
COMMENT ON COLUMN justice.household_member.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.household_member.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';

-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
CREATE INDEX IF NOT EXISTS idx_household_member_household_id ON justice.household_member(household_id);
CREATE INDEX IF NOT EXISTS idx_household_member_citizen_id ON justice.household_member(citizen_id); -- Quan trọng cho tra cứu thành viên theo công dân
CREATE INDEX IF NOT EXISTS idx_household_member_join_date ON justice.household_member(join_date);
CREATE INDEX IF NOT EXISTS idx_household_member_leave_date ON justice.household_member(leave_date);
CREATE INDEX IF NOT EXISTS idx_household_member_status ON justice.household_member(status);
CREATE INDEX IF NOT EXISTS idx_household_member_prev_hhold_id ON justice.household_member(previous_household_id) WHERE previous_household_id IS NOT NULL;
-- Index trên cột phân vùng province_id đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.household_member.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger kiểm tra tính hợp lệ khi thêm/sửa thành viên (vd: chủ hộ phải là thành viên, quan hệ với chủ hộ phải hợp lệ).
--    - Cân nhắc trigger tự động cập nhật `status` khi `leave_date` được điền hoặc khi công dân có trạng thái 'Đã mất' (cần phối hợp liên service).
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `region_id`) dựa trên `household_id`.
-- 4. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA để xác thực `citizen_id` trước khi thêm thành viên.
--    - Các thay đổi về thành viên hộ khẩu (nhập/rời) có thể cần thông báo cho App BCA để cập nhật thông tin cư trú liên quan (ví dụ: cập nhật `permanent_residence`).
-- 5. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 6. Permissions: Đảm bảo các role (justice_reader, justice_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 7. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của ràng buộc UNIQUE `uq_household_member_join` trên môi trường có partitioning.
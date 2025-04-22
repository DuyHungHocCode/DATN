-- =============================================================================
-- File: database/schemas/justice/household_member.sql
-- Description: Creates the household_member table in the justice schema, linking
--              citizens to households.
-- Version: 2.0 (Integrated constraints, indexes, partitioning, removed comments)
-- =============================================================================

\echo 'Creating household_member table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.household_member CASCADE;

-- Create the household_member table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.household_member (
    household_member_id SERIAL NOT NULL,                 -- ID tự tăng của bản ghi thành viên hộ khẩu
    household_id INT NOT NULL,                           -- Hộ khẩu mà thành viên thuộc về (FK justice.household)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân là thành viên (FK public_security.citizen)
    relationship_with_head household_relationship NOT NULL, -- Quan hệ với chủ hộ (ENUM)
    join_date DATE NOT NULL,                             -- Ngày công dân nhập hộ khẩu
    leave_date DATE,                                     -- Ngày công dân rời hộ khẩu (NULL nếu còn là thành viên)
    leave_reason TEXT,                                   -- Lý do rời hộ khẩu
    previous_household_id INT,                           -- Hộ khẩu trước đó (FK justice.household) (nếu chuyển khẩu)
    status VARCHAR(50) DEFAULT 'Active',                 -- Trạng thái thành viên (Active, Left, Moved, Deceased)
    order_in_household SMALLINT,                         -- Thứ tự hiển thị trong sổ hộ khẩu (nếu có)

    -- Thông tin hành chính & Phân vùng (Thường lấy theo hộ khẩu)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_household_member PRIMARY KEY (household_member_id, geographical_region, province_id),

    -- Ràng buộc Duy nhất: Một người chỉ có thể nhập vào một hộ khẩu vào một ngày cụ thể một lần.
    CONSTRAINT uq_household_member_join UNIQUE (household_id, citizen_id, join_date),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) và household (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_household_member_household FOREIGN KEY (household_id) REFERENCES justice.household(household_id) ON DELETE CASCADE,
    CONSTRAINT fk_household_member_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_household_member_prev_household FOREIGN KEY (previous_household_id) REFERENCES justice.household(household_id) ON DELETE SET NULL,
    CONSTRAINT fk_household_member_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_household_member_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_household_member_dates CHECK (join_date <= CURRENT_DATE AND (leave_date IS NULL OR leave_date >= join_date)),
    CONSTRAINT ck_household_member_order CHECK (order_in_household IS NULL OR order_in_household > 0),
    CONSTRAINT ck_household_member_status CHECK (status IN ('Active', 'Left', 'Moved', 'Deceased', 'Cancelled')), -- Thêm Cancelled
    CONSTRAINT ck_household_member_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_household_member_household_id ON justice.household_member(household_id);
CREATE INDEX IF NOT EXISTS idx_household_member_citizen_id ON justice.household_member(citizen_id);
CREATE INDEX IF NOT EXISTS idx_household_member_join_date ON justice.household_member(join_date);
CREATE INDEX IF NOT EXISTS idx_household_member_leave_date ON justice.household_member(leave_date);
CREATE INDEX IF NOT EXISTS idx_household_member_status ON justice.household_member(status);

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, region_id dựa trên household_id.
--    - Trigger tự động cập nhật status khi leave_date đến hạn hoặc khi citizen có trạng thái 'Đã mất'.
--    - Trigger kiểm tra tính hợp lệ khi thêm/sửa thành viên (vd: chủ hộ phải là thành viên).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.
-- 3. Foreign Data Wrapper (FDW): Cấu hình FDW để truy cập public_security.citizen.

COMMIT;

\echo 'household_member table created successfully with partitioning, constraints, and indexes.'
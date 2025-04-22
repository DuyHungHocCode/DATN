-- =============================================================================
-- File: database/schemas/justice/household.sql
-- Description: Tạo bảng household (hộ khẩu) trong schema justice.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating household table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.household CASCADE;

-- Create the household table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.household (
    household_id SERIAL NOT NULL,                        -- ID tự tăng của hộ khẩu
    household_book_no VARCHAR(20) NOT NULL,                -- Số sổ hộ khẩu (Unique)
    head_of_household_id VARCHAR(12) NOT NULL,             -- ID Chủ hộ (FK logic tới public_security.citizen)
    address_id INT NOT NULL,                             -- Địa chỉ đăng ký hộ khẩu (FK logic tới public_security.address)
    registration_date DATE NOT NULL,                     -- Ngày đăng ký hộ khẩu
    issuing_authority_id SMALLINT,                       -- Cơ quan cấp sổ (FK reference.authorities)
    area_code VARCHAR(10),                               -- Mã khu vực hành chính (nếu có)
    household_type household_type NOT NULL,              -- Loại hộ khẩu (ENUM: Thường trú, Tạm trú, Tập thể...)
    status household_status DEFAULT 'Đang hoạt động',     -- Trạng thái hộ khẩu (ENUM: Đang hoạt động, Đã chuyển đi...)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo address_id)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_household PRIMARY KEY (household_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_household_book_no UNIQUE (household_book_no),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng public_security.citizen và public_security.address (khác database)
    --       không thể tạo trực tiếp. Cần đảm bảo qua FDW hoặc logic đồng bộ/ứng dụng.
    -- CONSTRAINT fk_household_head FOREIGN KEY (head_of_household_id) REFERENCES public_security.citizen(citizen_id),
    -- CONSTRAINT fk_household_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_household_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_household_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_household_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_household_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_household_registration_date CHECK (registration_date <= CURRENT_DATE),
    CONSTRAINT ck_household_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
-- Index trên khóa chính đã được tạo tự động
-- Index trên khóa unique household_book_no đã được tạo tự động
CREATE INDEX IF NOT EXISTS idx_household_head_id ON justice.household(head_of_household_id);
CREATE INDEX IF NOT EXISTS idx_household_address_id ON justice.household(address_id);
CREATE INDEX IF NOT EXISTS idx_household_type ON justice.household(household_type);
CREATE INDEX IF NOT EXISTS idx_household_status ON justice.household(status);
CREATE INDEX IF NOT EXISTS idx_household_province_id ON justice.household(province_id); -- Hỗ trợ query/partition
CREATE INDEX IF NOT EXISTS idx_household_district_id ON justice.household(district_id); -- Hỗ trợ query/partition

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên address_id.
--    - Trigger kiểm tra tính hợp lệ của head_of_household_id và address_id thông qua FDW hoặc dữ liệu đã đồng bộ.
--    - Trigger đảm bảo chủ hộ cũng là một thành viên trong bảng household_member.
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.
-- 3. Foreign Data Wrapper (FDW): Cấu hình FDW để truy vấn public_security.citizen và public_security.address.

COMMIT;

\echo 'household table created successfully with partitioning, constraints, and indexes.'
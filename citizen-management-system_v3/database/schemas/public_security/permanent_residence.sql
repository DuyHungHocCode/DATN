-- =============================================================================
-- File: database/schemas/public_security/permanent_residence.sql
-- Description: Tạo bảng permanent_residence (Đăng ký thường trú) trong schema public_security.
--              Bảng này được tách ra từ residence.sql cũ.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating permanent_residence table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.permanent_residence CASCADE;

-- Create the permanent_residence table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.permanent_residence (
    permanent_residence_id SERIAL NOT NULL,              -- ID tự tăng của bản ghi đăng ký thường trú
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân được đăng ký (FK public_security.citizen)
    address_id INT NOT NULL,                             -- Địa chỉ thường trú (FK public_security.address)
    registration_date DATE NOT NULL,                     -- Ngày đăng ký thường trú
    decision_no VARCHAR(50) NOT NULL,                    -- Số quyết định đăng ký thường trú
    issuing_authority_id SMALLINT NOT NULL,              -- Cơ quan cấp quyết định (FK reference.authorities)
    previous_address_id INT,                             -- Địa chỉ thường trú trước đó (FK public_security.address)
    change_reason TEXT,                                  -- Lý do thay đổi chỗ ở thường trú
    document_url VARCHAR(255),                           -- Đường dẫn đến tài liệu quét (scan) (nếu có)
    household_id INT,                                    -- ID Hộ khẩu liên quan (FK logic tới justice.household)
    relationship_with_head VARCHAR(50),                  -- Quan hệ với chủ hộ trong hộ khẩu đó
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái đăng ký (TRUE = đang có hiệu lực)
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Thường lấy theo address_id)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế', -- Mức độ nhạy cảm

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_permanent_residence PRIMARY KEY (permanent_residence_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_permanent_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_permanent_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_permanent_residence_prev_address FOREIGN KEY (previous_address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_permanent_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_permanent_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_permanent_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_permanent_residence_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- FK tới justice.household (khác database) không thể tạo trực tiếp, cần xử lý qua FDW hoặc logic đồng bộ.
    -- CONSTRAINT fk_permanent_residence_household FOREIGN KEY (household_id) REFERENCES justice.household(household_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_permanent_residence_date CHECK (registration_date <= CURRENT_DATE),
    CONSTRAINT ck_permanent_residence_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_permanent_residence_citizen_id ON public_security.permanent_residence(citizen_id);
CREATE INDEX IF NOT EXISTS idx_permanent_residence_address_id ON public_security.permanent_residence(address_id);
CREATE INDEX IF NOT EXISTS idx_permanent_residence_reg_date ON public_security.permanent_residence(registration_date);
CREATE INDEX IF NOT EXISTS idx_permanent_residence_status ON public_security.permanent_residence(status);
CREATE INDEX IF NOT EXISTS idx_permanent_residence_household_id ON public_security.permanent_residence(household_id) WHERE household_id IS NOT NULL;

-- Chỉ mục unique đảm bảo mỗi công dân chỉ có một đăng ký thường trú đang hoạt động
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_permanent_residence_per_citizen
    ON public_security.permanent_residence (citizen_id)
    WHERE status = TRUE;

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên address_id.
--    - Trigger cập nhật trạng thái (status=FALSE) cho bản ghi thường trú cũ khi có bản ghi mới cho cùng citizen_id.
--    - Trigger kiểm tra/đồng bộ logic với bảng justice.household.
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.
-- 3. Foreign Data Wrapper (FDW): Cấu hình FDW để có thể truy vấn (hoặc trigger kiểm tra) bảng justice.household.

COMMIT;

\echo 'permanent_residence table created successfully with partitioning, constraints, and indexes.'
-- =============================================================================
-- File: database/schemas/public_security/citizen_address.sql
-- Description: Tạo bảng citizen_address (Liên kết Công dân - Địa chỉ) trong schema public_security.
--              Bảng này được tách ra từ residence.sql cũ.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating citizen_address table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_address CASCADE;

-- Create the citizen_address table with partitioning
-- Giả định phân vùng theo 3 cấp giống citizen: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.citizen_address (
    citizen_address_id SERIAL NOT NULL,                  -- ID tự tăng của liên kết
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân (FK public_security.citizen)
    address_id INT NOT NULL,                             -- Địa chỉ (FK public_security.address)
    address_type address_type NOT NULL,                  -- Loại địa chỉ liên kết (ENUM: Thường trú, Tạm trú...)
    from_date DATE NOT NULL,                             -- Ngày bắt đầu sử dụng/liên kết với địa chỉ này
    to_date DATE,                                        -- Ngày kết thúc sử dụng (NULL = hiện tại vẫn dùng)
    is_primary BOOLEAN DEFAULT FALSE,                    -- Có phải địa chỉ chính cho loại địa chỉ này không?
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái liên kết (TRUE = Active)
    registration_document_no VARCHAR(50),                -- Số giấy tờ đăng ký liên quan (nếu có)
    registration_date DATE,                              -- Ngày đăng ký trên giấy tờ
    issuing_authority_id SMALLINT,                       -- Cơ quan cấp giấy tờ (FK reference.authorities)
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh địa chỉ này với công dân
    verification_date DATE,                              -- Ngày xác minh
    verified_by VARCHAR(100),                            -- Người xác minh
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo citizen_id hoặc address_id)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1
    data_sensitivity_level data_sensitivity_level DEFAULT 'Công khai', -- Mức độ nhạy cảm

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_citizen_address PRIMARY KEY (citizen_address_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_citizen_address_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_citizen_address_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id) ON DELETE CASCADE,
    CONSTRAINT fk_citizen_address_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_citizen_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_citizen_address_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_citizen_address_dates CHECK (
            from_date <= CURRENT_DATE AND
            (to_date IS NULL OR to_date >= from_date) AND -- Ngày kết thúc phải sau hoặc bằng ngày bắt đầu
            (registration_date IS NULL OR registration_date <= CURRENT_DATE) AND
            (verification_date IS NULL OR verification_date <= CURRENT_DATE)
        ),
    CONSTRAINT ck_citizen_address_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_citizen_address_citizen_id ON public_security.citizen_address(citizen_id);
CREATE INDEX IF NOT EXISTS idx_citizen_address_address_id ON public_security.citizen_address(address_id);
CREATE INDEX IF NOT EXISTS idx_citizen_address_address_type ON public_security.citizen_address(address_type);
CREATE INDEX IF NOT EXISTS idx_citizen_address_from_date ON public_security.citizen_address(from_date);
CREATE INDEX IF NOT EXISTS idx_citizen_address_to_date ON public_security.citizen_address(to_date);
CREATE INDEX IF NOT EXISTS idx_citizen_address_status ON public_security.citizen_address(status);

-- Chỉ mục unique đảm bảo mỗi công dân chỉ có một địa chỉ chính (is_primary=TRUE) cho mỗi loại địa chỉ (address_type) đang hoạt động (status=TRUE)
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_citizen_address_primary
    ON public_security.citizen_address(citizen_id, address_type)
    WHERE is_primary = TRUE AND status = TRUE;

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên citizen_id hoặc address_id.
--    - Trigger đảm bảo logic is_primary (ví dụ: khi set 1 cái là primary thì cái cũ cùng loại phải thành FALSE).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.

COMMIT;

\echo 'citizen_address table created successfully with partitioning, constraints, and indexes.'
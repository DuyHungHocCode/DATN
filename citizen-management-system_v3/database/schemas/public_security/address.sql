-- =============================================================================
-- File: database/schemas/public_security/address.sql
-- Description: Tạo bảng address (địa chỉ chi tiết) trong schema public_security.
--              Bảng này được tách ra từ residence.sql cũ.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating address table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.address CASCADE;

-- Create the address table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.address (
    address_id SERIAL NOT NULL,                        -- ID địa chỉ, khóa chính logic
    address_detail TEXT NOT NULL,                      -- Chi tiết địa chỉ (số nhà, đường, thôn, xóm...)
    ward_id INT NOT NULL,                              -- Phường/Xã (FK reference.wards)
    district_id INT NOT NULL,                          -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    province_id INT NOT NULL,                          -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    address_type address_type NOT NULL,                -- Loại địa chỉ (ENUM: Thường trú, Tạm trú, Nơi ở hiện tại...)
    postal_code VARCHAR(10),                           -- Mã bưu chính (nếu có)
    latitude DECIMAL(10, 8),                           -- Vĩ độ (cho GIS)
    longitude DECIMAL(11, 8),                          -- Kinh độ (cho GIS)
    status BOOLEAN DEFAULT TRUE,                       -- Trạng thái địa chỉ (TRUE = còn sử dụng/hợp lệ)
    region_id SMALLINT NOT NULL,                       -- Vùng/Miền (FK reference.regions)
    geographical_region VARCHAR(20) NOT NULL,          -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1
    data_sensitivity_level data_sensitivity_level DEFAULT 'Công khai', -- Mức độ nhạy cảm

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_address PRIMARY KEY (address_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại
    CONSTRAINT fk_address_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    CONSTRAINT fk_address_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    CONSTRAINT fk_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_address_coordinates CHECK (
            (latitude IS NULL AND longitude IS NULL) OR
            (latitude IS NOT NULL AND longitude IS NOT NULL AND
             latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
        ),
    CONSTRAINT ck_address_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_address_ward_id ON public_security.address(ward_id);
CREATE INDEX IF NOT EXISTS idx_address_district_id ON public_security.address(district_id); -- Quan trọng cho partition pruning cấp 3
CREATE INDEX IF NOT EXISTS idx_address_province_id ON public_security.address(province_id); -- Quan trọng cho partition pruning cấp 2
CREATE INDEX IF NOT EXISTS idx_address_region_id ON public_security.address(region_id);
CREATE INDEX IF NOT EXISTS idx_address_status ON public_security.address(status);
CREATE INDEX IF NOT EXISTS idx_address_type ON public_security.address(address_type);
-- CREATE INDEX IF NOT EXISTS idx_address_geospatial ON public_security.address USING GIST (geography(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))); -- Chỉ mục không gian nếu dùng PostGIS

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger tự động cập nhật geographical_region dựa trên region_id (chuyển sang triggers/...).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.
-- 3. Spatial Index: Bỏ comment và tạo idx_address_geospatial nếu ứng dụng có các truy vấn không gian địa lý.

COMMIT;

\echo 'address table created successfully with partitioning, constraints, and indexes.'
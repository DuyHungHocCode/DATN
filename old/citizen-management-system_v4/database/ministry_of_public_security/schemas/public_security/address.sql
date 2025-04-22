-- =============================================================================
-- File: ministry_of_public_security/schemas/public_security/address.sql
-- Description: Tạo bảng address (Địa chỉ) trong schema public_security.
-- Version: 3.1 (Fixed potential invalid index creation)
--
-- Dependencies:
-- - Script tạo schema 'public_security', 'reference'.
-- - Script tạo bảng 'reference.wards', 'reference.districts', 'reference.provinces', 'reference.regions'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng public_security.address...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.address CASCADE;

-- Tạo bảng address với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE public_security.address (
    address_id SERIAL NOT NULL,                         -- ID tự tăng của địa chỉ (dùng SERIAL vì không quá lớn?)
    address_detail TEXT NOT NULL,                       -- Địa chỉ chi tiết (Số nhà, đường, thôn, xóm...)
    ward_id INT NOT NULL,                               -- Phường/Xã (FK reference.wards)
    district_id INT NOT NULL,                           -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    province_id INT NOT NULL,                           -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    region_id SMALLINT NOT NULL,                        -- Vùng/Miền (FK reference.regions) - Dùng cho truy vấn
    geographical_region VARCHAR(20) NOT NULL,           -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1
    postal_code VARCHAR(10),                            -- Mã bưu chính (nếu có)
    latitude DECIMAL(9,6),                              -- Vĩ độ (nếu có)
    longitude DECIMAL(9,6),                             -- Kinh độ (nếu có)
    -- geometry geometry(Point, 4326),                  -- Lưu trữ tọa độ dạng geometry của PostGIS (nếu cần)
    status BOOLEAN DEFAULT TRUE,                        -- Trạng thái địa chỉ (TRUE = đang sử dụng/hợp lệ)
    notes TEXT,                                         -- Ghi chú thêm

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                             -- User tạo bản ghi
    updated_by VARCHAR(50),                             -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_address PRIMARY KEY (address_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BCA)
    CONSTRAINT fk_address_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    CONSTRAINT fk_address_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    CONSTRAINT fk_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_address_lat_lon CHECK (
        (latitude IS NULL AND longitude IS NULL) OR -- Hoặc cả hai đều NULL
        (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180) -- Hoặc cả hai đều hợp lệ
    ),
    CONSTRAINT ck_address_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- province_id và district_id là NOT NULL, nên region_id cũng phải NOT NULL
        )
    -- Cân nhắc thêm UNIQUE constraint trên (address_detail, ward_id) nếu muốn tránh trùng lặp địa chỉ tuyệt đối?

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE public_security.address IS 'Lưu trữ thông tin chi tiết về các địa chỉ hành chính.';
COMMENT ON COLUMN public_security.address.address_id IS 'ID tự tăng duy nhất cho mỗi địa chỉ.';
COMMENT ON COLUMN public_security.address.address_detail IS 'Địa chỉ chi tiết (Số nhà, đường, thôn, xóm...).';
COMMENT ON COLUMN public_security.address.ward_id IS 'ID của Phường/Xã mà địa chỉ này thuộc về.';
COMMENT ON COLUMN public_security.address.district_id IS 'ID của Quận/Huyện - Cột phân vùng cấp 3.';
COMMENT ON COLUMN public_security.address.province_id IS 'ID của Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN public_security.address.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN public_security.address.postal_code IS 'Mã bưu chính (nếu có).';
COMMENT ON COLUMN public_security.address.latitude IS 'Vĩ độ địa lý.';
COMMENT ON COLUMN public_security.address.longitude IS 'Kinh độ địa lý.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
CREATE INDEX IF NOT EXISTS idx_address_ward_id ON public_security.address(ward_id);
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK
CREATE INDEX IF NOT EXISTS idx_address_postcode ON public_security.address(postal_code) WHERE postal_code IS NOT NULL;
-- CREATE INDEX IF NOT EXISTS idx_address_geometry ON public_security.address USING GIST (geometry); -- Nếu dùng PostGIS geometry
-- **ĐÃ XÓA DÒNG GÂY LỖI (ví dụ): CREATE INDEX IF NOT EXISTS idx_address_pk ON public_security.address(pk_address);**

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.address.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_public_security/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `ward_id` (cần join với reference tables).
-- 4. Data Loading: Nạp dữ liệu địa chỉ ban đầu (nếu có).
-- 5. Permissions: Đảm bảo các role (security_reader, security_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).

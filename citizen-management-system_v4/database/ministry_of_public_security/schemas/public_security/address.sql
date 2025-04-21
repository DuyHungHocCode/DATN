-- File: ministry_of_public_security/schemas/public_security/address.sql
-- Description: Tạo bảng address (địa chỉ chi tiết) trong schema public_security
--              của database ministry_of_public_security.
--              Bảng này được phân vùng theo Miền -> Tỉnh -> Huyện.
-- Version: 3.0 (Aligned with Microservices Structure)
-- =============================================================================

\echo '--> Tạo bảng public_security.address...'
-- Kết nối đến đúng database
\connect ministry_of_public_security

BEGIN;

-- Xóa bảng cũ nếu tồn tại để tạo lại sạch
DROP TABLE IF EXISTS public_security.address CASCADE;

-- Tạo bảng address với cấu trúc phân vùng 3 cấp
CREATE TABLE public_security.address (
    address_id SERIAL NOT NULL,                        -- ID địa chỉ (Khóa logic, không phải khóa chính vật lý)
    address_detail TEXT NOT NULL,                      -- Chi tiết địa chỉ (số nhà, đường, thôn, xóm...)
    ward_id INT NOT NULL,                              -- Phường/Xã (FK -> reference.wards)
    district_id INT NOT NULL,                          -- Quận/Huyện (FK -> reference.districts, Cột phân vùng cấp 3)
    province_id INT NOT NULL,                          -- Tỉnh/Thành phố (FK -> reference.provinces, Cột phân vùng cấp 2)
    address_type address_type NOT NULL,                -- Loại địa chỉ (ENUM: Thường trú, Tạm trú,...)
    postal_code VARCHAR(10),                           -- Mã bưu chính (tùy chọn)
    latitude DECIMAL(10, 8),                           -- Vĩ độ (cho GIS, tùy chọn)
    longitude DECIMAL(11, 8),                          -- Kinh độ (cho GIS, tùy chọn)
    status BOOLEAN DEFAULT TRUE NOT NULL,              -- Trạng thái địa chỉ (TRUE = còn sử dụng/hợp lệ)
    region_id SMALLINT NOT NULL,                       -- Vùng/Miền (FK -> reference.regions, Cột phân vùng cấp 1 dựa trên geographical_region)
    geographical_region VARCHAR(20) NOT NULL,          -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata (Thông tin quản lý bản ghi)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                            -- User tạo bản ghi (nếu cần theo dõi)
    updated_by VARCHAR(50),                            -- User cập nhật bản ghi lần cuối (nếu cần theo dõi)
    data_sensitivity_level data_sensitivity_level DEFAULT 'Công khai', -- Mức độ nhạy cảm của dữ liệu địa chỉ

    -- Ràng buộc Khóa chính (PRIMARY KEY)
    -- Bao gồm các cột phân vùng để đảm bảo tính duy nhất và hỗ trợ partition pruning.
    CONSTRAINT pk_address PRIMARY KEY (geographical_region, province_id, district_id, address_id),

    -- Ràng buộc Khóa ngoại (FOREIGN KEY)
    -- Tham chiếu đến các bảng reference cục bộ trong cùng database.
    CONSTRAINT fk_address_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id) ON DELETE RESTRICT, -- Không cho xóa phường/xã nếu có địa chỉ dùng
    CONSTRAINT fk_address_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id) ON DELETE RESTRICT, -- Không cho xóa quận/huyện nếu có địa chỉ dùng
    CONSTRAINT fk_address_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id) ON DELETE RESTRICT, -- Không cho xóa tỉnh/tp nếu có địa chỉ dùng
    CONSTRAINT fk_address_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id) ON DELETE RESTRICT, -- Không cho xóa vùng nếu có địa chỉ dùng

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_address_coordinates_valid CHECK (
            (latitude IS NULL AND longitude IS NULL) OR -- Hoặc không có tọa độ
            (latitude IS NOT NULL AND longitude IS NOT NULL AND -- Hoặc có cả hai và hợp lệ
             latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
        ),
    CONSTRAINT ck_address_geographical_region_valid CHECK (
            geographical_region IN ('Bắc', 'Trung', 'Nam') -- Đảm bảo giá trị hợp lệ cho cột phân vùng
        ),
    CONSTRAINT ck_address_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 theo Miền

-- Ghi chú về bảng và cột
COMMENT ON TABLE public_security.address IS '[BCA] Lưu trữ thông tin chi tiết về các địa chỉ hành chính.';
COMMENT ON COLUMN public_security.address.address_id IS 'ID logic duy nhất cho mỗi địa chỉ (không phải khóa chính vật lý).';
COMMENT ON COLUMN public_security.address.address_detail IS 'Địa chỉ chi tiết: số nhà, tên đường, thôn, xóm, tổ dân phố...';
COMMENT ON COLUMN public_security.address.ward_id IS 'Khóa ngoại tham chiếu đến bảng Phường/Xã (reference.wards).';
COMMENT ON COLUMN public_security.address.district_id IS 'Khóa ngoại tham chiếu đến Quận/Huyện (reference.districts), đồng thời là cột phân vùng cấp 3.';
COMMENT ON COLUMN public_security.address.province_id IS 'Khóa ngoại tham chiếu đến Tỉnh/Thành phố (reference.provinces), đồng thời là cột phân vùng cấp 2.';
COMMENT ON COLUMN public_security.address.address_type IS 'Loại địa chỉ (Thường trú, Tạm trú, Nơi ở hiện tại...).';
COMMENT ON COLUMN public_security.address.status IS 'Trạng thái của địa chỉ (TRUE: Còn sử dụng, FALSE: Không còn sử dụng/đã thay thế).';
COMMENT ON COLUMN public_security.address.region_id IS 'Khóa ngoại tham chiếu đến Vùng/Miền (reference.regions).';
COMMENT ON COLUMN public_security.address.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Dùng làm khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.address.pk_address IS 'Khóa chính vật lý, bao gồm các cột phân vùng và address_id.';

-- Các index sẽ được tạo sau khi các partition con được thiết lập
-- trong script partitioning/execute_setup.sql. Ví dụ các index cần tạo:
-- CREATE INDEX IF NOT EXISTS idx_address_ward_id ON public_security.address(ward_id);
-- CREATE INDEX IF NOT EXISTS idx_address_region_id ON public_security.address(region_id);
-- CREATE INDEX IF NOT EXISTS idx_address_status ON public_security.address(status);
-- CREATE INDEX IF NOT EXISTS idx_address_type ON public_security.address(address_type);
-- CREATE INDEX IF NOT EXISTS idx_address_geospatial ON public_security.address USING GIST (geography(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326))); -- Nếu dùng PostGIS

COMMIT;

\echo '--> Hoàn thành tạo bảng public_security.address.'
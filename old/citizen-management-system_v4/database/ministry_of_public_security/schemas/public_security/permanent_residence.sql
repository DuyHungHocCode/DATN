-- File: ministry_of_public_security/schemas/public_security/permanent_residence.sql
-- Description: Tạo bảng permanent_residence (Đăng ký thường trú) trong schema public_security.
--              Phiên bản dành cho kiến trúc Microservices.
-- Version: 3.0 (Microservices Alignment)
--
-- Changes from previous version:
-- - Removed household_id column (cross-database dependency).
-- - Removed relationship_with_head column (dependent on household_id).
-- - Removed commented-out foreign key to justice.household.
-- - Added notes regarding partitioning and unique index testing.
-- =============================================================================

\echo 'Creating table public_security.permanent_residence (Microservices version)...'
-- Kết nối đến DB Bộ Công an (giả sử đã kết nối từ script cha)
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng cũ nếu tồn tại để tạo lại
DROP TABLE IF EXISTS public_security.permanent_residence CASCADE;

-- Tạo bảng permanent_residence với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script trong thư mục partitioning
CREATE TABLE public_security.permanent_residence (
    permanent_residence_id SERIAL NOT NULL,              -- ID tự tăng của bản ghi đăng ký thường trú
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân được đăng ký (FK logic tới public_security.citizen)
    address_id INT NOT NULL,                             -- Địa chỉ thường trú (FK tới public_security.address)
    registration_date DATE NOT NULL,                     -- Ngày đăng ký thường trú
    decision_no VARCHAR(50) NOT NULL,                    -- Số quyết định/văn bản đăng ký thường trú
    issuing_authority_id SMALLINT NOT NULL,              -- Cơ quan cấp quyết định/đăng ký (FK reference.authorities)
    previous_address_id INT,                             -- ID địa chỉ thường trú trước đó (FK public_security.address, có thể NULL)
    change_reason TEXT,                                  -- Lý do thay đổi chỗ ở thường trú (nếu có)
    document_url VARCHAR(255),                           -- Đường dẫn đến tài liệu quét (scan) liên quan (nếu có)
    -- household_id INT,                                 -- !! ĐÃ XÓA !! - Liên kết logic với hộ khẩu BTP cần xử lý ở tầng ứng dụng/API
    -- relationship_with_head VARCHAR(50),               -- !! ĐÃ XÓA !! - Phụ thuộc vào household_id
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái đăng ký (TRUE = đang có hiệu lực/active)
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Lấy theo address_id)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho truy vấn & logic
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces) - Cột phân vùng cấp 2
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts) - Cột phân vùng cấp 3
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User/Ứng dụng tạo bản ghi
    updated_by VARCHAR(50),                              -- User/Ứng dụng cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng để tối ưu)
    CONSTRAINT pk_permanent_residence PRIMARY KEY (permanent_residence_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại (chỉ trong phạm vi DB BCA)
    -- Lưu ý: Cần kiểm tra kỹ hoạt động của FK đến các bảng đã phân vùng (citizen, address)
    CONSTRAINT fk_permanent_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Xóa đăng ký nếu công dân bị xóa
    CONSTRAINT fk_permanent_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id) ON DELETE RESTRICT, -- Không cho xóa địa chỉ nếu đang được dùng làm thường trú
    CONSTRAINT fk_permanent_residence_prev_address FOREIGN KEY (previous_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL, -- Nếu địa chỉ cũ bị xóa, chỉ set null ở đây
    CONSTRAINT fk_permanent_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_permanent_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_permanent_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_permanent_residence_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- !! ĐÃ XÓA FK đến justice.household !!

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_permanent_residence_date CHECK (registration_date <= CURRENT_DATE),
    CONSTRAINT ck_permanent_residence_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

COMMENT ON TABLE public_security.permanent_residence IS 'Lưu trữ thông tin đăng ký thường trú của công dân (DB Bộ Công an)';
COMMENT ON COLUMN public_security.permanent_residence.citizen_id IS 'ID công dân đăng ký thường trú';
COMMENT ON COLUMN public_security.permanent_residence.address_id IS 'ID địa chỉ thường trú (tham chiếu public_security.address)';
COMMENT ON COLUMN public_security.permanent_residence.registration_date IS 'Ngày đăng ký thường trú tại địa chỉ này';
COMMENT ON COLUMN public_security.permanent_residence.decision_no IS 'Số quyết định/văn bản đăng ký thường trú';
COMMENT ON COLUMN public_security.permanent_residence.issuing_authority_id IS 'Cơ quan công an cấp xã/phường/huyện nơi đăng ký';
COMMENT ON COLUMN public_security.permanent_residence.previous_address_id IS 'Địa chỉ thường trú trước đó (nếu có)';
COMMENT ON COLUMN public_security.permanent_residence.status IS 'Trạng thái đăng ký thường trú hiện tại (TRUE = còn hiệu lực)';
COMMENT ON COLUMN public_security.permanent_residence.geographical_region IS 'Miền địa lý (Bắc, Trung, Nam) - Khóa phân vùng cấp 1';
COMMENT ON COLUMN public_security.permanent_residence.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2';
COMMENT ON COLUMN public_security.permanent_residence.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3';


-- Indexes (sẽ được tạo trên từng partition bởi script partitioning/execute_setup.sql)
-- CREATE INDEX IF NOT EXISTS idx_permanent_residence_citizen_id ON public_security.permanent_residence(citizen_id);
-- CREATE INDEX IF NOT EXISTS idx_permanent_residence_address_id ON public_security.permanent_residence(address_id);
-- CREATE INDEX IF NOT EXISTS idx_permanent_residence_reg_date ON public_security.permanent_residence(registration_date);
-- CREATE INDEX IF NOT EXISTS idx_permanent_residence_status ON public_security.permanent_residence(status);

-- Chỉ mục unique đảm bảo mỗi công dân chỉ có một đăng ký thường trú đang hoạt động (status = TRUE)
-- Lưu ý: Cần kiểm tra kỹ hoạt động của UNIQUE INDEX trên bảng phân vùng.
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_permanent_residence_per_citizen
    ON public_security.permanent_residence (citizen_id)
    WHERE status = TRUE;
COMMENT ON INDEX public_security.uq_idx_active_permanent_residence_per_citizen IS 'Đảm bảo mỗi công dân chỉ có 1 đăng ký thường trú còn hiệu lực.';

-- TODO / Cần xử lý ở tầng khác:
-- 1. Triggers/Application Logic:
--    - Trigger cập nhật `updated_at`.
--    - Trigger/Logic cập nhật `geographical_region`, `province_id`, `district_id`, `region_id` dựa trên `address_id` khi INSERT/UPDATE.
--    - Logic (trong ứng dụng App BCA) để cập nhật `status=FALSE` cho bản ghi thường trú cũ khi có bản ghi mới cho cùng `citizen_id`.
--    - Logic (trong ứng dụng App BCA) để liên kết/hiển thị thông tin hộ khẩu từ App BTP (thông qua API calls) nếu cần thiết.
-- 2. Partitioning Setup: Script `partitioning/execute_setup.sql` cần được chạy để tạo các partition con và các index tương ứng trên đó.
-- 3. Unique Index Testing: Kiểm tra kỹ lưỡng `uq_idx_active_permanent_residence_per_citizen` hoạt động đúng trên môi trường phân vùng.

COMMIT;

\echo 'Table public_security.permanent_residence created/updated successfully (Microservices version).'
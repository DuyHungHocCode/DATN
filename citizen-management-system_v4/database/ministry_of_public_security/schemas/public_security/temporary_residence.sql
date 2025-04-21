-- =============================================================================
-- File: ministry_of_public_security/schemas/public_security/temporary_residence.sql
-- Description: Tạo bảng temporary_residence (Đăng ký tạm trú) trong schema public_security.
-- Version: 3.0 (Revised for Microservices Structure)
--
-- Dependencies:
-- - Script tạo schema 'public_security', 'reference'.
-- - Script tạo bảng 'reference.regions', 'reference.provinces', 'reference.districts', 'reference.authorities'.
-- - Script tạo bảng 'public_security.citizen', 'public_security.address'.
-- - Script tạo ENUMs liên quan (ví dụ: data_sensitivity_level).
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng public_security.temporary_residence...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.temporary_residence CASCADE;

-- Tạo bảng temporary_residence với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE public_security.temporary_residence (
    temporary_residence_id BIGSERIAL NOT NULL,              -- ID tự tăng của bản ghi đăng ký tạm trú (dùng BIGSERIAL cho bảng có thể rất lớn)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân đăng ký tạm trú (FK đến public_security.citizen)
    address_id INT NOT NULL,                             -- Địa chỉ tạm trú (FK đến public_security.address)
    registration_date DATE NOT NULL,                     -- Ngày đăng ký tạm trú
    expiry_date DATE,                                    -- Ngày hết hạn tạm trú (NULL = không xác định thời hạn)
    purpose VARCHAR(200) NOT NULL,                       -- Mục đích tạm trú (học tập, làm việc,...)
    registration_number VARCHAR(50) NOT NULL,            -- Số sổ/giấy đăng ký tạm trú (Yêu cầu duy nhất toàn cục)
    issuing_authority_id SMALLINT NOT NULL,              -- Cơ quan cấp đăng ký (FK đến reference.authorities)
    permanent_address_id INT,                            -- ID địa chỉ thường trú của công dân tại thời điểm đăng ký tạm trú (FK đến public_security.address)
    host_name VARCHAR(100),                              -- Tên chủ hộ/chủ nhà nơi tạm trú (nếu có)
    host_citizen_id VARCHAR(12),                         -- ID của chủ hộ/chủ nhà (FK đến public_security.citizen, nếu là công dân VN)
    host_relationship VARCHAR(50),                       -- Quan hệ với chủ hộ/chủ nhà
    document_url VARCHAR(255),                           -- Đường dẫn đến tài liệu quét (scan) (nếu có)
    extension_count SMALLINT DEFAULT 0,                  -- Số lần đã gia hạn tạm trú
    last_extension_date DATE,                            -- Ngày gia hạn gần nhất
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh thông tin
    verification_date DATE,                              -- Ngày xác minh
    verified_by VARCHAR(100),                            -- Người xác minh
    status VARCHAR(50) DEFAULT 'Active',                 -- Trạng thái đăng ký (Active, Expired, Cancelled, Extended)
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Thường lấy theo address_id của địa chỉ tạm trú)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế', -- Mức độ nhạy cảm của dữ liệu

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User tạo bản ghi
    updated_by VARCHAR(50),                              -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng để tối ưu truy vấn và đảm bảo tính duy nhất trong partition)
    CONSTRAINT pk_temporary_residence PRIMARY KEY (temporary_residence_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất (Cần kiểm tra kỹ với partitioning)
    -- Đảm bảo số đăng ký tạm trú là duy nhất trên toàn hệ thống
    CONSTRAINT uq_temporary_residence_reg_num UNIQUE (registration_number),

    -- Ràng buộc Khóa ngoại (chỉ tham chiếu đến bảng trong cùng database BCA)
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng.
    -- PostgreSQL hiện đại hỗ trợ FK đến bảng được phân vùng nếu tham chiếu đến PK logic.
    CONSTRAINT fk_temporary_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Nếu xóa công dân thì xóa luôn đăng ký tạm trú
    CONSTRAINT fk_temporary_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id) ON DELETE RESTRICT, -- Không cho xóa địa chỉ nếu đang có người tạm trú tại đó
    CONSTRAINT fk_temporary_residence_perm_addr FOREIGN KEY (permanent_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL, -- Nếu xóa địa chỉ thường trú cũ thì chỉ set null ở đây
    CONSTRAINT fk_temporary_residence_host FOREIGN KEY (host_citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE SET NULL, -- Nếu xóa chủ hộ thì chỉ set null
    CONSTRAINT fk_temporary_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_temporary_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_temporary_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_temporary_residence_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_temporary_residence_dates CHECK (
        registration_date <= CURRENT_DATE AND
        (expiry_date IS NULL OR expiry_date >= registration_date) AND -- Ngày hết hạn phải sau hoặc bằng ngày đăng ký
        (last_extension_date IS NULL OR (last_extension_date >= registration_date AND last_extension_date <= CURRENT_DATE)) AND
        (verification_date IS NULL OR verification_date <= CURRENT_DATE)
    ),
    CONSTRAINT ck_temporary_residence_status CHECK (status IN ('Active', 'Expired', 'Cancelled', 'Extended')), -- Các trạng thái hợp lệ
    CONSTRAINT ck_temporary_residence_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- province_id và district_id là NOT NULL, nên region_id cũng phải NOT NULL và thuộc 1 trong 3 miền
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE public_security.temporary_residence IS 'Lưu thông tin đăng ký tạm trú của công dân.';
COMMENT ON COLUMN public_security.temporary_residence.temporary_residence_id IS 'ID tự tăng của bản ghi đăng ký tạm trú.';
COMMENT ON COLUMN public_security.temporary_residence.citizen_id IS 'ID công dân đăng ký tạm trú.';
COMMENT ON COLUMN public_security.temporary_residence.address_id IS 'ID địa chỉ nơi công dân đăng ký tạm trú.';
COMMENT ON COLUMN public_security.temporary_residence.registration_date IS 'Ngày đăng ký tạm trú.';
COMMENT ON COLUMN public_security.temporary_residence.expiry_date IS 'Ngày hết hạn đăng ký tạm trú (nếu có thời hạn).';
COMMENT ON COLUMN public_security.temporary_residence.purpose IS 'Mục đích đăng ký tạm trú.';
COMMENT ON COLUMN public_security.temporary_residence.registration_number IS 'Số sổ/giấy đăng ký tạm trú (yêu cầu duy nhất).';
COMMENT ON COLUMN public_security.temporary_residence.permanent_address_id IS 'ID địa chỉ thường trú của công dân tại thời điểm đăng ký tạm trú.';
COMMENT ON COLUMN public_security.temporary_residence.host_citizen_id IS 'ID công dân của chủ hộ/chủ nhà nơi tạm trú (nếu có).';
COMMENT ON COLUMN public_security.temporary_residence.status IS 'Trạng thái của đăng ký tạm trú (Active, Expired, Cancelled, Extended).';
COMMENT ON COLUMN public_security.temporary_residence.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN public_security.temporary_residence.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN public_security.temporary_residence.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên các khóa ngoại và cột thường dùng để lọc/sắp xếp
CREATE INDEX IF NOT EXISTS idx_temporary_residence_citizen_id ON public_security.temporary_residence(citizen_id);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_address_id ON public_security.temporary_residence(address_id);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_reg_date ON public_security.temporary_residence(registration_date);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_expiry_date ON public_security.temporary_residence(expiry_date);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_status ON public_security.temporary_residence(status);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_perm_addr_id ON public_security.temporary_residence(permanent_address_id) WHERE permanent_address_id IS NOT NULL; -- Index có điều kiện
CREATE INDEX IF NOT EXISTS idx_temporary_residence_host_citizen_id ON public_security.temporary_residence(host_citizen_id) WHERE host_citizen_id IS NOT NULL; -- Index có điều kiện
-- Index trên registration_number đã được tạo tự động bởi ràng buộc UNIQUE
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK và giúp partition pruning

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.temporary_residence.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_public_security/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger (hoặc dùng job định kỳ) tự động cập nhật `status` thành 'Expired' khi `expiry_date` < CURRENT_DATE.
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `address_id`.
-- 4. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 5. Permissions: Đảm bảo các role (security_reader, security_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 6. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của ràng buộc UNIQUE `uq_temporary_residence_reg_num` trên môi trường có partitioning. Xem xét lại nếu `registration_number` không thực sự unique toàn quốc.

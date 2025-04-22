-- File: ministry_of_public_security/schemas/public_security/temporary_absence.sql
-- Description: Tạo bảng temporary_absence (Đăng ký tạm vắng) trong schema public_security.
-- Version: 3.0 (Revised for Microservices Structure)
--
-- Dependencies:
-- - Script tạo schema 'public_security', 'reference'.
-- - Script tạo bảng 'reference.regions', 'reference.provinces', 'reference.authorities', 'reference.address'.
-- - Script tạo bảng 'public_security.citizen'.
-- - Script tạo ENUMs liên quan (ví dụ: data_sensitivity_level).
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng public_security.temporary_absence...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.temporary_absence CASCADE;

-- Tạo bảng temporary_absence với cấu trúc phân vùng
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE public_security.temporary_absence (
    temporary_absence_id BIGSERIAL NOT NULL,             -- ID tự tăng của bản ghi đăng ký tạm vắng (dùng BIGSERIAL cho bảng lớn)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân đăng ký tạm vắng (FK đến public_security.citizen)
    from_date DATE NOT NULL,                             -- Ngày bắt đầu tạm vắng
    to_date DATE,                                        -- Ngày dự kiến kết thúc tạm vắng (NULL = chưa xác định)
    reason TEXT NOT NULL,                                -- Lý do tạm vắng
    destination_address_id INT,                          -- Địa chỉ nơi đến (FK đến public_security.address) (nếu có)
    destination_detail TEXT,                             -- Chi tiết nơi đến (nếu không có address_id cụ thể hoặc địa chỉ ngoài VN)
    contact_information TEXT,                            -- Thông tin liên lạc trong thời gian tạm vắng
    registration_authority_id SMALLINT,                  -- Cơ quan tiếp nhận đăng ký (FK đến reference.authorities)
    registration_number VARCHAR(50),                     -- Số giấy/sổ đăng ký tạm vắng (có thể NULL, nhưng nếu có nên là duy nhất?)
    document_url VARCHAR(255),                           -- Đường dẫn đến tài liệu quét (scan) (nếu có)
    return_date DATE,                                    -- Ngày thực tế quay lại (có thể khác to_date)
    return_confirmed BOOLEAN DEFAULT FALSE,              -- Đã xác nhận quay lại hay chưa
    return_confirmed_by VARCHAR(100),                    -- Người/Cán bộ xác nhận quay lại
    return_confirmed_date DATE,                          -- Ngày xác nhận quay lại
    return_notes TEXT,                                   -- Ghi chú khi quay lại
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh thông tin
    verification_date DATE,                              -- Ngày xác minh
    verified_by VARCHAR(100),                            -- Người xác minh
    status VARCHAR(50) DEFAULT 'Active',                 -- Trạng thái đăng ký (Active, Expired, Cancelled, Returned)
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký của công dân)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế', -- Mức độ nhạy cảm của dữ liệu

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User tạo bản ghi
    updated_by VARCHAR(50),                              -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng để đảm bảo tính duy nhất và hiệu năng)
    CONSTRAINT pk_temporary_absence PRIMARY KEY (temporary_absence_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại (chỉ tham chiếu đến bảng trong cùng database BCA)
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng.
    -- PostgreSQL hiện đại hỗ trợ FK đến bảng được phân vùng nếu tham chiếu đến PK logic.
    CONSTRAINT fk_temporary_absence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Nếu xóa công dân thì xóa luôn đăng ký tạm vắng
    CONSTRAINT fk_temporary_absence_dest_addr FOREIGN KEY (destination_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL, -- Nếu xóa địa chỉ thì chỉ set null
    CONSTRAINT fk_temporary_absence_authority FOREIGN KEY (registration_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_temporary_absence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_temporary_absence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_temporary_absence_dates CHECK (
        from_date <= CURRENT_DATE AND
        (to_date IS NULL OR to_date >= from_date) AND -- Ngày kết thúc phải sau hoặc bằng ngày bắt đầu
        (return_date IS NULL OR return_date >= from_date) AND
        (return_confirmed_date IS NULL OR (return_confirmed_date >= from_date AND return_confirmed_date <= CURRENT_DATE)) AND
        (verification_date IS NULL OR verification_date <= CURRENT_DATE)
    ),
    CONSTRAINT ck_temporary_absence_status CHECK (status IN ('Active', 'Expired', 'Cancelled', 'Returned')), -- Trạng thái hợp lệ
    CONSTRAINT ck_temporary_absence_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- Không cho phép NULL vì province_id là NOT NULL và province luôn thuộc 1 region
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) sẽ được tạo bởi script partitioning/execute_setup.sql

COMMENT ON TABLE public_security.temporary_absence IS 'Lưu thông tin đăng ký tạm vắng của công dân.';
COMMENT ON COLUMN public_security.temporary_absence.temporary_absence_id IS 'ID tự tăng của bản ghi đăng ký tạm vắng.';
COMMENT ON COLUMN public_security.temporary_absence.citizen_id IS 'ID công dân đăng ký tạm vắng.';
COMMENT ON COLUMN public_security.temporary_absence.from_date IS 'Ngày bắt đầu tạm vắng.';
COMMENT ON COLUMN public_security.temporary_absence.to_date IS 'Ngày dự kiến kết thúc tạm vắng.';
COMMENT ON COLUMN public_security.temporary_absence.reason IS 'Lý do tạm vắng.';
COMMENT ON COLUMN public_security.temporary_absence.destination_address_id IS 'ID địa chỉ nơi đến tạm vắng (nếu trong nước và có địa chỉ cụ thể).';
COMMENT ON COLUMN public_security.temporary_absence.destination_detail IS 'Chi tiết nơi đến (nếu không có address_id hoặc đi nước ngoài).';
COMMENT ON COLUMN public_security.temporary_absence.registration_number IS 'Số giấy/sổ đăng ký tạm vắng (nếu có).';
COMMENT ON COLUMN public_security.temporary_absence.return_date IS 'Ngày thực tế công dân quay lại nơi cư trú.';
COMMENT ON COLUMN public_security.temporary_absence.return_confirmed IS 'Trạng thái xác nhận công dân đã quay lại.';
COMMENT ON COLUMN public_security.temporary_absence.status IS 'Trạng thái của việc đăng ký tạm vắng (Active, Expired, Cancelled, Returned).';
COMMENT ON COLUMN public_security.temporary_absence.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN public_security.temporary_absence.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên khóa ngoại và các cột thường dùng để lọc/sắp xếp
CREATE INDEX IF NOT EXISTS idx_temporary_absence_citizen_id ON public_security.temporary_absence(citizen_id);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_from_date ON public_security.temporary_absence(from_date);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_to_date ON public_security.temporary_absence(to_date);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_status ON public_security.temporary_absence(status);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_return_date ON public_security.temporary_absence(return_date);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_dest_addr_id ON public_security.temporary_absence(destination_address_id) WHERE destination_address_id IS NOT NULL; -- Partial index
CREATE INDEX IF NOT EXISTS idx_temporary_absence_province_id ON public_security.temporary_absence(province_id); -- Hỗ trợ partition pruning / truy vấn theo tỉnh

-- Chỉ mục unique đảm bảo số đăng ký tạm vắng là duy nhất (nếu có và yêu cầu là unique toàn cục)
-- Cần kiểm tra kỹ xem ràng buộc này có thực sự cần thiết và khả thi trên bảng phân vùng không.
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_temporary_absence_reg_num
    ON public_security.temporary_absence (registration_number)
    WHERE registration_number IS NOT NULL;

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.temporary_absence.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_public_security/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh.
-- 2. Indexes: Script trên cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger tự động cập nhật `status` thành 'Expired' khi `to_date` < CURRENT_DATE (nếu `to_date` không null). Có thể thay bằng job định kỳ.
--    - Tạo trigger cập nhật `status` thành 'Returned' khi `return_confirmed` = TRUE.
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `region_id`) dựa trên thông tin `citizen_id` (lấy từ nơi đăng ký thường trú/tạm trú của công dân).
-- 4. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 5. Permissions: Đảm bảo các role (security_reader, security_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
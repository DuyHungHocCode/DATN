-- =============================================================================
-- File: database/schemas/public_security/temporary_absence.sql
-- Description: Tạo bảng temporary_absence (Đăng ký tạm vắng) trong schema public_security.
--              Bảng này được tách ra từ residence.sql cũ.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating temporary_absence table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.temporary_absence CASCADE;

-- Create the temporary_absence table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.temporary_absence (
    temporary_absence_id SERIAL NOT NULL,                -- ID tự tăng của bản ghi đăng ký tạm vắng
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân đăng ký tạm vắng (FK public_security.citizen)
    from_date DATE NOT NULL,                             -- Ngày bắt đầu tạm vắng
    to_date DATE,                                        -- Ngày dự kiến kết thúc tạm vắng (NULL = chưa xác định)
    reason TEXT NOT NULL,                                -- Lý do tạm vắng
    destination_address_id INT,                          -- Địa chỉ nơi đến (FK public_security.address) (nếu có)
    destination_detail TEXT,                             -- Chi tiết nơi đến (nếu không có address_id cụ thể)
    contact_information TEXT,                            -- Thông tin liên lạc trong thời gian tạm vắng
    registration_authority_id SMALLINT,                  -- Cơ quan tiếp nhận đăng ký (FK reference.authorities)
    registration_number VARCHAR(50),                     -- Số giấy/sổ đăng ký tạm vắng (có thể NULL)
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
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế', -- Mức độ nhạy cảm

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_temporary_absence PRIMARY KEY (temporary_absence_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_temporary_absence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_temporary_absence_dest_addr FOREIGN KEY (destination_address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_temporary_absence_authority FOREIGN KEY (registration_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_temporary_absence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_temporary_absence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_temporary_absence_dates CHECK (
        from_date <= CURRENT_DATE AND
        (to_date IS NULL OR to_date >= from_date) AND -- Ngày kết thúc phải sau hoặc bằng ngày bắt đầu
        (return_date IS NULL OR return_date >= from_date) AND
        (return_confirmed_date IS NULL OR (return_confirmed_date >= from_date AND return_confirmed_date <= CURRENT_DATE)) AND
        (verification_date IS NULL OR verification_date <= CURRENT_DATE)
    ),
    CONSTRAINT ck_temporary_absence_status CHECK (status IN ('Active', 'Expired', 'Cancelled', 'Returned')),
    CONSTRAINT ck_temporary_absence_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_temporary_absence_citizen_id ON public_security.temporary_absence(citizen_id);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_from_date ON public_security.temporary_absence(from_date);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_to_date ON public_security.temporary_absence(to_date);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_status ON public_security.temporary_absence(status);
CREATE INDEX IF NOT EXISTS idx_temporary_absence_return_date ON public_security.temporary_absence(return_date);

-- Chỉ mục unique đảm bảo số đăng ký tạm vắng là duy nhất (nếu có)
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_temporary_absence_reg_num
    ON public_security.temporary_absence (registration_number)
    WHERE registration_number IS NOT NULL;

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, region_id dựa trên địa chỉ đăng ký của citizen.
--    - Trigger tự động cập nhật status thành 'Expired' khi to_date < CURRENT_DATE (nếu to_date không null).
--    - Trigger cập nhật status thành 'Returned' khi return_confirmed = TRUE.
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.

COMMIT;

\echo 'temporary_absence table created successfully with partitioning, constraints, and indexes.'
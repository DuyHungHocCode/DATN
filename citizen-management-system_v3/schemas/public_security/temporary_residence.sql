-- =============================================================================
-- File: database/schemas/public_security/temporary_residence.sql
-- Description: Tạo bảng temporary_residence (Đăng ký tạm trú) trong schema public_security.
--              Bảng này được tách ra từ residence.sql cũ.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating temporary_residence table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.temporary_residence CASCADE;

-- Create the temporary_residence table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.temporary_residence (
    temporary_residence_id SERIAL NOT NULL,              -- ID tự tăng của bản ghi đăng ký tạm trú
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân đăng ký tạm trú (FK public_security.citizen)
    address_id INT NOT NULL,                             -- Địa chỉ tạm trú (FK public_security.address)
    registration_date DATE NOT NULL,                     -- Ngày đăng ký tạm trú
    expiry_date DATE,                                    -- Ngày hết hạn tạm trú (NULL = không xác định)
    purpose VARCHAR(200) NOT NULL,                       -- Mục đích tạm trú (học tập, làm việc,...)
    registration_number VARCHAR(50) NOT NULL,            -- Số giấy/sổ đăng ký tạm trú (Unique)
    issuing_authority_id SMALLINT NOT NULL,              -- Cơ quan cấp đăng ký (FK reference.authorities)
    permanent_address_id INT,                            -- Địa chỉ thường trú của công dân (FK public_security.address)
    host_name VARCHAR(100),                              -- Tên chủ hộ/chủ nhà nơi tạm trú (nếu có)
    host_citizen_id VARCHAR(12),                         -- ID của chủ hộ/chủ nhà (FK public_security.citizen)
    host_relationship VARCHAR(50),                       -- Quan hệ với chủ hộ/chủ nhà
    document_url VARCHAR(255),                           -- Đường dẫn đến tài liệu quét (scan) (nếu có)
    extension_count SMALLINT DEFAULT 0,                  -- Số lần đã gia hạn
    last_extension_date DATE,                            -- Ngày gia hạn gần nhất
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh thông tin
    verification_date DATE,                              -- Ngày xác minh
    verified_by VARCHAR(100),                            -- Người xác minh
    status VARCHAR(50) DEFAULT 'Active',                 -- Trạng thái đăng ký (Active, Expired, Cancelled, Extended)
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
    CONSTRAINT pk_temporary_residence PRIMARY KEY (temporary_residence_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_temporary_residence_reg_num UNIQUE (registration_number),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_temporary_residence_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_temporary_residence_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_temporary_residence_perm_addr FOREIGN KEY (permanent_address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_temporary_residence_host FOREIGN KEY (host_citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE SET NULL,
    CONSTRAINT fk_temporary_residence_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_temporary_residence_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_temporary_residence_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_temporary_residence_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_temporary_residence_dates CHECK (
        registration_date <= CURRENT_DATE AND
        (expiry_date IS NULL OR expiry_date >= registration_date) AND -- Ngày hết hạn phải sau hoặc bằng ngày đăng ký
        (last_extension_date IS NULL OR (last_extension_date >= registration_date AND last_extension_date <= CURRENT_DATE)) AND
        (verification_date IS NULL OR verification_date <= CURRENT_DATE)
    ),
    CONSTRAINT ck_temporary_residence_status CHECK (status IN ('Active', 'Expired', 'Cancelled', 'Extended')),
    CONSTRAINT ck_temporary_residence_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_temporary_residence_citizen_id ON public_security.temporary_residence(citizen_id);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_address_id ON public_security.temporary_residence(address_id);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_reg_date ON public_security.temporary_residence(registration_date);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_expiry_date ON public_security.temporary_residence(expiry_date);
CREATE INDEX IF NOT EXISTS idx_temporary_residence_status ON public_security.temporary_residence(status);
-- Index trên registration_number đã được tạo tự động bởi ràng buộc UNIQUE

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên address_id.
--    - Trigger tự động cập nhật status thành 'Expired' khi expiry_date < CURRENT_DATE (có thể dùng job thay thế).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.

COMMIT;

\echo 'temporary_residence table created successfully with partitioning, constraints, and indexes.'
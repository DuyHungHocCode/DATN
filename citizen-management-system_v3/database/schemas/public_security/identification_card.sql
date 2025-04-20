-- =============================================================================
-- File: database/schemas/public_security/identification_card.sql
-- Description: Tạo bảng identification_card (CCCD/CMND) trong schema public_security.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating identification_card table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.identification_card CASCADE;

-- Create the identification_card table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.identification_card (
    card_id SERIAL NOT NULL,                            -- ID tự tăng của thẻ
    citizen_id VARCHAR(12) NOT NULL,                    -- Số CCCD/Định danh của công dân (FK public_security.citizen)
    card_number VARCHAR(12) NOT NULL,                   -- Số thẻ CCCD/CMND (Unique)
    issue_date DATE NOT NULL,                           -- Ngày cấp
    expiry_date DATE,                                   -- Ngày hết hạn
    issuing_authority_id SMALLINT,                      -- Cơ quan cấp (FK reference.authorities)
    card_type card_type NOT NULL,                       -- Loại thẻ (ENUM: CMND 9 số, CMND 12 số, CCCD, CCCD gắn chip)

    chip_serial_number VARCHAR(50),                     -- Số serial của chip (nếu là CCCD gắn chip)
    card_status card_status NOT NULL DEFAULT 'Đang sử dụng', -- Trạng thái thẻ (ENUM)
    previous_card_number VARCHAR(12),                   -- Số thẻ cũ (nếu là cấp đổi)
    notes TEXT,                                         -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng
    region_id SMALLINT,                                 -- Vùng/Miền (FK reference.regions, dùng cho phân vùng và query)
    province_id INT NOT NULL,                           -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,           -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_identification_card PRIMARY KEY (card_id, geographical_region, province_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_identification_card_number UNIQUE (card_number),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) yêu cầu citizen_id phải là unique toàn cục hoặc có global unique index.
    CONSTRAINT fk_identification_card_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_identification_card_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_identification_card_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_identification_card_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_identification_card_dates CHECK (issue_date <= CURRENT_DATE AND (expiry_date IS NULL OR expiry_date > issue_date)),
    CONSTRAINT ck_card_number_format CHECK (
            (card_type = 'CMND 9 số' AND card_number ~ '^[0-9]{9}$') OR
            (card_type = 'CMND 12 số' AND card_number ~ '^[0-9]{12}$') OR
            (card_type IN ('CCCD', 'CCCD gắn chip') AND card_number ~ '^[0-9]{12}$')
        ),
    CONSTRAINT ck_chip_serial_required CHECK ( (card_type = 'CCCD gắn chip' AND chip_serial_number IS NOT NULL) OR (card_type != 'CCCD gắn chip') ),
    CONSTRAINT ck_identification_card_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu chưa xác định
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_identification_card_citizen_id ON public_security.identification_card(citizen_id);
CREATE INDEX IF NOT EXISTS idx_identification_card_card_status ON public_security.identification_card(card_status);
CREATE INDEX IF NOT EXISTS idx_identification_card_issue_date ON public_security.identification_card(issue_date);
CREATE INDEX IF NOT EXISTS idx_identification_card_expiry_date ON public_security.identification_card(expiry_date);
-- Chỉ mục unique đảm bảo mỗi công dân chỉ có 1 thẻ đang sử dụng
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_id_card_per_citizen ON public_security.identification_card (citizen_id) WHERE card_status = 'Đang sử dụng';


-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
--    - Trigger tự động cập nhật trạng thái thẻ cũ thành 'Đã thay thế' khi cấp thẻ mới.
--    - Trigger cập nhật geographical_region, province_id, region_id dựa trên địa chỉ của citizen.

COMMIT;

\echo 'identification_card table created successfully with partitioning, constraints, and indexes.'
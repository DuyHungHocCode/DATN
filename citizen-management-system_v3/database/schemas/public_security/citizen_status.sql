-- =============================================================================
-- File: database/schemas/public_security/citizen_status.sql
-- Description: Tạo bảng citizen_status (Trạng thái công dân) trong schema public_security.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating citizen_status table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_status CASCADE;

-- Create the citizen_status table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.citizen_status (
    status_id SERIAL NOT NULL,                           -- ID tự tăng của bản ghi trạng thái
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân liên quan (FK public_security.citizen)
    status_type death_status NOT NULL DEFAULT 'Còn sống', -- Trạng thái hiện tại (ENUM: Còn sống, Đã mất, Mất tích)
    status_date DATE NOT NULL,                           -- Ngày trạng thái này có hiệu lực/xảy ra
    description TEXT,                                    -- Mô tả chi tiết về thay đổi trạng thái
    cause VARCHAR(200),                                  -- Nguyên nhân (VD: Nguyên nhân tử vong)
    location VARCHAR(200),                               -- Địa điểm xảy ra (VD: Nơi mất)
    authority_id SMALLINT,                               -- Cơ quan xác nhận trạng thái (FK reference.authorities)
    document_number VARCHAR(50),                         -- Số hiệu văn bản liên quan (VD: Giấy báo tử, Quyết định mất tích)
    document_date DATE,                                  -- Ngày của văn bản liên quan
    certificate_id VARCHAR(50),                          -- ID giấy chứng nhận liên quan (VD: death_certificate_id)
    reported_by VARCHAR(100),                            -- Người báo tin/cung cấp thông tin
    relationship VARCHAR(50),                            -- Mối quan hệ của người báo tin với công dân
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh thông tin
    is_current BOOLEAN DEFAULT TRUE,                     -- Bản ghi trạng thái này có phải là mới nhất/còn hiệu lực không (thay cho status)
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký của công dân)
    region_id SMALLINT,                                  -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_citizen_status PRIMARY KEY (status_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_citizen_status_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_citizen_status_authority FOREIGN KEY (authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_citizen_status_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_status_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_citizen_status_date CHECK (status_date <= CURRENT_DATE),
    CONSTRAINT ck_citizen_document_date CHECK (document_date IS NULL OR (document_date <= CURRENT_DATE AND document_date >= status_date)),
    CONSTRAINT ck_citizen_cause_location_required CHECK (
        (status_type IN ('Đã mất', 'Mất tích') AND cause IS NOT NULL AND location IS NOT NULL) OR
        (status_type = 'Còn sống')
    ),
    CONSTRAINT ck_citizen_status_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu chưa xác định
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_citizen_status_citizen_id ON public_security.citizen_status(citizen_id);
CREATE INDEX IF NOT EXISTS idx_citizen_status_status_type ON public_security.citizen_status(status_type);
CREATE INDEX IF NOT EXISTS idx_citizen_status_status_date ON public_security.citizen_status(status_date);
CREATE INDEX IF NOT EXISTS idx_citizen_status_doc_num ON public_security.citizen_status(document_number) WHERE document_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_status_is_current ON public_security.citizen_status(is_current);

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, region_id dựa trên địa chỉ đăng ký của citizen.
--    - Trigger tự động cập nhật `is_current = FALSE` cho các bản ghi cũ khi có bản ghi mới `is_current = TRUE` cho cùng citizen_id.
--    - Trigger tự động cập nhật `public_security.citizen.death_status` khi có thay đổi ở bảng này (quan trọng).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.
-- 3. Views: Tạo view `vw_current_citizen_status` chỉ hiển thị bản ghi `is_current = TRUE` cho mỗi công dân.

COMMIT;

\echo 'citizen_status table created successfully with partitioning, constraints, and indexes.'
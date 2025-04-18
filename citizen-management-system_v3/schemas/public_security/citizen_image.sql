-- =============================================================================
-- File: database/schemas/public_security/citizen_image.sql
-- Description: Tạo bảng citizen_image để lưu trữ ảnh của công dân.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating citizen_image table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_image CASCADE;

-- Create the citizen_image table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST) (Giả định tương tự biometric_data)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.citizen_image (
    image_id SERIAL NOT NULL,                            -- ID tự tăng của ảnh
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân sở hữu ảnh (FK public_security.citizen)
    image_type VARCHAR(50) NOT NULL,                     -- Loại ảnh (vd: 'Chân dung 3x4', 'Toàn thân', 'CCCD Mặt trước', 'CCCD Mặt sau')
    image_data BYTEA NOT NULL,                           -- Dữ liệu ảnh (dạng nhị phân)
    image_format VARCHAR(20) NOT NULL,                   -- Định dạng ảnh (JPG, PNG, JP2, etc.)
    image_size INTEGER,                                  -- Kích thước ảnh (bytes) - Có thể tính bằng trigger
    width INTEGER,                                       -- Chiều rộng ảnh (pixels) - Có thể tính bằng trigger
    height INTEGER,                                      -- Chiều cao ảnh (pixels) - Có thể tính bằng trigger
    dpi INTEGER,                                         -- Độ phân giải (dots per inch) - Nếu có
    capture_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Thời điểm chụp/tải lên
    expiry_date DATE,                                    -- Ngày ảnh hết hạn (vd: ảnh thẻ CCCD)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái sử dụng của ảnh (TRUE = Active/Current)
    purpose VARCHAR(100),                                -- Mục đích sử dụng ảnh
    device_id VARCHAR(50),                               -- ID thiết bị chụp/scan
    photographer VARCHAR(100),                           -- Người chụp ảnh/scan
    location_taken VARCHAR(200),                         -- Địa điểm chụp/scan

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi chụp/nơi đăng ký)
    region_id SMALLINT,                                  -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1
    hash_value VARCHAR(128),                             -- Giá trị hash để kiểm tra tính toàn vẹn

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_citizen_image PRIMARY KEY (image_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_citizen_image_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_citizen_image_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_image_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_citizen_image_dimensions CHECK (width IS NULL OR width > 0),
    CONSTRAINT ck_citizen_image_height CHECK (height IS NULL OR height > 0),
    CONSTRAINT ck_citizen_image_dpi CHECK (dpi IS NULL OR dpi > 0),
    CONSTRAINT ck_citizen_image_dates CHECK (expiry_date IS NULL OR expiry_date > capture_date),
    CONSTRAINT ck_citizen_image_format CHECK (image_format = upper(image_format)), -- Đảm bảo định dạng viết hoa
    CONSTRAINT ck_citizen_image_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu chưa xác định
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_citizen_image_citizen_id ON public_security.citizen_image(citizen_id);
CREATE INDEX IF NOT EXISTS idx_citizen_image_type ON public_security.citizen_image(image_type);
CREATE INDEX IF NOT EXISTS idx_citizen_image_capture_date ON public_security.citizen_image(capture_date);
CREATE INDEX IF NOT EXISTS idx_citizen_image_status ON public_security.citizen_image(status);
-- CREATE INDEX IF NOT EXISTS idx_citizen_image_hash ON public_security.citizen_image USING HASH (hash_value); -- Nếu cần tìm theo hash

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
--    - Trigger tự động tính toán image_size, width, height từ image_data (nếu khả thi và cần thiết).
--    - Trigger kiểm tra/cập nhật hash_value.
--    - Trigger cập nhật geographical_region, province_id, region_id.
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.
-- 3. Security: Cân nhắc Row-Level Security (RLS) nếu cần kiểm soát truy cập ảnh chặt chẽ.

COMMIT;

\echo 'citizen_image table created successfully with partitioning, constraints, and indexes.'
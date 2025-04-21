-- =============================================================================
-- File: database/schemas/central_server/integrated_household.sql
-- Description: Tạo bảng integrated_household trong schema central,
--              tích hợp dữ liệu hộ khẩu từ các nguồn (chủ yếu là Bộ Tư pháp).
-- Version: 1.0
-- =============================================================================

\echo 'Creating integrated_household table for Central Server database...'
\connect national_citizen_central_server

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS central.integrated_household CASCADE;

-- Create the integrated_household table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE central.integrated_household (
    integrated_household_id BIGSERIAL NOT NULL,          -- Khóa chính tự tăng của bản ghi tích hợp
    source_system VARCHAR(50) NOT NULL,                  -- Nguồn dữ liệu gốc ('Bộ Tư pháp', 'Bộ Công an'?)
    source_household_id VARCHAR(50) NOT NULL,            -- Khóa chính của hộ khẩu ở hệ thống nguồn (vd: justice.household.household_id)

    household_book_no VARCHAR(20) NOT NULL,              -- Số sổ hộ khẩu
    head_of_household_citizen_id VARCHAR(12),            -- ID công dân của chủ hộ (FK central.integrated_citizen)
    -- Thay vì FK đến address, lưu trực tiếp thông tin khóa ngoại địa chỉ
    address_detail TEXT,                                 -- Chi tiết địa chỉ (denormalized hoặc lấy từ integrated_address)
    ward_id INT NOT NULL,                                -- Phường/Xã (FK reference.wards)
    -- district_id, province_id, region_id, geographical_region được dùng cho phân vùng và FK ở dưới

    registration_date DATE,                              -- Ngày đăng ký hộ khẩu gốc
    issuing_authority_id SMALLINT,                       -- Cơ quan cấp sổ gốc (FK reference.authorities)
    household_type household_type,                       -- Loại hộ khẩu (ENUM)
    status household_status,                             -- Trạng thái hộ khẩu (ENUM)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata đồng bộ và tích hợp
    source_created_at TIMESTAMP WITH TIME ZONE,          -- Thời điểm tạo ở nguồn
    source_updated_at TIMESTAMP WITH TIME ZONE,          -- Thời điểm cập nhật ở nguồn
    integrated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tích hợp/cập nhật vào central

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_integrated_household PRIMARY KEY (integrated_household_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất: Đảm bảo không có bản ghi trùng lặp từ cùng một nguồn
    CONSTRAINT uq_integrated_household_source UNIQUE (source_system, source_household_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng integrated_citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_integrated_household_head FOREIGN KEY (head_of_household_citizen_id) REFERENCES central.integrated_citizen(citizen_id) ON DELETE SET NULL,
    CONSTRAINT fk_integrated_household_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    CONSTRAINT fk_integrated_household_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    CONSTRAINT fk_integrated_household_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_integrated_household_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_integrated_household_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    -- CONSTRAINT fk_integrated_household_sync_batch FOREIGN KEY (last_sync_batch_id) REFERENCES sync.sync_batch(batch_id), -- Nếu bảng sync_batch ở schema sync

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_integrated_household_dates CHECK (registration_date IS NULL OR registration_date <= CURRENT_DATE),
    CONSTRAINT ck_integrated_household_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_source ON central.integrated_household(source_system, source_household_id);
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_book_no ON central.integrated_household(household_book_no);
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_head_id ON central.integrated_household(head_of_household_citizen_id) WHERE head_of_household_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_province_id ON central.integrated_household(province_id); -- Hỗ trợ partition pruning
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_district_id ON central.integrated_household(district_id); -- Hỗ trợ partition pruning
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_status ON central.integrated_household(status);
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_type ON central.integrated_household(household_type);
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_integrated_at ON central.integrated_household(integrated_at);

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Bảng integrated_citizen: Bảng này phụ thuộc vào sự tồn tại của bảng central.integrated_citizen.
-- 2. Bảng integrated_address: Cân nhắc tạo bảng địa chỉ tích hợp riêng và tham chiếu đến nó thay vì lưu ward_id, address_detail trực tiếp.
-- 3. Triggers/Procedures:
--    - Logic để điền/cập nhật dữ liệu vào bảng này từ các nguồn (Bộ Tư pháp, Bộ Công an) thông qua quy trình ETL hoặc đồng bộ (Kafka, Debezium).
--    - Trigger cập nhật các cột phân vùng (geographical_region, province_id, district_id, region_id) dựa trên ward_id hoặc thông tin địa chỉ khác.
--    - Trigger cập nhật integrated_at khi có thay đổi.
-- 4. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.

COMMIT;

\echo 'integrated_household table created successfully with partitioning, constraints, and indexes.'
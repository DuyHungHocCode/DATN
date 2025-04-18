-- =============================================================================
-- File: database/schemas/justice/population_change.sql
-- Description: Creates the population_change table in the justice schema to track
--              significant demographic events affecting citizens.
-- Version: 2.0 (Integrated constraints, indexes, partitioning, removed comments)
-- =============================================================================

\echo 'Creating population_change table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.population_change CASCADE;

-- Create the population_change table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.population_change (
    change_id SERIAL NOT NULL,                           -- ID tự tăng của bản ghi biến động
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân có biến động (FK public_security.citizen)
    change_type population_change_type NOT NULL,         -- Loại biến động (ENUM: Sinh, Tử, Chuyển đến, Kết hôn,...)
    change_date DATE NOT NULL,                           -- Ngày xảy ra biến động
    source_location_id INT,                              -- ID địa chỉ nguồn (cho Chuyển đi) (FK public_security.address)
    destination_location_id INT,                         -- ID địa chỉ đích (cho Chuyển đến) (FK public_security.address)
    reason TEXT,                                         -- Lý do biến động
    related_document_no VARCHAR(50),                     -- Số hiệu văn bản liên quan (Giấy KS, KT, Kết hôn, QĐ chuyển HK...)
    processing_authority_id SMALLINT,                    -- Cơ quan xử lý/ghi nhận (FK reference.authorities)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái của bản ghi biến động (TRUE = Hợp lệ/Active)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi xảy ra sự kiện/đăng ký)
    region_id SMALLINT,                                  -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_population_change PRIMARY KEY (change_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_population_change_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_population_change_source_loc FOREIGN KEY (source_location_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_population_change_dest_loc FOREIGN KEY (destination_location_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_population_change_authority FOREIGN KEY (processing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_population_change_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_population_change_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_population_change_date CHECK (change_date <= CURRENT_DATE),
    CONSTRAINT ck_population_change_locations CHECK ( -- Yêu cầu địa chỉ phù hợp với loại biến động
        (change_type IN ('Chuyển đi thường trú', 'Xóa tạm trú') AND source_location_id IS NOT NULL) OR
        (change_type IN ('Chuyển đến thường trú', 'Đăng ký tạm trú') AND destination_location_id IS NOT NULL) OR
        (change_type NOT IN ('Chuyển đi thường trú', 'Xóa tạm trú', 'Chuyển đến thường trú', 'Đăng ký tạm trú'))
    ),
    CONSTRAINT ck_population_change_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu chưa xác định
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_population_change_citizen_id ON justice.population_change(citizen_id);
CREATE INDEX IF NOT EXISTS idx_population_change_change_type ON justice.population_change(change_type);
CREATE INDEX IF NOT EXISTS idx_population_change_change_date ON justice.population_change(change_date);
CREATE INDEX IF NOT EXISTS idx_population_change_source_loc_id ON justice.population_change(source_location_id);
CREATE INDEX IF NOT EXISTS idx_population_change_dest_loc_id ON justice.population_change(destination_location_id);
-- geographical_region và province_id đã được index ngầm bởi primary key và partitioning

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, region_id.
--    - Trigger tự động cập nhật các bảng khác khi có biến động (vd: cập nhật citizen.status khi có 'Tử', cập nhật residence khi có 'Chuyển đi').
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.
-- 3. Enum: Đảm bảo ENUM population_change_type đã được cập nhật (loại bỏ giá trị liên quan adoption/nationality_change nếu cần).

COMMIT;

\echo 'population_change table created successfully with partitioning, constraints, and indexes.'
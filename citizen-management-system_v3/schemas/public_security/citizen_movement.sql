-- =============================================================================
-- File: database/schemas/public_security/citizen_movement.sql
-- Description: Creates the citizen_movement table in the public_security schema
--              to track citizen movements (domestic and international).
-- Version: 2.0 (Integrated constraints, indexes, partitioning, removed comments)
-- =============================================================================

\echo 'Creating citizen_movement table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen_movement CASCADE;

-- Create the citizen_movement table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST) (Giả định, vì có cột province_id và geo_region)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.citizen_movement (
    movement_id SERIAL NOT NULL,                         -- ID tự tăng của bản ghi di chuyển
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân di chuyển (FK public_security.citizen)
    movement_type movement_type NOT NULL,                -- Loại di chuyển (ENUM: Trong nước, Xuất cảnh, Nhập cảnh, Tái nhập cảnh)
    from_address_id INT,                                 -- Địa chỉ đi (FK public_security.address) (NULL nếu xuất cảnh)
    to_address_id INT,                                   -- Địa chỉ đến (FK public_security.address) (NULL nếu nhập cảnh từ nước ngoài)
    from_country_id SMALLINT,                            -- Quốc gia đi (FK reference.nationalities) (Chỉ dùng cho xuất cảnh)
    to_country_id SMALLINT,                              -- Quốc gia đến (FK reference.nationalities) (Chỉ dùng cho nhập cảnh)
    departure_date DATE NOT NULL,                        -- Ngày khởi hành
    arrival_date DATE,                                   -- Ngày đến (NULL nếu đang di chuyển hoặc không xác định)
    purpose VARCHAR(200),                                -- Mục đích di chuyển (du lịch, công tác, định cư...)
    document_no VARCHAR(50),                             -- Số giấy tờ liên quan (hộ chiếu, visa...)
    document_type VARCHAR(50),                           -- Loại giấy tờ
    document_issue_date DATE,                            -- Ngày cấp giấy tờ
    document_expiry_date DATE,                           -- Ngày hết hạn giấy tờ
    carrier VARCHAR(100),                                -- Hãng vận chuyển (Vietnam Airlines, Vietjet Air,...)
    border_checkpoint VARCHAR(100),                      -- Cửa khẩu (Nội Bài, Tân Sơn Nhất, Mộc Bài...)
    description TEXT,                                    -- Mô tả chi tiết thêm
    status VARCHAR(50) DEFAULT 'Active',                 -- Trạng thái bản ghi (Active, Completed, Cancelled)

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đi hoặc nơi đăng ký của công dân)
    source_region_id SMALLINT,                           -- Vùng/Miền đi (FK reference.regions)
    target_region_id SMALLINT,                           -- Vùng/Miền đến (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2) - Có thể là tỉnh đi hoặc tỉnh đăng ký
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_citizen_movement PRIMARY KEY (movement_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen và address (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_citizen_movement_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_citizen_movement_from_addr FOREIGN KEY (from_address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_citizen_movement_to_addr FOREIGN KEY (to_address_id) REFERENCES public_security.address(address_id),
    CONSTRAINT fk_citizen_movement_from_ctry FOREIGN KEY (from_country_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_citizen_movement_to_ctry FOREIGN KEY (to_country_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_citizen_movement_src_region FOREIGN KEY (source_region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_movement_tgt_region FOREIGN KEY (target_region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_movement_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_citizen_movement_dates CHECK (
        departure_date <= CURRENT_DATE AND
        (arrival_date IS NULL OR arrival_date >= departure_date) AND
        (document_issue_date IS NULL OR document_issue_date <= departure_date) AND
        (document_expiry_date IS NULL OR document_expiry_date >= document_issue_date)
    ),
    CONSTRAINT ck_citizen_movement_status CHECK (status IN ('Active', 'Completed', 'Cancelled')),
    CONSTRAINT ck_citizen_movement_international CHECK ( -- Logic cho di chuyển quốc tế
        (movement_type IN ('Xuất cảnh', 'Tái nhập cảnh') AND from_country_id IS NOT NULL AND border_checkpoint IS NOT NULL) OR
        (movement_type = 'Nhập cảnh' AND to_country_id IS NOT NULL AND border_checkpoint IS NOT NULL) OR
        (movement_type = 'Trong nước') -- Không cần country/checkpoint cho di chuyển trong nước
    ),
    CONSTRAINT ck_citizen_movement_address_country CHECK ( -- Đảm bảo không có cả address và country cùng lúc
        NOT (movement_type = 'Xuất cảnh' AND from_address_id IS NOT NULL AND from_country_id IS NOT NULL) AND
        NOT (movement_type = 'Nhập cảnh' AND to_address_id IS NOT NULL AND to_country_id IS NOT NULL)
    ),
     CONSTRAINT ck_citizen_movement_region_consistency CHECK ( -- Đảm bảo geographical_region hợp lệ
            geographical_region IN ('Bắc', 'Trung', 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_citizen_movement_citizen_id ON public_security.citizen_movement(citizen_id);
CREATE INDEX IF NOT EXISTS idx_citizen_movement_type ON public_security.citizen_movement(movement_type);
CREATE INDEX IF NOT EXISTS idx_citizen_movement_dep_date ON public_security.citizen_movement(departure_date);
CREATE INDEX IF NOT EXISTS idx_citizen_movement_arr_date ON public_security.citizen_movement(arrival_date);
CREATE INDEX IF NOT EXISTS idx_citizen_movement_doc_no ON public_security.citizen_movement(document_no) WHERE document_no IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_movement_status ON public_security.citizen_movement(status);
CREATE INDEX IF NOT EXISTS idx_citizen_movement_province ON public_security.citizen_movement(province_id); -- Hỗ trợ partition pruning


-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, source/target_region_id dựa trên địa chỉ hoặc logic nghiệp vụ.
--    - Trigger tự động cập nhật status='Completed' khi arrival_date được điền.
--    - Trigger kiểm tra logic nghiệp vụ phức tạp hơn (ví dụ: không thể xuất cảnh nếu đang có lệnh cấm).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.

COMMIT;

\echo 'citizen_movement table created successfully with partitioning, constraints, and indexes.'
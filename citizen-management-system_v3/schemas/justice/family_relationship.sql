-- =============================================================================
-- File: database/schemas/justice/family_relationship.sql
-- Description: Creates the family_relationship table in the justice schema
--              to record relationships between citizens.
-- Version: 2.0 (Integrated constraints, indexes, partitioning, removed comments)
-- =============================================================================

\echo 'Creating family_relationship table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.family_relationship CASCADE;

-- Create the family_relationship table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.family_relationship (
    relationship_id SERIAL NOT NULL,                   -- ID tự tăng của mối quan hệ
    citizen_id VARCHAR(12) NOT NULL,                   -- ID công dân thứ nhất (FK public_security.citizen)
    related_citizen_id VARCHAR(12) NOT NULL,           -- ID công dân thứ hai (FK public_security.citizen)
    relationship_type family_relationship_type NOT NULL, -- Loại quan hệ (ENUM: Vợ-Chồng, Cha-Con, Mẹ-Con...)
    start_date DATE NOT NULL,                          -- Ngày bắt đầu mối quan hệ (vd: ngày kết hôn, ngày sinh)
    end_date DATE,                                     -- Ngày kết thúc mối quan hệ (vd: ngày ly hôn, ngày mất)
    status record_status DEFAULT 'Đang xử lý',         -- Trạng thái xác thực bản ghi (ENUM: Đang xử lý, Đã duyệt...)
    document_proof TEXT,                               -- Tên hoặc mô tả văn bản chứng minh (vd: Giấy KH, Giấy KS)
    document_no VARCHAR(50),                           -- Số hiệu văn bản chứng minh
    issuing_authority_id SMALLINT,                     -- Cơ quan cấp văn bản (FK reference.authorities)
    notes TEXT,                                        -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký)
    region_id SMALLINT,                                -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                          -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,          -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_family_relationship PRIMARY KEY (relationship_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_family_relationship_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_family_relationship_related FOREIGN KEY (related_citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_family_relationship_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_family_relationship_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_family_relationship_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_family_relationship_dates CHECK (start_date <= CURRENT_DATE AND (end_date IS NULL OR end_date >= start_date)),
    CONSTRAINT ck_family_relationship_different_people CHECK (citizen_id <> related_citizen_id), -- Hai người phải khác nhau
    CONSTRAINT ck_family_relationship_valid_type CHECK ( -- Đảm bảo loại quan hệ hợp lệ (có thể thêm logic phức tạp hơn)
        relationship_type IS NOT NULL
    ),
    CONSTRAINT ck_family_relationship_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_family_relationship_citizen1 ON justice.family_relationship(citizen_id);
CREATE INDEX IF NOT EXISTS idx_family_relationship_citizen2 ON justice.family_relationship(related_citizen_id);
CREATE INDEX IF NOT EXISTS idx_family_relationship_type ON justice.family_relationship(relationship_type);
CREATE INDEX IF NOT EXISTS idx_family_relationship_start_date ON justice.family_relationship(start_date);
CREATE INDEX IF NOT EXISTS idx_family_relationship_end_date ON justice.family_relationship(end_date);
CREATE INDEX IF NOT EXISTS idx_family_relationship_status ON justice.family_relationship(status);
-- Index kết hợp để tìm quan hệ giữa 2 người cụ thể
CREATE INDEX IF NOT EXISTS idx_family_relationship_pair ON justice.family_relationship(citizen_id, related_citizen_id);


-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger kiểm tra tính nhất quán của mối quan hệ (vd: nếu A là cha của B thì B không thể là cha của A).
--    - Trigger tự động tạo mối quan hệ ngược lại (vd: khi tạo A là cha B, tự tạo B là con A).
--    - Trigger cập nhật geographical_region, province_id, region_id.
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.
-- 3. Foreign Data Wrapper (FDW): Cấu hình FDW để truy cập public_security.citizen.

COMMIT;

\echo 'family_relationship table created successfully with partitioning, constraints, and indexes.'
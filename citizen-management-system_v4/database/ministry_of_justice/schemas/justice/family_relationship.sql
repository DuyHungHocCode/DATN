-- =============================================================================
-- File: ministry_of_justice/schemas/justice/family_relationship.sql
-- Description: Tạo bảng family_relationship ghi nhận các mối quan hệ gia đình
--              (cha-con, mẹ-con, vợ-chồng...) trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure - Removed Cross-DB FKs)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'reference.authorities', 'reference.regions', 'reference.provinces'.
-- - Script tạo ENUM 'family_relationship_type', 'record_status'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.family_relationship...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.family_relationship CASCADE;

-- Tạo bảng family_relationship với cấu trúc phân vùng
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.family_relationship (
    relationship_id BIGSERIAL NOT NULL,                   -- ID tự tăng của mối quan hệ (dùng BIGSERIAL)
    citizen_id VARCHAR(12) NOT NULL,                   -- ID công dân thứ nhất (Logic liên kết đến public_security.citizen)
    related_citizen_id VARCHAR(12) NOT NULL,           -- ID công dân có quan hệ với người thứ nhất (Logic liên kết đến public_security.citizen)
    relationship_type family_relationship_type NOT NULL, -- Loại quan hệ (ENUM: Vợ-Chồng, Cha đẻ-Con đẻ, Mẹ đẻ-Con đẻ...)
    start_date DATE NOT NULL,                          -- Ngày bắt đầu mối quan hệ (vd: ngày kết hôn, ngày sinh của con)
    end_date DATE,                                     -- Ngày kết thúc mối quan hệ (vd: ngày ly hôn, ngày mất)
    status record_status DEFAULT 'Đang xử lý',         -- Trạng thái xác thực bản ghi quan hệ (ENUM: Đang xử lý, Đã duyệt...)
    document_proof TEXT,                               -- Tên hoặc mô tả văn bản chứng minh (vd: Giấy đăng ký kết hôn, Giấy khai sinh)
    document_no VARCHAR(50),                           -- Số hiệu văn bản chứng minh (nếu có)
    issuing_authority_id SMALLINT,                     -- Cơ quan cấp văn bản chứng minh (FK đến reference.authorities)
    notes TEXT,                                        -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký sự kiện tạo ra quan hệ)
    region_id SMALLINT,                                -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                          -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,          -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                            -- User tạo bản ghi
    updated_by VARCHAR(50),                            -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_family_relationship PRIMARY KEY (relationship_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- **ĐÃ XÓA FK đến public_security.citizen**
    CONSTRAINT fk_family_relationship_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_family_relationship_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_family_relationship_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_family_relationship_dates CHECK (start_date <= CURRENT_DATE AND (end_date IS NULL OR end_date >= start_date)), -- Ngày kết thúc phải sau ngày bắt đầu
    CONSTRAINT ck_family_relationship_different_people CHECK (citizen_id <> related_citizen_id), -- Hai người trong mối quan hệ phải khác nhau
    -- Ràng buộc đảm bảo tính đối xứng hoặc logic quan hệ (vd: A là cha B thì B là con A)
    -- nên được xử lý ở tầng ứng dụng hoặc trigger phức tạp hơn.
    CONSTRAINT ck_family_relationship_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu không xác định được vùng/miền lúc tạo
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.family_relationship IS 'Ghi nhận các mối quan hệ gia đình đã được xác thực giữa các công dân.';
COMMENT ON COLUMN justice.family_relationship.citizen_id IS 'ID công dân thứ nhất (Logic liên kết).';
COMMENT ON COLUMN justice.family_relationship.related_citizen_id IS 'ID công dân thứ hai có quan hệ với người thứ nhất (Logic liên kết).';
COMMENT ON COLUMN justice.family_relationship.relationship_type IS 'Loại quan hệ (ENUM family_relationship_type).';
COMMENT ON COLUMN justice.family_relationship.start_date IS 'Ngày mối quan hệ bắt đầu có hiệu lực (vd: ngày kết hôn, ngày sinh con).';
COMMENT ON COLUMN justice.family_relationship.end_date IS 'Ngày mối quan hệ kết thúc (vd: ngày ly hôn, ngày mất).';
COMMENT ON COLUMN justice.family_relationship.status IS 'Trạng thái xác thực của bản ghi quan hệ.';
COMMENT ON COLUMN justice.family_relationship.document_proof IS 'Tên/Mô tả giấy tờ chứng minh mối quan hệ.';
COMMENT ON COLUMN justice.family_relationship.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.family_relationship.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';

-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên các cột thường dùng để truy vấn mối quan hệ
CREATE INDEX IF NOT EXISTS idx_family_relationship_citizen1 ON justice.family_relationship(citizen_id);
CREATE INDEX IF NOT EXISTS idx_family_relationship_citizen2 ON justice.family_relationship(related_citizen_id);
CREATE INDEX IF NOT EXISTS idx_family_relationship_type ON justice.family_relationship(relationship_type);
CREATE INDEX IF NOT EXISTS idx_family_relationship_start_date ON justice.family_relationship(start_date);
CREATE INDEX IF NOT EXISTS idx_family_relationship_end_date ON justice.family_relationship(end_date);
CREATE INDEX IF NOT EXISTS idx_family_relationship_status ON justice.family_relationship(status);
-- Index kết hợp để tìm quan hệ giữa 2 người cụ thể (hữu ích cho việc kiểm tra tồn tại)
CREATE INDEX IF NOT EXISTS idx_family_relationship_pair ON justice.family_relationship(citizen_id, related_citizen_id);
-- Index trên cột phân vùng province_id đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.family_relationship.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Cân nhắc tạo trigger để tự động tạo bản ghi quan hệ ngược lại (ví dụ: khi thêm A là cha B, tự động thêm B là con A) để đảm bảo tính đối xứng, hoặc xử lý logic này trong tầng ứng dụng (App BTP). Cần cẩn thận để tránh vòng lặp vô hạn.
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `region_id`) dựa trên nơi đăng ký sự kiện hoặc thông tin khác.
-- 4. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA để xác thực `citizen_id` và `related_citizen_id` trước khi tạo mối quan hệ.
--    - Các sự kiện tạo quan hệ quan trọng (như Vợ-Chồng từ bảng Marriage) có thể cần thông báo cho App BCA để cập nhật thông tin liên quan nếu cần.
-- 5. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 6. Permissions: Đảm bảo các role (justice_reader, justice_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
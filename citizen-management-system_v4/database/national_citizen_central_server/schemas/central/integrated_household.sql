-- =============================================================================
-- File: national_citizen_central_server/schemas/central/integrated_household.sql
-- Description: Tạo bảng integrated_household trong schema central trên máy chủ trung tâm,
--              lưu trữ dữ liệu hộ khẩu đã được tích hợp.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Script tạo schema 'central', 'reference', 'sync' (nếu dùng sync_batch).
-- - Script tạo bảng 'central.integrated_citizen'.
-- - Script tạo các bảng 'reference.*' (wards, districts, provinces, regions, authorities).
-- - Script tạo các ENUM cần thiết (household_type, household_status...).
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng central.integrated_household...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
-- \connect national_citizen_central_server

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS central.integrated_household CASCADE;

-- Tạo bảng integrated_household với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE central.integrated_household (
    integrated_household_id BIGSERIAL NOT NULL,          -- Khóa chính tự tăng của bản ghi tích hợp
    source_system VARCHAR(50) NOT NULL,                  -- Nguồn dữ liệu gốc ('BTP', 'BCA'?). Chủ yếu là BTP.
    source_household_id VARCHAR(50) NOT NULL,            -- Khóa chính của hộ khẩu ở hệ thống nguồn (vd: justice.household.household_id)

    household_book_no VARCHAR(20) NOT NULL,              -- Số sổ hộ khẩu (Lấy từ nguồn)
    head_of_household_citizen_id VARCHAR(12),            -- ID công dân của chủ hộ (FK đến central.integrated_citizen)
    -- Lưu trữ chi tiết địa chỉ đã được denormalize và các ID hành chính cục bộ
    address_detail TEXT,                                 -- Chi tiết địa chỉ (số nhà, đường...) lấy từ nguồn
    ward_id INT NOT NULL,                                -- Phường/Xã (FK reference.wards)
    -- district_id, province_id, region_id, geographical_region được dùng cho phân vùng và FK ở dưới

    registration_date DATE,                              -- Ngày đăng ký hộ khẩu gốc (từ nguồn)
    issuing_authority_id SMALLINT,                       -- Cơ quan cấp sổ gốc (FK reference.authorities)
    household_type household_type,                       -- Loại hộ khẩu (ENUM)
    status household_status,                             -- Trạng thái hộ khẩu (ENUM)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Lấy theo địa chỉ hộ khẩu)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata đồng bộ và tích hợp
    source_created_at TIMESTAMP WITH TIME ZONE,          -- Thời điểm tạo ở nguồn (nếu có)
    source_updated_at TIMESTAMP WITH TIME ZONE,          -- Thời điểm cập nhật ở nguồn (nếu có)
    integrated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tích hợp/cập nhật vào central lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_integrated_household PRIMARY KEY (integrated_household_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất: Đảm bảo không có bản ghi trùng lặp từ cùng một nguồn với cùng ID nguồn
    CONSTRAINT uq_integrated_household_source UNIQUE (source_system, source_household_id),
    -- Ràng buộc Duy nhất cho số sổ hộ khẩu (cần cân nhắc kỹ nếu số sổ có thể tái sử dụng hoặc không duy nhất toàn quốc)
    CONSTRAINT uq_integrated_household_book_no UNIQUE (household_book_no),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database TT)
    -- Lưu ý: FK tới bảng integrated_citizen (đã phân vùng) cần kiểm tra kỹ lưỡng.
    CONSTRAINT fk_integrated_household_head FOREIGN KEY (head_of_household_citizen_id) REFERENCES central.integrated_citizen(citizen_id) ON DELETE SET NULL, -- Nếu xóa citizen tích hợp thì set null chủ hộ
    CONSTRAINT fk_integrated_household_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    CONSTRAINT fk_integrated_household_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    CONSTRAINT fk_integrated_household_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_integrated_household_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_integrated_household_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    -- CONSTRAINT fk_integrated_household_sync_batch FOREIGN KEY (last_sync_batch_id) REFERENCES sync.sync_batch(batch_id), -- Nếu có bảng sync_batch

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_integrated_household_dates CHECK (registration_date IS NULL OR registration_date <= CURRENT_DATE),
    CONSTRAINT ck_integrated_household_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- province_id và district_id là NOT NULL, nên region_id cũng phải NOT NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE central.integrated_household IS 'Bảng chứa dữ liệu hộ khẩu đã được tích hợp từ các nguồn (chủ yếu là Bộ Tư pháp).';
COMMENT ON COLUMN central.integrated_household.source_system IS 'Hệ thống nguồn của dữ liệu (vd: BTP, BCA).';
COMMENT ON COLUMN central.integrated_household.source_household_id IS 'ID gốc của hộ khẩu trên hệ thống nguồn.';
COMMENT ON COLUMN central.integrated_household.household_book_no IS 'Số sổ hộ khẩu.';
COMMENT ON COLUMN central.integrated_household.head_of_household_citizen_id IS 'ID Công dân của chủ hộ (tham chiếu đến central.integrated_citizen).';
COMMENT ON COLUMN central.integrated_household.address_detail IS 'Chi tiết địa chỉ hộ khẩu (denormalized từ nguồn).';
COMMENT ON COLUMN central.integrated_household.ward_id IS 'ID Phường/Xã của địa chỉ hộ khẩu (FK đến reference.wards cục bộ).';
COMMENT ON COLUMN central.integrated_household.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN central.integrated_household.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';
COMMENT ON COLUMN central.integrated_household.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN central.integrated_household.integrated_at IS 'Thời điểm bản ghi tích hợp này được tạo hoặc cập nhật lần cuối.';

-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_source ON central.integrated_household(source_system, source_household_id);
-- Index trên household_book_no đã được tạo bởi ràng buộc UNIQUE
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_head_id ON central.integrated_household(head_of_household_citizen_id) WHERE head_of_household_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_ward_id ON central.integrated_household(ward_id); -- Index trên ward_id
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_status ON central.integrated_household(status);
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_type ON central.integrated_household(household_type);
CREATE INDEX IF NOT EXISTS idx_integrated_hhold_integrated_at ON central.integrated_household(integrated_at);
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng central.integrated_household.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `national_citizen_central_server/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Synchronization Logic (Quan trọng):
--    - Xây dựng logic đồng bộ (trong schema `sync` hoặc dùng Airflow) để đọc dữ liệu hộ khẩu từ `justice_mirror.household`.
--    - Lấy thông tin chi tiết địa chỉ và ID hành chính tương ứng từ `reference.*` hoặc `justice_mirror.address` (nếu có).
--    - Xác thực/Liên kết `head_of_household_citizen_id` với bản ghi trong `central.integrated_citizen`.
--    - Cập nhật hoặc chèn (`INSERT ... ON CONFLICT DO UPDATE` dựa trên `source_system` và `source_household_id`) dữ liệu vào `central.integrated_household`.
--    - Cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên địa chỉ.
--    - Cập nhật các cột metadata đồng bộ.
-- 4. Data Loading: Chạy quy trình đồng bộ ban đầu để nạp dữ liệu.
-- 5. Permissions: Đảm bảo các role (central_server_reader, sync_user) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 6. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của ràng buộc UNIQUE `uq_integrated_household_book_no` và `uq_integrated_household_source` trên môi trường có partitioning.
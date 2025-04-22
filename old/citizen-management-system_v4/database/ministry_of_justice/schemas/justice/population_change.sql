-- File: ministry_of_justice/schemas/justice/population_change.sql
-- Description: Tạo bảng population_change ghi nhận các sự kiện làm thay đổi
--              thông tin dân số, hộ tịch, cư trú trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure - Removed Cross-DB FKs)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'reference.authorities', 'reference.regions', 'reference.provinces'.
-- - Script tạo ENUM 'population_change_type'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.population_change...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.population_change CASCADE;

-- Tạo bảng population_change với cấu trúc phân vùng
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.population_change (
    change_id BIGSERIAL NOT NULL,                        -- ID tự tăng của bản ghi biến động (dùng BIGSERIAL)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân có biến động (Logic liên kết đến public_security.citizen)
    change_type population_change_type NOT NULL,         -- Loại biến động (ENUM: Sinh, Tử, Chuyển đến, Kết hôn...)
    change_date DATE NOT NULL,                           -- Ngày xảy ra biến động
    source_location_id INT,                              -- ID địa chỉ nguồn (cho Chuyển đi) (Logic liên kết đến public_security.address)
    destination_location_id INT,                         -- ID địa chỉ đích (cho Chuyển đến) (Logic liên kết đến public_security.address)
    reason TEXT,                                         -- Lý do biến động (nếu có)
    related_document_no VARCHAR(50),                     -- Số hiệu văn bản liên quan (Giấy KS, KT, Kết hôn, QĐ chuyển HK...)
    processing_authority_id SMALLINT,                    -- Cơ quan xử lý/ghi nhận biến động (FK đến reference.authorities)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái của bản ghi biến động (TRUE = Hợp lệ/Active)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi xảy ra sự kiện/đăng ký)
    region_id SMALLINT,                                  -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User tạo bản ghi (hoặc tên trigger/process)
    updated_by VARCHAR(50),                              -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_population_change PRIMARY KEY (change_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- **ĐÃ XÓA FK đến public_security.citizen và public_security.address**
    CONSTRAINT fk_population_change_authority FOREIGN KEY (processing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_population_change_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_population_change_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_population_change_date CHECK (change_date <= CURRENT_DATE),
    -- Ràng buộc về địa điểm nguồn/đích vẫn có thể giữ lại về mặt logic (cột nào nên có giá trị)
    CONSTRAINT ck_population_change_locations CHECK (
        (change_type IN ('Chuyển đi thường trú', 'Xóa tạm trú') AND source_location_id IS NOT NULL) OR
        (change_type IN ('Chuyển đến thường trú', 'Đăng ký tạm trú') AND destination_location_id IS NOT NULL) OR
        (change_type NOT IN ('Chuyển đi thường trú', 'Xóa tạm trú', 'Chuyển đến thường trú', 'Đăng ký tạm trú'))
    ),
    CONSTRAINT ck_population_change_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu không xác định được vùng/miền lúc tạo
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.population_change IS 'Ghi nhận lịch sử các sự kiện biến động dân số, hộ tịch, cư trú.';
COMMENT ON COLUMN justice.population_change.citizen_id IS 'ID công dân có biến động (Logic liên kết).';
COMMENT ON COLUMN justice.population_change.change_type IS 'Loại biến động (ENUM population_change_type).';
COMMENT ON COLUMN justice.population_change.change_date IS 'Ngày xảy ra sự kiện biến động.';
COMMENT ON COLUMN justice.population_change.source_location_id IS 'ID địa chỉ nguồn (nếu là chuyển đi) (Logic liên kết).';
COMMENT ON COLUMN justice.population_change.destination_location_id IS 'ID địa chỉ đích (nếu là chuyển đến) (Logic liên kết).';
COMMENT ON COLUMN justice.population_change.related_document_no IS 'Số hiệu văn bản pháp lý liên quan đến biến động.';
COMMENT ON COLUMN justice.population_change.processing_authority_id IS 'Cơ quan đã xử lý hoặc ghi nhận biến động này.';
COMMENT ON COLUMN justice.population_change.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.population_change.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';

-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
CREATE INDEX IF NOT EXISTS idx_population_change_citizen_id ON justice.population_change(citizen_id);
CREATE INDEX IF NOT EXISTS idx_population_change_change_type ON justice.population_change(change_type);
CREATE INDEX IF NOT EXISTS idx_population_change_change_date ON justice.population_change(change_date);
CREATE INDEX IF NOT EXISTS idx_population_change_source_loc_id ON justice.population_change(source_location_id) WHERE source_location_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_population_change_dest_loc_id ON justice.population_change(destination_location_id) WHERE destination_location_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_population_change_authority_id ON justice.population_change(processing_authority_id);
-- Index trên cột phân vùng province_id đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.population_change.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Population Mechanism: Xác định rõ cách thức dữ liệu được ghi vào bảng này.
--    - Option A (Recommended): Tạo các trigger trong DB BTP trên các bảng nghiệp vụ khác (birth_certificate, death_certificate, marriage, divorce, household_member...) để tự động INSERT vào population_change khi có sự kiện xảy ra.
--    - Option B: Logic ghi nhận biến động nằm trong tầng ứng dụng (App BTP).
-- 4. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `region_id`) dựa trên nơi xảy ra sự kiện.
--    - Nếu dùng Option A ở trên, cần tạo các trigger để ghi dữ liệu vào bảng này.
-- 5. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA để xác thực `citizen_id` và lấy thông tin cần thiết nếu trigger/logic ghi biến động cần thông tin từ BCA.
--    - Các biến động quan trọng (Sinh, Tử, Kết hôn, Ly hôn, Thay đổi cư trú) cần được thông báo cho App BCA (qua API/event) để cập nhật dữ liệu tương ứng bên BCA.
-- 6. Data Loading: Nạp dữ liệu lịch sử biến động (nếu có).
-- 7. Permissions: Đảm bảo các role (justice_reader, justice_writer - nếu có chức năng ghi trực tiếp) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
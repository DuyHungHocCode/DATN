-- File: ministry_of_justice/schemas/justice/household.sql
-- Description: Tạo bảng household (Sổ hộ khẩu) trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure - Removed Cross-DB FKs)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'reference.authorities', 'reference.regions', 'reference.provinces', 'reference.districts'.
-- - Script tạo ENUM 'household_type', 'household_status'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.household...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.household CASCADE;

-- Tạo bảng household với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.household (
    household_id BIGSERIAL NOT NULL,                       -- ID tự tăng của hộ khẩu (dùng BIGSERIAL)
    household_book_no VARCHAR(20) NOT NULL,                -- Số sổ hộ khẩu (Yêu cầu duy nhất toàn cục)
    head_of_household_id VARCHAR(12) NOT NULL,             -- ID Chủ hộ (Logic liên kết đến public_security.citizen)
    address_id INT NOT NULL,                             -- ID Địa chỉ đăng ký hộ khẩu (Logic liên kết đến public_security.address)
    registration_date DATE NOT NULL,                     -- Ngày đăng ký hộ khẩu
    issuing_authority_id SMALLINT,                       -- Cơ quan cấp sổ (FK đến reference.authorities)
    area_code VARCHAR(10),                               -- Mã khu vực hành chính (theo địa phương, nếu có)
    household_type household_type NOT NULL,              -- Loại hộ khẩu (ENUM: Hộ gia đình, Hộ tập thể...)
    status household_status DEFAULT 'Đang hoạt động',     -- Trạng thái hộ khẩu (ENUM: Đang hoạt động, Đã chuyển đi...)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo địa chỉ đăng ký hộ khẩu)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User tạo bản ghi
    updated_by VARCHAR(50),                              -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_household PRIMARY KEY (household_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất (Cần kiểm tra kỹ với partitioning)
    CONSTRAINT uq_household_book_no UNIQUE (household_book_no), -- Số sổ hộ khẩu phải duy nhất

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- **ĐÃ XÓA FK đến public_security.citizen và public_security.address**
    CONSTRAINT fk_household_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_household_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_household_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_household_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_household_registration_date CHECK (registration_date <= CURRENT_DATE),
    CONSTRAINT ck_household_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- province_id và district_id là NOT NULL, nên region_id cũng phải NOT NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.household IS 'Lưu thông tin về Sổ hộ khẩu.';
COMMENT ON COLUMN justice.household.household_id IS 'ID tự tăng duy nhất của hộ khẩu.';
COMMENT ON COLUMN justice.household.household_book_no IS 'Số sổ hộ khẩu (yêu cầu duy nhất).';
COMMENT ON COLUMN justice.household.head_of_household_id IS 'ID Công dân của chủ hộ (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.household.address_id IS 'ID Địa chỉ đăng ký của hộ khẩu (Logic liên kết đến public_security.address).';
COMMENT ON COLUMN justice.household.registration_date IS 'Ngày đăng ký hộ khẩu.';
COMMENT ON COLUMN justice.household.household_type IS 'Loại hình hộ khẩu (ENUM household_type).';
COMMENT ON COLUMN justice.household.status IS 'Trạng thái của hộ khẩu (ENUM household_status).';
COMMENT ON COLUMN justice.household.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.household.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN justice.household.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên các cột thường dùng để truy vấn
CREATE INDEX IF NOT EXISTS idx_household_head_id ON justice.household(head_of_household_id);
CREATE INDEX IF NOT EXISTS idx_household_address_id ON justice.household(address_id);
CREATE INDEX IF NOT EXISTS idx_household_type ON justice.household(household_type);
CREATE INDEX IF NOT EXISTS idx_household_status ON justice.household(status);
-- Index trên household_book_no đã được tạo tự động bởi ràng buộc UNIQUE
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.household.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger đảm bảo chủ hộ (`head_of_household_id`) cũng là một thành viên trong bảng `household_member` với quan hệ là 'Chủ hộ'.
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `address_id` (cần phối hợp liên service để lấy thông tin địa chỉ).
-- 4. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA để xác thực `head_of_household_id` và `address_id` trước khi tạo hộ khẩu.
--    - Các thay đổi về hộ khẩu (địa chỉ, chủ hộ, trạng thái) có thể cần thông báo cho App BCA để cập nhật thông tin liên quan (ví dụ: `permanent_residence`).
-- 5. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 6. Permissions: Đảm bảo các role (justice_reader, justice_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 7. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của ràng buộc UNIQUE `uq_household_book_no` trên môi trường có partitioning.
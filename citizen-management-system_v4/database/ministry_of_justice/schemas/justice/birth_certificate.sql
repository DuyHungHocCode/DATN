-- File: ministry_of_justice/schemas/justice/birth_certificate.sql
-- Description: Tạo bảng birth_certificate (Giấy khai sinh) trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure - Removed Cross-DB FKs)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'reference.nationalities', 'reference.authorities', 'reference.regions', 'reference.provinces', 'reference.districts'.
-- - Script tạo ENUM 'gender_type'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.birth_certificate...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.birth_certificate CASCADE;

-- Tạo bảng birth_certificate với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.birth_certificate (
    birth_certificate_id BIGSERIAL NOT NULL,            -- ID tự tăng của giấy khai sinh (dùng BIGSERIAL)
    citizen_id VARCHAR(12) NOT NULL,                    -- Số định danh của người được khai sinh (Logic liên kết đến public_security.citizen)
    birth_certificate_no VARCHAR(20) NOT NULL,          -- Số giấy khai sinh (Yêu cầu duy nhất toàn cục)
    registration_date DATE NOT NULL,                    -- Ngày đăng ký khai sinh
    book_id VARCHAR(20),                                -- Số quyển sổ đăng ký khai sinh
    page_no VARCHAR(10),                                -- Số trang trong quyển sổ
    issuing_authority_id SMALLINT NOT NULL,             -- Cơ quan đăng ký khai sinh (FK đến reference.authorities)
    place_of_birth TEXT NOT NULL,                       -- Nơi sinh (chi tiết)
    date_of_birth DATE NOT NULL,                        -- Ngày sinh
    gender_at_birth gender_type NOT NULL,               -- Giới tính khi sinh (ENUM: Nam, Nữ, Khác)

    -- Thông tin cha (lưu trữ thông tin tại thời điểm đăng ký)
    father_full_name VARCHAR(100),                      -- Họ tên cha
    father_citizen_id VARCHAR(12),                      -- Số định danh của cha (Logic liên kết đến public_security.citizen)
    father_date_of_birth DATE,                          -- Ngày sinh cha
    father_nationality_id SMALLINT,                     -- Quốc tịch cha (FK đến reference.nationalities)

    -- Thông tin mẹ (lưu trữ thông tin tại thời điểm đăng ký)
    mother_full_name VARCHAR(100),                      -- Họ tên mẹ
    mother_citizen_id VARCHAR(12),                      -- Số định danh của mẹ (Logic liên kết đến public_security.citizen)
    mother_date_of_birth DATE,                          -- Ngày sinh mẹ
    mother_nationality_id SMALLINT,                     -- Quốc tịch mẹ (FK đến reference.nationalities)

    -- Thông tin người khai
    declarant_name VARCHAR(100) NOT NULL,               -- Họ tên người đi khai sinh
    declarant_citizen_id VARCHAR(12),                   -- Số định danh người đi khai (Logic liên kết đến public_security.citizen)
    declarant_relationship VARCHAR(50),                 -- Quan hệ với người được khai sinh

    -- Thông tin khác
    witness1_name VARCHAR(100),                         -- Người làm chứng 1 (nếu có)
    witness2_name VARCHAR(100),                         -- Người làm chứng 2 (nếu có)
    birth_notification_no VARCHAR(50),                  -- Số giấy chứng sinh (nếu có)
    status BOOLEAN DEFAULT TRUE,                        -- Trạng thái hiệu lực của bản ghi (TRUE = Active)
    notes TEXT,                                         -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký khai sinh)
    region_id SMALLINT NOT NULL,                        -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                           -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                           -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,           -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                             -- User tạo bản ghi
    updated_by VARCHAR(50),                             -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_birth_certificate PRIMARY KEY (birth_certificate_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất (Cần kiểm tra kỹ với partitioning)
    CONSTRAINT uq_birth_certificate_no UNIQUE (birth_certificate_no), -- Số giấy khai sinh phải duy nhất
    CONSTRAINT uq_birth_certificate_citizen_id UNIQUE (citizen_id), -- Mỗi công dân chỉ có 1 giấy khai sinh

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- **ĐÃ XÓA FK đến public_security.citizen**
    CONSTRAINT fk_birth_certificate_father_nat FOREIGN KEY (father_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_birth_certificate_mother_nat FOREIGN KEY (mother_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_birth_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_birth_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_birth_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_birth_certificate_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_birth_certificate_dates CHECK (
            date_of_birth < CURRENT_DATE AND
            registration_date >= date_of_birth AND
            registration_date <= CURRENT_DATE AND
            (father_date_of_birth IS NULL OR father_date_of_birth < date_of_birth) AND -- Cha phải sinh trước con
            (mother_date_of_birth IS NULL OR mother_date_of_birth < date_of_birth) -- Mẹ phải sinh trước con
        ),
    CONSTRAINT ck_birth_certificate_parents CHECK ( -- Cha mẹ không được là người được khai sinh
           citizen_id <> father_citizen_id AND
           citizen_id <> mother_citizen_id
        ),
    CONSTRAINT ck_birth_certificate_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.birth_certificate IS 'Lưu thông tin đăng ký khai sinh.';
COMMENT ON COLUMN justice.birth_certificate.citizen_id IS 'Số định danh cá nhân của người được khai sinh (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.birth_certificate.birth_certificate_no IS 'Số định danh duy nhất của giấy khai sinh.';
COMMENT ON COLUMN justice.birth_certificate.registration_date IS 'Ngày đăng ký khai sinh.';
COMMENT ON COLUMN justice.birth_certificate.issuing_authority_id IS 'Cơ quan thực hiện đăng ký khai sinh.';
COMMENT ON COLUMN justice.birth_certificate.father_citizen_id IS 'Số định danh của cha (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.birth_certificate.mother_citizen_id IS 'Số định danh của mẹ (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.birth_certificate.declarant_citizen_id IS 'Số định danh của người đi khai sinh (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.birth_certificate.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.birth_certificate.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN justice.birth_certificate.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';

-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên khóa ngoại và các cột thường dùng để lọc/sắp xếp
-- Index trên các cột UNIQUE đã được tạo tự động
CREATE INDEX IF NOT EXISTS idx_birth_certificate_reg_date ON justice.birth_certificate(registration_date);
CREATE INDEX IF NOT EXISTS idx_birth_certificate_dob ON justice.birth_certificate(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_birth_certificate_father_id ON justice.birth_certificate(father_citizen_id) WHERE father_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_birth_certificate_mother_id ON justice.birth_certificate(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_birth_certificate_declarant_id ON justice.birth_certificate(declarant_citizen_id) WHERE declarant_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_birth_certificate_authority_id ON justice.birth_certificate(issuing_authority_id);
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.birth_certificate.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `issuing_authority_id` hoặc nơi đăng ký.
-- 4. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA để xác thực `father_citizen_id`, `mother_citizen_id`, `declarant_citizen_id` (nếu được cung cấp).
--    - App BTP cần gọi API của App BCA (hoặc gửi event) để thông báo về việc tạo bản ghi khai sinh mới, cung cấp `citizen_id` và các thông tin cần thiết để App BCA tạo/cập nhật bản ghi `public_security.citizen`.
-- 5. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 6. Permissions: Đảm bảo các role (justice_reader, justice_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 7. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của các ràng buộc UNIQUE (`uq_birth_certificate_no`, `uq_birth_certificate_citizen_id`) trên môi trường có partitioning.
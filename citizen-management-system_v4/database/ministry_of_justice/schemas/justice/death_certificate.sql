-- =============================================================================
-- File: ministry_of_justice/schemas/justice/death_certificate.sql
-- Description: Tạo bảng death_certificate (Giấy khai tử) trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure - Removed Cross-DB FKs)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'reference.authorities', 'reference.regions', 'reference.provinces', 'reference.districts'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.death_certificate...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.death_certificate CASCADE;

-- Tạo bảng death_certificate với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.death_certificate (
    death_certificate_id BIGSERIAL NOT NULL,                 -- ID tự tăng của giấy khai tử (dùng BIGSERIAL)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân được khai tử (Logic liên kết đến public_security.citizen)
    death_certificate_no VARCHAR(20) NOT NULL,           -- Số giấy khai tử (Yêu cầu duy nhất toàn cục)
    book_id VARCHAR(20),                                 -- Số quyển sổ đăng ký khai tử
    page_no VARCHAR(10),                                 -- Số trang trong quyển sổ
    date_of_death DATE NOT NULL,                         -- Ngày mất
    time_of_death TIME,                                  -- Giờ mất (nếu có)
    place_of_death TEXT NOT NULL,                        -- Nơi mất chi tiết
    cause_of_death TEXT,                                 -- Nguyên nhân mất (ghi nhận dạng text)
    declarant_name VARCHAR(100) NOT NULL,                -- Tên người đi khai tử
    declarant_citizen_id VARCHAR(12),                    -- Số CCCD/ĐDCN của người khai tử (Logic liên kết đến public_security.citizen)
    declarant_relationship VARCHAR(50),                  -- Quan hệ của người khai tử với người đã mất
    registration_date DATE NOT NULL,                     -- Ngày đăng ký khai tử
    issuing_authority_id SMALLINT,                       -- Cơ quan đăng ký khai tử (FK đến reference.authorities)
    death_notification_no VARCHAR(50),                   -- Số giấy báo tử (nếu có, từ cơ sở y tế/công an)
    witness1_name VARCHAR(100),                          -- Tên người làm chứng 1 (nếu có)
    witness2_name VARCHAR(100),                          -- Tên người làm chứng 2 (nếu có)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái hiệu lực của bản ghi (TRUE = Active)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký khai tử)
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
    CONSTRAINT pk_death_certificate PRIMARY KEY (death_certificate_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất (Cần kiểm tra kỹ với partitioning)
    CONSTRAINT uq_death_certificate_no UNIQUE (death_certificate_no), -- Số giấy khai tử phải duy nhất
    CONSTRAINT uq_death_certificate_citizen_id UNIQUE (citizen_id), -- Mỗi công dân chỉ có 1 giấy khai tử

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- **ĐÃ XÓA FK đến public_security.citizen**
    CONSTRAINT fk_death_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_death_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_death_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_death_certificate_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_death_certificate_dates CHECK (
        date_of_death <= CURRENT_DATE AND
        registration_date >= date_of_death AND -- Ngày đăng ký phải sau hoặc bằng ngày mất
        registration_date <= CURRENT_DATE
    ),
     CONSTRAINT ck_death_certificate_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- province_id và district_id là NOT NULL, nên region_id cũng phải NOT NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.death_certificate IS 'Lưu thông tin đăng ký khai tử.';
COMMENT ON COLUMN justice.death_certificate.citizen_id IS 'Số định danh cá nhân của người được khai tử (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.death_certificate.death_certificate_no IS 'Số định danh duy nhất của giấy khai tử.';
COMMENT ON COLUMN justice.death_certificate.date_of_death IS 'Ngày mất của công dân.';
COMMENT ON COLUMN justice.death_certificate.place_of_death IS 'Nơi mất chi tiết.';
COMMENT ON COLUMN justice.death_certificate.cause_of_death IS 'Nguyên nhân mất (ghi nhận dạng text).';
COMMENT ON COLUMN justice.death_certificate.declarant_citizen_id IS 'Số định danh của người đi khai tử (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.death_certificate.registration_date IS 'Ngày đăng ký khai tử.';
COMMENT ON COLUMN justice.death_certificate.issuing_authority_id IS 'Cơ quan thực hiện đăng ký khai tử.';
COMMENT ON COLUMN justice.death_certificate.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.death_certificate.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN justice.death_certificate.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên khóa ngoại và các cột thường dùng để lọc/sắp xếp
-- Index trên các cột UNIQUE đã được tạo tự động
CREATE INDEX IF NOT EXISTS idx_death_certificate_date_of_death ON justice.death_certificate(date_of_death);
CREATE INDEX IF NOT EXISTS idx_death_certificate_reg_date ON justice.death_certificate(registration_date);
CREATE INDEX IF NOT EXISTS idx_death_certificate_declarant_id ON justice.death_certificate(declarant_citizen_id) WHERE declarant_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_death_certificate_authority_id ON justice.death_certificate(issuing_authority_id);
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.death_certificate.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `issuing_authority_id` hoặc nơi đăng ký.
-- 4. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA để xác thực `citizen_id` và `declarant_citizen_id` (nếu được cung cấp).
--    - App BTP cần gọi API của App BCA (hoặc gửi event) để thông báo về việc đăng ký khai tử, cung cấp `citizen_id` và các thông tin cần thiết (ngày mất, nơi mất, nguyên nhân...) để App BCA cập nhật trạng thái `citizen_status` và `citizen`.
-- 5. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 6. Permissions: Đảm bảo các role (justice_reader, justice_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 7. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của các ràng buộc UNIQUE (`uq_death_certificate_no`, `uq_death_certificate_citizen_id`) trên môi trường có partitioning.

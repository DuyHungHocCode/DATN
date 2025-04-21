-- =============================================================================
-- File: ministry_of_justice/schemas/justice/marriage.sql
-- Description: Tạo bảng marriage (Đăng ký kết hôn) trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure - Removed Cross-DB FKs)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'reference.nationalities', 'reference.authorities', 'reference.regions', 'reference.provinces', 'reference.districts'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.marriage...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.marriage CASCADE;

-- Tạo bảng marriage với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.marriage (
    marriage_id BIGSERIAL NOT NULL,                      -- ID tự tăng của bản ghi kết hôn (dùng BIGSERIAL)
    marriage_certificate_no VARCHAR(20) NOT NULL,        -- Số giấy đăng ký kết hôn (Yêu cầu duy nhất toàn cục)
    book_id VARCHAR(20),                                 -- Số quyển sổ hộ tịch
    page_no VARCHAR(10),                                 -- Số trang trong quyển sổ

    -- Thông tin người chồng
    husband_id VARCHAR(12) NOT NULL,                     -- ID của người chồng (Logic liên kết đến public_security.citizen)
    husband_full_name VARCHAR(100) NOT NULL,             -- Họ tên đầy đủ người chồng (lưu lại để tra cứu nhanh)
    husband_date_of_birth DATE NOT NULL,                 -- Ngày sinh người chồng (dùng để kiểm tra tuổi kết hôn)
    husband_nationality_id SMALLINT NOT NULL,            -- Quốc tịch người chồng (FK đến reference.nationalities)
    husband_previous_marriage_status VARCHAR(50),        -- Tình trạng hôn nhân trước đây (vd: Độc thân, Đã ly hôn - lấy từ giấy xác nhận)

    -- Thông tin người vợ
    wife_id VARCHAR(12) NOT NULL,                        -- ID của người vợ (Logic liên kết đến public_security.citizen)
    wife_full_name VARCHAR(100) NOT NULL,                -- Họ tên đầy đủ người vợ
    wife_date_of_birth DATE NOT NULL,                    -- Ngày sinh người vợ (dùng để kiểm tra tuổi kết hôn)
    wife_nationality_id SMALLINT NOT NULL,               -- Quốc tịch người vợ (FK đến reference.nationalities)
    wife_previous_marriage_status VARCHAR(50),           -- Tình trạng hôn nhân trước đây

    -- Thông tin đăng ký
    marriage_date DATE NOT NULL,                         -- Ngày đăng ký kết hôn (ngày diễn ra sự kiện)
    registration_date DATE NOT NULL,                     -- Ngày ghi vào sổ đăng ký kết hôn (có thể trùng marriage_date)
    issuing_authority_id SMALLINT NOT NULL,              -- Cơ quan đăng ký kết hôn (FK đến reference.authorities)
    issuing_place TEXT NOT NULL,                         -- Nơi đăng ký kết hôn (ghi chi tiết theo tên cơ quan/địa điểm)
    witness1_name VARCHAR(100),                          -- Tên người làm chứng 1 (nếu có)
    witness2_name VARCHAR(100),                          -- Tên người làm chứng 2 (nếu có)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái hôn nhân (TRUE = còn hiệu lực, FALSE = đã ly hôn/hủy bỏ)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Lấy theo nơi đăng ký kết hôn)
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
    CONSTRAINT pk_marriage PRIMARY KEY (marriage_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất (Cần kiểm tra kỹ với partitioning)
    CONSTRAINT uq_marriage_certificate_no UNIQUE (marriage_certificate_no), -- Số giấy ĐKKH phải duy nhất

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- **ĐÃ XÓA FK đến public_security.citizen**
    CONSTRAINT fk_marriage_husband_nationality FOREIGN KEY (husband_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_marriage_wife_nationality FOREIGN KEY (wife_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_marriage_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_marriage_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_marriage_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_marriage_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_marriage_dates CHECK (marriage_date <= CURRENT_DATE AND registration_date >= marriage_date AND registration_date <= CURRENT_DATE),
    -- Kiểm tra tuổi kết hôn hợp pháp (Nam >= 20, Nữ >= 18 tại thời điểm kết hôn)
    -- Lưu ý: Tính toán này giả định marriage_date là ngày kết hôn thực tế.
    CONSTRAINT ck_marriage_husband_age CHECK (husband_date_of_birth <= (marriage_date - INTERVAL '20 years')),
    CONSTRAINT ck_marriage_wife_age CHECK (wife_date_of_birth <= (marriage_date - INTERVAL '18 years')),
    CONSTRAINT ck_marriage_different_people CHECK (husband_id <> wife_id), -- Chồng và vợ phải là 2 người khác nhau
    CONSTRAINT ck_marriage_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
             -- province_id và district_id là NOT NULL, nên region_id cũng phải NOT NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.marriage IS 'Lưu thông tin đăng ký kết hôn.';
COMMENT ON COLUMN justice.marriage.marriage_id IS 'ID tự tăng duy nhất của bản ghi kết hôn.';
COMMENT ON COLUMN justice.marriage.marriage_certificate_no IS 'Số giấy đăng ký kết hôn (yêu cầu duy nhất).';
COMMENT ON COLUMN justice.marriage.husband_id IS 'ID Công dân của người chồng (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.marriage.wife_id IS 'ID Công dân của người vợ (Logic liên kết đến public_security.citizen).';
COMMENT ON COLUMN justice.marriage.marriage_date IS 'Ngày đăng ký kết hôn.';
COMMENT ON COLUMN justice.marriage.registration_date IS 'Ngày ghi vào sổ đăng ký kết hôn.';
COMMENT ON COLUMN justice.marriage.issuing_authority_id IS 'Cơ quan thực hiện đăng ký kết hôn.';
COMMENT ON COLUMN justice.marriage.status IS 'Trạng thái hôn nhân (TRUE = còn hiệu lực, FALSE = đã ly hôn/hủy bỏ).';
COMMENT ON COLUMN justice.marriage.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.marriage.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN justice.marriage.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên các cột thường dùng để truy vấn
CREATE INDEX IF NOT EXISTS idx_marriage_husband_id ON justice.marriage(husband_id);
CREATE INDEX IF NOT EXISTS idx_marriage_wife_id ON justice.marriage(wife_id);
CREATE INDEX IF NOT EXISTS idx_marriage_marriage_date ON justice.marriage(marriage_date);
CREATE INDEX IF NOT EXISTS idx_marriage_registration_date ON justice.marriage(registration_date);
CREATE INDEX IF NOT EXISTS idx_marriage_status ON justice.marriage(status);
CREATE INDEX IF NOT EXISTS idx_marriage_authority_id ON justice.marriage(issuing_authority_id);
-- Index trên marriage_certificate_no đã được tạo tự động bởi ràng buộc UNIQUE
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.marriage.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `issuing_authority_id` hoặc nơi đăng ký.
-- 4. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA để xác thực `husband_id`, `wife_id` và kiểm tra tình trạng hôn nhân hiện tại của họ (đảm bảo cả hai đang độc thân/đã ly hôn/góa) trước khi cho phép đăng ký.
--    - App BTP cần gọi API của App BCA (hoặc gửi event) để thông báo về việc đăng ký kết hôn, cung cấp ID của hai công dân để App BCA cập nhật `marital_status` trong `public_security.citizen`.
-- 5. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 6. Permissions: Đảm bảo các role (justice_reader, justice_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 7. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của ràng buộc UNIQUE `uq_marriage_certificate_no` trên môi trường có partitioning. Logic kiểm tra một người chỉ có một hôn nhân active cần được xử lý ở tầng ứng dụng (App BTP).
-- =============================================================================
-- File: ministry_of_justice/schemas/justice/divorce.sql
-- Description: Tạo bảng divorce (Ghi chú ly hôn) trong schema justice.
-- Version: 3.0 (Revised for Microservices Structure)
--
-- Dependencies:
-- - Script tạo schema 'justice', 'reference'.
-- - Script tạo bảng 'justice.marriage'.
-- - Script tạo bảng 'reference.authorities', 'reference.regions', 'reference.provinces'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng justice.divorce...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
-- \connect ministry_of_justice

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS justice.divorce CASCADE;

-- Tạo bảng divorce với cấu trúc phân vùng
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE justice.divorce (
    divorce_id BIGSERIAL NOT NULL,                       -- ID tự tăng của bản ghi ly hôn (dùng BIGSERIAL)
    divorce_certificate_no VARCHAR(20) NOT NULL,         -- Số giấy chứng nhận/ghi chú ly hôn (Yêu cầu duy nhất toàn cục)
    book_id VARCHAR(20),                                 -- Số quyển sổ đăng ký hộ tịch (ghi chú ly hôn)
    page_no VARCHAR(10),                                 -- Số trang trong sổ
    marriage_id INT NOT NULL,                            -- ID của cuộc hôn nhân đã ly hôn (FK đến justice.marriage, Yêu cầu duy nhất)
    divorce_date DATE NOT NULL,                          -- Ngày bản án/quyết định ly hôn có hiệu lực pháp luật
    registration_date DATE NOT NULL,                     -- Ngày thực hiện đăng ký/ghi chú ly hôn vào sổ hộ tịch
    court_name VARCHAR(200) NOT NULL,                    -- Tên Tòa án ra bản án/quyết định ly hôn
    judgment_no VARCHAR(50) NOT NULL,                    -- Số bản án/quyết định của Tòa án (Yêu cầu duy nhất toàn cục)
    judgment_date DATE NOT NULL,                         -- Ngày Tòa án ra bản án/quyết định
    issuing_authority_id SMALLINT,                       -- Cơ quan đăng ký/ghi chú ly hôn (FK đến reference.authorities)
    reason TEXT,                                         -- Lý do ly hôn (nếu được ghi nhận)
    child_custody TEXT,                                  -- Thông tin về quyền nuôi con (tóm tắt hoặc tham chiếu)
    property_division TEXT,                              -- Thông tin về phân chia tài sản (tóm tắt hoặc tham chiếu)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái bản ghi (TRUE = Active/Valid)
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký/ghi chú)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho phân vùng và truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User tạo bản ghi
    updated_by VARCHAR(50),                              -- User cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_divorce PRIMARY KEY (divorce_id, geographical_region, province_id),

    -- Ràng buộc Duy nhất (Cần kiểm tra kỹ với partitioning)
    CONSTRAINT uq_divorce_certificate_no UNIQUE (divorce_certificate_no), -- Số giấy chứng nhận/ghi chú phải duy nhất
    CONSTRAINT uq_divorce_judgment_no UNIQUE (judgment_no),               -- Số bản án/quyết định phải duy nhất
    CONSTRAINT uq_divorce_marriage_id UNIQUE (marriage_id),               -- Đảm bảo mỗi cuộc hôn nhân chỉ được ghi chú ly hôn 1 lần

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BTP)
    -- Lưu ý: FK tới bảng marriage (đã phân vùng) cần kiểm tra kỹ lưỡng.
    CONSTRAINT fk_divorce_marriage FOREIGN KEY (marriage_id) REFERENCES justice.marriage(marriage_id) ON DELETE RESTRICT, -- Không cho xóa hôn nhân nếu đã có ghi chú ly hôn
    CONSTRAINT fk_divorce_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_divorce_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_divorce_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_divorce_dates CHECK (
        divorce_date <= CURRENT_DATE AND
        registration_date <= CURRENT_DATE AND
        judgment_date <= registration_date AND -- Ngày bản án phải trước hoặc bằng ngày đăng ký
        divorce_date <= registration_date AND   -- Ngày ly hôn có hiệu lực phải trước hoặc bằng ngày đăng ký
        judgment_date <= divorce_date -- Ngày bản án phải trước hoặc bằng ngày ly hôn có hiệu lực
        -- Cần trigger hoặc logic ứng dụng để kiểm tra divorce_date > marriage_date từ bảng marriage
    ),
    CONSTRAINT ck_divorce_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- province_id là NOT NULL, nên region_id cũng phải NOT NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE justice.divorce IS 'Lưu thông tin ghi chú ly hôn dựa trên bản án/quyết định của Tòa án.';
COMMENT ON COLUMN justice.divorce.divorce_certificate_no IS 'Số giấy chứng nhận/ghi chú ly hôn (nếu có cấp riêng) hoặc số tham chiếu.';
COMMENT ON COLUMN justice.divorce.marriage_id IS 'ID của cuộc hôn nhân đã được Tòa án giải quyết ly hôn (tham chiếu đến justice.marriage).';
COMMENT ON COLUMN justice.divorce.divorce_date IS 'Ngày bản án/quyết định ly hôn có hiệu lực pháp luật.';
COMMENT ON COLUMN justice.divorce.registration_date IS 'Ngày thực hiện ghi chú việc ly hôn vào sổ hộ tịch.';
COMMENT ON COLUMN justice.divorce.court_name IS 'Tên Tòa án nhân dân đã ra bản án/quyết định ly hôn.';
COMMENT ON COLUMN justice.divorce.judgment_no IS 'Số bản án/quyết định ly hôn của Tòa án.';
COMMENT ON COLUMN justice.divorce.judgment_date IS 'Ngày Tòa án ra bản án/quyết định ly hôn.';
COMMENT ON COLUMN justice.divorce.issuing_authority_id IS 'Cơ quan Tư pháp thực hiện ghi chú ly hôn.';
COMMENT ON COLUMN justice.divorce.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN justice.divorce.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';

-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên khóa ngoại và các cột thường dùng để lọc/sắp xếp
-- Index trên các cột UNIQUE đã được tạo tự động
CREATE INDEX IF NOT EXISTS idx_divorce_divorce_date ON justice.divorce(divorce_date);
CREATE INDEX IF NOT EXISTS idx_divorce_registration_date ON justice.divorce(registration_date);
CREATE INDEX IF NOT EXISTS idx_divorce_judgment_date ON justice.divorce(judgment_date);
CREATE INDEX IF NOT EXISTS idx_divorce_issuing_authority_id ON justice.divorce(issuing_authority_id);
-- Index trên marriage_id đã có trong ràng buộc UNIQUE
-- Index trên cột phân vùng province_id đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng justice.divorce.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_justice/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at` (trong thư mục `triggers/`).
--    - Tạo trigger kiểm tra `divorce_date` > `marriage_date` (cần truy vấn bảng `justice.marriage`).
--    - Tạo trigger cập nhật trạng thái (`status` = FALSE) cho bản ghi `justice.marriage` tương ứng.
--    - Tạo trigger ghi nhật ký audit (trong thư mục `triggers/audit_triggers.sql`).
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `region_id`) dựa trên `issuing_authority_id` hoặc nơi đăng ký.
-- 4. Cross-Service Coordination (Application Layer - App BTP & App BCA):
--    - App BTP cần gọi API của App BCA (hoặc gửi event) để thông báo về việc ghi chú ly hôn, cung cấp ID của hai công dân liên quan để App BCA cập nhật `marital_status` trong `public_security.citizen`.
-- 5. Data Loading: Nạp dữ liệu ban đầu (nếu có).
-- 6. Permissions: Đảm bảo các role (justice_reader, justice_writer) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 7. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của các ràng buộc UNIQUE (`uq_divorce_certificate_no`, `uq_divorce_judgment_no`, `uq_divorce_marriage_id`) trên môi trường có partitioning.
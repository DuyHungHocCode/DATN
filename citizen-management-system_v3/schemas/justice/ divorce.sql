-- =============================================================================
-- File: database/schemas/justice/divorce.sql
-- Description: Creates the divorce table in the justice schema to store divorce records.
-- Version: 2.0 (Integrated constraints, indexes, partitioning, removed comments)
-- =============================================================================

\echo 'Creating divorce table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.divorce CASCADE;

-- Create the divorce table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.divorce (
    divorce_id SERIAL NOT NULL,                          -- ID tự tăng của bản ghi ly hôn
    divorce_certificate_no VARCHAR(20) NOT NULL,         -- Số giấy chứng nhận/ghi chú ly hôn (Unique)
    book_id VARCHAR(20),                                 -- Số quyển sổ đăng ký
    page_no VARCHAR(10),                                 -- Số trang trong sổ
    marriage_id INT NOT NULL,                            -- ID của cuộc hôn nhân đã ly hôn (FK justice.marriage, Unique)
    divorce_date DATE NOT NULL,                          -- Ngày bản án/quyết định ly hôn có hiệu lực
    registration_date DATE NOT NULL,                     -- Ngày đăng ký/ghi chú ly hôn vào sổ
    court_name VARCHAR(200) NOT NULL,                    -- Tên Tòa án ra bản án/quyết định
    judgment_no VARCHAR(50) NOT NULL,                    -- Số bản án/quyết định của Tòa án (Unique)
    judgment_date DATE NOT NULL,                         -- Ngày ra bản án/quyết định
    issuing_authority_id SMALLINT,                       -- Cơ quan đăng ký/ghi chú ly hôn (FK reference.authorities)
    reason TEXT,                                         -- Lý do ly hôn (nếu có)
    child_custody TEXT,                                  -- Thông tin về quyền nuôi con
    property_division TEXT,                              -- Thông tin về phân chia tài sản
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái bản ghi (TRUE = Active)
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_divorce PRIMARY KEY (divorce_id, geographical_region, province_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_divorce_certificate_no UNIQUE (divorce_certificate_no),
    CONSTRAINT uq_divorce_judgment_no UNIQUE (judgment_no),
    CONSTRAINT uq_divorce_marriage_id UNIQUE (marriage_id), -- Đảm bảo mỗi cuộc hôn nhân chỉ ly hôn 1 lần

    -- Ràng buộc Khóa ngoại
    CONSTRAINT fk_divorce_marriage FOREIGN KEY (marriage_id) REFERENCES justice.marriage(marriage_id) ON DELETE RESTRICT, -- Không cho xóa hôn nhân nếu đã có ly hôn
    CONSTRAINT fk_divorce_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_divorce_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_divorce_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_divorce_dates CHECK (
        divorce_date <= CURRENT_DATE AND
        registration_date <= CURRENT_DATE AND
        judgment_date <= registration_date AND -- Ngày bản án phải trước hoặc bằng ngày đăng ký
        divorce_date <= registration_date    -- Ngày ly hôn có hiệu lực phải trước hoặc bằng ngày đăng ký
        -- Cần trigger để kiểm tra divorce_date > marriage_date từ bảng marriage
    ),
    CONSTRAINT ck_divorce_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
-- marriage_id đã có unique index
-- divorce_certificate_no đã có unique index
-- judgment_no đã có unique index
CREATE INDEX IF NOT EXISTS idx_divorce_divorce_date ON justice.divorce(divorce_date);
CREATE INDEX IF NOT EXISTS idx_divorce_registration_date ON justice.divorce(registration_date);
CREATE INDEX IF NOT EXISTS idx_divorce_issuing_authority_id ON justice.divorce(issuing_authority_id);


-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger kiểm tra đảm bảo divorce_date > marriage_date (cần truy vấn bảng marriage).
--    - Trigger cập nhật marital_status trong public_security.citizen cho cả hai vợ chồng.
--    - Trigger cập nhật trạng thái của bản ghi marriage liên quan (ví dụ: set status = FALSE).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, region_id.
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.

COMMIT;

\echo 'divorce table created successfully with partitioning, constraints, and indexes.'
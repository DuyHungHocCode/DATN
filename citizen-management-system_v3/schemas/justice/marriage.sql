-- =============================================================================
-- File: database/schemas/justice/marriage.sql
-- Description: Creates the marriage table in the justice schema.
-- Version: 2.0 (Integrated constraints, indexes, partitioning, removed comments)
-- =============================================================================

\echo 'Creating marriage table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.marriage CASCADE;

-- Create the marriage table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.marriage (
    marriage_id SERIAL NOT NULL,                         -- ID tự tăng của bản ghi kết hôn
    marriage_certificate_no VARCHAR(20) NOT NULL,        -- Số giấy đăng ký kết hôn (Unique)
    book_id VARCHAR(20),                                 -- Số quyển hộ tịch
    page_no VARCHAR(10),                                 -- Số trang trong quyển

    -- Thông tin người chồng
    husband_id VARCHAR(12) NOT NULL,                     -- ID của người chồng (FK public_security.citizen)
    husband_full_name VARCHAR(100) NOT NULL,             -- Họ tên đầy đủ người chồng (lưu lại để tra cứu nhanh)
    husband_date_of_birth DATE NOT NULL,                 -- Ngày sinh người chồng (kiểm tra tuổi)
    husband_nationality_id SMALLINT NOT NULL,            -- Quốc tịch người chồng (FK reference.nationalities)
    husband_previous_marriage_status VARCHAR(50),        -- Tình trạng hôn nhân trước đây (vd: Độc thân, Đã ly hôn)

    -- Thông tin người vợ
    wife_id VARCHAR(12) NOT NULL,                        -- ID của người vợ (FK public_security.citizen)
    wife_full_name VARCHAR(100) NOT NULL,                -- Họ tên đầy đủ người vợ
    wife_date_of_birth DATE NOT NULL,                    -- Ngày sinh người vợ
    wife_nationality_id SMALLINT NOT NULL,               -- Quốc tịch người vợ (FK reference.nationalities)
    wife_previous_marriage_status VARCHAR(50),           -- Tình trạng hôn nhân trước đây

    -- Thông tin đăng ký
    marriage_date DATE NOT NULL,                         -- Ngày kết hôn
    registration_date DATE NOT NULL,                     -- Ngày đăng ký kết hôn
    issuing_authority_id SMALLINT NOT NULL,              -- Cơ quan đăng ký kết hôn (FK reference.authorities)
    issuing_place TEXT NOT NULL,                         -- Nơi đăng ký kết hôn (chi tiết)
    witness1_name VARCHAR(100),                          -- Tên người làm chứng 1 (nếu có)
    witness2_name VARCHAR(100),                          -- Tên người làm chứng 2 (nếu có)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái hôn nhân (TRUE = còn hiệu lực, FALSE = đã ly hôn/hủy)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Lấy theo nơi đăng ký)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_marriage PRIMARY KEY (marriage_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_marriage_certificate_no UNIQUE (marriage_certificate_no),
    -- Ràng buộc unique logic (đảm bảo 1 người chỉ có 1 hôn nhân active) cần xử lý bằng trigger hoặc logic ứng dụng

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_marriage_husband FOREIGN KEY (husband_id) REFERENCES public_security.citizen(citizen_id) ON DELETE RESTRICT, -- Không cho xóa citizen nếu đang có hôn nhân active
    CONSTRAINT fk_marriage_wife FOREIGN KEY (wife_id) REFERENCES public_security.citizen(citizen_id) ON DELETE RESTRICT,
    CONSTRAINT fk_marriage_husband_nationality FOREIGN KEY (husband_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_marriage_wife_nationality FOREIGN KEY (wife_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_marriage_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_marriage_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_marriage_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_marriage_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_marriage_dates CHECK (marriage_date <= CURRENT_DATE AND registration_date >= marriage_date AND registration_date <= CURRENT_DATE),
    -- Kiểm tra tuổi kết hôn hợp pháp (Nam >= 20, Nữ >= 18 tại thời điểm kết hôn)
    CONSTRAINT ck_marriage_husband_age CHECK (husband_date_of_birth <= (marriage_date - INTERVAL '20 years')),
    CONSTRAINT ck_marriage_wife_age CHECK (wife_date_of_birth <= (marriage_date - INTERVAL '18 years')),
    CONSTRAINT ck_marriage_different_people CHECK (husband_id <> wife_id),
    CONSTRAINT ck_marriage_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_marriage_husband_id ON justice.marriage(husband_id);
CREATE INDEX IF NOT EXISTS idx_marriage_wife_id ON justice.marriage(wife_id);
CREATE INDEX IF NOT EXISTS idx_marriage_marriage_date ON justice.marriage(marriage_date);
CREATE INDEX IF NOT EXISTS idx_marriage_registration_date ON justice.marriage(registration_date);
CREATE INDEX IF NOT EXISTS idx_marriage_status ON justice.marriage(status);
CREATE INDEX IF NOT EXISTS idx_marriage_authority_id ON justice.marriage(issuing_authority_id);

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên issuing_authority_id hoặc issuing_place.
--    - Trigger cập nhật marital_status trong bảng public_security.citizen cho cả vợ và chồng khi tạo/cập nhật bản ghi marriage.
--    - Trigger kiểm tra logic unique: Đảm bảo một người không thể có nhiều hơn một hôn nhân có status = TRUE.
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.
-- 3. Foreign Data Wrapper (FDW): Cần FDW để truy cập public_security.citizen cho FK và trigger cập nhật marital_status.

COMMIT;

\echo 'marriage table created successfully with partitioning, constraints, and indexes.'
-- =============================================================================
-- File: database/schemas/justice/death_certificate.sql
-- Description: Tạo bảng death_certificate (Giấy khai tử) trong schema justice.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating death_certificate table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.death_certificate CASCADE;

-- Create the death_certificate table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.death_certificate (
    death_certificate_id SERIAL NOT NULL,                 -- ID tự tăng của giấy khai tử
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân được khai tử (FK public_security.citizen, Unique)
    death_certificate_no VARCHAR(20) NOT NULL,           -- Số giấy khai tử (Unique)
    book_id VARCHAR(20),                                 -- Số quyển
    page_no VARCHAR(10),                                 -- Số trang trong quyển
    date_of_death DATE NOT NULL,                         -- Ngày mất
    time_of_death TIME,                                  -- Giờ mất (nếu có)
    place_of_death TEXT NOT NULL,                        -- Nơi mất chi tiết
    cause_of_death TEXT,                                 -- Nguyên nhân mất (nếu có)
    declarant_name VARCHAR(100) NOT NULL,                -- Tên người đi khai tử
    declarant_citizen_id VARCHAR(12),                    -- Số CCCD/ĐDCN của người khai tử (FK public_security.citizen)
    declarant_relationship VARCHAR(50),                  -- Quan hệ của người khai tử với người đã mất
    registration_date DATE NOT NULL,                     -- Ngày đăng ký khai tử
    issuing_authority_id SMALLINT,                       -- Cơ quan đăng ký khai tử (FK reference.authorities)
    death_notification_no VARCHAR(50),                   -- Số giấy báo tử (nếu có)
    witness1_name VARCHAR(100),                          -- Tên người làm chứng 1 (nếu có)
    witness2_name VARCHAR(100),                          -- Tên người làm chứng 2 (nếu có)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái hiệu lực của bản ghi (TRUE = Active)
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký khai tử)
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
    CONSTRAINT pk_death_certificate PRIMARY KEY (death_certificate_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_death_certificate_no UNIQUE (death_certificate_no),
    CONSTRAINT uq_death_certificate_citizen_id UNIQUE (citizen_id), -- Mỗi công dân chỉ có 1 giấy khai tử

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_death_certificate_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE RESTRICT, -- Không cho xóa citizen nếu đã có giấy khai tử
    CONSTRAINT fk_death_certificate_declarant FOREIGN KEY (declarant_citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE SET NULL,
    CONSTRAINT fk_death_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_death_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_death_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_death_certificate_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_death_certificate_dates CHECK (
        date_of_death <= CURRENT_DATE AND
        registration_date >= date_of_death AND
        registration_date <= CURRENT_DATE
    ),
     CONSTRAINT ck_death_certificate_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_death_certificate_citizen_id ON justice.death_certificate(citizen_id); -- Đã có unique index
CREATE INDEX IF NOT EXISTS idx_death_certificate_death_no ON justice.death_certificate(death_certificate_no); -- Đã có unique index
CREATE INDEX IF NOT EXISTS idx_death_certificate_date_of_death ON justice.death_certificate(date_of_death);
CREATE INDEX IF NOT EXISTS idx_death_certificate_reg_date ON justice.death_certificate(registration_date);
CREATE INDEX IF NOT EXISTS idx_death_certificate_declarant_id ON justice.death_certificate(declarant_citizen_id) WHERE declarant_citizen_id IS NOT NULL;
-- Index trên khóa ngoại thường được tạo tự động hoặc không quá cần thiết trừ khi có join lớn
-- CREATE INDEX IF NOT EXISTS idx_death_certificate_authority_id ON justice.death_certificate(issuing_authority_id);
-- CREATE INDEX IF NOT EXISTS idx_death_certificate_province_id ON justice.death_certificate(province_id); -- Đã có trong PK
-- CREATE INDEX IF NOT EXISTS idx_death_certificate_district_id ON justice.death_certificate(district_id); -- Đã có trong PK


-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger tự động cập nhật trạng thái death_status trong bảng public_security.citizen_status (và có thể cả public_security.citizen).
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên nơi đăng ký (issuing_authority_id) hoặc nơi mất.
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 2. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.
-- 3. Foreign Data Wrapper (FDW): Cấu hình FDW để truy cập public_security.citizen cho FK và trigger cập nhật trạng thái.

COMMIT;

\echo 'death_certificate table created successfully with partitioning, constraints, and indexes.'
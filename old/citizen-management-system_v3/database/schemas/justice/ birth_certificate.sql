-- =============================================================================
-- File: database/schemas/justice/birth_certificate.sql
-- Description: Tạo bảng birth_certificate (Giấy khai sinh) trong schema justice.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning, loại bỏ comments)
-- =============================================================================

\echo 'Creating birth_certificate table for Ministry of Justice database...'
\connect ministry_of_justice

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS justice.birth_certificate CASCADE;

-- Create the birth_certificate table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE justice.birth_certificate (
    birth_certificate_id SERIAL NOT NULL,               -- ID tự tăng của giấy khai sinh
    citizen_id VARCHAR(12) NOT NULL,                    -- Số định danh của người được khai sinh (FK logic tới public_security.citizen)
    birth_certificate_no VARCHAR(20) NOT NULL,          -- Số giấy khai sinh (Unique)
    registration_date DATE NOT NULL,                    -- Ngày đăng ký khai sinh
    book_id VARCHAR(20),                                -- Số quyển
    page_no VARCHAR(10),                                -- Số trang trong quyển
    issuing_authority_id SMALLINT NOT NULL,             -- Cơ quan đăng ký khai sinh (FK reference.authorities)
    place_of_birth TEXT NOT NULL,                       -- Nơi sinh (chi tiết)
    date_of_birth DATE NOT NULL,                        -- Ngày sinh
    gender_at_birth gender_type NOT NULL,               -- Giới tính khi sinh (ENUM: Nam, Nữ, Khác)

    -- Thông tin cha
    father_full_name VARCHAR(100),                      -- Họ tên cha
    father_citizen_id VARCHAR(12),                      -- Số định danh của cha (FK logic tới public_security.citizen)
    father_date_of_birth DATE,                          -- Ngày sinh cha
    father_nationality_id SMALLINT,                     -- Quốc tịch cha (FK reference.nationalities)

    -- Thông tin mẹ
    mother_full_name VARCHAR(100),                      -- Họ tên mẹ
    mother_citizen_id VARCHAR(12),                      -- Số định danh của mẹ (FK logic tới public_security.citizen)
    mother_date_of_birth DATE,                          -- Ngày sinh mẹ
    mother_nationality_id SMALLINT,                     -- Quốc tịch mẹ (FK reference.nationalities)

    -- Thông tin người khai
    declarant_name VARCHAR(100) NOT NULL,               -- Họ tên người đi khai sinh
    declarant_citizen_id VARCHAR(12),                   -- Số định danh người đi khai (FK logic tới public_security.citizen)
    declarant_relationship VARCHAR(50),                 -- Quan hệ với người được khai sinh

    -- Thông tin khác
    witness1_name VARCHAR(100),                         -- Người làm chứng 1 (nếu có)
    witness2_name VARCHAR(100),                         -- Người làm chứng 2 (nếu có)
    birth_notification_no VARCHAR(50),                  -- Số giấy chứng sinh (nếu có)
    status BOOLEAN DEFAULT TRUE,                        -- Trạng thái hiệu lực của bản ghi
    notes TEXT,                                         -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi đăng ký)
    region_id SMALLINT NOT NULL,                        -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                           -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                           -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,           -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_birth_certificate PRIMARY KEY (birth_certificate_id, geographical_region, province_id, district_id),

    -- Ràng buộc Duy nhất
    CONSTRAINT uq_birth_certificate_no UNIQUE (birth_certificate_no),
    CONSTRAINT uq_birth_certificate_citizen_id UNIQUE (citizen_id), -- Mỗi công dân chỉ có 1 giấy khai sinh

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới public_security.citizen (bảng phân vùng, khác DB) không thể tạo trực tiếp. Cần đảm bảo qua FDW và logic đồng bộ/trigger.
    -- CONSTRAINT fk_birth_certificate_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE RESTRICT, -- Cần FDW
    -- CONSTRAINT fk_birth_certificate_father FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id), -- Cần FDW
    -- CONSTRAINT fk_birth_certificate_mother FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id), -- Cần FDW
    -- CONSTRAINT fk_birth_certificate_declarant FOREIGN KEY (declarant_citizen_id) REFERENCES public_security.citizen(citizen_id), -- Cần FDW
    CONSTRAINT fk_birth_certificate_father_nat FOREIGN KEY (father_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_birth_certificate_mother_nat FOREIGN KEY (mother_nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_birth_certificate_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_birth_certificate_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_birth_certificate_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_birth_certificate_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra
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

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
-- Khóa chính và unique đã tự tạo index
CREATE INDEX IF NOT EXISTS idx_birth_certificate_reg_date ON justice.birth_certificate(registration_date);
CREATE INDEX IF NOT EXISTS idx_birth_certificate_dob ON justice.birth_certificate(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_birth_certificate_father_id ON justice.birth_certificate(father_citizen_id) WHERE father_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_birth_certificate_mother_id ON justice.birth_certificate(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_birth_certificate_authority_id ON justice.birth_certificate(issuing_authority_id);

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Foreign Data Wrapper (FDW): Cấu hình FDW để truy cập public_security.citizen (kiểm tra sự tồn tại của citizen_id, father_id, mother_id, declarant_id).
-- 2. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger kiểm tra logic dữ liệu phức tạp (ví dụ: tuổi của cha/mẹ khi sinh con).
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên nơi đăng ký (issuing_authority_id).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
--    - Trigger gửi thông tin sang Bộ Công an để tạo/cập nhật bản ghi công dân mới (qua Kafka/sync mechanism).
-- 3. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.

COMMIT;

\echo 'birth_certificate table created successfully with partitioning, constraints, and indexes.'
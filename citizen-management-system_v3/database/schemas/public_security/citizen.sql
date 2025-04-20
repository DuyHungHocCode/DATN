-- =============================================================================
-- File: database/schemas/public_security/citizen.sql
-- Description: Tạo bảng citizen trong schema public_security, chứa thông tin cốt lõi của công dân.
-- Version: 2.0 (Tích hợp constraints, indexes, partitioning)
-- =============================================================================

\echo 'Creating citizen table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.citizen CASCADE;

-- Create the citizen table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.citizen (
    -- Mã định danh và Thông tin cơ bản
    citizen_id VARCHAR(12) NOT NULL,                     -- Số CCCD/Định danh cá nhân (Khóa chính)
    full_name VARCHAR(100) NOT NULL,                    -- Họ và tên đầy đủ
    date_of_birth DATE NOT NULL,                        -- Ngày sinh
    place_of_birth TEXT NOT NULL,                       -- Nơi sinh (chi tiết)
    gender gender_type NOT NULL,                        -- Giới tính (ENUM: Nam, Nữ, Khác)

    -- Thông tin nhân khẩu học
    ethnicity_id SMALLINT,                              -- Dân tộc (FK reference.ethnicities)
    religion_id SMALLINT,                               -- Tôn giáo (FK reference.religions)
    nationality_id SMALLINT NOT NULL DEFAULT 1,         -- Quốc tịch (FK reference.nationalities, mặc định là Việt Nam)
    blood_type blood_type DEFAULT 'Không xác định',     -- Nhóm máu (ENUM)
    death_status death_status DEFAULT 'Còn sống',       -- Trạng thái sống/mất (ENUM)
    marital_status marital_status DEFAULT 'Độc thân',   -- Tình trạng hôn nhân (ENUM)

    -- Thông tin liên quan hộ tịch (tham chiếu logic, không FK trực tiếp)
    birth_certificate_no VARCHAR(20),                   -- Số giấy khai sinh (tham chiếu logic tới justice.birth_certificate)
    -- death_certificate_no VARCHAR(20),                -- Số giấy khai tử (tham chiếu logic tới justice.death_certificate) - Thường quản lý ở citizen_status

    -- Thông tin học vấn, nghề nghiệp
    education_level education_level DEFAULT 'Chưa đi học', -- Trình độ học vấn (ENUM)
    occupation_id SMALLINT,                             -- Nghề nghiệp (FK reference.occupations)
    occupation_detail TEXT,                             -- Chi tiết nghề nghiệp

    -- Thông tin định danh khác
    tax_code VARCHAR(13) UNIQUE,                        -- Mã số thuế cá nhân
    social_insurance_no VARCHAR(13) UNIQUE,             -- Số sổ bảo hiểm xã hội
    health_insurance_no VARCHAR(15) UNIQUE,             -- Số thẻ bảo hiểm y tế

    -- Thông tin gia đình (tham chiếu đến chính bảng này)
    father_citizen_id VARCHAR(12),                      -- ID cha (FK public_security.citizen)
    mother_citizen_id VARCHAR(12),                      -- ID mẹ (FK public_security.citizen)

    -- Thông tin hành chính & Phân vùng
    -- Lưu ý: ward_id, district_id thường được quản lý qua bảng address/residence
    region_id SMALLINT,                                 -- Vùng/Miền (FK reference.regions, dùng cho phân vùng và query)
    province_id INT,                                    -- Tỉnh/Thành phố (FK reference.provinces, dùng cho phân vùng và query)
    district_id INT,                                    -- Quận/Huyện (FK reference.districts, dùng cho phân vùng và query) - Được cập nhật từ địa chỉ thường trú/tạm trú
    geographical_region VARCHAR(20) NOT NULL,           -- Tên vùng địa lý (Bắc, Trung, Nam) - Khóa chính cho phân vùng cấp 1

    -- Dữ liệu khác
    notes TEXT,                                         -- Ghi chú thêm
    status BOOLEAN DEFAULT TRUE,                        -- Trạng thái bản ghi (TRUE = Active)

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính
    CONSTRAINT pk_citizen PRIMARY KEY (citizen_id, geographical_region, province_id, district_id), -- Bao gồm cả cột phân vùng

    -- Ràng buộc Khóa ngoại
    CONSTRAINT fk_citizen_ethnicity FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicities(ethnicity_id),
    CONSTRAINT fk_citizen_religion FOREIGN KEY (religion_id) REFERENCES reference.religions(religion_id),
    CONSTRAINT fk_citizen_nationality FOREIGN KEY (nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_citizen_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupations(occupation_id),
    CONSTRAINT fk_citizen_father FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION, -- Cần xem xét lại việc FK đến chính bảng phân vùng
    CONSTRAINT fk_citizen_mother FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION, -- Cần xem xét lại việc FK đến chính bảng phân vùng
    CONSTRAINT fk_citizen_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_citizen_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$'),
    CONSTRAINT ck_citizen_birth_date CHECK (date_of_birth < CURRENT_DATE), -- Ngày sinh phải trước ngày hiện tại
    CONSTRAINT ck_citizen_tax_code_format CHECK (tax_code IS NULL OR tax_code ~ '^[0-9]{10}$' OR tax_code ~ '^[0-9]{13}$'),
    CONSTRAINT ck_citizen_social_insurance_format CHECK (social_insurance_no IS NULL OR social_insurance_no ~ '^[0-9]{10}$'), -- Giả định định dạng 10 số
    CONSTRAINT ck_citizen_health_insurance_format CHECK (health_insurance_no IS NULL OR health_insurance_no ~ '^[A-Z0-9]{15}$'), -- Giả định định dạng BHYT
    CONSTRAINT ck_citizen_parents_different CHECK (father_citizen_id IS NULL OR mother_citizen_id IS NULL OR father_citizen_id <> mother_citizen_id), -- Cha mẹ phải khác nhau
    CONSTRAINT ck_citizen_not_parent_of_self CHECK (citizen_id <> father_citizen_id AND citizen_id <> mother_citizen_id), -- Không thể là cha/mẹ của chính mình
    CONSTRAINT ck_citizen_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu chưa xác định
        )
) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1




-- Indexes
CREATE INDEX IF NOT EXISTS idx_citizen_full_name ON public_security.citizen USING gin (full_name gin_trgm_ops); -- Index GIN cho tìm kiếm tên gần đúng
CREATE INDEX IF NOT EXISTS idx_citizen_dob ON public_security.citizen(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_citizen_father_id ON public_security.citizen(father_citizen_id) WHERE father_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_mother_id ON public_security.citizen(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_region_province ON public_security.citizen(region_id, province_id); -- Hỗ trợ query theo địa lý
CREATE INDEX IF NOT EXISTS idx_citizen_status ON public_security.citizen(status);
-- Các chỉ mục trên khóa ngoại (ethnicity_id, religion_id,...) thường được tạo tự động ở một số phiên bản PostgreSQL, nhưng tạo rõ ràng cũng tốt.
CREATE INDEX IF NOT EXISTS idx_citizen_ethnicity_id ON public_security.citizen(ethnicity_id);
CREATE INDEX IF NOT EXISTS idx_citizen_religion_id ON public_security.citizen(religion_id);
CREATE INDEX IF NOT EXISTS idx_citizen_nationality_id ON public_security.citizen(nationality_id);
CREATE INDEX IF NOT EXISTS idx_citizen_occupation_id ON public_security.citizen(occupation_id);


-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Foreign Data Wrapper configuration: Cấu hình FDW để truy cập dữ liệu từ Bộ Tư pháp (ví dụ: liên kết birth_certificate_no).
-- 2. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
--    - Trigger cập nhật region_id, province_id, district_id, geographical_region khi địa chỉ thường trú/tạm trú thay đổi.
-- 3. Functions: Tạo các hàm cần thiết (ví dụ: hàm tìm kiếm, hàm cập nhật thông tin liên quan).

COMMIT;

\echo 'citizen table created successfully with partitioning, constraints, and indexes.'
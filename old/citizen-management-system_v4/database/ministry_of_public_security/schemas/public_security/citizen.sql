-- =============================================================================
-- File: ministry_of_public_security/schemas/public_security/citizen.sql
-- Description: Tạo bảng citizen (Công dân) trong schema public_security.
-- Version: 3.1 (Removed UNIQUE constraints incompatible with partitioning)
--
-- Dependencies:
-- - Script tạo schema 'public_security', 'reference'.
-- - Script tạo các bảng 'reference.*' (ethnicities, religions, nationalities, occupations...).
-- - Script tạo ENUMs (gender_type, blood_type, death_status, marital_status, education_level...).
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng public_security.citizen...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.citizen CASCADE;

-- Tạo bảng citizen với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE public_security.citizen (
    -- === Thông tin Định danh Cốt lõi ===
    citizen_id VARCHAR(12) NOT NULL,                       -- Số định danh cá nhân (CCCD 12 số). Khóa chính logic.
    full_name VARCHAR(100) NOT NULL,                      -- Họ và tên khai sinh đầy đủ.
    date_of_birth DATE NOT NULL,                          -- Ngày sinh.
    place_of_birth_code VARCHAR(10),                      -- Mã nơi sinh (theo đơn vị hành chính xã - ward_id) - Cần làm rõ quy ước mã
    place_of_birth_detail TEXT,                           -- Chi tiết nơi sinh (ghi dạng text nếu không có mã)
    gender gender_type NOT NULL,                          -- Giới tính (ENUM: Nam, Nữ, Khác).
    blood_type blood_type,                                -- Nhóm máu (ENUM).

    -- === Thông tin Nhân khẩu học ===
    ethnicity_id SMALLINT,                                -- Dân tộc (FK reference.ethnicities).
    religion_id SMALLINT,                                 -- Tôn giáo (FK reference.religions).
    nationality_id SMALLINT NOT NULL DEFAULT 1,           -- Quốc tịch (FK reference.nationalities, mặc định VN).

    -- === Thông tin Gia đình (Cha, Mẹ) ===
    father_citizen_id VARCHAR(12),                        -- ID công dân của cha (Tự tham chiếu logic).
    mother_citizen_id VARCHAR(12),                        -- ID công dân của mẹ (Tự tham chiếu logic).

    -- === Thông tin Học vấn, Nghề nghiệp ===
    education_level education_level,                      -- Trình độ học vấn (ENUM).
    occupation_id SMALLINT,                               -- Nghề nghiệp (FK reference.occupations).
    occupation_detail TEXT,                               -- Chi tiết nghề nghiệp (nơi làm việc...).

    -- === Thông tin Xã hội ===
    tax_code VARCHAR(13),                                 -- Mã số thuế cá nhân. **UNIQUE constraint đã bị xóa do partitioning**
    social_insurance_no VARCHAR(13),                      -- Số sổ BHXH. **UNIQUE constraint đã bị xóa do partitioning**
    health_insurance_no VARCHAR(15),                      -- Số thẻ BHYT. **UNIQUE constraint đã bị xóa do partitioning**

    -- === Thông tin liên hệ (có thể thay đổi thường xuyên) ===
    current_email VARCHAR(100),
    current_phone_number VARCHAR(15),

    -- === Trạng thái (Lấy từ bảng citizen_status) ===
    -- Các cột này có thể được denormalize ở đây hoặc join từ citizen_status
    -- current_status death_status DEFAULT 'Còn sống',
    -- current_status_update_date DATE,

    -- === Thông tin Hành chính & Phân vùng ===
    -- Các cột này nên được cập nhật bởi trigger/logic dựa trên địa chỉ thường trú/tạm trú mới nhất
    region_id SMALLINT,                                   -- Vùng/Miền (FK reference.regions).
    province_id INT NOT NULL,                             -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2).
    district_id INT NOT NULL,                             -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3).
    geographical_region VARCHAR(20) NOT NULL,             -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_citizen PRIMARY KEY (citizen_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BCA)
    CONSTRAINT fk_citizen_ethnicity FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicities(ethnicity_id),
    CONSTRAINT fk_citizen_religion FOREIGN KEY (religion_id) REFERENCES reference.religions(religion_id),
    CONSTRAINT fk_citizen_nationality FOREIGN KEY (nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_citizen_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupations(occupation_id),
    CONSTRAINT fk_citizen_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_citizen_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- FK tự tham chiếu cho cha/mẹ (cần kiểm tra với partitioning nếu có)
    -- CONSTRAINT fk_citizen_father FOREIGN KEY (father_citizen_id) REFERENCES public_security.citizen(citizen_id), -- Logic này phức tạp với partition
    -- CONSTRAINT fk_citizen_mother FOREIGN KEY (mother_citizen_id) REFERENCES public_security.citizen(citizen_id), -- Logic này phức tạp với partition

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$'), -- Định dạng CCCD 12 số
    CONSTRAINT ck_citizen_birth_date CHECK (date_of_birth < CURRENT_DATE),
    CONSTRAINT ck_citizen_parents CHECK (citizen_id <> father_citizen_id AND citizen_id <> mother_citizen_id), -- Không thể là cha/mẹ của chính mình
    CONSTRAINT ck_citizen_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL ban đầu
        )

    -- **ĐÃ XÓA:** Các ràng buộc UNIQUE trên tax_code, social_insurance_no, health_insurance_no
    -- do không tương thích trực tiếp với partitioning (không chứa đủ cột khóa phân vùng).
    -- Việc đảm bảo tính duy nhất cho các cột này cần được xử lý ở tầng ứng dụng hoặc trigger.
    -- CONSTRAINT uq_citizen_tax_code UNIQUE (tax_code),
    -- CONSTRAINT uq_citizen_social_insurance_no UNIQUE (social_insurance_no),
    -- CONSTRAINT uq_citizen_health_insurance_no UNIQUE (health_insurance_no)

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE public_security.citizen IS 'Bảng trung tâm lưu trữ thông tin cơ bản của công dân.';
COMMENT ON COLUMN public_security.citizen.citizen_id IS 'Số định danh cá nhân (CCCD 12 số) - Khóa chính logic.';
COMMENT ON COLUMN public_security.citizen.full_name IS 'Họ và tên khai sinh đầy đủ.';
COMMENT ON COLUMN public_security.citizen.date_of_birth IS 'Ngày sinh.';
COMMENT ON COLUMN public_security.citizen.place_of_birth_code IS 'Mã nơi sinh (theo đơn vị hành chính cấp xã).';
COMMENT ON COLUMN public_security.citizen.father_citizen_id IS 'ID công dân của cha (Logic liên kết).';
COMMENT ON COLUMN public_security.citizen.mother_citizen_id IS 'ID công dân của mẹ (Logic liên kết).';
COMMENT ON COLUMN public_security.citizen.tax_code IS 'Mã số thuế cá nhân (Cần kiểm tra unique ở tầng ứng dụng/trigger).';
COMMENT ON COLUMN public_security.citizen.social_insurance_no IS 'Số sổ Bảo hiểm xã hội (Cần kiểm tra unique ở tầng ứng dụng/trigger).';
COMMENT ON COLUMN public_security.citizen.health_insurance_no IS 'Số thẻ Bảo hiểm y tế (Cần kiểm tra unique ở tầng ứng dụng/trigger).';
COMMENT ON COLUMN public_security.citizen.province_id IS 'Tỉnh/Thành phố hiện tại của công dân (dùng cho phân vùng).';
COMMENT ON COLUMN public_security.citizen.district_id IS 'Quận/Huyện hiện tại của công dân (dùng cho phân vùng).';
COMMENT ON COLUMN public_security.citizen.geographical_region IS 'Vùng địa lý hiện tại của công dân (dùng cho phân vùng).';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
CREATE INDEX IF NOT EXISTS idx_citizen_full_name ON public_security.citizen USING gin (full_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_citizen_dob ON public_security.citizen(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_citizen_father_id ON public_security.citizen(father_citizen_id) WHERE father_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_mother_id ON public_security.citizen(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL;
-- Tạo index thường (không unique) cho các cột cần kiểm tra unique ở tầng ứng dụng/trigger
CREATE INDEX IF NOT EXISTS idx_citizen_tax_code ON public_security.citizen(tax_code) WHERE tax_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_bhxh ON public_security.citizen(social_insurance_no) WHERE social_insurance_no IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_bhyt ON public_security.citizen(health_insurance_no) WHERE health_insurance_no IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_phone ON public_security.citizen(current_phone_number) WHERE current_phone_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_email ON public_security.citizen(current_email) WHERE current_email IS NOT NULL;
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.citizen.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_public_security/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at`.
--    - Tạo trigger ghi nhật ký audit.
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên địa chỉ thường trú/tạm trú mới nhất từ bảng citizen_address hoặc permanent/temporary_residence.
--    - **QUAN TRỌNG:** Tạo trigger (BEFORE INSERT/UPDATE) hoặc xây dựng logic tầng ứng dụng (App BCA) để kiểm tra và đảm bảo tính duy nhất (uniqueness) cho các cột `tax_code`, `social_insurance_no`, `health_insurance_no` trên toàn bộ bảng (tất cả các partition).
-- 4. Data Loading: Nạp dữ liệu công dân ban đầu.
-- 5. Permissions: Cấp quyền phù hợp trên bảng này.


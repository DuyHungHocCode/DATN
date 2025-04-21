-- File: ministry_of_public_security/schemas/public_security/citizen.sql
-- Description: Tạo bảng citizen trong schema public_security (DB Bộ Công an),
--              chứa thông tin cốt lõi của công dân. Đã điều chỉnh cho microservices.
-- Version: 3.0
--
-- Changes:
-- - Xác nhận không có FK liên database.
-- - Giữ lại FK nội bộ và FK đến reference.
-- - Giữ lại UNIQUE constraints (cần kiểm tra với partitioning).
-- - Giữ lại cấu trúc partitioning.
-- =============================================================================

\echo 'Tạo bảng citizen cho ministry_of_public_security...'
\connect ministry_of_public_security

BEGIN;

-- Xóa bảng cũ nếu tồn tại để tạo lại
DROP TABLE IF EXISTS public_security.citizen CASCADE;

-- Tạo bảng citizen với partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Cấu trúc partitioning sẽ được tạo bởi script riêng trong thư mục partitioning/
CREATE TABLE public_security.citizen (
    -- Mã định danh và Thông tin cơ bản
    citizen_id VARCHAR(12) NOT NULL,                     -- Số CCCD/Định danh cá nhân (Khóa chính logic)
    full_name VARCHAR(100) NOT NULL,                    -- Họ và tên đầy đủ khai sinh
    date_of_birth DATE NOT NULL,                        -- Ngày sinh
    place_of_birth TEXT,                                -- Nơi sinh (chi tiết)
    gender gender_type NOT NULL,                        -- Giới tính (ENUM: Nam, Nữ, Khác)

    -- Thông tin nhân khẩu học
    ethnicity_id SMALLINT,                              -- Dân tộc (FK reference.ethnicities)
    religion_id SMALLINT,                               -- Tôn giáo (FK reference.religions)
    nationality_id SMALLINT NOT NULL DEFAULT 1,         -- Quốc tịch (FK reference.nationalities, mặc định là Việt Nam)
    blood_type blood_type DEFAULT 'Không xác định',     -- Nhóm máu (ENUM)
    death_status death_status DEFAULT 'Còn sống',       -- Trạng thái sống/mất (ENUM) - Cập nhật từ citizen_status
    marital_status marital_status DEFAULT 'Độc thân',   -- Tình trạng hôn nhân (ENUM) - Cập nhật từ BTP

    -- Thông tin liên quan hộ tịch (tham chiếu logic, không FK trực tiếp đến BTP)
    birth_certificate_no VARCHAR(20),                   -- Số giấy khai sinh (tham chiếu logic)

    -- Thông tin học vấn, nghề nghiệp
    education_level education_level DEFAULT 'Không xác định', -- Trình độ học vấn (ENUM) - Đổi default
    occupation_id SMALLINT,                             -- Nghề nghiệp (FK reference.occupations)
    occupation_detail TEXT,                             -- Chi tiết nghề nghiệp (nếu có)

    -- Thông tin định danh khác
    tax_code VARCHAR(13) UNIQUE,                        -- Mã số thuế cá nhân (Cần kiểm tra UNIQUE với partitioning)
    social_insurance_no VARCHAR(13) UNIQUE,             -- Số sổ bảo hiểm xã hội (Cần kiểm tra UNIQUE với partitioning)
    health_insurance_no VARCHAR(15) UNIQUE,             -- Số thẻ bảo hiểm y tế (Cần kiểm tra UNIQUE với partitioning)

    -- Thông tin gia đình (tham chiếu đến chính bảng này)
    father_citizen_id VARCHAR(12),                      -- ID cha (FK public_security.citizen)
    mother_citizen_id VARCHAR(12),                      -- ID mẹ (FK public_security.citizen)

    -- Thông tin hành chính & Phân vùng (Các cột này sẽ được cập nhật bởi trigger/logic dựa trên địa chỉ cư trú)
    region_id SMALLINT,                                 -- Vùng/Miền (FK reference.regions)
    province_id INT,                                    -- Tỉnh/Thành phố (FK reference.provinces) - Khóa phân vùng cấp 2
    district_id INT,                                    -- Quận/Huyện (FK reference.districts) - Khóa phân vùng cấp 3
    geographical_region VARCHAR(20) NOT NULL,           -- Tên vùng địa lý (Bắc, Trung, Nam) - Khóa phân vùng cấp 1

    -- Dữ liệu khác
    notes TEXT,                                         -- Ghi chú thêm
    status BOOLEAN DEFAULT TRUE,                        -- Trạng thái bản ghi công dân (TRUE = Active/Tồn tại)

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                             -- User/Service tạo bản ghi
    updated_by VARCHAR(50),                             -- User/Service cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm cả cột phân vùng)
    CONSTRAINT pk_citizen PRIMARY KEY (citizen_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại (Chỉ đến bảng reference cục bộ hoặc tự tham chiếu)
    CONSTRAINT fk_citizen_ethnicity FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicities(ethnicity_id),
    CONSTRAINT fk_citizen_religion FOREIGN KEY (religion_id) REFERENCES reference.religions(religion_id),
    CONSTRAINT fk_citizen_nationality FOREIGN KEY (nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_citizen_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupations(occupation_id),
    -- FK tự tham chiếu đến cha/mẹ (cần kiểm tra kỹ với partitioning và logic cập nhật)
    CONSTRAINT fk_citizen_father FOREIGN KEY (father_citizen_id, geographical_region, province_id, district_id) REFERENCES public_security.citizen(citizen_id, geographical_region, province_id, district_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_citizen_mother FOREIGN KEY (mother_citizen_id, geographical_region, province_id, district_id) REFERENCES public_security.citizen(citizen_id, geographical_region, province_id, district_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION DEFERRABLE INITIALLY DEFERRED,
    -- FK đến các bảng địa giới hành chính trong reference
    CONSTRAINT fk_citizen_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_citizen_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$'), -- Định dạng CCCD 12 số
    CONSTRAINT ck_citizen_birth_date CHECK (date_of_birth < CURRENT_DATE), -- Ngày sinh phải trong quá khứ
    CONSTRAINT ck_citizen_tax_code_format CHECK (tax_code IS NULL OR tax_code ~ '^[0-9]{10}$' OR tax_code ~ '^[0-9]{13}$'), -- Định dạng MST
    CONSTRAINT ck_citizen_social_insurance_format CHECK (social_insurance_no IS NULL OR social_insurance_no ~ '^[0-9]{10}$'), -- Định dạng sổ BHXH (giả định)
    CONSTRAINT ck_citizen_health_insurance_format CHECK (health_insurance_no IS NULL OR health_insurance_no ~ '^[A-Z0-9]{15}$'), -- Định dạng thẻ BHYT (giả định)
    CONSTRAINT ck_citizen_parents_different CHECK (father_citizen_id IS NULL OR mother_citizen_id IS NULL OR father_citizen_id <> mother_citizen_id), -- Cha mẹ phải khác nhau
    CONSTRAINT ck_citizen_not_parent_of_self CHECK (citizen_id <> father_citizen_id AND citizen_id <> mother_citizen_id), -- Không thể là cha/mẹ của chính mình
    CONSTRAINT ck_citizen_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            (region_id IS NULL AND geographical_region IS NOT NULL) -- Cho phép region_id NULL ban đầu nhưng geographical_region phải có để phân vùng
        )
) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 theo Miền

-- Comments for table and columns
COMMENT ON TABLE public_security.citizen IS '[BCA] Bảng chính lưu trữ thông tin cơ bản của công dân Việt Nam.';
COMMENT ON COLUMN public_security.citizen.citizen_id IS 'Số định danh cá nhân (CCCD 12 số) - Khóa chính logic.';
COMMENT ON COLUMN public_security.citizen.full_name IS 'Họ và tên khai sinh đầy đủ.';
COMMENT ON COLUMN public_security.citizen.place_of_birth IS 'Nơi sinh chi tiết theo giấy khai sinh.';
COMMENT ON COLUMN public_security.citizen.gender IS 'Giới tính (Nam, Nữ, Khác).';
COMMENT ON COLUMN public_security.citizen.ethnicity_id IS 'FK đến bảng reference.ethnicities.';
COMMENT ON COLUMN public_security.citizen.religion_id IS 'FK đến bảng reference.religions.';
COMMENT ON COLUMN public_security.citizen.nationality_id IS 'FK đến bảng reference.nationalities (Mặc định Việt Nam).';
COMMENT ON COLUMN public_security.citizen.death_status IS 'Trạng thái sống/mất (Cập nhật từ citizen_status).';
COMMENT ON COLUMN public_security.citizen.marital_status IS 'Tình trạng hôn nhân (Cập nhật dựa trên thông tin từ Bộ Tư pháp).';
COMMENT ON COLUMN public_security.citizen.birth_certificate_no IS 'Số giấy khai sinh (Tham chiếu logic, không có FK).';
COMMENT ON COLUMN public_security.citizen.education_level IS 'Trình độ học vấn cao nhất.';
COMMENT ON COLUMN public_security.citizen.occupation_id IS 'FK đến bảng reference.occupations.';
COMMENT ON COLUMN public_security.citizen.tax_code IS 'Mã số thuế cá nhân (nếu có).';
COMMENT ON COLUMN public_security.citizen.social_insurance_no IS 'Số sổ bảo hiểm xã hội (nếu có).';
COMMENT ON COLUMN public_security.citizen.health_insurance_no IS 'Số thẻ bảo hiểm y tế (nếu có).';
COMMENT ON COLUMN public_security.citizen.father_citizen_id IS 'ID công dân của người cha.';
COMMENT ON COLUMN public_security.citizen.mother_citizen_id IS 'ID công dân của người mẹ.';
COMMENT ON COLUMN public_security.citizen.region_id IS 'ID Vùng/Miền (Cập nhật từ địa chỉ cư trú).';
COMMENT ON COLUMN public_security.citizen.province_id IS 'ID Tỉnh/Thành phố (Cập nhật từ địa chỉ cư trú) - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.citizen.district_id IS 'ID Quận/Huyện (Cập nhật từ địa chỉ cư trú) - Khóa phân vùng cấp 3.';
COMMENT ON COLUMN public_security.citizen.geographical_region IS 'Tên Vùng/Miền (Bắc, Trung, Nam) - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.citizen.status IS 'Trạng thái bản ghi (TRUE: Còn hoạt động/tồn tại).';
COMMENT ON COLUMN public_security.citizen.created_by IS 'Người dùng hoặc dịch vụ đã tạo bản ghi.';
COMMENT ON COLUMN public_security.citizen.updated_by IS 'Người dùng hoặc dịch vụ cập nhật bản ghi lần cuối.';


-- Indexes
-- Index trên khóa chính (pk_citizen) được tạo tự động.
-- Index trên các cột UNIQUE (tax_code, social_insurance_no, health_insurance_no) được tạo tự động.
-- Các index cần thiết khác sẽ được tạo trên từng partition bởi script partitioning/execute_setup.sql
-- Ví dụ các index sẽ được tạo trên partition :
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_full_name ON public_security.citizen_partition_name USING gin (full_name gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_dob ON public_security.citizen_partition_name(date_of_birth);
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_father_id ON public_security.citizen_partition_name(father_citizen_id) WHERE father_citizen_id IS NOT NULL;
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_mother_id ON public_security.citizen_partition_name(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL;
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_status ON public_security.citizen_partition_name(status);
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_ethnicity_id ON public_security.citizen_partition_name(ethnicity_id);
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_religion_id ON public_security.citizen_partition_name(religion_id);
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_nationality_id ON public_security.citizen_partition_name(nationality_id);
-- CREATE INDEX IF NOT EXISTS idx_citizen_part_occupation_id ON public_security.citizen_partition_name(occupation_id);

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.citizen.'
\echo 'Lưu ý: Các index cụ thể sẽ được tạo trên các partition con bởi script partitioning/execute_setup.sql.'
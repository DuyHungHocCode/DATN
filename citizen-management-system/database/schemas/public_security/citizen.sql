-- citizen.sql
-- Tạo bảng Citizen (Công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng Citizen cho các database vùng miền...'

-- Hàm tạo bảng Citizen
CREATE OR REPLACE FUNCTION create_citizen_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng Citizen trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.citizen (
        citizen_id VARCHAR(12) PRIMARY KEY, -- Mã định danh công dân (12 số)
        full_name VARCHAR(100) NOT NULL,
        date_of_birth DATE NOT NULL,
        place_of_birth TEXT NOT NULL,
        gender gender_type NOT NULL,
        ethnicity_id SMALLINT REFERENCES reference.ethnicity(ethnicity_id),
        religion_id SMALLINT REFERENCES reference.religion(religion_id),
        nationality_id SMALLINT REFERENCES reference.nationality(nationality_id),
        blood_type blood_type DEFAULT 'Không xác định',
        death_status death_status DEFAULT 'Còn sống',
        birth_certificate_no VARCHAR(20),
        marital_status marital_status DEFAULT 'Độc thân',
        education_level_id SMALLINT REFERENCES reference.education_level(education_level_id),
        occupation_type_id SMALLINT REFERENCES reference.occupation_type(occupation_type_id),
        occupation_detail TEXT,
        tax_code VARCHAR(13),
        social_insurance_no VARCHAR(13),
        health_insurance_no VARCHAR(15),
        father_citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),
        mother_citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        avatar BYTEA, -- Ảnh đại diện
        notes TEXT,
        status BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50)
    );
    
    -- Thêm comment cho bảng và các cột
    COMMENT ON TABLE public_security.citizen IS 'Bảng lưu trữ thông tin công dân';
    COMMENT ON COLUMN public_security.citizen.citizen_id IS 'Mã định danh công dân (12 số)';
    COMMENT ON COLUMN public_security.citizen.full_name IS 'Họ và tên đầy đủ của công dân';
    COMMENT ON COLUMN public_security.citizen.date_of_birth IS 'Ngày sinh của công dân';
    COMMENT ON COLUMN public_security.citizen.place_of_birth IS 'Nơi sinh của công dân';
    COMMENT ON COLUMN public_security.citizen.gender IS 'Giới tính của công dân';
    COMMENT ON COLUMN public_security.citizen.ethnicity_id IS 'Mã dân tộc';
    COMMENT ON COLUMN public_security.citizen.religion_id IS 'Mã tôn giáo';
    COMMENT ON COLUMN public_security.citizen.nationality_id IS 'Mã quốc tịch';
    COMMENT ON COLUMN public_security.citizen.blood_type IS 'Nhóm máu của công dân';
    COMMENT ON COLUMN public_security.citizen.death_status IS 'Trạng thái sống/mất của công dân';
    COMMENT ON COLUMN public_security.citizen.birth_certificate_no IS 'Số giấy khai sinh';
    COMMENT ON COLUMN public_security.citizen.marital_status IS 'Tình trạng hôn nhân';
    COMMENT ON COLUMN public_security.citizen.education_level_id IS 'Mã trình độ học vấn';
    COMMENT ON COLUMN public_security.citizen.occupation_type_id IS 'Mã loại nghề nghiệp';
    COMMENT ON COLUMN public_security.citizen.occupation_detail IS 'Chi tiết nghề nghiệp';
    COMMENT ON COLUMN public_security.citizen.tax_code IS 'Mã số thuế';
    COMMENT ON COLUMN public_security.citizen.social_insurance_no IS 'Số bảo hiểm xã hội';
    COMMENT ON COLUMN public_security.citizen.health_insurance_no IS 'Số bảo hiểm y tế';
    COMMENT ON COLUMN public_security.citizen.father_citizen_id IS 'Mã định danh của cha';
    COMMENT ON COLUMN public_security.citizen.mother_citizen_id IS 'Mã định danh của mẹ';
    COMMENT ON COLUMN public_security.citizen.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN public_security.citizen.province_id IS 'Mã tỉnh/thành phố';
    COMMENT ON COLUMN public_security.citizen.avatar IS 'Ảnh đại diện của công dân';
    COMMENT ON COLUMN public_security.citizen.notes IS 'Ghi chú bổ sung';
    COMMENT ON COLUMN public_security.citizen.status IS 'Trạng thái hoạt động của bản ghi';
    COMMENT ON COLUMN public_security.citizen.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.citizen.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
    COMMENT ON COLUMN public_security.citizen.created_by IS 'Người tạo bản ghi';
    COMMENT ON COLUMN public_security.citizen.updated_by IS 'Người cập nhật bản ghi gần nhất';
    
    -- Tạo các chỉ mục cho bảng citizen
    CREATE INDEX IF NOT EXISTS idx_citizen_full_name ON public_security.citizen USING gin (full_name gin_trgm_ops);
    CREATE INDEX IF NOT EXISTS idx_citizen_date_of_birth ON public_security.citizen(date_of_birth);
    CREATE INDEX IF NOT EXISTS idx_citizen_ethnicity ON public_security.citizen(ethnicity_id);
    CREATE INDEX IF NOT EXISTS idx_citizen_religion ON public_security.citizen(religion_id);
    CREATE INDEX IF NOT EXISTS idx_citizen_nationality ON public_security.citizen(nationality_id);
    CREATE INDEX IF NOT EXISTS idx_citizen_region ON public_security.citizen(region_id);
    CREATE INDEX IF NOT EXISTS idx_citizen_province ON public_security.citizen(province_id);
    CREATE INDEX IF NOT EXISTS idx_citizen_father ON public_security.citizen(father_citizen_id);
    CREATE INDEX IF NOT EXISTS idx_citizen_mother ON public_security.citizen(mother_citizen_id);
    CREATE INDEX IF NOT EXISTS idx_citizen_death_status ON public_security.citizen(death_status);
    
    -- Tạo chỉ mục toàn văn cho họ tên, để tìm kiếm không dấu
    CREATE INDEX IF NOT EXISTS idx_citizen_full_name_unaccent ON public_security.citizen USING gin(unaccent(full_name) gin_trgm_ops);
    
    -- Hàm cập nhật thời gian chỉnh sửa
    CREATE OR REPLACE FUNCTION update_citizen_timestamp()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    
    -- Trigger tự động cập nhật thời gian chỉnh sửa
    CREATE TRIGGER update_citizen_timestamp_trigger
    BEFORE UPDATE ON public_security.citizen
    FOR EACH ROW
    EXECUTE FUNCTION update_citizen_timestamp();
    
    -- Các ràng buộc kiểm tra
    
    -- Ràng buộc kiểm tra mã định danh công dân
    ALTER TABLE public_security.citizen
    ADD CONSTRAINT check_citizen_id_format
    CHECK (citizen_id ~ '^[0-9]{12}$'); -- 12 chữ số
    
    -- Ràng buộc kiểm tra mã số thuế
    ALTER TABLE public_security.citizen
    ADD CONSTRAINT check_tax_code_format
    CHECK (tax_code IS NULL OR tax_code ~ '^[0-9]{10}$|^[0-9]{13}$'); -- 10 hoặc 13 chữ số
    
    -- Ràng buộc kiểm tra tuổi công dân (không quá 150 tuổi)
    ALTER TABLE public_security.citizen
    ADD CONSTRAINT check_citizen_age
    CHECK (date_of_birth > CURRENT_DATE - INTERVAL '150 years');
    
    -- Tạo chức năng tìm kiếm công dân
    CREATE OR REPLACE FUNCTION public_security.search_citizens(
        search_text TEXT,
        birth_year INT DEFAULT NULL,
        gender_val gender_type DEFAULT NULL,
        province_id_val INT DEFAULT NULL
    )
    RETURNS TABLE (
        citizen_id VARCHAR(12),
        full_name VARCHAR(100),
        date_of_birth DATE,
        gender gender_type,
        province_name VARCHAR(100)
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT 
            c.citizen_id,
            c.full_name,
            c.date_of_birth,
            c.gender,
            p.province_name
        FROM 
            public_security.citizen c
        JOIN 
            reference.province p ON c.province_id = p.province_id
        WHERE 
            (search_text IS NULL OR 
             c.full_name ILIKE '%' || search_text || '%' OR
             unaccent(c.full_name) ILIKE unaccent('%' || search_text || '%') OR
             c.citizen_id::TEXT LIKE '%' || search_text || '%') AND
            (birth_year IS NULL OR EXTRACT(YEAR FROM c.date_of_birth) = birth_year) AND
            (gender_val IS NULL OR c.gender = gender_val) AND
            (province_id_val IS NULL OR c.province_id = province_id_val) AND
            c.status = TRUE
        ORDER BY 
            c.full_name
        LIMIT 100;
    END;
    $$ LANGUAGE plpgsql;

END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_citizen_table();
\echo 'Đã tạo bảng Citizen cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_citizen_table();
\echo 'Đã tạo bảng Citizen cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_citizen_table();
\echo 'Đã tạo bảng Citizen cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_citizen_table();
\echo 'Đã tạo bảng Citizen cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_citizen_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng Citizen cho tất cả các database.'
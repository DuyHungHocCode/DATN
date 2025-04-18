-- =============================================================================
-- File: database/schemas/central_server/integrated_citizen.sql
-- Description: Tạo bảng integrated_citizen trong schema central trên máy chủ trung tâm,
--              tích hợp dữ liệu công dân từ Bộ Công an và Bộ Tư pháp.
-- Version: 1.0
-- =============================================================================

\echo 'Creating integrated_citizen table for Central Server database...'
\connect national_citizen_central_server

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS central.integrated_citizen CASCADE;

-- Create the integrated_citizen table with partitioning
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE central.integrated_citizen (
    -- === Core Identity (Chủ yếu từ public_security.citizen) ===
    citizen_id VARCHAR(12) NOT NULL,                       -- Số định danh cá nhân (CCCD 12 số). Khóa chính logic.
    full_name VARCHAR(100) NOT NULL,                      -- Họ và tên khai sinh đầy đủ.
    date_of_birth DATE NOT NULL,                          -- Ngày sinh.
    place_of_birth TEXT,                                  -- Nơi sinh chi tiết.
    gender gender_type NOT NULL,                          -- Giới tính (ENUM: Nam, Nữ, Khác).

    -- === Demographic Info ===
    ethnicity_id SMALLINT,                                -- Dân tộc (FK reference.ethnicities).
    religion_id SMALLINT,                                 -- Tôn giáo (FK reference.religions).
    nationality_id SMALLINT NOT NULL DEFAULT 1,           -- Quốc tịch (FK reference.nationalities, mặc định VN).

    -- === Identification Documents (Từ public_security.identification_card) ===
    current_id_card_number VARCHAR(12),                   -- Số CCCD/CMND đang sử dụng.
    current_id_card_type card_type,                       -- Loại thẻ đang sử dụng.
    current_id_card_issue_date DATE,                      -- Ngày cấp thẻ đang sử dụng.
    current_id_card_expiry_date DATE,                     -- Ngày hết hạn thẻ đang sử dụng.
    current_id_card_issuing_authority_id SMALLINT,        -- Cơ quan cấp thẻ đang sử dụng (FK reference.authorities).

    -- === Civil Status (Từ justice.* và public_security.citizen) ===
    marital_status marital_status DEFAULT 'Độc thân',     -- Tình trạng hôn nhân (ENUM).
    death_status death_status DEFAULT 'Còn sống',         -- Trạng thái công dân (ENUM: Còn sống, Đã mất, Mất tích).
    date_of_death DATE,                                   -- Ngày mất (từ justice.death_certificate).
    place_of_death TEXT,                                  -- Nơi mất (từ justice.death_certificate).
    cause_of_death TEXT,                                  -- Nguyên nhân mất (từ justice.death_certificate).
    birth_certificate_no VARCHAR(20),                     -- Số giấy khai sinh (từ justice.birth_certificate).
    birth_registration_date DATE,                       -- Ngày đăng ký khai sinh (từ justice.birth_certificate).
    death_certificate_no VARCHAR(20),                     -- Số giấy khai tử (từ justice.death_certificate).
    -- Thông tin về kết hôn/ly hôn hiện tại (cần logic để xác định)
    current_marriage_id INT,                              -- ID của cuộc hôn nhân hiện tại (logic FK tới justice.marriage)
    current_spouse_citizen_id VARCHAR(12),                -- ID của vợ/chồng hiện tại (logic FK tới public_security.citizen)
    current_marriage_date DATE,                           -- Ngày kết hôn hiện tại
    last_divorce_date DATE,                               -- Ngày ly hôn gần nhất (nếu có)

    -- === Residence Info (Từ public_security.*residence) ===
    current_permanent_address_id INT,                     -- ID địa chỉ thường trú hiện tại (logic FK tới public_security.address)
    current_permanent_address_detail TEXT,                -- Chi tiết địa chỉ thường trú hiện tại.
    current_permanent_registration_date DATE,             -- Ngày đăng ký thường trú hiện tại.
    current_temporary_address_id INT,                     -- ID địa chỉ tạm trú hiện tại (logic FK tới public_security.address)
    current_temporary_address_detail TEXT,                -- Chi tiết địa chỉ tạm trú hiện tại.
    current_temporary_registration_date DATE,             -- Ngày đăng ký tạm trú hiện tại.
    current_temporary_expiry_date DATE,                   -- Ngày hết hạn tạm trú hiện tại.

    -- === Professional & Social Info (Từ public_security.citizen) ===
    education_level education_level,                      -- Trình độ học vấn (ENUM).
    occupation_id SMALLINT,                               -- Nghề nghiệp (FK reference.occupations).
    occupation_detail TEXT,                               -- Chi tiết nghề nghiệp.
    tax_code VARCHAR(13),                                 -- Mã số thuế cá nhân (UNIQUE nếu có).
    social_insurance_no VARCHAR(13),                      -- Số sổ BHXH (UNIQUE nếu có).
    health_insurance_no VARCHAR(15),                      -- Số thẻ BHYT (UNIQUE nếu có).

    -- === Family Info (Từ public_security.citizen) ===
    father_citizen_id VARCHAR(12),                        -- ID cha.
    mother_citizen_id VARCHAR(12),                        -- ID mẹ.

    -- === Biometric & Image (Chỉ lưu thông tin cơ bản, ID tham chiếu nếu cần) ===
    has_biometric_data BOOLEAN DEFAULT FALSE,             -- Cờ báo có dữ liệu sinh trắc học chi tiết không.
    avatar_url VARCHAR(255),                              -- Đường dẫn tới ảnh đại diện (thay vì lưu BYTEA trực tiếp).

    -- === Administrative & Partitioning Info ===
    -- Các cột này cần được cập nhật dựa trên địa chỉ thường trú/tạm trú mới nhất
    region_id SMALLINT,                                   -- Vùng/Miền (FK reference.regions).
    province_id INT NOT NULL,                             -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2).
    district_id INT NOT NULL,                             -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3).
    geographical_region VARCHAR(20) NOT NULL,             -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.

    -- === System & Metadata ===
    notes TEXT,                                           -- Ghi chú thêm.
    status BOOLEAN DEFAULT TRUE,                          -- Trạng thái hoạt động của bản ghi (TRUE = Active).
    data_sources TEXT[],                                  -- Mảng chứa nguồn gốc dữ liệu ('BCA', 'BTP').
    last_updated_from_mps TIMESTAMP WITH TIME ZONE,       -- Thời điểm cập nhật cuối từ Bộ Công an.
    last_updated_from_moj TIMESTAMP WITH TIME ZONE,       -- Thời điểm cập nhật cuối từ Bộ Tư pháp.
    last_integrated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Thời điểm tích hợp/cập nhật bản ghi này lần cuối.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Thời điểm bản ghi được tạo trên máy chủ trung tâm.

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_integrated_citizen PRIMARY KEY (citizen_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng reference trên central server)
    CONSTRAINT fk_integrated_citizen_ethnicity FOREIGN KEY (ethnicity_id) REFERENCES reference.ethnicities(ethnicity_id),
    CONSTRAINT fk_integrated_citizen_religion FOREIGN KEY (religion_id) REFERENCES reference.religions(religion_id),
    CONSTRAINT fk_integrated_citizen_nationality FOREIGN KEY (nationality_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_integrated_citizen_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupations(occupation_id),
    CONSTRAINT fk_integrated_citizen_id_authority FOREIGN KEY (current_id_card_issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_integrated_citizen_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_integrated_citizen_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_integrated_citizen_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    -- Lưu ý: Các tham chiếu logic đến citizen khác (cha, mẹ, vợ/chồng) hoặc các bảng nghiệp vụ
    -- ở các DB nguồn cần được xử lý ở tầng ứng dụng hoặc qua các view/function.

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_integrated_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$'),
    CONSTRAINT ck_integrated_citizen_birth_date CHECK (date_of_birth < CURRENT_DATE),
    CONSTRAINT ck_integrated_citizen_death_logic CHECK ( (death_status = 'Đã mất' AND date_of_death IS NOT NULL) OR (death_status != 'Đã mất') ),
    CONSTRAINT ck_integrated_citizen_id_card_dates CHECK ( current_id_card_issue_date IS NULL OR current_id_card_issue_date <= CURRENT_DATE ),
    CONSTRAINT ck_integrated_citizen_id_card_expiry CHECK ( current_id_card_expiry_date IS NULL OR current_id_card_issue_date IS NULL OR current_id_card_expiry_date > current_id_card_issue_date ),
    CONSTRAINT ck_integrated_citizen_marriage_logic CHECK ( (marital_status IN ('Đã kết hôn', 'Ly thân') AND current_marriage_id IS NOT NULL AND current_spouse_citizen_id IS NOT NULL AND current_marriage_date IS NOT NULL) OR (marital_status NOT IN ('Đã kết hôn', 'Ly thân')) ),
    CONSTRAINT ck_integrated_citizen_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu chưa xác định
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_full_name ON central.integrated_citizen USING gin (full_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_dob ON central.integrated_citizen(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_id_card_num ON central.integrated_citizen(current_id_card_number) WHERE current_id_card_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_marital_status ON central.integrated_citizen(marital_status);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_death_status ON central.integrated_citizen(death_status);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_perm_addr_id ON central.integrated_citizen(current_permanent_address_id) WHERE current_permanent_address_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_father_id ON central.integrated_citizen(father_citizen_id) WHERE father_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_mother_id ON central.integrated_citizen(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_spouse_id ON central.integrated_citizen(current_spouse_citizen_id) WHERE current_spouse_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_region_prov_dist ON central.integrated_citizen(region_id, province_id, district_id); -- Hỗ trợ query theo địa lý
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_status ON central.integrated_citizen(status);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_last_integrated ON central.integrated_citizen(last_integrated_at);

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. Synchronization Logic (sync/): Cần logic phức tạp để hợp nhất dữ liệu từ các nguồn, xác định bản ghi hiện tại (current_id_card, current_marriage, current_address, etc.), và xử lý xung đột.
-- 2. Triggers (triggers/):
--    - Trigger cập nhật last_integrated_at.
--    - Trigger cập nhật geographical_region, province_id, district_id, region_id dựa trên địa chỉ mới nhất.
--    - Trigger kiểm tra tính nhất quán dữ liệu sau khi đồng bộ.
-- 3. Functions (functions/): Các hàm để truy vấn, cập nhật dữ liệu tích hợp, có thể bao gồm logic nghiệp vụ phức tạp.
-- 4. Views (views/): Tạo các view đơn giản hóa hoặc tổng hợp dữ liệu từ bảng này cho báo cáo.
-- 5. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id và district_id.

COMMIT;

\echo 'integrated_citizen table created successfully on Central Server with partitioning, constraints, and indexes.'
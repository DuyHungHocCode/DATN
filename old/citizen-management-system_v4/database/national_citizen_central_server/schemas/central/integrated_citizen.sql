-- =============================================================================
-- File: national_citizen_central_server/schemas/central/integrated_citizen.sql
-- Description: Tạo bảng integrated_citizen trong schema central trên máy chủ trung tâm,
--              lưu trữ dữ liệu công dân đã được tích hợp và tổng hợp.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Script tạo schema 'central', 'reference'.
-- - Script tạo các bảng 'reference.*' (ethnicities, religions, nationalities, occupations, authorities, regions, provinces, districts).
-- - Script tạo các ENUM cần thiết (gender_type, card_type, marital_status, death_status, education_level...).
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng central.integrated_citizen...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
-- \connect national_citizen_central_server

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS central.integrated_citizen CASCADE;

-- Tạo bảng integrated_citizen với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE central.integrated_citizen (
    -- === Thông tin Định danh Cốt lõi ===
    citizen_id VARCHAR(12) NOT NULL,                       -- Số định danh cá nhân (CCCD 12 số). Khóa chính logic.
    full_name VARCHAR(100) NOT NULL,                      -- Họ và tên khai sinh đầy đủ.
    date_of_birth DATE NOT NULL,                          -- Ngày sinh.
    place_of_birth TEXT,                                  -- Nơi sinh chi tiết (từ Giấy khai sinh).
    gender gender_type NOT NULL,                          -- Giới tính (ENUM: Nam, Nữ, Khác).

    -- === Thông tin Nhân khẩu học ===
    ethnicity_id SMALLINT,                                -- Dân tộc (FK reference.ethnicities).
    religion_id SMALLINT,                                 -- Tôn giáo (FK reference.religions).
    nationality_id SMALLINT NOT NULL DEFAULT 1,           -- Quốc tịch (FK reference.nationalities, mặc định VN).

    -- === Thông tin CCCD/CMND Hiện tại (Lấy từ bản ghi mới nhất, active nhất từ BCA) ===
    current_id_card_number VARCHAR(12),                   -- Số CCCD/CMND đang sử dụng.
    current_id_card_type card_type,                       -- Loại thẻ đang sử dụng (ENUM).
    current_id_card_issue_date DATE,                      -- Ngày cấp thẻ đang sử dụng.
    current_id_card_expiry_date DATE,                     -- Ngày hết hạn thẻ đang sử dụng.
    current_id_card_issuing_authority_id SMALLINT,        -- Cơ quan cấp thẻ đang sử dụng (FK reference.authorities).

    -- === Thông tin Hộ tịch (Tổng hợp từ BTP và BCA) ===
    marital_status marital_status DEFAULT 'Độc thân',     -- Tình trạng hôn nhân hiện tại (ENUM).
    death_status death_status DEFAULT 'Còn sống',         -- Trạng thái công dân hiện tại (ENUM: Còn sống, Đã mất, Mất tích).
    date_of_death DATE,                                   -- Ngày mất (nếu death_status = 'Đã mất').
    place_of_death TEXT,                                  -- Nơi mất (nếu có).
    cause_of_death TEXT,                                  -- Nguyên nhân mất (nếu có).
    birth_certificate_no VARCHAR(20),                     -- Số giấy khai sinh (từ BTP).
    birth_registration_date DATE,                       -- Ngày đăng ký khai sinh (từ BTP).
    death_certificate_no VARCHAR(20),                     -- Số giấy khai tử (từ BTP, nếu có).
    -- Thông tin về kết hôn/ly hôn hiện tại (cần logic đồng bộ để xác định)
    current_marriage_id INT,                              -- ID logic của cuộc hôn nhân hiện tại (tham chiếu đến justice.marriage).
    current_spouse_citizen_id VARCHAR(12),                -- ID logic của vợ/chồng hiện tại (tham chiếu đến public_security.citizen).
    current_marriage_date DATE,                           -- Ngày kết hôn hiện tại.
    last_divorce_date DATE,                               -- Ngày ly hôn gần nhất (nếu có).

    -- === Thông tin Cư trú Hiện tại (Lấy từ bản ghi mới nhất, active nhất từ BCA) ===
    current_permanent_address_id INT,                     -- ID logic địa chỉ thường trú hiện tại (tham chiếu đến public_security.address).
    current_permanent_address_detail TEXT,                -- Chi tiết địa chỉ thường trú hiện tại (denormalized).
    current_permanent_registration_date DATE,             -- Ngày đăng ký thường trú hiện tại.
    current_temporary_address_id INT,                     -- ID logic địa chỉ tạm trú hiện tại (tham chiếu đến public_security.address).
    current_temporary_address_detail TEXT,                -- Chi tiết địa chỉ tạm trú hiện tại (denormalized).
    current_temporary_registration_date DATE,             -- Ngày đăng ký tạm trú hiện tại.
    current_temporary_expiry_date DATE,                   -- Ngày hết hạn tạm trú hiện tại.

    -- === Thông tin Học vấn, Nghề nghiệp, Xã hội (Từ BCA) ===
    education_level education_level,                      -- Trình độ học vấn (ENUM).
    occupation_id SMALLINT,                               -- Nghề nghiệp (FK reference.occupations).
    occupation_detail TEXT,                               -- Chi tiết nghề nghiệp.
    tax_code VARCHAR(13) UNIQUE,                          -- Mã số thuế cá nhân (nếu có, yêu cầu duy nhất).
    social_insurance_no VARCHAR(13) UNIQUE,               -- Số sổ BHXH (nếu có, yêu cầu duy nhất).
    health_insurance_no VARCHAR(15) UNIQUE,               -- Số thẻ BHYT (nếu có, yêu cầu duy nhất).

    -- === Thông tin Gia đình (Cha, Mẹ - Từ BCA/BTP) ===
    father_citizen_id VARCHAR(12),                        -- ID logic của cha.
    mother_citizen_id VARCHAR(12),                        -- ID logic của mẹ.

    -- === Thông tin Hành chính & Phân vùng ===
    -- Các cột này cần được cập nhật bởi quy trình đồng bộ dựa trên địa chỉ thường trú/tạm trú mới nhất.
    region_id SMALLINT,                                   -- Vùng/Miền (FK reference.regions).
    province_id INT NOT NULL,                             -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2).
    district_id INT NOT NULL,                             -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3).
    geographical_region VARCHAR(20) NOT NULL,             -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.

    -- === Metadata Đồng bộ & Hệ thống ===
    data_sources TEXT[],                                  -- Mảng chứa nguồn gốc dữ liệu ('BCA', 'BTP') cho bản ghi này.
    last_synced_from_bca TIMESTAMP WITH TIME ZONE,        -- Thời điểm dữ liệu từ BCA được đồng bộ lần cuối cho bản ghi này.
    last_synced_from_btp TIMESTAMP WITH TIME ZONE,        -- Thời điểm dữ liệu từ BTP được đồng bộ lần cuối cho bản ghi này.
    last_integrated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Thời điểm bản ghi tích hợp này được cập nhật lần cuối.
    record_status VARCHAR(50) DEFAULT 'Active',           -- Trạng thái của bản ghi tích hợp (Active, Merged, Conflict, Archived...)
    notes TEXT,                                           -- Ghi chú thêm của hệ thống hoặc quản trị viên.

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
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

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_integrated_citizen_id_format CHECK (citizen_id ~ '^[0-9]{12}$'),
    CONSTRAINT ck_integrated_citizen_birth_date CHECK (date_of_birth < CURRENT_DATE),
    CONSTRAINT ck_integrated_citizen_death_logic CHECK ( (death_status = 'Đã mất' AND date_of_death IS NOT NULL) OR (death_status != 'Đã mất') ),
    CONSTRAINT ck_integrated_citizen_id_card_dates CHECK ( current_id_card_issue_date IS NULL OR current_id_card_issue_date <= CURRENT_DATE ),
    CONSTRAINT ck_integrated_citizen_id_card_expiry CHECK ( current_id_card_expiry_date IS NULL OR current_id_card_issue_date IS NULL OR current_id_card_expiry_date > current_id_card_issue_date ),
    CONSTRAINT ck_integrated_citizen_marriage_logic CHECK ( (marital_status IN ('Đã kết hôn', 'Ly thân') AND current_spouse_citizen_id IS NOT NULL AND current_marriage_date IS NOT NULL) OR (marital_status NOT IN ('Đã kết hôn', 'Ly thân')) ),
    CONSTRAINT ck_integrated_citizen_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL ban đầu nếu chưa xác định được địa chỉ
        )
    -- Lưu ý: Ràng buộc UNIQUE trên tax_code, social_insurance_no, health_insurance_no được giữ lại
    -- để đảm bảo tính duy nhất trên dữ liệu tích hợp.

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE central.integrated_citizen IS 'Bảng chứa dữ liệu công dân đã được tích hợp và tổng hợp từ các nguồn (BCA, BTP).';
COMMENT ON COLUMN central.integrated_citizen.citizen_id IS 'Số định danh cá nhân (CCCD 12 số) - Khóa chính logic.';
COMMENT ON COLUMN central.integrated_citizen.current_id_card_number IS 'Số CCCD/CMND đang sử dụng (lấy từ bản ghi mới nhất/active nhất).';
COMMENT ON COLUMN central.integrated_citizen.marital_status IS 'Tình trạng hôn nhân hiện tại (được suy ra từ dữ liệu kết hôn/ly hôn).';
COMMENT ON COLUMN central.integrated_citizen.death_status IS 'Trạng thái sống/mất hiện tại.';
COMMENT ON COLUMN central.integrated_citizen.current_permanent_address_detail IS 'Chi tiết địa chỉ thường trú hiện tại (denormalized).';
COMMENT ON COLUMN central.integrated_citizen.current_temporary_address_detail IS 'Chi tiết địa chỉ tạm trú hiện tại (denormalized).';
COMMENT ON COLUMN central.integrated_citizen.province_id IS 'Tỉnh/Thành phố hiện tại của công dân (dùng cho phân vùng).';
COMMENT ON COLUMN central.integrated_citizen.district_id IS 'Quận/Huyện hiện tại của công dân (dùng cho phân vùng).';
COMMENT ON COLUMN central.integrated_citizen.geographical_region IS 'Vùng địa lý hiện tại của công dân (dùng cho phân vùng).';
COMMENT ON COLUMN central.integrated_citizen.last_synced_from_bca IS 'Thời điểm dữ liệu từ BCA được đồng bộ lần cuối cho công dân này.';
COMMENT ON COLUMN central.integrated_citizen.last_synced_from_btp IS 'Thời điểm dữ liệu từ BTP được đồng bộ lần cuối cho công dân này.';
COMMENT ON COLUMN central.integrated_citizen.last_integrated_at IS 'Thời điểm bản ghi tích hợp này được cập nhật lần cuối.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên các cột thường dùng để truy vấn/lọc
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_full_name ON central.integrated_citizen USING gin (full_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_dob ON central.integrated_citizen(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_id_card_num ON central.integrated_citizen(current_id_card_number) WHERE current_id_card_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_marital_status ON central.integrated_citizen(marital_status);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_death_status ON central.integrated_citizen(death_status);
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_perm_addr_id ON central.integrated_citizen(current_permanent_address_id) WHERE current_permanent_address_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_temp_addr_id ON central.integrated_citizen(current_temporary_address_id) WHERE current_temporary_address_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_father_id ON central.integrated_citizen(father_citizen_id) WHERE father_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_mother_id ON central.integrated_citizen(mother_citizen_id) WHERE mother_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_spouse_id ON central.integrated_citizen(current_spouse_citizen_id) WHERE current_spouse_citizen_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_tax_code ON central.integrated_citizen(tax_code) WHERE tax_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_bhxh ON central.integrated_citizen(social_insurance_no) WHERE social_insurance_no IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_bhyt ON central.integrated_citizen(health_insurance_no) WHERE health_insurance_no IS NOT NULL;
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK
CREATE INDEX IF NOT EXISTS idx_integrated_citizen_last_integrated ON central.integrated_citizen(last_integrated_at);


COMMIT;

\echo '-> Hoàn thành tạo bảng central.integrated_citizen.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `national_citizen_central_server/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Synchronization Logic (Quan trọng nhất):
--    - Xây dựng logic đồng bộ (trong schema `sync` hoặc dùng Airflow) để đọc dữ liệu từ các schema mirror (`public_security_mirror`, `justice_mirror`).
--    - Thực hiện biến đổi, làm sạch, và hợp nhất dữ liệu.
--    - Xác định logic để chọn thông tin "hiện tại" (current_id_card, current_address, current_marriage...).
--    - Xử lý xung đột dữ liệu giữa nguồn BCA và BTP.
--    - Cập nhật hoặc chèn (`INSERT ... ON CONFLICT DO UPDATE`) dữ liệu vào bảng `central.integrated_citizen`.
--    - Cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên địa chỉ mới nhất.
--    - Cập nhật các cột metadata đồng bộ (`last_synced_from_bca`, `last_synced_from_btp`, `last_integrated_at`, `data_sources`).
-- 4. Data Loading: Chạy quy trình đồng bộ ban đầu để nạp dữ liệu vào bảng này.
-- 5. Permissions: Đảm bảo các role (central_server_reader, sync_user) có quyền phù hợp trên bảng này (trong script `02_security/02_permissions.sql`).
-- 6. Constraints Verification: Kiểm tra kỹ lưỡng hoạt động của các ràng buộc UNIQUE (tax_code, bhxh, bhyt) trên môi trường có partitioning.

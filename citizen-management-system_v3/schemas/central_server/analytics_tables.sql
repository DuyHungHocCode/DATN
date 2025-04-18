-- =============================================================================
-- File: database/schemas/central_server/analytics_tables.sql
-- Description: Tạo các bảng phục vụ mục đích phân tích dữ liệu (OLAP)
--              trong schema analytics trên máy chủ trung tâm.
-- Version: 1.0
--
-- Lưu ý: Các bảng này thường được điền dữ liệu thông qua quy trình ETL/ELT
--       từ các bảng tích hợp (central.integrated_*) hoặc các nguồn khác.
-- =============================================================================

\echo 'Creating analytics tables for Central Server database...'
\connect national_citizen_central_server

-- Tạo schema analytics nếu chưa tồn tại (thường đã tạo trong create_schemas.sql)
CREATE SCHEMA IF NOT EXISTS analytics;

BEGIN;

-- ============================================================================
-- 1. Bảng Dimension: dim_date (Bảng chiều thời gian)
-- ============================================================================
DROP TABLE IF EXISTS analytics.dim_date CASCADE;
CREATE TABLE analytics.dim_date (
    date_key INT PRIMARY KEY,                          -- Khóa chính (YYYYMMDD)
    full_date DATE NOT NULL UNIQUE,                    -- Ngày đầy đủ
    day_of_week SMALLINT NOT NULL,                     -- Thứ trong tuần (1=CN, 2=T2,...)
    day_name VARCHAR(10) NOT NULL,                     -- Tên thứ (Chủ Nhật, Thứ Hai,...)
    day_of_month SMALLINT NOT NULL,                    -- Ngày trong tháng
    day_of_year SMALLINT NOT NULL,                     -- Ngày trong năm
    week_of_year SMALLINT NOT NULL,                    -- Tuần trong năm
    month_number SMALLINT NOT NULL,                    -- Tháng (1-12)
    month_name VARCHAR(10) NOT NULL,                   -- Tên tháng (Tháng 1, Tháng 2,...)
    quarter SMALLINT NOT NULL,                         -- Quý (1-4)
    year INT NOT NULL,                                 -- Năm
    is_weekday BOOLEAN NOT NULL,                       -- Là ngày làm việc? (T2-T6)
    is_holiday BOOLEAN DEFAULT FALSE,                  -- Là ngày lễ? (Cần cập nhật riêng)
    holiday_name VARCHAR(100)                          -- Tên ngày lễ
);
-- Index
CREATE INDEX idx_dim_date_full_date ON analytics.dim_date(full_date);
CREATE INDEX idx_dim_date_year_month ON analytics.dim_date(year, month_number);

-- TODO: Cần có procedure/function để điền dữ liệu cho bảng dim_date này.

-- ============================================================================
-- 2. Bảng Dimension: dim_location (Bảng chiều địa điểm)
-- ============================================================================
DROP TABLE IF EXISTS analytics.dim_location CASCADE;
CREATE TABLE analytics.dim_location (
    location_key SERIAL PRIMARY KEY,                   -- Khóa chính tự tăng
    ward_id INT UNIQUE,                                -- ID Phường/Xã gốc (Liên kết đến reference)
    ward_code VARCHAR(10),
    ward_name VARCHAR(100),
    district_id INT,                                   -- ID Quận/Huyện gốc
    district_code VARCHAR(10),
    district_name VARCHAR(100),
    province_id INT,                                   -- ID Tỉnh/Thành phố gốc
    province_code VARCHAR(10),
    province_name VARCHAR(100),
    region_id SMALLINT,                                -- ID Vùng/Miền gốc
    region_code VARCHAR(10),
    region_name VARCHAR(50),
    geographical_region VARCHAR(20),                   -- Tên vùng (Bắc, Trung, Nam)
    -- Có thể thêm các thuộc tính khác như cấp độ đô thị, diện tích,...
    effective_start_date DATE DEFAULT '1900-01-01',    -- Ngày bắt đầu hiệu lực (SCD Type 2)
    effective_end_date DATE DEFAULT '9999-12-31',      -- Ngày kết thúc hiệu lực (SCD Type 2)
    is_current BOOLEAN DEFAULT TRUE                    -- Là bản ghi hiện tại? (SCD Type 2)
);
-- Index
CREATE INDEX idx_dim_location_ward ON analytics.dim_location(ward_id) WHERE ward_id IS NOT NULL;
CREATE INDEX idx_dim_location_district ON analytics.dim_location(district_id) WHERE district_id IS NOT NULL;
CREATE INDEX idx_dim_location_province ON analytics.dim_location(province_id) WHERE province_id IS NOT NULL;
CREATE INDEX idx_dim_location_region ON analytics.dim_location(region_id) WHERE region_id IS NOT NULL;
CREATE INDEX idx_dim_location_current ON analytics.dim_location(is_current);

-- TODO: Cần có quy trình ETL để điền và cập nhật dữ liệu (SCD Type 2) từ bảng reference.*

-- ============================================================================
-- 3. Bảng Dimension: dim_citizen (Bảng chiều công dân - Denormalized)
-- ============================================================================
DROP TABLE IF EXISTS analytics.dim_citizen CASCADE;
CREATE TABLE analytics.dim_citizen (
    citizen_key BIGSERIAL PRIMARY KEY,                 -- Khóa chính tự tăng
    citizen_id VARCHAR(12) NOT NULL,                   -- ID công dân gốc (Unique theo version)
    version INT NOT NULL DEFAULT 1,                    -- Phiên bản (SCD Type 2)
    full_name VARCHAR(100),
    gender gender_type,
    date_of_birth DATE,
    age SMALLINT,                                      -- Tuổi (tính tại thời điểm snapshot)
    age_group VARCHAR(10),                             -- Nhóm tuổi (vd: 0-4, 5-9, ...)
    ethnicity_name VARCHAR(100),                       -- Tên dân tộc
    religion_name VARCHAR(100),                        -- Tên tôn giáo
    nationality_name VARCHAR(100),                     -- Tên quốc tịch
    marital_status marital_status,
    education_level education_level,
    occupation_name VARCHAR(200),                      -- Tên nghề nghiệp
    permanent_location_key INT REFERENCES analytics.dim_location(location_key), -- Địa chỉ thường trú (FK dim_location)
    temporary_location_key INT REFERENCES analytics.dim_location(location_key), -- Địa chỉ tạm trú (FK dim_location)
    death_status death_status,
    -- Thêm các thuộc tính khác cần cho phân tích
    effective_start_date TIMESTAMP WITH TIME ZONE,     -- Ngày bắt đầu hiệu lực (SCD Type 2)
    effective_end_date TIMESTAMP WITH TIME ZONE DEFAULT '9999-12-31 23:59:59+00', -- Ngày kết thúc hiệu lực (SCD Type 2)
    is_current BOOLEAN DEFAULT TRUE                    -- Là bản ghi hiện tại? (SCD Type 2)
);
-- Index
CREATE UNIQUE INDEX uq_dim_citizen_id_version ON analytics.dim_citizen(citizen_id, version);
CREATE INDEX idx_dim_citizen_current ON analytics.dim_citizen(citizen_id, is_current) WHERE is_current = TRUE;
CREATE INDEX idx_dim_citizen_age_group ON analytics.dim_citizen(age_group);
CREATE INDEX idx_dim_citizen_gender ON analytics.dim_citizen(gender);
CREATE INDEX idx_dim_citizen_perm_loc ON analytics.dim_citizen(permanent_location_key);

-- TODO: Cần có quy trình ETL phức tạp để điền và cập nhật dữ liệu (SCD Type 2) từ central.integrated_citizen và các bảng liên quan.

-- ============================================================================
-- 4. Bảng Fact: fact_population_snapshot (Bảng fact về dân số tại thời điểm)
-- ============================================================================
DROP TABLE IF EXISTS analytics.fact_population_snapshot CASCADE;
CREATE TABLE analytics.fact_population_snapshot (
    snapshot_date_key INT NOT NULL REFERENCES analytics.dim_date(date_key), -- Khóa thời gian (YYYYMMDD)
    location_key INT NOT NULL REFERENCES analytics.dim_location(location_key), -- Khóa địa điểm
    gender gender_type NOT NULL,                       -- Giới tính
    age_group VARCHAR(10) NOT NULL,                    -- Nhóm tuổi
    ethnicity_key SMALLINT,                            -- Khóa dân tộc (FK reference.ethnicities)
    nationality_key SMALLINT,                          -- Khóa quốc tịch (FK reference.nationalities)
    -- Measures
    population_count INT NOT NULL DEFAULT 0,           -- Số lượng dân
    -- Thêm các measure khác nếu cần: số người trong độ tuổi lao động, số người già,...
    PRIMARY KEY (snapshot_date_key, location_key, gender, age_group) -- Khóa chính tổ hợp
    -- Partitioning (Ví dụ theo năm)
) PARTITION BY RANGE (snapshot_date_key);
-- Index
CREATE INDEX idx_fact_pop_snapshot_loc ON analytics.fact_population_snapshot(location_key);
CREATE INDEX idx_fact_pop_snapshot_gender ON analytics.fact_population_snapshot(gender);
CREATE INDEX idx_fact_pop_snapshot_age ON analytics.fact_population_snapshot(age_group);

-- TODO: Cần có quy trình ETL để tổng hợp dữ liệu định kỳ (vd: cuối tháng) từ dim_citizen hoặc integrated_citizen.
-- TODO: Cần tạo các partition con cho bảng này (vd: theo năm).

-- ============================================================================
-- 5. Bảng Fact: fact_vital_events (Bảng fact về các sự kiện hộ tịch)
-- ============================================================================
DROP TABLE IF EXISTS analytics.fact_vital_events CASCADE;
CREATE TABLE analytics.fact_vital_events (
    event_date_key INT NOT NULL REFERENCES analytics.dim_date(date_key), -- Khóa thời gian (YYYYMMDD)
    registration_date_key INT REFERENCES analytics.dim_date(date_key),   -- Khóa thời gian đăng ký
    location_key INT NOT NULL REFERENCES analytics.dim_location(location_key), -- Khóa địa điểm xảy ra/đăng ký sự kiện
    event_type population_change_type NOT NULL,       -- Loại sự kiện (Sinh, Tử, Kết hôn, Ly hôn, Chuyển đến, Chuyển đi...)
    -- Dimensions bổ sung (có thể thêm nếu cần)
    -- gender gender_type,
    -- age_group VARCHAR(10),
    -- Measures
    event_count INT NOT NULL DEFAULT 0                 -- Số lượng sự kiện
    -- Có thể thêm các measure chi tiết hơn
    -- PRIMARY KEY (event_date_key, location_key, event_type) -- Khóa chính tổ hợp (có thể cần điều chỉnh)
    -- Partitioning (Ví dụ theo tháng hoặc năm của event_date_key)
) PARTITION BY RANGE (event_date_key);
-- Index
CREATE INDEX idx_fact_vital_event_loc ON analytics.fact_vital_events(location_key);
CREATE INDEX idx_fact_vital_event_type ON analytics.fact_vital_events(event_type);
CREATE INDEX idx_fact_vital_event_reg_date ON analytics.fact_vital_events(registration_date_key);

-- TODO: Cần có quy trình ETL để tổng hợp dữ liệu từ các bảng hộ tịch (birth, death, marriage, divorce) và biến động dân cư.
-- TODO: Cần tạo các partition con cho bảng này (vd: theo tháng/năm).

COMMIT;

\echo 'Analytics tables (samples) created successfully in schema analytics.'
\echo 'NOTE: These tables require separate ETL processes to populate data.'
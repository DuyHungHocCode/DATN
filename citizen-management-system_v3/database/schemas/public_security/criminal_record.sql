-- =============================================================================
-- File: database/schemas/public_security/criminal_record.sql
-- Description: Creates the criminal_record table in the public_security schema.
-- Version: 2.0 (Integrated constraints, indexes, partitioning, removed comments)
-- =============================================================================

\echo 'Creating criminal_record table for Ministry of Public Security database...'
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists for clean recreation
DROP TABLE IF EXISTS public_security.criminal_record CASCADE;

-- Create the criminal_record table with partitioning
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi function trong setup_partitioning.sql
CREATE TABLE public_security.criminal_record (
    record_id SERIAL NOT NULL,                           -- ID tự tăng của bản ghi tiền án tiền sự
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân có tiền án tiền sự (FK public_security.citizen)
    crime_type criminal_record_type NOT NULL,           -- Loại tội phạm (ENUM: Vi phạm hành chính, Tội phạm nhẹ,...)
    crime_description TEXT,                              -- Mô tả chi tiết hành vi phạm tội
    crime_date DATE NOT NULL,                            -- Ngày xảy ra hành vi phạm tội
    court_name VARCHAR(200) NOT NULL,                    -- Tên tòa án xét xử
    sentence_date DATE NOT NULL,                         -- Ngày tuyên án
    sentence_length VARCHAR(100) NOT NULL,               -- Mức án ("5 năm tù", "Chung thân", "Cảnh cáo", "Phạt tiền 10tr")
    sentence_details TEXT,                               -- Chi tiết bản án (nếu cần)
    prison_facility_id INT,                              -- Nơi thi hành án (FK reference.prison_facilities) (NULL nếu không phải án tù)
    -- prison_facility_name VARCHAR(200),               -- Nên lấy từ join bảng reference.prison_facilities
    entry_date DATE,                                     -- Ngày nhập trại (nếu có)
    release_date DATE,                                   -- Ngày ra trại/mãn hạn án (dự kiến hoặc thực tế)
    status VARCHAR(50) NOT NULL DEFAULT 'Đã thi hành xong', -- Trạng thái thi hành án (ENUM: Đang thụ án, Đã mãn hạn, Ân xá, Hoãn thi hành,...)
    decision_number VARCHAR(50) NOT NULL UNIQUE,         -- Số bản án/quyết định của tòa án
    decision_date DATE NOT NULL,                         -- Ngày ra bản án/quyết định
    note TEXT,                                           -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Thường lấy theo nơi công dân đăng ký hoặc nơi xảy ra vụ án)
    region_id SMALLINT,                                  -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1
    data_sensitivity_level data_sensitivity_level DEFAULT 'Bảo mật', -- Mức độ nhạy cảm

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_criminal_record PRIMARY KEY (record_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hoặc dựa vào logic/trigger.
    CONSTRAINT fk_criminal_record_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    -- Lưu ý: Bảng reference.prison_facilities cần được tạo.
    CONSTRAINT fk_criminal_record_prison FOREIGN KEY (prison_facility_id) REFERENCES reference.prison_facilities(prison_facility_id),
    CONSTRAINT fk_criminal_record_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_criminal_record_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_criminal_record_dates CHECK (
        crime_date <= sentence_date AND
        sentence_date <= decision_date AND
        decision_date <= CURRENT_DATE AND
        (entry_date IS NULL OR (entry_date >= sentence_date AND entry_date <= CURRENT_DATE)) AND
        (release_date IS NULL OR release_date >= entry_date)
    ),
     CONSTRAINT ck_criminal_record_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam') OR
            region_id IS NULL -- Cho phép NULL nếu chưa xác định
        )
    -- Có thể thêm CHECK cho status hợp lệ

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1

-- Indexes
CREATE INDEX IF NOT EXISTS idx_criminal_record_citizen_id ON public_security.criminal_record(citizen_id);
CREATE INDEX IF NOT EXISTS idx_criminal_record_crime_type ON public_security.criminal_record(crime_type);
CREATE INDEX IF NOT EXISTS idx_criminal_record_status ON public_security.criminal_record(status);
CREATE INDEX IF NOT EXISTS idx_criminal_record_crime_date ON public_security.criminal_record(crime_date);
CREATE INDEX IF NOT EXISTS idx_criminal_record_sentence_date ON public_security.criminal_record(sentence_date);
-- Index trên decision_number đã được tạo tự động bởi ràng buộc UNIQUE

-- TODO (Những phần cần hoàn thiện ở các file khác):
-- 1. reference_tables.sql: Cần định nghĩa bảng `reference.prison_facilities`.
-- 2. reference_data/: Cần có dữ liệu cho bảng `reference.prison_facilities`.
-- 3. enum.sql: Cần định nghĩa ENUM `criminal_record_type` nếu chưa có và kiểm tra/cập nhật ENUM cho cột `status`.
-- 4. Triggers:
--    - Trigger cập nhật updated_at (chuyển sang triggers/timestamp_triggers.sql).
--    - Trigger cập nhật geographical_region, province_id, region_id.
--    - Trigger ghi nhật ký audit (chuyển sang triggers/audit_triggers.sql).
-- 5. Partitioning: Script setup_partitioning.sql sẽ tạo các partition con thực tế theo province_id.

COMMIT;

\echo 'criminal_record table created successfully with partitioning, constraints, and indexes.'
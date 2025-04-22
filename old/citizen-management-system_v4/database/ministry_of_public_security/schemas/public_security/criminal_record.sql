-- File: ministry_of_public_security/schemas/public_security/criminal_record.sql
-- Description: Tạo bảng criminal_record (Tiền án, tiền sự) trong schema public_security
--              của database Bộ Công an. Bảng này được phân vùng theo địa lý.
-- Version: 3.0 (Aligned with Microservices Structure)
-- =============================================================================

\echo '--> Tạo bảng public_security.criminal_record...'

-- Nên kết nối vào đúng database trước khi chạy file này
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng cũ nếu tồn tại để tạo lại
DROP TABLE IF EXISTS public_security.criminal_record CASCADE;

-- Tạo bảng criminal_record với phân vùng theo 2 cấp: Miền -> Tỉnh
-- (Giả định gọi partitioning.setup_nested_partitioning với p_include_district = FALSE)
CREATE TABLE public_security.criminal_record (
    record_id BIGSERIAL NOT NULL,                         -- ID tự tăng của bản ghi (nên dùng BIGSERIAL cho bảng có thể lớn)
    citizen_id VARCHAR(12) NOT NULL,                    -- Công dân có tiền án tiền sự (FK logic tới public_security.citizen)
    crime_type criminal_record_type NOT NULL,          -- Loại tội phạm (ENUM đã định nghĩa)
    crime_description TEXT,                             -- Mô tả chi tiết hành vi phạm tội
    crime_date DATE NOT NULL,                           -- Ngày xảy ra hành vi phạm tội
    court_name VARCHAR(200) NOT NULL,                   -- Tên tòa án xét xử
    sentence_date DATE NOT NULL,                        -- Ngày tuyên án
    sentence_length VARCHAR(100) NOT NULL,              -- Mức án (vd: "5 năm tù", "Chung thân", "Cảnh cáo", "Phạt tiền 10 triệu")
    sentence_details TEXT,                              -- Chi tiết bản án (nếu cần)
    prison_facility_id INTEGER,                         -- Nơi thi hành án (FK tới reference.prison_facilities cục bộ) (NULL nếu không phải án tù)
    entry_date DATE,                                    -- Ngày nhập trại (nếu có)
    release_date DATE,                                  -- Ngày ra trại/mãn hạn án (dự kiến hoặc thực tế)
    execution_status VARCHAR(50) NOT NULL DEFAULT 'Đã thi hành xong', -- Trạng thái thi hành án (vd: Đang thụ án, Đã mãn hạn, Ân xá, Hoãn thi hành...) -> Nên dùng ENUM nếu có thể
    decision_number VARCHAR(50) NOT NULL,               -- Số bản án/quyết định của tòa án (Cần đảm bảo tính duy nhất)
    decision_date DATE NOT NULL,                        -- Ngày ra bản án/quyết định
    note TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng
    -- QUAN TRỌNG: Các cột này phải được điền chính xác TRƯỚC KHI INSERT/UPDATE
    -- để đảm bảo dữ liệu vào đúng partition. Logic này thường nằm ở tầng ứng dụng (App BCA)
    -- hoặc trigger BEFORE INSERT/UPDATE dựa trên citizen_id hoặc nơi xảy ra vụ án/nơi xét xử.
    region_id SMALLINT,                                 -- Vùng/Miền (FK reference.regions) - Cần để suy ra geographical_region
    province_id INT NOT NULL,                           -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL CHECK (geographical_region IN ('Bắc', 'Trung', 'Nam')), -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata & Bảo mật
    data_sensitivity_level data_sensitivity_level DEFAULT 'Bảo mật', -- Mức độ nhạy cảm (ENUM)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50), -- User hoặc process tạo bản ghi
    updated_by VARCHAR(50), -- User hoặc process cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_criminal_record PRIMARY KEY (record_id, geographical_region, province_id),

    -- Ràng buộc Duy nhất
    -- QUAN TRỌNG: Ràng buộc UNIQUE toàn cục trên bảng phân vùng cần được kiểm tra kỹ lưỡng
    -- về hiệu năng và tính khả thi. Có thể cần UNIQUE index trên từng partition + logic ứng dụng.
    CONSTRAINT uq_criminal_record_decision_number UNIQUE (decision_number),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng DB BCA)
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra hoạt động chính xác.
    CONSTRAINT fk_criminal_record_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Khi xóa công dân, xóa luôn tiền án? Cân nhắc ON DELETE RESTRICT?
    CONSTRAINT fk_criminal_record_prison FOREIGN KEY (prison_facility_id) REFERENCES reference.prison_facilities(prison_facility_id),
    CONSTRAINT fk_criminal_record_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_criminal_record_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_criminal_record_dates CHECK (
        crime_date <= sentence_date AND
        sentence_date <= decision_date AND
        decision_date <= CURRENT_DATE AND
        (entry_date IS NULL OR (entry_date >= sentence_date AND entry_date <= CURRENT_DATE)) AND
        (release_date IS NULL OR release_date >= entry_date) -- Ngày ra trại phải sau hoặc bằng ngày nhập trại
    ),
     CONSTRAINT ck_criminal_record_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán (nếu region_id không NULL)
            (region_id IS NULL) OR
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )
    -- Có thể thêm CHECK cho execution_status nếu tạo ENUM cho nó

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) sẽ được tạo tự động bởi hàm partitioning.setup_nested_partitioning

COMMENT ON TABLE public_security.criminal_record IS 'Lưu trữ thông tin về tiền án, tiền sự của công dân.';
COMMENT ON COLUMN public_security.criminal_record.record_id IS 'ID tự tăng của bản ghi tiền án tiền sự.';
COMMENT ON COLUMN public_security.criminal_record.citizen_id IS 'Số định danh của công dân liên quan.';
COMMENT ON COLUMN public_security.criminal_record.crime_type IS 'Loại hình vi phạm/tội phạm (theo phân loại).';
COMMENT ON COLUMN public_security.criminal_record.court_name IS 'Tên tòa án đã xét xử.';
COMMENT ON COLUMN public_security.criminal_record.sentence_length IS 'Mô tả mức án (vd: 5 năm tù, cảnh cáo...).';
COMMENT ON COLUMN public_security.criminal_record.prison_facility_id IS 'ID của cơ sở giam giữ thi hành án (nếu có).';
COMMENT ON COLUMN public_security.criminal_record.execution_status IS 'Trạng thái thi hành bản án.';
COMMENT ON COLUMN public_security.criminal_record.decision_number IS 'Số bản án hoặc quyết định của tòa án.';
COMMENT ON COLUMN public_security.criminal_record.province_id IS 'Tỉnh/TP liên quan (thường là nơi xét xử hoặc nơi đăng ký của công dân) - Dùng cho phân vùng.';
COMMENT ON COLUMN public_security.criminal_record.geographical_region IS 'Vùng địa lý (Bắc, Trung, Nam) - Dùng cho phân vùng.';
COMMENT ON COLUMN public_security.criminal_record.data_sensitivity_level IS 'Mức độ nhạy cảm của dữ liệu.';

-- Indexes (Index trên PK và UNIQUE constraint được tạo tự động)
-- Các index này sẽ được tạo trên từng partition bởi script partitioning/execute_setup.sql
-- CREATE INDEX IF NOT EXISTS idx_criminal_record_citizen_id ON public_security.criminal_record(citizen_id);
-- CREATE INDEX IF NOT EXISTS idx_criminal_record_crime_type ON public_security.criminal_record(crime_type);
-- CREATE INDEX IF NOT EXISTS idx_criminal_record_status ON public_security.criminal_record(execution_status);
-- CREATE INDEX IF NOT EXISTS idx_criminal_record_crime_date ON public_security.criminal_record(crime_date);
-- CREATE INDEX IF NOT EXISTS idx_criminal_record_sentence_date ON public_security.criminal_record(sentence_date);

-- Các TODO từ file gốc đã được giải quyết hoặc chuyển thành lưu ý trong comment.

COMMIT;

\echo '    -> Hoàn thành tạo bảng public_security.criminal_record.'
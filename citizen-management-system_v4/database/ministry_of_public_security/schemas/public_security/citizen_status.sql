-- File: ministry_of_public_security/schemas/public_security/citizen_status.sql
-- Description: Tạo bảng citizen_status (Lịch sử trạng thái công dân)
--              trong schema public_security của database Bộ Công an.
-- Version: 3.0 (Reviewed for Microservices Structure)
-- =============================================================================

\echo '--> Tạo bảng public_security.citizen_status...'

-- Kết nối đến database Bộ Công an (chỉ cần nếu chạy file riêng lẻ)
-- \connect ministry_of_public_security

-- Đảm bảo schema tồn tại
CREATE SCHEMA IF NOT EXISTS public_security;

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.citizen_status CASCADE;

-- Tạo bảng citizen_status với cấu trúc phân vùng
-- Phân vùng theo 2 cấp: Miền (LIST) -> Tỉnh (LIST)
-- Lưu ý: Cột phân vùng province_id và geographical_region cần được cập nhật
--       dựa trên thông tin của công dân (ví dụ: nơi đăng ký thường trú).
CREATE TABLE public_security.citizen_status (
    status_id SERIAL NOT NULL,                           -- ID tự tăng của bản ghi trạng thái
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân liên quan (FK đến public_security.citizen)
    status_type death_status NOT NULL DEFAULT 'Còn sống', -- Trạng thái hiện tại (ENUM: Còn sống, Đã mất, Mất tích)
    status_date DATE NOT NULL,                           -- Ngày trạng thái này có hiệu lực/xảy ra
    description TEXT,                                    -- Mô tả chi tiết về thay đổi trạng thái (vd: lý do mất tích)
    cause VARCHAR(200),                                  -- Nguyên nhân (vd: Nguyên nhân tử vong - thường lấy từ BTP)
    location VARCHAR(200),                               -- Địa điểm xảy ra (vd: Nơi mất - thường lấy từ BTP)
    authority_id SMALLINT,                               -- Cơ quan xác nhận trạng thái (FK reference.authorities - vd: Tòa án, CQĐT)
    document_number VARCHAR(50),                         -- Số hiệu văn bản liên quan (vd: Quyết định của Tòa án, Giấy báo tử từ BTP)
    document_date DATE,                                  -- Ngày của văn bản liên quan
    certificate_id VARCHAR(50),                          -- ID giấy chứng nhận liên quan (vd: death_certificate_id từ BTP - lưu dạng text)
    reported_by VARCHAR(100),                            -- Người báo tin/cung cấp thông tin
    relationship VARCHAR(50),                            -- Mối quan hệ của người báo tin với công dân
    verification_status VARCHAR(50) DEFAULT 'Chưa xác minh', -- Trạng thái xác minh thông tin ('Chưa xác minh', 'Đã xác minh', 'Cần kiểm tra lại')
    is_current BOOLEAN NOT NULL DEFAULT TRUE,            -- Đánh dấu bản ghi trạng thái này là mới nhất/còn hiệu lực?
    notes TEXT,                                          -- Ghi chú bổ sung

    -- Thông tin hành chính & Phân vùng (Cần trigger hoặc logic để cập nhật)
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                              -- User/Service tạo bản ghi
    updated_by VARCHAR(50),                              -- User/Service cập nhật lần cuối

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng)
    CONSTRAINT pk_citizen_status PRIMARY KEY (status_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại (Chỉ trong phạm vi DB BCA)
    -- Lưu ý: FK tới bảng citizen (đã phân vùng) cần kiểm tra kỹ lưỡng hiệu năng và hoạt động.
    CONSTRAINT fk_citizen_status_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Nếu xóa công dân thì xóa luôn lịch sử trạng thái? Xem xét lại ON DELETE
    CONSTRAINT fk_citizen_status_authority FOREIGN KEY (authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_citizen_status_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_status_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra
    CONSTRAINT ck_citizen_status_date CHECK (status_date <= CURRENT_DATE), -- Ngày trạng thái không thể ở tương lai
    CONSTRAINT ck_citizen_document_date CHECK (document_date IS NULL OR (document_date <= CURRENT_DATE)), -- Ngày văn bản không ở tương lai
    CONSTRAINT ck_citizen_cause_location_required CHECK ( -- Yêu cầu nguyên nhân/địa điểm nếu là Đã mất/Mất tích
        (status_type IN ('Đã mất', 'Mất tích') AND cause IS NOT NULL AND location IS NOT NULL) OR
        (status_type = 'Còn sống')
    ),
    CONSTRAINT ck_citizen_status_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán với bảng reference.regions
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
            -- Lưu ý: Có thể cần xử lý trường hợp region_id NULL nếu chưa xác định được ban đầu
            -- OR region_id IS NULL
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (theo Miền)
-- Các partition con theo province_id sẽ được tạo trong các partition miền này.

COMMENT ON TABLE public_security.citizen_status IS 'Lưu trữ lịch sử thay đổi trạng thái của công dân (Còn sống, Đã mất, Mất tích).';
COMMENT ON COLUMN public_security.citizen_status.status_id IS 'ID tự tăng của bản ghi trạng thái.';
COMMENT ON COLUMN public_security.citizen_status.citizen_id IS 'ID công dân liên quan (tham chiếu public_security.citizen).';
COMMENT ON COLUMN public_security.citizen_status.status_type IS 'Trạng thái hiện tại (ENUM: Còn sống, Đã mất, Mất tích).';
COMMENT ON COLUMN public_security.citizen_status.status_date IS 'Ngày trạng thái này có hiệu lực/xảy ra.';
COMMENT ON COLUMN public_security.citizen_status.cause IS 'Nguyên nhân (ví dụ: Nguyên nhân tử vong).';
COMMENT ON COLUMN public_security.citizen_status.location IS 'Địa điểm xảy ra (ví dụ: Nơi mất).';
COMMENT ON COLUMN public_security.citizen_status.authority_id IS 'Cơ quan xác nhận trạng thái (Tòa án, CQĐT...).';
COMMENT ON COLUMN public_security.citizen_status.document_number IS 'Số hiệu văn bản liên quan (Quyết định, Giấy báo tử...).';
COMMENT ON COLUMN public_security.citizen_status.certificate_id IS 'ID giấy chứng nhận liên quan từ nguồn khác (vd: death_certificate_id của BTP).';
COMMENT ON COLUMN public_security.citizen_status.is_current IS 'TRUE nếu đây là bản ghi trạng thái mới nhất và đang có hiệu lực.';
COMMENT ON COLUMN public_security.citizen_status.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Dùng cho khóa phân vùng cấp 1.';
COMMENT ON COLUMN public_security.citizen_status.province_id IS 'ID Tỉnh/Thành phố - Dùng cho khóa phân vùng cấp 2.';
COMMENT ON COLUMN public_security.citizen_status.region_id IS 'ID Vùng/Miền (tham chiếu reference.regions).';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_citizen_status_citizen_id ON public_security.citizen_status(citizen_id);
CREATE INDEX IF NOT EXISTS idx_citizen_status_status_type ON public_security.citizen_status(status_type);
CREATE INDEX IF NOT EXISTS idx_citizen_status_status_date ON public_security.citizen_status(status_date);
CREATE INDEX IF NOT EXISTS idx_citizen_status_doc_num ON public_security.citizen_status(document_number) WHERE document_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_citizen_status_is_current ON public_security.citizen_status(is_current); -- Quan trọng để lấy trạng thái hiện tại

-- TODO (Những phần cần hoàn thiện ở các file/logic khác):
-- 1. Triggers/Logic cập nhật `updated_at` (ví dụ: `common/triggers/timestamp_triggers.sql`).
-- 2. Triggers/Logic cập nhật các cột phân vùng (`geographical_region`, `province_id`, `region_id`) dựa trên thông tin công dân (vd: địa chỉ thường trú).
-- 3. Triggers/Logic tự động cập nhật `is_current = FALSE` cho các bản ghi cũ khi có bản ghi mới `is_current = TRUE` cho cùng `citizen_id`.
-- 4. Triggers/Logic (hoặc App BCA) tự động cập nhật `public_security.citizen.death_status` khi có thay đổi quan trọng ở bảng này.
-- 5. Triggers/Logic ghi nhật ký audit (ví dụ: `common/triggers/audit_triggers.sql`).
-- 6. Partitioning Setup: Script `partitioning/execute_setup.sql` sẽ tạo các partition con thực tế theo `province_id` bên trong các partition `geographical_region`.
-- 7. Views: Cân nhắc tạo view `vw_current_citizen_status` chỉ hiển thị bản ghi `is_current = TRUE` cho mỗi công dân để đơn giản hóa truy vấn trạng thái hiện tại.
-- 8. Inter-Service Communication: Logic để App BCA nhận thông tin khai tử từ App BTP (qua API/event) để tạo/cập nhật bản ghi trong bảng này.

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.citizen_status.'
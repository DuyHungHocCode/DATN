-- File: ministry_of_public_security/schemas/public_security/identification_card.sql
-- Description: Tạo bảng identification_card (CCCD/CMND) trong schema public_security.
-- Version: 3.0 (Revised for Microservices)
-- =============================================================================

\echo '----------------------------------------------------------------------------'
\echo 'Tạo bảng identification_card cho CSDL Bộ Công An (ministry_of_public_security)...'
-- Kết nối đến đúng database
\connect ministry_of_public_security

BEGIN;

-- Drop table if exists để đảm bảo tạo mới sạch sẽ
DROP TABLE IF EXISTS public_security.identification_card CASCADE;

-- Tạo bảng identification_card với chiến lược phân vùng 2 cấp:
-- Cấp 1: LIST theo geographical_region (Miền: Bắc, Trung, Nam)
-- Cấp 2: LIST theo province_id (Tỉnh/Thành phố)
-- (Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql)
CREATE TABLE public_security.identification_card (
    card_id BIGSERIAL NOT NULL,                         -- ID tự tăng của thẻ (dùng BIGSERIAL cho lượng lớn thẻ)
    citizen_id VARCHAR(12) NOT NULL,                    -- Số CCCD/Định danh của công dân (FK nội bộ đến public_security.citizen)
    card_number VARCHAR(12) NOT NULL,                   -- Số thẻ CCCD/CMND (Phải là duy nhất toàn quốc)
    issue_date DATE NOT NULL,                           -- Ngày cấp
    expiry_date DATE,                                   -- Ngày hết hạn (NULL nếu là CMND cũ không có hạn)
    issuing_authority_id INTEGER,                       -- Cơ quan cấp (FK đến reference.authorities)
    card_type card_type NOT NULL,                       -- Loại thẻ (ENUM: CMND 9 số, CMND 12 số, CCCD, CCCD gắn chip)

    chip_serial_number VARCHAR(50),                     -- Số serial của chip (chỉ cho CCCD gắn chip)
    card_status card_status NOT NULL DEFAULT 'Đang sử dụng', -- Trạng thái thẻ (ENUM)
    previous_card_number VARCHAR(12),                   -- Số thẻ cũ (nếu là cấp đổi)
    notes TEXT,                                         -- Ghi chú thêm

    -- Thông tin hành chính phục vụ phân vùng và truy vấn (Lấy từ thông tin công dân hoặc nơi cấp)
    region_id SMALLINT,                                 -- Vùng/Miền (FK reference.regions, dùng cho query)
    province_id INTEGER NOT NULL,                       -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    geographical_region VARCHAR(20) NOT NULL,           -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),                             -- Người dùng hệ thống tạo bản ghi
    updated_by VARCHAR(50),                             -- Người dùng hệ thống cập nhật lần cuối

    -- Ràng buộc Khóa chính (Bao gồm các cột phân vùng để tối ưu)
    CONSTRAINT pk_identification_card PRIMARY KEY (card_id, geographical_region, province_id),

    -- Ràng buộc Duy nhất
    -- QUAN TRỌNG: Ràng buộc UNIQUE toàn cục trên bảng phân vùng có thể ảnh hưởng hiệu năng.
    -- Cần kiểm thử kỹ lưỡng trong môi trường thực tế.
    CONSTRAINT uq_identification_card_number UNIQUE (card_number),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu nội bộ DB BCA hoặc bảng reference cục bộ)
    -- Lưu ý: FK đến bảng citizen (đã phân vùng) cần kiểm tra hoạt động chính xác.
    CONSTRAINT fk_identification_card_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Xóa thẻ nếu công dân bị xóa
    CONSTRAINT fk_identification_card_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_identification_card_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_identification_card_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_identification_card_dates CHECK (issue_date <= CURRENT_DATE AND (expiry_date IS NULL OR expiry_date >= issue_date)), -- Ngày cấp <= hiện tại, Ngày hết hạn >= Ngày cấp
    CONSTRAINT ck_card_number_format CHECK ( -- Kiểm tra định dạng số thẻ dựa trên loại thẻ
            (card_type = 'CMND 9 số' AND card_number ~ '^[0-9]{9}$') OR
            (card_type = 'CMND 12 số' AND card_number ~ '^[0-9]{12}$') OR
            (card_type IN ('CCCD', 'CCCD gắn chip') AND card_number ~ '^[0-9]{12}$')
        ),
    CONSTRAINT ck_chip_serial_required CHECK ( -- Yêu cầu serial chip nếu là CCCD gắn chip
            (card_type = 'CCCD gắn chip' AND chip_serial_number IS NOT NULL AND chip_serial_number <> '') OR
            (card_type <> 'CCCD gắn chip')
        ),
    CONSTRAINT ck_identification_card_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán (nếu region_id có)
            (region_id IS NULL) OR
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        ),
    CONSTRAINT ck_identification_card_geo_region CHECK (geographical_region IN ('Bắc', 'Trung', 'Nam')) -- Đảm bảo cột phân vùng hợp lệ

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Các partition con cấp 2 (theo Tỉnh) sẽ được tạo bởi partitioning/execute_setup.sql

COMMENT ON TABLE public_security.identification_card IS 'Lưu trữ thông tin về Chứng minh nhân dân (CMND) và Căn cước công dân (CCCD) của công dân.';
COMMENT ON COLUMN public_security.identification_card.card_id IS 'ID tự tăng duy nhất của bản ghi thẻ.';
COMMENT ON COLUMN public_security.identification_card.citizen_id IS 'Số định danh cá nhân của công dân sở hữu thẻ.';
COMMENT ON COLUMN public_security.identification_card.card_number IS 'Số thẻ CMND/CCCD (duy nhất toàn quốc).';
COMMENT ON COLUMN public_security.identification_card.issue_date IS 'Ngày cấp thẻ.';
COMMENT ON COLUMN public_security.identification_card.expiry_date IS 'Ngày hết hạn của thẻ (nếu có).';
COMMENT ON COLUMN public_security.identification_card.issuing_authority_id IS 'ID của cơ quan công an đã cấp thẻ.';
COMMENT ON COLUMN public_security.identification_card.card_type IS 'Loại thẻ (CMND 9 số, CMND 12 số, CCCD, CCCD gắn chip).';
COMMENT ON COLUMN public_security.identification_card.chip_serial_number IS 'Số serial của chip điện tử trên thẻ CCCD gắn chip.';
COMMENT ON COLUMN public_security.identification_card.card_status IS 'Trạng thái hiện tại của thẻ.';
COMMENT ON COLUMN public_security.identification_card.previous_card_number IS 'Số thẻ cũ trong trường hợp cấp đổi.';
COMMENT ON COLUMN public_security.identification_card.province_id IS 'ID Tỉnh/Thành phố (dùng cho phân vùng cấp 2).';
COMMENT ON COLUMN public_security.identification_card.geographical_region IS 'Vùng địa lý (Bắc, Trung, Nam) (dùng cho phân vùng cấp 1).';
COMMENT ON CONSTRAINT uq_identification_card_number ON public_security.identification_card IS 'Đảm bảo số thẻ là duy nhất toàn quốc. Cần kiểm tra hiệu năng với bảng phân vùng.';

-- Indexes
-- Index trên khóa chính và khóa unique đã được tạo tự động.
CREATE INDEX IF NOT EXISTS idx_identification_card_citizen_id ON public_security.identification_card(citizen_id); -- Quan trọng để tra cứu thẻ theo công dân
CREATE INDEX IF NOT EXISTS idx_identification_card_card_status ON public_security.identification_card(card_status); -- Tra cứu theo trạng thái
CREATE INDEX IF NOT EXISTS idx_identification_card_issue_date ON public_security.identification_card(issue_date); -- Tra cứu theo ngày cấp
CREATE INDEX IF NOT EXISTS idx_identification_card_expiry_date ON public_security.identification_card(expiry_date); -- Tra cứu theo ngày hết hạn
CREATE INDEX IF NOT EXISTS idx_identification_card_province_id ON public_security.identification_card(province_id); -- Hỗ trợ partition pruning cấp 2

-- Index unique đảm bảo mỗi công dân chỉ có 1 thẻ đang hoạt động ('Đang sử dụng')
-- QUAN TRỌNG: UNIQUE INDEX toàn cục trên bảng phân vùng cần kiểm thử kỹ lưỡng.
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_id_card_per_citizen ON public_security.identification_card (citizen_id) WHERE card_status = 'Đang sử dụng';
COMMENT ON INDEX public_security.uq_idx_active_id_card_per_citizen IS 'Đảm bảo mỗi công dân chỉ có tối đa 1 thẻ ở trạng thái "Đang sử dụng". Cần kiểm tra hiệu năng với bảng phân vùng.';

-- TODO (Logic/Trigger):
-- 1. Trigger (hoặc logic ứng dụng): Tự động cập nhật `updated_at`.
-- 2. Trigger (hoặc logic ứng dụng): Tự động cập nhật trạng thái thẻ cũ thành 'Đã thay thế' khi cấp thẻ mới cho cùng công dân.
-- 3. Trigger (hoặc logic ứng dụng): Tự động cập nhật geographical_region, province_id, region_id dựa trên thông tin công dân hoặc nơi cấp.
-- 4. Audit Trigger: Đã được định nghĩa riêng trong thư mục audit.

COMMIT;

\echo 'Bảng identification_card đã được tạo/cập nhật.'
\echo '----------------------------------------------------------------------------'
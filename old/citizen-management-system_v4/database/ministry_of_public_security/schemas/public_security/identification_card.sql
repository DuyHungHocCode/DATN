-- =============================================================================
-- File: ministry_of_public_security/schemas/public_security/identification_card.sql
-- Description: Tạo bảng identification_card (CCCD/CMND) trong schema public_security.
-- Version: 3.1 (Removed UNIQUE constraints incompatible with partitioning)
--
-- Dependencies:
-- - Script tạo schema 'public_security', 'reference'.
-- - Script tạo bảng 'public_security.citizen'.
-- - Script tạo bảng 'reference.authorities', 'reference.regions', 'reference.provinces', 'reference.districts'.
-- - Script tạo ENUM 'card_type', 'card_status'.
-- - Script setup phân vùng (sẽ tạo các partition con).
-- =============================================================================

\echo '--> Tạo bảng public_security.identification_card...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
-- \connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.identification_card CASCADE;

-- Tạo bảng identification_card với cấu trúc phân vùng
-- Phân vùng theo 3 cấp: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script partitioning/execute_setup.sql
CREATE TABLE public_security.identification_card (
    id_card_id BIGSERIAL NOT NULL,                       -- ID tự tăng của bản ghi thẻ (dùng BIGSERIAL)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân sở hữu thẻ (FK đến public_security.citizen)
    card_number VARCHAR(12) NOT NULL,                    -- Số thẻ CCCD/CMND. **UNIQUE constraint đã bị xóa do partitioning**
    card_type card_type NOT NULL,                        -- Loại thẻ (ENUM: CMND 9 số, CCCD...)
    issue_date DATE NOT NULL,                            -- Ngày cấp thẻ
    expiry_date DATE,                                    -- Ngày hết hạn (NULL nếu không có hạn)
    issuing_authority_id SMALLINT NOT NULL,              -- Cơ quan cấp thẻ (FK đến reference.authorities)
    issuing_place TEXT,                                  -- Nơi cấp thẻ (ghi dạng text)
    card_status card_status DEFAULT 'Đang sử dụng',      -- Trạng thái thẻ (ENUM: Đang sử dụng, Hết hạn...)
    previous_card_number VARCHAR(12),                    -- Số thẻ cũ (nếu cấp đổi)
    biometric_data BYTEA,                                -- Dữ liệu sinh trắc học (vân tay, ảnh...) - Cân nhắc lưu trữ và bảo mật
    chip_id VARCHAR(50),                                 -- ID của chip điện tử (nếu là CCCD gắn chip). **UNIQUE constraint đã bị xóa**
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Lấy theo công dân hoặc nơi cấp?) - Cần xác định rõ
    region_id SMALLINT NOT NULL,                         -- Vùng/Miền (FK reference.regions) - Dùng cho truy vấn
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INT NOT NULL,                            -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_identification_card PRIMARY KEY (id_card_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại (Chỉ tham chiếu đến bảng trong cùng database BCA)
    CONSTRAINT fk_identification_card_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE,
    CONSTRAINT fk_identification_card_authority FOREIGN KEY (issuing_authority_id) REFERENCES reference.authorities(authority_id),
    CONSTRAINT fk_identification_card_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_identification_card_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    CONSTRAINT fk_identification_card_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_identification_card_dates CHECK (issue_date <= CURRENT_DATE AND (expiry_date IS NULL OR expiry_date > issue_date)),
    CONSTRAINT ck_identification_card_number_format CHECK (card_number ~ '^[0-9]{9}$' OR card_number ~ '^[0-9]{12}$'), -- Format CMND/CCCD
    CONSTRAINT ck_identification_card_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

    -- **ĐÃ XÓA:** Ràng buộc UNIQUE trên card_number do không tương thích với partitioning.
    -- Việc đảm bảo tính duy nhất cho card_number cần được xử lý ở tầng ứng dụng hoặc trigger.
    -- CONSTRAINT uq_identification_card_number UNIQUE (card_number)

    -- **ĐÃ XÓA:** Ràng buộc UNIQUE trên chip_id (nếu có). Cần xử lý unique ở tầng ứng dụng/trigger nếu cần.
    -- CONSTRAINT uq_identification_card_chip_id UNIQUE (chip_id) WHERE chip_id IS NOT NULL

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 (Miền)
-- Phân vùng cấp 2 (Tỉnh) và cấp 3 (Huyện) sẽ được tạo bởi script partitioning/execute_setup.sql

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE public_security.identification_card IS 'Lưu trữ thông tin về các thẻ Căn cước công dân (CCCD) / Chứng minh nhân dân (CMND).';
COMMENT ON COLUMN public_security.identification_card.id_card_id IS 'ID tự tăng duy nhất của bản ghi thẻ.';
COMMENT ON COLUMN public_security.identification_card.citizen_id IS 'ID công dân sở hữu thẻ.';
COMMENT ON COLUMN public_security.identification_card.card_number IS 'Số thẻ CCCD/CMND (Cần kiểm tra unique ở tầng ứng dụng/trigger).';
COMMENT ON COLUMN public_security.identification_card.card_type IS 'Loại thẻ (ENUM card_type).';
COMMENT ON COLUMN public_security.identification_card.issue_date IS 'Ngày cấp thẻ.';
COMMENT ON COLUMN public_security.identification_card.expiry_date IS 'Ngày hết hạn thẻ (nếu có).';
COMMENT ON COLUMN public_security.identification_card.issuing_authority_id IS 'Cơ quan cấp thẻ.';
COMMENT ON COLUMN public_security.identification_card.card_status IS 'Trạng thái hiện tại của thẻ (ENUM card_status).';
COMMENT ON COLUMN public_security.identification_card.chip_id IS 'ID của chip điện tử (nếu là CCCD gắn chip, cần kiểm tra unique nếu cần).';
COMMENT ON COLUMN public_security.identification_card.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1.';
COMMENT ON COLUMN public_security.identification_card.province_id IS 'Tỉnh/Thành phố - Cột phân vùng cấp 2.';
COMMENT ON COLUMN public_security.identification_card.district_id IS 'Quận/Huyện - Cột phân vùng cấp 3.';


-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
CREATE INDEX IF NOT EXISTS idx_identification_card_citizen_id ON public_security.identification_card(citizen_id);
-- Tạo index thường (không unique) cho card_number để hỗ trợ kiểm tra unique ở tầng ứng dụng/trigger
CREATE INDEX IF NOT EXISTS idx_identification_card_number ON public_security.identification_card(card_number);
CREATE INDEX IF NOT EXISTS idx_identification_card_type ON public_security.identification_card(card_type);
CREATE INDEX IF NOT EXISTS idx_identification_card_status ON public_security.identification_card(card_status);
CREATE INDEX IF NOT EXISTS idx_identification_card_issue_date ON public_security.identification_card(issue_date);
CREATE INDEX IF NOT EXISTS idx_identification_card_expiry_date ON public_security.identification_card(expiry_date);
CREATE INDEX IF NOT EXISTS idx_identification_card_authority_id ON public_security.identification_card(issuing_authority_id);
CREATE INDEX IF NOT EXISTS idx_identification_card_chip_id ON public_security.identification_card(chip_id) WHERE chip_id IS NOT NULL; -- Index cho chip_id (unique đã bị xóa)
-- Index trên các cột phân vùng (province_id, district_id) đã có trong PK

-- **ĐÃ XÓA:** Index unique đảm bảo mỗi công dân chỉ có 1 thẻ active tại một thời điểm.
-- Logic này cần được xử lý ở tầng ứng dụng (App BCA).
-- CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_active_id_card_per_citizen
--     ON public_security.identification_card (citizen_id)
--     WHERE card_status = 'Đang sử dụng';

COMMIT;

\echo '-> Hoàn thành tạo bảng public_security.identification_card.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partitioning: Chạy script `ministry_of_public_security/partitioning/execute_setup.sql` để tạo các partition con theo tỉnh và huyện.
-- 2. Indexes: Script partitioning cũng sẽ tạo các index cần thiết cho từng partition con.
-- 3. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at`.
--    - Tạo trigger ghi nhật ký audit.
--    - Tạo trigger cập nhật các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `citizen_id` hoặc `issuing_authority_id`.
--    - **QUAN TRỌNG:** Tạo trigger hoặc xây dựng logic tầng ứng dụng (App BCA) để kiểm tra và đảm bảo tính duy nhất (uniqueness) cho cột `card_number` trên toàn bộ bảng.
--    - **QUAN TRỌNG:** Xây dựng logic tầng ứng dụng (App BCA) để đảm bảo mỗi công dân chỉ có một thẻ `card_status = 'Đang sử dụng'` tại một thời điểm và cập nhật trạng thái thẻ cũ thành 'Đã thay thế' khi cấp thẻ mới.
-- 4. Data Loading: Nạp dữ liệu thẻ ban đầu (nếu có).
-- 5. Permissions: Cấp quyền phù hợp trên bảng này.
-- 6. Constraints Verification: Kiểm tra lại ràng buộc UNIQUE trên `chip_id` nếu cột này thực sự cần là unique toàn cục và không rỗng (hiện tại đã xóa).

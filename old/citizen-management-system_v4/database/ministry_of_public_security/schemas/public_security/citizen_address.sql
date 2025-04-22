-- File: ministry_of_public_security/schemas/public_security/citizen_address.sql
-- Description: Tạo bảng citizen_address (Liên kết Công dân - Địa chỉ) trong schema public_security.
--              Bảng này liên kết công dân với các địa chỉ (thường trú, tạm trú...) theo thời gian.
-- Version: 3.0 (Adapted for Microservices Structure)
-- =============================================================================

\echo '--- Tạo bảng public_security.citizen_address ---'
\connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS public_security.citizen_address CASCADE;

-- Tạo bảng citizen_address với partitioning
-- Phân vùng theo 3 cấp giống citizen/address: Miền (LIST) -> Tỉnh (LIST) -> Quận/Huyện (LIST)
-- Việc tạo các partition con cụ thể được thực hiện bởi script trong thư mục partitioning.
CREATE TABLE public_security.citizen_address (
    citizen_address_id BIGSERIAL NOT NULL,                 -- ID tự tăng của liên kết (dùng BIGSERIAL vì có thể nhiều)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân liên quan (FK đến public_security.citizen)
    address_id INTEGER NOT NULL,                           -- Địa chỉ liên quan (FK đến public_security.address)
    address_type address_type NOT NULL,                  -- Loại địa chỉ liên kết (ENUM: Thường trú, Tạm trú...)
    from_date DATE NOT NULL,                             -- Ngày bắt đầu sử dụng/liên kết với địa chỉ này
    to_date DATE,                                        -- Ngày kết thúc sử dụng (NULL = hiện tại vẫn dùng)
    is_primary BOOLEAN DEFAULT FALSE,                    -- Có phải địa chỉ chính cho loại địa chỉ này không? (vd: chỉ có 1 thường trú chính)
    status BOOLEAN DEFAULT TRUE,                         -- Trạng thái liên kết (TRUE = Active/Còn hiệu lực)
    registration_document_no VARCHAR(50),                -- Số giấy tờ đăng ký liên quan (vd: số sổ tạm trú, quyết định nhập HK)
    registration_date DATE,                              -- Ngày đăng ký trên giấy tờ
    issuing_authority_id INTEGER REFERENCES reference.authorities(authority_id), -- Cơ quan cấp giấy tờ (FK đến reference.authorities)
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh địa chỉ này với công dân
    verification_date DATE,                              -- Ngày xác minh
    verified_by VARCHAR(100),                            -- Người/Cán bộ xác minh
    notes TEXT,                                          -- Ghi chú thêm

    -- Thông tin hành chính & Phân vùng (Lấy theo address_id hoặc citizen_id)
    -- Các cột này rất quan trọng cho việc định tuyến dữ liệu vào đúng partition.
    -- Cần có trigger hoặc logic ứng dụng để đảm bảo chúng được điền đúng dựa trên address_id hoặc citizen_id.
    region_id SMALLINT NOT NULL REFERENCES reference.regions(region_id),             -- Vùng/Miền (FK reference.regions)
    province_id INTEGER NOT NULL REFERENCES reference.provinces(province_id),        -- Tỉnh/Thành phố (FK reference.provinces, Cột phân vùng cấp 2)
    district_id INTEGER NOT NULL REFERENCES reference.districts(district_id),        -- Quận/Huyện (FK reference.districts, Cột phân vùng cấp 3)
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý (Bắc, Trung, Nam) - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng để đảm bảo tính duy nhất và hiệu quả)
    CONSTRAINT pk_citizen_address PRIMARY KEY (citizen_address_id, geographical_region, province_id, district_id),

    -- Ràng buộc Khóa ngoại (Nội bộ database BCA)
    -- Lưu ý: Tham chiếu đến các bảng đã phân vùng (citizen, address) cần được kiểm thử kỹ lưỡng.
    CONSTRAINT fk_citizen_address_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Nếu xóa citizen thì xóa liên kết địa chỉ
    CONSTRAINT fk_citizen_address_address FOREIGN KEY (address_id) REFERENCES public_security.address(address_id) ON DELETE RESTRICT, -- Không cho xóa địa chỉ nếu đang có người liên kết

    -- Ràng buộc Kiểm tra (CHECK constraints)
    CONSTRAINT ck_citizen_address_dates CHECK (
            from_date <= CURRENT_DATE AND
            (to_date IS NULL OR to_date >= from_date) AND -- Ngày kết thúc phải sau hoặc bằng ngày bắt đầu
            (registration_date IS NULL OR registration_date <= CURRENT_DATE) AND
            (verification_date IS NULL OR verification_date <= CURRENT_DATE)
        ),
    CONSTRAINT ck_citizen_address_region_consistency CHECK ( -- Đảm bảo region_id và geographical_region nhất quán
            (region_id = 1 AND geographical_region = 'Bắc') OR
            (region_id = 2 AND geographical_region = 'Trung') OR
            (region_id = 3 AND geographical_region = 'Nam')
        )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 theo miền địa lý

COMMENT ON TABLE public_security.citizen_address IS 'Bảng liên kết giữa công dân và địa chỉ theo thời gian, loại địa chỉ.';
COMMENT ON COLUMN public_security.citizen_address.citizen_id IS 'ID của công dân.';
COMMENT ON COLUMN public_security.citizen_address.address_id IS 'ID của địa chỉ.';
COMMENT ON COLUMN public_security.citizen_address.address_type IS 'Loại địa chỉ liên kết (Thường trú, Tạm trú...).';
COMMENT ON COLUMN public_security.citizen_address.from_date IS 'Ngày bắt đầu liên kết/cư trú tại địa chỉ.';
COMMENT ON COLUMN public_security.citizen_address.to_date IS 'Ngày kết thúc liên kết/cư trú (NULL nếu còn hiệu lực).';
COMMENT ON COLUMN public_security.citizen_address.is_primary IS 'Đánh dấu địa chỉ chính cho loại địa chỉ tương ứng.';
COMMENT ON COLUMN public_security.citizen_address.status IS 'Trạng thái hiện tại của liên kết này (TRUE=Active).';
COMMENT ON COLUMN public_security.citizen_address.geographical_region IS 'Cột phân vùng cấp 1: Miền địa lý (Bắc, Trung, Nam).';
COMMENT ON COLUMN public_security.citizen_address.province_id IS 'Cột phân vùng cấp 2: ID Tỉnh/Thành phố.';
COMMENT ON COLUMN public_security.citizen_address.district_id IS 'Cột phân vùng cấp 3: ID Quận/Huyện.';

-- Indexes
-- Index trên các khóa ngoại và các cột thường dùng để lọc/sắp xếp
CREATE INDEX IF NOT EXISTS idx_citizen_address_citizen_id ON public_security.citizen_address(citizen_id);
CREATE INDEX IF NOT EXISTS idx_citizen_address_address_id ON public_security.citizen_address(address_id);
CREATE INDEX IF NOT EXISTS idx_citizen_address_address_type ON public_security.citizen_address(address_type);
CREATE INDEX IF NOT EXISTS idx_citizen_address_from_date ON public_security.citizen_address(from_date);
CREATE INDEX IF NOT EXISTS idx_citizen_address_to_date ON public_security.citizen_address(to_date);
CREATE INDEX IF NOT EXISTS idx_citizen_address_status ON public_security.citizen_address(status);
-- district_id, province_id, geographical_region đã có trong khóa chính và dùng cho partitioning.

-- Chỉ mục unique đảm bảo mỗi công dân chỉ có một địa chỉ chính (is_primary=TRUE)
-- cho mỗi loại địa chỉ (address_type) đang hoạt động (status=TRUE).
-- Lưu ý: UNIQUE index trên bảng phân vùng cần được kiểm tra kỹ lưỡng.
CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_citizen_address_primary
    ON public_security.citizen_address(citizen_id, address_type)
    WHERE is_primary = TRUE AND status = TRUE;

-- TODO (Cần hoàn thiện trong các file/bước khác):
-- 1. Triggers:
--    - Trigger cập nhật `updated_at`.
--    - Trigger để tự động điền các cột phân vùng (`geographical_region`, `province_id`, `district_id`, `region_id`) dựa trên `address_id` hoặc `citizen_id` khi INSERT/UPDATE. Đây là việc **quan trọng** để đảm bảo dữ liệu vào đúng partition.
--    - Trigger hoặc logic ứng dụng để quản lý cờ `is_primary` (ví dụ: khi set 1 địa chỉ thường trú là primary thì các địa chỉ thường trú khác của cùng công dân phải thành `is_primary = FALSE`).
--    - Trigger ghi nhật ký audit (`audit_triggers.sql`).
-- 2. Partitioning Setup (`partitioning/execute_setup.sql`): Script này sẽ tạo các partition con thực tế theo tỉnh và huyện.
-- 3. Testing: Kiểm tra kỹ lưỡng hoạt động của FK và Unique Index trên bảng đã phân vùng này.

COMMIT;

\echo '--- Hoàn thành tạo bảng public_security.citizen_address ---'
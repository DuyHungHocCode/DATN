-- File: ministry_of_public_security/schemas/public_security/citizen_movement.sql
-- Description: Tạo bảng citizen_movement (Di biến động dân cư) trong schema public_security.
--              Bảng này theo dõi việc di chuyển trong nước và quốc tế của công dân.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Schema reference đã tồn tại và có dữ liệu (nationalities, regions, provinces).
-- - Bảng public_security.citizen và public_security.address đã tồn tại (là bảng cha phân vùng).
-- - Enum movement_type đã được định nghĩa (trong 01_common/02_enum.sql).
-- - Script tạo partition con sẽ được thực thi sau (trong ministry_of_public_security/partitioning/execute_setup.sql).
-- =============================================================================

\echo '*** TẠO BẢNG public_security.citizen_movement ***'
\connect ministry_of_public_security;

-- Drop table if exists để đảm bảo tạo mới sạch sẽ
DROP TABLE IF EXISTS public_security.citizen_movement CASCADE;

-- Tạo bảng citizen_movement với cấu trúc phân vùng
-- Phân vùng theo 2 cấp: Miền địa lý (LIST) -> Tỉnh/Thành phố (LIST)
-- Cột phân vùng cấp 1: geographical_region ('Bắc', 'Trung', 'Nam')
-- Cột phân vùng cấp 2: province_id (ID tỉnh/thành phố)
-- Khóa chính sẽ bao gồm cả các cột phân vùng này.
CREATE TABLE public_security.citizen_movement (
    movement_id BIGSERIAL NOT NULL,                      -- ID tự tăng của bản ghi di chuyển (dùng BIGSERIAL cho bảng lớn)
    citizen_id VARCHAR(12) NOT NULL,                     -- Công dân di chuyển (FK logic tới public_security.citizen)
    movement_type movement_type NOT NULL,                -- Loại di chuyển (ENUM: Trong nước, Xuất cảnh, Nhập cảnh, Tái nhập cảnh)

    -- Thông tin địa điểm đi/đến
    from_address_id INT,                                 -- ID địa chỉ đi (FK logic tới public_security.address) (NULL nếu xuất cảnh từ nước ngoài)
    to_address_id INT,                                   -- ID địa chỉ đến (FK logic tới public_security.address) (NULL nếu nhập cảnh vào nước ngoài)
    from_country_id SMALLINT,                            -- ID Quốc gia đi (FK reference.nationalities) (Chỉ dùng khi xuất cảnh)
    to_country_id SMALLINT,                              -- ID Quốc gia đến (FK reference.nationalities) (Chỉ dùng khi nhập cảnh)

    -- Thông tin thời gian
    departure_date DATE NOT NULL,                        -- Ngày khởi hành/rời đi
    arrival_date DATE,                                   -- Ngày đến nơi (NULL nếu đang di chuyển hoặc không xác định)

    -- Thông tin khác
    purpose VARCHAR(255),                                -- Mục đích di chuyển (du lịch, công tác, định cư...)
    document_no VARCHAR(50),                             -- Số giấy tờ liên quan (hộ chiếu, visa...)
    document_type VARCHAR(50),                           -- Loại giấy tờ
    document_issue_date DATE,                            -- Ngày cấp giấy tờ
    document_expiry_date DATE,                           -- Ngày hết hạn giấy tờ
    carrier VARCHAR(100),                                -- Hãng vận chuyển (Vietnam Airlines, Vietjet Air, Tàu hỏa, Xe khách...)
    border_checkpoint VARCHAR(150),                      -- Cửa khẩu (Nội Bài, Tân Sơn Nhất, Mộc Bài...) (cho di chuyển quốc tế)
    description TEXT,                                    -- Mô tả chi tiết thêm
    status VARCHAR(50) DEFAULT 'Hoạt động' NOT NULL,     -- Trạng thái bản ghi (ENUM hoặc VARCHAR: Hoạt động, Hoàn thành, Đã hủy)

    -- Thông tin hành chính & Phân vùng
    -- province_id và geographical_region được dùng làm khóa phân vùng.
    -- Các cột này nên được cập nhật tự động (qua trigger hoặc logic ứng dụng)
    -- dựa trên địa chỉ đi/đến hoặc nơi đăng ký của công dân.
    source_region_id SMALLINT,                           -- ID Vùng/Miền đi (FK reference.regions) (lấy từ from_address_id hoặc tỉnh đi)
    target_region_id SMALLINT,                           -- ID Vùng/Miền đến (FK reference.regions) (lấy từ to_address_id hoặc tỉnh đến)
    province_id INT NOT NULL,                            -- Tỉnh/Thành phố liên quan chính (Cột phân vùng cấp 2) - Có thể là tỉnh đi, tỉnh đến, hoặc tỉnh đăng ký của công dân
    geographical_region VARCHAR(20) NOT NULL,            -- Tên vùng địa lý ('Bắc', 'Trung', 'Nam') - Cột phân vùng cấp 1

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),

    -- Ràng buộc Khóa chính (bao gồm các cột phân vùng)
    CONSTRAINT pk_citizen_movement PRIMARY KEY (movement_id, geographical_region, province_id),

    -- Ràng buộc Khóa ngoại (Intra-DB hoặc đến Reference)
    -- Lưu ý: FK đến bảng đã phân vùng (citizen, address) cần được kiểm tra kỹ lưỡng trong môi trường thực tế.
    CONSTRAINT fk_citizen_movement_citizen FOREIGN KEY (citizen_id) REFERENCES public_security.citizen(citizen_id) ON DELETE CASCADE, -- Xóa di biến động nếu công dân bị xóa
    CONSTRAINT fk_citizen_movement_from_addr FOREIGN KEY (from_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL, -- Nếu địa chỉ đi bị xóa, chỉ set NULL
    CONSTRAINT fk_citizen_movement_to_addr FOREIGN KEY (to_address_id) REFERENCES public_security.address(address_id) ON DELETE SET NULL, -- Nếu địa chỉ đến bị xóa, chỉ set NULL
    CONSTRAINT fk_citizen_movement_from_ctry FOREIGN KEY (from_country_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_citizen_movement_to_ctry FOREIGN KEY (to_country_id) REFERENCES reference.nationalities(nationality_id),
    CONSTRAINT fk_citizen_movement_src_region FOREIGN KEY (source_region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_movement_tgt_region FOREIGN KEY (target_region_id) REFERENCES reference.regions(region_id),
    CONSTRAINT fk_citizen_movement_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),

    -- Ràng buộc Kiểm tra (CHECK)
    CONSTRAINT ck_citizen_movement_dates CHECK (
        departure_date <= CURRENT_DATE AND -- Ngày đi không thể ở tương lai
        (arrival_date IS NULL OR arrival_date >= departure_date) AND -- Ngày đến phải sau hoặc bằng ngày đi
        (document_issue_date IS NULL OR document_issue_date <= departure_date) AND -- Ngày cấp giấy tờ phải trước hoặc bằng ngày đi
        (document_expiry_date IS NULL OR document_expiry_date >= document_issue_date) -- Ngày hết hạn giấy tờ phải sau hoặc bằng ngày cấp
    ),
    CONSTRAINT ck_citizen_movement_status CHECK (status IN ('Hoạt động', 'Hoàn thành', 'Đã hủy')), -- Giới hạn trạng thái hợp lệ
    CONSTRAINT ck_citizen_movement_international CHECK ( -- Logic cho di chuyển quốc tế
        (movement_type IN ('Xuất cảnh', 'Tái nhập cảnh') AND to_country_id IS NOT NULL AND border_checkpoint IS NOT NULL) OR
        (movement_type = 'Nhập cảnh' AND from_country_id IS NOT NULL AND border_checkpoint IS NOT NULL) OR
        (movement_type = 'Trong nước') -- Không yêu cầu country/checkpoint cho di chuyển trong nước
    ),
    CONSTRAINT ck_citizen_movement_address_country CHECK ( -- Đảm bảo không có cả address và country cho cùng một chiều di chuyển
        NOT (movement_type = 'Xuất cảnh' AND from_address_id IS NOT NULL) AND -- Xuất cảnh thì phải có from_country_id thay vì from_address_id
        NOT (movement_type = 'Nhập cảnh' AND to_address_id IS NOT NULL)       -- Nhập cảnh thì phải có to_country_id thay vì to_address_id
        -- Logic này có thể cần điều chỉnh tùy theo quy ước nhập liệu chi tiết
    ),
     CONSTRAINT ck_citizen_movement_geo_region CHECK ( -- Đảm bảo cột phân vùng cấp 1 hợp lệ
            geographical_region IN ('Bắc', 'Trung', 'Nam')
     )

) PARTITION BY LIST (geographical_region); -- Khai báo phân vùng cấp 1 theo Miền địa lý

-- Phân vùng cấp 2 theo Tỉnh/Thành phố sẽ được tạo tự động bởi script trong partitioning/

COMMENT ON TABLE public_security.citizen_movement IS 'Lưu trữ thông tin về các lần di biến động (trong nước, xuất nhập cảnh) của công dân.';
COMMENT ON COLUMN public_security.citizen_movement.movement_id IS 'ID duy nhất của bản ghi di biến động.';
COMMENT ON COLUMN public_security.citizen_movement.citizen_id IS 'Số định danh của công dân thực hiện di chuyển.';
COMMENT ON COLUMN public_security.citizen_movement.movement_type IS 'Loại hình di chuyển.';
COMMENT ON COLUMN public_security.citizen_movement.from_address_id IS 'ID địa chỉ nơi đi (nếu trong nước).';
COMMENT ON COLUMN public_security.citizen_movement.to_address_id IS 'ID địa chỉ nơi đến (nếu trong nước).';
COMMENT ON COLUMN public_security.citizen_movement.from_country_id IS 'ID quốc gia đi (nếu nhập cảnh).';
COMMENT ON COLUMN public_security.citizen_movement.to_country_id IS 'ID quốc gia đến (nếu xuất cảnh/tái nhập cảnh).';
COMMENT ON COLUMN public_security.citizen_movement.border_checkpoint IS 'Cửa khẩu thực hiện xuất/nhập cảnh.';
COMMENT ON COLUMN public_security.citizen_movement.province_id IS 'ID Tỉnh/Thành phố liên quan chính (dùng cho phân vùng cấp 2).';
COMMENT ON COLUMN public_security.citizen_movement.geographical_region IS 'Miền địa lý liên quan chính (Bắc, Trung, Nam - dùng cho phân vùng cấp 1).';


-- Indexes (sẽ được tạo trên các partition con bởi script partitioning/execute_setup.sql)
-- CREATE INDEX IF NOT EXISTS idx_citizen_movement_citizen_id ON public_security.citizen_movement(citizen_id);
-- CREATE INDEX IF NOT EXISTS idx_citizen_movement_type ON public_security.citizen_movement(movement_type);
-- CREATE INDEX IF NOT EXISTS idx_citizen_movement_dep_date ON public_security.citizen_movement(departure_date);
-- CREATE INDEX IF NOT EXISTS idx_citizen_movement_arr_date ON public_security.citizen_movement(arrival_date);
-- CREATE INDEX IF NOT EXISTS idx_citizen_movement_doc_no ON public_security.citizen_movement(document_no) WHERE document_no IS NOT NULL;
-- CREATE INDEX IF NOT EXISTS idx_citizen_movement_status ON public_security.citizen_movement(status);
-- CREATE INDEX IF NOT EXISTS idx_citizen_movement_province ON public_security.citizen_movement(province_id); -- Hỗ trợ partition pruning


-- TODO (Những việc cần làm sau khi tạo bảng):
-- 1. Triggers:
--    - Tạo trigger tự động cập nhật `updated_at`.
--    - Tạo trigger tự động cập nhật các cột phân vùng `geographical_region`, `province_id` dựa trên `from_address_id`, `to_address_id`, hoặc thông tin khác.
--    - Tạo trigger tự động cập nhật `status`='Hoàn thành' khi `arrival_date` được điền.
--    - Tạo trigger kiểm tra logic nghiệp vụ phức tạp hơn (nếu cần).
--    - Gắn trigger ghi nhật ký audit (`audit.if_modified_func`).
-- 2. Partitioning:
--    - Chạy script `ministry_of_public_security/partitioning/execute_setup.sql` để tạo các partition con thực tế theo `province_id` cho từng miền.
--    - Script đó cũng sẽ tạo các indexes cần thiết trên từng partition con.
-- 3. Foreign Keys:
--    - Xác nhận các khóa ngoại đến bảng `citizen` và `address` (đã phân vùng) hoạt động chính xác.

\echo '-> Hoàn thành tạo bảng public_security.citizen_movement.'
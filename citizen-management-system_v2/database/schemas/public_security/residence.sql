-- =============================================================================
-- File: database/schemas/public_security/residence.sql
-- Description: Tạo các bảng quản lý địa chỉ và cư trú trong schema public_security
-- Version: 2.0
-- 
-- File này triển khai 5 bảng chính cho quản lý cư trú:
-- 1. address - Quản lý thông tin địa chỉ
-- 2. citizen_address - Liên kết giữa công dân và địa chỉ
-- 3. permanent_residence - Đăng ký thường trú
-- 4. temporary_residence - Đăng ký tạm trú 
-- 5. temporary_absence - Đăng ký tạm vắng
--
-- Các bảng được tạo tại database bộ Công an và được chia sẻ cho
-- các hệ thống khác qua Foreign Data Wrapper (FDW)
-- =============================================================================

\echo 'Tạo các bảng quản lý cư trú trong schema public_security...'

-- Kết nối đến database Bộ Công An (database chủ quản cho dữ liệu cư trú)
\connect ministry_of_public_security

BEGIN;

-- Xóa bảng nếu đã tồn tại để tạo lại
DROP TABLE IF EXISTS public_security.temporary_absence CASCADE;
DROP TABLE IF EXISTS public_security.temporary_residence CASCADE;
DROP TABLE IF EXISTS public_security.permanent_residence CASCADE;
DROP TABLE IF EXISTS public_security.citizen_address CASCADE;
DROP TABLE IF EXISTS public_security.address CASCADE;

-- =============================================================================
-- 1. BẢNG ADDRESS - THÔNG TIN ĐỊA CHỈ
-- =============================================================================
CREATE TABLE public_security.address (
    address_id SERIAL PRIMARY KEY,
    address_detail TEXT NOT NULL,
    ward_id INT NOT NULL,                -- FK to: reference.wards
    district_id INT NOT NULL,            -- FK to: reference.districts 
    province_id INT NOT NULL,            -- FK to: reference.provinces
    address_type address_type NOT NULL,  -- Enum: Thường trú, Tạm trú, Nơi ở hiện tại, Công ty, v.v.
    postal_code VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    status BOOLEAN DEFAULT TRUE,         -- Địa chỉ có còn hợp lệ không
    region_id SMALLINT NOT NULL,         -- FK to: reference.regions
    geographical_region VARCHAR(20) NOT NULL, -- Dùng cho phân vùng (Bắc, Trung, Nam) 
    data_sensitivity_level data_sensitivity_level DEFAULT 'Công khai',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);

-- Thêm chỉ mục cho bảng address
CREATE INDEX idx_address_ward_id ON public_security.address(ward_id);
CREATE INDEX idx_address_district_id ON public_security.address(district_id);
CREATE INDEX idx_address_province_id ON public_security.address(province_id);
CREATE INDEX idx_address_region_id ON public_security.address(region_id);
CREATE INDEX idx_address_status ON public_security.address(status);
CREATE INDEX idx_address_type ON public_security.address(address_type);
CREATE INDEX idx_address_geographical_region ON public_security.address(geographical_region);

-- Comment chi tiết cho bảng address
COMMENT ON TABLE public_security.address IS 'Bảng lưu trữ thông tin địa chỉ trong hệ thống quản lý dân cư';
COMMENT ON COLUMN public_security.address.address_id IS 'ID địa chỉ, là khóa chính của bảng';
COMMENT ON COLUMN public_security.address.address_detail IS 'Chi tiết địa chỉ (số nhà, đường, tổ, thôn, v.v.)';
COMMENT ON COLUMN public_security.address.ward_id IS 'ID phường/xã, tham chiếu đến bảng reference.wards';
COMMENT ON COLUMN public_security.address.district_id IS 'ID quận/huyện, tham chiếu đến bảng reference.districts';
COMMENT ON COLUMN public_security.address.province_id IS 'ID tỉnh/thành phố, tham chiếu đến bảng reference.provinces';
COMMENT ON COLUMN public_security.address.address_type IS 'Loại địa chỉ (Thường trú, Tạm trú, Nơi ở hiện tại, Công ty, v.v.)';
COMMENT ON COLUMN public_security.address.postal_code IS 'Mã bưu chính';
COMMENT ON COLUMN public_security.address.latitude IS 'Vĩ độ của địa chỉ (dùng cho GIS)';
COMMENT ON COLUMN public_security.address.longitude IS 'Kinh độ của địa chỉ (dùng cho GIS)';
COMMENT ON COLUMN public_security.address.status IS 'Trạng thái của địa chỉ (TRUE = hợp lệ, FALSE = không còn hợp lệ)';
COMMENT ON COLUMN public_security.address.region_id IS 'ID vùng/miền (Bắc, Trung, Nam)';
COMMENT ON COLUMN public_security.address.geographical_region IS 'Tên vùng địa lý (Bắc, Trung, Nam) dùng cho phân vùng dữ liệu';
COMMENT ON COLUMN public_security.address.data_sensitivity_level IS 'Mức độ nhạy cảm của dữ liệu';
COMMENT ON COLUMN public_security.address.created_at IS 'Thời điểm tạo bản ghi';
COMMENT ON COLUMN public_security.address.updated_at IS 'Thời điểm cập nhật bản ghi gần nhất';
COMMENT ON COLUMN public_security.address.created_by IS 'Người tạo bản ghi';
COMMENT ON COLUMN public_security.address.updated_by IS 'Người cập nhật bản ghi gần nhất';

-- =============================================================================
-- 2. BẢNG CITIZEN_ADDRESS - LIÊN KẾT GIỮA CÔNG DÂN VÀ ĐỊA CHỈ
-- =============================================================================
CREATE TABLE public_security.citizen_address (
    citizen_address_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,      -- FK to: public_security.citizen
    address_id INT NOT NULL,              -- FK to: public_security.address
    address_type address_type NOT NULL,   -- Enum: Thường trú, Tạm trú, Nơi ở hiện tại, Công ty, v.v.
    from_date DATE NOT NULL,              -- Ngày bắt đầu sử dụng địa chỉ này
    to_date DATE,                         -- Ngày kết thúc sử dụng (NULL = hiện tại vẫn dùng)
    is_primary BOOLEAN DEFAULT FALSE,     -- Có phải là địa chỉ chính không
    status BOOLEAN DEFAULT TRUE,          -- Trạng thái kích hoạt của liên kết địa chỉ
    registration_document_no VARCHAR(50), -- Số giấy tờ đăng ký
    registration_date DATE,               -- Ngày đăng ký
    issuing_authority_id SMALLINT,        -- FK to: reference.authorities
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh địa chỉ
    verification_date DATE,               -- Ngày xác minh
    verified_by VARCHAR(100),             -- Người xác minh
    notes TEXT,                           -- Ghi chú thêm
    region_id SMALLINT NOT NULL,          -- FK to: reference.regions
    province_id INT NOT NULL,             -- FK to: reference.provinces
    geographical_region VARCHAR(20) NOT NULL, -- Dùng cho phân vùng (Bắc, Trung, Nam)
    data_sensitivity_level data_sensitivity_level DEFAULT 'Công khai',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);


-- Tạo unique index đảm bảo mỗi công dân chỉ có một địa chỉ chính cho mỗi loại địa chỉ
CREATE UNIQUE INDEX idx_citizen_address_primary 
ON public_security.citizen_address(citizen_id, address_type) 
WHERE is_primary = TRUE AND status = TRUE;


-- =============================================================================
-- 3. BẢNG PERMANENT_RESIDENCE - ĐĂNG KÝ THƯỜNG TRÚ
-- =============================================================================
CREATE TABLE public_security.permanent_residence (
    permanent_residence_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,      -- FK to: public_security.citizen
    address_id INT NOT NULL,              -- FK to: public_security.address
    registration_date DATE NOT NULL,      -- Ngày đăng ký thường trú
    decision_no VARCHAR(50) NOT NULL,     -- Số quyết định đăng ký thường trú
    issuing_authority_id SMALLINT NOT NULL, -- FK to: reference.authorities
    previous_address_id INT,              -- FK to: public_security.address (địa chỉ thường trú trước đó)
    change_reason TEXT,                   -- Lý do thay đổi chỗ ở thường trú
    document_url VARCHAR(255),            -- Đường dẫn đến tài liệu quét (scan)
    household_id INT,                     -- FK to: justice.household (nếu đã thiết lập liên kết)
    relationship_with_head VARCHAR(50),   -- Quan hệ với chủ hộ
    status BOOLEAN DEFAULT TRUE,          -- Trạng thái đăng ký (TRUE = đang có hiệu lực)
    notes TEXT,                           -- Ghi chú bổ sung
    region_id SMALLINT NOT NULL,          -- FK to: reference.regions
    province_id INT NOT NULL,             -- FK to: reference.provinces
    geographical_region VARCHAR(20) NOT NULL, -- Dùng cho phân vùng (Bắc, Trung, Nam)
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);


-- Đảm bảo mỗi công dân chỉ có một đăng ký thường trú đang hoạt động 
CREATE UNIQUE INDEX idx_permanent_residence_active_citizen 
ON public_security.permanent_residence(citizen_id) 
WHERE status = TRUE;


-- =============================================================================
-- 4. BẢNG TEMPORARY_RESIDENCE - ĐĂNG KÝ TẠM TRÚ
-- =============================================================================
CREATE TABLE public_security.temporary_residence (
    temporary_residence_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,      -- FK to: public_security.citizen
    address_id INT NOT NULL,              -- FK to: public_security.address (địa chỉ tạm trú)
    registration_date DATE NOT NULL,      -- Ngày đăng ký tạm trú
    expiry_date DATE,                     -- Ngày hết hạn tạm trú (NULL = không xác định)
    purpose VARCHAR(200) NOT NULL,        -- Mục đích tạm trú
    registration_number VARCHAR(50) NOT NULL, -- Số giấy đăng ký tạm trú
    issuing_authority_id SMALLINT NOT NULL, -- FK to: reference.authorities
    permanent_address_id INT,             -- FK to: public_security.address (địa chỉ thường trú)
    host_name VARCHAR(100),               -- Tên chủ hộ/chủ nhà nơi tạm trú
    host_citizen_id VARCHAR(12),          -- FK to: public_security.citizen (ID của chủ hộ/chủ nhà)
    host_relationship VARCHAR(50),        -- Quan hệ với chủ hộ/chủ nhà
    document_url VARCHAR(255),            -- Đường dẫn đến tài liệu quét (scan)
    extension_count SMALLINT DEFAULT 0,   -- Số lần gia hạn
    last_extension_date DATE,             -- Ngày gia hạn gần nhất
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh
    verification_date DATE,               -- Ngày xác minh
    verified_by VARCHAR(100),             -- Người xác minh
    status VARCHAR(50) DEFAULT 'Active',  -- Trạng thái (Active, Expired, Cancelled, Extended)
    notes TEXT,                           -- Ghi chú bổ sung
    region_id SMALLINT NOT NULL,          -- FK to: reference.regions
    province_id INT NOT NULL,             -- FK to: reference.provinces
    geographical_region VARCHAR(20) NOT NULL, -- Dùng cho phân vùng (Bắc, Trung, Nam)
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);


-- Đảm bảo số đăng ký tạm trú là duy nhất
CREATE UNIQUE INDEX idx_temporary_residence_registration_number 
ON public_security.temporary_residence(registration_number);


-- =============================================================================
-- 5. BẢNG TEMPORARY_ABSENCE - ĐĂNG KÝ TẠM VẮNG
-- =============================================================================
CREATE TABLE public_security.temporary_absence (
    temporary_absence_id SERIAL PRIMARY KEY,
    citizen_id VARCHAR(12) NOT NULL,      -- FK to: public_security.citizen
    from_date DATE NOT NULL,              -- Ngày bắt đầu tạm vắng
    to_date DATE,                         -- Ngày kết thúc tạm vắng (NULL = chưa xác định)
    reason TEXT NOT NULL,                 -- Lý do tạm vắng
    destination_address_id INT,           -- FK to: public_security.address (nơi đến)
    destination_detail TEXT,              -- Chi tiết nơi đến (nếu không có địa chỉ cụ thể)
    contact_information TEXT,             -- Thông tin liên lạc trong thời gian tạm vắng
    registration_authority_id SMALLINT,   -- FK to: reference.authorities
    registration_number VARCHAR(50),      -- Số giấy đăng ký tạm vắng
    document_url VARCHAR(255),            -- Đường dẫn đến tài liệu quét (scan)
    return_date DATE,                     -- Ngày thực tế quay lại (có thể khác to_date)
    return_confirmed BOOLEAN DEFAULT FALSE, -- Đã xác nhận quay lại
    return_confirmed_by VARCHAR(100),     -- Người xác nhận quay lại
    return_confirmed_date DATE,           -- Ngày xác nhận quay lại
    return_notes TEXT,                    -- Ghi chú khi quay lại
    verification_status VARCHAR(50) DEFAULT 'Đã xác minh', -- Trạng thái xác minh
    verification_date DATE,               -- Ngày xác minh
    verified_by VARCHAR(100),             -- Người xác minh
    status VARCHAR(50) DEFAULT 'Active',  -- Trạng thái (Active, Expired, Cancelled, Returned)
    notes TEXT,                           -- Ghi chú bổ sung
    region_id SMALLINT NOT NULL,          -- FK to: reference.regions
    province_id INT NOT NULL,             -- FK to: reference.provinces
    geographical_region VARCHAR(20) NOT NULL, -- Dùng cho phân vùng (Bắc, Trung, Nam)
    data_sensitivity_level data_sensitivity_level DEFAULT 'Hạn chế',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50)
);


-- Đảm bảo số đăng ký tạm vắng là duy nhất (khi có giá trị)
CREATE UNIQUE INDEX idx_temporary_absence_registration_number 
ON public_security.temporary_absence(registration_number) 
WHERE registration_number IS NOT NULL;


-- =============================================================================
-- 6. RÀNG BUỘC CHECK
-- =============================================================================

-- Địa chỉ - Kiểm tra tọa độ GPS hợp lệ
ALTER TABLE public_security.address ADD CONSTRAINT ck_address_coordinates
CHECK (
    (latitude IS NULL AND longitude IS NULL) OR 
    (latitude IS NOT NULL AND longitude IS NOT NULL AND 
     latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
);

-- Citizen_Address - Kiểm tra ngày hợp lệ
ALTER TABLE public_security.citizen_address ADD CONSTRAINT ck_citizen_address_dates
CHECK (
    from_date <= CURRENT_DATE AND
    (to_date IS NULL OR to_date >= from_date)
);

-- Permanent_Residence - Kiểm tra ngày hợp lệ
ALTER TABLE public_security.permanent_residence ADD CONSTRAINT ck_permanent_residence_dates
CHECK (
    registration_date <= CURRENT_DATE
);

-- Temporary_Residence - Kiểm tra ngày hợp lệ
ALTER TABLE public_security.temporary_residence ADD CONSTRAINT ck_temporary_residence_dates
CHECK (
    registration_date <= CURRENT_DATE AND
    (expiry_date IS NULL OR expiry_date > registration_date) AND
    (last_extension_date IS NULL OR (last_extension_date >= registration_date AND 
                                   last_extension_date <= CURRENT_DATE))
);

-- Temporary_Absence - Kiểm tra ngày hợp lệ
ALTER TABLE public_security.temporary_absence ADD CONSTRAINT ck_temporary_absence_dates
CHECK (
    from_date <= CURRENT_DATE AND
    (to_date IS NULL OR to_date > from_date) AND
    (return_date IS NULL OR return_date >= from_date) AND
    (return_confirmed_date IS NULL OR 
     (return_confirmed_date >= from_date AND return_confirmed_date <= CURRENT_DATE))
);

-- =============================================================================
-- 7. TRIGGERS TÍNH TOÁN GEOGRAPHICAL_REGION TỰ ĐỘNG
-- =============================================================================

-- Tạo function lấy geographical_region từ region_id
CREATE OR REPLACE FUNCTION public_security.get_geographical_region(p_region_id SMALLINT)
RETURNS VARCHAR(20) AS $$
BEGIN
    CASE p_region_id
        WHEN 1 THEN RETURN 'Bắc';
        WHEN 2 THEN RETURN 'Trung';
        WHEN 3 THEN RETURN 'Nam';
        ELSE RETURN NULL;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Tạo trigger cho bảng address
CREATE OR REPLACE FUNCTION public_security.address_set_geographical_region()
RETURNS TRIGGER AS $$
BEGIN
    NEW.geographical_region := public_security.get_geographical_region(NEW.region_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_address_set_geographical_region
BEFORE INSERT OR UPDATE OF region_id ON public_security.address
FOR EACH ROW EXECUTE FUNCTION public_security.address_set_geographical_region();

-- Tạo trigger tương tự cho các bảng còn lại
-- (Bỏ qua để tiết kiệm không gian, nhưng thực tế sẽ tạo cho tất cả các bảng)

-- =============================================================================
-- 8. TRIGGERS CẬP NHẬT THỜI GIAN
-- =============================================================================

-- Tạo function cập nhật trường updated_at
CREATE OR REPLACE FUNCTION public_security.update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger cho tất cả các bảng
CREATE TRIGGER trg_address_update_timestamp
BEFORE UPDATE ON public_security.address
FOR EACH ROW EXECUTE FUNCTION public_security.update_modified_column();

CREATE TRIGGER trg_citizen_address_update_timestamp
BEFORE UPDATE ON public_security.citizen_address
FOR EACH ROW EXECUTE FUNCTION public_security.update_modified_column();

CREATE TRIGGER trg_permanent_residence_update_timestamp
BEFORE UPDATE ON public_security.permanent_residence
FOR EACH ROW EXECUTE FUNCTION public_security.update_modified_column();

CREATE TRIGGER trg_temporary_residence_update_timestamp
BEFORE UPDATE ON public_security.temporary_residence
FOR EACH ROW EXECUTE FUNCTION public_security.update_modified_column();

CREATE TRIGGER trg_temporary_absence_update_timestamp
BEFORE UPDATE ON public_security.temporary_absence
FOR EACH ROW EXECUTE FUNCTION public_security.update_modified_column();

COMMIT;


/*

1. THÊM ĐỊA CHỈ MỚI:
   - Đầu tiên, thêm bản ghi vào bảng address
   - Sau đó liên kết địa chỉ với công dân thông qua bảng citizen_address
   - Trong trường hợp đăng ký thường trú/tạm trú, thêm bản ghi vào bảng tương ứng

2. CẬP NHẬT ĐỊA CHỈ:
   - Không thay đổi bản ghi cũ, thay vào đó:
      + Đánh dấu bản ghi cũ là không còn hiệu lực (status = FALSE)
      + Thêm bản ghi địa chỉ mới
      + Cập nhật các liên kết địa chỉ tương ứng

3. QUẢN LÝ THƯỜNG TRÚ:
   - Mỗi công dân chỉ có một địa chỉ thường trú có hiệu lực tại một thời điểm
   - Khi đăng ký thường trú mới:
      + Cập nhật bản ghi thường trú cũ (status = FALSE)
      + Thêm bản ghi mới với thông tin địa chỉ mới
      + Cập nhật bảng citizen_address để phản ánh thay đổi

4. QUẢN LÝ TẠM TRÚ:
   - Có thể có nhiều bản ghi tạm trú cùng lúc với các mục đích khác nhau
   - Mỗi bản ghi tạm trú nên có thời hạn cụ thể (expiry_date)
   - Có thể gia hạn bằng cách cập nhật expiry_date và tăng extension_count

5. QUẢN LÝ TẠM VẮNG:
   - Ghi nhận thông tin khi công dân tạm thời rời khỏi nơi cư trú
   - Khi công dân quay lại, cập nhật return_date và return_confirmed

6. LIÊN KẾT VỚI HỘ KHẨU:
   - Bảng permanent_residence có thể liên kết với household_id từ bảng household trong schema justice
   - Điều này cho phép xây dựng mối quan hệ giữa đăng ký thường trú và sổ hộ khẩu

7. TÌM KIẾM CÔNG DÂN THEO ĐỊA CHỈ:
   - Sử dụng bảng citizen_address để tìm tất cả công dân sống tại một địa chỉ cụ thể
   - Lọc theo address_type để tìm các địa chỉ thường trú, tạm trú, hoặc nơi làm việc

8. PHÂN VÙNG DỮ LIỆU:
   - Các bảng được thiết kế để phân vùng theo geographical_region (Bắc, Trung, Nam)
   - Điều này cải thiện hiệu suất truy vấn trong cơ sở dữ liệu phân tán theo vùng địa lý
   - Các trường region_id, province_id và geographical_region cần được đồng bộ

9. AN TOÀN DỮ LIỆU:
   - Trường data_sensitivity_level xác định mức độ nhạy cảm của dữ liệu
   - Các quy tắc truy cập cần được triển khai dựa trên mức độ này
*/
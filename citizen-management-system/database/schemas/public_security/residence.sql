-- Tạo các bảng quản lý cư trú trong schema public_security
-- Bao gồm: address, citizen_address, permanent_residence,
-- temporary_residence, temporary_absence

-- Tạo bảng address trong schema public_security

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo các bảng quản lý cư trú cho các database vùng miền...'

CREATE OR REPLACE FUNCTION create_residence_tables() RETURNS void AS $$
BEGIN
    -- 1. Bảng Address (Địa chỉ)
    CREATE TABLE IF NOT EXISTS public_security.address (
        address_id SERIAL PRIMARY KEY,  --Mã địa chỉ
        address_detail TEXT NOT NULL, --Chi tiết địa chỉ
        ward_id INT REFERENCES reference.ward(ward_id), --Mã phường/xã
        district_id INT REFERENCES reference.district(district_id), --Mã quận/huyện
        province_id INT REFERENCES reference.province(province_id), --Mã tỉnh/thành phố
        address_type address_type, --Loại địa chỉ
        postal_code VARCHAR(10), --Mã bưu chính
        latitude DECIMAL(10, 8), --Vĩ độ
        longitude DECIMAL(11, 8), --Kinh độ
        status BOOLEAN DEFAULT TRUE, --Trạng thái
        region_id SMALLINT REFERENCES reference.region(region_id), --Mã vùng miền
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, --Thời gian tạo
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP --Thời gian cập nhật
    );
    
    COMMENT ON TABLE public_security.address IS 'Bảng lưu trữ thông tin địa chỉ';
    
    -- 2. Bảng CitizenAddress (Địa chỉ công dân)
    CREATE TABLE IF NOT EXISTS public_security.citizen_address (
        citizen_address_id SERIAL PRIMARY KEY,--Mã địa chỉ công dân
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),--Mã định danh công dân
        address_id INT NOT NULL REFERENCES public_security.address(address_id),--Mã địa chỉ
        address_type address_type NOT NULL,--Loại địa chỉ (Thường trú/Tạm trú/Nơi ở hiện tại)
        from_date DATE NOT NULL,--Từ ngày
        to_date DATE,--Đến ngày
        status BOOLEAN DEFAULT TRUE,--Trạng thái
        registration_document_no VARCHAR(50),--Số giấy đăng ký
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),--Cơ quan cấp
        region_id SMALLINT REFERENCES reference.region(region_id),--Mã vùng miề
        province_id INT REFERENCES reference.province(province_id),--Mã tỉnh/thành phố
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,--Thời gian tạo
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP--Thời gian cập nhật
    );
    
    COMMENT ON TABLE public_security.citizen_address IS 'Bảng liên kết giữa công dân và địa chỉ';
    
    -- 3. Bảng PermanentResidence (Đăng ký thường trú)
    CREATE TABLE IF NOT EXISTS public_security.permanent_residence (
        permanent_residence_id SERIAL PRIMARY KEY,--Mã đăng ký thường trú
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),--Mã định danh công dân
        address_id INT NOT NULL REFERENCES public_security.address(address_id),--Mã địa chỉ
        registration_date DATE NOT NULL,--Ngày đăng ký
        decision_no VARCHAR(50),--Số quyết định
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),--Cơ quan cấp
        previous_address_id INT REFERENCES public_security.address(address_id),--Mã địa chỉ trước đó
        change_reason TEXT,--Lý do thay đổi
        status BOOLEAN DEFAULT TRUE,--Trạng thái
        region_id SMALLINT REFERENCES reference.region(region_id),--
        province_id INT REFERENCES reference.province(province_id),--
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,--
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP--
    );
    
    COMMENT ON TABLE public_security.permanent_residence IS 'Bảng lưu trữ thông tin đăng ký thường trú của công dân';
    
    -- 4. Bảng TemporaryResidence (Đăng ký tạm trú)
    CREATE TABLE IF NOT EXISTS public_security.temporary_residence (
        temporary_residence_id SERIAL PRIMARY KEY,--Mã đăng ký tạm tr
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),--Mã định danh công dân
        address_id INT NOT NULL REFERENCES public_security.address(address_id),--Mã địa chỉ
        registration_date DATE NOT NULL,--Ngày đăng ký
        expiry_date DATE,--Ngày hết hạn
        purpose TEXT,--Mục đích
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),--Cơ quan cấp
        registration_number VARCHAR(50),--Số đăng ký
        status BOOLEAN DEFAULT TRUE,--Trạng thái
        permanent_address_id INT REFERENCES public_security.address(address_id),--Mã địa chỉ thường trú
        host_name VARCHAR(100),--Tên chủ hộ nơi tạm tr
        host_citizen_id VARCHAR(12) REFERENCES public_security.citizen(citizen_id),--Mã định danh chủ hộ nơi tạm trú
        host_relationship VARCHAR(50),--Mối quan hệ với chủ hộ
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE public_security.temporary_residence IS 'Bảng lưu trữ thông tin đăng ký tạm trú của công dân';
    
    -- 5. Bảng TemporaryAbsence (Đăng ký tạm vắng)
    CREATE TABLE IF NOT EXISTS public_security.temporary_absence (
        temporary_absence_id SERIAL PRIMARY KEY,--Mã đăng ký tạm vắng
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        from_date DATE NOT NULL,--
        to_date DATE,--
        reason TEXT,--
        destination_address_id INT REFERENCES public_security.address(address_id),--Mã địa chỉ đến
        destination_detail TEXT,--Chi tiết nơi đến
        contact_information TEXT,--Thông tin liên hệ
        registration_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),--Cơ quan đăng ký
        registration_number VARCHAR(50),--Số đăng ký
        status BOOLEAN DEFAULT TRUE,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    
    COMMENT ON TABLE public_security.temporary_absence IS 'Bảng lưu trữ thông tin đăng ký tạm vắng của công dân';
    
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_residence_tables();
\echo 'Đã tạo các bảng quản lý cư trú cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_residence_tables();
\echo 'Đã tạo các bảng quản lý cư trú cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_residence_tables();
\echo 'Đã tạo các bảng quản lý cư trú cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_residence_tables();
\echo 'Đã tạo các bảng quản lý cư trú cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_residence_tables();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong các bảng quản lý cư trú cho tất cả các database.'
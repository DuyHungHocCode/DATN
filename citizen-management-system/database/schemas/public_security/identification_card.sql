-- identification_card.sql
-- Tạo bảng IdentificationCard (Căn cước công dân) cho hệ thống CSDL phân tán quản lý dân cư quốc gia

-- Kết nối đến các database vùng miền và tạo bảng
\echo 'Tạo bảng IdentificationCard cho các database vùng miền...'

-- Hàm tạo bảng IdentificationCard
CREATE OR REPLACE FUNCTION create_identification_card_table() RETURNS void AS $$
BEGIN
    -- Tạo bảng IdentificationCard trong schema public_security
    CREATE TABLE IF NOT EXISTS public_security.identification_card (
        card_id SERIAL PRIMARY KEY,
        citizen_id VARCHAR(12) NOT NULL REFERENCES public_security.citizen(citizen_id),
        card_number VARCHAR(12) NOT NULL UNIQUE,
        issue_date DATE NOT NULL,
        expiry_date DATE,
        issuing_authority_id SMALLINT REFERENCES reference.issuing_authority(authority_id),
        card_type card_type NOT NULL,
        fingerprint_left_index BYTEA,
        fingerprint_right_index BYTEA,
        fingerprint_left_thumb BYTEA,
        fingerprint_right_thumb BYTEA,
        facial_biometric BYTEA,
        iris_data BYTEA,
        chip_serial_number VARCHAR(50),
        card_status card_status NOT NULL DEFAULT 'Đang sử dụng',
        previous_card_number VARCHAR(12),
        notes TEXT,
        region_id SMALLINT REFERENCES reference.region(region_id),
        province_id INT REFERENCES reference.province(province_id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_by VARCHAR(50),
        updated_by VARCHAR(50),
        CONSTRAINT uq_citizen_active_card UNIQUE (citizen_id, card_status)
            DEFERRABLE INITIALLY DEFERRED -- Cho phép tạm thời vi phạm ràng buộc trong cùng giao dịch
    );
    
    -- Thêm comment cho bảng và các cột
    COMMENT ON TABLE public_security.identification_card IS 'Bảng lưu trữ thông tin căn cước công dân';
    COMMENT ON COLUMN public_security.identification_card.card_id IS 'Mã định danh của thẻ căn cước';
    COMMENT ON COLUMN public_security.identification_card.citizen_id IS 'Mã định danh công dân';
    COMMENT ON COLUMN public_security.identification_card.card_number IS 'Số thẻ căn cước';
    COMMENT ON COLUMN public_security.identification_card.issue_date IS 'Ngày cấp thẻ';
    COMMENT ON COLUMN public_security.identification_card.expiry_date IS 'Ngày hết hạn thẻ';
    COMMENT ON COLUMN public_security.identification_card.issuing_authority_id IS 'Mã cơ quan cấp';
    COMMENT ON COLUMN public_security.identification_card.card_type IS 'Loại thẻ (CMND 9 số/CMND 12 số/CCCD/CCCD gắn chip)';
    COMMENT ON COLUMN public_security.identification_card.fingerprint_left_index IS 'Dữ liệu vân tay ngón trỏ trái';
    COMMENT ON COLUMN public_security.identification_card.fingerprint_right_index IS 'Dữ liệu vân tay ngón trỏ phải';
    COMMENT ON COLUMN public_security.identification_card.fingerprint_left_thumb IS 'Dữ liệu vân tay ngón cái trái';
    COMMENT ON COLUMN public_security.identification_card.fingerprint_right_thumb IS 'Dữ liệu vân tay ngón cái phải';
    COMMENT ON COLUMN public_security.identification_card.facial_biometric IS 'Dữ liệu khuôn mặt';
    COMMENT ON COLUMN public_security.identification_card.iris_data IS 'Dữ liệu mống mắt';
    COMMENT ON COLUMN public_security.identification_card.chip_serial_number IS 'Số seri chip trong thẻ (nếu có)';
    COMMENT ON COLUMN public_security.identification_card.card_status IS 'Trạng thái thẻ (Đang sử dụng/Hết hạn/Mất/Hỏng/Thu hồi)';
    COMMENT ON COLUMN public_security.identification_card.previous_card_number IS 'Số thẻ căn cước trước đây';
    COMMENT ON COLUMN public_security.identification_card.notes IS 'Ghi chú bổ sung';
    COMMENT ON COLUMN public_security.identification_card.region_id IS 'Mã vùng miền';
    COMMENT ON COLUMN public_security.identification_card.province_id IS 'Mã tỉnh/thành phố nơi cấp';
    COMMENT ON COLUMN public_security.identification_card.created_at IS 'Thời gian tạo bản ghi';
    COMMENT ON COLUMN public_security.identification_card.updated_at IS 'Thời gian cập nhật bản ghi gần nhất';
    COMMENT ON COLUMN public_security.identification_card.created_by IS 'Người tạo bản ghi';
    COMMENT ON COLUMN public_security.identification_card.updated_by IS 'Người cập nhật bản ghi gần nhất';
    
    -- Tạo các chỉ mục cho bảng identification_card
    CREATE INDEX IF NOT EXISTS idx_idc_citizen_id ON public_security.identification_card(citizen_id);
    CREATE INDEX IF NOT EXISTS idx_idc_card_number ON public_security.identification_card(card_number);
    CREATE INDEX IF NOT EXISTS idx_idc_issue_date ON public_security.identification_card(issue_date);
    CREATE INDEX IF NOT EXISTS idx_idc_expiry_date ON public_security.identification_card(expiry_date);
    CREATE INDEX IF NOT EXISTS idx_idc_card_status ON public_security.identification_card(card_status);
    CREATE INDEX IF NOT EXISTS idx_idc_issuing_authority ON public_security.identification_card(issuing_authority_id);
    CREATE INDEX IF NOT EXISTS idx_idc_region ON public_security.identification_card(region_id);
    CREATE INDEX IF NOT EXISTS idx_idc_province ON public_security.identification_card(province_id);
    CREATE INDEX IF NOT EXISTS idx_idc_card_type ON public_security.identification_card(card_type);
    CREATE INDEX IF NOT EXISTS idx_idc_previous_card_number ON public_security.identification_card(previous_card_number);
    
    -- Hàm cập nhật thời gian chỉnh sửa
    CREATE OR REPLACE FUNCTION update_identification_card_timestamp()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    
    -- Trigger tự động cập nhật thời gian chỉnh sửa
    CREATE TRIGGER update_identification_card_timestamp_trigger
    BEFORE UPDATE ON public_security.identification_card
    FOR EACH ROW
    EXECUTE FUNCTION update_identification_card_timestamp();
    
    -- Các ràng buộc kiểm tra
    
    -- Ràng buộc kiểm tra số CCCD
    ALTER TABLE public_security.identification_card
    ADD CONSTRAINT check_card_number_format
    CHECK (
        (card_type = 'CMND 9 số' AND card_number ~ '^[0-9]{9}$') OR
        (card_type = 'CMND 12 số' AND card_number ~ '^[0-9]{12}$') OR
        ((card_type = 'CCCD' OR card_type = 'CCCD gắn chip') AND card_number ~ '^[0-9]{12}$')
    );
    
    -- Ràng buộc kiểm tra thời hạn thẻ
    ALTER TABLE public_security.identification_card
    ADD CONSTRAINT check_card_expiry
    CHECK (expiry_date IS NULL OR expiry_date > issue_date);
    
    -- Chỉ được có một thẻ 'Đang sử dụng' cho mỗi công dân
    CREATE OR REPLACE FUNCTION check_active_card()
    RETURNS TRIGGER AS $$
    BEGIN
        -- Nếu thẻ mới đang được đánh dấu là đang sử dụng
        IF NEW.card_status = 'Đang sử dụng' THEN
            -- Cập nhật tất cả các thẻ khác của công dân này thành 'Đã thay thế'
            UPDATE public_security.identification_card
            SET card_status = 'Đã thay thế',
                updated_at = CURRENT_TIMESTAMP,
                updated_by = NEW.created_by
            WHERE citizen_id = NEW.citizen_id
              AND card_id != NEW.card_id
              AND card_status = 'Đang sử dụng';
        END IF;
        
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    
    -- Trigger kiểm tra thẻ đang sử dụng
    CREATE TRIGGER check_active_card_trigger
    BEFORE INSERT OR UPDATE ON public_security.identification_card
    FOR EACH ROW
    EXECUTE FUNCTION check_active_card();
    
    -- Function để lấy thông tin thẻ hiện hành của công dân
    CREATE OR REPLACE FUNCTION public_security.get_current_card(p_citizen_id VARCHAR(12))
    RETURNS TABLE (
        card_id INT,
        card_number VARCHAR(12),
        issue_date DATE,
        expiry_date DATE,
        card_type card_type,
        issuing_authority VARCHAR(200),
        card_status card_status
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT 
            ic.card_id,
            ic.card_number,
            ic.issue_date,
            ic.expiry_date,
            ic.card_type,
            ia.authority_name,
            ic.card_status
        FROM 
            public_security.identification_card ic
        JOIN 
            reference.issuing_authority ia ON ic.issuing_authority_id = ia.authority_id
        WHERE 
            ic.citizen_id = p_citizen_id
        AND 
            ic.card_status = 'Đang sử dụng'
        ORDER BY 
            ic.issue_date DESC
        LIMIT 1;
    END;
    $$ LANGUAGE plpgsql;
    
    -- Function để lấy lịch sử thẻ của công dân
    CREATE OR REPLACE FUNCTION public_security.get_card_history(p_citizen_id VARCHAR(12))
    RETURNS TABLE (
        card_id INT,
        card_number VARCHAR(12),
        issue_date DATE,
        expiry_date DATE,
        card_type card_type,
        issuing_authority VARCHAR(200),
        card_status card_status
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT 
            ic.card_id,
            ic.card_number,
            ic.issue_date,
            ic.expiry_date,
            ic.card_type,
            ia.authority_name,
            ic.card_status
        FROM 
            public_security.identification_card ic
        JOIN 
            reference.issuing_authority ia ON ic.issuing_authority_id = ia.authority_id
        WHERE 
            ic.citizen_id = p_citizen_id
        ORDER BY 
            ic.issue_date DESC;
    END;
    $$ LANGUAGE plpgsql;
    
    -- Procedure để cấp mới thẻ CCCD
    CREATE OR REPLACE PROCEDURE public_security.issue_new_card(
        p_citizen_id VARCHAR(12),
        p_card_number VARCHAR(12),
        p_issue_date DATE,
        p_expiry_date DATE,
        p_issuing_authority_id SMALLINT,
        p_card_type card_type,
        p_previous_card_number VARCHAR(12),
        p_region_id SMALLINT,
        p_province_id INT,
        p_created_by VARCHAR(50)
    )
    LANGUAGE plpgsql
    AS $$
    DECLARE
        v_new_card_id INT;
    BEGIN
        -- Bắt đầu transaction
        BEGIN
            -- Cấp mới thẻ
            INSERT INTO public_security.identification_card (
                citizen_id, card_number, issue_date, expiry_date, 
                issuing_authority_id, card_type, card_status, 
                previous_card_number, region_id, province_id, 
                created_by, updated_by
            ) VALUES (
                p_citizen_id, p_card_number, p_issue_date, p_expiry_date, 
                p_issuing_authority_id, p_card_type, 'Đang sử dụng', 
                p_previous_card_number, p_region_id, p_province_id, 
                p_created_by, p_created_by
            )
            RETURNING card_id INTO v_new_card_id;
            
            -- Trigger sẽ tự động cập nhật trạng thái các thẻ cũ
            
            -- Commit transaction
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                -- Rollback nếu có lỗi
                ROLLBACK;
                RAISE;
        END;
    END;
    $$;
END;
$$ LANGUAGE plpgsql;

-- Kết nối đến database miền Bắc
\connect national_citizen_north
SELECT create_identification_card_table();
\echo 'Đã tạo bảng IdentificationCard cho database miền Bắc'

-- Kết nối đến database miền Trung
\connect national_citizen_central
SELECT create_identification_card_table();
\echo 'Đã tạo bảng IdentificationCard cho database miền Trung'

-- Kết nối đến database miền Nam
\connect national_citizen_south
SELECT create_identification_card_table();
\echo 'Đã tạo bảng IdentificationCard cho database miền Nam'

-- Kết nối đến database trung tâm
\connect national_citizen_central_server
SELECT create_identification_card_table();
\echo 'Đã tạo bảng IdentificationCard cho database trung tâm'

-- Xóa hàm tạm sau khi sử dụng xong
DROP FUNCTION create_identification_card_table();

-- In ra thông báo hoàn thành
\echo 'Đã tạo xong bảng IdentificationCard cho tất cả các database.'
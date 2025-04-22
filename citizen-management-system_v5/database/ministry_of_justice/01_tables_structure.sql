-- =============================================================================
-- File: ministry_of_justice/01_tables_structure.sql
-- Description: Tạo cấu trúc cơ bản (CREATE TABLE) cho TẤT CẢ các bảng
--              trong database Bộ Tư pháp (ministry_of_justice).
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO CẤU TRÚC BẢNG CHO DATABASE BỘ TƯ PHÁP ***'
\connect ministry_of_justice

-- === Schema: justice ===

\echo '[1] Tạo cấu trúc bảng trong schema: justice...'

-- Bảng: birth_certificate (Giấy khai sinh) - Phân vùng theo địa lý
DROP TABLE IF EXISTS justice.birth_certificate CASCADE;
CREATE TABLE justice.birth_certificate (
    birth_certificate_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL, -- UNIQUE sẽ thêm sau
    birth_certificate_no VARCHAR(20) NOT NULL, -- UNIQUE sẽ thêm sau
    registration_date DATE NOT NULL,
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    issuing_authority_id SMALLINT NOT NULL,
    place_of_birth TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender_at_birth gender_type NOT NULL,
    -- Thông tin cha
    father_full_name VARCHAR(100),
    father_citizen_id VARCHAR(12),
    father_date_of_birth DATE,
    father_nationality_id SMALLINT,
    -- Thông tin mẹ
    mother_full_name VARCHAR(100),
    mother_citizen_id VARCHAR(12),
    mother_date_of_birth DATE,
    mother_nationality_id SMALLINT,
    -- Người khai
    declarant_name VARCHAR(100) NOT NULL,
    declarant_citizen_id VARCHAR(12),
    declarant_relationship VARCHAR(50),
    -- Khác
    witness1_name VARCHAR(100),
    witness2_name VARCHAR(100),
    birth_notification_no VARCHAR(50),
    status BOOLEAN DEFAULT TRUE,
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_birth_certificate PRIMARY KEY (birth_certificate_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.birth_certificate IS '[BTP] Lưu thông tin đăng ký khai sinh.';
COMMENT ON COLUMN justice.birth_certificate.citizen_id IS 'Số định danh của người được khai sinh (Logic liên kết).';
COMMENT ON COLUMN justice.birth_certificate.birth_certificate_no IS 'Số giấy khai sinh (Cần kiểm tra unique).';
COMMENT ON COLUMN justice.birth_certificate.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.birth_certificate.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN justice.birth_certificate.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: death_certificate (Giấy khai tử) - Phân vùng theo địa lý
DROP TABLE IF EXISTS justice.death_certificate CASCADE;
CREATE TABLE justice.death_certificate (
    death_certificate_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL, -- UNIQUE sẽ thêm sau
    death_certificate_no VARCHAR(20) NOT NULL, -- UNIQUE sẽ thêm sau
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    date_of_death DATE NOT NULL,
    time_of_death TIME,
    place_of_death TEXT NOT NULL,
    cause_of_death TEXT,
    declarant_name VARCHAR(100) NOT NULL,
    declarant_citizen_id VARCHAR(12),
    declarant_relationship VARCHAR(50),
    registration_date DATE NOT NULL,
    issuing_authority_id SMALLINT,
    death_notification_no VARCHAR(50),
    witness1_name VARCHAR(100),
    witness2_name VARCHAR(100),
    status BOOLEAN DEFAULT TRUE,
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_death_certificate PRIMARY KEY (death_certificate_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.death_certificate IS '[BTP] Lưu thông tin đăng ký khai tử.';
COMMENT ON COLUMN justice.death_certificate.citizen_id IS 'Số định danh của người được khai tử (Logic liên kết).';
COMMENT ON COLUMN justice.death_certificate.death_certificate_no IS 'Số giấy khai tử (Cần kiểm tra unique).';
COMMENT ON COLUMN justice.death_certificate.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.death_certificate.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN justice.death_certificate.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: marriage (Đăng ký kết hôn) - Phân vùng theo địa lý
DROP TABLE IF EXISTS justice.marriage CASCADE;
CREATE TABLE justice.marriage (
    marriage_id BIGSERIAL NOT NULL,
    marriage_certificate_no VARCHAR(20) NOT NULL, -- UNIQUE sẽ thêm sau
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    -- Chồng
    husband_id VARCHAR(12) NOT NULL,
    husband_full_name VARCHAR(100) NOT NULL,
    husband_date_of_birth DATE NOT NULL,
    husband_nationality_id SMALLINT NOT NULL,
    husband_previous_marriage_status VARCHAR(50),
    -- Vợ
    wife_id VARCHAR(12) NOT NULL,
    wife_full_name VARCHAR(100) NOT NULL,
    wife_date_of_birth DATE NOT NULL,
    wife_nationality_id SMALLINT NOT NULL,
    wife_previous_marriage_status VARCHAR(50),
    -- Đăng ký
    marriage_date DATE NOT NULL,
    registration_date DATE NOT NULL,
    issuing_authority_id SMALLINT NOT NULL,
    issuing_place TEXT NOT NULL,
    witness1_name VARCHAR(100),
    witness2_name VARCHAR(100),
    status BOOLEAN DEFAULT TRUE, -- Trạng thái hôn nhân (còn hiệu lực?)
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_marriage PRIMARY KEY (marriage_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.marriage IS '[BTP] Lưu thông tin đăng ký kết hôn.';
COMMENT ON COLUMN justice.marriage.marriage_certificate_no IS 'Số giấy đăng ký kết hôn (Cần kiểm tra unique).';
COMMENT ON COLUMN justice.marriage.status IS 'Trạng thái hôn nhân (TRUE = còn hiệu lực, FALSE = đã ly hôn/hủy bỏ).';
COMMENT ON COLUMN justice.marriage.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.marriage.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN justice.marriage.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: divorce (Ghi chú ly hôn) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS justice.divorce CASCADE;
CREATE TABLE justice.divorce (
    divorce_id BIGSERIAL NOT NULL,
    divorce_certificate_no VARCHAR(20) NOT NULL, -- UNIQUE sẽ thêm sau
    book_id VARCHAR(20),
    page_no VARCHAR(10),
    marriage_id INT NOT NULL, -- UNIQUE sẽ thêm sau
    divorce_date DATE NOT NULL,
    registration_date DATE NOT NULL,
    court_name VARCHAR(200) NOT NULL,
    judgment_no VARCHAR(50) NOT NULL, -- UNIQUE sẽ thêm sau
    judgment_date DATE NOT NULL,
    issuing_authority_id SMALLINT,
    reason TEXT,
    child_custody TEXT,
    property_division TEXT,
    status BOOLEAN DEFAULT TRUE,
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_divorce PRIMARY KEY (divorce_id, geographical_region, province_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.divorce IS '[BTP] Lưu thông tin ghi chú ly hôn dựa trên bản án/quyết định của Tòa án.';
COMMENT ON COLUMN justice.divorce.marriage_id IS 'ID của cuộc hôn nhân đã ly hôn (Cần kiểm tra unique).';
COMMENT ON COLUMN justice.divorce.judgment_no IS 'Số bản án/quyết định ly hôn của Tòa án (Cần kiểm tra unique).';
COMMENT ON COLUMN justice.divorce.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.divorce.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

-- Bảng: household (Sổ hộ khẩu) - Phân vùng theo địa lý
DROP TABLE IF EXISTS justice.household CASCADE;
CREATE TABLE justice.household (
    household_id BIGSERIAL NOT NULL,
    household_book_no VARCHAR(20) NOT NULL, -- UNIQUE sẽ thêm sau
    head_of_household_id VARCHAR(12) NOT NULL,
    address_id INT NOT NULL,
    registration_date DATE NOT NULL,
    issuing_authority_id SMALLINT,
    area_code VARCHAR(10),
    household_type household_type NOT NULL,
    status household_status DEFAULT 'Đang hoạt động',
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    district_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_household PRIMARY KEY (household_id, geographical_region, province_id, district_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.household IS '[BTP] Lưu thông tin về Sổ hộ khẩu.';
COMMENT ON COLUMN justice.household.household_book_no IS 'Số sổ hộ khẩu (Cần kiểm tra unique).';
COMMENT ON COLUMN justice.household.head_of_household_id IS 'ID Công dân của chủ hộ (Logic liên kết).';
COMMENT ON COLUMN justice.household.address_id IS 'ID Địa chỉ đăng ký của hộ khẩu (Logic liên kết).';
COMMENT ON COLUMN justice.household.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.household.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';
COMMENT ON COLUMN justice.household.district_id IS 'ID Quận/Huyện - Khóa phân vùng cấp 3.';

-- Bảng: household_member (Thành viên hộ khẩu) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS justice.household_member CASCADE;
CREATE TABLE justice.household_member (
    household_member_id BIGSERIAL NOT NULL,
    household_id INT NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    relationship_with_head household_relationship NOT NULL,
    join_date DATE NOT NULL,
    leave_date DATE,
    leave_reason TEXT,
    previous_household_id INT,
    status VARCHAR(50) DEFAULT 'Active', -- CHECK constraint sẽ thêm sau
    order_in_household SMALLINT,
    -- Phân vùng
    region_id SMALLINT NOT NULL,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_household_member PRIMARY KEY (household_member_id, geographical_region, province_id),
    -- Ràng buộc UNIQUE cơ bản (sẽ kiểm tra lại với partitioning)
    CONSTRAINT uq_household_member_join UNIQUE (household_id, citizen_id, join_date)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.household_member IS '[BTP] Lưu thông tin các thành viên thuộc một hộ khẩu.';
COMMENT ON COLUMN justice.household_member.citizen_id IS 'ID của công dân là thành viên (Logic liên kết).';
COMMENT ON COLUMN justice.household_member.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.household_member.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

-- Bảng: family_relationship (Quan hệ gia đình) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS justice.family_relationship CASCADE;
CREATE TABLE justice.family_relationship (
    relationship_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    related_citizen_id VARCHAR(12) NOT NULL,
    relationship_type family_relationship_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status record_status DEFAULT 'Đang xử lý',
    document_proof TEXT,
    document_no VARCHAR(50),
    issuing_authority_id SMALLINT,
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_family_relationship PRIMARY KEY (relationship_id, geographical_region, province_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.family_relationship IS '[BTP] Ghi nhận các mối quan hệ gia đình đã được xác thực.';
COMMENT ON COLUMN justice.family_relationship.citizen_id IS 'ID công dân thứ nhất (Logic liên kết).';
COMMENT ON COLUMN justice.family_relationship.related_citizen_id IS 'ID công dân thứ hai có quan hệ (Logic liên kết).';
COMMENT ON COLUMN justice.family_relationship.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.family_relationship.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

-- Bảng: population_change (Biến động dân số) - Phân vùng theo địa lý (Miền -> Tỉnh)
DROP TABLE IF EXISTS justice.population_change CASCADE;
CREATE TABLE justice.population_change (
    change_id BIGSERIAL NOT NULL,
    citizen_id VARCHAR(12) NOT NULL,
    change_type population_change_type NOT NULL,
    change_date DATE NOT NULL,
    source_location_id INT,
    destination_location_id INT,
    reason TEXT,
    related_document_no VARCHAR(50),
    processing_authority_id SMALLINT,
    status BOOLEAN DEFAULT TRUE,
    notes TEXT,
    -- Phân vùng
    region_id SMALLINT,
    province_id INT NOT NULL,
    geographical_region VARCHAR(20) NOT NULL,
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_population_change PRIMARY KEY (change_id, geographical_region, province_id)
) PARTITION BY LIST (geographical_region);
COMMENT ON TABLE justice.population_change IS '[BTP] Ghi nhận lịch sử các sự kiện biến động dân số, hộ tịch, cư trú.';
COMMENT ON COLUMN justice.population_change.citizen_id IS 'ID công dân có biến động (Logic liên kết).';
COMMENT ON COLUMN justice.population_change.geographical_region IS 'Vùng địa lý - Khóa phân vùng cấp 1.';
COMMENT ON COLUMN justice.population_change.province_id IS 'ID Tỉnh/Thành phố - Khóa phân vùng cấp 2.';

\echo '   -> Hoàn thành tạo cấu trúc bảng schema justice.'

-- === Schema: audit ===

\echo '[2] Tạo cấu trúc bảng trong schema: audit...'

-- Bảng: audit_log (Nhật ký thay đổi) - Phân vùng theo thời gian
DROP TABLE IF EXISTS audit.audit_log CASCADE;
CREATE TABLE audit.audit_log (
    log_id BIGSERIAL NOT NULL,
    action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(), -- Cột phân vùng
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation cdc_operation_type NOT NULL,
    session_user_name TEXT DEFAULT current_user,
    application_name TEXT DEFAULT current_setting('application_name'),
    client_addr INET DEFAULT inet_client_addr(),
    client_port INTEGER DEFAULT inet_client_port(),
    transaction_id BIGINT DEFAULT txid_current(),
    statement_only BOOLEAN NOT NULL DEFAULT FALSE,
    row_data JSONB,
    changed_fields JSONB,
    query TEXT,
    -- Khóa chính bao gồm cột phân vùng
    CONSTRAINT pk_audit_log PRIMARY KEY (log_id, action_tstamp)
) PARTITION BY RANGE (action_tstamp);
COMMENT ON TABLE audit.audit_log IS '[BTP] Bảng ghi nhật ký chi tiết các thay đổi dữ liệu.';
COMMENT ON COLUMN audit.audit_log.action_tstamp IS 'Thời điểm thay đổi (Cột phân vùng RANGE).';

\echo '   -> Hoàn thành tạo cấu trúc bảng schema audit.'

-- === Schema: partitioning ===

\echo '[3] Tạo cấu trúc bảng trong schema: partitioning...'

-- Bảng: config (Cấu hình phân vùng) - Không phân vùng
DROP TABLE IF EXISTS partitioning.config CASCADE;
CREATE TABLE partitioning.config (
    config_id SERIAL PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL, -- CHECK sẽ thêm sau
    partition_columns TEXT NOT NULL,
    partition_interval VARCHAR(100),
    retention_period VARCHAR(100),
    premake INTEGER DEFAULT 4,
    is_active BOOLEAN DEFAULT TRUE,
    use_pg_partman BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_partition_config UNIQUE (schema_name, table_name)
);
COMMENT ON TABLE partitioning.config IS '[BTP] Lưu trữ cấu hình phân vùng cho các bảng trong database này.';

-- Bảng: history (Lịch sử phân vùng) - Không phân vùng
DROP TABLE IF EXISTS partitioning.history CASCADE;
CREATE TABLE partitioning.history (
    history_id BIGSERIAL PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(200) NOT NULL,
    action VARCHAR(50) NOT NULL, -- CHECK sẽ thêm sau
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Success', -- CHECK sẽ thêm sau
    affected_rows BIGINT,
    duration_ms BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    details TEXT
    -- FK đến config sẽ thêm sau
);
COMMENT ON TABLE partitioning.history IS '[BTP] Ghi lại lịch sử các hành động liên quan đến phân vùng.';

\echo '   -> Hoàn thành tạo cấu trúc bảng schema partitioning.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH TẠO CẤU TRÚC BẢNG CHO DATABASE BỘ TƯ PHÁP ***'
\echo '-> Đã tạo cấu trúc cơ bản cho các bảng trong các schema: justice, audit, partitioning.'
\echo '-> Bước tiếp theo: Chạy script 02_tables_constraints.sql để thêm các ràng buộc (FK, CHECK, UNIQUE...).'

```

**Những điểm chính:**

* **Chỉ `CREATE TABLE`:** File chỉ chứa các lệnh `DROP TABLE IF EXISTS ... CASCADE;` và `CREATE TABLE ...` cơ bản.
* **Ràng buộc cơ bản:** Giữ lại `NOT NULL`, `DEFAULT`, `PRIMARY KEY` (bao gồm cả cột phân vùng khi cần thiết), và `UNIQUE` đơn giản (như `uq_household_member_join`).
* **Loại bỏ FK, CHECK phức tạp, Index:** Các ràng buộc này và các index truy vấn đã được loại bỏ, sẽ được thêm trong file `02_tables_constraints.sql` hoặc `partitioning_setup.sql`. Các ràng buộc UNIQUE phức tạp hoặc có thể gây lỗi trên bảng phân vùng (như `birth_certificate_no`, `citizen_id` trong `birth_certificate`) được đánh dấu bằng comment.
* **`PARTITION BY`:** Khai báo phân vùng cấp 1 (`LIST` hoặc `RANGE`) cho các bảng cần thiết.
* **Comment chuẩn:** Sử dụng `COMMENT ON TABLE` và `COMMENT ON COLUMN` để ghi chú thích.
* **Cấu trúc:** Phân chia rõ ràng theo từng schema (`justice`, `audit`, `partitioning`).

File này cung cấp cấu trúc khung cho tất cả các bảng cần thiết trong CSDL Bộ Tư pháp, sẵn sàng cho việc thêm các ràng buộc và dữ li
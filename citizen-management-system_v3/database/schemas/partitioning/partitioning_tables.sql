-- =============================================================================
-- File: database/schemas/partitioning/partitioning_tables.sql
-- Description: Định nghĩa các bảng hỗ trợ quản lý và ghi log
--              cho việc phân vùng dữ liệu trong hệ thống QLDCQG.
-- Version: 1.0
--
-- Chức năng chính:
-- 1. Tạo bảng `partitioning.config` để lưu cấu hình phân vùng cho các bảng.
-- 2. Tạo bảng `partitioning.history` để ghi log các thao tác liên quan đến phân vùng.
--
-- Lưu ý: Các bảng này cần được tạo trong cả 3 database (BCA, BTP, TT)
--       để hỗ trợ các function phân vùng hoạt động độc lập trong từng DB.
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO CÁC BẢNG QUẢN LÝ PHÂN VÙNG ***'

-- ============================================================================
-- 1. TẠO BẢNG CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo '-> Tạo bảng quản lý phân vùng cho ministry_of_public_security...'
\connect ministry_of_public_security

-- Tạo schema partitioning nếu chưa tồn tại (Thường đã được tạo bởi init/create_schemas.sql)
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BCA] Schema chứa cấu hình, lịch sử và hàm quản lý phân vùng dữ liệu';

-- Bảng lưu cấu hình phân vùng cho từng bảng
CREATE TABLE IF NOT EXISTS partitioning.config (
    config_id SERIAL PRIMARY KEY,                     -- Khóa chính tự tăng
    table_name VARCHAR(100) NOT NULL,                 -- Tên bảng được phân vùng
    schema_name VARCHAR(100) NOT NULL,                -- Schema của bảng
    partition_type VARCHAR(20) NOT NULL             -- Kiểu phân vùng: 'NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST'...
        CHECK (partition_type IN ('NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER')),
    partition_columns TEXT NOT NULL,                  -- Danh sách cột dùng để phân vùng (phân tách bởi dấu phẩy nếu nhiều cột)
    partition_interval VARCHAR(100),                  -- Khoảng thời gian cho RANGE partitioning (e.g., '1 month', '1 day')
    retention_period VARCHAR(100),                    -- Thời gian lưu giữ dữ liệu trước khi archive/drop (e.g., '5 years', '36 months')
    premake INTEGER DEFAULT 4,                        -- Số lượng partition tạo trước cho pg_partman (RANGE/LIST)
    is_active BOOLEAN DEFAULT TRUE,                   -- Phân vùng này có đang được quản lý tự động không?
    use_pg_partman BOOLEAN DEFAULT FALSE,             -- Có sử dụng pg_partman để quản lý không?
    notes TEXT,                                       -- Ghi chú thêm
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_partition_config UNIQUE (schema_name, table_name) -- Đảm bảo mỗi bảng chỉ có 1 cấu hình
);

COMMENT ON TABLE partitioning.config IS 'Lưu trữ cấu hình phân vùng cho các bảng trong database này.';
COMMENT ON COLUMN partitioning.config.table_name IS 'Tên bảng được phân vùng.';
COMMENT ON COLUMN partitioning.config.schema_name IS 'Schema chứa bảng được phân vùng.';
COMMENT ON COLUMN partitioning.config.partition_type IS 'Loại chiến lược phân vùng chính (NESTED, REGION, PROVINCE, RANGE, LIST...).';
COMMENT ON COLUMN partitioning.config.partition_columns IS 'Các cột được sử dụng làm khóa phân vùng (cách nhau bởi dấu phẩy).';
COMMENT ON COLUMN partitioning.config.partition_interval IS 'Khoảng thời gian cho phân vùng RANGE (ví dụ: 1 month, 1 day).';
COMMENT ON COLUMN partitioning.config.retention_period IS 'Thời gian dữ liệu được giữ lại trước khi lưu trữ/xóa (ví dụ: 5 years).';
COMMENT ON COLUMN partitioning.config.premake IS 'Số lượng partition tạo trước cho pg_partman.';
COMMENT ON COLUMN partitioning.config.is_active IS 'Cấu hình này có đang được áp dụng và quản lý không?';
COMMENT ON COLUMN partitioning.config.use_pg_partman IS 'Có sử dụng pg_partman cho việc tạo/bảo trì partition không?';

-- Bảng lưu lịch sử các thao tác phân vùng
CREATE TABLE IF NOT EXISTS partitioning.history (
    history_id BIGSERIAL PRIMARY KEY,                 -- Dùng BIGSERIAL vì có thể có nhiều log
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(200) NOT NULL,             -- Tên của partition cụ thể bị ảnh hưởng, hoặc tên bảng cha
    action VARCHAR(50) NOT NULL                     -- Hành động: 'CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION', 'ARCHIVE_PARTITION', 'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'ERROR', 'CONFIG_UPDATE', 'INIT', 'COMPLETE'...
        CHECK (action IN ('CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION', 'ARCHIVE_START', 'ARCHIVE_PARTITION', 'ARCHIVED', 'ARCHIVE_COMPLETE', 'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'ERROR', 'CONFIG_UPDATE', 'INIT', 'COMPLETE')),
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Success'             -- Trạng thái: 'Success', 'Failed'
        CHECK (status IN ('Success', 'Failed', 'Running', 'Skipped')),
    affected_rows BIGINT,                             -- Số dòng bị ảnh hưởng (nếu có)
    duration_ms BIGINT,                               -- Thời gian thực hiện (milliseconds, nếu đo được)
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    details TEXT,                                     -- Chi tiết thêm hoặc thông báo lỗi
    CONSTRAINT fk_partition_history_config FOREIGN KEY (schema_name, table_name) REFERENCES partitioning.config(schema_name, table_name) ON DELETE CASCADE -- Tham chiếu đến config
);

COMMENT ON TABLE partitioning.history IS 'Ghi lại lịch sử các hành động liên quan đến việc tạo, sửa, xóa, lưu trữ các partition.';
COMMENT ON COLUMN partitioning.history.partition_name IS 'Tên của partition bị ảnh hưởng, hoặc tên bảng cha nếu hành động áp dụng cho cả bảng.';
COMMENT ON COLUMN partitioning.history.action IS 'Hành động được thực hiện trên partition/bảng.';
COMMENT ON COLUMN partitioning.history.status IS 'Trạng thái thực hiện hành động.';
COMMENT ON COLUMN partitioning.history.details IS 'Thông tin chi tiết hoặc thông báo lỗi.';

-- Index cho bảng history để tra cứu
CREATE INDEX IF NOT EXISTS idx_partitioning_history_table ON partitioning.history(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_action ON partitioning.history(action);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_timestamp ON partitioning.history(action_timestamp);

\echo '-> Hoàn thành tạo bảng cho ministry_of_public_security.'

-- ============================================================================
-- 2. TẠO BẢNG CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo '-> Tạo bảng quản lý phân vùng cho ministry_of_justice...'
\connect ministry_of_justice

-- Tạo schema partitioning nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BTP] Schema chứa cấu hình, lịch sử và hàm quản lý phân vùng dữ liệu';

-- Bảng lưu cấu hình phân vùng cho từng bảng (Tương tự BCA)
CREATE TABLE IF NOT EXISTS partitioning.config (
    config_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL CHECK (partition_type IN ('NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER')),
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
COMMENT ON TABLE partitioning.config IS 'Lưu trữ cấu hình phân vùng cho các bảng trong database này.';

-- Bảng lưu lịch sử các thao tác phân vùng (Tương tự BCA)
CREATE TABLE IF NOT EXISTS partitioning.history (
    history_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(200) NOT NULL,
    action VARCHAR(50) NOT NULL CHECK (action IN ('CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION', 'ARCHIVE_START', 'ARCHIVE_PARTITION', 'ARCHIVED', 'ARCHIVE_COMPLETE', 'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'ERROR', 'CONFIG_UPDATE', 'INIT', 'COMPLETE')),
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Success' CHECK (status IN ('Success', 'Failed', 'Running', 'Skipped')),
    affected_rows BIGINT,
    duration_ms BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    details TEXT,
    CONSTRAINT fk_partition_history_config FOREIGN KEY (schema_name, table_name) REFERENCES partitioning.config(schema_name, table_name) ON DELETE CASCADE
);
COMMENT ON TABLE partitioning.history IS 'Ghi lại lịch sử các hành động liên quan đến việc tạo, sửa, xóa, lưu trữ các partition.';

-- Index cho bảng history
CREATE INDEX IF NOT EXISTS idx_partitioning_history_table ON partitioning.history(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_action ON partitioning.history(action);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_timestamp ON partitioning.history(action_timestamp);

\echo '-> Hoàn thành tạo bảng cho ministry_of_justice.'

-- ============================================================================
-- 3. TẠO BẢNG CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo '-> Tạo bảng quản lý phân vùng cho national_citizen_central_server...'
\connect national_citizen_central_server

-- Tạo schema partitioning nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-TT] Schema chứa cấu hình, lịch sử và hàm quản lý phân vùng dữ liệu';

-- Bảng lưu cấu hình phân vùng cho từng bảng (Tương tự BCA)
CREATE TABLE IF NOT EXISTS partitioning.config (
    config_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_type VARCHAR(20) NOT NULL CHECK (partition_type IN ('NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER')),
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
COMMENT ON TABLE partitioning.config IS 'Lưu trữ cấu hình phân vùng cho các bảng trong database này.';

-- Bảng lưu lịch sử các thao tác phân vùng (Tương tự BCA)
CREATE TABLE IF NOT EXISTS partitioning.history (
    history_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(200) NOT NULL,
    action VARCHAR(50) NOT NULL CHECK (action IN ('CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION', 'ARCHIVE_START', 'ARCHIVE_PARTITION', 'ARCHIVED', 'ARCHIVE_COMPLETE', 'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'ERROR', 'CONFIG_UPDATE', 'INIT', 'COMPLETE')),
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Success' CHECK (status IN ('Success', 'Failed', 'Running', 'Skipped')),
    affected_rows BIGINT,
    duration_ms BIGINT,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    details TEXT,
    CONSTRAINT fk_partition_history_config FOREIGN KEY (schema_name, table_name) REFERENCES partitioning.config(schema_name, table_name) ON DELETE CASCADE
);
COMMENT ON TABLE partitioning.history IS 'Ghi lại lịch sử các hành động liên quan đến việc tạo, sửa, xóa, lưu trữ các partition.';

-- Index cho bảng history
CREATE INDEX IF NOT EXISTS idx_partitioning_history_table ON partitioning.history(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_action ON partitioning.history(action);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_timestamp ON partitioning.history(action_timestamp);

\echo '-> Hoàn thành tạo bảng cho national_citizen_central_server.'

\echo '*** HOÀN THÀNH TẠO CÁC BẢNG QUẢN LÝ PHÂN VÙNG ***'
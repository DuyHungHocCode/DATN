-- File: ministry_of_public_security/schemas/partitioning.sql
-- Description: Tạo các bảng hỗ trợ quản lý phân vùng dữ liệu
--              trong schema 'partitioning' của database Bộ Công an.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Script tạo schema 'partitioning'.
-- =============================================================================

\echo '--> Tạo các bảng trong schema partitioning cho ministry_of_public_security...'

-- Kết nối tới database của Bộ Công an (nếu chạy file riêng lẻ)
\connect ministry_of_public_security

BEGIN;

-- Tạo schema nếu chưa tồn tại (để đảm bảo)
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BCA] Schema chứa cấu hình, lịch sử và hàm quản lý phân vùng dữ liệu';

-- 1. Bảng partitioning.config: Lưu cấu hình phân vùng cho từng bảng
\echo '    -> Tạo bảng partitioning.config...'
DROP TABLE IF EXISTS partitioning.config CASCADE;
CREATE TABLE partitioning.config (
    config_id SERIAL PRIMARY KEY,                     -- Khóa chính tự tăng
    schema_name VARCHAR(100) NOT NULL,                -- Schema của bảng được phân vùng
    table_name VARCHAR(100) NOT NULL,                 -- Tên bảng được phân vùng
    partition_type VARCHAR(20) NOT NULL             -- Kiểu phân vùng: 'NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER'...
        CHECK (partition_type IN ('NESTED', 'REGION', 'PROVINCE', 'RANGE', 'LIST', 'OTHER')),
    partition_columns TEXT NOT NULL,                  -- Danh sách cột dùng để phân vùng (phân tách bởi dấu phẩy nếu nhiều cột)
    partition_interval VARCHAR(100),                  -- Khoảng thời gian cho RANGE partitioning (e.g., '1 month', '1 day') - Dùng cho audit_log
    retention_period VARCHAR(100),                    -- Thời gian lưu giữ dữ liệu trước khi archive/drop (e.g., '5 years', '36 months')
    premake INTEGER DEFAULT 4,                        -- Số lượng partition tạo trước cho pg_partman (nếu dùng cho audit_log)
    is_active BOOLEAN DEFAULT TRUE,                   -- Phân vùng này có đang được quản lý tự động không?
    use_pg_partman BOOLEAN DEFAULT FALSE,             -- Có sử dụng pg_partman để quản lý không? (vd: cho audit_log)
    notes TEXT,                                       -- Ghi chú thêm
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_partition_config UNIQUE (schema_name, table_name) -- Đảm bảo mỗi bảng chỉ có 1 cấu hình
);

COMMENT ON TABLE partitioning.config IS '[QLDCQG-BCA] Lưu trữ cấu hình phân vùng cho các bảng trong database này.';
COMMENT ON COLUMN partitioning.config.schema_name IS 'Schema chứa bảng được phân vùng.';
COMMENT ON COLUMN partitioning.config.table_name IS 'Tên bảng được phân vùng.';
COMMENT ON COLUMN partitioning.config.partition_type IS 'Loại chiến lược phân vùng chính (NESTED, REGION, PROVINCE, RANGE, LIST...).';
COMMENT ON COLUMN partitioning.config.partition_columns IS 'Các cột được sử dụng làm khóa phân vùng (cách nhau bởi dấu phẩy).';
COMMENT ON COLUMN partitioning.config.partition_interval IS 'Khoảng thời gian cho phân vùng RANGE (ví dụ: 1 month, 1 day).';
COMMENT ON COLUMN partitioning.config.retention_period IS 'Thời gian dữ liệu được giữ lại trước khi lưu trữ/xóa (ví dụ: 5 years).';
COMMENT ON COLUMN partitioning.config.premake IS 'Số lượng partition tạo trước cho pg_partman (nếu dùng).';
COMMENT ON COLUMN partitioning.config.is_active IS 'Cấu hình này có đang được áp dụng và quản lý tự động không?';
COMMENT ON COLUMN partitioning.config.use_pg_partman IS 'Có sử dụng pg_partman cho việc tạo/bảo trì partition không?';


-- 2. Bảng partitioning.history: Lưu lịch sử các thao tác phân vùng
\echo '    -> Tạo bảng partitioning.history...'
DROP TABLE IF EXISTS partitioning.history CASCADE;
CREATE TABLE partitioning.history (
    history_id BIGSERIAL PRIMARY KEY,                 -- Dùng BIGSERIAL vì có thể có nhiều log
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    partition_name VARCHAR(200) NOT NULL,             -- Tên của partition cụ thể bị ảnh hưởng, hoặc tên bảng cha
    action VARCHAR(50) NOT NULL                     -- Hành động: CREATE_PARTITION, ATTACH_PARTITION, DETACH_PARTITION, DROP_PARTITION, REPARTITIONED, MOVE_DATA, CREATE_INDEX, ERROR, CONFIG_UPDATE, INIT, COMPLETE...
        CHECK (action IN ('CREATE_PARTITION', 'ATTACH_PARTITION', 'DETACH_PARTITION', 'DROP_PARTITION',
                          'ARCHIVE_START', 'ARCHIVE_PARTITION', 'ARCHIVED', 'ARCHIVE_COMPLETE',
                          'REPARTITIONED', 'MOVE_DATA', 'CREATE_INDEX', 'ERROR', 'CONFIG_UPDATE', 'INIT', 'COMPLETE')),
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Success'             -- Trạng thái: 'Success', 'Failed', 'Running', 'Skipped'
        CHECK (status IN ('Success', 'Failed', 'Running', 'Skipped')),
    affected_rows BIGINT,                             -- Số dòng bị ảnh hưởng (nếu có)
    duration_ms BIGINT,                               -- Thời gian thực hiện (milliseconds, nếu đo được)
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,   -- User hoặc process thực hiện
    details TEXT,                                     -- Chi tiết thêm hoặc thông báo lỗi
    -- Tham chiếu đến bảng config để liên kết log với cấu hình
    CONSTRAINT fk_partition_history_config FOREIGN KEY (schema_name, table_name)
        REFERENCES partitioning.config(schema_name, table_name) ON DELETE CASCADE
);

COMMENT ON TABLE partitioning.history IS '[QLDCQG-BCA] Ghi lại lịch sử các hành động liên quan đến việc tạo, sửa, xóa, lưu trữ các partition trong database này.';
COMMENT ON COLUMN partitioning.history.partition_name IS 'Tên của partition bị ảnh hưởng, hoặc tên bảng cha nếu hành động áp dụng cho cả bảng.';
COMMENT ON COLUMN partitioning.history.action IS 'Hành động được thực hiện trên partition/bảng.';
COMMENT ON COLUMN partitioning.history.status IS 'Trạng thái thực hiện hành động.';
COMMENT ON COLUMN partitioning.history.details IS 'Thông tin chi tiết hoặc thông báo lỗi.';

-- Index cho bảng history để tra cứu hiệu quả
CREATE INDEX IF NOT EXISTS idx_partitioning_history_table ON partitioning.history(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_action ON partitioning.history(action);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_timestamp ON partitioning.history(action_timestamp);
CREATE INDEX IF NOT EXISTS idx_partitioning_history_status ON partitioning.history(status);

COMMIT;

\echo '-> Hoàn thành tạo các bảng trong schema partitioning cho ministry_of_public_security.'

-- TODO (Các bước tiếp theo liên quan đến schema này):
-- 1. Functions: Tạo các hàm quản lý phân vùng (trong thư mục `partitioning/`) sẽ sử dụng các bảng này.
-- 2. Configuration: Nạp dữ liệu cấu hình ban đầu vào bảng `partitioning.config` cho các bảng cần phân vùng.
-- 3. Permissions: Cấp quyền phù hợp trên các bảng này cho các role quản trị hoặc role thực thi phân vùng (trong script `02_security/02_permissions.sql`).
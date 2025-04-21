-- =============================================================================
-- File: ministry_of_justice/schemas/audit.sql
-- Description: Tạo bảng audit_log để ghi nhật ký thay đổi dữ liệu
--              trong schema 'audit' của database Bộ Tư pháp (BTP).
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Script tạo schema 'audit' (trong file 00_init/02_create_schemas.sql).
-- - Script tạo ENUM 'cdc_operation_type' (trong file 01_common/02_enum.sql).
-- - Extension 'pg_partman' (nếu dùng để quản lý partition theo thời gian).
-- =============================================================================

\echo '--> Tạo bảng audit.audit_log cho ministry_of_justice...'

-- Kết nối tới database của Bộ Tư pháp (nếu chạy file riêng lẻ)
\connect ministry_of_justice

BEGIN;

-- Tạo schema nếu chưa tồn tại (để đảm bảo an toàn nếu script schema chưa chạy)
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BTP] Schema chứa dữ liệu nhật ký thay đổi (audit log)';

-- Xóa bảng nếu tồn tại để tạo lại (đảm bảo idempotency)
DROP TABLE IF EXISTS audit.audit_log CASCADE;

-- Tạo bảng audit_log với cấu trúc phân vùng theo thời gian (RANGE)
-- Việc tạo các partition con cụ thể (vd: theo tháng) sẽ được quản lý bởi
-- pg_partman (nếu được cấu hình trong partitioning.config và chạy job) hoặc script tùy chỉnh.
CREATE TABLE audit.audit_log (
    log_id BIGSERIAL NOT NULL,                      -- Khóa chính tự tăng của log (dùng BIGSERIAL vì bảng có thể rất lớn)
    action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(), -- Thời điểm hành động xảy ra (Cột phân vùng)
    schema_name TEXT NOT NULL,                      -- Schema của bảng bị thay đổi (vd: 'justice')
    table_name TEXT NOT NULL,                       -- Tên bảng bị thay đổi (vd: 'birth_certificate')
    operation cdc_operation_type NOT NULL,          -- Loại hành động (INSERT, UPDATE, DELETE - ENUM)
    session_user_name TEXT DEFAULT current_user,    -- User database thực hiện hành động
    application_name TEXT DEFAULT current_setting('application_name'), -- Tên ứng dụng kết nối (vd: 'AppBTP_API')
    client_addr INET DEFAULT inet_client_addr(),    -- Địa chỉ IP của client
    client_port INTEGER DEFAULT inet_client_port(), -- Cổng của client
    transaction_id BIGINT DEFAULT txid_current(),   -- ID của transaction chứa thay đổi
    statement_only BOOLEAN NOT NULL DEFAULT FALSE,  -- TRUE nếu chỉ log câu lệnh (cho TRUNCATE), FALSE nếu log dữ liệu hàng
    row_data JSONB,                                 -- Dữ liệu cũ của hàng (cho UPDATE, DELETE) - dạng JSONB
    changed_fields JSONB,                           -- Các trường đã thay đổi và giá trị mới (cho UPDATE) - dạng JSONB
    query TEXT,                                     -- Câu lệnh SQL gây ra thay đổi (nếu trigger có thể lấy được)

    -- Ràng buộc Khóa chính (bao gồm cột phân vùng để tối ưu)
    CONSTRAINT pk_audit_log PRIMARY KEY (log_id, action_tstamp)

) PARTITION BY RANGE (action_tstamp); -- Khai báo phân vùng theo RANGE thời gian

-- Comments mô tả bảng và các cột quan trọng
COMMENT ON TABLE audit.audit_log IS '[QLDCQG-BTP] Bảng ghi nhật ký chi tiết các thay đổi dữ liệu (INSERT, UPDATE, DELETE) trên các bảng được theo dõi trong database Bộ Tư pháp.';
COMMENT ON COLUMN audit.audit_log.log_id IS 'ID tự tăng duy nhất của mỗi bản ghi log.';
COMMENT ON COLUMN audit.audit_log.action_tstamp IS 'Thời điểm chính xác khi hành động thay đổi dữ liệu xảy ra (Cột phân vùng).';
COMMENT ON COLUMN audit.audit_log.schema_name IS 'Tên schema của bảng có dữ liệu bị thay đổi.';
COMMENT ON COLUMN audit.audit_log.table_name IS 'Tên bảng có dữ liệu bị thay đổi.';
COMMENT ON COLUMN audit.audit_log.operation IS 'Loại hành động (INSERT, UPDATE, DELETE).';
COMMENT ON COLUMN audit.audit_log.session_user_name IS 'Tên user database thực hiện hành động.';
COMMENT ON COLUMN audit.audit_log.application_name IS 'Tên ứng dụng được đặt khi kết nối (vd: AppBTP_API, psql).';
COMMENT ON COLUMN audit.audit_log.client_addr IS 'Địa chỉ IP của client thực hiện thay đổi.';
COMMENT ON COLUMN audit.audit_log.transaction_id IS 'ID của transaction chứa hành động thay đổi.';
COMMENT ON COLUMN audit.audit_log.statement_only IS 'TRUE nếu chỉ log câu lệnh (vd: TRUNCATE), FALSE nếu log dữ liệu hàng.';
COMMENT ON COLUMN audit.audit_log.row_data IS 'Dữ liệu cũ của hàng dưới dạng JSONB (cho UPDATE, DELETE).';
COMMENT ON COLUMN audit.audit_log.changed_fields IS 'Các trường thay đổi và giá trị mới dưới dạng JSONB (cho UPDATE).';
COMMENT ON COLUMN audit.audit_log.query IS 'Câu lệnh SQL gốc gây ra thay đổi (nếu có thể ghi lại).';

-- Indexes cho bảng cha (sẽ được kế thừa bởi các partition con)
-- Index trên các cột thường dùng để truy vấn log
CREATE INDEX IF NOT EXISTS idx_audit_log_action_tstamp ON audit.audit_log(action_tstamp); -- Cột phân vùng luôn cần index
CREATE INDEX IF NOT EXISTS idx_audit_log_schema_table ON audit.audit_log(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_operation ON audit.audit_log(operation);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit.audit_log(session_user_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_app ON audit.audit_log(application_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_txid ON audit.audit_log(transaction_id);
-- Index GIN trên dữ liệu JSONB để tìm kiếm bên trong (nếu cần)
CREATE INDEX IF NOT EXISTS idx_audit_log_row_data_gin ON audit.audit_log USING gin (row_data jsonb_path_ops); -- Sử dụng jsonb_path_ops để tối ưu hơn
CREATE INDEX IF NOT EXISTS idx_audit_log_changed_fields_gin ON audit.audit_log USING gin (changed_fields jsonb_path_ops); -- Sử dụng jsonb_path_ops

COMMIT;

\echo '-> Hoàn thành tạo bảng audit.audit_log cho ministry_of_justice.'

-- TODO (Các bước tiếp theo liên quan đến bảng này):
-- 1. Partition Management:
--    - Cấu hình pg_partman (nếu dùng) hoặc tạo script tùy chỉnh để tự động tạo các partition con theo tháng/ngày cho bảng audit_log. Cần cập nhật partitioning.config cho bảng này.
--    - Thiết lập job (pg_cron hoặc Airflow) để chạy việc tạo partition mới và xóa/archive partition cũ định kỳ dựa trên retention_period trong config.
-- 2. Trigger Function: Tạo hoặc đảm bảo tồn tại hàm trigger `audit.if_modified_func()` (trong thư mục `ministry_of_justice/triggers/audit_triggers.sql`) để ghi dữ liệu vào bảng này. Hàm này cần giống với hàm bên BCA.
-- 3. Attach Triggers: Gắn trigger `audit.if_modified_func()` vào các bảng cần theo dõi trong schema 'justice' (ví dụ: birth_certificate, death_certificate, marriage...) (trong thư mục `ministry_of_justice/triggers/audit_triggers.sql`).
-- 4. Permissions: Cấp quyền phù hợp trên bảng này cho role quản trị (justice_admin) và có thể là role đọc đặc biệt (trong script `02_security/02_permissions.sql`). Các role ứng dụng thông thường (reader/writer) không nên có quyền ghi trực tiếp vào bảng này.
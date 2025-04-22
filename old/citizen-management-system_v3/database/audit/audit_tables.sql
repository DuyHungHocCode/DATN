-- =============================================================================
-- File: database/schemas/audit/audit_log_table.sql
-- Description: Định nghĩa cấu trúc bảng audit_log để ghi lại lịch sử thay đổi
--              dữ liệu trong hệ thống QLDCQG.
-- Version: 1.0
--
-- Chức năng chính:
-- 1. Tạo bảng `audit.audit_log` để lưu trữ thông tin về các thao tác
--    INSERT, UPDATE, DELETE trên các bảng được theo dõi.
-- 2. Thiết lập phân vùng (partitioning) theo thời gian cho bảng audit_log
--    để quản lý hiệu quả dung lượng lưu trữ.
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO BẢNG AUDIT LOG ***'

-- ============================================================================
-- 1. TẠO BẢNG CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo '-> Tạo bảng audit_log cho ministry_of_public_security...'
\connect ministry_of_public_security

-- Tạo schema audit nếu chưa tồn tại (Thường đã được tạo bởi init/create_schemas.sql)
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BCA] Schema chứa dữ liệu nhật ký thay đổi (audit log)';

-- Bảng ghi log thay đổi dữ liệu
DROP TABLE IF EXISTS audit.audit_log CASCADE;
CREATE TABLE audit.audit_log (
    audit_log_id BIGSERIAL NOT NULL,                    -- ID tự tăng của log
    schema_name TEXT NOT NULL,                          -- Schema của bảng bị thay đổi
    table_name TEXT NOT NULL,                           -- Tên bảng bị thay đổi
    relid OID NOT NULL,                                 -- OID của bảng (ổn định hơn tên)
    session_user_name TEXT,                             -- Tên user thực hiện kết nối CSDL
    action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT transaction_timestamp(), -- Dấu thời gian của transaction
    transaction_id BIGINT,                              -- ID của transaction (nếu có)
    application_name TEXT,                              -- Tên ứng dụng kết nối (nếu được set)
    client_addr INET,                                   -- Địa chỉ IP của client
    client_port INTEGER,                                -- Port của client
    action CHAR(1) NOT NULL CHECK (action IN ('I', 'U', 'D', 'T')), -- Loại hành động: I=INSERT, U=UPDATE, D=DELETE, T=TRUNCATE
    row_data JSONB,                                     -- Dữ liệu cũ của hàng (cho UPDATE, DELETE)
    changed_fields JSONB,                               -- Dữ liệu mới (cho INSERT) hoặc chỉ các trường thay đổi (cho UPDATE)
    statement_only BOOLEAN NOT NULL DEFAULT FALSE,      -- TRUE nếu log này chỉ ghi nhận câu lệnh (TRUNCATE), không có row_data/changed_fields
    -- Khóa chính nên bao gồm cả cột phân vùng
    CONSTRAINT pk_audit_log PRIMARY KEY (audit_log_id, action_tstamp)

) PARTITION BY RANGE (action_tstamp); -- Phân vùng theo ngày tháng thực hiện

COMMENT ON TABLE audit.audit_log IS 'Bảng ghi lại lịch sử các thay đổi dữ liệu (INSERT, UPDATE, DELETE) trên các bảng được giám sát.';
COMMENT ON COLUMN audit.audit_log.audit_log_id IS 'ID duy nhất của bản ghi log.';
COMMENT ON COLUMN audit.audit_log.schema_name IS 'Schema của bảng có dữ liệu bị thay đổi.';
COMMENT ON COLUMN audit.audit_log.table_name IS 'Tên bảng có dữ liệu bị thay đổi.';
COMMENT ON COLUMN audit.audit_log.relid IS 'Object ID (OID) của bảng bị thay đổi.';
COMMENT ON COLUMN audit.audit_log.session_user_name IS 'Tên người dùng CSDL đã thực hiện thay đổi.';
COMMENT ON COLUMN audit.audit_log.action_tstamp IS 'Dấu thời gian bắt đầu của giao dịch thực hiện thay đổi (quan trọng nhất cho thứ tự).';
COMMENT ON COLUMN audit.audit_log.transaction_id IS 'ID của giao dịch PostgreSQL.';
COMMENT ON COLUMN audit.audit_log.application_name IS 'Tên ứng dụng (được đặt bởi client) thực hiện thay đổi.';
COMMENT ON COLUMN audit.audit_log.client_addr IS 'Địa chỉ IP của client thực hiện thay đổi.';
COMMENT ON COLUMN audit.audit_log.client_port IS 'Port của client thực hiện thay đổi.';
COMMENT ON COLUMN audit.audit_log.action IS 'Loại thao tác: I (INSERT), U (UPDATE), D (DELETE), T (TRUNCATE).';
COMMENT ON COLUMN audit.audit_log.row_data IS 'JSONB chứa dữ liệu của hàng TRƯỚC khi thay đổi (cho UPDATE và DELETE).';
COMMENT ON COLUMN audit.audit_log.changed_fields IS 'JSONB chứa dữ liệu của hàng MỚI (cho INSERT) hoặc chỉ các trường đã thay đổi (cho UPDATE).';
COMMENT ON COLUMN audit.audit_log.statement_only IS 'Đánh dấu TRUE cho các hành động như TRUNCATE không có dữ liệu hàng cụ thể.';
COMMENT ON COLUMN audit.audit_log.pk_audit_log IS 'Khóa chính bao gồm cả cột phân vùng thời gian.';

-- Tạo index trên bảng cha (sẽ được kế thừa bởi các partition con)
-- Index theo thời gian đã có trong PK
CREATE INDEX IF NOT EXISTS idx_audit_log_table_relid ON audit.audit_log(relid);
CREATE INDEX IF NOT EXISTS idx_audit_log_schema_table ON audit.audit_log(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_txid ON audit.audit_log(transaction_id) WHERE transaction_id IS NOT NULL;
-- Cân nhắc tạo index GIN trên row_data hoặc changed_fields nếu cần tìm kiếm sâu trong JSONB
-- CREATE INDEX idx_audit_log_row_data_gin ON audit.audit_log USING gin (row_data jsonb_path_ops);

-- Tạo partition con đầu tiên làm ví dụ (hoặc để pg_partman quản lý)
-- Ví dụ tạo partition cho tháng hiện tại (cần chạy lại hàng tháng hoặc dùng pg_partman)
-- DO $$
-- DECLARE
--   current_month_start date := date_trunc('month', current_date);
--   next_month_start date := current_month_start + interval '1 month';
--   partition_name text := 'audit_log_' || to_char(current_month_start, 'YYYYMM');
-- BEGIN
--   EXECUTE format('CREATE TABLE IF NOT EXISTS audit.%I PARTITION OF audit.audit_log FOR VALUES FROM (%L) TO (%L)',
--                  partition_name, current_month_start, next_month_start);
-- END $$;

\echo '-> Hoàn thành tạo bảng audit_log cho ministry_of_public_security.'

-- ============================================================================
-- 2. TẠO BẢNG CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo '-> Tạo bảng audit_log cho ministry_of_justice...'
\connect ministry_of_justice

-- Tạo schema audit nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BTP] Schema chứa dữ liệu nhật ký thay đổi (audit log)';

-- Bảng ghi log thay đổi dữ liệu (Tương tự BCA)
DROP TABLE IF EXISTS audit.audit_log CASCADE;
CREATE TABLE audit.audit_log (
    audit_log_id BIGSERIAL NOT NULL,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    relid OID NOT NULL,
    session_user_name TEXT,
    action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT transaction_timestamp(),
    transaction_id BIGINT,
    application_name TEXT,
    client_addr INET,
    client_port INTEGER,
    action CHAR(1) NOT NULL CHECK (action IN ('I', 'U', 'D', 'T')),
    row_data JSONB,
    changed_fields JSONB,
    statement_only BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_audit_log PRIMARY KEY (audit_log_id, action_tstamp)
) PARTITION BY RANGE (action_tstamp);
COMMENT ON TABLE audit.audit_log IS 'Bảng ghi lại lịch sử các thay đổi dữ liệu (INSERT, UPDATE, DELETE) trên các bảng được giám sát.';

-- Indexes (Tương tự BCA)
CREATE INDEX IF NOT EXISTS idx_audit_log_table_relid ON audit.audit_log(relid);
CREATE INDEX IF NOT EXISTS idx_audit_log_schema_table ON audit.audit_log(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_txid ON audit.audit_log(transaction_id) WHERE transaction_id IS NOT NULL;

\echo '-> Hoàn thành tạo bảng audit_log cho ministry_of_justice.'

-- ============================================================================
-- 3. TẠO BẢNG CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo '-> Tạo bảng audit_log cho national_citizen_central_server...'
\connect national_citizen_central_server

-- Tạo schema audit nếu chưa tồn tại
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-TT] Schema chứa dữ liệu nhật ký thay đổi (audit log)';

-- Bảng ghi log thay đổi dữ liệu (Tương tự BCA)
DROP TABLE IF EXISTS audit.audit_log CASCADE;
CREATE TABLE audit.audit_log (
    audit_log_id BIGSERIAL NOT NULL,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    relid OID NOT NULL,
    session_user_name TEXT,
    action_tstamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT transaction_timestamp(),
    transaction_id BIGINT,
    application_name TEXT,
    client_addr INET,
    client_port INTEGER,
    action CHAR(1) NOT NULL CHECK (action IN ('I', 'U', 'D', 'T')),
    row_data JSONB,
    changed_fields JSONB,
    statement_only BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_audit_log PRIMARY KEY (audit_log_id, action_tstamp)
) PARTITION BY RANGE (action_tstamp);
COMMENT ON TABLE audit.audit_log IS 'Bảng ghi lại lịch sử các thay đổi dữ liệu (INSERT, UPDATE, DELETE) trên các bảng được giám sát.';

-- Indexes (Tương tự BCA)
CREATE INDEX IF NOT EXISTS idx_audit_log_table_relid ON audit.audit_log(relid);
CREATE INDEX IF NOT EXISTS idx_audit_log_schema_table ON audit.audit_log(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_txid ON audit.audit_log(transaction_id) WHERE transaction_id IS NOT NULL;

\echo '-> Hoàn thành tạo bảng audit_log cho national_citizen_central_server.'

\echo '*** HOÀN THÀNH TẠO BẢNG AUDIT LOG ***'
\echo 'Lưu ý: Cần tạo trigger để ghi dữ liệu và tạo các partition con theo thời gian.'
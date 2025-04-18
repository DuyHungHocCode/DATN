-- =============================================================================
-- File: database/schemas/central_server/sync_tables.sql
-- Description: Tạo các bảng quản lý đồng bộ dữ liệu giữa các hệ thống
-- Version: 1.0
-- 
-- Các bảng chính:
-- 1. sync_config: Cấu hình đồng bộ cho từng bảng/schema
-- 2. sync_mapping: Ánh xạ cấu trúc dữ liệu giữa các hệ thống
-- 3. sync_batch: Lô đồng bộ dữ liệu
-- 4. sync_batch_detail: Chi tiết các bản ghi trong lô đồng bộ
-- 5. sync_conflict: Quản lý xung đột dữ liệu
-- 6. sync_resolution: Lịch sử giải quyết xung đột
-- 7. sync_log: Nhật ký hoạt động đồng bộ
-- =============================================================================

\echo 'Tạo các bảng quản lý đồng bộ dữ liệu cho máy chủ trung tâm...'
\connect national_citizen_central_server

BEGIN;

-- =============================================================================
-- 1. BẢNG CẤU HÌNH ĐỒNG BỘ (SYNC_CONFIG)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_config CASCADE;
CREATE TABLE central.sync_config (
    config_id SERIAL PRIMARY KEY,
    source_system VARCHAR(50) NOT NULL, -- 'Bộ Công an', 'Bộ Tư pháp', 'Trung tâm'
    target_system VARCHAR(50) NOT NULL, -- 'Bộ Công an', 'Bộ Tư pháp', 'Trung tâm'
    source_schema VARCHAR(50) NOT NULL, -- Schema nguồn
    source_table VARCHAR(100) NOT NULL, -- Bảng nguồn
    target_schema VARCHAR(50) NOT NULL, -- Schema đích
    target_table VARCHAR(100) NOT NULL, -- Bảng đích
    primary_key_columns TEXT NOT NULL, -- Danh sách cột khóa chính (phân cách bởi dấu phẩy)
    sync_columns TEXT, -- Các cột cần đồng bộ (NULL = tất cả)
    excluded_columns TEXT, -- Các cột loại trừ (ưu tiên hơn sync_columns)
    conflict_resolution_strategy VARCHAR(50) NOT NULL DEFAULT 'SOURCE_WINS', -- SOURCE_WINS, TARGET_WINS, NEWER_WINS, MANUAL
    sync_priority sync_priority NOT NULL DEFAULT 'Trung bình', -- Mức độ ưu tiên đồng bộ
    sync_frequency INTERVAL NOT NULL DEFAULT '1 hour', -- Tần suất đồng bộ
    batch_size INTEGER NOT NULL DEFAULT 1000, -- Kích thước lô đồng bộ
    enabled BOOLEAN NOT NULL DEFAULT TRUE, -- Trạng thái bật/tắt đồng bộ
    bidirectional BOOLEAN NOT NULL DEFAULT FALSE, -- Hai chiều hay một chiều
    initial_load_complete BOOLEAN NOT NULL DEFAULT FALSE, -- Đã hoàn thành tải ban đầu chưa
    filter_condition TEXT, -- Điều kiện WHERE để lọc dữ liệu cần đồng bộ
    transformation_script TEXT, -- Script biến đổi dữ liệu (JavaScript hoặc SQL)
    description TEXT,
    last_sync_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_config_source_system ON central.sync_config(source_system);
CREATE INDEX idx_sync_config_target_system ON central.sync_config(target_system);
CREATE INDEX idx_sync_config_source_table ON central.sync_config(source_schema, source_table);
CREATE INDEX idx_sync_config_target_table ON central.sync_config(target_schema, target_table);
CREATE INDEX idx_sync_config_enabled ON central.sync_config(enabled);
CREATE INDEX idx_sync_config_priority ON central.sync_config(sync_priority);

COMMENT ON TABLE central.sync_config IS 'Cấu hình đồng bộ cho từng cặp bảng giữa các hệ thống';

-- =============================================================================
-- 2. BẢNG ÁNH XẠ CẤU TRÚC (SYNC_MAPPING)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_mapping CASCADE;
CREATE TABLE central.sync_mapping (
    mapping_id SERIAL PRIMARY KEY,
    config_id INTEGER NOT NULL REFERENCES central.sync_config(config_id) ON DELETE CASCADE,
    source_column VARCHAR(100) NOT NULL, -- Tên cột nguồn
    target_column VARCHAR(100) NOT NULL, -- Tên cột đích
    data_transformation TEXT, -- Biến đổi dữ liệu (ví dụ: CAST, FORMAT)
    is_key_column BOOLEAN DEFAULT FALSE, -- Là cột khóa để xác định bản ghi
    is_updated_at_column BOOLEAN DEFAULT FALSE, -- Là cột theo dõi cập nhật
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (config_id, source_column)
);

CREATE INDEX idx_sync_mapping_config_id ON central.sync_mapping(config_id);
CREATE INDEX idx_sync_mapping_key_column ON central.sync_mapping(config_id, is_key_column);

COMMENT ON TABLE central.sync_mapping IS 'Ánh xạ cấu trúc dữ liệu giữa các bảng của các hệ thống';

-- =============================================================================
-- 3. BẢNG LÔ ĐỒNG BỘ (SYNC_BATCH)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_batch CASCADE;
CREATE TABLE central.sync_batch (
    batch_id SERIAL PRIMARY KEY,
    config_id INTEGER NOT NULL REFERENCES central.sync_config(config_id),
    batch_type VARCHAR(50) NOT NULL, -- 'INITIAL_LOAD', 'INCREMENTAL', 'FULL_REFRESH', 'CDC'
    batch_status sync_status NOT NULL DEFAULT 'Chưa đồng bộ', -- Trạng thái đồng bộ
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP WITH TIME ZONE,
    total_records INTEGER DEFAULT 0, -- Tổng số bản ghi trong lô
    processed_records INTEGER DEFAULT 0, -- Số bản ghi đã xử lý
    successful_records INTEGER DEFAULT 0, -- Số bản ghi thành công
    failed_records INTEGER DEFAULT 0, -- Số bản ghi thất bại
    conflict_records INTEGER DEFAULT 0, -- Số bản ghi xung đột
    last_processed_key TEXT, -- Khóa cuối cùng được xử lý (để tiếp tục nếu lỗi)
    error_message TEXT, -- Thông báo lỗi nếu có
    retry_count INTEGER DEFAULT 0, -- Số lần thử lại
    next_retry_time TIMESTAMP WITH TIME ZONE, -- Thời gian thử lại tiếp theo
    source_checkpoint TEXT, -- Checkpoint ở hệ thống nguồn (ví dụ: SCN, LSN)
    target_checkpoint TEXT, -- Checkpoint ở hệ thống đích
    kafka_topic VARCHAR(200), -- Topic Kafka sử dụng cho lô này
    kafka_partition INTEGER, -- Partition Kafka
    kafka_offset_start BIGINT, -- Offset bắt đầu
    kafka_offset_end BIGINT, -- Offset kết thúc
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_batch_config_id ON central.sync_batch(config_id);
CREATE INDEX idx_sync_batch_batch_status ON central.sync_batch(batch_status);
CREATE INDEX idx_sync_batch_start_time ON central.sync_batch(start_time);
CREATE INDEX idx_sync_batch_end_time ON central.sync_batch(end_time);
CREATE INDEX idx_sync_batch_kafka_topic ON central.sync_batch(kafka_topic);

COMMENT ON TABLE central.sync_batch IS 'Quản lý các lô đồng bộ dữ liệu';

-- =============================================================================
-- 4. BẢNG CHI TIẾT LÔ ĐỒNG BỘ (SYNC_BATCH_DETAIL)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_batch_detail CASCADE;
CREATE TABLE central.sync_batch_detail (
    detail_id SERIAL PRIMARY KEY,
    batch_id INTEGER NOT NULL REFERENCES central.sync_batch(batch_id) ON DELETE CASCADE,
    record_key TEXT NOT NULL, -- Khóa của bản ghi (có thể là composite)
    source_data JSONB, -- Dữ liệu từ nguồn (dạng JSON)
    target_data JSONB, -- Dữ liệu hiện tại ở đích (nếu có)
    operation_type cdc_operation_type NOT NULL, -- Loại thao tác (INSERT, UPDATE, DELETE)
    sync_status sync_status NOT NULL DEFAULT 'Chưa đồng bộ', -- Trạng thái đồng bộ
    status_message TEXT, -- Thông báo trạng thái hoặc lỗi
    processed_at TIMESTAMP WITH TIME ZONE, -- Thời điểm xử lý
    retry_count INTEGER DEFAULT 0, -- Số lần thử lại
    has_conflict BOOLEAN DEFAULT FALSE, -- Có xung đột không
    conflict_id INTEGER, -- ID xung đột (nếu có)
    kafka_offset BIGINT, -- Offset Kafka
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_batch_detail_batch_id ON central.sync_batch_detail(batch_id);
CREATE INDEX idx_sync_batch_detail_record_key ON central.sync_batch_detail(record_key);
CREATE INDEX idx_sync_batch_detail_operation_type ON central.sync_batch_detail(operation_type);
CREATE INDEX idx_sync_batch_detail_sync_status ON central.sync_batch_detail(sync_status);
CREATE INDEX idx_sync_batch_detail_has_conflict ON central.sync_batch_detail(has_conflict);
CREATE INDEX idx_sync_batch_detail_conflict_id ON central.sync_batch_detail(conflict_id);

COMMENT ON TABLE central.sync_batch_detail IS 'Chi tiết các bản ghi trong lô đồng bộ';

-- =============================================================================
-- 5. BẢNG XUNG ĐỘT DỮ LIỆU (SYNC_CONFLICT)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_conflict CASCADE;
CREATE TABLE central.sync_conflict (
    conflict_id SERIAL PRIMARY KEY,
    config_id INTEGER NOT NULL REFERENCES central.sync_config(config_id),
    batch_id INTEGER REFERENCES central.sync_batch(batch_id),
    detail_id INTEGER REFERENCES central.sync_batch_detail(detail_id),
    record_key TEXT NOT NULL, -- Khóa của bản ghi
    conflict_type VARCHAR(50) NOT NULL, -- 'UPDATE_UPDATE', 'INSERT_INSERT', 'UPDATE_DELETE', 'DELETE_UPDATE'
    source_data JSONB NOT NULL, -- Dữ liệu từ nguồn
    target_data JSONB, -- Dữ liệu từ đích
    detection_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolution_status VARCHAR(50) DEFAULT 'Chưa giải quyết', -- 'Chưa giải quyết', 'Đã giải quyết', 'Bỏ qua'
    resolution_time TIMESTAMP WITH TIME ZONE,
    resolution_strategy VARCHAR(50), -- 'SOURCE_WINS', 'TARGET_WINS', 'MANUAL_MERGE', 'CUSTOM'
    resolved_by VARCHAR(100), -- Người giải quyết
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_conflict_config_id ON central.sync_conflict(config_id);
CREATE INDEX idx_sync_conflict_batch_id ON central.sync_conflict(batch_id);
CREATE INDEX idx_sync_conflict_record_key ON central.sync_conflict(record_key);
CREATE INDEX idx_sync_conflict_conflict_type ON central.sync_conflict(conflict_type);
CREATE INDEX idx_sync_conflict_resolution_status ON central.sync_conflict(resolution_status);

COMMENT ON TABLE central.sync_conflict IS 'Quản lý xung đột dữ liệu trong quá trình đồng bộ';

-- =============================================================================
-- 6. BẢNG GIẢI QUYẾT XUNG ĐỘT (SYNC_RESOLUTION)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_resolution CASCADE;
CREATE TABLE central.sync_resolution (
    resolution_id SERIAL PRIMARY KEY,
    conflict_id INTEGER NOT NULL REFERENCES central.sync_conflict(conflict_id) ON DELETE CASCADE,
    resolved_data JSONB NOT NULL, -- Dữ liệu sau khi giải quyết
    resolution_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolution_strategy VARCHAR(50) NOT NULL, -- 'SOURCE_WINS', 'TARGET_WINS', 'MANUAL_MERGE', 'CUSTOM'
    resolved_by VARCHAR(100) NOT NULL, -- Người giải quyết
    applied_to_source BOOLEAN DEFAULT FALSE, -- Đã áp dụng về nguồn chưa
    applied_to_target BOOLEAN DEFAULT FALSE, -- Đã áp dụng lên đích chưa
    source_apply_time TIMESTAMP WITH TIME ZONE, -- Thời điểm áp dụng về nguồn
    target_apply_time TIMESTAMP WITH TIME ZONE, -- Thời điểm áp dụng lên đích
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_resolution_conflict_id ON central.sync_resolution(conflict_id);
CREATE INDEX idx_sync_resolution_strategy ON central.sync_resolution(resolution_strategy);
CREATE INDEX idx_sync_resolution_resolved_by ON central.sync_resolution(resolved_by);

COMMENT ON TABLE central.sync_resolution IS 'Lịch sử giải quyết xung đột dữ liệu';

-- =============================================================================
-- 7. BẢNG NHẬT KÝ ĐỒNG BỘ (SYNC_LOG)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_log CASCADE;
CREATE TABLE central.sync_log (
    log_id SERIAL PRIMARY KEY,
    log_level VARCHAR(20) NOT NULL, -- 'INFO', 'WARNING', 'ERROR', 'DEBUG'
    source_system VARCHAR(50) NOT NULL,
    target_system VARCHAR(50) NOT NULL,
    source_schema VARCHAR(50),
    source_table VARCHAR(100),
    message TEXT NOT NULL,
    additional_info JSONB,
    batch_id INTEGER,
    record_key TEXT,
    exception_stack TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_log_level ON central.sync_log(log_level);
CREATE INDEX idx_sync_log_source_system ON central.sync_log(source_system);
CREATE INDEX idx_sync_log_source_table ON central.sync_log(source_schema, source_table);
CREATE INDEX idx_sync_log_batch_id ON central.sync_log(batch_id);
CREATE INDEX idx_sync_log_created_at ON central.sync_log(created_at);

COMMENT ON TABLE central.sync_log IS 'Nhật ký hoạt động đồng bộ dữ liệu';

-- =============================================================================
-- 8. BẢNG TRẠNG THÁI CONNECTOR KAFKA (KAFKA_CONNECTOR_STATUS)
-- =============================================================================
DROP TABLE IF EXISTS central.kafka_connector_status CASCADE;
CREATE TABLE central.kafka_connector_status (
    connector_id SERIAL PRIMARY KEY,
    connector_name VARCHAR(100) NOT NULL UNIQUE,
    connector_type kafka_connector_type NOT NULL,
    connector_status cdc_connector_status NOT NULL DEFAULT 'Khởi tạo',
    config JSONB NOT NULL, -- Cấu hình connector
    source_system VARCHAR(50) NOT NULL,
    target_system VARCHAR(50) NOT NULL,
    last_status_change TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_error TEXT,
    error_count INTEGER DEFAULT 0,
    restart_count INTEGER DEFAULT 0,
    last_restart_time TIMESTAMP WITH TIME ZONE,
    topics TEXT[], -- Danh sách các topic liên quan
    current_lag BIGINT, -- Độ trễ hiện tại
    health_status VARCHAR(20) DEFAULT 'Good', -- 'Good', 'Warning', 'Critical'
    monitored BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kafka_connector_status_name ON central.kafka_connector_status(connector_name);
CREATE INDEX idx_kafka_connector_status_type ON central.kafka_connector_status(connector_type);
CREATE INDEX idx_kafka_connector_status_status ON central.kafka_connector_status(connector_status);
CREATE INDEX idx_kafka_connector_status_health ON central.kafka_connector_status(health_status);

COMMENT ON TABLE central.kafka_connector_status IS 'Trạng thái các connector Kafka Connect';

-- =============================================================================
-- 9. BẢNG TRẠNG THÁI TOPIC KAFKA (KAFKA_TOPIC_STATUS)
-- =============================================================================
DROP TABLE IF EXISTS central.kafka_topic_status CASCADE;
CREATE TABLE central.kafka_topic_status (
    topic_id SERIAL PRIMARY KEY,
    topic_name VARCHAR(200) NOT NULL UNIQUE,
    topic_type kafka_topic_type NOT NULL,
    partition_count INTEGER NOT NULL DEFAULT 1,
    replication_factor INTEGER NOT NULL DEFAULT 1,
    message_count BIGINT DEFAULT 0,
    message_rate DECIMAL(12,2) DEFAULT 0, -- Messages per second
    byte_rate DECIMAL(12,2) DEFAULT 0, -- Bytes per second
    retention_bytes BIGINT,
    retention_ms BIGINT,
    cleanup_policy VARCHAR(50),
    is_compacted BOOLEAN DEFAULT FALSE,
    last_message_timestamp TIMESTAMP WITH TIME ZONE,
    health_status VARCHAR(20) DEFAULT 'Good', -- 'Good', 'Warning', 'Critical'
    monitored BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kafka_topic_status_name ON central.kafka_topic_status(topic_name);
CREATE INDEX idx_kafka_topic_status_type ON central.kafka_topic_status(topic_type);
CREATE INDEX idx_kafka_topic_status_health ON central.kafka_topic_status(health_status);

COMMENT ON TABLE central.kafka_topic_status IS 'Trạng thái các topic Kafka';

-- =============================================================================
-- 10. BẢNG LỊCH TRÌNH ĐỒNG BỘ (SYNC_SCHEDULE)
-- =============================================================================
DROP TABLE IF EXISTS central.sync_schedule CASCADE;
CREATE TABLE central.sync_schedule (
    schedule_id SERIAL PRIMARY KEY,
    config_id INTEGER NOT NULL REFERENCES central.sync_config(config_id) ON DELETE CASCADE,
    schedule_name VARCHAR(100) NOT NULL,
    cron_expression VARCHAR(100) NOT NULL, -- Biểu thức cron để lập lịch
    enabled BOOLEAN DEFAULT TRUE,
    last_run_time TIMESTAMP WITH TIME ZONE,
    next_run_time TIMESTAMP WITH TIME ZONE,
    run_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_schedule_config_id ON central.sync_schedule(config_id);
CREATE INDEX idx_sync_schedule_enabled ON central.sync_schedule(enabled);
CREATE INDEX idx_sync_schedule_next_run ON central.sync_schedule(next_run_time);

COMMENT ON TABLE central.sync_schedule IS 'Lịch trình đồng bộ dữ liệu tự động';

-- =============================================================================
-- FUNCTION CẬP NHẬT THỜI GIAN
-- =============================================================================

-- Function tự động cập nhật trường updated_at
CREATE OR REPLACE FUNCTION central.sync_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger cập nhật timestamp cho các bảng
CREATE TRIGGER update_sync_config_timestamp
BEFORE UPDATE ON central.sync_config
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_sync_mapping_timestamp
BEFORE UPDATE ON central.sync_mapping
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_sync_batch_timestamp
BEFORE UPDATE ON central.sync_batch
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_sync_batch_detail_timestamp
BEFORE UPDATE ON central.sync_batch_detail
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_sync_conflict_timestamp
BEFORE UPDATE ON central.sync_conflict
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_sync_resolution_timestamp
BEFORE UPDATE ON central.sync_resolution
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_kafka_connector_status_timestamp
BEFORE UPDATE ON central.kafka_connector_status
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_kafka_topic_status_timestamp
BEFORE UPDATE ON central.kafka_topic_status
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

CREATE TRIGGER update_sync_schedule_timestamp
BEFORE UPDATE ON central.sync_schedule
FOR EACH ROW EXECUTE FUNCTION central.sync_update_timestamp();

-- =============================================================================
-- DỮ LIỆU MẪU CẤU HÌNH ĐỒNG BỘ
-- =============================================================================

-- Dữ liệu mẫu cho bảng sync_config
INSERT INTO central.sync_config (
    source_system, target_system, source_schema, source_table, 
    target_schema, target_table, primary_key_columns, 
    conflict_resolution_strategy, sync_priority, sync_frequency, 
    batch_size, description
) VALUES
-- Đồng bộ công dân
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'citizen',
    'central', 'integrated_citizen', 'citizen_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    1000, 'Đồng bộ thông tin công dân từ Bộ Công an lên máy chủ trung tâm'
),
-- Đồng bộ căn cước công dân
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'identification_card',
    'central', 'integrated_citizen', 'card_id',
    'SOURCE_WINS', 'Cao', '30 minutes',
    1000, 'Đồng bộ thông tin CCCD từ Bộ Công an lên máy chủ trung tâm'
),
-- Đồng bộ hộ khẩu
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'household',
    'central', 'integrated_household', 'household_id',
    'SOURCE_WINS', 'Cao', '1 hour',
    500, 'Đồng bộ thông tin hộ khẩu từ Bộ Tư pháp lên máy chủ trung tâm'
),
-- Đồng bộ khai sinh
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'birth_certificate',
    'central', 'integrated_citizen', 'birth_certificate_id',
    'SOURCE_WINS', 'Cao', '1 hour',
    500, 'Đồng bộ thông tin khai sinh từ Bộ Tư pháp lên máy chủ trung tâm'
),
-- Đồng bộ khai tử
(
    'Bộ Tư pháp', 'Trung tâm', 'justice', 'death_certificate',
    'central', 'integrated_citizen', 'death_certificate_id',
    'SOURCE_WINS', 'Cao', '1 hour',
    500, 'Đồng bộ thông tin khai tử từ Bộ Tư pháp lên máy chủ trung tâm'
),
-- Đồng bộ dữ liệu sinh trắc học
(
    'Bộ Công an', 'Trung tâm', 'public_security', 'biometric_data',
    'central', 'integrated_citizen', 'biometric_id',
    'SOURCE_WINS', 'Trung bình', '2 hours',
    200, 'Đồng bộ dữ liệu sinh trắc học từ Bộ Công an lên máy chủ trung tâm'
);

COMMIT;

\echo 'Hoàn thành việc tạo các bảng đồng bộ dữ liệu cho hệ thống!'
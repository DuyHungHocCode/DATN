-- =============================================================================
-- File: national_citizen_central_server/triggers/audit_triggers.sql
-- Description: Tạo function trigger và gắn trigger để ghi nhật ký thay đổi dữ liệu
--              vào bảng audit.audit_log cho các bảng trong database Máy chủ Trung tâm (TT).
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Dependencies:
-- - Schema 'audit' và bảng 'audit.audit_log'.
-- - Các bảng cần được audit trong schema 'central' (và 'sync' nếu cần).
-- - ENUM 'cdc_operation_type'.
-- =============================================================================

\echo '--> Tạo function và trigger audit cho national_citizen_central_server...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
\connect national_citizen_central_server

BEGIN;

-- Đảm bảo schema audit tồn tại
CREATE SCHEMA IF NOT EXISTS audit;

-- ============================================================================
-- 1. TẠO TRIGGER FUNCTION (audit.if_modified_func) - GIỐNG HỆT BÊN BCA/BTP
--    Đảm bảo hàm này giống hệt hàm đã tạo trong DB BCA/BTP để có logic audit nhất quán.
-- ============================================================================
\echo '    -> Tạo hoặc thay thế function audit.if_modified_func()...';

CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $audit_trigger$
DECLARE
    audit_row audit.audit_log;
    include_values BOOLEAN;
    log_diffs BOOLEAN;
    h_old JSONB;
    h_new JSONB;
    excluded_cols TEXT[] = ARRAY[]::TEXT[];
    object_pk TEXT;
    primary_key_cols TEXT[];
    pk_col TEXT;
BEGIN
    -- Mặc định không log chi tiết giá trị (chỉ cấu trúc) trừ khi được chỉ định
    IF TG_ARGV[0] IS NOT NULL THEN
        include_values := TG_ARGV[0]::BOOLEAN;
    ELSE
        include_values := FALSE; -- Hoặc TRUE nếu muốn log giá trị mặc định
    END IF;

    -- Mặc định không log sự khác biệt (changed_fields) trừ khi được chỉ định
    IF TG_ARGV[1] IS NOT NULL THEN
        log_diffs := TG_ARGV[1]::BOOLEAN;
    ELSE
        log_diffs := FALSE; -- Hoặc TRUE nếu muốn log diff mặc định
    END IF;

    -- Lấy danh sách các cột cần loại trừ khỏi log (từ tham số thứ 3 trở đi)
    excluded_cols = TG_ARGV[2:array_upper(TG_ARGV, 1)];

    -- Tạo bản ghi audit cơ bản
    audit_row = ROW(
        nextval('audit.audit_log_log_id_seq'), -- log_id (Lấy từ sequence)
        clock_timestamp(),                     -- action_tstamp
        TG_TABLE_SCHEMA::TEXT,                 -- schema_name
        TG_TABLE_NAME::TEXT,                   -- table_name
        NULL,                                  -- operation (sẽ được gán)
        session_user::TEXT,                    -- session_user_name
        current_setting('application_name'),   -- application_name
        inet_client_addr(),                    -- client_addr
        inet_client_port(),                    -- client_port
        txid_current(),                        -- transaction_id
        current_query(),                       -- query (có thể không đầy đủ/chính xác)
        FALSE,                                 -- statement_only
        NULL,                                  -- row_data
        NULL                                   -- changed_fields
    );

    -- Xác định loại hành động (operation)
    IF (TG_OP = 'INSERT') THEN
        audit_row.operation = 'INSERT';
    ELSIF (TG_OP = 'UPDATE') THEN
        audit_row.operation = 'UPDATE';
    ELSIF (TG_OP = 'DELETE') THEN
        audit_row.operation = 'DELETE';
    ELSIF (TG_OP = 'TRUNCATE') THEN
        audit_row.operation = 'TRUNCATE';
        audit_row.statement_only = TRUE; -- TRUNCATE không có dữ liệu hàng
    END IF;

    -- Xử lý dữ liệu hàng (row_data, changed_fields)
    IF NOT audit_row.statement_only THEN
        IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
            -- Chuyển dữ liệu cũ thành JSONB, loại bỏ các cột được exclude
            BEGIN
                h_old = to_jsonb(OLD.*);
                IF array_length(excluded_cols, 1) > 0 THEN
                    h_old = h_old - excluded_cols;
                END IF;
                IF include_values THEN
                    audit_row.row_data = h_old;
                ELSE
                    -- Chỉ lưu key nếu không include_values
                    audit_row.row_data = jsonb_object_keys(h_old)::jsonb;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING '[audit.if_modified_func] Lỗi chuyển đổi OLD thành JSONB: %', SQLERRM;
                audit_row.row_data = '{"error": "cannot convert OLD row to jsonb"}'::jsonb;
            END;
        END IF;

        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
             -- Chuyển dữ liệu mới thành JSONB, loại bỏ các cột được exclude
            BEGIN
                h_new = to_jsonb(NEW.*);
                 IF array_length(excluded_cols, 1) > 0 THEN
                    h_new = h_new - excluded_cols;
                END IF;
                -- Nếu là INSERT, row_data là null, changed_fields là dữ liệu mới
                IF (TG_OP = 'INSERT') THEN
                    IF include_values THEN
                         audit_row.changed_fields = h_new;
                    ELSE
                         audit_row.changed_fields = jsonb_object_keys(h_new)::jsonb;
                    END IF;
                -- Nếu là UPDATE và log_diffs = TRUE, tính toán sự khác biệt
                ELSIF (log_diffs) THEN
                    BEGIN
                        -- Tạo JSONB chỉ chứa các trường thay đổi và giá trị mới
                        SELECT jsonb_object_agg(key, value)
                        INTO audit_row.changed_fields
                        FROM jsonb_each(h_new)
                        WHERE NOT (h_old ? key AND h_old -> key = value); -- Chỉ lấy key/value mới hoặc khác với cũ
                    EXCEPTION WHEN OTHERS THEN
                         RAISE WARNING '[audit.if_modified_func] Lỗi tính toán diff JSONB: %', SQLERRM;
                         audit_row.changed_fields = '{"error": "cannot compute changes"}'::jsonb;
                    END;
                    -- Nếu không có gì thay đổi thực sự (sau khi loại trừ cột), thì không cần log UPDATE
                    IF audit_row.changed_fields IS NULL OR audit_row.changed_fields = '{}'::jsonb THEN
                        RETURN NULL; -- Bỏ qua việc ghi log
                    END IF;
                END IF; -- End if log_diffs for UPDATE
            EXCEPTION WHEN OTHERS THEN
                 RAISE WARNING '[audit.if_modified_func] Lỗi chuyển đổi NEW thành JSONB: %', SQLERRM;
                 audit_row.changed_fields = '{"error": "cannot convert NEW row to jsonb"}'::jsonb;
            END;
        END IF; -- End if INSERT or UPDATE
    END IF; -- End if not statement_only

    -- Ghi log vào bảng audit_log
    BEGIN
        INSERT INTO audit.audit_log VALUES (audit_row.*);
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[audit.if_modified_func] Lỗi khi INSERT vào audit.audit_log: %', SQLERRM;
        -- Cân nhắc ghi log lỗi ra một nơi khác hoặc chỉ RAISE WARNING
    END;

    -- Trả về bản ghi phù hợp cho trigger (NEW cho INSERT/UPDATE, OLD cho DELETE)
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;

END;
$audit_trigger$ LANGUAGE plpgsql SECURITY DEFINER; -- SECURITY DEFINER để có thể ghi log vào schema audit

COMMENT ON FUNCTION audit.if_modified_func() IS '[QLDCQG-TT] Trigger function tự động ghi nhật ký thay đổi dữ liệu vào bảng audit.audit_log.';

-- ============================================================================
-- 2. GẮN TRIGGER VÀO CÁC BẢNG CẦN AUDIT
-- ============================================================================
\echo '    -> Gắn trigger audit vào các bảng trong central...';

-- Danh sách các bảng cần audit trong schema central (và sync nếu cần)
DO $$
DECLARE
    t TEXT;
    target_schema TEXT := 'central'; -- Schema mục tiêu
    trigger_name TEXT;
    -- Các cột metadata đồng bộ và metadata chung thường không cần log chi tiết thay đổi giá trị
    excluded_columns TEXT[] := ARRAY[
        'created_at', 'updated_at', 'created_by', 'updated_by', -- Metadata chung
        'last_synced_from_bca', 'last_synced_from_btp', 'last_integrated_at', -- Metadata đồng bộ của integrated_citizen
        'integrated_at', 'source_created_at', 'source_updated_at' -- Metadata đồng bộ của integrated_household
    ];
BEGIN
    -- Liệt kê các bảng cần audit trong schema 'central'
    FOREACH t IN ARRAY ARRAY[
        'integrated_citizen',
        'integrated_household'
        -- Thêm các bảng khác trong 'central' hoặc 'sync' nếu cần audit
    ]
    LOOP
        -- Kiểm tra xem bảng có tồn tại không trước khi tạo trigger
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = target_schema AND table_name = t) THEN
            trigger_name := 'audit_trigger_' || t;

            -- Xóa trigger cũ nếu tồn tại
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I;', trigger_name, target_schema, t);

            -- Tạo trigger mới
            -- Tham số 1 (include_values): TRUE = log cả giá trị, FALSE = chỉ log tên cột
            -- Tham số 2 (log_diffs): TRUE = log changed_fields cho UPDATE, FALSE = không log
            -- Tham số 3 trở đi: Các cột cần loại trừ khỏi row_data và changed_fields
            EXECUTE format(
                'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I.%I '
                'FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func(%L, %L, %s);',
                trigger_name, target_schema, t,
                'TRUE', -- include_values = TRUE (Log giá trị)
                'TRUE', -- log_diffs = TRUE (Log các trường thay đổi cho UPDATE)
                quote_literal(excluded_columns::TEXT) -- Truyền mảng cột loại trừ
            );
            RAISE NOTICE '      -> Đã gắn trigger audit cho bảng: %.%', target_schema, t;
        ELSE
            RAISE WARNING '      -> Bảng %.% không tồn tại, bỏ qua gắn trigger audit.', target_schema, t;
        END IF;
    END LOOP;
END $$;

-- Trigger cho TRUNCATE (nếu cần theo dõi) - Chạy FOR EACH STATEMENT
-- DO $$
-- DECLARE
--     t TEXT;
--     target_schema TEXT := 'central';
--     trigger_name TEXT;
-- BEGIN
--     FOREACH t IN ARRAY ARRAY[
--         'integrated_citizen',
--         'integrated_household'
--     ]
--     LOOP
--         IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = target_schema AND table_name = t) THEN
--             trigger_name := 'audit_trigger_truncate_' || t;
--             EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I;', trigger_name, target_schema, t);
--             EXECUTE format(
--                 'CREATE TRIGGER %I AFTER TRUNCATE ON %I.%I '
--                 'FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();', -- Không cần tham số cho TRUNCATE
--                 trigger_name, target_schema, t
--             );
--             RAISE NOTICE '      -> Đã gắn trigger audit TRUNCATE cho bảng: %.%', target_schema, t;
--         END IF;
--     END LOOP;
-- END $$;

COMMIT;

\echo '-> Hoàn thành tạo function và gắn trigger audit cho national_citizen_central_server.'

-- TODO (Các bước tiếp theo):
-- 1. Partition Management for audit_log: Đảm bảo bảng audit_log được phân vùng và quản lý đúng cách.
-- 2. Review Excluded Columns: Xem xét lại danh sách `excluded_columns` cho phù hợp với các bảng tích hợp.
-- 3. Performance Monitoring: Theo dõi hiệu năng của trigger, đặc biệt khi có lượng lớn dữ liệu được đồng bộ vào bảng central.
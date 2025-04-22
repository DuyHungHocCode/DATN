-- File: national_citizen_central_server/04_triggers.sql
-- Description: Định nghĩa và gắn TẤT CẢ các triggers cho database Máy chủ Trung tâm (TT).
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
--
-- Dependencies:
-- - Schema 'audit' và bảng 'audit.audit_log'.
-- - Schema 'central' và các bảng tích hợp.
-- - Schema 'reference' và các bảng tham chiếu.
-- - Schema 'partitioning' và bảng 'partitioning.config'.
-- - ENUM 'cdc_operation_type'.
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO VÀ GẮN TRIGGERS CHO DATABASE national_citizen_central_server ***'
\connect national_citizen_central_server

-- Đảm bảo các schema cần thiết tồn tại
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS common; -- Schema chứa hàm trigger chung
CREATE SCHEMA IF NOT EXISTS central;
CREATE SCHEMA IF NOT EXISTS partitioning;
-- Các schema reference, sync được giả định đã tồn tại

BEGIN;

-- ============================================================================
-- I. ĐỊNH NGHĨA TRIGGER FUNCTIONS
-- ============================================================================

\echo '--> 1. Định nghĩa các trigger functions...'

-- 1.1. Function ghi log audit (audit.if_modified_func)
-- Đảm bảo hàm này giống hệt bên BCA/BTP để logic audit nhất quán.
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
        FALSE,                                 -- statement_only (Default)
        NULL,                                  -- row_data
        NULL,                                  -- changed_fields
        current_query()                        -- query (Cố gắng lấy query hiện tại)
    )::audit.audit_log; -- Ép kiểu về đúng record type

    -- Xác định loại hành động (operation) và statement_only
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
                    audit_row.row_data = '{}'::jsonb; -- Để trống nếu không muốn log keys
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING '[audit.if_modified_func] Lỗi chuyển đổi OLD thành JSONB cho %.%: %', TG_TABLE_NAME, SQLERRM;
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
                         audit_row.changed_fields = '{}'::jsonb; -- Để trống nếu không muốn log keys
                    END IF;
                -- Nếu là UPDATE và log_diffs = TRUE, tính toán sự khác biệt
                ELSIF (log_diffs) THEN
                     -- Chỉ tính diff nếu h_old và h_new hợp lệ
                    IF h_old IS NOT NULL AND h_new IS NOT NULL THEN
                        BEGIN
                            -- Tạo JSONB chỉ chứa các trường thay đổi và giá trị mới
                            SELECT jsonb_object_agg(key, value)
                            INTO audit_row.changed_fields
                            FROM jsonb_each(h_new)
                            WHERE NOT (h_old ? key AND h_old -> key = value); -- Chỉ lấy key/value mới hoặc khác với cũ
                        EXCEPTION WHEN OTHERS THEN
                            RAISE WARNING '[audit.if_modified_func] Lỗi tính toán diff JSONB cho %.%: %', TG_TABLE_NAME, SQLERRM;
                            audit_row.changed_fields = '{"error": "cannot compute changes"}'::jsonb;
                        END;
                        -- Nếu không có gì thay đổi thực sự (sau khi loại trừ cột), thì không cần log UPDATE
                        IF audit_row.changed_fields IS NULL OR jsonb_object_keys(audit_row.changed_fields)::text[] = ARRAY[]::text[] THEN
                             RAISE NOTICE '[audit.if_modified_func] No changes detected for UPDATE on %.%. Skipping audit log.', TG_TABLE_NAME, TG_NAME;
                            RETURN NULL; -- Bỏ qua việc ghi log
                        END IF;
                    ELSE
                         RAISE WARNING '[audit.if_modified_func] Cannot compute changes for UPDATE on %.% due to invalid OLD/NEW JSONB.', TG_TABLE_NAME, TG_NAME;
                         audit_row.changed_fields = '{"error": "cannot compute changes due to invalid OLD/NEW"}'::jsonb;
                    END IF;
                END IF; -- End if log_diffs for UPDATE
            EXCEPTION WHEN OTHERS THEN
                 RAISE WARNING '[audit.if_modified_func] Lỗi chuyển đổi NEW thành JSONB cho %.%: %', TG_TABLE_NAME, SQLERRM;
                 audit_row.changed_fields = '{"error": "cannot convert NEW row to jsonb"}'::jsonb;
            END;
        END IF; -- End if INSERT or UPDATE
    END IF; -- End if not statement_only

    -- Ghi log vào bảng audit_log
    BEGIN
        INSERT INTO audit.audit_log VALUES (audit_row.*);
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[audit.if_modified_func] Lỗi khi INSERT vào audit.audit_log: % - Row: %', SQLERRM, audit_row;
        -- Cân nhắc ghi log lỗi ra một nơi khác hoặc chỉ RAISE WARNING
    END;

    -- Trả về bản ghi phù hợp cho trigger (NEW cho INSERT/UPDATE, OLD cho DELETE)
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;

END;
$audit_trigger$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = audit, public; -- Cần chỉ định search_path

COMMENT ON FUNCTION audit.if_modified_func() IS '[QLDCQG-TT] Trigger function tự động ghi nhật ký thay đổi dữ liệu vào bảng audit.audit_log.';

-- 1.2. Function tự động cập nhật cột updated_at
\echo '    -> Tạo hoặc thay thế function common.update_updated_at_column()...';
CREATE OR REPLACE FUNCTION common.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';
COMMENT ON FUNCTION common.update_updated_at_column() IS '[Chung] Tự động cập nhật giá trị cột updated_at thành thời điểm hiện tại khi bản ghi được cập nhật.';


-- ============================================================================
-- II. GẮN TRIGGER AUDIT VÀO CÁC BẢNG
-- ============================================================================

\echo '--> 2. Gắn trigger audit vào các bảng cần theo dõi...'

-- Gắn trigger audit cho các bảng trong schema 'central'
\echo '    -> Gắn trigger audit vào các bảng trong central...';
DO $$
DECLARE
    t TEXT;
    target_schema TEXT := 'central';
    trigger_name TEXT;
    excluded_columns TEXT[];
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'integrated_citizen',
        'integrated_household'
    ]
    LOOP
        -- Xác định các cột metadata cần loại trừ cho từng bảng
        IF t = 'integrated_citizen' THEN
            excluded_columns := ARRAY[
                -- 'created_at', 'updated_at', 'created_by', 'updated_by', -- Không có trong bảng TT
                'last_synced_from_bca', 'last_synced_from_btp', 'last_integrated_at' -- Metadata đồng bộ
            ];
        ELSIF t = 'integrated_household' THEN
             excluded_columns := ARRAY[
                -- 'created_at', 'updated_at', 'created_by', 'updated_by', -- Không có trong bảng TT
                'integrated_at', 'source_created_at', 'source_updated_at' -- Metadata đồng bộ
            ];
        ELSE
             excluded_columns := ARRAY[]; -- Mặc định không loại trừ gì thêm
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = target_schema AND table_name = t) THEN
            trigger_name := 'audit_trigger_' || t;
            RAISE NOTICE '      -> Gắn trigger audit cho bảng: %.%', target_schema, t;
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I;', trigger_name, target_schema, t);
            EXECUTE format(
                'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I.%I '
                'FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func(%L, %L, %s);',
                trigger_name, target_schema, t,
                'TRUE', -- include_values = TRUE (Log giá trị)
                'TRUE', -- log_diffs = TRUE (Log các trường thay đổi cho UPDATE)
                quote_literal(excluded_columns::TEXT)
            );
        ELSE
            RAISE WARNING '      -> Bảng %.% không tồn tại, bỏ qua gắn trigger audit.', target_schema, t;
        END IF;
    END LOOP;
END $$;

-- Gắn trigger audit cho các bảng trong schema 'sync' (Tùy chọn)
\echo '    -> (Tùy chọn) Gắn trigger audit vào các bảng trong sync...';
DO $$
DECLARE
    t TEXT := 'sync_status'; -- Bảng ví dụ
    target_schema TEXT := 'sync';
    trigger_name TEXT;
    excluded_columns TEXT[] := ARRAY['created_at', 'updated_at', 'created_by', 'updated_by']; -- Giả sử có cột này
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = target_schema AND table_name = t) THEN
        trigger_name := 'audit_trigger_' || t;
        RAISE NOTICE '      -> Gắn trigger audit cho bảng: %.%', target_schema, t;
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I;', trigger_name, target_schema, t);
        EXECUTE format(
            'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I.%I '
            'FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func(%L, %L, %s);',
            trigger_name, target_schema, t,
            'TRUE', 'TRUE', quote_literal(excluded_columns::TEXT)
        );
    ELSE
        RAISE WARNING '      -> Bảng %.% không tồn tại, bỏ qua gắn trigger audit.', target_schema, t;
    END IF;
END $$;

-- Gắn trigger audit cho bảng partitioning.config (Tùy chọn)
\echo '    -> (Tùy chọn) Gắn trigger audit vào bảng partitioning.config...';
DO $$
DECLARE
    t TEXT := 'config';
    target_schema TEXT := 'partitioning';
    trigger_name TEXT;
    excluded_columns TEXT[] := ARRAY['created_at', 'updated_at']; -- Các cột metadata của config
BEGIN
     IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = target_schema AND table_name = t) THEN
        trigger_name := 'audit_trigger_' || t;
        RAISE NOTICE '      -> Gắn trigger audit cho bảng: %.%', target_schema, t;
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I;', trigger_name, target_schema, t);
        EXECUTE format(
            'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I.%I '
            'FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func(%L, %L, %s);',
            trigger_name, target_schema, t,
            'TRUE', 'TRUE', quote_literal(excluded_columns::TEXT)
        );
    ELSE
        RAISE WARNING '      -> Bảng %.% không tồn tại, bỏ qua gắn trigger audit.', target_schema, t;
    END IF;
END $$;


-- ============================================================================
-- III. GẮN TRIGGER CẬP NHẬT TIMESTAMP (updated_at)
-- ============================================================================

\echo '--> 3. Gắn trigger tự động cập nhật updated_at...'

DO $$
DECLARE
    schema_name_ TEXT;
    table_name_ TEXT;
    trigger_name TEXT := 'trigger_update_updated_at';
BEGIN
    FOR schema_name_, table_name_ IN
        SELECT c.table_schema, c.table_name
        FROM information_schema.columns c
        JOIN information_schema.tables t ON c.table_schema = t.table_schema AND c.table_name = t.table_name
        WHERE c.column_name = 'updated_at'
          AND t.table_schema IN ('reference', 'partitioning', 'sync') -- Các schema có thể có bảng chứa updated_at ở TT
          AND t.table_type = 'BASE TABLE'
          AND c.table_name != 'history' -- Bảng partitioning.history không dùng trigger này
    LOOP
        RAISE NOTICE '    -> Gắn trigger update_updated_at cho bảng: %.%', schema_name_, table_name_;
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I;', trigger_name, schema_name_, table_name_);
        EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION common.update_updated_at_column();',
                        trigger_name, schema_name_, table_name_);
    END LOOP;
END $$;


-- ============================================================================
-- IV. GẮN CÁC TRIGGER NGHIỆP VỤ KHÁC (NẾU CÓ)
-- ============================================================================
-- Ít khả năng cần trigger nghiệp vụ phức tạp ở DB Trung tâm.
-- Logic phức tạp nên nằm trong hàm đồng bộ (sync.*) hoặc tầng ứng dụng.
-- Nếu có, thêm vào đây.

COMMIT;

\echo '*** HOÀN THÀNH TẠO VÀ GẮN TRIGGERS CHO DATABASE national_citizen_central_server ***'
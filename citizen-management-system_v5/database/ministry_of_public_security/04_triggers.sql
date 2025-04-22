-- =============================================================================
-- File: ministry_of_public_security/04_triggers.sql
-- Description: Tạo các trigger function và gắn trigger vào các bảng cần thiết
--              trong database Bộ Công an (ministry_of_public_security).
-- Version: 3.1 (Consolidated trigger definitions and attachments)
--
-- Bao gồm:
-- 1. Trigger Function ghi nhật ký thay đổi (audit).
-- 2. Trigger Function tự động cập nhật timestamp.
-- 3. Gắn các trigger vào các bảng trong schema public_security.
-- 4. Placeholder cho các trigger nghiệp vụ phức tạp hơn (cần bổ sung logic).
--
-- Yêu cầu:
-- - Chạy sau khi đã tạo các hàm (03_functions.sql).
-- - Các bảng và schema liên quan đã tồn tại.
-- - Cần quyền tạo trigger function và trigger trên các bảng.
-- =============================================================================

\echo '*** BẮT ĐẦU ĐỊNH NGHĨA VÀ GẮN TRIGGERS CHO DATABASE BỘ CÔNG AN ***'
\connect ministry_of_public_security

-- Đảm bảo các schema cần thiết tồn tại
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS utility;

-- === 1. ĐỊNH NGHĨA CÁC TRIGGER FUNCTIONS ===

\echo '[1] Định nghĩa các trigger functions...'

-- 1.1. Trigger Function cho Audit Log (audit.if_modified_func)
--      (Giống hệt hàm đã tạo trong file gốc ministry_of_public_security/triggers/audit_triggers.sql)
\echo '   -> Tạo hoặc thay thế function audit.if_modified_func()...';
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $audit_trigger$
DECLARE
    audit_row audit.audit_log;
    include_values BOOLEAN;
    log_diffs BOOLEAN;
    h_old JSONB;
    h_new JSONB;
    excluded_cols TEXT[] = ARRAY[]::TEXT[];
BEGIN
    -- Xác định xem có log giá trị chi tiết và sự khác biệt không
    include_values := TG_ARGV[0]::BOOLEAN;
    log_diffs := TG_ARGV[1]::BOOLEAN;
    excluded_cols = TG_ARGV[2:array_upper(TG_ARGV, 1)];

    -- Tạo bản ghi audit cơ bản
    audit_row = ROW(
        nextval('audit.audit_log_log_id_seq'), -- log_id
        clock_timestamp(),                     -- action_tstamp
        TG_TABLE_SCHEMA::TEXT,                 -- schema_name
        TG_TABLE_NAME::TEXT,                   -- table_name
        NULL,                                  -- operation (sẽ được gán)
        session_user::TEXT,                    -- session_user_name
        current_setting('application_name', true), -- application_name (true để không lỗi nếu chưa set)
        inet_client_addr(),                    -- client_addr
        inet_client_port(),                    -- client_port
        txid_current(),                        -- transaction_id
        current_query(),                       -- query (có thể không đầy đủ)
        FALSE,                                 -- statement_only
        NULL,                                  -- row_data
        NULL                                   -- changed_fields
    );

    -- Xác định loại hành động
    IF (TG_OP = 'INSERT') THEN audit_row.operation = 'INSERT';
    ELSIF (TG_OP = 'UPDATE') THEN audit_row.operation = 'UPDATE';
    ELSIF (TG_OP = 'DELETE') THEN audit_row.operation = 'DELETE';
    ELSIF (TG_OP = 'TRUNCATE') THEN audit_row.operation = 'TRUNCATE'; audit_row.statement_only = TRUE;
    END IF;

    -- Xử lý dữ liệu hàng (nếu không phải TRUNCATE)
    IF NOT audit_row.statement_only THEN
        IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
            BEGIN h_old = to_jsonb(OLD.*);
                IF array_length(excluded_cols, 1) > 0 THEN h_old = h_old - excluded_cols; END IF;
                audit_row.row_data = CASE WHEN include_values THEN h_old ELSE jsonb_object_keys(h_old)::jsonb END;
            EXCEPTION WHEN OTHERS THEN RAISE WARNING '[audit.if_modified_func] Lỗi chuyển đổi OLD: %', SQLERRM; audit_row.row_data = '{"error": "conversion_error"}'::jsonb; END;
        END IF;
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            BEGIN h_new = to_jsonb(NEW.*);
                 IF array_length(excluded_cols, 1) > 0 THEN h_new = h_new - excluded_cols; END IF;
                 IF (TG_OP = 'INSERT') THEN
                     audit_row.changed_fields = CASE WHEN include_values THEN h_new ELSE jsonb_object_keys(h_new)::jsonb END;
                 ELSIF (log_diffs) THEN
                     BEGIN SELECT jsonb_object_agg(key, value) INTO audit_row.changed_fields FROM jsonb_each(h_new) WHERE NOT (h_old ? key AND h_old -> key = value);
                     EXCEPTION WHEN OTHERS THEN RAISE WARNING '[audit.if_modified_func] Lỗi tính toán diff: %', SQLERRM; audit_row.changed_fields = '{"error": "diff_error"}'::jsonb; END;
                     IF audit_row.changed_fields IS NULL OR audit_row.changed_fields = '{}'::jsonb THEN RETURN NULL; END IF; -- Không log nếu không có gì thay đổi
                 END IF;
            EXCEPTION WHEN OTHERS THEN RAISE WARNING '[audit.if_modified_func] Lỗi chuyển đổi NEW: %', SQLERRM; audit_row.changed_fields = '{"error": "conversion_error"}'::jsonb; END;
        END IF;
    END IF;

    -- Ghi log
    BEGIN INSERT INTO audit.audit_log VALUES (audit_row.*);
    EXCEPTION WHEN OTHERS THEN RAISE WARNING '[audit.if_modified_func] Lỗi INSERT vào audit.audit_log: %', SQLERRM; END;

    RETURN CASE TG_OP WHEN 'DELETE' THEN OLD ELSE NEW END;
END;
$audit_trigger$ LANGUAGE plpgsql SECURITY DEFINER;
COMMENT ON FUNCTION audit.if_modified_func() IS '[QLDCQG-BCA] Trigger function tự động ghi nhật ký thay đổi dữ liệu vào bảng audit.audit_log.';

-- 1.2. Trigger Function tự động cập nhật timestamp 'updated_at'
\echo '   -> Tạo hoặc thay thế function utility.trigger_set_timestamp()...';
CREATE OR REPLACE FUNCTION utility.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION utility.trigger_set_timestamp() IS '[QLDCQG-BCA] Trigger function tự động cập nhật cột updated_at khi có UPDATE.';

-- 1.3. Placeholder cho các Trigger Function nghiệp vụ khác
-- Ví dụ: Trigger cập nhật cột phân vùng, kiểm tra unique phức tạp...
-- CREATE OR REPLACE FUNCTION public_security.trigger_update_partition_keys() ...
-- CREATE OR REPLACE FUNCTION public_security.trigger_check_unique_card_number() ...


-- === 2. GẮN TRIGGERS VÀO CÁC BẢNG ===

\echo '[2] Gắn triggers vào các bảng...'

-- 2.1. Gắn Audit Trigger
\echo '   -> Gắn audit trigger vào các bảng trong public_security...'
DO $$
DECLARE
    t TEXT;
    trigger_name TEXT;
    -- Các cột nhạy cảm hoặc không cần log chi tiết giá trị thay đổi
    excluded_columns TEXT[] := ARRAY['created_at', 'updated_at', 'created_by', 'updated_by', 'password_hash', 'two_factor_secret', 'verification_token', 'password_reset_token', 'biometric_data'];
BEGIN
    -- Liệt kê các bảng cần audit trong schema 'public_security'
    FOREACH t IN ARRAY ARRAY[
        'citizen', 'address', 'identification_card', 'permanent_residence',
        'temporary_residence', 'temporary_absence', 'citizen_status',
        'citizen_movement', 'criminal_record', 'digital_identity',
        'user_account', 'citizen_address'
        -- Thêm các bảng khác nếu cần
    ]
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public_security' AND table_name = t) THEN
            trigger_name := 'audit_trigger_' || t;
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON public_security.%I;', trigger_name, t);
            EXECUTE format(
                'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON public_security.%I '
                'FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func(%L, %L, %s);',
                trigger_name, t,
                'TRUE', -- include_values = TRUE (Log giá trị)
                'TRUE', -- log_diffs = TRUE (Log các trường thay đổi cho UPDATE)
                quote_literal(excluded_columns::TEXT) -- Truyền mảng cột loại trừ
            );
            RAISE NOTICE '      -> Đã gắn trigger audit cho bảng: public_security.%', t;
        ELSE
            RAISE WARNING '      -> Bảng public_security.% không tồn tại, bỏ qua gắn trigger audit.', t;
        END IF;
    END LOOP;
END $$;

-- 2.2. Gắn Timestamp Trigger
\echo '   -> Gắn timestamp trigger (updated_at) vào các bảng...'
DO $$
DECLARE
    t TEXT;
    trigger_name TEXT;
BEGIN
    -- Liệt kê các bảng có cột updated_at
    FOREACH t IN ARRAY ARRAY[
        'citizen', 'address', 'identification_card', 'permanent_residence',
        'temporary_residence', 'temporary_absence', 'citizen_status',
        'citizen_movement', 'criminal_record', 'digital_identity',
        'user_account', 'citizen_address'
        -- Thêm các bảng khác nếu cần
    ]
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public_security' AND table_name = t AND column_name = 'updated_at') THEN
            trigger_name := 'set_timestamp_' || t;
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON public_security.%I;', trigger_name, t);
            EXECUTE format(
                'CREATE TRIGGER %I BEFORE UPDATE ON public_security.%I '
                'FOR EACH ROW EXECUTE FUNCTION utility.trigger_set_timestamp();',
                trigger_name, t
            );
            RAISE NOTICE '      -> Đã gắn trigger timestamp cho bảng: public_security.%', t;
        ELSE
             RAISE NOTICE '      -> Bảng public_security.% không có cột updated_at, bỏ qua gắn trigger timestamp.', t;
        END IF;
    END LOOP;
END $$;

-- 2.3. Gắn các Trigger nghiệp vụ khác (Placeholder)
\echo '   -> Placeholder: Gắn các trigger nghiệp vụ khác (cần triển khai logic)...'
-- Ví dụ:
-- DROP TRIGGER IF EXISTS trigger_update_citizen_partition ON public_security.address;
-- CREATE TRIGGER trigger_update_citizen_partition AFTER UPDATE OF ward_id ON public_security.address
--     FOR EACH ROW EXECUTE FUNCTION public_security.trigger_update_citizen_partition_keys();
--
-- DROP TRIGGER IF EXISTS trigger_check_unique_card ON public_security.identification_card;
-- CREATE TRIGGER trigger_check_unique_card BEFORE INSERT OR UPDATE ON public_security.identification_card
--     FOR EACH ROW EXECUTE FUNCTION public_security.trigger_check_unique_card_number();


-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH ĐỊNH NGHĨA VÀ GẮN TRIGGERS CHO DATABASE BỘ CÔNG AN ***'
\echo '-> Đã tạo và gắn các trigger audit, timestamp.'
\echo '-> LƯU Ý: Các trigger nghiệp vụ phức tạp (cập nhật khóa phân vùng, kiểm tra unique...) cần được định nghĩa và gắn riêng.'
\echo '-> Bước tiếp theo: Chạy script partitioning_setup.sql để thực thi tạo partition.'

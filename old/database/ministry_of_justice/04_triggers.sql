-- File: ministry_of_justice/04_triggers.sql
-- Description: Định nghĩa và gắn TẤT CẢ các triggers cho database Bộ Tư pháp (BTP).
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
--
-- Dependencies:
-- - Schema 'audit' và bảng 'audit.audit_log'.
-- - Schema 'justice' và các bảng nghiệp vụ.
-- - Schema 'reference' và các bảng tham chiếu.
-- - Schema 'partitioning' và bảng 'partitioning.config'.
-- - ENUM 'cdc_operation_type'.
-- - Extension 'pg_trgm' (nếu dùng index GIN, không trực tiếp cho trigger).
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO VÀ GẮN TRIGGERS CHO DATABASE ministry_of_justice ***'
\connect ministry_of_justice

-- Đảm bảo các schema cần thiết tồn tại
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS common; -- Schema chứa hàm trigger chung

BEGIN;

-- ============================================================================
-- I. ĐỊNH NGHĨA TRIGGER FUNCTIONS
-- ============================================================================

\echo '--> 1. Định nghĩa các trigger functions...'

-- 1.1. Function ghi log audit (audit.if_modified_func)
-- Đảm bảo hàm này giống hệt bên BCA/TT để logic audit nhất quán.
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
                    -- Chỉ lưu key nếu không include_values (có thể không hữu ích lắm)
                    -- audit_row.row_data = jsonb_object_keys(h_old)::jsonb;
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
                         -- audit_row.changed_fields = jsonb_object_keys(h_new)::jsonb;
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

COMMENT ON FUNCTION audit.if_modified_func() IS '[QLDCQG-BTP] Trigger function tự động ghi nhật ký thay đổi dữ liệu vào bảng audit.audit_log.';

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

-- Gắn trigger audit cho các bảng trong schema 'justice'
\echo '    -> Gắn trigger audit vào các bảng trong justice...';
DO $$
DECLARE
    t TEXT;
    trigger_name TEXT;
    -- Các cột thường không cần log giá trị cũ/mới chi tiết
    excluded_columns TEXT[] := ARRAY['created_at', 'updated_at', 'created_by', 'updated_by'];
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'birth_certificate',
        'death_certificate',
        'marriage',
        'divorce',
        'household',
        'household_member',
        'family_relationship',
        'population_change' -- Audit bảng này nếu nó được cập nhật trực tiếp
    ]
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'justice' AND table_name = t) THEN
            trigger_name := 'audit_trigger_' || t;
            RAISE NOTICE '      -> Gắn trigger audit cho bảng: justice.%', t;
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON justice.%I;', trigger_name, t);
            -- Tạo trigger mới, ghi cả giá trị (TRUE) và log diff (TRUE)
            EXECUTE format(
                'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON justice.%I '
                'FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func(%L, %L, %s);',
                trigger_name, t,
                'TRUE', -- include_values = TRUE
                'TRUE', -- log_diffs = TRUE
                quote_literal(excluded_columns::TEXT) -- Truyền mảng cột loại trừ
            );
        ELSE
            RAISE WARNING '      -> Bảng justice.% không tồn tại, bỏ qua gắn trigger audit.', t;
        END IF;
    END LOOP;
END $$;

-- Gắn trigger audit cho các bảng trong schema 'reference' (Tùy chọn)
-- \echo '    -> (Tùy chọn) Gắn trigger audit vào các bảng trong reference...';
-- DO $$ ... Tương tự vòng lặp trên cho các bảng reference ... $$;

-- Gắn trigger audit cho bảng partitioning.config (Tùy chọn)
-- \echo '    -> (Tùy chọn) Gắn trigger audit vào bảng partitioning.config...';
-- DO $$ ... Tương tự cho partitioning.config ... $$;


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
          AND t.table_schema IN ('justice', 'reference', 'partitioning') -- Chỉ các schema có bảng cần trigger này trong BTP
          AND t.table_type = 'BASE TABLE'
          AND c.table_name != 'audit_log' -- Không cần cho bảng audit_log
          AND c.table_name != 'history' -- Không cần cho bảng partitioning.history
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

-- Hiện tại không có trigger nghiệp vụ nào được định nghĩa trong các file gốc.
-- Thêm các lệnh CREATE TRIGGER cho các trigger nghiệp vụ vào đây nếu cần.
-- Ví dụ: Trigger cập nhật trạng thái hôn nhân khi có bản ghi ly hôn
-- (Cần hàm 'justice.update_marriage_status_after_divorce' được tạo trong 03_functions.sql)

-- \echo '--> 4. Gắn các trigger nghiệp vụ khác (nếu có)...'
--
-- -- Trigger: Cập nhật status=FALSE trong justice.marriage khi có bản ghi divorce mới
-- \echo '    -> Gắn trigger cập nhật trạng thái hôn nhân khi ly hôn...'
-- DROP TRIGGER IF EXISTS trigger_update_marriage_status_on_divorce ON justice.divorce;
-- -- CREATE TRIGGER trigger_update_marriage_status_on_divorce
-- --     AFTER INSERT ON justice.divorce
-- --     FOR EACH ROW
-- --     EXECUTE FUNCTION justice.update_marriage_status_after_divorce();
-- \echo '       (Lưu ý: Hàm justice.update_marriage_status_after_divorce cần được định nghĩa)';
--
-- -- Trigger: Đảm bảo chủ hộ là thành viên trong household_member
-- \echo '    -> Gắn trigger kiểm tra chủ hộ trong household_member...'
-- -- Logic này phức tạp hơn, có thể cần trigger AFTER INSERT/UPDATE/DELETE trên cả household và household_member
-- -- hoặc kiểm tra trong stored procedure/ứng dụng.
-- \echo '       (Lưu ý: Trigger này cần logic phức tạp hơn và hàm tương ứng)';


COMMIT;

\echo '*** HOÀN THÀNH TẠO VÀ GẮN TRIGGERS CHO DATABASE ministry_of_justice ***'
-- =============================================================================
-- File: database/triggers/audit_triggers.sql
-- Description: Tạo trigger function và gắn trigger để ghi nhật ký thay đổi
--              dữ liệu vào bảng audit.audit_log.
-- Version: 1.0
--
-- Chức năng chính:
-- 1. Định nghĩa function trigger `audit.if_modified_func()` để xử lý logic ghi log.
-- 2. Tạo các trigger (AFTER INSERT, UPDATE, DELETE, TRUNCATE) trên các bảng
--    nghiệp vụ quan trọng để gọi function ghi log.
--
-- Lưu ý:
-- - Function và trigger cần được tạo trong cả 3 database (BCA, BTP, TT).
-- - Cần đảm bảo bảng `audit.audit_log` đã được tạo trước khi chạy script này.
-- - Việc chọn bảng nào để audit cần được xem xét kỹ lưỡng dựa trên yêu cầu
--   nghiệp vụ và ảnh hưởng hiệu năng. Script này chỉ bao gồm một số bảng ví dụ.
-- =============================================================================

\echo '*** BẮT ĐẦU TẠO AUDIT TRIGGERS ***'

-- ============================================================================
-- I. AUDIT TRIGGERS CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo '--> Tạo audit trigger function và triggers cho ministry_of_public_security...'
\connect ministry_of_public_security

-- 1. Tạo Function Trigger Audit
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $audit_trigger$
DECLARE
    v_action CHAR(1);
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_app_name TEXT := current_setting('application_name', true); -- Lấy application_name nếu client set
    v_txid BIGINT := txid_current();
    v_client_addr INET := inet_client_addr();
    v_client_port INTEGER := inet_client_port();
BEGIN
    -- Xác định hành động
    v_action := TG_OP::CHAR(1); -- I, U, D, T

    -- Lấy dữ liệu cũ/mới dựa trên hành động
    IF (v_action = 'U') THEN -- UPDATE
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        -- Chỉ log nếu thực sự có thay đổi (tránh log các update không thay đổi gì)
        IF v_old_data = v_new_data THEN
             RETURN NEW;
        END IF;
    ELSIF (v_action = 'D') THEN -- DELETE
        v_old_data := to_jsonb(OLD);
    ELSIF (v_action = 'I') THEN -- INSERT
        v_new_data := to_jsonb(NEW);
    ELSIF (v_action = 'T') THEN -- TRUNCATE (Statement Level)
         -- TRUNCATE được xử lý bởi trigger riêng (FOR EACH STATEMENT)
         -- Chỉ ghi log ở trigger đó, không cần xử lý row_data/new_data ở đây.
         -- Tuy nhiên, function này cũng có thể được gọi bởi trigger TRUNCATE nếu cần.
         -- Nếu gọi từ TRUNCATE, sẽ không có OLD/NEW.
         INSERT INTO audit.audit_log (
                schema_name,
                table_name,
                relid,
                session_user_name,
                action_tstamp,
                transaction_id,
                application_name,
                client_addr,
                client_port,
                action,
                row_data,
                changed_fields,
                statement_only
            )
            VALUES (
                TG_TABLE_SCHEMA::TEXT,
                TG_TABLE_NAME::TEXT,
                TG_RELID,
                session_user::TEXT,
                transaction_timestamp(), -- Luôn dùng transaction timestamp
                v_txid,
                v_app_name,
                v_client_addr,
                v_client_port,
                'T',          -- Action 'T' for TRUNCATE
                NULL,         -- No row data for TRUNCATE
                NULL,         -- No changed fields for TRUNCATE
                TRUE          -- Mark as statement-only log
            );
            RETURN NULL; -- Return NULL for STATEMENT level trigger
    END IF;

    -- Ghi log vào bảng audit.audit_log cho INSERT, UPDATE, DELETE
    IF (v_action IN ('I', 'U', 'D')) THEN
        INSERT INTO audit.audit_log (
                schema_name,
                table_name,
                relid,
                session_user_name,
                action_tstamp,
                transaction_id,
                application_name,
                client_addr,
                client_port,
                action,
                row_data,         -- Dữ liệu cũ (NULL cho INSERT)
                changed_fields,   -- Dữ liệu mới (NULL cho DELETE)
                statement_only
            )
        VALUES (
            TG_TABLE_SCHEMA::TEXT,
            TG_TABLE_NAME::TEXT,
            TG_RELID,
            session_user::TEXT,
            transaction_timestamp(), -- Luôn dùng transaction timestamp
            v_txid,
            v_app_name,
            v_client_addr,
            v_client_port,
            v_action,
            v_old_data,
            v_new_data,
            FALSE -- Not statement-only for row-level actions
        );
    END IF;

    -- Trả về bản ghi phù hợp cho trigger
    IF (v_action = 'D') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;

EXCEPTION -- Bắt lỗi nếu không ghi được log (ví dụ: bảng log bị khóa, đầy...)
    WHEN OTHERS THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] Lỗi khi ghi audit log: %', SQLERRM;
        -- Quan trọng: Không raise exception để không làm dừng hoạt động nghiệp vụ chính
        -- Trả về bản ghi gốc để hoạt động tiếp tục
        IF (TG_OP = 'DELETE') THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
END;
$audit_trigger$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = "$user", public, pg_temp;
-- SECURITY DEFINER: Cho phép function ghi vào bảng audit.audit_log ngay cả khi user thực hiện DML không có quyền INSERT trực tiếp. Cần cẩn thận khi dùng.
-- SET search_path: Đảm bảo function tìm thấy các hàm như to_jsonb, txid_current...

COMMENT ON FUNCTION audit.if_modified_func() IS 'Trigger function chung để ghi lại các thay đổi (INSERT, UPDATE, DELETE) vào bảng audit.audit_log.';


-- 2. Gắn Trigger vào các bảng cần theo dõi (Ví dụ)
-- Lưu ý: Chọn các bảng quan trọng cần audit. Gắn trigger vào quá nhiều bảng sẽ ảnh hưởng hiệu năng.

-- Bảng citizen
DROP TRIGGER IF EXISTS audit_trigger_row ON public_security.citizen;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON public_security.citizen
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON public_security.citizen;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON public_security.citizen
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng identification_card
DROP TRIGGER IF EXISTS audit_trigger_row ON public_security.identification_card;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON public_security.identification_card
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON public_security.identification_card;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON public_security.identification_card
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng permanent_residence
DROP TRIGGER IF EXISTS audit_trigger_row ON public_security.permanent_residence;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON public_security.permanent_residence
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON public_security.permanent_residence;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON public_security.permanent_residence
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng temporary_residence
DROP TRIGGER IF EXISTS audit_trigger_row ON public_security.temporary_residence;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON public_security.temporary_residence
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON public_security.temporary_residence;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON public_security.temporary_residence
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng criminal_record (Audit rất quan trọng)
DROP TRIGGER IF EXISTS audit_trigger_row ON public_security.criminal_record;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON public_security.criminal_record
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON public_security.criminal_record;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON public_security.criminal_record
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- (Thêm trigger cho các bảng khác của BCA nếu cần: address, citizen_address, citizen_status, user_account, digital_identity...)

\echo '-> Hoàn thành tạo audit triggers cho ministry_of_public_security.'

-- ============================================================================
-- II. AUDIT TRIGGERS CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo '--> Tạo audit trigger function và triggers cho ministry_of_justice...'
\connect ministry_of_justice

-- 1. Tạo Function Trigger Audit (Định nghĩa lại function trong DB này)
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $audit_trigger$
DECLARE
    v_action CHAR(1);
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_app_name TEXT := current_setting('application_name', true);
    v_txid BIGINT := txid_current();
    v_client_addr INET := inet_client_addr();
    v_client_port INTEGER := inet_client_port();
BEGIN
    v_action := TG_OP::CHAR(1);
    IF (v_action = 'U') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        IF v_old_data = v_new_data THEN
             RETURN NEW;
        END IF;
    ELSIF (v_action = 'D') THEN
        v_old_data := to_jsonb(OLD);
    ELSIF (v_action = 'I') THEN
        v_new_data := to_jsonb(NEW);
    ELSIF (v_action = 'T') THEN
         INSERT INTO audit.audit_log (schema_name, table_name, relid, session_user_name, action_tstamp, transaction_id, application_name, client_addr, client_port, action, row_data, changed_fields, statement_only)
         VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, TG_RELID, session_user::TEXT, transaction_timestamp(), v_txid, v_app_name, v_client_addr, v_client_port, 'T', NULL, NULL, TRUE);
         RETURN NULL;
    END IF;

    IF (v_action IN ('I', 'U', 'D')) THEN
        INSERT INTO audit.audit_log (schema_name, table_name, relid, session_user_name, action_tstamp, transaction_id, application_name, client_addr, client_port, action, row_data, changed_fields, statement_only)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, TG_RELID, session_user::TEXT, transaction_timestamp(), v_txid, v_app_name, v_client_addr, v_client_port, v_action, v_old_data, v_new_data, FALSE);
    END IF;

    IF (v_action = 'D') THEN RETURN OLD; ELSE RETURN NEW; END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] Lỗi khi ghi audit log: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$audit_trigger$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = "$user", public, pg_temp;

COMMENT ON FUNCTION audit.if_modified_func() IS 'Trigger function chung để ghi lại các thay đổi (INSERT, UPDATE, DELETE) vào bảng audit.audit_log.';

-- 2. Gắn Trigger vào các bảng cần theo dõi (Ví dụ)
-- Bảng birth_certificate
DROP TRIGGER IF EXISTS audit_trigger_row ON justice.birth_certificate;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON justice.birth_certificate
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON justice.birth_certificate;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON justice.birth_certificate
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng death_certificate
DROP TRIGGER IF EXISTS audit_trigger_row ON justice.death_certificate;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON justice.death_certificate
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON justice.death_certificate;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON justice.death_certificate
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng marriage
DROP TRIGGER IF EXISTS audit_trigger_row ON justice.marriage;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON justice.marriage
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON justice.marriage;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON justice.marriage
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng divorce
DROP TRIGGER IF EXISTS audit_trigger_row ON justice.divorce;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON justice.divorce
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON justice.divorce;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON justice.divorce
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng household
DROP TRIGGER IF EXISTS audit_trigger_row ON justice.household;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON justice.household
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON justice.household;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON justice.household
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng household_member
DROP TRIGGER IF EXISTS audit_trigger_row ON justice.household_member;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON justice.household_member
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON justice.household_member;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON justice.household_member
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- (Thêm trigger cho các bảng khác của BTP nếu cần: family_relationship, population_change...)

\echo '-> Hoàn thành tạo audit triggers cho ministry_of_justice.'

-- ============================================================================
-- III. AUDIT TRIGGERS CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo '--> Tạo audit trigger function và triggers cho national_citizen_central_server...'
\connect national_citizen_central_server

-- 1. Tạo Function Trigger Audit (Định nghĩa lại function trong DB này)
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $audit_trigger$
DECLARE
    v_action CHAR(1);
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_app_name TEXT := current_setting('application_name', true);
    v_txid BIGINT := txid_current();
    v_client_addr INET := inet_client_addr();
    v_client_port INTEGER := inet_client_port();
BEGIN
    v_action := TG_OP::CHAR(1);
    IF (v_action = 'U') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        IF v_old_data = v_new_data THEN
             RETURN NEW;
        END IF;
    ELSIF (v_action = 'D') THEN
        v_old_data := to_jsonb(OLD);
    ELSIF (v_action = 'I') THEN
        v_new_data := to_jsonb(NEW);
    ELSIF (v_action = 'T') THEN
         INSERT INTO audit.audit_log (schema_name, table_name, relid, session_user_name, action_tstamp, transaction_id, application_name, client_addr, client_port, action, row_data, changed_fields, statement_only)
         VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, TG_RELID, session_user::TEXT, transaction_timestamp(), v_txid, v_app_name, v_client_addr, v_client_port, 'T', NULL, NULL, TRUE);
         RETURN NULL;
    END IF;

    IF (v_action IN ('I', 'U', 'D')) THEN
        INSERT INTO audit.audit_log (schema_name, table_name, relid, session_user_name, action_tstamp, transaction_id, application_name, client_addr, client_port, action, row_data, changed_fields, statement_only)
        VALUES (TG_TABLE_SCHEMA::TEXT, TG_TABLE_NAME::TEXT, TG_RELID, session_user::TEXT, transaction_timestamp(), v_txid, v_app_name, v_client_addr, v_client_port, v_action, v_old_data, v_new_data, FALSE);
    END IF;

    IF (v_action = 'D') THEN RETURN OLD; ELSE RETURN NEW; END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] Lỗi khi ghi audit log: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$audit_trigger$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = "$user", public, pg_temp;

COMMENT ON FUNCTION audit.if_modified_func() IS 'Trigger function chung để ghi lại các thay đổi (INSERT, UPDATE, DELETE) vào bảng audit.audit_log.';

-- 2. Gắn Trigger vào các bảng cần theo dõi (Ví dụ)
-- Bảng integrated_citizen (Quan trọng để theo dõi thay đổi sau khi tích hợp)
DROP TRIGGER IF EXISTS audit_trigger_row ON central.integrated_citizen;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON central.integrated_citizen
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON central.integrated_citizen;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON central.integrated_citizen
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- Bảng integrated_household
DROP TRIGGER IF EXISTS audit_trigger_row ON central.integrated_household;
CREATE TRIGGER audit_trigger_row
AFTER INSERT OR UPDATE OR DELETE ON central.integrated_household
FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func();

DROP TRIGGER IF EXISTS audit_trigger_stm ON central.integrated_household;
CREATE TRIGGER audit_trigger_stm
AFTER TRUNCATE ON central.integrated_household
FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func();

-- (Có thể cần audit các bảng trong schema sync, kafka, analytics nếu cần thiết)

\echo '-> Hoàn thành tạo audit triggers cho national_citizen_central_server.'

\echo '*** HOÀN THÀNH TẠO AUDIT TRIGGERS ***'
\echo 'Lưu ý: Cần kiểm tra và bổ sung trigger cho các bảng quan trọng khác nếu cần thiết.'
-- =============================================================================
-- File: database/init/create_foreign_data.sql
-- Description: Thiết lập Foreign Data Wrapper (FDW) cho phép truy cập dữ liệu
--              xuyên database giữa các hệ thống của QLDCQG.
--              **PHIÊN BẢN ĐƠN GIẢN HÓA:** Tập trung vào FDW để hỗ trợ đồng bộ
--              dữ liệu định kỳ bằng PL/pgSQL và pg_cron tại Central Server.
-- Version: 2.0
--
-- Chức năng chính:
-- 1. Thiết lập server FDW giữa ba database: BCA, BTP và server trung tâm.
-- 2. Tạo user mappings cho các tài khoản cần truy cập FDW (vd: sync_user, admin).
-- 3. Import các schema cần thiết từ DB nguồn vào các schema mirror/fdw.
-- 4. Tạo các view trên FDW tables 
-- 5. Cấu hình quyền truy cập trên các schema FDW.
-- 6. Thiết lập job pg_cron mẫu để gọi hàm đồng bộ dữ liệu (hàm cần được tạo riêng).
--
-- Lưu ý: Script này cần được chạy sau khi đã hoàn thành việc tạo database,
--        tạo schemas, tạo users và import dữ liệu tham chiếu.
-- =============================================================================

\echo '*** BẮT ĐẦU THIẾT LẬP FOREIGN DATA WRAPPER  ***'

-- ============================================================================
-- 1. THIẾT LẬP EXTENSION postgres_fdw TẠI MỖI DATABASE
-- ============================================================================
\echo 'Kiểm tra và thiết lập extension postgres_fdw tại mỗi database...'

-- 1.1 Thiết lập tại database Bộ Công an
\connect ministry_of_public_security
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
\echo '   -> Đã thiết lập extension postgres_fdw tại ministry_of_public_security.'

-- 1.2 Thiết lập tại database Bộ Tư pháp
\connect ministry_of_justice
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
\echo '   -> Đã thiết lập extension postgres_fdw tại ministry_of_justice.'

-- 1.3 Thiết lập tại database Máy chủ trung tâm
\connect national_citizen_central_server
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
\echo '   -> Đã thiết lập extension postgres_fdw tại national_citizen_central_server.'

-- ============================================================================
-- 2. TẠO SERVER FDW VÀ USER MAPPINGS CHO DATABASE BỘ CÔNG AN (DB1)
-- ============================================================================
\echo 'Bước 1: Thiết lập FDW tại ministry_of_public_security...'
\connect ministry_of_public_security

-- 2.1 Tạo server để kết nối đến database của Bộ Tư pháp (DB2)
DROP SERVER IF EXISTS justice_server CASCADE;
CREATE SERVER justice_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'ministry_of_justice'); -- Thay host/port nếu cần

-- 2.2 Tạo user mapping cho sync_user (nếu DB1 cần đọc từ DB2)
-- Thông thường sync_user sẽ chạy ở DB3, nhưng tạo sẵn nếu cần
CREATE USER MAPPING IF NOT EXISTS FOR sync_user
    SERVER justice_server
    OPTIONS (user 'sync_user', password 'SyncData@2025'); -- Thay password

-- 2.3 Tạo user mapping cho admin (nếu admin DB1 cần truy cập DB2)
CREATE USER MAPPING IF NOT EXISTS FOR security_admin
    SERVER justice_server
    OPTIONS (user 'justice_admin', password 'SecureMOJ@2025'); -- Thay password

-- 2.4 Tạo schema để chứa foreign tables từ Bộ Tư pháp (nếu chưa có)
CREATE SCHEMA IF NOT EXISTS justice_fdw;

-- 2.5 Import schema justice từ database Bộ Tư pháp
IMPORT FOREIGN SCHEMA justice
    LIMIT TO ( -- Chỉ import các bảng thực sự cần truy cập từ DB1
        birth_certificate,
        death_certificate,
        marriage,
        divorce,
        household,
        household_member
        -- family_relationship -- Có thể cần hoặc không
    )
    FROM SERVER justice_server
    INTO justice_fdw; -- Đổi tên schema fdw để rõ ràng hơn

\echo '   -> Đã import schema justice vào ministry_of_public_security.justice_fdw.'

-- 2.6 Tạo server để kết nối đến Máy chủ trung tâm (DB3) - Ít phổ biến hơn, chỉ tạo nếu DB1 cần đọc từ DB3
-- DROP SERVER IF EXISTS central_server CASCADE;
-- CREATE SERVER central_server
--     FOREIGN DATA WRAPPER postgres_fdw
--     OPTIONS (host 'localhost', port '5432', dbname 'national_citizen_central_server'); -- Thay host/port nếu cần

-- CREATE USER MAPPING IF NOT EXISTS FOR sync_user
--     SERVER central_server
--     OPTIONS (user 'sync_user', password 'SyncData@2025'); -- Thay password

-- CREATE SCHEMA IF NOT EXISTS central_fdw;
-- IMPORT FOREIGN SCHEMA central ... FROM SERVER central_server INTO central_fdw;

-- 2.7 Tạo view trên foreign tables (Tùy chọn)
-- Các view này giúp ứng dụng/người dùng truy vấn dữ liệu từ DB2 dễ dàng hơn từ DB1
CREATE OR REPLACE VIEW public_security.vw_birth_certificates AS
    SELECT * FROM justice_fdw.birth_certificate;

CREATE OR REPLACE VIEW public_security.vw_death_certificates AS
    SELECT * FROM justice_fdw.death_certificate;

CREATE OR REPLACE VIEW public_security.vw_marriages AS
    SELECT * FROM justice_fdw.marriage;

CREATE OR REPLACE VIEW public_security.vw_divorces AS
    SELECT * FROM justice_fdw.divorce;

CREATE OR REPLACE VIEW public_security.vw_households AS
    SELECT * FROM justice_fdw.household;

\echo '-> Hoàn thành thiết lập FDW tại ministry_of_public_security.'

-- ============================================================================
-- 3. TẠO SERVER FDW VÀ USER MAPPINGS CHO DATABASE BỘ TƯ PHÁP (DB2)
-- ============================================================================
\echo 'Bước 2: Thiết lập FDW tại ministry_of_justice...'
\connect ministry_of_justice

-- 3.1 Tạo server để kết nối đến database của Bộ Công an (DB1)
DROP SERVER IF EXISTS security_server CASCADE;
CREATE SERVER security_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'ministry_of_public_security'); -- Thay host/port nếu cần

-- 3.2 Tạo user mapping cho sync_user (nếu DB2 cần đọc từ DB1)
CREATE USER MAPPING IF NOT EXISTS FOR sync_user
    SERVER security_server
    OPTIONS (user 'sync_user', password 'SyncData@2025'); -- Thay password

-- 3.3 Tạo user mapping cho admin (nếu admin DB2 cần truy cập DB1)
CREATE USER MAPPING IF NOT EXISTS FOR justice_admin
    SERVER security_server
    OPTIONS (user 'security_admin', password 'SecureMPS@2025'); -- Thay password

-- 3.4 Tạo schema để chứa foreign tables từ Bộ Công an (nếu chưa có)
CREATE SCHEMA IF NOT EXISTS public_security_fdw;

-- 3.5 Import schema public_security từ database Bộ Công an
IMPORT FOREIGN SCHEMA public_security
    LIMIT TO ( -- Chỉ import các bảng thực sự cần truy cập từ DB2
        citizen,
        identification_card,
        address,
        -- citizen_address, -- Có thể cần hoặc không
        permanent_residence,
        temporary_residence,
        citizen_status
        -- criminal_record -- Có thể cần hoặc không
    )
    FROM SERVER security_server
    INTO public_security_fdw;

\echo '   -> Đã import schema public_security vào ministry_of_justice.public_security_fdw.'

-- 3.6 Tạo server để kết nối đến Máy chủ trung tâm (DB3) - Ít phổ biến hơn
-- DROP SERVER IF EXISTS central_server CASCADE;
-- CREATE SERVER central_server ...
-- CREATE USER MAPPING IF NOT EXISTS FOR sync_user SERVER central_server ...
-- CREATE SCHEMA IF NOT EXISTS central_fdw;
-- IMPORT FOREIGN SCHEMA central ... FROM SERVER central_server INTO central_fdw;

-- 3.7 Tạo view trên foreign tables (Tùy chọn)
CREATE OR REPLACE VIEW justice.vw_citizens AS
    SELECT * FROM public_security_fdw.citizen;

CREATE OR REPLACE VIEW justice.vw_identification_cards AS
    SELECT * FROM public_security_fdw.identification_card;

CREATE OR REPLACE VIEW justice.vw_citizen_statuses AS
    SELECT * FROM public_security_fdw.citizen_status;

CREATE OR REPLACE VIEW justice.vw_addresses AS
    SELECT * FROM public_security_fdw.address;

CREATE OR REPLACE VIEW justice.vw_permanent_residences AS
    SELECT * FROM public_security_fdw.permanent_residence;

\echo '-> Hoàn thành thiết lập FDW tại ministry_of_justice.'

-- ============================================================================
-- 4. TẠO SERVER FDW VÀ USER MAPPINGS CHO MÁY CHỦ TRUNG TÂM (DB3)
--    (Đây là phần quan trọng nhất cho việc đồng bộ dữ liệu)
-- ============================================================================
\echo 'Bước 3: Thiết lập FDW tại national_citizen_central_server...'
\connect national_citizen_central_server

-- 4.1 Tạo server để kết nối đến database của Bộ Công an (DB1)
DROP SERVER IF EXISTS security_server CASCADE;
CREATE SERVER security_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'ministry_of_public_security'); -- Thay host/port nếu cần

-- 4.2 Tạo server để kết nối đến database của Bộ Tư pháp (DB2)
DROP SERVER IF EXISTS justice_server CASCADE;
CREATE SERVER justice_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'ministry_of_justice'); -- Thay host/port nếu cần

-- 4.3 Tạo user mapping cho sync_user đến Bộ Công an
-- User này sẽ được dùng bởi các hàm PL/pgSQL đồng bộ chạy trong DB3
CREATE USER MAPPING IF NOT EXISTS FOR sync_user
    SERVER security_server
    OPTIONS (user 'sync_user', password 'SyncData@2025'); -- Thay password

-- 4.4 Tạo user mapping cho sync_user đến Bộ Tư pháp
CREATE USER MAPPING IF NOT EXISTS FOR sync_user
    SERVER justice_server
    OPTIONS (user 'sync_user', password 'SyncData@2025'); -- Thay password

-- 4.5 Tạo user mapping cho central_server_admin đến Bộ Công an (để quản trị viên TT truy cập nếu cần)
CREATE USER MAPPING IF NOT EXISTS FOR central_server_admin
    SERVER security_server
    OPTIONS (user 'security_admin', password 'SecureMPS@2025'); -- Thay password

-- 4.6 Tạo user mapping cho central_server_admin đến Bộ Tư pháp
CREATE USER MAPPING IF NOT EXISTS FOR central_server_admin
    SERVER justice_server
    OPTIONS (user 'justice_admin', password 'SecureMOJ@2025'); -- Thay password

-- 4.7 Import schema public_security từ database Bộ Công an vào schema mirror
-- Đảm bảo schema public_security_mirror đã được tạo (trong create_schemas.sql)
IMPORT FOREIGN SCHEMA public_security
    FROM SERVER security_server
    INTO public_security_mirror; -- Import toàn bộ schema hoặc giới hạn bảng nếu cần

\echo '   -> Đã import schema public_security vào national_citizen_central_server.public_security_mirror.'

-- 4.8 Import schema justice từ database Bộ Tư pháp vào schema mirror
-- Đảm bảo schema justice_mirror đã được tạo (trong create_schemas.sql)
IMPORT FOREIGN SCHEMA justice
    FROM SERVER justice_server
    INTO justice_mirror; -- Import toàn bộ schema hoặc giới hạn bảng nếu cần

\echo '   -> Đã import schema justice vào national_citizen_central_server.justice_mirror.'

-- 4.9 Loại bỏ các thành phần không cần thiết cho kiến trúc đơn giản
--    - Không tạo Materialized Views (trừ khi schema analytics được giữ lại và cần thiết)
--    - Không tạo bảng sync.cross_db_modification_log

\echo '   -> Đã bỏ qua việc tạo Materialized Views và bảng log đồng bộ phức tạp.'

\echo '-> Hoàn thành thiết lập FDW tại national_citizen_central_server.'

-- ============================================================================
-- 5. XEM XÉT LẠI CÁC TRIGGER ĐẢM BẢO TÍNH TOÀN VẸN XUYÊN DATABASE
-- ============================================================================
\echo 'Bước 4: Xem xét các trigger toàn vẹn tham chiếu xuyên database...'
\echo '        (Đã comment out trong phiên bản này, logic nên chuyển vào job đồng bộ)'

/* -- Bỏ comment nếu bạn thực sự cần kiểm tra tức thời và chấp nhận rủi ro hiệu năng
-- 5.1 Tạo trigger tại database Bộ Tư pháp để kiểm tra sự tồn tại của ID công dân
\connect ministry_of_justice

-- Hàm trigger kiểm tra sự tồn tại của citizen_id tại Bộ Công an
CREATE OR REPLACE FUNCTION justice.validate_citizen_id_exists()
RETURNS TRIGGER AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Kiểm tra sự tồn tại của citizen_id trong bảng citizen của Bộ Công an
    SELECT EXISTS(
        SELECT 1 FROM public_security_fdw.citizen
        WHERE citizen_id = NEW.citizen_id AND status = TRUE
    ) INTO v_exists;

    IF NOT v_exists THEN
        RAISE EXCEPTION 'Citizen ID % does not exist in public_security.citizen or is inactive', NEW.citizen_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Gắn trigger cho các bảng cần kiểm tra citizen_id
DROP TRIGGER IF EXISTS validate_citizen_id_trigger ON justice.birth_certificate;
CREATE TRIGGER validate_citizen_id_trigger
BEFORE INSERT OR UPDATE OF citizen_id ON justice.birth_certificate
FOR EACH ROW EXECUTE FUNCTION justice.validate_citizen_id_exists();

-- ... (Tương tự cho death_certificate, marriage) ...

\echo '   -> Đã tạo (hoặc bỏ qua) các trigger kiểm tra tính toàn vẹn citizen_id tại ministry_of_justice.'

-- 5.2 Tạo các trigger tại database Bộ Công an để đồng bộ thay đổi trạng thái
\connect ministry_of_public_security

-- Hàm trigger cập nhật death_status khi có giấy khai tử
CREATE OR REPLACE FUNCTION public_security.sync_death_certificate_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Khi có giấy khai tử mới, cập nhật trạng thái công dân thành 'Đã mất'
    UPDATE public_security.citizen
    SET death_status = 'Đã mất',
        updated_at = CURRENT_TIMESTAMP
    WHERE citizen_id = NEW.citizen_id
      AND death_status <> 'Đã mất';

    -- Thêm bản ghi vào citizen_status
    INSERT INTO public_security.citizen_status (
        citizen_id, status_type, status_date, description, cause, location,
        document_number, document_date, certificate_id, is_current,
        region_id, province_id, geographical_region
    )
    VALUES (
        NEW.citizen_id, 'Đã mất', NEW.date_of_death, 'Khai tử từ Bộ Tư pháp',
        NEW.cause_of_death, NEW.place_of_death, NEW.death_certificate_no,
        NEW.registration_date, NEW.death_certificate_id::TEXT, TRUE,
        NEW.region_id, NEW.province_id, NEW.geographical_region
    ) ON CONFLICT (citizen_id) WHERE is_current = TRUE DO UPDATE -- Xử lý nếu đã có status khác là current
    SET status_type = EXCLUDED.status_type,
        status_date = EXCLUDED.status_date,
        description = EXCLUDED.description,
        cause = EXCLUDED.cause,
        location = EXCLUDED.location,
        document_number = EXCLUDED.document_number,
        document_date = EXCLUDED.document_date,
        certificate_id = EXCLUDED.certificate_id,
        updated_at = CURRENT_TIMESTAMP;

    -- Cập nhật các bản ghi status cũ của citizen này thành is_current = FALSE
    UPDATE public_security.citizen_status
    SET is_current = FALSE, updated_at = CURRENT_TIMESTAMP
    WHERE citizen_id = NEW.citizen_id AND status_id <> currval(pg_get_serial_sequence('public_security.citizen_status', 'status_id'));


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Gắn trigger cho bảng death_certificate từ Bộ Tư pháp
DROP TRIGGER IF EXISTS sync_death_certificate_status_trigger ON justice_fdw.death_certificate; -- Sử dụng schema FDW đúng
CREATE TRIGGER sync_death_certificate_status_trigger
AFTER INSERT OR UPDATE ON justice_fdw.death_certificate -- Bảng foreign table
FOR EACH ROW EXECUTE FUNCTION public_security.sync_death_certificate_status();

\echo '   -> Đã tạo (hoặc bỏ qua) các trigger đồng bộ trạng thái công dân tại ministry_of_public_security.'
*/

-- ============================================================================
-- 6. CẤU HÌNH CÁC PERMISSIONS CHO FDW SCHEMAS
-- ============================================================================
\echo 'Bước 5: Cấu hình permissions cho FDW schemas...'

-- 6.1 Phân quyền tại database Bộ Công an
\connect ministry_of_public_security
GRANT USAGE ON SCHEMA justice_fdw TO security_reader, security_writer, sync_user; -- Cấp quyền cho sync_user nếu cần đọc
GRANT SELECT ON ALL TABLES IN SCHEMA justice_fdw TO security_reader, security_writer, sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice_fdw GRANT SELECT ON TABLES TO security_reader, security_writer, sync_user;
-- GRANT USAGE ON SCHEMA central_fdw ... (Nếu có)
-- GRANT SELECT ON ALL TABLES IN SCHEMA central_fdw ... (Nếu có)

-- 6.2 Phân quyền tại database Bộ Tư pháp
\connect ministry_of_justice
GRANT USAGE ON SCHEMA public_security_fdw TO justice_reader, justice_writer, sync_user; -- Cấp quyền cho sync_user nếu cần đọc
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_fdw TO justice_reader, justice_writer, sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_fdw GRANT SELECT ON TABLES TO justice_reader, justice_writer, sync_user;
-- GRANT USAGE ON SCHEMA central_fdw ... (Nếu có)
-- GRANT SELECT ON ALL TABLES IN SCHEMA central_fdw ... (Nếu có)

-- 6.3 Phân quyền tại database Máy chủ trung tâm
\connect national_citizen_central_server
-- Quyền cho sync_user đọc dữ liệu nguồn để đồng bộ
GRANT USAGE ON SCHEMA public_security_mirror TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO sync_user;

GRANT USAGE ON SCHEMA justice_mirror TO sync_user;
GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO sync_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO sync_user;

-- Quyền cho central_server_reader đọc dữ liệu mirror (nếu cần truy vấn trực tiếp FDW)
GRANT USAGE ON SCHEMA public_security_mirror TO central_server_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public_security_mirror TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public_security_mirror GRANT SELECT ON TABLES TO central_server_reader;

GRANT USAGE ON SCHEMA justice_mirror TO central_server_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA justice_mirror TO central_server_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA justice_mirror GRANT SELECT ON TABLES TO central_server_reader;


\echo '   -> Đã cấu hình permissions cho các FDW schemas.'

-- ============================================================================
-- 7. TẠO JOB ĐỊNH KỲ ĐỂ GỌI HÀM ĐỒNG BỘ DỮ LIỆU
-- ============================================================================
\echo 'Bước 6: Tạo job định kỳ mẫu cho việc đồng bộ dữ liệu...'
\connect national_citizen_central_server

-- Sử dụng extension pg_cron để lập lịch các job
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Job mẫu để gọi hàm đồng bộ chính (chạy mỗi 15 phút)
-- **LƯU Ý QUAN TRỌNG:** Bạn cần tạo hàm PL/pgSQL tên là 'central.sync_all_data()' (hoặc tên khác)
-- chứa logic đồng bộ dữ liệu trước khi job này có thể chạy thành công.
SELECT cron.schedule(
    job_name := 'central_data_sync_job', -- Đặt tên job
    schedule := '*/15 * * * *',          -- Lịch chạy: Mỗi 15 phút
    command := $$SELECT central.sync_all_data();$$ -- Lệnh SQL để chạy hàm đồng bộ
);

\echo '   -> Đã tạo job pg_cron mẫu để gọi hàm đồng bộ định kỳ (cần tạo hàm central.sync_all_data()).'
\echo '      Vui lòng điều chỉnh lịch chạy (schedule) và tên hàm (command) cho phù hợp.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH THIẾT LẬP FOREIGN DATA WRAPPER (PHIÊN BẢN ĐƠN GIẢN HÓA) ***'
\echo '-> Đã cấu hình FDW server và user mappings giữa các database.'
\echo '-> Đã import các schema cần thiết qua FDW vào các schema mirror tại Central Server.'
\echo '-> Đã cấu hình permissions và tạo job pg_cron mẫu để thực thi đồng bộ.'
\echo '-> Bước tiếp theo quan trọng: Xây dựng các hàm PL/pgSQL đồng bộ dữ liệu trong Central Server.'
```

**Giải thích các thay đổi chính:**

1.  **Loại bỏ Bảng Log Đồng bộ:** Phần tạo bảng `sync.cross_db_modification_log` (mục 4.10 cũ) đã bị xóa. Cơ chế đồng bộ chính sẽ dựa vào việc quét dữ liệu thay đổi từ nguồn thông qua FDW trong các job định kỳ.
2.  **Comment Out Trigger Liên DB:** Các trigger phức tạp dùng FDW để cập nhật/kiểm tra dữ liệu tức thời giữa các DB (mục 5 cũ) đã được comment out. Lý do là chúng có thể gây vấn đề về hiệu năng và logic đồng bộ chính sẽ nằm trong các job định kỳ tại DB3. Bạn có thể bỏ comment nếu hiểu rõ và chấp nhận rủi ro.
3.  **Loại bỏ Materialized View:** Phần tạo Materialized View `analytics.mv_citizen_basic_info` và hàm refresh của nó (mục 4.9 cũ) đã bị xóa, giả định rằng phần analytics phức tạp này được đơn giản hóa hoặc loại bỏ trong phạm vi đồ án.
4.  **Điều chỉnh Job pg_cron:** Job phân tích FDW statistics và refresh MV đã bị xóa. Thay vào đó, một job mẫu được thêm vào để gọi hàm đồng bộ PL/pgSQL chính (`central.sync_all_data()`) mà bạn **cần phải tự tạo**.
5.  **Nhấn mạnh Vai trò của PL/pgSQL:** Các comment nhấn mạnh rằng logic đồng bộ, biến đổi, và giải quyết xung đột giờ đây cần được thực hiện trong các hàm PL/pgSQL chạy trên DB3 và được gọi bởi `pg_cron`.
6.  **Schema FDW:** Tên schema chứa foreign table ở DB1 và DB2 được đổi thành `justice_fdw` và `public_security_fdw` để rõ ràng hơn (thay vì dùng tên schema gốc). Schema ở DB3 vẫn là `public_security_mirror` và `justice_mirror`.

File này giờ đây tập trung vào việc thiết lập kết nối FDW, tạo nền tảng để bạn xây dựng logic đồng bộ dữ liệu bằng PL/pgSQL trong database trung t
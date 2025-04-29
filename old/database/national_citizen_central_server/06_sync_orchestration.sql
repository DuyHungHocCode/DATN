-- File: national_citizen_central_server/06_sync_orchestration.sql
-- Description: Lập lịch (schedule) cho công việc đồng bộ hóa dữ liệu tự động
--              từ BCA và BTP vào DB Trung tâm bằng cách sử dụng pg_cron.
-- Version: 1.0 (Theo cấu trúc đơn giản hóa)
--
-- Dependencies:
-- - Extension 'pg_cron' đã được cài đặt và cấu hình đúng trên DB Trung tâm.
--   (Cần thêm 'pg_cron' vào shared_preload_libraries và đặt cron.database_name
--    trong postgresql.conf và khởi động lại server).
-- - Function thực hiện logic đồng bộ hóa đã tồn tại trong schema sync
--   (ví dụ: sync.run_synchronization() - đã định nghĩa trong 03_functions.sql).
-- - Role thực thi job (thường là postgres hoặc user được cấu hình cho pg_cron)
--   có quyền EXECUTE trên function sync.run_synchronization().
-- =============================================================================

\echo '*** BẮT ĐẦU LẬP LỊCH ĐỒNG BỘ DỮ LIỆU BẰNG PG_CRON ***'
\connect national_citizen_central_server

BEGIN;

-- ============================================================================
-- 1. ĐỊNH NGHĨA CÁC BIẾN CHO JOB
-- ============================================================================

-- Đặt tên rõ ràng cho công việc đồng bộ để dễ quản lý
\set sync_job_name '''Run Central Data Synchronization'''

-- Đặt lệnh SQL gọi hàm đồng bộ chính
-- **QUAN TRỌNG:** Đảm bảo tên hàm này ('sync.run_synchronization()') tồn tại và đúng.
\set sync_function '''SELECT sync.run_synchronization();'''

-- Đặt lịch chạy theo cú pháp cron
-- '*/15 * * * *' : Chạy mỗi 15 phút (vào phút 0, 15, 30, 45)
-- '0 * * * *'   : Chạy mỗi giờ (vào phút 00)
-- '0 2 * * *'   : Chạy vào 2 giờ sáng mỗi ngày
-- Chọn lịch phù hợp với đồ án của bạn. Chạy thường xuyên quá có thể không cần thiết.
\set sync_schedule '''*/15 * * * *''' -- Ví dụ: chạy mỗi 15 phút

-- ============================================================================
-- 2. HỦY LỊCH CŨ (NẾU CÓ) ĐỂ TRÁNH TRÙNG LẶP
-- ============================================================================
\echo '--> 1. Hủy lịch công việc cũ (nếu có) với tên:' :sync_job_name '...'
-- Sử dụng cron.unschedule để xóa job cũ theo tên.
-- Lệnh này sẽ không báo lỗi nếu job không tồn tại, giúp script chạy lại an toàn.
SELECT cron.unschedule(:sync_job_name);

-- ============================================================================
-- 3. LẬP LỊCH CÔNG VIỆC MỚI
-- ============================================================================
\echo '--> 2. Lập lịch công việc mới để chạy function đồng bộ...'
\echo '       - Tên Job    :' :sync_job_name
\echo '       - Lịch chạy :' :sync_schedule
\echo '       - Lệnh chạy  :' :sync_function

-- Sử dụng cron.schedule để tạo job mới
-- Job sẽ chạy câu lệnh SELECT gọi function đồng bộ trong database hiện tại (national_citizen_central_server)
-- với quyền của user chạy background worker pg_cron (thường là postgres).
SELECT cron.schedule(
    job_name := :sync_job_name,   -- Tên của công việc
    schedule := :sync_schedule,   -- Lịch chạy (định dạng cron)
    command  := :sync_function    -- Câu lệnh SQL cần thực thi
);

\echo '-> Đã lập lịch công việc đồng bộ dữ liệu thành công.'
\echo '-> Lưu ý quan trọng:'
\echo '   - Đảm bảo extension pg_cron được cấu hình đúng trong postgresql.conf.'
\echo '   - Đảm bảo function' :sync_function 'tồn tại và logic bên trong chính xác.'
\echo '   - Đảm bảo role thực thi pg_cron có quyền EXECUTE trên function đó.'

COMMIT;

-- ============================================================================
-- KIỂM TRA (TÙY CHỌN)
-- ============================================================================
-- Bạn có thể kiểm tra danh sách các job đã được lập lịch bằng câu lệnh sau trong psql
-- khi đang kết nối vào database national_citizen_central_server:
--
-- SELECT * FROM cron.job;
--
-- Để xem lịch sử chạy của các job (nếu pg_cron được cấu hình ghi log vào bảng):
--
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 100;
-- ============================================================================

\echo '*** HOÀN THÀNH LẬP LỊCH ĐỒNG BỘ DỮ LIỆU BẰNG PG_CRON ***'
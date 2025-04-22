-- =============================================================================
-- File: national_citizen_central_server/fdw_and_sync/02_sync_orchestration.sql
-- Description: Lập lịch (schedule) cho công việc đồng bộ hóa dữ liệu tự động
--              từ BCA và BTP vào DB Trung tâm bằng cách sử dụng pg_cron.
-- Version: 3.0 (Using pg_cron for scheduling)
--
-- Dependencies:
-- - Extension 'pg_cron' đã được cài đặt và cấu hình trên DB Trung tâm.
-- - Function thực hiện logic đồng bộ hóa đã tồn tại (ví dụ: sync.run_synchronization()).
--   Function này cần được tạo trong file functions/sync_logic.sql hoặc tương tự.
-- - Role thực thi job (thường là postgres hoặc user có quyền) có quyền EXECUTE trên function đồng bộ.
-- =============================================================================

\echo '--> Lập lịch công việc đồng bộ dữ liệu tự động bằng pg_cron...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
\connect national_citizen_central_server

BEGIN;

-- ============================================================================
-- 1. HỦY LỊCH CŨ (NẾU CÓ) ĐỂ TRÁNH TRÙNG LẶP
-- ============================================================================
-- Đặt tên cho công việc đồng bộ để dễ quản lý và đảm bảo có thể hủy lịch cũ
\set sync_job_name '''Run Central Data Synchronization'''

\echo '    -> Bước 1: Hủy lịch công việc cũ (nếu có) với tên:' :sync_job_name '...'
-- Sử dụng cron.unschedule để xóa job cũ theo tên
-- Lệnh này sẽ không báo lỗi nếu job không tồn tại.
SELECT cron.unschedule(:'sync_job_name');

-- ============================================================================
-- 2. LẬP LỊCH CÔNG VIỆC MỚI
-- ============================================================================
\echo '    -> Bước 2: Lập lịch công việc mới để chạy function đồng bộ...'

-- Giả định function thực hiện toàn bộ logic đồng bộ là: sync.run_synchronization()
-- Function này sẽ đọc từ các schema mirror, xử lý và ghi vào schema central.
-- **QUAN TRỌNG:** Bạn cần thay thế 'sync.run_synchronization()' bằng tên function thực tế của bạn nếu khác.
\set sync_function '''SELECT sync.run_synchronization();'''

-- Lập lịch chạy định kỳ. Ví dụ: chạy mỗi 15 phút.
-- Cú pháp cron: Phút(0-59) Giờ(0-23) NgàyTrongTháng(1-31) Tháng(1-12) NgàyTrongTuần(0-7, 0 và 7 là Chủ Nhật)
-- '*/15 * * * *' : Chạy vào các phút 0, 15, 30, 45 của mỗi giờ, mỗi ngày.
-- Ví dụ khác:
-- '0 * * * *'   : Chạy vào phút thứ 0 của mỗi giờ (đầu giờ).
-- '0 0 * * *'   : Chạy vào 00:00 mỗi ngày (nửa đêm).
-- '0 */6 * * *' : Chạy mỗi 6 giờ (vào 00:00, 06:00, 12:00, 18:00).
-- '30 2 * * 1-5': Chạy vào 02:30 sáng các ngày từ Thứ Hai đến Thứ Sáu.
-- Chọn lịch phù hợp với yêu cầu về tần suất cập nhật và tải hệ thống.
\set sync_schedule '''*/15 * * * *''' -- Chạy mỗi 15 phút

\echo '       - Lập lịch chạy:' :sync_function 'với tần suất:' :sync_schedule '...'

-- Sử dụng cron.schedule để tạo job mới
-- Job sẽ chạy câu lệnh SELECT gọi function đồng bộ trong database hiện tại (national_citizen_central_server)
SELECT cron.schedule(
    :'sync_job_name',   -- Tên của công việc (đã định nghĩa ở trên)
    :'sync_schedule',   -- Lịch chạy (định dạng cron, đã định nghĩa ở trên)
    :'sync_function'    -- Câu lệnh SQL cần thực thi (đã định nghĩa ở trên)
);

\echo '-> Đã lập lịch công việc đồng bộ dữ liệu.'
\echo '-> Tên job:' :sync_job_name
\echo '-> Lịch chạy:' :sync_schedule
\echo '-> Function được gọi:' :sync_function
\echo '-> Lưu ý: Đảm bảo function đồng bộ hóa tồn tại và role thực thi pg_cron (thường là postgres) có quyền EXECUTE trên function đó.'

COMMIT;

-- ============================================================================
-- KIỂM TRA (TÙY CHỌN)
-- ============================================================================
-- Bạn có thể kiểm tra danh sách các job đã được lập lịch bằng câu lệnh sau trong psql
-- khi đang kết nối vào database national_citizen_central_server:
-- SELECT * FROM cron.job;
--
-- Để xem lịch sử chạy của các job (nếu pg_cron được cấu hình ghi log vào bảng):
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 100;
-- ============================================================================

\echo '*** HOÀN THÀNH LẬP LỊCH ĐỒNG BỘ DỮ LIỆU BẰNG PG_CRON ***'
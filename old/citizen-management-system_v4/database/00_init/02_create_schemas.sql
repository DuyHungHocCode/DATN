-- =============================================================================
-- File: 00_init/02_create_schemas.sql
-- Description: Script tạo các schema cần thiết trong 3 database của hệ thống QLDCQG.
-- Version: 3.0 (Aligned with Microservices Structure)
--
-- Chức năng chính:
-- 1. Tạo các schemas cần thiết trong database ministry_of_public_security.
-- 2. Tạo các schemas cần thiết trong database ministry_of_justice.
-- 3. Tạo các schemas cần thiết trong database national_citizen_central_server.
--
-- Yêu cầu: Chạy sau script 00_init/01_create_databases.sql.
--          Cần quyền tạo schema trong các database (thường là owner hoặc superuser).
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO SCHEMAS ***'

-- ============================================================================
-- 1. TẠO SCHEMAS CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo 'Bước 1: Tạo schemas cho database ministry_of_public_security...'
-- Kết nối đến database của Bộ Công an
\connect ministry_of_public_security

-- Tạo schema chính cho dữ liệu nghiệp vụ của Bộ Công an
CREATE SCHEMA IF NOT EXISTS public_security;
COMMENT ON SCHEMA public_security IS '[QLDCQG-BCA] Schema chính quản lý dữ liệu dân cư';

-- Tạo schema chứa dữ liệu tham chiếu dùng chung (sẽ được nạp dữ liệu từ thư mục common)
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-BCA] Schema chứa dữ liệu tham chiếu dùng chung (cục bộ)';

-- Tạo schema cho việc ghi log kiểm toán (audit trail)
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BCA] Schema chứa dữ liệu nhật ký thay đổi (audit log)';

-- Tạo schema cho các hàm/procedure cung cấp API nội bộ (nếu ứng dụng BCA cần)
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-BCA] Schema chứa functions/procedures cung cấp API nội bộ (nếu có)';

-- Tạo schema chứa các đối tượng quản lý phân vùng dữ liệu
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BCA] Schema chứa cấu hình và hàm hỗ trợ phân vùng dữ liệu';

-- Tạo schema cho các view/function phục vụ báo cáo, thống kê riêng của BCA
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-BCA] Schema chứa views/functions phục vụ báo cáo, thống kê';

-- Tạo schema chứa dữ liệu tạm thời (staging area) cho các quá trình ETL hoặc nhập liệu
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-BCA] Schema chứa dữ liệu tạm thời cho các quá trình ETL/nhập liệu (nếu có)';

-- Tạo schema chứa các hàm, kiểu dữ liệu, hoặc đối tượng tiện ích chung dùng nội bộ BCA
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-BCA] Schema chứa các hàm và đối tượng tiện ích chung';

\echo '-> Đã tạo schemas cho ministry_of_public_security.'

-- ============================================================================
-- 2. TẠO SCHEMAS CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo 'Bước 2: Tạo schemas cho database ministry_of_justice...'
-- Kết nối đến database của Bộ Tư pháp
\connect ministry_of_justice

-- Tạo schema chính cho dữ liệu nghiệp vụ của Bộ Tư pháp (hộ tịch)
CREATE SCHEMA IF NOT EXISTS justice;
COMMENT ON SCHEMA justice IS '[QLDCQG-BTP] Schema chính quản lý dữ liệu hộ tịch';

-- Tạo schema chứa dữ liệu tham chiếu dùng chung (sẽ được nạp dữ liệu từ thư mục common)
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-BTP] Schema chứa dữ liệu tham chiếu dùng chung (cục bộ)';

-- Tạo schema cho việc ghi log kiểm toán (audit trail)
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BTP] Schema chứa dữ liệu nhật ký thay đổi (audit log)';

-- Tạo schema cho các hàm/procedure cung cấp API nội bộ (nếu ứng dụng BTP cần)
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-BTP] Schema chứa functions/procedures cung cấp API nội bộ (nếu có)';

-- Tạo schema chứa các đối tượng quản lý phân vùng dữ liệu
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BTP] Schema chứa cấu hình và hàm hỗ trợ phân vùng dữ liệu';

-- Tạo schema cho các view/function phục vụ báo cáo, thống kê riêng của BTP
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-BTP] Schema chứa views/functions phục vụ báo cáo, thống kê';

-- Tạo schema chứa dữ liệu tạm thời (staging area) cho các quá trình ETL hoặc nhập liệu
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-BTP] Schema chứa dữ liệu tạm thời cho các quá trình ETL/nhập liệu (nếu có)';

-- Tạo schema chứa các hàm, kiểu dữ liệu, hoặc đối tượng tiện ích chung dùng nội bộ BTP
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-BTP] Schema chứa các hàm và đối tượng tiện ích chung';

\echo '-> Đã tạo schemas cho ministry_of_justice.'

-- ============================================================================
-- 3. TẠO SCHEMAS CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo 'Bước 3: Tạo schemas cho database national_citizen_central_server...'
-- Kết nối đến database Trung tâm
\connect national_citizen_central_server

-- Tạo schema chính chứa dữ liệu đã được tích hợp từ BCA và BTP
CREATE SCHEMA IF NOT EXISTS central;
COMMENT ON SCHEMA central IS '[QLDCQG-TT] Schema chứa dữ liệu dân cư và hộ tịch đã được tích hợp';

-- Tạo schema chứa dữ liệu tham chiếu dùng chung (sẽ được nạp dữ liệu từ thư mục common)
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-TT] Schema chứa dữ liệu tham chiếu dùng chung (cục bộ)';

-- Tạo schema cho việc ghi log kiểm toán (audit trail) trên dữ liệu tích hợp
CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-TT] Schema chứa dữ liệu nhật ký thay đổi (audit log)';

-- Tạo schema chứa các cấu hình, bảng trạng thái, và logic (hàm) cho quá trình đồng bộ hóa
CREATE SCHEMA IF NOT EXISTS sync;
COMMENT ON SCHEMA sync IS '[QLDCQG-TT] Schema chứa cấu hình, bảng trạng thái và logic cho quá trình đồng bộ hóa dữ liệu';

-- Tạo schema để chứa các foreign tables phản chiếu dữ liệu từ Bộ Công an (sử dụng FDW)
CREATE SCHEMA IF NOT EXISTS public_security_mirror;
COMMENT ON SCHEMA public_security_mirror IS '[QLDCQG-TT] Schema chứa các foreign tables phản chiếu dữ liệu từ Bộ Công an (qua FDW)';

-- Tạo schema để chứa các foreign tables phản chiếu dữ liệu từ Bộ Tư pháp (sử dụng FDW)
CREATE SCHEMA IF NOT EXISTS justice_mirror;
COMMENT ON SCHEMA justice_mirror IS '[QLDCQG-TT] Schema chứa các foreign tables phản chiếu dữ liệu từ Bộ Tư pháp (qua FDW)';

-- Tạo schema cho các hàm/procedure cung cấp API dữ liệu tích hợp (nếu ứng dụng TT cần)
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-TT] Schema chứa functions/procedures cung cấp API dữ liệu tích hợp (nếu có)';

-- Tạo schema chứa các đối tượng quản lý phân vùng dữ liệu cho các bảng tích hợp
CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-TT] Schema chứa cấu hình và hàm hỗ trợ phân vùng dữ liệu';

-- Tạo schema cho các view/function phục vụ báo cáo, thống kê tổng hợp từ dữ liệu tích hợp
CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-TT] Schema chứa views/functions phục vụ báo cáo, thống kê tổng hợp';

-- Tạo schema chứa dữ liệu tạm thời (staging area) cho quá trình đồng bộ hóa và tích hợp
CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-TT] Schema chứa dữ liệu tạm thời cho quá trình ETL/đồng bộ hóa';

-- Tạo schema chứa các hàm, kiểu dữ liệu, hoặc đối tượng tiện ích chung dùng nội bộ TT
CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-TT] Schema chứa các hàm và đối tượng tiện ích chung';

\echo '-> Đã tạo schemas cho national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO SCHEMAS ***'
\echo '-> Đã tạo các schemas cần thiết cho 3 database.'
\echo '-> Bước tiếp theo: Chạy 01_common/01_extensions.sql để cài đặt extensions.'


-- =============================================================================
-- File: 00_init/02_create_schemas.sql
-- Description: Tạo các schema cần thiết trong 03 database của Hệ thống QLDCQG.
-- Version: 3.1 (Refined comments and structure)
--
-- Yêu cầu: Chạy sau script 00_init/01_create_databases.sql.
--          Cần quyền tạo schema trong các database.
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO SCHEMAS ***'

-- === 1. TẠO SCHEMAS CHO DATABASE BỘ CÔNG AN (ministry_of_public_security) ===

\echo '[Bước 1] Tạo schemas cho database: ministry_of_public_security...'
\connect ministry_of_public_security

CREATE SCHEMA IF NOT EXISTS public_security;
COMMENT ON SCHEMA public_security IS '[QLDCQG-BCA] Schema chính chứa dữ liệu nghiệp vụ của Bộ Công an.';

CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-BCA] Schema chứa các bảng dữ liệu tham chiếu dùng chung.';

CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BCA] Schema chứa bảng ghi nhật ký thay đổi dữ liệu (audit log).';

CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BCA] Schema chứa cấu hình và các đối tượng hỗ trợ phân vùng dữ liệu.';

CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-BCA] Schema chứa functions/procedures cung cấp API nội bộ (nếu có).';

CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-BCA] Schema chứa views/functions phục vụ báo cáo, thống kê.';

CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-BCA] Schema chứa dữ liệu tạm thời cho các quá trình ETL/nhập liệu.';

CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-BCA] Schema chứa các hàm và đối tượng tiện ích chung.';

\echo '   -> Hoàn thành tạo schemas cho ministry_of_public_security.'

-- === 2. TẠO SCHEMAS CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice) ===

\echo '[Bước 2] Tạo schemas cho database: ministry_of_justice...'
\connect ministry_of_justice

CREATE SCHEMA IF NOT EXISTS justice;
COMMENT ON SCHEMA justice IS '[QLDCQG-BTP] Schema chính chứa dữ liệu nghiệp vụ hộ tịch của Bộ Tư pháp.';

CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-BTP] Schema chứa các bảng dữ liệu tham chiếu dùng chung.';

CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-BTP] Schema chứa bảng ghi nhật ký thay đổi dữ liệu (audit log).';

CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-BTP] Schema chứa cấu hình và các đối tượng hỗ trợ phân vùng dữ liệu.';

CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-BTP] Schema chứa functions/procedures cung cấp API nội bộ (nếu có).';

CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-BTP] Schema chứa views/functions phục vụ báo cáo, thống kê.';

CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-BTP] Schema chứa dữ liệu tạm thời cho các quá trình ETL/nhập liệu.';

CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-BTP] Schema chứa các hàm và đối tượng tiện ích chung.';

\echo '   -> Hoàn thành tạo schemas cho ministry_of_justice.'

-- === 3. TẠO SCHEMAS CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server) ===

\echo '[Bước 3] Tạo schemas cho database: national_citizen_central_server...'
\connect national_citizen_central_server

CREATE SCHEMA IF NOT EXISTS central;
COMMENT ON SCHEMA central IS '[QLDCQG-TT] Schema chứa dữ liệu dân cư và hộ tịch đã được tích hợp.';

CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS '[QLDCQG-TT] Schema chứa các bảng dữ liệu tham chiếu dùng chung.';

CREATE SCHEMA IF NOT EXISTS audit;
COMMENT ON SCHEMA audit IS '[QLDCQG-TT] Schema chứa bảng ghi nhật ký thay đổi dữ liệu (audit log) trên dữ liệu tích hợp.';

CREATE SCHEMA IF NOT EXISTS partitioning;
COMMENT ON SCHEMA partitioning IS '[QLDCQG-TT] Schema chứa cấu hình và các đối tượng hỗ trợ phân vùng dữ liệu.';

CREATE SCHEMA IF NOT EXISTS sync;
COMMENT ON SCHEMA sync IS '[QLDCQG-TT] Schema chứa cấu hình, trạng thái và logic cho quá trình đồng bộ hóa dữ liệu.';

-- Schema chứa foreign tables ánh xạ dữ liệu từ BCA
CREATE SCHEMA IF NOT EXISTS public_security_mirror;
COMMENT ON SCHEMA public_security_mirror IS '[QLDCQG-TT] Schema chứa foreign tables ánh xạ dữ liệu từ Bộ Công an (qua FDW).';

-- Schema chứa foreign tables ánh xạ dữ liệu từ BTP
CREATE SCHEMA IF NOT EXISTS justice_mirror;
COMMENT ON SCHEMA justice_mirror IS '[QLDCQG-TT] Schema chứa foreign tables ánh xạ dữ liệu từ Bộ Tư pháp (qua FDW).';

CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS '[QLDCQG-TT] Schema chứa functions/procedures cung cấp API dữ liệu tích hợp (nếu có).';

CREATE SCHEMA IF NOT EXISTS reports;
COMMENT ON SCHEMA reports IS '[QLDCQG-TT] Schema chứa views/functions phục vụ báo cáo, thống kê tổng hợp.';

CREATE SCHEMA IF NOT EXISTS staging;
COMMENT ON SCHEMA staging IS '[QLDCQG-TT] Schema chứa dữ liệu tạm thời cho quá trình ETL/đồng bộ hóa.';

CREATE SCHEMA IF NOT EXISTS utility;
COMMENT ON SCHEMA utility IS '[QLDCQG-TT] Schema chứa các hàm và đối tượng tiện ích chung.';

\echo '   -> Hoàn thành tạo schemas cho national_citizen_central_server.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO SCHEMAS ***'
\echo '-> Đã tạo các schemas cần thiết cho 3 database.'
\echo '-> Bước tiếp theo: Chạy script 01_common/01_extensions.sql để cài đặt extensions.'
```

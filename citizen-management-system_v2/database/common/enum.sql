-- Script định nghĩa các kiểu dữ liệu enum cho hệ thống CSDL quản lý dân cư quốc gia
-- File: database/common/enum.sql

-- ============================================================================
-- 1. TẠO ENUM CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo 'Tạo kiểu dữ liệu enum cho database Bộ Công an...'
\connect ministry_of_public_security

-- 1.1 ENUM THÔNG TIN CƠ BẢN CÔNG DÂN
-- Giới tính
DROP TYPE IF EXISTS gender_type CASCADE;
CREATE TYPE gender_type AS ENUM ('Nam', 'Nữ', 'Khác');

-- Nhóm máu
DROP TYPE IF EXISTS blood_type CASCADE;
CREATE TYPE blood_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Không xác định');

-- Trạng thái sống/mất
DROP TYPE IF EXISTS death_status CASCADE;
CREATE TYPE death_status AS ENUM ('Còn sống', 'Đã mất', 'Mất tích');

-- Tình trạng hôn nhân
DROP TYPE IF EXISTS marital_status CASCADE;
CREATE TYPE marital_status AS ENUM ('Độc thân', 'Đã kết hôn', 'Đã ly hôn', 'Góa', 'Ly thân');

-- Học vấn
DROP TYPE IF EXISTS education_level CASCADE;
CREATE TYPE education_level AS ENUM (
    'Chưa đi học', 
    'Tiểu học', 
    'Trung học cơ sở', 
    'Trung học phổ thông', 
    'Trung cấp', 
    'Cao đẳng', 
    'Đại học', 
    'Thạc sĩ', 
    'Tiến sĩ',
    'Khác'
);

-- 1.2 ENUM CĂN CƯỚC CÔNG DÂN
-- Loại thẻ CCCD
DROP TYPE IF EXISTS card_type CASCADE;
CREATE TYPE card_type AS ENUM ('CMND 9 số', 'CMND 12 số', 'CCCD', 'CCCD gắn chip');

-- Trạng thái CCCD
DROP TYPE IF EXISTS card_status CASCADE;
CREATE TYPE card_status AS ENUM ('Đang sử dụng', 'Hết hạn', 'Mất', 'Hỏng', 'Thu hồi', 'Đã thay thế', 'Tạm giữ');

-- 1.3 ENUM SINH TRẮC HỌC
-- Loại sinh trắc học
DROP TYPE IF EXISTS biometric_type CASCADE;
CREATE TYPE biometric_type AS ENUM ('Vân tay', 'Khuôn mặt', 'Mống mắt', 'Giọng nói', 'ADN');

-- Chất lượng sinh trắc học
DROP TYPE IF EXISTS biometric_quality CASCADE;
CREATE TYPE biometric_quality AS ENUM ('Kém', 'Trung bình', 'Khá', 'Tốt', 'Rất tốt');

-- Vị trí vân tay
DROP TYPE IF EXISTS fingerprint_position CASCADE;
CREATE TYPE fingerprint_position AS ENUM (
    'Ngón cái trái', 'Ngón trỏ trái', 'Ngón giữa trái', 'Ngón áp út trái', 'Ngón út trái',
    'Ngón cái phải', 'Ngón trỏ phải', 'Ngón giữa phải', 'Ngón áp út phải', 'Ngón út phải'
);

-- 1.4 ENUM ĐỊA CHỈ & CƯ TRÚ
-- Loại địa chỉ
DROP TYPE IF EXISTS address_type CASCADE;
CREATE TYPE address_type AS ENUM ('Thường trú', 'Tạm trú', 'Nơi ở hiện tại', 'Công ty', 'Học tập', 'Khác');

-- Loại thay đổi cư trú
DROP TYPE IF EXISTS residence_change_type CASCADE;
CREATE TYPE residence_change_type AS ENUM (
    'Đăng ký thường trú', 'Đăng ký tạm trú', 'Xóa đăng ký thường trú', 
    'Xóa đăng ký tạm trú', 'Tạm vắng', 'Trở về', 'Điều chỉnh thông tin'
);

-- Loại di chuyển
DROP TYPE IF EXISTS movement_type CASCADE;
CREATE TYPE movement_type AS ENUM ('Trong nước', 'Xuất cảnh', 'Nhập cảnh', 'Tái nhập cảnh');

-- 1.5 ENUM ĐỊNH DANH & QUẢN LÝ
-- Mức xác thực định danh điện tử
DROP TYPE IF EXISTS verification_level CASCADE;
CREATE TYPE verification_level AS ENUM ('Mức 1', 'Mức 2');

-- Loại người dùng
DROP TYPE IF EXISTS user_type CASCADE;
CREATE TYPE user_type AS ENUM ('Công dân', 'Cán bộ', 'Quản trị viên');

-- Loại thay đổi
DROP TYPE IF EXISTS change_type CASCADE;
CREATE TYPE change_type AS ENUM ('Thêm mới', 'Cập nhật', 'Xóa', 'Vô hiệu hóa', 'Khôi phục');

-- Loại thao tác truy cập
DROP TYPE IF EXISTS access_type CASCADE;
CREATE TYPE access_type AS ENUM ('Đọc', 'Ghi', 'Xóa', 'Cập nhật', 'Truy vấn đặc biệt');

-- 1.6 ENUM VÙNG MIỀN & HÀNH CHÍNH
-- Vùng miền
DROP TYPE IF EXISTS geographical_region_type CASCADE;
CREATE TYPE geographical_region_type AS ENUM ('Bắc', 'Trung', 'Nam');

-- Loại đơn vị hành chính
DROP TYPE IF EXISTS division_type CASCADE;
CREATE TYPE division_type AS ENUM (
    'Tỉnh', 'Thành phố trực thuộc TW', 
    'Quận', 'Huyện', 'Thị xã', 'Thành phố thuộc tỉnh', 
    'Phường', 'Xã', 'Thị trấn'
);

-- Loại thay đổi đơn vị hành chính
DROP TYPE IF EXISTS admin_change_type CASCADE;
CREATE TYPE admin_change_type AS ENUM ('Tách', 'Nhập', 'Đổi tên', 'Điều chỉnh địa giới');

-- 1.7 ENUM ĐỒNG BỘ & CDC
-- Trạng thái đồng bộ
DROP TYPE IF EXISTS sync_status CASCADE;
CREATE TYPE sync_status AS ENUM ('Chưa đồng bộ', 'Đang đồng bộ', 'Đã đồng bộ', 'Lỗi đồng bộ', 'Xung đột');

-- Loại hoạt động CDC
DROP TYPE IF EXISTS cdc_operation_type CASCADE;
CREATE TYPE cdc_operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT');

-- Mức độ ưu tiên đồng bộ
DROP TYPE IF EXISTS sync_priority CASCADE;
CREATE TYPE sync_priority AS ENUM ('Thấp', 'Trung bình', 'Cao', 'Khẩn cấp');

-- Trạng thái CDC connector
DROP TYPE IF EXISTS cdc_connector_status CASCADE;
CREATE TYPE cdc_connector_status AS ENUM (
    'Khởi tạo', 'Đang chạy', 'Tạm dừng', 'Lỗi', 'Đang khôi phục', 'Đã dừng'
);

-- 1.8 ENUM QUẢN LÝ LUỒNG DỮ LIỆU KAFKA
-- Trạng thái xử lý Kafka
DROP TYPE IF EXISTS kafka_processing_status CASCADE;
CREATE TYPE kafka_processing_status AS ENUM (
    'Đang chờ', 'Đang xử lý', 'Hoàn thành', 'Lỗi', 'Đang thử lại', 'Bỏ qua'
);

-- Loại topic Kafka
DROP TYPE IF EXISTS kafka_topic_type CASCADE;
CREATE TYPE kafka_topic_type AS ENUM (
    'CDC-Source', 'Transformation', 'Enriched', 'MongoDB-Sink', 'DLQ', 'Control', 'Metrics'
);

-- 1.9 ENUM QUẢN LÝ AN NINH
-- Mức độ nhạy cảm dữ liệu
DROP TYPE IF EXISTS data_sensitivity_level CASCADE;
CREATE TYPE data_sensitivity_level AS ENUM ('Công khai', 'Hạn chế', 'Bảo mật', 'Tối mật');

-- Loại hệ thống mã hóa
DROP TYPE IF EXISTS encryption_type CASCADE;
CREATE TYPE encryption_type AS ENUM ('AES-256', 'RSA', 'Khóa công khai', 'Hashing', 'Không mã hóa');

-- Loại hồ sơ phạm tội
DROP TYPE IF EXISTS criminal_record_type CASCADE;
CREATE TYPE criminal_record_type AS ENUM (
    'Vi phạm hành chính', 'Tội phạm nhẹ', 'Tội phạm nghiêm trọng', 
    'Tội phạm rất nghiêm trọng', 'Tội phạm đặc biệt nghiêm trọng'
);

-- ============================================================================
-- 2. TẠO ENUM CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Tạo kiểu dữ liệu enum cho database Bộ Tư pháp...'
\connect ministry_of_justice

-- 2.1 ENUM THÔNG TIN CƠ BẢN CÔNG DÂN (Giống với Bộ Công an)
DROP TYPE IF EXISTS gender_type CASCADE;
CREATE TYPE gender_type AS ENUM ('Nam', 'Nữ', 'Khác');

DROP TYPE IF EXISTS blood_type CASCADE;
CREATE TYPE blood_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Không xác định');

DROP TYPE IF EXISTS death_status CASCADE;
CREATE TYPE death_status AS ENUM ('Còn sống', 'Đã mất', 'Mất tích');

DROP TYPE IF EXISTS marital_status CASCADE;
CREATE TYPE marital_status AS ENUM ('Độc thân', 'Đã kết hôn', 'Đã ly hôn', 'Góa', 'Ly thân');

-- 2.2 ENUM HỘ TỊCH
-- Loại giấy tờ hộ tịch
DROP TYPE IF EXISTS civil_document_type CASCADE;
CREATE TYPE civil_document_type AS ENUM (
    'Giấy khai sinh', 'Giấy khai tử', 'Giấy đăng ký kết hôn', 
    'Giấy đăng ký ly hôn', 'Giấy xác nhận tình trạng hôn nhân', 
    'Giấy xác nhận thông tin hộ tịch', 'Khác'
);

-- Trạng thái hồ sơ
DROP TYPE IF EXISTS record_status CASCADE;
CREATE TYPE record_status AS ENUM ('Đang xử lý', 'Đã duyệt', 'Từ chối', 'Yêu cầu bổ sung', 'Đã hủy');

-- Lý do khai tử
DROP TYPE IF EXISTS death_reason_type CASCADE;
CREATE TYPE death_reason_type AS ENUM (
    'Tự nhiên', 'Bệnh tật', 'Tai nạn', 'Tự tử', 'Bạo lực', 'Thiên tai', 'Khác', 'Không xác định'
);

-- 2.3 ENUM QUAN HỆ GIA ĐÌNH
-- Quan hệ với chủ hộ
DROP TYPE IF EXISTS household_relationship CASCADE;
CREATE TYPE household_relationship AS ENUM (
    'Chủ hộ', 'Vợ', 'Chồng', 'Con', 'Bố', 'Mẹ', 'Ông', 'Bà', 
    'Anh', 'Chị', 'Em', 'Cháu', 'Chắt', 'Cô', 'Dì', 'Chú', 'Bác', 
    'Người giám hộ', 'Họ hàng khác', 'Không có quan hệ họ hàng'
);

-- Loại quan hệ gia đình
DROP TYPE IF EXISTS family_relationship_type CASCADE;
CREATE TYPE family_relationship_type AS ENUM (
    'Vợ-Chồng', 'Cha-Con', 'Mẹ-Con', 'Ông-Cháu', 'Bà-Cháu',
    'Anh-Em', 'Chị-Em', 'Cô-Cháu', 'Dì-Cháu', 'Chú-Cháu', 'Bác-Cháu',
    'Giám hộ', 'Họ hàng khác'
);

-- Loại giám hộ
DROP TYPE IF EXISTS guardianship_type CASCADE;
CREATE TYPE guardianship_type AS ENUM (
    'Người chưa thành niên', 'Người mất năng lực hành vi'
);

-- Loại nhận cha/mẹ/con
DROP TYPE IF EXISTS recognition_type CASCADE;
CREATE TYPE recognition_type AS ENUM ('Cha nhận con', 'Con nhận cha', 'Mẹ nhận con', 'Con nhận mẹ');

-- 2.4 ENUM BIẾN ĐỘNG DÂN CƯ
-- Loại biến động dân cư
DROP TYPE IF EXISTS population_change_type CASCADE;
CREATE TYPE population_change_type AS ENUM (
    'Sinh', 'Tử', 'Chuyển đến', 'Chuyển đi', 
    'Thay đổi HKTT', 'Kết hôn', 'Ly hôn', 
    'Thay đổi thông tin cá nhân', 'Khác'
);

-- Loại thay đổi quốc tịch
DROP TYPE IF EXISTS nationality_change_type CASCADE;
CREATE TYPE nationality_change_type AS ENUM ('Nhập quốc tịch', 'Thôi quốc tịch', 'Trở lại quốc tịch');

-- 2.5 ENUM QUẢN LÝ HỘ KHẨU
-- Trạng thái hộ khẩu
DROP TYPE IF EXISTS household_status CASCADE;
CREATE TYPE household_status AS ENUM (
    'Đang hoạt động', 'Tạm ngừng', 'Đã chuyển đi', 'Đã giải thể', 'Đang cập nhật'
);

-- Loại cư trú hộ khẩu
DROP TYPE IF EXISTS household_type CASCADE;
CREATE TYPE household_type AS ENUM ('Thường trú', 'Tạm trú', 'Tập thể', 'Đặc biệt');

-- 2.6 ENUM VÙNG MIỀN & HÀNH CHÍNH (Giống với Bộ Công an)
DROP TYPE IF EXISTS geographical_region_type CASCADE;
CREATE TYPE geographical_region_type AS ENUM ('Bắc', 'Trung', 'Nam');

DROP TYPE IF EXISTS division_type CASCADE;
CREATE TYPE division_type AS ENUM (
    'Tỉnh', 'Thành phố trực thuộc TW', 
    'Quận', 'Huyện', 'Thị xã', 'Thành phố thuộc tỉnh', 
    'Phường', 'Xã', 'Thị trấn'
);

-- 2.7 ENUM ĐỒNG BỘ & CDC (Giống với Bộ Công an)
DROP TYPE IF EXISTS sync_status CASCADE;
CREATE TYPE sync_status AS ENUM ('Chưa đồng bộ', 'Đang đồng bộ', 'Đã đồng bộ', 'Lỗi đồng bộ', 'Xung đột');

DROP TYPE IF EXISTS cdc_operation_type CASCADE;
CREATE TYPE cdc_operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT');

DROP TYPE IF EXISTS sync_priority CASCADE;
CREATE TYPE sync_priority AS ENUM ('Thấp', 'Trung bình', 'Cao', 'Khẩn cấp');

DROP TYPE IF EXISTS cdc_connector_status CASCADE;
CREATE TYPE cdc_connector_status AS ENUM (
    'Khởi tạo', 'Đang chạy', 'Tạm dừng', 'Lỗi', 'Đang khôi phục', 'Đã dừng'
);

-- 2.8 ENUM QUẢN LÝ LUỒNG DỮ LIỆU KAFKA (Giống với Bộ Công an)
DROP TYPE IF EXISTS kafka_processing_status CASCADE;
CREATE TYPE kafka_processing_status AS ENUM (
    'Đang chờ', 'Đang xử lý', 'Hoàn thành', 'Lỗi', 'Đang thử lại', 'Bỏ qua'
);

DROP TYPE IF EXISTS kafka_topic_type CASCADE;
CREATE TYPE kafka_topic_type AS ENUM (
    'CDC-Source', 'Transformation', 'Enriched', 'MongoDB-Sink', 'DLQ', 'Control', 'Metrics'
);

-- ============================================================================
-- 3. TẠO ENUM CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Tạo kiểu dữ liệu enum cho database Máy chủ trung tâm...'
\connect national_citizen_central_server

-- 3.1 ENUM CƠ BẢN (Giống với Bộ Công an và Bộ Tư pháp)
DROP TYPE IF EXISTS gender_type CASCADE;
CREATE TYPE gender_type AS ENUM ('Nam', 'Nữ', 'Khác');

DROP TYPE IF EXISTS blood_type CASCADE;
CREATE TYPE blood_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Không xác định');

DROP TYPE IF EXISTS death_status CASCADE;
CREATE TYPE death_status AS ENUM ('Còn sống', 'Đã mất', 'Mất tích');

DROP TYPE IF EXISTS marital_status CASCADE;
CREATE TYPE marital_status AS ENUM ('Độc thân', 'Đã kết hôn', 'Đã ly hôn', 'Góa', 'Ly thân');

DROP TYPE IF EXISTS geographical_region_type CASCADE;
CREATE TYPE geographical_region_type AS ENUM ('Bắc', 'Trung', 'Nam');

DROP TYPE IF EXISTS division_type CASCADE;
CREATE TYPE division_type AS ENUM (
    'Tỉnh', 'Thành phố trực thuộc TW', 
    'Quận', 'Huyện', 'Thị xã', 'Thành phố thuộc tỉnh', 
    'Phường', 'Xã', 'Thị trấn'
);

-- 3.2 ENUM ĐẶC THÙ CHO MÁY CHỦ TRUNG TÂM
-- Loại đồng bộ trung tâm
DROP TYPE IF EXISTS central_sync_type CASCADE;
CREATE TYPE central_sync_type AS ENUM (
    'Đồng bộ toàn bộ', 'Đồng bộ tăng trưởng', 
    'Đồng bộ thủ công', 'Đồng bộ theo lịch',
    'Đồng bộ CDC'
);

-- Loại báo cáo trung tâm
DROP TYPE IF EXISTS central_report_type CASCADE;
CREATE TYPE central_report_type AS ENUM (
    'Dân số', 'Di cư', 'Hộ tịch', 'Thống kê hành chính', 
    'Điều tra dân số', 'Báo cáo đặc biệt', 'Báo cáo phân tích',
    'Dashboard', 'Báo cáo tổng hợp'
);

-- Trạng thái đồng bộ dữ liệu giữa các hệ thống
DROP TYPE IF EXISTS system_sync_status CASCADE;
CREATE TYPE system_sync_status AS ENUM (
    'Đồng bộ hoàn toàn', 'Đồng bộ một phần', 'Chưa đồng bộ', 
    'Lỗi đồng bộ', 'Đang xử lý', 'Xung đột dữ liệu', 'Đã hòa giải xung đột'
);

-- Nguồn dữ liệu
DROP TYPE IF EXISTS data_source CASCADE;
CREATE TYPE data_source AS ENUM (
    'Bộ Công an', 'Bộ Tư pháp', 'Tổng hợp', 'Ngoại vi', 
    'Cục thống kê', 'CDC', 'MongoDB', 'API'
);

-- Trạng thái luồng dữ liệu Kafka
DROP TYPE IF EXISTS kafka_stream_status CASCADE;
CREATE TYPE kafka_stream_status AS ENUM (
    'Hoạt động', 'Tạm dừng', 'Lỗi', 'Đã dừng', 'Khởi động lại', 
    'Đang nâng cấp', 'Đang mở rộng', 'Quá tải'
);

-- Loại kết nối Kafka Connect 
DROP TYPE IF EXISTS kafka_connector_type CASCADE;
CREATE TYPE kafka_connector_type AS ENUM (
    'Debezium PostgreSQL', 'MongoDB Sink', 'JDBC Sink', 'JDBC Source',
    'Elasticsearch Sink', 'File Sink', 'S3 Sink', 'Custom'
);

-- Trạng thái MongoDB Sink
DROP TYPE IF EXISTS mongodb_sink_status CASCADE;
CREATE TYPE mongodb_sink_status AS ENUM (
    'Đang chạy', 'Tạm dừng', 'Lỗi', 'Quá tải', 'Đang bảo trì',
    'Đã dừng', 'Đang khởi tạo', 'Đang đồng bộ lại'
);

-- Các chế độ đồng bộ MongoDB
DROP TYPE IF EXISTS mongodb_sync_mode CASCADE;
CREATE TYPE mongodb_sync_mode AS ENUM (
    'Bulk Insert', 'Upsert', 'Replace', 'Update', 'Insert Only', 
    'Delete And Replace', 'Transaction'
);

-- Loại chuyển đổi dữ liệu trong Spark
DROP TYPE IF EXISTS spark_transformation_type CASCADE;
CREATE TYPE spark_transformation_type AS ENUM (
    'Ánh xạ trường', 'Chuyển đổi kiểu', 'Gộp bản ghi',
    'Tách bản ghi', 'Làm giàu dữ liệu', 'Lọc dữ liệu',
    'Tính toán', 'Tổng hợp', 'Phân tích'
);

-- Trạng thái phân vùng dữ liệu
DROP TYPE IF EXISTS partition_status CASCADE;
CREATE TYPE partition_status AS ENUM (
    'Hoạt động', 'Đang tạo', 'Đang chia', 'Đang gộp',
    'Bảo trì', 'Chỉ đọc', 'Lỗi', 'Đã lưu trữ'
);

-- 3.3 ENUM KIỂM SOÁT VÀ GIÁM SÁT
-- Mức độ nghiêm trọng của sự cố
DROP TYPE IF EXISTS incident_severity CASCADE;
CREATE TYPE incident_severity AS ENUM (
    'Thông tin', 'Cảnh báo', 'Nghiêm trọng', 'Khẩn cấp', 'Thảm họa'
);

-- Loại sự cố
DROP TYPE IF EXISTS incident_type CASCADE;
CREATE TYPE incident_type AS ENUM (
    'Lỗi đồng bộ', 'Lỗi CDC', 'Lỗi Kafka', 'Lỗi MongoDB',
    'Lỗi Spark', 'Lỗi API', 'Lỗi hệ thống', 'Lỗi dữ liệu',
    'Lỗi mạng', 'Lỗi bảo mật', 'Khác'
);

-- Trạng thái xử lý sự cố
DROP TYPE IF EXISTS incident_status CASCADE;
CREATE TYPE incident_status AS ENUM (
    'Mới', 'Đang xác minh', 'Đang xử lý', 'Đã xử lý',
    'Đã đóng', 'Tái diễn', 'Đang theo dõi', 'Cần hỗ trợ'
);

\echo 'Đã tạo xong tất cả các kiểu dữ liệu enum cho hệ thống quản lý dân cư quốc gia'
\echo 'Các enum đã được đồng bộ giữa các hệ thống, với các enum đặc thù cho từng hệ thống'
\echo 'Tiếp theo là cài đặt các extension và thiết lập các bảng tham chiếu...'
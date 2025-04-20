-- =============================================================================
-- File: database/common/enum.sql
-- Description: Định nghĩa các kiểu dữ liệu enum cho hệ thống QLDCQG
-- Version: 2.0 (Phân tách ENUM theo database sử dụng)
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO ENUM TYPES ***'

-- ============================================================================
-- A. ĐỊNH NGHĨA CÁC ENUM THỰC SỰ CHUNG (COMMON)
--    (Sẽ được tạo trong cả 3 database)
-- ============================================================================

-- Hàm helper để tạo các ENUM chung
-- Lưu ý: Hàm này sẽ được tạo và xóa trong context của từng database
CREATE OR REPLACE FUNCTION _create_common_enums() RETURNS void AS $$
BEGIN
    -- A.1 Thông tin cơ bản
    DROP TYPE IF EXISTS gender_type CASCADE;
    CREATE TYPE gender_type AS ENUM ('Nam', 'Nữ', 'Khác');

    DROP TYPE IF EXISTS blood_type CASCADE;
    CREATE TYPE blood_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Không xác định');

    DROP TYPE IF EXISTS death_status CASCADE;
    CREATE TYPE death_status AS ENUM ('Còn sống', 'Đã mất', 'Mất tích');

    DROP TYPE IF EXISTS marital_status CASCADE;
    CREATE TYPE marital_status AS ENUM ('Độc thân', 'Đã kết hôn', 'Đã ly hôn', 'Góa', 'Ly thân');

    DROP TYPE IF EXISTS education_level CASCADE;
    CREATE TYPE education_level AS ENUM (
        'Chưa đi học', 'Tiểu học', 'Trung học cơ sở', 'Trung học phổ thông',
        'Trung cấp', 'Cao đẳng', 'Đại học', 'Thạc sĩ', 'Tiến sĩ', 'Khác'
    );

    -- A.2 Địa chỉ & Hành chính
    DROP TYPE IF EXISTS address_type CASCADE;
    CREATE TYPE address_type AS ENUM ('Thường trú', 'Tạm trú', 'Nơi ở hiện tại', 'Công ty', 'Học tập', 'Khác');

    DROP TYPE IF EXISTS geographical_region_type CASCADE;
    CREATE TYPE geographical_region_type AS ENUM ('Bắc', 'Trung', 'Nam'); -- Có thể thay bằng text trực tiếp

    DROP TYPE IF EXISTS division_type CASCADE;
    CREATE TYPE division_type AS ENUM (
        'Tỉnh', 'Thành phố trực thuộc TW', 'Quận', 'Huyện', 'Thị xã',
        'Thành phố thuộc tỉnh', 'Phường', 'Xã', 'Thị trấn'
    );

    -- A.3 Đồng bộ & CDC
    DROP TYPE IF EXISTS sync_status CASCADE;
    CREATE TYPE sync_status AS ENUM ('Chưa đồng bộ', 'Đang đồng bộ', 'Đã đồng bộ', 'Lỗi đồng bộ', 'Xung đột', 'Đã hòa giải'); -- Thêm 'Đã hòa giải'

    DROP TYPE IF EXISTS cdc_operation_type CASCADE;
    CREATE TYPE cdc_operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT');

    DROP TYPE IF EXISTS sync_priority CASCADE;
    CREATE TYPE sync_priority AS ENUM ('Thấp', 'Trung bình', 'Cao', 'Khẩn cấp');

    DROP TYPE IF EXISTS cdc_connector_status CASCADE;
    CREATE TYPE cdc_connector_status AS ENUM ('Khởi tạo', 'Đang chạy', 'Tạm dừng', 'Lỗi', 'Đang khôi phục', 'Đã dừng');

    -- A.4 Quản lý & Bảo mật
    DROP TYPE IF EXISTS data_sensitivity_level CASCADE;
    CREATE TYPE data_sensitivity_level AS ENUM ('Công khai', 'Hạn chế', 'Bảo mật', 'Tối mật');

END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- B. TẠO ENUM CHO DATABASE BỘ CÔNG AN
-- ============================================================================
\echo 'Bước 1: Tạo ENUMs cho ministry_of_public_security...'
\connect ministry_of_public_security

-- Tạo các ENUM chung
SELECT _create_common_enums();

-- Tạo các ENUM đặc thù của Bộ Công an
\echo '   -> Tạo ENUMs đặc thù của Bộ Công an...';
DROP TYPE IF EXISTS card_type CASCADE;
CREATE TYPE card_type AS ENUM ('CMND 9 số', 'CMND 12 số', 'CCCD', 'CCCD gắn chip');

DROP TYPE IF EXISTS card_status CASCADE;
CREATE TYPE card_status AS ENUM ('Đang sử dụng', 'Hết hạn', 'Mất', 'Hỏng', 'Thu hồi', 'Đã thay thế', 'Tạm giữ');


DROP TYPE IF EXISTS residence_change_type CASCADE;
CREATE TYPE residence_change_type AS ENUM (
    'Đăng ký thường trú', 'Đăng ký tạm trú', 'Xóa đăng ký thường trú',
    'Xóa đăng ký tạm trú', 'Tạm vắng', 'Trở về', 'Điều chỉnh thông tin'
);

DROP TYPE IF EXISTS movement_type CASCADE;
CREATE TYPE movement_type AS ENUM ('Trong nước', 'Xuất cảnh', 'Nhập cảnh', 'Tái nhập cảnh');

DROP TYPE IF EXISTS verification_level CASCADE;
CREATE TYPE verification_level AS ENUM ('Mức 1', 'Mức 2'); -- Mức xác thực định danh điện tử

DROP TYPE IF EXISTS user_type CASCADE;
CREATE TYPE user_type AS ENUM ('Công dân', 'Cán bộ', 'Quản trị viên');

DROP TYPE IF EXISTS encryption_type CASCADE;
CREATE TYPE encryption_type AS ENUM ('AES-256', 'RSA', 'Khóa công khai', 'Hashing', 'Không mã hóa');

DROP TYPE IF EXISTS criminal_record_type CASCADE;
CREATE TYPE criminal_record_type AS ENUM (
    'Vi phạm hành chính', 'Tội phạm nhẹ', 'Tội phạm nghiêm trọng',
    'Tội phạm rất nghiêm trọng', 'Tội phạm đặc biệt nghiêm trọng'
);

-- Dọn dẹp hàm helper
DROP FUNCTION IF EXISTS _create_common_enums();
\echo '-> Hoàn thành tạo ENUMs cho ministry_of_public_security.'

-- ============================================================================
-- C. TẠO ENUM CHO DATABASE BỘ TƯ PHÁP
-- ============================================================================
\echo 'Bước 2: Tạo ENUMs cho ministry_of_justice...'
\connect ministry_of_justice

-- Tạo các ENUM chung
SELECT _create_common_enums();

-- Tạo các ENUM đặc thù của Bộ Tư pháp
\echo '   -> Tạo ENUMs đặc thù của Bộ Tư pháp...';
DROP TYPE IF EXISTS civil_document_type CASCADE;
CREATE TYPE civil_document_type AS ENUM (
    'Giấy khai sinh', 'Giấy khai tử', 'Giấy đăng ký kết hôn',
    'Giấy đăng ký ly hôn', 'Giấy xác nhận tình trạng hôn nhân',
    'Giấy xác nhận thông tin hộ tịch', 'Trích lục', 'Khác' -- Thêm trích lục
);

DROP TYPE IF EXISTS record_status CASCADE;
CREATE TYPE record_status AS ENUM ('Đang xử lý', 'Đã duyệt', 'Từ chối', 'Yêu cầu bổ sung', 'Đã hủy');

DROP TYPE IF EXISTS death_reason_type CASCADE;
CREATE TYPE death_reason_type AS ENUM (
    'Tự nhiên', 'Bệnh tật', 'Tai nạn', 'Tự tử', 'Bạo lực', 'Thiên tai', 'Khác', 'Không xác định'
);

DROP TYPE IF EXISTS household_relationship CASCADE;
CREATE TYPE household_relationship AS ENUM (
    'Chủ hộ', 'Vợ', 'Chồng', 'Con đẻ', 'Con nuôi', 'Bố đẻ', 'Mẹ đẻ', 'Bố nuôi', 'Mẹ nuôi', -- Chi tiết hơn
    'Ông nội', 'Bà nội', 'Ông ngoại', 'Bà ngoại', -- Chi tiết hơn
    'Anh ruột', 'Chị ruột', 'Em ruột', -- Chi tiết hơn
    'Cháu ruột', 'Chắt ruột', 'Cô ruột', 'Dì ruột', 'Chú ruột', 'Bác ruột', -- Chi tiết hơn
    'Người giám hộ', 'Ở nhờ, ở thuê', 'Khác' -- Thêm 'Ở nhờ, ở thuê'
);

DROP TYPE IF EXISTS family_relationship_type CASCADE;
CREATE TYPE family_relationship_type AS ENUM (
    'Vợ-Chồng', 'Cha-Con', 'Mẹ-Con', 'Ông-Cháu', 'Bà-Cháu',
    'Anh-Em', 'Chị-Em', 'Cô-Cháu', 'Dì-Cháu', 'Chú-Cháu', 'Bác-Cháu',
    'Giám hộ', 'Cha nuôi-Con nuôi', 'Mẹ nuôi-Con nuôi', 'Khác' -- Thêm quan hệ nuôi
);

DROP TYPE IF EXISTS guardianship_type CASCADE;
CREATE TYPE guardianship_type AS ENUM (
    'Người chưa thành niên', 'Người mất năng lực hành vi', 'Người hạn chế NLHV'
);

DROP TYPE IF EXISTS recognition_type CASCADE;
CREATE TYPE recognition_type AS ENUM ('Cha nhận con', 'Con nhận cha', 'Mẹ nhận con', 'Con nhận mẹ');

DROP TYPE IF EXISTS population_change_type CASCADE;
CREATE TYPE population_change_type AS ENUM (
    'Sinh', 'Tử', 'Chuyển đến thường trú', 'Chuyển đi thường trú', 'Đăng ký tạm trú', 'Xóa tạm trú', -- Chi tiết hơn
    'Kết hôn', 'Ly hôn', 'Thay đổi thông tin cá nhân', 'Nhận nuôi', 'Chấm dứt nuôi', 'Thay đổi quốc tịch', 'Khác'
);

DROP TYPE IF EXISTS nationality_change_type CASCADE;
CREATE TYPE nationality_change_type AS ENUM ('Nhập quốc tịch', 'Thôi quốc tịch', 'Trở lại quốc tịch');

DROP TYPE IF EXISTS household_status CASCADE;
CREATE TYPE household_status AS ENUM ('Đang hoạt động', 'Tách hộ', 'Đã chuyển đi', 'Đã xóa', 'Đang cập nhật'); -- Đổi tên/thêm

DROP TYPE IF EXISTS household_type CASCADE;
CREATE TYPE household_type AS ENUM ('Thường trú', 'Tạm trú', 'Tập thể', 'Đặc biệt');

-- Dọn dẹp hàm helper
DROP FUNCTION IF EXISTS _create_common_enums();
\echo '-> Hoàn thành tạo ENUMs cho ministry_of_justice.'

-- ============================================================================
-- D. TẠO ENUM CHO DATABASE MÁY CHỦ TRUNG TÂM
-- ============================================================================
\echo 'Bước 3: Tạo ENUMs cho national_citizen_central_server...'
\connect national_citizen_central_server

-- Tạo các ENUM chung
SELECT _create_common_enums();

-- Tạo các ENUM cần thiết cho dữ liệu tích hợp (có thể trùng lặp có chủ đích với các DB khác)
\echo '   -> Tạo ENUMs cho dữ liệu tích hợp...';
-- (Tạo lại những ENUM từ BCA, BTP mà các bảng central.* hoặc views/procedures cần dùng)
DROP TYPE IF EXISTS card_type CASCADE;
CREATE TYPE card_type AS ENUM ('CMND 9 số', 'CMND 12 số', 'CCCD', 'CCCD gắn chip');
DROP TYPE IF EXISTS card_status CASCADE;
CREATE TYPE card_status AS ENUM ('Đang sử dụng', 'Hết hạn', 'Mất', 'Hỏng', 'Thu hồi', 'Đã thay thế', 'Tạm giữ');
DROP TYPE IF EXISTS household_relationship CASCADE;
CREATE TYPE household_relationship AS ENUM (
    'Chủ hộ', 'Vợ', 'Chồng', 'Con đẻ', 'Con nuôi', 'Bố đẻ', 'Mẹ đẻ', 'Bố nuôi', 'Mẹ nuôi',
    'Ông nội', 'Bà nội', 'Ông ngoại', 'Bà ngoại', 'Anh ruột', 'Chị ruột', 'Em ruột',
    'Cháu ruột', 'Chắt ruột', 'Cô ruột', 'Dì ruột', 'Chú ruột', 'Bác ruột',
    'Người giám hộ', 'Ở nhờ, ở thuê', 'Khác'
);
DROP TYPE IF EXISTS household_type CASCADE;
CREATE TYPE household_type AS ENUM ('Thường trú', 'Tạm trú', 'Tập thể', 'Đặc biệt');
DROP TYPE IF EXISTS population_change_type CASCADE;
CREATE TYPE population_change_type AS ENUM (
    'Sinh', 'Tử', 'Chuyển đến thường trú', 'Chuyển đi thường trú', 'Đăng ký tạm trú', 'Xóa tạm trú',
    'Kết hôn', 'Ly hôn', 'Thay đổi thông tin cá nhân', 'Nhận nuôi', 'Chấm dứt nuôi', 'Thay đổi quốc tịch', 'Khác'
);
-- ... (Thêm các ENUM khác từ BCA/BTP nếu bảng/view/function ở central cần)

-- Tạo các ENUM đặc thù của Máy chủ trung tâm
\echo '   -> Tạo ENUMs đặc thù của Máy chủ trung tâm...';
DROP TYPE IF EXISTS central_sync_type CASCADE;
CREATE TYPE central_sync_type AS ENUM ('Đồng bộ toàn bộ', 'Đồng bộ tăng trưởng', 'Đồng bộ thủ công', 'Đồng bộ theo lịch', 'Đồng bộ CDC');

DROP TYPE IF EXISTS central_report_type CASCADE;
CREATE TYPE central_report_type AS ENUM ('Dân số', 'Di cư', 'Hộ tịch', 'Thống kê hành chính', 'Điều tra dân số', 'Báo cáo đặc biệt', 'Báo cáo phân tích', 'Dashboard', 'Báo cáo tổng hợp');

DROP TYPE IF EXISTS system_sync_status CASCADE;
CREATE TYPE system_sync_status AS ENUM ('Đồng bộ hoàn toàn', 'Đồng bộ một phần', 'Chưa đồng bộ', 'Lỗi đồng bộ', 'Đang xử lý', 'Xung đột dữ liệu', 'Đã hòa giải xung đột');

DROP TYPE IF EXISTS data_source CASCADE;
CREATE TYPE data_source AS ENUM ('Bộ Công an', 'Bộ Tư pháp', 'Tổng hợp', 'Ngoại vi', 'Cục thống kê', 'CDC', 'MongoDB', 'API');

DROP TYPE IF EXISTS kafka_stream_status CASCADE;
CREATE TYPE kafka_stream_status AS ENUM ('Hoạt động', 'Tạm dừng', 'Lỗi', 'Đã dừng', 'Khởi động lại', 'Đang nâng cấp', 'Đang mở rộng', 'Quá tải');

DROP TYPE IF EXISTS kafka_connector_type CASCADE;
CREATE TYPE kafka_connector_type AS ENUM ('Debezium PostgreSQL', 'MongoDB Sink', 'JDBC Sink', 'JDBC Source', 'Elasticsearch Sink', 'File Sink', 'S3 Sink', 'Custom');

DROP TYPE IF EXISTS kafka_topic_type CASCADE; -- Đã có trong common, ko cần tạo lại nếu dùng hàm chung

DROP TYPE IF EXISTS mongodb_sink_status CASCADE;
CREATE TYPE mongodb_sink_status AS ENUM ('Đang chạy', 'Tạm dừng', 'Lỗi', 'Quá tải', 'Đang bảo trì', 'Đã dừng', 'Đang khởi tạo', 'Đang đồng bộ lại');

DROP TYPE IF EXISTS mongodb_sync_mode CASCADE;
CREATE TYPE mongodb_sync_mode AS ENUM ('Bulk Insert', 'Upsert', 'Replace', 'Update', 'Insert Only', 'Delete And Replace', 'Transaction');

DROP TYPE IF EXISTS spark_transformation_type CASCADE;
CREATE TYPE spark_transformation_type AS ENUM ('Ánh xạ trường', 'Chuyển đổi kiểu', 'Gộp bản ghi', 'Tách bản ghi', 'Làm giàu dữ liệu', 'Lọc dữ liệu', 'Tính toán', 'Tổng hợp', 'Phân tích');

DROP TYPE IF EXISTS partition_status CASCADE;
CREATE TYPE partition_status AS ENUM ('Hoạt động', 'Đang tạo', 'Đang chia', 'Đang gộp', 'Bảo trì', 'Chỉ đọc', 'Lỗi', 'Đã lưu trữ');

DROP TYPE IF EXISTS incident_severity CASCADE;
CREATE TYPE incident_severity AS ENUM ('Thông tin', 'Cảnh báo', 'Nghiêm trọng', 'Khẩn cấp', 'Thảm họa');

DROP TYPE IF EXISTS incident_type CASCADE;
CREATE TYPE incident_type AS ENUM ('Lỗi đồng bộ', 'Lỗi CDC', 'Lỗi Kafka', 'Lỗi MongoDB', 'Lỗi Spark', 'Lỗi API', 'Lỗi hệ thống', 'Lỗi dữ liệu', 'Lỗi mạng', 'Lỗi bảo mật', 'Khác');

DROP TYPE IF EXISTS incident_status CASCADE;
CREATE TYPE incident_status AS ENUM ('Mới', 'Đang xác minh', 'Đang xử lý', 'Đã xử lý', 'Đã đóng', 'Tái diễn', 'Đang theo dõi', 'Cần hỗ trợ');

-- Dọn dẹp hàm helper
DROP FUNCTION IF EXISTS _create_common_enums();
\echo '-> Hoàn thành tạo ENUMs cho national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO ENUM TYPES ***'
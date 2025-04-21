-- File: 01_common/02_enum.sql
-- Description: Định nghĩa các kiểu dữ liệu enum (kiểu liệt kê) cho hệ thống QLDCQG.
-- Version: 3.0 (Aligned with Microservices Structure and revised ENUM list)
--
-- Chức năng chính:
-- 1. Định nghĩa các ENUM dùng chung trên cả 3 database.
-- 2. Định nghĩa các ENUM đặc thù cho từng database (BCA, BTP, TT).
--
-- Yêu cầu: Chạy script này sau khi đã cài đặt extensions (01_common/01_extensions.sql).
--          Cần quyền tạo kiểu dữ liệu (thường là owner hoặc superuser).
-- =============================================================================

\echo '*** BẮT ĐẦU QUÁ TRÌNH TẠO ENUM TYPES ***'

-- ============================================================================
-- A. ĐỊNH NGHĨA CÁC ENUM CHUNG (COMMON)
--    Sử dụng một hàm helper để định nghĩa các ENUM này trong mỗi DB.
-- ============================================================================

-- Hàm helper (sẽ được định nghĩa lại trong context của mỗi DB)
-- Lưu ý: DO $$ BEGIN ... END $$; block cho phép khai báo biến và logic phức tạp hơn nếu cần.

-- ============================================================================
-- B. TẠO ENUM CHO DATABASE BỘ CÔNG AN (ministry_of_public_security)
-- ============================================================================
\echo 'Bước 1: Tạo ENUMs cho ministry_of_public_security...'
\connect ministry_of_public_security

DO $$
DECLARE
    -- Khai báo các biến nếu cần
BEGIN
    RAISE NOTICE '   -> Định nghĩa hàm tạo ENUMs chung cho BCA...';
    -- Định nghĩa lại hàm helper trong context DB này
    CREATE OR REPLACE FUNCTION _create_common_enums_bca() RETURNS void AS $_$
    BEGIN
        RAISE NOTICE '      -> Tạo ENUMs chung...';
        -- Thông tin cơ bản
        DROP TYPE IF EXISTS gender_type CASCADE;
        CREATE TYPE gender_type AS ENUM ('Nam', 'Nữ', 'Khác');

        DROP TYPE IF EXISTS blood_type CASCADE;
        CREATE TYPE blood_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Không xác định');

        DROP TYPE IF EXISTS death_status CASCADE;
        CREATE TYPE death_status AS ENUM ('Còn sống', 'Đã mất', 'Mất tích');

        DROP TYPE IF EXISTS marital_status CASCADE;
        CREATE TYPE marital_status AS ENUM ('Độc thân', 'Đã kết hôn', 'Đã ly hôn', 'Góa', 'Ly thân'); -- Ly thân có thể cần xem xét

        DROP TYPE IF EXISTS education_level CASCADE;
        CREATE TYPE education_level AS ENUM (
            'Chưa đi học', 'Tiểu học', 'Trung học cơ sở', 'Trung học phổ thông',
            'Trung cấp', 'Cao đẳng', 'Đại học', 'Thạc sĩ', 'Tiến sĩ', 'Khác', 'Không xác định'
        );

        -- Địa chỉ & Hành chính
        DROP TYPE IF EXISTS address_type CASCADE;
        CREATE TYPE address_type AS ENUM ('Thường trú', 'Tạm trú', 'Nơi ở hiện tại', 'Công ty', 'Học tập', 'Khác');

        DROP TYPE IF EXISTS division_type CASCADE; -- Loại đơn vị hành chính
        CREATE TYPE division_type AS ENUM (
            'Tỉnh', 'Thành phố trực thuộc TW', 'Quận', 'Huyện', 'Thị xã',
            'Thành phố thuộc tỉnh', 'Phường', 'Xã', 'Thị trấn'
        );

        -- Đồng bộ & CDC (Giữ lại những cái có thể hữu ích cho audit/logic đồng bộ FDW)
        DROP TYPE IF EXISTS sync_status CASCADE;
        CREATE TYPE sync_status AS ENUM ('Chưa đồng bộ', 'Đang đồng bộ', 'Đã đồng bộ', 'Lỗi đồng bộ', 'Xung đột', 'Đã hòa giải');

        DROP TYPE IF EXISTS cdc_operation_type CASCADE; -- Có thể dùng trong audit log
        CREATE TYPE cdc_operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT');

        DROP TYPE IF EXISTS sync_priority CASCADE;
        CREATE TYPE sync_priority AS ENUM ('Thấp', 'Trung bình', 'Cao', 'Khẩn cấp');

        -- Quản lý & Bảo mật
        DROP TYPE IF EXISTS data_sensitivity_level CASCADE;
        CREATE TYPE data_sensitivity_level AS ENUM ('Công khai', 'Hạn chế', 'Bảo mật', 'Tối mật');

    END;
    $_$ LANGUAGE plpgsql;

    -- Gọi hàm helper để tạo ENUMs chung
    PERFORM _create_common_enums_bca();

    -- Tạo các ENUM đặc thù của Bộ Công an
    RAISE NOTICE '   -> Tạo ENUMs đặc thù của Bộ Công an...';
    DROP TYPE IF EXISTS card_type CASCADE;
    CREATE TYPE card_type AS ENUM ('CMND 9 số', 'CMND 12 số', 'CCCD', 'CCCD gắn chip');

    DROP TYPE IF EXISTS card_status CASCADE;
    CREATE TYPE card_status AS ENUM ('Đang sử dụng', 'Hết hạn', 'Mất', 'Hỏng', 'Thu hồi', 'Đã thay thế', 'Tạm giữ');

    DROP TYPE IF EXISTS movement_type CASCADE;
    CREATE TYPE movement_type AS ENUM ('Trong nước', 'Xuất cảnh', 'Nhập cảnh', 'Tái nhập cảnh');

    DROP TYPE IF EXISTS verification_level CASCADE; -- Mức xác thực định danh điện tử VNeID
    CREATE TYPE verification_level AS ENUM ('Mức 1', 'Mức 2');

    DROP TYPE IF EXISTS user_type CASCADE; -- Loại tài khoản người dùng hệ thống
    CREATE TYPE user_type AS ENUM ('Công dân', 'Cán bộ', 'Quản trị viên');

    DROP TYPE IF EXISTS criminal_record_type CASCADE; -- Phân loại tiền án/tiền sự
    CREATE TYPE criminal_record_type AS ENUM (
        'Vi phạm hành chính', 'Tội phạm ít nghiêm trọng', 'Tội phạm nghiêm trọng', -- Điều chỉnh theo luật VN
        'Tội phạm rất nghiêm trọng', 'Tội phạm đặc biệt nghiêm trọng'
    );

    -- Dọn dẹp hàm helper (tùy chọn, vì nó sẽ bị ghi đè ở DB khác)
    -- DROP FUNCTION IF EXISTS _create_common_enums_bca();

END $$;
\echo '-> Hoàn thành tạo ENUMs cho ministry_of_public_security.'

-- ============================================================================
-- C. TẠO ENUM CHO DATABASE BỘ TƯ PHÁP (ministry_of_justice)
-- ============================================================================
\echo 'Bước 2: Tạo ENUMs cho ministry_of_justice...'
\connect ministry_of_justice

DO $$
BEGIN
    RAISE NOTICE '   -> Định nghĩa hàm tạo ENUMs chung cho BTP...';
     -- Định nghĩa lại hàm helper trong context DB này
    CREATE OR REPLACE FUNCTION _create_common_enums_btp() RETURNS void AS $_$
    BEGIN
        RAISE NOTICE '      -> Tạo ENUMs chung...';
        -- Thông tin cơ bản
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
            'Trung cấp', 'Cao đẳng', 'Đại học', 'Thạc sĩ', 'Tiến sĩ', 'Khác', 'Không xác định'
        );
        -- Địa chỉ & Hành chính
        DROP TYPE IF EXISTS address_type CASCADE;
        CREATE TYPE address_type AS ENUM ('Thường trú', 'Tạm trú', 'Nơi ở hiện tại', 'Công ty', 'Học tập', 'Khác');
        DROP TYPE IF EXISTS division_type CASCADE;
        CREATE TYPE division_type AS ENUM (
            'Tỉnh', 'Thành phố trực thuộc TW', 'Quận', 'Huyện', 'Thị xã',
            'Thành phố thuộc tỉnh', 'Phường', 'Xã', 'Thị trấn'
        );
        -- Đồng bộ & CDC
        DROP TYPE IF EXISTS sync_status CASCADE;
        CREATE TYPE sync_status AS ENUM ('Chưa đồng bộ', 'Đang đồng bộ', 'Đã đồng bộ', 'Lỗi đồng bộ', 'Xung đột', 'Đã hòa giải');
        DROP TYPE IF EXISTS cdc_operation_type CASCADE;
        CREATE TYPE cdc_operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT');
        DROP TYPE IF EXISTS sync_priority CASCADE;
        CREATE TYPE sync_priority AS ENUM ('Thấp', 'Trung bình', 'Cao', 'Khẩn cấp');
        -- Quản lý & Bảo mật
        DROP TYPE IF EXISTS data_sensitivity_level CASCADE;
        CREATE TYPE data_sensitivity_level AS ENUM ('Công khai', 'Hạn chế', 'Bảo mật', 'Tối mật');
    END;
    $_$ LANGUAGE plpgsql;

    -- Gọi hàm helper để tạo ENUMs chung
    PERFORM _create_common_enums_btp();

    -- Tạo các ENUM đặc thù của Bộ Tư pháp
    RAISE NOTICE '   -> Tạo ENUMs đặc thù của Bộ Tư pháp...';
    DROP TYPE IF EXISTS civil_document_type CASCADE; -- Loại giấy tờ hộ tịch
    CREATE TYPE civil_document_type AS ENUM (
        'Giấy khai sinh', 'Giấy khai tử', 'Giấy đăng ký kết hôn',
        'Quyết định công nhận thuận tình ly hôn', 'Bản án ly hôn', -- Chi tiết hơn ly hôn
        'Giấy xác nhận tình trạng hôn nhân',
        'Giấy xác nhận thông tin hộ tịch', 'Trích lục hộ tịch', 'Quyết định thay đổi/cải chính hộ tịch', 'Khác'
    );

    DROP TYPE IF EXISTS record_status CASCADE; -- Trạng thái xử lý hồ sơ/bản ghi
    CREATE TYPE record_status AS ENUM ('Mới', 'Đang xử lý', 'Đã duyệt', 'Từ chối', 'Yêu cầu bổ sung', 'Đã hủy', 'Đã cấp');

    DROP TYPE IF EXISTS household_relationship CASCADE; -- Quan hệ với chủ hộ
    CREATE TYPE household_relationship AS ENUM (
        'Chủ hộ', 'Vợ', 'Chồng', 'Con đẻ', 'Con nuôi', 'Bố đẻ', 'Mẹ đẻ', 'Bố nuôi', 'Mẹ nuôi',
        'Ông nội', 'Bà nội', 'Ông ngoại', 'Bà ngoại',
        'Anh ruột', 'Chị ruột', 'Em ruột',
        'Cháu ruột', 'Chắt ruột', 'Cô ruột', 'Dì ruột', 'Chú ruột', 'Bác ruột',
        'Người giám hộ', 'Người ở nhờ', 'Người làm thuê', 'Khác' -- Thêm chi tiết
    );

    DROP TYPE IF EXISTS family_relationship_type CASCADE; -- Loại quan hệ gia đình nói chung
    CREATE TYPE family_relationship_type AS ENUM (
        'Vợ-Chồng', 'Cha đẻ-Con đẻ', 'Mẹ đẻ-Con đẻ', 'Cha nuôi-Con nuôi', 'Mẹ nuôi-Con nuôi', -- Chi tiết
        'Ông nội-Cháu nội', 'Bà nội-Cháu nội', 'Ông ngoại-Cháu ngoại', 'Bà ngoại-Cháu ngoại', -- Chi tiết
        'Anh ruột-Em ruột', 'Chị ruột-Em ruột', -- Quan hệ ngang hàng
        'Giám hộ-Được giám hộ', 'Khác'
    );

    DROP TYPE IF EXISTS guardianship_type CASCADE; -- Loại hình giám hộ
    CREATE TYPE guardianship_type AS ENUM (
        'Giám hộ đương nhiên', 'Giám hộ cử', 'Giám hộ cho người chưa thành niên',
        'Giám hộ cho người mất năng lực hành vi dân sự', 'Giám hộ cho người có khó khăn trong nhận thức, làm chủ hành vi'
    );

    DROP TYPE IF EXISTS recognition_type CASCADE; -- Loại hình nhận cha/mẹ/con
    CREATE TYPE recognition_type AS ENUM ('Cha nhận con', 'Mẹ nhận con', 'Con nhận cha', 'Con nhận mẹ');

    DROP TYPE IF EXISTS population_change_type CASCADE; -- Loại biến động dân cư/hộ tịch
    CREATE TYPE population_change_type AS ENUM (
        'Đăng ký khai sinh', 'Đăng ký khai tử', 'Đăng ký kết hôn', 'Đăng ký ly hôn',
        'Đăng ký giám hộ', 'Chấm dứt giám hộ', 'Đăng ký nhận cha mẹ con',
        'Đăng ký thay đổi/cải chính/bổ sung hộ tịch', 'Xác định lại dân tộc', 'Xác định lại giới tính',
        'Đăng ký thường trú', 'Xóa đăng ký thường trú', 'Đăng ký tạm trú', 'Xóa đăng ký tạm trú', 'Tạm vắng',
        'Nhập quốc tịch', 'Thôi quốc tịch', 'Trở lại quốc tịch', 'Khác'
    );

    DROP TYPE IF EXISTS nationality_change_type CASCADE; -- Loại thay đổi quốc tịch
    CREATE TYPE nationality_change_type AS ENUM ('Nhập quốc tịch', 'Thôi quốc tịch', 'Trở lại quốc tịch', 'Hủy bỏ quyết định cho thôi/trở lại quốc tịch');

    DROP TYPE IF EXISTS household_status CASCADE; -- Trạng thái sổ hộ khẩu
    CREATE TYPE household_status AS ENUM ('Đang hoạt động', 'Tách hộ', 'Đã chuyển đi', 'Đã xóa', 'Đang cập nhật', 'Lưu trữ');

    DROP TYPE IF EXISTS household_type CASCADE; -- Loại hình hộ khẩu
    CREATE TYPE household_type AS ENUM ('Hộ gia đình', 'Hộ tập thể', 'Hộ tạm trú'); -- Đơn giản hóa

    -- DROP FUNCTION IF EXISTS _create_common_enums_btp();

END $$;
\echo '-> Hoàn thành tạo ENUMs cho ministry_of_justice.'

-- ============================================================================
-- D. TẠO ENUM CHO DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server)
-- ============================================================================
\echo 'Bước 3: Tạo ENUMs cho national_citizen_central_server...'
\connect national_citizen_central_server

DO $$
BEGIN
    RAISE NOTICE '   -> Định nghĩa hàm tạo ENUMs chung cho TT...';
     -- Định nghĩa lại hàm helper trong context DB này
    CREATE OR REPLACE FUNCTION _create_common_enums_tt() RETURNS void AS $_$
    BEGIN
        RAISE NOTICE '      -> Tạo ENUMs chung...';
        -- Thông tin cơ bản
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
            'Trung cấp', 'Cao đẳng', 'Đại học', 'Thạc sĩ', 'Tiến sĩ', 'Khác', 'Không xác định'
        );
        -- Địa chỉ & Hành chính
        DROP TYPE IF EXISTS address_type CASCADE;
        CREATE TYPE address_type AS ENUM ('Thường trú', 'Tạm trú', 'Nơi ở hiện tại', 'Công ty', 'Học tập', 'Khác');
        DROP TYPE IF EXISTS division_type CASCADE;
        CREATE TYPE division_type AS ENUM (
            'Tỉnh', 'Thành phố trực thuộc TW', 'Quận', 'Huyện', 'Thị xã',
            'Thành phố thuộc tỉnh', 'Phường', 'Xã', 'Thị trấn'
        );
        -- Đồng bộ & CDC
        DROP TYPE IF EXISTS sync_status CASCADE;
        CREATE TYPE sync_status AS ENUM ('Chưa đồng bộ', 'Đang đồng bộ', 'Đã đồng bộ', 'Lỗi đồng bộ', 'Xung đột', 'Đã hòa giải');
        DROP TYPE IF EXISTS cdc_operation_type CASCADE;
        CREATE TYPE cdc_operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT');
        DROP TYPE IF EXISTS sync_priority CASCADE;
        CREATE TYPE sync_priority AS ENUM ('Thấp', 'Trung bình', 'Cao', 'Khẩn cấp');
        -- Quản lý & Bảo mật
        DROP TYPE IF EXISTS data_sensitivity_level CASCADE;
        CREATE TYPE data_sensitivity_level AS ENUM ('Công khai', 'Hạn chế', 'Bảo mật', 'Tối mật');
    END;
    $_$ LANGUAGE plpgsql;

    -- Gọi hàm helper để tạo ENUMs chung
    PERFORM _create_common_enums_tt();

    -- Tạo các ENUM cần thiết cho dữ liệu tích hợp (tạo lại các ENUM từ BCA/BTP nếu bảng central.* dùng)
    RAISE NOTICE '   -> Tạo ENUMs cần thiết cho dữ liệu tích hợp (tái định nghĩa nếu cần)...';
    DROP TYPE IF EXISTS card_type CASCADE;
    CREATE TYPE card_type AS ENUM ('CMND 9 số', 'CMND 12 số', 'CCCD', 'CCCD gắn chip');

    DROP TYPE IF EXISTS household_type CASCADE;
    CREATE TYPE household_type AS ENUM ('Hộ gia đình', 'Hộ tập thể', 'Hộ tạm trú');

    DROP TYPE IF EXISTS household_status CASCADE;
    CREATE TYPE household_status AS ENUM ('Đang hoạt động', 'Tách hộ', 'Đã chuyển đi', 'Đã xóa', 'Đang cập nhật', 'Lưu trữ');
    -- Thêm các ENUM khác từ BCA/BTP nếu bảng/view/function ở central cần dùng trực tiếp kiểu đó

    -- Tạo các ENUM đặc thù của Máy chủ trung tâm
    RAISE NOTICE '   -> Tạo ENUMs đặc thù của Máy chủ trung tâm...';
    DROP TYPE IF EXISTS central_sync_type CASCADE; -- Loại hình đồng bộ tại TT
    CREATE TYPE central_sync_type AS ENUM ('Đồng bộ toàn bộ', 'Đồng bộ tăng trưởng', 'Đồng bộ thủ công', 'Đồng bộ theo lịch');

    DROP TYPE IF EXISTS central_report_type CASCADE; -- Loại báo cáo tại TT
    CREATE TYPE central_report_type AS ENUM ('Dân số', 'Di cư', 'Hộ tịch', 'Thống kê hành chính', 'Phân tích xu hướng', 'Dashboard');

    DROP TYPE IF EXISTS system_sync_status CASCADE; -- Trạng thái đồng bộ tổng thể hệ thống
    CREATE TYPE system_sync_status AS ENUM ('Đồng bộ hoàn toàn', 'Đồng bộ một phần', 'Chưa đồng bộ', 'Lỗi đồng bộ', 'Đang xử lý', 'Xung đột dữ liệu');

    DROP TYPE IF EXISTS data_source CASCADE; -- Nguồn gốc dữ liệu tích hợp
    CREATE TYPE data_source AS ENUM ('BCA', 'BTP', 'TT Tổng hợp', 'Nguồn khác'); -- Đơn giản hóa

    DROP TYPE IF EXISTS partition_status CASCADE; -- Trạng thái của một partition
    CREATE TYPE partition_status AS ENUM ('Hoạt động', 'Đang tạo', 'Đang tách', 'Đang gộp', 'Bảo trì', 'Chỉ đọc', 'Lỗi', 'Đã lưu trữ');

    DROP TYPE IF EXISTS incident_severity CASCADE; -- Mức độ nghiêm trọng sự cố
    CREATE TYPE incident_severity AS ENUM ('Thông tin', 'Cảnh báo', 'Trung bình', 'Cao', 'Nghiêm trọng');

    DROP TYPE IF EXISTS incident_type CASCADE; -- Loại sự cố hệ thống
    CREATE TYPE incident_type AS ENUM ('Lỗi đồng bộ', 'Lỗi FDW', 'Lỗi ứng dụng TT', 'Lỗi CSDL TT', 'Lỗi hạ tầng', 'Lỗi dữ liệu', 'Lỗi bảo mật', 'Khác');

    DROP TYPE IF EXISTS incident_status CASCADE; -- Trạng thái xử lý sự cố
    CREATE TYPE incident_status AS ENUM ('Mới', 'Đang xác minh', 'Đang xử lý', 'Đã xử lý', 'Đã đóng', 'Tạm đóng');

    -- DROP FUNCTION IF EXISTS _create_common_enums_tt();

END $$;
\echo '-> Hoàn thành tạo ENUMs cho national_citizen_central_server.'

-- ============================================================================
-- KẾT THÚC
-- ============================================================================
\echo '*** HOÀN THÀNH QUÁ TRÌNH TẠO ENUM TYPES ***'
\echo '-> Đã tạo các ENUMs chung và đặc thù cho 3 database.'
\echo '-> Bước tiếp theo: Chạy 01_common/03_reference_tables.sql để tạo cấu trúc bảng tham chiếu.'
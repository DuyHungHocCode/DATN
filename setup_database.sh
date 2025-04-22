#!/bin/bash
# Script chạy thử nghiệm database Bộ Công An (BCA)
# Phiên bản có ghi log output vào file và sửa thứ tự thực thi

# Thông tin kết nối
DB_HOST="localhost"
DB_PORT="5432"
DB_SUPERUSER="postgres"
DB_PASSWORD="123"  # Thay đổi mật khẩu ở đây
PROJECT_DIR="/home/duyhung/Desktop/DATN/citizen-management-system_v4"  # Thay đổi đường dẫn thư mục dự án

# File log
LOG_DIR="$PROJECT_DIR/logs" # Thư mục lưu log (tùy chọn)
mkdir -p "$LOG_DIR" # Tạo thư mục nếu chưa có
LOG_FILE="$LOG_DIR/bca_setup_$(date +%Y%m%d_%H%M%S).log" # Tên file log kèm timestamp

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== BẮT ĐẦU THIẾT LẬP DATABASE BỘ CÔNG AN ===${NC}"
echo -e "${YELLOW}Output chi tiết sẽ được ghi vào file: $LOG_FILE${NC}"

# Ghi dòng bắt đầu vào file log
echo "==================================================" >> "$LOG_FILE"
echo " Bắt đầu Script: $(date)" >> "$LOG_FILE"
echo "==================================================" >> "$LOG_FILE"


# Hàm thực thi file SQL với superuser, ghi log bằng tee
execute_as_superuser() {
    local file=$1
    echo -e "\n${YELLOW}Executing: $file${NC}"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_SUPERUSER -v ON_ERROR_STOP=1 -f "$file" 2>&1 | tee -a "$LOG_FILE"
    local psql_status=${PIPESTATUS[0]}
    if [ $psql_status -eq 0 ]; then
        echo -e "${GREEN}✓ Đã thực thi thành công: $file${NC}"
        echo "[SUCCESS] $file" >> "$LOG_FILE"
    else
        echo -e "${RED}✗ Lỗi khi thực thi: $file (Exit status: $psql_status)${NC}"
        echo "[FAILED] $file (Exit status: $psql_status)" >> "$LOG_FILE"
        echo "==================================================" >> "$LOG_FILE"
        echo " Script thất bại: $(date)" >> "$LOG_FILE"
        echo "==================================================" >> "$LOG_FILE"
        exit 1
    fi
}

# Hàm thực thi file SQL trên database BCA, ghi log bằng tee
execute_on_bca() {
    local file=$1
    echo -e "\n${YELLOW}Executing on BCA: $file${NC}"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_SUPERUSER -d ministry_of_public_security -v ON_ERROR_STOP=1 -f "$file" 2>&1 | tee -a "$LOG_FILE"
    local psql_status=${PIPESTATUS[0]}
    if [ $psql_status -eq 0 ]; then
        echo -e "${GREEN}✓ Đã thực thi thành công trên BCA: $file${NC}"
         echo "[SUCCESS] (BCA) $file" >> "$LOG_FILE"
    else
        echo -e "${RED}✗ Lỗi khi thực thi trên BCA: $file (Exit status: $psql_status)${NC}"
        echo "[FAILED] (BCA) $file (Exit status: $psql_status)" >> "$LOG_FILE"
        echo "==================================================" >> "$LOG_FILE"
        echo " Script thất bại: $(date)" >> "$LOG_FILE"
        echo "==================================================" >> "$LOG_FILE"
        exit 1
    fi
}

# --- Các bước thực thi ---

# # 1. Khởi tạo Database và Schema cơ bản
# echo -e "\n${GREEN}BƯỚC 1: KHỞI TẠO DATABASE VÀ SCHEMA${NC}"
# # **QUAN TRỌNG: Sử dụng file 01_create_databases_v3.1.sql đã loại bỏ bước GRANT CONNECT**
# execute_as_superuser "$PROJECT_DIR/database/00_init/01_create_databases.sql" # Đổi tên file nếu cần
# execute_as_superuser "$PROJECT_DIR/database/00_init/02_create_schemas.sql"

# # 2. Tạo roles bảo mật (**CHUYỂN LÊN TRƯỚC**)
# echo -e "\n${GREEN}BƯỚC 2: TẠO ROLES BẢO MẬT${NC}"
# execute_as_superuser "$PROJECT_DIR/database/02_security/01_roles.sql" # Sử dụng file đã sửa lỗi DROP OWNED BY

# # 3. Cài đặt Extensions (**CHẠY SAU KHI CÓ DB**)
# echo -e "\n${GREEN}BƯỚC 3: CÀI ĐẶT EXTENSIONS${NC}"
# execute_on_bca "$PROJECT_DIR/database/01_common/01_extensions.sql" # Sử dụng file đã sửa lỗi \echo và pg_cron

# 4. Tạo ENUM Types
echo -e "\n${GREEN}BƯỚC 4: TẠO ENUM TYPES${NC}"
execute_on_bca "$PROJECT_DIR/database/01_common/02_enum.sql"

# 5. Tạo bảng tham chiếu``
echo -e "\n${GREEN}BƯỚC 5: TẠO BẢNG THAM CHIẾU${NC}"
execute_on_bca "$PROJECT_DIR/database/01_common/03_reference_tables.sql"

# 6. Nạp dữ liệu mẫu vào bảng tham chiếu
echo -e "\n${GREEN}BƯỚC 6: NẠP DỮ LIỆU MẪU VÀO BẢNG THAM CHIẾU${NC}"
SAMPLE_DATA_SQL="/tmp/bca_sample_reference_data_$$.sql"
cat > "$SAMPLE_DATA_SQL" << 'EOF'
-- Dữ liệu mẫu cho reference.regions
INSERT INTO reference.regions (region_id, region_code, region_name, description)
VALUES
    (1, 'BAC', 'Bắc', 'Miền Bắc Việt Nam'),
    (2, 'TRUNG', 'Trung', 'Miền Trung Việt Nam'),
    (3, 'NAM', 'Nam', 'Miền Nam Việt Nam')
ON CONFLICT DO NOTHING;

-- Dữ liệu mẫu cho reference.provinces (5 tỉnh mẫu)
INSERT INTO reference.provinces (province_id, province_code, province_name, region_id)
VALUES
    (1, '01', 'Hà Nội', 1),
    (2, '08', 'Tuyên Quang', 1),
    (3, '43', 'Đà Nẵng', 2),
    (4, '75', 'Đồng Nai', 3),
    (5, '79', 'Hồ Chí Minh', 3)
ON CONFLICT DO NOTHING;

-- Dữ liệu mẫu cho reference.districts (2-3 quận/huyện cho mỗi tỉnh)
INSERT INTO reference.districts (district_id, district_code, district_name, province_id)
VALUES
    (101, 'HN01', 'Ba Đình', 1),
    (102, 'HN02', 'Hoàn Kiếm', 1),
    (103, 'HN03', 'Cầu Giấy', 1),
    (201, 'TQ01', 'TP. Tuyên Quang', 2),
    (202, 'TQ02', 'Yên Sơn', 2),
    (301, 'DN01', 'Hải Châu', 3),
    (302, 'DN02', 'Thanh Khê', 3),
    (401, 'DNN01', 'Biên Hòa', 4),
    (402, 'DNN02', 'Long Thành', 4),
    (501, 'HCM01', 'Quận 1', 5),
    (502, 'HCM02', 'Quận 3', 5),
    (503, 'HCM03', 'Quận 7', 5)
ON CONFLICT DO NOTHING;

-- Dữ liệu mẫu cho reference.wards (2 phường/xã cho mỗi quận/huyện)
INSERT INTO reference.wards (ward_id, ward_code, ward_name, district_id)
VALUES
    (1001, 'BD01', 'Phường Phúc Xá', 101),
    (1002, 'BD02', 'Phường Trúc Bạch', 101),
    (1003, 'HK01', 'Phường Hàng Bạc', 102),
    (1004, 'HK02', 'Phường Hàng Đào', 102),
    (1005, 'CG01', 'Phường Dịch Vọng', 103),
    (1006, 'CG02', 'Phường Mai Dịch', 103),
    (2001, 'TQ_TP01', 'Phường Tân Quang', 201),
    (2002, 'TQ_TP02', 'Phường Phan Thiết', 201),
    (2003, 'YS01', 'Xã Đội Bình', 202),
    (2004, 'YS02', 'Xã Tiến Bộ', 202),
    (3001, 'HC01', 'Phường Hải Châu 1', 301),
    (3002, 'HC02', 'Phường Thạch Thang', 301),
    (3003, 'TK01', 'Phường Thanh Khê Đông', 302),
    (3004, 'TK02', 'Phường Xuân Hà', 302),
    (4001, 'BH01', 'Phường Hố Nai', 401),
    (4002, 'BH02', 'Phường Tân Mai', 401),
    (4003, 'LT01', 'Thị trấn Long Thành', 402),
    (4004, 'LT02', 'Xã An Phước', 402),
    (5001, 'Q1P1', 'Phường Bến Nghé', 501),
    (5002, 'Q1P2', 'Phường Bến Thành', 501),
    (5003, 'Q3P1', 'Phường 1', 502),
    (5004, 'Q3P2', 'Phường 2', 502),
    (5005, 'Q7P1', 'Phường Tân Phong', 503),
    (5006, 'Q7P2', 'Phường Tân Thuận Đông', 503)
ON CONFLICT DO NOTHING;

-- Dữ liệu mẫu cho reference.ethnicities
INSERT INTO reference.ethnicities (ethnicity_id, ethnicity_code, ethnicity_name)
VALUES
    (1, 'KINH', 'Kinh'),
    (2, 'HOA', 'Hoa'),
    (3, 'TAY', 'Tày'),
    (4, 'THAI', 'Thái'),
    (5, 'MUONG', 'Mường')
ON CONFLICT DO NOTHING;

-- Dữ liệu mẫu cho reference.religions
INSERT INTO reference.religions (religion_id, religion_code, religion_name)
VALUES
    (1, 'NONE', 'Không'),
    (2, 'BUDDHISM', 'Phật giáo'),
    (3, 'CATHOLIC', 'Công giáo'),
    (4, 'PROTESTANT', 'Tin lành'),
    (5, 'CAODAI', 'Cao Đài')
ON CONFLICT DO NOTHING;

-- Dữ liệu mẫu cho reference.nationalities
INSERT INTO reference.nationalities (nationality_id, nationality_code, iso_code_alpha2, iso_code_alpha3, nationality_name, country_name)
VALUES
    (1, '001', 'VN', 'VNM', 'Việt Nam', 'Cộng hòa xã hội chủ nghĩa Việt Nam'),
    (2, '002', 'CN', 'CHN', 'Trung Quốc', 'Cộng hòa nhân dân Trung Hoa'),
    (3, '003', 'US', 'USA', 'Hoa Kỳ', 'Hợp chủng quốc Hoa Kỳ'),
    (4, '004', 'KR', 'KOR', 'Hàn Quốc', 'Đại Hàn Dân Quốc'),
    (5, '005', 'JP', 'JPN', 'Nhật Bản', 'Nhật Bản')
ON CONFLICT DO NOTHING;

-- Dữ liệu mẫu cho reference.authorities
INSERT INTO reference.authorities (authority_id, authority_code, authority_name, authority_type)
VALUES
    (1, 'BCA_HN', 'Công an thành phố Hà Nội', 'Công an'),
    (2, 'BCA_HCM', 'Công an thành phố Hồ Chí Minh', 'Công an'),
    (3, 'BCA_DN', 'Công an thành phố Đà Nẵng', 'Công an'),
    (4, 'BCA_TQ', 'Công an tỉnh Tuyên Quang', 'Công an'),
    (5, 'BCA_DNA', 'Công an tỉnh Đồng Nai', 'Công an')
ON CONFLICT DO NOTHING;

EOF
execute_on_bca "$SAMPLE_DATA_SQL"
rm -f "$SAMPLE_DATA_SQL"

# 7. Tạo schema partitioning
echo -e "\n${GREEN}BƯỚC 7: TẠO CÁC BẢNG HỖ TRỢ PARTITIONING${NC}" # Đổi tên bước
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/partitioning.sql"

# 8. Tạo schema audit
echo -e "\n${GREEN}BƯỚC 8: TẠO BẢNG AUDIT LOG${NC}" # Đổi tên bước
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/audit.sql"

# 9. Tạo các bảng chính trong schema public_security
echo -e "\n${GREEN}BƯỚC 9: TẠO CÁC BẢNG NGHIỆP VỤ CHÍNH (public_security)${NC}"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/address.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/citizen.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/identification_card.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/permanent_residence.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/temporary_residence.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/temporary_absence.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/citizen_address.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/citizen_movement.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/citizen_status.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/criminal_record.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/digital_identity.sql"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/schemas/public_security/user_account.sql"

# 10. Tạo các function phân vùng
echo -e "\n${GREEN}BƯỚC 10: TẠO CÁC FUNCTION PHÂN VÙNG${NC}"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/partitioning/functions.sql"

# 11. Tạo và gắn trigger audit (**CHUYỂN LÊN TRƯỚC KHI CẤP QUYỀN**)
echo -e "\n${GREEN}BƯỚC 11: TẠO VÀ GẮN TRIGGER AUDIT${NC}"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/triggers/audit_triggers.sql"

# 12. Cấp quyền chi tiết (**CHẠY TRƯỚC KHI THỰC THI PARTITIONING**)
echo -e "\n${GREEN}BƯỚC 12: CẤP QUYỀN CHI TIẾT${NC}"
execute_as_superuser "$PROJECT_DIR/database/02_security/02_permissions.sql"

# 13. Thực thi phân vùng (**CHẠY SAU KHI CÓ BẢNG, FUNCTION, QUYỀN**)
echo -e "\n${GREEN}BƯỚC 13: THỰC THI PHÂN VÙNG${NC}"
PART_CONFIG_SQL="/tmp/bca_part_config_$$.sql"
cat > "$PART_CONFIG_SQL" << 'EOF'
INSERT INTO partitioning.config (schema_name, table_name, partition_type, partition_columns, is_active, use_pg_partman, partition_interval, retention_period)
VALUES
    ('public_security', 'address', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'citizen', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'identification_card', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'permanent_residence', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'temporary_residence', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'temporary_absence', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL), -- Chỉ 2 cấp
    ('public_security', 'citizen_address', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'citizen_movement', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL), -- Chỉ 2 cấp
    ('public_security', 'citizen_status', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL), -- Chỉ 2 cấp
    ('public_security', 'criminal_record', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL), -- Chỉ 2 cấp
    ('public_security', 'digital_identity', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL), -- Chỉ 2 cấp
    ('audit', 'audit_log', 'RANGE', 'action_tstamp', TRUE, TRUE, '1 month', '12 months') -- Dùng pg_partman cho audit
ON CONFLICT (schema_name, table_name) DO UPDATE SET
    partition_type = EXCLUDED.partition_type,
    partition_columns = EXCLUDED.partition_columns,
    is_active = EXCLUDED.is_active,
    use_pg_partman = EXCLUDED.use_pg_partman,
    partition_interval = EXCLUDED.partition_interval,
    retention_period = EXCLUDED.retention_period,
    updated_at = CURRENT_TIMESTAMP;
EOF
execute_on_bca "$PART_CONFIG_SQL"
rm -f "$PART_CONFIG_SQL"
execute_on_bca "$PROJECT_DIR/database/ministry_of_public_security/partitioning/execute_setup.sql"

# Ghi dòng kết thúc vào file log
echo "==================================================" >> "$LOG_FILE"
echo " Script hoàn thành: $(date)" >> "$LOG_FILE"
echo "==================================================" >> "$LOG_FILE"

echo -e "\n${GREEN}=== HOÀN THÀNH THIẾT LẬP DATABASE BỘ CÔNG AN ===${NC}"
echo -e "\n${YELLOW}Log chi tiết đã được ghi vào: $LOG_FILE${NC}"
echo -e "\n${YELLOW}HƯỚNG DẪN SỬ DỤNG:${NC}"
# ... (hướng dẫn sử dụng giữ nguyên) ...

exit 0
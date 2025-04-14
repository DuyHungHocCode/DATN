#!/bin/bash

# Cấu hình thông tin kết nối PostgreSQL
DB_USER="postgres"  # Thay bằng tên người dùng PostgreSQL của bạn
DB_NAME="test"  # Thay bằng tên cơ sở dữ liệu của bạn
DB_HOST="localhost"      # Địa chỉ máy chủ PostgreSQL
DB_PORT="5432"           # Cổng PostgreSQL
DB_PASSWORD="123"  # Bỏ comment và thay bằng mật khẩu của bạn nếu cần

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

run_sql_file() {
    local file=$1
    echo -e "${BLUE}Đang chạy file: ${file}${NC}"
    
    # Sử dụng cat để đọc file và gửi nội dung vào psql
    cat "${file}" | sudo -u postgres psql || {
        echo -e "${RED}Lỗi khi chạy file ${file}${NC}"
        exit 1
    }
    
    echo -e "${GREEN}Hoàn thành file: ${file}${NC}"
}

echo -e "${GREEN}=== Bắt đầu tạo CSDL phân tán quản lý dân cư quốc gia ===${NC}"

echo -e "${YELLOW}=== 1. Khởi tạo CSDL cơ bản ===${NC}"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/init/create_database.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/init/create_schemas.sql"


# Phần còn lại của script giữ nguyên
# 2. Tạo các cấu trúc chung
echo -e "${YELLOW}=== 2. Tạo các cấu trúc chung ===${NC}"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/common/enum.sql"
#run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/common/extensions.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/common/reference_tables.sql"

# 3. Tạo các bảng Bộ Công An (Public Security)
echo -e "${YELLOW}=== 3. Tạo các bảng Bộ Công An ===${NC}"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/citizen.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/address.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/identification_card.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/biometric_data.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/residence.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/citizen_status.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/citizen_image.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/citizen_movement.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/digital_identity.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/user_account.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/public_security/criminal_record.sql"


# 4. Tạo các bảng Bộ Tư Pháp (Justice)
echo -e "${YELLOW}=== 4. Tạo các bảng Bộ Tư Pháp ===${NC}"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/household.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/household_member.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/birth_certificate.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/death_certificate.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/marriage.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/divorce.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/population_change.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/family_relationship.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/schemas/justice/guardian_relationship.sql"

echo -e "${YELLOW}=== 5. Tạo các ràng buộc ===${NC}"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/contraints/foreign_keys_central_server.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/contraints/foreign_keys_central.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/contraints/foreign_keys_north.sql"
run_sql_file "/home/duyhung/Desktop/DATN/citizen-management-system/database/contraints/foreign_keys_south.sql"

echo -e "${GREEN}=== Hoàn thành tạo CSDL phân tán quản lý dân cư quốc gia ===${NC}"
exit 0
#!/bin/bash
# Script này chạy tự động khi container PostgreSQL khởi động lần đầu tiên.
# Nó sẽ thực thi các file SQL để tạo databases, roles, schemas, tables, etc.

# Thoát ngay lập tức nếu có lỗi
set -e

# Biến môi trường được cung cấp bởi Docker/docker-compose
# POSTGRES_USER và POSTGRES_PASSWORD là user superuser ban đầu
echo "****** BẮT ĐẦU KHỞI TẠO DATABASE QLDCQG ******"

# Hàm thực thi file SQL với superuser mặc định trên database 'postgres'
# $1: Đường dẫn đến file SQL
execute_sql_on_postgres() {
    local sql_file="$1"
    echo "[POSTGRES] Executing: $sql_file ..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" -f "$sql_file"
    echo "[POSTGRES] Finished: $sql_file"
}

# Hàm thực thi file SQL trên một database cụ thể
# $1: Tên database
# $2: Đường dẫn đến file SQL
execute_sql_on_db() {
    local db_name="$1"
    local sql_file="$2"
    echo "[$db_name] Executing: $sql_file ..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" -f "$sql_file"
    echo "[$db_name] Finished: $sql_file"
}

# Đường dẫn gốc chứa các script SQL (đã được COPY vào /docker-entrypoint-initdb.d/database)
SQL_DIR="/docker-entrypoint-initdb.d/database"

# === Bước 1: Khởi tạo Databases và Schemas ===
echo "--- Bước 1: Khởi tạo Databases và Schemas ---"
execute_sql_on_postgres "${SQL_DIR}/00_init/01_create_databases.sql"
# create_schemas.sql chứa lệnh \connect nên chạy trên postgres
execute_sql_on_postgres "${SQL_DIR}/00_init/02_create_schemas.sql"

# === Bước 2: Tạo Roles ===
echo "--- Bước 2: Tạo Roles ---"
# roles.sql chứa lệnh \connect nên chạy trên postgres
# **QUAN TRỌNG**: Script này cần sử dụng mật khẩu từ biến môi trường
# Thay thế mật khẩu cứng trong file roles.sql bằng biến môi trường nếu có thể,
# hoặc đảm bảo biến môi trường trong docker-compose khớp với mật khẩu trong file roles.sql
# Ví dụ sửa file roles.sql để dùng biến: ENCRYPTED PASSWORD '${DB_PASSWORD_ADMIN_BCA}'
# Nếu không sửa file roles.sql, đảm bảo biến môi trường docker-compose khớp mật khẩu cứng.
execute_sql_on_postgres "${SQL_DIR}/02_security/01_roles.sql"

# === Bước 3: Cài đặt Thành phần Chung ===
echo "--- Bước 3: Cài đặt Thành phần Chung (Extensions, Enums, Ref Tables) ---"
# Các script này chứa \connect nên chạy trên postgres
execute_sql_on_postgres "${SQL_DIR}/01_common/01_extensions.sql"
execute_sql_on_postgres "${SQL_DIR}/01_common/02_enum.sql"
execute_sql_on_postgres "${SQL_DIR}/01_common/03_reference_tables.sql"

# === Bước 4: Nạp Dữ liệu Tham chiếu ===
echo "--- Bước 4: Nạp Dữ liệu Tham chiếu ---"
DATABASES=("ministry_of_public_security" "ministry_of_justice" "national_citizen_central_server")
REF_DATA_DIR="${SQL_DIR}/01_common/reference_data"
for db in "${DATABASES[@]}"; do
    echo "--- Loading reference data into $db ---"
    # Tìm và chạy tất cả file .sql trong thư mục reference_data
    find "$REF_DATA_DIR" -maxdepth 1 -name "*.sql" -print0 | while IFS= read -r -d $'\0' file; do
        execute_sql_on_db "$db" "$file"
    done
    # Thêm logic COPY FROM CSV nếu bạn dùng CSV
done

# === Bước 5: Setup Database BCA ===
echo "--- Bước 5: Setup ministry_of_public_security (BCA) ---"
DB_BCA="ministry_of_public_security"
# Tạo bảng partitioning và audit trước
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/partitioning.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/audit.sql"
# Tạo các bảng nghiệp vụ (đảm bảo đúng thứ tự nếu có FK nội bộ)
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/address.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/citizen.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/identification_card.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/permanent_residence.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/temporary_residence.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/temporary_absence.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/citizen_address.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/citizen_movement.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/citizen_status.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/criminal_record.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/digital_identity.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/schemas/public_security/user_account.sql"
# Tạo functions và triggers
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/partitioning/functions.sql"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/triggers/audit_triggers.sql"

# === Bước 6: Setup Database BTP ===
echo "--- Bước 6: Setup ministry_of_justice (BTP) ---"
DB_BTP="ministry_of_justice"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/partitioning.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/audit.sql"
# Tạo các bảng nghiệp vụ (đảm bảo đúng thứ tự)
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/marriage.sql" # Marriage trước divorce
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/household.sql" # Household trước member
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/birth_certificate.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/death_certificate.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/divorce.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/family_relationship.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/household_member.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/schemas/justice/population_change.sql"
# Tạo functions và triggers
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/partitioning/functions.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/triggers/audit_triggers.sql"

# === Bước 7: Setup Database TT ===
echo "--- Bước 7: Setup national_citizen_central_server (TT) ---"
DB_TT="national_citizen_central_server"
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/schemas/partitioning.sql"
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/schemas/audit.sql"
# Tạo các bảng nghiệp vụ (đảm bảo đúng thứ tự)
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/schemas/central/integrated_citizen.sql" # Citizen trước household
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/schemas/central/integrated_household.sql"
# Tạo functions và triggers
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/functions/sync_logic.sql" # Cần hoàn thiện logic
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/partitioning/functions.sql"
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/triggers/audit_triggers.sql"

# === Bước 8: Cấp quyền và Thực thi Phân vùng ===
echo "--- Bước 8: Cấp quyền và Thực thi Phân vùng ---"
# Permissions script kết nối nội bộ
execute_sql_on_postgres "${SQL_DIR}/02_security/02_permissions.sql"

# Nạp cấu hình partitioning (Ví dụ - bạn cần tạo file config_data.sql hoặc nạp thủ công)
echo "--- Nạp dữ liệu cấu hình partitioning (Ví dụ) ---"
PART_CONFIG_BCA="/tmp/bca_part_config_$$.sql"
cat > "$PART_CONFIG_BCA" << 'EOF'
INSERT INTO partitioning.config (schema_name, table_name, partition_type, partition_columns, is_active, use_pg_partman, partition_interval, retention_period) VALUES
    ('public_security', 'address', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'citizen', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'identification_card', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'permanent_residence', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'temporary_residence', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'temporary_absence', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'citizen_address', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'citizen_movement', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'citizen_status', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'criminal_record', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('public_security', 'digital_identity', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('audit', 'audit_log', 'RANGE', 'action_tstamp', TRUE, TRUE, '1 month', '12 months')
ON CONFLICT (schema_name, table_name) DO UPDATE SET partition_type=EXCLUDED.partition_type, partition_columns=EXCLUDED.partition_columns, is_active=EXCLUDED.is_active, use_pg_partman=EXCLUDED.use_pg_partman, partition_interval=EXCLUDED.partition_interval, retention_period=EXCLUDED.retention_period, updated_at=CURRENT_TIMESTAMP;
EOF
execute_sql_on_db "$DB_BCA" "$PART_CONFIG_BCA"
rm -f "$PART_CONFIG_BCA"

PART_CONFIG_BTP="/tmp/btp_part_config_$$.sql"
cat > "$PART_CONFIG_BTP" << 'EOF'
INSERT INTO partitioning.config (schema_name, table_name, partition_type, partition_columns, is_active, use_pg_partman, partition_interval, retention_period) VALUES
    ('justice', 'birth_certificate', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('justice', 'death_certificate', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('justice', 'marriage', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('justice', 'divorce', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('justice', 'household', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('justice', 'household_member', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('justice', 'family_relationship', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('justice', 'population_change', 'NESTED', 'geographical_region,province_id', TRUE, FALSE, NULL, NULL),
    ('audit', 'audit_log', 'RANGE', 'action_tstamp', TRUE, TRUE, '1 month', '12 months')
ON CONFLICT (schema_name, table_name) DO UPDATE SET partition_type=EXCLUDED.partition_type, partition_columns=EXCLUDED.partition_columns, is_active=EXCLUDED.is_active, use_pg_partman=EXCLUDED.use_pg_partman, partition_interval=EXCLUDED.partition_interval, retention_period=EXCLUDED.retention_period, updated_at=CURRENT_TIMESTAMP;
EOF
execute_sql_on_db "$DB_BTP" "$PART_CONFIG_BTP"
rm -f "$PART_CONFIG_BTP"

PART_CONFIG_TT="/tmp/tt_part_config_$$.sql"
cat > "$PART_CONFIG_TT" << 'EOF'
INSERT INTO partitioning.config (schema_name, table_name, partition_type, partition_columns, is_active, use_pg_partman, partition_interval, retention_period) VALUES
    ('central', 'integrated_citizen', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('central', 'integrated_household', 'NESTED', 'geographical_region,province_id,district_id', TRUE, FALSE, NULL, NULL),
    ('audit', 'audit_log', 'RANGE', 'action_tstamp', TRUE, TRUE, '1 month', '12 months')
ON CONFLICT (schema_name, table_name) DO UPDATE SET partition_type=EXCLUDED.partition_type, partition_columns=EXCLUDED.partition_columns, is_active=EXCLUDED.is_active, use_pg_partman=EXCLUDED.use_pg_partman, partition_interval=EXCLUDED.partition_interval, retention_period=EXCLUDED.retention_period, updated_at=CURRENT_TIMESTAMP;
EOF
execute_sql_on_db "$DB_TT" "$PART_CONFIG_TT"
rm -f "$PART_CONFIG_TT"

# Thực thi setup partitioning
echo "--- Thực thi các script execute_setup.sql ---"
execute_sql_on_db "$DB_BCA" "${SQL_DIR}/${DB_BCA}/partitioning/execute_setup.sql"
execute_sql_on_db "$DB_BTP" "${SQL_DIR}/${DB_BTP}/partitioning/execute_setup.sql"
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/partitioning/execute_setup.sql"

# === Bước 9: Setup FDW và Sync Orchestration ===
echo "--- Bước 9: Setup FDW và Sync Orchestration (trên TT) ---"
# Các script này cần thông tin kết nối đúng trong fdw_setup.sql
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/fdw_and_sync/01_fdw_setup.sql"
execute_sql_on_db "$DB_TT" "${SQL_DIR}/${DB_TT}/fdw_and_sync/02_sync_orchestration.sql" # Giả định dùng pg_cron

echo "****** HOÀN THÀNH KHỞI TẠO DATABASE QLDCQG ******"

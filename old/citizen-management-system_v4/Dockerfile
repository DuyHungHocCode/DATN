# Sử dụng image PostGIS chính thức dựa trên PostgreSQL 16 và Debian
# Chọn phiên bản PostGIS phù hợp (ví dụ: 3.4)
FROM postgis/postgis:16-3.4

# Metadata (tùy chọn)
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="PostgreSQL 16 with PostGIS and extensions for QLDCQG"

# Chuyển sang user root để cài đặt các gói OS
USER root

# Cài đặt các gói OS cần thiết cho các extension PostgreSQL
# (Cập nhật danh sách gói dựa trên kết quả tìm kiếm thực tế trên Debian/Ubuntu)
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-contrib-16 \
    postgresql-16-repack \
    postgresql-16-pgaudit \
    postgresql-16-cron \
    # postgresql-16-pgstatmonitor (Cài nếu tìm thấy hoặc thêm repo Percona)
    # Xóa cache để giảm kích thước image
    && rm -rf /var/lib/apt/lists/*

# Sao chép các script khởi tạo vào thư mục đặc biệt của PostgreSQL entrypoint
# Các script trong thư mục này sẽ tự động chạy khi container khởi tạo lần đầu
COPY ./database /docker-entrypoint-initdb.d/database
COPY ./docker-entrypoint-initdb.d/init-db.sh /docker-entrypoint-initdb.d/init-db.sh

# Cấp quyền thực thi cho script khởi tạo
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh

# Chuyển về user postgres mặc định
USER postgres

# Ghi chú: Các file postgresql.conf và pg_hba.conf sẽ được mount thông qua docker-compose.yml
# để dễ dàng thay đổi cấu hình mà không cần build lại image.
# Nếu muốn bake cấu hình vào image, dùng lệnh COPY:
# COPY ./config/postgresql.conf /etc/postgresql/postgresql.conf
# COPY ./config/pg_hba.conf /etc/postgresql/pg_hba.conf
# RUN chown postgres:postgres /etc/postgresql/postgresql.conf /etc/postgresql/pg_hba.conf
# (Đường dẫn file config có thể khác tùy base image)

# Port mặc định của PostgreSQL
EXPOSE 5432

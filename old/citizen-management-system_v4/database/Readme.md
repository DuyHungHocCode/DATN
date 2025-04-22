# Cơ sở dữ liệu Hệ thống Quản lý Dân cư Quốc gia (QLDCQG) - Kiến trúc Microservices

## Giới thiệu

Repository này chứa các script SQL để thiết lập và quản lý cơ sở dữ liệu (CSDL) cho Hệ thống Quản lý Dân cư Quốc gia, được thiết kế theo kiến trúc microservices. Hệ thống bao gồm ba CSDL PostgreSQL riêng biệt:

1.  **`ministry_of_public_security`**: Dành cho nghiệp vụ của Bộ Công an (Quản lý công dân, CCCD, cư trú...). Viết tắt: **BCA**.
2.  **`ministry_of_justice`**: Dành cho nghiệp vụ của Bộ Tư pháp (Hộ tịch: khai sinh, khai tử, kết hôn...). Viết tắt: **BTP**.
3.  **`national_citizen_central_server`**: Máy chủ trung tâm, chứa dữ liệu tích hợp từ hai nguồn trên và phục vụ các chức năng tổng hợp, báo cáo. Viết tắt: **TT**.

Kiến trúc này giúp phân tách rõ ràng các miền nghiệp vụ, cho phép phát triển, triển khai và scale độc lập từng hệ thống con.

## Cấu trúc thư mục

Cấu trúc thư mục được tổ chức như sau để đảm bảo tính rõ ràng và dễ quản lý:

database/├── 00_init/                     # Script khởi tạo DB và schema cơ bản ban đầu│   ├── 01_create_databases.sql    # Tạo 3 databases (BCA, BTP, TT)│   └── 02_create_schemas.sql      # Tạo các schema cơ bản trong mỗi DB│├── 01_common/                   # Các thành phần chung áp dụng cho CẢ 3 databases│   ├── 01_extensions.sql        # Cài đặt các extension cần thiết│   ├── 02_enum.sql              # Định nghĩa các kiểu ENUM│   ├── 03_reference_tables.sql  # Tạo cấu trúc các bảng tham chiếu│   └── reference_data/          # Thư mục chứa dữ liệu cho các bảng tham chiếu (SQL INSERT hoặc CSV)│       └── README.md              # Hướng dẫn nạp và đồng bộ dữ liệu tham chiếu│├── 02_security/                 # Cấu hình bảo mật│   ├── 01_roles.sql             # Tạo các Roles (Cluster Level)│   └── 02_permissions.sql       # Cấp quyền chi tiết (Chạy trên từng DB)│├── ministry_of_public_security/   # Cấu hình và Schema cho DB Bộ Công an (BCA)│   ├── schemas/                 # Định nghĩa cấu trúc bảng và các đối tượng schema│   │   ├── public_security/     # Bảng nghiệp vụ chính của BCA│   │   ├── audit.sql            # Bảng audit_log cho BCA│   │   └── partitioning.sql     # Bảng hỗ trợ phân vùng cho BCA│   ├── functions/               # Các hàm PL/pgSQL đặc thù cho BCA (nếu có)│   ├── triggers/                # Các trigger đặc thù cho BCA (audit, timestamp...)│   │   └── audit_triggers.sql   # Tạo trigger function và gắn vào bảng BCA│   └── partitioning/            # Logic và thực thi phân vùng cho BCA│       ├── functions.sql        # Các hàm PL/pgSQL quản lý phân vùng│       └── execute_setup.sql    # Script thực thi việc tạo partition và index│├── ministry_of_justice/           # Cấu hình và Schema cho DB Bộ Tư pháp (BTP)│   ├── schemas/                 # Định nghĩa cấu trúc bảng và các đối tượng schema│   │   ├── justice/             # Bảng nghiệp vụ chính của BTP│   │   ├── audit.sql            # Bảng audit_log cho BTP│   │   └── partitioning.sql     # Bảng hỗ trợ phân vùng cho BTP│   ├── functions/               # Các hàm PL/pgSQL đặc thù cho BTP (nếu có)│   ├── triggers/                # Các trigger đặc thù cho BTP (audit, timestamp...)│   │   └── audit_triggers.sql   # Tạo trigger function và gắn vào bảng BTP│   └── partitioning/            # Logic và thực thi phân vùng cho BTP│       ├── functions.sql        # Các hàm PL/pgSQL quản lý phân vùng│       └── execute_setup.sql    # Script thực thi việc tạo partition và index│├── national_citizen_central_server/ # Cấu hình và Schema cho DB Trung tâm (TT)│   ├── schemas/                 # Định nghĩa cấu trúc bảng và các đối tượng schema│   │   ├── central/             # Bảng dữ liệu tích hợp│   │   ├── sync/                # Bảng hỗ trợ đồng bộ (nếu có)│   │   ├── audit.sql            # Bảng audit_log cho TT│   │   └── partitioning.sql     # Bảng hỗ trợ phân vùng cho TT│   ├── functions/               # Các hàm PL/pgSQL đặc thù cho TT│   │   └── sync_logic.sql       # Hàm chứa logic đồng bộ hóa dữ liệu (QUAN TRỌNG)│   ├── triggers/                # Các trigger đặc thù cho TT (audit, timestamp...)│   │   └── audit_triggers.sql   # Tạo trigger function và gắn vào bảng TT│   ├── partitioning/            # Logic và thực thi phân vùng cho TT│   │   ├── functions.sql        # Các hàm PL/pgSQL quản lý phân vùng│   │   └── execute_setup.sql    # Script thực thi việc tạo partition và index│   └── fdw_and_sync/            # Cấu hình FDW và điều phối đồng bộ (chạy trên TT)│       ├── 01_fdw_setup.sql       # Tạo FDW server, user mapping, import schema mirror│       └── 02_sync_orchestration.sql # Lập lịch đồng bộ (vd: dùng pg_cron)│└── README.md                    # File hướng dẫn tổng quan này
## Thứ tự thực thi Script (Khuyến nghị)

Để thiết lập CSDL từ đầu hoặc trên một môi trường mới, hãy chạy các script theo thứ tự sau. **Yêu cầu quyền superuser PostgreSQL (ví dụ: user `postgres`) cho các bước 1 và 2.**

1.  **Khởi tạo Database và Schema cơ bản:**
    * Chạy các file trong `00_init/` (kết nối với quyền superuser):
        1.  `01_create_databases.sql`
        2.  `02_create_schemas.sql`

2.  **Tạo Roles:**
    * Chạy file `02_security/01_roles.sql` (kết nối với quyền superuser).
    * **QUAN TRỌNG:** Mở file này và **thay đổi tất cả mật khẩu mặc định** (`...ChangeMe!...`) bằng mật khẩu mạnh và an toàn trước khi chạy.

3.  **Cài đặt Thành phần Chung (Chạy trên cả 3 DB):**
    * Sử dụng `psql` hoặc công cụ tương tự, kết nối lần lượt vào từng database: `ministry_of_public_security`, `ministry_of_justice`, `national_citizen_central_server`.
    * Trong mỗi database, chạy các file sau theo thứ tự:
        1.  `01_common/01_extensions.sql`
        2.  `01_common/02_enum.sql`
        3.  `01_common/03_reference_tables.sql`

4.  **Nạp Dữ liệu Tham chiếu:**
    * Kết nối vào **từng database** (BCA, BTP, TT).
    * Nạp dữ liệu vào các bảng trong schema `reference` (ví dụ: `regions`, `provinces`, `ethnicities`...). Sử dụng các script SQL INSERT hoặc công cụ import (ví dụ: `COPY FROM`) với dữ liệu từ thư mục `01_common/reference_data/`.
    * **QUAN TRỌNG:** Đảm bảo dữ liệu tham chiếu được nạp **nhất quán** trên cả 3 database. Xây dựng quy trình cập nhật dữ liệu này khi cần.

5.  **Tạo Cấu trúc Bảng và Logic theo từng Database:**
    * **Database BCA:**
        1.  Kết nối vào `ministry_of_public_security`.
        2.  Chạy lần lượt các file `.sql` trong `ministry_of_public_security/schemas/` (trừ file `audit.sql` và `partitioning.sql` đã chạy ở bước 1 hoặc sẽ chạy ngay sau). **Lưu ý:** Đảm bảo thứ tự chạy đúng nếu có sự phụ thuộc giữa các bảng (ít khả năng xảy ra nếu FK liên bảng đã bị loại bỏ).
        3.  Chạy file `ministry_of_public_security/schemas/audit.sql`.
        4.  Chạy file `ministry_of_public_security/schemas/partitioning.sql`.
        5.  Chạy các file trong `ministry_of_public_security/functions/` (nếu có).
        6.  Chạy file `ministry_of_public_security/partitioning/functions.sql`.
        7.  Chạy file `ministry_of_public_security/triggers/audit_triggers.sql`.
    * **Database BTP:**
        1.  Kết nối vào `ministry_of_justice`.
        2.  Chạy lần lượt các file `.sql` trong `ministry_of_justice/schemas/` (trừ `audit.sql`, `partitioning.sql`).
        3.  Chạy file `ministry_of_justice/schemas/audit.sql`.
        4.  Chạy file `ministry_of_justice/schemas/partitioning.sql`.
        5.  Chạy các file trong `ministry_of_justice/functions/` (nếu có).
        6.  Chạy file `ministry_of_justice/partitioning/functions.sql`.
        7.  Chạy file `ministry_of_justice/triggers/audit_triggers.sql`.
    * **Database TT:**
        1.  Kết nối vào `national_citizen_central_server`.
        2.  Chạy lần lượt các file `.sql` trong `national_citizen_central_server/schemas/` (trừ `audit.sql`, `partitioning.sql`).
        3.  Chạy file `national_citizen_central_server/schemas/audit.sql`.
        4.  Chạy file `national_citizen_central_server/schemas/partitioning.sql`.
        5.  Chạy các file trong `national_citizen_central_server/functions/` (bao gồm `sync_logic.sql` - **Lưu ý:** file này cần được hoàn thiện logic đồng bộ chi tiết).
        6.  Chạy file `national_citizen_central_server/partitioning/functions.sql`.
        7.  Chạy file `national_citizen_central_server/triggers/audit_triggers.sql`.

6.  **Cấp quyền chi tiết:**
    * Chạy file `02_security/02_permissions.sql`. Script này sẽ tự động `\connect` đến từng database để cấp quyền phù hợp cho các roles trên các schema và đối tượng đã tạo.

7.  **Thiết lập Phân vùng và Index:**
    * **Database BCA:**
        1.  Kết nối vào `ministry_of_public_security`.
        2.  *(Tùy chọn)* Nạp dữ liệu cấu hình vào `partitioning.config` nếu chưa có hoặc cần cập nhật.
        3.  Chạy file `ministry_of_public_security/partitioning/execute_setup.sql`.
    * **Database BTP:**
        1.  Kết nối vào `ministry_of_justice`.
        2.  *(Tùy chọn)* Nạp dữ liệu cấu hình vào `partitioning.config`.
        3.  Chạy file `ministry_of_justice/partitioning/execute_setup.sql`.
    * **Database TT:**
        1.  Kết nối vào `national_citizen_central_server`.
        2.  *(Tùy chọn)* Nạp dữ liệu cấu hình vào `partitioning.config`.
        3.  Chạy file `national_citizen_central_server/partitioning/execute_setup.sql`.

8.  **Thiết lập FDW và Đồng bộ hóa (Chạy trên DB TT):**
    * Kết nối vào `national_citizen_central_server`.
    * Chạy file `national_citizen_central_server/fdw_and_sync/01_fdw_setup.sql`. **QUAN TRỌNG:** Mở file này và cập nhật thông tin kết nối FDW (host, port, dbname, password) cho chính xác.
    * Chạy file `national_citizen_central_server/fdw_and_sync/02_sync_orchestration.sql` (nếu dùng pg_cron). **QUAN TRỌNG:** Đảm bảo tên function đồng bộ trong script này khớp với function đã tạo trong `sync_logic.sql`. Nếu dùng Airflow, cấu hình DAG tương ứng.

## Công nghệ & Khái niệm chính

* **CSDL:** PostgreSQL (phiên bản 13+ khuyến nghị)
* **Kiến trúc:** Microservices Database Pattern (Database per service)
* **Kết nối liên DB (cho đồng bộ):** Foreign Data Wrapper (FDW)
* **Tối ưu hóa:** Partitioning (Phân vùng dữ liệu theo địa lý và thời gian)
* **Tự động hóa:** pg_cron (hoặc Airflow) để lập lịch đồng bộ và bảo trì partition.
* **Kiểm toán:** Trigger-based Audit Logging.

## Yêu cầu môi trường

* PostgreSQL Server (phiên bản 13+) đã cài đặt và đang chạy.
* Quyền truy cập superuser vào PostgreSQL instance.
* Công cụ dòng lệnh `psql` hoặc tương đương.
* (Tùy chọn) Extension `pg_partman` nếu sử dụng cho bảng `audit_log`.
* (Tùy chọn) Apache Airflow nếu sử dụng thay thế `pg_cron`.

## Cấu hình cần thiết

* **Mật khẩu Roles:** Thay đổi trong `02_security/01_roles.sql`.
* **FDW Connections:** Cập nhật trong `national_citizen_central_server/fdw_and_sync/01_fdw_setup.sql`.
* **Sync Function Name:** Kiểm tra trong `02_sync_orchestration.sql`.
* **pg_cron Configuration:** Cấu hình trong `postgresql.conf`.

## Lưu ý quan trọng

* **Bảo mật:** Luôn thay đổi mật khẩu mặc định.
* **Logic Đồng bộ:** Logic trong `sync_logic.sql` là phần phức tạp nhất và cần được phát triển, kiểm thử kỹ lưỡng.
* **Kiểm thử:** Chạy thử nghiệm toàn bộ quy trình trên môi trường development/staging.
* **Partitioning:** Cơ chế quản lý partition (tạo mới, xóa cũ) cần được tự động hóa và giám sát.
* **Thứ tự:** Chạy script đúng thứ tự là bắt buộc.


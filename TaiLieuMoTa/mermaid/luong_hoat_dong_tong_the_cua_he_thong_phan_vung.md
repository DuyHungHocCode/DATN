```mermaid
graph TD
    subgraph "Khởi tạo"
        A[Tạo CSDL] --> B[Tạo bảng partitioning.config]
        A --> C[Tạo bảng partitioning.history]
    end

    subgraph "Thiết lập phân vùng"
        B --> D[setup_citizen_tables_partitioning]
        B --> E[setup_residence_tables_partitioning]
        B --> F[setup_civil_status_tables_partitioning]
        B --> G[setup_household_tables_partitioning]
        B --> H[setup_integrated_data_partitioning]
    end

    subgraph "Hàm phân vùng cốt lõi"
        D --> I[setup_nested_partitioning]
        E --> I
        F --> I
        G --> I
        H --> I
        H --> J[setup_region_partitioning]
        D --> K[setup_province_partitioning]
        E --> K
    end

    subgraph "Vận hành"
        I --> L[Thêm dữ liệu vào các phân vùng]
        J --> L
        K --> L
        L --> M[move_data_between_partitions]
        L --> N[determine_partition_for_citizen]
        L --> O[archive_old_partitions]
        L --> P[create_partition_indexes]
    end

    subgraph "Giám sát"
        M --> Q[generate_partition_report]
        N --> Q
        O --> Q
        P --> Q
        Q --> R[Báo cáo & phân tích]
    end

    C --> M
    C --> O

graph TD
    subgraph "1. Khởi tạo ban đầu"
        A1[Chạy script khởi tạo CSDL] --> A2[Tạo các schema chính]
        A2 --> A3[Tạo các bảng tham chiếu]
        A3 --> A4[Tạo schemas partitioning]
        A4 --> A5[Tạo bảng partitioning.config]
        A4 --> A6[Tạo bảng partitioning.history]
        A5 --> A7[Tạo các hàm phân vùng]
        A6 --> A7
    end
    
    subgraph "2. Thiết lập phân vùng ban đầu"
        B1[Chạy script thiết lập phân vùng] --> B2[Thiết lập phân vùng cho Bộ Công an]
        B1 --> B3[Thiết lập phân vùng cho Bộ Tư pháp]
        B1 --> B4[Thiết lập phân vùng cho Máy chủ trung tâm]
        
        B2 --> B2a[setup_citizen_tables_partitioning]
        B2 --> B2b[setup_residence_tables_partitioning]
        
        B3 --> B3a[setup_civil_status_tables_partitioning]
        B3 --> B3b[setup_household_tables_partitioning]
        
        B4 --> B4a[setup_integrated_data_partitioning]
    end
    
    subgraph "3. Thêm dữ liệu vào hệ thống"
        C1[Xác định dữ liệu cần thêm] --> C2[Xác định phân vùng đích]
        C2 --> C2a[determine_partition_for_citizen]
        C2a --> C3[Chèn dữ liệu vào phân vùng đúng]
        C3 --> C4[Tạo chỉ mục nếu cần]
        C4 --> C4a[create_partition_indexes]
    end
    
    subgraph "4. Vận hành và bảo trì"
        D1[Giám sát hiệu suất phân vùng] --> D2[Tạo báo cáo định kỳ]
        D2 --> D2a[generate_partition_report]
        D1 --> D3[Cập nhật thông tin công dân]
        D3 --> D3a[move_data_between_partitions]
        D1 --> D4[Lưu trữ dữ liệu cũ]
        D4 --> D4a[archive_old_partitions]
    end
    
    A7 --> B1
    B2a --> C1
    B3a --> C1
    B4a --> C1
    C4 --> D1
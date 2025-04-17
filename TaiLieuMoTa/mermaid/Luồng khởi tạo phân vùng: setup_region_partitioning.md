sequenceDiagram
    participant A as Ứng dụng/Admin
    participant F as setup_region_partitioning
    participant DB as Database
    participant H as partitioning.history
    participant C as partitioning.config
    
    A->>F: Gọi với p_schema, p_table, p_column
    F->>H: Ghi log bắt đầu phân vùng
    F->>DB: Tạo bảng tạm với cấu trúc phân vùng
    
    loop Cho từng miền (Bắc, Trung, Nam)
        F->>DB: Tạo phân vùng con
        F->>H: Ghi log tạo phân vùng
    end
    
    F->>DB: Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng
    F->>DB: Đổi tên bảng cũ + bảng mới
    F->>C: Ghi nhận cấu hình phân vùng
    F->>H: Ghi log hoàn thành
    F->>A: Trả về kết quả (TRUE)
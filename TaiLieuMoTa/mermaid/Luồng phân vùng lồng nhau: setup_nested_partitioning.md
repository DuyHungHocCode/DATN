sequenceDiagram
    participant A as Ứng dụng/Admin
    participant F as setup_nested_partitioning
    participant DB as Database
    participant R as reference.regions
    participant P as reference.provinces
    participant D as reference.districts
    participant H as partitioning.history
    participant C as partitioning.config
    
    A->>F: Gọi với p_schema, p_table, p_table_ddl, p_region_column, p_province_column, p_district_column, p_include_district
    F->>H: Ghi log bắt đầu phân vùng
    F->>DB: Tạo bảng tạm với cấu trúc phân vùng theo miền
    
    F->>R: Lấy danh sách miền (Bắc, Trung, Nam)
    loop Cho từng miền
        F->>DB: Tạo phân vùng cấp 1 cho miền
        F->>H: Ghi log tạo phân vùng cấp 1
        
        F->>P: Lấy danh sách tỉnh trong miền
        loop Cho từng tỉnh
            alt Bao gồm quận/huyện
                F->>DB: Tạo phân vùng cấp 2 cho tỉnh với PARTITION BY LIST (district_id)
                F->>H: Ghi log tạo phân vùng cấp 2
                
                F->>D: Lấy danh sách quận/huyện trong tỉnh
                loop Cho từng quận/huyện
                    F->>DB: Tạo phân vùng cấp 3 cho quận/huyện
                    F->>H: Ghi log tạo phân vùng cấp 3
                end
            else Không bao gồm quận/huyện
                F->>DB: Tạo phân vùng cấp 2 cho tỉnh (phân vùng cuối)
                F->>H: Ghi log tạo phân vùng cuối cùng
            end
        end
    end
    
    F->>DB: Di chuyển dữ liệu từ bảng cũ sang bảng phân vùng
    F->>DB: Đổi tên bảng cũ + bảng mới
    F->>C: Ghi nhận cấu hình phân vùng
    F->>H: Ghi log hoàn thành
    F->>A: Trả về kết quả (TRUE)
    
    Note over F: Xử lý ngoại lệ với block TRY-CATCH
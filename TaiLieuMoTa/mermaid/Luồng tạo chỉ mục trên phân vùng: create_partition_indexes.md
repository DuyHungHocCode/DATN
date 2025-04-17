sequenceDiagram
    participant A as Ứng dụng/Admin
    participant F as create_partition_indexes
    participant DB as Database
    participant PG as pg_inherits, pg_class, pg_namespace
    participant PGI as pg_indexes
    participant H as partitioning.history
    
    A->>F: Gọi với p_schema, p_table, p_index_columns[]
    
    F->>PG: Tìm tất cả phân vùng của bảng
    
    loop Cho từng phân vùng
        loop Cho từng cột cần đánh chỉ mục
            F->>F: Tạo tên chỉ mục (idx_[tên phân vùng]_[tên cột])
            F->>PGI: Kiểm tra chỉ mục đã tồn tại chưa
            
            alt Chỉ mục chưa tồn tại
                F->>DB: Tạo chỉ mục mới
                F->>H: Ghi log tạo chỉ mục
            end
        end
    end
    
    F->>A: Hoàn thành (VOID)
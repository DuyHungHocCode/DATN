sequenceDiagram
    participant A as Ứng dụng
    participant F as move_data_between_partitions
    participant DB as Database
    participant T as Bảng tạm thời (temp_partition_move)
    participant H as partitioning.history
    
    A->>F: Gọi với p_schema, p_table, p_citizen_id, p_old_region, p_new_region, p_old_province, p_new_province, [p_old_district], [p_new_district]
    
    F->>DB: Tạo bảng tạm để lưu dữ liệu
    F->>DB: SELECT dữ liệu công dân vào bảng tạm
    F->>F: Kiểm tra có dữ liệu không (count > 0)
    
    alt Không có dữ liệu
        F->>DB: DROP bảng tạm
        F->>A: Trả về FALSE
    else Có dữ liệu
        F->>T: Cập nhật thông tin địa lý trên dữ liệu tạm
        Note over F,T: Cập nhật geographical_region, province_id, region_id, district_id
        
        F->>DB: Xóa dữ liệu cũ của công dân
        F->>DB: Chèn dữ liệu đã cập nhật từ bảng tạm
        F->>DB: DROP bảng tạm
        
        F->>H: Ghi log di chuyển dữ liệu
        F->>A: Trả về TRUE
    end
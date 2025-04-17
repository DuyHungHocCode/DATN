sequenceDiagram
    participant A as Ứng dụng/Admin
    participant F as archive_old_partitions
    participant DB as Database
    participant H as partitioning.history
    
    A->>F: Gọi với p_schema, p_table, p_months (mặc định = 60)
    
    F->>F: Tính ngày cắt giới (v_archive_date = current_date - p_months * 1 month)
    F->>H: Ghi log bắt đầu quá trình lưu trữ
    
    F->>DB: Tìm phân vùng thời gian cũ hơn v_archive_date
    loop Cho từng phân vùng cần lưu trữ
        F->>DB: Đếm số bản ghi trong phân vùng
        F->>H: Ghi log phân vùng cần lưu trữ
        
        F->>DB: Tạo bảng lưu trữ cho phân vùng
        F->>DB: Sao chép dữ liệu vào bảng lưu trữ
        F->>DB: Tách phân vùng khỏi bảng chính (DETACH PARTITION)
        
        F->>H: Ghi log hoàn thành lưu trữ phân vùng
    end
    
    F->>H: Ghi log kết thúc quá trình lưu trữ
    F->>A: Hoàn thành (VOID)
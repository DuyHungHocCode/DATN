sequenceDiagram
    participant A as Ứng dụng/Admin
    participant F as generate_partition_report
    participant DB as Database
    participant PG as pg_inherits, pg_class, pg_namespace
    participant PS as pg_stat_all_tables
    participant PV as reference.provinces
    participant DI as reference.districts
    
    A->>F: Gọi hàm không tham số
    
    F->>PG: Truy vấn thông tin cấu trúc phân vùng
    F->>PS: Kết hợp với thống kê bảng
    F->>F: Tính toán số lượng bản ghi và kích thước 
    F->>F: Trích xuất mã vùng từ tên phân vùng
    
    F->>PV: Kết hợp với thông tin tỉnh/thành
    F->>DI: Kết hợp với thông tin quận/huyện
    
    F->>A: Trả về báo cáo đầy đủ (dạng bảng)
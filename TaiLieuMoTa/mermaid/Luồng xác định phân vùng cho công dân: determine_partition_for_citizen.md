sequenceDiagram
    participant A as Ứng dụng
    participant F as determine_partition_for_citizen
    participant PR as public_security.permanent_residence
    participant TR as public_security.temporary_residence
    participant AD as public_security.address
    participant PV as reference.provinces
    
    A->>F: Gọi với p_citizen_id
    
    F->>PR: Tìm địa chỉ thường trú của công dân
    
    alt Có địa chỉ thường trú
        PR->>F: Trả về address_id
    else Không có địa chỉ thường trú
        F->>TR: Tìm địa chỉ tạm trú của công dân
        TR->>F: Trả về address_id hoặc NULL
    end
    
    alt Có địa chỉ
        F->>AD: Lấy thông tin province_id, district_id từ địa chỉ
        F->>PV: Lấy thông tin region_id từ tỉnh/thành phố
        
        F->>F: Chuyển đổi region_id sang tên miền (Bắc, Trung, Nam)
        F->>A: Trả về thông tin phân vùng (miền, tỉnh, quận/huyện)
    else Không có địa chỉ
        F->>A: Trả về giá trị mặc định (Bắc, 1, 101)
    end
graph TD
    A[setup_citizen_tables_partitioning] -->|Trích xuất định nghĩa| B[pg_get_tabledef]
    B -->|citizen| C[setup_nested_partitioning]
    B -->|identification_card| C
    B -->|biometric_data| C
    B -->|address| C
    B -->|citizen_status| C
    B -->|criminal_record| C
    
    D[setup_residence_tables_partitioning] -->|Trích xuất định nghĩa| B
    B -->|permanent_residence| C
    B -->|temporary_residence| C
    B -->|temporary_absence| C
    
    E[setup_civil_status_tables_partitioning] -->|Trích xuất định nghĩa| B
    B -->|birth_certificate| C
    B -->|death_certificate| C
    B -->|marriage| C
    B -->|divorce| C
    
    F[setup_household_tables_partitioning] -->|Trích xuất định nghĩa| B
    B -->|household| C
    B -->|household_member| C
    B -->|family_relationship| C
    B -->|population_change| C
    
    G[setup_integrated_data_partitioning] -->|Trích xuất định nghĩa| B
    B -->|integrated_citizen| C
    B -->|integrated_household| C
    B -->|sync_status| H[setup_region_partitioning]
    B -->|analytics_tables| H
    
    C --> I[Bảng đã phân vùng]
    H --> I
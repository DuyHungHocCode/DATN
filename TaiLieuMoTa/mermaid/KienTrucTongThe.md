graph TD
  %% Define subgraphs
  subgraph Clients
    Client["Giao diện Người dùng / Hệ thống Ngoài"]
  end

  subgraph Gateway
    APIGateway["API Gateway"]
  end

  subgraph AppServices["Application Microservices (FastAPI)"]
    ServiceBCA["CitizenService (BCA)"]
    ServiceBTP["CivilStatusService (BTP)"]
    ServiceTT["IntegrationService (TT - Tùy chọn)"]
  end

  subgraph SyncLayer["Data Synchronization (TT)"]
    SyncLogic["Sync Logic (PL/pgSQL / pg_cron)"]
  end

  subgraph Databases["Databases (PostgreSQL)"]
    DB_BCA["ministry_of_public_security"]
    DB_BTP["ministry_of_justice"]
    DB_TT["national_citizen_central_server"]
  end

  %% Client → API Gateway
  Client --> APIGateway

  %% API Gateway → Services
  APIGateway --> ServiceBCA
  APIGateway --> ServiceBTP
  APIGateway --> ServiceTT

  %% Services → Their Databases
  ServiceBCA --> DB_BCA
  ServiceBTP --> DB_BTP
  ServiceTT --> DB_TT

  %% Inter‑service communication (REST calls)
  ServiceBTP -- "1 Xác thực Citizen ID" --> ServiceBCA
  ServiceBTP -- "2 Thông báo sự kiện Hộ tịch (vd: Khai tử)" --> ServiceBCA

  %% Data synchronization via FDW and pg_cron
  SyncLogic -- "Đọc dữ liệu qua FDW" --> DB_BCA
  SyncLogic -- "Đọc dữ liệu qua FDW" --> DB_BTP
  SyncLogic -- "Ghi dữ liệu tích hợp" --> DB_TT

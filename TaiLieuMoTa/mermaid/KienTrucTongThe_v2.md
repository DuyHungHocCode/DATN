graph TD
  subgraph "Clients"
    Client["Người dùng / Hệ thống Ngoài"]
  end

  subgraph "Gateway"
    APIGateway["API Gateway"]
  end

  subgraph "Application Microservices (FastAPI)"
    ServiceBCA["CitizenService (BCA) + Kafka Consumer"]
    ServiceBTP["CivilStatusService (BTP) + Kafka Producer"]
    ServiceTT["IntegrationService (TT - Tùy chọn)"]
  end

  subgraph "Message Broker"
    Kafka["Kafka Cluster / Broker"]
    KafkaTopic["BTP Events Topic"]
  end

  subgraph "Data Synchronization (TT)"
    SyncLogic["Sync Logic (PL/pgSQL / pg_cron)"]
  end

  subgraph "Databases (PostgreSQL)"
    DB_BCA["ministry_of_public_security"]
    DB_BTP["ministry_of_justice"]
    DB_TT["national_citizen_central_server"]
  end

  %% Luồng Client
  Client --> APIGateway

  %% Luồng Gateway -> Services
  APIGateway --> ServiceBCA
  APIGateway --> ServiceBTP
  APIGateway --> ServiceTT

  %% Luồng Services -> Databases
  ServiceBCA --> DB_BCA
  ServiceBTP --> DB_BTP
  ServiceTT --> DB_TT

  %% Luồng Giao tiếp giữa Services
  ServiceBTP --|1. Gọi REST API Xác thực Citizen ID (Đồng bộ)|--> ServiceBCA
  ServiceBTP --|2. Publish Event Message (Bất đồng bộ)|--> KafkaTopic
  KafkaTopic --|3. Consume Event Message (Bất đồng bộ)|--> ServiceBCA

  %% Luồng Đồng bộ dữ liệu Trung tâm (Vẫn dùng FDW)
  SyncLogic --|Đọc dữ liệu qua FDW|--> DB_BCA
  SyncLogic --|Đọc dữ liệu qua FDW|--> DB_BTP
  SyncLogic --|Ghi dữ liệu tích hợp|--> DB_TT

  %% Liên kết Kafka Topic với Broker
  Kafka --- KafkaTopic

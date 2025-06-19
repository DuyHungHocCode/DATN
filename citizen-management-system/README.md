# Citizen Management System

A comprehensive microservices-based citizen management system designed for Vietnamese government agencies, implementing modern distributed architecture with event-driven communication.

##Architecture Overview

This system consists of two main microservices that manage citizen information and civil status records with real-time data synchronization:

- **Citizen Service (BCA)** - Manages citizen personal information, identification cards, residence history, and household registration
- **Civil Status Service (BTP)** - Manages civil status records including birth certificates, death certificates, marriage certificates, and divorce records

The system uses **Event-Driven Architecture** with **Kafka** and **Debezium CDC** for real-time data synchronization between services.

##System Components

### Core Services

#### 1. Citizen Service (BCA - Bộ Công an)
- **Port**: 8000
- **Database**: SQL Server (DB_BCA) on port 1401
- **Responsibilities**:
  - Citizen identity management (CCCD/CMND)
  - Residence registration and history tracking
  - Household management (Sổ Hộ Khẩu)
  - Family relationship management
  - Address and contact information
  - Temporary absence tracking

#### 2. Civil Status Service (BTP - Bộ Tư pháp)
- **Port**: 8001
- **Database**: SQL Server (DB_BTP) on port 1402
- **Responsibilities**:
  - Birth certificate registration
  - Death certificate registration
  - Marriage certificate registration
  - Divorce record management
  - Civil status validation and cross-referencing

### Infrastructure Components

#### Message Streaming
- **Apache Kafka** - Event streaming platform
- **Zookeeper** - Kafka cluster coordination
- **Kafka UI** - Web-based Kafka management (port 8080)
- **Debezium CDC** - Change Data Capture for real-time data synchronization

#### Data Storage
- **SQL Server 2019** - Primary database for both services
- **Redis** - Caching layer for reference data and performance optimization

##Technology Stack

### Backend Services
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - ORM and database toolkit
- **Pydantic** - Data validation and serialization
- **Uvicorn** - ASGI server

### Data & Messaging
- **Microsoft SQL Server 2019** - Primary database
- **Apache Kafka** - Event streaming
- **Debezium** - Change Data Capture
- **Redis** - Caching and session storage

### Infrastructure
- **Docker & Docker Compose** - Containerization and orchestration
- **Kafka Connect** - Data integration platform

##Database Schema

### BCA Database (DB_BCA)
Key entities managed by the Citizen Service:

- **Reference Schema**: Geographic and lookup data
  - Regions, Provinces, Districts, Wards
  - Authorities, Genders, Ethnicities, Nationalities
  - Document types, Education levels, Occupations

- **BCA Schema**: Core citizen data
  - `Citizen` - Primary citizen information
  - `Address` - Address management
  - `IdentificationCard` - ID card records
  - `ResidenceHistory` - Residence tracking
  - `CitizenMovement` - Movement records
  - `TemporaryAbsence` - Temporary absence tracking

### BTP Database (DB_BTP)
Key entities managed by the Civil Status Service:

- `BirthCertificate` - Birth registration records
- `DeathCertificate` - Death registration records
- `MarriageCertificate` - Marriage registration records
- `DivorceRecord` - Divorce records linked to marriage certificates

##API Endpoints

### Citizen Service (BCA) APIs

#### Citizen Management
```
GET    /api/v1/citizens/{citizen_id}              # Get citizen details
GET    /api/v1/citizens/{citizen_id}/validation   # Validate citizen for inter-service calls
GET    /api/v1/citizens/                          # Search citizens
POST   /api/v1/citizens/batch-validate           # Batch validate multiple citizens
```

#### Residence & Contact
```
GET    /api/v1/citizens/{citizen_id}/residence-history  # Get residence history
GET    /api/v1/citizens/{citizen_id}/contact-info       # Get contact information
POST   /api/v1/residence-registrations/owned-property   # Register permanent residence
```

#### Family & Household
```
GET    /api/v1/citizens/{citizen_id}/family-tree        # Get family tree (3 generations)
GET    /api/v1/households/{household_id}                # Get household details
POST   /api/v1/households/add-member                    # Add member to household
POST   /api/v1/households/transfer-member               # Transfer household member
DELETE /api/v1/households/{household_id}/members/{citizen_id}  # Remove household member
```

#### Reference Data
```
GET    /api/v1/reference/{table_name}           # Get reference data (provinces, districts, etc.)
```

### Civil Status Service (BTP) APIs

#### Civil Status Records
```
POST   /api/v1/birth-certificates               # Register birth certificate
GET    /api/v1/birth-certificates/{id}          # Get birth certificate details
POST   /api/v1/death-certificates               # Register death certificate
GET    /api/v1/death-certificates/{id}          # Get death certificate details
POST   /api/v1/marriage-certificates            # Register marriage certificate
POST   /api/v1/divorce-records                  # Register divorce record
```

##Event-Driven Architecture

The system implements **Event Sourcing** and **CQRS** patterns using Kafka and Debezium:

### Data Flow
1. **Civil Status Changes** → BTP Service writes to EventOutbox table
2. **Debezium CDC** captures changes from EventOutbox tables
3. **Kafka Topics** distribute events (`bca_events`, `btp_events`)
4. **BCA Service** consumes events and updates citizen status accordingly

### Event Types
- `citizen_died` - Death certificate registered
- `citizen_married` - Marriage certificate registered  
- `citizen_divorced` - Divorce record registered
- `citizen_born` - Birth certificate registered

##Installation & Setup

### Prerequisites
- Docker & Docker Compose
- Python 3.11+
- Git

### Quick Start

1. **Clone the repository**
```bash
git clone <repository-url>
cd citizen-management-system
```

2. **Start the infrastructure**
```bash
docker-compose up -d
```

This command will start:
- Zookeeper (port 2181)
- Kafka (port 29092)
- Kafka UI (port 8080)
- SQL Server BCA (port 1401)
- SQL Server BTP (port 1402)
- Kafka Connect with Debezium (port 8083)

3. **Set up databases**
The SQL Server containers will automatically create the databases. You'll need to run the migration scripts to create tables and constraints:

```bash
# Apply database migrations (tables and constraints)
# Connect to SQL Server instances and run the SQL scripts in the database/ folders
```

4. **Configure Debezium Connectors**
```bash
# Register BCA CDC connector
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @infrastructure/debezium/debezium-connector-bca-cdc.json

# Register BTP CDC connector  
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @infrastructure/debezium/debezium-connector-btp-cdc.json
```

5. **Start the services**
```bash
# Start Citizen Service (BCA)
cd service/citizen_service_bca
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Start Civil Status Service (BTP)
cd service/civil_status_service_btp  
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8001
```

### Environment Variables

Create `.env` files in each service directory:

**Citizen Service (.env)**
```env
DB_SERVER=localhost
DB_PORT=1401
DB_NAME=DB_BCA
DB_USER=sa
DB_PASSWORD=StrongPassword123!
KAFKA_BOOTSTRAP_SERVERS=localhost:29092
REDIS_HOST=localhost
REDIS_PORT=6379
```

**Civil Status Service (.env)**
```env
DB_SERVER_BTP=localhost
DB_PORT_BTP=1402
DB_NAME_BTP=DB_BTP
DB_USER_BTP=sa
DB_PASSWORD_BTP=StrongPassword123!
KAFKA_BOOTSTRAP_SERVERS=localhost:29092
BCA_SERVICE_BASE_URL=http://localhost:8000
```

##Usage Examples

### Register a Death Certificate
```bash
curl -X POST "http://localhost:8001/api/v1/death-certificates" \
  -H "Content-Type: application/json" \
  -d '{
    "citizen_id": "123456789012",
    "death_certificate_no": "DC-2024-001",
    "date_of_death": "2024-01-15",
    "time_of_death": "14:30:00",
    "place_of_death_detail": "Bệnh viện Bạch Mai",
    "cause_of_death": "Bệnh tim",
    "registration_date": "2024-01-16"
  }'
```

### Search Citizens
```bash
curl "http://localhost:8000/api/v1/citizens/?full_name=Nguyen Van A&limit=10"
```

### Get Family Tree
```bash
curl "http://localhost:8000/api/v1/citizens/123456789012/family-tree"
```

##Key Features

### Data Validation & Cross-Service Integration
- **Real-time validation** between BCA and BTP services
- **Automatic status updates** when civil status changes
- **Data consistency** across distributed services

### Advanced Search & Filtering
- **Full-text search** on citizen names
- **Geographic filtering** by administrative divisions
- **Family relationship** queries and traversal

### Event-Driven Updates
- **Immediate propagation** of status changes
- **Reliable delivery** with Kafka's persistence
- **Event replay** capability for system recovery

### Performance Optimization
- **Redis caching** for reference data
- **Database connection pooling**
- **Batch operations** for bulk processing

##Monitoring & Management

### Service Health Checks
- `GET /health` - Comprehensive health status for each service
- Database connectivity monitoring
- Kafka consumer status tracking
- Redis cache availability

### Kafka Management
- **Kafka UI**: http://localhost:8080
- Monitor topics, consumers, and message flow
- Debug CDC events and processing status

### Database Management
- **SQL Server Management Studio** or similar tools
- Connection strings provided in service configurations
- Separate databases for each service domain


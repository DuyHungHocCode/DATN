# civil_status_service_btp/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from sqlalchemy import text
import httpx  # Import httpx for making HTTP requests
import uvicorn # Thêm import uvicorn
from datetime import datetime, timezone
from contextlib import asynccontextmanager
from app.api.router import router as civil_status_router
from app.config import get_settings
#from app.services.kafka_producer import kafka_producer_instance # Import instance để đóng khi shutdown
from app.db.database import SessionLocal
from logging.handlers import RotatingFileHandler
import os
#from app.services.outbox_processor import outbox_processor
#from app.services.event_retry_worker import event_retry_worker
from app.services.reconciliation import reconciliation_service

settings = get_settings()

# Tạo thư mục logs nếu chưa tồn tại
log_dir = "logs"
os.makedirs(log_dir, exist_ok=True)

# Tạo file log với tên bao gồm ngày tháng
log_file = os.path.join(log_dir, f"btp_service_{datetime.now().strftime('%Y%m%d')}.txt")


# Cấu hình logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        # Handler ghi ra console
        logging.StreamHandler(),
        # Handler ghi ra file, tối đa 10MB, backup 5 file
        RotatingFileHandler(log_file, maxBytes=10*1024*1024, backupCount=5)
    ]
)


logger = logging.getLogger(__name__)
logger.info("BTP Civil Status Service starting, logs will be saved to: %s", log_file)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup code
    logger.info("Civil Status Service starting up...")
    # Start Kafka connections and retry worker
    #await outbox_processor.start()
    #await event_retry_worker.start()
    await reconciliation_service.start()
    
    yield  # App runs here
    
    # Shutdown code
    logger.info("Civil Status Service shutting down...")
    await reconciliation_service.stop()
    #await outbox_processor.stop()
    #await event_retry_worker.stop()
    #kafka_producer_instance.close()

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="API quản lý Hộ tịch (Bộ Tư pháp)",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS middleware (cấu hình tương tự BCA service)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Nên giới hạn trong production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include router
app.include_router(civil_status_router, prefix=settings.API_V1_STR, tags=["Civil Status"])


@app.get("/")
async def root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "docs": "/docs",
        "version": "0.1.0"
    }

@app.get("/health", tags=["Health"])
async def health_check():
    """Kiểm tra sức khỏe của service và các thành phần phụ thuộc."""
    health_data = {
        "status": "OK",
        "service": "BTP Civil Status Service",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": "0.1.0",
        "components": {}
    }
    
    # Kiểm tra kết nối database
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1")).fetchall()
        db.close()
        health_data["components"]["database"] = {"status": "UP"}
    except Exception as e:
        health_data["components"]["database"] = {"status": "DOWN", "error": str(e)}
        health_data["status"] = "Degraded"
    
    # Note: Kafka producer has been removed as events are now handled by Debezium
    health_data["components"]["event_streaming"] = {
        "status": "UP", 
        "method": "Debezium CDC"
    }
    
    # Kiểm tra BCA service (dependency)
    try:
        async with httpx.AsyncClient(timeout=2.0) as client:
            response = await client.get(f"{settings.BCA_SERVICE_BASE_URL}/health")
            if response.status_code == 200:
                health_data["components"]["bca_service"] = {"status": "UP"}
            else:
                health_data["components"]["bca_service"] = {
                    "status": "DEGRADED", 
                    "status_code": response.status_code
                }
                health_data["status"] = "Degraded"
    except Exception as e:
        health_data["components"]["bca_service"] = {"status": "DOWN", "error": str(e)}
        health_data["status"] = "Degraded"
    
    return health_data

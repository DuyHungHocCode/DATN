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
from app.services.kafka_producer import kafka_producer_instance # Import instance để đóng khi shutdown
from app.db.database import SessionLocal

settings = get_settings()

# Cấu hình logging cơ bản
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup code
    logger.info("Civil Status Service starting up...")
    # Kiểm tra kết nối DB & Kafka
    try:
        # Kiểm tra Kafka connection (optional)
        logger.info("Testing Kafka connection...")
        if kafka_producer_instance.producer is None:
            logger.warning("Kafka producer not available - events will not be sent")
    except Exception as e:
        logger.error(f"Error during startup: {e}")
    
    yield  # App runs here
    
    # Shutdown code
    logger.info("Civil Status Service shutting down...")
    kafka_producer_instance.close()

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

# @app.on_event("startup")
# async def startup_event():
#     logger.info("Civil Status Service starting up...")
#     # Có thể thêm kiểm tra kết nối DB, Kafka ở đây nếu cần
#     # kafka_producer_instance # Khởi tạo producer khi startup (nếu chưa làm trong class)
#     pass

# @app.on_event("shutdown")
# def shutdown_event():
#     logger.info("Civil Status Service shutting down...")
#     kafka_producer_instance.close() # Đóng kết nối Kafka producer

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
    
    # Kiểm tra Kafka
    if kafka_producer_instance.producer:
        try:
            # Kiểm tra cluster metadata (không gửi message thực)
            metadata = kafka_producer_instance.producer._client.cluster.metadata()
            if metadata and metadata.brokers():
                health_data["components"]["kafka"] = {
                    "status": "UP", 
                    "brokers": len(metadata.brokers())
                }
            else:
                health_data["components"]["kafka"] = {"status": "DEGRADED", "error": "No brokers available"}
                health_data["status"] = "Degraded"
        except Exception as e:
            health_data["components"]["kafka"] = {"status": "DEGRADED", "error": str(e)}
            health_data["status"] = "Degraded"
    else:
        health_data["components"]["kafka"] = {"status": "DOWN"}
        health_data["status"] = "Degraded"
    
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
# Thêm đoạn này để có thể chạy trực tiếp file main.py (cho development)
# if __name__ == "__main__":
#     uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True) # Port 8001 ví dụ
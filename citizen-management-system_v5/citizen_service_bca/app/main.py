from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from contextlib import asynccontextmanager
from app.api.router import router
from app.config import get_settings
from app.services.kafka_consumer import kafka_consumer_instance  # Thêm dòng này
from sqlalchemy import text
from datetime import datetime, timezone
from app.db.database import SessionLocal

settings = get_settings()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup code - runs before application startup
    logger.info("Citizen Service starting up...")
    # Khởi động Kafka consumer
    await kafka_consumer_instance.start()
    
    yield  # Application runs here
    
    # Shutdown code - runs when application is shutting down
    logger.info("Citizen Service shutting down...")
    # Dừng Kafka consumer
    await kafka_consumer_instance.stop()

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="API để tìm kiếm và truy vấn thông tin công dân",
    version="0.1.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Trong môi trường sản xuất nên giới hạn
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include router
app.include_router(router, prefix=settings.API_V1_STR)


@app.get("/")
async def root():
    return {
        "message": "Welcome to Citizen Information API",
        "docs": f"/docs",
        "version": "0.1.0"
    }

@app.get("/health", tags=["Health"])
async def health_check():
    """Kiểm tra sức khỏe của service và các thành phần phụ thuộc."""
    health_data = {
        "status": "OK",
        "service": "BCA Citizen Service",
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
    
    # Kiểm tra Kafka Consumer (nếu đã triển khai)
    if hasattr(kafka_consumer_instance, 'is_running') and kafka_consumer_instance.is_running:
        health_data["components"]["kafka_consumer"] = {"status": "UP"}
    else:
        health_data["components"]["kafka_consumer"] = {"status": "DOWN"}
        health_data["status"] = "Degraded"
    
    return health_data
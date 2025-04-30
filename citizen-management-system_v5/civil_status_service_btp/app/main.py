# civil_status_service_btp/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import uvicorn # Thêm import uvicorn

from app.api.router import router as civil_status_router
from app.config import get_settings
from app.services.kafka_producer import kafka_producer_instance # Import instance để đóng khi shutdown

settings = get_settings()

# Cấu hình logging cơ bản
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="API quản lý Hộ tịch (Bộ Tư pháp)",
    version="0.1.0",
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

@app.on_event("startup")
async def startup_event():
    logger.info("Civil Status Service starting up...")
    # Có thể thêm kiểm tra kết nối DB, Kafka ở đây nếu cần
    # kafka_producer_instance # Khởi tạo producer khi startup (nếu chưa làm trong class)
    pass

@app.on_event("shutdown")
def shutdown_event():
    logger.info("Civil Status Service shutting down...")
    kafka_producer_instance.close() # Đóng kết nối Kafka producer

@app.get("/")
async def root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "docs": "/docs",
        "version": "0.1.0"
    }

# Thêm đoạn này để có thể chạy trực tiếp file main.py (cho development)
# if __name__ == "__main__":
#     uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True) # Port 8001 ví dụ
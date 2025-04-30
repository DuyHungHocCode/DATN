# civil_status_service_btp/app/config.py
from pydantic_settings import BaseSettings
from functools import lru_cache
import os
from dotenv import load_dotenv

# load_dotenv(dotenv_path="../.env") # Tải biến môi trường từ file .env ở thư mục gốc dự án (nếu có)
load_dotenv() # Tải biến môi trường từ file .env trong thư mục hiện tại

class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Civil Status Service (BTP)"

    # Database settings (DB_BTP)
    DB_SERVER_BTP: str = os.getenv("DB_SERVER_BTP", "localhost")
    DB_PORT_BTP: str = os.getenv("DB_PORT_BTP", "1433")
    DB_NAME_BTP: str = os.getenv("DB_NAME_BTP", "DB_BTP")
    DB_USER_BTP: str = os.getenv("DB_USER_BTP", "sa")
    DB_PASSWORD_BTP: str = os.getenv("DB_PASSWORD_BTP", "")
    DB_DRIVER_BTP: str = os.getenv("DB_DRIVER_BTP", "ODBC Driver 17 for SQL Server") # Hoặc driver khác bạn dùng

    # Kafka settings
    KAFKA_BOOTSTRAP_SERVERS: str = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
    KAFKA_TOPIC_BTP_EVENTS: str = os.getenv("KAFKA_TOPIC_BTP_EVENTS", "btp_events")

    # Citizen Service (BCA) URL (Internal)
    BCA_SERVICE_BASE_URL: str = os.getenv("BCA_SERVICE_BASE_URL", "http://localhost:8000") # Địa chỉ của CitizenService BCA

    class Config:
        # Chỉ định file .env nếu cần (ưu tiên biến môi trường hệ thống)
        env_file = '.env'
        env_file_encoding = 'utf-8'

@lru_cache()
def get_settings():
    return Settings()
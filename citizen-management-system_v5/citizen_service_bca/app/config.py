from pydantic_settings import BaseSettings
from functools import lru_cache
import os
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Citizen Information API"
    
    # Database settings
    DB_SERVER: str = os.getenv("DB_SERVER", "localhost")
    DB_PORT: str = os.getenv("DB_PORT", "1433")
    DB_NAME: str = os.getenv("DB_NAME", "DB_BCA")
    DB_USER: str = os.getenv("DB_USER", "sa")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")

    KAFKA_BOOTSTRAP_SERVERS: str = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:29092")
    KAFKA_TOPIC_BTP_EVENTS: str = os.getenv("KAFKA_TOPIC_BTP_EVENTS", "btp_events")
    KAFKA_GROUP_ID: str = os.getenv("KAFKA_GROUP_ID", "bca_consumer_group")
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
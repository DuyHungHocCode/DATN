import redis
import json
from typing import Optional, List, Dict, Any
from app.config import get_settings
import datetime # <<<< THÊM IMPORT NÀY

settings = get_settings()

class RedisClient:
    def __init__(self):
        try:
            self.client = redis.Redis(
                host=settings.REDIS_HOST,
                port=settings.REDIS_PORT,
                db=settings.REDIS_DB,
                decode_responses=False
            )
            self.client.ping()
            print(f"Successfully connected to Redis at {settings.REDIS_HOST}:{settings.REDIS_PORT}")
        except redis.exceptions.ConnectionError as e:
            print(f"Error connecting to Redis: {e}")
            self.client = None

    def get_reference_table(self, table_name: str) -> Optional[List[Dict[str, Any]]]:
        if not self.client:
            return None
        try:
            key = f"ref:{table_name}"
            cached_data_bytes = self.client.get(key)
            if cached_data_bytes:
                cached_data_str = cached_data_bytes.decode('utf-8')
                return json.loads(cached_data_str)
            return None
        except Exception as e:
            print(f"Error getting data from Redis for table {table_name}: {e}")
            return None

    def set_reference_table(self, table_name: str, data: List[Dict[str, Any]], ttl: Optional[int] = None):
        if not self.client:
            print(f"Redis client not available. Cannot set data for table {table_name}.")
            return
        try:
            key = f"ref:{table_name}"

            # Custom default handler cho json.dumps để xử lý datetime
            def datetime_converter(o):
                if isinstance(o, (datetime.datetime, datetime.date, datetime.time)):
                    return o.isoformat() # Chuyển đổi datetime/date/time thành chuỗi ISO 8601
                raise TypeError(f"Object of type {o.__class__.__name__} is not JSON serializable")

            json_data = json.dumps(data, default=datetime_converter) # <<<< SỬ DỤNG datetime_converter
            
            self.client.set(key, json_data.encode('utf-8'), ex=ttl or settings.REDIS_REFERENCE_CACHE_TTL)
            print(f"Successfully SET data to Redis for table {table_name} with key {key}") # Thêm log để xác nhận
        except Exception as e:
            # Log này đã có sẵn và sẽ hiển thị lỗi serialization nếu datetime_converter không xử lý hết
            print(f"Error setting data to Redis for table {table_name}: {e}")


    def clear_reference_table(self, table_name: str):
        if not self.client:
            return
        try:
            key = f"ref:{table_name}"
            self.client.delete(key)
            print(f"Cleared cache for reference table: {table_name}")
        except Exception as e:
            print(f"Error clearing cache for table {table_name} in Redis: {e}")

    def clear_all_reference_tables(self, table_names: List[str]):
        if not self.client:
            return
        try:
            keys_to_delete = [f"ref:{name}" for name in table_names]
            if keys_to_delete:
                self.client.delete(*keys_to_delete)
            print(f"Cleared cache for reference tables: {', '.join(table_names)}")
        except Exception as e:
            print(f"Error clearing all reference tables cache in Redis: {e}")


# Singleton instance
redis_client_instance = RedisClient()

def get_redis_client():
    return redis_client_instance
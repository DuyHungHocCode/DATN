# citizen_service_bca/app/services/kafka_consumer.py

import json
import logging
import asyncio
from datetime import datetime, date
from aiokafka import AIOKafkaConsumer
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db.database import SessionLocal
from app.db.citizen_repo import CitizenRepository

settings = get_settings()
logger = logging.getLogger(__name__)

class KafkaEventConsumer:
    def __init__(self):
        self.bootstrap_servers = settings.KAFKA_BOOTSTRAP_SERVERS
        self.topic = settings.KAFKA_TOPIC_BTP_EVENTS
        self.group_id = settings.KAFKA_GROUP_ID
        self.consumer = None
        self.should_stop = False
        self.is_running = False
    
    async def start(self):
        """Khởi động Kafka consumer."""
        if self.is_running:
            return
        
        try:
            logger.info(f"Starting Kafka consumer for topic {self.topic}")
            self.consumer = AIOKafkaConsumer(
                self.topic,
                bootstrap_servers=self.bootstrap_servers,
                group_id=self.group_id,
                value_deserializer=lambda m: json.loads(m.decode('utf-8')),
                auto_offset_reset='earliest'
            )
            
            await self.consumer.start()
            self.is_running = True
            self.should_stop = False
            
            # Tạo task để xử lý messages
            asyncio.create_task(self._consume_messages())
            logger.info("Kafka consumer started successfully")
            
        except Exception as e:
            logger.error(f"Failed to start Kafka consumer: {e}", exc_info=True)
    
    async def stop(self):
        """Dừng Kafka consumer."""
        if not self.is_running:
            return
        
        logger.info("Stopping Kafka consumer...")
        self.should_stop = True
        
        if self.consumer:
            await self.consumer.stop()
            self.is_running = False
            logger.info("Kafka consumer stopped")
    
    async def _consume_messages(self):
        """Lắng nghe và xử lý messages từ Kafka."""
        try:
            async for message in self.consumer:
                if self.should_stop:
                    break
                
                logger.info(f"Received message: {message.value}")
                
                # Xử lý message
                await self._process_message(message.value)
                
        except Exception as e:
            logger.error(f"Error consuming messages: {e}", exc_info=True)
            self.is_running = False
            
            # Thử khởi động lại consumer sau một khoảng thời gian
            await asyncio.sleep(5)
            asyncio.create_task(self.start())
    
    async def _process_message(self, message: Dict[str, Any]):
        """Xử lý message nhận được từ Kafka."""
        try:
            event_type = message.get('eventType')
            payload = message.get('payload', {})
            
            if not event_type or not payload:
                logger.warning(f"Invalid message format: {message}")
                return
            
            logger.info(f"Processing event: {event_type}")
            
            # Xử lý các loại sự kiện
            if event_type == 'citizen_died':
                await self._process_citizen_died_event(payload)
            else:
                logger.info(f"Ignoring unsupported event type: {event_type}")
                
        except Exception as e:
            logger.error(f"Error processing message: {e}", exc_info=True)
    
    async def _process_citizen_died_event(self, payload: Dict[str, Any]):
        """Xử lý sự kiện khi công dân qua đời."""
        try:
            citizen_id = payload.get('citizen_id')
            date_of_death_str = payload.get('date_of_death')
            
            if not citizen_id or not date_of_death_str:
                logger.warning(f"Missing required fields in citizen_died event: {payload}")
                return
            
            # Chuyển đổi chuỗi ngày thành đối tượng date
            try:
                date_of_death = datetime.fromisoformat(date_of_death_str).date()
            except ValueError:
                logger.error(f"Invalid date format: {date_of_death_str}")
                return
            
            # Cập nhật trạng thái công dân trong database
            logger.info(f"Updating death status for citizen {citizen_id}")
            
            # Tạo session database
            db = SessionLocal()
            try:
                repo = CitizenRepository(db)
                updated = repo.update_citizen_death_status(citizen_id, date_of_death)
                
                if updated:
                    logger.info(f"Successfully updated death status for citizen {citizen_id}")
                else:
                    logger.warning(f"Failed to update death status for citizen {citizen_id}. Citizen may not exist or already marked as deceased.")
            finally:
                db.close()
            
        except Exception as e:
            logger.error(f"Error processing citizen_died event: {e}", exc_info=True)

# Tạo instance singleton
kafka_consumer_instance = KafkaEventConsumer()

def get_kafka_consumer():
    """Dependency function để inject KafkaConsumer."""
    return kafka_consumer_instance
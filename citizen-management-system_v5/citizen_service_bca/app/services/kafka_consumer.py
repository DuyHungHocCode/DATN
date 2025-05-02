# citizen_service_bca/app/services/kafka_consumer.py

import json
import logging
import asyncio
import os
from sqlalchemy import text
from datetime import datetime, timezone
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
            logger.info("Kafka consumer already running")
            return
        
        try:
            logger.info(f"Starting Kafka consumer for topic {self.topic} with bootstrap servers: {self.bootstrap_servers}")
            
            # Tách bootstrap_servers nếu có nhiều server
            bootstrap_servers_list = self.bootstrap_servers.split(',')
            logger.info(f"Using bootstrap servers: {bootstrap_servers_list}")
            
            self.consumer = AIOKafkaConsumer(
                self.topic,
                bootstrap_servers=bootstrap_servers_list,
                group_id=self.group_id,
                value_deserializer=lambda m: json.loads(m.decode('utf-8')),
                auto_offset_reset='earliest'
            )
            
            logger.info("Consumer created, attempting to start...")
            await self.consumer.start()
            logger.info("Consumer start() completed successfully")
            
            self.is_running = True
            self.should_stop = False
            
            # Tạo task để xử lý messages
            asyncio.create_task(self._consume_messages())
            logger.info("Kafka consumer started successfully")
            
        except Exception as e:
            logger.error(f"Failed to start Kafka consumer: {e}", exc_info=True)
            # Đảm bảo state được duy trì chính xác nếu khởi động thất bại  
            self.is_running = False
            self.consumer = None
    
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
            elif event_type == 'citizen_married':
                await self._process_citizen_married_event(payload)
            else:
                logger.info(f"Ignoring unsupported event type: {event_type}")
                    
        except Exception as e:
            logger.error(f"Error processing message: {e}", exc_info=True)
        
    async def _process_citizen_died_event(self, payload: Dict[str, Any]):
        """Xử lý sự kiện khi công dân qua đời."""
        try:
            logger.info(f"Processing citizen_died event with payload: {payload}")
            
            citizen_id = payload.get('citizen_id')
            date_of_death_str = payload.get('date_of_death')
            
            if not citizen_id or not date_of_death_str:
                logger.warning(f"Missing required fields in citizen_died event: {payload}")
                return
            
            # Chuyển đổi chuỗi ngày thành đối tượng date
            try:
                # Thử nhiều định dạng khác nhau
                try:
                    # Định dạng ISO 8601
                    date_of_death = datetime.fromisoformat(date_of_death_str).date()
                except ValueError:
                    # Thử định dạng ISO chuẩn (YYYY-MM-DD)
                    if 'T' in date_of_death_str:
                        date_of_death_str = date_of_death_str.split('T')[0]
                    date_of_death = datetime.strptime(date_of_death_str, "%Y-%m-%d").date()
                
                logger.info(f"Parsed date of death: {date_of_death}")
            except Exception as e:
                logger.error(f"Invalid date format: {date_of_death_str}, error: {e}")
                return
            
            # Cập nhật trạng thái công dân trong database - không cần kiểm tra tồn tại
            logger.info(f"Updating death status for citizen {citizen_id}")
            
            # Tạo session database
            db = SessionLocal()
            try:
                repo = CitizenRepository(db)
                updated = repo.update_citizen_death_status(citizen_id, date_of_death)
                
                if updated:
                    logger.info(f"Successfully updated death status for citizen {citizen_id}")
                else:
                    logger.warning(f"Failed to update death status for citizen {citizen_id}")
            finally:
                db.close()
            
        except Exception as e:
            logger.error(f"Error processing citizen_died event: {e}", exc_info=True)

    def _store_failed_event(self, payload, error_msg=None):
        """Lưu event thất bại để xử lý sau."""
        try:
            # Tạo tên file với timestamp
            filename = f"failed_events/{datetime.now().strftime('%Y%m%d')}_failed_events.jsonl"
            os.makedirs("failed_events", exist_ok=True)
            
            # Lưu thông tin sự kiện và lỗi
            failed_event = {
                "payload": payload,
                "error": error_msg,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            # Ghi vào file
            with open(filename, "a") as f:
                f.write(json.dumps(failed_event) + "\n")
                
            logger.info(f"Stored failed event for later processing: {error_msg}")
        except Exception as e:
            logger.error(f"Failed to store failed event: {e}")

    # Thêm phương thức để xử lý lại các sự kiện lỗi (chạy theo lịch)
    async def process_failed_events(self):
        """Xử lý lại các sự kiện bị lỗi."""
        try:
            failed_dir = "failed_events"
            if not os.path.exists(failed_dir):
                return
                
            for filename in os.listdir(failed_dir):
                if not filename.endswith('.jsonl'):
                    continue
                    
                file_path = os.path.join(failed_dir, filename)
                temp_path = file_path + ".processing"
                processed = []
                
                # Đổi tên file để không xử lý nhiều lần
                os.rename(file_path, temp_path)
                
                with open(temp_path, 'r') as f:
                    for line in f:
                        try:
                            event = json.loads(line.strip())
                            # Xử lý sự kiện
                            await self._process_message(event['payload'])
                            processed.append(event)
                        except Exception as e:
                            logger.error(f"Error reprocessing event: {e}")
                            # Vẫn giữ lại sự kiện trong file lỗi
                
                # Xóa các sự kiện đã xử lý thành công
                if processed:
                    remaining_events = []
                    with open(temp_path, 'r') as f:
                        for line in f:
                            event = json.loads(line.strip())
                            if event not in processed:
                                remaining_events.append(event)
                    
                    if remaining_events:
                        with open(file_path, 'w') as f:
                            for event in remaining_events:
                                f.write(json.dumps(event) + "\n")
                        os.remove(temp_path)
                    else:
                        os.remove(temp_path)  # Không còn sự kiện lỗi
                
        except Exception as e:
            logger.error(f"Error in process_failed_events: {e}")

    async def _process_citizen_married_event(self, payload: Dict[str, Any]):
        """Xử lý sự kiện khi công dân kết hôn."""
        try:
            logger.info(f"Processing citizen_married event with payload: {payload}")
            
            husband_id = payload.get('husband_id')
            wife_id = payload.get('wife_id')
            marriage_date_str = payload.get('marriage_date')
            certificate_id = payload.get('marriage_certificate_id')
            
            if not husband_id or not wife_id or not marriage_date_str:
                logger.warning(f"Missing required fields in citizen_married event: {payload}")
                return
            
            # Chuyển đổi chuỗi ngày thành đối tượng date
            try:
                if 'T' in marriage_date_str:
                    marriage_date_str = marriage_date_str.split('T')[0]
                marriage_date = datetime.strptime(marriage_date_str, "%Y-%m-%d").date()
                logger.info(f"Parsed marriage date: {marriage_date}")
            except Exception as e:
                logger.error(f"Invalid date format: {marriage_date_str}, error: {e}")
                return
            
            # Cập nhật trạng thái kết hôn cho cả hai công dân
            db = SessionLocal()
            try:
                # Cập nhật trạng thái cho chồng
                husband_updated = self._update_citizen_marriage_status(db, husband_id, wife_id)
                logger.info(f"Updated marital status for husband {husband_id}: {husband_updated}")
                
                # Cập nhật trạng thái cho vợ
                wife_updated = self._update_citizen_marriage_status(db, wife_id, husband_id)
                logger.info(f"Updated marital status for wife {wife_id}: {wife_updated}")
                
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error processing citizen_married event: {e}", exc_info=True)

    def _update_citizen_marriage_status(self, db: Session, citizen_id: str, spouse_id: str) -> bool:
        """Cập nhật trạng thái hôn nhân của công dân."""
        try:
            # Cập nhật thông tin hôn nhân
            query = text("""
                UPDATE [BCA].[Citizen]
                SET [marital_status] = N'Đã kết hôn',
                    [spouse_citizen_id] = :spouse_id,
                    [updated_at] = GETDATE(),
                    [updated_by] = 'SYSTEM'
                WHERE [citizen_id] = :citizen_id
            """)
            
            result = db.execute(query, {
                "citizen_id": citizen_id,
                "spouse_id": spouse_id
            })
            
            affected_rows = result.rowcount
            
            if affected_rows > 0:
                db.commit()
                return True
            else:
                logger.warning(f"No rows updated when updating marital status for citizen {citizen_id}")
                return False
                
        except Exception as e:
            db.rollback()
            logger.error(f"Database error when updating marriage status: {e}", exc_info=True)
            raise e

# Tạo instance singleton
kafka_consumer_instance = KafkaEventConsumer()

def get_kafka_consumer():
    """Dependency function để inject KafkaConsumer."""
    return kafka_consumer_instance
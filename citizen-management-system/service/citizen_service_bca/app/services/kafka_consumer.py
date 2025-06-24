# citizen_service_bca/app/services/kafka_consumer.py

import json
import logging
import asyncio
import os
from sqlalchemy import text
from datetime import datetime, timezone, date
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
           
            # {
            #   "outbox_id": 101,
            #   "aggregate_type": "DeathCertificate",
            #   "aggregate_id": "DC-TEST-12345",
            #   "event_type": "citizen_died", <--- Chúng ta cần lấy trường này
            #   "payload": "{...json string...}", <--- Và nội dung JSON từ trường này
            #   "created_at": "...",
            #   "processed": false,
            #   "processed_at": null,
            #   "retry_count": 0,
            #   "error_message": null,
            #   "next_retry_at": null
            # }

            if message.get('schema', {}).get('name', '').endswith('SchemaChangeValue'):
                logger.info(f"Skipping Debezium schema change event: {message.get('payload', {}).get('schemaName', 'N/A')}.{message.get('payload', {}).get('tableName', 'N/A')}")
                return # Bỏ qua tin nhắn DDL

            # Lấy phần payload chính, chứa dữ liệu bản ghi đã được unwrapped từ EventOutbox.
            # Cấu trúc của 'message' ở đây là {'schema': {...}, 'payload': {data_unwrapped_from_db}}
            event_outbox_record = message.get('payload') 

            if not event_outbox_record:
                logger.warning(f"Invalid message format: Missing primary payload from Kafka message. Message: {message}")
                self._store_failed_event(message, "Missing primary payload from Kafka message")
                return

            # Từ event_outbox_record (đã là bản ghi của EventOutbox), lấy các trường cần thiết.
            event_type = event_outbox_record.get('event_type') # Ví dụ: 'citizen_died', 'CitizenMarried'
            event_payload_json_str = event_outbox_record.get('payload') # Đây là chuỗi JSON chứa dữ liệu chi tiết của sự kiện

            if not event_type or not event_payload_json_str:
                logger.warning(f"Invalid message format: Missing 'event_type' ('{event_type}') or inner 'payload' string ('{event_payload_json_str}') within EventOutbox record. Record: {event_outbox_record}")
                self._store_failed_event(message, "Missing event_type or inner payload string in EventOutbox record")
                return

            try:
                # Chuyển đổi chuỗi JSON từ trường 'payload' bên trong thành Python dictionary.
                actual_event_payload = json.loads(event_payload_json_str)
            except json.JSONDecodeError as e:
                logger.error(f"Failed to decode JSON payload from EventOutbox record. Error: {e}. Inner Payload string: {event_payload_json_str}")
                self._store_failed_event(message, f"JSON Decode Error in inner payload: {str(e)}")
                return

            # Ghi log thông tin sự kiện đang xử lý
            logger.info(f"Processing event: {event_type} for aggregate_id: {event_outbox_record.get('aggregate_id', 'N/A')}")

            # Xử lý các loại sự kiện nghiệp vụ
            if event_type == 'citizen_died':
                await self._process_citizen_died_event(actual_event_payload)
            elif event_type == 'citizen_married':
                await self._process_citizen_married_event(actual_event_payload)
            elif event_type == 'citizen_divorced': 
                await self._process_citizen_divorced_event(actual_event_payload)
            elif event_type == 'citizen_birth_registered':
                await self._process_citizen_birth_registered_event(actual_event_payload)
            else:
                logger.info(f"Ignoring unsupported event type: {event_type} for aggregate_id: {event_outbox_record.get('aggregate_id', 'N/A')}")

        except Exception as e:
            logger.error(f"Error processing message (outer try-catch). Message: {message}. Error: {e}", exc_info=True)
            # Lưu toàn bộ message gốc nếu có lỗi không mong muốn ở đây
            self._store_failed_event(message, f"Unexpected error in _process_message: {str(e)}")


    async def _process_citizen_divorced_event(self, payload: Dict[str, Any]): # <-- Thêm phương thức xử lý ly hôn
        """Xử lý sự kiện khi công dân ly hôn."""
        try:
            logger.info(f"Processing citizen_divorced event with payload: {payload}")
            
            husband_id = payload.get('husband_id')
            wife_id = payload.get('wife_id')
            divorce_date_str = payload.get('divorce_date')
            judgment_no = payload.get('judgment_no')
            
            if not husband_id or not wife_id or not divorce_date_str or not judgment_no:
                logger.warning(f"Missing required fields in citizen_divorced event: {payload}")
                self._store_failed_event(payload, "Missing required fields")
                return
            
            try:
                if 'T' in divorce_date_str:
                    divorce_date_str = divorce_date_str.split('T')[0]
                divorce_date = datetime.strptime(divorce_date_str, "%Y-%m-%d").date()
                logger.info(f"Parsed divorce date: {divorce_date}")
            except Exception as e:
                logger.error(f"Invalid date format for divorce_date: {divorce_date_str}, error: {e}")
                self._store_failed_event(payload, f"Invalid date format for divorce_date: {e}")
                return
            
            db = SessionLocal()
            try:
                repo = CitizenRepository(db)
                
                # Cập nhật trạng thái ly hôn cho chồng
                husband_updated = repo.update_divorce_status(
                    husband_id,
                    wife_id, # former_spouse_citizen_id
                    divorce_date,
                    judgment_no
                )
                logger.info(f"Updated divorce status for husband {husband_id}: {husband_updated}")
                
                # Cập nhật trạng thái ly hôn cho vợ
                wife_updated = repo.update_divorce_status(
                    wife_id,
                    husband_id, # former_spouse_citizen_id
                    divorce_date,
                    judgment_no
                )
                logger.info(f"Updated divorce status for wife {wife_id}: {wife_updated}")
                
                if not husband_updated and not wife_updated:
                    logger.warning("Both husband and wife divorce updates failed. Possible data issue.")
                    self._store_failed_event(payload, "Both updates failed")

            finally:
                db.close()
                    
        except Exception as e:
            logger.error(f"Error processing citizen_divorced event: {e}", exc_info=True)
            self._store_failed_event(payload, str(e))


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

    def _store_failed_event(self, original_message_data: Dict[str, Any], error_msg: Optional[str] = None):
        """Lưu event thất bại để xử lý sau."""
        try:
            filename = f"failed_events/{datetime.now().strftime('%Y%m%d')}_failed_events.jsonl"
            os.makedirs("failed_events", exist_ok=True)
            
            # Custom JSON serializer để xử lý datetime.date
            def json_serializer(obj):
                if isinstance(obj, date):
                    return obj.isoformat()
                raise TypeError(f"Object of type {obj.__class__.__name__} is not JSON serializable")

            failed_event = {
                "original_message_data": original_message_data,
                "error": error_msg,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            with open(filename, "a") as f:
                f.write(json.dumps(failed_event, default=json_serializer) + "\n")
                
            logger.info(f"Stored failed event for later processing: {error_msg}. Original message aggregate_id: {original_message_data.get('aggregate_id', 'N/A') if isinstance(original_message_data, dict) else 'N/A'}")
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
                            failed_event_record = json.loads(line.strip())
                            
                            # Lấy lại dữ liệu gốc của tin nhắn Kafka đã lưu
                            original_message_data = failed_event_record.get('original_message_data', {})
                            
                            if not original_message_data:
                                logger.warning(f"Skipping failed event record with no original_message_data: {failed_event_record}")
                                processed.append(failed_event_record) # Coi như đã xử lý để không lặp lại lỗi
                                continue

                            # Gọi lại _process_message với dữ liệu tin nhắn gốc
                            await self._process_message(original_message_data)
                                
                            processed.append(failed_event_record) # Chỉ đánh dấu là xử lý nếu _process_message không ném lỗi
                        except Exception as e:
                            logger.error(f"Error reprocessing event: {e}. Record: {line.strip()[:200]}...")
                
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
            
            # Extract required data from payload
            husband_id = payload.get('husband_id')
            wife_id = payload.get('wife_id')
            marriage_date_str = payload.get('marriage_date')
            marriage_certificate_no = payload.get('marriage_certificate_no')
            
            # Validate required fields
            if not husband_id or not wife_id or not marriage_date_str or not marriage_certificate_no:
                logger.warning(f"Missing required fields in citizen_married event: {payload}")
                self._store_failed_event(payload, "Missing required fields")
                return
            
            # Parse date
            try:
                if 'T' in marriage_date_str:
                    marriage_date_str = marriage_date_str.split('T')[0]
                marriage_date = datetime.strptime(marriage_date_str, "%Y-%m-%d").date()
                logger.info(f"Parsed marriage date: {marriage_date}")
            except Exception as e:
                logger.error(f"Invalid date format: {marriage_date_str}, error: {e}")
                self._store_failed_event(payload, f"Invalid date format: {e}")
                return
            
            # Use repository pattern for DB updates
            db = SessionLocal()
            try:
                repo = CitizenRepository(db)
                
                # Update husband's marital status
                husband_updated = repo.update_marriage_status(
                    husband_id, 
                    wife_id, 
                    marriage_date, 
                    marriage_certificate_no
                )
                logger.info(f"Updated marital status for husband {husband_id}: {husband_updated}")
                
                # Update wife's marital status
                wife_updated = repo.update_marriage_status(
                    wife_id, 
                    husband_id, 
                    marriage_date, 
                    marriage_certificate_no
                )
                logger.info(f"Updated marital status for wife {wife_id}: {wife_updated}")
                
                # Check if any update failed
                if not husband_updated and not wife_updated:
                    logger.warning("Both husband and wife updates failed. Possible data issue.")
                    self._store_failed_event(payload, "Both updates failed")
                
            finally:
                db.close()
                    
        except Exception as e:
            logger.error(f"Error processing citizen_married event: {e}", exc_info=True)
            self._store_failed_event(payload, str(e))

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

    async def _process_citizen_birth_registered_event(self, payload: Dict[str, Any]):
        """Xử lý sự kiện khi một công dân mới được đăng ký khai sinh."""
        try:
            logger.info(f"Processing CitizenBirthRegistered event with payload: {payload}")
            
            # Kiểm tra các trường dữ liệu cần thiết từ payload
            required_fields = ['citizen_id', 'full_name', 'date_of_birth', 'gender_id']
            if not all(field in payload for field in required_fields):
                logger.warning(f"Missing required fields in CitizenBirthRegistered event: {payload}")
                self._store_failed_event(payload, "Missing required fields for birth registration")
                return
            
            # Parse date
            date_of_birth_str = payload.get('date_of_birth')
            try:
                if 'T' in date_of_birth_str:
                    date_of_birth_str = date_of_birth_str.split('T')[0]
                payload['date_of_birth'] = datetime.strptime(date_of_birth_str, "%Y-%m-%d").date()
            except (ValueError, TypeError) as e:
                logger.error(f"Invalid date format for date_of_birth: {date_of_birth_str}, error: {e}")
                self._store_failed_event(payload, f"Invalid date format for date_of_birth: {e}")
                return

            # Tạo citizen mới trong DB
            db = SessionLocal()
            try:
                repo = CitizenRepository(db)
                created = repo.create_newborn_citizen(payload)
                
                if created:
                    logger.info(f"Successfully created new citizen record for {payload.get('citizen_id')} from birth event.")
                else:
                    logger.error(f"Failed to create new citizen record for {payload.get('citizen_id')}. Storing event for retry.")
                    self._store_failed_event(payload, "Failed to create citizen record in repository.")
            finally:
                db.close()

        except Exception as e:
            logger.error(f"Error processing CitizenBirthRegistered event: {e}", exc_info=True)
            self._store_failed_event(payload, f"Unexpected error in _process_citizen_birth_registered_event: {str(e)}")

# Tạo instance singleton
kafka_consumer_instance = KafkaEventConsumer()

def get_kafka_consumer():
    """Dependency function để inject KafkaConsumer."""
    return kafka_consumer_instance
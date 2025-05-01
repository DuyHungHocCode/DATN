# civil_status_service_btp/app/services/kafka_producer.py
from kafka import KafkaProducer
from kafka.errors import KafkaError
import json
import logging
from datetime import datetime, timezone
from app.config import get_settings
from app.schemas.death_certificate import DeathCertificateResponse # Hoặc schema sự kiện riêng

settings = get_settings()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class KafkaEventProducer:
    def __init__(self):
        self.producer = None
        try:
            logger.info(f"Initializing Kafka producer with bootstrap servers: {settings.KAFKA_BOOTSTRAP_SERVERS}")
            self.producer = KafkaProducer(
                bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS.split(','), 
                value_serializer=lambda v: json.dumps(v).encode('utf-8'),
                retries=3,
                # Bỏ các tùy chọn không cần thiết có thể gây lỗi
                # api_version=(0, 11, 5) # Dòng này có thể gây lỗi
            )
            logger.info("Kafka producer initialized successfully.")
        except KafkaError as e:
            logger.error(f"Failed to initialize Kafka producer: {e}", exc_info=True)
        except Exception as e:
            logger.error(f"Unexpected error initializing Kafka producer: {e}", exc_info=True)

    # def send_citizen_died_event(self, certificate_data: DeathCertificateResponse):
    #     """Gửi sự kiện citizen_died lên Kafka."""
    #     if not self.producer:
    #         logger.error("Kafka producer is not available. Cannot send event.")
    #         return # Hoặc raise lỗi tùy logic

    #     event_payload = {
    #         "eventType": "citizen_died",
    #         "payload": {
    #             "citizen_id": certificate_data.citizen_id,
    #             "date_of_death": certificate_data.date_of_death.isoformat(), # Chuyển date thành string
    #             "place_of_death_detail": certificate_data.place_of_death_detail,
    #             "death_certificate_no": certificate_data.death_certificate_no,
    #             "registration_date": certificate_data.registration_date.isoformat(),
    #             # Thêm các trường cần thiết khác
    #         },
    #         "timestamp": datetime.utcnow().isoformat() + "Z" # UTC timestamp
    #     }

    #     try:
    #         logger.info(f"Sending event to Kafka topic: {settings.KAFKA_TOPIC_BTP_EVENTS}")
    #         # Gửi message bất đồng bộ
    #         future = self.producer.send(settings.KAFKA_TOPIC_BTP_EVENTS, value=event_payload)

    #         # (Optional) Xử lý kết quả gửi (có thể làm chậm quá trình nếu đợi đồng bộ)
    #         # record_metadata = future.get(timeout=10)
    #         # logger.info(f"Event sent successfully to topic {record_metadata.topic} partition {record_metadata.partition} offset {record_metadata.offset}")

    #         # Hoặc thêm callback để xử lý bất đồng bộ
    #         future.add_callback(self.on_send_success)
    #         future.add_errback(self.on_send_error)

    #         # Đảm bảo message được gửi đi (flush có thể làm chậm)
    #         # self.producer.flush(timeout=5)


    #     except KafkaError as e:
    #         logger.error(f"Failed to send event to Kafka: {e}")
    #         # Xử lý lỗi: ghi log, thử lại, hoặc báo cáo lỗi

    def on_send_success(self, record_metadata):
        logger.debug(f"Kafka event sent: topic={record_metadata.topic}, partition={record_metadata.partition}, offset={record_metadata.offset}")

    def on_send_error(self, excp):
        logger.error('Error sending Kafka event', exc_info=excp)
        # Xử lý lỗi ở đây, ví dụ: ghi vào dead-letter queue

    def close(self):
        if self.producer:
            self.producer.flush() # Đảm bảo mọi message đã được gửi trước khi đóng
            self.producer.close()
            logger.info("Kafka producer closed.")

    def send_citizen_died_event(self, certificate_data: DeathCertificateResponse):
        """Gửi sự kiện citizen_died lên Kafka."""
        if not self.producer:
            logger.error("Kafka producer is not available. Cannot send event.")
            self._store_failed_event(certificate_data)
            return False
        
        event_payload = {
            "eventType": "citizen_died",
            "payload": {
                "citizen_id": certificate_data.citizen_id,
                "date_of_death": certificate_data.date_of_death.isoformat(),
                "time_of_death": certificate_data.time_of_death.isoformat() if certificate_data.time_of_death else None,
                "place_of_death_detail": certificate_data.place_of_death_detail,
                "death_certificate_no": certificate_data.death_certificate_no,
                "registration_date": certificate_data.registration_date.isoformat(),
                "death_certificate_id": certificate_data.death_certificate_id,
                "cause_of_death": certificate_data.cause_of_death
            },
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

        try:
            logger.info(f"Sending event to Kafka topic: {settings.KAFKA_TOPIC_BTP_EVENTS}")
            logger.info(f"Event payload: {event_payload}")
            
            # Gửi message với timeout để đảm bảo được gửi
            future = self.producer.send(settings.KAFKA_TOPIC_BTP_EVENTS, value=event_payload)
            
            # Đợi kết quả đồng bộ để đảm bảo message được gửi đi
            record_metadata = future.get(timeout=10)
            logger.info(f"Event sent successfully to topic: {record_metadata.topic}, partition: {record_metadata.partition}, offset: {record_metadata.offset}")
            
            # Gọi flush để đảm bảo message được gửi
            self.producer.flush(timeout=5)
            logger.info("Producer flush completed")
            
            return True
            
        except KafkaError as e:
            logger.error(f"Failed to send event to Kafka: {e}", exc_info=True)
            self._store_failed_event(certificate_data, str(e))
            return False
        except Exception as e:
            logger.error(f"Unexpected error sending Kafka event: {e}", exc_info=True)
            self._store_failed_event(certificate_data, str(e))
            return False

    def _store_failed_event(self, certificate_data, error_msg=None):
        """Lưu event thất bại để xử lý sau (Dead Letter Queue)."""
        try:
            # Trong thực tế, bạn có thể lưu vào DB hoặc file
            failed_event = {
                "certificate_data": certificate_data.model_dump(),
                "error": error_msg,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            # Đơn giản lưu vào file (trong môi trường thực tế nên lưu vào DB)
            with open("failed_events.jsonl", "a") as f:
                f.write(json.dumps(failed_event) + "\n")
                
            logger.info(f"Stored failed event for certificate_id {certificate_data.death_certificate_id} for later processing")
        except Exception as e:
            logger.error(f"Failed to store failed event: {e}")
    
# Singleton pattern
kafka_producer_instance = KafkaEventProducer()
def get_kafka_producer():
    return kafka_producer_instance
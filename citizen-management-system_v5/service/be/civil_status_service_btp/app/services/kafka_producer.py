# # civil_status_service_btp/app/services/kafka_producer.py
# from kafka import KafkaProducer
# from kafka.errors import KafkaError
# import json
# import os
# import logging
# from datetime import datetime, timezone, timedelta
# from app.config import get_settings
# from app.schemas.death_certificate import DeathCertificateResponse # Hoặc schema sự kiện riêng
# from app.schemas.marriage_certificate import MarriageCertificateResponse # Hoặc schema sự kiện riêng

# settings = get_settings()
# logger = logging.getLogger(__name__)

# class KafkaEventProducer:
#     def __init__(self):
#         self.producer = None
#         try:
#             logger.info(f"Initializing Kafka producer with bootstrap servers: {settings.KAFKA_BOOTSTRAP_SERVERS}")
#             self.producer = KafkaProducer(
#                 bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS.split(','), 
#                 value_serializer=lambda v: json.dumps(v).encode('utf-8'),
#                 retries=3,
#                 # Bỏ các tùy chọn không cần thiết có thể gây lỗi
#                 # api_version=(0, 11, 5) # Dòng này có thể gây lỗi
#             )
#             logger.info("Kafka producer initialized successfully.")
#         except KafkaError as e:
#             logger.error(f"Failed to initialize Kafka producer: {e}", exc_info=True)
#         except Exception as e:
#             logger.error(f"Unexpected error initializing Kafka producer: {e}", exc_info=True)


#     def on_send_success(self, record_metadata):
#         logger.debug(f"Kafka event sent: topic={record_metadata.topic}, partition={record_metadata.partition}, offset={record_metadata.offset}")

#     def on_send_error(self, excp):
#         logger.error('Error sending Kafka event', exc_info=excp)
#         # Xử lý lỗi ở đây, ví dụ: ghi vào dead-letter queue

#     def close(self):
#         if self.producer:
#             self.producer.flush() # Đảm bảo mọi message đã được gửi trước khi đóng
#             self.producer.close()
#             logger.info("Kafka producer closed.")

#     def send_citizen_died_event(self, certificate_data: DeathCertificateResponse):
#         """Gửi sự kiện citizen_died lên Kafka."""
#         if not self.producer:
#             logger.error("Kafka producer is not available. Cannot send event.")
#             self._store_failed_event(certificate_data)
#             return False
        
#         # Đảm bảo định dạng ngày tháng chuẩn ISO 8601
#         date_of_death_iso = certificate_data.date_of_death.strftime("%Y-%m-%d")
        
#         # Đảm bảo time_of_death cũng có định dạng chuẩn nếu có
#         time_of_death_iso = None
#         if certificate_data.time_of_death:
#             time_of_death_iso = certificate_data.time_of_death.strftime("%H:%M:%S")
        
#         event_payload = {
#             "eventType": "citizen_died",
#             "payload": {
#                 "citizen_id": certificate_data.citizen_id,
#                 "date_of_death": date_of_death_iso,  # Định dạng YYYY-MM-DD
#                 "time_of_death": time_of_death_iso,  # Định dạng HH:MM:SS hoặc None
#                 "place_of_death_detail": certificate_data.place_of_death_detail,
#                 "death_certificate_no": certificate_data.death_certificate_no,
#                 "registration_date": certificate_data.registration_date.strftime("%Y-%m-%d"),
#                 "death_certificate_id": certificate_data.death_certificate_id,
#                 "cause_of_death": certificate_data.cause_of_death
#             },
#             "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
#         }

#         try:
#             logger.info(f"Sending event to Kafka topic: {settings.KAFKA_TOPIC_BTP_EVENTS}")
            
#             # Gửi message và đợi kết quả
#             future = self.producer.send(settings.KAFKA_TOPIC_BTP_EVENTS, value=event_payload)
#             record_metadata = future.get(timeout=10)
            
#             logger.info(f"Event sent successfully to topic: {record_metadata.topic}, partition: {record_metadata.partition}, offset: {record_metadata.offset}")
            
#             # Flush để đảm bảo message được gửi
#             self.producer.flush(timeout=5)
#             return True
            
#         except Exception as e:
#             logger.error(f"Failed to send event to Kafka: {e}", exc_info=True)
#             self._store_failed_event(certificate_data, str(e))
#             return False
        
#     def _store_failed_event(self, event_data, error_msg=None, retry_count=0):
#         """Store failed events with additional metadata for retry processing."""
#         try:
#             # Create a structured event record with retry information
#             failed_event = {
#                 "event_data": event_data.model_dump() if hasattr(event_data, "model_dump") else event_data,
#                 "error": error_msg,
#                 "timestamp": datetime.now(timezone.utc).isoformat(),
#                 "retry_count": retry_count,
#                 "next_retry_time": (datetime.now(timezone.utc) + 
#                                 timedelta(minutes=min(30, 2 ** retry_count))).isoformat(),
#                 "event_type": event_data.__class__.__name__
#             }
            
#             # Save to structured storage - organized by date for easier processing
#             filename = f"failed_events/{datetime.now().strftime('%Y%m%d')}_failed_events.jsonl"
#             os.makedirs("failed_events", exist_ok=True)
            
#             with open(filename, "a") as f:
#                 f.write(json.dumps(failed_event) + "\n")
                
#             logger.info(f"Stored failed event with ID: {getattr(event_data, 'marriage_certificate_id', None) or getattr(event_data, 'death_certificate_id', None)} for retry later. Next attempt: {failed_event['next_retry_time']}")
#         except Exception as e:
#             logger.error(f"Failed to store failed event: {e}", exc_info=True)
    
#     def send_marriage_event(self, certificate_data: MarriageCertificateResponse):
#         """Gửi sự kiện citizen_married lên Kafka."""
#         if not self.producer:
#             logger.error("Kafka producer is not available. Cannot send event.")
#             self._store_failed_event(certificate_data)
#             return False
        
#         # Đảm bảo định dạng ngày tháng chuẩn ISO 8601
#         marriage_date_iso = certificate_data.marriage_date.strftime("%Y-%m-%d")
#         registration_date_iso = certificate_data.registration_date.strftime("%Y-%m-%d")
        
#         event_payload = {
#             "eventType": "citizen_married",
#             "payload": {
#                 "marriage_certificate_id": certificate_data.marriage_certificate_id,
#                 "marriage_certificate_no": certificate_data.marriage_certificate_no,
#                 "husband_id": certificate_data.husband_id,
#                 "wife_id": certificate_data.wife_id,
#                 "marriage_date": marriage_date_iso,
#                 "registration_date": registration_date_iso,
#                 "issuing_authority_id": certificate_data.issuing_authority_id,
#                 "status": certificate_data.status
#             },
#             "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
#         }

#         try:
#             logger.info(f"Sending marriage event to Kafka topic: {settings.KAFKA_TOPIC_BTP_EVENTS}")
            
#             # Gửi message và đợi kết quả
#             future = self.producer.send(settings.KAFKA_TOPIC_BTP_EVENTS, value=event_payload)
#             record_metadata = future.get(timeout=10)
            
#             logger.info(f"Event sent successfully to topic: {record_metadata.topic}, partition: {record_metadata.partition}, offset: {record_metadata.offset}")
            
#             # Flush để đảm bảo message được gửi
#             self.producer.flush(timeout=5)
#             return True
            
#         except Exception as e:
#             logger.error(f"Failed to send event to Kafka: {e}", exc_info=True)
#             self._store_failed_event(certificate_data, str(e))
#             return False
# # Singleton pattern
# kafka_producer_instance = KafkaEventProducer()
# def get_kafka_producer():
#     return kafka_producer_instance
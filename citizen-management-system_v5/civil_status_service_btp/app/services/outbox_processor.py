# civil_status_service_btp/app/services/outbox_processor.py

import asyncio
import logging
import json
from datetime import datetime, timezone
from app.db.database import SessionLocal
from app.db.outbox_repo import OutboxRepository
from app.services.kafka_producer import kafka_producer_instance
from app.schemas.death_certificate import DeathCertificateResponse
from app.schemas.marriage_certificate import MarriageCertificateResponse

logger = logging.getLogger(__name__)

class OutboxProcessor:
    def __init__(self, processing_interval=10):  # 10 seconds
        self.processing_interval = processing_interval
        self.running = False
        self.max_batch_size = 20
    
    async def start(self):
        """Start the outbox processor."""
        if self.running:
            return
            
        self.running = True
        logger.info("Outbox processor started")
        
        # Start the processing loop
        asyncio.create_task(self._processing_loop())
    
    async def stop(self):
        """Stop the outbox processor."""
        self.running = False
        logger.info("Outbox processor stopped")
    
    async def _processing_loop(self):
        """Main processing loop that runs periodically."""
        while self.running:
            try:
                await self._process_batch()
            except Exception as e:
                logger.error(f"Error in outbox processing: {e}", exc_info=True)
            
            # Wait before next check
            await asyncio.sleep(self.processing_interval)
    
    async def _process_batch(self):
        """Process a batch of outbox messages."""
        db = SessionLocal()
        try:
            repo = OutboxRepository(db)
            pending_messages = repo.get_pending_messages(batch_size=self.max_batch_size)
            
            if not pending_messages:
                return
                
            logger.info(f"Processing {len(pending_messages)} outbox messages")
            
            for message in pending_messages:
                await self._process_message(repo, message)
                
        except Exception as e:
            logger.error(f"Error processing outbox batch: {e}", exc_info=True)
        finally:
            db.close()
    
    async def _process_message(self, repo, message):
        """Process a single outbox message."""
        outbox_id = message["outbox_id"]
        event_type = message["event_type"]
        payload = message["payload"]
        
        try:
            success = False
            
            # Process based on event type
            if event_type == "citizen_died":
                # Recreate certificate from payload
                certificate_data = DeathCertificateResponse.model_validate(payload)
                success =  kafka_producer_instance.send_citizen_died_event(certificate_data)
            elif event_type == "citizen_married":
                # Recreate certificate from payload
                certificate_data = MarriageCertificateResponse.model_validate(payload)
                success =  kafka_producer_instance.send_marriage_event(certificate_data)
            else:
                logger.warning(f"Unknown event type: {event_type}")
                success = False
            
            # Mark message as processed or failed
            if success:
                repo.mark_as_processed(outbox_id)
                logger.info(f"Successfully processed outbox message {outbox_id} ({event_type})")
            else:
                # Calculate exponential backoff
                retry_count = message["retry_count"]
                retry_delay = min(60, 2 ** retry_count) # Max 60 minutes
                
                repo.mark_as_failed(outbox_id, "Failed to send event to Kafka", retry_delay)
                logger.warning(f"Failed to process outbox message {outbox_id} ({event_type}). Retry scheduled in {retry_delay} minutes.")
                
        except Exception as e:
            logger.error(f"Error processing outbox message {outbox_id}: {e}", exc_info=True)
            repo.mark_as_failed(outbox_id, str(e))

# Create singleton instance
outbox_processor = OutboxProcessor()

def get_outbox_processor():
    """Dependency function for FastAPI."""
    return outbox_processor
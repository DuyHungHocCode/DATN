# civil_status_service_btp/app/services/event_retry_worker.py

import asyncio
import json
import os
import logging
from datetime import datetime, timezone, timedelta
import time
from app.schemas.death_certificate import DeathCertificateResponse
from app.schemas.marriage_certificate import MarriageCertificateResponse
from app.services.kafka_producer import kafka_producer_instance

logger = logging.getLogger(__name__)

class EventRetryWorker:
    def __init__(self, check_interval=60):  # Check every minute
        self.check_interval = check_interval
        self.running = False
        self.max_retries = 10  # Maximum retry attempts
    
    async def start(self):
        """Start the retry worker."""
        if self.running:
            return
            
        self.running = True
        logger.info("Event retry worker started")
        
        # Start the retry loop
        asyncio.create_task(self._retry_loop())
    
    async def stop(self):
        """Stop the retry worker."""
        self.running = False
        logger.info("Event retry worker stopped")
    
    async def _retry_loop(self):
        """Main retry loop that runs periodically."""
        while self.running:
            try:
                await self._process_failed_events()
            except Exception as e:
                logger.error(f"Error in retry processing: {e}", exc_info=True)
            
            # Wait before next check
            await asyncio.sleep(self.check_interval)
    
    async def _process_failed_events(self):
        """Process all failed event files."""
        if not os.path.exists("failed_events"):
            return
            
        current_time = datetime.now(timezone.utc)
        
        for filename in os.listdir("failed_events"):
            if not filename.endswith('.jsonl'):
                continue
                
            file_path = os.path.join("failed_events", filename)
            temp_path = file_path + ".processing"
            processed_events = []
            remaining_events = []
            
            # Rename file to prevent concurrent processing
            try:
                os.rename(file_path, temp_path)
            except OSError:
                # File might be being processed by another worker
                continue
            
            # Process each event in the file
            try:
                with open(temp_path, 'r') as f:
                    for line in f:
                        try:
                            event = json.loads(line.strip())
                            
                            # Check if it's time to retry
                            next_retry = datetime.fromisoformat(event['next_retry_time'])
                            if current_time >= next_retry:
                                # Time to retry this event
                                if event['retry_count'] >= self.max_retries:
                                    # Too many retries, move to dead letter queue
                                    self._move_to_dlq(event)
                                    processed_events.append(event)
                                    logger.warning(f"Event moved to DLQ after {event['retry_count']} failed attempts")
                                else:
                                    # Attempt to resend
                                    success = await self._resend_event(event)
                                    if success:
                                        processed_events.append(event)
                                        logger.info(f"Successfully resent event on attempt {event['retry_count'] + 1}")
                                    else:
                                        # Failed again, update retry count and time
                                        event['retry_count'] += 1
                                        event['next_retry_time'] = (datetime.now(timezone.utc) + 
                                                                   timedelta(minutes=min(30, 2 ** event['retry_count']))).isoformat()
                                        remaining_events.append(event)
                                        logger.info(f"Retry attempt {event['retry_count']} failed, next attempt at {event['next_retry_time']}")
                            else:
                                # Not time to retry yet
                                remaining_events.append(event)
                        except Exception as e:
                            logger.error(f"Error processing event: {e}")
                            # Keep problematic events for manual inspection
                            remaining_events.append(event)
            
                # Write remaining events back
                if remaining_events:
                    with open(file_path, 'w') as f:
                        for event in remaining_events:
                            f.write(json.dumps(event) + "\n")
                    os.remove(temp_path)
                else:
                    # No events left, remove both files
                    os.remove(temp_path)
                    if os.path.exists(file_path):
                        os.remove(file_path)
                        
            except Exception as e:
                logger.error(f"Error processing file {filename}: {e}")
                # If anything goes wrong, restore the original file
                if os.path.exists(temp_path):
                    if not os.path.exists(file_path):
                        os.rename(temp_path, file_path)
                    else:
                        os.remove(temp_path)
    
    async def _resend_event(self, event):
        """Attempt to resend the event."""
        try:
            event_type = event.get('event_type', '')
            event_data = event.get('event_data', {})
            
            if 'DeathCertificate' in event_type:
                # Recreate the DeathCertificateResponse
                certificate = DeathCertificateResponse.model_validate(event_data)
                return await kafka_producer_instance.send_citizen_died_event(certificate)
            elif 'MarriageCertificate' in event_type:
                # Recreate the MarriageCertificateResponse
                certificate = MarriageCertificateResponse.model_validate(event_data)
                return await kafka_producer_instance.send_marriage_event(certificate)
            else:
                logger.error(f"Unknown event type: {event_type}")
                return False
        except Exception as e:
            logger.error(f"Error resending event: {e}")
            return False
    
    def _move_to_dlq(self, event):
        """Move event to Dead Letter Queue for manual inspection."""
        try:
            dlq_dir = "dead_letter_queue"
            os.makedirs(dlq_dir, exist_ok=True)
            
            # Add reason for moving to DLQ
            event['dlq_reason'] = f"Exceeded maximum retry attempts ({self.max_retries})"
            event['moved_to_dlq_at'] = datetime.now(timezone.utc).isoformat()
            
            # Write to DLQ file
            dlq_file = os.path.join(dlq_dir, f"dlq_{datetime.now().strftime('%Y%m%d')}.jsonl")
            with open(dlq_file, "a") as f:
                f.write(json.dumps(event) + "\n")
                
            logger.info(f"Event moved to Dead Letter Queue: {dlq_file}")
        except Exception as e:
            logger.error(f"Error moving event to DLQ: {e}")

# Create singleton instance
event_retry_worker = EventRetryWorker()

def get_event_retry_worker():
    """Dependency function for FastAPI."""
    return event_retry_worker
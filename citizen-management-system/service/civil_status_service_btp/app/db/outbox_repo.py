# civil_status_service_btp/app/db/outbox_repo.py
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timezone, timedelta, date
import json
import logging


logger = logging.getLogger(__name__)

class OutboxRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def _json_serializer(self, obj):
        """Tùy chỉnh JSON serializer để hỗ trợ các kiểu dữ liệu đặc biệt."""
        if isinstance(obj, (date, datetime)):
            return obj.isoformat()
        raise TypeError(f"Type {type(obj)} not serializable")
    
    def create_outbox_message(self, aggregate_type, aggregate_id, event_type, payload):
        """Creates a new outbox message using a stored procedure."""
        try:
            # Serialize JSON with custom handler for date/datetime
            payload_json = json.dumps(payload, default=self._json_serializer)
            
            # Call the stored procedure
            query = text("""
                DECLARE @new_id BIGINT;
                EXEC [API_Internal].[CreateOutboxMessage]
                    @aggregate_type = :aggregate_type,
                    @aggregate_id = :aggregate_id,
                    @event_type = :event_type,
                    @payload = :payload,
                    @outbox_id = @new_id OUTPUT;
                SELECT @new_id AS new_outbox_id;
            """)
            
            result = self.db.execute(query, {
                "aggregate_type": aggregate_type,
                "aggregate_id": aggregate_id,
                "event_type": event_type,
                "payload": payload_json
            })
            
            outbox_id = result.scalar_one_or_none()
            
            if outbox_id is None:
                raise Exception("Stored procedure CreateOutboxMessage did not return the new outbox ID.")

            return outbox_id
        except Exception as e:
            logger.error(f"Error creating outbox message: {e}", exc_info=True)
            raise
    
    # def get_pending_messages(self, batch_size=10):
    #     """
    #     Get pending outbox messages ready for processing.
        
    #     Returns:
    #         List of outbox messages
    #     """
    #     try:
    #         query = text("""
    #                 SELECT TOP (:batch_size)
    #                     [outbox_id], [aggregate_type], [aggregate_id], 
    #                     [event_type], [payload], [retry_count]
    #                 FROM [BTP].[EventOutbox]
    #                 WHERE 
    #                     [processed] = 0 AND
    #                     ([next_retry_at] IS NULL OR [next_retry_at] <= GETDATE())
    #                 ORDER BY [created_at] ASC;
    #             """)
            
    #         result = self.db.execute(query, {"batch_size": batch_size})
            
    #         messages = []
    #         for row in result:
    #             message = {
    #                 "outbox_id": row.outbox_id,
    #                 "aggregate_type": row.aggregate_type,
    #                 "aggregate_id": row.aggregate_id,
    #                 "event_type": row.event_type,
    #                 "payload": json.loads(row.payload),
    #                 "retry_count": row.retry_count
    #             }
    #             messages.append(message)
            
    #         return messages
    #     except Exception as e:
    #         logger.error(f"Error fetching pending outbox messages: {e}", exc_info=True)
    #         return []
    
    # def mark_as_processed(self, outbox_id):
    #     """Mark an outbox message as processed."""
    #     try:
    #         query = text("""
    #             UPDATE [BTP].[EventOutbox]
    #             SET [processed] = 1,
    #                 [processed_at] = GETDATE()
    #             WHERE [outbox_id] = :outbox_id;
    #         """)
            
    #         self.db.execute(query, {"outbox_id": outbox_id})
    #         self.db.commit()
            
    #         return True
    #     except Exception as e:
    #         self.db.rollback()
    #         logger.error(f"Error marking outbox message as processed: {e}", exc_info=True)
    #         return False
    
    # def mark_as_failed(self, outbox_id, error_message, retry_delay_minutes=5):
    #     """Mark an outbox message as failed and schedule retry."""
    #     try:
    #         next_retry = datetime.now(timezone.utc) + timedelta(minutes=retry_delay_minutes)
            
    #         query = text("""
    #             UPDATE [BTP].[EventOutbox]
    #             SET [retry_count] = [retry_count] + 1,
    #                 [error_message] = :error_message,
    #                 [next_retry_at] = :next_retry_at
    #             WHERE [outbox_id] = :outbox_id;
    #         """)
            
    #         self.db.execute(query, {
    #             "outbox_id": outbox_id,
    #             "error_message": error_message,
    #             "next_retry_at": next_retry
    #         })
    #         self.db.commit()
            
    #         return True
    #     except Exception as e:
    #         self.db.rollback()
    #         logger.error(f"Error marking outbox message as failed: {e}", exc_info=True)
    #         return False
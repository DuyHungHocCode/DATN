# civil_status_service_btp/app/services/reconciliation.py

import logging
import asyncio
from sqlalchemy import text
from app.db.database import SessionLocal
from app.services.bca_client import BCAClient, get_bca_client
from datetime import datetime, timedelta, timezone

logger = logging.getLogger(__name__)

class ReconciliationService:
    """Service to detect and resolve inconsistencies between BTP and BCA."""
    
    def __init__(self):
        self.running = False
        self.check_interval = 3600  # Run every hour
        self.bca_client = get_bca_client()
    
    async def start(self):
        """Start the reconciliation service."""
        if self.running:
            return
            
        self.running = True
        logger.info("Reconciliation service started")
        
        # Start the reconciliation loop
        asyncio.create_task(self._reconciliation_loop())
    
    async def stop(self):
        """Stop the reconciliation service."""
        self.running = False
        logger.info("Reconciliation service stopped")
    
    async def _reconciliation_loop(self):
        """Main reconciliation loop that runs periodically."""
        while self.running:
            try:
                await self._check_marriage_consistency()
                await self._check_death_consistency()
            except Exception as e:
                logger.error(f"Error in reconciliation process: {e}", exc_info=True)
            
            # Wait before next check
            await asyncio.sleep(self.check_interval)
    
    async def _check_marriage_consistency(self):
        """Check consistency of marriage records between BTP and BCA."""
        logger.info("Starting marriage records consistency check")
        
        # Get recent marriages from the last 7 days
        db = SessionLocal()
        try:
            query = text("""
                SELECT TOP 100
                    [marriage_certificate_id], [husband_id], [wife_id], [marriage_date], [status]
                FROM [BTP].[MarriageCertificate]
                WHERE [registration_date] >= DATEADD(day, -7, GETDATE())
                AND [status] = 1
                ORDER BY [registration_date] DESC
            """)
            
            result = db.execute(query)
            
            inconsistencies = []
            for row in result:
                # For each marriage, check if both parties have updated marital status in BCA
                try:
                    husband = await self.bca_client.validate_citizen_status(row.husband_id)
                    wife = await self.bca_client.validate_citizen_status(row.wife_id)
                    
                    # Check for inconsistencies
                    if (husband and husband.marital_status != "Đã kết hôn") or (wife and wife.marital_status != "Đã kết hôn"):
                        inconsistencies.append({
                            "certificate_id": row.marriage_certificate_id,
                            "husband_id": row.husband_id,
                            "husband_status": husband.marital_status if husband else "Unknown",
                            "wife_id": row.wife_id,
                            "wife_status": wife.marital_status if wife else "Unknown",
                            "marriage_date": row.marriage_date
                        })
                        
                        # Log the inconsistency
                        logger.warning(f"Marriage inconsistency detected: Certificate ID {row.marriage_certificate_id}, Husband status: {husband.marital_status if husband else 'Unknown'}, Wife status: {wife.marital_status if wife else 'Unknown'}")
                        
                        #TODO: Automatically resolve by resubmitting Kafka event
                except Exception as e:
                    logger.error(f"Error checking marriage consistency for certificate {row.marriage_certificate_id}: {e}")
            
            # Report results
            if inconsistencies:
                logger.warning(f"Found {len(inconsistencies)} marriage inconsistencies")
            else:
                logger.info("No marriage inconsistencies found")
                
        except Exception as e:
            logger.error(f"Error in marriage consistency check: {e}", exc_info=True)
        finally:
            db.close()
    
    async def _check_death_consistency(self):
        """Check consistency of death records between BTP and BCA."""
        logger.info("Starting death records consistency check")
        
        

# Create singleton instance
reconciliation_service = ReconciliationService()

def get_reconciliation_service():
    """Dependency function for FastAPI."""
    return reconciliation_service
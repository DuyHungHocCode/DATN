# civil_status_service_btp/app/api/router.py
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
import logging
from datetime import datetime, timezone
from app.db.database import get_btp_db
from app.db.civil_status_repo import CivilStatusRepository
from app.schemas.death_certificate import DeathCertificateCreate, DeathCertificateResponse
from app.services.bca_client import BCAClient, get_bca_client
from app.services.kafka_producer import KafkaEventProducer, get_kafka_producer
from app.services.marriage_validator import MarriageValidator
from app.services.event_retry_worker import get_event_retry_worker  # Import the missing dependency
from app.db.outbox_repo import OutboxRepository  # Import OutboxRepository
from app.schemas.marriage_certificate import MarriageCertificateCreate, MarriageCertificateResponse

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post(
    "/death-certificates",
    response_model=DeathCertificateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký Giấy chứng tử mới",
    description="Tiếp nhận thông tin, xác thực công dân với BCA, ghi vào DB BTP và gửi sự kiện Kafka.",
)
async def register_death_certificate(
    certificate_data: DeathCertificateCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_btp_db),
    bca_client: BCAClient = Depends(get_bca_client),
    kafka_producer: KafkaEventProducer = Depends(get_kafka_producer)
):
    logger.info(f"Received request to register death certificate for citizen: {certificate_data.citizen_id}")

    # Khởi tạo repository trước khi sử dụng
    repo = CivilStatusRepository(db)
    
    # Kiểm tra xem công dân đã có giấy chứng tử chưa
    if repo.check_existing_death_certificate(certificate_data.citizen_id):
        logger.warning(f"Citizen already has death certificate: {certificate_data.citizen_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {certificate_data.citizen_id} đã có giấy chứng tử trong hệ thống."
        )

    # 1. Validate citizen status with BCA Service
    try:
        validation_result = await bca_client.validate_citizen_status(certificate_data.citizen_id)
    except HTTPException as e:
        logger.error(f"Error validating citizen {certificate_data.citizen_id} with BCA: {e.detail}")
        # Ném lại lỗi từ bca_client để trả về cho client
        raise e

    if validation_result is None:
        logger.warning(f"Citizen validation failed: Citizen {certificate_data.citizen_id} not found in BCA.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Công dân với ID {certificate_data.citizen_id} không tồn tại trong hệ thống BCA."
        )

    if validation_result.death_status in ('Đã mất', 'Mất tích'):
        logger.warning(f"Citizen validation failed: Citizen {certificate_data.citizen_id} already deceased/missing.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {certificate_data.citizen_id} đã được ghi nhận là đã mất hoặc mất tích."
        )

    logger.info(f"Citizen {certificate_data.citizen_id} validation successful (status: {validation_result.death_status}). Proceeding with registration.")

    # 2. Create death certificate record in DB BTP using stored procedure
    try:
        new_certificate_id = repo.create_death_certificate(certificate_data)
        if new_certificate_id is None:
            logger.error("Failed to create death certificate record in DB_BTP (repo returned None).")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể tạo bản ghi khai tử trong cơ sở dữ liệu."
            )
        logger.info(f"Successfully created death certificate record with ID: {new_certificate_id}")
    except HTTPException as e:
         logger.error(f"Database error during death certificate creation: {e.detail}")
         # Ném lại lỗi từ repo
         raise e
    except Exception as e:
         logger.error(f"Unexpected error during death certificate creation: {e}", exc_info=True)
         raise HTTPException(
             status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
             detail=f"Lỗi không xác định khi tạo bản ghi khai tử: {str(e)}"
         )

    # Phần còn lại của hàm không thay đổi
    # ...

    # 3. (Optional) Get the full created record to return and send to Kafka
    #    Hiện tại repo chưa hỗ trợ lấy chi tiết, nên ta tự tạo response tạm
    # created_certificate = repo.get_death_certificate_by_id(new_certificate_id)
    # if not created_certificate:
    #     # Vẫn xem là thành công nhưng log warning và trả về dữ liệu gốc + ID
    #     logger.warning(f"Could not retrieve details for newly created certificate ID: {new_certificate_id}")
    #     # Tạo response tạm thời
    created_certificate_response = DeathCertificateResponse(
         **certificate_data.model_dump(),
         death_certificate_id=new_certificate_id,
         status=True, # Giả định status là active khi mới tạo
         created_at=datetime.now(timezone.utc).isoformat(), # Thời gian gần đúng
         updated_at=datetime.now(timezone.utc).isoformat()  # Thời gian gần đúng
     )

    # 4. Send event to Kafka in the background
    # Truyền đối tượng response vừa tạo (hoặc certificate_data + new_id)
    background_tasks.add_task(kafka_producer.send_citizen_died_event, created_certificate_response)
    logger.info(f"Added Kafka event sending task to background for certificate ID: {new_certificate_id}")

    # 5. Return success response
    return created_certificate_response


@router.get(
    "/death-certificates/{certificate_id}",
    response_model=DeathCertificateResponse,
    summary="Tra cứu Giấy chứng tử theo ID",
    description="Lấy thông tin chi tiết của Giấy chứng tử theo ID."
)
async def get_death_certificate(
    certificate_id: int,
    db: Session = Depends(get_btp_db)
):
    logger.info(f"Request to get death certificate with ID: {certificate_id}")
    
    repo = CivilStatusRepository(db)
    certificate = repo.get_death_certificate_by_id(certificate_id)
    
    if not certificate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy giấy chứng tử với ID {certificate_id}"
        )
    
    return certificate

@router.post(
    "/marriage-certificates",
    response_model=MarriageCertificateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký Giấy chứng nhận kết hôn mới",
    description="Tiếp nhận thông tin, xác thực cả hai công dân với BCA, kiểm tra điều kiện kết hôn, ghi vào DB BTP và gửi sự kiện Kafka.",
)
async def register_marriage_certificate(
    certificate_data: MarriageCertificateCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_btp_db),
    bca_client: BCAClient = Depends(get_bca_client),
    #kafka_producer: KafkaEventProducer = Depends(get_kafka_producer)
):
    logger.info(f"Received request to register marriage between citizens: {certificate_data.husband_id} and {certificate_data.wife_id}")

    repo = CivilStatusRepository(db)
    
    # 1. Validate citizens exist and are alive
    try:
        husband_validation = await bca_client.validate_citizen_status(certificate_data.husband_id)
        if not husband_validation:
            logger.warning(f"Husband validation failed: Citizen {certificate_data.husband_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy công dân (chồng) với ID {certificate_data.husband_id} trong hệ thống BCA."
            )
        
        if husband_validation.death_status in ('Đã mất', 'Mất tích'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Công dân (chồng) với ID {certificate_data.husband_id} không thể kết hôn (trạng thái: {husband_validation.death_status})"
            )
            
        wife_validation = await bca_client.validate_citizen_status(certificate_data.wife_id)
        if not wife_validation:
            logger.warning(f"Wife validation failed: Citizen {certificate_data.wife_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Không tìm thấy công dân (vợ) với ID {certificate_data.wife_id} trong hệ thống BCA."
            )
            
        if wife_validation.death_status in ('Đã mất', 'Mất tích'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Công dân (vợ) với ID {certificate_data.wife_id} không thể kết hôn (trạng thái: {wife_validation.death_status})"
            )
    except HTTPException as e:
        logger.error(f"Error validating citizens: {e.detail}")
        raise e

    # 2. Validate marriage requirements
    validator = MarriageValidator()
    is_valid, validation_error = await validator.validate_marriage(
        bca_client,
        certificate_data.husband_id,
        certificate_data.wife_id,
        certificate_data.husband_date_of_birth,
        certificate_data.wife_date_of_birth
    )
    
    if not is_valid:
        logger.warning(f"Marriage validation failed: {validation_error}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Không thỏa mãn điều kiện kết hôn: {validation_error}"
        )

    logger.info("Marriage validation passed. Proceeding with registration.")

    # 3. Create marriage certificate record in DB BTP
    try:
        # Begin database transaction
        transaction = db.begin_nested()  # Use nested transaction for finer control
        
        # 3. Create marriage certificate record in DB BTP
        try:
            new_certificate_id = repo.create_marriage_certificate(certificate_data)
            if new_certificate_id is None:
                logger.error("Failed to create marriage certificate record")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Không thể tạo bản ghi giấy chứng nhận kết hôn trong cơ sở dữ liệu."
                )
            logger.info(f"Successfully created marriage certificate with ID: {new_certificate_id}")
        except HTTPException:
            transaction.rollback()
            raise  # Re-throw the HTTP exception
        
        # 4. Create response object
        created_certificate_response = MarriageCertificateResponse(
            **certificate_data.model_dump(),
            marriage_certificate_id=new_certificate_id,
            status=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        
        # 5. Create outbox message in the same transaction
        try:
            outbox_repo = OutboxRepository(db)
            
            # Prepare event payload
            event_payload = {
                "eventType": "citizen_married",
                "payload": {
                    "marriage_certificate_id": new_certificate_id,
                    "marriage_certificate_no": certificate_data.marriage_certificate_no,
                    "husband_id": certificate_data.husband_id,
                    "wife_id": certificate_data.wife_id,
                    "marriage_date": certificate_data.marriage_date.isoformat(),
                    "registration_date": certificate_data.registration_date.isoformat(),
                    "issuing_authority_id": certificate_data.issuing_authority_id,
                    "status": True
                },
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            # Store in outbox
            outbox_id = outbox_repo.create_outbox_message(
                "MarriageCertificate",
                new_certificate_id,
                "citizen_married",
                created_certificate_response.model_dump()
            )
            
            logger.info(f"Created outbox message with ID: {outbox_id}")
            
            # Commit both certificate and outbox entries
            transaction.commit()
            db.commit()
            
        except Exception as e:
            transaction.rollback()
            logger.error(f"Error creating outbox message: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Lỗi lưu trữ sự kiện kết hôn. Vui lòng thử lại."
            )
        
        # 6. Return success response
        return created_certificate_response
        
    except Exception as e:
        if 'transaction' in locals() and transaction.is_active:
            transaction.rollback()
        logger.error(f"Unexpected error during marriage registration: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi không xác định: {str(e)}"
        )

@router.post(
    "/admin/retry-failed-events",
    status_code=status.HTTP_202_ACCEPTED,
    summary="Manually trigger retry of failed events",
    description="Admin endpoint to process failed events immediately rather than waiting for scheduled retry."
)
async def retry_failed_events(
    background_tasks: BackgroundTasks,
    retry_worker = Depends(get_event_retry_worker)
):
    # Run the retry processing in background
    background_tasks.add_task(retry_worker._process_failed_events)
    return {"message": "Event retry processing triggered"}
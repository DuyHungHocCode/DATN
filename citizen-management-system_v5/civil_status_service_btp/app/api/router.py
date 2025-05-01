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
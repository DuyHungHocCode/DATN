# civil_status_service_btp/app/api/router.py
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
import logging
from datetime import datetime, timezone
from typing import List, Dict, Any
from app.db.database import get_btp_db
from app.db.civil_status_repo import CivilStatusRepository
from app.schemas.death_certificate import DeathCertificateCreate, DeathCertificateResponse
from app.services.bca_client import BCAClient, get_bca_client
#from app.services.kafka_producer import KafkaEventProducer, get_kafka_producer
from app.services.marriage_validator import MarriageValidator
#from app.services.event_retry_worker import get_event_retry_worker  # Import the missing dependency
from app.db.outbox_repo import OutboxRepository  # Import OutboxRepository
from app.schemas.marriage_certificate import MarriageCertificateCreate, MarriageCertificateResponse
from app.schemas.death_certificate import DeathCertificateResponse 
from app.schemas.divorce_record import DivorceRecordCreate, DivorceRecordResponse 
from app.schemas.birth_certificate import BirthCertificateCreate, BirthCertificateResponse 


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
    #kafka_producer: KafkaEventProducer = Depends(get_kafka_producer)
):
    logger.info(f"Received request to register death certificate for citizen: {certificate_data.citizen_id}")

    # Khởi tạo repository trước khi sử dụng
    repo = CivilStatusRepository(db)
    outbox_repo = OutboxRepository(db)


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

        # Begin transaction
        transaction = db.begin_nested()
        
        new_certificate_id = repo.create_death_certificate(certificate_data)
        if new_certificate_id is None:
            transaction.rollback()
            logger.error("Failed to create death certificate record in DB_BTP.")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể tạo bản ghi khai tử trong cơ sở dữ liệu."
            )
        logger.info(f"Successfully created death certificate record with ID: {new_certificate_id}")

        # 3. Create outbox event for Debezium to capture
        outbox_payload = {
            "citizen_id": certificate_data.citizen_id,
            "date_of_death": certificate_data.date_of_death.isoformat(),
            "time_of_death": certificate_data.time_of_death.isoformat() if certificate_data.time_of_death else None,
            "place_of_death_detail": certificate_data.place_of_death_detail,
            "death_certificate_no": certificate_data.death_certificate_no,
            "registration_date": certificate_data.registration_date.isoformat(),
            "death_certificate_id": new_certificate_id,
            "cause_of_death": certificate_data.cause_of_death
        }

        outbox_id = outbox_repo.create_outbox_message(
            "DeathCertificate",
            str(new_certificate_id),
            "citizen_died",
            outbox_payload
        )

        # Commit transaction
        if transaction.is_active:
            transaction.commit()
        db.commit()
        
        logger.info(f"Created outbox event with ID: {outbox_id} for Debezium CDC")

    except HTTPException as e:
        if 'transaction' in locals() and transaction.is_active:
            transaction.rollback()
        db.rollback()
        raise e
    except Exception as e:
        if 'transaction' in locals() and transaction.is_active:
            transaction.rollback()
        db.rollback()
        logger.error(f"Unexpected error during death certificate creation: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi không xác định khi tạo bản ghi khai tử: {str(e)}"
        )

    
    # 4. Return response
    created_certificate_response = DeathCertificateResponse(
        **certificate_data.model_dump(),
        death_certificate_id=new_certificate_id,
        status=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )

    return created_certificate_response


@router.get(
    "/death-certificates/{certificate_id}",
    response_model=DeathCertificateResponse,
    summary="Tra cứu Giấy chứng tử theo ID",
    description="Lấy thông tin chi tiết của Giấy chứng tử theo ID."
)
async def get_death_certificate(
    certificate_id: int,
    db: Session = Depends(get_btp_db),
    bca_client: BCAClient = Depends(get_bca_client)
):
    logger.info(f"Request to get death certificate with ID: {certificate_id}")
    
    repo = CivilStatusRepository(db)
    death_cert_raw = repo.get_death_certificate_by_id(certificate_id)
    
    if not death_cert_raw:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy giấy chứng tử với ID {certificate_id}"
        )
    
    logger.info(f"Raw death certificate data: {death_cert_raw}")

    response_data = death_cert_raw.copy()

    # Bước 2: Chuẩn bị lấy dữ liệu tham chiếu từ BCA service
    ids_to_resolve = {
        "ward_id": response_data.get("place_of_death_ward_id"),
        "district_id": response_data.get("place_of_death_district_id"),
        "province_id": response_data.get("place_of_death_province_id"),
        "authority_id": response_data.get("issuing_authority_id")
    }

    logger.info(f"IDs to resolve: {ids_to_resolve}")

    reference_data = {}

    try:
        # Lấy dữ liệu Provinces nếu cần
        if ids_to_resolve["province_id"]:
            logger.info(f"Fetching Provinces data from BCA")
            provinces_data = await bca_client.get_reference_data(["Provinces"])
            reference_data["Provinces"] = provinces_data.get("Provinces", [])
            logger.info(f"Got {len(reference_data['Provinces'])} provinces")
        
        # Lấy dữ liệu Districts nếu cần
        if ids_to_resolve["district_id"]:
            logger.info(f"Fetching Districts data from BCA")
            districts_data = await bca_client.get_reference_data(["Districts"])
            reference_data["Districts"] = districts_data.get("Districts", [])
            logger.info(f"Got {len(reference_data['Districts'])} districts")
        
        # Lấy dữ liệu Wards nếu cần
        if ids_to_resolve["ward_id"]:
            logger.info(f"Fetching Wards data from BCA")
            wards_data = await bca_client.get_reference_data(["Wards"])
            reference_data["Wards"] = wards_data.get("Wards", [])
            logger.info(f"Got {len(reference_data['Wards'])} wards")
        
        # Lấy dữ liệu Authorities nếu cần
        if ids_to_resolve["authority_id"]:
            logger.info(f"Fetching Authorities data from BCA")
            authorities_data = await bca_client.get_reference_data(["Authorities"])
            reference_data["Authorities"] = authorities_data.get("Authorities", [])
            logger.info(f"Got {len(reference_data['Authorities'])} authorities")
            
    except Exception as e:
        logger.error(f"Error fetching reference data from BCA: {e}", exc_info=True)
        # Tiếp tục với dữ liệu đã có

    # Bước 4: Map ID sang tên
    # Map cho Province
    if reference_data.get("Provinces") and ids_to_resolve["province_id"]:
        for province in reference_data["Provinces"]:
            if province.get("province_id") == ids_to_resolve["province_id"]:
                response_data["place_of_death_province_name"] = province.get("province_name")
                logger.info(f"Mapped province {ids_to_resolve['province_id']} to {province.get('province_name')}")
                break
    
    # Map cho District
    if reference_data.get("Districts") and ids_to_resolve["district_id"]:
        for district in reference_data["Districts"]:
            if district.get("district_id") == ids_to_resolve["district_id"]:
                response_data["place_of_death_district_name"] = district.get("district_name")
                logger.info(f"Mapped district {ids_to_resolve['district_id']} to {district.get('district_name')}")
                break
    
    # Map cho Ward
    if reference_data.get("Wards") and ids_to_resolve["ward_id"]:
        for ward in reference_data["Wards"]:
            if ward.get("ward_id") == ids_to_resolve["ward_id"]:
                response_data["place_of_death_ward_name"] = ward.get("ward_name")
                logger.info(f"Mapped ward {ids_to_resolve['ward_id']} to {ward.get('ward_name')}")
                break
    
    # Map cho Authority
    if reference_data.get("Authorities") and ids_to_resolve["authority_id"]:
        for authority in reference_data["Authorities"]:
            if authority.get("authority_id") == ids_to_resolve["authority_id"]:
                response_data["issuing_authority_name"] = authority.get("authority_name")
                logger.info(f"Mapped authority {ids_to_resolve['authority_id']} to {authority.get('authority_name')}")
                break

    # Đảm bảo các trường name có giá trị mặc định nếu không map được
    response_data["place_of_death_province_name"] = response_data.get("place_of_death_province_name", "Không xác định")
    response_data["place_of_death_district_name"] = response_data.get("place_of_death_district_name", "Không xác định")
    response_data["place_of_death_ward_name"] = response_data.get("place_of_death_ward_name", "Không xác định")
    response_data["issuing_authority_name"] = response_data.get("issuing_authority_name", "Không xác định")

    # Đảm bảo các trường bắt buộc
    if "status" not in response_data:
        response_data["status"] = True

    # Log final response data
    logger.info(f"Final response data with names: {response_data}")

    # Validate và trả về
    try:
        return DeathCertificateResponse.model_validate(response_data)
    except Exception as e:
        logger.error(f"Error validating response: {e}", exc_info=True)
        logger.error(f"Response data causing error: {response_data}")
        raise HTTPException(
            status_code=500, 
            detail="Lỗi tạo response cho giấy chứng tử."
        )

            
@router.post(
    "/marriage-certificates",
    response_model=MarriageCertificateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký Giấy chứng nhận kết hôn mới",
    description="Tiếp nhận thông tin, xác thực cả hai công dân với BCA, kiểm tra điều kiện kết hôn, ghi vào DB BTP và gửi sự kiện Kafka.",
)
async def register_marriage_certificate(
    certificate_data: MarriageCertificateCreate,
    #background_tasks: BackgroundTasks,
    db: Session = Depends(get_btp_db),
    bca_client: BCAClient = Depends(get_bca_client),
    #kafka_producer: KafkaEventProducer = Depends(get_kafka_producer)
):
    logger.info(f"Received request to register marriage between citizens: {certificate_data.husband_id} and {certificate_data.wife_id}")

    repo = CivilStatusRepository(db)
    
    # Validate marriage requirements
    validator = MarriageValidator()
    is_valid, validation_errors = await validator.validate_marriage(
        bca_client,
        certificate_data.husband_id,
        certificate_data.wife_id,
        certificate_data.husband_date_of_birth,
        certificate_data.wife_date_of_birth
    )
    
    if not is_valid:
        logger.warning(f"Marriage validation failed: {validation_errors}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Không thỏa mãn điều kiện kết hôn: {validation_errors}"
        )

    logger.info("Marriage validation passed. Proceeding with registration.")

    try:
        # Begin database transaction
        transaction = db.begin_nested()  # Use nested transaction
        
        # 3. Create marriage certificate record in DB BTP
        try:
            new_certificate_id = repo.create_marriage_certificate(certificate_data)
            if new_certificate_id is None:
                transaction.rollback()
                logger.error("Failed to create marriage certificate record")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Không thể tạo bản ghi giấy chứng nhận kết hôn trong cơ sở dữ liệu."
                )
            logger.info(f"Successfully created marriage certificate with ID: {new_certificate_id}")
        
            # 4. Create response object
            created_certificate_response = MarriageCertificateResponse(
                **certificate_data.model_dump(),
                marriage_certificate_id=new_certificate_id,
                status=True,
                created_at=datetime.now(timezone.utc),
                updated_at=datetime.now(timezone.utc)
            )
            
            # 5. Create outbox message
            try:
                outbox_repo = OutboxRepository(db)
                
                # Chuẩn bị payload đơn giản hơn, chuyển đổi các đối tượng date thành string
                outbox_payload = {
                    "marriage_certificate_id": new_certificate_id,
                    "marriage_certificate_no": certificate_data.marriage_certificate_no,
                    "husband_id": certificate_data.husband_id,
                    "wife_id": certificate_data.wife_id,
                    "marriage_date": certificate_data.marriage_date.isoformat(),
                    "registration_date": certificate_data.registration_date.isoformat(),
                    "issuing_authority_id": certificate_data.issuing_authority_id,
                    "status": True
                }
                
                # Lưu vào outbox - đảm bảo transaction vẫn còn hoạt động
                outbox_id = outbox_repo.create_outbox_message(
                    "MarriageCertificate",
                    new_certificate_id,
                    "citizen_married",
                    outbox_payload
                )
                
                # Commit transaction nếu thành công
                if 'transaction' in locals() and transaction.is_active:
                    transaction.commit()
                db.commit()
                
                logger.info(f"Created outbox message with ID: {outbox_id}")
            except Exception as e:
                # Rollback transaction nếu có lỗi
                if 'transaction' in locals() and transaction.is_active:
                    transaction.rollback()
                db.rollback()  # Đảm bảo rollback session
                logger.error(f"Error creating outbox message: {e}", exc_info=True)
                
                # Tạo HTTP Exception
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Lỗi lưu trữ sự kiện kết hôn: {str(e)}"
                )
            
            # 6. Return success response
            return created_certificate_response
            
        except Exception as e:
            if transaction.is_active:
                transaction.rollback()
            logger.error(f"Error during marriage registration: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi: {str(e)}"
            )
            
    except Exception as e:
        logger.error(f"Unexpected error during marriage registration: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi không xác định: {str(e)}"
        )
        


@router.post(
    "/divorce-records",
    response_model=DivorceRecordResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký hồ sơ ly hôn mới",
    description="Tiếp nhận thông tin, xác thực công dân và giấy kết hôn với BCA, ghi vào DB BTP và gửi sự kiện Outbox.",
)
async def register_divorce_record(
    record_data: DivorceRecordCreate,
    db: Session = Depends(get_btp_db),
    bca_client: BCAClient = Depends(get_bca_client)
):
    logger.info(f"Received request to register divorce record for marriage ID: {record_data.marriage_certificate_id}")

    repo = CivilStatusRepository(db)
    outbox_repo = OutboxRepository(db)

    # 1. Lấy thông tin Giấy chứng nhận kết hôn từ BTP DB
    marriage_cert_details = repo.get_marriage_certificate_details(record_data.marriage_certificate_id)
    if not marriage_cert_details:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy giấy chứng nhận kết hôn với ID {record_data.marriage_certificate_id}."
        )
    
    if not marriage_cert_details['status']: # status = 0 (Dissolved/Annulled)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Giấy chứng nhận kết hôn ID {record_data.marriage_certificate_id} đã bị ly hôn/hủy bỏ trước đó."
        )
    
    husband_id = marriage_cert_details['husband_id']
    wife_id = marriage_cert_details['wife_id']
    
    # 2. Validate citizen status with BCA Service (cả chồng và vợ)
    try:
        validation_result = await bca_client.batch_validate_citizens(
            citizen_ids=[husband_id, wife_id],
            include_family_tree=False # Không cần cây phả hệ cho ly hôn
        )
    except HTTPException as e:
        logger.error(f"Error validating citizens for divorce: {e.detail}")
        raise e

    husband_validation = validation_result.get(husband_id, {}).get("validation", {})
    wife_validation = validation_result.get(wife_id, {}).get("validation", {})

    if not validation_result.get(husband_id, {}).get("found", False) or \
       husband_validation.get("death_status") in ('Đã mất', 'Mất tích'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân (chồng) với ID {husband_id} không hợp lệ (không tồn tại hoặc đã mất)."
        )
    
    if not validation_result.get(wife_id, {}).get("found", False) or \
       wife_validation.get("death_status") in ('Đã mất', 'Mất tích'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân (vợ) với ID {wife_id} không hợp lệ (không tồn tại hoặc đã mất)."
        )

    # Kiểm tra tình trạng hôn nhân hiện tại (phải là "Đã kết hôn")
    if husband_validation.get("marital_status") != "Đã kết hôn" or \
       husband_validation.get("spouse_citizen_id") != wife_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tình trạng hôn nhân của chồng ({husband_id}) không phải 'Đã kết hôn' với người vợ này."
        )
        
    if wife_validation.get("marital_status") != "Đã kết hôn" or \
       wife_validation.get("spouse_citizen_id") != husband_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tình trạng hôn nhân của vợ ({wife_id}) không phải 'Đã kết hôn' với người chồng này."
        )

    logger.info(f"Citizens {husband_id} and {wife_id} validation successful. Proceeding with divorce registration.")

    # 3. Tạo bản ghi ly hôn trong DB_BTP bằng Stored Procedure
    try:
        transaction = db.begin_nested()
        
        new_record_id = repo.create_divorce_record(record_data)
        if new_record_id is None:
            transaction.rollback()
            logger.error("Failed to create divorce record in DB_BTP.")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể tạo bản ghi ly hôn trong cơ sở dữ liệu."
            )
        logger.info(f"Successfully created divorce record with ID: {new_record_id}")

        # 4. Tạo sự kiện Outbox
        outbox_payload = {
            "divorce_record_id": new_record_id,
            "marriage_certificate_id": record_data.marriage_certificate_id,
            "husband_id": husband_id,
            "wife_id": wife_id,
            "divorce_date": record_data.divorce_date.isoformat(),
            "judgment_no": record_data.judgment_no,
            "registration_date": record_data.registration_date.isoformat()
        }

        outbox_id = outbox_repo.create_outbox_message(
            "DivorceRecord",
            str(new_record_id),
            "citizen_divorced",
            outbox_payload
        )
        
        if transaction.is_active:
            transaction.commit()
        db.commit() # Commit transaction của session

        logger.info(f"Created outbox event with ID: {outbox_id} for Debezium CDC")

    except HTTPException as e:
        if 'transaction' in locals() and transaction.is_active:
            transaction.rollback()
        db.rollback()
        raise e
    except Exception as e:
        if 'transaction' in locals() and transaction.is_active:
            transaction.rollback()
        db.rollback()
        logger.error(f"Unexpected error during divorce record creation: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi không xác định khi tạo bản ghi ly hôn: {str(e)}"
        )

    # 5. Trả về phản hồi
    created_record_response = DivorceRecordResponse(
        **record_data.model_dump(),
        divorce_record_id=new_record_id,
        status=True, # Mặc định là True khi mới tạo
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )

    return created_record_response


@router.post(
    "/birth-certificates",
    response_model=BirthCertificateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký Giấy khai sinh mới",
    description="Tiếp nhận thông tin, xác thực cha mẹ với BCA (nếu có), ghi vào DB BTP và gửi sự kiện Outbox.",
)
async def register_birth_certificate(
    certificate_data: BirthCertificateCreate,
    db: Session = Depends(get_btp_db),
    bca_client: BCAClient = Depends(get_bca_client),
):
    logger.info(f"Received request to register birth certificate for citizen: {certificate_data.citizen_id}")

    repo = CivilStatusRepository(db)
    outbox_repo = OutboxRepository(db)

    # 0. Kiểm tra xem trẻ sơ sinh đã có giấy khai sinh chưa
    if repo.check_existing_birth_certificate_for_citizen(certificate_data.citizen_id):
        logger.warning(f"Birth certificate already exists for citizen: {certificate_data.citizen_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {certificate_data.citizen_id} đã có giấy khai sinh trong hệ thống."
        )
    
    # 1. Validate parents (if provided) with BCA Service
    parent_ids_to_validate = []
    if certificate_data.father_citizen_id:
        parent_ids_to_validate.append(certificate_data.father_citizen_id)
    if certificate_data.mother_citizen_id:
        parent_ids_to_validate.append(certificate_data.mother_citizen_id)

    if parent_ids_to_validate:
        try:
            validation_results = await bca_client.batch_validate_citizens(
                citizen_ids=parent_ids_to_validate,
                include_family_tree=False # Không cần cây phả hệ cho bước này
            )
            
            for parent_id in parent_ids_to_validate:
                parent_info = validation_results.get(parent_id)
                if not parent_info or not parent_info.get("found"):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Công dân (cha/mẹ) với ID {parent_id} không tồn tại trong hệ thống BCA."
                    )
                parent_validation = parent_info.get("validation", {})
                if parent_validation.get("death_status") in ('Đã mất', 'Mất tích'):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Công dân (cha/mẹ) với ID {parent_id} đã được ghi nhận là đã mất hoặc mất tích."
                    )
            logger.info(f"Parents validation successful for: {', '.join(parent_ids_to_validate)}")

        except HTTPException as e:
            logger.error(f"Error validating parents with BCA: {e.detail}")
            raise e
        except Exception as e:
            logger.error(f"Unexpected error during parents validation: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi không xác định khi xác thực thông tin cha mẹ: {str(e)}"
            )

    # 2. Create birth certificate record in DB BTP using stored procedure
    try:
        transaction = db.begin_nested()
        
        new_certificate_id = repo.create_birth_certificate(certificate_data)
        if new_certificate_id is None:
            transaction.rollback()
            logger.error("Failed to create birth certificate record in DB_BTP.")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể tạo bản ghi khai sinh trong cơ sở dữ liệu."
            )
        logger.info(f"Successfully created birth certificate record with ID: {new_certificate_id}")

        # 3. Create outbox event for Debezium to capture
        outbox_payload = {
            "citizen_id": certificate_data.citizen_id,
            "full_name": certificate_data.full_name,
            "date_of_birth": certificate_data.date_of_birth.isoformat(),
            "gender_id": certificate_data.gender_id,
            "father_citizen_id": certificate_data.father_citizen_id,
            "mother_citizen_id": certificate_data.mother_citizen_id,
            "birth_certificate_id": new_certificate_id,
            "birth_certificate_no": certificate_data.birth_certificate_no
        }

        outbox_id = outbox_repo.create_outbox_message(
            "BirthCertificate",
            str(new_certificate_id),
            "citizen_birth_registered",
            outbox_payload
        )

        if transaction.is_active:
            transaction.commit()
        db.commit()
        
        logger.info(f"Created outbox event with ID: {outbox_id} for Debezium CDC")

    except HTTPException as e:
        if 'transaction' in locals() and transaction.is_active:
            transaction.rollback()
        db.rollback()
        raise e
    except Exception as e:
        if 'transaction' in locals() and transaction.is_active:
            transaction.rollback()
        db.rollback()
        logger.error(f"Unexpected error during birth certificate creation: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi không xác định khi tạo bản ghi khai sinh: {str(e)}"
        )
    
    # 4. Return response
    created_certificate_response = BirthCertificateResponse(
        **certificate_data.model_dump(),
        birth_certificate_id=new_certificate_id,
        status=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )

    return created_certificate_response

@router.get(
    "/birth-certificates/{certificate_id}",
    response_model=BirthCertificateResponse,
    summary="Tra cứu Giấy khai sinh theo ID",
    description="Lấy thông tin chi tiết của Giấy khai sinh theo ID."
)
async def get_birth_certificate(
    certificate_id: int,
    db: Session = Depends(get_btp_db),
    bca_client: BCAClient = Depends(get_bca_client)
):
    logger.info(f"Request to get birth certificate with ID: {certificate_id}")
    
    repo = CivilStatusRepository(db)
    birth_cert_raw = repo.get_birth_certificate_by_id(certificate_id)
    
    if not birth_cert_raw:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy giấy khai sinh với ID {certificate_id}"
        )
    
    logger.info(f"Raw birth certificate data: {birth_cert_raw}")

    response_data = birth_cert_raw.copy()

    # Bước 2: Chuẩn bị lấy dữ liệu tham chiếu từ BCA service
    ids_to_resolve = {
        "gender_id": response_data.get("gender_id"),
        "father_nationality_id": response_data.get("father_nationality_id"),
        "mother_nationality_id": response_data.get("mother_nationality_id"),
        "issuing_authority_id": response_data.get("issuing_authority_id")
    }

    logger.info(f"IDs to resolve: {ids_to_resolve}")

    reference_data = {}

    try:
        tables_to_fetch = []
        if ids_to_resolve["gender_id"]: tables_to_fetch.append("Genders")
        if ids_to_resolve["father_nationality_id"] or ids_to_resolve["mother_nationality_id"]: tables_to_fetch.append("Nationalities")
        if ids_to_resolve["issuing_authority_id"]: tables_to_fetch.append("Authorities")
        
        if tables_to_fetch:
            fetched_data = await bca_client.get_reference_data(tables_to_fetch)
            reference_data.update(fetched_data)
            logger.info(f"Fetched reference data for tables: {tables_to_fetch}")
            
    except Exception as e:
        logger.error(f"Error fetching reference data from BCA: {e}", exc_info=True)
        # Tiếp tục với dữ liệu đã có

    # Bước 4: Map ID sang tên
    # Map cho Gender
    if reference_data.get("Genders") and ids_to_resolve["gender_id"]:
        for gender in reference_data["Genders"]:
            if gender.get("gender_id") == ids_to_resolve["gender_id"]:
                response_data["gender_name"] = gender.get("gender_name_vi")
                logger.info(f"Mapped gender {ids_to_resolve['gender_id']} to {gender.get('gender_name_vi')}")
                break
    
    # Map cho Nationalities (cha và mẹ)
    if reference_data.get("Nationalities"):
        if ids_to_resolve["father_nationality_id"]:
            for nation in reference_data["Nationalities"]:
                if nation.get("nationality_id") == ids_to_resolve["father_nationality_id"]:
                    response_data["father_nationality_name"] = nation.get("nationality_name")
                    logger.info(f"Mapped father nationality {ids_to_resolve['father_nationality_id']} to {nation.get('nationality_name')}")
                    break
        if ids_to_resolve["mother_nationality_id"]:
            for nation in reference_data["Nationalities"]:
                if nation.get("nationality_id") == ids_to_resolve["mother_nationality_id"]:
                    response_data["mother_nationality_name"] = nation.get("nationality_name")
                    logger.info(f"Mapped mother nationality {ids_to_resolve['mother_nationality_id']} to {nation.get('nationality_name')}")
                    break
    
    # Map cho Authority
    if reference_data.get("Authorities") and ids_to_resolve["issuing_authority_id"]:
        for authority in reference_data["Authorities"]:
            if authority.get("authority_id") == ids_to_resolve["issuing_authority_id"]:
                response_data["issuing_authority_name"] = authority.get("authority_name")
                logger.info(f"Mapped authority {ids_to_resolve['issuing_authority_id']} to {authority.get('authority_name')}")
                break

    # Đảm bảo các trường name có giá trị mặc định nếu không map được
    response_data["gender_name"] = response_data.get("gender_name", "Không xác định")
    response_data["father_nationality_name"] = response_data.get("father_nationality_name", "Không xác định")
    response_data["mother_nationality_name"] = response_data.get("mother_nationality_name", "Không xác định")
    response_data["issuing_authority_name"] = response_data.get("issuing_authority_name", "Không xác định")

    # Đảm bảo các trường bắt buộc
    if "status" not in response_data:
        response_data["status"] = True

    # Log final response data
    logger.info(f"Final response data with names: {response_data}")

    # Validate và trả về
    try:
        return BirthCertificateResponse.model_validate(response_data)
    except Exception as e:
        logger.error(f"Error validating response: {e}", exc_info=True)
        logger.error(f"Response data causing error: {response_data}")
        raise HTTPException(
            status_code=500, 
            detail="Lỗi tạo response cho giấy khai sinh."
        )















# @router.post(
#     "/admin/retry-failed-events",
#     status_code=status.HTTP_202_ACCEPTED,
#     summary="Manually trigger retry of failed events",
#     description="Admin endpoint to process failed events immediately rather than waiting for scheduled retry."
# )
# async def retry_failed_events(
#     background_tasks: BackgroundTasks,
#     retry_worker = Depends(get_event_retry_worker)
# ):
#     # Run the retry processing in background
#     background_tasks.add_task(retry_worker._process_failed_events)
#     return {"message": "Event retry processing triggered"}
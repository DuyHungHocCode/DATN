from fastapi import APIRouter, Depends, HTTPException, Query, status, Body
from typing import List, Optional, Dict, Any
import json
from datetime import date
from sqlalchemy.orm import Session
import logging
from sqlalchemy import text
from app.schemas.household import HouseholdDetailResponse
from app.db.database import get_db
from app.db.citizen_repo import CitizenRepository
from app.schemas.citizen import CitizenSearch, CitizenResponse, CitizenValidationResponse
from app.schemas.residence import ResidenceHistoryResponse, ContactInfoResponse, PermanentResidenceOwnedPropertyCreate, PermanentResidenceRegistrationResponse
from app.schemas.family_tree import FamilyTreeResponse
from app.api.reference import router as reference_router


router = APIRouter()
logger = logging.getLogger(__name__)

router.include_router(reference_router)

@router.get("/citizens/{citizen_id}", response_model=CitizenResponse)
def get_citizen(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy thông tin chi tiết của một công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    citizen = repo.find_by_id(citizen_id)
    
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Citizen with ID {citizen_id} not found"
        )
    
    return citizen

@router.get("/citizens/{citizen_id}/validation", response_model=CitizenValidationResponse)
def validate_citizen(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Get essential citizen validation data for inter-service validation
    """
    repo = CitizenRepository(db)
    citizen = repo.find_by_id(citizen_id)
    
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Citizen with ID {citizen_id} not found"
        )
    
    return citizen

@router.get("/citizens/", response_model=List[CitizenResponse])
def search_citizens(
    full_name: Optional[str] = None,
    date_of_birth: Optional[date] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """
    Tìm kiếm danh sách công dân theo tên hoặc ngày sinh
    """
    repo = CitizenRepository(db)
    citizens = repo.search_citizens(full_name, date_of_birth, limit, offset)
    
    return citizens

@router.get("/citizens/{citizen_id}/residence-history", response_model=List[ResidenceHistoryResponse])
def get_citizen_residence_history(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy lịch sử cư trú của một công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    
    # Kiểm tra công dân tồn tại
    citizen = repo.find_by_id(citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy công dân với ID {citizen_id}"
        )
    
    # Lấy lịch sử cư trú
    residence_history = repo.get_residence_history(citizen_id)
    return residence_history

@router.get("/citizens/{citizen_id}/contact-info", response_model=ContactInfoResponse)
def get_citizen_contact_info(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy thông tin liên hệ của một công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    
    # Kiểm tra công dân tồn tại
    citizen = repo.find_by_id(citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy công dân với ID {citizen_id}"
        )
    
    # Lấy thông tin liên hệ
    contact_info = repo.get_contact_info(citizen_id)
    if not contact_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy thông tin liên hệ cho công dân với ID {citizen_id}"
        )
    
    return contact_info

@router.get("/citizens/{citizen_id}/family-tree", response_model=FamilyTreeResponse)
def get_citizen_family_tree(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy cây phả hệ 3 đời của công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    
    # Kiểm tra công dân tồn tại
    citizen = repo.find_by_id(citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy công dân với ID {citizen_id}"
        )
    
    # Lấy thông tin phả hệ
    family_members = repo.get_family_tree(citizen_id)
    
    return {
        "citizen_id": citizen_id,
        "family_members": family_members
    }

@router.post("/citizens/batch-validate", response_model=Dict[str, Any])
def batch_validate_citizens(
    request_data: Dict[str, Any] = Body(...),
    db: Session = Depends(get_db)
):
    """
    Batch validate multiple citizens with optional family tree in a single request
    """
    # Kiểm tra định dạng request
    print(f"DEBUG - Received batch validate request: {json.dumps(request_data)}")
    
    # Đảm bảo citizen_ids là một danh sách
    citizen_ids = request_data.get("citizen_ids", [])
    include_family_tree = request_data.get("include_family_tree", False)
    
    if not isinstance(citizen_ids, list):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="citizen_ids must be a list"
        )
    
    repo = CitizenRepository(db)
    result = {}
    
    for citizen_id in citizen_ids:
        # Get basic validation data
        citizen = repo.find_by_id(citizen_id)
        if not citizen:
            result[citizen_id] = {"found": False}
            continue
        
        # Build response
        citizen_data = {
            "found": True,
            "validation": {
                "citizen_id": citizen["citizen_id"],
                "full_name": citizen["full_name"],
                "date_of_birth": citizen["date_of_birth"],
                "gender": citizen["gender"],
                "death_status": citizen["citizen_status"],
                "marital_status": citizen["marital_status"],
                "spouse_citizen_id": citizen["spouse_citizen_id"]
            }
        }
        
        # Add family tree if requested
        if include_family_tree:
            family_tree = repo.get_family_tree(citizen_id)
            citizen_data["family_tree"] = {
                "citizen_id": citizen_id,
                "family_members": family_tree
            }
        
        result[citizen_id] = citizen_data
    
    return result

@router.post(
    "/residence-registrations/owned-property",
    response_model=PermanentResidenceRegistrationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký thường trú cho công dân sở hữu chỗ ở hợp pháp",
    description="Tiếp nhận thông tin đăng ký thường trú khi công dân có quyền sở hữu chỗ ở hợp pháp. Thực hiện xác thực và ghi dữ liệu vào các bảng liên quan.",
)
def register_permanent_residence_owned_property(
    request_data: PermanentResidenceOwnedPropertyCreate,
    db: Session = Depends(get_db)
):
    logger.info(f"Received request to register permanent residence for citizen: {request_data.citizen_id} at {request_data.address_detail}")

    repo = CitizenRepository(db)

    # 1. Xác thực công dân: Tồn tại và còn sống
    citizen = repo.find_by_id(request_data.citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Công dân với ID {request_data.citizen_id} không tồn tại."
        )
    
    # Giả định 'Còn sống' có citizen_status_id là 1 (từ Reference.CitizenStatusTypes)
    # Cần đảm bảo logic này khớp với dữ liệu reference thực tế
    if citizen.get("citizen_status") != "Còn sống":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {request_data.citizen_id} hiện không ở trạng thái 'Còn sống' và không thể đăng ký thường trú."
        )
    
    # 2. Xác thực Giấy chứng nhận quyền sở hữu
    # Để đơn giản, chúng ta sẽ giả định có một cách để kiểm tra OwnershipCertificate
    # Trong môi trường thực tế, đây có thể là một API call tới TNMT Service hoặc truy vấn trực tiếp bảng TNMT.OwnershipCertificate
    # Hiện tại, chúng ta sẽ truy vấn trực tiếp bảng TNMT.OwnershipCertificate trong DB_BCA
    try:
        ownership_cert_query = text("""
            SELECT [owner_citizen_id], [status], [property_address_id]
            FROM [TNMT].[OwnershipCertificate]
            WHERE [certificate_id] = :ownership_certificate_id
        """)
        ownership_cert_result = db.execute(ownership_cert_query, {"ownership_certificate_id": request_data.ownership_certificate_id}).fetchone()

        if not ownership_cert_result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Giấy chứng nhận quyền sở hữu với ID {request_data.ownership_certificate_id} không tồn tại."
            )
        
        owner_citizen_id_from_cert = ownership_cert_result[0] # owner_citizen_id
        ownership_cert_status = ownership_cert_result[1]      # status (BIT)
        property_address_id_from_cert = ownership_cert_result[2] # property_address_id

        if not ownership_cert_status: # status = 0 (Đã hủy/Thu hồi)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Giấy chứng nhận quyền sở hữu với ID {request_data.ownership_certificate_id} không còn hiệu lực."
            )
        
        if owner_citizen_id_from_cert != request_data.citizen_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Công dân {request_data.citizen_id} không phải là chủ sở hữu của giấy chứng nhận quyền sở hữu này (chủ sở hữu trên giấy: {owner_citizen_id_from_cert})."
            )
        
        # Tùy chọn: Kiểm tra property_address_id trên giấy chứng nhận có khớp với địa chỉ đăng ký không
        # Logic này phức tạp hơn vì cần tìm address_id của địa chỉ mới đăng ký.
        # Để đơn giản, chúng ta sẽ bỏ qua kiểm tra này ở đây và giả định SP sẽ xử lý việc tạo/tìm address_id.
        # Nếu cần kiểm tra chặt chẽ, có thể cần một hàm riêng để lấy address_id từ chi tiết địa chỉ.
        # 2.1. KIỂM TRA KHỚP ĐỊA CHỈ GCNQS VÀ ĐỊA CHỈ ĐĂNG KÝ
        if property_address_id_from_cert is None:
                raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Giấy chứng nhận quyền sở hữu ID {request_data.ownership_certificate_id} không có thông tin địa chỉ tài sản (property_address_id is NULL)."
            )
        
        is_address_matched = repo.check_address_match(
                property_address_id_from_cert,
                request_data.address_detail,
                request_data.ward_id,
                request_data.district_id,
                request_data.province_id
            )

        if not is_address_matched:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Địa chỉ tài sản trên Giấy chứng nhận quyền sở hữu (ID GCNQS: {request_data.ownership_certificate_id}, Address ID tài sản: {property_address_id_from_cert}) không khớp với địa chỉ đang đăng ký thường trú."
                )
          
    except HTTPException as e:
        raise e # Ném lại các lỗi đã được xử lý
    except Exception as e:
        logger.error(f"Error validating ownership certificate {request_data.ownership_certificate_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi khi xác thực giấy chứng nhận quyền sở hữu: {str(e)}"
        )

    logger.info("Citizen and ownership validation successful. Proceeding with registration.")

    # 3. Gọi Repository để ghi dữ liệu bằng Stored Procedure
    try:
        # Chuyển Pydantic model thành dictionary để truyền vào repository
        data_to_sp = request_data.model_dump()
        
        new_residence_history_id = repo.register_permanent_residence_owned_property(data_to_sp)
        
        return PermanentResidenceRegistrationResponse(
            new_residence_history_id=new_residence_history_id,
            citizen_id=request_data.citizen_id,
            address_detail=request_data.address_detail,
            registration_date=request_data.registration_date
        )
    except HTTPException as e:
        raise e # Ném lại lỗi từ repository
    except Exception as e:
        logger.error(f"Unexpected error during permanent residence registration: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Lỗi không xác định khi đăng ký thường trú: {str(e)}"
        )

@router.get(
    "/households/{household_id}",
    response_model=HouseholdDetailResponse,
    summary="Lấy thông tin chi tiết Sổ Hộ Khẩu",
    description="Trả về thông tin chi tiết của một Sổ Hộ Khẩu, bao gồm thông tin chung và danh sách các thành viên."
)
def get_household_details(
    household_id: int,
    db: Session = Depends(get_db)
):
    """
    Lấy thông tin chi tiết của một Sổ Hộ Khẩu theo `household_id`.
    """
    logger.info(f"Yêu cầu lấy chi tiết hộ khẩu ID: {household_id}")
    repo = CitizenRepository(db)
    household_details = repo.get_household_details_by_id(household_id)

    if not household_details:
        logger.warning(f"Không tìm thấy hộ khẩu với ID: {household_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy Sổ Hộ Khẩu với ID {household_id}"
        )
    
    logger.info(f"Trả về chi tiết hộ khẩu ID: {household_id} thành công.")
    return household_details

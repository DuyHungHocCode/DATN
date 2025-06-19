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
from app.schemas.household_change import HouseholdAddMemberRequest, HouseholdTransferMemberRequest, HouseholdRemoveMemberRequest, HouseholdChangeResponse
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
    db: Session = Depends(get_db)
):
    """
    Tìm kiếm danh sách công dân theo tên hoặc ngày sinh
    """
    repo = CitizenRepository(db)
    citizens = repo.search_citizens(full_name, date_of_birth, limit)
    
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


@router.post(
    "/households/add-member",
    response_model=HouseholdChangeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Nhập hộ khẩu cho công dân chưa có hộ khẩu",
    description="Thực hiện nghiệp vụ thêm một công dân (chưa có hộ khẩu) vào một hộ khẩu đã tồn tại"
)
def add_member_to_household(
    request_data: HouseholdAddMemberRequest,
    db: Session = Depends(get_db)
):
    """
    Tổ chức lại endpoint theo cấu trúc:
    1.  Khối kiểm tra và xác thực nghiệp vụ (Validation Block).
    2.  Khối thực thi và ghi dữ liệu (Execution Block).
    """
    repo = CitizenRepository(db)
    logger.info(f"Yêu cầu nhập hộ khẩu cho công dân {request_data.citizen_id} vào hộ khẩu {request_data.to_household_id}")

    # --------------------------------------------------------------------------
    # KHỐI 1: KIỂM TRA VÀ XÁC THỰC NGHIỆP VỤ (VALIDATION BLOCK)
    # Tạm thời để trống theo yêu cầu. Logic xác thực sẽ được thêm vào đây.
    # --------------------------------------------------------------------------
    
    
    household = repo.find_household_by_id(request_data.to_household_id)
    if not household:
        logger.warning(f"Validation failed: Destination household with ID {request_data.to_household_id} not found.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hộ khẩu đích với ID {request_data.to_household_id} không tồn tại."
        )
    if household.get("household_status") != "Đang hoạt động":
        logger.warning(f"Validation failed: Destination household with ID {request_data.to_household_id} is not active.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Hộ khẩu đích với ID {request_data.to_household_id} không hợp lệ hoặc không đang ở trạng thái hoạt động."
        )
    logger.info(f"Destination household {request_data.to_household_id} validation passed.")

    citizen = repo.find_by_id(request_data.citizen_id)
    if not citizen:
        logger.warning(f"Validation failed: Citizen with ID {request_data.citizen_id} not found.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Công dân với ID {request_data.citizen_id} không tồn tại."
        )

    # Giả định 'Còn sống' là giá trị chuỗi trả về từ DB Function
    if citizen.get("citizen_status") != "Còn sống":
        logger.warning(f"Validation failed: Citizen {request_data.citizen_id} is not alive. Status: {citizen.get('citizen_status')}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {request_data.citizen_id} không hợp lệ hoặc đã qua đời."
        )
    logger.info(f"Citizen {request_data.citizen_id} validation passed.")

    
    is_already_member = repo.is_citizen_in_active_household(request_data.citizen_id)
    if is_already_member:
        logger.warning(f"Validation failed: Citizen {request_data.citizen_id} is already an active member of a household.")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Công dân với ID {request_data.citizen_id} đã là thành viên của một hộ khẩu khác. Vui lòng sử dụng chức năng Chuyển hộ khẩu."
        )
    logger.info(f"Prerequisite check for citizen {request_data.citizen_id} passed.")
    
    # 4. Xác thực các ID tham chiếu khác
    # Validation relationship_with_head_id với logic 3 cấp độ
    relationship_validation = repo._validate_relationship_with_head_id(
        request_data.citizen_id, 
        request_data.to_household_id, 
        request_data.relationship_with_head_id
    )
    
    if not relationship_validation['is_valid']:
        # Determine HTTP status code based on error type
        status_code = status.HTTP_400_BAD_REQUEST
        if relationship_validation['error_code'] in ['DUPLICATE_HEAD_OF_HOUSEHOLD', 'DUPLICATE_SPOUSE', 'INVALID_GENDER_RELATIONSHIP']:
            status_code = status.HTTP_409_CONFLICT
            
        logger.warning(f"Relationship validation failed: {relationship_validation['error_code']} - {relationship_validation['error_message']}")
        raise HTTPException(
            status_code=status_code,
            detail=relationship_validation['error_message']
        )
    
    # Log warning if exists but still allow to proceed
    if relationship_validation['warning_message']:
        logger.warning(f"Relationship validation warning: {relationship_validation['warning_message']}")
    
    logger.info(f"Relationship validation passed for citizen {request_data.citizen_id} -> household {request_data.to_household_id}")
    
    # Kiểm tra issuing_authority_id có tồn tại trong bảng Reference.Authorities không.
    if not repo._validate_authority_id(request_data.issuing_authority_id):
        logger.warning(f"Validation failed: Invalid issuing_authority_id {request_data.issuing_authority_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Mã cơ quan cấp {request_data.issuing_authority_id} không hợp lệ hoặc không hoạt động."
        )
    
    logger.info("Xác thực nghiệp vụ thành công. Bắt đầu ghi dữ liệu.")
    
    # --------------------------------------------------------------------------
    # KHỐI 2: THỰC THI VÀ GHI DỮ LIỆU (EXECUTION BLOCK)
    # Gọi repository để thực thi Stored Procedure.
    # --------------------------------------------------------------------------
    
    try:
        # Gọi phương thức trong repository, phương thức này sẽ gọi Stored Procedure
        result = repo.add_household_member(request_data)
        logger.info(f"Nhập hộ khẩu thành công. Log ID: {result.log_id}")
        return result
    except ValueError as e:
        # Lỗi logic nghiệp vụ được ném từ tầng repo (nếu có)
        logger.warning(f"Lỗi nghiệp vụ khi nhập hộ khẩu: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        # Các lỗi khác, thường là lỗi DB từ Stored Procedure
        logger.error(f"Lỗi cơ sở dữ liệu khi nhập hộ khẩu: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Đã xảy ra lỗi không mong muốn khi ghi dữ liệu nhập hộ khẩu: {str(e)}"
        )


@router.post(
    "/households/transfer-member",
    response_model=HouseholdChangeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Chuyển hộ khẩu cho công dân",
    description="Thực hiện nghiệp vụ chuyển một công dân từ hộ khẩu này sang hộ khẩu khác."
)
def transfer_household_member(
    request_data: HouseholdTransferMemberRequest,
    db: Session = Depends(get_db)
):
    """
    Tổ chức endpoint theo cấu trúc tương tự add_member_to_household:
    1. Khối kiểm tra và xác thực nghiệp vụ (Validation Block).
    2. Khối thực thi và ghi dữ liệu (Execution Block).
    """
    repo = CitizenRepository(db)
    logger.info(f"Yêu cầu chuyển hộ khẩu cho công dân {request_data.citizen_id} từ hộ khẩu {request_data.from_household_id} sang hộ khẩu {request_data.to_household_id}")

    # --------------------------------------------------------------------------
    # KHỐI 1: KIỂM TRA VÀ XÁC THỰC NGHIỆP VỤ (VALIDATION BLOCK)
    # --------------------------------------------------------------------------

    # 1. Kiểm tra hộ khẩu nguồn
    from_household = repo.find_household_by_id(request_data.from_household_id)
    if not from_household:
        logger.warning(f"Validation failed: Source household with ID {request_data.from_household_id} not found.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hộ khẩu nguồn với ID {request_data.from_household_id} không tồn tại."
        )
    if from_household.get("household_status") != "Đang hoạt động":
        logger.warning(f"Validation failed: Source household with ID {request_data.from_household_id} is not active.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Hộ khẩu nguồn với ID {request_data.from_household_id} không hợp lệ hoặc không đang ở trạng thái hoạt động."
        )
    logger.info(f"Source household {request_data.from_household_id} validation passed.")

    # 2. Kiểm tra hộ khẩu đích
    to_household = repo.find_household_by_id(request_data.to_household_id)
    if not to_household:
        logger.warning(f"Validation failed: Destination household with ID {request_data.to_household_id} not found.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hộ khẩu đích với ID {request_data.to_household_id} không tồn tại."
        )
    if to_household.get("household_status") != "Đang hoạt động":
        logger.warning(f"Validation failed: Destination household with ID {request_data.to_household_id} is not active.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Hộ khẩu đích với ID {request_data.to_household_id} không hợp lệ hoặc không đang ở trạng thái hoạt động."
        )
    logger.info(f"Destination household {request_data.to_household_id} validation passed.")

    # 3. Kiểm tra công dân
    citizen = repo.find_by_id(request_data.citizen_id)
    if not citizen:
        logger.warning(f"Validation failed: Citizen with ID {request_data.citizen_id} not found.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Công dân với ID {request_data.citizen_id} không tồn tại."
        )

    if citizen.get("citizen_status") != "Còn sống":
        logger.warning(f"Validation failed: Citizen {request_data.citizen_id} is not alive. Status: {citizen.get('citizen_status')}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {request_data.citizen_id} không hợp lệ hoặc đã qua đời."
        )
    logger.info(f"Citizen {request_data.citizen_id} validation passed.")

    # 4. Kiểm tra công dân có phải là thành viên của hộ khẩu nguồn không
    is_member_of_source = repo.is_citizen_member_of_household(request_data.citizen_id, request_data.from_household_id)
    if not is_member_of_source:
        logger.warning(f"Validation failed: Citizen {request_data.citizen_id} is not a member of source household {request_data.from_household_id}.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {request_data.citizen_id} không phải là thành viên của hộ khẩu nguồn {request_data.from_household_id}."
        )
    logger.info(f"Citizen membership in source household validation passed.")

    # 5. Xác thực các ID tham chiếu khác
    # Validation relationship_with_head_id với logic 3 cấp độ
    relationship_validation = repo._validate_relationship_with_head_id(
        request_data.citizen_id, 
        request_data.to_household_id, 
        request_data.relationship_with_head_id
    )
    
    if not relationship_validation['is_valid']:
        # Determine HTTP status code based on error type
        status_code = status.HTTP_400_BAD_REQUEST
        if relationship_validation['error_code'] in ['DUPLICATE_HEAD_OF_HOUSEHOLD', 'DUPLICATE_SPOUSE', 'INVALID_GENDER_RELATIONSHIP']:
            status_code = status.HTTP_409_CONFLICT
            
        logger.warning(f"Relationship validation failed: {relationship_validation['error_code']} - {relationship_validation['error_message']}")
        raise HTTPException(
            status_code=status_code,
            detail=relationship_validation['error_message']
        )
    
    # Log warning if exists but still allow to proceed
    if relationship_validation['warning_message']:
        logger.warning(f"Relationship validation warning: {relationship_validation['warning_message']}")
    
    logger.info(f"Relationship validation passed for citizen {request_data.citizen_id} -> household {request_data.to_household_id}")

    if not repo._validate_authority_id(request_data.issuing_authority_id):
        logger.warning(f"Validation failed: Invalid issuing_authority_id {request_data.issuing_authority_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Mã cơ quan cấp {request_data.issuing_authority_id} không hợp lệ hoặc không hoạt động."
        )

    logger.info("Xác thực nghiệp vụ thành công. Bắt đầu ghi dữ liệu.")

    # --------------------------------------------------------------------------
    # KHỐI 2: THỰC THI VÀ GHI DỮ LIỆU (EXECUTION BLOCK)
    # Gọi repository để thực thi Stored Procedure.
    # --------------------------------------------------------------------------

    try:
        # Gọi phương thức trong repository, phương thức này sẽ gọi Stored Procedure
        result = repo.transfer_household_member(request_data)
        logger.info(f"Chuyển hộ khẩu thành công. Log ID: {result.log_id}")
        return result
    except ValueError as e:
        # Lỗi logic nghiệp vụ được ném từ tầng repo (nếu có)
        logger.warning(f"Lỗi nghiệp vụ khi chuyển hộ khẩu: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        # Các lỗi khác, thường là lỗi DB từ Stored Procedure
        logger.error(f"Lỗi cơ sở dữ liệu khi chuyển hộ khẩu: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Đã xảy ra lỗi không mong muốn khi ghi dữ liệu chuyển hộ khẩu: {str(e)}"
        )

@router.delete(
    "/households/{household_id}/members/{citizen_id}",
    response_model=HouseholdChangeResponse,
    status_code=status.HTTP_200_OK,
    summary="Xóa thành viên khỏi hộ khẩu",
    description="Thực hiện nghiệp vụ xóa một thành viên khỏi hộ khẩu (soft delete)"
)
def remove_household_member(
    household_id: int,
    citizen_id: str,
    request_data: HouseholdRemoveMemberRequest,
    db: Session = Depends(get_db)
):
    """
    Tổ chức endpoint theo cấu trúc:
    1. Khối kiểm tra và xác thực nghiệp vụ (Validation Block).
    2. Khối thực thi và ghi dữ liệu (Execution Block).
    """
    repo = CitizenRepository(db)
    logger.info(f"Yêu cầu xóa công dân {citizen_id} khỏi hộ khẩu {household_id}")

    # --------------------------------------------------------------------------
    # KHỐI 1: KIỂM TRA VÀ XÁC THỰC NGHIỆP VỤ (VALIDATION BLOCK)
    # --------------------------------------------------------------------------

    # 1. Kiểm tra hộ khẩu có tồn tại và đang hoạt động không
    household = repo.find_household_by_id(household_id)
    if not household:
        logger.warning(f"Validation failed: Household with ID {household_id} not found.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Hộ khẩu với ID {household_id} không tồn tại."
        )
    if household.get("household_status") != "Đang hoạt động":
        logger.warning(f"Validation failed: Household with ID {household_id} is not active.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Hộ khẩu với ID {household_id} không hợp lệ hoặc không đang ở trạng thái hoạt động."
        )
    logger.info(f"Household {household_id} validation passed.")

    # 2. Kiểm tra công dân có tồn tại và còn sống không
    citizen = repo.find_by_id(citizen_id)
    if not citizen:
        logger.warning(f"Validation failed: Citizen with ID {citizen_id} not found.")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Công dân với ID {citizen_id} không tồn tại."
        )

    if citizen.get("citizen_status") != "Còn sống":
        logger.warning(f"Validation failed: Citizen {citizen_id} is not alive. Status: {citizen.get('citizen_status')}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {citizen_id} không hợp lệ hoặc đã qua đời."
        )
    logger.info(f"Citizen {citizen_id} validation passed.")

    # 3. Kiểm tra công dân có phải là thành viên đang hoạt động của hộ khẩu này không
    is_member_of_household = repo.is_citizen_member_of_household(citizen_id, household_id)
    if not is_member_of_household:
        logger.warning(f"Validation failed: Citizen {citizen_id} is not an active member of household {household_id}.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Công dân với ID {citizen_id} không phải là thành viên đang hoạt động của hộ khẩu {household_id}."
        )
    logger.info(f"Citizen membership validation passed.")

    # 4. KIỂM TRA QUY TẮC VÀNG: XỬ LÝ TRƯỜNG HỢP CHỦ HỘ
    # Kiểm tra xem công dân có phải là chủ hộ không (relationship_with_head_id = 1)
    is_head_of_household = repo.is_citizen_head_of_household(citizen_id, household_id)
    if is_head_of_household:
        # Đếm số thành viên khác còn lại trong hộ khẩu (đang hoạt động, không tính chủ hộ)
        remaining_members_count = repo.count_active_household_members_excluding_citizen(household_id, citizen_id)
        
        if remaining_members_count > 0:
            logger.warning(f"Cannot remove head of household: {remaining_members_count} active members remain in household {household_id}")
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Không thể xóa chủ hộ khi vẫn còn các thành viên khác trong hộ khẩu. Vui lòng thực hiện nghiệp vụ 'Thay đổi chủ hộ' để chỉ định một chủ hộ mới trước."
            )
        
        logger.info(f"Head of household can be removed: no other active members in household {household_id}")
    
    logger.info(f"Head of household validation passed.")

    # 5. Kiểm tra issuing_authority_id có hợp lệ không
    if not repo._validate_authority_id(request_data.issuing_authority_id):
        logger.warning(f"Validation failed: Invalid issuing_authority_id {request_data.issuing_authority_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Mã cơ quan cấp {request_data.issuing_authority_id} không hợp lệ hoặc không hoạt động."
        )

    logger.info("Xác thực nghiệp vụ thành công. Bắt đầu ghi dữ liệu.")

    # --------------------------------------------------------------------------
    # KHỐI 2: THỰC THI VÀ GHI DỮ LIỆU (EXECUTION BLOCK)
    # Gọi repository để thực thi Stored Procedure.
    # --------------------------------------------------------------------------

    try:
        # Gọi phương thức trong repository, phương thức này sẽ gọi Stored Procedure
        result = repo.remove_household_member(household_id, citizen_id, request_data)
        logger.info(f"Xóa thành viên hộ khẩu thành công. Log ID: {result.log_id}")
        return result
    except ValueError as e:
        # Lỗi logic nghiệp vụ được ném từ tầng repo (nếu có)
        logger.warning(f"Lỗi nghiệp vụ khi xóa thành viên hộ khẩu: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        # Các lỗi khác, thường là lỗi DB từ Stored Procedure
        logger.error(f"Lỗi cơ sở dữ liệu khi xóa thành viên hộ khẩu: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Đã xảy ra lỗi không mong muốn khi ghi dữ liệu xóa thành viên hộ khẩu: {str(e)}"
        )

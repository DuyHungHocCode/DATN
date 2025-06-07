# citizen_service_bca/app/schemas/household.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime

class HouseholdMemberDetailResponse(BaseModel):
    citizen_id: str
    full_name: str
    relationship_with_head: str # Tên quan hệ đã được giải nghĩa
    join_date: date
    member_status: str # Tên trạng thái thành viên đã được giải nghĩa
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None # Tên giới tính đã được giải nghĩa
    # Thêm các trường khác của thành viên nếu cần

    model_config = {
        "from_attributes": True
    }

class HouseholdDetailResponse(BaseModel):
    household_id: int
    household_book_no: str
    head_of_household_id: str
    head_of_household_full_name: str
    
    address_detail: str
    ward_name: str
    district_name: str
    province_name: str
    
    registration_date: date
    issuing_authority_name: Optional[str] = None # Tên cơ quan cấp đã được giải nghĩa
    household_type_name: str # Tên loại hộ khẩu đã được giải nghĩa
    household_status_name: str # Tên trạng thái hộ khẩu đã được giải nghĩa
    
    ownership_certificate_id: Optional[int] = None # Logical FK to TNMT.OwnershipCertificate
    rental_contract_id: Optional[int] = None # Logical FK to TNMT.RentalContract
    notes: Optional[str] = None
    
    members: List[HouseholdMemberDetailResponse] = []

    created_at: datetime
    updated_at: datetime

    model_config = {
        "from_attributes": True
    }
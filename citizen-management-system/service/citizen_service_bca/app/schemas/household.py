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
    # Core household info
    household_id: int
    household_book_no: str
    head_of_household_id: Optional[str] = None
    head_of_household_name: Optional[str] = None # Can be null if citizen not found
    full_address: Optional[str] = None          # Can be null if address not found
    
    # Detailed address parts, can be null
    ward_name: Optional[str] = None
    district_name: Optional[str] = None
    province_name: Optional[str] = None
    
    # Other details, can be null
    registration_date: Optional[date] = None
    area_code: Optional[str] = None
    household_type: Optional[str] = None
    household_status: Optional[str] = None
    issuing_authority: Optional[str] = None
    
    # Timestamps
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    # Member list
    members: List[HouseholdMemberDetailResponse] = []

    model_config = {
        "from_attributes": True
    }
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date

class ResidenceHistoryResponse(BaseModel):
    record_type: str
    residence_type: str
    record_id: int
    address_detail: Optional[str] = None
    ward_name: Optional[str] = None
    district_name: Optional[str] = None
    province_name: Optional[str] = None
    destination_detail: Optional[str] = None
    start_date: Optional[datetime] = None          # Đổi từ date sang datetime
    end_date: Optional[datetime] = None            # Đổi từ date sang datetime
    is_current_permanent_residence: bool
    is_current_temporary_residence: bool
    is_temporary_absence: bool
    is_current_address: bool
    is_accommodation: bool
    reason: Optional[str] = None
    deregistration_date: Optional[datetime] = None # Đổi từ date sang datetime
    record_status: str
    host_name: Optional[str] = None
    host_citizen_id: Optional[str] = None
    host_relationship: Optional[str] = None
    issuing_authority: Optional[str] = None
    verification_status: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        orm_mode = True

class ContactInfoResponse(BaseModel):
    citizen_id: str
    phone_number: Optional[str] = None
    email: Optional[str] = None
    full_name: str
    current_address_detail: Optional[str] = None
    current_ward_name: Optional[str] = None
    current_district_name: Optional[str] = None
    current_province_name: Optional[str] = None
    
    class Config:
        orm_mode = True
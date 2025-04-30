from pydantic import BaseModel, Field, field_validator
from typing import Optional, Any
from datetime import date, time, datetime

class DeathCertificateBase(BaseModel):
    citizen_id: str = Field(..., max_length=12, description="ID CCCD/CMND của người mất")
    death_certificate_no: str = Field(..., max_length=20, description="Số giấy chứng tử")
    book_id: Optional[str] = Field(None, max_length=20, description="Quyển số")
    page_no: Optional[str] = Field(None, max_length=10, description="Số trang")
    date_of_death: date = Field(..., description="Ngày mất")
    time_of_death: Optional[time] = Field(None, description="Giờ mất")
    place_of_death_detail: str = Field(..., description="Nơi mất chi tiết")
    place_of_death_ward_id: Optional[int] = Field(None, description="ID Phường/Xã nơi mất (FK)")
    cause_of_death: Optional[str] = Field(None, description="Nguyên nhân mất")
    declarant_name: str = Field(..., max_length=100, description="Họ tên người khai")
    declarant_citizen_id: Optional[str] = Field(None, max_length=12, description="ID CCCD/CMND người khai")
    declarant_relationship: Optional[str] = Field(None, max_length=50, description="Quan hệ với người mất")
    registration_date: date = Field(..., description="Ngày đăng ký khai tử")
    issuing_authority_id: Optional[int] = Field(None, description="ID cơ quan đăng ký (FK)")
    death_notification_no: Optional[str] = Field(None, max_length=50, description="Số giấy báo tử")
    witness1_name: Optional[str] = Field(None, max_length=100, description="Người làm chứng 1")
    witness2_name: Optional[str] = Field(None, max_length=100, description="Người làm chứng 2")
    notes: Optional[str] = Field(None, description="Ghi chú thêm")
    
    @field_validator('date_of_death', 'registration_date')
    @classmethod
    def date_must_not_be_in_future(cls, v):
        if v > date.today():
            raise ValueError('Ngày không được ở tương lai')
        return v
    
    @field_validator('registration_date')
    @classmethod
    def registration_date_must_be_on_or_after_death(cls, v, info):
        date_of_death = info.data.get('date_of_death')
        if date_of_death is not None and v < date_of_death:
            raise ValueError('Ngày đăng ký phải sau hoặc bằng ngày mất')
        return v

class DeathCertificateCreate(DeathCertificateBase):
    pass # Kế thừa tất cả các trường từ Base

class DeathCertificateResponse(DeathCertificateBase):
    death_certificate_id: int # Thêm ID sau khi tạo
    status: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = {
        "from_attributes": True  # Thay thế cho orm_mode
    }

class CitizenValidationResponse(BaseModel):
    """Schema đơn giản để nhận phản hồi từ BCA Service"""
    citizen_id: str
    death_status: Optional[str] = None
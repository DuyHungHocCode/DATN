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
    # Các trường ID cho district và province cũng sẽ được lấy từ DB nếu có
    place_of_death_district_id: Optional[int] = Field(None, description="ID Quận/Huyện nơi mất (FK)")
    place_of_death_province_id: Optional[int] = Field(None, description="ID Tỉnh/Thành phố nơi mất (FK)")
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
    pass

class DeathCertificateResponse(DeathCertificateBase): # Schema này sẽ được sử dụng cho response chi tiết
    death_certificate_id: int
    status: bool
    created_at: datetime
    updated_at: datetime

    # Các trường tên đã được phân giải (lấy từ JOIN trong repository hoặc gọi BCAClient nếu cần thêm)
    place_of_death_ward_name: Optional[str] = None
    place_of_death_district_name: Optional[str] = None
    place_of_death_province_name: Optional[str] = None
    issuing_authority_name: Optional[str] = None
    # Nếu có thêm các trường ID khác cần phân giải, ví dụ quốc tịch người khai, thì thêm trường tên tương ứng ở đây

    model_config = {
        "from_attributes": True  # Cho phép tạo model từ thuộc tính đối tượng ORM
    }

class CitizenValidationResponse(BaseModel):
    """Schema đơn giản để nhận phản hồi từ BCA Service"""
    citizen_id: str
    death_status: Optional[str] = None

class DeathCertificateSearch(BaseModel):
    citizen_id: Optional[str] = None
    declarant_citizen_id: Optional[str] = None
    date_of_death_from: Optional[date] = None
    date_of_death_to: Optional[date] = None
    registration_date_from: Optional[date] = None
    registration_date_to: Optional[date] = None
    death_certificate_no: Optional[str] = None
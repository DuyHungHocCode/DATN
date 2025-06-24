# citizen-management-system_v5/service/be/civil_status_service_btp/app/schemas/birth_certificate.py

from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import date, datetime

class BirthCertificateBase(BaseModel):
    citizen_id: str = Field(..., max_length=12, description="ID CCCD/CMND của trẻ sơ sinh")
    full_name: str = Field(..., max_length=100, description="Họ và tên của trẻ")
    birth_certificate_no: str = Field(..., max_length=20, description="Số giấy khai sinh")
    registration_date: date = Field(..., description="Ngày đăng ký khai sinh")
    book_id: Optional[str] = Field(None, max_length=20, description="Quyển số")
    page_no: Optional[str] = Field(None, max_length=10, description="Số trang")
    issuing_authority_id: int = Field(..., description="ID cơ quan đăng ký khai sinh")
    place_of_birth: str = Field(..., description="Nơi sinh chi tiết")
    date_of_birth: date = Field(..., description="Ngày sinh của trẻ")
    gender_id: int = Field(..., description="ID giới tính của trẻ (1=Nam, 2=Nữ, 3=Khác)")
    father_full_name: Optional[str] = Field(None, max_length=100, description="Họ tên cha")
    father_citizen_id: Optional[str] = Field(None, max_length=12, description="ID CCCD/CMND của cha")
    father_date_of_birth: Optional[date] = Field(None, description="Ngày sinh của cha")
    father_nationality_id: Optional[int] = Field(None, description="ID quốc tịch của cha")
    mother_full_name: Optional[str] = Field(None, max_length=100, description="Họ tên mẹ")
    mother_citizen_id: Optional[str] = Field(None, max_length=12, description="ID CCCD/CMND của mẹ")
    mother_date_of_birth: Optional[date] = Field(None, description="Ngày sinh của mẹ")
    mother_nationality_id: Optional[int] = Field(None, description="ID quốc tịch của mẹ")
    declarant_name: str = Field(..., max_length=100, description="Họ tên người khai sinh")
    declarant_citizen_id: Optional[str] = Field(None, max_length=12, description="ID CCCD/CMND người khai sinh")
    declarant_relationship: Optional[str] = Field(None, max_length=50, description="Quan hệ với trẻ sơ sinh")
    witness1_name: Optional[str] = Field(None, max_length=100, description="Người làm chứng 1")
    witness2_name: Optional[str] = Field(None, max_length=100, description="Người làm chứng 2")
    birth_notification_no: Optional[str] = Field(None, max_length=50, description="Số giấy báo sinh")
    notes: Optional[str] = Field(None, description="Ghi chú thêm")

    @field_validator('date_of_birth', 'registration_date')
    @classmethod
    def date_must_not_be_in_future(cls, v):
        if v > date.today():
            raise ValueError('Ngày không được ở tương lai')
        return v
    
    @field_validator('registration_date')
    @classmethod
    def registration_date_must_be_on_or_after_birth(cls, v, info):
        date_of_birth = info.data.get('date_of_birth')
        if date_of_birth is not None and v < date_of_birth:
            raise ValueError('Ngày đăng ký phải sau hoặc bằng ngày sinh')
        return v

class BirthCertificateCreate(BirthCertificateBase):
    pass

class BirthCertificateResponse(BirthCertificateBase):
    birth_certificate_id: int
    status: bool
    created_at: datetime
    updated_at: datetime

    # Các trường tên đã được phân giải (nếu cần hiển thị trong response)
    issuing_authority_name: Optional[str] = None
    gender_name: Optional[str] = None
    father_nationality_name: Optional[str] = None
    mother_nationality_name: Optional[str] = None

    model_config = {
        "from_attributes": True
    }

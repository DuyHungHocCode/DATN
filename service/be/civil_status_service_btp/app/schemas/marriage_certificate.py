# civil_status_service_btp/app/schemas/marriage_certificate.py

from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import date, datetime

class MarriageCertificateBase(BaseModel):
    # Certificate info
    marriage_certificate_no: str = Field(..., max_length=20, description="Số giấy chứng nhận kết hôn")
    book_id: Optional[str] = Field(None, max_length=20, description="Quyển số")
    page_no: Optional[str] = Field(None, max_length=10, description="Số trang")
    
    # Husband info
    husband_id: str = Field(..., max_length=12, description="ID CCCD/CMND của chồng")
    husband_full_name: str = Field(..., max_length=100, description="Họ tên đầy đủ của chồng")
    husband_date_of_birth: date = Field(..., description="Ngày sinh của chồng")
    husband_nationality_id: int = Field(..., description="ID quốc tịch của chồng")
    husband_previous_marriage_status: Optional[str] = Field(None, description="Tình trạng hôn nhân trước đây của chồng")
    
    # Wife info
    wife_id: str = Field(..., max_length=12, description="ID CCCD/CMND của vợ") 
    wife_full_name: str = Field(..., max_length=100, description="Họ tên đầy đủ của vợ")
    wife_date_of_birth: date = Field(..., description="Ngày sinh của vợ")
    wife_nationality_id: int = Field(..., description="ID quốc tịch của vợ")
    wife_previous_marriage_status: Optional[str] = Field(None, description="Tình trạng hôn nhân trước đây của vợ")
    
    # Registration info
    marriage_date: date = Field(..., description="Ngày kết hôn")
    registration_date: date = Field(..., description="Ngày đăng ký kết hôn")
    issuing_authority_id: int = Field(..., description="ID cơ quan đăng ký")
    issuing_place: str = Field(..., description="Nơi đăng ký kết hôn")
    
    # Additional info
    witness1_name: Optional[str] = Field(None, max_length=100, description="Người làm chứng 1")
    witness2_name: Optional[str] = Field(None, max_length=100, description="Người làm chứng 2")
    notes: Optional[str] = Field(None, description="Ghi chú thêm")
    
    @field_validator('marriage_date', 'registration_date')
    @classmethod
    def date_must_not_be_in_future(cls, v):
        if v > date.today():
            raise ValueError('Ngày không được ở tương lai')
        return v
        
    @field_validator('registration_date')
    @classmethod
    def registration_date_must_be_on_or_after_marriage(cls, v, info):
        marriage_date = info.data.get('marriage_date')
        if marriage_date is not None and v < marriage_date:
            raise ValueError('Ngày đăng ký phải sau hoặc bằng ngày kết hôn')
        return v

class MarriageCertificateCreate(MarriageCertificateBase):
    pass # Inherits all fields from base

# class MarriageCertificateResponse(MarriageCertificateBase):
#     marriage_certificate_id: int # Added after creation
#     status: bool
#     created_at: datetime
#     updated_at: datetime
    
#     model_config = {
#         "from_attributes": True
#     }

class MarriageCertificateResponse(BaseModel):
    marriage_certificate_id: int
    marriage_certificate_no: str
    husband_id: str
    wife_id: str
    marriage_date: date
    registration_date: date
    issuing_authority_id: int
    status: bool
    
    # Các trường không bắt buộc
    book_id: Optional[str] = None
    page_no: Optional[str] = None
    husband_full_name: Optional[str] = None
    husband_date_of_birth: Optional[date] = None
    husband_nationality_id: Optional[int] = None
    husband_previous_marriage_status: Optional[str] = None
    wife_full_name: Optional[str] = None
    wife_date_of_birth: Optional[date] = None
    wife_nationality_id: Optional[int] = None
    wife_previous_marriage_status: Optional[str] = None
    issuing_place: Optional[str] = None
    witness1_name: Optional[str] = None
    witness2_name: Optional[str] = None
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    model_config = {
        "from_attributes": True
    }
# citizen-management-system_v5/service/be/civil_status_service_btp/app/schemas/divorce_record.py

from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import date, datetime

class DivorceRecordBase(BaseModel):
    divorce_certificate_no: Optional[str] = Field(None, max_length=20, description="Số giấy chứng nhận ly hôn (nếu có)")
    book_id: Optional[str] = Field(None, max_length=20, description="Quyển số")
    page_no: Optional[str] = Field(None, max_length=10, description="Số trang")
    marriage_certificate_id: int = Field(..., description="ID giấy chứng nhận kết hôn liên quan")
    divorce_date: date = Field(..., description="Ngày ly hôn (theo quyết định/bản án)")
    registration_date: date = Field(..., description="Ngày đăng ký ly hôn")
    court_name: str = Field(..., max_length=200, description="Tên Tòa án ra quyết định/bản án")
    judgment_no: str = Field(..., max_length=50, description="Số quyết định/bản án")
    judgment_date: date = Field(..., description="Ngày quyết định/bản án có hiệu lực")
    issuing_authority_id: Optional[int] = Field(None, description="ID cơ quan đăng ký/Tòa án")
    reason: Optional[str] = Field(None, description="Lý do ly hôn")
    child_custody: Optional[str] = Field(None, description="Thông tin về quyền nuôi con")
    property_division: Optional[str] = Field(None, description="Thông tin về phân chia tài sản")
    notes: Optional[str] = Field(None, description="Ghi chú thêm")

    @field_validator('divorce_date', 'registration_date', 'judgment_date')
    @classmethod
    def date_must_not_be_in_future(cls, v):
        if v > date.today():
            raise ValueError('Ngày không được ở tương lai')
        return v
    
    @field_validator('registration_date')
    @classmethod
    def registration_date_must_be_on_or_after_divorce_and_judgment(cls, v, info):
        divorce_date = info.data.get('divorce_date')
        judgment_date = info.data.get('judgment_date')

        if divorce_date is not None and v < divorce_date:
            raise ValueError('Ngày đăng ký phải sau hoặc bằng ngày ly hôn')
        if judgment_date is not None and v < judgment_date:
            raise ValueError('Ngày đăng ký phải sau hoặc bằng ngày ra quyết định/bản án')
        return v
    
    @field_validator('judgment_date')
    @classmethod
    def judgment_date_must_be_on_or_before_divorce(cls, v, info):
        divorce_date = info.data.get('divorce_date')
        if divorce_date is not None and v > divorce_date:
            raise ValueError('Ngày ra quyết định/bản án phải trước hoặc bằng ngày ly hôn')
        return v

class DivorceRecordCreate(DivorceRecordBase):
    pass

class DivorceRecordResponse(DivorceRecordBase):
    divorce_record_id: int
    status: bool
    created_at: datetime
    updated_at: datetime
    
    # Các trường tên đã được phân giải (nếu cần hiển thị trong response)
    issuing_authority_name: Optional[str] = None

    model_config = {
        "from_attributes": True
    }
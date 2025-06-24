from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import date


class TemporaryAbsenceRegisterRequest(BaseModel):
    """
    Schema for registering a new temporary absence.
    """
    citizen_id: str = Field(..., min_length=12, max_length=12, description="CCCD/CMND của công dân")
    from_date: date = Field(..., description="Ngày bắt đầu tạm vắng")
    to_date: Optional[date] = Field(None, description="Ngày dự kiến kết thúc (có thể NULL)")
    reason: str = Field(..., min_length=1, max_length=1000, description="Lý do tạm vắng")
    temporary_absence_type_id: int = Field(..., gt=0, description="ID loại tạm vắng")
    
    # Địa chỉ đích (tùy chọn)
    destination_address_detail: Optional[str] = Field(None, max_length=500, description="Địa chỉ chi tiết nơi đến")
    destination_ward_id: Optional[int] = Field(None, gt=0, description="ID phường/xã nơi đến")
    destination_district_id: Optional[int] = Field(None, gt=0, description="ID quận/huyện nơi đến")
    destination_province_id: Optional[int] = Field(None, gt=0, description="ID tỉnh/thành nơi đến")
    
    contact_information: Optional[str] = Field(None, max_length=500, description="Thông tin liên lạc")
    registration_authority_id: int = Field(..., gt=0, description="ID cơ quan đăng ký")
    sensitivity_level_id: int = Field(1, gt=0, description="Mức độ nhạy cảm")
    notes: Optional[str] = Field(None, max_length=1000, description="Ghi chú")

    @validator('to_date')
    def validate_to_date(cls, v, values):
        if v is not None and 'from_date' in values and v <= values['from_date']:
            raise ValueError('Ngày kết thúc phải sau ngày bắt đầu')
        return v

    @validator('destination_ward_id')
    def validate_address_consistency(cls, v, values):
        # Nếu có ward_id thì phải có đầy đủ district_id và province_id
        if v is not None:
            if 'destination_district_id' not in values or values['destination_district_id'] is None:
                raise ValueError('Nếu có ward_id thì phải có district_id')
            if 'destination_province_id' not in values or values['destination_province_id'] is None:
                raise ValueError('Nếu có ward_id thì phải có province_id')
        return v

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "citizen_id": "001201786523",
                "from_date": "2024-01-15",
                "to_date": "2024-06-15",
                "reason": "Đi công tác dài hạn tại Hà Nội",
                "temporary_absence_type_id": 1,
                "destination_address_detail": "123 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội",
                "destination_ward_id": 1001,
                "destination_district_id": 100,
                "destination_province_id": 1,
                "contact_information": "0987654321, email@example.com",
                "registration_authority_id": 401,
                "sensitivity_level_id": 1,
                "notes": "Công tác tại chi nhánh công ty"
            }
        }
    }


class TemporaryAbsenceResponse(BaseModel):
    """
    Schema for temporary absence response after successful registration.
    """
    success: bool = True
    message: str
    temporary_absence_id: int
    registration_number: str
    citizen_id: str
    from_date: date
    to_date: Optional[date]
    status: str = "ACTIVE"

    model_config = {
        "from_attributes": True
    }


class ConfirmReturnRequest(BaseModel):
    """
    Schema for confirming return from temporary absence.
    """
    temporary_absence_id: Optional[int] = Field(None, gt=0, description="ID đăng ký tạm vắng (ưu tiên)")
    citizen_id: Optional[str] = Field(None, min_length=12, max_length=12, description="CCCD/CMND (nếu không có ID)")
    return_date: Optional[date] = Field(None, description="Ngày trở về (mặc định là hôm nay)")
    return_notes: Optional[str] = Field(None, max_length=500, description="Ghi chú về việc trở về")

    @validator('temporary_absence_id')
    def validate_identification(cls, v, values):
        if v is None and ('citizen_id' not in values or values['citizen_id'] is None):
            raise ValueError('Phải cung cấp temporary_absence_id hoặc citizen_id')
        return v

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "temporary_absence_id": 123,
                "return_date": "2024-06-10",
                "return_notes": "Trở về sớm hơn dự kiến do hoàn thành công việc"
            }
        }
    }


class ExtendTemporaryAbsenceRequest(BaseModel):
    """
    Schema for extending temporary absence duration.
    """
    temporary_absence_id: int = Field(..., gt=0, description="ID đăng ký tạm vắng")
    new_to_date: date = Field(..., description="Ngày kết thúc mới")
    extension_reason: str = Field(..., min_length=1, max_length=500, description="Lý do gia hạn")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "temporary_absence_id": 123,
                "new_to_date": "2024-09-15",
                "extension_reason": "Cần thêm thời gian để hoàn thành dự án"
            }
        }
    }


class CancelTemporaryAbsenceRequest(BaseModel):
    """
    Schema for cancelling temporary absence registration.
    """
    temporary_absence_id: int = Field(..., gt=0, description="ID đăng ký tạm vắng")
    cancellation_reason: str = Field(..., min_length=1, max_length=500, description="Lý do hủy")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "temporary_absence_id": 123,
                "cancellation_reason": "Thay đổi kế hoạch, không cần tạm vắng nữa"
            }
        }
    }


class TemporaryAbsenceDetailResponse(BaseModel):
    """
    Schema for detailed temporary absence information.
    """
    temporary_absence_id: int
    citizen_id: str
    citizen_name: Optional[str]
    from_date: date
    to_date: Optional[date]
    reason: str
    destination_address: Optional[str]
    contact_information: Optional[str]
    registration_number: Optional[str]
    registration_authority: Optional[str]
    status: str
    temporary_absence_type: Optional[str]
    return_date: Optional[date]
    return_confirmed: bool
    extension_count: Optional[int]
    notes: Optional[str]
    created_at: Optional[str]

    model_config = {
        "from_attributes": True
    }


class TemporaryAbsenceListResponse(BaseModel):
    """
    Schema for listing temporary absences with pagination.
    """
    total_count: int
    items: list[TemporaryAbsenceDetailResponse]
    page: int = 1
    page_size: int = 20

    model_config = {
        "from_attributes": True
    } 
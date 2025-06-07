from pydantic import BaseModel, Field, field_validator
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

class PermanentResidenceOwnedPropertyCreate(BaseModel):
    citizen_id: str = Field(..., max_length=12, description="ID CCCD/CMND của công dân")
    address_detail: str = Field(..., description="Địa chỉ chi tiết (số nhà, ngõ, đường)")
    ward_id: int = Field(..., description="ID Phường/Xã (FK tới Reference.Wards)")
    district_id: int = Field(..., description="ID Quận/Huyện (FK tới Reference.Districts)")
    province_id: int = Field(..., description="ID Tỉnh/Thành phố (FK tới Reference.Provinces)")
    postal_code: Optional[str] = Field(None, max_length=10, description="Mã bưu chính")
    latitude: Optional[float] = Field(None, description="Vĩ độ")
    longitude: Optional[float] = Field(None, description="Kinh độ")

    ownership_certificate_id: int = Field(..., description="ID Giấy chứng nhận quyền sở hữu (FK tới TNMT.OwnershipCertificate)")

    registration_date: date = Field(..., description="Ngày đăng ký thường trú")
    issuing_authority_id: int = Field(..., description="ID Cơ quan đăng ký (Công an Quận/Phường)")
    registration_number: Optional[str] = Field(None, max_length=50, description="Số đăng ký thường trú")
    registration_reason: Optional[str] = Field(None, description="Lý do đăng ký thường trú")
    residence_expiry_date: Optional[date] = Field(None, description="Ngày hết hạn cư trú (thường NULL cho thường trú)")
    previous_address_id: Optional[int] = Field(None, description="ID địa chỉ cũ (nếu có chuyển đi)")
    residence_status_change_reason_id: Optional[int] = Field(None, description="ID lý do thay đổi trạng thái cư trú (FK tới Reference.ResidenceStatusChangeReasons)")
    document_url: Optional[str] = Field(None, max_length=255, description="URL tài liệu đính kèm")
    rh_verification_status: Optional[str] = Field("Đã xác minh", max_length=50, description="Trạng thái xác minh của ResidenceHistory")
    rh_verification_date: Optional[date] = Field(None, description="Ngày xác minh của ResidenceHistory")
    rh_verified_by: Optional[str] = Field(None, max_length=100, description="Người xác minh của ResidenceHistory")
    registration_case_type: str = Field(..., max_length=50, description="Loại trường hợp đăng ký (ví dụ: 'OwnedProperty')")
    supporting_document_info: Optional[str] = Field(None, description="Thông tin chi tiết tài liệu hỗ trợ")

    notes: Optional[str] = Field(None, description="Ghi chú chung")
    updated_by: Optional[str] = Field("API_USER", max_length=50, description="Người/hệ thống cập nhật")

    # Thông tin cho bảng CitizenStatus (nếu có thay đổi trạng thái kèm theo)
    cs_description: Optional[str] = Field(None, description="Mô tả trạng thái công dân")
    cs_cause: Optional[str] = Field(None, max_length=200, description="Nguyên nhân thay đổi trạng thái")
    cs_location: Optional[str] = Field(None, max_length=200, description="Địa điểm thay đổi trạng thái")
    cs_authority_id: Optional[int] = Field(None, description="ID Cơ quan liên quan đến thay đổi trạng thái")
    cs_document_number: Optional[str] = Field(None, max_length=50, description="Số tài liệu liên quan đến thay đổi trạng thái")
    cs_document_date: Optional[date] = Field(None, description="Ngày tài liệu liên quan đến thay đổi trạng thái")
    cs_certificate_id: Optional[str] = Field(None, max_length=50, description="ID giấy chứng nhận liên quan đến thay đổi trạng thái")
    cs_reported_by: Optional[str] = Field(None, max_length=100, description="Người báo cáo thay đổi trạng thái")
    cs_relationship: Optional[str] = Field(None, max_length=50, description="Mối quan hệ của người báo cáo")
    cs_verification_status: Optional[str] = Field("Đã xác minh", max_length=50, description="Trạng thái xác minh của CitizenStatus")
    
    # Các trường này được thêm vào để khớp với các tham số mới của SP
    ca_verification_status: Optional[str] = Field("Đã xác minh", max_length=50, description="Trạng thái xác minh của CitizenAddress")
    ca_verification_date: Optional[date] = Field(None, description="Ngày xác minh của CitizenAddress")
    ca_verified_by: Optional[str] = Field(None, max_length=100, description="Người xác minh của CitizenAddress")
    ca_notes: Optional[str] = Field(None, description="Ghi chú của CitizenAddress")

    @field_validator('registration_date')
    @classmethod
    def registration_date_must_not_be_in_future(cls, v):
        if v > date.today():
            raise ValueError('Ngày đăng ký không được ở tương lai')
        return v
    
    model_config = {
        "from_attributes": True
    }

class PermanentResidenceRegistrationResponse(BaseModel):
    new_residence_history_id: int
    citizen_id: str
    address_detail: str
    registration_date: date
    status: str = "Đăng ký thành công"
    
    class Config:
        orm_mode = True


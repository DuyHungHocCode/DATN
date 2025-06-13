# citizen_service_bca/app/schemas/household_change.py
from pydantic import BaseModel, Field
from typing import Optional
from datetime import date

class HouseholdAddMemberRequest(BaseModel):
    """
    Schema for adding a new member to a household.
    (Luồng "Nhập Hộ khẩu")
    """
    citizen_id: str = Field(..., description="Số CCCD (12 số) của công dân cần nhập hộ khẩu.", pattern=r"^\d{12}$")
    to_household_id: int = Field(..., gt=0, description="Mã định danh của hộ khẩu đích.")
    relationship_with_head_id: int = Field(..., gt=0, description="Mã định danh mối quan hệ với chủ hộ.")
    reason_code: str = Field(..., description="Mã lý do nhập hộ.")
    effective_date: date = Field(..., description="Ngày hiệu lực của việc nhập hộ khẩu.")
    issuing_authority_id: int = Field(..., gt=0, description="Mã định danh cơ quan cấp.")
    created_by_user_id: Optional[str] = Field(None, description="ID của cán bộ thực hiện thay đổi.")
    notes: Optional[str] = Field(None, description="Ghi chú thêm nếu cần.")

class HouseholdTransferMemberRequest(BaseModel):
    """
    Schema for transferring a member from one household to another.
    (Luồng "Chuyển Hộ khẩu")
    """
    citizen_id: str = Field(..., description="Số CCCD (12 số) của công dân cần chuyển.", pattern=r"^\d{12}$")
    from_household_id: int = Field(..., gt=0, description="Mã định danh của hộ khẩu nguồn.")
    to_household_id: int = Field(..., gt=0, description="Mã định danh của hộ khẩu đích.")
    relationship_with_head_id: int = Field(..., gt=0, description="Mã định danh mối quan hệ với chủ hộ mới.")
    reason_code: str = Field(..., description="Mã lý do nhập hộ.")
    effective_date: date = Field(..., description="Ngày hiệu lực của việc chuyển khẩu.")
    issuing_authority_id: int = Field(..., gt=0, description="Mã định danh cơ quan cấp.")
    created_by_user_id: Optional[str] = Field(None, description="ID của cán bộ thực hiện thay đổi.")
    notes: Optional[str] = Field(None, description="Ghi chú thêm nếu cần.")

class HouseholdRemoveMemberRequest(BaseModel):
    """
    Schema for removing a member from a household.
    (Luồng "Xóa thành viên khỏi hộ khẩu")
    """
    reason_code: str = Field(..., description="Mã lý do xóa thành viên khỏi hộ khẩu.")
    issuing_authority_id: int = Field(..., gt=0, description="Mã định danh cơ quan cấp.")
    created_by_user_id: Optional[str] = Field(None, description="ID của cán bộ thực hiện thay đổi.")
    notes: Optional[str] = Field(None, description="Ghi chú thêm nếu cần.")

class HouseholdChangeResponse(BaseModel):
    """
    Schema for the response after a successful household change.
    """
    success: bool = True
    message: str
    log_id: int
    household_member_id: Optional[int] = None
    
    model_config = {
        "from_attributes": True
    } 
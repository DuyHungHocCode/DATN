# citizen_service_bca/app/schemas/family_tree.py
from pydantic import BaseModel
from typing import Optional, List
from datetime import date

class FamilyTreeMemberResponse(BaseModel):
    level_id: int
    relationship_path: str
    citizen_id: str
    full_name: str
    date_of_birth: date
    gender: str
    id_card_number: Optional[str] = None
    nationality_name: Optional[str] = None
    ethnicity_name: Optional[str] = None
    religion_name: Optional[str] = None
    marital_status: Optional[str] = None
    
    class Config:
        orm_mode = True

class FamilyTreeResponse(BaseModel):
    citizen_id: str
    family_members: List[FamilyTreeMemberResponse]
    
    class Config:
        orm_mode = True
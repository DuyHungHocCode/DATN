from pydantic import BaseModel
from typing import Optional
from datetime import date

class CitizenValidationResponse(BaseModel):
    citizen_id: str
    full_name: str
    date_of_birth: date
    gender: str
    death_status: Optional[str] = None
    marital_status: Optional[str] = None
    spouse_citizen_id: Optional[str] = None
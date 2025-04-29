from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import date

class CitizenSearch(BaseModel):
    citizen_id: Optional[str] = None
    full_name: Optional[str] = None
    date_of_birth: Optional[date] = None

class CitizenResponse(BaseModel):
    citizen_id: str
    full_name: str
    date_of_birth: date
    gender: str
    nationality_name: Optional[str] = None
    ethnicity_name: Optional[str] = None
    religion_name: Optional[str] = None
    marital_status: Optional[str] = None
    education_level: Optional[str] = None
    occupation_name: Optional[str] = None
    birth_province_name: Optional[str] = None
    current_address_detail: Optional[str] = None
    current_province_name: Optional[str] = None
    current_district_name: Optional[str] = None
    current_ward_name: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    
    class Config:
        orm_mode = True
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

class ReferenceDataResponse(BaseModel):
    data: Dict[str, List[Dict[str, Any]]]
    total_tables: int
    
    class Config:
        orm_mode = True
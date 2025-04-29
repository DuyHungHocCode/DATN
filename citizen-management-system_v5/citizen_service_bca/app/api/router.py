from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from datetime import date
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.citizen_repo import CitizenRepository
from app.schemas.citizen import CitizenSearch, CitizenResponse

router = APIRouter()

@router.get("/citizens/{citizen_id}", response_model=CitizenResponse)
def get_citizen(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy thông tin chi tiết của một công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    citizen = repo.find_by_id(citizen_id)
    
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Citizen with ID {citizen_id} not found"
        )
    
    return citizen

@router.get("/citizens/", response_model=List[CitizenResponse])
def search_citizens(
    full_name: Optional[str] = None,
    date_of_birth: Optional[date] = None,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """
    Tìm kiếm danh sách công dân theo tên hoặc ngày sinh
    """
    repo = CitizenRepository(db)
    citizens = repo.search_citizens(full_name, date_of_birth, limit, offset)
    
    return citizens
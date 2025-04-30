from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from datetime import date
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.citizen_repo import CitizenRepository
from app.schemas.citizen import CitizenSearch, CitizenResponse
from app.schemas.residence import ResidenceHistoryResponse, ContactInfoResponse

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

@router.get("/citizens/{citizen_id}/residence-history", response_model=List[ResidenceHistoryResponse])
def get_citizen_residence_history(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy lịch sử cư trú của một công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    
    # Kiểm tra công dân tồn tại
    citizen = repo.find_by_id(citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy công dân với ID {citizen_id}"
        )
    
    # Lấy lịch sử cư trú
    residence_history = repo.get_residence_history(citizen_id)
    return residence_history

@router.get("/citizens/{citizen_id}/contact-info", response_model=ContactInfoResponse)
def get_citizen_contact_info(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy thông tin liên hệ của một công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    
    # Kiểm tra công dân tồn tại
    citizen = repo.find_by_id(citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy công dân với ID {citizen_id}"
        )
    
    # Lấy thông tin liên hệ
    contact_info = repo.get_contact_info(citizen_id)
    if not contact_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy thông tin liên hệ cho công dân với ID {citizen_id}"
        )
    
    return contact_info
from fastapi import APIRouter, Depends, HTTPException, Query, status, Body
from typing import List, Optional, Dict, Any
import json
from datetime import date
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.citizen_repo import CitizenRepository
from app.schemas.citizen import CitizenSearch, CitizenResponse, CitizenValidationResponse
from app.schemas.residence import ResidenceHistoryResponse, ContactInfoResponse
from app.schemas.family_tree import FamilyTreeResponse

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

@router.get("/citizens/{citizen_id}/validation", response_model=CitizenValidationResponse)
def validate_citizen(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Get essential citizen validation data for inter-service validation
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

@router.get("/citizens/{citizen_id}/family-tree", response_model=FamilyTreeResponse)
def get_citizen_family_tree(
    citizen_id: str,
    db: Session = Depends(get_db)
):
    """
    Lấy cây phả hệ 3 đời của công dân theo ID CCCD/CMND
    """
    repo = CitizenRepository(db)
    
    # Kiểm tra công dân tồn tại
    citizen = repo.find_by_id(citizen_id)
    if not citizen:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Không tìm thấy công dân với ID {citizen_id}"
        )
    
    # Lấy thông tin phả hệ
    family_members = repo.get_family_tree(citizen_id)
    
    return {
        "citizen_id": citizen_id,
        "family_members": family_members
    }

@router.post("/citizens/batch-validate", response_model=Dict[str, Any])
def batch_validate_citizens(
    request_data: Dict[str, Any] = Body(...),
    db: Session = Depends(get_db)
):
    """
    Batch validate multiple citizens with optional family tree in a single request
    """
    # Kiểm tra định dạng request
    print(f"DEBUG - Received batch validate request: {json.dumps(request_data)}")
    
    # Đảm bảo citizen_ids là một danh sách
    citizen_ids = request_data.get("citizen_ids", [])
    include_family_tree = request_data.get("include_family_tree", False)
    
    if not isinstance(citizen_ids, list):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="citizen_ids must be a list"
        )
    
    repo = CitizenRepository(db)
    result = {}
    
    for citizen_id in citizen_ids:
        # Get basic validation data
        citizen = repo.find_by_id(citizen_id)
        if not citizen:
            result[citizen_id] = {"found": False}
            continue
        
        # Build response
        citizen_data = {
            "found": True,
            "validation": {
                "citizen_id": citizen["citizen_id"],
                "full_name": citizen["full_name"],
                "date_of_birth": citizen["date_of_birth"],
                "gender": citizen["gender"],
                "death_status": citizen["death_status"],
                "marital_status": citizen["marital_status"],
                "spouse_citizen_id": citizen["spouse_citizen_id"]
            }
        }
        
        # Add family tree if requested
        if include_family_tree:
            family_tree = repo.get_family_tree(citizen_id)
            citizen_data["family_tree"] = {
                "citizen_id": citizen_id,
                "family_members": family_tree
            }
        
        result[citizen_id] = citizen_data
    
    return result
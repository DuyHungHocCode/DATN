from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.reference_repo import ReferenceRepository
import logging

router = APIRouter(prefix="/references", tags=["References"])
logger = logging.getLogger(__name__)

@router.get("/", response_model=Dict[str, List[Dict[str, Any]]])
def get_reference_data(
    tables: str = Query(..., description="Danh sách tên bảng tham chiếu, phân cách bằng dấu phẩy"),
    db: Session = Depends(get_db)
):
    """
    Lấy dữ liệu tham chiếu từ các bảng được chỉ định sử dụng stored procedure.
    
    Truyền danh sách tên bảng cách nhau bởi dấu phẩy, ví dụ: Provinces,Districts,Ethnicities
    
    Response là một đối tượng JSON với key là tên bảng và value là mảng các bản ghi của bảng đó.
    """
    try:
        repo = ReferenceRepository(db)
        
        # Sử dụng stored procedure
        try:
            return repo.get_reference_tables_data(tables)
        except Exception as first_error:
            # Thử phương thức thay thế nếu phương thức chính không hoạt động
            try:
                logger.warning(f"Primary method failed: {str(first_error)}. Trying alternative method.")
                return repo.get_reference_tables_data_alternative(tables)
            except Exception as second_error:
                logger.error(f"Both methods failed. Primary error: {str(first_error)}, Secondary error: {str(second_error)}")
                raise second_error
        
    except Exception as e:
        logger.error(f"Error getting reference data: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving reference data: {str(e)}"
        )

@router.get("/all", response_model=Dict[str, List[Dict[str, Any]]])
def get_all_reference_data(
    db: Session = Depends(get_db)
):
    """
    Lấy dữ liệu từ các bảng tham chiếu thường dùng.
    """
    # Danh sách các bảng tham chiếu thường dùng
    common_tables = "Provinces,Districts,Wards,Ethnicities,Religions,Nationalities,Occupations,Genders,MaritalStatuses,EducationLevels,BloodTypes,DocumentTypes"
    
    try:
        repo = ReferenceRepository(db)
        return repo.get_reference_tables_data(common_tables)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving reference data: {str(e)}"
        )
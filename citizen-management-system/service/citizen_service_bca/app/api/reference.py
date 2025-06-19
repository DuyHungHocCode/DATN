from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from app.db.redis_client import get_redis_client
from app.db.database import get_db
from app.db.reference_repo import ReferenceRepository # Đảm bảo import đúng
import logging

router = APIRouter(prefix="/references", tags=["References"])
logger = logging.getLogger(__name__)

@router.get("/", response_model=Dict[str, List[Dict[str, Any]]])
def get_reference_data(
    tables: str = Query(..., description="Danh sách tên bảng tham chiếu, phân cách bằng dấu phẩy, ví dụ: Provinces,Districts"),
    db: Session = Depends(get_db)
):
    """
    Lấy dữ liệu tham chiếu từ các bảng được chỉ định.
    Dữ liệu sẽ được lấy từ cache nếu có, ngược lại sẽ query từ DB và cache lại.
    """
    try:
        repo = ReferenceRepository(db)
        # Phương thức get_reference_tables_data trong repo đã được cập nhật để xử lý cache
        data = repo.get_reference_tables_data(tables) # Sửa lại tên tham số cho phù hợp
        
        # Kiểm tra xem tất cả các bảng yêu cầu có được trả về không (kể cả khi rỗng)
        requested_tables_list = [name.strip() for name in tables.split(',') if name.strip()]
        for req_table in requested_tables_list:
            if req_table not in data:
                # Có thể SP không trả về gì cho bảng này, hoặc bảng không tồn tại
                # Trả về một list rỗng cho bảng này để frontend không bị lỗi
                data[req_table] = []
                logger.warning(f"Reference table '{req_table}' not found in SP result or DB, returning empty list.")

        if not data and requested_tables_list: # Nếu không có data nào được trả về mặc dù có yêu cầu
             logger.warning(f"No data returned for requested tables: {tables}")
             # Trả về dict rỗng với các key là tên bảng yêu cầu và value là list rỗng
             return {req_table: [] for req_table in requested_tables_list}

        return data
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
    common_tables = "Provinces,Districts,Wards,Ethnicities,Religions,Nationalities,Occupations,Genders,MaritalStatuses,EducationLevels,BloodTypes,DocumentTypes,Authorities,RelationshipTypes,CitizenStatusTypes,HouseholdTypes" # Thêm các bảng cần thiết
    
    try:
        repo = ReferenceRepository(db)
        return repo.get_reference_tables_data(common_tables) # Sửa lại tên tham số
    except Exception as e:
        logger.error(f"Error getting all reference data: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving all reference data: {str(e)}"
        )

@router.post("/references/cache/clear", status_code=status.HTTP_200_OK, tags=["Cache Management"])
async def clear_reference_cache(
    table_names: Optional[List[str]] = Query(None, description="Danh sách các bảng tham chiếu cần xóa cache. Nếu không cung cấp, sẽ xóa cache của một số bảng mặc định."),
    redis_client_dep: Any = Depends(get_redis_client) # Sử dụng Any để tránh lỗi type hint nếu RedisClient không được khởi tạo
):
    """
    API endpoint để xóa cache của các bảng tham chiếu trong Redis.
    Hữu ích khi dữ liệu tham chiếu trong DB được cập nhật.
    """
    if not redis_client_dep or not redis_client_dep.client:
        raise HTTPException(status_code=503, detail="Redis client not available.")

    default_tables_to_clear = [
        "Provinces", "Districts", "Wards", "Ethnicities", "Religions",
        "Nationalities", "Occupations", "Genders", "MaritalStatuses",
        "EducationLevels", "BloodTypes", "DocumentTypes", "Authorities",
        "RelationshipTypes","CitizenStatusTypes", "HouseholdTypes"
    ]
    
    tables_to_process = table_names if table_names else default_tables_to_clear
    
    try:
        if not tables_to_process: # Nếu table_names là list rỗng
             redis_client_dep.clear_all_reference_tables(default_tables_to_clear)
             return {"message": f"Successfully cleared cache for default reference tables."}

        cleared_tables = []
        failed_tables = []
        for table_name in tables_to_process:
            try:
                redis_client_dep.clear_reference_table(table_name)
                cleared_tables.append(table_name)
            except Exception as e:
                logger.error(f"Failed to clear cache for table {table_name}: {str(e)}")
                failed_tables.append({"table": table_name, "error": str(e)})
        
        if failed_tables:
            detail_msg = f"Successfully cleared cache for: {', '.join(cleared_tables)}. Failed for: {failed_tables}"
            # Có thể raise lỗi nếu có bất kỳ bảng nào không xóa được cache
            raise HTTPException(status_code=500, detail=detail_msg)
            return {"message": detail_msg, "cleared": cleared_tables, "failed": failed_tables}

        return {"message": f"Successfully cleared cache for tables: {', '.join(cleared_tables)}"}
    except Exception as e:
        logger.error(f"Error clearing reference cache: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error clearing reference cache: {str(e)}"
        )
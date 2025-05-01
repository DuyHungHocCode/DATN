from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import Optional, List, Dict, Any
from datetime import date
from fastapi import HTTPException, status
import logging
# Configure logger
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

class CitizenRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def find_by_id(self, citizen_id: str) -> Dict[str, Any]:
        """Tìm kiếm công dân theo ID sử dụng function SQL Server."""
        try:
            # Sử dụng hàm GetCitizenDetails đã được tạo trong SQL Server
            query = text("SELECT * FROM [API_Internal].[GetCitizenDetails](:citizen_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id}).fetchone()
            
            if not result:
                return None
                
            # Chuyển đổi từ Row sang dict
            return {key: value for key, value in result._mapping.items()}
            
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Database error: {str(e)}"
            )
    
    def search_citizens(self, 
                       full_name: Optional[str] = None, 
                       date_of_birth: Optional[date] = None,
                       limit: int = 20, 
                       offset: int = 0) -> List[Dict[str, Any]]:
        """Tìm kiếm danh sách công dân theo các tiêu chí."""
        try:
            # Tạo query base
            query_parts = ["SELECT TOP :limit * FROM [BCA].[Citizen] c"]
            
            # Thêm các joins
            joins = [
                "LEFT JOIN [Reference].[Nationalities] nat ON c.nationality_id = nat.nationality_id",
                "LEFT JOIN [Reference].[Ethnicities] eth ON c.ethnicity_id = eth.ethnicity_id",
                "LEFT JOIN [Reference].[Religions] rel ON c.religion_id = rel.religion_id",
                "LEFT JOIN [Reference].[Occupations] occ ON c.occupation_id = occ.occupation_id",
                "LEFT JOIN [Reference].[Provinces] bp ON c.birth_province_id = bp.province_id",
                "LEFT JOIN [Reference].[Provinces] cp ON c.current_province_id = cp.province_id",
                "LEFT JOIN [Reference].[Districts] cd ON c.current_district_id = cd.district_id",
                "LEFT JOIN [Reference].[Wards] cw ON c.current_ward_id = cw.ward_id"
            ]
            
            query_parts.extend(joins)
            
            # Thêm WHERE clause
            where_clauses = []
            params = {"limit": limit, "offset": offset}
            
            if full_name:
                where_clauses.append("c.full_name LIKE :full_name")
                params["full_name"] = f"%{full_name}%"
                
            if date_of_birth:
                where_clauses.append("c.date_of_birth = :date_of_birth")
                params["date_of_birth"] = date_of_birth
            
            if where_clauses:
                query_parts.append("WHERE " + " AND ".join(where_clauses))
            
            # Thêm ORDER BY và OFFSET
            query_parts.append("ORDER BY c.full_name OFFSET :offset ROWS")
            
            # Tạo câu query hoàn chỉnh
            query = " ".join(query_parts)
            
            # Thực thi query
            result = self.db.execute(text(query), params).fetchall()
            
            # Trả về danh sách dict
            return [dict(row._mapping) for row in result]
            
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Database error: {str(e)}"
            )
        
    def get_residence_history(self, citizen_id: str) -> List[Dict[str, Any]]:
        """Lấy lịch sử cư trú của công dân theo ID."""
        try:
            query = text("SELECT * FROM [API_Internal].[GetResidenceHistory](:citizen_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id}).fetchall()
            
            if not result:
                return []
                
            # Chuyển đổi từ Row sang dict
            return [dict(row._mapping) for row in result]
            
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Lỗi cơ sở dữ liệu: {str(e)}"
            )

    def get_contact_info(self, citizen_id: str) -> Dict[str, Any]:
        """Lấy thông tin liên hệ của công dân theo ID."""
        try:
            query = text("SELECT * FROM [API_Internal].[GetCitizenContactInfo](:citizen_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id}).fetchone()
            
            if not result:
                return None
                
            # Chuyển đổi từ Row sang dict
            return {key: value for key, value in result._mapping.items()}
            
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Lỗi cơ sở dữ liệu: {str(e)}"
            )
        
    def update_citizen_death_status(self, citizen_id: str, date_of_death: date) -> bool:
        """Cập nhật trạng thái và ngày mất của công dân sử dụng stored procedure."""
        try:
            # Gọi stored procedure API_Internal.UpdateCitizenDeathStatus
            query = text("""
                EXEC [API_Internal].[UpdateCitizenDeathStatus] 
                    @citizen_id = :citizen_id, 
                    @date_of_death = :date_of_death, 
                    @updated_by = 'KAFKA_CONSUMER'
            """)
            
            result = self.db.execute(query, {
                "citizen_id": citizen_id, 
                "date_of_death": date_of_death
            })
            
            # Lấy kết quả trả về (affected_rows)
            row = result.fetchone()
            affected_rows = row[0] if row else 0
            
            if affected_rows == 0:
                # Công dân không tồn tại hoặc đã được đánh dấu là đã mất
                return False
            
            self.db.commit()
            return True
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Database error when updating citizen death status: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Database error when updating citizen death status: {str(e)}"
            )
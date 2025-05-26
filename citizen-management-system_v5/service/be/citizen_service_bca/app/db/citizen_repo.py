from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import Optional, List, Dict, Any
from datetime import date
from fastapi import HTTPException, status
import logging
# Configure logger
logger = logging.getLogger(__name__)

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
        
    def update_citizen_death_status(
        self, 
        citizen_id: str, 
        date_of_death: date, 
        cause_of_death: Optional[str] = None,
        place_of_death_detail: Optional[str] = None,
        death_certificate_no: Optional[str] = None,
        issuing_authority_id_btp: Optional[int] = None,
        updated_by: str = 'KAFKA_CONSUMER' # Default value as in SP
    ) -> bool:
        """Cập nhật trạng thái và ngày mất của công dân."""
        try:
            logger.info(f"Calling stored procedure to update death status for citizen {citizen_id} with date {date_of_death}")
            
            # Gọi stored procedure
            query = text("""
                EXEC [API_Internal].[UpdateCitizenDeathStatus] 
                    @citizen_id = :citizen_id, 
                    @date_of_death = :date_of_death, 
                    @cause_of_death = :cause_of_death,
                    @place_of_death_detail = :place_of_death_detail,
                    @death_certificate_no = :death_certificate_no,
                    @issuing_authority_id_btp = :issuing_authority_id_btp,
                    @updated_by = :updated_by
            """)
            
            result = self.db.execute(query, {
                "citizen_id": citizen_id, 
                "date_of_death": date_of_death,
                "cause_of_death": cause_of_death,
                "place_of_death_detail": place_of_death_detail,
                "death_certificate_no": death_certificate_no,
                "issuing_authority_id_btp": issuing_authority_id_btp,
                "updated_by": updated_by
            })
            
            # Lấy kết quả trả về (affected_rows) từ stored procedure
            row = result.fetchone()
            affected_rows = row[0] if row else 0
            logger.info(f"Stored procedure returned affected_rows: {affected_rows}")
            
            # Commit transaction nếu có cập nhật
            if affected_rows > 0:
                self.db.commit()
                logger.info(f"Successfully committed update for citizen {citizen_id}")
                return True
            else:
                # Nếu không có hàng nào bị ảnh hưởng, có thể công dân không tồn tại hoặc đã được cập nhật
                logger.warning(f"No update performed for citizen {citizen_id}. Citizen may not exist or already deceased.")
                self.db.rollback() # Rollback nếu không có hàng nào bị ảnh hưởng để đảm bảo consistency
                return False
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Database error when updating citizen death status: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Database error when updating citizen death status: {str(e)}"
            )
    
    def get_family_tree(self, citizen_id: str) -> List[Dict[str, Any]]:
        """Lấy cây phả hệ 3 đời của công dân theo ID."""
        try:
            query = text("SELECT * FROM [API_Internal].[GetCitizenFamilyTree](:citizen_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id}).fetchall()
            
            if not result:
                return []
                
            # Chuyển đổi từ Row sang dict
            return [dict(row._mapping) for row in result]
            
        except Exception as e:
            logger.error(f"Database error when getting family tree: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Lỗi cơ sở dữ liệu khi truy vấn phả hệ: {str(e)}"
            )
        
    def update_marriage_status(self, citizen_id: str, spouse_id: str, marriage_date: date, marriage_certificate_no: str) -> bool:
        """Update citizen's marital status and spouse ID."""
        try:
            logger.info(f"Updating marriage status for citizen {citizen_id} to spouse {spouse_id}")
            
            # Call stored procedure instead of direct SQL
            query = text("""
                EXEC [API_Internal].[UpdateCitizenMarriageStatus]
                    @citizen_id = :citizen_id,
                    @spouse_citizen_id = :spouse_id,
                    @marriage_date = :marriage_date,
                    @marriage_certificate_no = :marriage_certificate_no,
                    @updated_by = 'KAFKA_CONSUMER'
            """)
            
            result = self.db.execute(query, {
                "citizen_id": citizen_id,
                "spouse_id": spouse_id,
                "marriage_date": marriage_date,
                "marriage_certificate_no": marriage_certificate_no
            })
            
            # Get the affected_rows output parameter
            row = result.fetchone()
            affected_rows = row[0] if row else 0
            
            if affected_rows > 0:
                self.db.commit()
                logger.info(f"Successfully updated marriage status for citizen {citizen_id}")
                return True
            else:
                logger.warning(f"No rows updated for citizen {citizen_id}. Citizen may already be married or doesn't exist.")
                return False
                
        except Exception as e:
            self.db.rollback()
            logger.error(f"Database error when updating marriage status: {e}", exc_info=True)
            raise e
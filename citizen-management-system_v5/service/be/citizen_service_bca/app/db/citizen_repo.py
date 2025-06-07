from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import Optional, List, Dict, Any
from datetime import date
from fastapi import HTTPException, status
import logging
from app.schemas.household import HouseholdDetailResponse, HouseholdMemberDetailResponse # Thêm import này
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
        
    def update_divorce_status(self, citizen_id: str, former_spouse_citizen_id: str, divorce_date: date, judgment_no: str) -> bool:
        """Cập nhật trạng thái ly hôn của công dân."""
        try:
            logger.info(f"Updating divorce status for citizen {citizen_id} from marriage with {former_spouse_citizen_id}")
            
            query = text("""
                EXEC [API_Internal].[UpdateCitizenDivorceStatus]
                    @citizen_id = :citizen_id,
                    @former_spouse_citizen_id = :former_spouse_citizen_id,
                    @divorce_date = :divorce_date,
                    @judgment_no = :judgment_no,
                    @updated_by = 'KAFKA_CONSUMER'
            """)
            
            result = self.db.execute(query, {
                "citizen_id": citizen_id,
                "former_spouse_citizen_id": former_spouse_citizen_id,
                "divorce_date": divorce_date,
                "judgment_no": judgment_no
            })
            
            row = result.fetchone()
            affected_rows = row[0] if row else 0 # Lấy giá trị trả về từ SP

            if affected_rows > 0:
                self.db.commit()
                logger.info(f"Successfully updated divorce status for citizen {citizen_id}")
                return True
            else:
                logger.warning(f"No rows updated for citizen {citizen_id}. Citizen may not exist or already divorced/not married to this spouse.")
                self.db.rollback()
                return False
                
        except Exception as e:
            self.db.rollback()
            logger.error(f"Database error when updating divorce status: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi cập nhật trạng thái ly hôn: {str(e)}"
            )
        
    def register_permanent_residence_owned_property(self, data: Dict[str, Any]) -> int:
        """
        Ghi dữ liệu đăng ký thường trú cho trường hợp công dân sở hữu chỗ ở hợp pháp.
        Gọi stored procedure API_Internal.RegisterPermanentResidence_OwnedProperty_DataOnly.
        """
        try:
            logger.info(f"Calling stored procedure RegisterPermanentResidence_OwnedProperty_DataOnly for citizen {data['citizen_id']}")
            
            # Chuẩn bị các tham số cho stored procedure
            params = data.copy()
            params['new_residence_history_id'] = None # Tham số output
            
            sql = text("""
                DECLARE @output_id BIGINT;
                EXEC [API_Internal].[RegisterPermanentResidence_OwnedProperty_DataOnly]
                    @citizen_id = :citizen_id,
                    @address_detail = :address_detail,
                    @ward_id = :ward_id,
                    @district_id = :district_id,
                    @province_id = :province_id,
                    @postal_code = :postal_code,
                    @latitude = :latitude,
                    @longitude = :longitude,
                    @ownership_certificate_id = :ownership_certificate_id,
                    @registration_date = :registration_date,
                    @issuing_authority_id = :issuing_authority_id,
                    @registration_number = :registration_number,
                    @registration_reason = :registration_reason,
                    @residence_expiry_date = :residence_expiry_date,
                    @previous_address_id = :previous_address_id,
                    @residence_status_change_reason_id = :residence_status_change_reason_id,
                    @document_url = :document_url,
                    @rh_verification_status = :rh_verification_status,
                    @rh_verification_date = :rh_verification_date,
                    @rh_verified_by = :rh_verified_by,
                    @registration_case_type = :registration_case_type,
                    @supporting_document_info = :supporting_document_info,
                    @notes = :notes,
                    @updated_by = :updated_by,
                    @cs_description = :cs_description,
                    @cs_cause = :cs_cause,
                    @cs_location = :cs_location,
                    @cs_authority_id = :cs_authority_id,
                    @cs_document_number = :cs_document_number,
                    @cs_document_date = :cs_document_date,
                    @cs_certificate_id = :cs_certificate_id,
                    @cs_reported_by = :cs_reported_by,
                    @cs_relationship = :cs_relationship,
                    @cs_verification_status = :cs_verification_status,
                    @ca_verification_status = :ca_verification_status,
                    @ca_verification_date = :ca_verification_date,
                    @ca_verified_by = :ca_verified_by,
                    @ca_notes = :ca_notes,
                    @new_residence_history_id = @output_id OUTPUT;
                SELECT @output_id AS new_id;
            """)
            
            result = self.db.execute(sql, params)
            new_id_row = result.fetchone()

            if new_id_row and new_id_row.new_id:
                self.db.commit()
                logger.info(f"Successfully registered permanent residence for citizen {data['citizen_id']} with new history ID: {new_id_row.new_id}")
                return new_id_row.new_id
            else:
                self.db.rollback()
                logger.error("Stored procedure RegisterPermanentResidence_OwnedProperty_DataOnly did not return a new ID.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Không thể tạo bản ghi đăng ký thường trú trong cơ sở dữ liệu."
                )
                
        except Exception as e:
            self.db.rollback()
            logger.error(f"Database error calling RegisterPermanentResidence_OwnedProperty_DataOnly: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi đăng ký thường trú: {str(e)}"
            )

    def check_address_match(
        self,
        gcnqs_property_address_id: int,
        registration_address_detail: str,
        registration_ward_id: int,
        registration_district_id: int,
        registration_province_id: int
    ) -> bool:
        """
        Kiểm tra xem địa chỉ tài sản trên GCNQS có khớp với địa chỉ đăng ký thường trú không.
        Gọi SQL Function API_Internal.MatchPropertyAndRegistrationAddress.
        """
        try:
            query = text("""
                SELECT [API_Internal].[MatchPropertyAndRegistrationAddress] (
                    :gcnqs_property_address_id,
                    :reg_address_detail,
                    :reg_ward_id,
                    :reg_district_id,
                    :reg_province_id
                ) AS IsMatch;
            """)
            result = self.db.execute(query, {
                "gcnqs_property_address_id": gcnqs_property_address_id,
                "reg_address_detail": registration_address_detail,
                "reg_ward_id": registration_ward_id,
                "reg_district_id": registration_district_id,
                "reg_province_id": registration_province_id
            }).scalar_one_or_none() # scalar_one_or_none() sẽ trả về giá trị đơn hoặc None

            if result is None:
                logger.error("SQL Function MatchPropertyAndRegistrationAddress không trả về giá trị.")
                return False # Hoặc ném lỗi tùy theo logic mong muốn
            return bool(result)

        except Exception as e:
            logger.error(f"Lỗi cơ sở dữ liệu khi kiểm tra khớp địa chỉ: {e}", exc_info=True)
            # Ném lại lỗi để tầng service có thể xử lý hoặc rollback transaction
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi kiểm tra khớp địa chỉ: {str(e)}"
            )
        
    def get_household_details_by_id(self, household_id: int) -> Optional[HouseholdDetailResponse]:
        """
        Lấy thông tin chi tiết của một hộ khẩu bao gồm các thành viên,
        sử dụng Stored Procedure API_Internal.GetHouseholdDetails.
        """
        try:
            # SQL Alchemy không hỗ trợ trực tiếp lấy nhiều result set từ một SP một cách dễ dàng
            # như các thư viện DB-API thuần túy.
            # Chúng ta sẽ sử dụng connection thuần để thực thi SP và xử lý result sets.
            
            conn = self.db.connection() # Lấy underlying DBAPI connection
            cursor = conn.connection.cursor() # Lấy cursor từ DBAPI connection
            
            sql_query = "EXEC [API_Internal].[GetHouseholdDetails] @household_id = ?"
            cursor.execute(sql_query, household_id)

            # Xử lý result set đầu tiên: Thông tin hộ khẩu
            household_data_row = cursor.fetchone()
            if not household_data_row:
                return None

            # Lấy tên cột từ cursor.description cho result set đầu tiên
            household_columns = [column[0] for column in cursor.description]
            household_info_dict = dict(zip(household_columns, household_data_row))

            # Chuyển sang result set tiếp theo: Danh sách thành viên
            if not cursor.nextset():
                # Nếu không có result set thứ hai, có thể hộ khẩu không có thành viên (ít khả năng)
                # hoặc SP không trả về đúng cách.
                logger.warning(f"Stored procedure GetHouseholdDetails không trả về result set thứ hai cho household_id: {household_id}")
                household_info_dict["members"] = []
            else:
                members_data_rows = cursor.fetchall()
                member_list = []
                if members_data_rows:
                    # Lấy tên cột cho result set thành viên
                    member_columns = [column[0] for column in cursor.description]
                    for row in members_data_rows:
                        member_info_dict = dict(zip(member_columns, row))
                        member_list.append(HouseholdMemberDetailResponse(**member_info_dict))
                household_info_dict["members"] = member_list
            
            cursor.close()
            conn.close() # Nhớ đóng connection

            return HouseholdDetailResponse(**household_info_dict)

        except Exception as e:
            logger.error(f"Lỗi cơ sở dữ liệu khi lấy chi tiết hộ khẩu ID {household_id}: {e}", exc_info=True)
            # Không ném HTTPException ở đây để service layer có thể xử lý hoặc ghi log thêm nếu cần
            # Hoặc có thể ném nếu đây là lỗi nghiêm trọng
            # raise HTTPException(status_code=500, detail=f"Lỗi DB: {str(e)}")
            return None

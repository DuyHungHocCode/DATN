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
                       limit: int = 20) -> List[Dict[str, Any]]:
        """Tìm kiếm danh sách công dân theo các tiêu chí bằng Stored Procedure."""
        try:
            query = text("""
                EXEC [API_Internal].[SearchCitizens]
                    @FullName = :full_name,
                    @DateOfBirth = :date_of_birth,
                    @Limit = :limit
            """)
            
            params = {
                "full_name": full_name,
                "date_of_birth": date_of_birth,
                "limit": limit
            }
            
            result = self.db.execute(query, params).fetchall()
            
            return [dict(row._mapping) for row in result]
            
        except Exception as e:
            logger.error(f"Database error in search_citizens: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail=f"Database error during citizen search: {str(e)}"
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

    def _map_reason_code_to_id(self, reason_code: str) -> int:
        """Maps a reason_code to a reason_id using a database function."""
        try:
            query = text("SELECT [API_Internal].[MapReasonCodeToId](:reason_code)")
            result = self.db.execute(query, {"reason_code": reason_code}).scalar()
            
            if result is None:
                logger.warning(f"Function MapReasonCodeToId returned NULL for code: {reason_code}. Defaulting to 2.")
                return 2 # Default to "Nhập hộ - Chuyển đến"
                
            logger.info(f"Mapped reason_code '{reason_code}' to reason_id {result}")
            return result
                
        except Exception as e:
            logger.error(f"Error mapping reason_code to reason_id: {e}", exc_info=True)
            return 2  # Default fallback

    def _validate_authority_id(self, authority_id: int) -> bool:
        """Validates if an authority_id exists and is active using a database function."""
        try:
            query = text("SELECT [API_Internal].[ValidateAuthorityId](:authority_id)")
            result = self.db.execute(query, {"authority_id": authority_id}).scalar()
            
            if bool(result):
                logger.info(f"Authority ID {authority_id} validation passed")
                return True
            else:
                logger.warning(f"Authority ID {authority_id} not found or inactive")
                return False
        except Exception as e:
            logger.error(f"Error validating authority_id: {e}", exc_info=True)
            return False

    def _validate_relationship_with_head_id(self, citizen_id: str, to_household_id: int, rel_with_head_id: int) -> Dict[str, Any]:
        """
        Validates the household relationship using the dedicated stored procedure.
        """
        try:
            query = text("""
                DECLARE @validation_result BIT;
                DECLARE @error_code VARCHAR(20);
                DECLARE @error_message NVARCHAR(500);
                DECLARE @warning_message NVARCHAR(500);
                
                EXEC [API_Internal].[ValidateHouseholdRelationship]
                    @citizen_id = :citizen_id,
                    @to_household_id = :to_household_id,
                    @relationship_with_head_id = :relationship_with_head_id,
                    @validation_result = @validation_result OUTPUT,
                    @error_code = @error_code OUTPUT,
                    @error_message = @error_message OUTPUT,
                    @warning_message = @warning_message OUTPUT;
                
                SELECT @validation_result AS validation_result,
                       @error_code AS error_code,
                       @error_message AS error_message,
                       @warning_message AS warning_message;
            """)
            
            result = self.db.execute(query, {
                "citizen_id": citizen_id,
                "to_household_id": to_household_id,
                "relationship_with_head_id": rel_with_head_id
            }).fetchone()
            
            if result:
                validation_result = {
                    'is_valid': bool(result.validation_result),
                    'error_code': result.error_code,
                    'error_message': result.error_message,
                    'warning_message': result.warning_message
                }
                
                if validation_result['is_valid']:
                    logger.info(f"Relationship validation passed for citizen {citizen_id} -> household {to_household_id} with relationship {rel_with_head_id}")
                    if validation_result['warning_message']:
                        logger.warning(f"Validation warning: {validation_result['warning_message']}")
                else:
                    logger.warning(f"Relationship validation failed: {validation_result['error_code']} - {validation_result['error_message']}")
                
                return validation_result
            else:
                logger.error("Stored procedure ValidateHouseholdRelationship did not return result")
                return {
                    'is_valid': False,
                    'error_code': 'VALIDATION_ERROR',
                    'error_message': 'Lỗi hệ thống khi xác minh mối quan hệ.',
                    'warning_message': None
                }
                
        except Exception as e:
            logger.error(f"Error validating relationship_with_head_id: {e}", exc_info=True)
            return {
                'is_valid': False,
                'error_code': 'VALIDATION_ERROR',
                'error_message': f'Lỗi hệ thống khi xác minh mối quan hệ: {str(e)}',
                'warning_message': None
            }

    def add_household_member(self, request_data) -> Dict[str, Any]:
        """
        Thêm một công dân (chưa có hộ khẩu) vào hộ khẩu đã tồn tại.
        Gọi stored procedure API_Internal.AddHouseholdMember.
        """
        try:
            logger.info(f"Adding household member: citizen {request_data.citizen_id} to household {request_data.to_household_id}")
            
            # Note: Comprehensive relationship validation (3 levels) is now handled at router level
            # Map reason_code to reason_id
            reason_id = self._map_reason_code_to_id(request_data.reason_code)
            
            # Chuẩn bị parameters cho stored procedure
            sql = text("""
                DECLARE @new_household_member_id BIGINT;
                DECLARE @new_log_id INT;
                DECLARE @new_residence_history_id BIGINT;
                
                EXEC [API_Internal].[AddHouseholdMember]
                    @citizen_id = :citizen_id,
                    @to_household_id = :to_household_id,
                    @relationship_with_head_id = :relationship_with_head_id,
                    @effective_date = :effective_date,
                    @reason_id = :reason_id,
                    @issuing_authority_id = :issuing_authority_id,
                    @created_by_user_id = :created_by_user_id,
                    @notes = :notes,
                    @new_household_member_id = @new_household_member_id OUTPUT,
                    @new_log_id = @new_log_id OUTPUT,
                    @new_residence_history_id = @new_residence_history_id OUTPUT;
                
                SELECT @new_household_member_id AS household_member_id, 
                       @new_log_id AS log_id,
                       @new_residence_history_id AS residence_history_id;
            """)
            
            params = {
                "citizen_id": request_data.citizen_id,
                "to_household_id": request_data.to_household_id,
                "relationship_with_head_id": request_data.relationship_with_head_id,
                "effective_date": request_data.effective_date,
                "reason_id": reason_id,
                "issuing_authority_id": request_data.issuing_authority_id,
                "created_by_user_id": request_data.created_by_user_id,
                "notes": request_data.notes
            }
            
            result = self.db.execute(sql, params)
            output_row = result.fetchone()
            
            if output_row:
                self.db.commit()
                logger.info(f"Successfully added household member: log_id={output_row.log_id}, household_member_id={output_row.household_member_id}")
                
                # Trả về response theo schema HouseholdChangeResponse
                from app.schemas.household_change import HouseholdChangeResponse
                
                return HouseholdChangeResponse(
                    success=True,
                    message=f"Đã thêm công dân {request_data.citizen_id} vào hộ khẩu {request_data.to_household_id} thành công.",
                    log_id=output_row.log_id,
                    household_member_id=output_row.household_member_id
                )
            else:
                self.db.rollback()
                logger.error("Stored procedure AddHouseholdMember did not return expected output.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Không thể thêm thành viên vào hộ khẩu. Vui lòng thử lại."
                )
                
        except Exception as e:
            self.db.rollback()
            logger.error(f"Database error when adding household member: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi thêm thành viên hộ khẩu: {str(e)}"
            )

    def transfer_household_member(self, request_data) -> Dict[str, Any]:
        """
        Chuyển một công dân từ hộ khẩu này sang hộ khẩu khác.
        Gọi stored procedure API_Internal.TransferHouseholdMember.
        """
        try:
            logger.info(f"Transferring household member: citizen {request_data.citizen_id} from household {request_data.from_household_id} to household {request_data.to_household_id}")
            
            # Note: Comprehensive relationship validation (3 levels) is now handled at router level
            # Map reason_code to reason_id
            reason_id = self._map_reason_code_to_id(request_data.reason_code)
            
            # Chuẩn bị parameters cho stored procedure
            sql = text("""
                DECLARE @old_household_member_id BIGINT;
                DECLARE @new_household_member_id BIGINT;
                DECLARE @new_log_id INT;
                DECLARE @new_residence_history_id BIGINT;
                
                EXEC [API_Internal].[TransferHouseholdMember]
                    @citizen_id = :citizen_id,
                    @from_household_id = :from_household_id,
                    @to_household_id = :to_household_id,
                    @relationship_with_head_id = :relationship_with_head_id,
                    @effective_date = :effective_date,
                    @reason_id = :reason_id,
                    @issuing_authority_id = :issuing_authority_id,
                    @created_by_user_id = :created_by_user_id,
                    @notes = :notes,
                    @old_household_member_id = @old_household_member_id OUTPUT,
                    @new_household_member_id = @new_household_member_id OUTPUT,
                    @new_log_id = @new_log_id OUTPUT,
                    @new_residence_history_id = @new_residence_history_id OUTPUT;
                
                SELECT @old_household_member_id AS old_household_member_id,
                       @new_household_member_id AS new_household_member_id, 
                       @new_log_id AS log_id,
                       @new_residence_history_id AS residence_history_id;
            """)
            
            params = {
                "citizen_id": request_data.citizen_id,
                "from_household_id": request_data.from_household_id,
                "to_household_id": request_data.to_household_id,
                "relationship_with_head_id": request_data.relationship_with_head_id,
                "effective_date": request_data.effective_date,
                "reason_id": reason_id,
                "issuing_authority_id": request_data.issuing_authority_id,
                "created_by_user_id": request_data.created_by_user_id,
                "notes": request_data.notes
            }
            
            result = self.db.execute(sql, params)
            output_row = result.fetchone()
            
            if output_row:
                self.db.commit()
                logger.info(f"Successfully transferred household member: log_id={output_row.log_id}, new_household_member_id={output_row.new_household_member_id}")
                
                # Trả về response theo schema HouseholdChangeResponse
                from app.schemas.household_change import HouseholdChangeResponse
                return HouseholdChangeResponse(
                    success=True,
                    message=f"Đã chuyển công dân {request_data.citizen_id} từ hộ khẩu {request_data.from_household_id} sang hộ khẩu {request_data.to_household_id} thành công.",
                    log_id=output_row.log_id,
                    household_member_id=output_row.new_household_member_id
                )
            else:
                self.db.rollback()
                logger.error("Stored procedure TransferHouseholdMember did not return expected output.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Không thể chuyển thành viên hộ khẩu. Vui lòng thử lại."
                )
                
        except Exception as e:
            self.db.rollback()
            logger.error(f"Database error when transferring household member: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi chuyển thành viên hộ khẩu: {str(e)}"
            )

    def find_household_by_id(self, household_id: int) -> Optional[Dict[str, Any]]:
        """Finds a household by its ID using a stored procedure."""
        try:
            query = text("EXEC [API_Internal].[FindHouseholdById] @household_id = :household_id")
            result = self.db.execute(query, {"household_id": household_id}).fetchone()
            if result:
                return dict(result._mapping)
            return None
        except Exception as e:
            logger.error(f"Error finding household by id {household_id}: {e}", exc_info=True)
            raise

    def is_citizen_in_active_household(self, citizen_id: str) -> bool:
        """Checks if a citizen is part of any active household using a database function."""
        try:
            query = text("SELECT [API_Internal].[IsCitizenInActiveHousehold](:citizen_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id}).scalar()
            return bool(result)
        except Exception as e:
            logger.error(f"Error checking if citizen {citizen_id} is in active household: {e}", exc_info=True)
            raise

    def is_citizen_member_of_household(self, citizen_id: str, household_id: int) -> bool:
        """Checks if a citizen is a member of a specific household using a database function."""
        try:
            query = text("SELECT [API_Internal].[IsCitizenMemberOfHousehold](:citizen_id, :household_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id, "household_id": household_id}).scalar()
            return bool(result)
        except Exception as e:
            logger.error(f"Error checking if citizen {citizen_id} is member of household {household_id}: {e}", exc_info=True)
            raise

    def is_citizen_head_of_household(self, citizen_id: str, household_id: int) -> bool:
        """Checks if a citizen is the head of a specific household using a database function."""
        try:
            query = text("SELECT [API_Internal].[IsCitizenHeadOfHousehold](:citizen_id, :household_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id, "household_id": household_id}).scalar()
            return bool(result)
        except Exception as e:
            logger.error(f"Error checking if citizen {citizen_id} is head of household {household_id}: {e}", exc_info=True)
            raise

    def count_active_household_members_excluding_citizen(self, household_id: int, exclude_citizen_id: str) -> int:
        """Counts active members in a household, excluding a specific citizen, using a database function."""
        try:
            query = text("SELECT [API_Internal].[CountActiveHouseholdMembersExcludingCitizen](:household_id, :exclude_citizen_id)")
            result = self.db.execute(query, {"household_id": household_id, "exclude_citizen_id": exclude_citizen_id}).scalar()
            return result if result is not None else 0
        except Exception as e:
            logger.error(f"Error counting members in household {household_id}: {e}", exc_info=True)
            raise

    def remove_household_member(self, household_id: int, citizen_id: str, request_data) -> Dict[str, Any]:
        """
        Removes a member from a household using the RemoveHouseholdMember stored procedure.
        """
        try:
            logger.info(f"Removing household member: citizen {citizen_id} from household {household_id}")
            
            # Map reason_code to reason_id
            reason_id = self._map_reason_code_to_id(request_data.reason_code)
            
            # Chuẩn bị parameters cho stored procedure
            sql = text("""
                DECLARE @removed_household_member_id BIGINT;
                DECLARE @new_log_id INT;
                
                EXEC [API_Internal].[RemoveHouseholdMember]
                    @household_id = :household_id,
                    @citizen_id = :citizen_id,
                    @reason_id = :reason_id,
                    @issuing_authority_id = :issuing_authority_id,
                    @created_by_user_id = :created_by_user_id,
                    @notes = :notes,
                    @removed_household_member_id = @removed_household_member_id OUTPUT,
                    @new_log_id = @new_log_id OUTPUT;
                
                SELECT @removed_household_member_id AS household_member_id, 
                       @new_log_id AS log_id;
            """)
            
            params = {
                "household_id": household_id,
                "citizen_id": citizen_id,
                "reason_id": reason_id,
                "issuing_authority_id": request_data.issuing_authority_id,
                "created_by_user_id": request_data.created_by_user_id,
                "notes": request_data.notes
            }
            
            result = self.db.execute(sql, params)
            output_row = result.fetchone()
            
            if output_row:
                self.db.commit()
                logger.info(f"Successfully removed household member: log_id={output_row.log_id}, household_member_id={output_row.household_member_id}")
                
                # Trả về response theo schema HouseholdChangeResponse
                from app.schemas.household_change import HouseholdChangeResponse
                
                return HouseholdChangeResponse(
                    success=True,
                    message=f"Đã xóa công dân {citizen_id} khỏi hộ khẩu {household_id} thành công.",
                    log_id=output_row.log_id,
                    household_member_id=output_row.household_member_id
                )
            else:
                self.db.rollback()
                logger.error("Stored procedure RemoveHouseholdMember did not return expected output.")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Không thể xóa thành viên khỏi hộ khẩu. Vui lòng thử lại."
                )
                
        except Exception as e:
            self.db.rollback()
            logger.error(f"Error removing household member: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"An error occurred while removing the household member: {str(e)}"
            )

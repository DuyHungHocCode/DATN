# civil_status_service_btp/app/db/civil_status_repo.py
from sqlalchemy.orm import Session
from sqlalchemy import text, select
from sqlalchemy.exc import SQLAlchemyError
from fastapi import HTTPException, status
import logging

from app.schemas.death_certificate import DeathCertificateCreate, DeathCertificateResponse
from app.schemas.marriage_certificate import MarriageCertificateCreate
logger = logging.getLogger(__name__)

class CivilStatusRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_death_certificate(self, certificate: DeathCertificateCreate) -> int | None:
        """
        Gọi stored procedure API_Internal.InsertDeathCertificate để thêm bản ghi.
        Trả về ID của bản ghi mới được tạo hoặc None nếu thất bại.
        """
        try:
            # Chuẩn bị các tham số cho stored procedure
            params = certificate.model_dump() # Chuyển Pydantic model thành dict
            params['new_death_certificate_id'] = None # Tham số output

            # Tạo câu lệnh SQL để thực thi procedure
            # Lưu ý: Cần kiểm tra cú pháp EXEC và truyền tham số OUTPUT cho SQL Server
            sql = text("""
                DECLARE @output_id BIGINT;
                EXEC [API_Internal].[InsertDeathCertificate]
                    @citizen_id = :citizen_id,
                    @death_certificate_no = :death_certificate_no,
                    @book_id = :book_id,
                    @page_no = :page_no,
                    @date_of_death = :date_of_death,
                    @time_of_death = :time_of_death,
                    @place_of_death_detail = :place_of_death_detail,
                    @place_of_death_ward_id = :place_of_death_ward_id,
                    @cause_of_death = :cause_of_death,
                    @declarant_name = :declarant_name,
                    @declarant_citizen_id = :declarant_citizen_id,
                    @declarant_relationship = :declarant_relationship,
                    @registration_date = :registration_date,
                    @issuing_authority_id = :issuing_authority_id,
                    @death_notification_no = :death_notification_no,
                    @witness1_name = :witness1_name,
                    @witness2_name = :witness2_name,
                    @notes = :notes,
                    @new_death_certificate_id = @output_id OUTPUT;
                SELECT @output_id AS new_id;
            """)

            # Thực thi procedure và lấy kết quả (ID mới)
            result = self.db.execute(sql, params)
            new_id_row = result.fetchone()

            if new_id_row and new_id_row.new_id:
                self.db.commit() # Commit transaction nếu procedure chạy thành công (trong procedure có transaction riêng)
                return new_id_row.new_id
            else:
                # Trường hợp procedure không trả về ID (có thể do lỗi logic trong procedure)
                logger.error("Stored procedure InsertDeathCertificate did not return a new ID.")
                self.db.rollback()
                return None

        except SQLAlchemyError as e:
            self.db.rollback()
            logger.error(f"Database error calling InsertDeathCertificate: {e}", exc_info=True)
            # Ném lỗi cụ thể hơn nếu cần phân biệt lỗi ràng buộc, kết nối,...
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi đăng ký khai tử: {e}"
            )
        except Exception as e:
            self.db.rollback()
            logger.error(f"Unexpected error calling InsertDeathCertificate: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi không xác định khi đăng ký khai tử: {str(e)}"
            )

    def get_death_certificate_by_id(self, certificate_id: int) -> DeathCertificateResponse | None:
        """Lấy thông tin giấy chứng tử theo ID."""
        try:
            # Query trực tiếp từ bảng DeathCertificate và các bảng Reference cần thiết
            query = text("""
                SELECT 
                    dc.*,
                    w.ward_name AS place_of_death_ward_name,
                    d.district_name AS place_of_death_district_name,
                    p.province_name AS place_of_death_province_name,
                    a.authority_name AS issuing_authority_name
                FROM 
                    [BTP].[DeathCertificate] dc
                    LEFT JOIN [Reference].[Wards] w ON dc.place_of_death_ward_id = w.ward_id
                    LEFT JOIN [Reference].[Districts] d ON dc.place_of_death_district_id = d.district_id
                    LEFT JOIN [Reference].[Provinces] p ON dc.place_of_death_province_id = p.province_id
                    LEFT JOIN [Reference].[Authorities] a ON dc.issuing_authority_id = a.authority_id
                WHERE 
                    dc.death_certificate_id = :certificate_id
            """)
            
            result = self.db.execute(query, {"certificate_id": certificate_id}).fetchone()
            
            if not result:
                return None
                
            # Chuyển đổi Row thành dict
            data = {key: value for key, value in result._mapping.items()}
            
            # Tạo response object
            return DeathCertificateResponse.model_validate(data)
            
        except SQLAlchemyError as e:
            logger.error(f"Database error getting death certificate by ID {certificate_id}: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi lấy thông tin giấy chứng tử: {str(e)}"
            )
    def check_existing_death_certificate(self, citizen_id: str) -> bool:
        """Kiểm tra xem công dân đã có giấy chứng tử chưa."""
        try:
            query = text("SELECT COUNT(*) FROM [BTP].[DeathCertificate] WHERE [citizen_id] = :citizen_id")
            result = self.db.execute(query, {"citizen_id": citizen_id}).scalar()
            return result > 0
        except SQLAlchemyError as e:
            logger.error(f"Database error when checking existing death certificate: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi kiểm tra giấy chứng tử: {str(e)}"
            )
        
    def create_marriage_certificate(self, certificate: MarriageCertificateCreate) -> int | None:
        """
        Gọi stored procedure API_Internal.InsertMarriageCertificate để đăng ký kết hôn.
        """
        try:
            # Chuẩn bị các tham số cho stored procedure
            params = certificate.model_dump()
            params['new_marriage_certificate_id'] = None # Tham số output

            # Tạo câu lệnh SQL để thực thi procedure
            sql = text("""
                DECLARE @output_id BIGINT;
                EXEC [API_Internal].[InsertMarriageCertificate]
                    @marriage_certificate_no = :marriage_certificate_no,
                    @book_id = :book_id,
                    @page_no = :page_no,
                    @husband_id = :husband_id,
                    @husband_full_name = :husband_full_name,
                    @husband_date_of_birth = :husband_date_of_birth,
                    @husband_nationality_id = :husband_nationality_id,
                    @husband_previous_marriage_status = :husband_previous_marriage_status,
                    @wife_id = :wife_id,
                    @wife_full_name = :wife_full_name,
                    @wife_date_of_birth = :wife_date_of_birth,
                    @wife_nationality_id = :wife_nationality_id,
                    @wife_previous_marriage_status = :wife_previous_marriage_status,
                    @marriage_date = :marriage_date,
                    @registration_date = :registration_date,
                    @issuing_authority_id = :issuing_authority_id,
                    @issuing_place = :issuing_place,
                    @witness1_name = :witness1_name,
                    @witness2_name = :witness2_name,
                    @notes = :notes,
                    @new_marriage_certificate_id = @output_id OUTPUT;
                SELECT @output_id AS new_id;
            """)

            # Thực thi procedure và lấy kết quả
            result = self.db.execute(sql, params)
            new_id_row = result.fetchone()

            if new_id_row and new_id_row.new_id:
                self.db.commit()
                return new_id_row.new_id
            else:
                logger.error("Stored procedure InsertMarriageCertificate did not return a new ID")
                self.db.rollback()
                return None

        except SQLAlchemyError as e:
            self.db.rollback()
            logger.error(f"Database error calling InsertMarriageCertificate: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi đăng ký kết hôn: {e}"
            )
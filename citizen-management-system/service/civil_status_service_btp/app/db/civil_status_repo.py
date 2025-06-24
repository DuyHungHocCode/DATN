# civil_status_service_btp/app/db/civil_status_repo.py
from sqlalchemy.orm import Session
from sqlalchemy import text, select
from sqlalchemy.exc import SQLAlchemyError
from fastapi import HTTPException, status
import logging

from app.schemas.death_certificate import DeathCertificateCreate, DeathCertificateResponse
from app.schemas.marriage_certificate import MarriageCertificateCreate
from app.schemas.divorce_record import DivorceRecordCreate 
from app.schemas.birth_certificate import BirthCertificateCreate

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
                    @place_of_death_district_id = :place_of_death_district_id, 
                    @place_of_death_province_id = :place_of_death_province_id, 
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
        """Lấy thông tin giấy chứng tử theo ID bằng Stored Procedure."""
        try:
            query = text("EXEC [API_Internal].[GetDeathCertificateById] @certificate_id = :certificate_id")
            result_row = self.db.execute(query, {"certificate_id": certificate_id}).fetchone()
            
            if not result_row:
                return None
            
            return dict(result_row._mapping) 
            
        except SQLAlchemyError as e:
            logger.error(f"Database error getting death certificate by ID {certificate_id}: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi lấy thông tin giấy chứng tử: {str(e)}"
            )
        
    def check_existing_death_certificate(self, citizen_id: str) -> bool:
        """Kiểm tra xem công dân đã có giấy chứng tử chưa bằng Function."""
        try:
            query = text("SELECT [API_Internal].[CheckExistingDeathCertificate](:citizen_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id}).scalar()
            return bool(result)
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
                    @husband_previous_marital_status_id = :husband_previous_marital_status_id,
                    @wife_id = :wife_id,
                    @wife_full_name = :wife_full_name,
                    @wife_date_of_birth = :wife_date_of_birth,
                    @wife_nationality_id = :wife_nationality_id,
                    @wife_previous_marital_status_id = :wife_previous_marital_status_id,
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
    
    def get_marriage_certificate_details(self, marriage_certificate_id: int) -> dict | None:
        """Lấy chi tiết giấy chứng nhận kết hôn bằng Stored Procedure."""
        try:
            query = text("EXEC [API_Internal].[GetMarriageCertificateDetails] @marriage_certificate_id = :marriage_certificate_id")
            result = self.db.execute(query, {"marriage_certificate_id": marriage_certificate_id}).fetchone()
            if result:
                return dict(result._mapping)
            return None
        except SQLAlchemyError as e:
            logger.error(f"Database error getting marriage certificate details: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi lấy thông tin giấy chứng nhận kết hôn: {str(e)}"
            )

    def create_divorce_record(self, record: DivorceRecordCreate) -> int | None:
        """
        Gọi stored procedure API_Internal.InsertDivorceRecord để đăng ký ly hôn.
        """
        try:
            params = record.model_dump()
            params['new_divorce_record_id'] = None

            sql = text("""
                DECLARE @output_id BIGINT;
                EXEC [API_Internal].[InsertDivorceRecord]
                    @divorce_certificate_no = :divorce_certificate_no,
                    @book_id = :book_id,
                    @page_no = :page_no,
                    @marriage_certificate_id = :marriage_certificate_id,
                    @divorce_date = :divorce_date,
                    @registration_date = :registration_date,
                    @court_name = :court_name,
                    @judgment_no = :judgment_no,
                    @judgment_date = :judgment_date,
                    @issuing_authority_id = :issuing_authority_id,
                    @reason = :reason,
                    @child_custody = :child_custody,
                    @property_division = :property_division,
                    @new_divorce_record_id = @output_id OUTPUT;
                SELECT @output_id AS new_id;
            """)

            result = self.db.execute(sql, params)
            new_id_row = result.fetchone()

            if new_id_row and new_id_row.new_id:
                self.db.commit()
                return new_id_row.new_id
            else:
                logger.error("Stored procedure InsertDivorceRecord did not return a new ID")
                self.db.rollback()
                return None

        except SQLAlchemyError as e:
            self.db.rollback()
            logger.error(f"Database error calling InsertDivorceRecord: {e}", exc_info=True)
            # Kiểm tra lỗi ràng buộc cụ thể nếu cần
            if "FK_DivorceRecord_MarriageCertificate" in str(e):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="ID giấy chứng nhận kết hôn không tồn tại hoặc không hợp lệ."
                )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi đăng ký ly hôn: {e}"
            )
        except Exception as e:
            self.db.rollback()
            logger.error(f"Unexpected error calling InsertDivorceRecord: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi không xác định khi đăng ký ly hôn: {str(e)}"
            )


    def create_birth_certificate(self, certificate: BirthCertificateCreate) -> int | None:
        """
        Gọi stored procedure API_Internal.InsertBirthCertificate để thêm bản ghi.
        """
        try:
            params = certificate.model_dump()
            params['new_birth_certificate_id'] = None # Tham số output

            sql = text("""
                DECLARE @output_id BIGINT;
                EXEC [API_Internal].[InsertBirthCertificate]
                    @citizen_id = :citizen_id,
                    @full_name = :full_name,
                    @birth_certificate_no = :birth_certificate_no,
                    @registration_date = :registration_date,
                    @book_id = :book_id,
                    @page_no = :page_no,
                    @issuing_authority_id = :issuing_authority_id,
                    @place_of_birth = :place_of_birth,
                    @date_of_birth = :date_of_birth,
                    @gender_id = :gender_id,
                    @father_full_name = :father_full_name,
                    @father_citizen_id = :father_citizen_id,
                    @father_date_of_birth = :father_date_of_birth,
                    @father_nationality_id = :father_nationality_id,
                    @mother_full_name = :mother_full_name,
                    @mother_citizen_id = :mother_citizen_id,
                    @mother_date_of_birth = :mother_date_of_birth,
                    @mother_nationality_id = :mother_nationality_id,
                    @declarant_name = :declarant_name,
                    @declarant_citizen_id = :declarant_citizen_id,
                    @declarant_relationship = :declarant_relationship,
                    @witness1_name = :witness1_name,
                    @witness2_name = :witness2_name,
                    @birth_notification_no = :birth_notification_no,
                    @notes = :notes,
                    @new_birth_certificate_id = @output_id OUTPUT;
                SELECT @output_id AS new_id;
            """)

            result = self.db.execute(sql, params)
            new_id_row = result.fetchone()

            if new_id_row and new_id_row.new_id:
                self.db.commit()
                return new_id_row.new_id
            else:
                logger.error("Stored procedure InsertBirthCertificate did not return a new ID.")
                self.db.rollback()
                return None

        except SQLAlchemyError as e:
            self.db.rollback()
            logger.error(f"Database error calling InsertBirthCertificate: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi đăng ký khai sinh: {str(e)}"
            )
        except Exception as e:
            self.db.rollback()
            logger.error(f"Unexpected error calling InsertBirthCertificate: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi không xác định khi đăng ký khai sinh: {str(e)}"
            )
        
    def get_birth_certificate_by_id(self, certificate_id: int) -> dict | None:
        """Lấy thông tin giấy khai sinh theo ID bằng Stored Procedure."""
        try:
            query = text("EXEC [API_Internal].[GetBirthCertificateById] @certificate_id = :certificate_id")
            result = self.db.execute(query, {"certificate_id": certificate_id}).fetchone()
            if result:
                return dict(result._mapping)
            return None
        except SQLAlchemyError as e:
            logger.error(f"Database error in get_birth_certificate_by_id: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi lấy giấy khai sinh: {e}"
            )
    
    def check_existing_birth_certificate_for_citizen(self, citizen_id: str) -> bool:
        """Kiểm tra xem công dân đã có giấy khai sinh chưa bằng Function."""
        try:
            query = text("SELECT [API_Internal].[CheckExistingBirthCertificateForCitizen](:citizen_id)")
            result = self.db.execute(query, {"citizen_id": citizen_id}).scalar()
            return bool(result)
        except SQLAlchemyError as e:
            logger.error(f"Database error in check_existing_birth_certificate_for_citizen: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi cơ sở dữ liệu khi kiểm tra giấy khai sinh: {e}"
            )
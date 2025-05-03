# civil_status_service_btp/app/services/marriage_validator.py
import logging
from datetime import date
from typing import Dict, List, Tuple, Any, Set
import json
from fastapi import HTTPException, status
from app.services.bca_client import BCAClient

logger = logging.getLogger(__name__)

class MarriageValidator:
    """Lớp xác thực các điều kiện kết hôn theo luật Việt Nam."""
    
    def __init__(self):
        self.min_age_male = 20
        self.min_age_female = 18
    
    def calculate_age(self, birth_date: date) -> int:
        """Tính tuổi từ ngày sinh."""
        today = date.today()
        return today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
    
    def validate_age_requirements(self, husband_dob: date, wife_dob: date) -> Tuple[bool, str]:
        """Xác thực tuổi tối thiểu của cặp đôi."""
        husband_age = self.calculate_age(husband_dob)
        wife_age = self.calculate_age(wife_dob)
        
        if husband_age < self.min_age_male:
            return False, f"Người chồng chưa đủ tuổi kết hôn (yêu cầu tối thiểu {self.min_age_male} tuổi, hiện tại {husband_age} tuổi)"
            
        if wife_age < self.min_age_female:
            return False, f"Người vợ chưa đủ tuổi kết hôn (yêu cầu tối thiểu {self.min_age_female} tuổi, hiện tại {wife_age} tuổi)"
            
        return True, ""
    
    def validate_marital_status(self, husband_status: str, wife_status: str) -> Tuple[bool, str]:
        """Xác thực cả hai người đều độc thân."""
            # Only block if already married
        if husband_status == "Đã kết hôn":
            return False, f"Người chồng đã kết hôn (hiện tại: {husband_status})"
            
        if wife_status == "Đã kết hôn":
            return False, f"Người vợ đã kết hôn (hiện tại: {wife_status})"
            
        return True, ""
    
    def are_blood_relatives(self, husband_tree: Dict[str, Any], wife_tree: Dict[str, Any]) -> Tuple[bool, str]:
        """
        Kiểm tra xem vợ chồng có quan hệ huyết thống trong phạm vi 3 đời không.
        Hàm này được thiết kế để xử lý dữ liệu thiếu hoặc không đầy đủ.
        
        Args:
            husband_tree: Dữ liệu cây phả hệ của chồng
            wife_tree: Dữ liệu cây phả hệ của vợ
            
        Returns:
            Tuple[bool, str]: (Có quan hệ hay không, Mô tả chi tiết nếu có)
        """
        try:
            # Đảm bảo cấu trúc cơ bản tồn tại, nếu không thì khởi tạo cấu trúc trống
            husband_family_members = husband_tree.get("family_members", []) if husband_tree else []
            wife_family_members = wife_tree.get("family_members", []) if wife_tree else []
            
            husband_id = husband_tree.get("citizen_id", "") if husband_tree else ""
            wife_id = wife_tree.get("citizen_id", "") if wife_tree else ""
            
            if not husband_id or not wife_id:
                # Ghi log cảnh báo nhưng vẫn tiếp tục
                logger.warning("Thiếu ID công dân trong dữ liệu cây phả hệ")
            
            # Trích xuất ID của họ hàng huyết thống từ cây phả hệ của chồng
            husband_blood_relations = {}
            for member in husband_family_members:
                # Sử dụng get() với giá trị mặc định để tránh lỗi khi thiếu trường
                member_id = member.get("citizen_id", "")
                if not member_id:
                    continue  # Bỏ qua thành viên không có ID
                    
                relation_path = member.get("relationship_path", "")
                # Chỉ xét các quan hệ huyết thống (loại trừ quan hệ hôn nhân)
                if relation_path and "Vợ" not in relation_path and "Chồng" not in relation_path:
                    husband_blood_relations[member_id] = {
                        "level": member.get("level_id", 0),
                        "relation": relation_path,
                        "name": member.get("full_name", "Không có tên")
                    }
            
            # Trích xuất ID của họ hàng huyết thống từ cây phả hệ của vợ
            wife_blood_relations = {}
            for member in wife_family_members:
                # Tương tự, xử lý an toàn khi thiếu trường
                member_id = member.get("citizen_id", "")
                if not member_id:
                    continue  # Bỏ qua thành viên không có ID
                    
                relation_path = member.get("relationship_path", "")
                if relation_path and "Vợ" not in relation_path and "Chồng" not in relation_path:
                    wife_blood_relations[member_id] = {
                        "level": member.get("level_id", 0),
                        "relation": relation_path,
                        "name": member.get("full_name", "Không có tên")
                    }
            
            # Nếu không có đủ thông tin để phân tích, ghi log cảnh báo
            if len(husband_blood_relations) <= 1 or len(wife_blood_relations) <= 1:
                logger.warning(
                    f"Dữ liệu phả hệ không đầy đủ: Chồng {len(husband_blood_relations)} người, "
                    f"Vợ {len(wife_blood_relations)} người"
                )
            
            # 1. Kiểm tra nếu vợ xuất hiện trong cây phả hệ huyết thống của chồng
            if wife_id and wife_id in husband_blood_relations:
                relation = husband_blood_relations[wife_id]["relation"]
                return True, f"Phát hiện quan hệ huyết thống: Người vợ là {relation} của người chồng"
            
            # 2. Kiểm tra nếu chồng xuất hiện trong cây phả hệ huyết thống của vợ
            if husband_id and husband_id in wife_blood_relations:
                relation = wife_blood_relations[husband_id]["relation"]
                return True, f"Phát hiện quan hệ huyết thống: Người chồng là {relation} của người vợ"
            
            # 3. Kiểm tra các họ hàng chung (giao nhau của tập hợp ID)
            common_relatives = set(husband_blood_relations.keys()).intersection(set(wife_blood_relations.keys()))
            if common_relatives:
                relative_info = []
                for relative_id in common_relatives:
                    # Lấy thông tin của người họ hàng chung
                    husband_relation = husband_blood_relations[relative_id]["relation"]
                    wife_relation = wife_blood_relations[relative_id]["relation"]
                    relative_name = husband_blood_relations[relative_id]["name"]
                    
                    # Thông tin đầy đủ về người họ hàng chung
                    relative_info.append(
                        f"{relative_name} (ID {relative_id}): {husband_relation} của chồng và {wife_relation} của vợ"
                    )
                
                return True, f"Phát hiện họ hàng huyết thống chung: {', '.join(relative_info)}"
            
            # Không tìm thấy quan hệ huyết thống
            return False, ""
            
        except Exception as e:
            # Ghi log lỗi nhưng vẫn trả về kết quả an toàn
            logger.error(f"Lỗi khi kiểm tra quan hệ huyết thống: {str(e)}", exc_info=True)
            return False, f"Không thể xác định chính xác do lỗi dữ liệu: {str(e)}"
    
    async def validate_marriage(self, bca_client: BCAClient, husband_id: str, wife_id: str, 
                           husband_dob: date, wife_dob: date) -> Tuple[bool, str]:
        """
        Optimized validation using batch API call. Checks all validation criteria
        and returns all errors found.
        """
        # Initialize a list to collect all validation errors
        validation_errors = []
        
        # 1. Age check remains the same (uses provided DOBs)
        age_valid, age_reason = self.validate_age_requirements(husband_dob, wife_dob)
        if not age_valid:
            validation_errors.append(age_reason)
        
        print(f"DEBUG - Batch validating citizens: {husband_id}, {wife_id}")

        # 2. Get all needed data in a single API call
        validation_data = await bca_client.batch_validate_citizens(
            citizen_ids=[husband_id, wife_id],
            include_family_tree=True
        )

        print(f"DEBUG - Validation data received: {json.dumps(validation_data)}")

        # 3. Process husband data
        husband_data = validation_data.get(husband_id, {})
        husband_exists = husband_data.get("found", False)
        if not husband_exists:
            validation_errors.append(f"Không tìm thấy công dân (chồng) với ID {husband_id}")
                
        husband_validation = husband_data.get("validation", {}) if husband_exists else {}
        husband_tree = husband_data.get("family_tree", {}) if husband_exists else {}
        
        # 4. Process wife data
        wife_data = validation_data.get(wife_id, {})
        wife_exists = wife_data.get("found", False)
        if not wife_exists:
            validation_errors.append(f"Không tìm thấy công dân (vợ) với ID {wife_id}")
                
        wife_validation = wife_data.get("validation", {}) if wife_exists else {}
        wife_tree = wife_data.get("family_tree", {}) if wife_exists else {}
        
        # 5. Check death status - continue checking even if there are issues
        if husband_exists and husband_validation.get("death_status") in ('Đã mất', 'Mất tích'):
            validation_errors.append(f"Công dân (chồng) không thể kết hôn (trạng thái: {husband_validation.get('death_status')})")
            
        if wife_exists and wife_validation.get("death_status") in ('Đã mất', 'Mất tích'):
            validation_errors.append(f"Công dân (vợ) không thể kết hôn (trạng thái: {wife_validation.get('death_status')})")
        
        # 6. Check marital status if both citizens exist
        if husband_exists and wife_exists:
            status_valid, status_reason = self.validate_marital_status(
                husband_validation.get("marital_status"),
                wife_validation.get("marital_status")
            )
            if not status_valid:
                validation_errors.append(status_reason)
        
        # 7. Blood relation check if both citizens exist and we have tree data
        if husband_exists and wife_exists:
            try:
                are_relatives, relative_reason = self.are_blood_relatives(husband_tree, wife_tree)
                
                if are_relatives:
                    validation_errors.append(f"Không được phép kết hôn do quan hệ huyết thống: {relative_reason}")
            except Exception as e:
                validation_errors.append(f"Không thể xác định quan hệ huyết thống: {str(e)}")
        
        # Return consolidated results
        if validation_errors:
            # Join all error messages
            return False, "; ".join(validation_errors)
        else:
            # All checks passed
            return True, ""
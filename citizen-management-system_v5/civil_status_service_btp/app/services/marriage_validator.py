# civil_status_service_btp/app/services/marriage_validator.py
import logging
from datetime import date
from typing import Dict, List, Tuple, Any, Set

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
        valid_single_statuses = ["Độc thân", None, ""] # Các giá trị hợp lệ cho trạng thái độc thân
        
        if husband_status not in valid_single_statuses:
            return False, f"Người chồng không ở trạng thái độc thân (hiện tại: {husband_status})"
            
        if wife_status not in valid_single_statuses:
            return False, f"Người vợ không ở trạng thái độc thân (hiện tại: {wife_status})"
            
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
        Thực hiện xác thực toàn diện các điều kiện kết hôn.
        """
        # 1. Kiểm tra tuổi tối thiểu
        age_valid, age_reason = self.validate_age_requirements(husband_dob, wife_dob)
        if not age_valid:
            return False, age_reason
        
        # 2. Lấy thông tin chi tiết công dân để kiểm tra tình trạng hôn nhân
        husband_details = await bca_client.validate_citizen_status(husband_id)
        wife_details = await bca_client.validate_citizen_status(wife_id)
        
        if not husband_details or not wife_details:
            return False, "Không thể lấy thông tin chi tiết của công dân"
        
        # 3. Kiểm tra tình trạng hôn nhân hiện tại
        status_valid, status_reason = self.validate_marital_status(
            husband_details.get("marital_status"), 
            wife_details.get("marital_status")
        )
        if not status_valid:
            return False, status_reason
        
        # 4. Lấy cây phả hệ
        husband_tree = await bca_client.get_citizen_family_tree(husband_id)
        wife_tree = await bca_client.get_citizen_family_tree(wife_id)
        
        if not husband_tree or not wife_tree:
            return False, "Không thể lấy thông tin phả hệ của công dân"
        
        # 5. Kiểm tra quan hệ huyết thống
        are_relatives, relative_reason = self.are_blood_relatives(husband_tree, wife_tree)
        if are_relatives:
            return False, f"Không được phép kết hôn do quan hệ huyết thống: {relative_reason}"
        
        # Tất cả kiểm tra đã thành công
        return True, ""
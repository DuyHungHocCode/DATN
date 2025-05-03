# civil_status_service_btp/app/services/bca_client.py
import httpx
from typing import Dict, Any, Optional, List
import json
from fastapi import HTTPException, status
from app.config import get_settings
from app.schemas.validation import CitizenValidationResponse
settings = get_settings()

class BCAClient:
    def __init__(self):
        self.base_url = settings.BCA_SERVICE_BASE_URL
        # Cân nhắc dùng AsyncClient nếu service BTP là async
        self.client = httpx.Client(base_url=self.base_url, timeout=5.0)

    async def validate_citizen_status(self, citizen_id: str) -> CitizenValidationResponse | None:
        """
        Gọi API của CitizenService (BCA) để kiểm tra sự tồn tại và trạng thái công dân.
        Trả về CitizenValidationResponse nếu tìm thấy, None nếu không tìm thấy (404).
        Ném HTTPException cho các lỗi khác.
        """
        try:
            # Sử dụng AsyncClient nếu hàm này là async
            async with httpx.AsyncClient(base_url=self.base_url, timeout=10.0) as client:
                response = await client.get(f"/api/v1/citizens/{citizen_id}/validation")

            if response.status_code == status.HTTP_404_NOT_FOUND:
                return None # Công dân không tồn tại
            elif response.status_code == status.HTTP_200_OK:
                return CitizenValidationResponse.model_validate(response.json())
            else:
                # Xử lý các lỗi khác từ BCA service
                response.raise_for_status() # Ném HTTP lỗi nếu status code là 4xx hoặc 5xx

        except httpx.TimeoutException:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="Gọi dịch vụ BCA bị timeout."
            )
        except httpx.RequestError as exc:
            # Lỗi mạng hoặc kết nối
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Lỗi kết nối đến dịch vụ BCA: {exc}"
            )
        except httpx.HTTPStatusError as exc:
             # Lỗi trả về từ BCA service (không phải 404 đã xử lý)
             # Log lỗi chi tiết ở đây nếu cần
             raise HTTPException(
                 status_code=status.HTTP_502_BAD_GATEWAY, # Hoặc status code gốc từ exc.response.status_code
                 detail=f"Dịch vụ BCA trả về lỗi: {exc.response.text}"
            )
        except Exception as e:
             # Các lỗi không mong muốn khác
             # Log lỗi chi tiết
             raise HTTPException(
                 status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                 detail=f"Lỗi không xác định khi gọi dịch vụ BCA: {str(e)}"
             )
    async def get_citizen_family_tree(self, citizen_id: str) -> Dict[str, Any] | None:
        """
        Gọi API của CitizenService (BCA) để lấy thông tin phả hệ 3 đời của công dân.
        """
        try:
            async with httpx.AsyncClient(base_url=self.base_url, timeout=15.0) as client:
                response = await client.get(f"/api/v1/citizens/{citizen_id}/family-tree")

            if response.status_code == status.HTTP_404_NOT_FOUND:
                return None
            elif response.status_code == status.HTTP_200_OK:
                return response.json()
            else:
                response.raise_for_status()

        except httpx.TimeoutException:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="Gọi dịch vụ BCA bị timeout khi truy vấn phả hệ."
            )
        except httpx.RequestError as exc:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Lỗi kết nối đến dịch vụ BCA: {exc}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Lỗi khi truy vấn phả hệ từ dịch vụ BCA: {str(e)}"
            )
    
    async def batch_validate_citizens(self, citizen_ids: List[str], include_family_tree: bool = False) -> Dict[str, Any]:
        """
        Batch validate multiple citizens in a single API call
        """
        try:
            async with httpx.AsyncClient(base_url=self.base_url, timeout=15.0) as client:
                # Kiểm tra định dạng request
                print(f"DEBUG - Request payload: {json.dumps({'citizen_ids': citizen_ids, 'include_family_tree': include_family_tree})}")
                
                response = await client.post(
                    "/api/v1/citizens/batch-validate",
                    json={"citizen_ids": citizen_ids, "include_family_tree": include_family_tree}
                )
                
                # Kiểm tra mã phản hồi và nội dung
                if response.status_code != 200:
                    print(f"DEBUG - Response status: {response.status_code}, content: {response.text}")
                    
                if response.status_code == status.HTTP_200_OK:
                    return response.json()
                else:
                    response.raise_for_status()
        
        except Exception as e:
            # Ghi log chi tiết hơn
            print(f"DEBUG - Exception in batch_validate_citizens: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error in batch validation: {str(e)}"
            )
        
    

# Dependency function để inject client
# Singleton pattern để tránh tạo nhiều client không cần thiết
bca_client_instance = BCAClient()
def get_bca_client():
    return bca_client_instance
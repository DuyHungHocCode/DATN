# civil_status_service_btp/app/services/bca_client.py
import httpx
from fastapi import HTTPException, status
from app.config import get_settings
from app.schemas.death_certificate import CitizenValidationResponse # Import schema đơn giản

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
                response = await client.get(f"/api/v1/citizens/{citizen_id}")

            if response.status_code == status.HTTP_404_NOT_FOUND:
                return None # Công dân không tồn tại
            elif response.status_code == status.HTTP_200_OK:
                # Chỉ lấy citizen_id và death_status
                data = response.json()
                return CitizenValidationResponse(
                    citizen_id=data.get("citizen_id"),
                    death_status=data.get("death_status")
                )
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

# Dependency function để inject client
# Singleton pattern để tránh tạo nhiều client không cần thiết
bca_client_instance = BCAClient()
def get_bca_client():
    return bca_client_instance
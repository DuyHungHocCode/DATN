from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Any
import logging
import json

# Configure logger
logger = logging.getLogger(__name__)

class ReferenceRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def get_reference_tables_data(self, table_names: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Lấy dữ liệu tham chiếu sử dụng stored procedure đã tạo sẵn
        
        Args:
            table_names: Chuỗi chứa tên các bảng, phân cách bằng dấu phẩy
            
        Returns:
            Dict với key là tên bảng, value là danh sách các record của bảng đó
        """
        try:
            # Cách 1: Sử dụng phương thức text() để tạo SQL statement đúng cách
            query = text("EXEC [API_Internal].[GetReferenceTableData] @tableNames = :table_names")
            
            # Lấy connection từ session để có thể xử lý multiple result sets
            with self.db.connection() as conn:
                # Tạo cursor trực tiếp từ DBAPI connection
                cursor = conn.connection.cursor()
                
                # Thực thi stored procedure
                cursor.execute(f"EXEC [API_Internal].[GetReferenceTableData] @tableNames = '{table_names}'")
                
                # Xử lý kết quả
                result = {}
                
                # Xử lý từng result set
                more_results = True
                while more_results:
                    # Lấy tên các cột
                    columns = [column[0] for column in cursor.description]
                    
                    # Lấy tất cả dữ liệu
                    rows = cursor.fetchall()
                    
                    # Xử lý dữ liệu nếu có
                    if rows:
                        # Lấy tên bảng từ cột đầu tiên của row đầu tiên
                        table_name = rows[0][0]
                        
                        # Khởi tạo danh sách cho bảng
                        if table_name not in result:
                            result[table_name] = []
                        
                        # Chuyển đổi rows thành dictionaries và thêm vào kết quả
                        for row in rows:
                            row_dict = {}
                            for i, column in enumerate(columns):
                                if i > 0:  # Bỏ qua cột TableName
                                    row_dict[column] = row[i]
                            result[table_name].append(row_dict)
                        
                        logger.info(f"Loaded {len(rows)} records for table {table_name}")
                    
                    # Chuyển sang result set tiếp theo (nếu có)
                    more_results = cursor.nextset()
                
                return result
                
        except Exception as e:
            logger.error(f"Database error when getting reference data: {str(e)}", exc_info=True)
            raise e
    
    # Phương thức thay thế nếu cách trên vẫn không hoạt động
    def get_reference_tables_data_alternative(self, table_names: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Phương thức thay thế sử dụng exec_driver_sql
        """
        try:
            # Kết nối trực tiếp đến driver
            with self.db.connection() as conn:
                # Thực thi SP với exec_driver_sql
                result_proxy = conn.exec_driver_sql(
                    f"EXEC [API_Internal].[GetReferenceTableData] @tableNames = '{table_names}'"
                )
                
                # Xử lý kết quả cho result set đầu tiên
                result = {}
                
                # Lấy kết quả đầu tiên
                first_result = result_proxy.fetchall()
                
                if first_result:
                    # Lấy tên các cột
                    columns = result_proxy.keys()
                    
                    # Xử lý rows
                    for row in first_result:
                        # Lấy tên bảng (cột đầu tiên)
                        table_name = row[0]
                        
                        # Khởi tạo danh sách cho bảng
                        if table_name not in result:
                            result[table_name] = []
                        
                        # Tạo dict từ row
                        row_dict = {}
                        for i, col_name in enumerate(columns):
                            if i > 0:  # Bỏ qua cột TableName
                                row_dict[col_name] = row[i]
                        
                        result[table_name].append(row_dict)
                
                # Cố gắng lấy các result sets tiếp theo
                try:
                    # Lấy result set tiếp theo
                    while result_proxy.nextset():
                        rows = result_proxy.fetchall()
                        if not rows:
                            continue
                            
                        # Lấy tên các cột mới
                        columns = result_proxy.keys()
                        
                        # Xử lý rows
                        for row in rows:
                            # Lấy tên bảng (cột đầu tiên)
                            table_name = row[0]
                            
                            # Khởi tạo danh sách cho bảng
                            if table_name not in result:
                                result[table_name] = []
                            
                            # Tạo dict từ row
                            row_dict = {}
                            for i, col_name in enumerate(columns):
                                if i > 0:  # Bỏ qua cột TableName
                                    row_dict[col_name] = row[i]
                            
                            result[table_name].append(row_dict)
                except Exception as e:
                    # Có thể không có result sets khác
                    logger.warning(f"Error getting next result set: {str(e)}")
                
                return result
                
        except Exception as e:
            logger.error(f"Error getting reference data: {str(e)}", exc_info=True)
            raise e
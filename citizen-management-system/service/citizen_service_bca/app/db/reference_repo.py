from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Any
import logging
import json
from app.db.redis_client import get_redis_client
# Configure logger
logger = logging.getLogger(__name__)

class ReferenceRepository:
    def __init__(self, db: Session):
        self.db = db
        self.redis_client = get_redis_client()
    def _fetch_from_db(self, table_name: str) -> List[Dict[str, Any]]:
        """
        Helper method to fetch a single reference table from DB.
        """
        try:
            # Escape single quotes trong tên bảng để tránh SQL injection và lỗi syntax
            escaped_table_name = table_name.replace("'", "''")
            
            # Sử dụng parameterized query thay vì f-string
            query = text("EXEC [API_Internal].[GetReferenceTableData] @tableNames = :table_names")
            
            # Tạo connection mới cho mỗi query
            with self.db.begin():  # Sử dụng begin() để tự động commit/rollback
                result = self.db.execute(query, {"table_names": table_name})
                
                table_data = []
                rows = result.fetchall()
                
                if rows:
                    # Lấy tên cột từ result
                    columns = result.keys()
                    
                    for row in rows:
                        row_dict = {}
                        for i, column_name in enumerate(columns):
                            # Bỏ qua cột 'TableName' (nếu có)
                            if column_name != 'TableName':
                                row_dict[column_name] = row[i]
                        if row_dict:
                            table_data.append(row_dict)
                
                return table_data
        except Exception as e:
            logger.error(f"DB error fetching reference table {table_name}: {str(e)}", exc_info=True)
            # Không ném lỗi ở đây để logic cache-aside có thể xử lý
            return []
    
    def get_reference_table_data(self, table_name: str) -> List[Dict[str, Any]]:
        """
        Lấy dữ liệu cho một bảng tham chiếu cụ thể, sử dụng cache-aside.
        """
        if not self.redis_client or not self.redis_client.client:
            logger.warning("Redis client not available. Fetching directly from DB.")
            return self._fetch_from_db(table_name)

        # 1. Thử lấy từ Redis cache
        cached_data = self.redis_client.get_reference_table(table_name)
        if cached_data is not None: # Phân biệt giữa None (không có key) và [] (key có nhưng value rỗng)
            logger.info(f"Cache hit for reference table: {table_name}")
            return cached_data

        # 2. Cache miss, lấy từ DB
        logger.info(f"Cache miss for reference table: {table_name}. Fetching from DB.")
        db_data = self._fetch_from_db(table_name)

        # 3. Lưu vào cache (ngay cả khi db_data là rỗng để tránh query lại DB liên tục cho bảng rỗng)
        if db_data is not None: # Chỉ cache nếu query DB thành công (trả về list, dù rỗng)
            self.redis_client.set_reference_table(table_name, db_data)
            logger.info(f"Cached data for reference table: {table_name}")
        
        return db_data
    
    def get_multiple_reference_tables_data(self, table_names_str: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Lấy dữ liệu cho nhiều bảng tham chiếu, sử dụng cache cho từng bảng.
        """
        table_names_list = [name.strip() for name in table_names_str.split(',') if name.strip()]
        result = {}
        for table_name in table_names_list:
            result[table_name] = self.get_reference_table_data(table_name)
        return result
    
    def get_reference_tables_data(self, table_names: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Lấy dữ liệu tham chiếu sử dụng stored procedure đã tạo sẵn
        
        Args:
            table_names: Chuỗi chứa tên các bảng, phân cách bằng dấu phẩy
            
        Returns:
            Dict với key là tên bảng, value là danh sách các record của bảng đó
        """

        if not self.redis_client or not self.redis_client.client:
            logger.warning("Redis client not available. Fetching directly from DB.")
            return self._fetch_from_db(table_name)
        

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
                
                return self.get_multiple_reference_tables_data(table_names)
                
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
        
    def _fetch_from_db_sp(self, table_names_str: str) -> Dict[str, List[Dict[str, Any]]]:
        try:
            query = text("EXEC [API_Internal].[GetReferenceTableData] @tableNames = :table_names_param")
            
            result_from_sp = {}
            with self.db.connection() as conn:
                cursor = conn.connection.cursor()
                cursor.execute(f"EXEC [API_Internal].[GetReferenceTableData] @tableNames = '{table_names_str}'")
                
                more_results = True
                while more_results:
                    current_table_name_from_sp_col = None # Tên bảng lấy từ cột 'TableName'
                    current_table_data = []
                    
                    columns = [column[0] for column in cursor.description]
                    if not columns: # Không có cột, có thể là result set rỗng từ SP
                        more_results = cursor.nextset()
                        continue

                    rows = cursor.fetchall()
                    
                    if rows:
                        # Giả sử cột đầu tiên luôn là 'TableName' do SP trả về
                        sp_table_name_col_idx = 0 
                        try:
                            # Kiểm tra xem cột 'TableName' có tồn tại không
                            # Nếu không có cột 'TableName', SP có thể không trả về như mong đợi cho 1 bảng
                            if 'TableName' not in columns:
                                logger.warning(f"Stored procedure did not return 'TableName' column for query: {table_names_str}. Assuming single table result if possible.")
                                # Nếu chỉ query 1 bảng, có thể lấy tên từ input
                                requested_tables = [name.strip() for name in table_names_str.split(',') if name.strip()]
                                if len(requested_tables) == 1:
                                     current_table_name_from_sp_col = requested_tables[0]
                                else: # Không xác định được tên bảng
                                    logger.error(f"Cannot determine table name from SP result for multiple tables query without 'TableName' column: {table_names_str}")
                                    more_results = cursor.nextset()
                                    continue
                            else:
                                current_table_name_from_sp_col = rows[0][sp_table_name_col_idx]

                        except IndexError: # Xử lý trường hợp rows[0] không có phần tử nào
                            logger.warning(f"Empty row encountered for a result set in SP for: {table_names_str}")
                            more_results = cursor.nextset()
                            continue


                        if current_table_name_from_sp_col not in result_from_sp:
                             result_from_sp[current_table_name_from_sp_col] = []

                        for row_tuple in rows:
                            row_dict = {}
                            for i, column_name in enumerate(columns):
                                # Bỏ qua cột 'TableName' khi thêm vào dict dữ liệu của bảng
                                if column_name != 'TableName':
                                    row_dict[column_name] = row_tuple[i]
                            if row_dict: # Chỉ thêm nếu dict không rỗng
                                result_from_sp[current_table_name_from_sp_col].append(row_dict)
                    
                    more_results = cursor.nextset()
            return result_from_sp
        except Exception as e:
            logger.error(f"Database error when getting reference data via SP: {str(e)}", exc_info=True)
            raise # Ném lại lỗi để API endpoint xử lý


    def get_reference_tables_data_cached_per_table(self, table_names_str: str) -> Dict[str, List[Dict[str, Any]]]:
        table_names_list = [name.strip() for name in table_names_str.split(',') if name.strip()]
        result = {}
        for table_name in table_names_list:
            # Sử dụng phương thức đã có cache-aside cho từng bảng
            result[table_name] = self.get_reference_table_data(table_name)
        return result
    
    # Ghi đè phương thức cũ để sử dụng logic mới
    def get_reference_tables_data(self, table_names: str) -> Dict[str, List[Dict[str, Any]]]:
        return self.get_reference_tables_data_cached_per_table(table_names)
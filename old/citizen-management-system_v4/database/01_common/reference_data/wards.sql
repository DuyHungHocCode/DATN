-- File: database/reference_data/wards.sql
-- Dữ liệu tham chiếu cho bảng wards (phường/xã)
-- Trong ví dụ này, chỉ thêm dữ liệu cho các phường thuộc quận Ba Đình, Hà Nội

\echo 'Bắt đầu nạp dữ liệu cho bảng wards...'

-- Xóa dữ liệu cũ (nếu có)
\connect ministry_of_public_security
TRUNCATE TABLE reference.wards CASCADE;

-- Định nghĩa các giá trị cho administrative_unit_id:
-- 5: Phường
-- 6: Xã
-- 7: Thị trấn

INSERT INTO reference.wards (
    ward_id, ward_code, ward_name, district_id,
    area, population, gso_code, is_urban, administrative_unit_id
) VALUES
-- Các phường thuộc quận Ba Đình (district_id = 101)
(10101, 'PHUCXA', 'Phúc Xá', 101, 0.95, 18500, '00001', TRUE, 5),
(10102, 'TRUCBACH', 'Trúc Bạch', 101, 0.54, 11200, '00002', TRUE, 5),
(10103, 'VINHPHUC', 'Vĩnh Phúc', 101, 0.63, 14800, '00003', TRUE, 5),
(10104, 'CONGVI', 'Cống Vị', 101, 0.82, 24600, '00004', TRUE, 5),
(10105, 'LIEUGIAI', 'Liễu Giai', 101, 0.76, 22100, '00005', TRUE, 5),
(10106, 'NGUYENTT', 'Nguyễn Trung Trực', 101, 0.41, 13300, '00006', TRUE, 5),
(10107, 'QUANTHANH', 'Quán Thánh', 101, 0.61, 16900, '00007', TRUE, 5),
(10108, 'DOICAN', 'Đội Cấn', 101, 0.85, 25400, '00008', TRUE, 5),
(10109, 'NGOCHA', 'Ngọc Hà', 101, 0.74, 20700, '00009', TRUE, 5),
(10110, 'KIMMA', 'Kim Mã', 101, 0.58, 19800, '00010', TRUE, 5),
(10111, 'GIANGVO', 'Giảng Võ', 101, 0.72, 23500, '00011', TRUE, 5),
(10112, 'THANHCONG', 'Thành Công', 101, 0.88, 26100, '00012', TRUE, 5),
-- Các phường thuộc quận Hoàn Kiếm (district_id = 102)
(10201, 'PHUCTAN', 'Phúc Tân', 102, 0.79, 18541, '00013', TRUE, 5),
(10202, 'DONGXUAN', 'Đồng Xuân', 102, 0.17, 9444, '00014', TRUE, 5),
(10203, 'HANGMA', 'Hàng Mã', 102, 0.17, 6894, '00015', TRUE, 5),
(10204, 'HANGBUOM', 'Hàng Buồm', 102, 0.12, 7620, '00016', TRUE, 5),
(10205, 'HANGDAO', 'Hàng Đào', 102, 0.07, 5339, '00017', TRUE, 5),
(10206, 'HANGBO', 'Hàng Bồ', 102, 0.09, 5431, '00018', TRUE, 5),
(10207, 'CUADONG', 'Cửa Đông', 102, 0.15, 6652, '00019', TRUE, 5),
(10208, 'LYTHAITO', 'Lý Thái Tổ', 102, 0.24, 5556, '00020', TRUE, 5),
(10209, 'HANGBAC', 'Hàng Bạc', 102, 0.09, 5133, '00021', TRUE, 5),
(10210, 'HANGGAI', 'Hàng Gai', 102, 0.09, 5779, '00022', TRUE, 5),
(10211, 'HANGTRONG', 'Hàng Trống', 102, 0.35, 15141, '00023', TRUE, 5),
(10212, 'CUANAM', 'Cửa Nam', 102, 0.26, 10527, '00024', TRUE, 5),
(10213, 'HANGBONG', 'Hàng Bông', 102, 0.18, 17937, '00025', TRUE, 5),
(10214, 'TRANGTIEN', 'Tràng Tiền', 102, 0.39, 10666, '00026', TRUE, 5),
(10215, 'TRANKHANGDAO', 'Trần Hưng Đạo', 102, 0.47, 10901, '00027', TRUE, 5),
(10216, 'PHANCHUTRINH', 'Phan Chu Trinh', 102, 0.43, 10503, '00028', TRUE, 5),
(10217, 'CHUONGDUONG', 'Chương Dương', 102, 1.00, 24229, '00029', TRUE, 5),
(10218, 'HANGBAI', 'Hàng Bài', 102, 0.27, 10534, '00030', TRUE, 5),

-- Các phường thuộc quận Tây Hồ (district_id = 103)
(10301, 'BUOI', 'Bưởi', 103, NULL, NULL, '00031', TRUE, 5),
(10302, 'NHATTAN', 'Nhật Tân', 103, NULL, NULL, '00032', TRUE, 5),
(10303, 'PHUTHUONG', 'Phú Thượng', 103, NULL, NULL, '00033', TRUE, 5),
(10304, 'QUANGAN', 'Quảng An', 103, NULL, NULL, '00034', TRUE, 5),
(10305, 'THUYKHUE', 'Thụy Khuê', 103, NULL, NULL, '00035', TRUE, 5),
(10306, 'TULIEN', 'Tứ Liên', 103, NULL, NULL, '00036', TRUE, 5),
(10307, 'XUANLA', 'Xuân La', 103, NULL, NULL, '00037', TRUE, 5),
(10308, 'YENPHU', 'Yên Phụ', 103, NULL, NULL, '00038', TRUE, 5),

-- Các phường thuộc quận Long Biên (district_id = 104)
(10401, 'BODE', 'Bồ Đề', 104, NULL, NULL, '00039', TRUE, 5),
(10402, 'CUKHOI', 'Cự Khối', 104, NULL, NULL, '00040', TRUE, 5),
(10403, 'DUCGIANG', 'Đức Giang', 104, NULL, NULL, '00041', TRUE, 5),
(10404, 'GIATHUY', 'Gia Thụy', 104, NULL, NULL, '00042', TRUE, 5),
(10405, 'GIANGBIEN', 'Giang Biên', 104, NULL, NULL, '00043', TRUE, 5),
(10406, 'LONGBIEN', 'Long Biên', 104, NULL, NULL, '00044', TRUE, 5),
(10407, 'NGOCLAM', 'Ngọc Lâm', 104, NULL, NULL, '00045', TRUE, 5),
(10408, 'NGOCTHUY', 'Ngọc Thụy', 104, NULL, NULL, '00046', TRUE, 5),
(10409, 'PHUCDONG', 'Phúc Đồng', 104, NULL, NULL, '00047', TRUE, 5),
(10410, 'PHUCLOI', 'Phúc Lợi', 104, NULL, NULL, '00048', TRUE, 5),
(10411, 'THACHBAN', 'Thạch Bàn', 104, NULL, NULL, '00049', TRUE, 5),
(10412, 'THUONGTHANH', 'Thượng Thanh', 104, NULL, NULL, '00050', TRUE, 5),

-- Các phường thuộc quận Cầu Giấy (district_id = 105)
(10501, 'DICHVONG', 'Dịch Vọng', 105, 1.15, 25661, '00013', TRUE, 5),
(10502, 'DICHVONGHAU', 'Dịch Vọng Hậu', 105, 1.45, 28696, '00014', TRUE, 5),
(10503, 'MAIDICH', 'Mai Dịch', 105, NULL, NULL, '00015', TRUE, 5),
(10504, 'NGHIADO', 'Nghĩa Đô', 105, 1.22, 33003, '00016', TRUE, 5),
(10505, 'NGHIATAN', 'Nghĩa Tân', 105, 1.12, 31536, '00017', TRUE, 5),
(10506, 'QUANHOA', 'Quan Hoa', 105, 1.08, 41378, '00018', TRUE, 5),
(10507, 'TRUNGHOA', 'Trung Hòa', 105, NULL, NULL, '00019', TRUE, 5),
(10508, 'YENHOA', 'Yên Hòa', 105, NULL, NULL, '00020', TRUE, 5),

-- Các phường thuộc quận Đống Đa (district_id = 106)
(10601, 'KIMLIEN', 'Kim Liên', 106, 0.59, 21707, '00021', TRUE, 5),
(10602, 'PHUONGMAI', 'Phương Mai', 106, NULL, NULL, '00022', TRUE, 5),
(10603, 'PHUONGLIEN_TRUNGTU', 'Phương Liên - Trung Tự', 106, 0.61, 19844, '00023', TRUE, 5),
(10604, 'KHAMTHIEN', 'Khâm Thiên', 106, 0.42, 22201, '00024', TRUE, 5),
(10605, 'THINHQUANG', 'Thịnh Quang', 106, 0.59, 20593, '00025', TRUE, 5),
(10606, 'VANMIEU_QUOCTUGIAM', 'Văn Miếu - Quốc Tử Giám', 106, 0.48, 17203, '00026', TRUE, 5),
(10607, 'KHUONGTHUONG', 'Khương Thượng', 106, 0.43, 15727, '00027', TRUE, 5),

-- Các phường thuộc quận Hai Bà Trưng (district_id = 107)
(10701, 'BACHKHOA', 'Bách Khoa', 107, 0.66, 20773, '00028', TRUE, 5),
(10702, 'BACHMAI', 'Bạch Mai', 107, 0.51, 28948, '00029', TRUE, 5),
(10703, 'DONGNHAN', 'Đồng Nhân', 107, 0.30, 18109, '00030', TRUE, 5),
(10704, 'THANHNHAN', 'Thanh Nhàn', 107, 0.77, 22899, '00031', TRUE, 5),

-- Các phường thuộc quận Thanh Xuân (district_id = 109)
(10901, 'THANHXUANBAC', 'Thanh Xuân Bắc', 109, 0.49, 21225, '00051', TRUE, 5),
(10902, 'THANHXUANNAM', 'Thanh Xuân Nam', 109, 0.31, 12904, '00052', TRUE, 5),
(10903, 'THANHXUANTRUNG', 'Thanh Xuân Trung', 109, 1.08, 33418, '00053', TRUE, 5),
(10904, 'THUONGDINH', 'Thượng Đình', 109, 0.67, 28101, '00054', TRUE, 5),
(10905, 'HADINH', 'Hạ Đình', 109, 0.70, 18580, '00055', TRUE, 5),
(10906, 'KHUONGDINH', 'Khương Đình', 109, 1.31, 31695, '00056', TRUE, 5),
(10907, 'KHUONGMAI', 'Khương Mai', 109, 1.06, 21543, '00057', TRUE, 5),
(10908, 'KHUONGTRUNG', 'Khương Trung', 109, 0.74, 35000, '00058', TRUE, 5),
(10909, 'NHANCHINH', 'Nhân Chính', 109, 1.65, 50982, '00059', TRUE, 5),
(10910, 'PHUONGLIET', 'Phương Liệt', 109, 0.94, 25817, '00060', TRUE, 5),
(10911, 'KIMGIANG', 'Kim Giang', 109, 0.23, 13494, '00061', TRUE, 5),

-- Các phường thuộc quận Bắc Từ Liêm (district_id = 110)
(11001, 'CONHUE1', 'Cổ Nhuế 1', 110, NULL, NULL, '00062', TRUE, 5),
(11002, 'CONHUE2', 'Cổ Nhuế 2', 110, NULL, NULL, '00063', TRUE, 5),
(11003, 'DONGNGAC', 'Đông Ngạc', 110, NULL, NULL, '00064', TRUE, 5),
(11004, 'DUCTHANG', 'Đức Thắng', 110, NULL, NULL, '00065', TRUE, 5),
(11005, 'LIENMAC', 'Liên Mạc', 110, NULL, NULL, '00066', TRUE, 5),
(11006, 'MINHKHAI', 'Minh Khai', 110, NULL, NULL, '00067', TRUE, 5),
(11007, 'PHUCDIEN', 'Phúc Diễn', 110, NULL, NULL, '00068', TRUE, 5),
(11008, 'PHUODIEN', 'Phú Diễn', 110, NULL, NULL, '00069', TRUE, 5),
(11009, 'TAYTUU', 'Tây Tựu', 110, NULL, NULL, '00070', TRUE, 5),
(11010, 'THUONGCAT', 'Thượng Cát', 110, NULL, NULL, '00071', TRUE, 5),
(11011, 'THUYPHUONG', 'Thụy Phương', 110, NULL, NULL, '00072', TRUE, 5),
(11012, 'XUANDINH', 'Xuân Đỉnh', 110, NULL, NULL, '00073', TRUE, 5),
(11013, 'XUANTAO', 'Xuân Tảo', 110, NULL, NULL, '00074', TRUE, 5),

-- Các phường thuộc quận Nam Từ Liêm (district_id = 111)
(11101, 'CAUDIEN', 'Cầu Diễn', 111, 1.79, 27017, '00075', TRUE, 5),
(11102, 'DAIMO', 'Đại Mỗ', 111, 4.98, 32920, '00076', TRUE, 5),
(11103, 'METRI', 'Mễ Trì', 111, 4.67, 32169, '00077', TRUE, 5),
(11104, 'MYDINH1', 'Mỹ Đình 1', 111, 2.28, 30264, '00078', TRUE, 5),
(11105, 'MYDINH2', 'Mỹ Đình 2', 111, 1.94, 33666, '00079', TRUE, 5),
(11106, 'PHUDO', 'Phú Đô', 111, 2.39, 15983, '00080', TRUE, 5),
(11107, 'PHUONGCANH', 'Phương Canh', 111, 2.61, 20117, '00081', TRUE, 5),
(11108, 'TAYMO', 'Tây Mỗ', 111, 6.05, 28808, '00082', TRUE, 5),
(11109, 'TRUNGVAN', 'Trung Văn', 111, 2.78, 43757, '00083', TRUE, 5),
(11110, 'XUANPHUONG', 'Xuân Phương', 111, 2.76, 17743, '00084', TRUE, 5),

-- Các phường thuộc quận Hà Đông (district_id = 112)
(11201, 'BIENGIANG', 'Biên Giang', 112, 2.36, 8350, '00085', TRUE, 5),
(11202, 'DONGMAI', 'Đồng Mai', 112, 6.34, 16050, '00086', TRUE, 5),
(11203, 'DUONGNOI', 'Dương Nội', 112, 5.85, 25950, '00087', TRUE, 5),
(11204, 'HACAU', 'Hà Cầu', 112, 1.53, 14876, '00088', TRUE, 5),
(11205, 'KIENHUNG', 'Kiến Hưng', 112, 1.80, 12300, '00089', TRUE, 5),
(11206, 'LAKHE', 'La Khê', 112, 2.60, 12935, '00090', TRUE, 5),
(11207, 'MOLAO', 'Mộ Lao', 112, 1.26, 24221, '00091', TRUE, 5),
(11208, 'NGUYENTRAI', 'Nguyễn Trãi', 112, 1.50, 11500, '00092', TRUE, 5),
(11209, 'PHULA', 'Phú La', 112, 1.39, 6243, '00093', TRUE, 5),
(11210, 'PHULAM', 'Phú Lãm', 112, 2.10, 9800, '00094', TRUE, 5),
(11211, 'PHULUONG', 'Phú Lương', 112, 2.50, 10500, '00095', TRUE, 5),
(11212, 'PHUCLA', 'Phúc La', 112, 1.39, 6243, '00096', TRUE, 5),
(11213, 'QUANGTRUNG', 'Quang Trung', 112, 1.80, 14500, '00097', TRUE, 5),
(11214, 'VANQUAN', 'Văn Quán', 112, 1.20, 11000, '00098', TRUE, 5),
(11215, 'VANPHUC', 'Vạn Phúc', 112, 1.43, 14289, '00099', TRUE, 5),
(11216, 'YENNGHIA', 'Yên Nghĩa', 112, 6.93, 24058, '00100', TRUE, 5),
(11217, 'YETKIEU', 'Yết Kiêu', 112, 0.21, 8623, '00101', TRUE, 5),

-- Các phường thuộc quận Cầu Giấy (district_id = 113)
(11301, 'DICHVONG', 'Dịch Vọng', 113, 1.32, 27979, '00102', TRUE, 5),
(11302, 'DICHVONGHAU', 'Dịch Vọng Hậu', 113, 1.48, 31879, '00103', TRUE, 5),
(11303, 'MAIDICH', 'Mai Dịch', 113, 2.02, 40527, '00104', TRUE, 5),
(11304, 'NGHIADO', 'Nghĩa Đô', 113, 1.29, 35054, '00105', TRUE, 5),
(11305, 'NGHIATAN', 'Nghĩa Tân', 113, 0.68, 22207, '00106', TRUE, 5),
(11306, 'QUANHOA', 'Quan Hoa', 113, 0.83, 34055, '00107', TRUE, 5),
(11307, 'TRUNGHOA', 'Trung Hòa', 113, 2.46, 54770, '00108', TRUE, 5),
(11308, 'YENHOA', 'Yên Hòa', 113, 2.07, 47467, '00109', TRUE, 5);



-- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice
TRUNCATE TABLE reference.wards CASCADE;

-- Copy dữ liệu từ Bộ Công an
INSERT INTO reference.wards
SELECT * FROM ministry_of_public_security.reference.wards;

-- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server
TRUNCATE TABLE reference.wards CASCADE;

-- Copy dữ liệu từ Bộ Công an
INSERT INTO reference.wards
SELECT * FROM ministry_of_public_security.reference.wards;

\echo 'Hoàn thành nạp dữ liệu mẫu cho các phường thuộc quận Ba Đình vào bảng wards'
-- File: database/reference_data/districts.sql
-- Dữ liệu tham chiếu cho bảng districts (quận/huyện)


\echo 'Bắt đầu nạp dữ liệu cho bảng districts...'

-- Xóa dữ liệu cũ (nếu có)
\connect ministry_of_public_security
TRUNCATE TABLE reference.districts CASCADE;

-- Định nghĩa các giá trị cho administrative_unit_id:
-- 1: Quận
-- 2: Huyện
-- 3: Thị xã
-- 4: Thành phố thuộc tỉnh

INSERT INTO reference.districts (
    district_id, district_code, district_name, province_id,
    area, population, gso_code, is_urban, administrative_unit_id
) VALUES

-- Hà Nội (province_id = 1)
-- Central Districts (Quận nội thành)
(101, 'BAD', 'Ba Đình', 1, 9.25, 247100, '001', TRUE, 1),
(102, 'HKM', 'Hoàn Kiếm', 1, 5.29, 147300, '002', TRUE, 1),
(103, 'THO', 'Tây Hồ', 1, 24.01, 168300, '003', TRUE, 1),
(104, 'LBI', 'Long Biên', 1, 60.38, 318000, '004', TRUE, 1),
(105, 'CGI', 'Cầu Giấy', 1, 12.04, 266800, '005', TRUE, 1),
(106, 'DDA', 'Đống Đa', 1, 9.95, 410000, '006', TRUE, 1),
(107, 'HBT', 'Hai Bà Trưng', 1, 10.09, 318400, '007', TRUE, 1),
(108, 'HMA', 'Hoàng Mai', 1, 40.32, 411500, '008', TRUE, 1),
(109, 'TXU', 'Thanh Xuân', 1, 9.11, 285400, '009', TRUE, 1),
(110, 'BTL', 'Bắc Từ Liêm', 1, 43.35, 333000, '010', TRUE, 1),
(111, 'NTL', 'Nam Từ Liêm', 1, 32.19, 236000, '019', TRUE, 1),
(112, 'HDO', 'Hà Đông', 1, 49.64, 382637, '268', TRUE, 1),

-- Suburban Districts (Huyện ngoại thành)
(113, 'SSO', 'Sóc Sơn', 1, 306.51, 322200, '016', FALSE, 2),
(114, 'DAN', 'Đông Anh', 1, 182.30, 381000, '017', FALSE, 2),
(115, 'GLA', 'Gia Lâm', 1, 114.17, 276000, '018', FALSE, 2),
(116, 'THT', 'Thanh Trì', 1, 63.43, 247300, '020', FALSE, 2),
(117, 'BAV', 'Ba Vì', 1, 424.14, 282800, '250', FALSE, 2),
(118, 'PTH', 'Phúc Thọ', 1, 113.23, 182400, '251', FALSE, 2),
(119, 'DTI', 'Đan Phượng', 1, 76.80, 162900, '252', FALSE, 2),
(120, 'HOA', 'Hoài Đức', 1, 82.70, 229800, '253', FALSE, 2),
(121, 'QUO', 'Quốc Oai', 1, 147.00, 175800, '254', FALSE, 2),
(122, 'THA', 'Thạch Thất', 1, 128.10, 207500, '255', FALSE, 2),
(123, 'CPA', 'Chương Mỹ', 1, 232.40, 320000, '256', FALSE, 2),
(124, 'TNH', 'Thanh Oai', 1, 129.60, 184900, '257', FALSE, 2),
(125, 'TDU', 'Thường Tín', 1, 130.70, 247400, '258', FALSE, 2),
(126, 'PHX', 'Phú Xuyên', 1, 171.10, 189400, '259', FALSE, 2),
(127, 'UHG', 'Ứng Hòa', 1, 184.60, 204000, '260', FALSE, 2),
(128, 'MYD', 'Mỹ Đức', 1, 230.00, 180000, '261', FALSE, 2),
(129, 'MDC', 'Mê Linh', 1, 141.90, 202700, '262', FALSE, 2),

-- Hải Phòng (province_id = 2)
(201, 'HBG', 'Hồng Bàng', 2, 14.32, 160000, '303', TRUE, 1),
(202, 'NQY', 'Ngô Quyền', 2, 8.76, 195000, '304', TRUE, 1),
(203, 'LCH', 'Lê Chân', 2, 13.17, 241000, '305', TRUE, 1),
(204, 'HAI', 'Hải An', 2, 36.50, 129000, '306', TRUE, 1),
(205, 'KAN', 'Kiến An', 2, 27.10, 113000, '307', TRUE, 1),
(206, 'DDU', 'Đồ Sơn', 2, 42.40, 42000, '308', TRUE, 1),
(207, 'DLH', 'Dương Kinh', 2, 44.50, 85000, '309', TRUE, 1),
(208, 'THU', 'Thủy Nguyên', 2, 242.80, 330000, '312', FALSE, 2),
(209, 'ALD', 'An Lão', 2, 113.10, 130000, '313', FALSE, 2),
(210, 'KTH', 'Kiến Thụy', 2, 107.50, 145000, '314', FALSE, 2),
(211, 'TNG', 'Tiên Lãng', 2, 190.80, 148000, '315', FALSE, 2),
(212, 'VBA', 'Vĩnh Bảo', 2, 180.20, 192000, '316', FALSE, 2),
(213, 'CLH', 'Cát Hải', 2, 345.70, 36000, '317', FALSE, 2),
(214, 'BCH', 'Bạch Long Vĩ', 2, 4.50, 1000, '318', FALSE, 2),
(215, 'ADG', 'An Dương', 2, 78.65, 176000, '319', FALSE, 2),

-- Bắc Ninh (province_id = 3)
(301, 'BNI', 'Bắc Ninh', 3, 82.60, 240000, '213', TRUE, 4),
(302, 'YPH', 'Yên Phong', 3, 113.30, 171000, '215', FALSE, 2),
(303, 'QVU', 'Quế Võ', 3, 157.20, 230000, '216', FALSE, 2),
(304, 'TIF', 'Tiên Du', 3, 115.40, 183000, '217', FALSE, 2),
(305, 'TDS', 'Từ Sơn', 3, 60.10, 204000, '218', TRUE, 3),
(306, 'TSO', 'Thuận Thành', 3, 115.90, 177000, '219', FALSE, 2),
(307, 'GIA', 'Gia Bình', 3, 108.10, 115000, '220', FALSE, 2),
(308, 'LUH', 'Lương Tài', 3, 147.00, 110000, '221', FALSE, 2),

-- Hải Dương (province_id = 4)
(401, 'HDG', 'Hải Dương', 4, 71.40, 235000, '288', TRUE, 4),
(402, 'CHG', 'Chí Linh', 4, 282.10, 170000, '290', TRUE, 4),
(403, 'NAM', 'Nam Sách', 4, 130.40, 130000, '291', FALSE, 2),
(404, 'KMO', 'Kinh Môn', 4, 163.90, 140000, '292', TRUE, 3),
(405, 'KTH', 'Kim Thành', 4, 118.90, 123000, '293', FALSE, 2),
(406, 'THH', 'Thanh Hà', 4, 158.90, 130000, '294', FALSE, 2),
(407, 'CNI', 'Cẩm Giàng', 4, 110.50, 130000, '295', FALSE, 2),
(408, 'BNG', 'Bình Giang', 4, 106.70, 120000, '296', FALSE, 2),
(409, 'GLC', 'Gia Lộc', 4, 128.60, 147000, '297', FALSE, 2),
(410, 'TKY', 'Tứ Kỳ', 4, 118.90, 127000, '298', FALSE, 2),
(411, 'NIA', 'Ninh Giang', 4, 158.60, 137000, '299', FALSE, 2),
(412, 'TTN', 'Thanh Miện', 4, 123.80, 125000, '300', FALSE, 2),

-- Hưng Yên (province_id = 5)
(501, 'HYE', 'Hưng Yên', 5, 46.90, 125000, '323', TRUE, 4),
(502, 'MHA', 'Mỹ Hào', 5, 79.30, 110000, '325', TRUE, 3),
(503, 'AHI', 'Ân Thi', 5, 128.70, 130000, '326', FALSE, 2),
(504, 'KCH', 'Khoái Châu', 5, 131.80, 145000, '327', FALSE, 2),
(505, 'KKI', 'Kim Động', 5, 114.60, 119000, '328', FALSE, 2),
(506, 'TIT', 'Tiên Lữ', 5, 95.80, 108000, '329', FALSE, 2),
(507, 'PDH', 'Phù Cừ', 5, 95.50, 88000, '330', FALSE, 2),
(508, 'VGI', 'Văn Giang', 5, 72.40, 120000, '331', FALSE, 2),
(509, 'VLA', 'Văn Lâm', 5, 75.40, 130000, '332', FALSE, 2),
(510, 'YMY', 'Yên Mỹ', 5, 92.70, 155000, '333', FALSE, 2),

-- Nam Định (province_id = 6)
(601, 'NAM', 'Nam Định', 6, 46.40, 270000, '356', TRUE, 4),
(602, 'MTV', 'Mỹ Lộc', 6, 74.80, 74000, '358', FALSE, 2),
(603, 'VBA', 'Vụ Bản', 6, 150.20, 126000, '359', FALSE, 2),
(604, 'YKH', 'Ý Yên', 6, 238.10, 234000, '360', FALSE, 2),
(605, 'NGP', 'Nghĩa Hưng', 6, 247.40, 165000, '361', FALSE, 2),
(606, 'NQN', 'Nam Trực', 6, 168.10, 172000, '362', FALSE, 2),
(607, 'TRC', 'Trực Ninh', 6, 148.40, 160000, '363', FALSE, 2),
(608, 'XTH', 'Xuân Trường', 6, 115.60, 140000, '364', FALSE, 2),
(609, 'GAO', 'Giao Thủy', 6, 214.80, 132000, '365', FALSE, 2),
(610, 'HAI', 'Hải Hậu', 6, 211.60, 248000, '366', FALSE, 2),

-- Thái Bình (province_id = 7)
(701, 'TBH', 'Thái Bình', 7, 67.70, 145000, '336', TRUE, 4),
(702, 'QIN', 'Quỳnh Phụ', 7, 208.70, 180000, '338', FALSE, 2),
(703, 'HUG', 'Hưng Hà', 7, 222.50, 190000, '339', FALSE, 2),
(704, 'DTH', 'Đông Hưng', 7, 191.20, 220000, '340', FALSE, 2),
(705, 'TAI', 'Thái Thụy', 7, 261.80, 170000, '341', FALSE, 2),
(706, 'TBI', 'Tiền Hải', 7, 232.80, 160000, '342', FALSE, 2),
(707, 'KSH', 'Kiến Xương', 7, 208.50, 185000, '343', FALSE, 2),
(708, 'VTH', 'Vũ Thư', 7, 189.20, 175000, '344', FALSE, 2),

-- Vĩnh Phúc (province_id = 8)
(801, 'VYE', 'Vĩnh Yên', 8, 50.80, 140000, '243', TRUE, 4),
(802, 'PYE', 'Phúc Yên', 8, 120.20, 115000, '244', TRUE, 4),
(803, 'LAP', 'Lập Thạch', 8, 141.70, 125000, '246', FALSE, 2),
(804, 'TAD', 'Tam Đảo', 8, 236.60, 80000, '247', FALSE, 2),
(805, 'BXY', 'Bình Xuyên', 8, 150.30, 135000, '248', FALSE, 2),
(806, 'YLA', 'Yên Lạc', 8, 113.20, 160000, '249', FALSE, 2),
(807, 'VTG', 'Vĩnh Tường', 8, 140.60, 178000, '251', FALSE, 2),
(808, 'SGT', 'Sông Lô', 8, 147.20, 130000, '252', FALSE, 2),
(809, 'TDA', 'Tam Dương', 8, 83.10, 105000, '253', FALSE, 2),

-- Hà Nam (province_id = 9)
(901, 'PLY', 'Phủ Lý', 9, 79.70, 110000, '347', TRUE, 4),
(902, 'DUY', 'Duy Tiên', 9, 118.10, 125000, '349', TRUE, 3),
(903, 'KBA', 'Kim Bảng', 9, 148.00, 118000, '350', FALSE, 2),
(904, 'THK', 'Thanh Liêm', 9, 166.20, 128000, '351', FALSE, 2),
(905, 'BLI', 'Bình Lục', 9, 154.50, 134000, '352', FALSE, 2),
(906, 'LYN', 'Lý Nhân', 9, 168.60, 140000, '353', FALSE, 2),

-- Hà Giang (province_id = 10)
(1001, 'HGG', 'Hà Giang', 10, 135.60, 80000, '024', TRUE, 4),
(1002, 'DVC', 'Đồng Văn', 10, 447.00, 75000, '026', FALSE, 2),
(1003, 'MVA', 'Mèo Vạc', 10, 574.00, 60000, '027', FALSE, 2),
(1004, 'YMI', 'Yên Minh', 10, 780.00, 95000, '028', FALSE, 2),
(1005, 'QBA', 'Quản Bạ', 10, 552.00, 50000, '029', FALSE, 2),
(1006, 'VCH', 'Vị Xuyên', 10, 1459.00, 120000, '030', FALSE, 2),
(1007, 'BGI', 'Bắc Mê', 10, 862.00, 55000, '031', FALSE, 2),
(1008, 'HOG', 'Hoàng Su Phì', 10, 631.00, 75000, '032', FALSE, 2),
(1009, 'XMA', 'Xín Mần', 10, 581.00, 70000, '033', FALSE, 2),
(1010, 'BQA', 'Bắc Quang', 10, 1095.00, 130000, '034', FALSE, 2),
(1011, 'QBI', 'Quang Bình', 10, 547.00, 60000, '035', FALSE, 2),

-- Cao Bằng (province_id = 11)
(1101, 'CAB', 'Cao Bằng', 11, 107.60, 95000, '040', TRUE, 4),
(1102, 'BAL', 'Bảo Lâm', 11, 922.20, 55000, '042', FALSE, 2),
(1103, 'BAC', 'Bảo Lạc', 11, 872.60, 51000, '043', FALSE, 2),
(1104, 'HQU', 'Hà Quảng', 11, 806.60, 60000, '044', FALSE, 2),
(1105, 'THO', 'Trùng Khánh', 11, 668.80, 62000, '045', FALSE, 2),
(1106, 'HLA', 'Hạ Lang', 11, 454.60, 25000, '046', FALSE, 2),
(1107, 'QUY', 'Quảng Hòa', 11, 419.20, 45000, '047', FALSE, 2),
(1108, 'HOA', 'Hòa An', 11, 645.60, 68000, '048', FALSE, 2),
(1109, 'NGD', 'Nguyên Bình', 11, 828.20, 43000, '049', FALSE, 2),
(1110, 'THN', 'Thạch An', 11, 648.20, 38000, '050', FALSE, 2)
;

-- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice
TRUNCATE TABLE reference.districts CASCADE;

-- Copy dữ liệu từ Bộ Công an
INSERT INTO reference.districts
SELECT * FROM ministry_of_public_security.reference.districts;

-- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server
TRUNCATE TABLE reference.districts CASCADE;

-- Copy dữ liệu từ Bộ Công an
INSERT INTO reference.districts
SELECT * FROM ministry_of_public_security.reference.districts;

\echo 'Hoàn thành nạp dữ liệu cho bảng districts'
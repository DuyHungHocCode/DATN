-- File: database/reference_data/provinces.sql
-- Dữ liệu tham chiếu cho bảng provinces (63 tỉnh/thành phố)
-- Phân loại theo 3 miền và 8 vùng kinh tế

\echo 'Bắt đầu nạp dữ liệu cho bảng provinces...'

-- Xóa dữ liệu cũ (nếu có)
TRUNCATE TABLE reference.provinces CASCADE;

-- Định nghĩa các giá trị cho administrative_unit_id:
-- 1: Thành phố trực thuộc trung ương
-- 2: Tỉnh

-- Định nghĩa các giá trị cho administrative_region_id:
-- 1: Đồng bằng sông Hồng
-- 2: Đông Bắc
-- 3: Tây Bắc
-- 4: Bắc Trung Bộ
-- 5: Nam Trung Bộ
-- 6: Tây Nguyên
-- 7: Đông Nam Bộ
-- 8: Đồng bằng sông Cửu Long

-- Nạp dữ liệu cho Bộ Công an
\connect ministry_of_public_security

INSERT INTO reference.provinces (
    province_id, province_code, province_name, region_id, 
    area, population, gso_code, is_city, 
    administrative_unit_id, administrative_region_id
) VALUES
-- Miền Bắc (region_id = 1)
-- Đồng bằng sông Hồng (administrative_region_id = 1)
(1, 'HNO', 'Hà Nội', 1, 3358.6, 8418600, '01', TRUE, 1, 1),
(2, 'HPH', 'Hải Phòng', 1, 1561.8, 2029500, '31', TRUE, 1, 1),
(3, 'BNI', 'Bắc Ninh', 1, 822.7, 1368000, '27', FALSE, 2, 1),
(4, 'HDG', 'Hải Dương', 1, 1656.0, 1892100, '30', FALSE, 2, 1),
(5, 'HNG', 'Hưng Yên', 1, 926.0, 1252700, '33', FALSE, 2, 1),
(6, 'NDH', 'Nam Định', 1, 1652.6, 1780000, '36', FALSE, 2, 1),
(7, 'TBH', 'Thái Bình', 1, 1570.5, 1860000, '34', FALSE, 2, 1),
(8, 'VPC', 'Vĩnh Phúc', 1, 1236.5, 1154000, '26', FALSE, 2, 1),
(9, 'HNA', 'Hà Nam', 1, 860.5, 854000, '35', FALSE, 2, 1),

-- Đông Bắc (administrative_region_id = 2)
(10, 'HGG', 'Hà Giang', 1, 7914.9, 854679, '02', FALSE, 2, 2),
(11, 'CAB', 'Cao Bằng', 1, 6707.9, 530341, '04', FALSE, 2, 2),
(12, 'BKN', 'Bắc Kạn', 1, 4860.0, 313905, '06', FALSE, 2, 2),
(13, 'LCA', 'Lào Cai', 1, 6383.9, 730000, '10', FALSE, 2, 2),
(14, 'YBA', 'Yên Bái', 1, 6886.3, 821000, '15', FALSE, 2, 2),
(15, 'TNG', 'Thái Nguyên', 1, 3534.7, 1294000, '19', FALSE, 2, 2),
(16, 'LGS', 'Lạng Sơn', 1, 8320.8, 781000, '20', FALSE, 2, 2),
(17, 'QNH', 'Quảng Ninh', 1, 6102.3, 1320300, '22', FALSE, 2, 2),
(18, 'BGG', 'Bắc Giang', 1, 3848.9, 1803950, '24', FALSE, 2, 2),
(19, 'PTO', 'Phú Thọ', 1, 3533.3, 1466800, '25', FALSE, 2, 2),
(20, 'THA', 'Tuyên Quang', 1, 5867.3, 786800, '08', FALSE, 2, 2),

-- Tây Bắc (administrative_region_id = 3)
(21, 'DBO', 'Điện Biên', 1, 9562.9, 598856, '11', FALSE, 2, 3),
(22, 'LAC', 'Lai Châu', 1, 9068.8, 460196, '12', FALSE, 2, 3),
(23, 'SLA', 'Sơn La', 1, 14174.4, 1248904, '14', FALSE, 2, 3),
(24, 'HBH', 'Hòa Bình', 1, 4608.7, 854131, '17', FALSE, 2, 3),

-- Bắc Trung Bộ (administrative_region_id = 4)
(25, 'THH', 'Thanh Hóa', 1, 11132.2, 3645800, '38', FALSE, 2, 4),
(26, 'NAN', 'Nghệ An', 1, 16490.9, 3327791, '40', FALSE, 2, 4),
(27, 'HTH', 'Hà Tĩnh', 1, 5997.8, 1288866, '42', FALSE, 2, 4),

-- Miền Trung (region_id = 2)
-- Bắc Trung Bộ tiếp (administrative_region_id = 4)
(28, 'QBH', 'Quảng Bình', 2, 8065.3, 896599, '44', FALSE, 2, 4),
(29, 'QTR', 'Quảng Trị', 2, 4739.8, 628789, '45', FALSE, 2, 4),
(30, 'TTH', 'Thừa Thiên Huế', 2, 5033.2, 1163591, '46', FALSE, 2, 4),

-- Nam Trung Bộ (administrative_region_id = 5)
(31, 'DNG', 'Đà Nẵng', 2, 1285.4, 1134310, '48', TRUE, 1, 5),
(32, 'QNM', 'Quảng Nam', 2, 10574.7, 1493843, '49', FALSE, 2, 5),
(33, 'QNI', 'Quảng Ngãi', 2, 5153.0, 1231697, '51', FALSE, 2, 5),
(34, 'BDH', 'Bình Định', 2, 6050.6, 1529141, '52', FALSE, 2, 5),
(35, 'PYN', 'Phú Yên', 2, 5060.6, 868961, '54', FALSE, 2, 5),
(36, 'KHA', 'Khánh Hòa', 2, 5217.7, 1232844, '56', FALSE, 2, 5),
(37, 'NTN', 'Ninh Thuận', 2, 3358.3, 576739, '58', FALSE, 2, 5),
(38, 'BTN', 'Bình Thuận', 2, 7812.8, 1230408, '60', FALSE, 2, 5),

-- Tây Nguyên (administrative_region_id = 6)
(39, 'KTM', 'Kon Tum', 2, 9689.6, 540438, '62', FALSE, 2, 6),
(40, 'GLI', 'Gia Lai', 2, 15536.9, 1513847, '64', FALSE, 2, 6),
(41, 'DLK', 'Đắk Lắk', 2, 13125.4, 1869322, '66', FALSE, 2, 6),
(42, 'DNO', 'Đắk Nông', 2, 6515.6, 645413, '67', FALSE, 2, 6),
(43, 'LDG', 'Lâm Đồng', 2, 9773.5, 1298145, '68', FALSE, 2, 6),

-- Miền Nam (region_id = 3)
-- Đông Nam Bộ (administrative_region_id = 7)
(44, 'BPC', 'Bình Phước', 3, 6871.5, 994679, '70', FALSE, 2, 7),
(45, 'TNH', 'Tây Ninh', 3, 4041.4, 1169165, '72', FALSE, 2, 7),
(46, 'BDG', 'Bình Dương', 3, 2694.4, 2426561, '74', FALSE, 2, 7),
(47, 'DNI', 'Đồng Nai', 3, 5907.2, 3097107, '75', FALSE, 2, 7),
(48, 'BRV', 'Bà Rịa - Vũng Tàu', 3, 1989.5, 1148313, '77', FALSE, 2, 7),
(49, 'HCM', 'Hồ Chí Minh', 3, 2061.4, 9038600, '79', TRUE, 1, 7),

-- Đồng bằng sông Cửu Long (administrative_region_id = 8)
(50, 'LAN', 'Long An', 3, 4492.4, 1688547, '80', FALSE, 2, 8),
(51, 'TGG', 'Tiền Giang', 3, 2484.2, 1764185, '82', FALSE, 2, 8),
(52, 'BTE', 'Bến Tre', 3, 2360.6, 1288463, '83', FALSE, 2, 8),
(53, 'TVH', 'Trà Vinh', 3, 2341.2, 1009168, '84', FALSE, 2, 8),
(54, 'VLG', 'Vĩnh Long', 3, 1504.9, 1022791, '86', FALSE, 2, 8),
(55, 'DTP', 'Đồng Tháp', 3, 3377.0, 1599504, '87', FALSE, 2, 8),
(56, 'AGG', 'An Giang', 3, 3536.7, 1907403, '89', FALSE, 2, 8),
(57, 'KGG', 'Kiên Giang', 3, 6348.5, 1726188, '91', FALSE, 2, 8),
(58, 'CTO', 'Cần Thơ', 3, 1409.0, 1235171, '92', TRUE, 1, 8),
(59, 'HGG', 'Hậu Giang', 3, 1602.0, 733017, '93', FALSE, 2, 8),
(60, 'SOC', 'Sóc Trăng', 3, 3311.9, 1199653, '94', FALSE, 2, 8),
(61, 'BCL', 'Bạc Liêu', 3, 2468.7, 873400, '95', FALSE, 2, 8),
(62, 'CMU', 'Cà Mau', 3, 5294.9, 1191999, '96', FALSE, 2, 8);

-- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice
INSERT INTO reference.provinces (
    province_id, province_code, province_name, region_id, 
    area, population, gso_code, is_city, 
    administrative_unit_id, administrative_region_id
) VALUES
-- Miền Bắc (region_id = 1)
-- Đồng bằng sông Hồng (administrative_region_id = 1)
(1, 'HNO', 'Hà Nội', 1, 3358.6, 8418600, '01', TRUE, 1, 1),
(2, 'HPH', 'Hải Phòng', 1, 1561.8, 2029500, '31', TRUE, 1, 1),
(3, 'BNI', 'Bắc Ninh', 1, 822.7, 1368000, '27', FALSE, 2, 1),
(4, 'HDG', 'Hải Dương', 1, 1656.0, 1892100, '30', FALSE, 2, 1),
(5, 'HNG', 'Hưng Yên', 1, 926.0, 1252700, '33', FALSE, 2, 1),
(6, 'NDH', 'Nam Định', 1, 1652.6, 1780000, '36', FALSE, 2, 1),
(7, 'TBH', 'Thái Bình', 1, 1570.5, 1860000, '34', FALSE, 2, 1),
(8, 'VPC', 'Vĩnh Phúc', 1, 1236.5, 1154000, '26', FALSE, 2, 1),
(9, 'HNA', 'Hà Nam', 1, 860.5, 854000, '35', FALSE, 2, 1),

-- Đông Bắc (administrative_region_id = 2)
(10, 'HGG', 'Hà Giang', 1, 7914.9, 854679, '02', FALSE, 2, 2),
(11, 'CAB', 'Cao Bằng', 1, 6707.9, 530341, '04', FALSE, 2, 2),
(12, 'BKN', 'Bắc Kạn', 1, 4860.0, 313905, '06', FALSE, 2, 2),
(13, 'LCA', 'Lào Cai', 1, 6383.9, 730000, '10', FALSE, 2, 2),
(14, 'YBA', 'Yên Bái', 1, 6886.3, 821000, '15', FALSE, 2, 2),
(15, 'TNG', 'Thái Nguyên', 1, 3534.7, 1294000, '19', FALSE, 2, 2),
(16, 'LGS', 'Lạng Sơn', 1, 8320.8, 781000, '20', FALSE, 2, 2),
(17, 'QNH', 'Quảng Ninh', 1, 6102.3, 1320300, '22', FALSE, 2, 2),
(18, 'BGG', 'Bắc Giang', 1, 3848.9, 1803950, '24', FALSE, 2, 2),
(19, 'PTO', 'Phú Thọ', 1, 3533.3, 1466800, '25', FALSE, 2, 2),
(20, 'THA', 'Tuyên Quang', 1, 5867.3, 786800, '08', FALSE, 2, 2),

-- Tây Bắc (administrative_region_id = 3)
(21, 'DBO', 'Điện Biên', 1, 9562.9, 598856, '11', FALSE, 2, 3),
(22, 'LAC', 'Lai Châu', 1, 9068.8, 460196, '12', FALSE, 2, 3),
(23, 'SLA', 'Sơn La', 1, 14174.4, 1248904, '14', FALSE, 2, 3),
(24, 'HBH', 'Hòa Bình', 1, 4608.7, 854131, '17', FALSE, 2, 3),

-- Bắc Trung Bộ (administrative_region_id = 4)
(25, 'THH', 'Thanh Hóa', 1, 11132.2, 3645800, '38', FALSE, 2, 4),
(26, 'NAN', 'Nghệ An', 1, 16490.9, 3327791, '40', FALSE, 2, 4),
(27, 'HTH', 'Hà Tĩnh', 1, 5997.8, 1288866, '42', FALSE, 2, 4),

-- Miền Trung (region_id = 2)
-- Bắc Trung Bộ tiếp (administrative_region_id = 4)
(28, 'QBH', 'Quảng Bình', 2, 8065.3, 896599, '44', FALSE, 2, 4),
(29, 'QTR', 'Quảng Trị', 2, 4739.8, 628789, '45', FALSE, 2, 4),
(30, 'TTH', 'Thừa Thiên Huế', 2, 5033.2, 1163591, '46', FALSE, 2, 4),

-- Nam Trung Bộ (administrative_region_id = 5)
(31, 'DNG', 'Đà Nẵng', 2, 1285.4, 1134310, '48', TRUE, 1, 5),
(32, 'QNM', 'Quảng Nam', 2, 10574.7, 1493843, '49', FALSE, 2, 5),
(33, 'QNI', 'Quảng Ngãi', 2, 5153.0, 1231697, '51', FALSE, 2, 5),
(34, 'BDH', 'Bình Định', 2, 6050.6, 1529141, '52', FALSE, 2, 5),
(35, 'PYN', 'Phú Yên', 2, 5060.6, 868961, '54', FALSE, 2, 5),
(36, 'KHA', 'Khánh Hòa', 2, 5217.7, 1232844, '56', FALSE, 2, 5),
(37, 'NTN', 'Ninh Thuận', 2, 3358.3, 576739, '58', FALSE, 2, 5),
(38, 'BTN', 'Bình Thuận', 2, 7812.8, 1230408, '60', FALSE, 2, 5),

-- Tây Nguyên (administrative_region_id = 6)
(39, 'KTM', 'Kon Tum', 2, 9689.6, 540438, '62', FALSE, 2, 6),
(40, 'GLI', 'Gia Lai', 2, 15536.9, 1513847, '64', FALSE, 2, 6),
(41, 'DLK', 'Đắk Lắk', 2, 13125.4, 1869322, '66', FALSE, 2, 6),
(42, 'DNO', 'Đắk Nông', 2, 6515.6, 645413, '67', FALSE, 2, 6),
(43, 'LDG', 'Lâm Đồng', 2, 9773.5, 1298145, '68', FALSE, 2, 6),

-- Miền Nam (region_id = 3)
-- Đông Nam Bộ (administrative_region_id = 7)
(44, 'BPC', 'Bình Phước', 3, 6871.5, 994679, '70', FALSE, 2, 7),
(45, 'TNH', 'Tây Ninh', 3, 4041.4, 1169165, '72', FALSE, 2, 7),
(46, 'BDG', 'Bình Dương', 3, 2694.4, 2426561, '74', FALSE, 2, 7),
(47, 'DNI', 'Đồng Nai', 3, 5907.2, 3097107, '75', FALSE, 2, 7),
(48, 'BRV', 'Bà Rịa - Vũng Tàu', 3, 1989.5, 1148313, '77', FALSE, 2, 7),
(49, 'HCM', 'Hồ Chí Minh', 3, 2061.4, 9038600, '79', TRUE, 1, 7),

-- Đồng bằng sông Cửu Long (administrative_region_id = 8)
(50, 'LAN', 'Long An', 3, 4492.4, 1688547, '80', FALSE, 2, 8),
(51, 'TGG', 'Tiền Giang', 3, 2484.2, 1764185, '82', FALSE, 2, 8),
(52, 'BTE', 'Bến Tre', 3, 2360.6, 1288463, '83', FALSE, 2, 8),
(53, 'TVH', 'Trà Vinh', 3, 2341.2, 1009168, '84', FALSE, 2, 8),
(54, 'VLG', 'Vĩnh Long', 3, 1504.9, 1022791, '86', FALSE, 2, 8),
(55, 'DTP', 'Đồng Tháp', 3, 3377.0, 1599504, '87', FALSE, 2, 8),
(56, 'AGG', 'An Giang', 3, 3536.7, 1907403, '89', FALSE, 2, 8),
(57, 'KGG', 'Kiên Giang', 3, 6348.5, 1726188, '91', FALSE, 2, 8),
(58, 'CTO', 'Cần Thơ', 3, 1409.0, 1235171, '92', TRUE, 1, 8),
(59, 'HGG', 'Hậu Giang', 3, 1602.0, 733017, '93', FALSE, 2, 8),
(60, 'SOC', 'Sóc Trăng', 3, 3311.9, 1199653, '94', FALSE, 2, 8),
(61, 'BCL', 'Bạc Liêu', 3, 2468.7, 873400, '95', FALSE, 2, 8),
(62, 'CMU', 'Cà Mau', 3, 5294.9, 1191999, '96', FALSE, 2, 8);

-- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server
INSERT INTO reference.provinces (
    province_id, province_code, province_name, region_id, 
    area, population, gso_code, is_city, 
    administrative_unit_id, administrative_region_id
) VALUES
-- Miền Bắc (region_id = 1)
-- Đồng bằng sông Hồng (administrative_region_id = 1)
(1, 'HNO', 'Hà Nội', 1, 3358.6, 8418600, '01', TRUE, 1, 1),
(2, 'HPH', 'Hải Phòng', 1, 1561.8, 2029500, '31', TRUE, 1, 1),
(3, 'BNI', 'Bắc Ninh', 1, 822.7, 1368000, '27', FALSE, 2, 1),
(4, 'HDG', 'Hải Dương', 1, 1656.0, 1892100, '30', FALSE, 2, 1),
(5, 'HNG', 'Hưng Yên', 1, 926.0, 1252700, '33', FALSE, 2, 1),
(6, 'NDH', 'Nam Định', 1, 1652.6, 1780000, '36', FALSE, 2, 1),
(7, 'TBH', 'Thái Bình', 1, 1570.5, 1860000, '34', FALSE, 2, 1),
(8, 'VPC', 'Vĩnh Phúc', 1, 1236.5, 1154000, '26', FALSE, 2, 1),
(9, 'HNA', 'Hà Nam', 1, 860.5, 854000, '35', FALSE, 2, 1),

-- Đông Bắc (administrative_region_id = 2)
(10, 'HGG', 'Hà Giang', 1, 7914.9, 854679, '02', FALSE, 2, 2),
(11, 'CAB', 'Cao Bằng', 1, 6707.9, 530341, '04', FALSE, 2, 2),
(12, 'BKN', 'Bắc Kạn', 1, 4860.0, 313905, '06', FALSE, 2, 2),
(13, 'LCA', 'Lào Cai', 1, 6383.9, 730000, '10', FALSE, 2, 2),
(14, 'YBA', 'Yên Bái', 1, 6886.3, 821000, '15', FALSE, 2, 2),
(15, 'TNG', 'Thái Nguyên', 1, 3534.7, 1294000, '19', FALSE, 2, 2),
(16, 'LGS', 'Lạng Sơn', 1, 8320.8, 781000, '20', FALSE, 2, 2),
(17, 'QNH', 'Quảng Ninh', 1, 6102.3, 1320300, '22', FALSE, 2, 2),
(18, 'BGG', 'Bắc Giang', 1, 3848.9, 1803950, '24', FALSE, 2, 2),
(19, 'PTO', 'Phú Thọ', 1, 3533.3, 1466800, '25', FALSE, 2, 2),
(20, 'THA', 'Tuyên Quang', 1, 5867.3, 786800, '08', FALSE, 2, 2),

-- Tây Bắc (administrative_region_id = 3)
(21, 'DBO', 'Điện Biên', 1, 9562.9, 598856, '11', FALSE, 2, 3),
(22, 'LAC', 'Lai Châu', 1, 9068.8, 460196, '12', FALSE, 2, 3),
(23, 'SLA', 'Sơn La', 1, 14174.4, 1248904, '14', FALSE, 2, 3),
(24, 'HBH', 'Hòa Bình', 1, 4608.7, 854131, '17', FALSE, 2, 3),

-- Bắc Trung Bộ (administrative_region_id = 4)
(25, 'THH', 'Thanh Hóa', 1, 11132.2, 3645800, '38', FALSE, 2, 4),
(26, 'NAN', 'Nghệ An', 1, 16490.9, 3327791, '40', FALSE, 2, 4),
(27, 'HTH', 'Hà Tĩnh', 1, 5997.8, 1288866, '42', FALSE, 2, 4),

-- Miền Trung (region_id = 2)
-- Bắc Trung Bộ tiếp (administrative_region_id = 4)
(28, 'QBH', 'Quảng Bình', 2, 8065.3, 896599, '44', FALSE, 2, 4),
(29, 'QTR', 'Quảng Trị', 2, 4739.8, 628789, '45', FALSE, 2, 4),
(30, 'TTH', 'Thừa Thiên Huế', 2, 5033.2, 1163591, '46', FALSE, 2, 4),

-- Nam Trung Bộ (administrative_region_id = 5)
(31, 'DNG', 'Đà Nẵng', 2, 1285.4, 1134310, '48', TRUE, 1, 5),
(32, 'QNM', 'Quảng Nam', 2, 10574.7, 1493843, '49', FALSE, 2, 5),
(33, 'QNI', 'Quảng Ngãi', 2, 5153.0, 1231697, '51', FALSE, 2, 5),
(34, 'BDH', 'Bình Định', 2, 6050.6, 1529141, '52', FALSE, 2, 5),
(35, 'PYN', 'Phú Yên', 2, 5060.6, 868961, '54', FALSE, 2, 5),
(36, 'KHA', 'Khánh Hòa', 2, 5217.7, 1232844, '56', FALSE, 2, 5),
(37, 'NTN', 'Ninh Thuận', 2, 3358.3, 576739, '58', FALSE, 2, 5),
(38, 'BTN', 'Bình Thuận', 2, 7812.8, 1230408, '60', FALSE, 2, 5),

-- Tây Nguyên (administrative_region_id = 6)
(39, 'KTM', 'Kon Tum', 2, 9689.6, 540438, '62', FALSE, 2, 6),
(40, 'GLI', 'Gia Lai', 2, 15536.9, 1513847, '64', FALSE, 2, 6),
(41, 'DLK', 'Đắk Lắk', 2, 13125.4, 1869322, '66', FALSE, 2, 6),
(42, 'DNO', 'Đắk Nông', 2, 6515.6, 645413, '67', FALSE, 2, 6),
(43, 'LDG', 'Lâm Đồng', 2, 9773.5, 1298145, '68', FALSE, 2, 6),

-- Miền Nam (region_id = 3)
-- Đông Nam Bộ (administrative_region_id = 7)
(44, 'BPC', 'Bình Phước', 3, 6871.5, 994679, '70', FALSE, 2, 7),
(45, 'TNH', 'Tây Ninh', 3, 4041.4, 1169165, '72', FALSE, 2, 7),
(46, 'BDG', 'Bình Dương', 3, 2694.4, 2426561, '74', FALSE, 2, 7),
(47, 'DNI', 'Đồng Nai', 3, 5907.2, 3097107, '75', FALSE, 2, 7),
(48, 'BRV', 'Bà Rịa - Vũng Tàu', 3, 1989.5, 1148313, '77', FALSE, 2, 7),
(49, 'HCM', 'Hồ Chí Minh', 3, 2061.4, 9038600, '79', TRUE, 1, 7),

-- Đồng bằng sông Cửu Long (administrative_region_id = 8)
(50, 'LAN', 'Long An', 3, 4492.4, 1688547, '80', FALSE, 2, 8),
(51, 'TGG', 'Tiền Giang', 3, 2484.2, 1764185, '82', FALSE, 2, 8),
(52, 'BTE', 'Bến Tre', 3, 2360.6, 1288463, '83', FALSE, 2, 8),
(53, 'TVH', 'Trà Vinh', 3, 2341.2, 1009168, '84', FALSE, 2, 8),
(54, 'VLG', 'Vĩnh Long', 3, 1504.9, 1022791, '86', FALSE, 2, 8),
(55, 'DTP', 'Đồng Tháp', 3, 3377.0, 1599504, '87', FALSE, 2, 8),
(56, 'AGG', 'An Giang', 3, 3536.7, 1907403, '89', FALSE, 2, 8),
(57, 'KGG', 'Kiên Giang', 3, 6348.5, 1726188, '91', FALSE, 2, 8),
(58, 'CTO', 'Cần Thơ', 3, 1409.0, 1235171, '92', TRUE, 1, 8),
(59, 'HGG', 'Hậu Giang', 3, 1602.0, 733017, '93', FALSE, 2, 8),
(60, 'SOC', 'Sóc Trăng', 3, 3311.9, 1199653, '94', FALSE, 2, 8),
(61, 'BCL', 'Bạc Liêu', 3, 2468.7, 873400, '95', FALSE, 2, 8),
(62, 'CMU', 'Cà Mau', 3, 5294.9, 1191999, '96', FALSE, 2, 8);

\echo 'Hoàn thành nạp dữ liệu cho bảng provinces'
\echo 'Đã nạp dữ liệu cho 62 tỉnh/thành phố'

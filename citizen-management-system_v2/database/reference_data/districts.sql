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
(120, 'HOA', 'Hoài Đức', 1, 82.70, 229800, '253', FALSE, 2)
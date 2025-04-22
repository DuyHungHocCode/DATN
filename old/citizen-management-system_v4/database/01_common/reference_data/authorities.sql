-- File: database/reference_data/authorities.sql
-- Dữ liệu tham chiếu cho bảng authorities (cơ quan có thẩm quyền)
-- Chứa thông tin về các cơ quan công an, tư pháp, UBND các cấp và các cơ quan chức năng liên quan

\echo 'Bắt đầu nạp dữ liệu cho bảng authorities...'

-- Xóa dữ liệu cũ (nếu có)
\connect ministry_of_public_security
TRUNCATE TABLE reference.authorities CASCADE;

-- Nạp dữ liệu cho Bộ Công an
INSERT INTO reference.authorities (
    authority_id, authority_code, authority_name, authority_type,
    address, phone, email, province_id, district_id, ward_id,
    parent_authority_id, is_active
) VALUES

-- CƠ QUAN TRUNG ƯƠNG
-- Bộ Công an
(1, 'BCA', 'Bộ Công an', 'Bộ', 
'Số 44 Yết Kiêu, Hoàn Kiếm, Hà Nội', '024 3825 6255', 'bocongan@mps.gov.vn', 1, 102, NULL, 
NULL, TRUE),

-- Bộ Tư pháp
(2, 'BTP', 'Bộ Tư pháp', 'Bộ', 
'Số 58-60 Trần Phú, Ba Đình, Hà Nội', '024 6273 9718', 'btp@moj.gov.vn', 1, 101, NULL, 
NULL, TRUE),

-- Tổng cục Cảnh sát
(3, 'TCCS', 'Tổng cục Cảnh sát', 'Tổng cục', 
'Số 47 Phạm Văn Đồng, Cầu Giấy, Hà Nội', '024 3694 2593', 'canhsat@mps.gov.vn', 1, 105, NULL, 
1, TRUE),

-- Cục Cảnh sát quản lý hành chính về trật tự xã hội (C06)
(4, 'C06', 'Cục Cảnh sát quản lý hành chính về trật tự xã hội', 'Cục', 
'Số 47 Phạm Văn Đồng, Cầu Giấy, Hà Nội', '024 3556 3308', 'c06@mps.gov.vn', 1, 105, NULL, 
3, TRUE),

-- Cục Hộ tịch, quốc tịch, chứng thực
(5, 'HTQT', 'Cục Hộ tịch, quốc tịch, chứng thực', 'Cục', 
'Số 58-60 Trần Phú, Ba Đình, Hà Nội', '024 6273 9538', 'hotich@moj.gov.vn', 1, 101, NULL, 
2, TRUE),

-- CÔNG AN CẤP TỈNH/THÀNH PHỐ
-- Hà Nội
(10, 'CATP-HN', 'Công an thành phố Hà Nội', 'Công an tỉnh/thành phố', 
'Số 87 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội', '024 3826 9118', 'catp@hanoi.gov.vn', 1, 102, NULL, 
1, TRUE),

-- Hồ Chí Minh
(11, 'CATP-HCM', 'Công an thành phố Hồ Chí Minh', 'Công an tỉnh/thành phố', 
'268 Trần Hưng Đạo, Quận 1, TP Hồ Chí Minh', '028 3837 0330', 'catp@tphcm.gov.vn', 49, NULL, NULL, 
1, TRUE),

-- Đà Nẵng
(12, 'CATP-DN', 'Công an thành phố Đà Nẵng', 'Công an tỉnh/thành phố', 
'47 Lý Tự Trọng, Hải Châu, Đà Nẵng', '0236 3822 442', 'catp@danang.gov.vn', 31, NULL, NULL, 
1, TRUE),

-- Hải Phòng
(13, 'CATP-HP', 'Công an thành phố Hải Phòng', 'Công an tỉnh/thành phố', 
'Số 2 Lê Đại Hành, Hồng Bàng, Hải Phòng', '0225 3745 344', 'catp@haiphong.gov.vn', 2, 201, NULL, 
1, TRUE),

-- SỞ TƯ PHÁP CẤP TỈNH/THÀNH PHỐ
-- Hà Nội
(20, 'STP-HN', 'Sở Tư pháp thành phố Hà Nội', 'Sở Tư pháp', 
'Số 1B Trần Phú, Ba Đình, Hà Nội', '024 3733 0836', 'sotuphap@hanoi.gov.vn', 1, 101, NULL, 
2, TRUE),

-- Hồ Chí Minh
(21, 'STP-HCM', 'Sở Tư pháp thành phố Hồ Chí Minh', 'Sở Tư pháp', 
'141-143 Pasteur, Quận 3, TP Hồ Chí Minh', '028 3822 1748', 'sotuphap@tphcm.gov.vn', 49, NULL, NULL, 
2, TRUE),

-- Đà Nẵng
(22, 'STP-DN', 'Sở Tư pháp thành phố Đà Nẵng', 'Sở Tư pháp', 
'89 Tô Hiến Thành, Sơn Trà, Đà Nẵng', '0236 3888 432', 'sotuphap@danang.gov.vn', 31, NULL, NULL, 
2, TRUE),

-- Hải Phòng
(23, 'STP-HP', 'Sở Tư pháp thành phố Hải Phòng', 'Sở Tư pháp', 
'18 Hoàng Diệu, Hồng Bàng, Hải Phòng', '0225 3842 028', 'sotuphap@haiphong.gov.vn', 2, 201, NULL, 
2, TRUE),

-- UBND CẤP TỈNH/THÀNH PHỐ
-- Hà Nội
(30, 'UBND-HN', 'Ủy ban nhân dân thành phố Hà Nội', 'UBND cấp tỉnh', 
'Số 12 Lê Lai, Hoàn Kiếm, Hà Nội', '024 3825 3536', 'ubnd@hanoi.gov.vn', 1, 102, NULL, 
NULL, TRUE),

-- Hồ Chí Minh
(31, 'UBND-HCM', 'Ủy ban nhân dân thành phố Hồ Chí Minh', 'UBND cấp tỉnh', 
'86 Lê Thánh Tôn, Quận 1, TP Hồ Chí Minh', '028 3829 6052', 'ubnd@tphcm.gov.vn', 49, NULL, NULL, 
NULL, TRUE),

-- Đà Nẵng
(32, 'UBND-DN', 'Ủy ban nhân dân thành phố Đà Nẵng', 'UBND cấp tỉnh', 
'24 Trần Phú, Hải Châu, Đà Nẵng', '0236 3822 347', 'ubnd@danang.gov.vn', 31, NULL, NULL, 
NULL, TRUE),

-- Hải Phòng
(33, 'UBND-HP', 'Ủy ban nhân dân thành phố Hải Phòng', 'UBND cấp tỉnh', 
'18 Hoàng Diệu, Hồng Bàng, Hải Phòng', '0225 3821 238', 'ubnd@haiphong.gov.vn', 2, 201, NULL, 
NULL, TRUE),

-- CÔNG AN CẤP QUẬN/HUYỆN TẠI HÀ NỘI
(100, 'CAQ-BD', 'Công an quận Ba Đình', 'Công an quận/huyện', 
'37A Điện Biên Phủ, Ba Đình, Hà Nội', '024 3845 3267', 'caqbadinh@hanoi.gov.vn', 1, 101, NULL, 
10, TRUE),

(101, 'CAQ-HK', 'Công an quận Hoàn Kiếm', 'Công an quận/huyện', 
'3 Lý Thái Tổ, Hoàn Kiếm, Hà Nội', '024 3826 5067', 'caqhoankiem@hanoi.gov.vn', 1, 102, NULL, 
10, TRUE),

(102, 'CAQ-TX', 'Công an quận Thanh Xuân', 'Công an quận/huyện', 
'116 Nguyễn Trãi, Thanh Xuân, Hà Nội', '024 3557 1234', 'caqthanhxuan@hanoi.gov.vn', 1, 109, NULL, 
10, TRUE),

(103, 'CAQ-CG', 'Công an quận Cầu Giấy', 'Công an quận/huyện', 
'112 Trần Bình, Cầu Giấy, Hà Nội', '024 3834 5678', 'caqcaugiay@hanoi.gov.vn', 1, 105, NULL, 
10, TRUE),

(104, 'CAQ-HD', 'Công an quận Hà Đông', 'Công an quận/huyện', 
'2 Trần Phú, Hà Đông, Hà Nội', '024 3321 5678', 'caqhadong@hanoi.gov.vn', 1, 112, NULL, 
10, TRUE),

(105, 'CAH-SS', 'Công an huyện Sóc Sơn', 'Công an quận/huyện', 
'Thị trấn Sóc Sơn, Sóc Sơn, Hà Nội', '024 3884 1234', 'cahsocson@hanoi.gov.vn', 1, 113, NULL, 
10, TRUE),

-- PHÒNG TƯ PHÁP CẤP QUẬN/HUYỆN TẠI HÀ NỘI
(150, 'PTP-BD', 'Phòng Tư pháp quận Ba Đình', 'Phòng Tư pháp', 
'10 Trần Phú, Ba Đình, Hà Nội', '024 3823 4512', 'tuphapbadinh@hanoi.gov.vn', 1, 101, NULL, 
20, TRUE),

(151, 'PTP-HK', 'Phòng Tư pháp quận Hoàn Kiếm', 'Phòng Tư pháp', 
'26 Lý Thái Tổ, Hoàn Kiếm, Hà Nội', '024 3825 6789', 'tuphaphoankiem@hanoi.gov.vn', 1, 102, NULL, 
20, TRUE),

(152, 'PTP-TX', 'Phòng Tư pháp quận Thanh Xuân', 'Phòng Tư pháp', 
'72 Nguyễn Trãi, Thanh Xuân, Hà Nội', '024 3557 8901', 'tuphapdanhxuan@hanoi.gov.vn', 1, 109, NULL, 
20, TRUE),

(153, 'PTP-CG', 'Phòng Tư pháp quận Cầu Giấy', 'Phòng Tư pháp', 
'116 Trần Bình, Cầu Giấy, Hà Nội', '024 3834 6789', 'tuphapcaugiay@hanoi.gov.vn', 1, 105, NULL, 
20, TRUE),

(154, 'PTP-HD', 'Phòng Tư pháp quận Hà Đông', 'Phòng Tư pháp', 
'34 Trần Phú, Hà Đông, Hà Nội', '024 3321 2345', 'tuphaphadong@hanoi.gov.vn', 1, 112, NULL, 
20, TRUE),

(155, 'PTP-SS', 'Phòng Tư pháp huyện Sóc Sơn', 'Phòng Tư pháp', 
'Thị trấn Sóc Sơn, Sóc Sơn, Hà Nội', '024 3884 4556', 'tuphapsocson@hanoi.gov.vn', 1, 113, NULL, 
20, TRUE),

-- UBND CẤP QUẬN/HUYỆN TẠI HÀ NỘI
(200, 'UBND-BD', 'UBND quận Ba Đình', 'UBND cấp quận/huyện', 
'18 Trần Phú, Ba Đình, Hà Nội', '024 3823 1234', 'ubndbadinh@hanoi.gov.vn', 1, 101, NULL, 
30, TRUE),

(201, 'UBND-HK', 'UBND quận Hoàn Kiếm', 'UBND cấp quận/huyện', 
'126 Hàng Trống, Hoàn Kiếm, Hà Nội', '024 3825 8901', 'ubndhoankiem@hanoi.gov.vn', 1, 102, NULL, 
30, TRUE),

(202, 'UBND-TX', 'UBND quận Thanh Xuân', 'UBND cấp quận/huyện', 
'124 Nguyễn Trãi, Thanh Xuân, Hà Nội', '024 3557 6789', 'ubndthanhxuan@hanoi.gov.vn', 1, 109, NULL, 
30, TRUE),

(203, 'UBND-CG', 'UBND quận Cầu Giấy', 'UBND cấp quận/huyện', 
'118 Trần Bình, Cầu Giấy, Hà Nội', '024 3834 9012', 'ubndcaugiay@hanoi.gov.vn', 1, 105, NULL, 
30, TRUE),

(204, 'UBND-HD', 'UBND quận Hà Đông', 'UBND cấp quận/huyện', 
'36 Trần Phú, Hà Đông, Hà Nội', '024 3321 9012', 'ubndhadong@hanoi.gov.vn', 1, 112, NULL, 
30, TRUE),

(205, 'UBND-SS', 'UBND huyện Sóc Sơn', 'UBND cấp quận/huyện', 
'Thị trấn Sóc Sơn, Sóc Sơn, Hà Nội', '024 3884 6789', 'ubndsocson@hanoi.gov.vn', 1, 113, NULL, 
30, TRUE),

-- CÔNG AN CẤP QUẬN/HUYỆN TẠI TP HỒ CHÍ MINH
(300, 'CAQ-Q1', 'Công an Quận 1', 'Công an quận/huyện', 
'24 Lê Thánh Tôn, Quận 1, TP Hồ Chí Minh', '028 3829 7434', 'caquan1@tphcm.gov.vn', 49, NULL, NULL, 
11, TRUE),

(301, 'CAQ-Q3', 'Công an Quận 3', 'Công an quận/huyện', 
'258 Võ Văn Tần, Quận 3, TP Hồ Chí Minh', '028 3829 8765', 'caquan3@tphcm.gov.vn', 49, NULL, NULL, 
11, TRUE),

(302, 'CAQ-BTH', 'Công an quận Bình Thạnh', 'Công an quận/huyện', 
'16 Phan Đăng Lưu, Bình Thạnh, TP Hồ Chí Minh', '028 3510 1234', 'caqbinhthanh@tphcm.gov.vn', 49, NULL, NULL, 
11, TRUE),

-- PHÒNG TƯ PHÁP CẤP QUẬN/HUYỆN TẠI TP HỒ CHÍ MINH
(350, 'PTP-Q1', 'Phòng Tư pháp Quận 1', 'Phòng Tư pháp', 
'37 Lê Thánh Tôn, Quận 1, TP Hồ Chí Minh', '028 3829 8901', 'tuphapquan1@tphcm.gov.vn', 49, NULL, NULL, 
21, TRUE),

(351, 'PTP-Q3', 'Phòng Tư pháp Quận 3', 'Phòng Tư pháp', 
'260 Võ Văn Tần, Quận 3, TP Hồ Chí Minh', '028 3829 9012', 'tuphapquan3@tphcm.gov.vn', 49, NULL, NULL, 
21, TRUE),

(352, 'PTP-BTH', 'Phòng Tư pháp quận Bình Thạnh', 'Phòng Tư pháp', 
'18 Phan Đăng Lưu, Bình Thạnh, TP Hồ Chí Minh', '028 3510 2345', 'tuphapbinhthanh@tphcm.gov.vn', 49, NULL, NULL, 
21, TRUE),

-- UBND CẤP QUẬN/HUYỆN TẠI TP HỒ CHÍ MINH
(400, 'UBND-Q1', 'UBND Quận 1', 'UBND cấp quận/huyện', 
'45 Lý Tự Trọng, Quận 1, TP Hồ Chí Minh', '028 3829 5463', 'ubndquan1@tphcm.gov.vn', 49, NULL, NULL, 
31, TRUE),

(401, 'UBND-Q3', 'UBND Quận 3', 'UBND cấp quận/huyện', 
'261 Võ Văn Tần, Quận 3, TP Hồ Chí Minh', '028 3930 4567', 'ubndquan3@tphcm.gov.vn', 49, NULL, NULL, 
31, TRUE),

(402, 'UBND-BTH', 'UBND quận Bình Thạnh', 'UBND cấp quận/huyện', 
'6 Phan Đăng Lưu, Bình Thạnh, TP Hồ Chí Minh', '028 3512 3456', 'ubndbinhthanh@tphcm.gov.vn', 49, NULL, NULL, 
31, TRUE),

-- CÔNG AN CẤP PHƯỜNG/XÃ TẠI HÀ NỘI
(500, 'CAP-DHBD', 'Công an phường Điện Biên', 'Công an phường/xã', 
'22 Phố Liễu Giai, phường Điện Biên, Ba Đình, Hà Nội', '024 3734 1234', 'capdienbienphu@hanoi.gov.vn', 1, 101, NULL, 
100, TRUE),

(501, 'CAP-CDKM', 'Công an phường Chương Dương', 'Công an phường/xã', 
'15 Trần Nhật Duật, phường Chương Dương, Hoàn Kiếm, Hà Nội', '024 3825 2345', 'capchuongduong@hanoi.gov.vn', 1, 102, NULL, 
101, TRUE),

(502, 'CAP-NTTX', 'Công an phường Nhân Chính', 'Công an phường/xã', 
'73 Trường Chinh, phường Nhân Chính, Thanh Xuân, Hà Nội', '024 3858 3456', 'capnhanchinh@hanoi.gov.vn', 1, 109, NULL, 
102, TRUE);

-- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice
TRUNCATE TABLE reference.authorities CASCADE;

-- Copy dữ liệu từ Bộ Công an
INSERT INTO reference.authorities
SELECT * FROM ministry_of_public_security.reference.authorities;

-- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server
TRUNCATE TABLE reference.authorities CASCADE;

-- Copy dữ liệu từ Bộ Công an
INSERT INTO reference.authorities
SELECT * FROM ministry_of_public_security.reference.authorities;

\echo 'Hoàn thành nạp dữ liệu cho bảng authorities'
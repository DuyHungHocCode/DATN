\echo 'Thêm dữ liệu cho bảng quốc tịch...'

TRUNCATE TABLE reference.provinces CASCADE;

-- Nạp dữ liệu cho Bộ Công an
\connect ministry_of_public_security


INSERT INTO reference.nationalities (nationality_id, nationality_code, iso_code, nationality_name, country_name) VALUES
-- Việt Nam (đầu tiên)
(1, 'VN', 'VNM', 'Việt Nam', 'Cộng hòa Xã hội Chủ nghĩa Việt Nam'),

-- Các nước ASEAN (theo thứ tự alphabet)
(2, 'BN', 'BRN', 'Brunei', 'Quốc gia Brunei Darussalam'),
(3, 'KH', 'KHM', 'Campuchia', 'Vương quốc Campuchia'),
(4, 'ID', 'IDN', 'Indonesia', 'Cộng hòa Indonesia'),
(5, 'LA', 'LAO', 'Lào', 'Cộng hòa Dân chủ Nhân dân Lào'),
(6, 'MY', 'MYS', 'Malaysia', 'Malaysia'),
(7, 'MM', 'MMR', 'Myanmar', 'Cộng hòa Liên bang Myanmar'),
(8, 'PH', 'PHL', 'Philippines', 'Cộng hòa Philippines'),
(9, 'SG', 'SGP', 'Singapore', 'Cộng hòa Singapore'),
(10, 'TH', 'THA', 'Thái Lan', 'Vương quốc Thái Lan'),
(11, 'TL', 'TLS', 'Đông Timor', 'Cộng hòa Dân chủ Đông Timor'),

-- Các cường quốc và đối tác quan trọng
(12, 'US', 'USA', 'Hoa Kỳ', 'Hợp chủng quốc Hoa Kỳ'),
(13, 'CN', 'CHN', 'Trung Quốc', 'Cộng hòa Nhân dân Trung Hoa'),
(14, 'JP', 'JPN', 'Nhật Bản', 'Nhật Bản'),
(15, 'KR', 'KOR', 'Hàn Quốc', 'Đại Hàn Dân Quốc'),
(16, 'RU', 'RUS', 'Nga', 'Liên bang Nga'),
(17, 'DE', 'DEU', 'Đức', 'Cộng hòa Liên bang Đức'),
(18, 'FR', 'FRA', 'Pháp', 'Cộng hòa Pháp'),
(19, 'GB', 'GBR', 'Anh', 'Vương quốc Anh'),
(20, 'IN', 'IND', 'Ấn Độ', 'Cộng hòa Ấn Độ'),

-- Các nước và vùng lãnh thổ châu Á quan trọng
(21, 'TW', 'TWN', 'Đài Loan', 'Đài Loan'),
(22, 'HK', 'HKG', 'Hồng Kông', 'Đặc khu hành chính Hồng Kông'),
(23, 'MO', 'MAC', 'Ma Cao', 'Đặc khu hành chính Ma Cao'),
(24, 'KP', 'PRK', 'Triều Tiên', 'Cộng hòa Dân chủ Nhân dân Triều Tiên'),

-- Các quốc gia quan trọng khác
(25, 'AU', 'AUS', 'Úc', 'Liên bang Úc'),
(26, 'CA', 'CAN', 'Canada', 'Canada'),
(27, 'BR', 'BRA', 'Brazil', 'Cộng hòa Liên bang Brazil'),
(28, 'UA', 'UKR', 'Ukraine', 'Ukraine'),
(29, 'AE', 'ARE', 'Các Tiểu Vương quốc Ả Rập Thống nhất', 'Các Tiểu Vương quốc Ả Rập Thống nhất'),
(30, 'SA', 'SAU', 'Ả Rập Xê Út', 'Vương quốc Ả Rập Xê Út'),

-- Các quốc gia đại diện cho các khu vực khác
(31, 'TR', 'TUR', 'Thổ Nhĩ Kỳ', 'Cộng hòa Thổ Nhĩ Kỳ'),
(32, 'ZA', 'ZAF', 'Nam Phi', 'Cộng hòa Nam Phi'),
(33, 'NG', 'NGA', 'Nigeria', 'Cộng hòa Liên bang Nigeria'),
(34, 'MX', 'MEX', 'Mexico', 'Hợp chủng quốc Mexico'),
(35, 'AR', 'ARG', 'Argentina', 'Cộng hòa Argentina');

-- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice

INSERT INTO reference.nationalities (nationality_id, nationality_code, iso_code, nationality_name, country_name) VALUES
-- Việt Nam (đầu tiên)
(1, 'VN', 'VNM', 'Việt Nam', 'Cộng hòa Xã hội Chủ nghĩa Việt Nam'),

-- Các nước ASEAN (theo thứ tự alphabet)
(2, 'BN', 'BRN', 'Brunei', 'Quốc gia Brunei Darussalam'),
(3, 'KH', 'KHM', 'Campuchia', 'Vương quốc Campuchia'),
(4, 'ID', 'IDN', 'Indonesia', 'Cộng hòa Indonesia'),
(5, 'LA', 'LAO', 'Lào', 'Cộng hòa Dân chủ Nhân dân Lào'),
(6, 'MY', 'MYS', 'Malaysia', 'Malaysia'),
(7, 'MM', 'MMR', 'Myanmar', 'Cộng hòa Liên bang Myanmar'),
(8, 'PH', 'PHL', 'Philippines', 'Cộng hòa Philippines'),
(9, 'SG', 'SGP', 'Singapore', 'Cộng hòa Singapore'),
(10, 'TH', 'THA', 'Thái Lan', 'Vương quốc Thái Lan'),
(11, 'TL', 'TLS', 'Đông Timor', 'Cộng hòa Dân chủ Đông Timor'),

-- Các cường quốc và đối tác quan trọng
(12, 'US', 'USA', 'Hoa Kỳ', 'Hợp chủng quốc Hoa Kỳ'),
(13, 'CN', 'CHN', 'Trung Quốc', 'Cộng hòa Nhân dân Trung Hoa'),
(14, 'JP', 'JPN', 'Nhật Bản', 'Nhật Bản'),
(15, 'KR', 'KOR', 'Hàn Quốc', 'Đại Hàn Dân Quốc'),
(16, 'RU', 'RUS', 'Nga', 'Liên bang Nga'),
(17, 'DE', 'DEU', 'Đức', 'Cộng hòa Liên bang Đức'),
(18, 'FR', 'FRA', 'Pháp', 'Cộng hòa Pháp'),
(19, 'GB', 'GBR', 'Anh', 'Vương quốc Anh'),
(20, 'IN', 'IND', 'Ấn Độ', 'Cộng hòa Ấn Độ'),

-- Các nước và vùng lãnh thổ châu Á quan trọng
(21, 'TW', 'TWN', 'Đài Loan', 'Đài Loan'),
(22, 'HK', 'HKG', 'Hồng Kông', 'Đặc khu hành chính Hồng Kông'),
(23, 'MO', 'MAC', 'Ma Cao', 'Đặc khu hành chính Ma Cao'),
(24, 'KP', 'PRK', 'Triều Tiên', 'Cộng hòa Dân chủ Nhân dân Triều Tiên'),

-- Các quốc gia quan trọng khác
(25, 'AU', 'AUS', 'Úc', 'Liên bang Úc'),
(26, 'CA', 'CAN', 'Canada', 'Canada'),
(27, 'BR', 'BRA', 'Brazil', 'Cộng hòa Liên bang Brazil'),
(28, 'UA', 'UKR', 'Ukraine', 'Ukraine'),
(29, 'AE', 'ARE', 'Các Tiểu Vương quốc Ả Rập Thống nhất', 'Các Tiểu Vương quốc Ả Rập Thống nhất'),
(30, 'SA', 'SAU', 'Ả Rập Xê Út', 'Vương quốc Ả Rập Xê Út'),

-- Các quốc gia đại diện cho các khu vực khác
(31, 'TR', 'TUR', 'Thổ Nhĩ Kỳ', 'Cộng hòa Thổ Nhĩ Kỳ'),
(32, 'ZA', 'ZAF', 'Nam Phi', 'Cộng hòa Nam Phi'),
(33, 'NG', 'NGA', 'Nigeria', 'Cộng hòa Liên bang Nigeria'),
(34, 'MX', 'MEX', 'Mexico', 'Hợp chủng quốc Mexico'),
(35, 'AR', 'ARG', 'Argentina', 'Cộng hòa Argentina');

-- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server

INSERT INTO reference.nationalities (nationality_id, nationality_code, iso_code, nationality_name, country_name) VALUES
-- Việt Nam (đầu tiên)
(1, 'VN', 'VNM', 'Việt Nam', 'Cộng hòa Xã hội Chủ nghĩa Việt Nam'),

-- Các nước ASEAN (theo thứ tự alphabet)
(2, 'BN', 'BRN', 'Brunei', 'Quốc gia Brunei Darussalam'),
(3, 'KH', 'KHM', 'Campuchia', 'Vương quốc Campuchia'),
(4, 'ID', 'IDN', 'Indonesia', 'Cộng hòa Indonesia'),
(5, 'LA', 'LAO', 'Lào', 'Cộng hòa Dân chủ Nhân dân Lào'),
(6, 'MY', 'MYS', 'Malaysia', 'Malaysia'),
(7, 'MM', 'MMR', 'Myanmar', 'Cộng hòa Liên bang Myanmar'),
(8, 'PH', 'PHL', 'Philippines', 'Cộng hòa Philippines'),
(9, 'SG', 'SGP', 'Singapore', 'Cộng hòa Singapore'),
(10, 'TH', 'THA', 'Thái Lan', 'Vương quốc Thái Lan'),
(11, 'TL', 'TLS', 'Đông Timor', 'Cộng hòa Dân chủ Đông Timor'),

-- Các cường quốc và đối tác quan trọng
(12, 'US', 'USA', 'Hoa Kỳ', 'Hợp chủng quốc Hoa Kỳ'),
(13, 'CN', 'CHN', 'Trung Quốc', 'Cộng hòa Nhân dân Trung Hoa'),
(14, 'JP', 'JPN', 'Nhật Bản', 'Nhật Bản'),
(15, 'KR', 'KOR', 'Hàn Quốc', 'Đại Hàn Dân Quốc'),
(16, 'RU', 'RUS', 'Nga', 'Liên bang Nga'),
(17, 'DE', 'DEU', 'Đức', 'Cộng hòa Liên bang Đức'),
(18, 'FR', 'FRA', 'Pháp', 'Cộng hòa Pháp'),
(19, 'GB', 'GBR', 'Anh', 'Vương quốc Anh'),
(20, 'IN', 'IND', 'Ấn Độ', 'Cộng hòa Ấn Độ'),

-- Các nước và vùng lãnh thổ châu Á quan trọng
(21, 'TW', 'TWN', 'Đài Loan', 'Đài Loan'),
(22, 'HK', 'HKG', 'Hồng Kông', 'Đặc khu hành chính Hồng Kông'),
(23, 'MO', 'MAC', 'Ma Cao', 'Đặc khu hành chính Ma Cao'),
(24, 'KP', 'PRK', 'Triều Tiên', 'Cộng hòa Dân chủ Nhân dân Triều Tiên'),

-- Các quốc gia quan trọng khác
(25, 'AU', 'AUS', 'Úc', 'Liên bang Úc'),
(26, 'CA', 'CAN', 'Canada', 'Canada'),
(27, 'BR', 'BRA', 'Brazil', 'Cộng hòa Liên bang Brazil'),
(28, 'UA', 'UKR', 'Ukraine', 'Ukraine'),
(29, 'AE', 'ARE', 'Các Tiểu Vương quốc Ả Rập Thống nhất', 'Các Tiểu Vương quốc Ả Rập Thống nhất'),
(30, 'SA', 'SAU', 'Ả Rập Xê Út', 'Vương quốc Ả Rập Xê Út'),

-- Các quốc gia đại diện cho các khu vực khác
(31, 'TR', 'TUR', 'Thổ Nhĩ Kỳ', 'Cộng hòa Thổ Nhĩ Kỳ'),
(32, 'ZA', 'ZAF', 'Nam Phi', 'Cộng hòa Nam Phi'),
(33, 'NG', 'NGA', 'Nigeria', 'Cộng hòa Liên bang Nigeria'),
(34, 'MX', 'MEX', 'Mexico', 'Hợp chủng quốc Mexico'),
(35, 'AR', 'ARG', 'Argentina', 'Cộng hòa Argentina');
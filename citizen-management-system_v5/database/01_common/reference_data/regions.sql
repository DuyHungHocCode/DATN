-- File: database/reference_data/regions.sql
-- Dữ liệu tham chiếu cho bảng regions (vùng/miền)
-- Chứa thông tin cơ bản về 3 miền: Bắc, Trung, Nam

\echo 'Bắt đầu nạp dữ liệu cho bảng regions...'

-- Xóa dữ liệu cũ (nếu có)
TRUNCATE TABLE reference.regions CASCADE;

-- Nạp dữ liệu cho Bộ Công an
\connect ministry_of_public_security
INSERT INTO reference.regions (region_id, region_code, region_name, description) VALUES
(1, 'BAC', 'Miền Bắc', 'Bao gồm các tỉnh/thành phố từ Hà Tĩnh trở ra, với trung tâm là Thủ đô Hà Nội. Gồm các vùng: Đồng bằng sông Hồng, Đông Bắc, Tây Bắc và Bắc Trung Bộ'),
(2, 'TRU', 'Miền Trung', 'Bao gồm các tỉnh/thành phố từ Quảng Bình đến Bình Thuận, với trung tâm là thành phố Đà Nẵng. Gồm các vùng: Duyên hải Nam Trung Bộ và Tây Nguyên'),
(3, 'NAM', 'Miền Nam', 'Bao gồm các tỉnh/thành phố từ Bà Rịa - Vũng Tàu trở vào, với trung tâm là TP. Hồ Chí Minh. Gồm các vùng: Đông Nam Bộ và Đồng bằng sông Cửu Long');

-- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice
INSERT INTO reference.regions (region_id, region_code, region_name, description) VALUES
(1, 'BAC', 'Miền Bắc', 'Bao gồm các tỉnh/thành phố từ Hà Tĩnh trở ra, với trung tâm là Thủ đô Hà Nội. Gồm các vùng: Đồng bằng sông Hồng, Đông Bắc, Tây Bắc và Bắc Trung Bộ'),
(2, 'TRU', 'Miền Trung', 'Bao gồm các tỉnh/thành phố từ Quảng Bình đến Bình Thuận, với trung tâm là thành phố Đà Nẵng. Gồm các vùng: Duyên hải Nam Trung Bộ và Tây Nguyên'),
(3, 'NAM', 'Miền Nam', 'Bao gồm các tỉnh/thành phố từ Bà Rịa - Vũng Tàu trở vào, với trung tâm là TP. Hồ Chí Minh. Gồm các vùng: Đông Nam Bộ và Đồng bằng sông Cửu Long');

-- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server
INSERT INTO reference.regions (region_id, region_code, region_name, description) VALUES
(1, 'BAC', 'Miền Bắc', 'Bao gồm các tỉnh/thành phố từ Hà Tĩnh trở ra, với trung tâm là Thủ đô Hà Nội. Gồm các vùng: Đồng bằng sông Hồng, Đông Bắc, Tây Bắc và Bắc Trung Bộ'),
(2, 'TRU', 'Miền Trung', 'Bao gồm các tỉnh/thành phố từ Quảng Bình đến Bình Thuận, với trung tâm là thành phố Đà Nẵng. Gồm các vùng: Duyên hải Nam Trung Bộ và Tây Nguyên'),
(3, 'NAM', 'Miền Nam', 'Bao gồm các tỉnh/thành phố từ Bà Rịa - Vũng Tàu trở vào, với trung tâm là TP. Hồ Chí Minh. Gồm các vùng: Đông Nam Bộ và Đồng bằng sông Cửu Long');

\echo 'Hoàn thành nạp dữ liệu cho bảng regions'
\echo 'Đã nạp dữ liệu cho 3 miền: Bắc, Trung, Nam'

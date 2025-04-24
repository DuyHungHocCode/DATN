\echo 'Bắt đầu nạp dữ liệu cho bảng regions...'

-- Xóa dữ liệu cũ (nếu có)
\connect ministry_of_public_security
TRUNCATE TABLE reference.ethnicities CASCADE;

-- Nạp dữ liệu cho Bộ Công an
INSERT INTO reference.ethnicities (
    ethnicity_id, ethnicity_code, ethnicity_name, description,
    population
) VALUES

(1, 'KINH', 'Kinh', 'Dân tộc đa số của Việt Nam, phân bố rộng khắp cả nước. Văn hóa lúa nước là nét đặc trưng, với nhiều lễ hội truyền thống và phong tục tập quán phong phú.', 85320000),
(2, 'TAY', 'Tày', 'Cư trú chủ yếu ở vùng Đông Bắc Việt Nam. Có văn hóa cồng chiêng đặc sắc, sống định cư và làm nông nghiệp là chính.', 1850000),
(3, 'THAI', 'Thái', 'Tập trung chủ yếu ở Tây Bắc và Nghệ An. Nổi tiếng với nghề dệt thổ cẩm, văn hóa xòe Thái và kiến trúc nhà sàn độc đáo.', 1820000),
(4, 'MUONG', 'Mường', 'Sinh sống tập trung tại vùng Tây Bắc Bắc Bộ. Có nhiều nét văn hóa tương đồng với người Kinh, đặc biệt là trong ngôn ngữ và tín ngưỡng.', 1450000),
(5, 'HMONG', 'H''Mông', 'Cư trú chủ yếu ở vùng núi cao phía Bắc. Nổi tiếng với nghề trồng và chế biến lanh, dệt vải thổ cẩm và lễ hội Gầu Tào.', 1280000),
(6, 'KHMER', 'Khơ-me', 'Tập trung chủ yếu ở đồng bằng sông Cửu Long. Có nền văn hóa phật giáo Nam tông đặc trưng, kiến trúc chùa tháp độc đáo.', 1260000),
(7, 'NUNG', 'Nùng', 'Sinh sống chủ yếu ở các tỉnh Đông Bắc. Có nghề trồng lúa nước và làm ruộng bậc thang, nổi tiếng với lễ hội Lồng Tồng.', 1080000),
(8, 'HOA', 'Hoa', 'Phân bố rải rác khắp cả nước, tập trung nhiều ở các đô thị lớn. Giữ gìn văn hóa Trung Hoa truyền thống, nổi tiếng về kinh doanh buôn bán.', 823000),
(9, 'DAO', 'Dao', 'Cư trú rải rác ở vùng núi phía Bắc. Có nghề thêu, dệt và chạm bạc truyền thống, nổi tiếng với trang phục thổ cẩm đặc sắc.', 796000),
(10, 'GIARAI', 'Gia-rai', 'Sinh sống chủ yếu ở Tây Nguyên. Có văn hóa cồng chiêng độc đáo, kiến trúc nhà rông và lễ hội đâm trâu truyền thống.', 497000);
(11, 'EDE', 'Ê-đê', 'Cư trú chủ yếu ở Tây Nguyên, đặc biệt là Đắk Lắk. Theo chế độ mẫu hệ, nổi tiếng với sử thi Đăm San và nghệ thuật đánh cồng chiêng.', 398000),
(12, 'BANA', 'Ba Na', 'Sinh sống tập trung ở Tây Nguyên. Có văn hóa cồng chiêng độc đáo, kiến trúc nhà rông đặc trưng và lễ hội mừng lúa mới.', 248000),
(13, 'XODANG', 'Xơ-Đăng', 'Cư trú chủ yếu ở Kon Tum. Nổi tiếng với lễ hội đâm trâu, nghề dệt thổ cẩm và kiến trúc nhà rông truyền thống.', 190000),
(14, 'SANCHI', 'Sán Chay', 'Sinh sống chủ yếu ở vùng Đông Bắc. Có nghề dệt vải, thêu thùa tinh xảo và lễ hội Lồng Tồng đặc sắc.', 188000),
(15, 'COHO', 'Cơ Ho', 'Cư trú tại Lâm Đồng và một số tỉnh Tây Nguyên. Có văn hóa canh tác nương rẫy, lễ hội mừng lúa mới và nghề dệt thổ cẩm.', 186000),
(16, 'CHAM', 'Chăm', 'Tập trung ở Nam Trung Bộ. Là hậu duệ của vương quốc Champa, nổi tiếng với nghệ thuật kiến trúc tháp Chăm và nghề dệt vải truyền thống.', 178000),
(17, 'SANDIU', 'Sán Dìu', 'Sinh sống chủ yếu ở trung du Bắc Bộ. Có nghề trồng chè, dệt vải và các lễ hội cầu mùa đặc sắc.', 176000),
(18, 'HRE', 'Hrê', 'Cư trú tại Quảng Ngãi và các tỉnh duyên hải miền Trung. Có nghề trồng lúa nương và văn hóa cồng chiêng độc đáo.', 142000),
(19, 'MNONG', 'M''Nông', 'Sinh sống chủ yếu ở Đắk Lắk, Đắk Nông. Nổi tiếng với nghệ thuật sử dụng nhạc cụ truyền thống và lễ hội đâm trâu.', 128000),
(20, 'RAGLAI', 'Ra-glai', 'Cư trú tại các tỉnh duyên hải Nam Trung Bộ. Có nghề dệt thổ cẩm, đan lát và canh tác nương rẫy truyền thống.', 123000),
(21, 'XTIENG', 'X''Tiêng', 'Sinh sống tại Bình Phước và một số tỉnh Đông Nam Bộ. Có văn hóa canh tác nương rẫy và lễ hội mừng lúa mới.', 87000),
(22, 'BROVK', 'Bru-Vân Kiều', 'Cư trú chủ yếu ở Quảng Trị, Quảng Bình. Có nghề dệt thổ cẩm, đan lát và văn hóa cồng chiêng đặc sắc.', 74000),
(23, 'KHOMU', 'Khơ-mú', 'Sinh sống tại vùng Tây Bắc. Nổi tiếng với nghề rèn, đan lát và các lễ hội nông nghiệp truyền thống.', 72000),
(24, 'COTU', 'Cơ-tu', 'Cư trú chủ yếu ở Quảng Nam. Có nghề dệt zeng truyền thống và lễ hội đâm trâu nổi tiếng.', 61000),
(25, 'GIAY', 'Giáy', 'Sinh sống tại vùng núi phía Bắc. Có nghề trồng lúa nước, dệt vải và lễ hội cầu mùa đặc sắc.', 58000);
(26, 'GIETRI', 'Giẻ-Triêng', 'Sinh sống chủ yếu ở Kon Tum. Có văn hóa cồng chiêng đặc sắc và lễ hội mừng lúa mới truyền thống.', 51000),
(27, 'MA', 'Mạ', 'Cư trú tại Lâm Đồng và các tỉnh Tây Nguyên. Có nghề dệt thổ cẩm, canh tác nương rẫy và văn hóa cồng chiêng.', 41000),
(28, 'TAOI', 'Tà-ôi', 'Sinh sống tại Thừa Thiên-Huế và Quảng Trị. Nổi tiếng với nghề dệt zèng và kiến trúc nhà sàn truyền thống.', 43000),
(29, 'CHORO', 'Chơ-ro', 'Cư trú tại Đồng Nai và vùng Đông Nam Bộ. Có nghề canh tác nương rẫy và văn hóa lễ hội đặc sắc.', 26000),
(30, 'XINH', 'Xinh-mun', 'Sinh sống tại Sơn La và vùng Tây Bắc. Có nghề trồng lúa nương và các lễ hội cầu mùa truyền thống.', 24000),
(31, 'HANHI', 'Hà Nhì', 'Cư trú chủ yếu ở Lai Châu. Nổi tiếng với nghề trồng lúa ruộng bậc thang và trang phục thổ cẩm đặc sắc.', 22000),
(32, 'CHURU', 'Chu-ru', 'Sinh sống tại Lâm Đồng. Có văn hóa cồng chiêng, lễ hội mừng lúa mới và nghề dệt thổ cẩm truyền thống.', 19000),
(33, 'LAO', 'Lào', 'Cư trú tại vùng biên giới Việt-Lào. Có nhiều nét văn hóa tương đồng với người Lào, giữ gìn phong tục tập quán riêng.', 15000),
(34, 'KHANG', 'Kháng', 'Sinh sống tại Sơn La và Điện Biên. Có nghề canh tác nương rẫy và văn hóa lễ hội đặc trưng.', 14000),
(35, 'LACHI', 'La Chí', 'Cư trú tại Hà Giang. Nổi tiếng với nghề dệt vải, thêu thùa và kiến trúc nhà sàn truyền thống.', 13000),
(36, 'PHULA', 'Phù Lá', 'Sinh sống tại vùng núi phía Bắc. Có nghề trồng lúa nương và văn hóa trang phục đặc sắc.', 11000),
(37, 'LAHU', 'La Hủ', 'Cư trú tại Lai Châu. Có nghề canh tác nương rẫy và các lễ hội cầu mùa truyền thống.', 9000),
(38, 'LAHA', 'La Ha', 'Sinh sống tại Sơn La. Có văn hóa canh tác nương rẫy và lễ hội đặc trưng.', 8000),
(39, 'PATHEN', 'Pà Thẻn', 'Cư trú tại Hà Giang, Tuyên Quang. Nổi tiếng với nghề dệt vải và trang phục truyền thống.', 7000),
(40, 'CHUT', 'Chứt', 'Sinh sống tại Quảng Bình. Có văn hóa du canh du cư và các nghi lễ tín ngưỡng đặc trưng.', 7000);
(41, 'LOHO', 'Lô Lô', 'Sinh sống chủ yếu ở Hà Giang, Cao Bằng. Nổi tiếng với nghề dệt vải thổ cẩm và lễ hội Gầu Tào đặc sắc.', 6000),
(42, 'MANG', 'Mảng', 'Cư trú tại Lai Châu. Có văn hóa canh tác nương rẫy và các lễ hội cầu mùa truyền thống.', 5500),
(43, 'COLAO', 'Cờ Lao', 'Sinh sống tại Hà Giang. Có nghề trồng lúa nước, dệt vải và kiến trúc nhà sàn đặc trưng.', 4000),
(44, 'BOY', 'Bố Y', 'Cư trú tại Lào Cai. Nổi tiếng với nghề thêu, dệt và các lễ hội truyền thống.', 3500),
(45, 'NGAI', 'Ngái', 'Sinh sống tại Cao Bằng và Lạng Sơn. Có nhiều nét văn hóa tương đồng với người Hoa, giữ gìn phong tục riêng.', 3200),
(46, 'CONONG', 'Cống', 'Cư trú tại Điện Biên. Có nghề canh tác nương rẫy và văn hóa trang phục đặc sắc.', 2800),
(47, 'BRAU', 'Brâu', 'Sinh sống tại Kon Tum. Có văn hóa cồng chiêng và lễ hội mừng lúa mới truyền thống.', 2700),
(48, 'OZU', 'Ơ Đu', 'Cư trú tại Nghệ An. Có nghề đan lát, săn bắt và các nghi lễ tín ngưỡng đặc trưng.', 2500),
(49, 'ROMAM', 'Rơ Măm', 'Sinh sống tại Kon Tum. Là một trong những dân tộc có dân số ít nhất Việt Nam, có văn hóa cồng chiêng độc đáo.', 600),
(50, 'PUPEO', 'Pu Péo', 'Cư trú tại Hà Giang. Có nghề dệt vải, thêu thùa và các lễ hội cầu mùa truyền thống.', 900),
(51, 'SILA', 'Si La', 'Sinh sống tại Điện Biên. Có văn hóa canh tác nương rẫy và trang phục truyền thống đặc sắc.', 800),
(52, 'LULUONG', 'Lu', 'Cư trú tại Lai Châu. Có nghề trồng lúa nương và các lễ hội đặc trưng.', 600),
(53, 'NGUON', 'Ngươn', 'Sinh sống tại Quảng Bình. Có văn hóa du canh và các nghi lễ tín ngưỡng riêng.', 500),
(54, 'MLAO', 'MLao', 'Cư trú tại các tỉnh Tây Nguyên. Có nghề canh tác nương rẫy và văn hóa cồng chiêng truyền thống.', 400);


\connect ministry_of_justice
TRUNCATE TABLE reference.ethnicities CASCADE;

-- Nạp dữ liệu cho Bộ Công an
INSERT INTO reference.ethnicities (
    ethnicity_id, ethnicity_code, ethnicity_name, description,
    population
) VALUES

(1, 'KINH', 'Kinh', 'Dân tộc đa số của Việt Nam, phân bố rộng khắp cả nước. Văn hóa lúa nước là nét đặc trưng, với nhiều lễ hội truyền thống và phong tục tập quán phong phú.', 85320000),
(2, 'TAY', 'Tày', 'Cư trú chủ yếu ở vùng Đông Bắc Việt Nam. Có văn hóa cồng chiêng đặc sắc, sống định cư và làm nông nghiệp là chính.', 1850000),
(3, 'THAI', 'Thái', 'Tập trung chủ yếu ở Tây Bắc và Nghệ An. Nổi tiếng với nghề dệt thổ cẩm, văn hóa xòe Thái và kiến trúc nhà sàn độc đáo.', 1820000),
(4, 'MUONG', 'Mường', 'Sinh sống tập trung tại vùng Tây Bắc Bắc Bộ. Có nhiều nét văn hóa tương đồng với người Kinh, đặc biệt là trong ngôn ngữ và tín ngưỡng.', 1450000),
(5, 'HMONG', 'H''Mông', 'Cư trú chủ yếu ở vùng núi cao phía Bắc. Nổi tiếng với nghề trồng và chế biến lanh, dệt vải thổ cẩm và lễ hội Gầu Tào.', 1280000),
(6, 'KHMER', 'Khơ-me', 'Tập trung chủ yếu ở đồng bằng sông Cửu Long. Có nền văn hóa phật giáo Nam tông đặc trưng, kiến trúc chùa tháp độc đáo.', 1260000),
(7, 'NUNG', 'Nùng', 'Sinh sống chủ yếu ở các tỉnh Đông Bắc. Có nghề trồng lúa nước và làm ruộng bậc thang, nổi tiếng với lễ hội Lồng Tồng.', 1080000),
(8, 'HOA', 'Hoa', 'Phân bố rải rác khắp cả nước, tập trung nhiều ở các đô thị lớn. Giữ gìn văn hóa Trung Hoa truyền thống, nổi tiếng về kinh doanh buôn bán.', 823000),
(9, 'DAO', 'Dao', 'Cư trú rải rác ở vùng núi phía Bắc. Có nghề thêu, dệt và chạm bạc truyền thống, nổi tiếng với trang phục thổ cẩm đặc sắc.', 796000),
(10, 'GIARAI', 'Gia-rai', 'Sinh sống chủ yếu ở Tây Nguyên. Có văn hóa cồng chiêng độc đáo, kiến trúc nhà rông và lễ hội đâm trâu truyền thống.', 497000);
(11, 'EDE', 'Ê-đê', 'Cư trú chủ yếu ở Tây Nguyên, đặc biệt là Đắk Lắk. Theo chế độ mẫu hệ, nổi tiếng với sử thi Đăm San và nghệ thuật đánh cồng chiêng.', 398000),
(12, 'BANA', 'Ba Na', 'Sinh sống tập trung ở Tây Nguyên. Có văn hóa cồng chiêng độc đáo, kiến trúc nhà rông đặc trưng và lễ hội mừng lúa mới.', 248000),
(13, 'XODANG', 'Xơ-Đăng', 'Cư trú chủ yếu ở Kon Tum. Nổi tiếng với lễ hội đâm trâu, nghề dệt thổ cẩm và kiến trúc nhà rông truyền thống.', 190000),
(14, 'SANCHI', 'Sán Chay', 'Sinh sống chủ yếu ở vùng Đông Bắc. Có nghề dệt vải, thêu thùa tinh xảo và lễ hội Lồng Tồng đặc sắc.', 188000),
(15, 'COHO', 'Cơ Ho', 'Cư trú tại Lâm Đồng và một số tỉnh Tây Nguyên. Có văn hóa canh tác nương rẫy, lễ hội mừng lúa mới và nghề dệt thổ cẩm.', 186000),
(16, 'CHAM', 'Chăm', 'Tập trung ở Nam Trung Bộ. Là hậu duệ của vương quốc Champa, nổi tiếng với nghệ thuật kiến trúc tháp Chăm và nghề dệt vải truyền thống.', 178000),
(17, 'SANDIU', 'Sán Dìu', 'Sinh sống chủ yếu ở trung du Bắc Bộ. Có nghề trồng chè, dệt vải và các lễ hội cầu mùa đặc sắc.', 176000),
(18, 'HRE', 'Hrê', 'Cư trú tại Quảng Ngãi và các tỉnh duyên hải miền Trung. Có nghề trồng lúa nương và văn hóa cồng chiêng độc đáo.', 142000),
(19, 'MNONG', 'M''Nông', 'Sinh sống chủ yếu ở Đắk Lắk, Đắk Nông. Nổi tiếng với nghệ thuật sử dụng nhạc cụ truyền thống và lễ hội đâm trâu.', 128000),
(20, 'RAGLAI', 'Ra-glai', 'Cư trú tại các tỉnh duyên hải Nam Trung Bộ. Có nghề dệt thổ cẩm, đan lát và canh tác nương rẫy truyền thống.', 123000),
(21, 'XTIENG', 'X''Tiêng', 'Sinh sống tại Bình Phước và một số tỉnh Đông Nam Bộ. Có văn hóa canh tác nương rẫy và lễ hội mừng lúa mới.', 87000),
(22, 'BROVK', 'Bru-Vân Kiều', 'Cư trú chủ yếu ở Quảng Trị, Quảng Bình. Có nghề dệt thổ cẩm, đan lát và văn hóa cồng chiêng đặc sắc.', 74000),
(23, 'KHOMU', 'Khơ-mú', 'Sinh sống tại vùng Tây Bắc. Nổi tiếng với nghề rèn, đan lát và các lễ hội nông nghiệp truyền thống.', 72000),
(24, 'COTU', 'Cơ-tu', 'Cư trú chủ yếu ở Quảng Nam. Có nghề dệt zeng truyền thống và lễ hội đâm trâu nổi tiếng.', 61000),
(25, 'GIAY', 'Giáy', 'Sinh sống tại vùng núi phía Bắc. Có nghề trồng lúa nước, dệt vải và lễ hội cầu mùa đặc sắc.', 58000);
(26, 'GIETRI', 'Giẻ-Triêng', 'Sinh sống chủ yếu ở Kon Tum. Có văn hóa cồng chiêng đặc sắc và lễ hội mừng lúa mới truyền thống.', 51000),
(27, 'MA', 'Mạ', 'Cư trú tại Lâm Đồng và các tỉnh Tây Nguyên. Có nghề dệt thổ cẩm, canh tác nương rẫy và văn hóa cồng chiêng.', 41000),
(28, 'TAOI', 'Tà-ôi', 'Sinh sống tại Thừa Thiên-Huế và Quảng Trị. Nổi tiếng với nghề dệt zèng và kiến trúc nhà sàn truyền thống.', 43000),
(29, 'CHORO', 'Chơ-ro', 'Cư trú tại Đồng Nai và vùng Đông Nam Bộ. Có nghề canh tác nương rẫy và văn hóa lễ hội đặc sắc.', 26000),
(30, 'XINH', 'Xinh-mun', 'Sinh sống tại Sơn La và vùng Tây Bắc. Có nghề trồng lúa nương và các lễ hội cầu mùa truyền thống.', 24000),
(31, 'HANHI', 'Hà Nhì', 'Cư trú chủ yếu ở Lai Châu. Nổi tiếng với nghề trồng lúa ruộng bậc thang và trang phục thổ cẩm đặc sắc.', 22000),
(32, 'CHURU', 'Chu-ru', 'Sinh sống tại Lâm Đồng. Có văn hóa cồng chiêng, lễ hội mừng lúa mới và nghề dệt thổ cẩm truyền thống.', 19000),
(33, 'LAO', 'Lào', 'Cư trú tại vùng biên giới Việt-Lào. Có nhiều nét văn hóa tương đồng với người Lào, giữ gìn phong tục tập quán riêng.', 15000),
(34, 'KHANG', 'Kháng', 'Sinh sống tại Sơn La và Điện Biên. Có nghề canh tác nương rẫy và văn hóa lễ hội đặc trưng.', 14000),
(35, 'LACHI', 'La Chí', 'Cư trú tại Hà Giang. Nổi tiếng với nghề dệt vải, thêu thùa và kiến trúc nhà sàn truyền thống.', 13000),
(36, 'PHULA', 'Phù Lá', 'Sinh sống tại vùng núi phía Bắc. Có nghề trồng lúa nương và văn hóa trang phục đặc sắc.', 11000),
(37, 'LAHU', 'La Hủ', 'Cư trú tại Lai Châu. Có nghề canh tác nương rẫy và các lễ hội cầu mùa truyền thống.', 9000),
(38, 'LAHA', 'La Ha', 'Sinh sống tại Sơn La. Có văn hóa canh tác nương rẫy và lễ hội đặc trưng.', 8000),
(39, 'PATHEN', 'Pà Thẻn', 'Cư trú tại Hà Giang, Tuyên Quang. Nổi tiếng với nghề dệt vải và trang phục truyền thống.', 7000),
(40, 'CHUT', 'Chứt', 'Sinh sống tại Quảng Bình. Có văn hóa du canh du cư và các nghi lễ tín ngưỡng đặc trưng.', 7000);
(41, 'LOHO', 'Lô Lô', 'Sinh sống chủ yếu ở Hà Giang, Cao Bằng. Nổi tiếng với nghề dệt vải thổ cẩm và lễ hội Gầu Tào đặc sắc.', 6000),
(42, 'MANG', 'Mảng', 'Cư trú tại Lai Châu. Có văn hóa canh tác nương rẫy và các lễ hội cầu mùa truyền thống.', 5500),
(43, 'COLAO', 'Cờ Lao', 'Sinh sống tại Hà Giang. Có nghề trồng lúa nước, dệt vải và kiến trúc nhà sàn đặc trưng.', 4000),
(44, 'BOY', 'Bố Y', 'Cư trú tại Lào Cai. Nổi tiếng với nghề thêu, dệt và các lễ hội truyền thống.', 3500),
(45, 'NGAI', 'Ngái', 'Sinh sống tại Cao Bằng và Lạng Sơn. Có nhiều nét văn hóa tương đồng với người Hoa, giữ gìn phong tục riêng.', 3200),
(46, 'CONONG', 'Cống', 'Cư trú tại Điện Biên. Có nghề canh tác nương rẫy và văn hóa trang phục đặc sắc.', 2800),
(47, 'BRAU', 'Brâu', 'Sinh sống tại Kon Tum. Có văn hóa cồng chiêng và lễ hội mừng lúa mới truyền thống.', 2700),
(48, 'OZU', 'Ơ Đu', 'Cư trú tại Nghệ An. Có nghề đan lát, săn bắt và các nghi lễ tín ngưỡng đặc trưng.', 2500),
(49, 'ROMAM', 'Rơ Măm', 'Sinh sống tại Kon Tum. Là một trong những dân tộc có dân số ít nhất Việt Nam, có văn hóa cồng chiêng độc đáo.', 600),
(50, 'PUPEO', 'Pu Péo', 'Cư trú tại Hà Giang. Có nghề dệt vải, thêu thùa và các lễ hội cầu mùa truyền thống.', 900),
(51, 'SILA', 'Si La', 'Sinh sống tại Điện Biên. Có văn hóa canh tác nương rẫy và trang phục truyền thống đặc sắc.', 800),
(52, 'LULUONG', 'Lu', 'Cư trú tại Lai Châu. Có nghề trồng lúa nương và các lễ hội đặc trưng.', 600),
(53, 'NGUON', 'Ngươn', 'Sinh sống tại Quảng Bình. Có văn hóa du canh và các nghi lễ tín ngưỡng riêng.', 500),
(54, 'MLAO', 'MLao', 'Cư trú tại các tỉnh Tây Nguyên. Có nghề canh tác nương rẫy và văn hóa cồng chiêng truyền thống.', 400);


\connect national_citizen_central_server
TRUNCATE TABLE reference.ethnicities CASCADE;

-- Nạp dữ liệu cho Bộ Công an
INSERT INTO reference.ethnicities (
    ethnicity_id, ethnicity_code, ethnicity_name, description,
    population
) VALUES

(1, 'KINH', 'Kinh', 'Dân tộc đa số của Việt Nam, phân bố rộng khắp cả nước. Văn hóa lúa nước là nét đặc trưng, với nhiều lễ hội truyền thống và phong tục tập quán phong phú.', 85320000),
(2, 'TAY', 'Tày', 'Cư trú chủ yếu ở vùng Đông Bắc Việt Nam. Có văn hóa cồng chiêng đặc sắc, sống định cư và làm nông nghiệp là chính.', 1850000),
(3, 'THAI', 'Thái', 'Tập trung chủ yếu ở Tây Bắc và Nghệ An. Nổi tiếng với nghề dệt thổ cẩm, văn hóa xòe Thái và kiến trúc nhà sàn độc đáo.', 1820000),
(4, 'MUONG', 'Mường', 'Sinh sống tập trung tại vùng Tây Bắc Bắc Bộ. Có nhiều nét văn hóa tương đồng với người Kinh, đặc biệt là trong ngôn ngữ và tín ngưỡng.', 1450000),
(5, 'HMONG', 'H''Mông', 'Cư trú chủ yếu ở vùng núi cao phía Bắc. Nổi tiếng với nghề trồng và chế biến lanh, dệt vải thổ cẩm và lễ hội Gầu Tào.', 1280000),
(6, 'KHMER', 'Khơ-me', 'Tập trung chủ yếu ở đồng bằng sông Cửu Long. Có nền văn hóa phật giáo Nam tông đặc trưng, kiến trúc chùa tháp độc đáo.', 1260000),
(7, 'NUNG', 'Nùng', 'Sinh sống chủ yếu ở các tỉnh Đông Bắc. Có nghề trồng lúa nước và làm ruộng bậc thang, nổi tiếng với lễ hội Lồng Tồng.', 1080000),
(8, 'HOA', 'Hoa', 'Phân bố rải rác khắp cả nước, tập trung nhiều ở các đô thị lớn. Giữ gìn văn hóa Trung Hoa truyền thống, nổi tiếng về kinh doanh buôn bán.', 823000),
(9, 'DAO', 'Dao', 'Cư trú rải rác ở vùng núi phía Bắc. Có nghề thêu, dệt và chạm bạc truyền thống, nổi tiếng với trang phục thổ cẩm đặc sắc.', 796000),
(10, 'GIARAI', 'Gia-rai', 'Sinh sống chủ yếu ở Tây Nguyên. Có văn hóa cồng chiêng độc đáo, kiến trúc nhà rông và lễ hội đâm trâu truyền thống.', 497000);
(11, 'EDE', 'Ê-đê', 'Cư trú chủ yếu ở Tây Nguyên, đặc biệt là Đắk Lắk. Theo chế độ mẫu hệ, nổi tiếng với sử thi Đăm San và nghệ thuật đánh cồng chiêng.', 398000),
(12, 'BANA', 'Ba Na', 'Sinh sống tập trung ở Tây Nguyên. Có văn hóa cồng chiêng độc đáo, kiến trúc nhà rông đặc trưng và lễ hội mừng lúa mới.', 248000),
(13, 'XODANG', 'Xơ-Đăng', 'Cư trú chủ yếu ở Kon Tum. Nổi tiếng với lễ hội đâm trâu, nghề dệt thổ cẩm và kiến trúc nhà rông truyền thống.', 190000),
(14, 'SANCHI', 'Sán Chay', 'Sinh sống chủ yếu ở vùng Đông Bắc. Có nghề dệt vải, thêu thùa tinh xảo và lễ hội Lồng Tồng đặc sắc.', 188000),
(15, 'COHO', 'Cơ Ho', 'Cư trú tại Lâm Đồng và một số tỉnh Tây Nguyên. Có văn hóa canh tác nương rẫy, lễ hội mừng lúa mới và nghề dệt thổ cẩm.', 186000),
(16, 'CHAM', 'Chăm', 'Tập trung ở Nam Trung Bộ. Là hậu duệ của vương quốc Champa, nổi tiếng với nghệ thuật kiến trúc tháp Chăm và nghề dệt vải truyền thống.', 178000),
(17, 'SANDIU', 'Sán Dìu', 'Sinh sống chủ yếu ở trung du Bắc Bộ. Có nghề trồng chè, dệt vải và các lễ hội cầu mùa đặc sắc.', 176000),
(18, 'HRE', 'Hrê', 'Cư trú tại Quảng Ngãi và các tỉnh duyên hải miền Trung. Có nghề trồng lúa nương và văn hóa cồng chiêng độc đáo.', 142000),
(19, 'MNONG', 'M''Nông', 'Sinh sống chủ yếu ở Đắk Lắk, Đắk Nông. Nổi tiếng với nghệ thuật sử dụng nhạc cụ truyền thống và lễ hội đâm trâu.', 128000),
(20, 'RAGLAI', 'Ra-glai', 'Cư trú tại các tỉnh duyên hải Nam Trung Bộ. Có nghề dệt thổ cẩm, đan lát và canh tác nương rẫy truyền thống.', 123000),
(21, 'XTIENG', 'X''Tiêng', 'Sinh sống tại Bình Phước và một số tỉnh Đông Nam Bộ. Có văn hóa canh tác nương rẫy và lễ hội mừng lúa mới.', 87000),
(22, 'BROVK', 'Bru-Vân Kiều', 'Cư trú chủ yếu ở Quảng Trị, Quảng Bình. Có nghề dệt thổ cẩm, đan lát và văn hóa cồng chiêng đặc sắc.', 74000),
(23, 'KHOMU', 'Khơ-mú', 'Sinh sống tại vùng Tây Bắc. Nổi tiếng với nghề rèn, đan lát và các lễ hội nông nghiệp truyền thống.', 72000),
(24, 'COTU', 'Cơ-tu', 'Cư trú chủ yếu ở Quảng Nam. Có nghề dệt zeng truyền thống và lễ hội đâm trâu nổi tiếng.', 61000),
(25, 'GIAY', 'Giáy', 'Sinh sống tại vùng núi phía Bắc. Có nghề trồng lúa nước, dệt vải và lễ hội cầu mùa đặc sắc.', 58000);
(26, 'GIETRI', 'Giẻ-Triêng', 'Sinh sống chủ yếu ở Kon Tum. Có văn hóa cồng chiêng đặc sắc và lễ hội mừng lúa mới truyền thống.', 51000),
(27, 'MA', 'Mạ', 'Cư trú tại Lâm Đồng và các tỉnh Tây Nguyên. Có nghề dệt thổ cẩm, canh tác nương rẫy và văn hóa cồng chiêng.', 41000),
(28, 'TAOI', 'Tà-ôi', 'Sinh sống tại Thừa Thiên-Huế và Quảng Trị. Nổi tiếng với nghề dệt zèng và kiến trúc nhà sàn truyền thống.', 43000),
(29, 'CHORO', 'Chơ-ro', 'Cư trú tại Đồng Nai và vùng Đông Nam Bộ. Có nghề canh tác nương rẫy và văn hóa lễ hội đặc sắc.', 26000),
(30, 'XINH', 'Xinh-mun', 'Sinh sống tại Sơn La và vùng Tây Bắc. Có nghề trồng lúa nương và các lễ hội cầu mùa truyền thống.', 24000),
(31, 'HANHI', 'Hà Nhì', 'Cư trú chủ yếu ở Lai Châu. Nổi tiếng với nghề trồng lúa ruộng bậc thang và trang phục thổ cẩm đặc sắc.', 22000),
(32, 'CHURU', 'Chu-ru', 'Sinh sống tại Lâm Đồng. Có văn hóa cồng chiêng, lễ hội mừng lúa mới và nghề dệt thổ cẩm truyền thống.', 19000),
(33, 'LAO', 'Lào', 'Cư trú tại vùng biên giới Việt-Lào. Có nhiều nét văn hóa tương đồng với người Lào, giữ gìn phong tục tập quán riêng.', 15000),
(34, 'KHANG', 'Kháng', 'Sinh sống tại Sơn La và Điện Biên. Có nghề canh tác nương rẫy và văn hóa lễ hội đặc trưng.', 14000),
(35, 'LACHI', 'La Chí', 'Cư trú tại Hà Giang. Nổi tiếng với nghề dệt vải, thêu thùa và kiến trúc nhà sàn truyền thống.', 13000),
(36, 'PHULA', 'Phù Lá', 'Sinh sống tại vùng núi phía Bắc. Có nghề trồng lúa nương và văn hóa trang phục đặc sắc.', 11000),
(37, 'LAHU', 'La Hủ', 'Cư trú tại Lai Châu. Có nghề canh tác nương rẫy và các lễ hội cầu mùa truyền thống.', 9000),
(38, 'LAHA', 'La Ha', 'Sinh sống tại Sơn La. Có văn hóa canh tác nương rẫy và lễ hội đặc trưng.', 8000),
(39, 'PATHEN', 'Pà Thẻn', 'Cư trú tại Hà Giang, Tuyên Quang. Nổi tiếng với nghề dệt vải và trang phục truyền thống.', 7000),
(40, 'CHUT', 'Chứt', 'Sinh sống tại Quảng Bình. Có văn hóa du canh du cư và các nghi lễ tín ngưỡng đặc trưng.', 7000);
(41, 'LOHO', 'Lô Lô', 'Sinh sống chủ yếu ở Hà Giang, Cao Bằng. Nổi tiếng với nghề dệt vải thổ cẩm và lễ hội Gầu Tào đặc sắc.', 6000),
(42, 'MANG', 'Mảng', 'Cư trú tại Lai Châu. Có văn hóa canh tác nương rẫy và các lễ hội cầu mùa truyền thống.', 5500),
(43, 'COLAO', 'Cờ Lao', 'Sinh sống tại Hà Giang. Có nghề trồng lúa nước, dệt vải và kiến trúc nhà sàn đặc trưng.', 4000),
(44, 'BOY', 'Bố Y', 'Cư trú tại Lào Cai. Nổi tiếng với nghề thêu, dệt và các lễ hội truyền thống.', 3500),
(45, 'NGAI', 'Ngái', 'Sinh sống tại Cao Bằng và Lạng Sơn. Có nhiều nét văn hóa tương đồng với người Hoa, giữ gìn phong tục riêng.', 3200),
(46, 'CONONG', 'Cống', 'Cư trú tại Điện Biên. Có nghề canh tác nương rẫy và văn hóa trang phục đặc sắc.', 2800),
(47, 'BRAU', 'Brâu', 'Sinh sống tại Kon Tum. Có văn hóa cồng chiêng và lễ hội mừng lúa mới truyền thống.', 2700),
(48, 'OZU', 'Ơ Đu', 'Cư trú tại Nghệ An. Có nghề đan lát, săn bắt và các nghi lễ tín ngưỡng đặc trưng.', 2500),
(49, 'ROMAM', 'Rơ Măm', 'Sinh sống tại Kon Tum. Là một trong những dân tộc có dân số ít nhất Việt Nam, có văn hóa cồng chiêng độc đáo.', 600),
(50, 'PUPEO', 'Pu Péo', 'Cư trú tại Hà Giang. Có nghề dệt vải, thêu thùa và các lễ hội cầu mùa truyền thống.', 900),
(51, 'SILA', 'Si La', 'Sinh sống tại Điện Biên. Có văn hóa canh tác nương rẫy và trang phục truyền thống đặc sắc.', 800),
(52, 'LULUONG', 'Lu', 'Cư trú tại Lai Châu. Có nghề trồng lúa nương và các lễ hội đặc trưng.', 600),
(53, 'NGUON', 'Ngươn', 'Sinh sống tại Quảng Bình. Có văn hóa du canh và các nghi lễ tín ngưỡng riêng.', 500),
(54, 'MLAO', 'MLao', 'Cư trú tại các tỉnh Tây Nguyên. Có nghề canh tác nương rẫy và văn hóa cồng chiêng truyền thống.', 400);

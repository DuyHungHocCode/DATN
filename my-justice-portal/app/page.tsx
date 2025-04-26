// app/page.js
import Link from 'next/link';
import Image from 'next/image';

export default function Home() {
  // Get current date in Vietnamese format
  const today = new Date();
  const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
  const dayName = days[today.getDay()];
  const formattedDate = `${dayName}, ${today.getDate().toString().padStart(2, '0')}/${(today.getMonth() + 1).toString().padStart(2, '0')}/${today.getFullYear()}`;

  return (
    <main className="min-h-screen bg-white">
      {/* Top header with logo and date */}
      <div className="border-b">
        <div className="container mx-auto px-4 py-2 flex items-center justify-between">
          <div className="flex items-center">
            <div className="w-16 h-16 relative mr-2">
              <Image
                src="/logo.png"
                alt="Quốc huy Việt Nam"
                width={64}
                height={64}
                className="object-contain"
              />
            </div>
            <div>
              <p className="text-xs text-gray-700">CHÍNH PHỦ NƯỚC CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM</p>
              <h1 className="text-3xl font-bold text-red-600">botu.gov.vn</h1>
            </div>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-sm">{formattedDate}</span>
            <div className="flex space-x-2">
              <a href="#" className="text-sm text-blue-700 hover:underline">Tiếng Việt</a>
              <a href="#" className="text-sm text-blue-700 hover:underline">English</a>
              <a href="#" className="text-sm text-blue-700 hover:underline">中文</a>
            </div>
          </div>
        </div>
      </div>

      {/* Main navigation */}
      <nav className="bg-white border-b">
        <div className="container mx-auto px-4">
          <ul className="flex">
            <li className="flex items-center">
              <Link href="/" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50 flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mr-2">
                  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                </svg>
                TRANG CHỦ
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="#" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50">
                GIỚI THIỆU
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="#" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50">
                DỊCH VỤ CÔNG
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="khai-sinh" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50">
                KHAI SINH
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="ket-hon" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50">
                KẾT HÔN
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="khai-tu" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50">
                KHAI TỬ
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="ly-hon" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50">
                LY HÔN
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="ho-khau" className="px-4 py-3 text-blue-800 font-medium hover:bg-blue-50">
                HỘ KHẨU
              </Link>
            </li>
          </ul>
        </div>
      </nav>

      {/* Search bar */}
      <div className="bg-gray-100 py-4 border-b">
        <div className="container mx-auto px-4">
          <div className="flex max-w-xl mx-auto">
            <input
              type="text"
              placeholder="Nhập từ khóa..."
              className="flex-1 px-4 py-2 border border-gray-300 rounded-l focus:outline-none"
            />
            <button className="bg-blue-700 text-white px-4 py-2 rounded-r hover:bg-blue-800">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
              </svg>
            </button>
          </div>
        </div>
      </div>

      {/* Quick links */}
      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Dịch vụ hộ tịch */}
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <div className="bg-blue-700 text-white py-3 px-4">
              <h2 className="text-lg font-medium">DỊCH VỤ HỘ TỊCH</h2>
            </div>
            <div className="p-4">
              <ul className="space-y-2">
                <li>
                  <Link href="khai-sinh" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Đăng ký khai sinh
                  </Link>
                </li>
                <li>
                  <Link href="ket-hon" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Đăng ký kết hôn
                  </Link>
                </li>
                <li>
                  <Link href="khai-tu" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Đăng ký khai tử
                  </Link>
                </li>
                <li>
                  <Link href="ly-hon" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Đăng ký ly hôn
                  </Link>
                </li>
                <li>
                  <Link href="ho-khau" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Quản lý hộ khẩu
                  </Link>
                </li>
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Cấp giấy xác nhận tình trạng hôn nhân
                  </Link>
                </li>
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Đăng ký nhận cha, mẹ, con
                  </Link>
                </li>
              </ul>
            </div>
          </div>

          {/* Các dịch vụ khác */}
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <div className="bg-blue-700 text-white py-3 px-4">
              <h2 className="text-lg font-medium">DỊCH VỤ HÀNH CHÍNH</h2>
            </div>
            <div className="p-4">
              <ul className="space-y-2">
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Cấp phiếu lý lịch tư pháp
                  </Link>
                </li>
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Công chứng, chứng thực
                  </Link>
                </li>
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Cấp đổi giấy tờ
                  </Link>
                </li>
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Thủ tục hộ tịch khác
                  </Link>
                </li>
              </ul>
            </div>
          </div>

          {/* Hướng dẫn */}
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <div className="bg-blue-700 text-white py-3 px-4">
              <h2 className="text-lg font-medium">THÔNG TIN CHUNG</h2>
            </div>
            <div className="p-4">
              <ul className="space-y-2">
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Giới thiệu Bộ Tư pháp
                  </Link>
                </li>
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Văn bản pháp luật
                  </Link>
                </li>
                <li>
                  <Link href="#" className="flex items-center text-blue-600 hover:underline">
                    <span className="text-red-500 mr-2">›</span> Liên hệ hỗ trợ
                  </Link>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Contact info */}
      <footer className="bg-gray-100 border-t py-8 mt-8">
        <div className="container mx-auto px-4">
          <div className="text-center md:text-left">
            <h3 className="text-lg font-bold text-gray-800 mb-2">BỘ TƯ PHÁP VIỆT NAM</h3>
            <p className="text-gray-600">Địa chỉ: 58-60 Trần Phú, Ba Đình, Hà Nội</p>
            <p className="text-gray-600">Điện thoại: (024) 62739718 - Fax: (024) 38431431</p>
            <p className="text-gray-600">Email: btp@moj.gov.vn</p>
          </div>
          
          <div className="mt-4 text-center">
            <p className="text-sm text-gray-500">© {new Date().getFullYear()} Bộ Tư Pháp Việt Nam. Tất cả các quyền được bảo lưu.</p>
          </div>
        </div>
      </footer>
    </main>
  );
}
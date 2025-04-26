// app/page.js
import Link from 'next/link';
import Image from 'next/image';

export default function Home() {
  const services = [
    { 
      id: 'khai-sinh', 
      title: 'Đăng ký khai sinh', 
      description: 'Đăng ký khai sinh cho trẻ em mới sinh', 
      icon: '👶' 
    },
    { 
      id: 'khai-tu', 
      title: 'Đăng ký khai tử', 
      description: 'Đăng ký khai tử cho người đã mất', 
      icon: '📜' 
    },
    { 
      id: 'ket-hon', 
      title: 'Đăng ký kết hôn', 
      description: 'Đăng ký kết hôn cho các cặp đôi', 
      icon: '💍' 
    },
    { 
      id: 'ly-hon', 
      title: 'Đăng ký ly hôn', 
      description: 'Đăng ký ly hôn cho các cặp đôi', 
      icon: '⚖️' 
    },
  ];

  return (
    <main className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-md">
        <div className="container mx-auto px-4 py-6 flex items-center">
          <div className="flex items-center">
            <div className="w-16 h-16 relative mr-4">
              <Image
                src="/logo.png"
                alt="Logo Bộ Tư Pháp"
                width={64}
                height={64}
                className="object-contain"
              />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-red-600">CỔNG DỊCH VỤ CÔNG</h1>
              <h2 className="text-xl text-blue-800">BỘ TƯ PHÁP VIỆT NAM</h2>
            </div>
          </div>
          <nav className="ml-auto">
            <ul className="flex space-x-6">
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Trang chủ</a></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Dịch vụ</a></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Hướng dẫn</a></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Liên hệ</a></li>
            </ul>
          </nav>
        </div>
      </header>

      <section className="py-12 bg-gradient-to-r from-blue-800 to-blue-600 text-white">
        <div className="container mx-auto px-4">
          <h2 className="text-4xl font-bold mb-4">Dịch vụ công trực tuyến</h2>
          <p className="text-xl max-w-3xl">
            Hệ thống cung cấp các dịch vụ đăng ký hộ tịch trực tuyến, giúp người dân dễ dàng thực hiện thủ tục hành chính mà không cần đến trực tiếp cơ quan nhà nước.
          </p>
        </div>
      </section>

      <section className="container mx-auto px-4 py-12">
        <h2 className="text-3xl font-bold mb-8 text-center text-gray-800">Các dịch vụ hộ tịch</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {services.map((service) => (
            <Link 
              href={`/${service.id}`} 
              key={service.id}
              className="block bg-white rounded-lg shadow-lg p-6 hover:shadow-xl transition-shadow"
            >
              <div className="text-4xl mb-4">{service.icon}</div>
              <h3 className="text-xl font-bold text-blue-700 mb-2">{service.title}</h3>
              <p className="text-gray-600">{service.description}</p>
              <div className="mt-4 text-blue-600 font-medium">Bắt đầu →</div>
            </Link>
          ))}
        </div>
      </section>

      <section className="bg-gray-100 py-12">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold mb-8 text-center text-gray-800">Hướng dẫn sử dụng</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="bg-white p-6 rounded-lg shadow">
              <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-xl mb-4">1</div>
              <h3 className="text-xl font-bold mb-2">Đăng nhập tài khoản</h3>
              <p className="text-gray-600">Sử dụng tài khoản VNeID hoặc tài khoản dịch vụ công để đăng nhập vào hệ thống.</p>
            </div>
            
            <div className="bg-white p-6 rounded-lg shadow">
              <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-xl mb-4">2</div>
              <h3 className="text-xl font-bold mb-2">Chọn dịch vụ</h3>
              <p className="text-gray-600">Lựa chọn dịch vụ hộ tịch phù hợp với nhu cầu của bạn.</p>
            </div>
            
            <div className="bg-white p-6 rounded-lg shadow">
              <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-xl mb-4">3</div>
              <h3 className="text-xl font-bold mb-2">Điền thông tin và gửi hồ sơ</h3>
              <p className="text-gray-600">Hoàn thành biểu mẫu trực tuyến và gửi hồ sơ để chờ xét duyệt.</p>
            </div>
          </div>
        </div>
      </section>

      <footer className="bg-blue-900 text-white py-6">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <h3 className="text-xl font-bold mb-4">Bộ Tư Pháp Việt Nam</h3>
              <p>Địa chỉ: 58-60 Trần Phú, Ba Đình, Hà Nội</p>
              <p>Điện thoại: (024) 62739718</p>
              <p>Email: btp@moj.gov.vn</p>
            </div>
            
            <div>
              <h3 className="text-xl font-bold mb-4">Liên kết hữu ích</h3>
              <ul className="space-y-2">
                <li><a href="#" className="hover:text-blue-300">Cổng thông tin điện tử Chính phủ</a></li>
                <li><a href="#" className="hover:text-blue-300">Dịch vụ công quốc gia</a></li>
                <li><a href="#" className="hover:text-blue-300">VNeID</a></li>
              </ul>
            </div>
            
            <div>
              <h3 className="text-xl font-bold mb-4">Hỗ trợ</h3>
              <ul className="space-y-2">
                <li><a href="#" className="hover:text-blue-300">Hướng dẫn sử dụng</a></li>
                <li><a href="#" className="hover:text-blue-300">Câu hỏi thường gặp</a></li>
                <li><a href="#" className="hover:text-blue-300">Liên hệ hỗ trợ kỹ thuật</a></li>
              </ul>
            </div>
          </div>
          
          <div className="mt-8 pt-6 border-t border-blue-800 text-center">
            <p>© {new Date().getFullYear()} Bộ Tư Pháp Việt Nam. Tất cả các quyền được bảo lưu.</p>
          </div>
        </div>
      </footer>
    </main>
  );
}
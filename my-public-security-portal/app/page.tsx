'use client';

import React from 'react';
import Link from 'next/link';

export default function OfficerHomepage() {
  // Get current date in Vietnamese format
  const today = new Date();
  const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
  const dayName = days[today.getDay()];
  const formattedDate = `${dayName}, ${today.getDate().toString().padStart(2, '0')}/${(today.getMonth() + 1).toString().padStart(2, '0')}/${today.getFullYear()}`;

  return (
    <main className="min-h-screen bg-gray-100">
      {/* Top header */}
      <div className="border-b bg-white">
        <div className="container mx-auto px-4 py-2 flex items-center justify-between">
          <div className="flex items-center">
             <div className="w-16 h-16 relative mr-2">
              <img src="/logo-bocongan.png" alt="Logo Bộ Công An" width={64} height={64} className="object-contain" />
            </div>
            <div>
              <p className="text-xs text-gray-700 uppercase">Bộ Công An</p>
              <h1 className="text-2xl font-bold text-blue-800">HỆ THỐNG QUẢN LÝ THÔNG TIN</h1>
            </div>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-sm text-gray-600">{formattedDate}</span>
          </div>
        </div>
      </div>

      {/* Main navigation - Dành cho cán bộ */}
      <nav className="bg-blue-900 text-white shadow-md">
        <div className="container mx-auto px-4">
          <ul className="flex flex-wrap">
            <li className="flex items-center">
              <Link href="/" className="px-4 py-3 text-white font-medium hover:bg-blue-800 flex items-center bg-blue-800">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mr-2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
                BẢNG ĐIỀU KHIỂN
              </Link>
            </li>
            <li className="flex items-center">
              {/* ----- ĐÃ SỬA ĐƯỜNG DẪN Ở ĐÂY ----- */}
              <Link href="/cong-dan/tra-cuu" className="px-4 py-3 text-white font-medium hover:bg-blue-800 flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mr-2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                TRA CỨU CÔNG DÂN
              </Link>
            </li>
            <li className="flex items-center">
              <Link href="/cong-dan/cap-nhat" className="px-4 py-3 text-white font-medium hover:bg-blue-800 flex items-center">
               <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mr-2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                CẬP NHẬT THÔNG TIN
              </Link>
            </li>
             <li className="flex items-center">
              <Link href="#" className="px-4 py-3 text-white font-medium hover:bg-blue-800 flex items-center">
                 <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mr-2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                 QUẢN LÝ HỒ SƠ
              </Link>
            </li>
             <li className="flex items-center">
              <Link href="#" className="px-4 py-3 text-white font-medium hover:bg-blue-800 flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mr-2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg>
                BÁO CÁO
              </Link>
            </li>
          </ul>
        </div>
      </nav>

      {/* Main content area - Chỉ còn Quick Actions */}
      <div className="container mx-auto px-4 py-8">
        <h2 className="text-xl font-semibold text-gray-700 mb-6">Chức năng chính</h2>

        {/* Quick Actions Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
             {/* Card: Tra cứu công dân */}
             {/* ----- ĐÃ SỬA ĐƯỜNG DẪN Ở ĐÂY ----- */}
             <Link href="/cong-dan/tra-cuu" className="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200 text-center">
                 <div className="flex justify-center mb-3">
                     <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-blue-600"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                 </div>
                <h3 className="text-lg font-semibold text-gray-800 mb-1">Tra cứu Công dân</h3>
                <p className="text-sm text-gray-500">Tìm kiếm thông tin chi tiết công dân theo CCCD hoặc Họ tên.</p>
             </Link>

             {/* Card: Cập nhật thông tin */}
             <Link href="/cong-dan/cap-nhat" className="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200 text-center">
                 <div className="flex justify-center mb-3">
                    <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-green-600"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                 </div>
                <h3 className="text-lg font-semibold text-gray-800 mb-1">Cập nhật Thông tin</h3>
                <p className="text-sm text-gray-500">Chỉnh sửa thông tin cơ bản của công dân đã có hồ sơ.</p>
             </Link>

            {/* Card: Quản lý CCCD */}
             <Link href="/quan-ly-cccd" /* Thay bằng đường dẫn thực tế */ className="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200 text-center">
                 <div className="flex justify-center mb-3">
                     <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-purple-600"><rect x="3" y="4" width="18" height="16" rx="2"></rect><line x1="8" y1="2" x2="8" y2="4"></line><line x1="16" y1="2" x2="16" y2="4"></line><circle cx="12" cy="10" r="3"></circle><path d="M7 16h.01M12 16h.01M17 16h.01"></path></svg>
                 </div>
                <h3 className="text-lg font-semibold text-gray-800 mb-1">Quản lý CCCD</h3>
                <p className="text-sm text-gray-500">Xử lý cấp mới, cấp đổi, cấp lại thẻ CCCD.</p>
             </Link>

             {/* Card: Quản lý Tiền án, Tiền sự */}
             <Link href="/quan-ly-tien-an" /* Thay bằng đường dẫn thực tế */ className="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200 text-center">
                 <div className="flex justify-center mb-3">
                    <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-red-600"><path d="M22 12h-4l-3 9L9 3l-3 9H2"></path></svg>
                 </div>
                <h3 className="text-lg font-semibold text-gray-800 mb-1">QL Tiền án, Tiền sự</h3>
                <p className="text-sm text-gray-500">Tra cứu, cập nhật hồ sơ tiền án, tiền sự.</p>
             </Link>
        </div>
      </div>

      {/* Footer */}
       <footer className="bg-gray-800 text-gray-300 py-6 mt-12 fixed bottom-0 left-0 w-full">
         <div className="container mx-auto px-4 text-center text-sm">
            <p>© {new Date().getFullYear()} Hệ thống quản lý thông tin - Bộ Công An.</p>
          </div>
      </footer>
    </main>
  );
}
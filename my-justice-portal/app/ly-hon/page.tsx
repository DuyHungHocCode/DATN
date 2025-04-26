'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function LyHonPage() {
  const [formData, setFormData] = useState({
    // Certificate information
    divorce_certificate_no: '',
    book_id: '',
    page_no: '',
    
    // Marriage information
    marriage_id: '',
    husbandName: '',
    husbandId: '',
    husbandAddress: '',
    husbandPhone: '',
    wifeName: '',
    wifeId: '',
    wifeAddress: '',
    wifePhone: '',
    marriageDate: '',
    marriagePlace: '',
    
    // Divorce information
    divorce_date: '',
    registration_date: '',
    court_name: '',
    judgment_no: '',
    judgment_date: '',
    reason: '',
    
    // Child custody and property
    hasChildren: false,
    childCount: '',
    child_custody: '',
    property_division: '',
    
    // Location information
    region_id: '',
    province_id: '',
    geographical_region: '',
    issuing_authority_id: '',
    
    // Additional information
    notes: '',
  });

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    // Here you would typically send the data to an API
    console.log('Form submitted:', formData);
    alert('Đã gửi đơn đăng ký ly hôn thành công!');
  };

  // Mock data for dropdowns
  const regions = [
    { id: 1, name: 'Miền Bắc' },
    { id: 2, name: 'Miền Trung' },
    { id: 3, name: 'Miền Nam' },
  ];

  const provinces = [
    { id: 1, name: 'Hà Nội', region_id: 1 },
    { id: 2, name: 'TP. Hồ Chí Minh', region_id: 3 },
    { id: 3, name: 'Đà Nẵng', region_id: 2 },
    // Add more provinces as needed
  ];

  const courts = [
    { id: 1, name: 'Tòa án nhân dân TP Hà Nội' },
    { id: 2, name: 'Tòa án nhân dân TP Hồ Chí Minh' },
    { id: 3, name: 'Tòa án nhân dân TP Đà Nẵng' },
    { id: 4, name: 'Tòa án nhân dân tỉnh Hải Phòng' },
    // Add more courts as needed
  ];

  const authorities = [
    { id: 1, name: 'UBND Phường Liễu Giai' },
    { id: 2, name: 'UBND Phường Cống Vị' },
    { id: 3, name: 'UBND Phường Phúc Tân' },
    // Add more authorities as needed
  ];

  // Filter provinces based on selected region
  const filteredProvinces = formData.region_id 
    ? provinces.filter(province => province.region_id === parseInt(formData.region_id))
    : [];

  return (
    <div className="min-h-screen bg-gray-50">
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
              <li><Link href="/" className="text-gray-700 hover:text-blue-600">Trang chủ</Link></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Dịch vụ</a></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Hướng dẫn</a></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Liên hệ</a></li>
            </ul>
          </nav>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="flex items-center mb-6">
          <Link href="/" className="text-blue-600 hover:text-blue-800">
            ← Trang chủ
          </Link>
          <span className="mx-2 text-gray-500">/</span>
          <span className="text-gray-700">Đăng ký ly hôn</span>
        </div>

        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          <div className="bg-purple-700 text-white p-6 text-center">
            <h1 className="text-3xl font-bold">ĐĂNG KÝ LY HÔN</h1>
            <p className="text-lg">(Đăng ký trực tuyến)</p>
          </div>

          <div className="p-6 bg-purple-50 border-b border-purple-100">
            <h2 className="text-xl font-semibold text-gray-800">Thông tin quan trọng:</h2>
            <ul className="mt-2 list-disc list-inside text-gray-700 space-y-1">
              <li>Đơn đăng ký ly hôn chỉ được xử lý sau khi đã có bản án/quyết định ly hôn có hiệu lực của Tòa án.</li>
              <li>Việc đăng ký ly hôn phải được thực hiện trong vòng 30 ngày kể từ ngày bản án/quyết định ly hôn có hiệu lực pháp luật.</li>
              <li>Cả hai bên cần cung cấp thông tin chính xác về bản án/quyết định và các thông tin liên quan đến hôn nhân cũ.</li>
              <li>Cần đính kèm bản sao công chứng của bản án/quyết định ly hôn có hiệu lực pháp luật.</li>
            </ul>
          </div>

          <form onSubmit={handleSubmit} className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Judgment Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-purple-700 mb-4 border-b pb-2">Thông tin bản án/quyết định ly hôn</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Tên tòa án ra quyết định: <span className="text-red-500">*</span>
                </label>
                <select
                  name="court_name"
                  value={formData.court_name}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                >
                  <option value="">Chọn tòa án</option>
                  {courts.map(court => (
                    <option key={court.id} value={court.name}>
                      {court.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số bản án/quyết định: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="judgment_no"
                  value={formData.judgment_no}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Ví dụ: 123/2025/QĐST-HNGĐ"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày bản án/quyết định: <span className="text-red-500">*</span>
                </label>
                <input
                  type="date"
                  name="judgment_date"
                  value={formData.judgment_date}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày ly hôn có hiệu lực: <span className="text-red-500">*</span>
                </label>
                <input
                  type="date"
                  name="divorce_date"
                  value={formData.divorce_date}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                />
              </div>

              {/* Marriage Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-purple-700 mt-6 mb-4 border-b pb-2">Thông tin hôn nhân cũ</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số đăng ký kết hôn: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="marriage_id"
                  value={formData.marriage_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày đăng ký kết hôn:
                </label>
                <input
                  type="date"
                  name="marriageDate"
                  value={formData.marriageDate}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi đăng ký kết hôn:
                </label>
                <input
                  type="text"
                  name="marriagePlace"
                  value={formData.marriagePlace}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  placeholder="Ví dụ: UBND Phường Liễu Giai, Quận Ba Đình, Hà Nội"
                />
              </div>

              {/* Husband Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-blue-700 mt-6 mb-4 border-b pb-2">Thông tin chồng</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ và tên: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="husbandName"
                  value={formData.husbandName}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số CCCD/CMND: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="husbandId"
                  value={formData.husbandId}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Địa chỉ hiện tại:
                </label>
                <input
                  type="text"
                  name="husbandAddress"
                  value={formData.husbandAddress}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số điện thoại:
                </label>
                <input
                  type="tel"
                  name="husbandPhone"
                  value={formData.husbandPhone}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Wife Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-pink-700 mt-6 mb-4 border-b pb-2">Thông tin vợ</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ và tên: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="wifeName"
                  value={formData.wifeName}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số CCCD/CMND: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="wifeId"
                  value={formData.wifeId}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Địa chỉ hiện tại:
                </label>
                <input
                  type="text"
                  name="wifeAddress"
                  value={formData.wifeAddress}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số điện thoại:
                </label>
                <input
                  type="tel"
                  name="wifePhone"
                  value={formData.wifePhone}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                />
              </div>

              {/* Child Custody Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-purple-700 mt-6 mb-4 border-b pb-2">Thông tin quyền nuôi con và phân chia tài sản</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2 flex items-center">
                  <input
                    type="checkbox"
                    name="hasChildren"
                    checked={formData.hasChildren}
                    onChange={handleChange}
                    className="h-5 w-5 text-purple-600 mr-2"
                  />
                  Có con chung cần phân chia quyền nuôi dưỡng
                </label>
              </div>

              {formData.hasChildren && (
                <div className="form-group">
                  <label className="block text-gray-700 font-medium mb-2">
                    Số lượng con chung:
                  </label>
                  <input
                    type="number"
                    name="childCount"
                    value={formData.childCount}
                    onChange={handleChange}
                    min="1"
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  />
                </div>
              )}

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Thông tin quyền nuôi con:
                </label>
                <textarea
                  name="child_custody"
                  value={formData.child_custody}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  rows="3"
                  placeholder="Mô tả chi tiết việc phân chia quyền nuôi con theo quyết định của tòa án"
                ></textarea>
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Thông tin phân chia tài sản:
                </label>
                <textarea
                  name="property_division"
                  value={formData.property_division}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  rows="3"
                  placeholder="Mô tả chi tiết việc phân chia tài sản theo quyết định của tòa án"
                ></textarea>
              </div>

              {/* Registration Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-purple-700 mt-6 mb-4 border-b pb-2">Thông tin đăng ký</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số đăng ký ly hôn: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="divorce_certificate_no"
                  value={formData.divorce_certificate_no}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số sổ:
                </label>
                <input
                  type="text"
                  name="book_id"
                  value={formData.book_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số trang:
                </label>
                <input
                  type="text"
                  name="page_no"
                  value={formData.page_no}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày đăng ký: <span className="text-red-500">*</span>
                </label>
                <input
                  type="date"
                  name="registration_date"
                  value={formData.registration_date}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Cơ quan đăng ký: <span className="text-red-500">*</span>
                </label>
                <select
                  name="issuing_authority_id"
                  value={formData.issuing_authority_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                >
                  <option value="">Chọn cơ quan đăng ký</option>
                  {authorities.map(authority => (
                    <option key={authority.id} value={authority.id}>
                      {authority.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Geographical Information */}
              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Khu vực: <span className="text-red-500">*</span>
                </label>
                <select
                  name="region_id"
                  value={formData.region_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                >
                  <option value="">Chọn khu vực</option>
                  {regions.map(region => (
                    <option key={region.id} value={region.id}>
                      {region.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Tỉnh/Thành phố: <span className="text-red-500">*</span>
                </label>
                <select
                  name="province_id"
                  value={formData.province_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                  disabled={!formData.region_id}
                >
                  <option value="">Chọn tỉnh/thành</option>
                  {filteredProvinces.map(province => (
                    <option key={province.id} value={province.id}>
                      {province.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Vùng địa lý: <span className="text-red-500">*</span>
                </label>
                <select
                  name="geographical_region"
                  value={formData.geographical_region}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  required
                >
                  <option value="">Chọn vùng địa lý</option>
                  <option value="Đồng bằng">Đồng bằng</option>
                  <option value="Trung du miền núi">Trung du miền núi</option>
                  <option value="Thành thị">Thành thị</option>
                  <option value="Nông thôn">Nông thôn</option>
                  <option value="Hải đảo">Hải đảo</option>
                </select>
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Lý do ly hôn:
                </label>
                <textarea
                  name="reason"
                  value={formData.reason}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  rows="3"
                  placeholder="Nguyên nhân dẫn đến ly hôn (theo quyết định của tòa án)"
                ></textarea>
              </div>

              {/* Additional Notes */}
              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Ghi chú:
                </label>
                <textarea
                  name="notes"
                  value={formData.notes}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                  rows="3"
                  placeholder="Thông tin bổ sung (nếu có)"
                ></textarea>
              </div>
            </div>

            {/* Attachments Section */}
            <div className="mt-8">
              <h2 className="text-xl font-bold text-purple-700 mb-4 border-b pb-2">Tài liệu đính kèm</h2>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Bản sao công chứng quyết định/bản án ly hôn có hiệu lực pháp luật (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy chứng nhận kết hôn cũ (nếu có):
                </label>
                <input
                  type="file"
                  className="w-full"
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy CMND/CCCD của cả hai bên (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  multiple
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Tài liệu khác có liên quan (nếu có):
                </label>
                <input
                  type="file"
                  className="w-full"
                  multiple
                />
              </div>
            </div>

            {/* Consent Section */}
            <div className="mt-6">
              <div className="flex items-start">
                <input
                  id="consent"
                  type="checkbox"
                  className="h-5 w-5 text-purple-600 mt-1"
                  required
                />
                <label htmlFor="consent" className="ml-2 text-gray-700">
                  Tôi/Chúng tôi xin cam đoan những nội dung khai trên đây là đúng sự thật và chịu trách nhiệm trước pháp luật về
                  cam đoan của mình.
                </label>
              </div>
            </div>

            {/* Submit Button */}
            <div className="mt-8 text-center">
              <button
                type="submit"
                className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 px-8 rounded-md shadow-md transition-colors"
              >
                Gửi đơn đăng ký ly hôn
              </button>
            </div>
          </form>

          <div className="bg-gray-100 p-6">
            <h3 className="text-lg font-bold text-gray-700 mb-2">Quy trình đăng ký ly hôn:</h3>
            <ol className="list-decimal pl-5 text-gray-600 space-y-1">
              <li>Nộp hồ sơ trực tuyến và nhận mã hồ sơ.</li>
              <li>Chờ cán bộ tư pháp xác minh thông tin (2-3 ngày làm việc).</li>
              <li>Nhận thông báo đến trực tiếp để hoàn tất thủ tục.</li>
              <li>Nhận trích lục đăng ký ly hôn.</li>
            </ol>
            
            <h3 className="text-lg font-bold text-gray-700 mt-4 mb-2">Lưu ý quan trọng:</h3>
            <ul className="list-disc pl-5 text-gray-600 space-y-1">
              <li>Việc đăng ký ly hôn khác với thủ tục xin ly hôn tại tòa án. Đây là thủ tục đăng ký, ghi nhận sự kiện ly hôn đã được tòa án phán quyết.</li>
              <li>Sau khi đăng ký ly hôn, hai bên sẽ được cấp trích lục đăng ký ly hôn.</li>
              <li>Mọi thắc mắc xin liên hệ hotline: 1900xxxx hoặc email: hotro@moj.gov.vn</li>
            </ul>
          </div>
        </div>
      </div>

      <footer className="bg-blue-900 text-white py-6 mt-12">
        <div className="container mx-auto px-4">
          <div className="text-center">
            <p>© {new Date().getFullYear()} Bộ Tư Pháp Việt Nam. Tất cả các quyền được bảo lưu.</p>
            <p className="mt-2">Cổng Dịch vụ công Bộ Tư pháp - Địa chỉ: 58-60 Trần Phú, Ba Đình, Hà Nội</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
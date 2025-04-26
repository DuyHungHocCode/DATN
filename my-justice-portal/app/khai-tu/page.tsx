'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function KhaiTuPage() {
  const [formData, setFormData] = useState({
    // Deceased person information
    citizen_id: '',
    fullName: '',
    dateOfBirth: '',
    gender: '',
    ethnicity: '',
    nationality: '',
    lastResidence: '',
    
    // Death information
    death_certificate_no: '',
    book_id: '',
    page_no: '',
    date_of_death: '',
    time_of_death: '',
    place_of_death: '',
    cause_of_death: '',
    
    // Declarant information
    declarant_name: '',
    declarant_citizen_id: '',
    declarant_relationship: '',
    declarant_address: '',
    declarant_phone: '',
    
    // Witness information
    witness1_name: '',
    witness1_citizen_id: '',
    witness2_name: '',
    witness2_citizen_id: '',
    
    // Registration details
    registration_date: '',
    issuing_authority_id: '',
    death_notification_no: '',
    
    // Location information
    region_id: '',
    province_id: '',
    district_id: '',
    geographical_region: '',
    
    // Additional information
    notes: '',
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    // Here you would typically send the data to an API
    console.log('Form submitted:', formData);
    alert('Đã gửi đơn đăng ký khai tử thành công!');
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

  const districts = [
    { id: 1, name: 'Ba Đình', province_id: 1 },
    { id: 2, name: 'Hoàn Kiếm', province_id: 1 },
    { id: 3, name: 'Quận 1', province_id: 2 },
    { id: 4, name: 'Quận 2', province_id: 2 },
    { id: 5, name: 'Hải Châu', province_id: 3 },
    // Add more districts as needed
  ];

  const authorities = [
    { id: 1, name: 'UBND Phường Liễu Giai' },
    { id: 2, name: 'UBND Phường Cống Vị' },
    { id: 3, name: 'UBND Phường Phúc Tân' },
    // Add more authorities as needed
  ];

  const relationshipTypes = [
    { value: 'spouse', label: 'Vợ/Chồng' },
    { value: 'child', label: 'Con' },
    { value: 'parent', label: 'Cha/Mẹ' },
    { value: 'sibling', label: 'Anh/Chị/Em' },
    { value: 'relative', label: 'Người thân khác' },
    { value: 'other', label: 'Khác' },
  ];

  // Filter districts based on selected province
  const filteredDistricts = formData.province_id 
    ? districts.filter(district => district.province_id === parseInt(formData.province_id))
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
          <span className="text-gray-700">Đăng ký khai tử</span>
        </div>

        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          <div className="bg-gray-800 text-white p-6 text-center">
            <h1 className="text-3xl font-bold">GIẤY KHAI TỬ</h1>
            <p className="text-lg">(Đăng ký trực tuyến)</p>
          </div>

          <div className="p-6 bg-gray-100 border-b border-gray-200">
            <h2 className="text-xl font-semibold text-gray-800">Lưu ý quan trọng:</h2>
            <ul className="mt-2 list-disc list-inside text-gray-700 space-y-1">
              <li>Việc khai tử phải được thực hiện trong vòng 15 ngày kể từ ngày chết.</li>
              <li>Người có trách nhiệm khai tử là thân nhân của người chết hoặc người đại diện của cơ quan, tổ chức nơi người đó công tác.</li>
              <li>Cần cung cấp đầy đủ các giấy tờ liên quan như Giấy báo tử hoặc giấy tờ thay thế Giấy báo tử.</li>
            </ul>
          </div>

          <form onSubmit={handleSubmit} className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Deceased Person Information Section */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mb-4 border-b pb-2">Thông tin người đã mất</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số CCCD/CMND: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="citizen_id"
                  value={formData.citizen_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ và tên: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày sinh:
                </label>
                <input
                  type="date"
                  name="dateOfBirth"
                  value={formData.dateOfBirth}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Giới tính:
                </label>
                <select
                  name="gender"
                  value={formData.gender}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Chọn giới tính</option>
                  <option value="Nam">Nam</option>
                  <option value="Nữ">Nữ</option>
                </select>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Dân tộc:
                </label>
                <input
                  type="text"
                  name="ethnicity"
                  value={formData.ethnicity}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Quốc tịch:
                </label>
                <input
                  type="text"
                  name="nationality"
                  value={formData.nationality}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi cư trú cuối cùng:
                </label>
                <input
                  type="text"
                  name="lastResidence"
                  value={formData.lastResidence}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Địa chỉ nơi cư trú cuối cùng của người đã mất"
                />
              </div>

              {/* Death Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin về việc chết</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số giấy khai tử: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="death_certificate_no"
                  value={formData.death_certificate_no}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số giấy báo tử/thông báo:
                </label>
                <input
                  type="text"
                  name="death_notification_no"
                  value={formData.death_notification_no}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày chết: <span className="text-red-500">*</span>
                </label>
                <input
                  type="date"
                  name="date_of_death"
                  value={formData.date_of_death}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Giờ chết:
                </label>
                <input
                  type="time"
                  name="time_of_death"
                  value={formData.time_of_death}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi chết: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="place_of_death"
                  value={formData.place_of_death}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Địa chỉ nơi xảy ra sự việc"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nguyên nhân chết:
                </label>
                <textarea
                  name="cause_of_death"
                  value={formData.cause_of_death}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows="2"
                  placeholder="Nguyên nhân dẫn đến cái chết (nếu biết)"
                ></textarea>
              </div>

              {/* Declarant Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin người đi khai tử</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ và tên người khai: <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="declarant_name"
                  value={formData.declarant_name}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số CCCD/CMND:
                </label>
                <input
                  type="text"
                  name="declarant_citizen_id"
                  value={formData.declarant_citizen_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Quan hệ với người đã mất:
                </label>
                <select
                  name="declarant_relationship"
                  value={formData.declarant_relationship}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="">Chọn quan hệ</option>
                  {relationshipTypes.map(type => (
                    <option key={type.value} value={type.value}>
                      {type.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số điện thoại liên hệ:
                </label>
                <input
                  type="tel"
                  name="declarant_phone"
                  value={formData.declarant_phone}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Địa chỉ liên hệ:
                </label>
                <input
                  type="text"
                  name="declarant_address"
                  value={formData.declarant_address}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Địa chỉ liên hệ của người khai tử"
                />
              </div>

              {/* Witness Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin người làm chứng (nếu có)</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ tên người làm chứng 1:
                </label>
                <input
                  type="text"
                  name="witness1_name"
                  value={formData.witness1_name}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số CCCD/CMND:
                </label>
                <input
                  type="text"
                  name="witness1_citizen_id"
                  value={formData.witness1_citizen_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ tên người làm chứng 2:
                </label>
                <input
                  type="text"
                  name="witness2_name"
                  value={formData.witness2_name}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Số CCCD/CMND:
                </label>
                <input
                  type="text"
                  name="witness2_citizen_id"
                  value={formData.witness2_citizen_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Registration Information */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin đăng ký</h2>
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Chọn tỉnh/thành</option>
                  {provinces.map(province => (
                    <option key={province.id} value={province.id}>
                      {province.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Quận/Huyện: <span className="text-red-500">*</span>
                </label>
                <select
                  name="district_id"
                  value={formData.district_id}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                  disabled={!formData.province_id}
                >
                  <option value="">Chọn quận/huyện</option>
                  {filteredDistricts.map(district => (
                    <option key={district.id} value={district.id}>
                      {district.name}
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
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

              {/* Additional Notes */}
              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Ghi chú:
                </label>
                <textarea
                  name="notes"
                  value={formData.notes}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows="3"
                  placeholder="Thông tin bổ sung (nếu có)"
                ></textarea>
              </div>
            </div>

            {/* Attachments Section */}
            <div className="mt-8">
              <h2 className="text-xl font-bold text-gray-700 mb-4 border-b pb-2">Tài liệu đính kèm</h2>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy báo tử hoặc giấy tờ thay thế (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy CMND/CCCD của người đã mất (nếu có):
                </label>
                <input
                  type="file"
                  className="w-full"
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy CMND/CCCD của người đi khai tử (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy tờ chứng minh quan hệ với người đã mất (nếu có):
                </label>
                <input
                  type="file"
                  className="w-full"
                />
              </div>
            </div>

            {/* Consent Section */}
            <div className="mt-6">
              <div className="flex items-start">
                <input
                  id="consent"
                  type="checkbox"
                  className="h-5 w-5 text-blue-600 mt-1"
                  required
                />
                <label htmlFor="consent" className="ml-2 text-gray-700">
                  Tôi xin cam đoan những nội dung khai trên đây là đúng sự thật và chịu trách nhiệm trước pháp luật về
                  cam đoan của mình.
                </label>
              </div>
            </div>

            {/* Submit Button */}
            <div className="mt-8 text-center">
              <button
                type="submit"
                className="bg-gray-800 hover:bg-gray-900 text-white font-bold py-3 px-8 rounded-md shadow-md transition-colors"
              >
                Gửi đơn đăng ký khai tử
              </button>
            </div>
          </form>

          <div className="bg-gray-100 p-6">
            <h3 className="text-lg font-bold text-gray-700 mb-2">Quy trình đăng ký khai tử:</h3>
            <ol className="list-decimal pl-5 text-gray-600 space-y-1">
              <li>Nộp hồ sơ trực tuyến và nhận mã hồ sơ.</li>
              <li>Chờ cán bộ tư pháp xác minh thông tin (2-3 ngày làm việc).</li>
              <li>Nhận thông báo đến trực tiếp để nộp bản cứng các giấy tờ liên quan và nhận kết quả.</li>
              <li>Người đi khai tử cần mang theo giấy tờ tùy thân để đối chiếu.</li>
            </ol>
            
            <h3 className="text-lg font-bold text-gray-700 mt-4 mb-2">Lưu ý quan trọng:</h3>
            <ul className="list-disc pl-5 text-gray-600 space-y-1">
              <li>Sau khi đăng ký khai tử, bạn sẽ được cấp trích lục khai tử và giấy chứng tử.</li>
              <li>Các giấy tờ được cấp có thể được sử dụng để giải quyết các thủ tục liên quan khác như hưởng chế độ bảo hiểm, thừa kế, v.v.</li>
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
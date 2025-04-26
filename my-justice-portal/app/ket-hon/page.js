'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function KetHonPage() {
  const [formData, setFormData] = useState({
    // Husband's information
    husbandName: '',
    husbandDateOfBirth: '',
    husbandEthnicity: '',
    husbandNationality: '',
    husbandResidence: '',
    husbandIdType: '',
    husbandIdNumber: '',
    
    // Wife's information
    wifeName: '',
    wifeDateOfBirth: '',
    wifeEthnicity: '',
    wifeNationality: '',
    wifeResidence: '',
    wifeIdType: '',
    wifeIdNumber: '',
    
    // Registration details
    registrationPlace: '',
    registrationDate: '',
    
    // Additional information for validation
    husbandMaritalStatus: '',
    wifeMaritalStatus: '',
    relationship: '',
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
    alert('Đã gửi đơn đăng ký kết hôn thành công!');
  };

  // List of ID document types
  const idTypes = [
    { value: 'cccd', label: 'Căn cước công dân' },
    { value: 'cmnd', label: 'Chứng minh nhân dân' },
    { value: 'passport', label: 'Hộ chiếu' },
  ];

  // List of marital statuses
  const maritalStatuses = [
    { value: 'single', label: 'Độc thân' },
    { value: 'divorced', label: 'Đã ly hôn' },
    { value: 'widowed', label: 'Góa' },
  ];

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
          <span className="text-gray-700">Đăng ký kết hôn</span>
        </div>

        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          <div className="bg-red-600 text-white p-6 text-center">
            <h1 className="text-3xl font-bold">ĐĂNG KÝ KẾT HÔN</h1>
            <p className="text-lg">(Đăng ký trực tuyến)</p>
          </div>

          <div className="p-6 bg-pink-50 border-b border-pink-100">
            <h2 className="text-xl font-semibold text-gray-800">Điều kiện đăng ký kết hôn:</h2>
            <ul className="mt-2 list-disc list-inside text-gray-700 space-y-1">
              <li>Nam từ đủ 20 tuổi trở lên, nữ từ đủ 18 tuổi trở lên</li>
              <li>Việc kết hôn do nam và nữ tự nguyện quyết định</li>
              <li>Không bị mất năng lực hành vi dân sự</li>
              <li>Không đang có vợ hoặc có chồng</li>
              <li>Không thuộc các trường hợp cấm kết hôn theo quy định của Luật Hôn nhân và Gia đình</li>
            </ul>
          </div>

          <form onSubmit={handleSubmit} className="p-6">
            {/* Section: Information about the couple */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {/* Husband's Information */}
              <div className="bg-blue-50 p-6 rounded-lg">
                <h2 className="text-xl font-bold text-blue-800 mb-4 border-b pb-2">Thông tin bên chồng</h2>
                
                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Họ, chữ đệm, tên:
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

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Ngày, tháng, năm sinh:
                  </label>
                  <input
                    type="date"
                    name="husbandDateOfBirth"
                    value={formData.husbandDateOfBirth}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Dân tộc:
                  </label>
                  <input
                    type="text"
                    name="husbandEthnicity"
                    value={formData.husbandEthnicity}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Quốc tịch:
                  </label>
                  <input
                    type="text"
                    name="husbandNationality"
                    value={formData.husbandNationality}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Nơi cư trú:
                  </label>
                  <textarea
                    name="husbandResidence"
                    value={formData.husbandResidence}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    rows="3"
                    required
                  ></textarea>
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Loại giấy tờ tùy thân:
                  </label>
                  <select
                    name="husbandIdType"
                    value={formData.husbandIdType}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  >
                    <option value="">Chọn loại giấy tờ</option>
                    {idTypes.map(type => (
                      <option key={`husband-${type.value}`} value={type.value}>
                        {type.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Số giấy tờ tùy thân:
                  </label>
                  <input
                    type="text"
                    name="husbandIdNumber"
                    value={formData.husbandIdNumber}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Tình trạng hôn nhân hiện tại:
                  </label>
                  <select
                    name="husbandMaritalStatus"
                    value={formData.husbandMaritalStatus}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  >
                    <option value="">Chọn tình trạng</option>
                    {maritalStatuses.map(status => (
                      <option key={`husband-${status.value}`} value={status.value}>
                        {status.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              
              {/* Wife's Information */}
              <div className="bg-pink-50 p-6 rounded-lg">
                <h2 className="text-xl font-bold text-pink-700 mb-4 border-b pb-2">Thông tin bên vợ</h2>
                
                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Họ, chữ đệm, tên:
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

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Ngày, tháng, năm sinh:
                  </label>
                  <input
                    type="date"
                    name="wifeDateOfBirth"
                    value={formData.wifeDateOfBirth}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Dân tộc:
                  </label>
                  <input
                    type="text"
                    name="wifeEthnicity"
                    value={formData.wifeEthnicity}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Quốc tịch:
                  </label>
                  <input
                    type="text"
                    name="wifeNationality"
                    value={formData.wifeNationality}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Nơi cư trú:
                  </label>
                  <textarea
                    name="wifeResidence"
                    value={formData.wifeResidence}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                    rows="3"
                    required
                  ></textarea>
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Loại giấy tờ tùy thân:
                  </label>
                  <select
                    name="wifeIdType"
                    value={formData.wifeIdType}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                    required
                  >
                    <option value="">Chọn loại giấy tờ</option>
                    {idTypes.map(type => (
                      <option key={`wife-${type.value}`} value={type.value}>
                        {type.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Số giấy tờ tùy thân:
                  </label>
                  <input
                    type="text"
                    name="wifeIdNumber"
                    value={formData.wifeIdNumber}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                    required
                  />
                </div>

                <div className="form-group mb-4">
                  <label className="block text-gray-700 font-medium mb-2">
                    Tình trạng hôn nhân hiện tại:
                  </label>
                  <select
                    name="wifeMaritalStatus"
                    value={formData.wifeMaritalStatus}
                    onChange={handleChange}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
                    required
                  >
                    <option value="">Chọn tình trạng</option>
                    {maritalStatuses.map(status => (
                      <option key={`wife-${status.value}`} value={status.value}>
                        {status.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            {/* Registration Information */}
            <div className="mt-8 bg-gray-50 p-6 rounded-lg">
              <h2 className="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Thông tin đăng ký</h2>
              
              <div className="form-group mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Mối quan hệ hiện tại giữa hai bên:
                </label>
                <select
                  name="relationship"
                  value={formData.relationship}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Chọn mối quan hệ</option>
                  <option value="dating">Đang hẹn hò</option>
                  <option value="engaged">Đã đính hôn</option>
                  <option value="living_together">Đang sống chung</option>
                  <option value="other">Khác</option>
                </select>
              </div>
              
              <div className="form-group mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi đăng ký kết hôn:
                </label>
                <input
                  type="text"
                  name="registrationPlace"
                  value={formData.registrationPlace}
                  onChange={handleChange}
                  placeholder="Ví dụ: UBND Phường Liễu Giai, Quận Ba Đình, Hà Nội"
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày, tháng, năm đăng ký:
                </label>
                <input
                  type="date"
                  name="registrationDate"
                  value={formData.registrationDate}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>
            </div>

            {/* Attachments Section */}
            <div className="mt-8 bg-gray-50 p-6 rounded-lg">
              <h2 className="text-xl font-bold text-gray-800 mb-4 border-b pb-2">Tài liệu đính kèm</h2>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy xác nhận tình trạng hôn nhân của bên chồng (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy xác nhận tình trạng hôn nhân của bên vợ (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Bản sao giấy tờ tùy thân của bên chồng (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Bản sao giấy tờ tùy thân của bên vợ (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
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
            <div className="mt-8">
              <div className="flex items-start">
                <input
                  id="consent-laws"
                  type="checkbox"
                  className="h-5 w-5 text-blue-600 mt-1"
                  required
                />
                <label htmlFor="consent-laws" className="ml-2 text-gray-700">
                  Chúng tôi cam đoan tình nguyện kết hôn với nhau, không vi phạm quy định của Luật Hôn nhân và Gia đình về điều kiện kết hôn.
                </label>
              </div>
              
              <div className="flex items-start mt-4">
                <input
                  id="consent-info"
                  type="checkbox"
                  className="h-5 w-5 text-blue-600 mt-1"
                  required
                />
                <label htmlFor="consent-info" className="ml-2 text-gray-700">
                  Chúng tôi cam đoan những lời khai trên đây là đúng sự thật, nếu sai chúng tôi xin chịu trách nhiệm trước pháp luật.
                </label>
              </div>
            </div>

            {/* Submit Button */}
            <div className="mt-8 text-center">
              <button
                type="submit"
                className="bg-red-600 hover:bg-red-700 text-white font-bold py-3 px-8 rounded-md shadow-md transition-colors"
              >
                Gửi đơn đăng ký kết hôn
              </button>
            </div>
          </form>

          <div className="bg-gray-100 p-6">
            <h3 className="text-lg font-bold text-gray-700 mb-2">Quy trình đăng ký kết hôn:</h3>
            <ol className="list-decimal pl-5 text-gray-600 space-y-1">
              <li>Nộp hồ sơ trực tuyến và nhận mã hồ sơ.</li>
              <li>Chờ cán bộ tư pháp xác minh thông tin (2-3 ngày làm việc).</li>
              <li>Nhận thông báo đến trực tiếp để hoàn tất thủ tục.</li>
              <li>Hai bên cùng đến cơ quan đăng ký để ký tên và nhận Giấy chứng nhận kết hôn.</li>
            </ol>
            
            <h3 className="text-lg font-bold text-gray-700 mt-4 mb-2">Lưu ý quan trọng:</h3>
            <ul className="list-disc pl-5 text-gray-600 space-y-1">
              <li>Vui lòng điền đầy đủ và chính xác các thông tin theo yêu cầu.</li>
              <li>Cả hai bên đều phải đến trực tiếp để ký vào Giấy chứng nhận kết hôn.</li>
              <li>Giấy chứng nhận kết hôn có hiệu lực kể từ ngày được cấp.</li>
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
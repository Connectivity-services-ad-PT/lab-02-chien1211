# Chính sách Versioning — Access Gate API

Tài liệu này quy định cách đánh phiên bản (versioning) cho hệ thống API của Access Gate nhằm đảm bảo Core Business (Consumer) không bị ảnh hưởng khi API thay đổi.

## 1. Phương pháp đánh phiên bản
Chúng tôi áp dụng mô hình **Global URI Versioning** cho các bản cập nhật lớn (Breaking Changes) ở cấp độ Base URL (hoặc cấu hình API Gateway).
- Ví dụ: `https://api.access.campus.local/v1/gates/...`
- Trong file `openapi.yaml`, phiên bản của hợp đồng hiện tại được khai báo là `version: 1.0.0`.

## 2. Backward-Compatible Changes (Cập nhật không phá vỡ)
Các thay đổi sau được phép thực hiện trực tiếp trên version hiện tại (`v1`) mà không cần đổi version:
- Thêm một endpoint (path) mới hoàn toàn.
- Thêm một optional parameter (query, header) vào endpoint có sẵn.
- Thêm một thuộc tính mới vào JSON response (Core Business bắt buộc phải bỏ qua các trường không biết mặt - ignore unknown properties).
- Thêm mã lỗi HTTP status code mới (ngoại trừ các lỗi nghiêm trọng làm thay đổi luồng nghiệp vụ cốt lõi).

## 3. Breaking Changes (Cập nhật phá vỡ)
Các thay đổi sau bắt buộc phải đẩy lên phiên bản mới (`v2`):
- Xóa một path hiện có (vd: xóa `/access/logs/recent`).
- Đổi tên một thuộc tính trong request/response JSON (vd: đổi `gateId` thành `gateCode`).
- Thay đổi kiểu dữ liệu của thuộc tính (vd: đổi `limit` từ string sang integer).
- Biến một optional parameter thành required parameter.

## 4. Quy trình Deprecation (Vòng đời khai tử API)
Khi một endpoint bị thay thế, chúng tôi sẽ không xóa ngay lập tức mà áp dụng quy trình sau:
1. Đánh dấu `deprecated: true` trong operation của file `openapi.yaml`.
2. Trả về header tiêu chuẩn `Deprecation: @1716768000` (Unix timestamp ngày thông báo).
3. Cung cấp header `Link: <https://api.access.campus.local/v2/new-endpoint>; rel="alternate"` để trỏ tới API mới.
4. Gửi kèm header `Sunset: Wed, 27 May 2027 00:00:00 GMT` để báo trước cho Consumer biết chính xác ngày API này sẽ ngừng hoạt động (ít nhất 6 tháng).
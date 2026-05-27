# Biên bản đàm phán hợp đồng API

- Cặp đàm phán: Pair 03
- Product: A
- Provider: Access Gate
- Consumer: Core Business
- Phiên: v1.0
- Ngày: 20-05-2026

---

## Issue #1

- Raised by: Provider
- Endpoint: `POST /vision/detect`
- Concern: Định dạng tải ảnh lên là gửi dạng base64 hay qua URL? Base64 làm payload rất lớn và gây lag server REST.
- Proposal: Consumer upload ảnh lên Storage nội bộ (MinIO) và chỉ gửi `imageRef` (URL).
- Resolution: Accepted
- Rationale: Tối ưu băng thông mạng, giảm tải cho API Gateway.
- Impact: Consumer phải có bước upload trước khi gọi API Provider.

---

## Issue #2

- Raised by: Consumer
- Endpoint: `POST /vision/detect`
- Concern: Xử lý AI tốn thời gian, nếu Consumer dùng REST sync thông thường sẽ bị timeout.
- Proposal: Chuyển endpoint này sang dạng Asynchronous REST. Trả về `202 Accepted` và `detectionId` ngay lập tức. Consumer sẽ gọi GET để lấy kết quả.
- Resolution: Accepted
- Rationale: Tránh block thread của Consumer.
- Impact: Phải thêm endpoint `GET /vision/detections/{detectionId}`.

---

## Issue #3

- Raised by: Provider
- Endpoint: `POST /vision/detect`
- Concern: Nếu ảnh quá mờ hoặc file hỏng, AI Vision không phân tích được.
- Proposal: Trả về mã lỗi HTTP 422 (Unprocessable Entity) kèm chi tiết `Problem` schema để báo ảnh không hợp lệ.
- Resolution: Accepted
- Rationale: Tuân thủ chuẩn REST cho các vi phạm rule nghiệp vụ không phải do cú pháp (400).
- Impact: Consumer cần xử lý mã 422 và không retry các ảnh này.

---

## Issue #4

- Raised by: Consumer
- Endpoint: `GET /vision/detections/{detectionId}`
- Concern: Có nhiều loại kết quả phân tích (phát hiện mặt người, phát hiện đồ vật bị bỏ quên). Cấu trúc response cần linh hoạt.
- Proposal: Sử dụng `oneOf` kết hợp `discriminator` để định nghĩa `DetectionResult`.
- Resolution: Accepted
- Rationale: Tận dụng tính năng đa hình của OpenAPI 3.1.
- Impact: Schema phức tạp hơn, Consumer cần phân loại kiểu khi parse JSON.

---

## Issue #5

- Raised by: Provider
- Endpoint: (General Schema)
- Concern: Consumer muốn biết thời gian xử lý xong, nhưng khi task đang chạy thì giá trị này chưa có.
- Proposal: Trường `resolvedAt` sẽ sử dụng tính năng union type với null (`type: [string, "null"]`).
- Resolution: Accepted
- Rationale: OpenAPI 3.1 không hỗ trợ `nullable: true`, nên `[string, "null"]` là bắt buộc và chuẩn mực.
- Impact: Không đổi nhiều, chỉ cần cẩn thận khi code schema.

---

## Issue #6

- Raised by: Consumer
- Endpoint: `POST /vision/detect`
- Concern: Tránh việc gửi trùng sự kiện nếu rớt mạng.
- Proposal: Thêm trường `idempotencyKey` vào header hoặc body request.
- Resolution: Modified (Thêm vào header `Idempotency-Key`).
- Rationale: Tiêu chuẩn hóa việc chống trùng lặp request theo chuẩn ngành.
- Impact: Provider phải lưu cache `Idempotency-Key` trong khoảng 5 phút để so sánh.

---

# Chốt hợp đồng v1.0

Provider sign-off: Đã ký (Trưởng nhóm AI Vision)
Consumer sign-off: Đã ký (Trưởng nhóm Camera Stream)
Witness (GV/TA): Đã duyệt
Date: 20-05-2026
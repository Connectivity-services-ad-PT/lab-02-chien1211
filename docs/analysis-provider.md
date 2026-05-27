# Phân tích yêu cầu — vai Provider

- Cặp đàm phán: Pair 03
- Product: A
- Provider service: Access Gate
- Consumer service: Core Business
- Người viết: Lương Duy Chiến
- Ngày: 20-05-2026

---

## 1. Resource chính

| Resource | Mô tả | Thuộc tính bắt buộc | Thuộc tính tùy chọn |
|---|---|---|---|
| `DetectionTask` | Nhiệm vụ phân tích ảnh | `detectionId`, `cameraId`, `imageRef`, `status` | `errorMessage` |
| `ModelInfo` | Thông tin model AI hiện tại | `version`, `supportedTypes` | `accuracy` |

---

## 2. Action/API dự kiến

| Method | Path | Mục đích | Consumer gọi khi nào? |
|---|---|---|---|
| GET | `/health` | Kiểm tra service AI Vision còn sống không. | Hệ thống monitor gọi, hoặc Consumer gọi khi khởi tạo. |
| POST | `/vision/detect` | Tạo task phân tích AI mới. | Khi có motion event từ Camera. |
| GET | `/vision/detections/{detectionId}` | Trả về kết quả phân tích. | Consumer polling để lấy kết quả (do POST trả về 202). |
| GET | `/vision/models/info` | Trả về thông tin AI models. | Khi Consumer cần cấu hình. |

---

## 3. Error case

| Status | Tình huống | Response body dự kiến |
|---:|---|---|
| 400 | Payload sai định dạng (URL lỗi) | `Problem` schema |
| 401 | Thiếu Bearer token | `Problem` schema |
| 403 | Token hợp lệ nhưng không có role vision | `Problem` schema |
| 404 | `detectionId` không tồn tại | `Problem` schema |
| 422 | Không tải được ảnh từ `imageRef` do file hỏng | `Problem` schema |
| 429 | Vượt quá Rate Limit (Quá nhiều request/giây) | `Problem` schema |

---

## 4. Giả định bổ sung

- Giả định 1: AI Vision hỗ trợ nhiều loại phân tích (Ví dụ: `FaceDetection` và `ObjectDetection`). Kết quả trả về sẽ là cấu trúc đa hình (Polymorphism).
- Giả định 2: AI Vision chỉ lưu kết quả detection trong RAM/Redis khoảng 5 phút. Consumer phải lấy sớm.

---

## 5. Câu hỏi cho Consumer

1. Consumer polling với tần suất bao nhiêu? (Tránh làm sập Provider).
2. Consumer có cần gửi `minConfidence` tùy biến cho mỗi bức ảnh không, hay dùng mặc định của Provider?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| URL ảnh Consumer gửi không thể truy cập từ mạng của AI Vision | 422 liên tục | Kiểm tra lại cấu trúc DNS và Firewall (Service Mesh). |
| Consumer gửi quá nhiều ảnh trùng lặp trong 1 giây | Cạn kiệt tài nguyên GPU | Provider triển khai Rate Limit nghiêm ngặt và IDEMPOTENCY KEY. |
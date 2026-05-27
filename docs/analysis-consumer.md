# Phân tích yêu cầu — vai Consumer

- Cặp đàm phán: Pair 03
- Product: A
- Consumer service: Core Business
- Provider service: Access Gate
- Người viết: Lương Duy Chiến
- Ngày: 20-05-2026

---

## 1. Resource Consumer cần nhận/gửi

| Resource | Consumer dùng để làm gì? | Field bắt buộc với Consumer | Field có thể tùy chọn |
|---|---|---|---|
| `DetectionRequest` | Gửi yêu cầu phân tích hình ảnh/frame từ camera khi có chuyển động. | `cameraId`, `imageRef` (URL ảnh), `timestamp` | `roi` (vùng quan tâm), `minConfidence` |
| `DetectionResult` | Nhận kết quả phân tích để gửi cảnh báo nếu có bất thường. | `detectionId`, `status`, `objects`, `riskLevel` | `resolvedAt`, `modelVersion` |

---

## 2. API Consumer cần gọi

| Method | Path | Lúc nào gọi? | Kỳ vọng response |
|---|---|---|---|
| POST | `/vision/detect` | Khi camera phát hiện có chuyển động (motion). | `202 Accepted` kèm `detectionId` để lấy sau, do xử lý ảnh tốn thời gian. |
| GET | `/vision/detections/{detectionId}` | Gọi định kỳ (polling) sau khi gửi request. | `200 OK` kèm kết quả phân tích (hoặc status là PROCESSING/COMPLETED). |
| GET | `/vision/models/info` | Khi khởi động service để biết AI Vision đang dùng model nào. | `200 OK` chứa version và danh sách nhãn hỗ trợ. |

---

## 3. Error case Consumer cần xử lý

| Status | Consumer hiểu là gì? | Consumer sẽ xử lý thế nào? |
|---:|---|---|
| 400 | Request sai schema (thiếu URL ảnh) | Log lỗi và không gửi lại (cần fix bug nội bộ). |
| 401 | Thiếu token | Yêu cầu cấp lại Bearer token từ Identity Service. |
| 403 | Không đủ quyền gọi AI Vision | Báo cảnh báo Security. |
| 404 | Không tìm thấy detectionId | Bỏ qua hoặc bắt đầu luồng detect mới. |
| 422 | Vi phạm rule nghiệp vụ (ảnh mờ/lỗi format) | Đánh dấu frame bị bỏ qua, không retry frame đó. |
| 429 | Gửi quá nhiều frame cùng lúc | Đưa vào hàng đợi nội bộ (Queue), dãn cách thời gian gửi. |

---

## 4. Giả định bổ sung

- Giả định 1: Để tiết kiệm băng thông, Camera Stream không gửi ảnh thô (base64) qua REST API mà upload lên Object Storage (MinIO/S3) và gửi `imageRef` (URL) cho AI Vision.
- Giả định 2: Quá trình phân tích AI có thể mất 1-3 giây, do đó API `POST` sẽ là dạng Asynchronous (trả về 202).

---

## 5. Câu hỏi cho Provider

1. Provider có giới hạn kích thước/độ phân giải của ảnh được tải từ URL không?
2. AI Vision tự động xóa kết quả detection sau bao lâu?
3. Nếu ảnh quá tối/mờ, AI Vision sẽ trả về 200 (không thấy gì) hay 422?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| Provider xử lý quá chậm | Consumer bị nghẽn queue chờ | Provider giới hạn timeout, trả 503 nếu quá tải. |
| Khác biệt định dạng thời gian | Lệch đồng bộ dữ liệu sự kiện | Thống nhất dùng chuẩn ISO 8601 (UTC). |
# Phân tích yêu cầu — vai Provider

- Cặp đàm phán: Pair 03
- Product: A
- Provider service: Access Gate
- Consumer service: Core Business
- Người viết: Lương Duy Chiến
- Ngày: 27-05-2026

---

## 1. Resource chính

| Resource | Mô tả | Thuộc tính bắt buộc | Thuộc tính tùy chọn |
|---|---|---|---|
| `AccessLog` | Lịch sử quẹt thẻ ra/vào cổng | `logId`, `gateId`, `cardId`, `direction`, `timestamp`, `status` | `operatorNote` |
| `Gate` | Thông tin cổng kiểm soát | `gateId`, `status`, `location` | `lastMaintenance` |
| `Card` | Thẻ định danh | `cardId`, `isActive`, `ownerId` | `expiredAt` |

---

## 2. Action/API dự kiến

| Method | Path | Mục đích | Consumer gọi khi nào? |
|---|---|---|---|
| GET | `/health` | Kiểm tra service Access Gate | Monitor hệ thống gọi định kỳ. |
| GET | `/access/logs/recent` | Lấy danh sách log gần nhất | Core Business cần đối soát sự kiện ra/vào. |
| GET | `/access/logs/{logId}` | Lấy chi tiết 1 log cụ thể | Khi Core Business cần audit một sự kiện đáng ngờ. |
| GET | `/gates/{gateId}/status` | Kiểm tra cổng đang đóng hay mở | Khi có cảnh báo an ninh cần khóa cổng. |
| GET | `/cards/{cardId}` | Lấy thông tin thẻ | Khi cần xác minh thẻ hợp lệ không. |

---

## 3. Error case

| Status | Tình huống | Response body dự kiến |
|---:|---|---|
| 400 | Query parameters sai định dạng | `Problem` schema |
| 401 | Core Business không truyền Bearer token | `Problem` schema |
| 403 | Token hợp lệ nhưng không có quyền read:access | `Problem` schema |
| 404 | `logId`, `gateId`, hoặc `cardId` không tồn tại | `Problem` schema |
| 500 | Lỗi kết nối database nội bộ của Access Gate | `Problem` schema |

---

## 4. Giả định bổ sung

- Giả định 1: `AccessLog` có thể là quẹt thẻ bình thường (`CardSwipeEvent`) hoặc mở cổng thủ công từ bảo vệ (`ManualOverrideEvent`). Cần dùng tính năng đa hình (Polymorphism) để biểu diễn.
- Giả định 2: Dữ liệu log rất lớn, bắt buộc phải có phân trang (pagination) cho API danh sách.

---

## 5. Câu hỏi cho Consumer

1. Core Business cần lấy tối đa bao nhiêu log trong một request (limit)?
2. Chiều ra/vào (`direction`) Core Business muốn lưu dạng `IN/OUT` hay `ENTER/EXIT`?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| Bị tấn công DDoS bằng cách gọi `/access/logs/recent` liên tục | Quá tải Database | Áp dụng Rate Limit và bắt buộc dùng Pagination (Cursor-based). |
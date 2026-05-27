# Phân tích yêu cầu — vai Consumer

- Cặp đàm phán: Pair 03
- Product: A
- Consumer service: Core Business
- Provider service: Access Gate
- Người viết: Lương Duy Chiến
- Ngày: 27-05-2026

---

## 1. Resource Consumer cần nhận/gửi

| Resource | Consumer dùng để làm gì? | Field bắt buộc với Consumer | Field có thể tùy chọn |
|---|---|---|---|
| `AccessEvent` | Đánh giá chính sách an ninh theo thời gian thực | `gateId`, `eventType`, `timestamp`, `status` | `operatorNote` |
| `GateStatus` | Ghi nhận sự cố cổng trên Dashboard | `gateId`, `status` | `lastMaintenance` |

---

## 2. API Consumer cần gọi

| Method | Path | Lúc nào gọi? | Kỳ vọng response |
|---|---|---|---|
| GET | `/access/logs/recent` | Quét định kỳ (cronjob) để đồng bộ dữ liệu | `200 OK` kèm danh sách logs và con trỏ phân trang. |
| GET | `/access/logs/{logId}` | Click xem chi tiết từ giao diện Admin | `200 OK` kèm thông tin chi tiết. |
| GET | `/gates/{gateId}/status` | Hiển thị bản đồ tòa nhà thời gian thực | `200 OK` kèm status (OPEN, CLOSED, MAINTENANCE). |
| GET | `/cards/{cardId}` | Xử lý nghiệp vụ mất thẻ/cấp lại thẻ | `200 OK` chứa thông tin chủ thẻ. |

---

## 3. Error case Consumer cần xử lý

| Status | Consumer hiểu là gì? | Consumer sẽ xử lý thế nào? |
|---:|---|---|
| 400 | Code gọi API bị sai param | Báo lỗi nội bộ, dừng đồng bộ. |
| 401/403 | Lỗi phân quyền | Alert cho team Security kiểm tra lại API Key/Token. |
| 404 | Resource không còn trên Access Gate | Bỏ qua, coi như dữ liệu rác. |
| 429 | Gọi API quá nhanh | Tạm dừng, áp dụng cơ chế Exponential Backoff chờ 5 giây rồi thử lại. |
| 500/503 | Access Gate đang sập | Chuyển sang hàng đợi, thử đồng bộ lại sau 15 phút. |

---

## 4. Giả định bổ sung

- Giả định: Consumer không cần quan tâm đến cách Access Gate giao tiếp phần cứng, chỉ cần dữ liệu REST JSON sạch sẽ qua API.

---

## 5. Câu hỏi cho Provider

1. Nếu hệ thống mất điện, log có lưu offline tại Gate rồi đẩy lên sau không? Timestamp lúc này là giờ gốc hay giờ đẩy lên?
2. Phân trang dùng Offset (`page`, `limit`) hay Cursor (`next_cursor`)?

---

## 6. Rủi ro tích hợp

| Rủi ro | Tác động | Đề xuất xử lý |
|---|---|---|
| Lệch múi giờ ghi log | Sai lệch logic đánh giá người đến muộn | Thống nhất toàn bộ `timestamp` phải dùng chuẩn ISO 8601 (UTC `Z`). |
# Biên bản đàm phán hợp đồng API

- Cặp đàm phán: Pair 03
- Product: A
- Provider: Access Gate
- Consumer: Core Business
- Phiên: v1.0
- Ngày: 27-05-2026

---

## Issue #1

- Raised by: Provider
- Endpoint: `GET /access/logs/recent`
- Concern: Dữ liệu log truy cập rất lớn, nếu Consumer gọi không truyền parameter giới hạn sẽ gây sập database.
- Proposal: Bắt buộc áp dụng Cursor-based pagination. Consumer cần truyền `cursor` và `limit` (mặc định 20, max 100).
- Resolution: Accepted.
- Rationale: Cursor-based hiệu năng cao hơn Offset-based (page/size) khi query bảng hàng triệu dòng log.
- Impact: Consumer phải code xử lý lấy `nextCursor` từ response để gọi trang tiếp theo.

## Issue #2

- Raised by: Consumer
- Endpoint: `GET /access/logs/recent`
- Concern: Sự kiện ra vào không chỉ có quẹt thẻ, mà có lúc bảo vệ mở cổng khẩn cấp bằng nút bấm cứng.
- Proposal: Dùng tính năng Polymorphism (`oneOf` + `discriminator`) trong OpenAPI 3.1. Phân loại `eventType` thành `CARD_SWIPE` và `MANUAL_OVERRIDE`.
- Resolution: Accepted.
- Rationale: Giúp Schema rành mạch. Nếu là `CARD_SWIPE` thì có `cardId`, nếu `MANUAL_OVERRIDE` thì có `operatorId`.
- Impact: Provider phải chuẩn hóa dữ liệu trả về theo đúng định dạng đa hình.

## Issue #3

- Raised by: Provider
- Endpoint: (General Schema)
- Concern: Cột `operatorNote` (ghi chú của bảo vệ) không phải lúc nào cũng có. OpenAPI 3.1 không cho dùng `nullable: true`.
- Proposal: Khai báo trường này là union type: `type: [string, "null"]`.
- Resolution: Accepted.
- Rationale: Tuân thủ đúng chuẩn JSON Schema 2020-12 của OpenAPI 3.1.
- Impact: Không thay đổi business, chỉ chuẩn hóa spec tài liệu.

## Issue #4

- Raised by: Consumer
- Endpoint: `GET /gates/{gateId}/status`
- Concern: Khi cổng bị khóa cứng do báo cháy, Provider trả về gì?
- Proposal: Thêm enum `LOCKED_EMERGENCY` vào thuộc tính `status`.
- Resolution: Accepted.
- Rationale: Giúp Core Business phân biệt được khóa chủ động và khóa khẩn cấp.
- Impact: Schema `GateStatus` cần cập nhật danh sách Enum.

## Issue #5

- Raised by: Provider
- Endpoint: All endpoints
- Concern: Định dạng thời gian.
- Proposal: Thống nhất dùng ISO 8601 UTC (ví dụ: `2026-05-27T08:00:00Z`).
- Resolution: Accepted.
- Rationale: Tránh lỗi lệch múi giờ giữa các microservices.
- Impact: Cả hai team cần kiểm tra lại config serialize/deserialize Date trong code backend.

## Issue #6

- Raised by: Consumer
- Endpoint: All error responses (4xx, 5xx)
- Concern: Các lỗi trả về cần đồng nhất cấu trúc để Consumer dễ parse.
- Proposal: Sử dụng chuẩn `application/problem+json` với schema `Problem` chuẩn của Smart Campus.
- Resolution: Accepted.
- Rationale: Đảm bảo tính đồng bộ trên toàn bộ kiến trúc.
- Impact: Khai báo lại toàn bộ response 400, 401, 403, 404 trong file openapi.yaml trỏ về `$ref: '#/components/schemas/Problem'`.

---

# Chốt hợp đồng v1.0

Provider sign-off: Đã ký (Trưởng nhóm Access Gate)
Consumer sign-off: Đã ký (Trưởng nhóm Core Business)
Witness (GV/TA): Đã duyệt
Date: 27-05-2026
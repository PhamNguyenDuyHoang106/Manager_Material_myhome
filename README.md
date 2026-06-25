# VLXD Manager

Ứng dụng Flutter quản lý cửa hàng vật liệu xây dựng gia đình.

## Mục tiêu dự án

Ứng dụng được xây dựng để thay thế hoàn toàn việc ghi chép thủ công trong cửa hàng vật liệu xây dựng quy mô hộ gia đình.

Đối tượng sử dụng chính:

* Chủ cửa hàng lớn tuổi
* Không rành công nghệ
* Cần thao tác đơn giản
* Yêu cầu dữ liệu công nợ chính xác tuyệt đối
* Không được mất dữ liệu khi đổi máy hoặc hỏng điện thoại

---

# Công nghệ sử dụng

## Frontend

* Flutter
* Riverpod
* GoRouter
* Freezed
* Json Serializable

## Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

## Local Storage

* Hive

---

# Kiến trúc dự án

Áp dụng Clean Architecture:

```text
lib/
├── application/
├── config/
├── data/
├── domain/
├── features/
└── shared/
```

### Domain

Chứa:

* Entities
* Repository Contracts
* Business Services

### Data

Chứa:

* Firestore Repositories
* Firebase Datasources
* Hive Cache

### Presentation

Chứa:

* Screens
* Widgets
* ViewModels
* Providers

---

# Nguyên tắc dữ liệu quan trọng

## Single Source Of Truth

Nguồn dữ liệu công nợ duy nhất là:

CustomerLedgerEntry

Không lưu Running Balance trong Firestore.

Dư nợ được tính động từ Ledger.

```text
Debt = SUM(amountCents)
```

---

## Debt Cache

Customer có trường:

```dart
currentDebtCacheCents
```

Mục đích:

* Hiển thị nhanh
* Dashboard
* Danh sách khách hàng

Nếu cache lệch:

```text
Ledger luôn đúng
Cache được tính lại
```

---

## Immutable Ledger

Không xóa lịch sử công nợ.

Mọi thay đổi đều sinh Ledger mới.

Ví dụ:

### Bán hàng

```text
Ledger Type = sale
```

### Thanh toán

```text
Ledger Type = payment
```

### Hủy hóa đơn

```text
Ledger Type = cancellation
```

### Hủy thanh toán

```text
Ledger Type = paymentReversal
```

Nguyên tắc:

```text
Không xóa Ledger
Không sửa Ledger cũ
Chỉ ghi thêm Ledger mới
```

---

# Chức năng chính

## 1. Quản lý vật liệu

* Danh mục vật liệu
* Nhóm vật liệu động
* Cảnh báo tồn kho tối thiểu
* Theo dõi nhập xuất tồn

---

## 2. Quản lý khách hàng

* Danh sách khách hàng
* Địa chỉ mặc định
* Ghi chú chỉ đường mặc định
* Công nợ hiện tại

---

## 3. Hóa đơn bán hàng

Hỗ trợ:

* Khối
* Xe

Quy đổi:

```text
Xe → Khối
```

Thông qua:

```dart
AppSettings.truckVolume
```

---

## 4. Công nợ khách hàng

Sổ nợ điện tử dạng Ledger.

Hiển thị:

* Ngày
* Nội dung
* Phát sinh
* Dư nợ lũy kế

Cho phép:

* Tìm kiếm
* Lọc loại giao dịch
* Xuất PDF

---

## 5. Thanh toán

Hỗ trợ:

* Thu tiền mặt
* Chuyển khoản

Đính kèm:

* Ảnh biên nhận
* Ảnh chuyển khoản

Lưu trên Firebase Storage.

---

## 6. Cảnh báo nợ quá hạn

Tiêu chí:

```text
Invoice > 30 ngày
Và còn dư nợ
```

Hiển thị trên Dashboard.

---

# Soft Delete

Áp dụng cho:

* Customer
* Material
* Invoice
* Payment

Nguyên tắc:

```text
Không xóa vật lý
```

Thay vào đó:

```dart
isDeleted = true
deletedAt = timestamp
```

Mọi truy vấn mặc định phải loại bỏ dữ liệu đã xóa mềm.

---

# Backup & Restore

## Mục tiêu

Không mất dữ liệu khi:

* Hỏng điện thoại
* Đổi điện thoại
* Cài lại ứng dụng

---

## Auto Backup

Khi ứng dụng mở lần đầu trong ngày:

```text
Kiểm tra ngày backup gần nhất
Nếu chưa backup hôm nay:
    Tự động backup
```

Backup chạy nền.

---

## Manual Backup

Đường dẫn:

```text
Cài đặt
→ Sao lưu & Khôi phục
→ Tạo bản sao lưu ngay
```

---

## Định dạng Backup

```text
backup_YYYY_MM_DD_HH_mm_ss.zip
```

Bên trong:

```text
backup.json
```

Bao gồm:

* Categories
* Materials
* Customers
* Invoices
* Payments
* Ledger
* Settings

---

## Checksum

Sử dụng:

```text
SHA256
```

Quy trình Restore:

```text
Giải nén
↓
Đọc JSON
↓
Kiểm tra SHA256
↓
Restore
```

Nếu checksum sai:

```text
Dừng Restore
```

---

## Retention Policy

Giữ tối đa:

```text
30 bản backup gần nhất
```

Các bản cũ hơn sẽ tự động xóa.

---

# Restore

## Merge

An toàn nhất.

Quy tắc:

```text
Nếu document tồn tại:
    So sánh updatedAt
    Chỉ ghi đè nếu backup mới hơn
```

Có thể chạy nhiều lần.

(Idempotent)

---

## Replace

Xóa dữ liệu hiện tại và khôi phục hoàn toàn.

Yêu cầu:

1. Xác nhận lần 1
2. Xác nhận lần 2
3. Nhập:

```text
XAC_NHAN_RESTORE
```

---

# Firebase Collections

```text
users/{uid}
├── app_settings
├── customers
├── customer_ledger
├── invoices
├── payments
├── materials
├── material_categories
└── inventory_transactions
```

---

# Quy tắc nghiệp vụ quan trọng

## Hủy hóa đơn

Chỉ được hủy khi:

```text
paidAmountCents == 0
```

Nếu đã phát sinh thanh toán:

```text
Không cho phép hủy
```

---

## Hủy thanh toán

Không được xóa Ledger cũ.

Phải sinh:

```text
LedgerEntryType.paymentReversal
```

Để cộng nợ trở lại.

---

# Unit Tests bắt buộc

Các nghiệp vụ cần test:

* Ledger Calculation
* Debt Cache Recalculation
* Invoice Cancellation
* Payment Reversal
* Overdue Debt
* Backup ZIP
* Backup Checksum
* Restore Merge
* Restore Replace

---

# Build Production

Android:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload lên Google Play Console.

---

# Roadmap tương lai

Ưu tiên cao:

* Google Play Internal Testing
* Firebase Crashlytics
* Firebase Analytics
* Cloud Scheduled Backup
* Multi User (Nhân viên)
* Audit Log
* Excel Export

---

# Tác giả

Dự án được phát triển để phục vụ hoạt động kinh doanh của gia đình và tối ưu hóa việc quản lý công nợ, kho hàng và hóa đơn trong cửa hàng vật liệu xây dựng.

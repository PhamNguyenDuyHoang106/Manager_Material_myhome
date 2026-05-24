# Hướng dẫn cài đặt — Quản Lý Vật Liệu (Firebase)

Ứng dụng Flutter dành cho **một cửa hàng, một người dùng** (mẹ bạn). Không cần server riêng — mọi thứ chạy trên Firebase.

## Yêu cầu

- Flutter SDK 3.4+
- Tài khoản [Firebase](https://console.firebase.google.com/)
- Android Studio (để build APK)
- Node.js (chỉ để cài Firebase CLI, tùy chọn)

## Bước 1: Tạo project Firebase

1. Vào Firebase Console → **Add project** (ví dụ: `material-manager-myhome`).
2. Bật **Authentication** → Sign-in method → **Email/Password** → Enable.
3. Tạo user cho mẹ:
   - Authentication → Users → **Add user**
   - Email + mật khẩu (ghi lại để đăng nhập trên điện thoại).
4. Tạo **Cloud Firestore** → Start in **production mode** (sẽ deploy rules sau).
5. Tạo **Storage** (cho logo cửa hàng, tùy chọn).

## Bước 2: Gắn Firebase vào app Android

```bash
cd mobile_app
dart pub global activate flutterfire_cli
flutterfire configure
```

Lệnh này tạo/cập nhật:

- `lib/config/firebase/firebase_options.dart`
- `android/app/google-services.json`

**Hoặc thủ công:** tải `google-services.json` từ Firebase Console → đặt vào `android/app/`.

## Bước 3: Deploy Firestore & Storage rules

```bash
cd ..   # thư mục gốc repo (có folder firebase/)
npm install -g firebase-tools
firebase login
firebase init   # chọn Firestore + Storage, trỏ tới project vừa tạo
firebase deploy --only firestore:rules,storage
```

File rules có sẵn:

- `firebase/firestore.rules` — chỉ user đăng nhập được đọc/ghi dữ liệu của chính họ (`users/{userId}/...`)
- `firebase/storage.rules` — logo trong `users/{userId}/logo/`

## Bước 4: Cài dependency & generate code

```bash
cd mobile_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Bước 5: Chạy trên máy / build APK

```bash
# Debug trên điện thoại (USB debugging)
flutter run

# APK release (gửi cho mẹ cài)
flutter build apk --release
```

File APK: `build/app/outputs/flutter-apk/app-release.apk`

Gửi file qua Zalo/Drive → mẹ bật **Cài đặt từ nguồn không xác định** rồi cài.

## Cấu trúc Firestore

```
users/{userId}/
  customers/{customerId}
  materials/{materialId}
  inventory_transactions/{txId}
  invoices/{invoiceId}
    invoice_items/{itemId}
  payments/{paymentId}
  settings/store
```

Mỗi document chỉ thuộc `userId` = Firebase Auth UID của mẹ.

## Offline

- **Firestore persistence** bật trong `bootstrap.dart` — đọc/ghi offline, tự sync khi có mạng.
- **Hive** cache danh sách customers/materials/invoices khi mất mạng lâu.

## Xuất PDF & gửi Zalo

Trên màn hình chi tiết hóa đơn → menu → **Xuất PDF / Chia sẻ Zalo** → chọn Zalo trong sheet chia sẻ Android.

## Cài đặt cửa hàng

Tab **Cài đặt** → tên cửa hàng, địa chỉ, SĐT (hiển thị trên PDF).

## Index Firestore (nếu báo lỗi index)

Khi chạy lần đầu, Firestore có thể yêu cầu composite index. Mở link trong log lỗi trên Console hoặc thêm file `firestore.indexes.json` và `firebase deploy --only firestore:indexes`.

## Bảo mật

- Chỉ **một** tài khoản email/password cho mẹ.
- Không chia sẻ APK kèm mật khẩu trong tin nhắn công khai.
- Rules đã chặn truy cập chéo giữa các `userId`.

## Kiến trúc app

| Layer | Thư mục |
|-------|---------|
| UI | `lib/features/*/presentation/` |
| State | `lib/application/providers/` |
| Domain | `lib/domain/` |
| Data | `lib/data/repositories/` |
| Core | `lib/core/` |

## Xử lý sự cố

| Vấn đề | Cách xử lý |
|--------|------------|
| `YOUR_ANDROID_API_KEY` | Chạy lại `flutterfire configure` |
| Đăng nhập lỗi | Kiểm tra Email/Password đã bật, user đã tạo |
| Không đủ tồn kho | Nhập kho trước (tab Kho → +) |
| Không sửa/xóa HĐ đã thanh toán | Đúng nghiệp vụ — chỉ HĐ chưa TT mới sửa/xóa |

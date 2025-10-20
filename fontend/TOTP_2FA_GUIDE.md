# Hướng dẫn Xác thực 2 yếu tố (TOTP 2FA)

## Tổng quan
Hệ thống xác thực 2 yếu tố (Two-Factor Authentication - 2FA) sử dụng chuẩn TOTP (Time-based One-Time Password) với Google Authenticator để tăng cường bảo mật tài khoản.

## Công nghệ sử dụng

### Backend
- **GoogleAuthenticator 3.2.0**: Tạo và xác thực mã TOTP
- **QRCoder 1.4.3**: Tạo mã QR cho việc quét
- **ASP.NET Core Identity**: Quản lý người dùng
- **SQL Server**: Lưu trữ TotpSecretKey và IsTotpEnabled

### Frontend
- **qr_flutter 4.1.0**: Hiển thị mã QR
- **pin_code_fields 8.0.1**: Nhập mã 6 chữ số

## Luồng hoạt động

### 1. Bật 2FA (Enable TOTP)
1. User vào **Cá nhân** → Bật switch "Xác thực 2 yếu tố"
2. Hệ thống tạo secret key và QR code
3. User quét QR bằng Google Authenticator hoặc nhập key thủ công
4. User nhập mã 6 chữ số để xác nhận
5. Backend lưu secret key và set `IsTotpEnabled = true`

**API Flow:**
```
POST /api/Auth/totp/enable [Authorize]
Response: { secretKey, qrCodeImageUrl, manualEntryKey }

POST /api/Auth/totp/verify [Authorize]
Body: { code: "123456" }
Response: { success: true, message: "..." }
```

### 2. Đăng nhập với 2FA
1. User nhập email + password → `POST /api/Auth/login-with-totp`
2. Nếu user có 2FA bật:
   - Backend trả về: `{ requiresTwoFactor: true, tempToken: "..." }`
   - App hiển thị màn hình nhập TOTP code
3. User nhập mã 6 chữ số từ Google Authenticator
4. App gửi: `POST /api/Auth/login-with-totp`
   ```json
   {
     "email": "user@example.com",
     "password": "pass",
     "totpCode": "123456"
   }
   ```
5. Backend xác thực mã TOTP và trả về JWT token
6. User được đăng nhập

**Code Flow (Flutter):**
```dart
// LoginScreen._handleLogin()
final result = await authProvider.loginWithTotpSupport(email, password);

if (result['requiresTwoFactor'] == true) {
  // Navigate to TotpVerificationScreen
  final code = await Navigator.push(TotpVerificationScreen(...));
  
  // Verify TOTP code
  await authProvider.loginWithTotp(email, password, code);
}
```

### 3. Tắt 2FA (Disable TOTP)
1. User vào **Cá nhân** → Tắt switch "Xác thực 2 yếu tố"
2. Hệ thống yêu cầu nhập mật khẩu xác nhận
3. Backend xóa secret key và set `IsTotpEnabled = false`

**API:**
```
POST /api/Auth/totp/disable [Authorize]
Body: { password: "user_password" }
```

## Cấu trúc Database

### Migration: 20251020163813_AddTotpSupport
```sql
ALTER TABLE AspNetUsers ADD
  TotpSecretKey nvarchar(max) NULL,
  IsTotpEnabled bit NOT NULL DEFAULT 0;
```

## Files đã tạo/chỉnh sửa

### Backend
- `Models/ApplicationUser.cs` - Thêm TotpSecretKey, IsTotpEnabled
- `Models/DTOs/TotpDTOs.cs` - TOTP request/response models
- `Models/DTOs/AuthDTOs.cs` - Thêm requiresTwoFactor, isTotpEnabled
- `Controllers/AuthController.cs` - 4 endpoints TOTP
- `Migrations/20251020163813_AddTotpSupport.cs`

### Frontend
- `lib/models/auth_models.dart` - Thêm isTotpEnabled
- `lib/models/totp_models.dart` - TOTP models
- `lib/services/auth_service.dart` - 4 TOTP methods
- `lib/providers/auth_provider.dart` - TOTP state management
- `lib/screens/totp_setup_screen.dart` - Setup wizard (3 bước)
- `lib/screens/totp_verification_screen.dart` - Nhập mã khi login
- `lib/screens/login_screen.dart` - Xử lý 2FA flow
- `lib/screens/personal_screen.dart` - Toggle 2FA switch

## API Endpoints

### 1. Enable TOTP
```http
POST https://localhost:5035/api/Auth/totp/enable
Authorization: Bearer <token>

Response:
{
  "secretKey": "BASE32ENCODED...",
  "qrCodeImageUrl": "data:image/png;base64,...",
  "manualEntryKey": "ABCD EFGH IJKL..."
}
```

### 2. Verify TOTP (Complete Setup)
```http
POST https://localhost:5035/api/Auth/totp/verify
Authorization: Bearer <token>
Content-Type: application/json

{
  "code": "123456"
}

Response:
{
  "success": true,
  "message": "TOTP đã được kích hoạt thành công"
}
```

### 3. Login with TOTP
```http
POST https://localhost:5035/api/Auth/login-with-totp
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!",
  "totpCode": "123456"
}

Response (nếu chưa bật 2FA):
{
  "token": "eyJ...",
  "refreshToken": "...",
  "user": { ... },
  "requiresTwoFactor": false
}

Response (nếu đã bật 2FA, chưa nhập code):
{
  "requiresTwoFactor": true,
  "tempToken": null
}

Response (nếu code đúng):
{
  "token": "eyJ...",
  "refreshToken": "...",
  "user": { ... },
  "requiresTwoFactor": false
}
```

### 4. Disable TOTP
```http
POST https://localhost:5035/api/Auth/totp/disable
Authorization: Bearer <token>
Content-Type: application/json

{
  "password": "Password123!"
}

Response:
{
  "success": true,
  "message": "TOTP đã được vô hiệu hóa thành công"
}
```

## UI Components

### 1. TotpSetupScreen (3 bước)
- **Bước 1**: Hướng dẫn tải app authenticator
  - Google Authenticator
  - Microsoft Authenticator
  - Authy
  
- **Bước 2**: Hiển thị QR code
  - QrImageView (200x200)
  - Manual entry key với nút copy
  
- **Bước 3**: Nhập mã xác nhận
  - PinCodeTextField (6 chữ số)
  - Validation realtime
  - Error handling

### 2. TotpVerificationScreen
- Nhập mã 6 chữ số khi login
- Icon security
- Tip box (mã đổi mỗi 30s)
- Nút "Quay lại đăng nhập"

### 3. PersonalScreen - TOTP Card
- Switch bật/tắt 2FA
- Trạng thái hiện tại (Đang bật/Chưa bật)
- Badge màu xanh/cam theo trạng thái
- Dialog nhập password khi tắt

## Testing Guide

### 1. Test Enable TOTP
```bash
# Swagger: POST /api/Auth/totp/enable
# Authorization: Bearer <your_token>
# Expected: JSON với qrCodeImageUrl và manualEntryKey

# Flutter:
1. Login vào app
2. Vào màn Cá nhân
3. Bật switch "Xác thực 2 yếu tố"
4. Quét QR bằng Google Authenticator
5. Nhập mã 6 số
6. Xem toast thành công
```

### 2. Test Login with 2FA
```bash
# Flutter:
1. Logout
2. Login với email + password
3. Thấy màn hình nhập TOTP code
4. Mở Google Authenticator
5. Nhập mã 6 số
6. Login thành công
```

### 3. Test Disable TOTP
```bash
# Swagger: POST /api/Auth/totp/disable
# Body: { "password": "Password123!" }

# Flutter:
1. Vào màn Cá nhân
2. Tắt switch 2FA
3. Nhập password
4. Xem toast "Đã tắt"
5. Logout và login lại → không cần TOTP nữa
```

## Bảo mật

### Secret Key Storage
- Secret key lưu trong database (encrypted by ASP.NET Core)
- Không hiển thị secret key sau khi setup xong

### TOTP Validation
- Mã có hiệu lực 30 giây
- Kiểm tra time window để tránh clock skew
- Mỗi mã chỉ dùng được 1 lần (time-based)

### Password Protection
- Yêu cầu password khi disable 2FA
- JWT token bảo vệ enable/verify/disable endpoints

## Troubleshooting

### Mã TOTP không đúng
- Kiểm tra giờ điện thoại có chính xác không
- Đảm bảo đang xem đúng tài khoản trong Authenticator
- Đợi mã mới (30s refresh)

### Không hiện QR code
- Check response từ backend có qrCodeImageUrl không
- Kiểm tra format: `data:image/png;base64,...`
- Thử manual entry key

### User quên disable 2FA
- Admin có thể update database:
  ```sql
  UPDATE AspNetUsers 
  SET IsTotpEnabled = 0, TotpSecretKey = NULL
  WHERE Email = 'user@example.com'
  ```

## Mở rộng

### Backup Codes (Future)
- Tạo 10 mã backup khi bật 2FA
- User dùng khi mất thiết bị

### SMS 2FA (Alternative)
- Thay TOTP bằng SMS OTP
- Endpoint riêng cho send/verify SMS

### Recovery Email
- Gửi link reset 2FA qua email
- Yêu cầu xác thực identity

## References
- [RFC 6238 - TOTP](https://tools.ietf.org/html/rfc6238)
- [Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)
- [ASP.NET Core Identity](https://docs.microsoft.com/en-us/aspnet/core/security/authentication/identity)

# TOTP (Google Authenticator) - Backend Implementation

## Tổng quan
Đã thêm xác thực 2 yếu tố (Two-Factor Authentication) sử dụng TOTP (Time-based One-Time Password) với Google Authenticator.

## Packages đã cài đặt
- **GoogleAuthenticator** v3.2.0: Generate QR codes và verify TOTP codes
- **QRCoder** v1.4.3: Tạo QR code images (dependency của GoogleAuthenticator)

## Database Changes

### Migration: AddTotpSupport
Thêm 2 cột vào bảng `AspNetUsers`:
- `TotpSecretKey` (nvarchar(max), nullable): Secret key để verify TOTP codes
- `IsTotpEnabled` (bit, NOT NULL, default: 0): Flag để check user có bật 2FA không

## API Endpoints

### 1. POST /api/Auth/totp/enable
**Auth**: Required (Bearer token)  
**Description**: Bắt đầu setup TOTP cho user

**Response**:
```json
{
  "secretKey": "abc123...",
  "qrCodeImageUrl": "data:image/png;base64,...",
  "manualEntryKey": "ABC 123 DEF 456"
}
```

**Flow**:
1. Generate random secret key (16 chars)
2. Lưu vào `TotpSecretKey` (chưa enable)
3. Tạo QR code với issuer "BE1 App"
4. Trả về QR code để user scan

### 2. POST /api/Auth/totp/verify
**Auth**: Required (Bearer token)  
**Request**:
```json
{
  "code": "123456"
}
```

**Response**:
```json
{
  "success": true,
  "message": "TOTP enabled successfully"
}
```

**Flow**:
1. Verify code với TotpSecretKey
2. Nếu đúng: set `IsTotpEnabled = true`
3. User phải verify code thành công mới enable TOTP

### 3. POST /api/Auth/totp/disable
**Auth**: Required (Bearer token)  
**Request**:
```json
{
  "password": "user_password"
}
```

**Response**:
```json
{
  "message": "TOTP disabled successfully"
}
```

**Flow**:
1. Verify password trước khi disable (bảo mật)
2. Set `IsTotpEnabled = false`
3. Xóa `TotpSecretKey = null`

### 4. POST /api/Auth/login-with-totp
**Auth**: Not required  
**Request**:
```json
{
  "email": "user@example.com",
  "password": "password",
  "totpCode": "123456"  // optional
}
```

**Response (nếu user có TOTP nhưng chưa nhập code)**:
```json
{
  "token": "",
  "refreshToken": "",
  "user": {
    "id": "...",
    "email": "...",
    "fullName": "...",
    "roles": [],
    "isTotpEnabled": true
  },
  "requiresTwoFactor": true,
  "tempToken": "base64_encoded_email",
  "expiration": "..."
}
```

**Response (nếu login thành công)**:
```json
{
  "token": "jwt_token",
  "refreshToken": "refresh_token",
  "user": {...},
  "requiresTwoFactor": false,
  "expiration": "..."
}
```

## Login Flow

### Không có TOTP:
1. POST /api/Auth/login → Trả JWT token ngay

### Có TOTP:
1. POST /api/Auth/login-with-totp (chỉ email + password)
2. Server check: user có `IsTotpEnabled = true`
3. Server trả `requiresTwoFactor: true`
4. Client hiển thị màn hình nhập TOTP code
5. Client gọi lại POST /api/Auth/login-with-totp (có totpCode)
6. Server verify TOTP code
7. Nếu đúng → trả JWT token

## Security Features

1. **Secret Key Generation**: Random GUID, 16 characters
2. **Password Verification**: Phải nhập password để disable TOTP
3. **Time-based**: TOTP code thay đổi mỗi 30 giây
4. **No Bypass**: Nếu user enable TOTP, PHẢI nhập code mới login được

## DTO Updates

### AuthResponse
```csharp
public bool RequiresTwoFactor { get; set; } = false;
public string? TempToken { get; set; }
```

### UserInfo
```csharp
public bool IsTotpEnabled { get; set; } = false;
```

## Code Locations

- **Models/ApplicationUser.cs**: Thêm `TotpSecretKey`, `IsTotpEnabled`
- **Models/DTOs/TotpDTOs.cs**: TOTP DTOs
- **Models/DTOs/AuthDTOs.cs**: Updated AuthResponse, UserInfo
- **Controllers/AuthController.cs**: TOTP endpoints (line ~240+)
- **Migrations/20251020163813_AddTotpSupport.cs**: Database migration

## Testing với Swagger

1. **Register/Login** để lấy JWT token
2. **Authorize** trong Swagger với token
3. **POST /api/Auth/totp/enable** → Lấy QR code
4. Scan QR code bằng **Google Authenticator** app
5. **POST /api/Auth/totp/verify** với code từ app (6 digits)
6. **POST /api/Auth/login-with-totp** để test login flow

## Next Steps (Flutter)

- [ ] Tạo TOTP models
- [ ] Cập nhật AuthService với TOTP methods
- [ ] Tạo TotpSetupScreen (hiển thị QR code)
- [ ] Tạo TotpVerificationScreen (nhập 6-digit code)
- [ ] Cập nhật LoginScreen để handle requiresTwoFactor
- [ ] Thêm toggle TOTP trong Personal/Settings screen

## Dependencies

```xml
<PackageReference Include="GoogleAuthenticator" Version="3.2.0" />
```

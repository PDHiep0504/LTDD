# 🔐 TOTP Secret Encryption Implementation

## 📋 Tổng quan

Đã implement mã hóa AES-256 cho `TotpSecretKey` trong database để tăng cường bảo mật.

---

## 🔧 Các thay đổi

### 1. **Services mới**
- `IEncryptionService.cs` - Interface cho encryption/decryption
- `EncryptionService.cs` - Implementation AES-256-CBC encryption

### 2. **Configuration**
Thêm vào `appsettings.json` và `appsettings.Development.json`:
```json
"Encryption": {
  "Key": "qfrLgQM8AoR8V1HfXqOBIi7QsG9UHeYS/MjL+/blBK4=",
  "IV": "JzQwj/P3BFOkb9ER0QlXgA=="
}
```

⚠️ **QUAN TRỌNG**: Đổi key và IV khác cho môi trường production!

### 3. **Program.cs**
```csharp
builder.Services.AddSingleton<IEncryptionService, EncryptionService>();
```

### 4. **AuthController.cs**
- Inject `IEncryptionService` vào constructor
- Encrypt secret khi enable TOTP
- Decrypt secret khi verify/login

---

## 🚀 Cách triển khai

### Bước 1: Generate keys mới cho production

```powershell
# PowerShell
$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
$iv = [Convert]::ToBase64String((1..16 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
Write-Host "Key: $key"
Write-Host "IV: $iv"
```

Hoặc dùng C#:
```csharp
using System.Security.Cryptography;

var key = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
var iv = Convert.ToBase64String(RandomNumberGenerator.GetBytes(16));
Console.WriteLine($"Key: {key}");
Console.WriteLine($"IV: {iv}");
```

### Bước 2: Cập nhật appsettings.json

```json
"Encryption": {
  "Key": "YOUR_NEW_KEY_HERE",
  "IV": "YOUR_NEW_IV_HERE"
}
```

### Bước 3: Migrate dữ liệu cũ (nếu có users đã enable TOTP)

**Option A: Reset tất cả users (khuyến nghị)**
```sql
UPDATE AspNetUsers
SET 
    IsTotpEnabled = 0,
    TotpSecretKey = NULL
WHERE IsTotpEnabled = 1;
```

Users sẽ phải setup lại TOTP với encryption mới.

**Option B: Migrate và encrypt secrets cũ**

Tạo endpoint tạm thời trong AuthController:
```csharp
[HttpPost("admin/migrate-totp-secrets")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> MigrateTotpSecrets()
{
    var helper = new TotpSecretMigrationHelper(_context, _encryptionService);
    await helper.MigrateExistingSecretsAsync();
    return Ok(new { message = "Migration completed" });
}
```

⚠️ **XÓA endpoint này sau khi migrate xong!**

---

## 🔐 Bảo mật

### ✅ Đã làm
- ✅ Mã hóa `TotpSecretKey` bằng AES-256
- ✅ Key và IV lưu trong appsettings (không commit vào git)
- ✅ Decrypt chỉ khi cần verify

### ⚠️ Cần lưu ý
- ❌ **KHÔNG commit** encryption keys vào git
- ✅ Dùng Azure Key Vault hoặc AWS Secrets Manager cho production
- ✅ Rotate keys định kỳ (6-12 tháng)
- ✅ Backup database trước khi migrate

### 🔒 Best practices cho production

1. **Dùng Environment Variables**
```bash
export ENCRYPTION_KEY="your-key-here"
export ENCRYPTION_IV="your-iv-here"
```

```csharp
// Program.cs
builder.Configuration["Encryption:Key"] = Environment.GetEnvironmentVariable("ENCRYPTION_KEY");
builder.Configuration["Encryption:IV"] = Environment.GetEnvironmentVariable("ENCRYPTION_IV");
```

2. **Dùng Azure Key Vault**
```csharp
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{keyVaultName}.vault.azure.net/"),
    new DefaultAzureCredential());
```

3. **Dùng AWS Secrets Manager**
```csharp
builder.Configuration.AddSecretsManager();
```

---

## 📊 Database Schema

Không có thay đổi về schema. Column `TotpSecretKey` vẫn là `nvarchar(MAX)`, nhưng giờ chứa encrypted data (Base64).

### Trước khi mã hóa:
```
TotpSecretKey: "abc123def456ghi789"
```

### Sau khi mã hóa:
```
TotpSecretKey: "xJ2Kd9f3Qw7R5tYu8iOp1aSdFg6hJkL4zXcVbNm=="
```

---

## 🧪 Testing

### Test encryption/decryption:

```csharp
var encryptionService = new EncryptionService(configuration);

var plaintext = "abc123def456";
var encrypted = encryptionService.Encrypt(plaintext);
var decrypted = encryptionService.Decrypt(encrypted);

Assert.Equal(plaintext, decrypted);
```

### Test TOTP flow:

1. Enable TOTP → Secret được encrypt trước khi save
2. Verify TOTP → Secret được decrypt rồi verify
3. Login với TOTP → Secret được decrypt rồi verify
4. Disable TOTP → Secret bị xóa

---

## 🐛 Troubleshooting

### Lỗi: "Encryption key must be 32 bytes"
- Key phải là 32 bytes (256 bits) khi decode từ Base64
- Dùng script generate ở trên

### Lỗi: "Failed to decrypt data"
- Key/IV không đúng
- Dữ liệu bị corrupt
- Hoặc đang cố decrypt plaintext (chưa encrypt)

### Lỗi: "Invalid TOTP code" sau khi enable encryption
- User cần setup lại TOTP
- Hoặc chạy migration script để encrypt secrets cũ

---

## 📝 Changelog

### v1.0.0 - 2025-10-21
- ✅ Thêm `IEncryptionService` và `EncryptionService`
- ✅ Encrypt `TotpSecretKey` khi enable TOTP
- ✅ Decrypt `TotpSecretKey` khi verify/login
- ✅ Thêm migration helper cho dữ liệu cũ
- ✅ Document cách triển khai

---

## 🔗 Tham khảo

- [AES Encryption in .NET](https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.aes)
- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)
- [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)

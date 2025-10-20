# Debug Guide: 2FA Login Issue

## Problem
- Account with 2FA enabled (admin@be1.com) cannot login
- Account without 2FA can login successfully

## Root Cause Analysis

### Expected Flow for 2FA Account
1. User enters email + password
2. App calls `POST /api/Auth/login-with-totp` with email/password (no totpCode)
3. Backend verifies password, sees IsTotpEnabled=true
4. Backend returns:
   ```json
   {
     "token": "",
     "refreshToken": "",
     "user": {
       "id": "user-id",
       "email": "admin@be1.com",
       "fullName": "Admin User",
       "roles": [],
       "isTotpEnabled": true
     },
     "requiresTwoFactor": true,
     "tempToken": "base64-encoded-email",
     "expiration": "2025-10-21T..."
   }
   ```
5. Flutter sees `requiresTwoFactor: true`
6. Flutter navigates to TotpVerificationScreen
7. User enters 6-digit code
8. App calls `POST /api/Auth/login-with-totp` with email/password/totpCode
9. Backend validates TOTP code
10. Backend returns full token and user data
11. User is logged in

### Debugging Steps

#### Step 1: Check Backend Response
Add this to your backend AuthController.cs LoginWithTotp method (line 396):

```csharp
// After creating AuthResponse for 2FA
if (user.IsTotpEnabled && string.IsNullOrEmpty(request.TotpCode))
{
    var twoFactorResponse = new AuthResponse
    {
        Token = string.Empty,
        RefreshToken = string.Empty,
        User = new UserInfo
        {
            Id = user.Id,
            Email = user.Email!,
            FullName = user.FullName ?? "",
            Roles = new List<string>(),
            IsTotpEnabled = true
        },
        RequiresTwoFactor = true,
        TempToken = Convert.ToBase64String(Encoding.UTF8.GetBytes(user.Email!)),
        Expiration = DateTime.UtcNow
    };
    
    // DEBUG: Log the response
    _logger.LogInformation("2FA Response: {@Response}", twoFactorResponse);
    
    return Ok(twoFactorResponse);
}
```

#### Step 2: Check Flutter Logs
After my changes, you should see this in Flutter console when logging in with 2FA account:

```
=== Login with TOTP Response ===
{"token":"","refreshToken":"","user":{"id":"...","email":"admin@be1.com",...},"requiresTwoFactor":true,...}
================================
2FA required, not saving tokens
```

#### Step 3: Common Issues and Fixes

##### Issue A: Backend returns 401 Unauthorized
- **Symptom**: No response body, just 401 status
- **Cause**: Password is incorrect or user doesn't exist
- **Fix**: Verify credentials in database

##### Issue B: Flutter throws parsing error
- **Symptom**: Error like "type 'Null' is not a subtype of type 'String'"
- **Cause**: Backend JSON keys don't match Flutter models
- **Fix**: Check if backend uses camelCase (token) or PascalCase (Token)

##### Issue C: requiresTwoFactor is false when it should be true
- **Symptom**: App doesn't show TOTP screen, tries to login directly
- **Cause**: Backend not setting flag correctly
- **Fix**: Verify `user.IsTotpEnabled` is true in database:
  ```sql
  SELECT Email, IsTotpEnabled, TotpSecretKey FROM AspNetUsers WHERE Email = 'admin@be1.com'
  ```

##### Issue D: TOTP screen appears but login fails after entering code
- **Symptom**: "Invalid TOTP code" even when code is correct
- **Cause**: Time sync issue or wrong secret key
- **Fix**: 
  - Ensure server time is accurate (TOTP is time-based)
  - Verify TotpSecretKey is not null in database
  - Check if `secretIsBase32: false` matches how secret was generated

#### Step 4: Manual API Test

Test the endpoint directly with curl or Postman:

```bash
# Test 1: Login without TOTP code (should return requiresTwoFactor: true)
curl -X POST https://dfb7a7ab57eb.ngrok-free.app/api/Auth/login-with-totp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@be1.com",
    "password": "YourPassword123!"
  }'

# Expected response:
# {
#   "token": "",
#   "refreshToken": "",
#   "user": { ... },
#   "requiresTwoFactor": true,
#   ...
# }

# Test 2: Login with TOTP code
curl -X POST https://dfb7a7ab57eb.ngrok-free.app/api/Auth/login-with-totp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@be1.com",
    "password": "YourPassword123!",
    "totpCode": "123456"
  }'

# Expected response (if code correct):
# {
#   "token": "eyJhbGc...",
#   "refreshToken": "...",
#   "user": { ... },
#   "requiresTwoFactor": false,
#   ...
# }
```

## Code Changes Made

### 1. AuthService.loginWithTotp() - Added Debug Logging
File: `fontend/lib/services/auth_service.dart`

Added:
- Debug print of full API response
- Better handling of 2FA response parsing
- Stack trace on errors

### 2. AuthProvider.loginWithTotpSupport() - Uses Unified Endpoint
File: `fontend/lib/providers/auth_provider.dart`

Changed:
- Now calls `loginWithTotp()` instead of `login()`
- Properly handles requiresTwoFactor flag

## How to Test Now

1. **Start backend** (if not running):
   ```powershell
   cd D:\LTDD\LTDD\backend
   dotnet run
   ```

2. **Ensure ngrok is forwarding**:
   - Check that ngrok URL in `.env` matches running ngrok tunnel
   - Visit: https://dfb7a7ab57eb.ngrok-free.app/swagger

3. **Run Flutter app** (already building):
   - Wait for build to finish
   - App should auto-hot-reload with new code

4. **Test 2FA Login**:
   - Enter `admin@be1.com` + password
   - Watch Flutter console for debug output
   - You should see:
     - "=== Login with TOTP Response ===" with JSON
     - "2FA required, not saving tokens"
   - TotpVerificationScreen should appear
   - Enter 6-digit code from Google Authenticator
   - Should login successfully

5. **If still fails**, share the console output (especially the JSON response)

## Quick Verification Commands

```powershell
# Check if backend is running
curl https://dfb7a7ab57eb.ngrok-free.app/swagger/index.html

# Check database for 2FA status
# (Run this in SQL Server Management Studio or Azure Data Studio)
SELECT Email, IsTotpEnabled, TotpSecretKey IS NOT NULL as HasSecret 
FROM AspNetUsers 
WHERE Email = 'admin@be1.com'

# Should show: IsTotpEnabled = 1, HasSecret = 1
```

## Next Steps

After you run the test:
1. Share the Flutter console output (the JSON response)
2. If there's an error, share the full error message
3. I'll pinpoint the exact issue and fix it

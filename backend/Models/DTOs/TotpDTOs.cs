namespace BE1.Models.DTOs
{
    public class EnableTotpRequest
    {
        // Request không cần gì, chỉ cần user đã đăng nhập
    }

    public class EnableTotpResponse
    {
        public string SecretKey { get; set; } = string.Empty;
        public string QrCodeImageUrl { get; set; } = string.Empty; // Base64 image (nếu cần)
        public string QrCodeData { get; set; } = string.Empty; // otpauth:// URL
        public string ManualEntryKey { get; set; } = string.Empty;
    }

    public class VerifyTotpRequest
    {
        public required string Code { get; set; }
    }

    public class VerifyTotpResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
    }

    public class DisableTotpRequest
    {
        public required string Password { get; set; }
    }

    public class LoginWithTotpRequest
    {
        public required string Email { get; set; }
        public required string Password { get; set; }
        public string? TotpCode { get; set; }
    }
}

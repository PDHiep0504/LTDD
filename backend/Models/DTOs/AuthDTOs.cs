namespace BE1.Models.DTOs;

public class RegisterRequest
{
	public required string Email { get; set; }
	public required string Password { get; set; }
	public required string FullName { get; set; }
	public string? UserName { get; set; }
}

public class LoginRequest
{
	public required string Email { get; set; }
	public required string Password { get; set; }
}

public class AuthResponse
{
	public required string Token { get; set; }
	public required string RefreshToken { get; set; }
	public required UserInfo User { get; set; }
	public DateTime Expiration { get; set; }
}

public class UserInfo
{
	public required string Id { get; set; }
	public required string Email { get; set; }
	public required string FullName { get; set; }
	public required List<string> Roles { get; set; }
}

public class RefreshTokenRequest
{
	public required string Token { get; set; }
	public required string RefreshToken { get; set; }
}

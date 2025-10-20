namespace BE1.Models;

public class RefreshToken
{
	public int Id { get; set; }
	public required string UserId { get; set; }
	public required string Token { get; set; }
	public DateTime ExpiresAt { get; set; }
	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
	public bool IsRevoked { get; set; }
}

using Microsoft.AspNetCore.Identity;

namespace BE1.Models;

public class ApplicationUser : IdentityUser
{
	public string? FullName { get; set; }
	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
	public DateTime? LastLoginAt { get; set; }
}

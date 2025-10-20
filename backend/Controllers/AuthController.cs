using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using BE1.Models;
using BE1.Models.DTOs;
using BE1.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Google.Authenticator;
using Microsoft.AspNetCore.Authorization;

namespace BE1.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
	private readonly UserManager<ApplicationUser> _userManager;
	private readonly RoleManager<IdentityRole> _roleManager;
	private readonly ApplicationDbContext _context;
	private readonly IConfiguration _configuration;
	private readonly ILogger<AuthController> _logger;
	private readonly IEncryptionService _encryptionService;

	public AuthController(
		UserManager<ApplicationUser> userManager,
		RoleManager<IdentityRole> roleManager,
		ApplicationDbContext context,
		IConfiguration configuration,
		ILogger<AuthController> logger,
		IEncryptionService encryptionService)
	{
		_userManager = userManager;
		_roleManager = roleManager;
		_context = context;
		_configuration = configuration;
		_logger = logger;
		_encryptionService = encryptionService;
	}

	[HttpPost("register")]
	public async Task<IActionResult> Register([FromBody] RegisterRequest request)
	{
		try
		{
			var existingUser = await _userManager.FindByEmailAsync(request.Email);
			if (existingUser != null)
				return BadRequest(new { message = "Email already registered" });

			var user = new ApplicationUser
			{
				Email = request.Email,
				UserName = request.UserName ?? request.Email,
				FullName = request.FullName,
				EmailConfirmed = true
			};

			var result = await _userManager.CreateAsync(user, request.Password);
			if (!result.Succeeded)
				return BadRequest(new { message = "Registration failed", errors = result.Errors });

			// Assign default User role
			await _userManager.AddToRoleAsync(user, "User");

			_logger.LogInformation("User {Email} registered successfully", request.Email);
			return Ok(new { message = "Registration successful" });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Registration error");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpPost("login")]
	public async Task<IActionResult> Login([FromBody] LoginRequest request)
	{
		try
		{
			var user = await _userManager.FindByEmailAsync(request.Email);
			if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
				return Unauthorized(new { message = "Invalid email or password" });

			user.LastLoginAt = DateTime.UtcNow;
			await _userManager.UpdateAsync(user);

			var roles = await _userManager.GetRolesAsync(user);
			var token = await GenerateJwtToken(user, roles.ToList());
			var refreshToken = GenerateRefreshToken();

			// Save refresh token to database
			var refreshTokenEntity = new RefreshToken
			{
				UserId = user.Id,
				Token = refreshToken,
				ExpiresAt = DateTime.UtcNow.AddDays(_configuration.GetValue<int>("JwtSettings:RefreshTokenExpirationInDays"))
			};
			_context.RefreshTokens.Add(refreshTokenEntity);
			await _context.SaveChangesAsync();

			var response = new AuthResponse
			{
				Token = token,
				RefreshToken = refreshToken,
				User = new UserInfo
				{
					Id = user.Id,
					Email = user.Email!,
					FullName = user.FullName ?? "",
					Roles = roles.ToList(),
					IsTotpEnabled = user.IsTotpEnabled
				},
				Expiration = DateTime.UtcNow.AddMinutes(_configuration.GetValue<int>("JwtSettings:ExpirationInMinutes"))
			};

			_logger.LogInformation("User {Email} logged in successfully", request.Email);
			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Login error");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpPost("refresh")]
	public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
	{
		try
		{
			var principal = GetPrincipalFromExpiredToken(request.Token);
			if (principal == null)
				return Unauthorized(new { message = "Invalid token" });

			var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
			var savedToken = await _context.RefreshTokens
				.FirstOrDefaultAsync(rt => rt.Token == request.RefreshToken && rt.UserId == userId && !rt.IsRevoked);

			if (savedToken == null || savedToken.ExpiresAt < DateTime.UtcNow)
				return Unauthorized(new { message = "Invalid or expired refresh token" });

			var user = await _userManager.FindByIdAsync(userId!);
			if (user == null)
				return Unauthorized(new { message = "User not found" });

			var roles = await _userManager.GetRolesAsync(user);
			var newToken = await GenerateJwtToken(user, roles.ToList());
			var newRefreshToken = GenerateRefreshToken();

			// Revoke old refresh token
			savedToken.IsRevoked = true;

			// Save new refresh token
			var refreshTokenEntity = new RefreshToken
			{
				UserId = user.Id,
				Token = newRefreshToken,
				ExpiresAt = DateTime.UtcNow.AddDays(_configuration.GetValue<int>("JwtSettings:RefreshTokenExpirationInDays"))
			};
			_context.RefreshTokens.Add(refreshTokenEntity);
			await _context.SaveChangesAsync();

			var response = new AuthResponse
			{
				Token = newToken,
				RefreshToken = newRefreshToken,
				User = new UserInfo
				{
					Id = user.Id,
					Email = user.Email!,
					FullName = user.FullName ?? "",
					Roles = roles.ToList(),
					IsTotpEnabled = user.IsTotpEnabled
				},
				Expiration = DateTime.UtcNow.AddMinutes(_configuration.GetValue<int>("JwtSettings:ExpirationInMinutes"))
			};

			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Token refresh error");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	private async Task<string> GenerateJwtToken(ApplicationUser user, List<string> roles)
	{
		var claims = new List<Claim>
		{
			new Claim(ClaimTypes.NameIdentifier, user.Id),
			new Claim(ClaimTypes.Email, user.Email!),
			new Claim(ClaimTypes.Name, user.FullName ?? user.UserName!),
			new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
		};

		foreach (var role in roles)
		{
			claims.Add(new Claim(ClaimTypes.Role, role));
		}

		var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JwtSettings:Secret"]!));
		var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
		var expires = DateTime.UtcNow.AddMinutes(_configuration.GetValue<int>("JwtSettings:ExpirationInMinutes"));

		var token = new JwtSecurityToken(
			issuer: _configuration["JwtSettings:Issuer"],
			audience: _configuration["JwtSettings:Audience"],
			claims: claims,
			expires: expires,
			signingCredentials: creds
		);

		return new JwtSecurityTokenHandler().WriteToken(token);
	}

	private string GenerateRefreshToken()
	{
		var randomNumber = new byte[32];
		using var rng = RandomNumberGenerator.Create();
		rng.GetBytes(randomNumber);
		return Convert.ToBase64String(randomNumber);
	}

	private ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
	{
		var tokenValidationParameters = new TokenValidationParameters
		{
			ValidateAudience = false,
			ValidateIssuer = false,
			ValidateIssuerSigningKey = true,
			IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JwtSettings:Secret"]!)),
			ValidateLifetime = false
		};

		var tokenHandler = new JwtSecurityTokenHandler();
		try
		{
			var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out SecurityToken securityToken);
			if (securityToken is not JwtSecurityToken jwtSecurityToken || 
			    !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
				return null;

			return principal;
		}
		catch
		{
			return null;
		}
	}

	// ==================== TOTP (Google Authenticator) Endpoints ====================

	[HttpPost("totp/enable")]
	[Authorize]
	public async Task<IActionResult> EnableTotp()
	{
		try
		{
			var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
			var user = await _userManager.FindByIdAsync(userId!);
			
			if (user == null)
				return NotFound(new { message = "User not found" });

			if (user.IsTotpEnabled)
				return BadRequest(new { message = "TOTP is already enabled" });

			// Generate secret key
			var key = Guid.NewGuid().ToString().Replace("-", "").Substring(0, 16);
			
			// 🔐 ENCRYPT secret key before saving to database
			user.TotpSecretKey = _encryptionService.Encrypt(key);
			await _userManager.UpdateAsync(user);

			// Generate QR Code (use plaintext key)
			var authenticator = new TwoFactorAuthenticator();
			var setupInfo = authenticator.GenerateSetupCode(
				issuer: "BE1 App",
				accountTitleNoSpaces: user.Email!,
				accountSecretKey: key, // ← Use plaintext for QR code
				secretIsBase32: false
			);

			// Tạo otpauth:// URL để Flutter app tạo QR code
			var otpauthUrl = $"otpauth://totp/BE1%20App:{Uri.EscapeDataString(user.Email!)}?secret={setupInfo.ManualEntryKey}&issuer=BE1%20App";

			var response = new EnableTotpResponse
			{
				SecretKey = key, // ← Return plaintext to user (only once)
				QrCodeImageUrl = setupInfo.QrCodeSetupImageUrl, // Base64 image (optional, nếu muốn hiển thị trực tiếp)
				QrCodeData = otpauthUrl, // ← Chuỗi otpauth:// để Flutter tạo QR code
				ManualEntryKey = setupInfo.ManualEntryKey
			};

			_logger.LogInformation("TOTP setup initiated for user {Email}", user.Email);
			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Enable TOTP error");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpPost("totp/verify")]
	[Authorize]
	public async Task<IActionResult> VerifyTotp([FromBody] VerifyTotpRequest request)
	{
		try
		{
			var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
			var user = await _userManager.FindByIdAsync(userId!);
			
			if (user == null)
				return NotFound(new { message = "User not found" });

		if (string.IsNullOrEmpty(user.TotpSecretKey))
			return BadRequest(new { message = "TOTP is not set up" });

		// 🔐 DECRYPT secret key from database
		var decryptedKey = _encryptionService.Decrypt(user.TotpSecretKey);

		var authenticator = new TwoFactorAuthenticator();
		var isValid = authenticator.ValidateTwoFactorPIN(
			accountSecretKey: decryptedKey, // ← Use decrypted key
			twoFactorCodeFromClient: request.Code,
			secretIsBase32: false
		);			if (isValid)
			{
				user.IsTotpEnabled = true;
				await _userManager.UpdateAsync(user);

				_logger.LogInformation("TOTP enabled successfully for user {Email}", user.Email);
				return Ok(new VerifyTotpResponse 
				{ 
					Success = true, 
					Message = "TOTP enabled successfully" 
				});
			}

			return BadRequest(new VerifyTotpResponse 
			{ 
				Success = false, 
				Message = "Invalid TOTP code" 
			});
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Verify TOTP error");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpPost("totp/disable")]
	[Authorize]
	public async Task<IActionResult> DisableTotp([FromBody] DisableTotpRequest request)
	{
		try
		{
			var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
			var user = await _userManager.FindByIdAsync(userId!);
			
			if (user == null)
				return NotFound(new { message = "User not found" });

			if (!user.IsTotpEnabled)
				return BadRequest(new { message = "TOTP is not enabled" });

			// Verify password before disabling
			if (!await _userManager.CheckPasswordAsync(user, request.Password))
				return Unauthorized(new { message = "Invalid password" });

			user.IsTotpEnabled = false;
			user.TotpSecretKey = null;
			await _userManager.UpdateAsync(user);

			_logger.LogInformation("TOTP disabled for user {Email}", user.Email);
			return Ok(new { message = "TOTP disabled successfully" });
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Disable TOTP error");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpPost("login-with-totp")]
	public async Task<IActionResult> LoginWithTotp([FromBody] LoginWithTotpRequest request)
	{
		try
		{
			var user = await _userManager.FindByEmailAsync(request.Email);
			if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
				return Unauthorized(new { message = "Invalid email or password" });

			// Check if user has TOTP enabled
			if (user.IsTotpEnabled)
			{
				// If TOTP code not provided, return flag to request it
				if (string.IsNullOrEmpty(request.TotpCode))
				{
					return Ok(new AuthResponse
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
					});
				}

			// Verify TOTP code
			// 🔐 DECRYPT secret key from database
			var decryptedKey = _encryptionService.Decrypt(user.TotpSecretKey!);
			
			var authenticator = new TwoFactorAuthenticator();
			var isValid = authenticator.ValidateTwoFactorPIN(
				accountSecretKey: decryptedKey, // ← Use decrypted key
				twoFactorCodeFromClient: request.TotpCode,
				secretIsBase32: false
			);				if (!isValid)
					return Unauthorized(new { message = "Invalid TOTP code" });
			}

			// Proceed with login
			user.LastLoginAt = DateTime.UtcNow;
			await _userManager.UpdateAsync(user);

			var roles = await _userManager.GetRolesAsync(user);
			var token = await GenerateJwtToken(user, roles.ToList());
			var refreshToken = GenerateRefreshToken();

			// Save refresh token
			var refreshTokenEntity = new RefreshToken
			{
				UserId = user.Id,
				Token = refreshToken,
				ExpiresAt = DateTime.UtcNow.AddDays(_configuration.GetValue<int>("JwtSettings:RefreshTokenExpirationInDays"))
			};
			_context.RefreshTokens.Add(refreshTokenEntity);
			await _context.SaveChangesAsync();

			var response = new AuthResponse
			{
				Token = token,
				RefreshToken = refreshToken,
				User = new UserInfo
				{
					Id = user.Id,
					Email = user.Email!,
					FullName = user.FullName ?? "",
					Roles = roles.ToList(),
					IsTotpEnabled = user.IsTotpEnabled
				},
				Expiration = DateTime.UtcNow.AddMinutes(_configuration.GetValue<int>("JwtSettings:ExpirationInMinutes"))
			};

			_logger.LogInformation("User {Email} logged in successfully with TOTP", request.Email);
			return Ok(response);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Login with TOTP error");
			return Problem("Internal server error", statusCode: 500);
		}
	}
}

using BE1.Models;
using BE1.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace BE1.Migrations
{
    /// <summary>
    /// Helper class to migrate existing plaintext TOTP secrets to encrypted format
    /// Run this ONCE after deploying encryption feature
    /// </summary>
    public class TotpSecretMigrationHelper
    {
        private readonly ApplicationDbContext _context;
        private readonly IEncryptionService _encryptionService;

        public TotpSecretMigrationHelper(
            ApplicationDbContext context, 
            IEncryptionService encryptionService)
        {
            _context = context;
            _encryptionService = encryptionService;
        }

        /// <summary>
        /// Encrypt all existing plaintext TOTP secrets
        /// ⚠️ WARNING: This assumes existing secrets are plaintext!
        /// </summary>
        public async Task MigrateExistingSecretsAsync()
        {
            var usersWithTotp = await _context.Users
                .Where(u => u.IsTotpEnabled && !string.IsNullOrEmpty(u.TotpSecretKey))
                .ToListAsync();

            if (!usersWithTotp.Any())
            {
                Console.WriteLine("No users with TOTP enabled found.");
                return;
            }

            Console.WriteLine($"Found {usersWithTotp.Count} users with TOTP enabled.");
            Console.WriteLine("Encrypting TOTP secrets...");

            int successCount = 0;
            int errorCount = 0;

            foreach (var user in usersWithTotp)
            {
                try
                {
                    // Check if secret is already encrypted by trying to decrypt
                    try
                    {
                        _encryptionService.Decrypt(user.TotpSecretKey!);
                        Console.WriteLine($"User {user.Email} - Secret already encrypted, skipping.");
                        continue;
                    }
                    catch
                    {
                        // Secret is plaintext, proceed with encryption
                    }

                    // Encrypt the plaintext secret
                    var plaintextSecret = user.TotpSecretKey;
                    user.TotpSecretKey = _encryptionService.Encrypt(plaintextSecret!);

                    successCount++;
                    Console.WriteLine($"User {user.Email} - Secret encrypted successfully.");
                }
                catch (Exception ex)
                {
                    errorCount++;
                    Console.WriteLine($"User {user.Email} - ERROR: {ex.Message}");
                }
            }

            // Save all changes
            await _context.SaveChangesAsync();

            Console.WriteLine("\n=== Migration Complete ===");
            Console.WriteLine($"Success: {successCount}");
            Console.WriteLine($"Errors: {errorCount}");
            Console.WriteLine($"Total: {usersWithTotp.Count}");
        }

        /// <summary>
        /// Force all users to re-setup TOTP (safest option)
        /// </summary>
        public async Task ResetAllTotpAsync()
        {
            var usersWithTotp = await _context.Users
                .Where(u => u.IsTotpEnabled)
                .ToListAsync();

            foreach (var user in usersWithTotp)
            {
                user.IsTotpEnabled = false;
                user.TotpSecretKey = null;
            }

            await _context.SaveChangesAsync();

            Console.WriteLine($"Reset TOTP for {usersWithTotp.Count} users.");
            Console.WriteLine("Users will need to re-enable TOTP with the new encryption.");
        }
    }
}

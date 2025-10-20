using System.Security.Cryptography;
using System.Text;

namespace BE1.Services
{
    /// <summary>
    /// AES-256 encryption service for sensitive data like TOTP secrets
    /// </summary>
    public class EncryptionService : IEncryptionService
    {
        private readonly byte[] _key;
        private readonly byte[] _iv;

        public EncryptionService(IConfiguration configuration)
        {
            // Get encryption key and IV from configuration
            var keyString = configuration["Encryption:Key"] 
                ?? throw new ArgumentNullException("Encryption:Key not configured");
            var ivString = configuration["Encryption:IV"] 
                ?? throw new ArgumentNullException("Encryption:IV not configured");

            // Convert to bytes (must be 32 bytes for AES-256 key, 16 bytes for IV)
            _key = Convert.FromBase64String(keyString);
            _iv = Convert.FromBase64String(ivString);

            // Validate key and IV lengths
            if (_key.Length != 32)
                throw new ArgumentException("Encryption key must be 32 bytes (256 bits) for AES-256");
            if (_iv.Length != 16)
                throw new ArgumentException("Encryption IV must be 16 bytes (128 bits)");
        }

        /// <summary>
        /// Encrypt plaintext using AES-256-CBC
        /// </summary>
        public string Encrypt(string plainText)
        {
            if (string.IsNullOrEmpty(plainText))
                return plainText;

            try
            {
                using var aes = Aes.Create();
                aes.Key = _key;
                aes.IV = _iv;
                aes.Mode = CipherMode.CBC;
                aes.Padding = PaddingMode.PKCS7;

                var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

                using var msEncrypt = new MemoryStream();
                using (var csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
                using (var swEncrypt = new StreamWriter(csEncrypt))
                {
                    swEncrypt.Write(plainText);
                }

                var encrypted = msEncrypt.ToArray();
                return Convert.ToBase64String(encrypted);
            }
            catch (Exception ex)
            {
                throw new CryptographicException("Failed to encrypt data", ex);
            }
        }

        /// <summary>
        /// Decrypt ciphertext using AES-256-CBC
        /// </summary>
        public string Decrypt(string cipherText)
        {
            if (string.IsNullOrEmpty(cipherText))
                return cipherText;

            try
            {
                var buffer = Convert.FromBase64String(cipherText);

                using var aes = Aes.Create();
                aes.Key = _key;
                aes.IV = _iv;
                aes.Mode = CipherMode.CBC;
                aes.Padding = PaddingMode.PKCS7;

                var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);

                using var msDecrypt = new MemoryStream(buffer);
                using var csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read);
                using var srDecrypt = new StreamReader(csDecrypt);

                return srDecrypt.ReadToEnd();
            }
            catch (Exception ex)
            {
                throw new CryptographicException("Failed to decrypt data", ex);
            }
        }
    }
}

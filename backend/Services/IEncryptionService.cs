namespace BE1.Services
{
    /// <summary>
    /// Interface for encryption/decryption operations
    /// </summary>
    public interface IEncryptionService
    {
        /// <summary>
        /// Encrypt plaintext string to Base64 encoded ciphertext
        /// </summary>
        string Encrypt(string plainText);

        /// <summary>
        /// Decrypt Base64 encoded ciphertext to plaintext string
        /// </summary>
        string Decrypt(string cipherText);
    }
}

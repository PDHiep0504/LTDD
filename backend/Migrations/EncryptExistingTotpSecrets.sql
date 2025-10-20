-- Migration script to encrypt existing TOTP secrets
-- Run this AFTER deploying the new code with encryption

-- ⚠️ WARNING: Backup database before running this script!
-- This script will encrypt all existing TotpSecretKey values

USE [Db_BE1];
GO

-- Step 1: Check if there are any users with TOTP enabled
SELECT 
    Id,
    Email,
    IsTotpEnabled,
    CASE 
        WHEN TotpSecretKey IS NOT NULL THEN 'HAS_SECRET'
        ELSE 'NO_SECRET'
    END AS SecretStatus
FROM AspNetUsers
WHERE IsTotpEnabled = 1;

-- Step 2: Users will need to re-enable TOTP after this migration
-- because we cannot decrypt the old plaintext secrets with the new encryption key

-- Option 1: Force all users to re-setup TOTP
UPDATE AspNetUsers
SET 
    IsTotpEnabled = 0,
    TotpSecretKey = NULL
WHERE IsTotpEnabled = 1;

PRINT 'All users have been reset. They will need to re-enable TOTP.';

-- Option 2: If you want to keep existing users, you'll need to:
-- 1. Read old plaintext TotpSecretKey
-- 2. Encrypt it using C# EncryptionService
-- 3. Update the record
-- This cannot be done in SQL alone - use a C# migration script instead

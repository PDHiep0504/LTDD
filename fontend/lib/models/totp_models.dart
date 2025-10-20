class TotpSetupResponse {
  final String secretKey;
  final String qrCodeImageUrl; // Base64 image (optional)
  final String qrCodeData; // otpauth:// URL
  final String manualEntryKey;

  const TotpSetupResponse({
    required this.secretKey,
    required this.qrCodeImageUrl,
    required this.qrCodeData,
    required this.manualEntryKey,
  });

  factory TotpSetupResponse.fromJson(Map<String, dynamic> json) {
    return TotpSetupResponse(
      secretKey: json['secretKey'] as String,
      qrCodeImageUrl: json['qrCodeImageUrl'] as String,
      qrCodeData: json['qrCodeData'] as String,
      manualEntryKey: json['manualEntryKey'] as String,
    );
  }
}

class TotpVerifyRequest {
  final String code;

  const TotpVerifyRequest({required this.code});

  Map<String, dynamic> toJson() {
    return {'code': code};
  }
}

class TotpVerifyResponse {
  final bool success;
  final String message;

  const TotpVerifyResponse({required this.success, required this.message});

  factory TotpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return TotpVerifyResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}

class TotpDisableRequest {
  final String password;

  const TotpDisableRequest({required this.password});

  Map<String, dynamic> toJson() {
    return {'password': password};
  }
}

class LoginWithTotpRequest {
  final String email;
  final String password;
  final String? totpCode;

  const LoginWithTotpRequest({
    required this.email,
    required this.password,
    this.totpCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (totpCode != null) 'totpCode': totpCode,
    };
  }
}

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final List<String> roles;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'fullName': fullName, 'roles': roles};
  }

  bool hasRole(String role) => roles.contains(role);
  bool get isAdmin => hasRole('Admin');
  bool get isManager => hasRole('Manager');
  bool get isUser => hasRole('User');
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String? userName;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.userName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (userName != null) 'userName': userName,
    };
  }
}

class AuthResponse {
  final String token;
  final String refreshToken;
  final AuthUser user;
  final DateTime expiration;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.expiration,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      expiration: DateTime.parse(json['expiration'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user.toJson(),
      'expiration': expiration.toIso8601String(),
    };
  }
}

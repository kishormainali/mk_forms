/// Model representing user authentication credentials.
class AuthCredentials {
  const AuthCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

/// Result of an authentication request.
class AuthResult {
  const AuthResult({
    required this.token,
    required this.userId,
    required this.email,
  });

  final String token;
  final String userId;
  final String email;
}

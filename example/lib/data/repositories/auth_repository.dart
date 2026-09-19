import 'package:injectable/injectable.dart';
import '../client/api_client.dart';
import '../models/auth_credentials.dart';

/// Repository interface for authentication operations.
abstract class AuthRepository {
  Future<AuthResult> login(AuthCredentials credentials);
}

/// Implementation of [AuthRepository] interacting directly with [ApiClient].
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthResult> login(AuthCredentials credentials) async {
    final response = await _client.login(
      credentials.email,
      credentials.password,
    );
    return AuthResult(
      token: response['token'] as String,
      userId: response['userId'] as String,
      email: response['email'] as String,
    );
  }
}

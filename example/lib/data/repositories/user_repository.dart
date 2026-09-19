import 'package:injectable/injectable.dart';
import '../client/api_client.dart';
import '../models/user_profile.dart';

/// Repository interface for user operations.
abstract class UserRepository {
  Future<bool> isUsernameAvailable(String username);
  Future<Map<String, dynamic>> registerUser(UserProfile profile);
}

/// Implementation of [UserRepository] interacting directly with [ApiClient].
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<bool> isUsernameAvailable(String username) {
    return _client.checkUsernameAvailability(username);
  }

  @override
  Future<Map<String, dynamic>> registerUser(UserProfile profile) {
    return _client.registerUser(profile.name, profile.password);
  }
}

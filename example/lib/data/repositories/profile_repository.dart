import 'package:injectable/injectable.dart';
import '../client/api_client.dart';

/// Repository for the profile form's independent API calls.
abstract class ProfileRepository {
  Future<bool> isUsernameAvailable(String username);
  Future<String> uploadAvatar(String fileName);
  Future<void> sendOtp(String phone);
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile);
}

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<bool> isUsernameAvailable(String username) =>
      _client.checkUsernameAvailability(username);

  @override
  Future<String> uploadAvatar(String fileName) =>
      _client.uploadAvatar(fileName);

  @override
  Future<void> sendOtp(String phone) => _client.sendOtp(phone);

  @override
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) =>
      _client.saveProfile(profile);
}

import 'package:mk_forms_example/data/repositories/profile_repository.dart';

/// A [ProfileRepository] whose calls are plain overridable closures, so a test
/// decides per call whether it succeeds, fails, or waits on a completer.
class FakeProfileRepository implements ProfileRepository {
  Future<bool> Function(String username) onIsUsernameAvailable = (_) async =>
      true;
  Future<String> Function(String fileName) onUploadAvatar = (fileName) async =>
      'https://cdn.test/$fileName';
  Future<void> Function(String phone) onSendOtp = (_) async {};
  Future<Map<String, dynamic>> Function(Map<String, dynamic> profile)
  onSaveProfile = (profile) async => {'id': 'p1', ...profile};

  @override
  Future<bool> isUsernameAvailable(String username) =>
      onIsUsernameAvailable(username);

  @override
  Future<String> uploadAvatar(String fileName) => onUploadAvatar(fileName);

  @override
  Future<void> sendOtp(String phone) => onSendOtp(phone);

  @override
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) =>
      onSaveProfile(profile);
}

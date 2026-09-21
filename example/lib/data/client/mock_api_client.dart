import 'dart:async';
import 'package:injectable/injectable.dart';
import 'api_client.dart';

/// Mock implementation of [ApiClient] simulating backend latency and network responses.
@LazySingleton(as: ApiClient)
class MockApiClient implements ApiClient {
  static final Set<String> _takenUsernames = {
    'admin',
    'flutter',
    'mk7',
    'google',
    'john',
  };

  // Simulated server draft store for onboarding
  static Map<String, dynamic> _onboardingDraft = {
    'username': 'john_developer',
    'email': 'john.dev@example.com',
    'password': 'secretPassword123',
    'fullName': 'John Developer',
    'role': 'developer',
    'step': 1,
  };

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (email == 'fail@example.com') {
      throw Exception('Invalid email or password');
    }

    return {
      'token': 'jwt_mock_token_xyz',
      'userId': 'usr_9876',
      'email': email,
    };
  }

  @override
  Future<bool> checkUsernameAvailability(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return !_takenUsernames.contains(username.trim().toLowerCase());
  }

  @override
  Future<Map<String, dynamic>> registerUser(
    String name,
    String password,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (name.toLowerCase() == 'admin') {
      throw Exception('The name "admin" is reserved by system');
    }

    return {
      'status': 'success',
      'registeredAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> fetchOnboardingDraft() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return Map<String, dynamic>.from(_onboardingDraft);
  }

  @override
  Future<Map<String, dynamic>> fetchOnboardingInvalidDraft() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // Server returns step 1 (Profile) or step 2 (Preferences),
    // but Step 0 has an invalid email and empty username!
    return {
      'username': 'ab', // Invalid: minimum length is 3
      'email': 'invalid-email-address', // Invalid: invalid email pattern
      'password': 'validPassword123',
      'fullName': 'Jane Incomplete',
      'role': 'designer',
      'bio': 'Designer with invalid account draft',
      'step': 1, // Target was step 1, but step 0 is invalid!
    };
  }

  @override
  Future<void> saveOnboardingData(Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _onboardingDraft = Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>> submitCheckoutOrder(
    Map<String, dynamic> orderPayload,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return {
      'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'confirmed',
    };
  }

  @override
  Future<String> uploadAvatar(String fileName) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (fileName.contains('fail')) {
      throw Exception('Upload failed: file rejected by server');
    }
    return 'https://example.com/avatars/$fileName';
  }

  @override
  Future<void> sendOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return {'id': 'profile-1', ...profile};
  }
}

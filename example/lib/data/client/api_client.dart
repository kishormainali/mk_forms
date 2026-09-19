/// Abstract API client contract for network operations across repositories.
abstract class ApiClient {
  /// Authenticates user credentials.
  Future<Map<String, dynamic>> login(String email, String password);

  /// Verifies if a given username is available.
  Future<bool> checkUsernameAvailability(String username);

  /// Registers a new user.
  Future<Map<String, dynamic>> registerUser(String name, String password);

  /// Fetches saved onboarding draft state from backend.
  Future<Map<String, dynamic>> fetchOnboardingDraft();

  /// Fetches an onboarding draft that has validation errors in a prior step.
  Future<Map<String, dynamic>> fetchOnboardingInvalidDraft();

  /// Persists onboarding draft or completed data.
  Future<void> saveOnboardingData(Map<String, dynamic> data);

  /// Submits an order payload for checkout.
  Future<Map<String, dynamic>> submitCheckoutOrder(
    Map<String, dynamic> orderPayload,
  );
}

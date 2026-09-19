/// Complete payload for multi-step onboarding flow.
class OnboardingData {
  const OnboardingData({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.bio,
    this.interests = const [],
    this.notificationEmails = true,
    this.agreeTerms = false,
    this.currentStep = 0,
  });

  final String username;
  final String email;
  final String password;
  final String fullName;
  final String role;
  final String? bio;
  final List<String> interests;
  final bool notificationEmails;
  final bool agreeTerms;
  final int currentStep;

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'fullName': fullName,
    'role': role,
    'bio': bio,
    'interests': interests,
    'notificationEmails': notificationEmails,
    'agreeTerms': agreeTerms,
    'step': currentStep,
  };

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'developer',
      bio: json['bio'] as String?,
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? const [],
      notificationEmails: json['notificationEmails'] as bool? ?? true,
      agreeTerms: json['agreeTerms'] as bool? ?? false,
      currentStep: json['step'] as int? ?? 0,
    );
  }
}

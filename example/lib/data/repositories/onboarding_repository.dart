import 'package:injectable/injectable.dart';
import '../client/api_client.dart';
import '../models/onboarding_data.dart';

/// Repository interface for multi-step onboarding operations and draft persistence.
abstract class OnboardingRepository {
  Future<OnboardingData> fetchDraft();
  Future<OnboardingData> fetchInvalidDraft();
  Future<void> saveProgress(OnboardingData data);
}

/// Implementation of [OnboardingRepository] interacting directly with [ApiClient].
@LazySingleton(as: OnboardingRepository)
class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<OnboardingData> fetchDraft() async {
    final json = await _client.fetchOnboardingDraft();
    return OnboardingData.fromJson(json);
  }

  @override
  Future<OnboardingData> fetchInvalidDraft() async {
    final json = await _client.fetchOnboardingInvalidDraft();
    return OnboardingData.fromJson(json);
  }

  @override
  Future<void> saveProgress(OnboardingData data) {
    return _client.saveOnboardingData(data.toJson());
  }
}

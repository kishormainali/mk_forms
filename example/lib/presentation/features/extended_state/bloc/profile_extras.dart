import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mk_forms/mk_forms.dart';

part 'profile_extras.freezed.dart';

/// Everything the profile form tracks beyond the base [MkFormState]: one status
/// per independent API call, and the data those calls produce.
///
/// Statuses answer "how did the call go?" (idle / submitting / success /
/// failure); the other fields hold "what did it give us?", so the UI reads
/// plain values instead of unpacking a status `response`.
///
/// This class is generated with freezed: adding a field is one line here, and
/// `copyWith` (including setting a nullable field back to null), `==` and
/// `toString` come for free. It sits in a single `extras` field of
/// `ProfileFormState` because freezed cannot generate a subclass of
/// `MkFormState` itself.
@freezed
abstract class ProfileExtras with _$ProfileExtras {
  const ProfileExtras._();

  const factory ProfileExtras({
    /// Avatar upload.
    @Default(MkSubmissionStatus.idle()) MkSubmissionStatus avatarStatus,

    /// Username availability check.
    @Default(MkSubmissionStatus.idle()) MkSubmissionStatus usernameStatus,

    /// OTP request.
    @Default(MkSubmissionStatus.idle()) MkSubmissionStatus otpStatus,

    /// URL of the uploaded avatar; null until an upload succeeds.
    String? avatarUrl,

    /// The username the last finished availability check was run for.
    String? checkedUsername,

    /// The result of that check (`true` = available).
    bool? usernameAvailable,

    /// The phone number the one-time code was sent to.
    String? otpSentTo,

    /// Human-readable step of the multi-call submit that is running now.
    String? submitStage,
  }) = _ProfileExtras;

  /// Whether any of the side calls is still running.
  bool get isBusy =>
      avatarStatus.isSubmitting ||
      usernameStatus.isSubmitting ||
      otpStatus.isSubmitting;
}

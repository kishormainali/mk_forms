import 'package:equatable/equatable.dart';

/// Represents the form submission lifecycle status.
sealed class MkSubmissionStatus with Equatable {
  const MkSubmissionStatus();

  /// Form is idle (no submission in progress).
  const factory MkSubmissionStatus.idle() = MkSubmissionIdle;

  /// Form is actively submitting.
  const factory MkSubmissionStatus.submitting() = MkSubmissionInProgress;

  /// Form submission succeeded.
  const factory MkSubmissionStatus.success([Object? response]) =
      MkSubmissionSuccess;

  /// Form submission failed with an error.
  const factory MkSubmissionStatus.failure(Object error) = MkSubmissionFailure;

  bool get isIdle => this is MkSubmissionIdle;
  bool get isSubmitting => this is MkSubmissionInProgress;
  bool get isSuccess => this is MkSubmissionSuccess;
  bool get isFailure => this is MkSubmissionFailure;
}

class MkSubmissionIdle extends MkSubmissionStatus {
  const MkSubmissionIdle();

  @override
  List<Object?> get props => [];
}

class MkSubmissionInProgress extends MkSubmissionStatus {
  const MkSubmissionInProgress();

  @override
  List<Object?> get props => [];
}

class MkSubmissionSuccess extends MkSubmissionStatus {
  const MkSubmissionSuccess([this.response]);

  final Object? response;

  @override
  List<Object?> get props => [response];
}

class MkSubmissionFailure extends MkSubmissionStatus {
  const MkSubmissionFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

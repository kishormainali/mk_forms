import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

/// Minimal extra payload proving `MkStepFormBloc<T>` composes step tracking
/// with typed extras without any hand-written state subclass.
class _OnboardingExtra {
  const _OnboardingExtra({
    this.welcomeEmailStatus = const MkSubmissionStatus.idle(),
  });

  final MkSubmissionStatus welcomeEmailStatus;

  _OnboardingExtra copyWith({MkSubmissionStatus? welcomeEmailStatus}) {
    return _OnboardingExtra(
      welcomeEmailStatus: welcomeEmailStatus ?? this.welcomeEmailStatus,
    );
  }
}

class _OnboardingBloc extends MkStepFormBloc<_OnboardingExtra> {
  _OnboardingBloc()
    : super(
        controls: {
          'username': MkFieldBloc<String>(
            initialValue: '',
            validators: [MkValidators.required()],
          ),
          'email': MkFieldBloc<String>(initialValue: ''),
        },
        steps: const [
          MkFormStep(controlNames: ['username']),
          MkFormStep(controlNames: ['email']),
        ],
        initialExtra: () => const _OnboardingExtra(),
        extraReset: () => const _OnboardingExtra(),
        isExtraBusy: (e) => e.welcomeEmailStatus.isSubmitting,
      );

  Future<void> sendWelcomeEmail() async {
    emit(
      state.updateExtra(
        (e) => e.copyWith(
          welcomeEmailStatus: const MkSubmissionStatus.submitting(),
        ),
      ),
    );
    emit(
      state.updateExtra(
        (e) =>
            e.copyWith(welcomeEmailStatus: const MkSubmissionStatus.success()),
      ),
    );
  }

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => 'ok';
}

void main() {
  group('MkStepFormBloc<T> with typed extras', () {
    test('extra and step fields coexist and update independently', () async {
      final bloc = _OnboardingBloc();
      addTearDown(bloc.close);

      expect(bloc.state.extra.welcomeEmailStatus.isIdle, isTrue);
      expect(bloc.currentStep, 0);

      bloc.field<String>('username')!.changeValue('ada');
      expect(await bloc.nextStep(), isTrue);
      expect(bloc.currentStep, 1);
      // Step advanced; extra untouched by the control edit and step move.
      expect(bloc.state.extra.welcomeEmailStatus.isIdle, isTrue);

      await bloc.sendWelcomeEmail();
      expect(bloc.state.extra.welcomeEmailStatus.isSuccess, isTrue);
      // Updating extra did not disturb step-tracking fields.
      expect(bloc.currentStep, 1);
      expect(bloc.state.completedSteps.contains(0), isTrue);

      bloc.reset();
      expect(bloc.currentStep, 0);
      expect(bloc.state.completedSteps, isEmpty);
      expect(bloc.state.extra.welcomeEmailStatus.isIdle, isTrue);
    });
  });
}

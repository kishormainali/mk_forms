import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms_example/presentation/features/extended_state/bloc/profile_form_bloc.dart';
import 'support/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;
  late ProfileFormBloc bloc;

  void fill({
    String displayName = 'Ada',
    String username = 'ada',
    String phone = '555',
  }) {
    bloc.field<String>('displayName')!.changeValue(displayName);
    bloc.field<String>('username')!.changeValue(username);
    bloc.field<String>('phone')!.changeValue(phone);
  }

  setUp(() {
    repository = FakeProfileRepository();
    bloc = ProfileFormBloc(repository);
    addTearDown(bloc.close);
  });

  group('avatar', () {
    test('a successful upload stores avatarUrl', () async {
      expect(bloc.state.extras.avatarUrl, isNull);

      await bloc.uploadAvatar('me.png');

      expect(bloc.state.extras.avatarStatus.isSuccess, isTrue);
      expect(bloc.state.extras.avatarUrl, 'https://cdn.test/me.png');
    });

    test('a failed upload clears a previously stored avatarUrl', () async {
      await bloc.uploadAvatar('me.png');
      repository.onUploadAvatar = (_) async => throw Exception('rejected');

      await bloc.uploadAvatar('bad.png');

      expect(bloc.state.extras.avatarStatus.isFailure, isTrue);
      expect(bloc.state.extras.avatarUrl, isNull);
    });
  });

  group('username check', () {
    test('records which username was checked and the verdict', () async {
      fill(username: 'ada');
      repository.onIsUsernameAvailable = (_) async => false;

      await bloc.checkUsername();

      expect(bloc.state.extras.checkedUsername, 'ada');
      expect(bloc.state.extras.usernameAvailable, isFalse);
      expect(bloc.state.usernameVerdict, isFalse);
      expect(bloc.state.shownUsernameStatus.isSuccess, isTrue);
    });

    test('the verdict is hidden once the username is edited', () async {
      fill(username: 'ada');
      await bloc.checkUsername();
      expect(bloc.state.usernameVerdict, isTrue);

      bloc.field<String>('username')!.changeValue('ada2');

      expect(bloc.state.usernameVerdict, isNull);
      expect(bloc.state.shownUsernameStatus.isIdle, isTrue);
      // The finished check itself is untouched: only its display is gated.
      expect(bloc.state.extras.checkedUsername, 'ada');
    });

    test(
      'a check that finishes after the username changed is not shown',
      () async {
        fill(username: 'ada');
        final call = Completer<bool>();
        repository.onIsUsernameAvailable = (_) => call.future;

        final pending = bloc.checkUsername();
        expect(bloc.state.isBusy, isTrue);
        bloc.field<String>('username')!.changeValue('grace');
        call.complete(true);
        await pending;

        expect(bloc.state.isBusy, isFalse);
        expect(bloc.state.extras.checkedUsername, 'ada');
        expect(bloc.state.usernameVerdict, isNull);
        expect(bloc.state.shownUsernameStatus.isIdle, isTrue);
      },
    );

    test('a failed check clears the recorded verdict', () async {
      fill(username: 'ada');
      await bloc.checkUsername();
      repository.onIsUsernameAvailable = (_) async => throw Exception('down');

      await bloc.checkUsername();

      expect(bloc.state.extras.usernameStatus.isFailure, isTrue);
      expect(bloc.state.extras.checkedUsername, isNull);
      expect(bloc.state.extras.usernameAvailable, isNull);
    });
  });

  group('otp', () {
    test('records the number the code was sent to (trimmed)', () async {
      fill(phone: '  555 0100 ');

      await bloc.sendOtp();

      expect(bloc.state.extras.otpStatus.isSuccess, isTrue);
      expect(bloc.state.extras.otpSentTo, '555 0100');
    });

    test('a failed send clears otpSentTo', () async {
      fill(phone: '555');
      await bloc.sendOtp();
      repository.onSendOtp = (_) async => throw Exception('sms down');

      await bloc.sendOtp();

      expect(bloc.state.extras.otpStatus.isFailure, isTrue);
      expect(bloc.state.extras.otpSentTo, isNull);
    });
  });

  group('submit', () {
    test('reports each stage of the two-call submit, then clears it', () async {
      fill();
      await bloc.uploadAvatar('me.png');
      final availability = Completer<bool>();
      final save = Completer<Map<String, dynamic>>();
      Map<String, dynamic>? saved;
      repository.onIsUsernameAvailable = (_) => availability.future;
      repository.onSaveProfile = (profile) {
        saved = profile;
        return save.future;
      };

      final submitting = bloc.submit();
      await pumpEventQueue();
      expect(bloc.state.extras.submitStage, 'Checking username…');
      expect(bloc.state.isSubmitting, isTrue);

      availability.complete(true);
      await pumpEventQueue();
      expect(bloc.state.extras.submitStage, 'Saving profile…');

      save.complete({'id': 'p1'});
      await submitting;

      expect(bloc.state.isSuccess, isTrue);
      expect(bloc.state.extras.submitStage, isNull);
      expect(saved!['avatarUrl'], 'https://cdn.test/me.png');
    });

    test('a taken username fails the submit and clears the stage', () async {
      fill();
      repository.onIsUsernameAvailable = (_) async => false;

      await bloc.submit();

      expect(bloc.state.isFailure, isTrue);
      expect(bloc.state.extras.submitStage, isNull);
    });
  });

  test('reset returns every extra field and status to its default', () async {
    fill();
    await bloc.uploadAvatar('me.png');
    await bloc.checkUsername();
    await bloc.sendOtp();
    expect(bloc.state.extras.avatarUrl, isNotNull);
    expect(bloc.state.extras.checkedUsername, isNotNull);
    expect(bloc.state.extras.otpSentTo, isNotNull);

    bloc.reset();

    expect(bloc.state.extras.avatarUrl, isNull);
    expect(bloc.state.extras.checkedUsername, isNull);
    expect(bloc.state.extras.usernameAvailable, isNull);
    expect(bloc.state.extras.otpSentTo, isNull);
    expect(bloc.state.extras.submitStage, isNull);
    expect(bloc.state.extras.avatarStatus.isIdle, isTrue);
    expect(bloc.state.extras.usernameStatus.isIdle, isTrue);
    expect(bloc.state.extras.otpStatus.isIdle, isTrue);
  });
}

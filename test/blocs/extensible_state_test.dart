import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../support/profile_form.dart';

void main() {
  group('MkFormState<T> extras', () {
    test('reset preserves the extra type and resets custom fields', () {
      final bloc = ProfileBloc(avatarUpload: Completer<void>());
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);

      bloc.reset();

      expect(bloc.state.extra.avatarStatus.isIdle, isTrue);
      expect(bloc.state.extra.otpStatus.isIdle, isTrue);
      expect(bloc.state.submissionStatus.isIdle, isTrue);
    });

    test('a busy extra blocks canSubmit and submit()', () async {
      final upload = Completer<void>();
      final bloc = ProfileBloc(avatarUpload: upload);
      addTearDown(bloc.close);
      bloc.field<String>('name')!.changeValue('Ada');
      expect(bloc.state.canSubmit, isTrue);

      unawaited(bloc.uploadAvatar());
      expect(bloc.state.isBusy, isTrue);
      expect(bloc.state.canSubmit, isFalse);

      await bloc.submit();
      expect(bloc.submitCalls, 0);

      upload.complete();
      await pumpEventQueue();
      expect(bloc.state.isBusy, isFalse);
      expect(bloc.state.canSubmit, isTrue);

      await bloc.submit();
      expect(bloc.submitCalls, 1);
      expect(bloc.state.isSuccess, isTrue);
    });

    test('concurrent calls report independent statuses', () async {
      final upload = Completer<void>();
      final otp = Completer<void>();
      final bloc = ProfileBloc(avatarUpload: upload, otpSend: otp);
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      unawaited(bloc.sendOtp());
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.extra.otpStatus.isSubmitting, isTrue);

      otp.complete();
      await pumpEventQueue();
      expect(bloc.state.extra.otpStatus.isSuccess, isTrue);
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.isBusy, isTrue);

      upload.completeError(Exception('upload failed'));
      await pumpEventQueue();
      expect(bloc.state.extra.avatarStatus.isFailure, isTrue);
      expect(bloc.state.extra.otpStatus.isSuccess, isTrue);
      expect(bloc.state.isBusy, isFalse);
    });

    test('a control edit leaves extra reference-identical', () {
      final bloc = ProfileBloc(avatarUpload: Completer<void>());
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      final extraBeforeEdit = bloc.state.extra;

      bloc.field<String>('name')!.changeValue('Ada');

      expect(identical(bloc.state.extra, extraBeforeEdit), isTrue);
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.values['name'], 'Ada');
    });
  });
}

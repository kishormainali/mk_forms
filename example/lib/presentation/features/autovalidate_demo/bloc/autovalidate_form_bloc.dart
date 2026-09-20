import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';

/// Form BLoC designed to demonstrate how [AutovalidateMode] impacts error visibility.
@injectable
class AutovalidateFormBloc extends MkFormBloc {
  AutovalidateFormBloc()
    : super(
        controls: {
          'username': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Username is required'),
              MkValidators.minLength(
                4,
                'Username must be at least 4 characters',
              ),
            ],
          ),
          'email': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Email is required'),
              MkValidators.email('Please enter a valid email address'),
            ],
          ),
          'bio': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Bio is required'),
              MkValidators.minLength(10, 'Bio must be at least 10 characters'),
            ],
          ),
          'agreeTerms': MkFieldBloc<bool>(
            initialValue: false,
            validators: [
              MkValidators.required('You must accept the terms of service'),
            ],
          ),
        },
      );

  /// Fills valid dummy data into all fields.
  void fillValidData() {
    field<String>('username')?.changeValue('alex_dev');
    field<String>('email')?.changeValue('alex@example.com');
    field<String>('bio')?.changeValue(
      'Full-stack Flutter developer passionate about clean forms.',
    );
    field<bool>('agreeTerms')?.changeValue(true);
  }

  /// Resets all fields to their initial untouched states.
  void resetForm() {
    reset();
  }

  @override
  Future<Map<String, dynamic>> onSubmit(Map<String, dynamic> values) async {
    // Simulate network submission latency
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return values;
  }
}

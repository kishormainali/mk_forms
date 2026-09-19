import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';

/// Form BLoC managing custom design system form fields (billing cycle and interests).
@injectable
class CustomDesignFormBloc extends MkFormBloc {
  CustomDesignFormBloc()
      : super(
          controls: {
            'billingCycle': MkFieldBloc<String>(
              initialValue: 'annual',
              validators: [
                MkValidators.required('Please select a billing cycle')
              ],
            ),
            'interests': MkFieldBloc<List<String>>(
              initialValue: ['Mobile', 'Design'],
              validators: [
                MkValidators.required('Select at least one interest')
              ],
            ),
          },
        );

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {}
}

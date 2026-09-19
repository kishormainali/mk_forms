import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import 'bloc/onboarding_form_bloc.dart';
import 'routes/account_step_route.dart';

/// Entry screen launching the multi-route onboarding flow.
///
/// Keeps the [OnboardingFormBloc] alive while navigating across routes.
@RoutePage()
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final OnboardingFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = getIt<OnboardingFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccountStepScreen(formBloc: _formBloc);
  }
}

/// Backwards compatibility alias.
typedef OnboardingFlow = OnboardingFlowScreen;

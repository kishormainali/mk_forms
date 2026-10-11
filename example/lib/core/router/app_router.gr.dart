// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i18;
import 'package:flutter/material.dart' as _i19;
import 'package:mk_forms_example/presentation/features/all_fields_showcase/all_fields_screen.dart'
    as _i2;
import 'package:mk_forms_example/presentation/features/all_fields_showcase/bloc/all_fields_form_bloc.dart'
    as _i21;
import 'package:mk_forms_example/presentation/features/async_validation/bloc/username_form_bloc.dart'
    as _i30;
import 'package:mk_forms_example/presentation/features/async_validation/username_screen.dart'
    as _i17;
import 'package:mk_forms_example/presentation/features/autovalidate_demo/autovalidate_screen.dart'
    as _i3;
import 'package:mk_forms_example/presentation/features/autovalidate_demo/bloc/autovalidate_form_bloc.dart'
    as _i22;
import 'package:mk_forms_example/presentation/features/custom_design_system/bloc/custom_design_form_bloc.dart'
    as _i24;
import 'package:mk_forms_example/presentation/features/custom_design_system/custom_design_screen.dart'
    as _i5;
import 'package:mk_forms_example/presentation/features/dependent_fields/bloc/registration_form_bloc.dart'
    as _i29;
import 'package:mk_forms_example/presentation/features/dependent_fields/registration_screen.dart'
    as _i16;
import 'package:mk_forms_example/presentation/features/dynamic_array/bloc/dynamic_todos_form_bloc.dart'
    as _i25;
import 'package:mk_forms_example/presentation/features/dynamic_array/dynamic_todos_screen.dart'
    as _i6;
import 'package:mk_forms_example/presentation/features/extended_state/bloc/profile_form_bloc.dart'
    as _i26;
import 'package:mk_forms_example/presentation/features/extended_state/extended_state_screen.dart'
    as _i7;
import 'package:mk_forms_example/presentation/features/form_integration/form_integration_screen.dart'
    as _i8;
import 'package:mk_forms_example/presentation/features/i18n_demo/bloc/i18n_demo_form_bloc.dart'
    as _i27;
import 'package:mk_forms_example/presentation/features/i18n_demo/i18n_screen.dart'
    as _i10;
import 'package:mk_forms_example/presentation/features/large_form/large_form_screen.dart'
    as _i11;
import 'package:mk_forms_example/presentation/features/minimal_login/bloc/login_form_bloc.dart'
    as _i28;
import 'package:mk_forms_example/presentation/features/minimal_login/minimal_login_screen.dart'
    as _i12;
import 'package:mk_forms_example/presentation/features/onboarding_flow/bloc/onboarding_form_bloc.dart'
    as _i20;
import 'package:mk_forms_example/presentation/features/onboarding_flow/onboarding_flow.dart'
    as _i13;
import 'package:mk_forms_example/presentation/features/onboarding_flow/routes/account_step_route.dart'
    as _i1;
import 'package:mk_forms_example/presentation/features/onboarding_flow/routes/preferences_step_route.dart'
    as _i14;
import 'package:mk_forms_example/presentation/features/onboarding_flow/routes/profile_step_route.dart'
    as _i15;
import 'package:mk_forms_example/presentation/features/subforms_checkout/bloc/checkout_form_bloc.dart'
    as _i23;
import 'package:mk_forms_example/presentation/features/subforms_checkout/checkout_screen.dart'
    as _i4;
import 'package:mk_forms_example/presentation/screens/home_screen.dart' as _i9;

/// generated route for
/// [_i1.AccountStepScreen]
class AccountStepRoute extends _i18.PageRouteInfo<AccountStepRouteArgs> {
  AccountStepRoute({
    _i19.Key? key,
    required _i20.OnboardingFormBloc formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         AccountStepRoute.name,
         args: AccountStepRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'AccountStepRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AccountStepRouteArgs>();
      return _i1.AccountStepScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class AccountStepRouteArgs {
  const AccountStepRouteArgs({this.key, required this.formBloc});

  final _i19.Key? key;

  final _i20.OnboardingFormBloc formBloc;

  @override
  String toString() {
    return 'AccountStepRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AccountStepRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i2.AllFieldsScreen]
class AllFieldsRoute extends _i18.PageRouteInfo<AllFieldsRouteArgs> {
  AllFieldsRoute({
    _i19.Key? key,
    _i21.AllFieldsFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         AllFieldsRoute.name,
         args: AllFieldsRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'AllFieldsRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AllFieldsRouteArgs>(
        orElse: () => const AllFieldsRouteArgs(),
      );
      return _i2.AllFieldsScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class AllFieldsRouteArgs {
  const AllFieldsRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i21.AllFieldsFormBloc? formBloc;

  @override
  String toString() {
    return 'AllFieldsRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AllFieldsRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i3.AutovalidateScreen]
class AutovalidateRoute extends _i18.PageRouteInfo<AutovalidateRouteArgs> {
  AutovalidateRoute({
    _i19.Key? key,
    _i22.AutovalidateFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         AutovalidateRoute.name,
         args: AutovalidateRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'AutovalidateRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AutovalidateRouteArgs>(
        orElse: () => const AutovalidateRouteArgs(),
      );
      return _i3.AutovalidateScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class AutovalidateRouteArgs {
  const AutovalidateRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i22.AutovalidateFormBloc? formBloc;

  @override
  String toString() {
    return 'AutovalidateRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AutovalidateRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i4.CheckoutScreen]
class CheckoutRoute extends _i18.PageRouteInfo<CheckoutRouteArgs> {
  CheckoutRoute({
    _i19.Key? key,
    _i23.CheckoutFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         CheckoutRoute.name,
         args: CheckoutRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'CheckoutRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CheckoutRouteArgs>(
        orElse: () => const CheckoutRouteArgs(),
      );
      return _i4.CheckoutScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class CheckoutRouteArgs {
  const CheckoutRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i23.CheckoutFormBloc? formBloc;

  @override
  String toString() {
    return 'CheckoutRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CheckoutRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i5.CustomDesignScreen]
class CustomDesignRoute extends _i18.PageRouteInfo<CustomDesignRouteArgs> {
  CustomDesignRoute({
    _i19.Key? key,
    _i24.CustomDesignFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         CustomDesignRoute.name,
         args: CustomDesignRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'CustomDesignRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CustomDesignRouteArgs>(
        orElse: () => const CustomDesignRouteArgs(),
      );
      return _i5.CustomDesignScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class CustomDesignRouteArgs {
  const CustomDesignRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i24.CustomDesignFormBloc? formBloc;

  @override
  String toString() {
    return 'CustomDesignRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomDesignRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i6.DynamicTodosScreen]
class DynamicTodosRoute extends _i18.PageRouteInfo<DynamicTodosRouteArgs> {
  DynamicTodosRoute({
    _i19.Key? key,
    _i25.DynamicTodosFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         DynamicTodosRoute.name,
         args: DynamicTodosRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'DynamicTodosRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DynamicTodosRouteArgs>(
        orElse: () => const DynamicTodosRouteArgs(),
      );
      return _i6.DynamicTodosScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class DynamicTodosRouteArgs {
  const DynamicTodosRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i25.DynamicTodosFormBloc? formBloc;

  @override
  String toString() {
    return 'DynamicTodosRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DynamicTodosRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i7.ExtendedStateScreen]
class ExtendedStateRoute extends _i18.PageRouteInfo<ExtendedStateRouteArgs> {
  ExtendedStateRoute({
    _i19.Key? key,
    _i26.ProfileFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         ExtendedStateRoute.name,
         args: ExtendedStateRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'ExtendedStateRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExtendedStateRouteArgs>(
        orElse: () => const ExtendedStateRouteArgs(),
      );
      return _i7.ExtendedStateScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class ExtendedStateRouteArgs {
  const ExtendedStateRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i26.ProfileFormBloc? formBloc;

  @override
  String toString() {
    return 'ExtendedStateRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExtendedStateRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i8.FormIntegrationScreen]
class FormIntegrationRoute extends _i18.PageRouteInfo<void> {
  const FormIntegrationRoute({List<_i18.PageRouteInfo>? children})
    : super(FormIntegrationRoute.name, initialChildren: children);

  static const String name = 'FormIntegrationRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i8.FormIntegrationScreen();
    },
  );
}

/// generated route for
/// [_i9.HomeScreen]
class HomeRoute extends _i18.PageRouteInfo<void> {
  const HomeRoute({List<_i18.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i9.HomeScreen();
    },
  );
}

/// generated route for
/// [_i10.I18nDemoScreen]
class I18nDemoRoute extends _i18.PageRouteInfo<I18nDemoRouteArgs> {
  I18nDemoRoute({
    _i19.Key? key,
    _i27.I18nDemoFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         I18nDemoRoute.name,
         args: I18nDemoRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'I18nDemoRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<I18nDemoRouteArgs>(
        orElse: () => const I18nDemoRouteArgs(),
      );
      return _i10.I18nDemoScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class I18nDemoRouteArgs {
  const I18nDemoRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i27.I18nDemoFormBloc? formBloc;

  @override
  String toString() {
    return 'I18nDemoRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! I18nDemoRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i11.LargeFormScreen]
class LargeFormRoute extends _i18.PageRouteInfo<void> {
  const LargeFormRoute({List<_i18.PageRouteInfo>? children})
    : super(LargeFormRoute.name, initialChildren: children);

  static const String name = 'LargeFormRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i11.LargeFormScreen();
    },
  );
}

/// generated route for
/// [_i12.MinimalLoginScreen]
class MinimalLoginRoute extends _i18.PageRouteInfo<MinimalLoginRouteArgs> {
  MinimalLoginRoute({
    _i19.Key? key,
    _i28.LoginFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         MinimalLoginRoute.name,
         args: MinimalLoginRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'MinimalLoginRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MinimalLoginRouteArgs>(
        orElse: () => const MinimalLoginRouteArgs(),
      );
      return _i12.MinimalLoginScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class MinimalLoginRouteArgs {
  const MinimalLoginRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i28.LoginFormBloc? formBloc;

  @override
  String toString() {
    return 'MinimalLoginRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MinimalLoginRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i13.OnboardingFlowScreen]
class OnboardingFlowRoute extends _i18.PageRouteInfo<void> {
  const OnboardingFlowRoute({List<_i18.PageRouteInfo>? children})
    : super(OnboardingFlowRoute.name, initialChildren: children);

  static const String name = 'OnboardingFlowRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i13.OnboardingFlowScreen();
    },
  );
}

/// generated route for
/// [_i14.PreferencesStepScreen]
class PreferencesStepRoute
    extends _i18.PageRouteInfo<PreferencesStepRouteArgs> {
  PreferencesStepRoute({
    _i19.Key? key,
    required _i20.OnboardingFormBloc formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         PreferencesStepRoute.name,
         args: PreferencesStepRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'PreferencesStepRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PreferencesStepRouteArgs>();
      return _i14.PreferencesStepScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class PreferencesStepRouteArgs {
  const PreferencesStepRouteArgs({this.key, required this.formBloc});

  final _i19.Key? key;

  final _i20.OnboardingFormBloc formBloc;

  @override
  String toString() {
    return 'PreferencesStepRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PreferencesStepRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i15.ProfileStepScreen]
class ProfileStepRoute extends _i18.PageRouteInfo<ProfileStepRouteArgs> {
  ProfileStepRoute({
    _i19.Key? key,
    required _i20.OnboardingFormBloc formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         ProfileStepRoute.name,
         args: ProfileStepRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'ProfileStepRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProfileStepRouteArgs>();
      return _i15.ProfileStepScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class ProfileStepRouteArgs {
  const ProfileStepRouteArgs({this.key, required this.formBloc});

  final _i19.Key? key;

  final _i20.OnboardingFormBloc formBloc;

  @override
  String toString() {
    return 'ProfileStepRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProfileStepRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i16.RegistrationScreen]
class RegistrationRoute extends _i18.PageRouteInfo<RegistrationRouteArgs> {
  RegistrationRoute({
    _i19.Key? key,
    _i29.RegistrationFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         RegistrationRoute.name,
         args: RegistrationRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'RegistrationRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RegistrationRouteArgs>(
        orElse: () => const RegistrationRouteArgs(),
      );
      return _i16.RegistrationScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class RegistrationRouteArgs {
  const RegistrationRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i29.RegistrationFormBloc? formBloc;

  @override
  String toString() {
    return 'RegistrationRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RegistrationRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

/// generated route for
/// [_i17.UsernameScreen]
class UsernameRoute extends _i18.PageRouteInfo<UsernameRouteArgs> {
  UsernameRoute({
    _i19.Key? key,
    _i30.UsernameFormBloc? formBloc,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         UsernameRoute.name,
         args: UsernameRouteArgs(key: key, formBloc: formBloc),
         initialChildren: children,
       );

  static const String name = 'UsernameRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UsernameRouteArgs>(
        orElse: () => const UsernameRouteArgs(),
      );
      return _i17.UsernameScreen(key: args.key, formBloc: args.formBloc);
    },
  );
}

class UsernameRouteArgs {
  const UsernameRouteArgs({this.key, this.formBloc});

  final _i19.Key? key;

  final _i30.UsernameFormBloc? formBloc;

  @override
  String toString() {
    return 'UsernameRouteArgs{key: $key, formBloc: $formBloc}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UsernameRouteArgs) return false;
    return key == other.key && formBloc == other.formBloc;
  }

  @override
  int get hashCode => key.hashCode ^ formBloc.hashCode;
}

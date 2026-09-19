// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mk_forms_example/core/router/app_router.dart' as _i713;
import 'package:mk_forms_example/data/client/api_client.dart' as _i855;
import 'package:mk_forms_example/data/client/mock_api_client.dart' as _i503;
import 'package:mk_forms_example/data/repositories/auth_repository.dart'
    as _i723;
import 'package:mk_forms_example/data/repositories/checkout_repository.dart'
    as _i994;
import 'package:mk_forms_example/data/repositories/onboarding_repository.dart'
    as _i133;
import 'package:mk_forms_example/data/repositories/task_repository.dart'
    as _i123;
import 'package:mk_forms_example/data/repositories/user_repository.dart'
    as _i874;
import 'package:mk_forms_example/presentation/features/all_fields_showcase/bloc/all_fields_form_bloc.dart'
    as _i591;
import 'package:mk_forms_example/presentation/features/async_validation/bloc/username_form_bloc.dart'
    as _i212;
import 'package:mk_forms_example/presentation/features/autovalidate_demo/bloc/autovalidate_form_bloc.dart'
    as _i975;
import 'package:mk_forms_example/presentation/features/custom_design_system/bloc/custom_design_form_bloc.dart'
    as _i717;
import 'package:mk_forms_example/presentation/features/dependent_fields/bloc/registration_form_bloc.dart'
    as _i0;
import 'package:mk_forms_example/presentation/features/dynamic_array/bloc/dynamic_todos_form_bloc.dart'
    as _i171;
import 'package:mk_forms_example/presentation/features/i18n_demo/bloc/i18n_demo_form_bloc.dart'
    as _i962;
import 'package:mk_forms_example/presentation/features/minimal_login/bloc/login_form_bloc.dart'
    as _i782;
import 'package:mk_forms_example/presentation/features/onboarding_flow/bloc/onboarding_form_bloc.dart'
    as _i951;
import 'package:mk_forms_example/presentation/features/subforms_checkout/bloc/checkout_form_bloc.dart'
    as _i257;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i591.AllFieldsFormBloc>(() => _i591.AllFieldsFormBloc());
    gh.factory<_i975.AutovalidateFormBloc>(() => _i975.AutovalidateFormBloc());
    gh.factory<_i717.CustomDesignFormBloc>(() => _i717.CustomDesignFormBloc());
    gh.factory<_i962.I18nDemoFormBloc>(() => _i962.I18nDemoFormBloc());
    gh.lazySingleton<_i713.AppRouter>(() => _i713.AppRouter());
    gh.lazySingleton<_i855.ApiClient>(() => _i503.MockApiClient());
    gh.lazySingleton<_i123.TaskRepository>(() => _i123.TaskRepositoryImpl());
    gh.lazySingleton<_i994.CheckoutRepository>(
        () => _i994.CheckoutRepositoryImpl(gh<_i855.ApiClient>()));
    gh.lazySingleton<_i133.OnboardingRepository>(
        () => _i133.OnboardingRepositoryImpl(gh<_i855.ApiClient>()));
    gh.lazySingleton<_i874.UserRepository>(
        () => _i874.UserRepositoryImpl(gh<_i855.ApiClient>()));
    gh.lazySingleton<_i723.AuthRepository>(
        () => _i723.AuthRepositoryImpl(gh<_i855.ApiClient>()));
    gh.factory<_i171.DynamicTodosFormBloc>(
        () => _i171.DynamicTodosFormBloc(gh<_i123.TaskRepository>()));
    gh.factory<_i257.CheckoutFormBloc>(
        () => _i257.CheckoutFormBloc(gh<_i994.CheckoutRepository>()));
    gh.factory<_i0.RegistrationFormBloc>(
        () => _i0.RegistrationFormBloc(gh<_i874.UserRepository>()));
    gh.factory<_i212.UsernameFormBloc>(
        () => _i212.UsernameFormBloc(gh<_i874.UserRepository>()));
    gh.factory<_i951.OnboardingFormBloc>(
        () => _i951.OnboardingFormBloc(gh<_i133.OnboardingRepository>()));
    gh.factory<_i782.LoginFormBloc>(
        () => _i782.LoginFormBloc(gh<_i723.AuthRepository>()));
    return this;
  }
}

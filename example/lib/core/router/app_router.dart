import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'app_router.gr.dart';

@lazySingleton
@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: MinimalLoginRoute.page),
        AutoRoute(page: OnboardingFlowRoute.page),
        AutoRoute(page: AccountStepRoute.page),
        AutoRoute(page: ProfileStepRoute.page),
        AutoRoute(page: PreferencesStepRoute.page),
        AutoRoute(page: CheckoutRoute.page),
        AutoRoute(page: RegistrationRoute.page),
        AutoRoute(page: UsernameRoute.page),
        AutoRoute(page: DynamicTodosRoute.page),
        AutoRoute(page: AllFieldsRoute.page),
        AutoRoute(page: I18nDemoRoute.page),
        AutoRoute(page: CustomDesignRoute.page),
        AutoRoute(page: AutovalidateRoute.page),
      ];
}

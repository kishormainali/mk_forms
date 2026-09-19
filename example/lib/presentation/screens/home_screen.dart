import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../core/router/app_router.gr.dart';

/// Navigation dashboard presenting all distinct mk_forms example features.
@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final features = <({
      String title,
      String subtitle,
      IconData icon,
      Color color,
      PageRouteInfo route,
    })>[
      (
        title: 'Minimal Login Form',
        subtitle: 'Lightweight MkSimpleFormBloc, 2-layer repo, pure initial states',
        icon: Icons.login,
        color: Colors.indigo,
        route: MinimalLoginRoute(),
      ),
      (
        title: 'Multi-Route Onboarding Wizard',
        subtitle: 'Multi-step forms, route navigation, API draft hydration & resuming',
        icon: Icons.alt_route,
        color: Colors.deepPurple,
        route: const OnboardingFlowRoute(),
      ),
      (
        title: 'Independent Subforms (Checkout)',
        subtitle: 'Multiple subforms with MkSubformBuilder and isolated group validation',
        icon: Icons.shopping_cart_checkout,
        color: Colors.cyan.shade800,
        route: CheckoutRoute(),
      ),
      (
        title: 'Cross-Field Dependent Validation',
        subtitle: 'Password & Confirm Password reactive bidirectional validation',
        icon: Icons.sync_alt,
        color: Colors.teal,
        route: RegistrationRoute(),
      ),
      (
        title: 'Debounced Async Validation',
        subtitle: 'Asynchronous username availability check with in-flight spinner',
        icon: Icons.timer_outlined,
        color: Colors.deepOrange,
        route: UsernameRoute(),
      ),
      (
        title: 'Dynamic Array Forms',
        subtitle: 'Dynamic list of controls with add, remove, and aggregate validation',
        icon: Icons.dynamic_feed,
        color: Colors.purple,
        route: DynamicTodosRoute(),
      ),
      (
        title: 'All Fields Showcase',
        subtitle: 'Text, Email, Password, Checkbox, Radio, Dropdown, Multi-select search',
        icon: Icons.dashboard_customize_outlined,
        color: Colors.blue,
        route: AllFieldsRoute(),
      ),
      (
        title: 'Internationalization (i18n)',
        subtitle: 'flutter_localizations delegation, dynamic English/Spanish switching',
        icon: Icons.translate,
        color: Colors.green,
        route: I18nDemoRoute(),
      ),
      (
        title: 'Custom Design System',
        subtitle: 'Custom selectable Card radios, custom chips, custom styling',
        icon: Icons.palette_outlined,
        color: Colors.amber.shade800,
        route: CustomDesignRoute(),
      ),
      (
        title: 'Autovalidate Modes',
        subtitle: 'Dynamic switching between onUserInteraction, always, and disabled',
        icon: Icons.fact_check_outlined,
        color: Colors.pink.shade700,
        route: AutovalidateRoute(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('mk_forms Examples'),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: features.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final feature = features[index];
          return Card(
            elevation: 1,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                unawaited(context.router.push(feature.route));
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: feature.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(feature.icon, color: feature.color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

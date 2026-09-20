import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mk_forms/mk_forms.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MkFormsExampleApp());
}

class MkFormsExampleApp extends StatelessWidget {
  const MkFormsExampleApp({super.key, AppRouter? appRouter})
    : _appRouter = appRouter;

  final AppRouter? _appRouter;

  @override
  Widget build(BuildContext context) {
    final router = _appRouter ?? getIt<AppRouter>();

    return MaterialApp.router(
      title: 'mk_forms Example',
      debugShowCheckedModeBanner: false,
      routerConfig: router.config(),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      // Integrate standard flutter_localizations with mk_forms delegates
      localizationsDelegates: const [
        MkFormLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: MkFormLocalizations.supportedLocales,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reagentkit/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/config/get_it_config.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/settings/presentation/states/settings_state.dart';
import 'features/reagent_testing/data/services/remote_config_service.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';
import 'core/globals.dart';
import 'core/services/build_release_check.dart';
import 'core/services/review_runtime_guard.dart';
import 'core/router/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run build configuration and environment assertions
  BuildReleaseCheck.validate();
  ReviewRuntimeGuard.runGuard();

  if (isPremiumReviewMode) {
    Logger.info('[Review Mode] Premium features unlocked.');
  }
  
  // Load environment variables safely
  await dotenv.load(fileName: ".env").catchError((_) {
    // Ignore error if .env file is missing, we fallback to --dart-define or hardcoded
  });

  Object? startupError;
  StackTrace? startupStackTrace;
  var firebaseReady = false;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    firebaseReady = true;
  } catch (e, st) {
    startupError = e;
    startupStackTrace = st;
    Logger.error(
      'Firebase initialization failed',
      error: e,
      stackTrace: st,
    );
  }

  if (firebaseReady) {
    try {
      final remoteConfigService = RemoteConfigService();
      await remoteConfigService.initialize();
      Logger.info('Remote Config initialized successfully in main()');
    } catch (e, st) {
      Logger.error(
        'Remote Config initialization failed in main()',
        error: e,
        stackTrace: st,
      );
    }
  }

  if (!firebaseReady) {
    runApp(
      StartupErrorApp(
        error: startupError,
        stackTrace: startupStackTrace,
      ),
    );
    return;
  }

  try {
    await configureDependencies();
  } catch (e, st) {
    Logger.error(
      'Dependency initialization failed',
      error: e,
      stackTrace: st,
    );
    runApp(
      StartupErrorApp(
        error: e,
        stackTrace: st,
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: ReagentTestingApp()));
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object? error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final message = error?.toString() ?? 'Unknown startup error';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 20),
                const Text(
                  'ReagentKit could not start',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                if (stackTrace != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    stackTrace.toString().split('\n').take(3).join('\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReagentTestingApp extends ConsumerStatefulWidget {
  const ReagentTestingApp({super.key});

  @override
  ConsumerState<ReagentTestingApp> createState() => _ReagentTestingAppState();
}

class _ReagentTestingAppState extends ConsumerState<ReagentTestingApp> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      ref.read(unifiedDataServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final settingsState = ref.watch(settingsControllerProvider);

    // Get theme mode from settings
    ThemeMode themeMode = ThemeMode.system;
    if (settingsState is SettingsLoaded) {
      themeMode = settingsState.settings.themeMode;
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'ReagentKit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localeResolutionCallback: (Locale? deviceLocale, Iterable<Locale> supportedLocales) {
        if (deviceLocale == null) {
          return locale;
        }
        for (final Locale supported in supportedLocales) {
          if (supported.languageCode == deviceLocale.languageCode) {
            return supported;
          }
        }
        return locale;
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,

      debugShowCheckedModeBanner: false,
    );
  }
}

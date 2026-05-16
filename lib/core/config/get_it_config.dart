import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/gemini_image_analysis_service.dart';
import '../../features/reagent_testing/data/services/remote_config_service.dart';
// import 'api_keys.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core Services
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService());

  // AI Services - Gemini API with Remote Config support
  // Register as factory since we need async initialization
  getIt.registerFactoryAsync<GeminiImageAnalysisService>(
    () async => await GeminiImageAnalysisService.createWithRemoteConfig(),
  );

  // TODO: Add other services as we implement them
  // getIt.registerLazySingleton<SharedPreferencesService>(() => SharedPreferencesService());
}

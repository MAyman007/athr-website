import 'package:get_it/get_it.dart';
import 'package:athr/core/services/firebase_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => FirebaseService());
}

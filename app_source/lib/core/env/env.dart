import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'IP_CHECK_BASE_URL')
  static final String ipCheckBaseUrl = _Env.ipCheckBaseUrl;

  @EnviedField(varName: 'IP_CHECK_API_KEY', obfuscate: true)
  static final String ipCheckApiKey = _Env.ipCheckApiKey;
}

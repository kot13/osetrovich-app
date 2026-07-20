import 'dart:io' show Platform;

String get pushPlatform => Platform.isIOS ? 'ios' : 'android';

String? resolvePushToken(Map<String, String?> tokens) {
  final platformKey = Platform.isIOS ? 'ios' : 'android';
  final platformToken = tokens[platformKey];
  if (platformToken != null && platformToken.isNotEmpty) {
    return platformToken;
  }

  final generic = tokens['token'];
  if (generic != null && generic.isNotEmpty) {
    return generic;
  }

  for (final value in tokens.values) {
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

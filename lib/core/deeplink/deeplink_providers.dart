import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/deeplink/deeplink_resolver.dart';

final deepLinkResolverProvider = Provider<DeepLinkResolver>(
  (ref) => const DeepLinkResolver(),
);

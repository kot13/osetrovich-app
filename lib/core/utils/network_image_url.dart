/// Проверяет, что URL можно передать в [CachedNetworkImage] без ArgumentError.
bool isResolvableNetworkImageUrl(String? url) {
  if (url == null) {
    return false;
  }

  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return false;
  }

  return uri.hasScheme && uri.host.isNotEmpty;
}

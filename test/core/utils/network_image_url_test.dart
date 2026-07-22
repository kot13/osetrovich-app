import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/utils/network_image_url.dart';

void main() {
  test('accepts absolute http and https urls', () {
    expect(isResolvableNetworkImageUrl('https://example.com/a.jpg'), isTrue);
    expect(isResolvableNetworkImageUrl('http://example.com/a.jpg'), isTrue);
  });

  test('rejects empty relative and malformed urls', () {
    expect(isResolvableNetworkImageUrl(null), isFalse);
    expect(isResolvableNetworkImageUrl(''), isFalse);
    expect(isResolvableNetworkImageUrl('   '), isFalse);
    expect(isResolvableNetworkImageUrl('/uploads/image.jpg'), isFalse);
    expect(isResolvableNetworkImageUrl('not-a-url'), isFalse);
  });
}

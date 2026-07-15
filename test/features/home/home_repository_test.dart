import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/home/data/home_repository.dart';

void main() {
  test('getBanners returns mock banners', () async {
    final repo = HomeRepository(MockApiClient());
    final banners = await repo.getBanners();
    expect(banners.length, 4);
  });
}

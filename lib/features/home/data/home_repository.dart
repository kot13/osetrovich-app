import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/home/domain/banner.dart';

class HomeRepository {
  HomeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Banner>> getBanners() => _apiClient.getHomeBanners();

  Future<List<ProductSummary>> getWeeklyProducts() =>
      _apiClient.getWeeklyProducts();
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

final bannersProvider = FutureProvider<List<Banner>>((ref) async {
  return ref.watch(homeRepositoryProvider).getBanners();
});

final weeklyProductsProvider = FutureProvider<List<ProductSummary>>((ref) async {
  return ref.watch(homeRepositoryProvider).getWeeklyProducts();
});

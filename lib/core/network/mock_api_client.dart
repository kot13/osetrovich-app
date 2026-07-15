import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/home/domain/banner.dart';
import 'package:osetrovich/features/home/domain/notification_badge.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';
import 'package:osetrovich/features/cart/domain/delivery_fee.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

class MockApiClient implements ApiClient {
  /// Mock presets for manual QA (quickstart):
  /// - +79001111111 — текущий заказ в статусе «Доставка»
  /// - +79002222222 — выполненный заказ, оценка не дана (pending)
  /// - +79003333333 — выполненный заказ, оценка пропущена (repeat ready)
  /// Обычный вход → заказ появляется после createOrder (checkout).
  static const validCode = '123456';
  static const takenPhone = '+79999999999';
  static const takenEmail = 'taken@example.com';
  static const demoPhoneDelivery = '+79001111111';
  static const demoPhoneRatingPending = '+79002222222';
  static const demoPhoneRatingSkipped = '+79003333333';
  static const _accessTokenPhonePrefix = 'mock.access.token.';

  /// Extracts phone embedded in mock access tokens (`mock.access.token.+7...`).
  static String? phoneFromAccessToken(String accessToken) {
    if (!accessToken.startsWith(_accessTokenPhonePrefix)) {
      return null;
    }
    final phone = accessToken.substring(_accessTokenPhonePrefix.length);
    return phone.isEmpty ? null : phone;
  }

  /// Seeds in-memory profile after session restore (mock state is not persisted).
  void ensureProfile(String phone) {
    final normalized = phone.trim();
    if (normalized.isEmpty) {
      return;
    }
    _profile = UserProfile(
      id: _userIdForPhone(normalized),
      name: 'Покупатель',
      phone: normalized,
      email: null,
      emailVerified: false,
      pushEnabled: true,
    );
    _seedDemoOrdersIfNeeded(normalized);
  }

  static String _userIdForPhone(String phone) =>
      'u-${phone.replaceAll(RegExp(r'\D'), '')}';

  MockApiClient() {
    _notifications = List<AppNotification>.from(_initialNotifications);
  }

  UserProfile? _profile;

  static final List<CatalogCategory> _categories = [
    const CatalogCategory(id: 'all', name: 'Все', sortOrder: 0),
    const CatalogCategory(id: 'fish', name: 'Рыба', sortOrder: 1),
    const CatalogCategory(id: 'caviar', name: 'Икра', sortOrder: 2),
    const CatalogCategory(id: 'crabs', name: 'Крабы', sortOrder: 3),
    const CatalogCategory(
      id: 'seaweed',
      name: 'Морские водоросли',
      sortOrder: 4,
    ),
    const CatalogCategory(id: 'spices', name: 'Специи', sortOrder: 5),
    const CatalogCategory(id: 'sauces', name: 'Соусы', sortOrder: 6),
    const CatalogCategory(id: 'shrimp', name: 'Креветки', sortOrder: 7),
    const CatalogCategory(id: 'mollusks', name: 'Моллюски', sortOrder: 8),
    const CatalogCategory(id: 'canned', name: 'Консервы', sortOrder: 9),
    const CatalogCategory(id: 'for_fish', name: 'Всё для рыбы', sortOrder: 10),
    const CatalogCategory(
      id: 'semi_finished',
      name: 'Полуфабрикаты',
      sortOrder: 11,
    ),
  ];

  static final List<AppNotification> _initialNotifications = [
    AppNotification(
      id: 'n1',
      title: 'Скидка на икру',
      body: 'До конца недели скидка 15% на красную икру.',
      createdAt: DateTime.utc(2026, 7, 14, 10),
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      title: 'Новая поставка крабов',
      body: 'Камчатский краб уже в каталоге.',
      createdAt: DateTime.utc(2026, 7, 13, 14, 30),
      isRead: false,
    ),
    AppNotification(
      id: 'n3',
      title: 'Ваш заказ доставлен',
      body: 'Заказ №12345 успешно доставлен.',
      createdAt: DateTime.utc(2026, 7, 12, 9, 15),
      isRead: false,
    ),
    AppNotification(
      id: 'n4',
      title: 'Акция выходного дня',
      body: 'Скидки на рыбу в субботу и воскресенье.',
      createdAt: DateTime.utc(2026, 7, 10, 8),
      isRead: true,
    ),
  ];

  static final Map<String, PromotionArticleDetail> _promotionArticles = {
    'promo-1': PromotionArticleDetail(
      id: 'promo-1',
      type: PromotionType.promotion,
      title: 'Скидка 15% на красную икру',
      publishedAt: DateTime.utc(2026, 7, 14, 9),
      imageUrl: 'https://picsum.photos/seed/promo1/800/450',
      bodyHtml:
          '<p>Успейте купить <strong>красную икру</strong> со скидкой! 🎉</p>'
          '<ul><li>До 31 июля</li><li>Онлайн и в магазине</li></ul>'
          '<p><a href="https://osetrovich.ru">Подробнее на сайте</a></p>',
    ),
    'promo-2': PromotionArticleDetail(
      id: 'promo-2',
      type: PromotionType.promotion,
      title: 'Акция выходного дня на рыбу',
      publishedAt: DateTime.utc(2026, 7, 12, 8),
      imageUrl: 'https://picsum.photos/seed/promo2/800/450',
      bodyHtml:
          '<p>Скидки на свежую рыбу в <em>субботу и воскресенье</em>.</p>',
    ),
    'promo-3': PromotionArticleDetail(
      id: 'promo-3',
      type: PromotionType.promotion,
      title: '2+1 на креветки',
      publishedAt: DateTime.utc(2026, 7, 10, 12),
      imageUrl: 'https://picsum.photos/seed/promo3/800/450',
      bodyHtml: '<p>Купите две упаковки креветок — третья в подарок.</p>',
    ),
    'promo-4': PromotionArticleDetail(
      id: 'promo-4',
      type: PromotionType.promotion,
      title: 'Бесплатная доставка от 3000 ₽',
      publishedAt: DateTime.utc(2026, 7, 8, 10),
      imageUrl: 'https://picsum.photos/seed/promo4/800/450',
      bodyHtml:
          '<p>Оформите заказ от 3000 ₽ и получите бесплатную доставку.</p>',
    ),
    'promo-5': PromotionArticleDetail(
      id: 'promo-5',
      type: PromotionType.promotion,
      title: 'Скидка на крабов',
      publishedAt: DateTime.utc(2026, 7, 5, 11),
      imageUrl: 'https://invalid.example/broken-image.png',
      bodyHtml: '<p>Камчатский краб по специальной цене.</p>',
    ),
    'promo-script': PromotionArticleDetail(
      id: 'promo-script',
      type: PromotionType.promotion,
      title: 'Тест безопасности HTML',
      publishedAt: DateTime.utc(2026, 7, 4, 9),
      imageUrl: 'https://picsum.photos/seed/promoscript/800/450',
      bodyHtml:
          '<p>Безопасный текст</p><script>alert("xss")</script><p>После скрипта</p>',
    ),
    'news-1': PromotionArticleDetail(
      id: 'news-1',
      type: PromotionType.news,
      title: 'Новая поставка камчатского краба',
      publishedAt: DateTime.utc(2026, 7, 13, 14),
      imageUrl: 'https://picsum.photos/seed/news1/800/450',
      bodyHtml:
          '<p>На склад поступил свежий <strong>камчатский краб</strong>. 🦀</p>'
          '<ol><li>Доступен в каталоге</li><li>Доставка по СПб</li></ol>',
    ),
    'news-2': PromotionArticleDetail(
      id: 'news-2',
      type: PromotionType.news,
      title: 'Открытие сезона икры',
      publishedAt: DateTime.utc(2026, 7, 11, 10),
      imageUrl: 'https://picsum.photos/seed/news2/800/450',
      bodyHtml: '<p>Начался сезон продажи красной икры нового урожая.</p>',
    ),
    'news-3': PromotionArticleDetail(
      id: 'news-3',
      type: PromotionType.news,
      title: 'Расширение ассортимента соусов',
      publishedAt: DateTime.utc(2026, 7, 9, 16),
      imageUrl: 'https://picsum.photos/seed/news3/800/450',
      bodyHtml: '<p>Добавлены новые соусы для морепродуктов.</p>',
    ),
    'news-4': PromotionArticleDetail(
      id: 'news-4',
      type: PromotionType.news,
      title: 'График работы в праздники',
      publishedAt: DateTime.utc(2026, 7, 7, 9),
      imageUrl: 'https://picsum.photos/seed/news4/800/450',
      bodyHtml: '<p>Магазин работает без выходных с 9:00 до 21:00.</p>',
    ),
    'unpublished-demo': PromotionArticleDetail(
      id: 'unpublished-demo',
      type: PromotionType.promotion,
      title: 'Снятая с публикации акция',
      publishedAt: DateTime.utc(2026, 6, 1, 9),
      imageUrl: 'https://picsum.photos/seed/unpub/800/450',
      bodyHtml: '<p>Этот материал не должен быть в ленте.</p>',
    ),
  };

  static const _publishedPromotionIds = {
    'promo-1',
    'promo-2',
    'promo-3',
    'promo-4',
    'promo-5',
    'promo-script',
  };

  static const _publishedNewsIds = {'news-1', 'news-2', 'news-3', 'news-4'};

  late List<AppNotification> _notifications;
  int _orderSequence = 1000;
  final Map<String, List<CurrentOrder>> _ordersByUserId = {};

  @override
  Future<SmsRequestResponse> requestSmsCode(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!_isValidPhone(phone)) {
      throw ApiException(
        code: 'INVALID_PHONE',
        message: 'Некорректный номер телефона',
      );
    }
    return const SmsRequestResponse(retryAfterSeconds: 60);
  }

  @override
  Future<TokenResponse> verifySmsCode(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (code != validCode) {
      throw ApiException(code: 'INVALID_CODE', message: 'Неверный код');
    }
    ensureProfile(phone);
    return TokenResponse(
      accessToken: 'mock.access.token.$phone',
      refreshToken: 'mock.refresh.token.$phone',
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<TokenResponse> refreshToken(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return TokenResponse(
      accessToken: 'mock.access.refreshed',
      refreshToken: refreshToken,
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _profile = null;
  }

  @override
  Future<List<CatalogCategory>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<CatalogCategory>.from(_categories);
  }

  static final List<ProductSummary> _products = _buildMockProducts();
  static final Map<String, ProductDetail> _productDetails = {
    for (final p in _products) p.id: _toDetail(p),
  };

  static List<ProductSummary> _buildMockProducts() {
    final products = <ProductSummary>[];
    const fishNames = [
      'Сёмга слабосолёная',
      'Форель радужная',
      'Гorbача',
      'Кета',
      'Нерка',
      'Голец',
      'Минтай',
      'Треска',
      'Палтус',
      'Дорадо',
    ];
    for (var i = 0; i < 30; i++) {
      products.add(
        ProductSummary(
          id: 'p-fish-$i',
          name: '${fishNames[i % fishNames.length]} №${i + 1}',
          weightLabel: '${300 + (i % 5) * 100} г',
          priceRub: 450 + i * 30,
          imageUrl: 'https://picsum.photos/seed/osetrovich-fish$i/400/400',
          categoryIds: const ['fish'],
        ),
      );
    }

    const categoryProducts = <String, List<String>>{
      'caviar': [
        'Красная икра',
        'Чёрная икра',
        'Икра кеты',
        'Икра нерки',
        'Икра горбуши',
      ],
      'crabs': ['Камчатский краб', 'Стригун', 'Колючий краб', 'Краб-ванам'],
      'seaweed': ['Вакаме', 'Нори', 'Комбу'],
      'spices': ['Соль морская', 'Перец душистый', 'Лавровый лист'],
      'sauces': ['Соус терияки', 'Соус соевый', 'Икра тобико'],
      'shrimp': [
        'Креветки тигровые',
        'Креветки северные',
        'Креветки королевские',
      ],
      'mollusks': ['Мидии', 'Гребешок', 'Кальмар'],
      'canned': ['Лосось в масле', 'Шпроты', 'Тунец'],
      'for_fish': ['Нож рыболовный', 'Доска для разделки'],
    };

    for (final entry in categoryProducts.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final name = entry.value[i];
        products.add(
          ProductSummary(
            id: 'p-${entry.key}-$i',
            name: name,
            weightLabel: i.isEven ? '500 г' : '1 кг',
            priceRub: 250 + i * 120,
            imageUrl:
                'https://picsum.photos/seed/osetrovich-${entry.key}$i/400/400',
            categoryIds: [entry.key],
          ),
        );
      }
    }

    return products;
  }

  static ProductDetail _toDetail(ProductSummary summary) {
    final multiImageIds = {'p-fish-0', 'p-caviar-0', 'p-crabs-0'};
    final imageUrls =
        multiImageIds.contains(summary.id)
            ? [
              summary.imageUrl,
              'https://picsum.photos/seed/${summary.id}-2/400/400',
              'https://picsum.photos/seed/${summary.id}-3/400/400',
            ]
            : [summary.imageUrl];

    return ProductDetail(
      id: summary.id,
      name: summary.name,
      weightLabel: summary.weightLabel,
      priceRub: summary.priceRub,
      imageUrls: imageUrls,
      description:
          '${summary.name} — свежая продукция от osetrovich.ru. '
          'Идеально для праздничного стола и ежедневного меню. '
          'Хранить при температуре от −2 до +4 °C.',
      categoryIds: summary.categoryIds,
    );
  }

  List<ProductSummary> _filterProducts(String categoryId) {
    if (categoryId == 'all') {
      return List<ProductSummary>.from(_products);
    }
    return _products.where((p) => p.categoryIds.contains(categoryId)).toList();
  }

  @override
  Future<ProductListPage> getProducts({
    required String categoryId,
    required int offset,
    required int limit,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final clampedLimit = limit.clamp(1, 20);
    final filtered = _filterProducts(categoryId);
    final total = filtered.length;
    final slice = filtered.skip(offset).take(clampedLimit).toList();
    final hasMore = offset + slice.length < total;

    return ProductListPage(
      items: slice,
      total: total,
      hasMore: hasMore,
      offset: offset,
      limit: clampedLimit,
    );
  }

  @override
  Future<ProductDetail> getProductById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final detail = _productDetails[id];
    if (detail == null) {
      throw ApiException(code: 'NOT_FOUND', message: 'Товар не найден');
    }
    return detail;
  }

  @override
  Future<List<Banner>> getHomeBanners() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return [
      Banner(
        id: 'banner-1',
        imageUrl: 'https://picsum.photos/seed/osetrovich-banner1/800/360',
        sortOrder: 0,
        link: const BannerLink(
          type: BannerLinkType.external,
          url: 'https://osetrovich.ru',
        ),
      ),
      Banner(
        id: 'banner-2',
        imageUrl: 'https://picsum.photos/seed/osetrovich-banner2/800/360',
        sortOrder: 1,
        link: const BannerLink(
          type: BannerLinkType.promotion,
          targetId: 'promo-1',
        ),
      ),
      Banner(
        id: 'banner-3',
        imageUrl: 'https://picsum.photos/seed/osetrovich-banner3/800/360',
        sortOrder: 2,
        link: const BannerLink(
          type: BannerLinkType.product,
          targetId: 'p-fish-0',
        ),
      ),
      Banner(
        id: 'banner-4',
        imageUrl: 'https://picsum.photos/seed/osetrovich-banner4/800/360',
        sortOrder: 3,
        link: const BannerLink(type: BannerLinkType.news, targetId: 'news-1'),
      ),
    ];
  }

  @override
  Future<List<ProductSummary>> getWeeklyProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    const weeklyIds = [
      'p-fish-0',
      'p-fish-1',
      'p-caviar-0',
      'p-crabs-0',
      'p-shrimp-0',
      'p-sauces-0',
      'p-mollusks-0',
      'p-canned-0',
    ];
    return [
      for (final id in weeklyIds)
        for (final product in _products)
          if (product.id == id) product,
    ];
  }

  @override
  Future<CurrentOrder?> getCurrentOrder() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final profile = _requireProfile();
    final orders = _ordersByUserId[profile.id];
    if (orders == null || orders.isEmpty) {
      return null;
    }
    return orders.last;
  }

  @override
  Future<CurrentOrder> submitOrderRating(
    String orderId,
    SubmitOrderRatingRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final profile = _requireProfile();
    final order = _findOrder(profile.id, orderId);
    if (order.status != OrderStatus.completed) {
      throw ApiException(
        code: 'INVALID_REQUEST',
        message: 'Оценка доступна только для выполненного заказа',
      );
    }
    if (order.ratingState != OrderRatingState.pending) {
      throw ApiException(
        code: 'RATING_ALREADY_SET',
        message: 'Оценка уже отправлена или пропущена',
      );
    }
    if (request.stars < 1 || request.stars > 5) {
      throw ApiException(
        code: 'INVALID_REQUEST',
        message: 'Оценка должна быть от 1 до 5',
      );
    }
    final updated = order.copyWith(
      ratingState: OrderRatingState.submitted,
      ratingStars: request.stars,
    );
    _replaceOrder(profile.id, updated);
    return updated;
  }

  @override
  Future<CurrentOrder> skipOrderRating(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final profile = _requireProfile();
    final order = _findOrder(profile.id, orderId);
    if (order.status != OrderStatus.completed) {
      throw ApiException(
        code: 'INVALID_REQUEST',
        message: 'Пропуск оценки доступен только для выполненного заказа',
      );
    }
    if (order.ratingState != OrderRatingState.pending) {
      throw ApiException(
        code: 'RATING_ALREADY_SET',
        message: 'Оценка уже отправлена или пропущена',
      );
    }
    final updated = order.copyWith(
      ratingState: OrderRatingState.skipped,
      clearRatingStars: true,
    );
    _replaceOrder(profile.id, updated);
    return updated;
  }

  @override
  Future<NotificationBadge> getUnreadNotificationCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final count = _notifications.where((n) => !n.isRead).length;
    return NotificationBadge(unreadCount: count);
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<AppNotification>.from(_notifications);
  }

  @override
  Future<AppNotification> getNotificationById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    for (final notification in _notifications) {
      if (notification.id == id) {
        return notification;
      }
    }
    throw ApiException(code: 'NOT_FOUND', message: 'Уведомление не найдено');
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) {
      throw ApiException(code: 'NOT_FOUND', message: 'Уведомление не найдено');
    }
    _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _notifications = [for (final n in _notifications) n.copyWith(isRead: true)];
  }

  UserProfile _requireProfile() {
    final profile = _profile;
    if (profile == null) {
      throw ApiException(
        code: 'UNAUTHORIZED',
        message: 'Требуется авторизация',
      );
    }
    return profile;
  }

  @override
  Future<UserProfile> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _requireProfile();
  }

  @override
  Future<UserProfile> updateProfile({required String name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ApiException(
        code: 'INVALID_REQUEST',
        message: 'Имя не может быть пустым',
      );
    }
    _profile = _requireProfile().copyWith(name: trimmed);
    return _profile!;
  }

  @override
  Future<SmsRequestResponse> requestPhoneChange(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!_isValidPhone(phone)) {
      throw ApiException(
        code: 'INVALID_REQUEST',
        message: 'Некорректный номер телефона',
      );
    }
    if (phone == takenPhone) {
      throw ApiException(
        code: 'PHONE_TAKEN',
        message: 'Этот номер уже используется',
      );
    }
    return const SmsRequestResponse(retryAfterSeconds: 60);
  }

  @override
  Future<UserProfile> verifyPhoneChange(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (code != validCode) {
      throw ApiException(code: 'INVALID_CODE', message: 'Неверный код');
    }
    _profile = _requireProfile().copyWith(phone: phone);
    return _profile!;
  }

  @override
  Future<SmsRequestResponse> requestEmailVerification(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw ApiException(code: 'INVALID_EMAIL', message: 'Некорректный email');
    }
    if (email.toLowerCase() == takenEmail) {
      throw ApiException(
        code: 'EMAIL_TAKEN',
        message: 'Этот email уже используется',
      );
    }
    return const SmsRequestResponse(retryAfterSeconds: 60);
  }

  @override
  Future<UserProfile> verifyEmail(String email, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (code != validCode) {
      throw ApiException(code: 'INVALID_CODE', message: 'Неверный код');
    }
    _profile = _requireProfile().copyWith(email: email, emailVerified: true);
    return _profile!;
  }

  @override
  Future<ProfilePreferences> getProfilePreferences() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return ProfilePreferences(pushEnabled: _requireProfile().pushEnabled);
  }

  @override
  Future<ProfilePreferences> updateProfilePreferences({
    required bool pushEnabled,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _profile = _requireProfile().copyWith(pushEnabled: pushEnabled);
    return ProfilePreferences(pushEnabled: pushEnabled);
  }

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _requireProfile();

    final address = request.deliveryAddress.trim();
    if (address.isEmpty) {
      throw ApiException(
        code: 'INVALID_REQUEST',
        message: 'Укажите адрес доставки',
      );
    }

    if (request.items.isEmpty) {
      throw ApiException(code: 'INVALID_REQUEST', message: 'Корзина пуста');
    }

    final orderLines = <OrderLine>[];
    var itemsSubtotalRub = 0;

    for (final item in request.items) {
      final detail = _productDetails[item.productId];
      if (detail == null) {
        throw ApiException(
          code: 'PRODUCT_UNAVAILABLE',
          message: 'Товар недоступен',
        );
      }
      final lineTotalRub = detail.priceRub * item.quantity;
      itemsSubtotalRub += lineTotalRub;
      orderLines.add(
        OrderLine(
          productId: detail.id,
          name: detail.name,
          weightLabel: detail.weightLabel,
          priceRub: detail.priceRub,
          quantity: item.quantity,
          lineTotalRub: lineTotalRub,
        ),
      );
    }

    final deliveryFeeRub = calculateDeliveryFeeRub(itemsSubtotalRub);
    _orderSequence += 1;
    final profile = _requireProfile();

    final currentOrder = CurrentOrder(
      id: 'ord-$_orderSequence',
      orderNumber: 'ORD-$_orderSequence',
      items: orderLines,
      itemsSubtotalRub: itemsSubtotalRub,
      deliveryFeeRub: deliveryFeeRub,
      totalRub: itemsSubtotalRub + deliveryFeeRub,
      deliveryAddress: address,
      comment: request.comment,
      status: OrderStatus.accepted,
      createdAt: DateTime.now().toUtc(),
      ratingState: OrderRatingState.notApplicable,
    );

    _ordersByUserId.putIfAbsent(profile.id, () => []).add(currentOrder);
    return currentOrder;
  }

  @override
  Future<List<PromotionArticleSummary>> getPromotionArticles(
    PromotionType type,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final publishedIds = switch (type) {
      PromotionType.all => {..._publishedPromotionIds, ..._publishedNewsIds},
      PromotionType.promotion => _publishedPromotionIds,
      PromotionType.news => _publishedNewsIds,
    };

    final items =
        publishedIds
            .map((id) => _promotionArticles[id]!)
            .map(
              (detail) => PromotionArticleSummary(
                id: detail.id,
                type: detail.type,
                title: detail.title,
                publishedAt: detail.publishedAt,
                imageUrl: detail.imageUrl,
              ),
            )
            .toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return items;
  }

  @override
  Future<PromotionArticleDetail> getPromotionArticleById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final detail = _promotionArticles[id];
    if (detail == null || !_isPublishedArticle(id)) {
      throw ApiException(code: 'NOT_FOUND', message: 'Материал недоступен');
    }
    return detail;
  }

  bool _isPublishedArticle(String id) {
    return _publishedPromotionIds.contains(id) ||
        _publishedNewsIds.contains(id);
  }

  void _seedDemoOrdersIfNeeded(String phone) {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    if (_ordersByUserId.containsKey(profile.id)) {
      return;
    }

    CurrentOrder? demo;
    if (phone == demoPhoneDelivery) {
      demo = _buildDemoOrder(
        id: 'ord-demo-delivery',
        number: 'ORD-DEMO-1',
        status: OrderStatus.delivery,
        ratingState: OrderRatingState.notApplicable,
      );
    } else if (phone == demoPhoneRatingPending) {
      demo = _buildDemoOrder(
        id: 'ord-demo-rating',
        number: 'ORD-DEMO-2',
        status: OrderStatus.completed,
        ratingState: OrderRatingState.pending,
      );
    } else if (phone == demoPhoneRatingSkipped) {
      demo = _buildDemoOrder(
        id: 'ord-demo-repeat',
        number: 'ORD-DEMO-3',
        status: OrderStatus.completed,
        ratingState: OrderRatingState.skipped,
      );
    }

    if (demo != null) {
      _ordersByUserId[profile.id] = [demo];
    }
  }

  CurrentOrder _buildDemoOrder({
    required String id,
    required String number,
    required OrderStatus status,
    required OrderRatingState ratingState,
  }) {
    final fish = _productDetails['p-fish-0']!;
    final caviar = _productDetails['p-caviar-0']!;
    final lines = [
      OrderLine(
        productId: fish.id,
        name: fish.name,
        weightLabel: fish.weightLabel,
        priceRub: fish.priceRub,
        quantity: 1,
        lineTotalRub: fish.priceRub,
      ),
      OrderLine(
        productId: caviar.id,
        name: caviar.name,
        weightLabel: caviar.weightLabel,
        priceRub: caviar.priceRub,
        quantity: 2,
        lineTotalRub: caviar.priceRub * 2,
      ),
    ];
    final subtotal = fish.priceRub + caviar.priceRub * 2;
    final delivery = calculateDeliveryFeeRub(subtotal);
    return CurrentOrder(
      id: id,
      orderNumber: number,
      items: lines,
      itemsSubtotalRub: subtotal,
      deliveryFeeRub: delivery,
      totalRub: subtotal + delivery,
      deliveryAddress: 'г. Санкт-Петербург, Невский пр., д. 1',
      status: status,
      createdAt: DateTime.utc(2026, 7, 14, 12),
      ratingState: ratingState,
    );
  }

  CurrentOrder _findOrder(String userId, String orderId) {
    final orders = _ordersByUserId[userId];
    if (orders == null) {
      throw ApiException(code: 'NOT_FOUND', message: 'Заказ не найден');
    }
    for (final order in orders) {
      if (order.id == orderId) {
        return order;
      }
    }
    throw ApiException(code: 'NOT_FOUND', message: 'Заказ не найден');
  }

  void _replaceOrder(String userId, CurrentOrder updated) {
    final orders = _ordersByUserId[userId];
    if (orders == null) {
      throw ApiException(code: 'NOT_FOUND', message: 'Заказ не найден');
    }
    final index = orders.indexWhere((o) => o.id == updated.id);
    if (index == -1) {
      throw ApiException(code: 'NOT_FOUND', message: 'Заказ не найден');
    }
    orders[index] = updated;
  }

  bool _isValidPhone(String phone) => RegExp(r'^\+7\d{10}$').hasMatch(phone);
}

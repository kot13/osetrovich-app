# Research: Интеграция Yandex AppMetrica

**Дата**: 2026-07-15  
**Фича**: [spec.md](./spec.md)

## 1. Выбор SDK и версий пакетов

**Decision**:

| Пакет | Версия | Назначение |
|-------|--------|------------|
| `appmetrica_plugin` | `^3.4.0` (минимум) / `^4.0.0` при Flutter ≥ 3.38 | События, сессии, краши, user profile ID |
| `appmetrica_push_plugin` | `^3.1.0` | Push-токены, доставка, silent push |

**Rationale**: официальные плагины Yandex; единая инициализация `AppMetrica.activate` +
`AppMetricaPush.activate`. Версия 4.x `appmetrica_plugin` требует Flutter 3.38+ (Dart 3.10);
текущий README проекта указывает Dart 3.7+ — на этапе implement выбрать совместимую пару
версий или обновить Flutter SDK.

**Alternatives considered**:
- **Firebase Analytics + Crashlytics + FCM** — три отдельных продукта; пользователь явно
  запросил AppMetrica.
- **Прямой вызов AppMetrica из виджетов** — нарушает слоистую архитектуру и усложняет тесты.

---

## 2. Инициализация и разделение debug/release

**Decision**:

```dart
// main.dart — до runApp
WidgetsFlutterBinding.ensureInitialized();
await AppMetrica.activate(AppMetricaConfig(
  apiKey,  // из String.fromEnvironment('APPMETRICA_API_KEY')
  logsEnabled: kDebugMode,
  flutterCrashReporting: true,
));
```

- **Production-ключ** и **debug-ключ** — разные приложения в консоли AppMetrica
  (`--dart-define=APPMETRICA_API_KEY=...`).
- Если ключ не задан (локальные тесты без define) — `NoOpAnalyticsService`, push не
  активируется.

**Rationale**: FR-014; `flutterCrashReporting: true` покрывает Dart/Flutter-краши (US2);
нативные краши собираются SDK автоматически.

**Alternatives considered**:
- **Один ключ для всех сборок** — загрязняет production-метрики.
- **Отключить flutterCrashReporting** — потеря Dart-крашей во Flutter-слое.

---

## 3. Каталог событий воронки

**Decision**: фиксированные имена событий (snake_case) и параметры — см.
[contracts/analytics-events.yaml](./contracts/analytics-events.yaml).

| Событие | Точка вызова в коде |
|---------|---------------------|
| `app_launch` | `app_bootstrap` после успешной инициализации |
| `catalog_view` | `CatalogScreen` — первое отображение вкладки |
| `product_view` | `ProductDetailScreen` — при открытии с `productId` |
| `add_to_cart` | `CartNotifier.increment` / `add` / `addQuantity` |
| `checkout_start` | `CartScreen` — при открытии непустой корзины |
| `order_success` | `CheckoutNotifier` — после успешного `createOrder` |

Параметры: `product_id`, `order_id`, `order_total` (копейки или рубли — единый формат в
implement: **рубли, int**).

**Rationale**: FR-002–FR-004; имена стабильны для отчёта воронки в панели AppMetrica;
вызов из Notifier гарантирует событие при любом UI-пути (каталог, главная weekly, повтор
заказа).

**Alternatives considered**:
- **Автотрекинг экранов SDK** — не даёт бизнес-семантику «добавление в корзину» / «успешный
  заказ».
- **Событие на каждый `build` виджета** — дубли и шум в воронке.

---

## 4. Абстракция AnalyticsService и тестирование

**Decision**:

```dart
abstract class AnalyticsService {
  void reportAppLaunch();
  void reportCatalogView();
  void reportProductView(String productId);
  void reportAddToCart(String productId);
  void reportCheckoutStart();
  void reportOrderSuccess({required String orderId, required int orderTotalRub});
  void setUserId(String? userId);
}
```

- Реализация `AppMetricaAnalyticsService` → `AppMetrica.reportEventWithMap`.
- `NoOpAnalyticsService` — default в widget-тестах.
- `FakeAnalyticsService` — integration-тесты: проверка последовательности событий воронки.

**Rationale**: принцип III (тесты); принцип IV (логика вне виджетов); SC-002 верифицируется
unit/integration без реальной панели AppMetrica.

**Alternatives considered**:
- **Mocktail только на AppMetrica** — сложнее из-за static API плагина.
- **Integration только с реальным API-ключом** — нестабильно в CI.

---

## 5. Краш-рейт

**Decision**: полагаться на встроенный crash reporter AppMetrica SDK (нативные + Flutter при
`flutterCrashReporting: true`). Дополнительный код отправки крашей не пишется.

**Rationale**: FR-007–FR-008; AppMetrica предоставляет crash rate в панели «Стабильность».

**Alternatives considered**:
- **Sentry параллельно** — дублирование; вне scope.
- **Ручной `FlutterError.onError`** — SDK уже перехватывает при включённой опции.

---

## 6. Push-уведомления

**Decision**:

1. `AppMetricaPush.activate()` после `AppMetrica.activate` в `main.dart`.
2. Подписка на `AppMetricaPush.tokenStream` — логирование в debug; токен регистрируется SDK
   автоматически (FR-009).
3. Синхронизация согласия пользователя:
   - при `pushEnabled == true` + permission ОС → `AppMetricaPush.activate()` / resume
   - при `pushEnabled == false` → отписка / `AppMetricaPush.deactivate` (если доступно) +
     атрибут профиля `push_enabled: false` через `AppMetrica.reportUserProfile`
4. Нативная настройка по [официальному quick-start](https://appmetrica.yandex.com/docs/en/sdk/flutter/push/quick-start):
   - Android: `google-services.json`, FCM в консоли AppMetrica
   - iOS: Push Notifications capability, APNs key в AppMetrica

**Rationale**: FR-009–FR-012; переиспользование `PushPreferencesService` (003); рассылка из
панели AppMetrica, не из REST API мока.

**Alternatives considered**:
- **Новый REST `POST /devices/push-token`** — избыточно при рассылке через AppMetrica;
  backend может подключиться позже через Push API AppMetrica.
- **FCM напрямую без AppMetrica Push** — не выполняет требование FR-001.

---

## 7. Deep link из push

**Decision**: payload в `data` push — JSON по [contracts/push-deeplink.yaml](./contracts/push-deeplink.yaml):

| type | Маршрут go_router |
|------|-------------------|
| `home` | `/home` |
| `order` | `/home` (блок истории заказов; отдельного `/orders/:id` нет) |
| `promotion` | `/promotions/article/{targetId}` |
| `notification` | `/home/notifications/{targetId}` |
| `product` | `/catalog/product/{targetId}` |

Обработчик: `PushDeeplinkHandler.handle(Map payload, GoRouter router)` — вызывается из
callback открытия push (foreground/background/cold start).

**Rationale**: FR-011; согласовано с существующими маршрутами `app_router.dart`.

**Alternatives considered**:
- **Только URL deep link** — хрупкий парсинг; дублирует подход баннеров, но push приходит
  извне панели AppMetrica.
- **Новый экран деталей заказа** — вне scope; заказ на главной (007).

---

## 8. User Profile ID и приватность

**Decision**:

- При успешном login: `AppMetrica.setUserProfileID(userId)` (внутренний ID из JWT/sub, не
  телефон).
- При logout: `AppMetrica.setUserProfileID(null)` или пустая строка по документации SDK.
- Атрибуты профиля: `push_enabled` (bool) — для сегментации в панели AppMetrica.
- **Запрещено** в параметрах событий: `phone`, `address`, `email`, JWT.

**Rationale**: FR-013; связь воронки с аккаунтом без PII.

**Alternatives considered**:
- **Хеш телефона в userId** — избыточный риск при наличии server-side user id.

---

## 9. Хранение API-ключей

**Decision**: `--dart-define=APPMETRICA_API_KEY=...` при `flutter run` / CI; документировать в
`quickstart.md`. Ключи не коммитить в репозиторий.

**Rationale**: безопасность; разные ключи для debug/release через разные define в CI lanes.

**Alternatives considered**:
- **Хардкод в `lib/`** — утечка секретов.
- **`.env` в assets** — риск попадания в APK/IPA.

---

## 10. OpenAPI и моки

**Decision**: REST API **не расширяется**. Поле `pushEnabled` в `UserProfile` и
`PATCH /profile/preferences` (v0.3.0) достаточно для согласия пользователя. Push-токен
управляется AppMetrica SDK.

**Rationale**: принцип VI; фича — клиентская интеграция SDK, не контракт бэкенда.

**Alternatives considered**:
- **Эндпоинт регистрации токена** — понадобится при переходе на server-initiated push вне
  AppMetrica; отложено.

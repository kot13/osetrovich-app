# Quickstart: Интеграция Yandex AppMetrica

**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md) | **Модель**: [data-model.md](./data-model.md)

Руководство по проверке фичи после реализации.

## Предварительные требования

- Flutter SDK (stable), Dart 3.x
- Аккаунт [Yandex AppMetrica](https://appmetrica.yandex.com/) с двумя приложениями:
  **debug** и **release** (разные API-ключи)
- Для push:
  - Android: проект Firebase, `google-services.json`, FCM настроен в консоли AppMetrica
  - iOS: APNs key (.p8), Push Notifications capability в Xcode
- Реализованы фичи: корзина (`005`), профиль с push-toggle (`003`), главная с заказами (`007`)

## Переменные окружения

Ключи **не коммитить** в репозиторий.

```bash
# Debug-сборка
flutter run \
  --dart-define=APPMETRICA_API_KEY=<debug_api_key>

# Release / profile
flutter run --release \
  --dart-define=APPMETRICA_API_KEY=<release_api_key>
```

## Установка и запуск

```bash
flutter pub get
flutter run --dart-define=APPMETRICA_API_KEY=<your_key>
```

## Автоматические тесты

```bash
flutter test
flutter test test/core/analytics/
flutter test test/features/cart/cart_notifier_analytics_test.dart
flutter test integration_test/analytics_funnel_flow_test.dart -d <deviceId>
```

**Ожидание**: unit-тесты `PushDeeplinkHandler` и маппинга событий; integration с
`FakeAnalyticsService` проверяет последовательность воронки без реального SDK.

---

## Сценарии ручной проверки

### С1. Воронка покупки (US1, FR-002–FR-006)

1. Запустить приложение с API-ключом debug.
2. Открыть «Каталог» → товар → добавить в корзину → «Корзина» → оформить заказ.
3. В панели AppMetrica → **События** / настроенная воронка: убедиться в наличии
   `app_launch` → `catalog_view` или `product_view` → `add_to_cart` → `checkout_start` →
   `order_success` с `order_id` и `order_total`.
4. **Срок**: события появляются в панели в течение 24 ч (обычно минуты).

---

### С2. Офлайн-буферизация (Edge case)

1. Включить режим полёта после `app_launch`.
2. Добавить товар в корзину.
3. Выключить режим полёта, подождать 1–2 мин.
4. Убедиться, что `add_to_cart` появился в панели.

---

### С3. Краш-рейт (US2, FR-007–FR-008)

1. Собрать **release** или profile с production-ключом AppMetrica.
2. Вызвать тестовый краш (debug-меню или `throw Exception('test crash')` в dev-сборке).
3. Перезапустить приложение.
4. В панели AppMetrica → **Стабильность**: отчёт с версией приложения, платформой и stack trace.

---

### С4. Push — включение и токен (US3, FR-009–FR-010)

1. Авторизоваться.
2. Профиль → включить «Push-уведомления» → разрешить в ОС.
3. В логах debug (при `logsEnabled`) или панели AppMetrica убедиться в регистрации токена.
4. Выключить push в профиле — токен/сегмент `push_enabled=false`; тестовый push не приходит.

---

### С5. Push — доставка и deep link (US3, FR-011)

1. При включённом push отправить тест из панели AppMetrica с payload:

```json
{
  "type": "promotion",
  "targetId": "promo-1"
}
```

2. Убедиться в доставке на устройство (≤ 5 мин, SC-005).
3. Нажать уведомление → открывается `/promotions/article/promo-1`.

Повторить для `type: order`, `notification`, `product`, `home` — см.
[contracts/push-deeplink.yaml](./contracts/push-deeplink.yaml).

---

### С6. User Profile ID (FR-013)

1. Авторизоваться под пользователем A.
2. Совершить `add_to_cart`.
3. В AppMetrica проверить привязку событий к profile ID (не телефону).
4. Выйти из аккаунта — последующие события без ID пользователя A.

---

### С7. Debug vs Release (FR-014)

1. Отправить события из debug-сборки (debug API key).
2. Отправить события из release-сборки (release API key).
3. Убедиться, что в production-отчёте нет событий debug-приложения.

---

### С8. Холодный старт (SC-007)

1. Замерить время до первого кадра «Главной» до интеграции (baseline).
2. Замерить после интеграции с тем же устройством.
3. Разница MUST быть ≤ 500 мс.

---

## Проверка контрактов

| Артефакт | Проверка |
|----------|----------|
| [analytics-events.yaml](./contracts/analytics-events.yaml) | Имена событий в коде = контракт |
| [push-deeplink.yaml](./contracts/push-deeplink.yaml) | `PushDeeplinkHandler` покрыт unit-тестами |
| OpenAPI | Без изменений; `pushEnabled` в профиле работает как раньше |

## Настройка воронки в панели AppMetrica

1. Откройте [AppMetrica](https://appmetrica.yandex.com/) → приложение (release-ключ).
2. Раздел **Отчёты** → **Воронки** → создать воронку.
3. Добавьте шаги в порядке (имена из контракта):
   - `app_launch`
   - `catalog_view` / `product_view` (параллельные ветки после запуска)
   - `add_to_cart`
   - `checkout_start`
   - `order_success`
4. Для шагов с параметрами используйте фильтры: `product_id`, `order_id`, `order_total`.
5. Для push-рассылок создайте сегмент с атрибутом профиля `push_enabled = true`.

## Troubleshooting

| Симптом | Действие |
|---------|----------|
| События не видны | Проверить API-ключ, интернет, фильтр debug/release в панели |
| Push не приходит | FCM/APNs в консоли AppMetrica; permission ОС; `push_enabled=true` |
| Deep link на `/home` вместо цели | Проверить JSON payload в push |
| Краши не отображаются | `flutterCrashReporting: true`; перезапуск после краша |

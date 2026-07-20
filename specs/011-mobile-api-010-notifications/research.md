# Research: Mobile API 0.10.0 — push-токены и реальные уведомления

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md)

## 1. Обновление OpenAPI 0.9.0 → 0.10.0

**Decision**: поднять `info.version` до `0.10.0` в `openapi/openapi.yaml` и добавить
`PUT /profile/push-token` со схемой `PushTokenRequest` (`token`, `platform`: `ios` | `android`);
ответы 204 / 401 / 422 (пустой token). Эндпоинты уведомлений уже есть в 0.9.0 — меняется
только семантика (реальные ID) и обязательность регистрации push-токена.

**Rationale**: конституция VI — contract-first; дельта зафиксирована в
`specs/011-mobile-api-010-notifications/contracts/openapi.yaml`.

**Alternatives considered**:
- Только клиент без OpenAPI — отклонено: нарушение конституции.
- Отдельный openapi-файл вместо корневого — отклонено: единый контракт в `openapi/`.

---

## 2. Регистрация FCM-токена на сервере

**Decision**: новый сервис `PushTokenRegistrationService` в `lib/core/push/`:
- метод `registerIfNeeded()` — читает токен из `PushService`, вызывает
  `ApiClient.registerPushToken(token, platform)`;
- платформа: `Platform.isIOS ? 'ios' : 'android'`;
- идемпотентность: не отправлять повторно тот же token+platform, пока не изменился токен
  (in-memory + optional `shared_preferences` ключ последнего отправленного токена).

Триггеры регистрации (FR-003):
1. После `authSessionProvider` переходит в авторизованное состояние (`setSession` / restore).
2. `PushService.listenForTokenUpdates` (AppMetrica `tokenStream`).
3. После успешного `PushPreferencesService.updatePushEnabled(true)`.

**Rationale**: отдельный сервис не смешивает AppMetrica SDK с REST; тестируется через mock
`ApiClient` и fake `PushService`.

**Alternatives considered**:
- Регистрация внутри `AppMetricaPushService` — отклонено: нарушает SRP, сложнее мокать API.
- Регистрация только при включении push в профиле — отклонено: не покрывает post-login и
  onTokenRefresh.

---

## 3. Интеграция с существующим AppMetrica Push (фича 008)

**Decision**: сохранить `AppMetricaPushService` и `AnalyticsBootstrap.initializePush()`;
добавить `PushRegistrationBootstrap` (Riverpod `Provider`) — подписка на сессию и token stream,
вызов `PushTokenRegistrationService`. `syncPushEnabled` по-прежнему уходит в AppMetrica
аналитику; **серверная** настройка — через `PATCH /profile/preferences`.

**Rationale**: FCM/APNs уже активируются через AppMetrica; дублировать `firebase_messaging`
не требуется. Токен для backend берётся из `AppMetricaPush.tokenStream` (ключи `android` / `ios`
или единый `token` — нормализовать в сервисе).

**Alternatives considered**:
- Прямая интеграция `firebase_messaging` — отклонено: дублирование с AppMetrica, лишняя
  нативная настройка.

---

## 4. Счётчик непрочитанных (unread-count)

**Decision**: заменить вычисление `unreadCountProvider` из локального списка на отдельный
`unreadCountNotifierProvider` (`AsyncNotifier<int>`), источник — `GET /notifications/unread-count`.
После `markRead` / `markAllRead` / foreground push — `invalidate` или `refresh` счётчика.
Список уведомлений по-прежнему в `notificationsNotifierProvider`.

**Rationale**: SC-003 требует совпадения с сервером; локальный подсчёт расходится при push
без открытия списка.

**Alternatives considered**:
- Только локальный подсчёт — отклонено: не соответствует spec FR-005 и SC-003.
- Один notifier для списка и счётчика — допустимо, но разделение проще тестировать.

---

## 5. Загрузка уведомлений после входа

**Decision**: `notificationsNotifierProvider` и `unreadCountNotifierProvider` слушают
`authSessionProvider` — при появлении сессии `ref.invalidateSelf()` / `reload()`; при logout —
сброс в пустое состояние без запросов.

Дополнительно: при первом запуске после обновления — `NotificationsCacheMigration` (ключ
`notifications_cache_version` в `shared_preferences`, значение `2` для API 0.10.0) очищает
любой локальный кэш stub-данных (если появится персистентный кэш в будущем; сейчас —
invalidate провайдеров).

**Rationale**: FR-005, FR-013; home уже `ref.watch(notificationsNotifierProvider)` — загрузка
стартует на главной после логина.

---

## 6. Mock-данные уведомлений

**Decision**: в `MockApiClient` заменить `_initialNotifications` id `n1`–`n4` на реалистичные
строковые ID (`"1"`, `"2"`, …) и тексты по таблице из spec (заказ принят, на доставке с `\n`,
водитель, доставлен). Убрать парсинг номера заказа из body в тестах/UI.

**Rationale**: FR-004, SC-002; моки MUST соответствовать контракту (конституция VI).

---

## 7. Push tap и deep link (конфликт 008 vs 011)

**Decision**: для push **с бэкенда** (только `title` + `body`, без JSON payload) — при tap
всегда `router.go('/home/notifications')` (FR-010). Существующий `PushDeeplinkHandler` и
контракт `push-deeplink.yaml` **сохраняются** для рассылок AppMetrica с JSON payload
(`type: notification`, `targetId`); если payload пустой или только notification fields —
fallback на список уведомлений.

**Rationale**: spec Out of Scope — id в push payload с бэкенда нет; маркетинговые пуши AppMetrica
могут по-прежнему вести на деталь.

**Alternatives considered**:
- Удалить deeplink handler — отклонено: ломает фичу 008.
- Парсить title для маршрутизации — отклонено: spec запрещает неявную логику.

---

## 8. Foreground push

**Decision**: в `appmetrica_push_plugin` 2.4.0 нет публичного `pushReceivedStream`; тип
`AppMetricaPushInfo` не экспортируется из пакета. `PushForegroundHandler` подписывается на
`AppMetricaPush.pushClickStream` (событие при взаимодействии с push) и при срабатывании:
1. `ref.invalidate(unreadCountNotifierProvider)`;
2. `notificationsNotifierProvider.notifier.reload()`;
3. показывает SnackBar с `AppStrings.pushNotificationReceived`.

Полноценный receive в foreground без tap потребует обновления плагина или нативного FCM
handler — вне scope 011.

**Rationale**: FR-009; обновление счётчика и списка при push-взаимодействии; SnackBar даёт
feedback пользователю в рамках доступного API плагина.

**Alternatives considered**:
- Только обновление счётчика без баннера — отклонено: хуже UX, spec рекомендует in-app баннер.

---

## 9. Уведомление «Заказ доставлен» → оценка

**Decision**: доменный хелпер `NotificationAction.fromNotification(AppNotification)` —
если `title == 'Заказ доставлен'` (константа в `AppStrings`), на экране деталей показать CTA
«Оценить заказ»; по нажатию — `GET /orders/current`, если `ratingState == pending` —
показать существующий `OrderRatingSheet` (из `home_order_history_section`).

**Rationale**: FR-011; переиспользование UI оценки без парсинга текста.

**Alternatives considered**:
- Отдельный экран оценки — отклонено: дублирование `OrderRatingSheet`.

---

## 10. Обработка 404 при mark read

**Decision**: в `NotificationsNotifier.markRead` ловить `ApiException` с HTTP 404 —
вызвать `reload()` списка и счётчика; на экране деталей при отсутствии id после reload —
`pop` с сообщением «Уведомление недоступно».

**Rationale**: FR-006, edge case удалённого уведомления.

---

## 11. Многострочный body

**Decision**: в `NotificationDetailScreen` рендерить `body` через `Text` с `height: 1.5`;
символы `\n` в строке отображаются нативно. Для preview в списке — `body.split('\n').first`
или `maxLines: 2`.

**Rationale**: FR-012; без кастомного markdown.

---

## 12. Тестирование

**Decision**:
- **Unit**: `PushTokenRegistrationService`, `NotificationAction`, mock register + token dedupe.
- **Widget**: detail screen CTA «Заказ доставлен», multiline body, 404 state.
- **Widget**: home badge из `unreadCountNotifierProvider` (fake API).
- **Integration** (опционально): login → register push token (mock) → list notifications.

`NoOpPushService` в тестах без AppMetrica; `MockApiClient` + `registerPushToken`.

**Rationale**: конституция III — основной функционал покрыт тестами.

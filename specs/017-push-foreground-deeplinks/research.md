# Research: Push в foreground и диплинки уведомлений

**Дата**: 2026-07-22  
**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md)

## 1. AppMetrica Push Plugin 2.4.0 — ограничения foreground API

**Decision**: **не** апгрейдить `appmetrica_push_plugin` до 3.x в рамках этой фичи; добавить
`firebase_core` + `firebase_messaging` для подписки на `FirebaseMessaging.onMessage` в foreground.

**Rationale**:
- В 2.4.0 единственный публичный stream с push-info — `AppMetricaPush.pushClickStream`; в исходниках
  плагина явно: *«New elements appear after user clicks on push notification»*
  (`appmetrica_push.dart:38–40`).
- Текущий `PushForegroundHandler` ошибочно подписан на `pushClickStream` — срабатывает только
  при tap, не при доставке (баг относительно FR-001/FR-002).
- Апгрейд до 3.0.x требует `appmetrica_plugin ^4.0.0`, Flutter ≥ 3.38 — выходит за рамки фичи.

**Alternatives considered**:
- Апгрейд AppMetrica Push 3.x — отклонено: каскадное обновление зависимостей.
- Polling `GET /notifications/unread-count` по таймеру — отклонено: лишняя нагрузка, не real-time.
- Только SnackBar при возврате на «Главную» — отклонено: не соответствует spec.

---

## 2. Интеграция firebase_messaging рядом с AppMetrica

**Decision**:
- Android: `firebase-messaging` уже в `android/app/build.gradle.kts`; добавить `firebase_core` и
  `firebase_messaging` в `pubspec.yaml`; инициализировать `Firebase.initializeApp()` в
  `main.dart` / bootstrap **до** `AppMetricaPush.activate()`.
- iOS: `GoogleService-Info.plist` (как для FCM/AppMetrica) — prerequisite для manual QA.
- `FcmForegroundPushService` слушает **только** `onMessage` (foreground); tap в фоне остаётся
  на `AppMetricaPush.pushClickStream` + `getLaunchPushInfo` — без дублирования navigation.

**Rationale**: FCM на Android уже подключён для AppMetrica transport; `onMessage` — стандартный
способ получения notification+data при активном приложении (spec user story).

**Alternatives considered**:
- Полная замена AppMetrica Push на `firebase_messaging` — отклонено: ломает token stream,
  аналитику и существующие маркетинговые рассылки (008).
- Нативный `FirebaseMessagingService` + MethodChannel — отклонено: дублирует flutter-плагин.

**Риск**: двойная обработка одного push маловероятна — `onMessage` не вызывается при tap;
`pushClickStream` не вызывается в foreground без взаимодействия. Документировать в quickstart.

---

## 3. Формат payload order push (FCM → клиент)

**Decision**: зафиксировать контракт [fcm-order-push.yaml](./contracts/fcm-order-push.yaml):

```json
{
  "notification": { "title": "...", "body": "..." },
  "data": {
    "deeplink": "osetrovich://notifications/{id}",
    "notification_id": "{id}"
  }
}
```

В `RemoteMessage`:
- `message.notification?.title` / `body` — для in-app баннера (FR-008).
- `message.data['deeplink']`, `message.data['notification_id']` — для навигации (FR-003–FR-006).

AppMetrica при tap передаёт `payload` как строку — обычно JSON serialization поля `data` или
custom payload; `PushIncomingMapper` MUST поддерживать оба входа.

**Rationale**: соответствует входному описанию пользователя и spec FR-004/FR-005.

---

## 4. Расширение PushDeeplinkHandler — поле notification_id

**Decision**: в `resolveTarget(Map)` после проверки `deeplink`/`url` добавить:

```dart
final notificationId = payload['notification_id'] as String?;
if (notificationId != null && notificationId.isNotEmpty) {
  return _resolver.resolve('osetrovich://notifications/$notificationId');
}
```

Приоритет разрешения (v3, см. [push-deeplink-v3.yaml](./contracts/push-deeplink-v3.yaml)):
1. Raw `osetrovich://`
2. JSON `deeplink` / `url`
3. JSON `notification_id` → синтетический deeplink
4. Legacy `type` / `targetId` (008)
5. Fallback `/home/notifications`

**Rationale**: FR-003, US2 scenario 2 (tap без deeplink, только notification_id).

---

## 5. Обновление счётчика в foreground

**Decision**: при каждом `PushIncomingMessage` в foreground:
1. `ref.read(unreadCountNotifierProvider.notifier).refresh()` (или `invalidate`);
2. `ref.read(notificationsNotifierProvider.notifier).reload()` — опционально debounce 300 ms при
   burst push.

**Без** локального `unreadCount++` — только сервер как источник истины (spec Assumptions, SC-001).

**Rationale**: согласовано с фичей 011 research §4; исключает рассинхрон при дубликатах push.

---

## 6. In-app баннер (foreground UX)

**Decision**: `MaterialBanner` через `ScaffoldMessenger` корневого контекста (или
`rootScaffoldMessengerKey` в `app.dart`):
- Заголовок: `notification.title` (fallback — `AppStrings.pushNotificationReceived`).
- Текст: `notification.body` (одна строка, `maxLines: 2`).
- Tap на баннер → `PushDeeplinkHandler.navigate` с payload из `PushIncomingMessage`.
- Swipe/close — только скрыть баннер; уведомление остаётся непрочитанным (US3).

**Rationale**: spec FR-008 (MAY); лучше заметность чем пустой SnackBar «Новое уведомление».

**Alternatives considered**:
- `flutter_local_notifications` для foreground — отклонено: дублирует системный UX, лишняя
  зависимость для P2.
- Только счётчик без баннера — допустимо как MVP, но баннер включён в план (P2).

---

## 7. Экран «Уведомление не найдено»

**Decision**:
- Добавить `AppStrings.notificationNotFound = 'Уведомление не найдено'`.
- В `NotificationDetailScreen`: если после `reload()` id отсутствует в списке — показать
  `notificationNotFound` (заменить `notificationUnavailable` для 404-сценария).
- При `markRead` 404 — `reload()` + тот же текст (уже частично в 011).

**Rationale**: spec FR-007, SC-003; точная формулировка из spec.

---

## 8. Тестирование

**Decision**:

| Уровень | Объект | Кейсы |
|---------|--------|-------|
| Unit | `PushIncomingMapper` | FCM data map, JSON string, только notification_id, пустой payload |
| Unit | `PushDeeplinkHandler` | notification_id без deeplink; приоритет deeplink |
| Unit | `PushForegroundHandler` | receive → refresh count; banner tap → navigate callback |
| Widget | `NotificationDetailScreen` | id не в списке → «Уведомление не найдено» |
| Widget | Foreground banner | tap вызывает navigation (mock handler) |

`FcmForegroundPushService` — integration/manual; unit через fake stream.

**Rationale**: конституция III; Firebase не поднимается в widget-тестах.

---

## 9. OpenAPI / REST

**Decision**: изменений OpenAPI **нет** — push payload описан в `contracts/fcm-order-push.yaml`;
`GET /v1/notifications/{id}` уже существует.

**Rationale**: spec Out of Scope для серверной логики; конституция VI — контракт order push
вне REST, но фиксируется в `specs/017/.../contracts/` для согласования с бэкендом.

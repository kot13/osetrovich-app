# Quickstart: Push в foreground и диплинки уведомлений

**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md) | **Модель**: [data-model.md](./data-model.md)

Руководство по проверке фичи после реализации.

## Предварительные требования

- Flutter SDK (stable), Dart 3.x
- `--dart-define=APPMETRICA_API_KEY=...` для push
- FCM: `google-services.json` (Android), `GoogleService-Info.plist` (iOS)
- Зависимости `firebase_core`, `firebase_messaging` в `pubspec.yaml`
- Авторизованный пользователь с зарегистрированным push-токеном (`PUT /v1/profile/push-token`)
- Выполненные задачи из `tasks.md`

## Установка и запуск

```bash
flutter pub get
flutter run --dart-define=APPMETRICA_API_KEY=<ваш-ключ>
```

## Автоматические тесты

```bash
flutter test test/core/push/push_incoming_mapper_test.dart
flutter test test/core/push/push_deeplink_handler_test.dart
flutter test test/core/push/push_foreground_handler_test.dart
flutter test test/features/notifications/notification_detail_screen_test.dart
flutter analyze
```

**Ожидание**:
- Mapper строит маршрут из `notification_id` без `deeplink`
- `PushDeeplinkHandler` — приоритет `deeplink` над `notification_id`
- Foreground handler вызывает refresh счётчика при receive
- Detail screen — «Уведомление не найдено» для отсутствующего id

---

## Сценарии ручной проверки

### С1. Foreground — обновление счётчика (US1, FR-001–FR-002)

**Предусловие**: пользователь авторизован, приложение открыто на любом экране.

1. Запомнить текущий бейдж на колокольчике «Главной».
2. Отправить order push (см. [fcm-order-push.yaml](./contracts/fcm-order-push.yaml)) с новым
   `notification_id`, существующим в API.
3. В течение 5 с бейдж обновился и совпадает с `GET /v1/notifications/unread-count`.
4. Открыть «Уведомления» — новое сообщение в списке с корректным title/body.

### С2. Foreground — in-app баннер (US3, FR-008)

1. При открытом приложении отправить push с `notification.title` и `notification.body`.
2. Появился in-app баннер с этими текстами.
3. Нажать на баннер → открыта деталь уведомления `{id}`.
4. Закрыть баннер без нажатия → счётчик обновлён, уведомление остаётся непрочитанным.

### С3. Tap на push — деталь по deeplink (US2, FR-003–FR-006)

**Предусловие**: приложение в фоне или закрыто.

1. Отправить push:
   ```json
   {
     "data": {
       "deeplink": "osetrovich://notifications/42",
       "notification_id": "42"
     },
     "notification": { "title": "Тест", "body": "Текст" }
   }
   ```
2. Нажать системное уведомление.
3. Открыт экран детали уведомления `42`.
4. Уведомление помечено прочитанным, бейдж уменьшился.

### С4. Tap только с notification_id (US2)

1. Push без `deeplink`, только `data.notification_id: "42"`.
2. Tap → деталь уведомления `42`.

### С5. Уведомление не найдено (US4, FR-007)

1. Отправить push с `notification_id`, отсутствующим в API (или удалить запись).
2. Нажать на push.
3. Отображается **«Уведомление не найдено»**; приложение не падает.

### С6. Fallback без data (Edge case)

1. Push только с `notification` (title/body), без `data`.
2. Tap → список уведомлений `/home/notifications`.
3. Foreground receive → счётчик всё равно обновляется.

### С7. Legacy совместимость (FR-010)

1. Маркетинговый push с `osetrovich://catalog/product/1000` — открывается товар.
2. Legacy JSON `{"type":"notification","targetId":"5"}` — деталь уведомления 5.

---

## Отправка тестового push

Через Firebase Console / Admin SDK / бэкенд staging — формат по
[fcm-order-push.yaml](./contracts/fcm-order-push.yaml).

Минимальный data payload:

```json
{
  "deeplink": "osetrovich://notifications/<id>",
  "notification_id": "<id>"
}
```

`{id}` MUST существовать в `GET /v1/notifications/{id}` для сценариев С3–С4.

## Контракты

| Файл | Назначение |
|------|------------|
| [fcm-order-push.yaml](./contracts/fcm-order-push.yaml) | Структура FCM message |
| [push-deeplink-v3.yaml](./contracts/push-deeplink-v3.yaml) | Разрешение маршрута на клиенте |

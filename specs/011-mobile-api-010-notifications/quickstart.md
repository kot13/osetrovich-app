# Quickstart: Mobile API 0.10.0 — push-токены и реальные уведомления

**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md) | **Модель**: [data-model.md](./data-model.md)

Руководство по проверке фичи после реализации.

## Предварительные требования

- Flutter SDK (stable), Dart 3.x
- Для push на устройстве: `--dart-define=APPMETRICA_API_KEY=...`, настроенные FCM (Android) / APNs (iOS)
- Для API: `useMockApi = false` в `lib/core/network/providers.dart` **или** mock с новыми сценариями
- Выполненные задачи из `tasks.md`

## Установка и запуск

```bash
flutter pub get
flutter run --dart-define=APPMETRICA_API_KEY=<ваш-ключ>
```

## Автоматические тесты

```bash
flutter test test/core/push/push_token_registration_service_test.dart
flutter test test/features/notifications/
flutter test test/core/network/mock_api_client_notifications_test.dart
flutter analyze
```

**Ожидание**:
- Регистрация push-токена вызывается после login (mock verify)
- `unreadCountNotifierProvider` использует API unread-count, не локальный подсчёт
- Mock-уведомления без id `n1`/`n2`
- Detail screen: multiline body, CTA для «Заказ доставлен»
- 404 при mark read → reload без краша

---

## Сценарии ручной проверки

### С1. Регистрация push-токена после входа (US1, FR-002–FR-003)

**Предусловие**: `useMockApi = false`, push активирован (AppMetrica + FCM).

1. Выйти из аккаунта.
2. Войти по SMS.
3. В network trace — `PUT /profile/push-token` с `platform` и непустым `token`, ответ **204**.
4. Повторный вход с тем же токеном — повторный PUT не обязателен (дедупликация).

### С2. onTokenRefresh (US1)

1. Авторизоваться.
2. Симулировать обновление FCM-токена (переустановка / dev tools Firebase).
3. Снова `PUT /profile/push-token` с новым token.

### С3. Включение push в профиле (US3, FR-007)

1. Выключить «Уведомления» в профиле.
2. Включить снова — запрос разрешения ОС (если не выдан), `PATCH /profile/preferences`, затем `PUT /profile/push-token`.

### С4. Реальный список уведомлений (US2, FR-004–FR-006)

1. Авторизоваться.
2. Открыть колокольчик — список с сервера, id не `n1`/`n2`.
3. Бейдж на главной совпадает с `GET /notifications/unread-count`.
4. Открыть уведомление — `POST .../read`, бейдж уменьшается.
5. «Отметить все прочитанным» — `POST /notifications/read-all`, бейдж = 0.

### С5. Push в фоне и foreground (US4, FR-009–FR-010)

1. Зарегистрировать токен (С1).
2. Отправить тестовый push с бэкенда (title + body).
3. **Фон**: системное уведомление в трее.
4. **Foreground**: SnackBar или обновление счётчика/списка.
5. Tap на push → экран «Уведомления».

### С6. «Заказ доставлен» → оценка (US5, FR-011)

1. Иметь `GET /orders/current` с `ratingState: pending` (demo phone в mock).
2. Открыть уведомление с title «Заказ доставлен».
3. Нажать «Оценить заказ» → `OrderRatingSheet`.
4. Убедиться, что номер заказа **не** извлекается из текста body.

### С7. Многострочный body (FR-012)

1. Открыть уведомление «Заказ на доставке» с `\n` в body.
2. Состав и сумма отображаются с переносами строк.

### С8. 404 при прочтении (Edge case)

1. Открыть уведомление, удалённое на сервере (или подставить несуществующий id).
2. Приложение не падает; список обновляется.

### С9. Обновление приложения (FR-013)

1. Установить сборку до миграции; затем обновить до 0.10.0.
2. Первый запуск — нет устаревших stub-данных; свежая загрузка с API.

---

## Проверка OpenAPI

```bash
# В корневом openapi/openapi.yaml:
# - info.version: 0.10.0
# - paths./profile/push-token
# - components.schemas.PushTokenRequest
```

Сверить с [contracts/openapi.yaml](./contracts/openapi.yaml).

## Откат / отладка

- Push не приходит: проверить `PUT /profile/push-token` (204), `pushEnabled`, FCM setup.
- Бейдж не совпадает: проверить источник `unreadCountNotifierProvider`, не локальный filter.
- `useMockApi = true` — push registration тестируется через mock, реальный FCM не нужен.

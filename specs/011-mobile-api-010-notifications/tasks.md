---

description: "Список задач для фичи «Mobile API 0.10.0 — push-токены и реальные уведомления»"
---

# Tasks: Mobile API 0.10.0 — push-токены и реальные уведомления

**Input**: Design documents from `/specs/011-mobile-api-010-notifications/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и integration тесты включены для каждой user story.

**Organization**: Задачи сгруппированы по user story для независимой реализации и проверки.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Можно выполнять параллельно (разные файлы, нет зависимостей от незавершённых задач)
- **[Story]**: User story из spec.md (US1–US5)
- В описании указан точный путь к файлу

## Path Conventions

- **Flutter (Osetrovich)**: `lib/`, `test/`, `integration_test/`, `openapi/`
- Структура согласно [plan.md](./plan.md)

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Обновление контракта API 0.10.0 и строк UI

- [x] T001 Обновить `openapi/openapi.yaml`: `info.version` → `0.10.0`, добавить `PUT /profile/push-token`, схему `PushTokenRequest` (`token`, `platform`: `ios`|`android`), ответы 204/401/422 — сверить со `specs/011-mobile-api-010-notifications/contracts/openapi.yaml`
- [x] T002 [P] Добавить строки в `lib/core/l10n/app_strings.dart`: CTA «Оценить заказ», «Уведомление недоступно», сообщения foreground push, константа заголовка «Заказ доставлен»

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: API-клиент, моки и базовый сервис регистрации push-токена — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 Добавить `registerPushToken({required String token, required String platform})` в интерфейс `ApiClient` и реализацию `DioApiClient` (`PUT /profile/push-token`, ожидать 204) в `lib/core/network/api_client.dart`
- [x] T004 Реализовать `registerPushToken` в `lib/core/network/mock_api_client.dart`: сохранять последний token, отклонять пустой token с `ApiException` (аналог 422), требовать авторизацию
- [x] T005 [P] Заменить stub-уведомления `n1`–`n4` в `lib/core/network/mock_api_client.dart` на реалистичные ID (`"1"`, `"2"`, …) и тексты API 0.10.0 (заказ принят, на доставке с `\n`, водитель, доставлен)
- [x] T006 [P] Расширить `PushService` методом получения текущего FCM-токена (или нормализации `tokenStream`) в `lib/core/push/push_service.dart`; обновить `lib/core/push/appmetrica_push_service.dart` и `lib/core/push/no_op_push_service.dart`
- [x] T007 Создать `lib/core/push/push_token_registration_service.dart`: дедупликация token+platform, вызов `ApiClient.registerPushToken`, обработка 401/422 без блокировки UI
- [x] T008 [P] Unit-тест `PushTokenRegistrationService` в `test/core/push/push_token_registration_service_test.dart`: успешная регистрация, дедупликация, пустой token, 401
- [x] T009 [P] Unit-тест mock notifications и `registerPushToken` в `test/core/network/mock_api_client_notifications_test.dart`: нет id `n1`/`n2`, mark read/read-all, registerPushToken

**Checkpoint**: Контракт, клиент, моки и сервис регистрации готовы

---

## Phase 3: User Story 1 — Регистрация push-токена (Priority: P1) 🎯 MVP

**Goal**: После входа, onTokenRefresh и включения push — `PUT /profile/push-token` с `platform` ios/android

**Independent Test**: Войти по SMS → в trace/mock виден `PUT /profile/push-token` с 204; повтор с тем же token не дублирует запрос (quickstart С1–С2)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T010 [P] [US1] Unit-тест: после `setSession` вызывается регистрация токена в `test/core/push/push_registration_bootstrap_test.dart`
- [x] T011 [P] [US1] Unit-тест: `listenForTokenUpdates` повторно регистрирует новый token в `test/core/push/push_registration_bootstrap_test.dart`

### Implementation for User Story 1

- [x] T012 [US1] Создать `lib/core/push/push_registration_bootstrap.dart`: Riverpod-провайдер, подписка на `authSessionProvider` и `PushService.listenForTokenUpdates`, вызов `PushTokenRegistrationService` только при активной сессии и `pushEnabled` (читать из профиля или prefs)
- [x] T013 [US1] Подключить bootstrap в `lib/app.dart` (`pushRegistrationBootstrapProvider`)
- [x] T014 [US1] После успешного `setSession` / `applyRefreshedTokens` в `lib/features/auth/domain/auth_session_provider.dart` — триггер регистрации push-токена (invalidate bootstrap или прямой вызов сервиса)

**Checkpoint**: Авторизованный пользователь с FCM-токеном регистрирует его на сервере

---

## Phase 4: User Story 2 — Реальный список уведомлений (Priority: P1)

**Goal**: Список и бейдж с сервера; stub-данные удалены; read/read-all; миграция кэша; обработка 404

**Independent Test**: После входа бейдж = `GET /notifications/unread-count`; список без `n1`/`n2`; mark read уменьшает бейдж (quickstart С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T015 [P] [US2] Unit-тест `UnreadCountNotifier` в `test/features/notifications/unread_count_notifier_test.dart`: загрузка с API, refresh после mark read
- [x] T016 [P] [US2] Unit-тест 404 при `markRead` → reload списка в `test/features/notifications/notifications_notifier_test.dart`
- [x] T017 [P] [US2] Widget-тест бейджа на главной из API-счётчика в `test/features/home/home_screen_test.dart`
- [x] T018 [P] [US2] Обновить `test/features/notifications/notifications_list_screen_test.dart`: данные без stub-id, пустое состояние

### Implementation for User Story 2

- [x] T019 [US2] Создать `lib/features/notifications/domain/unread_count_notifier.dart` (`AsyncNotifier<int>`, источник `ApiClient.getUnreadNotificationCount`, invalidate при login/logout/mark read)
- [x] T020 [US2] Обновить `lib/features/notifications/domain/notifications_notifier.dart`: reload при появлении сессии; обработка 404 в `markRead`/`markAllRead` с `reload()`; после mark — invalidate `unreadCountNotifierProvider`
- [x] T021 [US2] Удалить локальный подсчёт в `unreadCountProvider` — заменить на `unread_count_notifier.dart` в `lib/features/notifications/domain/notifications_notifier.dart`
- [x] T022 [US2] Обновить `lib/features/home/presentation/home_screen.dart`: `ref.watch(unreadCountNotifierProvider)` вместо filter по списку
- [x] T023 [US2] Создать `lib/features/notifications/data/notifications_cache_migration.dart`: ключ `notifications_cache_version = 2` в `shared_preferences`, invalidate провайдеров при миграции
- [x] T024 [US2] Вызвать миграцию при старте приложения в `lib/core/bootstrap/app_bootstrap.dart`

**Checkpoint**: Уведомления и бейдж полностью с сервера; stub-id отсутствуют

---

## Phase 5: User Story 3 — Управление push в настройках (Priority: P2)

**Goal**: Переключатель «Уведомления» синхронизирует `pushEnabled`; при включении — разрешение ОС и регистрация токена

**Independent Test**: Включить push в профиле → `PATCH /profile/preferences` + `PUT /profile/push-token`; выключить → push registration не обязателен (quickstart С3)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T025 [P] [US3] Unit-тест: `updatePushEnabled(true)` вызывает registerPushToken в `test/features/profile/push_preferences_service_test.dart`
- [x] T026 [P] [US3] Widget-тест переключателя push в `test/features/profile/profile_screen_test.dart`: отказ в разрешении ОС — сообщение без падения

### Implementation for User Story 3

- [x] T027 [US3] Обновить `lib/features/profile/domain/push_preferences_service.dart`: после успешного `updatePushEnabled(true)` вызвать `PushTokenRegistrationService.registerIfNeeded()`
- [x] T028 [US3] При `updatePushEnabled(false)` — опционально сбросить lastRegisteredToken в `lib/core/push/push_token_registration_service.dart` (сервер переключит SMS сам)

**Checkpoint**: Настройки профиля и регистрация токена согласованы

---

## Phase 6: User Story 4 — Push foreground/background (Priority: P2)

**Goal**: Фон — системный трей; foreground — SnackBar + обновление списка/счётчика; tap → экран уведомлений

**Independent Test**: Push с title/body → отображение в foreground/background; tap открывает `/home/notifications` (quickstart С5)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО)

- [x] T029 [P] [US4] Unit-тест: пустой/notification-only payload → `/home/notifications` в `test/core/push/push_deeplink_handler_test.dart`
- [x] T030 [P] [US4] Unit-тест foreground handler: invalidate unread + list в `test/core/push/push_foreground_handler_test.dart`

### Implementation for User Story 4

- [x] T031 [US4] Обновить `lib/core/push/push_deeplink_handler.dart`: если payload пустой или без поля `type` — маршрут `/home/notifications` (сохранить JSON deeplink 008 для маркетинговых пушей)
- [x] T032 [US4] Обновить `lib/core/push/push_navigation_setup.dart`: согласовать tap с FR-010 (список уведомлений для backend push)
- [x] T033 [US4] Создать `lib/core/push/push_foreground_handler.dart`: подписка на `AppMetricaPush.pushClickStream`, SnackBar, invalidate `unreadCountNotifierProvider` и `notificationsNotifierProvider`
- [x] T034 [US4] Подключить foreground handler в `lib/app.dart` (`pushForegroundSetupProvider`)

**Checkpoint**: Push-цикл завершён: доставка, отображение, навигация

---

## Phase 7: User Story 5 — «Заказ доставлен» → оценка (Priority: P3)

**Goal**: CTA оценки по title «Заказ доставлен»; многострочный body; без парсинга номера заказа

**Independent Test**: Уведомление «Заказ доставлен» + `ratingState: pending` → `OrderRatingSheet` (quickstart С6–С7)

### Tests for User Story 5 (ОБЯЗАТЕЛЬНО)

- [x] T035 [P] [US5] Unit-тест `NotificationAction.fromNotification` в `test/features/notifications/notification_action_test.dart`: rateOrder только для точного title
- [x] T036 [P] [US5] Widget-тест CTA и multiline body в `test/features/notifications/notification_detail_screen_test.dart`

### Implementation for User Story 5

- [x] T037 [US5] Создать `lib/features/notifications/domain/notification_action.dart`: `NotificationAction.rateOrder` при `title == AppStrings.orderDeliveredNotificationTitle`
- [x] T038 [US5] Обновить `lib/features/notifications/presentation/notification_detail_screen.dart`: multiline `body`, кнопка «Оценить заказ» → `GET /orders/current` + `OrderRatingSheet` при `ratingState.pending`
- [x] T039 [US5] Обновить `lib/features/notifications/presentation/notifications_list_screen.dart`: preview body с `maxLines` и корректным отображением первой строки многострочного текста

**Checkpoint**: Сценарий доставки и оценки работает без парсинга текста

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Документация, интеграционные проверки, финальный прогон

- [x] T040 [P] Обновить `README.md`: кратко описать регистрацию FCM-токена и API 0.10.0 notifications
- [x] T041 [P] Добавить integration-тест login → register push (mock) в `integration_test/notifications_flow_test.dart`
- [x] T042 Прогнать сценарии из `specs/011-mobile-api-010-notifications/quickstart.md` (С1–С9)
- [x] T043 Выполнить `flutter analyze` и `flutter test`; исправить регрессии

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Нет зависимостей — можно начинать сразу
- **Foundational (Phase 2)**: Зависит от Phase 1 — **блокирует** все user stories
- **User Stories (Phase 3–7)**: Зависят от Phase 2
  - US1 (P1) и US2 (P1) — оба P1; US2 может начаться параллельно с US1 после Phase 2 (разные файлы)
  - US3 зависит от US1 (регистрация при enable push)
  - US4 зависит от US1 (токен) и US2 (invalidate счётчика)
  - US5 независима от US4, использует US2 (список/детали)
- **Polish (Phase 8)**: После завершения желаемых user stories

### User Story Dependencies

| Story | Зависимости | Можно тестировать независимо |
|-------|-------------|------------------------------|
| US1 | Phase 2 | ✅ login → PUT push-token |
| US2 | Phase 2 | ✅ list + unread-count + mark read |
| US3 | US1 (регистрация) | ✅ toggle preferences |
| US4 | US1, US2 (invalidate) | ✅ push tap + foreground |
| US5 | US2 (detail screen) | ✅ CTA оценки |

### Parallel Opportunities

- **Phase 1**: T002 параллельно с T001 (разные файлы)
- **Phase 2**: T005, T006, T008, T009 параллельно после T003–T004
- **US1 + US2**: после Phase 2 разные разработчики на Phase 3 и Phase 4
- Внутри каждой story: все тесты с [P] — параллельно

### Parallel Example: User Story 2

```bash
# Тесты US2 параллельно:
flutter test test/features/notifications/unread_count_notifier_test.dart
flutter test test/features/notifications/notifications_notifier_test.dart
flutter test test/features/home/home_screen_test.dart
flutter test test/features/notifications/notifications_list_screen_test.dart
```

### Parallel Example: Foundational

```bash
# После T003–T004:
# T005 mock notifications + T006 PushService + T008–T009 tests в параллель
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US1 (push-token registration)
4. Complete Phase 4: US2 (real notifications)
5. **STOP and VALIDATE**: quickstart С1, С4
6. Deploy/demo

### Incremental Delivery

1. Setup + Foundational → контракт и клиент готовы
2. US1 → push-token на сервере (MVP для push-доставки)
3. US2 → реальные in-app уведомления и бейдж
4. US3 → синхронизация настроек профиля
5. US4 → foreground/background UX
6. US5 → CTA оценки заказа

### Suggested MVP Scope

**US1 + US2** (оба P1): без них push и in-app уведомления не работают по контракту 0.10.0.

---

## Notes

- Все задачи с чекбоксом `- [ ]`, ID `T001`–`T043`, пути к файлам в описании
- `useMockApi = true` — достаточно для большинства unit/widget тестов; push на устройстве — `useMockApi = false` + AppMetrica
- Не парсить номер заказа из `body` уведомлений (FR-011)
- Commit после каждой фазы или логической группы задач

---

## Task Summary

| Metric | Value |
|--------|-------|
| **Total tasks** | 43 |
| Phase 1 Setup | 2 |
| Phase 2 Foundational | 7 |
| US1 (P1) | 5 |
| US2 (P1) | 10 |
| US3 (P2) | 4 |
| US4 (P2) | 6 |
| US5 (P3) | 5 |
| Polish | 4 |

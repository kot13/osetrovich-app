---

description: "Список задач для фичи «Push в foreground и диплинки уведомлений»"
---

# Tasks: Push в foreground и диплинки уведомлений

**Input**: Design documents from `/specs/017-push-foreground-deeplinks/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и integration тесты включены для каждой user story.

**Organization**: Задачи сгруппированы по user story для независимой реализации и проверки.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Можно выполнять параллельно (разные файлы, нет зависимостей от незавершённых задач)
- **[Story]**: User story из spec.md (US1–US4)
- В описании указан точный путь к файлу

## Path Conventions

- **Flutter (Osetrovich)**: `lib/`, `test/`, `integration_test/`, `openapi/`
- Структура согласно [plan.md](./plan.md)

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Зависимости Firebase и строки UI

- [x] T001 Добавить `firebase_core` и `firebase_messaging` в `pubspec.yaml`; выполнить `flutter pub get`
- [x] T002 Инициализировать `Firebase.initializeApp()` в `lib/main.dart` до `AnalyticsBootstrap.initialize()` (с `WidgetsFlutterBinding.ensureInitialized()` и обработкой ошибок в debug)
- [x] T003 [P] Добавить `AppStrings.notificationNotFound = 'Уведомление не найдено'` в `lib/core/l10n/app_strings.dart` (сохранить `notificationUnavailable` для прочих ошибок или заменить по plan.md)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модель входящего push, mapper и расширение deeplink handler — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T004 Создать модель `PushIncomingMessage` (title, body, deeplink, notificationId) в `lib/core/push/push_incoming_message.dart`
- [x] T005 Создать `PushIncomingMapper` с методами `fromFcm(RemoteMessage)` и `fromPayloadString(String?)` в `lib/core/push/push_incoming_mapper.dart`; синтетический deeplink из `notification_id`
- [x] T006 Расширить `PushDeeplinkHandler.resolveTarget` для поля `notification_id` (приоритет после `deeplink`/`url`, до legacy `type`) в `lib/core/push/push_deeplink_handler.dart`
- [x] T007 [P] Unit-тест `PushIncomingMapper` в `test/core/push/push_incoming_mapper_test.dart`: FCM data map, JSON string, только notification_id, пустой payload
- [x] T008 [P] Дополнить `test/core/push/push_deeplink_handler_test.dart`: notification_id без deeplink; приоритет deeplink над notification_id; JSON order push

**Checkpoint**: Mapper и deeplink handler готовы; можно параллелить US1 и US2

---

## Phase 3: User Story 1 — Обновление счётчика при push в активном приложении (Priority: P1) 🎯 MVP

**Goal**: При foreground push счётчик колокольчика и список уведомлений синхронизируются с сервером без tap

**Independent Test**: Открытое приложение → отправить order push → бейдж обновился в течение 5 с; новое уведомление в списке (quickstart С1)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО) ⚠️

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T009 [P] [US1] Обновить `test/core/push/push_foreground_handler_test.dart`: receive через fake `Stream<PushIncomingMessage>` → вызов refresh unread + reload notifications
- [x] T010 [P] [US1] Unit-тест `FcmForegroundPushService` (mock `FirebaseMessaging.onMessage` или inject stream) в `test/core/push/fcm_foreground_push_service_test.dart`

### Implementation for User Story 1

- [x] T011 [US1] Создать `FcmForegroundPushService` с подпиской на `FirebaseMessaging.onMessage` и маппингом в `PushIncomingMessage` в `lib/core/push/fcm_foreground_push_service.dart`
- [x] T012 [US1] Рефакторинг `PushForegroundHandler` в `lib/core/push/push_foreground_handler.dart`: подписка на `Stream<PushIncomingMessage>` вместо `pushClickStream`; на receive — `unreadCountNotifierProvider.refresh()` + `notificationsNotifierProvider.notifier.reload()`
- [x] T013 [US1] Добавить провайдеры `fcmForegroundPushServiceProvider` и обновить `pushForegroundSetupProvider` в `lib/core/push/push_providers.dart`; подключить только при `AnalyticsBootstrap.isPushEnabled`
- [x] T014 [US1] Убедиться, что `lib/app.dart` вызывает обновлённый `pushForegroundSetupProvider` после bootstrap

**Checkpoint**: Foreground push обновляет бейдж; in-app баннер и tap-навигация — в US2/US3

---

## Phase 4: User Story 2 — Переход в деталь уведомления по нажатию на push (Priority: P1)

**Goal**: Tap на push (фон/cold start) открывает `/home/notifications/{id}` по `data.deeplink` или `data.notification_id`; без парсинга notification.body

**Independent Test**: Push с deeplink + notification_id → tap при закрытом приложении → экран детали (quickstart С3–С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО) ⚠️

- [x] T015 [P] [US2] Unit-тест `PushIncomingMapper.fromPayloadString` для JSON AppMetrica tap payload в `test/core/push/push_incoming_mapper_test.dart`
- [x] T016 [P] [US2] Integration-тест cold start / tap deeplink в `integration_test/push_notification_deeplink_test.dart`: payload `osetrovich://notifications/{id}` → маршрут детали

### Implementation for User Story 2

- [x] T017 [US2] Обновить `lib/core/push/push_navigation_setup.dart`: нормализовать `info.payload` через `PushIncomingMapper` / payload string для `deeplink` перед `handler.navigate` (сохранить legacy raw URL и JSON)
- [x] T018 [US2] Добавить метод `navigationPayload(PushIncomingMessage)` или `toNavigationPayload()` в `lib/core/push/push_incoming_message.dart` для единого формата deeplink при navigate
- [x] T019 [US2] Убедиться, что `PushDeeplinkHandler.navigate` в `lib/core/push/push_deeplink_handler.dart` корректно обрабатывает JSON `{"deeplink":"...","notification_id":"..."}` из AppMetrica tap

**Checkpoint**: Tap на order push ведёт на деталь; foreground счётчик из US1 не ломается

---

## Phase 5: User Story 3 — In-app баннер при push в foreground (Priority: P2)

**Goal**: В foreground показывается MaterialBanner с title/body; tap открывает деталь по тому же deeplink

**Independent Test**: Открытое приложение → push → баннер с текстами → tap → деталь; dismiss без tap — непрочитанное (quickstart С2)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО) ⚠️

- [x] T020 [P] [US3] Unit-тест `PushForegroundHandler`: при receive вызывается `showBanner` с title/body; tap callback передаёт deeplink в `test/core/push/push_foreground_handler_test.dart`

### Implementation for User Story 3

- [x] T021 [US3] Добавить `rootScaffoldMessengerKey` в `lib/app.dart` (MaterialApp.router `scaffoldMessengerKey`) для показа баннера из push handler
- [x] T022 [US3] Реализовать показ `MaterialBanner` в `lib/core/push/push_foreground_handler.dart`: title/body из `PushIncomingMessage`, стили через `ThemeData`/`AppColors`
- [x] T023 [US3] По tap на баннер вызывать `PushDeeplinkHandler.navigate` с payload из сообщения в `lib/core/push/push_foreground_handler.dart` (inject через callback/provider)

**Checkpoint**: Foreground UX полный: бейдж + баннер + навигация

---

## Phase 6: User Story 4 — Уведомление не найдено (Priority: P2)

**Goal**: При 404 или отсутствии id в списке — «Уведомление не найдено»

**Independent Test**: Push с несуществующим notification_id → tap → экран с текстом FR-007 (quickstart С5)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО) ⚠️

- [x] T024 [P] [US4] Widget-тест: id отсутствует после reload → `AppStrings.notificationNotFound` в `test/features/notifications/notification_detail_screen_test.dart`

### Implementation for User Story 4

- [x] T025 [US4] Обновить `lib/features/notifications/presentation/notification_detail_screen.dart`: при отсутствии уведомления в списке после загрузки показывать `notificationNotFound`; опционально `reload()` перед empty state
- [x] T026 [US4] Согласовать обработку 404 в `lib/features/notifications/domain/notifications_notifier.dart` (`markRead` / reload) с текстом `notificationNotFound` на экране детали

**Checkpoint**: Все четыре user story независимо проверяемы по quickstart

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Стабильность, анализ, документация

- [x] T027 [P] Создать `NoOpFcmForegroundPushService` или тестовый fake в `lib/core/push/` для отключения Firebase в widget-тестах без нативного SDK
- [x] T028 Запустить `flutter test test/core/push/` и `flutter test test/features/notifications/`; исправить регрессии
- [x] T029 Выполнить `flutter analyze`; убедиться в отсутствии ошибок
- [x] T030 Пройти сценарии из `specs/017-push-foreground-deeplinks/quickstart.md` (С1–С7) на устройстве с FCM

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: без зависимостей
- **Foundational (Phase 2)**: зависит от Phase 1 (T001–T002 для FCM types) — **блокирует все user stories**
- **US1 (Phase 3)**: после Phase 2 — **MVP**
- **US2 (Phase 4)**: после Phase 2; интеграция с US1 через общий mapper/handler, но тестируется отдельно (tap vs foreground)
- **US3 (Phase 5)**: после US1 (расширяет `PushForegroundHandler`)
- **US4 (Phase 6)**: после Phase 2; может выполняться параллельно с US1–US3
- **Polish (Phase 7)**: после желаемых user stories

### User Story Dependencies

| Story | Приоритет | Зависит от | Независимый тест |
|-------|-----------|------------|------------------|
| US1 | P1 | Phase 2 | quickstart С1 |
| US2 | P1 | Phase 2 | quickstart С3–С4 |
| US3 | P2 | US1 (handler) | quickstart С2 |
| US4 | P2 | Phase 2 | quickstart С5 |

### Within Each User Story

1. Тесты (T009–T010, T015–T016, …) — написать первыми, убедиться что падают
2. Реализация сервисов/handler
3. Wiring providers / app.dart
4. Checkpoint — прогон тестов story

### Parallel Opportunities

- **Phase 1**: T003 параллельно после T001
- **Phase 2**: T007 ∥ T008 после T004–T006
- **US1**: T009 ∥ T010; затем T011 → T012 → T013–T014
- **US2**: T015 ∥ T016; T017–T019 последовательно
- **US3**: T020 параллельно началу T021; T022–T023 последовательно
- **US4**: T024 параллельно US3; T025–T026 последовательно
- **Polish**: T027 ∥ подготовка к T028–T030

---

## Parallel Example: User Story 1

```bash
# Тесты US1 параллельно:
# T009 — test/core/push/push_foreground_handler_test.dart
# T010 — test/core/push/fcm_foreground_push_service_test.dart

# После падения тестов — реализация:
# T011 fcm_foreground_push_service.dart
# T012 push_foreground_handler.dart
# T013 push_providers.dart
```

## Parallel Example: User Story 2 + US4

```bash
# Разные разработчики после Phase 2:
# Dev A: US2 (T015–T019) — push_navigation_setup, integration_test
# Dev B: US4 (T024–T026) — notification_detail_screen
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1: Setup (T001–T003)
2. Phase 2: Foundational (T004–T008)
3. Phase 3: US1 (T009–T014)
4. **STOP and VALIDATE**: quickstart С1 — бейдж обновляется в foreground

### Incremental Delivery

1. Setup + Foundational → mapper и deeplink готовы
2. US1 → foreground счётчик (MVP)
3. US2 → tap на деталь (P1 complete)
4. US3 → in-app баннер
5. US4 → 404 UX
6. Polish → analyze + quickstart

### Suggested MVP Scope

**US1 only** (Phases 1–3): решает основную боль «колокольчик не обновляется в foreground».
US2 критичен для order push с deeplink — рекомендуется сразу после MVP в том же релизе.

---

## Notes

- REST OpenAPI **не меняется**; контракты FCM — `specs/017-push-foreground-deeplinks/contracts/`
- AppMetrica `pushClickStream` остаётся для tap; `firebase_messaging` — только `onMessage` (foreground)
- Не использовать `notification.title`/`body` для маршрутизации (FR-006)
- `PushForegroundHandler` MUST принимать injectable stream для unit-тестов без Firebase

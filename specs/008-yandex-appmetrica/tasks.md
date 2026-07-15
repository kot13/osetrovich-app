---
description: "Список задач для фичи «Интеграция Yandex AppMetrica»"
---

# Tasks: Интеграция Yandex AppMetrica

**Input**: Design documents from `/specs/008-yandex-appmetrica/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и integration тесты включены для каждой user story.

**Organization**: Задачи сгруппированы по user story для независимой реализации и проверки.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Можно выполнять параллельно (разные файлы, нет зависимостей от незавершённых задач)
- **[Story]**: User story из spec.md (US1–US3)
- В описании указан точный путь к файлу

## Path Conventions

- **Flutter (Osetrovich)**: `lib/`, `test/`, `integration_test/`, `openapi/`
- Структура согласно [plan.md](./plan.md)
- REST API не меняется; контракты — `contracts/analytics-events.yaml`, `contracts/push-deeplink.yaml`

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Зависимости SDK, структура каталогов, документация ключей

- [x] T001 Add `appmetrica_plugin` (^3.4.0 или ^4.0.0 по совместимости Flutter) and `appmetrica_push_plugin` (^3.1.0) to `pubspec.yaml`; run `flutter pub get`
- [x] T002 [P] Create directory tree `lib/core/analytics/` and `lib/core/push/` per plan.md
- [x] T003 [P] Create `test/core/analytics/` and stub `integration_test/analytics_funnel_flow_test.dart`
- [x] T004 [P] Document `--dart-define=APPMETRICA_API_KEY=...` in `README.md` (раздел конфигурации / запуск)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Абстракции аналитики и push, инициализация SDK, DI — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T005 Create `lib/core/analytics/analytics_service.dart` abstract interface per research.md §4
- [x] T006 [P] Create `lib/core/analytics/analytics_events.dart` with event names and param keys per `contracts/analytics-events.yaml`
- [x] T007 [P] Create `lib/core/analytics/no_op_analytics_service.dart` (used when API key absent)
- [x] T008 [P] Create `test/core/analytics/fake_analytics_service.dart` recording events for tests
- [x] T009 Create `lib/core/analytics/appmetrica_analytics_service.dart` implementing `AnalyticsService` via `AppMetrica.reportEventWithMap` and `setUserProfileID`
- [x] T010 Create `lib/core/analytics/analytics_providers.dart` with `analyticsServiceProvider` (NoOp vs AppMetrica by `String.fromEnvironment('APPMETRICA_API_KEY')`)
- [x] T011 Initialize `AppMetrica.activate(AppMetricaConfig(...))` in `lib/main.dart` before `runApp` (`logsEnabled: kDebugMode`, `flutterCrashReporting: true`)
- [x] T012 Extend `lib/core/bootstrap/app_bootstrap.dart` to call `reportAppLaunch()` after session restore and categories load
- [x] T013 [P] Create `lib/core/push/push_service.dart` abstract interface (`activate`, `deactivate`, `syncPushEnabled`)
- [x] T014 [P] Create `lib/core/push/push_deeplink_handler.dart` mapping payload → go_router path per `contracts/push-deeplink.yaml`

**Checkpoint**: SDK инициализирован; абстракции и DI готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Воронка «от запуска к заказу» (Priority: P1) 🎯 MVP

**Goal**: 6 событий воронки от `app_launch` до `order_success` с корректными параметрами

**Independent Test**: Пройти сценарий запуск → каталог → товар → корзина → заказ; в `FakeAnalyticsService` или панели AppMetrica видна полная цепочка (quickstart С1)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T015 [P] [US1] Unit-тест имён и параметров событий в `test/core/analytics/analytics_events_test.dart`
- [x] T016 [P] [US1] Unit-тест маппинга `AppMetricaAnalyticsService` в `test/core/analytics/appmetrica_analytics_service_test.dart`
- [x] T017 [P] [US1] Unit-тест `add_to_cart` при increment/add в `test/features/cart/cart_notifier_analytics_test.dart`
- [x] T018 [P] [US1] Integration-тест воронки с `FakeAnalyticsService` в `integration_test/analytics_funnel_flow_test.dart`

### Implementation for User Story 1

- [x] T019 [US1] Report `catalog_view` on first display in `lib/features/catalog/presentation/catalog_screen.dart`
- [x] T020 [US1] Report `product_view` with `product_id` in `lib/features/catalog/presentation/product_detail_screen.dart`
- [x] T021 [US1] Inject `AnalyticsService` into `CartNotifier`; report `add_to_cart` in `lib/features/cart/domain/cart_notifier.dart` (increment/add/addQuantity)
- [x] T022 [US1] Report `checkout_start` when cart is non-empty in `lib/features/cart/presentation/cart_screen.dart`
- [x] T023 [US1] Report `order_success` with `order_id` and `order_total` after successful `createOrder` in `lib/features/cart/domain/checkout_notifier.dart`
- [x] T024 [US1] Call `analytics.setUserId(userId)` on login and clear on logout in `lib/features/auth/domain/auth_session_provider.dart` (internal user id, not phone)

**Checkpoint**: Воронка полностью инструментирована; unit/integration тесты зелёные

---

## Phase 4: User Story 2 — Мониторинг стабильности (краш-рейт) (Priority: P2)

**Goal**: Автоматический сбор Dart/Flutter и нативных крашей в панели AppMetrica

**Independent Test**: Контролируемый краш → перезапуск → отчёт в панели «Стабильность» (quickstart С3)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T025 [P] [US2] Unit-тест конфигурации bootstrap: `flutterCrashReporting: true` when API key present in `test/core/analytics/analytics_bootstrap_test.dart`
- [x] T026 [P] [US2] Unit-тест: `NoOpAnalyticsService` used when `APPMETRICA_API_KEY` empty in `test/core/analytics/analytics_providers_test.dart`

### Implementation for User Story 2

- [x] T027 [US2] Verify `AppMetricaConfig.flutterCrashReporting` and separate debug/release API keys documented in `specs/008-yandex-appmetrica/quickstart.md` (С3, С7); no PII in crash attachments

**Checkpoint**: Краши собираются SDK; конфигурация и тесты bootstrap подтверждают FR-007–FR-008, FR-014

---

## Phase 5: User Story 3 — Push-уведомления через AppMetrica (Priority: P3)

**Goal**: Регистрация push-токена, учёт `pushEnabled` из профиля, deep link по нажатию

**Independent Test**: Включить push в профиле → тестовый push из панели → доставка и переход на целевой экран (quickstart С4–С5)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T028 [P] [US3] Unit-тест маршрутов `PushDeeplinkHandler` (all types + fallback) в `test/core/push/push_deeplink_handler_test.dart`
- [x] T029 [P] [US3] Unit-тест sync `push_enabled` attribute in `test/core/push/appmetrica_push_service_test.dart`

### Implementation for User Story 3

- [x] T030 [P] [US3] Create `lib/core/push/appmetrica_push_service.dart` (`AppMetricaPush.activate`, `tokenStream`, sync with profile preference)
- [x] T031 [US3] Create `lib/core/push/push_providers.dart` wiring `PushService` to Riverpod
- [x] T032 [US3] Call `AppMetricaPush.activate()` in `lib/main.dart` after `AppMetrica.activate` when API key present
- [x] T033 [US3] Extend `lib/features/profile/domain/push_preferences_service.dart` to sync `push_enabled` to AppMetrica user profile and activate/deactivate push SDK
- [x] T034 [US3] Wire push open callback and `PushDeeplinkHandler` navigation in `lib/core/router/app_router.dart` (cold start, background tap)
- [x] T035 [US3] Configure Android FCM for AppMetrica Push in `android/app/build.gradle` and `android/app/src/main/AndroidManifest.xml` (google-services, meta-data per official quick-start)
- [x] T036 [US3] Configure iOS push: `remote-notification` in `ios/Runner/Info.plist` and Push Notifications capability in Xcode project

**Checkpoint**: Push доставляется при включённом переключателе; deep link открывает корректный маршрут

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Качество, документация, финальная валидация

- [x] T037 [P] Run `dart format` and `flutter analyze` on changed files; fix issues
- [x] T038 [P] Add AppMetrica / push setup section to `README.md` (ссылка на `specs/008-yandex-appmetrica/quickstart.md`)
- [ ] T039 Execute manual scenarios С1–С8 from `specs/008-yandex-appmetrica/quickstart.md` on debug device
- [x] T040 [P] Document funnel report setup steps in AppMetrica web console in `specs/008-yandex-appmetrica/quickstart.md` (имена событий из контракта)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Foundational — MVP
- **US2 (Phase 4)**: Depends on Foundational (T011 init); largely verified in parallel with US1
- **US3 (Phase 5)**: Depends on Foundational (T013–T014); integrates with profile push toggle (003)
- **Polish (Phase 6)**: Depends on desired user stories complete

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|-------|
| US1 (P1) | Phase 2 | Независима; не требует push |
| US2 (P2) | Phase 2 T011 | Параллельна с US1 после init |
| US3 (P3) | Phase 2 + profile `pushEnabled` (003) | Deep link использует существующие маршруты |

### Within Each User Story

- Tests MUST be written first and FAIL before implementation
- Core abstractions (Phase 2) before feature wiring
- US3 native config (T035–T036) after Dart push service (T030–T034)

### Parallel Opportunities

- Phase 1: T002, T003, T004 параллельно после T001
- Phase 2: T006–T008, T013–T014 параллельно после T005
- US1 tests: T015–T018 параллельно
- US1 impl: T019–T020 параллельно; T021–T024 последовательно по файлам cart/auth
- US2: T025–T026 параллельно
- US3 tests: T028–T029 параллельно; T030 + T035/T036 параллельно (разные платформы)
- Polish: T037, T038, T040 параллельно

---

## Parallel Example: User Story 1

```bash
# Tests first (parallel):
T015: test/core/analytics/analytics_events_test.dart
T016: test/core/analytics/appmetrica_analytics_service_test.dart
T017: test/features/cart/cart_notifier_analytics_test.dart
T018: integration_test/analytics_funnel_flow_test.dart

# Implementation (partial parallel):
T019: lib/features/catalog/presentation/catalog_screen.dart
T020: lib/features/catalog/presentation/product_detail_screen.dart
# then cart + auth wiring T021–T024
```

---

## Parallel Example: User Story 3

```bash
# After T030 push service:
T035: android/app/...          # Developer A
T036: ios/Runner/...           # Developer B
T028: test/core/push/push_deeplink_handler_test.dart  # Developer C
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (**critical**)
3. Complete Phase 3: User Story 1 (воронка)
4. **STOP and VALIDATE**: `flutter test` + quickstart С1
5. Demo funnel in AppMetrica panel

### Incremental Delivery

1. Setup + Foundational → SDK ready
2. US1 → воронка в production-аналитике (**MVP**)
3. US2 → подтверждение crash reporting (частично уже в T011)
4. US3 → push + deep links
5. Polish → документация и ручная приёмка

### Suggested MVP Scope

**User Story 1 only** (Phase 1 + 2 + 3): даёт бизнес-ценность воронки без нативной настройки FCM/APNs.

---

## Notes

- OpenAPI и `mock_api_client.dart` **не меняются**; `pushEnabled` уже в профиле (003)
- API-ключи AppMetrica **не коммитить**; только `--dart-define`
- `FakeAnalyticsService` / `NoOpAnalyticsService` — обязательны для CI без реального SDK
- При отсутствии `google-services.json` / APNs — US3 помечается как blocked, US1/US2 всё равно работают
- События MUST NOT содержать phone, address, email (FR-013) — проверять в code review

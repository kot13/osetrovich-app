---

description: "Список задач для фичи «Уведомления и доработки главной»"
---

# Tasks: Уведомления и доработки главной

**Input**: Design documents from `/specs/002-notifications-home/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

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

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Зависимости, контракт API, структура каталогов

- [x] T001 Add `url_launcher` to `pubspec.yaml` and run `flutter pub get`
- [x] T002 Merge OpenAPI v0.2.0 from `specs/002-notifications-home/contracts/openapi.yaml` into `openapi/openapi.yaml` (notifications endpoints + Notification schema)
- [x] T003 [P] Create feature directory tree `lib/features/notifications/{data,domain,presentation}/` per plan.md
- [x] T004 [P] Create test directory `test/features/notifications/`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: API-клиент, моки, доменная модель — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T005 [P] Add UI strings to `lib/core/l10n/app_strings.dart`: `notificationsTitle`, `markAllRead`, `notificationsEmpty`, `contactUs`, tab rename constant `tabPromotions = 'Акции'`
- [x] T006 [P] Create `lib/features/notifications/domain/app_notification.dart` per data-model.md
- [x] T007 Extend `lib/core/network/api_client.dart` with `getNotifications`, `getNotificationById`, `markNotificationRead`, `markAllNotificationsRead`
- [x] T008 Update `lib/core/network/api_client.dart` DioClient implementation for new notification endpoints
- [x] T009 Update `lib/core/network/mock_api_client.dart`: mutable `_notifications` list (4 items, 3 unread), implement new methods with in-memory mutations

**Checkpoint**: API и модель готовы — можно начинать US1

---

## Phase 3: User Story 1 — Раздел «Уведомления» (Priority: P1) 🎯 MVP

**Goal**: Список, деталь, mark-read / mark-all, реактивный badge на колокольчике

**Independent Test**: Главная → колокольчик → список → деталь → badge уменьшается;
«Отметить все прочитанным» → badge = 0 (quickstart С1–С5)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T010 [P] [US1] Unit-тест `NotificationsRepository` в `test/features/notifications/notifications_repository_test.dart`
- [x] T011 [P] [US1] Unit-тест `notifications_notifier` (unread count, markRead, markAllRead) в `test/features/notifications/notifications_notifier_test.dart`
- [x] T012 [P] [US1] Widget-тест списка в `test/features/notifications/notifications_list_screen_test.dart` (read/unread styles, mark-all disabled)
- [x] T013 [P] [US1] Widget-тест детали в `test/features/notifications/notification_detail_screen_test.dart`
- [x] T014 [P] [US1] Integration-тест flow в `integration_test/notifications_flow_test.dart`

### Implementation for User Story 1

- [x] T015 [P] [US1] Create `lib/features/notifications/data/notifications_repository.dart` wrapping ApiClient
- [x] T016 [US1] Create `lib/features/notifications/domain/notifications_notifier.dart` with `notificationsNotifierProvider` and `unreadCountProvider`
- [x] T017 [US1] Create `lib/features/notifications/presentation/notifications_list_screen.dart` (AppBar back, mark-all, list, empty state)
- [x] T018 [US1] Create `lib/features/notifications/presentation/notification_detail_screen.dart` (back, title, time, body; markRead on open)
- [x] T019 [US1] Add nested routes `/home/notifications` and `/home/notifications/:id` in `lib/core/router/app_router.dart`
- [x] T020 [US1] Update `lib/features/home/presentation/home_screen.dart`: bell `context.push('/home/notifications')`, badge from `unreadCountProvider`
- [x] T021 [US1] Remove `notificationBadgeProvider` from `lib/features/home/data/home_repository.dart`; preload notifications via `notificationsNotifierProvider` on home if needed

**Checkpoint**: Уведомления полностью работают; badge реактивен

---

## Phase 4: User Story 2 — Главная: баннеры, отступ, «Связаться» (Priority: P2)

**Goal**: Infinite carousel 3 баннеров, отступ от шапки, блок звонка

**Independent Test**: Главная — отступ, 3 баннера по кругу, «Связаться» → tel (quickstart С6–С7)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T022 [P] [US2] Widget-тест `ContactBlock` в `test/features/home/contact_block_test.dart`
- [x] T023 [P] [US2] Widget-тест infinite `BannerCarousel` в `test/features/home/banner_carousel_test.dart`
- [x] T024 [P] [US2] Update `test/features/home/home_screen_test.dart` for top padding and contact block

### Implementation for User Story 2

- [x] T025 [US2] Create `lib/features/home/presentation/contact_block.dart` with phone icon, label «Связаться», `url_launcher` `tel:+78125645548`
- [x] T026 [US2] Update `lib/features/home/presentation/banner_carousel.dart` for infinite loop (modulo PageView, initialPage in middle)
- [x] T027 [US2] Update `lib/features/home/presentation/home_screen.dart`: `Padding(top: 16)` before carousel; insert `ContactBlock` after banners per data-model HomeLayout

**Checkpoint**: Главная соответствует FR-010–FR-012

---

## Phase 5: User Story 3 — Переименование вкладки «Акции» (Priority: P3)

**Goal**: Tab Bar и заголовок экрана — «Акции»

**Independent Test**: Третья вкладка и AppBar promotions — «Акции» (quickstart С8)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T028 [P] [US3] Update `test/features/shell/main_shell_test.dart` — expect `AppStrings.tabPromotions` = «Акции»
- [x] T029 [P] [US3] Update `test/features/promotions/promotions_screen_test.dart` — AppBar title «Акции»

### Implementation for User Story 3

- [x] T030 [US3] Verify `lib/features/promotions/presentation/promotions_screen.dart` and `lib/features/shell/presentation/main_shell.dart` use `AppStrings.tabPromotions` (already «Акции» from T005)

**Checkpoint**: Навигация переименована согласованно

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Качество, регрессии, валидация quickstart

- [x] T031 [P] Update `test/features/home/home_repository_test.dart` if it references removed `notificationBadgeProvider`
- [x] T032 Run `dart format .` and `flutter analyze` — zero issues
- [x] T033 Run full `flutter test` suite — all green
- [x] T034 Run `integration_test/notifications_flow_test.dart` on device/emulator per `quickstart.md` С1–С8 *(опционально; файл добавлен, прогон на устройстве при необходимости)*
- [x] T035 [P] FAB «Отметить все прочитанным» вместо действия в AppBar (полный заголовок)
- [x] T036 [P] Карусель: `viewportFraction` peek + автопрокрутка 5 с

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Старт сразу
- **Foundational (Phase 2)**: После Setup — **блокирует все user stories**
- **US1 (Phase 3)**: После Foundational — **MVP**
- **US2 (Phase 4)**: После Foundational; независима от US1 (можно параллельно после Phase 2)
- **US3 (Phase 5)**: После T005 (строка в app_strings); независима от US1/US2
- **Polish (Phase 6)**: После всех желаемых user stories

### User Story Dependencies

| Story | Зависит от | Независимый тест |
|-------|------------|------------------|
| US1 | Phase 2 | Колокольчик → список → деталь → badge |
| US2 | Phase 2 | Карусель, отступ, «Связаться» |
| US3 | T005 | Вкладка «Акции» |

### Within Each User Story

- Тесты MUST быть написаны первыми и падать до реализации
- data → domain → presentation → router integration
- Story complete перед переходом к следующему приоритету

---

## Parallel Example: User Story 1

```bash
# Параллельно — тесты:
test/features/notifications/notifications_repository_test.dart
test/features/notifications/notifications_notifier_test.dart
test/features/notifications/notifications_list_screen_test.dart
test/features/notifications/notification_detail_screen_test.dart

# Параллельно после T015:
lib/features/notifications/presentation/notifications_list_screen.dart
lib/features/notifications/presentation/notification_detail_screen.dart
```

## Parallel Example: User Story 2

```bash
# Параллельно:
lib/features/home/presentation/contact_block.dart
test/features/home/contact_block_test.dart
test/features/home/banner_carousel_test.dart
```

---

## Implementation Strategy

### MVP First (только User Story 1)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US1
4. **STOP и VALIDATE**: `integration_test/notifications_flow_test.dart` + quickstart С1–С5

### Incremental Delivery

1. Setup + Foundational → API и модель
2. US1 → Уведомления (MVP)
3. US2 → Доработки главной
4. US3 → «Акции»
5. Polish → quickstart полностью

### Suggested MVP Scope

**User Story 1 only** (Phase 1–3): in-app уведомления с реактивным badge — основная ценность фичи.

---

## Notes

- Мок: 4 уведомления, 3 непрочитанных; мутации read сохраняются в сессии мока
- `unreadCountProvider` — единый источник для badge; `GET /notifications/unread-count` остаётся в OpenAPI для совместимости
- Колокольчик: `context.push`, не `go` — сохраняет стек «Главной»
- Всего задач: **36** (Setup 4 + Foundational 5 + US1 12 + US2 6 + US3 3 + Polish 6)

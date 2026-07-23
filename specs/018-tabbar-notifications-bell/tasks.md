---

description: "Список задач для фичи «Колокольчик уведомлений на всех вкладках Tab Bar»"
---

# Tasks: Колокольчик уведомлений на всех вкладках Tab Bar

**Input**: Design documents from `/specs/018-tabbar-notifications-bell/`

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

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Структура каталогов и токен цвета бейджа (без изменений OpenAPI)

- [x] T001 Создать каталог `lib/features/notifications/presentation/widgets/` для `NotificationBellAction`
- [x] T002 [P] Добавить токен цвета бейджа уведомлений (например `badgeNotification` / переиспользовать существующий) в `lib/core/theme/app_colors.dart` — красный фон, белый текст (визуальный паритет с текущим `HomeScreen`)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Переиспользуемый виджет колокольчика, хелпер навигации и маршруты уведомлений во всех ветках shell — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 Создать `openNotificationsList(BuildContext)` и `notificationsListPathForLocation(String matchedLocation)` в `lib/features/notifications/presentation/notification_navigation.dart` (контракт [tab-notifications-routes.yaml](./contracts/tab-notifications-routes.yaml))
- [x] T004 Создить `NotificationBellAction` (иконка, бейдж из `unreadCountProvider`, tap → `openNotificationsList`) в `lib/features/notifications/presentation/widgets/notification_bell_action.dart`
- [x] T005 Вынести фабрику вложенных маршрутов `_notificationRoutes()` в `lib/core/router/app_router.dart` (список + `:id`, те же `NotificationsListScreen` / `NotificationDetailScreen`)
- [x] T006 Подключить `_notificationRoutes()` к веткам `/catalog`, `/promotions`, `/cart`, `/profile` в `lib/core/router/app_router.dart` (ветка `/home` уже содержит маршруты — унифицировать через фабрику)
- [x] T007 [P] Unit-тест резолва путей `notificationsListPathForLocation` в `test/features/notifications/notification_navigation_test.dart`: `/catalog`, `/promotions`, `/cart`, `/profile`, `/home`, вложенные пути
- [x] T008 [P] Widget-тест `NotificationBellAction` в `test/features/notifications/notification_bell_action_test.dart`: иконка; бейдж при count>0; скрыт при 0; tap вызывает push на корректный путь

**Checkpoint**: Виджет и маршруты готовы; можно подключать колокольчик на экранах вкладок

---

## Phase 3: User Story 1 — Колокольчик на каждой корневой вкладке (Priority: P1) 🎯 MVP

**Goal**: Колокольчик с бейджем непрочитанных отображается в шапке всех пяти корневых экранов Tab Bar в едином стиле

**Independent Test**: Открыть каждую вкладку — колокольчик виден; при непрочитанных — бейдж с числом (quickstart С1)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО) ⚠️

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T009 [P] [US1] Дополнить `test/features/catalog/catalog_screen_test.dart`: `find.byIcon(Icons.notifications_none)` в AppBar
- [x] T010 [P] [US1] Дополнить `test/features/promotions/promotions_screen_test.dart`: колокольчик в AppBar
- [x] T011 [P] [US1] Дополнить `test/features/cart/cart_screen_test.dart`: колокольчик в AppBar (пустая и заполненная корзина)
- [x] T012 [P] [US1] Дополнить `test/features/profile/profile_screen_test.dart`: колокольчик для гостя и авторизованного пользователя
- [x] T013 [P] [US1] Регрессия: убедиться, что `test/features/home/home_screen_test.dart` по-прежнему проверяет бейдж после рефакторинга

### Implementation for User Story 1

- [x] T014 [US1] Заменить inline колокольчик на `NotificationBellAction` в `lib/features/home/presentation/home_screen.dart`
- [x] T015 [P] [US1] Добавить `actions: const [NotificationBellAction()]` в `lib/features/catalog/presentation/catalog_screen.dart`
- [x] T016 [P] [US1] Добавить `actions: const [NotificationBellAction()]` в `lib/features/promotions/presentation/promotions_screen.dart`
- [x] T017 [P] [US1] Добавить `actions: const [NotificationBellAction()]` в `lib/features/cart/presentation/cart_screen.dart`
- [x] T018 [US1] Добавить `actions: const [NotificationBellAction()]` в оба `AppBar` (гость и авторизованный) в `lib/features/profile/presentation/profile_screen.dart`

**Checkpoint**: Колокольчик на всех пяти корневых вкладках; US1 проверяется quickstart С1

---

## Phase 4: User Story 2 — Открытие уведомлений с любой вкладки (Priority: P1)

**Goal**: Tap колокольчика с любой вкладки открывает список уведомлений; «Назад» возвращает на ту же вкладку; Tab Bar не переключается на «Главную»

**Independent Test**: С «Корзины» tap bell → список → «Назад» → «Корзина» активна (quickstart С2–С4, SC-004)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО) ⚠️

- [x] T019 [P] [US2] Расширить `test/features/shell/main_shell_test.dart`: с вкладки «Корзина» tap колокольчик → `AppStrings.notificationsTitle`; Tab Bar остаётся на «Корзине»; pop → корневой экран корзины
- [x] T020 [P] [US2] Добавить сценарий навигации с «Каталога» в `test/core/router/app_router_notifications_test.dart`: push `/catalog/notifications`, pop → `/catalog`
- [x] T021 [P] [US2] Расширить `integration_test/notifications_flow_test.dart`: открыть уведомления с не-home вкладки (например «Акции»), вернуться назад на ту же вкладку

### Implementation for User Story 2

- [x] T022 [US2] Убедиться, что `NotificationBellAction` использует `openNotificationsList` (относительный tab root), а не хардкод `/home/notifications` в `lib/features/notifications/presentation/widgets/notification_bell_action.dart`
- [x] T023 [US2] Проверить, что `DeepLinkResolver` и `PushDeeplinkHandler` по-прежнему ведут на `/home/notifications` — регрессия не требует изменений; при необходимости добавить комментарий в `lib/core/deeplink/deeplink_resolver.dart`

**Checkpoint**: Навигация с любой вкладки сохраняет контекст; диплинки без регрессий (quickstart С7)

---

## Phase 5: User Story 3 — Синхронный бейдж на всех вкладках (Priority: P2)

**Goal**: Счётчик непрочитанных на колокольчике одинаков и реактивно обновляется на всех вкладках

**Independent Test**: Прочитать уведомления на одной вкладке → переключиться на другую — бейдж актуален (quickstart С5, SC-003)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО) ⚠️

- [x] T024 [P] [US3] Widget-тест: два `NotificationBellAction` в одном `ProviderScope` с общим `unreadCountProvider` — оба показывают одно число; после override count оба обновляются в `test/features/notifications/notification_bell_action_test.dart`
- [x] T025 [P] [US3] Widget-тест в `test/features/shell/main_shell_test.dart` или `test/features/notifications/notification_bell_sync_test.dart`: переключение вкладок «Главная» ↔ «Каталог» — бейдж с одинаковым значением

### Implementation for User Story 3

- [x] T026 [US3] Убедиться, что `NotificationBellAction` подписан только на `unreadCountProvider` (без дублирования локального state) в `lib/features/notifications/presentation/widgets/notification_bell_action.dart`
- [x] T027 [US3] При необходимости добавить `ref.watch(unreadCountNotifierProvider)` на корневых экранах для eager refresh после auth (только если бейдж не обновляется после входа) — иначе задокументировать в PR, что существующий провайдер достаточен

**Checkpoint**: Бейдж синхронен между вкладками; mark-all-read обновляет все колокольчики ≤ 1 с

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Качество, анализ и финальная валидация

- [x] T028 [P] Запустить `dart format` для изменённых файлов в `lib/features/notifications/`, `lib/core/router/app_router.dart` и затронутых экранов
- [x] T029 Запустить `flutter analyze` — без ошибок
- [x] T030 Запустить `flutter test` для затронутых пакетов: `test/features/notifications/`, `test/features/shell/`, `test/features/home/`, `test/features/catalog/`, `test/features/promotions/`, `test/features/cart/`, `test/features/profile/`, `test/core/router/`, `integration_test/notifications_flow_test.dart`
- [ ] T031 Пройти ручные сценарии из [quickstart.md](./quickstart.md) (С1–С7)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Нет зависимостей — можно начать сразу
- **Foundational (Phase 2)**: Зависит от Phase 1 — **блокирует** все user stories
- **User Stories (Phase 3–5)**:
  - **US1 (Phase 3)**: после Phase 2
  - **US2 (Phase 4)**: после Phase 2; логически после US1 (колокольчик на экранах)
  - **US3 (Phase 5)**: после US1 (колокольчики на всех вкладках); может частично параллелиться с US2
- **Polish (Phase 6)**: После завершения US1–US3

### User Story Dependencies

| Story | Зависит от | Независимая проверка |
|-------|------------|----------------------|
| US1 (P1) | Foundational | Колокольчик на 5 вкладках |
| US2 (P1) | Foundational + US1 | Навигация с сохранением вкладки |
| US3 (P2) | US1 | Синхронный бейдж при переключении вкладок |

### Parallel Opportunities

- **Phase 1**: T002 параллельно с T001
- **Phase 2**: T007, T008 параллельно после T003–T006
- **Phase 3**: T009–T013 параллельно; T015–T017 параллельно после T014
- **Phase 4**: T019–T021 параллельно
- **Phase 5**: T024, T025 параллельно
- **Phase 6**: T028 параллельно с подготовкой к T031

---

## Parallel Example: User Story 1

```bash
# Все widget-тесты экранов вкладок параллельно (после Foundational):
Task T009: test/features/catalog/catalog_screen_test.dart
Task T010: test/features/promotions/promotions_screen_test.dart
Task T011: test/features/cart/cart_screen_test.dart
Task T012: test/features/profile/profile_screen_test.dart

# Подключение колокольчика на 4 вкладках параллельно (после T014):
Task T015: catalog_screen.dart
Task T016: promotions_screen.dart
Task T017: cart_screen.dart
```

---

## Parallel Example: User Story 2

```bash
# Тесты навигации параллельно:
Task T019: test/features/shell/main_shell_test.dart
Task T020: test/core/router/app_router_notifications_test.dart
Task T021: integration_test/notifications_flow_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (**критично**)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: quickstart С1 — колокольчик на всех вкладках
5. Demo / merge при необходимости минимального инкремента

### Incremental Delivery

1. Setup + Foundational → виджет и маршруты готовы
2. US1 → колокольчик везде (MVP для видимости)
3. US2 → корректная навигация с любой вкладки
4. US3 → подтверждение синхронизации бейджа
5. Polish → analyze, test, quickstart

### Suggested MVP Scope

**User Story 1** (Phase 1–3): колокольчик на всех корневых вкладках. Даёт основную пользовательскую ценность (видимость уведомлений). US2 критична для UX навигации — рекомендуется включить в тот же PR сразу после US1.

---

## Notes

- OpenAPI и `MockApiClient` **не меняются** (research §7)
- Диплинки `osetrovich://notifications` остаются на `/home/notifications` — не ломать при рефакторинге
- Вложенные экраны (product detail, promotion article) **без** колокольчика (spec Edge Cases)
- Профиль: два `Scaffold` — не забыть оба `AppBar` (research §6)
- Всего задач: **31** (Setup: 2, Foundational: 6, US1: 10, US2: 5, US3: 4, Polish: 4)

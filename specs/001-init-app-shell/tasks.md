---

description: "Список задач для фичи «Инициализация приложения»"
---

# Tasks: Инициализация приложения

**Input**: Design documents from `/specs/001-init-app-shell/`

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

## Phase 1: Setup (Инициализация проекта)

**Purpose**: Создание Flutter-проекта и базовой конфигурации

- [x] T001 Create Flutter project in repo root: `flutter create . --org ru.osetrovich --project-name osetrovich`
- [x] T002 Add dependencies to `pubspec.yaml`: flutter_riverpod, go_router, dio, flutter_secure_storage, mask_text_input_formatter, mocktail; dev: integration_test, flutter_native_splash
- [x] T003 [P] Copy OpenAPI contract from `specs/001-init-app-shell/contracts/openapi.yaml` to `openapi/openapi.yaml`
- [x] T004 [P] Create feature-first directory tree under `lib/` per plan.md (`core/`, `features/shell|home|catalog|promotions|cart|profile|auth/`)
- [x] T005 [P] Configure `analysis_options.yaml` with flutter_lints and run `flutter pub get`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Тема, сеть, моки, auth storage — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T006 [P] Create brand colors in `lib/core/theme/app_colors.dart` (`#252A2F`, `#213C57`, `#FFB400`, `#F4F5F5`)
- [x] T007 Create `lib/core/theme/app_theme.dart` with ThemeData using AppColors
- [x] T008 [P] Create Russian UI strings in `lib/core/l10n/app_strings.dart` (все тексты из spec.md)
- [x] T009 [P] Create reusable `lib/core/widgets/empty_state.dart` (message + optional action button)
- [x] T010 [P] Create `lib/core/widgets/loading_indicator.dart`
- [x] T011 Create `lib/core/network/dio_client.dart` with base URL config and error mapping
- [x] T012 Create `lib/core/network/auth_interceptor.dart` adding `Authorization: Bearer` from secure storage
- [x] T013 Create `lib/core/network/mock_api_client.dart` implementing all endpoints from `openapi/openapi.yaml` (mock code `123456`, 12 categories, 3 banners, unread count `3`)
- [x] T014 Create `lib/features/auth/data/secure_token_storage.dart` using flutter_secure_storage
- [x] T015 [P] Create `lib/features/auth/domain/auth_session.dart` model per data-model.md
- [x] T016 Create `lib/features/auth/domain/auth_session_provider.dart` Riverpod Notifier (authenticated / unauthenticated)
- [x] T017 Create `lib/app.dart` with ProviderScope and MaterialApp.router theme
- [x] T018 Update `lib/main.dart` to run App with mock API flag enabled

**Checkpoint**: Foundation ready — можно начинать US1

---

## Phase 3: User Story 1 — Навигация Tab Bar (Priority: P1) 🎯 MVP

**Goal**: Пять вкладок с сохранением состояния при переключении

**Independent Test**: Запустить приложение, переключить все 5 вкладок; активная вкладка
выделена; состояние «Корзина» сохраняется при уходе и возврате (quickstart С1)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T019 [P] [US1] Widget-тест 5 вкладок и переключения в `test/features/shell/main_shell_test.dart`
- [x] T020 [P] [US1] Integration-тест навигации в `integration_test/app_navigation_test.dart`

### Implementation for User Story 1

- [x] T021 [US1] Create `lib/features/shell/presentation/main_shell.dart` with BottomNavigationBar (5 labels from app_strings)
- [x] T022 [P] [US1] Create placeholder screens: `lib/features/home/presentation/home_screen.dart`, `lib/features/catalog/presentation/catalog_screen.dart`, `lib/features/promotions/presentation/promotions_screen.dart`, `lib/features/cart/presentation/cart_screen.dart`, `lib/features/profile/presentation/profile_screen.dart`
- [x] T023 [US1] Configure `lib/core/router/app_router.dart` with StatefulShellRoute.indexedStack (routes `/home`, `/catalog`, `/promotions`, `/cart`, `/profile`)
- [x] T024 [US1] Wire `go_router` in `lib/app.dart` via routerProvider

**Checkpoint**: MVP — приложение с 5 вкладками работает; можно демонстрировать навигацию

---

## Phase 4: User Story 2 — Авторизация по телефону и СМС (Priority: P2)

**Goal**: Полный цикл SMS-авторизации с JWT и таймером 60 с

**Independent Test**: Профиль → Войти → телефон → код `123456` → профиль без заглушки
(quickstart С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T025 [P] [US2] Unit-тест валидации телефона в `test/features/auth/phone_validator_test.dart`
- [x] T026 [P] [US2] Unit-тест таймера resend 60 с в `test/features/auth/sms_resend_timer_test.dart`
- [x] T027 [P] [US2] Unit-тест `AuthRepository` (mock) в `test/features/auth/auth_repository_test.dart`
- [x] T028 [P] [US2] Widget-тест `phone_input_screen` в `test/features/auth/phone_input_screen_test.dart`
- [x] T029 [P] [US2] Widget-тест `sms_code_screen` (back, disabled resend, timer) в `test/features/auth/sms_code_screen_test.dart`
- [x] T030 [P] [US2] Integration-тест auth flow в `integration_test/auth_flow_test.dart`

### Implementation for User Story 2

- [x] T031 [P] [US2] Create DTOs and `lib/features/auth/data/auth_repository.dart` (`requestSms`, `verifySms`, `refresh`, `logout`)
- [x] T032 [US2] Create `lib/features/auth/domain/sms_auth_notifier.dart` (phone step, sms step, 60s timer, error states)
- [x] T033 [US2] Create `lib/features/auth/presentation/phone_input_screen.dart` with +7 mask and continue button
- [x] T034 [US2] Create `lib/features/auth/presentation/sms_code_screen.dart` (6 digits, back, resend + countdown)
- [x] T035 [US2] Add routes `/auth/phone` and `/auth/sms` to `lib/core/router/app_router.dart` (full-screen, outside shell)
- [x] T036 [US2] On successful verify: persist JWT via `secure_token_storage.dart`, update `auth_session_provider.dart`

**Checkpoint**: Авторизация работает end-to-end с мок-API

---

## Phase 5: User Story 3 — Пустые состояния разделов (Priority: P3)

**Goal**: Заглушки Корзины, Профиля (guest), Акции и новости; каталог — в US5

**Independent Test**: Открыть Корзину, Профиль (без входа), Акции — корректные тексты и
кнопки (quickstart С2, С3, С7)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T037 [P] [US3] Widget-тест пустой корзины в `test/features/cart/cart_screen_test.dart`
- [x] T038 [P] [US3] Widget-тест guest-профиля в `test/features/profile/profile_screen_test.dart`
- [x] T039 [P] [US3] Widget-тест пустых акций в `test/features/promotions/promotions_screen_test.dart`

### Implementation for User Story 3

- [x] T040 [US3] Update `lib/features/cart/presentation/cart_screen.dart`: «В корзине пока пусто» + кнопка перехода в `/catalog` (goBranch index 1)
- [x] T041 [US3] Update `lib/features/profile/presentation/profile_screen.dart`: guest — «Необходима авторизация» + кнопка `/auth/phone`; authed — placeholder «Вы вошли»
- [x] T042 [US3] Update `lib/features/promotions/presentation/promotions_screen.dart`: EmptyState «Ничего не нашлось»

**Checkpoint**: Три раздела с пустыми состояниями и CTA где требуется

---

## Phase 6: User Story 4 — Главная: шапка, баннеры, авторизация (Priority: P4)

**Goal**: Шапка с уведомлениями, карусель баннеров, блок «Авторизуйтесь»

**Independent Test**: Вкладка «Главная» — шапка, баннеры, блок auth для guest (quickstart С5)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО)

- [x] T043 [P] [US4] Unit-тест `HomeRepository` в `test/features/home/home_repository_test.dart`
- [x] T044 [P] [US4] Widget-тест `home_screen` в `test/features/home/home_screen_test.dart`

### Implementation for User Story 4

- [x] T045 [P] [US4] Create models `lib/features/home/domain/banner.dart` and `lib/features/home/domain/notification_badge.dart`
- [x] T046 [P] [US4] Create `lib/features/home/data/home_repository.dart` (`GET /home/banners`, `GET /notifications/unread-count`)
- [x] T047 [US4] Create `lib/features/home/presentation/banner_carousel.dart` PageView carousel
- [x] T048 [US4] Create `lib/features/home/presentation/auth_prompt_banner.dart` visible when unauthenticated
- [x] T049 [US4] Replace `lib/features/home/presentation/home_screen.dart`: AppBar with bell + badge count, carousel, auth prompt; bell tap — no-op

**Checkpoint**: Главная полностью соответствует FR-010–FR-012

---

## Phase 7: User Story 5 — Каталог: Filter Chips (Priority: P5)

**Goal**: 12 категорий из API при старте, chips, пустое состояние «Ничего не нашлось»

**Independent Test**: После cold start открыть Каталог ≤ 3 с, 12 chips, «Все» активен,
«Ничего не нашлось» (quickstart С6)

### Tests for User Story 5 (ОБЯЗАТЕЛЬНО)

- [x] T050 [P] [US5] Unit-тест `CatalogRepository` в `test/features/catalog/catalog_repository_test.dart`
- [x] T051 [P] [US5] Widget-тест chips и empty state в `test/features/catalog/catalog_screen_test.dart`

### Implementation for User Story 5

- [x] T052 [P] [US5] Create `lib/features/catalog/domain/catalog_category.dart` per data-model.md
- [x] T053 [US5] Create `lib/features/catalog/data/catalog_repository.dart` for `GET /catalog/categories`
- [x] T054 [US5] Create `lib/features/catalog/domain/categories_provider.dart` AsyncNotifier; load on app startup in `lib/main.dart` or startup provider
- [x] T055 [US5] Create `lib/features/catalog/presentation/category_chips.dart` horizontal ChoiceChip row
- [x] T056 [US5] Replace `lib/features/catalog/presentation/catalog_screen.dart`: chips + selected state + EmptyState «Ничего не нашлось» + loading/error retry

**Checkpoint**: Каталог с категориями и пустым списком товаров готов

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Финальная интеграция, качество, валидация quickstart

- [x] T057 [P] Hide «Авторизуйтесь» on Home when `auth_session_provider` is authenticated (verify `auth_prompt_banner.dart`)
- [x] T058 [P] Ensure 100% UI strings use `app_strings.dart` (no hardcoded Russian in widgets)
- [x] T059 Run `dart format .` and `flutter analyze` — zero issues
- [x] T060 Run full `flutter test` suite — all green
- [x] T062 [P] Configure native splash in `pubspec.yaml` (`flutter_native_splash`, logo on `#213C57`, Android 12 image); run `dart run flutter_native_splash:create`
- [x] T063 [P] Set display name «Осетрович» in `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `lib/app.dart`
- [ ] T061 Run `integration_test/` on device/emulator per `quickstart.md` scenarios С0–С8

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Старт сразу
- **Foundational (Phase 2)**: После Setup — **блокирует все user stories**
- **US1 (Phase 3)**: После Foundational — **MVP**
- **US2 (Phase 4)**: После Foundational; независима от US3–US5, но нужна для guest→auth в US3
- **US3 (Phase 5)**: После US1 (экраны существуют); профиль guest лучше после US2 (маршрут auth)
- **US4 (Phase 6)**: После US1 + Foundational; auth prompt после US2
- **US5 (Phase 7)**: После Foundational (mock categories); экран-каркас из US1
- **Polish (Phase 8)**: После всех желаемых user stories

### User Story Dependencies

| Story | Зависит от | Независимый тест |
|-------|------------|------------------|
| US1 | Phase 2 | 5 вкладок, переключение |
| US2 | Phase 2 | Auth flow с мок-API |
| US3 | US1, US2 (профиль) | Empty states cart/profile/promotions |
| US4 | US1, US2 (auth banner) | Home header + banners |
| US5 | US1, Phase 2 | Catalog chips + empty |

### Within Each User Story

- Тесты MUST быть написаны первыми и падать до реализации
- data → domain → presentation
- Story complete перед переходом к следующему приоритету

---

## Parallel Example: User Story 2

```bash
# Параллельно — unit/widget тесты:
test/features/auth/phone_validator_test.dart
test/features/auth/sms_resend_timer_test.dart
test/features/auth/auth_repository_test.dart
test/features/auth/phone_input_screen_test.dart
test/features/auth/sms_code_screen_test.dart

# Параллельно после T031:
# DTO можно писать параллельно с тестами до implementation
```

## Parallel Example: User Story 4

```bash
# Параллельно:
lib/features/home/domain/banner.dart
lib/features/home/domain/notification_badge.dart
lib/features/home/data/home_repository.dart
test/features/home/home_repository_test.dart
```

---

## Implementation Strategy

### MVP First (только User Story 1)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US1
4. **STOP и VALIDATE**: `integration_test/app_navigation_test.dart` + quickstart С1

### Incremental Delivery

1. Setup + Foundational → инфраструктура
2. US1 → Tab Bar (MVP demo)
3. US2 → Auth
4. US3 → Empty states
5. US4 → Home
6. US5 → Catalog
7. Polish → quickstart полностью

### Suggested MVP Scope

**User Story 1 only** (Phase 1–3): приложение с 5 вкладками и placeholder-экранами —
минимум для демо навигации osetrovich.ru.

---

## Notes

- Мок-API: код `123456` валиден; иные коды → `INVALID_CODE`
- Категории в моке: 12 штук с `id: all` первым (см. openapi.yaml + spec FR-013)
- Колокольчик уведомлений: отображение only, без навигации (out of scope)
- Кнопка «Поддержка» на «Главной» не реализуется (out of scope)
- Сплэш: `assets/images/osetrovich_logo.png`, Android 12 — `osetrovich_logo_android12.png`
- Всего задач: **63** (Setup 5 + Foundational 13 + US1 6 + US2 12 + US3 6 + US4 7 + US5 7 + Polish 7)

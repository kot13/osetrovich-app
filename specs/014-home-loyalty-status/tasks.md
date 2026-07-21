---

description: "Список задач для фичи «Блок статуса лояльности на главной»"
---

# Tasks: Блок статуса лояльности на главной

**Input**: Design documents from `/specs/014-home-loyalty-status/`

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

**Purpose**: Контракт API, строки локализации

- [x] T001 Merge OpenAPI v0.12.4 from `specs/014-home-loyalty-status/contracts/openapi.yaml` into `openapi/openapi.yaml` (`UserProfile.loyaltyStatus`, `UserProfile.discount`, `UserProfile.card`, schema `LoyaltyStatus`; bump `info.version` to `0.12.4`)
- [x] T002 [P] Add home loyalty strings to `lib/core/l10n/app_strings.dart` per research.md §9: `homeAuthButton` («Авторизоваться»), `homeLoyaltyDiscount` («Скидка {percent}%»), `homeLoyaltyCard` («Карта {number}»)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели профиля, моки, domain-правила слота — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 [P] Create `lib/features/profile/domain/loyalty_status.dart`: enum `LoyaltyStatus` (superVip, vip, elite, premium, friend, clubMember), `loyaltyStatusFromJson(String?)`, `loyaltyStatusToJson(LoyaltyStatus)` per data-model.md §2
- [x] T004 [P] Create `lib/features/profile/domain/loyalty_status_label.dart` with `loyaltyStatusLabel(LoyaltyStatus) → String` (6 UI labels per spec FR-006)
- [x] T005 Extend `lib/features/profile/domain/user_profile.dart`: add `loyaltyStatus`, `discount` (required, default 0), `card`; update `fromJson`, `copyWith`, constructor; import `loyalty_status.dart`
- [x] T006 Update `lib/core/network/mock_api_client.dart` `ensureProfile(String phone)`: set `loyaltyStatus`, `discount`, `card` per phone table in research.md §7 (`+79001111111` premium/10/1234567890; `+79002222222` vip/0/null; `+79003333333` null/0/null; others club_member/5/9876543210)
- [x] T007 [P] Create `lib/features/home/domain/home_profile_slot_ui_state.dart`: enum `HomeProfileSlotMode` (guestAuth, hidden, loyalty), pure `buildHomeProfileSlotUiState({required bool isAuthenticated, required AsyncValue<UserProfile?> profile})` per data-model.md §3
- [x] T008 [P] Unit-тест `loyaltyStatusLabel` и `loyaltyStatusFromJson` (все 6 значений + null) в `test/features/profile/loyalty_status_label_test.dart`
- [x] T009 [P] Unit-тест `buildHomeProfileSlotUiState` (guest → guestAuth; auth+loading/error/no status → hidden; auth+loyaltyStatus → loyalty) в `test/features/home/home_profile_slot_ui_state_test.dart`
- [x] T010 [P] Extend `test/core/network/mock_api_client_test.dart`: assert `getProfile()` returns loyalty fields for demo phone `+79001111111`
- [x] T011 [P] Update `test/features/profile/profile_repository_test.dart` and `test/features/profile/profile_notifier_test.dart`: add `discount: 0` (and loyalty fields where needed) to `UserProfile` test fixtures

**Checkpoint**: Модель, моки и правила слота готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Призыв к авторизации вместо «Связаться» (Priority: P1) 🎯 MVP

**Goal**: Гость видит «Авторизоваться» вместо «Связаться»; нижний баннер «Авторизуйтесь» убран

**Independent Test**: Открыть «Главную» без авторизации → нет «Связаться», есть «Авторизоваться» → tap → `/auth/phone` (quickstart С1)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T012 [P] [US1] Widget-тест `HomeAuthButton` в `test/features/home/home_auth_button_test.dart` (renders `AppStrings.homeAuthButton`; tap navigates to `/auth/phone`)
- [x] T013 [P] [US1] Update widget-тест `test/features/home/home_screen_test.dart` for guest: expect `homeAuthButton`, no `contactUs`, no `authPrompt` banner

### Implementation for User Story 1

- [x] T014 [P] [US1] Create `lib/features/home/presentation/home_auth_button.dart`: CTA card styled like former `HomeContactButton` (`AppColors`, padding 16, radius 12); `onTap` → `context.push('/auth/phone')`
- [x] T015 [US1] Create `lib/features/home/presentation/home_profile_slot.dart`: accepts `HomeProfileSlotMode`; renders `HomeAuthButton` for `guestAuth`, `SizedBox.shrink` for `hidden` and `loyalty` (loyalty branch stub until US2)
- [x] T016 [US1] Update `lib/features/home/presentation/home_screen.dart`: remove `HomeContactButton` and bottom `AuthPromptBanner`; insert `HomeProfileSlot` below banners wired via `buildHomeProfileSlotUiState(isAuthenticated, const AsyncData(null))` for guests / `AsyncData(null)` when not watching profile yet

**Checkpoint**: Гостевая главная соответствует US1; зона под баннерами готова для loyalty-блока

---

## Phase 4: User Story 2 — Блок статуса лояльности (Priority: P1)

**Goal**: Авторизованный покупатель со статусом видит карточку лояльности; данные из профиля; pull-to-refresh обновляет профиль

**Independent Test**: Войти под `+79001111111` → блок Premium + скидка + карта; `+79002222222` → VIP без скидки; `+79003333333` → пустая зона (quickstart С2–С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T017 [P] [US2] Create `lib/features/home/domain/home_loyalty_status_ui_model.dart` with `HomeLoyaltyStatusUiModel` and `buildHomeLoyaltyStatusUiModel(UserProfile)` (requires non-null `loyaltyStatus`; discount line only if > 0; card line only if non-empty)
- [x] T018 [P] [US2] Unit-тест `buildHomeLoyaltyStatusUiModel` в `test/features/home/home_loyalty_status_ui_model_test.dart` (discount 0 hides percent; empty card hides card line; all status labels)
- [x] T019 [P] [US2] Widget-тест `HomeLoyaltyStatusCard` в `test/features/home/home_loyalty_status_card_test.dart` (status title visible; discount/card rows conditional)
- [x] T020 [P] [US2] Update `test/features/home/home_screen_test.dart` for authenticated user with loyalty profile override: expect loyalty card content; no auth button

### Implementation for User Story 2

- [x] T021 [P] [US2] Create `lib/features/home/presentation/home_loyalty_status_card.dart`: informational card (`AppColors`); shows status label, optional discount (`AppStrings.homeLoyaltyDiscount`), optional card (`AppStrings.homeLoyaltyCard`); no navigation on tap
- [x] T022 [US2] Update `lib/features/home/presentation/home_profile_slot.dart`: for `loyalty` mode render `HomeLoyaltyStatusCard` with `HomeLoyaltyStatusUiModel`
- [x] T023 [US2] Update `lib/features/home/presentation/home_screen.dart`: when `isAuthenticated`, `ref.watch(profileNotifierProvider)`; pass `AsyncValue` into `buildHomeProfileSlotUiState`; in `_refreshHome` add `profileNotifier.refresh()` for authenticated users (FR-010)

**Checkpoint**: Блок лояльности и загрузка профиля на главной работают по US2

---

## Phase 5: User Story 3 — Смена сессии и ошибки загрузки (Priority: P2)

**Goal**: Logout/login меняет слот реактивно; ошибка профиля не показывает чужие данные; refresh повторяет загрузку

**Independent Test**: Login → loyalty block → logout → «Авторизоваться»; auth + profile error → hidden slot (quickstart С5–С6)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T024 [P] [US3] Extend `test/features/home/home_profile_slot_ui_state_test.dart`: `AsyncError` and `AsyncLoading` → `hidden` when authenticated
- [x] T025 [P] [US3] Update `test/features/home/home_screen_test.dart`: simulate logout (session null) → auth button returns; simulate `profileNotifier` error → no loyalty card
- [x] T026 [P] [US3] Extend `integration_test/home_screen_flow_test.dart`: scenarios guest auth CTA, loyalty block after login `+79001111111`, empty slot for `+79003333333`

### Implementation for User Story 3

- [x] T027 [US3] Verify `lib/features/home/presentation/home_screen.dart` rebuilds slot on `authSessionProvider` and `profileNotifierProvider` changes without stale loyalty data (no manual cache outside providers)
- [x] T028 [US3] Ensure `profileNotifier.clear()` on logout (existing `lib/features/profile/presentation/profile_screen.dart`) leaves home slot in `guestAuth` state — fix wiring only if test T025 fails

**Checkpoint**: US3 сценарии проходят; персональные данные не «залипают» между сессиями

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, регрессии, валидация quickstart

- [x] T029 [P] Remove `lib/features/home/presentation/home_contact_button.dart` if no remaining imports (grep repo); delete `test/features/home/home_contact_button_test.dart` if it exists
- [x] T030 [P] Update `test/features/home/contact_block_test.dart` only if broken by shared strings — profile ContactBlock MUST remain unchanged (quickstart С7)
- [x] T031 Run `dart format` on changed Dart files and `flutter analyze` — zero issues
- [x] T032 Run `flutter test` and `flutter test integration_test/home_screen_flow_test.dart` — all green
- [x] T033 Validate manual scenarios from `specs/014-home-loyalty-status/quickstart.md` (С1–С7)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS** all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — MVP без loyalty card body
- **US2 (Phase 4)**: Depends on Phase 2; integrates with US1 `HomeProfileSlot`
- **US3 (Phase 5)**: Depends on US1 + US2 (session + profile wiring)
- **Polish (Phase 6)**: Depends on US1–US3

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| US1 (P1) | Foundational | Guest home: auth CTA, no contact |
| US2 (P1) | Foundational, US1 slot shell | Logged-in loyalty card |
| US3 (P2) | US1, US2 | Logout/login/error refresh |

### Parallel Opportunities

- **Phase 1**: T002 ∥ T001 (after T001 paths known — T002 fully parallel)
- **Phase 2**: T003, T004, T007, T008, T009, T010, T011 parallel after T005/T006 sequence: T003+T004 → T005 → T006; tests T008–T011 parallel after models
- **US1 tests**: T012 ∥ T013; **US1 impl**: T014 → T015 → T016
- **US2**: T017–T020 parallel tests; T021 ∥ T022 after T017; T023 last
- **US3**: T024–T026 parallel; T027–T028 sequential
- **Polish**: T029–T030 parallel

### Parallel Example: Foundational

```bash
# After T005–T006 complete, in parallel:
flutter test test/features/profile/loyalty_status_label_test.dart
flutter test test/features/home/home_profile_slot_ui_state_test.dart
flutter test test/core/network/mock_api_client_test.dart
```

### Parallel Example: User Story 2

```bash
# Tests in parallel:
flutter test test/features/home/home_loyalty_status_ui_model_test.dart
flutter test test/features/home/home_loyalty_status_card_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 + Phase 2
2. Complete Phase 3 (US1)
3. **STOP and VALIDATE**: quickstart С1
4. Demo: гостевая главная с «Авторизоваться»

### Incremental Delivery

1. Setup + Foundational → модель и моки готовы
2. US1 → гостевая главная (MVP)
3. US2 → блок лояльности (основная ценность)
4. US3 → надёжность сессий
5. Polish → quickstart С1–С7

### Suggested MVP Scope

**User Story 1** (Phase 3) после Foundational — минимальный shippable increment для гостей.

---

## Notes

- Порядок contract-first: T001 → T005/T006 → UI (конституция VI)
- `profileNotifierProvider` уже существует — не дублировать провайдер на главной
- Скидка 0 скрывает **строку** скидки, не весь блок (spec Assumptions)
- Всего задач: **33** (T001–T033); US1: 5 задач, US2: 7 задач, US3: 5 задач

## Post-MVP (реализовано в той же ветке)

- Тёмная карточка лояльности (`HomeLoyaltyStatusCard`): двухколоночный layout, бейдж
  «Максимальный уровень» для VIP/Super VIP, копирование номера карты со snackbar
- Скидка в корзине: `cart_loyalty_discount.dart`, расширение `OrderTotals`, UI в
  `CartOrderSummary`
- Спека обновлена: User Story 4, FR-014–FR-019, статус **Implemented**

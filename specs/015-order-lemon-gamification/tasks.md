---

description: "Список задач для фичи «Геймификация — Делай заказы, получай призы»"
---

# Tasks: Геймификация «Делай заказы — получай призы»

**Input**: Design documents from `/specs/015-order-lemon-gamification/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

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

**Purpose**: Контракт API, строки локализации

- [x] T001 Merge OpenAPI v0.12.5 from `specs/015-order-lemon-gamification/contracts/openapi.yaml` into `openapi/openapi.yaml` (`UserProfile.lemons`, `UserProfile.lemonGift`, schema `LemonGiftPreview`, `OrderLine.isGift`; bump `info.version` to `0.12.5`)
- [x] T002 [P] Add gamification strings to `lib/core/l10n/app_strings.dart` per research.md §9: `homeLemonGamificationTitle` («Делай заказы — получай призы»), `homeLemonGamificationCaption` («Один заказ = Один лимон»), `cartGiftLabel` («Подарок»)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели профиля/заказа, моки с лимонами — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 [P] Create `lib/features/profile/domain/lemon_gift_preview.dart`: class `LemonGiftPreview` with `productId`, `name`, `weightLabel`, `imageUrl`; `fromJson` / `toJson` per data-model.md §2
- [x] T004 Extend `lib/features/profile/domain/user_profile.dart`: add required `lemons` (int, default 0) and optional `lemonGift`; update `fromJson`, `copyWith`, constructor; import `lemon_gift_preview.dart`
- [x] T005 Extend `lib/features/cart/domain/order.dart` `OrderLine`: add `isGift` (bool, default `false`); update `fromJson` / constructor per contracts `OrderLine.isGift`
- [x] T006 Update `lib/core/network/mock_api_client.dart` `ensureProfile(String phone)`: set `lemons` and `lemonGift` per research.md §8 (`+79004444444` → 0/null; `+79005555555` → 7/null; `+79006666666` → 10/gift preview; others → 3/null)
- [x] T007 Update `lib/core/network/mock_api_client.dart` `createOrder`: on success if `lemons == 10` append gift `OrderLine` (`isGift: true`, `priceRub: 0`) from `lemonGift`, then set `lemons = 1`; else `lemons = min(lemons + 1, 10)`; rebuild `lemonGift` in profile when `lemons == 10`
- [x] T008 [P] Unit-тест парсинга `LemonGiftPreview` и `UserProfile.lemons`/`lemonGift` в `test/features/profile/lemon_gift_preview_test.dart` (lemons 0–10; lemonGift null when < 10)
- [x] T009 [P] Extend `test/core/network/mock_api_client_test.dart`: `getProfile()` returns `lemons` for demo phones; `createOrder` increments lemons 0→1 and 9→10; at 10 lemons order adds `isGift` line and resets to 1
- [x] T010 [P] Update `test/features/profile/profile_repository_test.dart`, `test/features/profile/profile_notifier_test.dart`, and other `UserProfile` fixtures repo-wide: add `lemons: 0` (and `lemonGift: null`) to constructors/`copyWith` defaults

**Checkpoint**: Модель, моки и контракт готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Блок прогресса на главной (Priority: P1) 🎯 MVP

**Goal**: Авторизованный покупатель видит блок «Делай заказы — получай призы» со шкалой из 10 лимонов и подписью; гость блок не видит

**Independent Test**: Войти под `+79005555555` → 7 жёлтых и 3 серых лимона; гость → блок отсутствует (quickstart С1–С3)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T011 [P] [US1] Unit-тест `buildHomeLemonGamificationUiModel` в `test/features/home/home_lemon_gamification_ui_model_test.dart` (lemons 0→0 filled; 7→7; 10→10; clamp negatives)
- [x] T012 [P] [US1] Widget-тест `HomeLemonGamificationCard` в `test/features/home/home_lemon_gamification_card_test.dart` (title, caption, 10 lemon icons with correct filled count)
- [x] T013 [P] [US1] Update `test/features/home/home_screen_test.dart`: authenticated profile with `lemons: 7` shows gamification card; guest does not; loading/error profile hides card

### Implementation for User Story 1

- [x] T014 [P] [US1] Create `lib/features/home/domain/home_lemon_gamification_ui_model.dart` with `HomeLemonGamificationUiModel` (`filledCount`, `totalSlots = 10`) and `buildHomeLemonGamificationUiModel(int lemons)` per data-model.md §4
- [x] T015 [P] [US1] Create `lib/features/home/presentation/lemon_progress_icon.dart`: `LemonProgressIcon({required bool filled})` — filled `AppColors.accent`, empty `#BDBDBD`, size ~24 logical px
- [x] T016 [US1] Create `lib/features/home/presentation/home_lemon_gamification_card.dart`: card with `AppStrings.homeLemonGamificationTitle`, `Row` of 10 `LemonProgressIcon`, `AppStrings.homeLemonGamificationCaption`; styling via `AppColors` / `ThemeData`
- [x] T017 [US1] Update `lib/features/home/presentation/home_screen.dart`: after `HomeProfileSlot`, before `HomeWeeklyProductsSection`, render `HomeLemonGamificationCard` when `isAuthenticated && profileAsync?.hasValue == true && profileAsync?.hasError != true`; pass `profile.lemons`

**Checkpoint**: Блок лимонов на главной работает для авторизованных; гости не видят блок

---

## Phase 4: User Story 2 — Начисление лимона за заказ (Priority: P1)

**Goal**: После успешного оформления заказа счётчик лимонов в профиле увеличивается; шкала на главной обновляется без перезапуска

**Independent Test**: Войти под `+79004444444` (0 лимонов) → оформить заказ → на главной 1 жёлтый лимон (quickstart С7, С10)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T018 [P] [US2] Extend `test/core/network/mock_api_client_test.dart`: failed/invalid `createOrder` does not change `lemons`; successful order from 9→10
- [x] T019 [P] [US2] Update `test/features/cart/checkout_notifier_test.dart`: after successful `submit`, verify `profileNotifier.refresh()` is triggered (mock/ref override)

### Implementation for User Story 2

- [x] T020 [US2] Update `lib/features/cart/domain/checkout_notifier.dart`: after successful `createOrder`, call `ref.read(profileNotifierProvider.notifier).refresh()` before returning order (research.md §11)
- [x] T021 [US2] Verify `lib/features/home/presentation/home_screen.dart` rebuilds `HomeLemonGamificationCard` when `profileNotifierProvider` updates after checkout (no local lemon cache)

**Checkpoint**: Начисление лимонов через мок и обновление UI после заказа работают

---

## Phase 5: User Story 3 — Подарок к 11-му заказу в корзине (Priority: P1)

**Goal**: При 10 лимонах и непустой корзине в списке товаров отображается строка «Подарок» (read-only, 0 ₽); после заказа с подарком `lemons = 1`

**Independent Test**: Войти под `+79006666666` → добавить товар → в корзине «Подарок»; оформить → 1 лимон на главной (quickstart С4, С6, С8)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T022 [P] [US3] Unit-тест правил `cartDisplayLinesProvider` в `test/features/cart/cart_gift_line_test.dart` (gift when auth+lemons==10+cart non-empty+lemonGift; no gift when lemons<10 or empty cart or guest)
- [x] T023 [P] [US3] Update `test/features/cart/cart_line_tile_test.dart`: gift line shows `AppStrings.cartGiftLabel`, no `QuantityPriceBar`, price 0 ₽
- [x] T024 [P] [US3] Update `test/features/cart/cart_order_summary_test.dart` if needed: gift line does not inflate `itemsSubtotalRub`

### Implementation for User Story 3

- [x] T025 [US3] Extend `lib/features/cart/domain/cart_line_item_view.dart`: add `isGift` (default `false`); factory `CartLineItemView.fromLemonGift(LemonGiftPreview)` with `priceRub: 0`, `quantity: 1`, `isGift: true`
- [x] T026 [US3] Create `lib/features/cart/domain/cart_display_lines_provider.dart`: combine `cartLinesProvider` + `profileNotifierProvider` + `cartNotifierProvider` per data-model.md §6
- [x] T027 [US3] Update `lib/features/cart/presentation/widgets/cart_line_tile.dart`: if `line.isGift` — show `AppStrings.cartGiftLabel`, hide quantity controls, show weight/image from gift; non-removable
- [x] T028 [US3] Update `lib/features/cart/presentation/cart_screen.dart`: replace `cartLinesProvider` with `cartDisplayLinesProvider` for the product list
- [x] T029 [US3] Verify `lib/features/cart/domain/order_totals_provider.dart` / `cart_loyalty_discount.dart`: gift lines (`isGift` or price 0) excluded from loyalty discount base and do not affect subtotal incorrectly

**Checkpoint**: Подарок в корзине и сброс до 1 лимона после заказа работают

---

## Phase 6: User Story 4 — Размещение блока на главной (Priority: P2)

**Goal**: Блок лимонов расположен ниже профиля/лояльности и выше «Товаров недели»; не перекрывает гостевой CTA

**Independent Test**: Авторизованный пользователь с лояльностью и лимонами — порядок блоков по spec US4 (quickstart С9)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО)

- [x] T030 [P] [US4] Extend `test/features/home/home_screen_test.dart`: assert widget order — `HomeProfileSlot` before `HomeLemonGamificationCard` before weekly products section (find by `Key` or type order)
- [x] T031 [P] [US4] Extend `integration_test/home_screen_flow_test.dart`: lemon block visible after login `+79005555555`; hidden for guest; block below banners

### Implementation for User Story 4

- [x] T032 [US4] Finalize layout in `lib/features/home/presentation/home_screen.dart`: confirm padding/margins consistent with `HomeLoyaltyStatusCard` (16px horizontal); no duplicate gamification for guests

**Checkpoint**: Порядок блоков на главной соответствует spec

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Регрессии, интеграция, валидация quickstart

- [x] T033 [P] Extend `integration_test/home_screen_flow_test.dart`: checkout flow under `+79006666666` — gift in cart before submit, 1 lemon on home after order
- [x] T034 [P] Run `dart format` on changed Dart files and `flutter analyze` — zero issues
- [x] T035 Run `flutter test` (full suite) — all green
- [x] T036 Run `flutter test integration_test/home_screen_flow_test.dart` on device/emulator — green
- [x] T037 Validate manual scenarios from `specs/015-order-lemon-gamification/quickstart.md` (С1–С10)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS** all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — MVP блока на главной
- **US2 (Phase 4)**: Depends on Phase 2; integrates with US1 (`HomeScreen` profile watch)
- **US3 (Phase 5)**: Depends on Phase 2; integrates with US2 (profile refresh after order)
- **US4 (Phase 6)**: Depends on US1 (block exists); layout verification
- **Polish (Phase 7)**: Depends on US1–US4

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| US1 (P1) | Foundational | Шкала лимонов на главной для auth; скрыта для гостя |
| US2 (P1) | Foundational, US1 wiring | +1 лимон после заказа, refresh UI |
| US3 (P1) | Foundational, US2 | «Подарок» в корзине; сброс до 1 |
| US4 (P2) | US1 | Порядок блоков на главной |

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models/providers before UI
- Mock/API before checkout side effects

### Parallel Opportunities

- **Phase 1**: T002 ∥ T001 (после merge paths известны)
- **Phase 2**: T003 ∥ T005; T008–T010 ∥ после T004–T007
- **US1 tests**: T011 ∥ T012 ∥ T013; **US1 impl**: T014 ∥ T015 → T016 → T017
- **US2 tests**: T018 ∥ T019; **US2 impl**: T020 → T021
- **US3 tests**: T022 ∥ T023 ∥ T024; **US3 impl**: T025 → T026 → T027 → T028 → T029
- **US4**: T030 ∥ T031; T032 after US1
- **Polish**: T033–T034 parallel; T035–T037 sequential

### Parallel Example: User Story 1

```bash
# Tests in parallel (after Phase 2):
flutter test test/features/home/home_lemon_gamification_ui_model_test.dart
flutter test test/features/home/home_lemon_gamification_card_test.dart
flutter test test/features/home/home_screen_test.dart

# Implementation in parallel where marked [P]:
# T014 home_lemon_gamification_ui_model.dart
# T015 lemon_progress_icon.dart
# then T016 → T017
```

### Parallel Example: User Story 3

```bash
flutter test test/features/cart/cart_gift_line_test.dart
flutter test test/features/cart/cart_line_tile_test.dart
flutter test test/features/cart/cart_order_summary_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 + Phase 2
2. Complete Phase 3 (US1)
3. **STOP and VALIDATE**: quickstart С1–С3
4. Demo: блок лимонов на главной для авторизованного пользователя

### Incremental Delivery

1. Setup + Foundational → модель `lemons`, моки, OpenAPI
2. US1 → блок прогресса на главной (MVP)
3. US2 → начисление после заказа
4. US3 → подарок в корзине (полная ценность акции)
5. US4 → порядок блоков
6. Polish → quickstart С1–С10

### Suggested MVP Scope

**User Story 1** (Phase 3) после Foundational — визуальный прогресс на главной без подарка в корзине.

---

## Notes

- Порядок contract-first: T001 → T004–T007 → UI (конституция VI)
- Подарок **не** добавлять в `cartNotifierProvider` — только synthetic line в `cartDisplayLinesProvider`
- `profileNotifierProvider` уже на главной и в корзине — переиспользовать, не дублировать
- Серый `#BDBDBD` для пустых лимонов — см. Complexity Tracking в plan.md
- Всего задач: **37** (T001–T037); US1: 7, US2: 4, US3: 8, US4: 3, Setup: 2, Foundational: 8, Polish: 5

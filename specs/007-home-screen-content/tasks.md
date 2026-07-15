---

description: "Список задач для фичи «Наполнение главного экрана»"
---

# Tasks: Наполнение главного экрана

**Input**: Design documents from `/specs/007-home-screen-content/`

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

**Purpose**: Контракт API, строки локализации, заготовка integration-теста

- [x] T001 Merge OpenAPI v0.7.0 from `specs/007-home-screen-content/contracts/openapi.yaml` into `openapi/openapi.yaml` (`Banner.link`, `GET /home/weekly-products`, `GET /orders/current`, `POST /orders/{id}/rating`, `POST /orders/{id}/rating/skip`, расширенные `OrderStatus` и `OrderRatingState`)
- [x] T002 [P] Add home/order UI strings to `lib/core/l10n/app_strings.dart` per research.md §9: homeWeeklyProductsTitle, homeOrderHistoryTitle, homeOrderStatusAccepted/Processing/Assembly/Delivery/Completed, homeContactOperator, homeOrderRatingPrompt, homeOrderRate, homeOrderSkipRating, homeRepeatOrder, homeOrderRatingTitle, homeOrderRatingSubmit, homeOrderRatingCommentHint, homeRepeatOrderPartial, homeRepeatOrderFailed, homeBannerLinkFailed, homeLoadError, homeRetry
- [x] T003 [P] Create stub `integration_test/home_screen_flow_test.dart` with `main()` placeholder

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели, API-клиент, моки, репозитории и провайдеры — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T004 [P] Update `lib/features/home/domain/banner.dart`: replace `linkUrl?` with `BannerLink` (`type`, `url?`, `targetId?`), `BannerLinkType` enum, `fromJson`/`toJson` per data-model.md §1
- [x] T005 [P] Extend `lib/features/cart/domain/order.dart`: expand `OrderStatus` (accepted, processing, assembly, delivery, completed; map legacy `pending` → accepted), add `OrderRatingState`, `CurrentOrder`, `SubmitOrderRatingRequest`, `CurrentOrderResponse` with `fromJson` per data-model.md §3–§6
- [x] T006 [P] Create `lib/features/cart/domain/order_status_label.dart` with `orderStatusLabel(OrderStatus) → String` using `AppStrings` (русские подписи FR-012)
- [x] T007 Extend `lib/core/network/api_client.dart` with `getWeeklyProducts()`, `getCurrentOrder()`, `submitOrderRating(orderId, request)`, `skipOrderRating(orderId)`; implement in `DioApiClient` in same file (`GET /home/weekly-products`, `GET /orders/current`, `POST /orders/{id}/rating`, `POST /orders/{id}/rating/skip`, bearer token via existing interceptor)
- [x] T008 Update `lib/core/network/mock_api_client.dart`: (a) `getHomeBanners` — ≥3 баннеров с реальными `imageUrl` и всеми типами `link`; (b) `getWeeklyProducts` — 6–8 товаров из `_products`; (c) `_ordersByUserId` storage — persist orders from `createOrder` as `accepted`; (d) preset demo orders per user id (delivery, completed+pending rating, completed+skipped); (e) `getCurrentOrder`, `submitOrderRating`, `skipOrderRating` per research.md §6
- [x] T009 [P] Extend `lib/features/home/data/home_repository.dart` with `getWeeklyProducts()`; add `weeklyProductsProvider` (`FutureProvider<List<ProductSummary>>`)
- [x] T010 [P] Extend `lib/features/cart/data/order_repository.dart` with `getCurrentOrder()`, `submitOrderRating()`, `skipOrderRating()`; add `currentOrderProvider` (`FutureProvider<CurrentOrder?>`) — skip API call when `!isAuthenticated`, return `null`
- [x] T011 [P] Create `lib/features/home/domain/home_order_ui_state.dart` with `HomeOrderUiState` and pure `buildHomeOrderUiState(CurrentOrder)` per data-model.md §7
- [x] T012 [P] Unit-тест `orderStatusLabel` и `orderStatusFromJson` (включая `pending` → accepted) в `test/features/cart/order_status_test.dart`
- [x] T013 [P] Unit-тест `MockApiClient` home/order endpoints в `test/core/network/mock_api_client_home_test.dart` (banners link schema, weekly products, getCurrentOrder null/active, rating submit/skip, 409 duplicate rating)

**Checkpoint**: API, модели, моки и провайдеры готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Баннеры с API и переходами по ссылкам (Priority: P1) 🎯 MVP

**Goal**: Карусель с реальными фото из API; нажатие открывает external / акцию / новость / товар

**Independent Test**: Открыть «Главную» → баннеры с изображениями → нажать каждый тип ссылки (quickstart С1–С2)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T014 [P] [US1] Unit-тест `BannerLinkHandler` в `test/features/home/banner_link_handler_test.dart` (external → launchUrl; promotion/news → `/promotions/article/{id}`; product → `/catalog/product/{id}`; none → no navigation)
- [x] T015 [P] [US1] Widget-тест `BannerCarousel` в `test/features/home/banner_carousel_test.dart` (renders `CachedNetworkImage` when imageUrl set; tap invokes handler; preserves auto-scroll viewportFraction)

### Implementation for User Story 1

- [x] T016 [P] [US1] Create `lib/features/home/domain/banner_link_handler.dart`: `handleBannerLink(BuildContext, BannerLink)` using `url_launcher` + `go_router`; snackbar on failure (`AppStrings.homeBannerLinkFailed`)
- [x] T017 [US1] Update `lib/features/home/presentation/banner_carousel.dart`: wrap banner in `InkWell`/`GestureDetector`; use `CachedNetworkImage` for non-empty `imageUrl`; call `handleBannerLink` on tap; remove placeholder text «Баннер N» when imageUrl present
- [x] T018 [US1] Update `lib/features/home/presentation/home_screen.dart`: banner `AsyncValue` — on error show compact retry (`AppStrings.homeRetry`) or `SizedBox.shrink` per edge cases; keep carousel padding/behavior from `002-notifications-home`

**Checkpoint**: Баннеры загружаются с API и ведут на целевые экраны; карусель работает как раньше

---

## Phase 4: User Story 2 — Горизонтальная лента «Товары недели» (Priority: P1)

**Goal**: Блок «Товары недели» — горизонтальный скролл карточек с добавлением в корзину

**Independent Test**: «Главная» → заголовок «Товары недели» → свайп → tap → add to cart → badge (quickstart С3)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T019 [P] [US2] Widget-тест `HomeWeeklyProductsSection` в `test/features/home/home_weekly_products_section_test.dart` (title visible; horizontal list renders ProductCard; hidden when items empty; tap + updates cart badge)

### Implementation for User Story 2

- [x] T020 [P] [US2] Create `lib/features/home/presentation/home_weekly_products_section.dart`: section title `AppStrings.homeWeeklyProductsTitle`; `SizedBox` + horizontal `ListView.separated`; `SizedBox(width: 160, child: ProductCard(...))` per research.md §7; loading/error states isolated
- [x] T021 [US2] Wire `weeklyProductsProvider` into `lib/features/home/presentation/home_screen.dart` below `HomeContactButton`; hide section when `items.isEmpty`

**Checkpoint**: Лента товаров недели работает независимо от блока заказа

---

## Phase 5: User Story 3 — Блок текущего заказа на «Главной» (Priority: P1)

**Goal**: Авторизованному пользователю с текущим заказом — статус, состав, сумма, «Связаться с оператором»

**Independent Test**: Login с активным заказом → «Главная» → блок «История заказов» → звонок оператору (quickstart С4)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T022 [P] [US3] Unit-тест `buildHomeOrderUiState` в `test/features/home/home_order_ui_state_test.dart` (active status → no rating/repeat; completed+pending → rating only)
- [x] T023 [P] [US3] Widget-тест `HomeOrderHistorySection` в `test/features/home/home_order_history_section_test.dart` (status label, line items, total, contact button `tel:+78125645548`; hidden when order null or guest)

### Implementation for User Story 3

- [x] T024 [P] [US3] Create `lib/features/home/presentation/home_order_history_section.dart`: title `AppStrings.homeOrderHistoryTitle`; status chip with `orderStatusLabel`; expandable/collapsible order lines (name, qty × price); total; `HomeContactButton`-style operator button (`url_launcher` tel +78125645548, label `AppStrings.homeContactOperator`)
- [x] T025 [US3] Wire `currentOrderProvider` into `lib/features/home/presentation/home_screen.dart`: show `HomeOrderHistorySection` only when `isAuthenticated && order != null`; independent loading/error from other sections

**Checkpoint**: Активный заказ отображается; оценка и повтор — в US4/US5

---

## Phase 6: User Story 4 — Оценка выполненного заказа (Priority: P2)

**Goal**: Для completed заказа — приглашение, «Оценить» (bottom sheet 1–5 звёзд), «Пропустить»

**Independent Test**: Пользователь с completed+pending rating → оценить или пропустить → приглашение скрыто (quickstart С5)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО)

- [x] T026 [P] [US4] Widget-тест `OrderRatingSheet` в `test/features/home/order_rating_sheet_test.dart` (5 stars selectable; submit disabled until star chosen; submit calls callback with stars+comment)
- [x] T027 [P] [US4] Extend `test/features/home/home_order_history_section_test.dart` [US4]: completed+pending shows prompt and buttons; after skip hides prompt

### Implementation for User Story 4

- [x] T028 [P] [US4] Create `lib/features/home/presentation/order_rating_sheet.dart`: `showOrderRatingSheet(context)` — bottom sheet with 5 `IconButton` stars, optional comment `TextField`, «Отправить»/`Отмена` (`AppStrings`)
- [x] T029 [US4] Update `lib/features/home/presentation/home_order_history_section.dart`: when `showRatingPrompt` — FR-015 text + «Оценить» opens sheet → `orderRepository.submitOrderRating` → `ref.invalidate(currentOrderProvider)`; «Пропустить» → `skipOrderRating` → invalidate
- [x] T030 [US4] Extend `test/core/network/mock_api_client_home_test.dart` [US4]: rating 400 stars out of range; 409 on second submit

**Checkpoint**: Оценка и пропуск сохраняются на сервере; UI обновляется реактивно

---

## Phase 7: User Story 5 — Повтор заказа (Priority: P2)

**Goal**: После оценки/пропуска — «Повторить заказ» добавляет позиции в корзину и переходит на `/cart`

**Independent Test**: Completed+skipped order → «Повторить заказ» при пустой и непустой корзине (quickstart С6)

### Tests for User Story 5 (ОБЯЗАТЕЛЬНО)

- [x] T031 [P] [US5] Unit-тест `repeatOrderToCart` в `test/features/home/repeat_order_test.dart` (adds all lines; merges quantities; skips unavailable products; returns `RepeatOrderResult`)
- [x] T032 [P] [US5] Extend `test/features/home/home_order_history_section_test.dart` [US5]: `showRepeatButton` visible only after rating/skipped; tap triggers repeat callback

### Implementation for User Story 5

- [x] T033 [P] [US5] Create `lib/features/home/domain/repeat_order.dart`: `repeatOrderToCart(CurrentOrder, CartNotifier, CatalogRepository) → Future<RepeatOrderResult>` per research.md §5; use current catalog prices
- [x] T034 [US5] Update `lib/features/home/presentation/home_order_history_section.dart`: when `showRepeatButton` — accent button `AppStrings.homeRepeatOrder`; on tap call `repeatOrderToCart`, show snackbar on partial/full failure, `context.go('/cart')` on success (≥1 item added)

**Checkpoint**: Повтор заказа работает с merge в корзину и навигацией на вкладку «Корзина»

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Сквозные тесты, регрессия, валидация quickstart

- [x] T035 [P] Implement `integration_test/home_screen_flow_test.dart`: banner tap → product detail; weekly add → cart badge; auth → order block → repeat → cart tab (quickstart С1–С7)
- [x] T036 [P] Extend `test/features/home/home_screen_test.dart` (create if missing): full `HomeScreen` composes banners, contact, weekly, order (mock providers), auth prompt for guest; existing blocks FR-022 preserved
- [x] T037 Run `flutter analyze` and `flutter test`; fix regressions from `Banner.link` breaking change in any existing banner tests/mocks
- [x] T038 Validate manual scenarios from `specs/007-home-screen-content/quickstart.md` (С1–С8) and document any mock user presets in comment atop `mock_api_client.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Нет зависимостей — можно начинать сразу
- **Foundational (Phase 2)**: Зависит от Phase 1 — **блокирует** все user stories
- **User Stories (Phase 3–7)**: Зависят от Foundational
  - US1, US2, US3 (все P1) могут идти параллельно после Phase 2
  - US4 зависит от US3 (блок заказа на главной)
  - US5 зависит от US4 (кнопка повтора после оценки/пропуска)
- **Polish (Phase 8)**: После завершения нужных user stories

### User Story Dependencies

| Story | Priority | Зависимости | Независимый тест |
|-------|----------|-------------|------------------|
| US1 | P1 | Phase 2 | quickstart С1–С2 |
| US2 | P1 | Phase 2 | quickstart С3 |
| US3 | P1 | Phase 2 | quickstart С4 |
| US4 | P2 | US3 (секция заказа) | quickstart С5 |
| US5 | P2 | US4 (rating state) | quickstart С6 |

### Within Each User Story

- Тесты MUST быть написаны первыми и падать до реализации
- Domain → presentation → интеграция в `home_screen.dart`
- Checkpoint после каждой фазы

### Parallel Opportunities

- **Phase 1**: T002 ∥ T003
- **Phase 2**: T004 ∥ T005 ∥ T006 ∥ T009 ∥ T010 ∥ T011 ∥ T012 ∥ T013 (после T001); T007 после T004–T006
- **После Phase 2**: US1 (T014–T018) ∥ US2 (T019–T021) ∥ US3 (T022–T025)
- **US4 и US5**: последовательно (US4 → US5)
- **Phase 8**: T035 ∥ T036

---

## Parallel Example: User Story 1

```bash
# Тесты US1 параллельно:
Task T014: test/features/home/banner_link_handler_test.dart
Task T015: test/features/home/banner_carousel_test.dart

# Реализация после падающих тестов:
Task T016: lib/features/home/domain/banner_link_handler.dart
Task T017: lib/features/home/presentation/banner_carousel.dart
```

## Parallel Example: P1 stories after Foundational

```bash
# Три разработчика после Phase 2:
Developer A: Phase 3 (US1 — баннеры)
Developer B: Phase 4 (US2 — товары недели)
Developer C: Phase 5 (US3 — блок заказа)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (баннеры)
4. **STOP and VALIDATE**: quickstart С1–С2
5. Demo при готовности

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 (баннеры) → validate → demo
3. US2 (товары недели) → validate → demo
4. US3 (текущий заказ) → validate → demo
5. US4 (оценка) → US5 (повтор) → validate → demo
6. Polish → full quickstart

### Suggested MVP Scope

**MVP = Phase 1 + Phase 2 + Phase 3 (US1)**: реальные баннеры с рабочими ссылками — первый измеримый прирост на главной (SC-001, SC-002).

---

## Notes

- `[P]` = разные файлы, нет жёсткой зависимости от незавершённых задач в той же фазе
- Breaking change: `Banner.linkUrl` → `Banner.link` — обновить все ссылки в тестах и моках
- `createOrder` в моке MUST сохранять заказ в `_ordersByUserId` для сценария US3 после оформления
- Блоки главной загружаются независимо: ошибка одной секции не блокирует остальные (edge cases spec)
- Commit после каждой задачи или логической группы
- Остановка на checkpoint для независимой проверки story

---

## Task Summary

| Metric | Value |
|--------|-------|
| **Total tasks** | 38 |
| **Phase 1 Setup** | 3 |
| **Phase 2 Foundational** | 10 |
| **US1 (P1)** | 5 tasks (2 tests + 3 impl) |
| **US2 (P1)** | 3 tasks (1 test + 2 impl) |
| **US3 (P1)** | 4 tasks (2 tests + 2 impl) |
| **US4 (P2)** | 5 tasks (2 tests + 3 impl) |
| **US5 (P2)** | 4 tasks (2 tests + 2 impl) |
| **Polish** | 4 |
| **Format validation** | ✅ All tasks use `- [x] T### [P?] [US?]` with file paths |

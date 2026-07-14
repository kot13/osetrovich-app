---

description: "Список задач для фичи «Каталог товаров»"
---

# Tasks: Каталог товаров

**Input**: Design documents from `/specs/004-product-catalog/`

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

- [x] T001 Add `cached_network_image` to `pubspec.yaml` and run `flutter pub get`
- [x] T002 Merge OpenAPI v0.4.0 from `specs/004-product-catalog/contracts/openapi.yaml` into `openapi/openapi.yaml` (products endpoints + ProductSummary/ProductDetail schemas)
- [x] T003 [P] Create directory `lib/features/catalog/presentation/widgets/` per plan.md
- [x] T004 [P] Create directory `lib/features/cart/domain/` and stub `integration_test/catalog_flow_test.dart`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели, API-клиент, моки, репозиторий, notifier пагинации — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T005 [P] Add catalog UI strings to `lib/core/l10n/app_strings.dart`: productsLoadFailed, loadMoreFailed, productNotFound, retry
- [x] T006 [P] Create `lib/core/utils/price_formatter.dart` with `formatPriceRub(int priceRub) → '300 ₽'`
- [x] T007 [P] Create `lib/features/catalog/domain/product.dart`: `ProductSummary`, `ProductDetail`, `ProductListPage` with `fromJson` per data-model.md
- [x] T008 Extend `lib/core/network/api_client.dart` with `getProducts(categoryId, offset, limit)` and `getProductById(id)`; implement in Dio client class in same file
- [x] T009 Update `lib/core/network/mock_api_client.dart`: ≥60 `ProductSummary` across categories, offset/limit pagination (`limit` max 20), `getProductById` with multi-image samples and 404 for unknown id
- [x] T010 [P] Create `lib/features/catalog/data/catalog_repository.dart` wrapping `getProducts` and `getProductById`
- [x] T011 Create `lib/features/catalog/domain/products_notifier.dart` with `productsNotifierProvider`: category reset, initial load, `loadMore()`, `hasMore` / `isLoadingMore` / error states per data-model.md

**Checkpoint**: API, модели и пагинация готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Просмотр каталога и подгрузка товаров (Priority: P1) 🎯 MVP

**Goal**: Сетка 2 колонки, Filter Chips + товары, infinite scroll по 20 позиций

**Independent Test**: Открыть «Каталог» → выбрать категорию → 2×N карточки → скролл → подгрузка (quickstart С1, С2)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T012 [P] [US1] Unit-тест `formatPriceRub` в `test/core/utils/price_formatter_test.dart`
- [x] T013 [P] [US1] Unit-тест `CatalogRepository.getProducts` в `test/features/catalog/catalog_repository_test.dart`
- [x] T014 [P] [US1] Unit-тест `ProductsNotifier` (reset on category, append pages, hasMore) в `test/features/catalog/products_notifier_test.dart`
- [x] T015 [P] [US1] Widget-тест сетки в `test/features/catalog/product_grid_test.dart` (2 columns, initial items visible)

### Implementation for User Story 1

- [x] T016 [P] [US1] Create `lib/features/catalog/presentation/widgets/product_card.dart`: photo (`CachedNetworkImage` + placeholder), name max 2 lines ellipsis, weight, static «цена +» button (accent, no cart logic yet)
- [x] T017 [P] [US1] Create `lib/features/catalog/presentation/widgets/product_grid.dart`: `GridView.builder` crossAxisCount 2, `ScrollController` with 200px threshold → `loadMore()`, bottom loading indicator
- [x] T018 [US1] Replace empty product area in `lib/features/catalog/presentation/catalog_screen.dart`: wire `CategoryChips` → reset notifier; show `ProductGrid` / loading / error / `EmptyState` (nothingFound)
- [x] T019 [US1] Update `test/features/catalog/catalog_screen_test.dart`: mock products → grid visible instead of only empty state

**Checkpoint**: Каталог показывает сетку товаров с подгрузкой; корзина ещё не обязательна

---

## Phase 4: User Story 2 — Быстрое добавление в корзину с карточки (Priority: P1)

**Goal**: «− K × цена +», реактивный бейдж на вкладке «Корзина» (уникальные SKU)

**Independent Test**: Добавить 2 разных товара → бейдж «2» → «−» до нуля → бейдж «1» (quickstart С3, С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T020 [P] [US2] Unit-тест `CartNotifier` в `test/features/cart/cart_notifier_test.dart` (increment, decrement to zero removes, distinctCount)
- [x] T021 [P] [US2] Widget-тест `ProductCard` cart states в `test/features/catalog/product_card_test.dart` (shadow + center qty, bar labels)
- [x] T022 [P] [US2] Widget-тест cart badge в `test/features/shell/main_shell_test.dart` (hidden at 0, shows distinct SKU count)

### Implementation for User Story 2

- [x] T023 [P] [US2] Create `lib/features/cart/domain/cart_notifier.dart` with `cartNotifierProvider` and derived `cartDistinctCountProvider` (`Map<String,int>` per data-model.md)
- [x] T024 [P] [US2] Create `lib/features/catalog/presentation/widgets/quantity_price_bar.dart`: compact mode «300 ₽ +» / «− 300 ₽ +»; callbacks for −/+
- [x] T025 [US2] Update `lib/features/catalog/presentation/widgets/product_card.dart`: integrate `QuantityPriceBar` (compact «− K × price +»), reserved text block height; tap isolation on bar (no navigate)
- [x] T026 [US2] Convert `lib/features/shell/presentation/main_shell.dart` to `ConsumerWidget`; wrap cart `BottomNavigationBarItem` icon in `Badge` when `cartDistinctCountProvider > 0`
- [x] T027 [US2] Wire `ProductGrid` / `product_card.dart` to `cartNotifierProvider` for reactive quantity display

**Checkpoint**: Добавление с карточки и бейдж корзины работают без страницы товара

---

## Phase 5: User Story 3 — Страница товара и добавление из деталей (Priority: P2)

**Goal**: Деталь с галереей, описанием, floating «− K × цена +»; синхронизация с сеткой и бейджем

**Independent Test**: Tap карточку → деталь → изменить qty → back → карточка и бейдж синхронны (quickstart С5)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T028 [P] [US3] Unit-тест `MockApiClient.getProductById` pagination edge cases в `test/core/network/mock_api_client_products_test.dart`
- [x] T029 [P] [US3] Widget-тест `ProductImageGallery` в `test/features/catalog/product_image_gallery_test.dart` (single vs multi image PageView)
- [x] T030 [P] [US3] Widget-тест `ProductDetailScreen` в `test/features/catalog/product_detail_screen_test.dart` (fields, floating bar states, ± qty)

### Implementation for User Story 3

- [x] T031 [P] [US3] Create `lib/features/catalog/presentation/widgets/product_image_gallery.dart`: horizontal `PageView`, dot indicator when `imageUrls.length > 1`
- [x] T032 [US3] Create `lib/features/catalog/presentation/product_detail_screen.dart`: load via `getProductById`, show gallery/name/weight/price/description; pinned bar in `Column` body with `QuantityPriceBar` detail mode «− 1 × 300 ₽ +»
- [x] T033 [US3] Add nested route `/catalog/product/:id` in `lib/core/router/app_router.dart` inside catalog branch (preserve Tab Bar)
- [x] T034 [US3] Update `lib/features/catalog/presentation/widgets/product_card.dart`: tap on card body → `context.push('/catalog/product/${product.id}')`

**Checkpoint**: Все три user story работают независимо и синхронизированы через `CartNotifier`

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Сквозные проверки, контракт, документация

- [x] T035 [P] Integration-тест полного flow в `integration_test/catalog_flow_test.dart`: grid → add 2 SKU → badge 2 → open detail → change qty → back sync (quickstart С1–С5)
- [x] T036 Run `flutter analyze` and `dart format` on changed files; fix any issues
- [x] T037 [P] Manual validation per `specs/004-product-catalog/quickstart.md` (С6 errors, С7 без авторизации)
- [x] T038 Update `specs/004-product-catalog/spec.md` **Status** to `Implemented` after all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Foundational
- **US2 (Phase 4)**: Depends on Foundational + US1 `ProductCard`/`ProductGrid` skeleton (T016–T018)
- **US3 (Phase 5)**: Depends on US2 `CartNotifier` + `QuantityPriceBar` + US1 grid navigation target
- **Polish (Phase 6)**: Depends on US1–US3

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| **US1** (P1) | Phase 2 only | Grid + pagination without cart |
| **US2** (P1) | US1 card/grid | Cart from card + Tab badge |
| **US3** (P2) | US1 + US2 | Detail page + sync |

### Parallel Opportunities

- **Phase 1**: T003 ∥ T004
- **Phase 2**: T005 ∥ T006 ∥ T007; T010 after T008–T009
- **US1 tests**: T012 ∥ T013 ∥ T014 ∥ T015; **US1 impl**: T016 ∥ T017
- **US2 tests**: T020 ∥ T021 ∥ T022; **US2 impl**: T023 ∥ T024
- **US3 tests**: T028 ∥ T029 ∥ T030; **US3 impl**: T031 before T032

### Parallel Example: User Story 1

```bash
# Tests first (parallel):
flutter test test/core/utils/price_formatter_test.dart
flutter test test/features/catalog/catalog_repository_test.dart
flutter test test/features/catalog/products_notifier_test.dart
flutter test test/features/catalog/product_grid_test.dart

# Then implementation (parallel where marked):
# T016 product_card.dart + T017 product_grid.dart
# T018 catalog_screen.dart wires both
```

### Parallel Example: User Story 2

```bash
# Tests (parallel):
flutter test test/features/cart/cart_notifier_test.dart
flutter test test/features/catalog/product_card_test.dart
flutter test test/features/shell/main_shell_test.dart

# Implementation:
# T023 cart_notifier.dart + T024 quantity_price_bar.dart in parallel
# T025–T027 integrate
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: `flutter test test/features/catalog/` — grid + pagination
5. Demo browse-only catalog

### Incremental Delivery

1. Setup + Foundational → API ready
2. **US1** → browse catalog (MVP)
3. **US2** → add to cart + badge
4. **US3** → product detail + full sync
5. **Polish** → integration + quickstart

### Suggested MVP Scope

**User Story 1** (Phase 3) — минимальный инкремент: сетка товаров с подгрузкой без корзины.

---

## Notes

- Корзина **локальная** (без API) до отдельной фичи; `CartNotifier` in-memory
- Бейдж = **число уникальных SKU**, не сумма штук (FR-006)
- Эндпоинты каталога **без** JWT (публичный доступ)
- Кнопки ± на карточке MUST NOT открывать деталь (edge case из spec)
- При смене категории: `ScrollController.jumpTo(0)` + reset `ProductsNotifier`

---

## Task Summary

| Phase | Tasks | Count |
|-------|-------|-------|
| Setup | T001–T004 | 4 |
| Foundational | T005–T011 | 7 |
| US1 | T012–T019 | 8 |
| US2 | T020–T027 | 8 |
| US3 | T028–T034 | 7 |
| Polish | T035–T038 | 4 |
| **Total** | | **38** |

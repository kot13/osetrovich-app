---

description: "Список задач для фичи «Обновление каталога по контракту»"
---

# Tasks: Обновление каталога по контракту

**Input**: Design documents from `/specs/009-product-contract-update/`

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

**Purpose**: Проверка контракта, константы и строки UI

- [x] T001 Сверить `openapi/openapi.yaml` со схемами из `specs/009-product-contract-update/contracts/openapi.yaml` (integer id, поля `sale` / `special` / `oldPriceRub`)
- [x] T002 [P] Добавить константу `kAllCategoriesId = 0` в `lib/features/catalog/domain/catalog_category.dart` (или отдельный `catalog_constants.dart` по plan.md)
- [x] T003 [P] Добавить строки `badgeSale` («Акция») и `badgeSpecialPrice` («СПЕЦЦЕНА») в `lib/core/l10n/app_strings.dart`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели, API, моки и миграция корзины на `int` — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T004 [P] Обновить `lib/features/catalog/domain/catalog_category.dart`: `id` → `int`, `fromJson` парсит integer
- [x] T005 [P] Обновить `lib/features/catalog/domain/product.dart`: `id` / `categoryIds` → `int`; добавить `sale`, `special`, `oldPriceRub` в `ProductSummary` и `ProductDetail` с `fromJson`
- [x] T006 Обновить `lib/core/network/api_client.dart`: `getProductById(int id)`; маппинг `categoryId` query (`0` → `"all"`, иначе `"$id"`) в `getProducts`
- [x] T007 Обновить `lib/core/network/mock_api_client.dart`: числовые id категорий (1…N), синтетическая «Все» с `id: 0`; товары с int id, `categoryIds: [int]`, `sale`/`special`/`oldPriceRub`; ≥3 товара с разными комбинациями флагов
- [x] T008 [P] Обновить сигнатуры в `lib/features/catalog/data/catalog_repository.dart` (`getProductById(int)`, query categoryId)
- [x] T009 Обновить `lib/features/cart/domain/cart_notifier.dart`: state `Map<int, int>`; методы принимают `int productId`; analytics — `productId.toString()`
- [x] T010 [P] Обновить `lib/features/cart/domain/cart_line_item_view.dart`: `productId` → `int`
- [x] T011 Обновить `lib/features/catalog/domain/products_notifier.dart`: `categoryId` → `int` (default `kAllCategoriesId`); API mapping в `_fetchPage`
- [x] T012 [P] Обновить `lib/features/catalog/presentation/category_chips.dart`: `selectedId` / `onSelected` → `int`
- [x] T013 Обновить `lib/core/router/app_router.dart` (`int.parse` для `product/:id`) и `lib/features/catalog/presentation/product_detail_screen.dart` (`productId: int`, `productDetailProvider` family `int`)

**Checkpoint**: Модели и сетевой слой соответствуют контракту; корзина на int-ключах

---

## Phase 3: User Story 1 — Каталог с числовыми идентификаторами (Priority: P1) 🎯 MVP

**Goal**: Каталог, деталь товара, корзина и главная работают с integer id без ошибок парсинга

**Independent Test**: Открыть «Каталог» → выбрать категорию → открыть товар → добавить в корзину → проверить «Товары недели» (quickstart С1, С2, С7)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T014 [P] [US1] Unit-тест `ProductSummary.fromJson` / `ProductDetail.fromJson` с int id в `test/features/catalog/product_model_test.dart`
- [x] T015 [P] [US1] Обновить `test/features/catalog/products_notifier_test.dart` под `categoryId: int` и `kAllCategoriesId`
- [x] T016 [P] [US1] Обновить `test/features/cart/cart_notifier_test.dart` под `Map<int, int>`
- [x] T017 [P] [US1] Обновить `test/core/network/mock_api_client_products_test.dart` под int category/product id

### Implementation for User Story 1

- [x] T018 [US1] Обновить `lib/features/cart/domain/cart_lines_provider.dart` и `lib/features/cart/domain/checkout_notifier.dart` (`OrderLineInput.productId: entry.key.toString()`)
- [x] T019 [US1] Обновить `lib/features/cart/presentation/cart_screen.dart` и `lib/features/cart/presentation/widgets/cart_line_tile.dart` под `Map<int, int>`
- [x] T020 [US1] Обновить `lib/features/catalog/presentation/catalog_screen.dart`: wiring `CategoryChips` / `ProductsNotifier` с `int categoryId`
- [x] T021 [US1] Обновить `lib/features/home/domain/repeat_order.dart`: `int.parse(line.productId)` при `getProductById`
- [x] T022 [P] [US1] Обновить фикстуры в `test/features/catalog/catalog_screen_test.dart`, `test/features/catalog/product_grid_test.dart`, `test/features/catalog/product_detail_screen_test.dart`, `test/features/catalog/catalog_repository_test.dart`
- [x] T023 [P] [US1] Обновить `test/features/home/repeat_order_test.dart`, `test/features/cart/cart_line_tile_test.dart` под int product id
- [x] T024 [US1] Обновить `integration_test/catalog_flow_test.dart` под числовые id товаров

**Checkpoint**: Каталог и корзина полностью работают с int id; промо-бейджи ещё не обязательны

---

## Phase 4: User Story 2 — Бейдж «Акция» (Priority: P1)

**Goal**: На карточке товара отображается бейдж «Акция» при `sale = true`

**Independent Test**: Товар с `sale: true` в сетке каталога показывает жёлтый бейдж «Акция»; при `sale: false` бейджа нет (quickstart С3)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T025 [P] [US2] Widget-тест `ProductPromoBadges` (только sale) в `test/features/catalog/product_promo_badges_test.dart`
- [x] T026 [P] [US2] Обновить `test/features/catalog/product_card_test.dart`: `sale: true` → текст «Акция» на карточке

### Implementation for User Story 2

- [x] T027 [P] [US2] Создать `lib/features/catalog/presentation/widgets/product_promo_badges.dart`: бейдж «Акция» (`AppColors.accent` / `AppColors.dark`); скрывать при `sale: false`
- [x] T028 [US2] Интегрировать `ProductPromoBadges` в `lib/features/catalog/presentation/widgets/product_card.dart` (`Stack` поверх фото, inset 8px)

**Checkpoint**: Бейдж «Акция» виден в каталоге и на главной (через общий `ProductCard`)

---

## Phase 5: User Story 3 — Бейдж «СПЕЦЦЕНА» (Priority: P1)

**Goal**: Бейдж «СПЕЦЦЕНА» при `special = true`; оба бейджа при `sale && special`

**Independent Test**: Товар `special: true` — бейдж «СПЕЦЦЕНА»; оба флага — два бейджа в ряд (quickstart С4, С5, С6)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T029 [P] [US3] Расширить `test/features/catalog/product_promo_badges_test.dart`: `special` only, оба бейджа, ни одного
- [x] T030 [P] [US3] Обновить `test/features/catalog/product_card_test.dart`: `special: true` и `sale+special` комбинации

### Implementation for User Story 3

- [x] T031 [US3] Добавить бейдж «СПЕЦЦЕНА» в `lib/features/catalog/presentation/widgets/product_promo_badges.dart` (`AppColors.primary`, белый текст); порядок: «Акция» → «СПЕЦЦЕНА»
- [x] T032 [P] [US3] Обновить `test/features/home/home_screen_test.dart` (weekly products fixtures с int id и флагами sale/special при необходимости)

**Checkpoint**: Все промо-бейджи по контракту; «Товары недели» используют тот же `ProductCard`

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Финальная проверка и соответствие quickstart

- [x] T033 [P] Прогнать `dart format .` и `flutter analyze` — без ошибок
- [x] T034 [P] Прогнать `flutter test` (полный suite) и исправить регрессии
- [x] T035 Выполнить ручную проверку по `specs/009-product-contract-update/quickstart.md` (сценарии С1–С6)
- [x] T036 [P] Убедиться, что `lib/core/network/mock_profile_sync.dart` и прочие ссылки на product id согласованы с int (при наличии)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Нет зависимостей — можно начинать сразу
- **Foundational (Phase 2)**: Зависит от Phase 1 — **блокирует** все user stories
- **User Stories (Phase 3–5)**: Зависят от Phase 2; US2/US3 зависят от US1 (нужен рабочий `ProductCard` и модели с флагами)
- **Polish (Phase 6)**: После завершения US1–US3

### User Story Dependencies

- **US1 (P1)**: После Foundational — без зависимостей от US2/US3
- **US2 (P1)**: После US1 (карточка и модели готовы)
- **US3 (P1)**: После US2 (виджет `ProductPromoBadges` создан; расширение special)

### Within Each User Story

- Тесты пишутся первыми и должны падать до реализации
- Foundational: модели → API/моки → cart → UI types
- US2/US3: widget-тесты → виджет → интеграция в `ProductCard`

### Parallel Opportunities

- Phase 1: T002 и T003 параллельно
- Phase 2: T004, T005, T008, T010, T012 параллельно после T002
- US1 tests: T014–T017 параллельно; T022–T023 параллельно
- US2: T025–T027 параллельно (тесты + виджет)
- US3: T029–T030 параллельно
- Polish: T033–T034, T036 параллельно

---

## Parallel Example: User Story 1

```bash
# Тесты US1 параллельно:
T014: test/features/catalog/product_model_test.dart
T015: test/features/catalog/products_notifier_test.dart
T016: test/features/cart/cart_notifier_test.dart
T017: test/core/network/mock_api_client_products_test.dart

# Фикстуры US1 параллельно после implementation:
T022: test/features/catalog/*_test.dart
T023: test/features/home/repeat_order_test.dart
```

---

## Parallel Example: User Stories 2 & 3

```bash
# US2 — тесты и виджет:
T025: test/features/catalog/product_promo_badges_test.dart
T026: test/features/catalog/product_card_test.dart
T027: lib/features/catalog/presentation/widgets/product_promo_badges.dart

# US3 — расширение того же виджета:
T031: product_promo_badges.dart (+ special badge)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: User Story 1
4. **STOP and VALIDATE**: `flutter test` + quickstart С1, С2
5. Демо: каталог на боевом API с int id

### Incremental Delivery

1. Setup + Foundational → контракт и модели готовы
2. US1 → каталог/корзина на int id (MVP без бейджей)
3. US2 → бейдж «Акция»
4. US3 → бейдж «СПЕЦЦЕНА» + dual badges
5. Polish → полный quickstart

### Parallel Team Strategy

1. Один разработчик: Foundational → US1 → US2 → US3
2. Два разработчика после Foundational:
   - Dev A: US1 (int migration + integration tests)
   - Dev B: готовит US2/US3 тесты и `ProductPromoBadges` после merge US1

---

## Notes

- `OrderLine.productId` в API заказов остаётся `string` — конвертация только на границе checkout
- Analytics (`reportProductView` / `reportAddToCart`) остаётся `String` — передавать `.toString()`
- `oldPriceRub` парсить, но не отображать в UI (вне scope)
- Детальный экран товара без промо-бейджей (spec Assumptions)

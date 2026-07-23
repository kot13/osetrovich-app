---

description: "Список задач для фичи «Штучный товар, цена за кг и старая цена»"
---

# Tasks: Штучный товар, цена за кг и старая цена

**Input**: Design documents from `/specs/019-piece-product-pricing/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi-delta.yaml, quickstart.md

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

**Purpose**: Проверка контракта и согласованности артефактов фичи

- [x] T001 Сверить `openapi/openapi.yaml` со схемами из `specs/019-piece-product-pricing/contracts/openapi-delta.yaml` (поля `pricePerKgRub`, `pieceProduct`, `oldPriceRub` required в ProductSummary и ProductDetail)
- [x] T002 [P] Убедиться, что `openapi/openapi.yaml` описывает `pieceProduct` как признак штучного товара и `pricePerKgRub` с `minimum: 0`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели, моки и утилиты ценообразования — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 [P] Добавить `pricePerKgRub` и `pieceProduct` в `ProductSummary` и `ProductDetail` (`fromJson`, конструкторы) в `lib/features/catalog/domain/product.dart`
- [x] T004 Обновить `lib/core/network/mock_api_client.dart`: все товары с `pricePerKgRub` и `pieceProduct`; матрица комбинаций для id 1000, 1001, 1002 и икры 2000 (см. `research.md` §7)
- [x] T005 [P] Создать `lib/core/utils/product_price_display.dart` с `shouldShowStrikethroughOldPrice({required int oldPriceRub, required int priceRub})`
- [x] T006 [P] Добавить `formatPricePerKgRub(int pricePerKgRub)` в `lib/core/utils/price_formatter.dart` (суффикс `/кг` через `formatPriceRub`)
- [x] T007 [P] Unit-тест `shouldShowStrikethroughOldPrice` и `formatPricePerKgRub` в `test/core/utils/product_price_display_test.dart`
- [x] T008 [P] Расширить `test/features/catalog/product_model_test.dart`: `fromJson` с `pricePerKgRub`, `pieceProduct` (`true`/`false`); обновить все конструкторы фикстур в файле
- [x] T009 [P] Обновить фикстуры `ProductSummary`/`ProductDetail` (добавить `pricePerKgRub: 0`, `pieceProduct: false` или осмысленные значения) в `test/features/catalog/product_grid_test.dart`, `test/features/catalog/product_detail_screen_test.dart`, `test/features/cart/cart_line_item_view_test.dart`, `test/features/home/repeat_order_test.dart`
- [x] T010 [P] Обновить `test/core/network/mock_api_client_products_test.dart`: ожидания `pricePerKgRub` и `pieceProduct` в ответах мока

**Checkpoint**: Парсинг JSON и моки соответствуют OpenAPI; утилиты цен готовы; проект компилируется

---

## Phase 3: User Story 1 — Старая цена на кнопке добавления (Priority: P1) 🎯 MVP

**Goal**: Зачёркнутая старая цена слева от текущей на кнопке «цена +», когда товар не в корзине и `oldPriceRub > priceRub` (каталог, «Товары недели», деталь)

**Independent Test**: Товар id 1000 не в корзине — кнопка «[̶s̶t̶a̶r̶a̶y̶a̶] [текущая] +»; после добавления — «− 1 × [текущая] +» без старой цены (quickstart С1, С2, С4)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T011 [P] [US1] Создать widget-тесты зачёркнутой старой цены в `test/features/catalog/quantity_price_bar_test.dart` (`quantity: 0`, `oldPriceRub > priceRub`; равенство цен; `quantity >= 1` без старой)
- [x] T012 [P] [US1] Обновить `test/features/catalog/product_card_test.dart`: товар со скидкой — зачёркнутая старая на кнопке; товар в корзине — без старой цены
- [x] T013 [P] [US1] Обновить `test/features/catalog/product_detail_screen_test.dart`: нижняя панель со старой ценой при qty=0; без старой при qty≥1

### Implementation for User Story 1

- [x] T014 [US1] Расширить `lib/features/catalog/presentation/widgets/quantity_price_bar.dart`: параметр `oldPriceRub`; при `quantity == 0` и `shouldShowStrikethroughOldPrice` — `Row`/`FittedBox` с зачёркнутой старой ценой слева; стили через `AppColors`
- [x] T015 [US1] Передать `oldPriceRub: product.oldPriceRub` в `QuantityPriceBar` в `lib/features/catalog/presentation/widgets/product_card.dart`
- [x] T016 [US1] Передать `oldPriceRub: product.oldPriceRub` в `QuantityPriceBar` в `lib/features/catalog/presentation/product_detail_screen.dart` (`_ProductDetailBar`)

**Checkpoint**: Старая цена на кнопке работает в каталоге, на главной (через `ProductCard`) и на детали

---

## Phase 4: User Story 2 — Цена за килограмм на карточке и странице товара (Priority: P1)

**Goal**: Строка «X ₽/кг» под весом при `pricePerKgRub > 0` на карточке списка и на странице товара

**Independent Test**: Товар с `pricePerKgRub > 0` показывает цену/кг; при `0` — строки нет (quickstart С3, С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T017 [P] [US2] Расширить `test/features/catalog/product_card_test.dart`: `pricePerKgRub > 0` → текст `formatPricePerKgRub(...)`; `pricePerKgRub: 0` → отсутствие строки
- [x] T018 [P] [US2] Расширить `test/features/catalog/product_detail_screen_test.dart`: цена/кг в теле экрана при `pricePerKgRub > 0`; скрыта при нуле

### Implementation for User Story 2

- [x] T019 [US2] Добавить строку цены за кг под `weightLabel` в `lib/features/catalog/presentation/widgets/product_card.dart`; увеличить `_kProductTextBlockHeight` (~70) по `data-model.md`
- [x] T020 [US2] Добавить строку цены за кг в блок ценовой информации в `lib/features/catalog/presentation/product_detail_screen.dart` (`_ProductDetailBody`, под весом, над `priceRub`)

**Checkpoint**: Цена/кг отображается в каталоге, «Товары недели» и на детали; US1 и US2 работают вместе

---

## Phase 5: User Story 3 — Признак штучного товара в данных каталога (Priority: P2)

**Goal**: Приложение корректно получает и хранит `pieceProduct`; штучные и весовые товары отображаются и добавляются в корзину без ошибок (UI-бейдж вне scope)

**Independent Test**: Товар id 1002 (`pieceProduct: true`) — карточка и деталь без ошибок; increment/decrement в корзине работает (quickstart С7)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T021 [P] [US3] Unit-тест: `ProductSummary.fromJson` с `pieceProduct: true` и `false` в `test/features/catalog/product_model_test.dart` (если не покрыто в T008)
- [x] T022 [P] [US3] Widget-тест: штучный товар добавляется в корзину из `ProductCard` в `test/features/catalog/product_card_test.dart` (`pieceProduct: true`, проверка qty bar)

### Implementation for User Story 3

- [x] T023 [US3] Проверить мок id 1002 (`pieceProduct: true`) в `lib/core/network/mock_api_client.dart` и при необходимости скорректировать `weightLabel` для ручной проверки
- [x] T024 [US3] Убедиться, что `lib/features/cart/domain/cart_notifier.dart` не требует изменений для штучных товаров (количество = штуки); задокументировать в комментарии к PR при отсутствии кода

**Checkpoint**: `pieceProduct` парсится и не ломает каталог/корзину; отдельный UI не добавляется

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Регрессии, анализ и валидация по quickstart

- [x] T025 [P] Обновить оставшиеся фикстуры с `pricePerKgRub`/`pieceProduct` в `test/features/catalog/catalog_screen_test.dart`, `test/features/catalog/catalog_repository_test.dart` (если используют `ProductSummary`)
- [x] T026 Запустить `flutter test test/features/catalog/ test/core/utils/product_price_display_test.dart test/core/network/mock_api_client_products_test.dart` и исправить регрессии
- [x] T027 [P] Запустить `flutter analyze` — без ошибок
- [x] T028 Пройти сценарии С1–С8 из `specs/019-piece-product-pricing/quickstart.md` (ручная проверка)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: без зависимостей
- **Foundational (Phase 2)**: зависит от Phase 1 — **блокирует** все user stories
- **User Stories (Phase 3–5)**: зависят от Phase 2
  - US1 и US2 оба P1 — после Phase 2 можно параллельно, но US2 логически удобнее после US1 (общий `ProductCard`)
  - US3 зависит только от Phase 2 (парсинг в T003); может идти параллельно с US1/US2
- **Polish (Phase 6)**: после завершения желаемых user stories

### User Story Dependencies

| Story | Зависит от | Независимая проверка |
|-------|------------|----------------------|
| **US1** (P1) | Phase 2 | Кнопка со старой ценой без цены/кг |
| **US2** (P1) | Phase 2; удобно после US1 для одного PR в `ProductCard` | Цена/кг без изменений кнопки (можно до US1) |
| **US3** (P2) | Phase 2 (T003, T004) | Парсинг и корзина для `pieceProduct: true` |

### Within Each User Story

1. Тесты (T011–T013, T017–T018, T021–T022) — написать и убедиться, что **падают**
2. Реализация в указанных `lib/` файлах
3. Прогон тестов story — зелёные
4. Checkpoint перед следующей story

### Parallel Opportunities

- **Phase 1**: T001 и T002 параллельно
- **Phase 2**: T003, T005, T006 параллельно; T007–T010 параллельно после T003–T006
- **US1**: T011, T012, T013 параллельно; затем T014 → T015, T016 (T015/T016 параллельно после T014)
- **US2**: T017, T018 параллельно; T019 и T020 — разные файлы, параллельно после тестов
- **US3**: T021, T022 параллельно
- **Polish**: T025, T027 параллельно

---

## Parallel Example: User Story 1

```bash
# Тесты US1 одновременно (разные файлы):
test/features/catalog/quantity_price_bar_test.dart
test/features/catalog/product_card_test.dart      # только кейсы старой цены
test/features/catalog/product_detail_screen_test.dart

# После T014 (QuantityPriceBar) — параллельно:
lib/features/catalog/presentation/widgets/product_card.dart
lib/features/catalog/presentation/product_detail_screen.dart
```

---

## Parallel Example: Foundational

```bash
# Параллельно после сверки OpenAPI:
lib/features/catalog/domain/product.dart
lib/core/utils/product_price_display.dart
lib/core/utils/price_formatter.dart

# Затем последовательно:
lib/core/network/mock_api_client.dart   # зависит от product.dart

# Параллельно после утилит и модели:
test/core/utils/product_price_display_test.dart
test/features/catalog/product_model_test.dart
test/core/network/mock_api_client_products_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001–T002)
2. Phase 2: Foundational (T003–T010) — **обязательно**
3. Phase 3: User Story 1 (T011–T016)
4. **STOP and VALIDATE**: quickstart С1, С2, С4
5. Демо: скидка видна на кнопке в каталоге

### Incremental Delivery

1. Setup + Foundational → контракт и модели готовы
2. US1 → старая цена на кнопке → demo
3. US2 → цена за кг на карточках → demo
4. US3 → штучный товар в данных → demo
5. Polish → полный quickstart

### Suggested MVP Scope

**MVP = Phase 1 + Phase 2 + Phase 3 (US1)** — минимальная ценность: покупатель видит скидку на кнопке «добавить» без открытия карточки товара.

---

## Notes

- `oldPriceRub` уже парсится с фичи 009 — в US1 только UI
- `ProductCard` на главной («Товары недели») наследует US1/US2 без отдельных задач
- Корзина, заказы и бейджи промо — без изменений (FR-009)
- При длинных суммах на compact-кнопке использовать `FittedBox` (plan.md, research §3)
- Коммит после каждой фазы или логической группы задач

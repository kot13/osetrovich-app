---

description: "Список задач для фичи «Оформление заказа через API»"
---

# Tasks: Оформление заказа через API

**Input**: Design documents from `/specs/012-api-order-create/`

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

**Purpose**: Верификация контракта и строки локализации для поля квартиры

- [x] T001 Verify `openapi/openapi.yaml` v0.11.2 matches `specs/012-api-order-create/contracts/openapi.yaml`: `OrderLineInput.id` (integer), `CreateOrderRequest.apartment`/`lat`/`lng`, `OrderLine.id` (integer)
- [x] T002 [P] Add `cartApartmentLabel` («Квартира / офис») and `cartApartmentHint` («Необязательно») to `lib/core/l10n/app_strings.dart`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Доменные модели заказа и мок API — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 [P] Update `lib/features/cart/domain/order.dart`: `OrderLineInput.id` (int), `CreateOrderRequest` (+optional `apartment`, `lat`, `lng`), `OrderLine.id` (int), `Order` (+optional `apartment`, `lat`, `lng`); `toJson` omits empty/null optional fields per data-model.md
- [x] T004 [P] Create `test/features/cart/order_test.dart`: `CreateOrderRequest.toJson` uses `items[].id` (int); `apartment`/`comment` omitted when empty; `OrderLine.fromJson` parses `id` as int
- [x] T005 Update `lib/core/network/mock_api_client.dart` `createOrder`: read `item.id` (int), lookup product by int id, include `request.apartment` in `CurrentOrder`/`Order` response, `OrderLine.id` as int (remove `int.tryParse`/`productId` string)
- [x] T006 [P] Update `test/core/network/mock_api_client_orders_test.dart`: `OrderLineInput(id: 1000)`, success with `apartment: '42'`, unknown id `999999` → `PRODUCT_UNAVAILABLE`
- [x] T007 [P] Update `OrderLine` fixtures in `test/features/home/home_screen_test.dart`, `test/features/home/home_order_history_section_test.dart`: replace `productId: '1000'` with `id: 1000`

**Checkpoint**: Модели и мок соответствуют OpenAPI v0.11.2 — можно начинать user stories

---

## Phase 3: User Story 1 — Оформление заказа с актуальными данными доставки (Priority: P1) 🎯 MVP

**Goal**: Отправка заказа с целочисленными id товаров, опциональной квартирой в payload, сохранение квартиры в `PendingCheckout` при auth gate

**Independent Test**: Авторизованный пользователь оформляет заказ с заполненным адресом → успех и пустая корзина; unit-тесты checkout/pending; передача `apartment` в repository (quickstart С2, С3, С6; сценарий с квартирой в UI — после US2)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T008 [P] [US1] Update `test/features/cart/checkout_notifier_test.dart`: assert `CreateOrderRequest` items use `id` (int) not `productId`; `submit(apartment: '42')` passes trimmed apartment to repository mock
- [x] T009 [P] [US1] Create `test/features/cart/pending_checkout_test.dart`: `save(address, apartment, comment)` persists all fields; `clear()` resets state
- [x] T010 [P] [US1] Update `integration_test/cart_checkout_flow_test.dart`: checkout succeeds with updated `OrderLineInput.id` contract (regression after model change)

### Implementation for User Story 1

- [x] T011 [US1] Update `lib/features/cart/domain/checkout_notifier.dart`: `submit({required String address, String? apartment, String? comment})`; build `OrderLineInput(id: entry.key, quantity: entry.value)`; trim and omit empty `apartment` in `CreateOrderRequest`
- [x] T012 [US1] Update `lib/features/cart/domain/pending_checkout_provider.dart`: add `apartment` field to `PendingCheckout`; extend `save({required address, required apartment, required comment})`
- [x] T013 [US1] Update `lib/features/cart/presentation/cart_screen.dart`: add `_apartmentController`; pass `apartment` to `pendingCheckoutProvider.save`, `_resumePendingCheckoutAfterAuth`, `_submitOrder`, and `clear()` on success

**Checkpoint**: Заказ отправляется с int id; квартира передаётся через notifier/pending flow (UI поле — в US2)

---

## Phase 4: User Story 2 — Поле квартиры или офиса в форме заказа (Priority: P1)

**Goal**: Необязательное поле «Квартира / офис» между адресом и комментарием в форме checkout

**Independent Test**: Открыть корзину с товарами → поле квартиры видно; оформление без квартиры разрешено; с квартирой значение уходит в заказ (quickstart С1, С2)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T014 [P] [US2] Create `test/features/cart/checkout_form_test.dart`: `CheckoutForm` shows apartment `TextField` with `AppStrings.cartApartmentLabel` between address and comment fields
- [x] T015 [P] [US2] Extend `test/features/cart/cart_screen_test.dart` [US2]: filled cart shows apartment field; submit with address only (empty apartment) does not block checkout

### Implementation for User Story 2

- [x] T016 [US2] Update `lib/features/cart/presentation/widgets/checkout_form.dart`: add `apartmentController` parameter; insert `TextField` for apartment after address field (label/hint from `AppStrings`)
- [x] T017 [US2] Wire `apartmentController: _apartmentController` from `lib/features/cart/presentation/cart_screen.dart` into `CheckoutForm` inside `_FilledCartBody`

**Checkpoint**: Пользователь видит и заполняет поле квартиры; полный сценарий US1+US2 (заказ с квартирой) готов

---

## Phase 5: User Story 3 — Снятие фокуса с полей ввода (Priority: P2)

**Goal**: Тап вне полей ввода на экране корзины снимает фокус и скрывает клавиатуру

**Independent Test**: Фокус на поле адреса → тап по строке товара или блоку условий → клавиатура скрыта, текст сохранён; кнопка «Оформить» и ± работают (quickstart С4)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T018 [P] [US3] Extend `test/features/cart/cart_screen_test.dart` [US3]: tap outside `TextField` unfocuses primary focus (use `FocusNode` or `FocusManager` assertion)

### Implementation for User Story 3

- [x] T019 [US3] Wrap `ListView` in `_FilledCartBody` (`lib/features/cart/presentation/cart_screen.dart`) with `GestureDetector(onTap: () => FocusManager.instance.primaryFocus?.unfocus(), behavior: HitTestBehavior.translucent)` per research.md §5

**Checkpoint**: UX снятия фокуса работает без регрессии кнопок и quantity bar

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Повтор заказа, оставшиеся фикстуры, финальная валидация

- [x] T020 [P] Update `lib/features/home/domain/repeat_order.dart`: use `line.id` (int) directly instead of `int.parse(line.productId)`; update `skippedProductIds` to `int`
- [x] T021 [P] Update `test/features/home/repeat_order_test.dart`: `OrderLine(id: 1001, ...)` fixtures; assert repeat flow with int ids
- [x] T022 [P] Update remaining `OrderLine` seed data in `lib/core/network/mock_api_client.dart` (e.g. `getCurrentOrder`, order history helpers) from `productId` string to `id` int
- [x] T023 Run `flutter analyze` and full `flutter test` per `specs/012-api-order-create/quickstart.md`; fix any regressions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **User Stories (Phase 3–5)**: Depend on Foundational completion
  - US1 → US2 recommended order (US2 UI для полного сценария с квартирой)
  - US3 independent of US2, can run parallel with US2 after US1
- **Polish (Phase 6)**: After US1–US3 (or minimally after US1 for repeat_order fixes)

### User Story Dependencies

- **User Story 1 (P1)**: After Phase 2 — core API checkout; не зависит от US3
- **User Story 2 (P1)**: After Phase 2; интегрируется с US1 (`cart_screen`, `CheckoutForm`); сценарий «заказ с квартирой» требует US1+US2
- **User Story 3 (P2)**: After Phase 2; только `cart_screen.dart` — параллельно с US2

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Domain/notifier before presentation wiring
- Story checkpoint before next priority

### Parallel Opportunities

- **Phase 1**: T002 ∥ T001 (после быстрой верификации T001)
- **Phase 2**: T003, T004, T006, T007 параллельно после T003; T005 после T003
- **US1**: T008, T009, T010 параллельно; T011 → T012 → T013 последовательно
- **US2**: T014, T015 параллельно; T016 → T017
- **US3**: T018 до T019
- **Polish**: T020, T021, T022 параллельно; T023 последним

---

## Parallel Example: User Story 1

```bash
# Тесты US1 параллельно (разные файлы):
Task T008: test/features/cart/checkout_notifier_test.dart
Task T009: test/features/cart/pending_checkout_test.dart
Task T010: integration_test/cart_checkout_flow_test.dart

# После падения тестов — реализация по цепочке:
Task T011 → T012 → T013
```

---

## Parallel Example: User Story 2 + User Story 3

```bash
# После US1, двумя потоками:
Developer A: T014 → T015 → T016 → T017  (поле квартиры)
Developer B: T018 → T019                 (снятие фокуса)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (**CRITICAL**)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: `flutter test test/features/cart/checkout_notifier_test.dart test/core/network/mock_api_client_orders_test.dart` — заказ с int id работает
5. Demo: оформление без квартиры (адрес + комментарий)

### Incremental Delivery

1. Setup + Foundational → контракт синхронизирован
2. US1 → API checkout + pending apartment → Validate
3. US2 → UI поле квартиры → Validate (quickstart С1–С2)
4. US3 → unfocus UX → Validate (quickstart С4)
5. Polish → repeat_order + full test suite

### Suggested MVP Scope

**User Story 1** после Phase 2 — минимально жизнеспособное обновление: заказы принимаются API с int id. Для полной ценности фичи добавить **US2** (поле квартиры) в том же релизе.

---

## Notes

- OpenAPI в корне уже v0.11.2 — merge не требуется (T001 — верификация)
- Координаты `lat`/`lng` в моделях для парсинга ответа; в UI и `toJson` запроса не передаются (spec Assumptions)
- `CartLineItemView.productId` (int) — без изменений; меняется только API-слой `OrderLine`/`OrderLineInput`
- Commit после каждой фазы или логической группы задач
- [P] задачи = разные файлы, без конфликтов

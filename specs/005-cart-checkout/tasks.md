---

description: "Список задач для фичи «Корзина и оформление заказа»"
---

# Tasks: Корзина и оформление заказа

**Input**: Design documents from `/specs/005-cart-checkout/`

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

**Purpose**: Контракт API, структура каталогов, строки локализации

- [x] T001 Merge OpenAPI v0.5.0 from `specs/005-cart-checkout/contracts/openapi.yaml` into `openapi/openapi.yaml` (`POST /orders`, Order schemas, `product_unavailable` error code)
- [x] T002 [P] Create directories `lib/features/cart/data/` and `lib/features/cart/presentation/widgets/` per plan.md
- [x] T003 [P] Create stub `integration_test/cart_checkout_flow_test.dart` with `main()` placeholder
- [x] T004 [P] Add cart/checkout UI strings to `lib/core/l10n/app_strings.dart`: cartAddressLabel, cartAddressHint, cartCommentLabel, cartCommentHint, cartItemsSubtotal, cartDeliveryFee, cartTotal, cartDeliveryFree, cartDeliveryTerms (multiline FR-005), cartCheckout, cartOrderSuccess, cartOrderSuccessDetails, addressRequired, checkoutAuthRequired, orderFailed, productUnavailableInCart

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели заказа, API-клиент, моки, расчёт доставки, провайдеры позиций и итогов — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T005 [P] Create `lib/features/cart/domain/delivery_fee.dart` with `freeDeliveryThresholdRub`, `paidDeliveryFeeRub`, `calculateDeliveryFeeRub(int itemsSubtotalRub)` per data-model.md
- [x] T006 [P] Create `lib/features/cart/domain/order.dart`: `OrderLineInput`, `CreateOrderRequest`, `OrderLine`, `Order`, `OrderStatus` with `fromJson`/`toJson` per data-model.md and contracts
- [x] T007 [P] Create `lib/features/cart/domain/cart_line_item_view.dart`: `CartLineItemView` with `lineTotalRub` computed field per data-model.md
- [x] T008 Extend `lib/core/network/api_client.dart` with `createOrder(CreateOrderRequest)`; implement in `DioApiClient` (`POST /orders`, bearer token via existing interceptor)
- [x] T009 Update `lib/core/network/mock_api_client.dart`: implement `createOrder` — auth check, address trim validation, product lookup, delivery fee recalculation, `ORD-{n}` orderNumber, 400/401 errors per research.md §8
- [x] T010 [P] Create `lib/features/cart/data/order_repository.dart` wrapping `ApiClient.createOrder`
- [x] T011 [P] Create `lib/features/cart/domain/cart_lines_provider.dart`: async resolve `CartNotifier` product IDs via `CatalogRepository.getProductById`, build `List<CartLineItemView>`, remove unavailable products from cart on 404
- [x] T012 Create `lib/features/cart/domain/order_totals_provider.dart`: `Provider<OrderTotals>` from `cartLinesProvider` + `calculateDeliveryFeeRub` per data-model.md §2
- [x] T013 Add `clear()` method to `lib/features/cart/domain/cart_notifier.dart` resetting state to `{}`
- [x] T014 [P] Unit-тест `calculateDeliveryFeeRub` в `test/features/cart/delivery_fee_test.dart` (1999→300, 2000→0, 2500→0)
- [x] T015 [P] Unit-тест `MockApiClient.createOrder` в `test/core/network/mock_api_client_orders_test.dart` (201 success, 401, 400 empty address, 400 product_unavailable)
- [x] T016 [P] Extend `test/features/cart/cart_notifier_test.dart` with `clear()` removes all items and distinctCount becomes 0

**Checkpoint**: API заказов, domain-модели и провайдеры итогов готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Просмотр непустой корзины (Priority: P1) 🎯 MVP

**Goal**: При непустой корзине — список позиций, итоги с доставкой, поля адреса/комментария, блок условий, кнопка «Оформить»

**Independent Test**: Добавить товары в каталоге → открыть «Корзину» → все блоки видны, суммы корректны (quickstart С2, С4)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T017 [P] [US1] Unit-тест `orderTotalsProvider` в `test/features/cart/order_totals_test.dart` (subtotal, delivery 300 below 2000, free at 2000+)
- [x] T018 [P] [US1] Widget-тест `CartOrderSummary` в `test/features/cart/cart_order_summary_test.dart` (three lines: товары, доставка, итого)
- [x] T019 [P] [US1] Widget-тест `DeliveryTermsCard` в `test/features/cart/delivery_terms_card_test.dart` (FR-005 text present)
- [x] T020 [P] [US1] Widget-тест filled `CartScreen` в `test/features/cart/cart_screen_test.dart` (list visible, summary, address field, terms, checkout button; empty state when cart empty)

### Implementation for User Story 1

- [x] T021 [P] [US1] Create `lib/features/cart/presentation/widgets/cart_line_tile.dart`: photo, name, weight, quantity text, line total; read-only row (no ± yet)
- [x] T022 [P] [US1] Create `lib/features/cart/presentation/widgets/cart_order_summary.dart`: rows for itemsSubtotal, deliveryFee (or «Бесплатно»), total using `formatPriceRub` and `AppColors`
- [x] T023 [P] [US1] Create `lib/features/cart/presentation/widgets/delivery_terms_card.dart`: static `AppStrings.cartDeliveryTerms` in styled card
- [x] T024 [P] [US1] Create `lib/features/cart/presentation/widgets/checkout_form.dart`: `TextField` for address and comment with labels/hints; «Оформить» accent button (onPressed callback param, no submit logic yet)
- [x] T025 [US1] Replace `lib/features/cart/presentation/cart_screen.dart`: branch on `cartDistinctCountProvider` — empty `EmptyState` (existing) vs `ListView` with `cartLinesProvider` async (loading/error), `CartLineTile` list, `CartOrderSummary`, `DeliveryTermsCard`, `CheckoutForm`
- [x] T026 [US1] Wire `order_totals_provider` into `CartOrderSummary` inside `cart_screen.dart`

**Checkpoint**: Непустая корзина отображает полный экран оформления; изменение количества и submit — в US2/US3

---

## Phase 4: User Story 2 — Изменение состава корзины на экране (Priority: P1)

**Goal**: ± на строках корзины, реактивный пересчёт сумм и бейджа Tab Bar; пустое состояние при удалении последней позиции

**Independent Test**: На экране корзины изменить qty и удалить позицию → итоги и бейдж обновились (quickstart С3)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T027 [P] [US2] Unit-тест `cartLinesProvider` в `test/features/cart/cart_lines_provider_test.dart` (resolves products, line totals, removes 404 product from cart)
- [x] T028 [P] [US2] Widget-тест `CartLineTile` с `QuantityPriceBar` в `test/features/cart/cart_line_tile_test.dart` (−/+ callbacks, line total updates)
- [x] T029 [P] [US2] Extend `test/features/cart/cart_screen_test.dart` [US2]: tap +/− updates summary; last item removed → empty state

### Implementation for User Story 2

- [x] T030 [US2] Update `lib/features/cart/presentation/widgets/cart_line_tile.dart`: replace static quantity with compact `QuantityPriceBar` from `lib/features/catalog/presentation/widgets/quantity_price_bar.dart`; wire to `cartNotifierProvider` increment/decrement
- [x] T031 [US2] Ensure `lib/features/cart/presentation/cart_screen.dart` rebuilds list and `CartOrderSummary` reactively on `cartNotifierProvider` changes (watch providers)
- [x] T032 [US2] Verify `lib/features/shell/presentation/main_shell.dart` badge updates when quantity changes on cart screen (extend `test/features/shell/main_shell_test.dart` if needed)

**Checkpoint**: Редактирование корзины на экране синхронизировано с каталогом и бейджем Tab Bar

---

## Phase 5: User Story 3 — Оформление заказа (Priority: P1)

**Goal**: Авторизованный пользователь оформляет заказ → success dialog → корзина очищена; валидация адреса и auth gate

**Independent Test**: Login → fill address → «Оформить» → success → empty cart (quickstart С5–С7)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T033 [P] [US3] Unit-тест `CheckoutNotifier` в `test/features/cart/checkout_notifier_test.dart` (address validation, success clears cart, error preserves cart, isSubmitting guard)
- [x] T034 [P] [US3] Widget-тест auth gate в `test/features/cart/cart_screen_test.dart` [US3]: unauthenticated tap «Оформить» → navigate/prompt login; no order created
- [x] T035 [P] [US3] Integration-тест checkout flow в `integration_test/cart_checkout_flow_test.dart`: add items → auth → cart → address → checkout → success dialog → empty cart

### Implementation for User Story 3

- [x] T036 [P] [US3] Create `lib/features/cart/domain/checkout_notifier.dart` with `checkoutNotifierProvider`: `submit(address, comment)` calls `OrderRepository.createOrder`, `cartNotifier.clear()` on success, error handling per research.md §4
- [x] T037 [US3] Wire `CheckoutForm` in `lib/features/cart/presentation/cart_screen.dart` to `CheckoutNotifier`: disable button while `isSubmitting`; show `addressRequired` / `orderFailed` errors; on success show `AlertDialog` with `AppStrings.cartOrderSuccess` and order number
- [x] T038 [US3] Implement auth gate in `lib/features/cart/presentation/cart_screen.dart`: if `!isAuthenticatedProvider` on «Оформить» → `context.push('/auth/phone')` (preserve form controllers)
- [x] T039 [US3] Handle `product_unavailable` API error in `checkout_notifier.dart`: show `productUnavailableInCart`, refresh `cartLinesProvider`

**Checkpoint**: Полный цикл оформления заказа работает end-to-end

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Финальная валидация, регрессии, документация

- [x] T040 [P] Run `dart format` on all new/modified files under `lib/features/cart/` and `test/features/cart/`
- [x] T041 Run `flutter analyze` and fix any issues in cart/checkout files
- [x] T042 Run full `flutter test` and fix regressions in `test/features/cart/cart_screen_test.dart` and shell tests
- [x] T043 [P] Manual validation per `specs/005-cart-checkout/quickstart.md` scenarios С1–С9; note results in PR description
- [x] T044 Update `specs/005-cart-checkout/spec.md` status Draft → Implemented after acceptance

### Post-implementation fixes (2026-07-14)

- [x] T045 [US3] Create `lib/features/cart/domain/pending_checkout_provider.dart` and wire auth gate with `?from=checkout` query param
- [x] T046 [US3] Update auth screens: pass `from` phone→sms; SMS success navigates to `/cart` when `from=checkout`, else `/profile`
- [x] T047 [US3] Auto-resume checkout on `CartScreen` after auth (`initState` + `isAuthenticatedProvider` listener)
- [x] T048 [P] Create `lib/core/network/mock_profile_sync.dart`; sync profile on session restore/set and before `createOrder`
- [x] T049 [P] Widget-тест `checkout resumes order after auth from checkout` in `test/features/cart/cart_screen_test.dart`
- [x] T050 [P] Update `integration_test/cart_checkout_flow_test.dart`: address before checkout, auto order after auth
- [x] T051 [US2] Autofocus on `phone_input_screen` and `sms_code_screen` (`FocusNode` + `autofocus: true`)
- [x] T052 Update specs (`spec.md`, `research.md`, `data-model.md`, `quickstart.md`) and `001-init-app-shell/spec.md` (autofocus FR)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (OpenAPI merge T001) — **BLOCKS all user stories**
- **User Stories (Phase 3–5)**: All depend on Foundational completion
  - US1 (Phase 3) → US2 (Phase 4) → US3 (Phase 5) recommended sequentially (shared `cart_screen.dart`)
  - US2 can start after US1 `CartLineTile` exists; US3 after US1 `CheckoutForm` exists
- **Polish (Phase 6)**: Depends on US1–US3 complete

### User Story Dependencies

- **User Story 1 (P1)**: After Phase 2 — no dependency on US2/US3
- **User Story 2 (P1)**: After US1 `CartLineTile` and filled `CartScreen` layout
- **User Story 3 (P1)**: After US1 `CheckoutForm`; integrates US2 cart state for submit payload

### Within Each User Story

- Tests MUST be written first and FAIL before implementation
- Domain/providers before presentation widgets
- Widgets before `cart_screen.dart` integration
- Story checkpoint before next priority

### Parallel Opportunities

- Phase 1: T002, T003, T004 in parallel after T001
- Phase 2: T005, T006, T007, T010, T014, T015, T016 in parallel; T008–T009 sequential; T011–T012 after T007
- US1 tests T017–T020 in parallel; widgets T021–T024 in parallel before T025
- US2 tests T027–T029 in parallel
- US3 tests T033–T035 in parallel; T036 before T037–T039

---

## Parallel Example: User Story 1

```bash
# Tests first (parallel):
T017: test/features/cart/order_totals_test.dart
T018: test/features/cart/cart_order_summary_test.dart
T019: test/features/cart/delivery_terms_card_test.dart
T020: test/features/cart/cart_screen_test.dart

# Widgets (parallel):
T021: lib/features/cart/presentation/widgets/cart_line_tile.dart
T022: lib/features/cart/presentation/widgets/cart_order_summary.dart
T023: lib/features/cart/presentation/widgets/delivery_terms_card.dart
T024: lib/features/cart/presentation/widgets/checkout_form.dart

# Then integrate:
T025–T026: lib/features/cart/presentation/cart_screen.dart
```

---

## Parallel Example: Foundational Phase

```bash
# After T001 OpenAPI merge:
T005: lib/features/cart/domain/delivery_fee.dart
T006: lib/features/cart/domain/order.dart
T007: lib/features/cart/domain/cart_line_item_view.dart
T014: test/features/cart/delivery_fee_test.dart

# Then API layer:
T008 → T009 → T010

# Then providers:
T011 → T012 → T013
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: quickstart С2, С4 — экран корзины с итогами и условиями
5. Demo без оформления заказа

### Incremental Delivery

1. Setup + Foundational → API и провайдеры готовы
2. US1 → просмотр корзины с итогами (MVP UI)
3. US2 → редактирование состава на экране
4. US3 → оформление заказа end-to-end
5. Polish → quickstart С1–С9

### Parallel Team Strategy

1. Один разработчик: Phase 1 → 2 → 3 → 4 → 5 → 6 последовательно
2. Два разработчика после Phase 2:
   - Dev A: US1 widgets + cart_screen layout
   - Dev B: Foundational tests + US3 domain (`checkout_notifier`, `order_repository`) — merge before T037

---

## Notes

- `CartNotifier` и `QuantityPriceBar` уже есть из `004-product-catalog`; расширяем, не дублируем
- Пустое состояние корзины (`EmptyState`) не менять — тексты из `001-init-app-shell`
- Кнопка «Оформить» — `AppColors.accent`, текст `AppColors.dark`
- `POST /orders` требует JWT; мок должен отклонять запрос без токена
- История заказов вне scope — не добавлять экраны/эндпоинты списка заказов

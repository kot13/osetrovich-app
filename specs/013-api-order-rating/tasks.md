---

description: "Список задач для фичи «Текущий заказ и оценка через Mobile API»"
---

# Tasks: Текущий заказ и оценка через Mobile API

**Input**: Design documents from `/specs/013-api-order-rating/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и contract-тесты включены для каждой user story.

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

**Purpose**: Верификация контракта OpenAPI v0.12.1 (TTL 7 суток) и строк локализации

- [x] T001 Verify `openapi/openapi.yaml` v0.12.1 matches `specs/013-api-order-rating/contracts/openapi.yaml`: paths `/orders/current`, `/orders/{orderId}/rating`, `/orders/{orderId}/rating/skip`; TTL 7 суток от `delivery_at`; error code `rating_period_expired` on 400
- [x] T002 [P] Add to `lib/core/l10n/app_strings.dart`: `ratingPeriodExpired` («Срок оценки истёк»), `ratingAlreadySet` («Оценка уже отправлена или пропущена»), `ratingSubmitFailed` («Не удалось отправить оценку. Попробуйте ещё раз»)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Удаление demo-seed, `deliveryAt`, TTL в моке, contract-тесты — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 Remove `_seedDemoOrdersIfNeeded`, `demoPhoneDelivery`, `demoPhoneRatingPending`, `demoPhoneRatingSkipped` and all call sites from `lib/core/network/mock_api_client.dart`; `getCurrentOrder()` returns last eligible order from `_ordersByUserId` (via `createOrder` only) or `null`
- [x] T004 [P] Update `lib/features/cart/domain/order.dart`: add optional `deliveryAt` (`DateTime?`) to `CurrentOrder`/`Order`; parse `delivery_at` / `deliveryAt` from JSON if present; include in `copyWith`
- [x] T005 [P] Add `@visibleForTesting` helpers in `lib/core/network/mock_api_client.dart`: `completeOrderForRating(String orderId, {DateTime? deliveryAt})` sets `status: completed`, `ratingState: pending`, `deliveryAt`; `expireOrderRatingPeriod(String orderId)` shifts `deliveryAt` to 8+ days ago
- [x] T006 Update `lib/core/network/mock_api_client.dart`: in `submitOrderRating` / `skipOrderRating` reject if `now > deliveryAt + 7 days` with `ApiException(code: 'rating_period_expired')`; in `getCurrentOrder` return `null` for unrated completed orders past TTL
- [x] T007 [P] Rewrite `test/core/network/mock_api_client_home_test.dart`: createOrder → completeOrderForRating → rating/skip; duplicate 409; `expireOrderRatingPeriod` → `rating_period_expired`; expired unrated order → `getCurrentOrder` null
- [x] T008 [P] Update `test/core/network/mock_api_client_test.dart`: remove demo-phone order switching; use createOrder-based flow
- [x] T009 [P] Update `test/features/cart/current_order_provider_test.dart`: replace demo phone fixtures with `createOrder`-based mock setup
- [x] T010 Verify `lib/core/network/api_client.dart` `DioApiClient`: `getCurrentOrder` parses `{order: null|object}`; rating endpoints parse direct `CurrentOrder`; paths match v0.12.1 (fix only if mismatch)

**Checkpoint**: Мок без автосида; TTL 7 суток в моке; contract-тесты зелёные — можно начинать user stories

---

## Phase 3: User Story 1 — Актуальный текущий заказ с сервера (Priority: P1) 🎯 MVP

**Goal**: Блок «История заказов» на «Главной» показывает данные с Mobile API; после оформления заказа блок обновляется без ручного refresh

**Independent Test**: Авторизованный пользователь с заказом на сервере видит статус/состав/сумму на «Главной»; после checkout новый заказ появляется на «Главной»; при ошибке загрузки — сообщение и «Повторить» (quickstart С1–С3, С7)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T011 [P] [US1] Extend `test/features/home/home_screen_test.dart`: when `currentOrderProvider` throws, `_HomeSectionError` with `AppStrings.homeLoadError` and retry invalidates provider
- [x] T012 [P] [US1] Extend `test/features/cart/checkout_notifier_test.dart`: after successful `submit`, `currentOrderProvider` is invalidated (verify via `ProviderContainer` listener or mock ref)

### Implementation for User Story 1

- [x] T013 [US1] Update `lib/features/cart/domain/checkout_notifier.dart`: after successful `createOrder`, call `ref.invalidate(currentOrderProvider)` (import from `order_repository.dart`)
- [x] T014 [US1] Verify `lib/features/cart/data/order_repository.dart` `currentOrderProvider`: returns `null` without HTTP when `authSessionProvider == null`; no changes if already correct

**Checkpoint**: Текущий заказ с сервера на «Главной»; синхронизация после checkout — MVP готов

---

## Phase 4: User Story 2 — Оценка выполненного заказа с сохранением на сервере (Priority: P1)

**Goal**: Оценка 1–5 звёзд + comment (≤ 500) на сервер в течение 7 суток; обработка ошибок включая `rating_period_expired`

**Independent Test**: `pending` заказ → оценка → prompt скрыт; 409 → SnackBar; expired TTL → «Срок оценки истёк» (quickstart С4, С8, С9)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T015 [P] [US2] Extend `test/features/home/order_rating_sheet_test.dart`: `TextField` has `maxLength: 500`
- [x] T016 [P] [US2] Extend `test/features/home/home_order_history_section_test.dart`: `submitOrderRating` throws `rating_already_set` → SnackBar `ratingAlreadySet`; throws `rating_period_expired` → SnackBar `ratingPeriodExpired` + provider invalidated
- [x] T017 [P] [US2] Extend `test/core/network/mock_api_client_home_test.dart`: `submitOrderRating` success sets `ratingState: submitted`; invalid stars throws

### Implementation for User Story 2

- [x] T018 [US2] Update `lib/features/home/presentation/order_rating_sheet.dart`: add `maxLength: 500` to comment `TextField`
- [x] T019 [US2] Update `lib/features/home/presentation/home_order_history_section.dart` `_onRateOrder`: `try/catch ApiException`; map codes to `ratingPeriodExpired`, `ratingAlreadySet`, `ratingSubmitFailed`, `ratingUnavailable`, `networkError`; invalidate on 409/404/`rating_period_expired`

**Checkpoint**: Оценка сохраняется; истёкший срок и дубликаты обрабатываются корректно

---

## Phase 5: User Story 3 — Пропуск оценки с фиксацией на сервере (Priority: P2)

**Goal**: «Пропустить» фиксирует `skipped` на сервере в пределах TTL 7 суток

**Independent Test**: `pending` → «Пропустить» → prompt скрыт; expired TTL → ошибка (quickstart С5, С9)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T020 [P] [US3] Extend `test/core/network/mock_api_client_home_test.dart`: `skipOrderRating` sets `skipped`; expired period → `rating_period_expired`
- [x] T021 [P] [US3] Extend `test/features/home/home_order_history_section_test.dart`: «Пропустить» calls `skipOrderRating`, invalidates provider; `rating_period_expired` shows SnackBar

### Implementation for User Story 3

- [x] T022 [US3] Update `lib/features/home/presentation/home_order_history_section.dart` `_onSkipRating`: `try/catch ApiException` with same error mapping as `_onRateOrder`; invalidate on 409/404/`rating_period_expired`

**Checkpoint**: Пропуск работает в пределах TTL и синхронизируется с сервером

---

## Phase 6: User Story 4 — Оценка заказа из уведомления (Priority: P2)

**Goal**: Согласованное поведение оценки из уведомления, включая истёкший срок

**Independent Test**: Уведомление при `pending` → оценка OK; при expired/`submitted`/`skipped` → сообщение об ошибке (quickstart С6, С9)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО)

- [x] T023 [P] [US4] Create or extend `test/features/notifications/notification_detail_screen_test.dart`: `ratingState != pending` → `ratingUnavailable`; `rating_period_expired` on submit → `ratingPeriodExpired` SnackBar

### Implementation for User Story 4

- [x] T024 [US4] Update `lib/features/notifications/presentation/notification_detail_screen.dart` `_onRateOrder`: `try/catch ApiException`; map `rating_period_expired` and other codes; invalidate `currentOrderProvider` on success and on 409/404/expired

**Checkpoint**: Оценка из уведомления согласована с «Главной»

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Регрессии, финальная валидация, обновление спеки

- [x] T025 [P] Run `flutter analyze` and `flutter test`; fix regressions in `test/features/home/`, `test/core/network/mock_api_client_home_test.dart`, `test/features/cart/current_order_provider_test.dart`
- [x] T026 [P] Verify `lib/core/network/providers.dart` has `useMockApi = false` for production build
- [x] T027 Validate manual scenarios from `specs/013-api-order-rating/quickstart.md` (С1–С9) against `https://trout.osetrovich.ru/v1`
- [x] T028 Update `specs/013-api-order-rating/spec.md` Status to **Implemented** with implementation date after all tasks complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **User Stories (Phase 3–6)**: Depend on Foundational completion
  - US1 (P1) — MVP
  - US2 (P1) — error mapping reused by US3/US4
  - US3 (P2) — after US2 T019 pattern
  - US4 (P2) — after US2 T019 pattern
- **Polish (Phase 7)**: Depends on desired user stories complete

### User Story Dependencies

| Story | Priority | Depends on | Independent Test |
|-------|----------|------------|------------------|
| US1 | P1 | Phase 2 | Заказ с API на «Главной» + checkout sync |
| US2 | P1 | Phase 2 | Оценка в TTL; `rating_period_expired` UX |
| US3 | P2 | US2 (same widget) | Пропуск в TTL; expired → ошибка |
| US4 | P2 | US2 (error mapping) | Уведомление + expired согласованы |

### Parallel Opportunities

- **Phase 1**: T002 ∥ T001
- **Phase 2**: T004–T005 ∥ after T003; T007–T009 ∥ after T006
- **US1**: T011 ∥ T012; then T013 → T014
- **US2**: T015 ∥ T016 ∥ T017; then T018 → T019
- **US3**: T020 ∥ T021; then T022
- **US4**: T023 then T024
- **Polish**: T025 ∥ T026

---

## Parallel Example: User Story 2

```bash
flutter test test/features/home/order_rating_sheet_test.dart
flutter test test/features/home/home_order_history_section_test.dart
flutter test test/core/network/mock_api_client_home_test.dart
# Then: order_rating_sheet.dart → home_order_history_section.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 + Phase 2
2. Phase 3 (US1)
3. **VALIDATE**: quickstart С1–С3, С7

### Incremental Delivery

1. Setup + Foundational → мок с TTL, без demo-seed
2. US1 → **MVP**
3. US2 → оценка + TTL errors
4. US3 → пропуск + TTL
5. US4 → уведомления
6. Polish → С9 manual, spec Implemented

---

## Notes

- TTL проверяется на **сервере**; клиент не скрывает кнопки по `deliveryAt` — только обрабатывает `rating_period_expired`
- `buildHomeOrderUiState` без изменений — `ratingState` server-driven
- При 409/404/`rating_period_expired` всегда `ref.invalidate(currentOrderProvider)`
- `order_rating_sheet_test.dart` уже существует — расширять

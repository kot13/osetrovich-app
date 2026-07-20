# Implementation Plan: Текущий заказ и оценка через Mobile API

**Branch**: `013-api-order-rating` | **Date**: 2026-07-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-api-order-rating/spec.md`

## Summary

Перевод блока «История заказов» и сценариев оценки с демонстрационных мок-данных на
боевой Mobile API (OpenAPI **v0.12.1**): `GET /orders/current`, `POST /orders/{orderId}/rating`,
`POST /orders/{orderId}/rating/skip`. Оценка и пропуск доступны **7 суток с даты доставки**
(`delivery_at`); после истечения — HTTP 400 `rating_period_expired`. UI и `DioApiClient` уже
реализованы в фиче 007; основная работа — убрать автосид демо-заказов в моке, обработка
ошибок оценки (включая истёкший срок), валидация комментария (500 символов), инвалидация
`currentOrderProvider` после checkout и тесты под контракт ERP.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio; существующий стек из фич 001–012

**Storage**: заказы на сервере (ERP); клиент — `FutureProvider<CurrentOrder?>` без локального
кэша; мок — in-memory `_ordersByUserId` только от `createOrder` (без demo phones); TTL
проверяется на сервере, клиент не вычисляет срок самостоятельно

**Testing**: flutter test (unit + widget); mock_api_client_home_test (включая
`rating_period_expired`); home_order_history_section_test; current_order_provider_test;
notification_detail rating flow

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: загрузка текущего заказа без заметной задержки на «Главной»; оценка/пропуск
≤ 5 с при стабильной сети (SC-003)

**Constraints**: UI на русском; `useMockApi = false` в рабочей сборке; JWT Bearer на всех
эндпоинтах orders; мок MUST соответствовать OpenAPI v0.12.1 (принцип VI); клиент не показывает
countdown TTL — сервер решает через `ratingState` и ошибки

**Scale/Scope**: ~11 затронутых Dart-файлов, 0 новых экранов, 3 эндпоинта orders (уже в
`DioApiClient`), удаление demo-seed, TTL в моке, error UX и тесты

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: изменения в `features/home/`, `features/cart/data/`, `core/network/`
- [x] **Русский UI**: `ratingPeriodExpired`, `ratingAlreadySet`, `ratingSubmitFailed` в `app_strings.dart`
- [x] **Тесты**: unit, widget, contract — включая `rating_period_expired` и истечение 7 суток в моке
- [x] **Flutter best practices**: логика видимости оценки в `buildHomeOrderUiState`; TTL на сервере
- [x] **Tab Bar**: без изменений; блок на вкладке «Главная»
- [x] **OpenAPI + моки**: v0.12.1 в `openapi/openapi.yaml`; мок синхронизирован, demo-seed удалён, TTL в rating/skip
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: без изменений UI-компонентов оценки
- [x] **JWT-авторизация**: `bearerAuth` на `/orders/current`, `/orders/{id}/rating`, `/orders/{id}/rating/skip`

*Повторная проверка после Phase 1 (с TTL v0.12.1): data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/013-api-order-rating/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # дельта orders: current + rating + TTL (v0.12.1)
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart                         # +ratingPeriodExpired, +ratingAlreadySet, +ratingSubmitFailed
│   └── network/
│       ├── api_client.dart                           # VERIFY getCurrentOrder, rating, skip
│       └── mock_api_client.dart                      # REMOVE demo seed; +TTL check (7d from deliveryAt)
└── features/
    ├── cart/
    │   ├── domain/order.dart                         # +deliveryAt? parse (optional, forward-compatible)
    │   ├── data/order_repository.dart                # VERIFY currentOrderProvider guard
    │   └── domain/checkout_notifier.dart             # +invalidate currentOrderProvider on success
    ├── home/
    │   ├── domain/home_order_ui_state.dart           # VERIFY (server-driven ratingState)
    │   └── presentation/
    │       ├── home_order_history_section.dart       # +ApiException snackbar; rating_period_expired
    │       └── order_rating_sheet.dart               # +maxLength: 500
    └── notifications/
        └── presentation/notification_detail_screen.dart  # +error handling incl. rating_period_expired

test/
├── core/network/mock_api_client_home_test.dart       # createOrder + TTL expired scenarios
├── features/cart/current_order_provider_test.dart
├── features/home/home_order_history_section_test.dart
├── features/home/home_order_ui_state_test.dart
└── features/home/order_rating_sheet_test.dart

openapi/openapi.yaml                                  # VERIFY v0.12.1 (TTL, rating_period_expired)
```

**Structure Decision**: расширяем существующие модули без новых каталогов. TTL не дублируется
в UI-логике — `buildHomeOrderUiState` опирается на `ratingState` с сервера; при попытке оценки
после истечения срока обрабатывается `rating_period_expired`.

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

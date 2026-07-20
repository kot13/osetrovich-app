# Implementation Plan: Оформление заказа через API

**Branch**: `012-api-order-create` | **Date**: 2026-07-20 | **Spec**: [spec.md](./spec.md)

**Status**: Implemented

**Input**: Feature specification from `/specs/012-api-order-create/spec.md`

## Summary

Синхронизация оформления заказа с обновлённым контрактом API (v0.11.2): целочисленный `id`
в позициях заказа (`OrderLineInput` / `OrderLine`), опциональные поля `apartment`, `lat`,
`lng` в запросе и ответе. В форме checkout — поле «Квартира / офис»; снятие фокуса с полей
ввода по тапу вне поля. OpenAPI уже обновлён в `openapi/openapi.yaml`; работа по цепочке
конституции: моки → доменные модели → checkout flow → UI → тесты. Координаты в UI не
собираются (per spec Assumptions).

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio; существующий стек из фич 001–011

**Storage**: корзина — in-memory `CartNotifier` (`Map<int, int>`); поля формы —
`TextEditingController` на `CartScreen`; `PendingCheckout` в Riverpod notifier

**Testing**: flutter test (unit + widget), integration_test; mocktail для `OrderRepository`

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: без деградации checkout UX; оформление ≤ 10 с (SC-005); мгновенное
снятие фокуса при тапе (SC-003)

**Constraints**: UI на русском; фирменная палитра; моки MUST соответствовать OpenAPI;
координаты не передаются без источника данных; наследуются правила доставки и авторизации
из `005-cart-checkout`

**Scale/Scope**: ~12 затронутых Dart-файлов, 0 новых экранов, 1 эндпоинт `POST /orders`
(расширение payload), обновление моков и 5+ тестовых файлов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: изменения в `features/cart/` и сетевом слое; кроссплатформенные виджеты
- [x] **Русский UI**: подпись поля квартиры в `app_strings.dart` («Квартира / офис»)
- [x] **Тесты**: unit (модели, checkout notifier, pending checkout), widget (форма, снятие фокуса), обновление `mock_api_client_orders_test` и `cart_screen_test`
- [x] **Flutter best practices**: маппинг JSON в domain; логика submit в `CheckoutNotifier`; UI только отображает форму
- [x] **Tab Bar**: без изменений корневой навигации; экран `/cart`
- [x] **OpenAPI + моки**: контракт v0.11.2 в `openapi/openapi.yaml`; фича обновляет `MockApiClient.createOrder` и доменные модели
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: новое поле через `OutlineInputBorder` / `ThemeData` как существующие поля формы
- [x] **JWT-авторизация**: `POST /orders` с `bearerAuth`; сценарий `from=checkout` без изменений

*Повторная проверка после Phase 1: data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/012-api-order-create/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # дельта схем orders (int id, apartment, lat/lng)
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart                    # +cartApartmentLabel, +cartApartmentHint
│   └── network/
│       └── mock_api_client.dart                 # createOrder: int id, apartment, lat/lng
└── features/
    └── cart/
        ├── domain/
        │   ├── order.dart                       # OrderLineInput.id (int), apartment, lat/lng
        │   ├── checkout_notifier.dart           # submit(+ apartment)
        │   └── pending_checkout_provider.dart   # +apartment
        └── presentation/
            ├── cart_screen.dart                 # apartment controller, resume/save, clear
            └── widgets/
                └── checkout_form.dart           # +apartment field; tap-to-unfocus wrapper

lib/features/home/domain/repeat_order.dart       # OrderLine.id (int) вместо productId string

test/features/cart/
    checkout_notifier_test.dart                  # UPDATE — int id, apartment
    cart_screen_test.dart                        # UPDATE — apartment field, unfocus
    pending_checkout_test.dart                   # NEW или UPDATE
test/core/network/
    mock_api_client_orders_test.dart             # UPDATE — int id, apartment
test/features/home/
    repeat_order_test.dart                       # UPDATE — int id в OrderLine

openapi/openapi.yaml                             # уже v0.11.2 (без merge, только верификация)
```

**Structure Decision**: расширяем существующий модуль `features/cart/` без новых каталогов.
Миграция `OrderLineInput.productId: String` → `id: int` согласована с `CartNotifier`
(`Map<int, int>`) и каталогом (фича 009). Снятие фокуса — обёртка `GestureDetector` вокруг
тела заполненной корзины (`_FilledCartBody`), не внутри отдельных `TextField`.

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

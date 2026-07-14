# Implementation Plan: Корзина и оформление заказа

**Branch**: `005-cart-checkout` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-cart-checkout/spec.md`

## Summary

Полноценный экран «Корзина» при непустом состоянии: список позиций с ±, итоги с расчётом
доставки (0 ₽ от 2000 ₽, иначе 300 ₽), поля адреса и комментария, блок условий оплаты/
доставки, кнопка «Оформить». Оформление — `POST /orders` с JWT; после успеха — сообщение,
очистка локальной корзины. Расширение OpenAPI v0.5.0; архитектура: `features/cart/` (data +
domain + presentation), переиспользование `CartNotifier`, `QuantityPriceBar`, `formatPriceRub`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, cached_network_image, mocktail,
integration_test; существующий стек из 001–004

**Storage**: корзина — in-memory `CartNotifier` (до фичи персистентной корзины); адрес и
комментарий — локальное состояние экрана (`CheckoutNotifier` / `TextEditingController`);
заказ — сервер через REST API (мок).

**Testing**: flutter test (unit + widget), integration_test; mocktail для OrderRepository

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: мгновенный пересчёт сумм на клиенте (SC-003); оформление ≤ 10 с
(SC-005); 60 fps при скролле списка позиций

**Constraints**: UI на русском; фирменная палитра; моки по OpenAPI; оформление только для
авторизованных (FR-008, FR-012); просмотр/редактирование корзины без входа

**Scale/Scope**: 1 основной экран (корзина/checkout), 4–5 новых виджетов, 1 API-эндпоинт,
расширение `CartNotifier`, integration-тест checkout flow

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база; ListView, TextField, AlertDialog — кроссплатформенно
- [x] **Русский UI**: новые строки в `lib/core/l10n/app_strings.dart` (адрес, комментарий, итоги, успех, ошибки)
- [x] **Тесты**: unit (delivery fee, order totals, checkout notifier), widget (cart screen states), integration (cart checkout flow)
- [x] **Flutter best practices**: `cart/data`, `cart/domain`, `cart/presentation`; расчёт доставки в domain, не в виджетах
- [x] **Tab Bar**: корневая навигация без изменений; экран корзины — вкладка `/cart`
- [x] **OpenAPI + моки**: v0.5.0 в `contracts/openapi.yaml` → merge в `openapi/openapi.yaml`; `MockApiClient.createOrder`
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: кнопка «Оформить» через `AppColors.accent`; тексты через `AppColors.dark`
- [x] **JWT-авторизация**: `POST /orders` с `bearerAuth`; 401 → предложение войти (`/auth/phone`)

*Повторная проверка после Phase 1: контракты, data-model и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/005-cart-checkout/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # v0.5.0 (+ orders)
└── tasks.md                    # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart              # +строки корзины, checkout, доставки
│   └── network/
│       ├── api_client.dart                # +createOrder
│       └── mock_api_client.dart           # +createOrder, валидация, мок-заказы
└── features/
    └── cart/
        ├── data/
        │   └── order_repository.dart      # NEW — POST /orders
        ├── domain/
        │   ├── cart_notifier.dart         # +clear()
        │   ├── order.dart                 # NEW — Order, CreateOrderRequest
        │   ├── delivery_fee.dart          # NEW — порог 2000, fee 300
        │   ├── cart_line_item_view.dart   # NEW — product + quantity + lineTotal
        │   ├── cart_lines_provider.dart   # NEW — resolve products for cart IDs
        │   ├── order_totals_provider.dart # NEW — subtotal, delivery, total
        │   └── checkout_notifier.dart     # NEW — submit, loading, errors
        └── presentation/
            ├── cart_screen.dart           # REPLACE — empty vs filled state
            └── widgets/
                ├── cart_line_tile.dart    # NEW — строка списка + QuantityPriceBar
                ├── cart_order_summary.dart # NEW — товары / доставка / итого
                ├── delivery_terms_card.dart # NEW — FR-005 текст
                └── checkout_form.dart     # NEW — адрес, комментарий, кнопка

test/features/cart/
    cart_notifier_test.dart                # +clear
    delivery_fee_test.dart                 # NEW
    order_totals_test.dart                 # NEW
    checkout_notifier_test.dart            # NEW
    cart_screen_test.dart                  # UPDATE — filled + empty states
    cart_line_tile_test.dart               # NEW (optional)

test/core/network/
    mock_api_client_orders_test.dart       # NEW

integration_test/
    cart_checkout_flow_test.dart           # NEW

openapi/openapi.yaml                       # merge v0.5.0
```

**Structure Decision**: расширяем `features/cart/` до полного feature-модуля (data/domain/
presentation). Состояние корзины остаётся в `CartNotifier`; обогащение позиций данными товара —
`cartLinesProvider` (async, через `CatalogRepository.getProductById`). Расчёт доставки —
чистая функция `calculateDeliveryFeeRub(subtotalRub)` в `delivery_fee.dart`. Оформление —
`CheckoutNotifier` вызывает `OrderRepository.createOrder`, при успехе `cartNotifier.clear()`.

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

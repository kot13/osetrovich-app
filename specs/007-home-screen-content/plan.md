# Implementation Plan: Наполнение главного экрана

**Branch**: `007-home-screen-content` | **Date**: 2026-07-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-home-screen-content/spec.md`

## Summary

Наполнение вкладки «Главная» контентом с сервера: баннеры с типизированными ссылками и
реальными изображениями, горизонтальная лента «Товары недели», блок «История заказов» с
текущим заказом (5 статусов), оценкой выполненного заказа (1–5 звёзд) и повтором заказа в
корзину. Расширение OpenAPI v0.7.0; архитектура: расширение `features/home/`, переиспользование
`ProductCard`, `CartNotifier`, `OrderRepository`; новые эндпоинты заказов в `features/cart/data/`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, cached_network_image, url_launcher,
mocktail, integration_test; существующий стек из 001–006

**Storage**: баннеры и товары недели — stateless fetch; текущий заказ — сервер (мок in-memory
`_ordersByUserId`); оценка — POST на сервер; корзина — `CartNotifier` (in-memory)

**Testing**: flutter test (unit + widget), integration_test; mocktail для home/order repositories

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: главная отображает баннеры ≤ 3 с (SC-001); бейдж корзины ≤ 1 с (SC-004);
повтор заказа ≤ 5 с (SC-006); 60 fps при горизонтальном скролле ленты

**Constraints**: UI на русском; фирменная палитра; моки по OpenAPI; блок заказа только для
авторизованных; независимая загрузка секций главной

**Scale/Scope**: 1 экран (расширение HomeScreen), 5–7 новых виджетов, 4 новых/изменённых
API-эндпоинта, расширение модели Banner и Order

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база; карусель, horizontal ListView, bottom sheet — кроссплатформенно
- [x] **Русский UI**: новые строки в `lib/core/l10n/app_strings.dart` (см. research.md §9)
- [x] **Тесты**: unit (banner link, order status, repeat order), widget (home sections), integration (home flow)
- [x] **Flutter best practices**: `home/data`, `home/domain`, `home/presentation`; навигация по ссылкам в `BannerLinkHandler`, не в виджете карусели
- [x] **Tab Bar**: без изменений корневой навигации; повтор заказа → `context.go('/cart')`
- [x] **OpenAPI + моки**: v0.7.0 в `contracts/openapi.yaml` → merge в `openapi/openapi.yaml`; моки для banners, weekly, current order, rating
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: секции через `AppColors`; CTA «Повторить заказ» / «Оценить» — accent
- [x] **JWT-авторизация**: `GET /orders/current`, rating/skip с `bearerAuth`; гостю блок заказа не показывается

*Повторная проверка после Phase 1: research, data-model и contracts согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/007-home-screen-content/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # v0.7.0 (+ home weekly, orders current/rating, Banner.link)
└── tasks.md                    # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart                    # +строки главной, заказа, оценки
│   └── network/
│       ├── api_client.dart                      # +getWeeklyProducts, getCurrentOrder,
│       │                                        #  submitOrderRating, skipOrderRating
│       └── mock_api_client.dart                 # +баннеры с imageUrl/link, weekly,
│                                                #  _ordersByUserId, rating
└── features/
    ├── home/
    │   ├── data/
    │   │   └── home_repository.dart             # +getWeeklyProducts
    │   ├── domain/
    │   │   ├── banner.dart                      # UPDATE — BannerLink
    │   │   ├── banner_link_handler.dart         # NEW — навигация по type
    │   │   ├── home_order_ui_state.dart         # NEW — showRating/Repeat flags
    │   │   └── repeat_order.dart                # NEW — repeatOrderToCart()
    │   └── presentation/
    │       ├── home_screen.dart                 # UPDATE — новые секции
    │       ├── banner_carousel.dart             # UPDATE — tap + real images
    │       ├── home_weekly_products_section.dart # NEW
    │       ├── home_order_history_section.dart  # NEW
    │       └── order_rating_sheet.dart          # NEW — bottom sheet 1–5 звёзд
    └── cart/
        ├── data/
        │   └── order_repository.dart            # UPDATE — current, rating, skip
        └── domain/
            └── order.dart                       # UPDATE — OrderStatus×5, CurrentOrder,
                                                 #  OrderRatingState

test/features/home/
    banner_link_handler_test.dart                # NEW
    home_order_ui_state_test.dart                # NEW
    repeat_order_test.dart                       # NEW
    banner_carousel_test.dart                    # NEW / UPDATE
    home_weekly_products_section_test.dart       # NEW
    home_order_history_section_test.dart         # NEW
    order_rating_sheet_test.dart                 # NEW

test/core/network/
    mock_api_client_home_test.dart               # NEW

integration_test/
    home_screen_flow_test.dart                   # NEW

openapi/openapi.yaml                             # merge v0.7.0
```

**Structure Decision**: основная логика главной остаётся в `features/home/`; заказы и оценка —
в `features/cart/` (существующий `OrderRepository`). `ProductCard` из каталога переиспользуется
в `HomeWeeklyProductsSection` с фиксированной шириной. Повтор заказа — чистая функция в
`home/domain/repeat_order.dart`, вызывающая `CartNotifier` и `CatalogRepository`.

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

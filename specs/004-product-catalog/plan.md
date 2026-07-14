# Implementation Plan: Каталог товаров

**Branch**: `004-product-catalog` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-product-catalog/spec.md`

## Summary

Сетка товаров во вкладке «Каталог» (2 колонки на телефоне, infinite scroll по 20 позиций),
карточка с быстрым добавлением в корзину, страница товара с галереей и floating-панелью
количества, реактивный бейдж на вкладке «Корзина» (число уникальных SKU). Расширение
OpenAPI v0.4.0 эндпоинтами `/catalog/products`; корзина — **локальный** `CartNotifier`
(Riverpod) без серверного API в этой фиче. Архитектура: расширение `features/catalog/` +
новая `features/cart/domain/` для состояния корзины + правки `MainShell`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, **cached_network_image**
(фото товаров по URL из мока), mocktail, integration_test; существующий стек из 001–003

**Storage**: корзина — in-memory `CartNotifier` (Map\<productId, quantity\>); при
перезапуске приложения корзина сбрасывается (до фичи персистентной корзины). Каталог —
read-only через API/мок.

**Testing**: flutter test (unit + widget), integration_test; mocktail для CatalogRepository

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: первая страница товаров ≤ 3 с (SC-001); подгрузка следующих 20 без
«пустого хвоста» при нормальной сети (SC-002); мгновенное обновление UI корзины (SC-003);
60 fps при скролле сетки

**Constraints**: UI на русском; фирменная палитра (`#FFB400` для CTA-кнопок цены);
моки по OpenAPI; каталог и корзина без обязательной авторизации (FR-014)

**Scale/Scope**: ~2 экрана (сетка каталога, деталь товара), 3–4 новых виджета, 2 API-
эндпоинта каталога, локальная модель корзины, бейдж Tab Bar; ~60+ мок-товаров для
демонстрации пагинации

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база; GridView, PageView, BottomNavigationBar badge — кроссплатформенно
- [x] **Русский UI**: новые строки в `lib/core/l10n/app_strings.dart` (ошибки, пустые состояния, формат цены)
- [x] **Тесты**: unit (cart notifier, pagination, price format), widget (product card, catalog grid, product detail), integration (catalog flow)
- [x] **Flutter best practices**: `catalog/` data/domain/presentation; `cart/domain/` для корзины; Notifier без логики в виджетах
- [x] **Tab Bar**: корневая навигация без изменений; деталь товара — вложенный маршрут `/catalog/product/:id`
- [x] **OpenAPI + моки**: v0.4.0 в `contracts/openapi.yaml` → merge в `openapi/openapi.yaml`; `MockApiClient` с ≥60 товарами
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: кнопки цены/CTA через `AppColors.accent`
- [x] **JWT-авторизация**: эндпоинты каталога **без** bearerAuth (публичный каталог); JWT не затрагивается

*Повторная проверка после Phase 1: контракты, data-model и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/004-product-catalog/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # v0.4.0 (+ products)
└── tasks.md                    # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart              # +строки каталога, корзины, цены
│   ├── network/
│   │   ├── api_client.dart                # +getProducts, getProductById
│   │   └── mock_api_client.dart           # +~60 ProductSummary, детали
│   ├── router/app_router.dart             # +/catalog/product/:id
│   ├── theme/app_colors.dart              # без изменений (reuse)
│   └── utils/price_formatter.dart         # NEW — «300 ₽»
└── features/
    ├── catalog/
    │   ├── data/catalog_repository.dart   # NEW — products API
    │   ├── domain/
    │   │   ├── catalog_category.dart      # существует
    │   │   ├── categories_provider.dart   # существует
    │   │   ├── product.dart               # NEW — ProductSummary, ProductDetail
    │   │   └── products_notifier.dart     # NEW — пагинация + category filter
    │   └── presentation/
    │       ├── catalog_screen.dart        # REPLACE empty state → grid
    │       ├── product_detail_screen.dart # NEW
    │       ├── category_chips.dart        # существует
    │       └── widgets/
    │           ├── product_card.dart      # NEW — grid card + quantity overlay
    │           ├── product_grid.dart      # NEW — 2-col GridView + scroll listener
    │           ├── quantity_price_bar.dart # NEW — shared − price + / − qty × price +
    │           └── product_image_gallery.dart # NEW — PageView
    ├── cart/
    │   ├── domain/
    │   │   ├── cart_line_item.dart        # NEW
    │   │   └── cart_notifier.dart         # NEW — add/increment/decrement/remove
    │   └── presentation/
    │       └── cart_screen.dart           # без изменений (пустое состояние)
    └── shell/
        └── presentation/main_shell.dart   # ConsumerWidget + cart badge

test/features/catalog/                       # +product_card, products_notifier, grid
test/features/cart/                          # +cart_notifier
integration_test/catalog_flow_test.dart      # NEW

openapi/openapi.yaml                         # merge v0.4.0
pubspec.yaml                                 # +cached_network_image
```

**Structure Decision**: расширяем `features/catalog/`; состояние корзины выносим в
`features/cart/domain/` (единый источник правды для карточек, детали и Tab Bar). Пагинация
— `ProductsNotifier` (Notifier/AsyncNotifier) с накоплением `items` и флагами `hasMore` /
`isLoadingMore`. `MainShell` становится `ConsumerWidget` и подписывается на
`cartDistinctCountProvider` (аналог `unreadCountProvider` на «Главной»).

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

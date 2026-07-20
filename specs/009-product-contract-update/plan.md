# Implementation Plan: Обновление каталога по контракту

**Branch**: `009-product-contract-update` | **Date**: 2026-07-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-product-contract-update/spec.md`

## Summary

Синхронизация клиента с обновлённым контрактом каталога: **целочисленные** `id` категорий и
товаров, поля `sale` / `special` в моделях товара, промо-бейджи **«Акция»** и **«СПЕЦЦЕНА»**
на карточках в сетке каталога и в блоке «Товары недели». OpenAPI в `openapi/openapi.yaml`
уже содержит изменения; работа — моки → доменные модели → корзина/роутинг → UI бейджей →
тесты. Детальный экран товара без бейджей (по spec Assumptions).

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, cached_network_image; существующий
стек из фич 001–008

**Storage**: корзина — in-memory `CartNotifier` (`Map<int, int>` после миграции); JWT и
профиль без изменений

**Testing**: flutter test (unit + widget), integration_test; mocktail для репозиториев

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: без деградации скролла сетки (60 fps); парсинг JSON и смена типа id
не влияют на UX заметно

**Constraints**: UI на русском; бейджи через `AppColors`; моки MUST соответствовать OpenAPI;
`categoryId=all` в query остаётся строкой; `productId` в заказах (`OrderLine`) остаётся
`string` в контракте — конвертация при повторном заказе

**Scale/Scope**: ~15 затронутых Dart-файлов, 1 новый виджет бейджей, обновление моков и
7+ тестовых файлов; без новых API-эндпоинтов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: изменения в domain/presentation; кроссплатформенные виджеты
- [x] **Русский UI**: тексты бейджей «Акция», «СПЕЦЦЕНА» в `app_strings.dart`
- [x] **Тесты**: unit (модели, cart notifier, фильтр категорий), widget (product_card с бейджами), обновление integration catalog flow
- [x] **Flutter best practices**: бейджи — отдельный виджет; логика отображения по флагам в presentation, не в сетевом слое
- [x] **Tab Bar**: без изменений корневой навигации
- [x] **OpenAPI + моки**: контракт в `openapi/openapi.yaml` актуален; фича обновляет `MockApiClient` и клиентский парсинг
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: бейджи через `AppColors` (accent для «Акция», primary для «СПЕЦЦЕНА»)
- [x] **JWT-авторизация**: не затрагивается (каталог публичный)

*Повторная проверка после Phase 1: data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/009-product-contract-update/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # дельта схем каталога (int id, sale, special)
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart                    # +badgeSale, +badgeSpecialPrice
│   ├── network/
│   │   ├── api_client.dart                      # getProductById(int), query categoryId
│   │   └── mock_api_client.dart                 # int ids, sale/special в товарах
│   └── router/app_router.dart                   # int.parse path :id
└── features/
    ├── catalog/
    │   ├── domain/
    │   │   ├── catalog_category.dart            # id: int
    │   │   ├── product.dart                     # int id, categoryIds, sale, special, oldPriceRub
    │   │   └── products_notifier.dart           # selectedCategoryId: int (0 = все)
    │   ├── data/catalog_repository.dart
    │   └── presentation/
    │       ├── category_chips.dart              # int selectedId
    │       ├── product_detail_screen.dart       # productId: int
    │       └── widgets/
    │           ├── product_card.dart            # +ProductPromoBadges overlay
    │           └── product_promo_badges.dart    # NEW
    ├── cart/
    │   └── domain/
    │       ├── cart_notifier.dart               # Map<int, int>
    │       └── cart_line_item_view.dart         # productId: int
    └── home/
        └── domain/repeat_order.dart             # int.parse(order line productId)

test/features/catalog/                             # обновить фикстуры и ожидания
test/features/cart/cart_notifier_test.dart
test/core/network/mock_api_client_products_test.dart
integration_test/catalog_flow_test.dart

openapi/openapi.yaml                               # уже обновлён (reference)
```

**Structure Decision**: feature-first; изменения сосредоточены в `catalog/`, `cart/domain/`,
`core/network/` и общем виджете бейджей. Отдельный пакет не требуется.

## Complexity Tracking

> Нарушений конституции нет — таблица пуста.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

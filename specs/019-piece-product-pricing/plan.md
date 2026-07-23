# Implementation Plan: Штучный товар, цена за кг и старая цена

**Branch**: `019-piece-product-pricing` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/019-piece-product-pricing/spec.md`

## Summary

Клиент каталога синхронизируется с обновлённым контрактом: поля **`pieceProduct`** и
**`pricePerKgRub`** в моделях товара, **отображение зачёркнутой старой цены** на кнопке
«добавить» (`QuantityPriceBar` при `quantity == 0` и `oldPriceRub > priceRub`), **цена за
кг** на карточке в списке и на странице товара при `pricePerKgRub > 0`. OpenAPI в
`openapi/openapi.yaml` уже обновлён; работа: моки → доменные модели → утилиты форматирования
→ `QuantityPriceBar` / `ProductCard` / `ProductDetailScreen` → тесты.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, cached_network_image; существующий
стек фич 001–018

**Storage**: корзина — in-memory `CartNotifier` (`Map<int, int>`); JWT без изменений

**Testing**: flutter test (unit + widget), integration_test; mocktail для репозиториев

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: без деградации скролла сетки (60 fps); `FittedBox` на compact-кнопке
при двух ценах не вызывает заметных лагов

**Constraints**: UI на русском; цвета через `AppColors`; моки MUST соответствовать OpenAPI;
старая цена только на кнопке добавления, не в панели количества; корзина и заказы вне scope

**Scale/Scope**: ~10 затронутых Dart-файлов, 1 новый тестовый файл, обновление моков и 4+
тестовых файлов; без новых API-эндпоинтов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: изменения в core/utils и catalog/presentation; кроссплатформенные виджеты
- [x] **Русский UI**: суффикс «/кг», формат ₽ через существующий `formatPriceRub`
- [x] **Тесты**: unit (правило старой цены, fromJson, formatPricePerKgRub), widget (QuantityPriceBar, ProductCard, ProductDetailScreen)
- [x] **Flutter best practices**: правило `shouldShowStrikethroughOldPrice` в утилите; виджеты только рендерят по флагам
- [x] **Tab Bar**: без изменений корневой навигации
- [x] **OpenAPI + моки**: контракт в `openapi/openapi.yaml` актуален; фича обновляет `MockApiClient` и парсинг моделей
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: зачёркнутая цена — `AppColors.dark` с opacity; кнопка — `AppColors.accent`
- [x] **JWT-авторизация**: не затрагивается (каталог публичный)

*Повторная проверка после Phase 1: research.md, data-model.md, contracts и quickstart согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/019-piece-product-pricing/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi-delta.yaml
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── utils/
│   │   ├── price_formatter.dart               # +formatPricePerKgRub
│   │   └── product_price_display.dart         # NEW: shouldShowStrikethroughOldPrice
│   └── network/
│       └── mock_api_client.dart               # +pricePerKgRub, pieceProduct; матрица моков
└── features/
    └── catalog/
        ├── domain/
        │   └── product.dart                   # +pricePerKgRub, pieceProduct в Summary/Detail
        └── presentation/
            ├── product_detail_screen.dart     # цена/кг, oldPriceRub → QuantityPriceBar
            └── widgets/
                ├── product_card.dart          # цена/кг, oldPriceRub, высота текстового блока
                └── quantity_price_bar.dart    # зачёркнутая старая цена на кнопке

test/
├── core/utils/product_price_display_test.dart # NEW
├── features/catalog/
│   ├── product_model_test.dart                # новые поля fromJson
│   ├── product_card_test.dart                 # старая цена, цена/кг
│   ├── product_detail_screen_test.dart        # старая цена, цена/кг
│   └── quantity_price_bar_test.dart           # NEW
└── core/network/mock_api_client_products_test.dart

openapi/openapi.yaml                           # reference (уже обновлён)
```

**Structure Decision**: feature-first; изменения сосредоточены в `catalog/` и
`core/utils/`; `ProductCard` на главной («Товары недели») получает поведение автоматически
через общий виджет.

## Complexity Tracking

> Нарушений конституции нет — таблица пуста.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Phase 0: Research

См. [research.md](./research.md) — все технические решения зафиксированы, NEEDS CLARIFICATION
отсутствуют.

## Phase 1: Design

| Артефакт | Путь | Содержание |
|----------|------|------------|
| Модель данных | [data-model.md](./data-model.md) | Поля, правила UI, layout карточки и детали |
| Контракт | [contracts/openapi-delta.yaml](./contracts/openapi-delta.yaml) | Дельта ProductSummary/Detail |
| Quickstart | [quickstart.md](./quickstart.md) | Ручные и автоматические сценарии проверки |

## Implementation Notes (для tasks.md)

1. **Порядок**: `product.dart` + моки → утилиты → `QuantityPriceBar` → `ProductCard` →
   `ProductDetailScreen` → тесты.
2. **QuantityPriceBar**: обернуть содержимое кнопки в `FittedBox` (compact) при двух ценах,
   чтобы edge case длинных сумм не обрезал «+».
3. **Обратная совместимость**: поля required в OpenAPI — все фикстуры тестов обновить
   одновременно с моделями.
4. **pieceProduct**: только парсинг; тест `fromJson` с `true`/`false`.

# Implementation Plan: Акции и новости

**Branch**: `006-promotions-news` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-promotions-news/spec.md`

## Summary

Наполнение вкладки «Акции»: Filter Chips «Все» / «Акции» / «Новости» (по умолчанию «Все»),
одноколоночная лента карточек (фото, метка типа, заголовок, дата) и детальная страница с
безопасным HTML-текстом и эмодзи. Расширение
OpenAPI v0.6.0 эндпоинтами `/promotions/articles` (публичные, без JWT). Архитектура:
расширение `features/promotions/` (data/domain/presentation), маршрут
`/promotions/article/:id` внутри ветки Tab Bar, рендеринг тела — `flutter_html` с whitelist
тегов.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, cached_network_image,
**flutter_html** (безопасный HTML), url_launcher (ссылки в тексте), mocktail,
integration_test; существующий стек из 001–005

**Storage**: read-only контент через API/мок; локальное состояние — выбранный тип чипа и
позиция прокрутки ленты (в памяти виджета / indexedStack ветки)

**Testing**: flutter test (unit + widget), integration_test; mocktail для PromotionsRepository

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: смена фильтра и отображение ленты ≤ 2 с (SC-001); плавный скролл
одноколоночного списка (60 fps); детальная страница без блокировки UI при рендере HTML

**Constraints**: UI на русском; фирменная палитра; моки по OpenAPI; публичный доступ без
авторизации (FR-015); без пагинации (полный список из API); whitelist HTML-тегов (FR-011–012)

**Scale/Scope**: 2 экрана (лента, деталь), 3–4 новых виджета, 2 API-эндпоинта, ~10–15
мок-материалов; замена EmptyState на `PromotionsScreen`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: ListView, FilterChip, Html — кроссплатформенно
- [x] **Русский UI**: строки в `app_strings.dart` (типы «Акция»/«Новость», ошибки, retry)
- [x] **Тесты**: unit (notifier, date format, html whitelist), widget (chips, card, detail),
  integration (promotions flow)
- [x] **Flutter best practices**: `promotions/` data/domain/presentation; Notifier без логики в виджетах
- [x] **Tab Bar**: корневая навигация без изменений; деталь — `/promotions/article/:id` внутри ветки
- [x] **OpenAPI + моки**: v0.6.0 в `contracts/openapi.yaml` → merge в `openapi/openapi.yaml`;
  `MockApiClient` с мок-материалами обоих типов
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: чипы через `AppColors.accent` (как каталог); метка типа — accent/primary
- [x] **JWT-авторизация**: эндпоинты promotions **без** bearerAuth (публичный контент); JWT не затрагивается

*Повторная проверка после Phase 1: контракты, data-model и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/006-promotions-news/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # v0.6.0 (+ promotions/articles)
└── tasks.md                    # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart              # +типы, ошибки ленты/детали
│   ├── network/
│   │   ├── api_client.dart                # +getPromotionArticles, getPromotionArticleById
│   │   └── mock_api_client.dart           # +мок-акции и новости с HTML
│   ├── router/app_router.dart             # +/promotions/article/:id
│   └── utils/date_formatter.dart          # NEW — formatPublishedDate → «14 июля 2026»
└── features/
    └── promotions/
        ├── data/promotions_repository.dart    # NEW
        ├── domain/
        │   ├── promotion_article.dart       # NEW — summary + detail
        │   ├── promotion_type.dart          # NEW — promotion | news
        │   ├── selected_type_provider.dart  # NEW — активный Filter Chip
        │   └── promotions_notifier.dart     # NEW — загрузка ленты по типу
        └── presentation/
            ├── promotions_screen.dart       # REPLACE empty state → chips + list
            ├── promotion_detail_screen.dart # NEW
            └── widgets/
                ├── promotion_type_chips.dart    # NEW
                ├── promotion_article_card.dart  # NEW
                └── promotion_html_body.dart     # NEW — flutter_html + whitelist

test/features/promotions/                    # +notifier, chips, card, detail, html
integration_test/promotions_flow_test.dart   # NEW

openapi/openapi.yaml                         # merge v0.6.0
pubspec.yaml                                 # +flutter_html
```

**Structure Decision**: расширяем существующий модуль `features/promotions/` по слоям
data/domain/presentation (как catalog, notifications). Filter Chips — отдельный виджет по
образцу `CategoryChips`. `PromotionsNotifier` подписан на `selectedPromotionTypeProvider`;
смена типа перезагружает список. Деталь загружается отдельным запросом
`GET /promotions/articles/{id}` (поле `bodyHtml`). `PromotionsScreen` — `ConsumerStatefulWidget`
с `ScrollController` для сохранения позиции при `context.pop()` с детали (FR-014).

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

# Implementation Plan: Признак «Товар недели» и диплинки

**Branch**: `016-week-product-deeplinks` | **Date**: 2026-07-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/016-week-product-deeplinks/spec.md`

## Summary

Две связанные, но независимые части:

1. **productOfWeek** — синхронизация клиента с уже обновлённым OpenAPI: поле в доменных
   моделях, моках, бейдж **«Товар недели»** на `ProductCard` (каталог + лента на главной).
   Детальный экран товара без бейджей (как в фиче 009).

2. **Диплинки `osetrovich://`** — единый резолвер URL → маршрут go_router; регистрация
   схемы на Android/iOS; обработка из трёх источников: HTML статей, push (URL приоритетнее
   JSON), внешние intent (пакет `app_links`). Маршрут категории через побочный эффект
   `selectedCategoryIdProvider` при переходе на `/catalog`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, flutter_html, appmetrica_push_plugin;
**новая**: `app_links` ^6.x (входящие custom URL scheme)

**Storage**: без изменений (корзина in-memory, JWT в secure storage)

**Testing**: flutter test (unit + widget), integration_test; mocktail для репозиториев

**Target Platform**: Android 8+ / iOS 15+

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: резолв диплинка < 50 ms; навигация без заметной задержки; 60 fps
скролла сетки с дополнительным бейджем

**Constraints**: UI на русском; бейджи через `AppColors`; моки MUST соответствовать OpenAPI;
сохранить JSON push-deeplink (008); Universal Links вне scope; только схема `osetrovich://`

**Scale/Scope**: ~20 затронутых Dart-файлов, 2–3 новых модуля в `core/deeplink/`, обновление
нативных манифестов, 3 контракта, 10+ тестовых файлов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: `app_links` + нативная регистрация схемы на Android/iOS;
  логика резолва в `core/deeplink/` — единая для обеих платформ
- [x] **Русский UI**: бейдж «Товар недели» в `app_strings.dart`; сообщения об ошибках —
  существующие штатные
- [x] **Тесты**: unit (`DeepLinkResolver`, `PushDeeplinkHandler` расширение), widget
  (`ProductPromoBadges`, `PromotionHtmlBody`), integration (deeplink cold start)
- [x] **Flutter best practices**: резолвер и навигация в `core/`; виджеты только отображают;
  категория через Riverpod notifier
- [x] **Tab Bar**: диплинки ведут на существующие вкладки shell; корневая навигация не меняется
- [x] **OpenAPI + моки**: `productOfWeek` уже в `openapi/openapi.yaml`; фича обновляет моки
  и парсинг; контракт диплинков в `contracts/deeplink-schema.yaml`
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: бейдж «Товар недели» — `AppColors.dark` + `AppColors.accent`
  (см. research.md §2)
- [x] **JWT-авторизация**: не затрагивается; уведомления — существующее поведение для гостя

*Повторная проверка после Phase 1: data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/016-week-product-deeplinks/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── deeplink-schema.yaml      # схема osetrovich:// → маршрут
│   ├── push-deeplink-v2.yaml     # расширение push: URL + legacy JSON
│   └── openapi-delta.yaml        # дельта productOfWeek (reference)
└── tasks.md                      # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── deeplink/
│   │   ├── deeplink_resolver.dart           # NEW: osetrovich:// → DeepLinkTarget
│   │   ├── deeplink_navigation.dart         # NEW: navigate + category side-effect
│   │   └── deeplink_providers.dart          # NEW: Riverpod
│   ├── l10n/app_strings.dart                # +badgeProductOfWeek
│   ├── network/
│   │   └── mock_api_client.dart             # productOfWeek в товарах
│   ├── push/
│   │   └── push_deeplink_handler.dart       # URL priority + legacy JSON
│   └── router/app_router.dart               # опционально route catalog/category/:id
└── features/
    ├── catalog/
    │   ├── domain/product.dart                # +productOfWeek
    │   └── presentation/widgets/
    │       ├── product_promo_badges.dart      # +productOfWeek badge
    │       └── product_card.dart              # pass productOfWeek
    └── promotions/presentation/widgets/
        └── promotion_html_body.dart           # intercept osetrovich://

android/app/src/main/AndroidManifest.xml      # intent-filter VIEW + scheme osetrovich
ios/Runner/Info.plist                           # CFBundleURLTypes

test/core/deeplink/deeplink_resolver_test.dart
test/core/push/push_deeplink_handler_test.dart  # + URL cases
test/features/catalog/product_promo_badges_test.dart
test/features/promotions/promotion_html_body_test.dart

pubspec.yaml                                    # +app_links

openapi/openapi.yaml                            # уже содержит productOfWeek (reference)
```

**Structure Decision**: feature-first; новая подсистема диплинков в `core/deeplink/`; бейджи
расширяют существующий `ProductPromoBadges` из фичи 009; push handler расширяется, не
заменяется.

## Complexity Tracking

> Нарушений конституции нет — таблица пуста.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

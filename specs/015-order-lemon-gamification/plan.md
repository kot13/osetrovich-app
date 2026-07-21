# Implementation Plan: Геймификация «Делай заказы — получай призы»

**Branch**: `015-order-lemon-gamification` | **Date**: 2026-07-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/015-order-lemon-gamification/spec.md`

## Summary

Добавляем акцию лимонов: счётчик `lemons` (0–10) и опциональный `lemonGift` в
`GET /profile/me`; блок прогресса на «Главной»; подарочная строка в корзине при 10 лимонах;
начисление и сброс на сервере при `POST /orders`. OpenAPI v0.12.5; моки с демо-номерами
по телефону; после checkout — `profileNotifier.refresh()`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, mocktail, integration_test;
существующий стек 001–014 (`profileNotifierProvider`, `HomeScreen`, `CartScreen`,
`MockApiClient`, `CheckoutNotifier`)

**Storage**: счётчик лимонов — сервер (`UserProfile.lemons`); in-memory в `MockApiClient`;
локальная корзина без изменений (`cartNotifierProvider`)

**Testing**: flutter test (unit + widget), integration_test; mocktail для home/cart/profile

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: блок лимонов виден вместе с профилем ≤ 3 с (как loyalty SC-002);
обновление шкалы после заказа — один refresh профиля без перезапуска приложения

**Constraints**: UI на русском; жёлтые лимоны — `AppColors.accent`; серые — `#BDBDBD`;
подарок read-only в корзине; только авторизованные видят блок

**Scale/Scope**: расширение `UserProfile`, 2 новых home-виджета, 1 cart provider, правки
`CartLineTile` / `CheckoutNotifier`, merge OpenAPI v0.12.5

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база; виджеты Material
- [x] **Русский UI**: строки в `app_strings.dart` (см. research.md §9)
- [x] **Тесты**: unit (ui model, gift rules, mock lemons), widget (card, cart gift tile),
  integration (home + checkout с подарком)
- [x] **Flutter best practices**: domain-модели и провайдеры; виджеты без бизнес-логики
- [x] **Tab Bar**: без изменений корневой навигации
- [x] **OpenAPI + моки**: v0.12.5 в `contracts/openapi.yaml` → merge в `openapi/openapi.yaml`;
  `MockApiClient` — lemons, lemonGift, createOrder side effects
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: жёлтый лимон — `AppColors.accent`; карточка — `AppColors` /
  `ThemeData`; серый для пустых лимонов — функциональный (см. Complexity Tracking)
- [x] **JWT-авторизация**: `GET /profile/me` и `POST /orders` с `bearerAuth`; блок скрыт
  для гостей

*Повторная проверка после Phase 1: research, data-model и contracts согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/015-order-lemon-gamification/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # v0.12.5 — lemons, lemonGift, OrderLine.isGift
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart                           # +homeLemonGamification*, cartGiftLabel
│   └── network/
│       ├── mock_api_client.dart                        # UPDATE — lemons, gift, createOrder
│       └── api_client.dart                             # без изменений сигнатур
└── features/
    ├── profile/
    │   └── domain/
    │       ├── user_profile.dart                       # UPDATE — lemons, lemonGift
    │       └── lemon_gift_preview.dart                 # NEW
    ├── home/
    │   ├── domain/
    │   │   └── home_lemon_gamification_ui_model.dart   # NEW
    │   └── presentation/
    │       ├── home_screen.dart                        # UPDATE — LemonGamificationCard
    │       ├── home_lemon_gamification_card.dart       # NEW
    │       └── lemon_progress_icon.dart                # NEW
    └── cart/
        ├── domain/
        │   ├── cart_line_item_view.dart                # UPDATE — isGift, fromLemonGift
        │   ├── cart_display_lines_provider.dart        # NEW
        │   └── checkout_notifier.dart                  # UPDATE — profile refresh
        └── presentation/
            ├── cart_screen.dart                        # UPDATE — cartDisplayLinesProvider
            └── widgets/
                └── cart_line_tile.dart                 # UPDATE — gift variant

test/features/home/
    home_lemon_gamification_ui_model_test.dart          # NEW
    home_lemon_gamification_card_test.dart              # NEW
    home_screen_test.dart                               # UPDATE

test/features/cart/
    cart_gift_line_test.dart                            # NEW
    cart_line_tile_test.dart                            # UPDATE

test/core/network/
    mock_api_client_test.dart                           # UPDATE — lemons / gift order

integration_test/
    home_screen_flow_test.dart                          # UPDATE — lemon block scenarios

openapi/openapi.yaml                                    # merge v0.12.5
```

**Structure Decision**: feature-first; поля геймификации в `profile/domain`; UI главной —
`home/presentation`; логика подарка в корзине — `cart/domain` (провайдер display lines).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Серый `#BDBDBD` для незаполненных лимонов | Spec требует «10 серых лимонов»; не брендовый акцент | `AppColors.background` слишком светлый на карточке; accent для пустых шагов вводит в заблуждение |

## Phase 0 / Phase 1 Artifacts

| Артефакт | Путь | Статус |
|----------|------|--------|
| Research | [research.md](./research.md) | ✅ |
| Data model | [data-model.md](./data-model.md) | ✅ |
| Contracts | [contracts/openapi.yaml](./contracts/openapi.yaml) | ✅ v0.12.5 |
| Quickstart | [quickstart.md](./quickstart.md) | ✅ |

## Implementation Notes (для /speckit-tasks)

1. **OpenAPI → моки → модель**: merge v0.12.5; затем `UserProfile`, `OrderLine`, мок.
2. **HomeScreen**: показывать `HomeLemonGamificationCard` только при `isAuthenticated &&
   profileAsync.hasValue && !profileAsync.hasError`.
3. **Cart**: переключить список строк на `cartDisplayLinesProvider`; итоги заказа не
   учитывают цену подарка (0 ₽).
4. **Checkout**: после успеха — `profileNotifier.refresh()`; подарок не в `cartNotifier`.
5. **createOrder (mock)**: при `lemons == 10` append gift `OrderLine` с `isGift: true`,
   затем `lemons = 1`; иначе `lemons = min(lemons + 1, 10)` — фактически +1 до 10.
6. **Демо-телефоны**: `+79004444444` (0), `+79005555555` (7), `+79006666666` (10 + gift).

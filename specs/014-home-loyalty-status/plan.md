# Implementation Plan: Блок статуса лояльности на главной

**Branch**: `014-home-loyalty-status` | **Date**: 2026-07-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/014-home-loyalty-status/spec.md`

## Summary

На вкладке «Главная» заменяем кнопку «Связаться» на «Авторизоваться» для гостей и
показываем информационный блок программы лояльности для авторизованных покупателей со
статусом. Данные (`loyaltyStatus`, `discount`, `card`) приходят в `GET /profile/me`;
клиент расширяет `UserProfile`, подключает `profileNotifierProvider` на `HomeScreen` и
добавляет виджеты `HomeProfileSlot`, `HomeAuthButton`, `HomeLoyaltyStatusCard`. OpenAPI
v0.12.4; моки с демо-статусами по телефону.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, mocktail, integration_test;
существующий стек из 001–013 (`profileNotifierProvider`, `HomeScreen`, `MockApiClient`)

**Storage**: профиль — fetch через `ProfileRepository`; in-memory мок `_profile` в
`MockApiClient`; локальная сессия JWT без изменений

**Testing**: flutter test (unit + widget), integration_test; mocktail для home/profile

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: блок лояльности виден ≤ 3 с после открытия главной (SC-002); смена
UI при logout ≤ 1 с (SC-005); без дополнительного HTTP-запроса сверх профиля

**Constraints**: UI на русском; фирменная палитра; моки по OpenAPI; блок только при
`loyaltyStatus != null`; скидка 0 скрывает строку скидки, не весь блок

**Scale/Scope**: 1 экран (расширение `HomeScreen`), 3–4 новых виджета, расширение модели
`UserProfile`, без новых API-эндпоинтов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база; новые виджеты — стандартный Material
- [x] **Русский UI**: новые строки в `lib/core/l10n/app_strings.dart` (см. research.md §9)
- [x] **Тесты**: unit (маппинг статусов, правила слота), widget (auth button, loyalty card,
  home screen), integration (guest / loyalty / no status)
- [x] **Flutter best practices**: domain-функции `buildHomeProfileSlotUiState`,
  `loyaltyStatusLabel`; виджеты без бизнес-логики
- [x] **Tab Bar**: без изменений корневой навигации; auth → `context.push('/auth/phone')`
- [x] **OpenAPI + моки**: v0.12.4 в `contracts/openapi.yaml` → merge в `openapi/openapi.yaml`;
  `MockApiClient.ensureProfile` с loyalty-полями
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: карточки через `AppColors`; CTA «Авторизоваться» — primary/accent
  по паттерну существующих home-кнопок
- [x] **JWT-авторизация**: `GET /profile/me` с `bearerAuth`; гостю показывается auth CTA,
  профиль не запрашивается

*Повторная проверка после Phase 1: research, data-model и contracts согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/014-home-loyalty-status/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # v0.12.4 — UserProfile + LoyaltyStatus
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── l10n/app_strings.dart                    # +homeAuthButton, homeLoyaltyDiscount, homeLoyaltyCard
│   └── network/
│       ├── api_client.dart                      # UserProfile.fromJson — loyalty fields (via model)
│       └── mock_api_client.dart                 # UPDATE ensureProfile — loyalty по телефону
└── features/
    ├── profile/
    │   └── domain/
    │       ├── user_profile.dart                # UPDATE — loyaltyStatus, discount, card
    │       ├── loyalty_status.dart              # NEW — enum + fromJson
    │       └── loyalty_status_label.dart        # NEW — loyaltyStatusLabel()
    └── home/
        ├── domain/
        │   ├── home_profile_slot_ui_state.dart  # NEW — mode + builder
        │   └── home_loyalty_status_ui_model.dart # NEW — card view model
        └── presentation/
            ├── home_screen.dart                 # UPDATE — profile slot, refresh profile, убрать contact/auth banner
            ├── home_profile_slot.dart           # NEW
            ├── home_auth_button.dart            # NEW
            ├── home_loyalty_status_card.dart    # NEW
            ├── home_contact_button.dart         # REMOVE usage (delete if unused)
            └── auth_prompt_banner.dart          # без изменений файла; убрать с HomeScreen

test/features/profile/
    loyalty_status_label_test.dart               # NEW

test/features/home/
    home_profile_slot_ui_state_test.dart         # NEW
    home_auth_button_test.dart                   # NEW
    home_loyalty_status_card_test.dart           # NEW
    home_screen_test.dart                        # UPDATE
    contact_block_test.dart                      # без изменений (профиль)

test/core/network/
    mock_api_client_test.dart                    # UPDATE — loyalty в профиле

integration_test/
    home_screen_flow_test.dart                   # UPDATE — loyalty сценарии

openapi/openapi.yaml                             # merge v0.12.4 (если ещё не в main)
```

**Structure Decision**: feature-first; лояльность как часть домена `profile/`, UI-слот и
карточка — в `home/presentation`; правила видимости — `home/domain`.

## Complexity Tracking

> Нарушений конституции нет; таблица не заполняется.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Phase 0 / Phase 1 Artifacts

| Артефакт | Путь | Статус |
|----------|------|--------|
| Research | [research.md](./research.md) | ✅ |
| Data model | [data-model.md](./data-model.md) | ✅ |
| Contracts | [contracts/openapi.yaml](./contracts/openapi.yaml) | ✅ v0.12.4 |
| Quickstart | [quickstart.md](./quickstart.md) | ✅ |

## Implementation Notes (для /speckit-tasks)

1. **OpenAPI → моки → модель**: синхронизировать `UserProfile` и `MockApiClient` до UI.
2. **HomeScreen**: `ref.watch(profileNotifierProvider)` только при `isAuthenticated`;
   в `_refreshHome` — `profileNotifier.refresh()`.
3. **Logout**: `profileNotifier.clear()` уже вызывается из профиля; главная реагирует через
   `isAuthenticatedProvider` + cleared profile.
4. **Удалить** `HomeContactButton` с главной; проверить grep — удалить файл, если orphaned.
5. **Тесты profile_notifier / profile_repository** — обновить константы `UserProfile` с
   полем `discount: 0` по умолчанию.

# Implementation Plan: Инициализация приложения

**Branch**: `001-init-app-shell` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-init-app-shell/spec.md`

## Summary

Создание каркаса мобильного приложения osetrovich.ru на Flutter: нижний Tab Bar с пятью
разделами, пустые состояния, SMS-авторизация с JWT, главная с уведомлениями и баннерами,
каталог с Filter Chips, нативный сплэш и отображаемое имя «Осетрович». API описывается в
OpenAPI; на этапе разработки используются моки. Архитектура feature-first с разделением
presentation / domain / data и управлением состоянием через Riverpod.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, flutter_secure_storage,
mask_text_input_formatter (или аналог), mocktail, integration_test, flutter_native_splash

**Storage**: flutter_secure_storage (JWT access/refresh); in-memory + Riverpod для сессии и
кэша категорий на время сессии

**Testing**: flutter test (unit + widget), integration_test, mocktail для моков репозиториев

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: переключение вкладок без заметной задержки; категории на экране «Каталог»
≤ 3 с после холодного старта; 60 fps при скролле и свайпе баннеров

**Constraints**: UI только на русском; фирменная палитра; JWT в secure storage; моки по OpenAPI

**Scale/Scope**: 5 вкладок, 2 экрана авторизации, 12 категорий, ~15 экранов/состояний в scope

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база Flutter для Android и iOS
- [x] **Русский UI**: все строки в `lib/core/l10n/` или константах на русском
- [x] **Тесты**: unit (auth timer, validators), widget (экраны, tab bar), integration (навигация, auth flow)
- [x] **Flutter best practices**: feature-first, Riverpod, слои presentation/domain/data
- [x] **Tab Bar**: `StatefulShellRoute` в go_router, 5 веток навигации
- [x] **OpenAPI + моки**: `openapi/openapi.yaml` + `lib/core/network/mock_api_client.dart`
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: `lib/core/theme/app_colors.dart` + `ThemeData`
- [x] **JWT-авторизация**: Bearer interceptor, secure storage, эндпоинты в OpenAPI

*Повторная проверка после Phase 1: все пункты соблюдены; контракты и data-model согласованы.*

## Project Structure

### Documentation (this feature)

```text
specs/001-init-app-shell/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── auth_interceptor.dart
│   │   └── mock_api_client.dart
│   ├── l10n/
│   │   └── app_strings.dart
│   └── widgets/
│       ├── empty_state.dart
│       └── loading_indicator.dart
└── features/
    ├── shell/
    │   └── presentation/main_shell.dart
    ├── home/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── catalog/
    ├── promotions/
    ├── cart/
    ├── profile/
    └── auth/
        ├── data/
        ├── domain/
        └── presentation/
            ├── phone_input_screen.dart
            └── sms_code_screen.dart

test/
├── core/
└── features/
    ├── auth/
    ├── catalog/
    └── shell/
integration_test/
├── app_navigation_test.dart
└── auth_flow_test.dart

openapi/
└── openapi.yaml
```

**Structure Decision**: feature-first под `lib/features/`; общая инфраструктура в `lib/core/`.
Каждая фича содержит `data` (DTO, репозитории), `domain` (модели, use cases), `presentation`
(экраны, провайдеры). Tab Bar реализован через `go_router` `StatefulShellRoute` для
сохранения состояния вкладок (FR-002, US1 AC3).

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

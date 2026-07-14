# Implementation Plan: Профиль пользователя

**Branch**: `003-user-profile` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-user-profile/spec.md`

## Summary

Полноценный экран «Профиль» для авторизованного пользователя: имя, email (с верификацией
кодом), смена телефона (СМС-код), локальный PIN и биометрия, переключатель push,
«Связаться», оферта, соцсети VK/OK, выход. Расширение OpenAPI эндпоинтами `/profile/*`;
моки с мутабельным профилем. Переиспользование паттернов auth-flow (СМС, таймер 60 с);
новые зависимости: `local_auth`, `permission_handler`. Архитектура: feature `profile/` +
Riverpod + go_router (вложенные маршруты в ветке `/profile`).

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, flutter_secure_storage,
url_launcher (оферта, соцсети), **local_auth** (биометрия), **permission_handler**
(разрешение push), mocktail, integration_test; существующий стек из 001/002

**Storage**: JWT в `flutter_secure_storage`; PIN-hash и флаг биометрии — secure storage;
push-предпочтение — сервер + локальный кэш; профиль — in-memory мок с мутациями

**Testing**: flutter test (unit + widget), integration_test; mocktail для ProfileRepository

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: профиль отображается ≤ 2 с (SC-001); выход ≤ 2 с (SC-007);
экраны верификации без заметной задержки

**Constraints**: UI на русском; фирменная палитра; моки по OpenAPI; PIN только локально;
биометрия — системный API; push без FCM в мок-фазе (только preference + permission ОС)

**Scale/Scope**: ~1 главный экран + 5–6 вложенных (смена телефона, email, PIN);
8 новых API-эндпоинтов профиля; рефакторинг переиспользуемых виджетов верификации

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база; `local_auth` и `permission_handler` — кроссплатформенные
- [x] **Русский UI**: новые строки в `lib/core/l10n/app_strings.dart`
- [x] **Тесты**: unit (repository, validators, PIN), widget (profile, verification flows), integration (profile flow)
- [x] **Flutter best practices**: feature `profile/` data/domain/presentation; Notifier для состояния
- [x] **Tab Bar**: профиль остаётся вкладкой; смена телефона/email — вложенные маршруты `/profile/*`
- [x] **OpenAPI + моки**: расширение `openapi/openapi.yaml` + `MockApiClient` с мутациями профиля
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: формы и кнопки через AppColors / ThemeData
- [x] **JWT-авторизация**: `/profile/*` с `bearerAuth`; logout через `/auth/logout`; PIN не заменяет JWT

*Повторная проверка после Phase 1: контракты, data-model и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/003-user-profile/
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
├── core/
│   ├── l10n/app_strings.dart              # +строки профиля, PIN, push, оферта
│   ├── network/
│   │   ├── api_client.dart                # +методы profile
│   │   └── mock_api_client.dart           # +мутабельный UserProfile
│   ├── router/app_router.dart             # вложенные /profile/change-phone, /profile/email, …
│   └── widgets/
│       ├── contact_block.dart             # MOVE из home (общий виджет)
│       └── verification_code_field.dart   # NEW — 6-значный ввод (reuse auth)
└── features/
    ├── profile/
    │   ├── data/profile_repository.dart
    │   ├── domain/
    │   │   ├── user_profile.dart
    │   │   ├── profile_notifier.dart
    │   │   ├── local_auth_service.dart    # PIN hash + local_auth
    │   │   └── push_preferences_service.dart
    │   └── presentation/
    │       ├── profile_screen.dart        # REPLACE placeholder
    │       ├── change_phone_screen.dart
    │       ├── change_phone_code_screen.dart
    │       ├── email_verify_screen.dart
    │       ├── email_code_screen.dart
    │       ├── pin_setup_screen.dart
    │       ├── pin_change_screen.dart
    │       ├── app_lock_screen.dart       # разблокировка при resume (US4)
    │       └── widgets/
    │           ├── profile_field_tile.dart
    │           ├── social_links_row.dart
    │           └── legal_support_section.dart
    ├── auth/                              # без изменений API; logout reuse
    └── home/
        └── presentation/home_screen.dart  # import ContactBlock из core/widgets

test/features/profile/                     # NEW
integration_test/profile_flow_test.dart    # NEW

openapi/openapi.yaml                       # v0.3.0 + profile tag
pubspec.yaml                               # +local_auth, permission_handler
```

**Structure Decision**: расширяем существующую feature `profile/`; `ContactBlock` выносится
в `core/widgets` для переиспользования на «Главной» и в «Профиле». Верификационные экраны
смены телефона/email — отдельные маршруты с `parentNavigatorKey` (как `/auth/*`), чтобы
Tab Bar оставался контекстом вкладки. PIN и биометрия — `LocalAuthService` в domain слое
profile (локальное хранилище, не OpenAPI).

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

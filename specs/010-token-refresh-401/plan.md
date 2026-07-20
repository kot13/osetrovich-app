# Implementation Plan: Автоматическое обновление токена при 401

**Branch**: `010-token-refresh-401` | **Date**: 2026-07-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-token-refresh-401/spec.md`

## Summary

При ответе сервера **401** на защищённый запрос приложение автоматически обновляет пару
JWT-токенов через `POST /auth/refresh`, повторяет исходный запрос и сохраняет новую сессию.
При отказе refresh — **принудительный выход** (`clearSession`). Параллельные 401
координируются одним refresh на «волну». Технические сообщения (`DioException[bad response]`)
заменяются русскоязычными формулировками через улучшенный маппинг `ApiException` и правки
экранов, показывающих `error.toString()`.

Центральное изменение — **Dio-интерцептор** в `lib/core/network/` + колбэки в
`createDio` для синхронизации с `AuthSessionNotifier`. OpenAPI уже описывает `/auth/refresh`;
изменения контракта не требуются — только клиент и моки для тестовых сценариев.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod ^2.6, dio ^5.8, go_router; существующий стек auth
(`AuthSessionNotifier`, `SecureTokenStorage`, `AuthRepository`)

**Storage**: JWT в `flutter_secure_storage` через `SecureTokenStorage`; состояние сессии в
`authSessionProvider` (Riverpod)

**Testing**: flutter test — unit (интерцептор, маппер ошибок, auth session refresh),
widget (profile/cart error states); `dio` `MockAdapter` для симуляции 401/refresh

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: прозрачный refresh без заметной задержки для пользователя (< 1 с при
нормальной сети); один refresh на пачку параллельных 401

**Constraints**: UI на русском; токены только в secure storage; refresh MUST NOT зацикливаться
на `/auth/refresh`; сетевой сбой при refresh не разлогинивает (spec Assumptions); `useMockApi`
обходит Dio — тесты интерцептора через отдельный Dio + adapter

**Scale/Scope**: ~8–10 Dart-файлов (1–2 новых, остальные правки), 4+ тестовых файла;
без новых API-эндпоинтов; затронуты все защищённые запросы через `DioApiClient`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: логика в `core/network` и `auth/domain` — кроссплатформенно
- [x] **Русский UI**: сообщения об ошибках через `AppStrings` / `ApiException.message` на русском
- [x] **Тесты**: unit (интерцептор, маппер, session refresh/logout), widget (ошибки без DioException)
- [x] **Flutter best practices**: refresh в сетевом слое; UI только отображает `ApiException`
- [x] **Tab Bar**: без изменений корневой навигации
- [x] **OpenAPI + моки**: `/auth/refresh` уже в `openapi/openapi.yaml`; моки дополняются
  сценариями 401/refresh для тестов (см. research §6)
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: UI-правки только в error states; палитра без изменений
- [x] **JWT-авторизация**: прямая реализация принципа IX — refresh при истечении access,
  secure storage, тесты сценариев сессии

*Повторная проверка после Phase 1: data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/010-token-refresh-401/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # дельта auth refresh (ссылка на корневой контракт)
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart                         # +sessionExpired, +networkError (при необходимости)
│   └── network/
│       ├── api_client.dart                           # улучшить _mapError (Dio → ApiException)
│       ├── api_error_mapper.dart                     # NEW — русские сообщения по коду/статусу
│       ├── auth_interceptor.dart                     # без изменений или merge в refresh
│       ├── token_refresh_interceptor.dart            # NEW — 401 → refresh → retry / logout
│       ├── dio_client.dart                           # wire interceptors + callbacks
│       └── providers.dart                            # передать колбэки сессии в createDio
└── features/
    ├── auth/
    │   └── domain/auth_session_provider.dart         # +refreshFromStorage / +applyTokens / logout hook
    └── profile/
        └── presentation/profile_screen.dart          # error.toString() → user-friendly message

test/
├── core/network/
│   ├── token_refresh_interceptor_test.dart           # NEW — 401, retry, dedupe, logout
│   └── api_error_mapper_test.dart                    # NEW
└── features/auth/
    └── auth_session_refresh_test.dart                # NEW — сохранение токенов после refresh

openapi/openapi.yaml                                  # без изменений (reference)
```

**Structure Decision**: feature-first; основная логика в `core/network` (инфраструктура),
интеграция сессии — в `auth/domain`. Отдельный пакет не требуется.

## Complexity Tracking

> Нарушений конституции нет — таблица пуста.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

# Implementation Plan: Mobile API 0.10.0 — push-токены и реальные уведомления

**Branch**: `011-mobile-api-010-notifications` | **Date**: 2026-07-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-mobile-api-010-notifications/spec.md`

## Summary

Переход клиента на **Mobile API 0.10.0**: добавить `PUT /profile/push-token` (регистрация FCM
после входа, onTokenRefresh и включения push), убрать stub-уведомления (`n1`–`n4`), подключить
**реальный** поток list / unread-count / read / read-all, синхронизировать бейдж с сервером,
обработать foreground/background push и CTA оценки для «Заказ доставлен». OpenAPI в корне
обновляется до `0.10.0`; моки и `ApiClient` дополняются `registerPushToken`.

Центральные изменения: `PushTokenRegistrationService` + bootstrap в `core/push`,
`unreadCountNotifierProvider` вместо локального подсчёта, обновление `MockApiClient` и
`notifications`-слоя, доработка `NotificationDetailScreen` и push navigation fallback.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod ^2.6, dio ^5.8, go_router, appmetrica_push_plugin,
permission_handler; существующие auth (010), profile, notifications (002), push (008)

**Storage**: JWT — `flutter_secure_storage`; метка миграции кэша уведомлений —
`shared_preferences` (`notifications_cache_version`); last registered push token — prefs или
in-memory

**Testing**: flutter test — unit (`PushTokenRegistrationService`, `NotificationAction`),
widget (notifications list/detail, home badge, delivered CTA), mock API notifications

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: регистрация push-токена < 10 с после входа (SC-001); обновление бейджа
< 3 с после mark read (SC-003); foreground push feedback < 5 с (SC-005)

**Constraints**: UI на русском; канал push/SMS не выбирается на клиенте; push payload с бэкенда
без `id` — tap всегда на список уведомлений; AppMetrica deeplink JSON сохраняется для
маркетинговых рассылок (008)

**Scale/Scope**: ~12–15 Dart-файлов (3–5 новых, остальные правки), OpenAPI delta, 6+ тестовых
файлов; без новых экранов — расширение существующих notifications/profile/push

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: push registration и notifications — общий Dart-код; platform
  только в значении `platform: ios|android`
- [x] **Русский UI**: SnackBar, CTA, ошибки через `AppStrings`
- [x] **Тесты**: unit + widget для registration, unread count, detail CTA, 404; см. research §12
- [x] **Flutter best practices**: логика в domain/data/core; виджеты — presentation only
- [x] **Tab Bar**: без изменений корневой навигации; push → `/home/notifications`
- [x] **OpenAPI + моки**: 0.10.0 + `PushTokenRequest`; моки с реалистичными ID и текстами
- [x] **Русские спеки**: артефакты фичи на русском
- [x] **Фирменная палитра**: SnackBar/CTA через ThemeData и `AppColors`
- [x] **JWT-авторизация**: push-token и notifications — Bearer; 401 через фичу 010

*Повторная проверка после Phase 1: data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/011-mobile-api-010-notifications/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── openapi.yaml          # дельта 0.10.0 (push-token + notifications)
└── tasks.md                  # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
openapi/openapi.yaml                                  # version 0.10.0, +/profile/push-token

lib/
├── core/
│   ├── l10n/app_strings.dart                         # +строки push/notification CTA
│   ├── network/
│   │   ├── api_client.dart                           # +registerPushToken
│   │   └── mock_api_client.dart                      # stub IDs → реальные; +registerPushToken
│   └── push/
│       ├── push_service.dart                         # +getCurrentToken() (опционально)
│       ├── appmetrica_push_service.dart              # foreground stream hook
│       ├── push_token_registration_service.dart      # NEW
│       ├── push_registration_bootstrap.dart          # NEW — session + token listeners
│       ├── push_navigation_setup.dart                # fallback → /home/notifications
│       └── push_deeplink_handler.dart                # пустой payload → notifications list
└── features/
    ├── auth/domain/auth_session_provider.dart        # hook invalidate notifications on login
    ├── notifications/
    │   ├── domain/
    │   │   ├── notifications_notifier.dart           # auth-aware reload; 404 handling
    │   │   ├── unread_count_notifier.dart            # NEW — API unread-count
    │   │   └── notification_action.dart              # NEW — rateOrder by title
    │   └── presentation/
    │       ├── notification_detail_screen.dart       # multiline body, CTA оценки
    │       └── notifications_list_screen.dart      # preview multiline
    ├── profile/domain/push_preferences_service.dart  # +register after enable
    └── home/presentation/home_screen.dart            # unreadCountNotifierProvider

test/
├── core/push/push_token_registration_service_test.dart   # NEW
├── core/network/mock_api_client_notifications_test.dart  # NEW или расширение
└── features/notifications/                             # обновить + новые кейсы
```

**Structure Decision**: feature-first; инфраструктура push-token в `core/push`, домен
уведомлений в `features/notifications`, интеграция с профилем через существующий
`PushPreferencesService`.

## Complexity Tracking

> Нарушений конституции нет — таблица пуста.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Phase 0 & Phase 1 Artifacts

| Артефакт | Путь | Статус |
|----------|------|--------|
| Research | [research.md](./research.md) | ✅ |
| Data model | [data-model.md](./data-model.md) | ✅ |
| Contracts | [contracts/openapi.yaml](./contracts/openapi.yaml) | ✅ |
| Quickstart | [quickstart.md](./quickstart.md) | ✅ |

### Ключевые технические решения (из research)

1. **PushTokenRegistrationService** — триггеры: login, tokenStream, pushEnabled=true.
2. **unreadCountNotifierProvider** — `GET /notifications/unread-count` вместо filter по списку.
3. **MockApiClient** — убрать `n1`–`n4`, добавить тексты API 0.10.0.
4. **Push tap** — backend push (title/body only) → `/home/notifications`; JSON deeplink 008 сохранён.
5. **«Заказ доставлен»** — CTA + `OrderRatingSheet` через `GET /orders/current`.
6. **Миграция** — `notifications_cache_version = 2` при первом запуске после обновления.

### Следующий шаг

`/speckit-tasks` — разбить реализацию на зависимые задачи с тестами.

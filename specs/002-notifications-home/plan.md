# Implementation Plan: Уведомления и доработки главной

**Branch**: `002-notifications-home` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-notifications-home/spec.md`

## Summary

Реализация in-app раздела «Уведомления» (список, детали, FAB «Отметить все прочитанным»,
реактивный счётчик на колокольчике), доработки «Главной» (бесконечная карусель из 3 баннеров
с peek соседних и автопрокруткой каждые 5 с, отступ от шапки, блок «Связаться» с звонком)
и переименование вкладки «Акции». Расширение OpenAPI
новыми эндпоинтами уведомлений; моки с мутабельным состоянием прочитанности. Архитектура
сохраняет feature-first + Riverpod + go_router.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod, go_router, dio, url_launcher (возврат для блока
«Связаться»), mocktail, integration_test; существующий стек из 001-init-app-shell

**Storage**: in-memory состояние уведомлений в моке (мутации read/mark-all); JWT без изменений

**Testing**: flutter test (unit + widget), integration_test; mocktail для NotificationsRepository

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: переход на экран уведомлений без заметной задержки; обновление badge
≤ 1 с после mark-read (SC-002); 60 fps при свайпе карусели

**Constraints**: UI на русском; фирменная палитра; моки по OpenAPI; push-уведомления вне scope

**Scale/Scope**: +2 экрана (список, деталь), +1 виджет «Связаться», правки карусели и Tab Bar;
4 новых API-эндпоинта уведомлений

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единая кодовая база Flutter для Android и iOS
- [x] **Русский UI**: новые строки в `lib/core/l10n/app_strings.dart`
- [x] **Тесты**: unit (repository, unread count), widget (список, деталь, home), integration (notifications flow)
- [x] **Flutter best practices**: feature `notifications/` с data/domain/presentation; логика в Notifier
- [x] **Tab Bar**: корневая навигация без изменений; уведомления — вложенные маршруты в ветке `/home`
- [x] **OpenAPI + моки**: расширение `openapi/openapi.yaml` + `MockApiClient` с мутациями
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: индикация read/unread через AppColors (primary/accent/background)
- [x] **JWT-авторизация**: эндпоинты уведомлений с `bearerAuth` (как unread-count)

*Повторная проверка после Phase 1: все пункты соблюдены; контракты и data-model согласованы.*

## Project Structure

### Documentation (this feature)

```text
specs/002-notifications-home/
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
│   ├── l10n/app_strings.dart          # +строки уведомлений, «Акции», «Связаться»
│   ├── network/
│   │   ├── api_client.dart            # +методы notifications
│   │   └── mock_api_client.dart       # +мутабельный список уведомлений
│   └── router/app_router.dart         # вложенные /home/notifications, /home/notifications/:id
└── features/
    ├── notifications/                 # NEW
    │   ├── data/notifications_repository.dart
    │   ├── domain/
    │   │   ├── app_notification.dart
    │   │   └── notifications_notifier.dart
    │   └── presentation/
    │       ├── notifications_list_screen.dart
    │       └── notification_detail_screen.dart
    ├── home/
    │   └── presentation/
    │       ├── home_screen.dart       # bell → push, contact block, top padding
    │       ├── banner_carousel.dart   # infinite loop
    │       └── contact_block.dart     # NEW
    ├── promotions/                    # заголовок «Акции»
    └── shell/main_shell.dart          # tab label «Акции»

test/features/notifications/           # NEW
integration_test/notifications_flow_test.dart  # NEW

openapi/openapi.yaml                   # расширение контракта
```

**Structure Decision**: новая фича `lib/features/notifications/`; счётчик на «Главной»
подписывается на общий `notificationsNotifierProvider` (derived `unreadCount`), а не на
отдельный `FutureProvider` unread-count — единый источник правды после мутаций.

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

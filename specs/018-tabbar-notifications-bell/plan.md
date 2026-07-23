# Implementation Plan: Колокольчик уведомлений на всех вкладках Tab Bar

**Branch**: `018-tabbar-notifications-bell` | **Date**: 2026-07-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/018-tabbar-notifications-bell/spec.md`

## Summary

Расширить точки входа в раздел «Уведомления»: вынести колокольчик с бейджем непрочитанных
из `HomeScreen` в переиспользуемый виджет `NotificationBellAction` и добавить его в шапки
всех пяти корневых экранов Tab Bar. Для сохранения контекста вкладки (FR-005, FR-006)
зарегистрировать вложенные маршруты `notifications` / `notifications/:id` в каждой ветке
`StatefulShellRoute` и навигационный хелпер `openNotificationsList`. REST API и экраны
уведомлений не меняются; диплинки остаются на `/home/notifications`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod ^2.6, go_router; существующие модули notifications
(002/011), shell (001)

**Storage**: без изменений (счётчик — API `GET /v1/notifications/unread-count`)

**Testing**: flutter test — widget (`NotificationBellAction`, корневые экраны вкладок),
router/shell (навигация с не-home вкладки); регрессия `home_screen_test.dart`

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: tap → список уведомлений без заметной задержки (SC-002); обновление
бейджа ≤ 1 с после mark-read (SC-003)

**Constraints**: UI на русском; визуальный паритет с текущим колокольчиком «Главной»;
OpenAPI REST без изменений; диплинки/push на `/home/notifications` без регрессий

**Scale/Scope**: ~6–8 Dart-файлов (1–2 новых, остальные правки), 1 навигационный контракт,
6+ тестовых файлов; без новых экранов и API-эндпоинтов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: единый виджет и маршруты для Android и iOS
- [x] **Русский UI**: новых пользовательских строк не требуется; существующие `AppStrings`
- [x] **Тесты**: widget + router тесты для колокольчика и навигации с каждой вкладки (research §8)
- [x] **Flutter best practices**: виджет в `features/notifications/presentation/`; навигация в хелпере
- [x] **Tab Bar**: shell без изменений состава вкладок; уведомления — вложенные маршруты в каждой ветке
- [x] **OpenAPI + моки**: REST без изменений; моки notifications уже есть
- [x] **Русские спеки**: артефакты фичи на русском
- [x] **Фирменная палитра**: бейдж через `AppColors` при рефакторинге (визуал как на «Главной»)
- [x] **JWT-авторизация**: без изменений; unread-count — существующий защищённый эндпоинт

*Повторная проверка после Phase 1: data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/018-tabbar-notifications-bell/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── tab-notifications-routes.yaml
└── tasks.md                      # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── router/
│       └── app_router.dart                           # +notifications routes в 4 ветках
└── features/
    ├── notifications/
    │   └── presentation/
    │       ├── widgets/
    │       │   └── notification_bell_action.dart     # NEW: колокольчик + бейдж
    │       └── notification_navigation.dart          # NEW: openNotificationsList()
    ├── home/presentation/home_screen.dart            # REFACTOR: NotificationBellAction
    ├── catalog/presentation/catalog_screen.dart      # +actions
    ├── promotions/presentation/promotions_screen.dart
    ├── cart/presentation/cart_screen.dart
    └── profile/presentation/profile_screen.dart      # +actions (guest + auth)

test/
├── features/notifications/
│   └── notification_bell_action_test.dart            # NEW
├── features/catalog/catalog_screen_test.dart         # NEW or extend
├── features/promotions/promotions_screen_test.dart   # NEW or extend
├── features/cart/cart_screen_test.dart               # NEW or extend
├── features/profile/profile_screen_test.dart         # extend
├── features/shell/main_shell_test.dart               # +notifications nav from cart
└── features/home/home_screen_test.dart               # regression
```

**Structure Decision**: feature-first; UI колокольчика в модуле `notifications/`; маршруты —
в `core/router/app_router.dart` (единая точка конфигурации go_router).

## Complexity Tracking

> Нет отклонений от конституции. Дублирование вложенных маршрутов `notifications` в пяти
> ветках shell обосновано требованием FR-006 (сохранение активной вкладки); альтернатива
> с единым `/home/notifications` отклонена в [research.md](./research.md) §2.

## Phase 0: Research

**Статус**: ✅ Завершено — [research.md](./research.md)

Ключевые решения:
1. Виджет `NotificationBellAction` + хелпер `openNotificationsList`
2. Вложенные маршруты уведомлений в каждой ветке shell
3. Диплинки/push без изменений (`/home/notifications`)
4. Переиспользование `unreadCountProvider`

## Phase 1: Design & Contracts

**Статус**: ✅ Завершено

| Артефакт | Путь | Описание |
|----------|------|----------|
| Data model | [data-model.md](./data-model.md) | UI-состояние колокольчика, табличная модель маршрутов |
| Navigation contract | [contracts/tab-notifications-routes.yaml](./contracts/tab-notifications-routes.yaml) | Маршруты по вкладкам, правила pop и tab_bar_active |
| Quickstart | [quickstart.md](./quickstart.md) | Ручные и автоматические сценарии проверки |

## Phase 2: Tasks

Выполняется командой `/speckit-tasks` → `tasks.md`.

Ожидаемые группы задач:
1. **Routing** — дублирование `notifications` routes в catalog/promotions/cart/profile ветках
2. **Widget** — `NotificationBellAction`, `openNotificationsList`
3. **Screens** — подключение actions на 5 корневых экранах
4. **Tests** — widget + router + regression

## Dependencies

| Фича | Зависимость |
|------|-------------|
| 001-init-app-shell | Tab Bar, `MainShell`, `app_router` |
| 002-notifications-home | экраны уведомлений, колокольчик на «Главной» |
| 011-mobile-api-010-notifications | `unreadCountProvider`, реальные данные |
| 016/017 | диплинки на `/home/notifications` — без изменений |

## Risks & Mitigations

| Риск | Митигация |
|------|-----------|
| Дублирование route-конфигурации в router | вынести фабрику `notificationRoutes()` в приватную функцию в `app_router.dart` |
| Рассинхрон бейджа между вкладками | один `unreadCountProvider` на все экземпляры виджета |
| Профиль: два Scaffold | добавить `actions` в оба AppBar (research §6) |

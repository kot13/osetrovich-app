# Implementation Plan: Push в foreground и диплинки уведомлений

**Branch**: `017-push-foreground-deeplinks` | **Date**: 2026-07-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/017-push-foreground-deeplinks/spec.md`

## Summary

Доработка клиентской обработки **order push** от бэкенда (FCM `notification` + `data`):

1. **Foreground** — подписка на входящие FCM-сообщения (`onMessage`), обновление
   `unreadCountNotifierProvider` и списка уведомлений с сервера; опциональный in-app баннер
   (MaterialBanner / SnackBar) с `title`/`body` и навигацией по `data`.
2. **Tap на push** (фон / cold start) — разбор `data.deeplink` и `data.notification_id`,
   переход на `/home/notifications/{id}`; без парсинга `notification.body`.
3. **404** — единое сообщение «Уведомление не найдено» на экране детали.

Центральные изменения: `PushIncomingMessage` + `FcmForegroundPushService`, рефакторинг
`PushForegroundHandler`, расширение `PushDeeplinkHandler` для поля `notification_id`,
контракт FCM в `contracts/fcm-order-push.yaml`. OpenAPI REST **не меняется**.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel

**Primary Dependencies**: flutter_riverpod ^2.6, go_router, dio, appmetrica_push_plugin ^2.4.0
(без апгрейда до 3.x — см. research §1); **новые**: `firebase_core`, `firebase_messaging`;
существующие: deeplink (016), notifications (002/011), push registration (011)

**Storage**: без изменений (JWT — secure storage; last push token — prefs/in-memory)

**Testing**: flutter test — unit (`PushDeeplinkHandler`, `PushIncomingMessageMapper`,
`PushForegroundHandler`), widget (in-app banner tap, 404 detail), integration (опционально
deeplink из push payload)

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: обновление бейджа < 5 с после foreground push (SC-001); навигация по tap
< 3 с (SC-002)

**Constraints**: UI на русском; REST API без изменений; AppMetrica остаётся транспортом
токена и обработчиком tap; `firebase_messaging` — только foreground receive + унификация
payload; не парсить `notification.body` для маршрутизации

**Scale/Scope**: ~8–12 Dart-файлов (2–4 новых, остальные правки), 2 контракта, 5+ тестовых
файлов; без новых экранов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: foreground listener через `firebase_messaging` (Android/iOS);
  tap — AppMetrica `pushClickStream` + `getLaunchPushInfo`; общая Dart-логика парсинга payload
- [x] **Русский UI**: «Уведомление не найдено», баннер с серверным title/body, `AppStrings`
- [x] **Тесты**: unit mapper/handler/deeplink; widget banner + 404; см. research §8
- [x] **Flutter best practices**: парсинг и маршрутизация в `core/push/`; виджеты — presentation
- [x] **Tab Bar**: push ведёт на `/home/notifications/{id}` внутри shell; корневая навигация не меняется
- [x] **OpenAPI + моки**: REST без изменений; FCM-контракт в `contracts/`; моки notifications уже есть
- [x] **Русские спеки**: артефакты фичи на русском
- [x] **Фирменная палитра**: in-app баннер через ThemeData / `AppColors`
- [x] **JWT-авторизация**: деталь уведомления — существующие защищённые эндпоинты

*Повторная проверка после Phase 1: data-model, contracts и research согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/017-push-foreground-deeplinks/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── fcm-order-push.yaml       # структура FCM message от бэкенда
│   └── push-deeplink-v3.yaml     # расширение v2: notification_id + order push
└── tasks.md                      # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── l10n/app_strings.dart                         # +notificationNotFound; уточнить баннер
│   └── push/
│       ├── push_incoming_message.dart                # NEW: нормализованная модель push
│       ├── push_incoming_mapper.dart                 # NEW: FCM data / JSON → PushIncomingMessage
│       ├── fcm_foreground_push_service.dart          # NEW: FirebaseMessaging.onMessage
│       ├── push_foreground_handler.dart              # REFACTOR: receive stream + banner tap
│       ├── push_deeplink_handler.dart                # +notification_id fallback
│       ├── push_navigation_setup.dart                # payload из AppMetrica tap (без изменений логики)
│       └── push_providers.dart                       # wire FCM + foreground handler
└── features/
    └── notifications/
        └── presentation/
            └── notification_detail_screen.dart       # «Уведомление не найдено» + GET by id (опц.)

test/
├── core/push/
│   ├── push_incoming_mapper_test.dart                # NEW
│   ├── push_deeplink_handler_test.dart               # +notification_id cases
│   └── push_foreground_handler_test.dart             # +banner tap, payload
└── features/notifications/
    └── notification_detail_screen_test.dart          # 404 copy

pubspec.yaml                                          # +firebase_core, firebase_messaging
```

**Structure Decision**: инфраструктура push в `core/push/`; UI баннера — через
`ScaffoldMessenger` / `MaterialBanner` в `PushForegroundHandler` (без отдельного feature-модуля).

## Complexity Tracking

> Нет отклонений от конституции. Добавление `firebase_messaging` рядом с AppMetrica
> обосновано в [research.md](./research.md) §2 — плагин AppMetrica 2.4.0 не экспонирует
> stream получения push в foreground.

## Phase 0 / Phase 1 Artifacts

| Артефакт | Путь | Статус |
|----------|------|--------|
| Research | [research.md](./research.md) | ✅ |
| Data model | [data-model.md](./data-model.md) | ✅ |
| FCM contract | [contracts/fcm-order-push.yaml](./contracts/fcm-order-push.yaml) | ✅ |
| Push deeplink v3 | [contracts/push-deeplink-v3.yaml](./contracts/push-deeplink-v3.yaml) | ✅ |
| Quickstart | [quickstart.md](./quickstart.md) | ✅ |

## Implementation Notes (для /speckit-tasks)

1. **Foreground receive**: `FcmForegroundPushService` подписывается на
   `FirebaseMessaging.onMessage` после `Firebase.initializeApp()` в bootstrap (только если push
   активирован).
2. **Mapper**: `RemoteMessage.data` → `PushIncomingMessage(title, body, deeplink?, notificationId?)`;
   при отсутствии `deeplink` построить `osetrovich://notifications/{notification_id}`.
3. **Handler**: на receive — `unreadCountNotifier.refresh()` + `notificationsNotifier.reload()`;
   показать `MaterialBanner` с tap → `PushDeeplinkHandler.navigate`.
4. **Tap (background)**: AppMetrica передаёт `payload` строкой — mapper MUST понимать JSON
   `{"deeplink":"...","notification_id":"42"}` и raw URL.
5. **404**: заменить `AppStrings.notificationUnavailable` на `notificationNotFound` =
   «Уведомление не найдено» (spec FR-007); при отсутствии id в локальном списке после reload —
   показать empty state.
6. **Тесты без Firebase**: inject fake `Stream<PushIncomingMessage>` в `PushForegroundHandler`.

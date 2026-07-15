# Implementation Plan: Интеграция Yandex AppMetrica

**Branch**: `008-yandex-appmetrica` | **Date**: 2026-07-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-yandex-appmetrica/spec.md`

## Summary

Интеграция Yandex AppMetrica в Flutter-приложение osetrovich.ru: базовая воронка покупки
(6 событий от запуска до успешного заказа), автоматический сбор крашей и push-уведомления
через `appmetrica_push_plugin`. Архитектура: абстракции `AnalyticsService` и `PushService` в
`lib/core/analytics/` и `lib/core/push/` с реализациями AppMetrica; инициализация в
`app_bootstrap`; события воронки — из domain-слоя (CartNotifier, CheckoutNotifier) и
ключевых экранов; deep link из push — `PushDeeplinkHandler` + go_router. REST API не
расширяется: push-токен регистрируется SDK; `pushEnabled` уже в `PATCH /profile/preferences`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter stable channel (README: Dart 3.7+)

**Primary Dependencies**: flutter_riverpod, go_router, dio; **новые**: `appmetrica_plugin`
(аналитика + краши), `appmetrica_push_plugin` (push); существующие: `permission_handler`
(push permission из 003), mocktail, integration_test

**Storage**: API-ключи AppMetrica — `--dart-define` / env (не в репозитории); буферизация
событий — внутри SDK AppMetrica; `pushEnabled` — сервер + `PushPreferencesService`

**Testing**: flutter test (unit + widget), integration_test; `NoOpAnalyticsService` /
`FakeAnalyticsService` для изоляции тестов от SDK

**Target Platform**: Android 8+ / iOS 15+ (push и deep link)

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: холодный старт +≤ 500 мс vs baseline (SC-007); события воронки не
блокируют UI (FR-005); 95% событий доставляются при стабильной сети (SC-002)

**Constraints**: UI на русском; фирменная палитра без изменений; моки REST без изменений;
PII (телефон, адрес) не в аналитике (FR-013); debug/release — разные API-ключи AppMetrica
(FR-014); нативная настройка FCM (Android) и APNs + Push Capability (iOS)

**Scale/Scope**: 2 новых core-модуля, ~6 точек интеграции событий, 1 bootstrap, нативная
конфигурация Android/iOS, контракты событий и push-payload (не REST)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter multi-platform**: `appmetrica_plugin` и `appmetrica_push_plugin` — официальные кроссплатформенные плагины; единая Dart-обёртка
- [x] **Русский UI**: новые пользовательские тексты не требуются (push permission — reuse `AppStrings` из 003)
- [x] **Тесты**: unit (AnalyticsService, PushDeeplinkHandler, event mapping), widget (bootstrap), integration (воронка + mock analytics)
- [x] **Flutter best practices**: абстракции в `core/`; вызовы аналитики из Notifier/domain, не из виджетов напрямую
- [x] **Tab Bar**: без изменений корневой навигации; push deep link → существующие маршруты
- [x] **OpenAPI + моки**: REST API не меняется; push-токен — SDK; `pushEnabled` уже в OpenAPI v0.3.0
- [x] **Русские спеки**: все артефакты фичи на русском
- [x] **Фирменная палитра**: фича не добавляет экранов с новым UI
- [x] **JWT-авторизация**: `AppMetrica.setUserProfileID` при входе/выходе; Bearer token не передаётся в AppMetrica

*Повторная проверка после Phase 1: research, data-model и contracts согласованы; нарушений нет.*

## Project Structure

### Documentation (this feature)

```text
specs/008-yandex-appmetrica/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── analytics-events.yaml    # каталог событий воронки
│   └── push-deeplink.yaml       # схема payload push → маршрут
└── tasks.md                     # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── main.dart                                    # WidgetsFlutterBinding + ранняя init AppMetrica
├── core/
│   ├── bootstrap/
│   │   └── app_bootstrap.dart                   # +analytics init, push sync, userProfileId
│   ├── analytics/
│   │   ├── analytics_service.dart               # abstract interface
│   │   ├── analytics_events.dart                # имена + параметры (контракт)
│   │   ├── appmetrica_analytics_service.dart    # AppMetrica implementation
│   │   ├── no_op_analytics_service.dart         # tests / missing API key
│   │   └── analytics_providers.dart             # Riverpod DI
│   ├── push/
│   │   ├── push_service.dart                    # abstract interface
│   │   ├── appmetrica_push_service.dart         # token stream, activate/deactivate
│   │   ├── push_deeplink_handler.dart           # payload → go_router path
│   │   └── push_providers.dart
│   └── router/
│       └── app_router.dart                      # +initial push deeplink listener
├── features/
│   ├── auth/domain/
│   │   └── auth_session_provider.dart           # setUserProfileID on login/logout
│   ├── cart/domain/
│   │   ├── cart_notifier.dart                   # +event add_to_cart
│   │   └── checkout_notifier.dart               # +event order_success
│   ├── catalog/presentation/
│   │   ├── catalog_screen.dart                  # +event catalog_view
│   │   └── product_detail_screen.dart           # +event product_view
│   ├── cart/presentation/
│   │   └── cart_screen.dart                     # +event checkout_start
│   └── profile/domain/
│       └── push_preferences_service.dart        # +sync push_enabled → AppMetrica profile

test/core/analytics/
    analytics_events_test.dart                   # NEW
    appmetrica_analytics_service_test.dart       # NEW (mock platform channel / fake)
    push_deeplink_handler_test.dart              # NEW

test/features/cart/
    cart_notifier_analytics_test.dart            # NEW

integration_test/
    analytics_funnel_flow_test.dart              # NEW (FakeAnalyticsService)

android/
    app/build.gradle                             # FCM / AppMetrica manifest meta-data
    app/src/main/AndroidManifest.xml             # permissions, services

ios/
    Runner/Info.plist                            # background modes (remote-notification)
    Runner.xcodeproj                             # Push Notifications capability

pubspec.yaml                                     # +appmetrica_plugin, appmetrica_push_plugin
```

**Structure Decision**: инфраструктурная интеграция в `lib/core/analytics/` и
`lib/core/push/` (по аналогии с `core/network/`, `core/router/`). Feature-модули только
вызывают `AnalyticsService` через Riverpod — без прямой зависимости от AppMetrica SDK.
Контракты событий и push-payload — YAML в `contracts/` (не OpenAPI: внешний интерфейс —
AppMetrica SDK и панель рассылок).

## Complexity Tracking

> Нарушений конституции, требующих обоснования, нет. Ниже — осознанная платформенная сложность.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Нативная конфигурация FCM/APNs | AppMetrica Push требует transport на уровне ОС | Только in-app уведомления (002) не покрывают FR-009–FR-011 |
| Платформенный код в Android/iOS | Официальный quick-start AppMetrica Push | Чистый Dart без плагина не доставляет push |
| Два API-ключа (debug/release) | FR-014: не смешивать метрики | Один ключ исказит production-воронку и crash rate |

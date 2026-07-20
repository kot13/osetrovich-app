---

description: "Список задач для фичи «Автоматическое обновление токена при 401»"
---

# Tasks: Автоматическое обновление токена при 401

**Input**: Design documents from `/specs/010-token-refresh-401/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и integration тесты включены для каждой user story.

**Organization**: Задачи сгруппированы по user story для независимой реализации и проверки.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Можно выполнять параллельно (разные файлы, нет зависимостей от незавершённых задач)
- **[Story]**: User story из spec.md (US1–US3)
- В описании указан точный путь к файлу

## Path Conventions

- **Flutter (Osetrovich)**: `lib/`, `test/`, `integration_test/`, `openapi/`
- Структура согласно [plan.md](./plan.md)

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Проверка контракта и строки UI для ошибок авторизации

- [x] T001 Сверить `POST /auth/refresh` и схемы `RefreshBody` / `TokenResponse` в `openapi/openapi.yaml` со `specs/010-token-refresh-401/contracts/openapi.yaml`
- [x] T002 [P] Добавить строки `sessionExpired` («Сессия истекла. Войдите снова.») и `networkError` («Нет соединения с интернетом») в `lib/core/l10n/app_strings.dart` (если отсутствуют)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Маппер ошибок и методы сессии — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T003 [P] Создать `lib/core/network/api_error_mapper.dart`: `mapToApiException(Object)` (DioException → `ApiException` с русским message) и `userFacingErrorMessage(Object)` для UI
- [x] T004 [P] Unit-тест маппера в `test/core/network/api_error_mapper_test.dart`: HTTP 401, сетевые ошибки, `ErrorResponse` из тела ответа
- [x] T005 Добавить `applyRefreshedTokens(TokenResponse tokens)` в `lib/features/auth/domain/auth_session_provider.dart`: сохранение в `SecureTokenStorage` + обновление `AuthSession` без смены `phone`
- [x] T006 [P] Unit-тест `applyRefreshedTokens` в `test/features/auth/auth_session_refresh_test.dart`: токены в storage и state обновлены после refresh

**Checkpoint**: Маппер ошибок и обновление сессии готовы; интерцептор может использовать колбэки

---

## Phase 3: User Story 1 — Прозрачное обновление сессии при 401 (Priority: P1) 🎯 MVP

**Goal**: При 401 на защищённом запросе — автоматический `POST /auth/refresh`, повтор запроса; параллельные 401 координируются одним refresh

**Independent Test**: Симулировать 401 → refresh 200 → retry успешен; два параллельных 401 — один вызов refresh (quickstart С1, С3)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T007 [P] [US1] Unit-тест 401 → refresh 200 → retry success в `test/core/network/token_refresh_interceptor_test.dart` (dio + `MockAdapter`)
- [x] T008 [P] [US1] Unit-тест дедупликации: два параллельных 401 → один `POST /auth/refresh` в `test/core/network/token_refresh_interceptor_test.dart`
- [x] T009 [P] [US1] Unit-тест: пути `/auth/sms/request`, `/auth/sms/verify`, `/auth/refresh` не запускают auto-refresh в `test/core/network/token_refresh_interceptor_test.dart`

### Implementation for User Story 1

- [x] T010 [US1] Создать `lib/core/network/token_refresh_interceptor.dart`: `QueuedInterceptor`, `onError` при 401, `_refreshFuture` для дедупликации, исключённые пути, refresh через отдельный Dio без интерцептора
- [x] T011 [US1] Обновить `lib/core/network/dio_client.dart`: подключить `TokenRefreshInterceptor` после `AuthInterceptor`; параметры `onTokensRefreshed`, `onSessionExpired`, `baseUrl`/timeouts
- [x] T012 [US1] Обновить `lib/core/network/providers.dart`: передать в `createDio` колбэк `onTokensRefreshed` → `AuthSessionNotifier.applyRefreshedTokens`
- [x] T013 [US1] В `token_refresh_interceptor.dart`: после успешного refresh обновить заголовок `Authorization` и повторить исходный `RequestOptions` через `dio.fetch`

**Checkpoint**: Авторизованный пользователь с истёкшим access получает данные без повторного входа

---

## Phase 4: User Story 2 — Выход при невозможности обновить сессию (Priority: P1)

**Goal**: При отказе refresh (401, нет refresh-токена) — `clearSession`, состояние неавторизованного пользователя

**Independent Test**: Refresh 401 → `onSessionExpired` вызван, токены очищены, профиль показывает заглушку входа (quickstart С2)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T014 [P] [US2] Unit-тест: refresh возвращает 401 → `onSessionExpired` вызван, retry не выполняется в `test/core/network/token_refresh_interceptor_test.dart`
- [x] T015 [P] [US2] Unit-тест: 401 без refresh-токена в storage → `onSessionExpired` без вызова `/auth/refresh` в `test/core/network/token_refresh_interceptor_test.dart`
- [x] T016 [P] [US2] Unit-тест: сетевой сбой при refresh → сессия **не** очищается, пробрасывается `NETWORK_ERROR` в `test/core/network/token_refresh_interceptor_test.dart`
- [x] T017 [P] [US2] Widget-тест: после `clearSession` профиль показывает `EmptyState` с `AppStrings.profileAuthRequired` в `test/features/profile/profile_screen_test.dart`

### Implementation for User Story 2

- [x] T018 [US2] Реализовать ветку `onSessionExpired` в `lib/core/network/token_refresh_interceptor.dart`: 401 на `/auth/refresh`, пустой refresh, отказ сервера
- [x] T019 [US2] Обновить `lib/core/network/providers.dart`: колбэк `onSessionExpired` → `AuthSessionNotifier.clearSession()`
- [x] T020 [US2] Обработать гонку «Выйти» во время refresh: флаг/отмена в `token_refresh_interceptor.dart` или проверка `authSessionProvider` перед применением refresh (см. spec Edge case)

**Checkpoint**: Недействительный refresh разлогинивает пользователя; сетевой сбой при refresh не разлогинивает

---

## Phase 5: User Story 3 — Понятные сообщения вместо технических ошибок (Priority: P2)

**Goal**: В UI нет `DioException[bad response]`; русскоязычные сообщения через `ApiException` / `AppStrings`

**Independent Test**: Ошибка загрузки профиля не содержит подстроку `DioException` (quickstart SC-003)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T021 [P] [US3] Расширить `test/core/network/api_error_mapper_test.dart`: `DioException` type badResponse → message на русском, не `error.toString()`
- [x] T022 [P] [US3] Widget-тест error state в `test/features/profile/profile_screen_test.dart`: текст ошибки не содержит `DioException` / `bad response`

### Implementation for User Story 3

- [x] T023 [US3] Обновить `_mapError` в `lib/core/network/api_client.dart`: делегировать в `api_error_mapper.dart` вместо `error.toString()`
- [x] T024 [US3] Заменить `error.toString()` на `userFacingErrorMessage(error)` в `lib/features/profile/presentation/profile_screen.dart`
- [x] T025 [P] [US3] Проверить остальные экраны с `AsyncValue.error` (корзина, каталог, главная): при отображении `errorMessage` использовать маппер, не сырой `toString()` — правки только там, где утекает технический текст

**Checkpoint**: Пользователь видит понятные русские сообщения при ошибках авторизации и сети

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Регрессия, интеграция, валидация quickstart

- [x] T026 [P] Добавить в `lib/core/network/mock_api_client.dart` опциональный режим симуляции 401 на `getProfile` + успешный `refreshToken` для ручной отладки (если `useMockApi = true`)
- [x] T027 [P] Обновить или добавить сценарий в `integration_test/auth_flow_test.dart`: авторизация → защищённый раздел без технических ошибок (при возможности с мок-Dio)
- [x] T028 Прогнать сценарии из `specs/010-token-refresh-401/quickstart.md`: `flutter test`, `flutter analyze`
- [x] T029 [P] Обновить `README.md` (кратко): поведение auto-refresh при 401 и logout при неуспешном refresh — только если в проекте документируется auth

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: без зависимостей
- **Foundational (Phase 2)**: после Setup — **блокирует** все user stories
- **US1 (Phase 3)**: после Foundational
- **US2 (Phase 4)**: после US1 (logout — ветка того же интерцептора; тесты можно писать параллельно с T010–T013)
- **US3 (Phase 5)**: после Foundational; **можно параллельно с US1/US2** (отдельные файлы UI/маппер)
- **Polish (Phase 6)**: после US1 + US2 + US3

### User Story Dependencies

| Story | Зависит от | Независимая проверка |
|-------|------------|----------------------|
| US1 (P1) | Phase 2 | Unit-тесты интерцептора: refresh + retry + dedupe |
| US2 (P1) | US1 (интерцептор) | Unit-тесты logout; widget профиля без авторизации |
| US3 (P2) | Phase 2 | Unit маппера + widget profile error без DioException |

### Parallel Opportunities

- **Phase 1**: T002 параллельно с T001
- **Phase 2**: T003/T004 параллельно с T005/T006
- **US1 tests**: T007, T008, T009 параллельно
- **US2 tests**: T014–T017 параллельно (после T010 или в TDD до реализации logout-ветки)
- **US3**: T021–T025 параллельно с US2 implementation (другие файлы)
- **Polish**: T026, T027, T029 параллельно

### Parallel Example: User Story 1

```bash
# Тесты до реализации (TDD):
flutter test test/core/network/token_refresh_interceptor_test.dart

# Параллельно после T010:
# — T011 dio_client.dart
# — T012 providers.dart (колбэк refresh)
```

### Parallel Example: User Story 3 (независимо от US2)

```bash
# Пока US2 дорабатывает logout-ветку:
flutter test test/core/network/api_error_mapper_test.dart
# T023 api_client.dart + T024 profile_screen.dart
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 + Phase 2
2. Phase 3 (US1): интерцептор с refresh + retry
3. **STOP and VALIDATE**: unit-тесты T007–T009 зелёные; ручная проверка quickstart С1
4. Демо: прозрачный refresh без logout

### Incremental Delivery

1. Setup + Foundational → готовы маппер и `applyRefreshedTokens`
2. US1 → MVP: auto-refresh работает
3. US2 → безопасный logout при мёртвой сессии
4. US3 → UX: нет технических ошибок в UI
5. Polish → интеграция и quickstart

### Suggested MVP Scope

**User Story 1 only** (Phase 1–3): покрывает основную боль «401 без ручного re-login». US2 критична для production — добавить сразу после US1 в том же PR или следующим коммитом.

---

## Notes

- При `useMockApi = true` Dio не используется — основной охват через unit-тесты с `MockAdapter`
- Интерцептор MUST NOT вызывать `AuthRepository` / `DioApiClient.refreshToken` (рекурсия) — отдельный Dio (research §3)
- `[P]` = разные файлы, без конфликтов
- Коммит после каждой фазы или логической группы задач

---

## Task Summary

| Phase | Задач | User Story |
|-------|-------|------------|
| 1 Setup | 2 | — |
| 2 Foundational | 4 | — |
| 3 US1 | 7 | US1 (P1) 🎯 MVP |
| 4 US2 | 7 | US2 (P1) |
| 5 US3 | 5 | US3 (P2) |
| 6 Polish | 4 | — |
| **Итого** | **29** | |

**Format validation**: все задачи в формате `- [x] Tnnn [P?] [USn?] Description with file path`

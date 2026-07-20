# Research: Автоматическое обновление токена при 401

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md)

## 1. Место реализации refresh-логики

**Decision**: отдельный `TokenRefreshInterceptor` (Dio `QueuedInterceptor`) в
`lib/core/network/token_refresh_interceptor.dart`, подключается **после** `AuthInterceptor`
в `createDio`.

**Rationale**: `AuthInterceptor` только добавляет `Authorization` в `onRequest`.
Обработка 401 — в `onError`: попытка refresh, повтор запроса, logout. Разделение
ответственности упрощает тестирование и исключает циклические зависимости в одном классе.

**Alternatives considered**:
- Логика refresh в каждом `DioApiClient`-методе — отклонено: дублирование, нарушение DRY,
  легко пропустить эндпоинт.
- Riverpod `Provider` с обёрткой над каждым API-вызовом — отклонено: слишком много
  boilerplate; интерцептор — стандартный паттерн для Dio.

---

## 2. Координация параллельных 401

**Decision**: в интерцепторе — `Future<TokenResponse>? _refreshFuture`; при первом 401
создаётся один `Completer`/future refresh, остальные запросы `await` тот же future.
После успеха — все повторяют запрос с новым access-токеном.

**Rationale**: соответствует FR-005; `QueuedInterceptor` сериализует обработку ошибок
в очереди Dio, дополнительный mutex на refresh future защищает от гонок между воркерами.

**Alternatives considered**:
- Пакет `dio_refresh_token` — отклонено: лишняя зависимость; логика простая и специфична
  для проекта (logout через Riverpod).
- Без дедупликации — отклонено: множественные вызовы `/auth/refresh` при пачке запросов.

---

## 3. Запрос refresh без зацикливания

**Decision**: refresh выполняется через **отдельный «голый» Dio** (без `TokenRefreshInterceptor`,
только baseUrl/timeout) **или** через тот же Dio с флагом
`options.extra['skipTokenRefresh'] = true` на запросе `/auth/refresh`. Пути `/auth/sms/*`
и `/auth/refresh` исключены из auto-refresh по `requestOptions.path`.

**Rationale**: FR-006 — 401 на `/auth/refresh` сразу вызывает logout, без повторного refresh.
Отдельный Dio для refresh — распространённый паттерн, исключает рекурсию в `onError`.

**Alternatives considered**:
- Вызывать `AuthRepository.refresh` через `DioApiClient` — отклонено: снова проходит
  через интерцептор и может зациклиться.

---

## 4. Интеграция с Riverpod и сессией

**Decision**: `createDio` принимает колбэки:
- `Future<void> Function(TokenResponse tokens) onTokensRefreshed` — сохранить в storage +
  обновить `AuthSessionNotifier`;
- `Future<void> Function() onSessionExpired` — `clearSession()`.

Колбэки собираются в `providers.dart` через `ref` (отдельный `dioProvider` или расширение
`apiClientProvider`).

**Rationale**: интерцептор не должен зависеть от Riverpod напрямую (сложно тестировать,
циклические провайдеры). Колбэки — чистая инъекция зависимостей.

**Alternatives considered**:
- `GlobalKey` / singleton для `AuthSessionNotifier` — отклонено: антипаттерн в Riverpod.
- Refresh только в storage без обновления `authSessionProvider` — отклонено: рассинхрон
  in-memory сессии и токенов.

---

## 5. Поведение при сетевой ошибке vs отказе сервера

**Decision**:
- **401 на `/auth/refresh`** или отсутствие refresh-токена → `onSessionExpired()` (logout).
- **Таймаут / connection error** при refresh → пробросить `ApiException` с кодом
  `NETWORK_ERROR` и русским сообщением; сессия **сохраняется** (spec Assumptions).

**Rationale**: различие «сессия мёртва» и «сеть недоступна» критично для UX.

**Alternatives considered**:
- Logout при любой ошибке refresh — отклонено: противоречит spec Assumptions.

---

## 6. Маппинг ошибок и отображение в UI

**Decision**: вынести `DioException` → `ApiException` в `api_error_mapper.dart`:
- HTTP 401 (без успешного retry) → `UNAUTHORIZED`, message из тела или `AppStrings.sessionExpired`
- Сетевые ошибки → `NETWORK_ERROR`, `AppStrings.networkError` / `loadFailed`
- Прочие 4xx/5xx — парсинг `ErrorResponse` из OpenAPI при наличии

Исправить экраны, где в UI используется `error.toString()` (например,
`profile_screen.dart`), на хелпер `userFacingErrorMessage(Object error)`.

**Rationale**: корневая причина «DioException[bad response]» — `_mapError` возвращает
`error.toString()`; плюс прямой вывод в виджетах.

**Alternatives considered**:
- Только интерцептор без маппера — отклонено: ошибки после retry и не-auth ошибки
  всё равно утекут в UI.

---

## 7. Моки и тестирование

**Decision**:
- **Unit-тесты интерцептора**: `dio` + `MockAdapter` — симуляция 401 → 200 refresh →
  retry success; 401 → 401 refresh → logout callback.
- **MockApiClient**: опционально добавить флаги/режим для интеграционных сценариев с
  `useMockApi = true` (эмуляция 401 на `getProfile`); основной охват — Dio-тесты.
- **Widget-тест**: profile error state не содержит подстроку `DioException`.

**Rationale**: при `useMockApi = true` Dio не используется — интерцептор не тестируется
через моки без отдельного Dio.

**Alternatives considered**:
- Только integration_test на боевом API — отклонено: нестабильно, нет контроля 401.

---

## 8. OpenAPI и контракт

**Decision**: изменений в `openapi/openapi.yaml` **не требуется**; эндпоинт `POST /auth/refresh`
и схемы `RefreshBody` / `TokenResponse` уже описаны. В `contracts/openapi.yaml` фичи —
дельта-ссылка для документации.

**Rationale**: принцип VI — contract-first уже выполнен для auth.

**Alternatives considered**:
- Добавить заголовок `X-Retry-After-Refresh` — отклонено: вне scope, сервер не меняется.

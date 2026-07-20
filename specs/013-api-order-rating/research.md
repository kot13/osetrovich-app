# Research: Текущий заказ и оценка через Mobile API

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md)

## 1. Контракт Mobile API v0.12.1

**Decision**: принять эндпоинты и схемы из `openapi/openapi.yaml` (v0.12.1):

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/orders/current` | Текущий заказ из ERP или `order: null`; неоценённый completed — только в течение 7 суток от `delivery_at` |
| POST | `/orders/{orderId}/rating` | Оценка 1–5 + comment (≤ 500); TTL 7 суток от `delivery_at` |
| POST | `/orders/{orderId}/rating/skip` | Пропуск оценки; TTL 7 суток от `delivery_at` |

Ответ `GET /orders/current`:

```json
{ "order": { ...CurrentOrder } }
```

или `{ "order": null }`.

Ответ `POST .../rating` и `.../rating/skip` — объект `CurrentOrder` (не обёртка).

**Rationale**: contract-first (принцип VI); OpenAPI уже обновлён; `DioApiClient` реализует
парсинг `response.data!['order']` и прямой `CurrentOrder.fromJson` для rating.

**Alternatives considered**:
- **Локальный кэш заказа после createOrder** — дублирует сервер, расходится при смене статуса в ERP.
- **Polling статуса** — вне scope; достаточно pull-to-refresh и инвалидации после действий.

---

## 2. Удаление демо-моков текущего заказа

**Decision**: удалить `_seedDemoOrdersIfNeeded` и константы `demoPhoneDelivery`,
`demoPhoneRatingPending`, `demoPhoneRatingSkipped` из `MockApiClient`.

Поведение мока после изменения:

- `getCurrentOrder()` — возвращает последний заказ из `_ordersByUserId[userId]`, созданный через
  `createOrder`, или `null` если заказов нет.
- `submitOrderRating` / `skipOrderRating` — без изменений логики, работают с заказами из
  `_ordersByUserId`.
- Для тестов рейтинга: сначала `createOrder`, затем вручную перевести статус в `completed` и
  `ratingState: pending` через helper в тесте или публичный test-only метод мока.

**Rationale**: FR-005 — рабочая сборка не должна показывать фиктивные заказы; demo phones
создавали ложное ощущение «всегда есть заказ» при входе под тестовыми номерами.

**Alternatives considered**:
- **Оставить demo phones за флагом** — усложняет мок без пользы для production.
- **Полностью удалить мок-методы rating** — нарушает принцип VI для offline-тестов.

---

## 3. Рабочая конфигурация API

**Decision**: `useMockApi = false` в `lib/core/network/providers.dart` (текущее значение);
базовый URL — `https://trout.osetrovich.ru/v1` (`dio_client.dart`).

**Rationale**: фича нацелена на боевой API; мок остаётся для `flutter test` и локальной
разработки при явном переключении.

**Alternatives considered**:
- **Flavor-based конфиг** — вне scope; достаточно `dart-define` / константы.

---

## 4. Обработка ошибок оценки

**Decision**:

| HTTP | code (типичный) | UX |
|------|-----------------|-----|
| 400 | invalid_request | SnackBar: «Оценка недоступна» |
| 400 | rating_period_expired | SnackBar: `AppStrings.ratingPeriodExpired` + `invalidate(currentOrderProvider)` |
| 404 | not_found | SnackBar: «Заказ не найден» + `invalidate(currentOrderProvider)` |
| 409 | rating_already_set / conflict | SnackBar: `AppStrings.ratingAlreadySet` + refresh заказа |
| сеть | network_error | SnackBar: `AppStrings.networkError` |

Реализация: `try/catch ApiException` в `HomeOrderHistorySection` (`_onSkipRating`, `_onRateOrder`)
и `NotificationDetailScreen._onRateOrder`; при 409/404/`rating_period_expired` —
`ref.invalidate(currentOrderProvider)`.

**Rationale**: FR-009; текущий код только `invalidate` без feedback пользователю.

**Alternatives considered**:
- **Глобальный error handler** — избыточно для двух точек входа.
- **Игнорировать 409** — пользователь видит устаревший prompt.

---

## 5. Валидация комментария к оценке

**Decision**: `TextField` в `OrderRatingSheet` — `maxLength: 500` (контракт
`SubmitOrderRatingRequest.comment`); `toJson` omit empty comment (уже есть).

**Rationale**: edge case spec; предотвращает 400 от сервера.

**Alternatives considered**:
- **Валидация только на сервере** — худший UX.

---

## 6. Синхронизация после оформления заказа

**Decision**: в `CheckoutNotifier.submit` после успешного `createOrder` вызвать
`ref.invalidate(currentOrderProvider)` (и опционально `ref.read(currentOrderProvider.future)`).

**Rationale**: FR-012 — после оформления на «Главной» должен появиться новый заказ с сервера,
а не остаться пустым до ручного refresh.

**Alternatives considered**:
- **Оптимистично подставлять `Order` из ответа createOrder** — `createOrder` возвращает `Order`,
  не `CurrentOrder` с `ratingState`; безопаснее refetch.

---

## 7. UI-состояние оценки (без изменений логики)

**Decision**: сохранить `buildHomeOrderUiState`:

- `showRatingPrompt` = `status == completed && ratingState == pending`
- `showRepeatButton` = `status == completed && (submitted || skipped)`
- `showContactOperator` = всегда `true`

**Rationale**: соответствует фиче 007 и серверным `ratingState` из ERP.

**Alternatives considered**:
- **Скрывать блок после completed+skipped** — против spec (блок остаётся с «Повторить заказ»).

---

## 8. Тестирование

| Уровень | Объект |
|---------|--------|
| Unit | `buildHomeOrderUiState`, `SubmitOrderRatingRequest.toJson`, mock rating после createOrder |
| Widget | `OrderRatingSheet` maxLength; `HomeOrderHistorySection` error snackbar (mockthrow) |
| Contract | mock: getCurrentOrder null без заказа; rating submit/skip/409 после createOrder+status patch |
| Manual | боевой API: активный заказ, completed+pending, оценка, пропуск, уведомление |

**Rationale**: конституция III; user stories 1–4.

**Alternatives considered**:
- **Integration test на реальный API** — нестабильно в CI; manual в quickstart.

---

## 9. TTL оценки (7 суток с даты доставки)

**Decision**:

- Оценка и пропуск доступны **7 суток** от `delivery_at` (дата доставки в ERP).
- После истечения: `POST /rating` и `POST /rating/skip` → HTTP **400**, code **`rating_period_expired`**.
- `GET /orders/current`: неоценённый выполненный заказ **не возвращается** после 7 суток
  (`order: null`).
- Клиент **не вычисляет TTL** самостоятельно; опирается на `ratingState` с сервера и коды ошибок.
- Опционально парсить `deliveryAt` в `CurrentOrder` для будущего UI (countdown вне scope).

**Мок** (`MockApiClient`):

- Хранить `deliveryAt` на заказе (при `completeOrderForRating` — `DateTime.now()` или заданная дата).
- В `submitOrderRating` / `skipOrderRating` проверять `DateTime.now().difference(deliveryAt).inDays > 7`
  → `ApiException(code: 'rating_period_expired', ...)`.
- Test helper `expireOrderRatingPeriod(orderId)` — сдвинуть `deliveryAt` на 8+ дней назад.

**Rationale**: FR-006, FR-007, FR-013, SC-006; spec Clarifications Session 2026-07-20.

**Alternatives considered**:
- **Клиентский countdown и скрытие кнопок по `deliveryAt`** — дублирует сервер, риск рассинхрона часовых поясов.
- **Отдельный `ratingState: expired`** — в контракте нет; сервер использует `order: null` или 400.

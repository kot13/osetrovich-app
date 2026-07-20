# Data Model: Текущий заказ и оценка через Mobile API

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. CurrentOrderResponse (API response, GET /orders/current)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| order | CurrentOrder? | да (nullable) | Текущий заказ или `null` |

**Парсинг клиента**: `response.data!['order']` → `null` или `CurrentOrder.fromJson`.

---

## 2. CurrentOrder (domain / API)

Наследует поля `Order` + поля оценки.

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Идентификатор заказа |
| orderNumber | string | да | Номер для пользователя |
| items | List\<OrderLine\> | да | min 1 |
| itemsSubtotalRub | int | да | ≥ 0 |
| deliveryFeeRub | int | да | ≥ 0 |
| totalRub | int | да | ≥ 0 |
| deliveryAddress | string | да | Адрес доставки |
| apartment | string? | нет | Квартира / офис |
| lat | double? | нет | Широта |
| lng | double? | нет | Долгота |
| comment | string? | нет | Комментарий к заказу |
| status | OrderStatus | да | accepted … completed |
| createdAt | DateTime | да | ISO 8601 |
| deliveryAt | DateTime? | нет | Дата доставки (`delivery_at`); используется сервером для TTL 7 суток; парсить если есть в ответе |
| ratingState | OrderRatingState | да | Состояние оценки |
| ratingStars | int? | нет | 1–5, если `submitted` |

**Файл**: `lib/features/cart/domain/order.dart` — `CurrentOrder`, `CurrentOrder.fromJson`.

---

## 3. OrderRatingState (enum)

| Значение JSON | Domain | Описание |
|---------------|--------|----------|
| not_applicable | notApplicable | Оценка не требуется (активный заказ) |
| pending | pending | Ожидает оценки или пропуска |
| submitted | submitted | Оценка отправлена |
| skipped | skipped | Пользователь пропустил |

**Переходы** (сервер — источник истины):

```text
not_applicable → (заказ completed) → pending
pending → submitted  (POST /rating)
pending → skipped    (POST /rating/skip)
submitted → (terminal)
skipped → (terminal)
```

Повторный `POST /rating` или `/rating/skip` при `submitted`/`skipped` → HTTP 409.

**Окно оценки** (сервер — источник истины):

```text
completed + pending → оценка/пропуск разрешены, если now ≤ delivery_at + 7 суток
после delivery_at + 7 суток → rating_period_expired (400); getCurrentOrder может вернуть order: null
```

Клиент не вычисляет TTL; UI prompt определяется `ratingState == pending` из ответа сервера.

---

## 4. SubmitOrderRatingRequest (API request)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| stars | int | да | 1–5 |
| comment | string? | нет | max 500; omit if empty |

**toJson**:

```json
{ "stars": 4, "comment": "Отлично!" }
```

или `{ "stars": 5 }` без comment.

**Файл**: `lib/features/cart/domain/order.dart`.

---

## 5. HomeOrderUiState (presentation)

| Поле | Тип | Вычисление |
|------|-----|------------|
| order | CurrentOrder | вход |
| showRatingPrompt | bool | `completed && ratingState == pending` |
| showRepeatButton | bool | `completed && (submitted \|\| skipped)` |
| showContactOperator | bool | `true` |

**Файл**: `lib/features/home/domain/home_order_ui_state.dart`.

---

## 6. Riverpod providers

| Provider | Тип | Поведение |
|----------|-----|-----------|
| currentOrderProvider | `FutureProvider<CurrentOrder?>` | `session == null` → `null` без HTTP; иначе `getCurrentOrder()` |
| orderRepositoryProvider | `Provider<OrderRepository>` | делегирует `ApiClient` |

**Инвалидация** `currentOrderProvider`:

- после `submitOrderRating` / `skipOrderRating` (успех или 409/404/`rating_period_expired`)
- после успешного `checkoutNotifier.submit`
- pull-to-refresh на `HomeScreen` (баннеры, товары недели, текущий заказ, счётчик и **список**
  in-app уведомлений)
- logout → provider возвращает `null` через `authSessionProvider`

---

## 7. Mock storage (тесты)

| Структура | Описание |
|-----------|----------|
| `_ordersByUserId: Map<String, List<CurrentOrder>>` | Заказы пользователя |
| Источник заказов | только `createOrder` (без demo phone seed) |
| `getCurrentOrder` | `orders.last` или `null`; скрывать неоценённый completed старше 7 суток от `deliveryAt` |
| TTL в моке | `deliveryAt` на заказе; проверка 7 суток в rating/skip |

Для widget/unit-тестов рейтинга: helper `completeOrderForRating(orderId, {deliveryAt})` и
`expireOrderRatingPeriod(orderId)` (сдвиг `deliveryAt` на 8+ дней назад).

---

## 8. AppStrings (новые / используемые)

| Ключ | Текст |
|------|-------|
| ratingUnavailable | Оценка недоступна |
| ratingPeriodExpired | Срок оценки истёк |
| ratingAlreadySet | Оценка уже отправлена или пропущена |
| ratingSubmitFailed | Не удалось отправить оценку. Попробуйте ещё раз |
| ratingThankYou | Спасибо за оценку! |
| homeLoadError | Не удалось загрузить данные |
| homeRetry | Повторить |

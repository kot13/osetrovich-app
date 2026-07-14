# Data Model: Корзина и оформление заказа

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. CartLineItemView (клиент, отображение строки)

| Поле | Тип | Описание |
|------|-----|----------|
| productId | string | SKU |
| name | string | Название товара |
| weightLabel | string | Вес («500 г») |
| priceRub | int | Цена за единицу |
| imageUrl | string | Фото для строки списка |
| quantity | int | ≥ 1 |
| lineTotalRub | int | priceRub × quantity |

**Источник**: `CartNotifier.state[productId]` + `ProductSummary`/`ProductDetail` из каталога.

**UI**: `CartLineTile` — фото, название, вес, `QuantityPriceBar`, lineTotal справа или под баром.

---

## 2. OrderTotals (клиент, агрегаты корзины)

| Поле | Тип | Описание |
|------|-----|----------|
| itemsSubtotalRub | int | Σ lineTotalRub |
| deliveryFeeRub | int | 0 или 300 |
| totalRub | int | itemsSubtotalRub + deliveryFeeRub |

**Вычисление**:

```text
itemsSubtotalRub = sum(line.lineTotalRub for line in cartLines)
deliveryFeeRub = itemsSubtotalRub >= 2000 ? 0 : 300
totalRub = itemsSubtotalRub + deliveryFeeRub
```

**Провайдер**: `orderTotalsProvider` — `Provider<OrderTotals>` от `cartLinesProvider`.

**Инвариант**: при пустой корзине провайдер не используется (экран — EmptyState).

---

## 3. DeliveryFeePolicy (константы domain)

| Константа | Значение | Описание |
|-----------|----------|----------|
| freeDeliveryThresholdRub | 2000 | Порог бесплатной доставки (включительно) |
| paidDeliveryFeeRub | 300 | Стоимость доставки ниже порога |

**Функция**: `calculateDeliveryFeeRub(int itemsSubtotalRub) → int`

---

## 4. CreateOrderRequest (API request)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| items | List\<OrderLineInput\> | да | min 1 |
| deliveryAddress | string | да | trim, min 1 символ |
| comment | string? | нет | Комментарий покупателя |

### OrderLineInput

| Поле | Тип | Обязательное |
|------|-----|--------------|
| productId | string | да |
| quantity | int | да, ≥ 1 |

**Источник**: `CartNotifier.state` + поля формы checkout.

---

## 5. Order (ответ API / domain)

| Поле | Тип | Описание |
|------|-----|----------|
| id | string | UUID заказа |
| orderNumber | string | Номер для пользователя (`ORD-1001`) |
| items | List\<OrderLine\> | Snapshot позиций |
| itemsSubtotalRub | int | Сумма товаров |
| deliveryFeeRub | int | Доставка |
| totalRub | int | Итого |
| deliveryAddress | string | Адрес |
| comment | string? | Комментарий |
| status | OrderStatus | `pending` в v1 |
| createdAt | DateTime | Время создания |

### OrderLine (snapshot в заказе)

| Поле | Тип | Описание |
|------|-----|----------|
| productId | string | SKU |
| name | string | Название на момент заказа |
| weightLabel | string | Вес |
| priceRub | int | Цена за единицу |
| quantity | int | Количество |
| lineTotalRub | int | priceRub × quantity |

### OrderStatus (enum)

| Значение | Описание |
|----------|----------|
| pending | Принят, ожидает обработки |

*Дальнейшие статусы (confirmed, delivered) — вне scope v1.*

---

## 6. CheckoutState (клиент, notifier)

| Поле | Тип | Описание |
|------|-----|----------|
| isSubmitting | bool | Идёт отправка заказа |
| errorMessage | string? | Последняя ошибка |
| lastSuccessOrder | Order? | Успешно оформленный заказ (для dialog) |

**Переходы**:

```text
idle ──submit──► isSubmitting=true
isSubmitting + success ──► isSubmitting=false, lastSuccessOrder=order, cart cleared
isSubmitting + error ──► isSubmitting=false, errorMessage set, cart unchanged
lastSuccessOrder shown ──► clear lastSuccessOrder (ack dialog)
```

---

## 7. CartNotifier (расширение из 004)

| Метод | Эффект |
|-------|--------|
| increment / decrement / add | без изменений |
| clear() | state = {} |

**После clear**: `distinctCount = 0` → EmptyState, badge скрыт.

---

## 8. CheckoutFormFields (UI-local)

| Поле | Тип | Валидация |
|------|-----|-----------|
| deliveryAddress | TextEditingController | required on submit |
| comment | TextEditingController | optional |

Не персистируются между перезапусками приложения (Assumptions spec).

---

## 8a. PendingCheckout (клиент, notifier)

| Поле | Тип | Описание |
|------|-----|----------|
| address | string | Адрес на момент нажатия «Оформить» без сессии |
| comment | string | Комментарий (может быть пустым) |

**Провайдер**: `pendingCheckoutProvider` (`Notifier<PendingCheckout?>`).

**Жизненный цикл**:

```text
null ──save on auth gate──► PendingCheckout
PendingCheckout + auth + resume submit success ──► null
```

Сохраняется при `push('/auth/phone?from=checkout')`; очищается только после успешного заказа.

---

## 9. Ошибки API (заказ)

| code | HTTP | Сообщение (пример) |
|------|------|-------------------|
| invalid_request | 400 | Пустой адрес или корзина |
| product_unavailable | 400 | Товар недоступен |
| unauthorized | 401 | Требуется авторизация |

---

## 10. Навигация

| Маршрут | Экран |
|---------|-------|
| `/cart` | CartScreen (empty или checkout) |
| `/auth/phone?from=checkout` | Вход при оформлении без сессии |
| `/auth/sms?from=checkout` | Ввод СМС; успех → `/cart` и auto-submit |
| `/auth/phone` | Вход из профиля/главной; успех → `/profile` |

**Tab Bar index**: 3 — Корзина.

---

## 11. Диаграмма связей

```text
CartNotifier (Map<productId, qty>)
     │
     ├── cartLinesProvider ──► CatalogRepository.getProductById
     │         │
     │         └── CartLineItemView[]
     │
     ├── orderTotalsProvider ──► OrderTotals
     │
     └── checkout submit ──► OrderRepository.createOrder
                                   │
     pendingCheckoutProvider ◄────┘ (auth gate)
                                   │
                                   ▼
                              Order (API)
                                   │
                                   success ──► CartNotifier.clear()
                                               success dialog
```

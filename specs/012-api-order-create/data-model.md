# Data Model: Оформление заказа через API

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. OrderLineInput (API request, позиция)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | int | да | Идентификатор товара, ≥ 1 |
| quantity | int | да | Количество, ≥ 1 |

**JSON**: `{ "id": 1000, "quantity": 2 }`

**Источник**: `CartNotifier.state` — ключ `int` передаётся напрямую (без `toString`).

**Миграция**: ~~`productId: String`~~ → `id: int`.

---

## 2. CreateOrderRequest (API request)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| items | List\<OrderLineInput\> | да | min 1 |
| deliveryAddress | string | да | trim, min 1 символ |
| apartment | string? | нет | Квартира / офис; omit if empty |
| lat | double? | нет | Широта; omit if null (вне UI scope) |
| lng | double? | нет | Долгота; omit if null (вне UI scope) |
| comment | string? | нет | Комментарий; omit if empty |

**toJson правила**:

```text
deliveryAddress — всегда (после trim)
items — всегда
apartment — только если trim().isNotEmpty
comment — только если trim().isNotEmpty
lat, lng — только если != null (в фиче 012 не задаются из UI)
```

**Источник**: корзина + поля формы checkout.

---

## 3. OrderLine (ответ API / domain snapshot)

| Поле | Тип | Описание |
|------|-----|----------|
| id | int | Идентификатор товара |
| name | string | Название на момент заказа |
| weightLabel | string | Вес |
| priceRub | int | Цена за единицу |
| quantity | int | Количество |
| lineTotalRub | int | priceRub × quantity |

**Миграция**: ~~`productId: String`~~ → `id: int` в `fromJson` (`json['id']`).

**Потребители**: `repeat_order.dart`, экраны истории заказов (home).

---

## 4. Order (ответ API / domain)

| Поле | Тип | Описание |
|------|-----|----------|
| id | string | UUID заказа |
| orderNumber | string | Номер для пользователя |
| items | List\<OrderLine\> | Snapshot позиций |
| itemsSubtotalRub | int | Сумма товаров |
| deliveryFeeRub | int | Доставка |
| totalRub | int | Итого |
| deliveryAddress | string | Адрес |
| apartment | string? | Квартира / офис |
| lat | double? | Широта (если была в заказе) |
| lng | double? | Долгота (если была в заказе) |
| comment | string? | Комментарий |
| status | OrderStatus | Статус |
| createdAt | DateTime | Время создания |

`CurrentOrder` наследует те же поля + `ratingState`, `ratingStars`.

---

## 5. CheckoutFormFields (UI-local)

| Поле | Controller | Валидация |
|------|------------|-----------|
| deliveryAddress | `_addressController` | required on submit |
| apartment | `_apartmentController` | optional |
| comment | `_commentController` | optional |

Расположение в UI: адрес → квартира → комментарий → кнопка «Оформить».

Не персистируются между перезапусками приложения.

---

## 6. PendingCheckout (клиент, notifier)

| Поле | Тип | Описание |
|------|-----|----------|
| address | string | Адрес |
| apartment | string | Квартира / офис (может быть пустой) |
| comment | string | Комментарий (может быть пустым) |

**Провайдер**: `pendingCheckoutProvider`.

**Жизненный цикл** (без изменений логики, расширен payload):

```text
null ──save on auth gate──► PendingCheckout(address, apartment, comment)
PendingCheckout + auth + resume submit success ──► null
```

При resume: восстановить controllers из `PendingCheckout`, если поля пустые.

---

## 7. CheckoutNotifier.submit (сигнатура)

```dart
Future<Order?> submit({
  required String address,
  String? apartment,
  String? comment,
});
```

**Алгоритм** (дополнение к 005):

1. trim address — required.
2. trim apartment — передать в request только если не пусто.
3. trim comment — как раньше.
4. items: `[OrderLineInput(id: entry.key, quantity: entry.value) for entry in cart]`.

---

## 8. Снятие фокуса (presentation)

| Элемент | Поведение |
|---------|-----------|
| GestureDetector на ListView | `onTap` → `FocusManager.instance.primaryFocus?.unfocus()` |
| TextField | получает фокус по тапу; `onTap` родителя не мешает |
| FilledButton «Оформить» | onPressed выполняется штатно |

Не отдельная сущность в domain — UX-поведение экрана корзины.

---

## 9. Ошибки API (без изменений)

| code | HTTP | Сообщение (пример) |
|------|------|-------------------|
| INVALID_REQUEST | 400 | Пустой адрес или корзина |
| PRODUCT_UNAVAILABLE | 400 | Товар недоступен |
| unauthorized | 401 | Требуется авторизация |

---

## 10. Диаграмма потока данных

```text
CartScreen
  ├── _addressController
  ├── _apartmentController      ← NEW
  └── _commentController
           │
           ▼
  CheckoutNotifier.submit
           │
           ├── CreateOrderRequest { items[{id, qty}], address, apartment?, comment? }
           │
           ▼
  OrderRepository → POST /orders
           │
           ▼
  Order { items[{id, ...}], apartment?, ... }
           │
           success ──► CartNotifier.clear()
                     controllers.clear()
                     PendingCheckout.clear()
```

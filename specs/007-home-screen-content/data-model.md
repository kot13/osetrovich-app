# Data Model: Наполнение главного экрана

**Дата**: 2026-07-15  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. Banner (расширение)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Идентификатор баннера |
| imageUrl | string (uri) | да | URL фотографии |
| sortOrder | int | да | Порядок в карусели |
| link | BannerLink | да | Целевая ссылка |

### BannerLink

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| type | BannerLinkType | да | Тип перехода |
| url | string (uri)? | при `external` | Внешний URL |
| targetId | string? | при `promotion` / `news` / `product` | ID сущности в приложении |

### BannerLinkType (enum)

| Значение | UI-действие |
|----------|-------------|
| none | Нет перехода |
| external | Браузер |
| promotion | `/promotions/article/{targetId}` |
| news | `/promotions/article/{targetId}` |
| product | `/catalog/product/{targetId}` |

**Валидация API**: при `type=external` обязателен `url`; при внутренних типах — `targetId`.

**Клиент**: `lib/features/home/domain/banner.dart` — заменить `linkUrl?` на `BannerLink link`.

---

## 2. WeeklyProductsResponse (API)

| Поле | Тип | Описание |
|------|-----|----------|
| items | List\<ProductSummary\> | Товары недели, порядок как в ответе |

Переиспользует `ProductSummary` из `lib/features/catalog/domain/product.dart`.

**UI**: горизонтальная лента; пустой `items` → секция скрыта (FR-009).

---

## 3. OrderStatus (расширение)

| API value | UI label (рус.) | Описание |
|-----------|-----------------|----------|
| accepted | Принят | Заказ принят |
| processing | В обработке | Обрабатывается |
| assembly | Сборка | Комплектуется |
| delivery | Доставка | В пути |
| completed | Выполнено | Доставлен |

**Миграция**: значение `pending` из `POST /orders` (v0.5.0) трактуется как `accepted` при отображении и в мок-хранилище.

**Клиент**: расширить `OrderStatus` enum и `orderStatusFromJson` в `lib/features/cart/domain/order.dart`.

---

## 4. OrderRatingState

| Значение | Условие | UI на главной |
|----------|---------|---------------|
| not_applicable | status ≠ completed | Нет блока оценки/повтора по оценке |
| pending | completed, оценка не дана | Текст + «Оценить» / «Пропустить» |
| submitted | completed, оценка отправлена | «Повторить заказ» |
| skipped | completed, нажато «Пропустить» | «Повторить заказ» |

---

## 5. CurrentOrder (API / domain)

Расширяет поля `Order`:

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | UUID |
| orderNumber | string | да | ORD-XXXX |
| items | List\<OrderLine\> | да | Snapshot позиций |
| itemsSubtotalRub | int | да | Сумма товаров |
| deliveryFeeRub | int | да | Доставка |
| totalRub | int | да | Итого |
| deliveryAddress | string | да | Адрес |
| comment | string? | нет | Комментарий |
| status | OrderStatus | да | Статус |
| createdAt | DateTime | да | Дата создания |
| ratingState | OrderRatingState | да | Состояние оценки |
| ratingStars | int? | нет | 1–5 при `submitted` |

### CurrentOrderResponse

| Поле | Тип | Описание |
|------|-----|----------|
| order | CurrentOrder? | `null` — нет текущего заказа |

---

## 6. SubmitOrderRatingRequest (API)

| Поле | Тип | Обязательное | Валидация |
|------|-----|--------------|-----------|
| stars | int | да | 1–5 |
| comment | string? | нет | trim, max 500 символов (мок) |

**Ответ**: обновлённый `CurrentOrder` с `ratingState: submitted`.

---

## 7. HomeOrderUiState (клиент, presentation)

Агрегат для виджета `HomeOrderHistorySection`:

| Поле | Тип | Описание |
|------|-----|----------|
| order | CurrentOrder | Данные заказа |
| showRatingPrompt | bool | `ratingState == pending` |
| showRepeatButton | bool | `status == completed` && (`submitted` \|\| `skipped`) |
| showContactOperator | bool | всегда `true` при отображении блока |

**Вычисление**: pure function `buildHomeOrderUiState(CurrentOrder)`.

---

## 8. RepeatOrderResult (клиент, domain)

| Поле | Тип | Описание |
|------|-----|----------|
| addedCount | int | Число добавленных позиций |
| skippedProductIds | List\<string\> | Недоступные товары |

**Инвариант**: `addedCount + skippedProductIds.length <= order.items.length`.

---

## 9. Провайдеры (Riverpod)

| Провайдер | Тип | Условие |
|-----------|-----|---------|
| bannersProvider | `FutureProvider<List<Banner>>` | всегда |
| weeklyProductsProvider | `FutureProvider<List<ProductSummary>>` | всегда |
| currentOrderProvider | `FutureProvider<CurrentOrder?>` | `isAuthenticated` → API; иначе `null` без запроса |

**Инвалидация** `currentOrderProvider` после rating / skip.

---

## 10. Ошибки API

| code | HTTP | Контекст |
|------|------|----------|
| unauthorized | 401 | `/orders/current`, rating |
| not_found | 404 | заказ не найден |
| rating_already_set | 409 | повторная оценка или skip |
| invalid_request | 400 | stars вне 1–5 |

---

## 11. Навигация

| Источник | Маршрут |
|----------|---------|
| Баннер product | `/catalog/product/{id}` |
| Баннер promotion/news | `/promotions/article/{id}` |
| Баннер external | системный браузер |
| Повторить заказ | `/cart` (Tab Bar index 3) |
| Карточка weekly | `/catalog/product/{id}` |

---

## 12. Диаграмма потоков (блок заказа)

```text
GET /orders/current
        │
        ▼
   order == null ──► секция скрыта
        │
        ▼
   CurrentOrder
        │
        ├── status != completed ──► статус + состав + сумма + «Связаться с оператором»
        │
        └── status == completed
                 │
                 ├── ratingState == pending ──► + приглашение + Оценить/Пропустить
                 │         │
                 │         ├── POST /rating ──► ratingState = submitted
                 │         └── POST /rating/skip ──► ratingState = skipped
                 │
                 └── ratingState in (submitted, skipped) ──► + «Повторить заказ»
                              │
                              └── repeatOrderToCart ──► go('/cart')
```

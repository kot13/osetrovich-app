# Research: Корзина и оформление заказа

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md)

## 1. API оформления заказа

**Decision**: REST-эндпоинт под тегом `orders`, **с** `bearerAuth`:

| Метод | Путь | Назначение |
|-------|------|------------|
| POST | `/orders` | Создать заказ из позиций корзины |

**Request body** (`CreateOrderRequest`):
- `items[]`: `{ productId, quantity }` — min 1 позиция
- `deliveryAddress`: string, trim, min length 1
- `comment`: string?, optional

**Response** (`OrderResponse`):
- `id`, `orderNumber` (человекочитаемый, напр. `ORD-1001`)
- `items[]` с snapshot: productId, name, weightLabel, priceRub, quantity, lineTotalRub
- `itemsSubtotalRub`, `deliveryFeeRub`, `totalRub`
- `status`: `pending` (v1)
- `createdAt`

**Ошибки**:
- `401` — не авторизован
- `400` + `invalid_request` — пустой адрес, пустая корзина
- `400` + `product_unavailable` — товар не найден или снят с продажи

**Rationale**: contract-first (принцип VI); сервер — источник правды для цен и итогов;
клиент показывает предварительный расчёт, ответ API подтверждает окончательную сумму (FR-005).

**Alternatives considered**:
- **Только локальное оформление без API** — не соответствует e-commerce и конституции (моки по OpenAPI).
- **`POST /cart/checkout`** — корзина на сервере не существует в v1; клиент отправляет snapshot позиций.

---

## 2. Расчёт стоимости доставки

**Decision**: константы в `delivery_fee.dart`:

```dart
const freeDeliveryThresholdRub = 2000;
const paidDeliveryFeeRub = 300;

int calculateDeliveryFeeRub(int itemsSubtotalRub) =>
    itemsSubtotalRub >= freeDeliveryThresholdRub ? 0 : paidDeliveryFeeRub;
```

**Поток**:
1. Клиент: `itemsSubtotalRub` = Σ (priceRub × quantity) по разрешённым позициям.
2. Клиент: `deliveryFeeRub` = `calculateDeliveryFeeRub(itemsSubtotalRub)`.
3. Клиент: `totalRub` = `itemsSubtotalRub + deliveryFeeRub`.
4. Сервер (мок): пересчитывает по тем же правилам; расхождение цен товара → серверная цена.

**Rationale**: FR-004; мгновенный UX (SC-003); порог ≥ 2000 включительно (edge case spec).

**Alternatives considered**:
- **Доставка в ответе только с сервера** — задержка UI при каждом изменении количества.
- **Хардкод в виджете** — нарушает принцип IV (бизнес-логика в domain).

---

## 3. Обогащение позиций корзины данными товара

**Decision**: `cartLinesProvider` — `FutureProvider` / `AsyncNotifier`, подписанный на
`cartNotifierProvider`.

**Алгоритм**:
1. Для каждого `productId` в `CartNotifier.state` вызвать `CatalogRepository.getProductById(id)`.
2. Собрать `CartLineItemView(product, quantity)`; `lineTotalRub = product.priceRub * quantity`.
3. При 404 — исключить позицию из списка и вызвать `cartNotifier.remove(productId)` (edge case).

**Параллельность**: `Future.wait` по уникальным ID (типично 1–10 позиций).

**Rationale**: `CartNotifier` хранит только `Map<productId, quantity>` (004); name/price не
дублируются при добавлении; актуальная цена с сервера при открытии корзины.

**Alternatives considered**:
- **Snapshot в CartNotifier при add** — дублирование данных, рассинхрон цен.
- **Batch API `POST /products/by-ids`** — избыточно для v1; N вызовов `getProductById` достаточно в моке.

---

## 4. Состояние оформления (CheckoutNotifier)

**Decision**: `CheckoutNotifier extends Notifier<CheckoutState>`:

| Поле | Тип | Описание |
|------|-----|----------|
| isSubmitting | bool | Блокировка повторного нажатия |
| errorMessage | String? | Ошибка на русском |
| lastOrder | Order? | Последний успешный заказ (для success UI) |

**Метод `submit(address, comment)`**:
1. Guard: `isSubmitting` → return
2. Guard: `!isAuthenticated` → error / redirect (presentation)
3. Validate: `address.trim().isEmpty` → `AppStrings.addressRequired`
4. Build request from `cartNotifier.state`
5. `orderRepository.createOrder(...)`
6. Success: `cartNotifier.clear()`, `lastOrder = response`, signal UI
7. Error: `errorMessage`, cart unchanged

**Rationale**: FR-008, FR-009; edge case двойного нажатия; тестируемый Notifier.

**Alternatives considered**:
- **Вся логика в `CartScreen` StatefulWidget** — нарушает принцип IV.
- **Riverpod `AsyncNotifier` для submit** — избыточно; одноразовая операция.

---

## 5. UI экрана корзины

**Decision**: `CartScreen` — `ConsumerWidget` с ветвлением:

```text
cartDistinctCount == 0  → EmptyState (как сейчас)
cartDistinctCount > 0   → CustomScrollView / ListView:
    ├── CartLineTile × N
    ├── CartOrderSummary
    ├── DeliveryTermsCard (статический текст FR-005)
    ├── CheckoutForm (адрес, комментарий)
    └── кнопка «Оформить» (accent, full width)
```

**Количество на строке**: переиспользовать `QuantityPriceBar` из catalog (compact mode) или
обёртка `CartLineTile` с тем же виджетом.

**Успех**: `showDialog` или `AlertDialog` «Заказ оформлен» + номер заказа; после закрытия —
пустое состояние (корзина уже очищена).

**Rationale**: FR-001–FR-007; единый scroll; условия доставки всегда видны перед оформлением.

**Alternatives considered**:
- **Отдельный экран Checkout** — spec описывает один экран «Корзина».
- **Bottom sheet для адреса** — лишний шаг для пользователя.

---

## 6. Авторизация при оформлении

**Decision**: при нажатии «Оформить» без сессии:

1. Сохранить адрес и комментарий в `pendingCheckoutProvider` (`PendingCheckout`).
2. `context.push('/auth/phone?from=checkout')`.
3. Телефон передаёт `from=checkout` на `/auth/sms?from=checkout`.
4. После успешного `verifyCode`:
   - если `from=checkout` → `context.go('/cart')`;
   - иначе → `context.go('/profile')` (вход из профиля/главной).
5. При открытии `CartScreen` с активным `PendingCheckout` и сессией — автоматический
   `checkoutNotifier.submit()` (в `initState` post-frame + `ref.listen` на `isAuthenticatedProvider`).

Перед `createOrder` вызывается `syncMockApiProfile(ref, session)` — профиль в мок-API
синхронизируется из JWT при восстановлении сессии и перед оформлением (без обязательного
визита на экран «Профиль»).

**Rationale**: FR-012, FR-013; JWT на `POST /orders` (принцип IX); UX — один проход
«Оформить → войти → заказ готов» без повторного ввода.

**Alternatives considered**:
- **Гостевой checkout без auth** — против spec Assumptions.
- **Блокировать весь экран корзины без auth** — против FR-012 (просмотр без входа).
- **Возврат через `pop` после auth** — ненадёжно при `go()` и пересоздании `CartScreen`;
  отклонено в пользу `PendingCheckout` + resume на `/cart`.

---

## 7. Расширение CartNotifier

**Decision**: добавить метод `clear()` → `state = {}`.

Вызывается только после успешного `createOrder`.

**Rationale**: FR-009, SC-004.

---

## 8. Мок createOrder

**Decision** в `MockApiClient`:
- Проверка bearer token (как profile endpoints)
- `ensureProfile` через `syncMockApiProfile` при `setSession` / `restoreSession` / перед заказом
- Валидация address trim
- Для каждого item — lookup product; 400 если нет
- Пересчёт subtotal, delivery, total
- Генерация `orderNumber`: `ORD-{increment}`
- Сохранение в in-memory list (для отладки; не exposed в API v1)

**Rationale**: полное соответствие OpenAPI; тестируемые сценарии ошибок.

---

## 9. Тексты UI (app_strings)

**Decision** — ключевые строки:

| Ключ | Текст |
|------|-------|
| cartAddressLabel | Адрес доставки |
| cartAddressHint | Укажите адрес в Санкт-Петербурге или ближайшем пригороде |
| cartCommentLabel | Комментарий к заказу |
| cartCommentHint | Необязательно |
| cartItemsSubtotal | Товары |
| cartDeliveryFee | Доставка |
| cartTotal | Итого |
| cartDeliveryFree | Бесплатно |
| cartCheckout | Оформить |
| cartOrderSuccess | Заказ успешно оформлен |
| cartOrderSuccessDetails | После формирования заказа вам поступит сообщение с деталями |
| addressRequired | Укажите адрес доставки |
| checkoutAuthRequired | Войдите, чтобы оформить заказ |
| orderFailed | Не удалось оформить заказ. Попробуйте ещё раз |
| productUnavailableInCart | Некоторые товары недоступны и удалены из корзины |

Блок FR-005 — отдельная константа `cartDeliveryTerms` (многострочный).

**Rationale**: принцип II; FR-005 дословно.

---

## 10. Тестирование

**Decision**:

| Уровень | Объект |
|---------|--------|
| Unit | `calculateDeliveryFeeRub` (1999→300, 2000→0, 2500→0), `OrderTotals`, `CheckoutNotifier` (validation, clear cart on success), `CartNotifier.clear` |
| Widget | `CartScreen` empty/filled, summary lines, address validation message, checkout button disabled while submitting, resume order after auth from checkout |
| Integration | `cart_checkout_flow`: add items → cart → fill address → checkout → auth → auto success → empty cart |
| Contract | `mock_api_client_orders_test`: 201, 401, 400 empty address, 400 unavailable product |

**Rationale**: конституция III; user stories 1–3 из spec.

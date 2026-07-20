# Research: Оформление заказа через API

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md)

## 1. Изменения контракта `POST /orders`

**Decision**: принять схемы из OpenAPI v0.11.2 (`openapi/openapi.yaml`):

| Область | Было (клиент v0.5–0.10) | Стало (v0.11.2) |
|---------|-------------------------|-----------------|
| `OrderLineInput` | `productId: string` | `id: integer` (≥ 1) |
| `CreateOrderRequest` | items, deliveryAddress, comment? | + `apartment?`, `lat?`, `lng?` (+ deliveryDate/interval — вне scope) |
| `OrderLine` (ответ) | `productId: string` | `id: integer` |
| `Order` (ответ) | deliveryAddress, comment? | + `apartment?`, `lat?`, `lng?` |

**Сериализация запроса** (`CreateOrderRequest.toJson`):

```json
{
  "items": [{ "id": 1000, "quantity": 2 }],
  "deliveryAddress": "ул. Примерная, 1",
  "apartment": "42",
  "comment": "Позвонить за час"
}
```

Поля `apartment`, `lat`, `lng`, `comment` — **omit if empty/null** (не отправлять `null` и не
отправлять строку из пробелов).

**Rationale**: contract-first (принцип VI); OpenAPI уже обновлён в репозитории; `CartNotifier`
уже хранит `Map<int, int>` — убираем лишний `toString()` / `int.tryParse` в моке.

**Alternatives considered**:
- **Оставить `productId` в клиенте с маппингом** — расхождение с контрактом, риск отказа API.
- **Отправлять `lat`/`lng` как 0** — нарушает семантику optional; spec требует omit.

---

## 2. Поле «Квартира / офис» в форме

**Decision**:

- Подпись: `AppStrings.cartApartmentLabel` = «Квартира / офис»; hint = «Необязательно».
- Расположение: между полем адреса и комментарием в `CheckoutForm`.
- `TextEditingController` на `CartScreen` (как address/comment).
- `CheckoutNotifier.submit(address:, apartment:, comment:)` — `apartment` trim, omit if empty.
- `PendingCheckout` расширить полем `apartment`; `save` / `resume` / `clear` после успеха.

**Rationale**: FR-004, FR-008; единый паттерн с существующими полями checkout (005).

**Alternatives considered**:
- **Объединить с адресом в одно поле** — не соответствует контракту (`apartment` отдельно).
- **Сохранять квартиру в профиле** — вне scope spec.

---

## 3. Координаты доставки (`lat`, `lng`)

**Decision**: в рамках фичи 012 координаты **не собираются** и **не передаются** в запросе.
Доменные модели (`CreateOrderRequest`, `Order`) получают опциональные `lat`/`lng` для
парсинга ответа API и будущего расширения; `toJson` не включает их без значения.

**Rationale**: spec Assumptions — «отдельный ввод координат вне scope»; FR-005.

**Alternatives considered**:
- **Geolocation при оформлении** — отдельная фича, требует разрешений и UX-согласования.
- **Хардкод null в JSON** — лишний шум в payload.

---

## 4. Миграция `OrderLine` в ответе API

**Decision**: поле `productId: String` в `OrderLine` заменить на `id: int`; обновить
`fromJson` (`json['id'] as int`), `repeat_order.dart` (убрать `int.parse`), тесты home/cart.

**Rationale**: контракт v0.11.2; согласованность с каталогом (int id, фича 009).

**Alternatives considered**:
- **Дублировать оба поля в модели** — технический долг без пользы.

---

## 5. Снятие фокуса с полей ввода (tap outside)

**Decision**: обернуть содержимое `_FilledCartBody` (виджет `ListView` с формой) в
`GestureDetector`:

```dart
GestureDetector(
  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
  behavior: HitTestBehavior.translucent,
  child: ListView(...),
)
```

**Поведение**:
- Тап по `TextField`, `FilledButton`, `QuantityPriceBar` обрабатывается дочерними виджетами
  (фокус не снимается при тапе на само поле).
- Тап по пустой области списка, карточке условий доставки, строке товара (вне интерактивных
  зон) — `unfocus()` + скрытие клавиатуры.
- Прокрутка `ListView` не блокируется (`translucent` не перехватывает drag).

**Rationale**: FR-009, FR-010; минимальный diff; стандартный Flutter-паттерн без зависимостей.

**Alternatives considered**:
- **`keyboardDismissBehavior: onDrag` только** — не покрывает тап вне поля (spec US3).
- **`onTapOutside` на каждом TextField** — дублирование; не снимает фокус при тапе на summary.
- **Отдельный `FocusNode` на форму** — избыточно для трёх полей.

---

## 6. Обновление мока `MockApiClient.createOrder`

**Decision**:

1. Читать `item.id` (int) вместо `int.tryParse(item.productId)`.
2. Сохранять `request.apartment` в `CurrentOrder` / `Order` при непустом trim.
3. В `OrderLine` ответа использовать `id: detail.id` (int).
4. Валидация: пустой `deliveryAddress` → `INVALID_REQUEST` (без изменений).

**Rationale**: принцип VI — моки соответствуют OpenAPI.

---

## 7. Тестовая стратегия

**Decision**:

| Уровень | Что покрыть |
|---------|-------------|
| Unit | `CreateOrderRequest.toJson` (int id, apartment omit/trim); `OrderLine.fromJson` (int id); `CheckoutNotifier.submit` с apartment; `PendingCheckout` save/resume |
| Widget | `CheckoutForm` — наличие поля квартиры; `cart_screen_test` — unfocus после тапа вне поля |
| Network | `mock_api_client_orders_test` — int id, apartment в ответе, unknown id → PRODUCT_UNAVAILABLE |
| Integration | обновить `cart_checkout_flow_test` — при необходимости apartment в pending flow |

**Rationale**: принцип III; регрессии в заказах критичны.

---

## 8. Порядок реализации (для tasks)

1. Доменные модели (`order.dart`) + unit-тесты сериализации.
2. `MockApiClient.createOrder` + `mock_api_client_orders_test`.
3. `CheckoutNotifier`, `PendingCheckout`, `cart_screen` (apartment flow).
4. `CheckoutForm` UI + `app_strings`.
5. `GestureDetector` unfocus + widget-тест.
6. `repeat_order.dart` + связанные тесты.
7. `flutter analyze` + полный `flutter test`.

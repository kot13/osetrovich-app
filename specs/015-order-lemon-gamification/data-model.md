# Data Model: Геймификация «Делай заказы — получай призы»

**Дата**: 2026-07-21  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. UserProfile (расширение)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| … | … | … | Существующие поля без изменений |
| lemons | int | да | Счётчик лимонов в текущем цикле акции, 0–10 |
| lemonGift | LemonGiftPreview? | нет | Данные подарка; присутствует только при `lemons == 10` |

**Валидация API**:
- `lemons`: integer, minimum 0, maximum 10.
- `lemonGift`: MUST быть `null`, если `lemons < 10`; MUST быть объектом, если `lemons == 10`.

**Клиент**: `lib/features/profile/domain/user_profile.dart`.

---

## 2. LemonGiftPreview

Подарочная позиция для отображения в корзине; не хранится в локальной корзине.

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| productId | int | да | ID товара-подарка на сервере |
| name | string | да | Название от сервера (в UI корзины показывается как «Подарок») |
| weightLabel | string | да | Вес / фасовка |
| imageUrl | string? | нет | URL изображения |

**Клиент**: `lib/features/profile/domain/lemon_gift_preview.dart` (или вложенный класс в
`user_profile.dart`).

---

## 3. Цикл акции (состояния)

```text
lemons = 0 ──(заказ)──► 1 ──…──► 9 ──(заказ)──► 10
                                                  │
                                    (заказ с подарком)
                                                  ▼
                                            lemons = 1
```

| lemons | Шкала на главной | lemonGift в профиле | Подарок в корзине (корзина не пуста) |
|--------|------------------|---------------------|--------------------------------------|
| 0 | 0 жёлтых | null | нет |
| 1–9 | N жёлтых | null | нет |
| 10 | 10 жёлтых | объект | да |

**Правило сброса**: только успешный заказ при `lemons == 10` → `lemons = 1` (FR-009).

---

## 4. HomeLemonGamificationUiModel (UI-модель главной)

Производная модель; не приходит с сервера.

| Поле | Тип | Описание |
|------|-----|----------|
| filledCount | int | Количество жёлтых лимонов (0–10) |
| totalSlots | int | Всегда 10 |

**Построение**: `buildHomeLemonGamificationUiModel(int lemons)` — `filledCount = lemons.clamp(0, 10)`.

**Клиент**: `lib/features/home/domain/home_lemon_gamification_ui_model.dart`.

---

## 5. CartLineItemView (расширение)

| Поле | Тип | По умолчанию | Описание |
|------|-----|--------------|----------|
| isGift | bool | false | Подарочная позиция |
| … | … | … | Существующие поля |

**Фабрика подарка**: `CartLineItemView.fromLemonGift(LemonGiftPreview gift)`:
- `isGift: true`
- `name` — для внутренней логики из API; в UI — `AppStrings.cartGiftLabel`
- `priceRub: 0`, `quantity: 1`, `sale: false`

---

## 6. cartDisplayLinesProvider

```text
cartNotifierProvider (Map<productId, qty>)
        +
profileNotifierProvider (lemons, lemonGift)
        │
        ▼
cartDisplayLinesProvider → List<CartLineItemView>
  1. cartLinesProvider (обычные товары)
  2. if auth && lemons==10 && cart not empty && lemonGift != null
       → append gift line
```

**Клиент**: `lib/features/cart/domain/cart_display_lines_provider.dart`.

---

## 7. OrderLine (расширение ответа заказа)

| Поле | Тип | Описание |
|------|-----|----------|
| isGift | bool | `true` для подарочной строки в подтверждённом заказе |

Добавляется сервером в `POST /orders` response при выдаче подарка.

**Клиент**: `lib/features/cart/domain/order.dart` — `OrderLine.isGift`.

---

## 8. Диаграмма потока данных

```text
HomeScreen
  ├── watch profileNotifierProvider (auth)
  └── HomeLemonGamificationCard
        └── HomeLemonGamificationUiModel (lemons)

CartScreen
  ├── watch cartDisplayLinesProvider
  └── CartLineTile (isGift ? read-only : editable)

CheckoutNotifier.submit
  └── POST /orders
        └── MockApiClient: update profile.lemons, add gift line to order
  └── profileNotifier.refresh()
```

---

## 9. Layout «Главной» (после фичи)

1. AppBar «Главная»
2. Карусель баннеров
3. `HomeProfileSlot` (auth | loyalty | пусто)
4. **`HomeLemonGamificationCard`** (только авторизован + профиль загружен)
5. «Товары недели»
6. «История заказов»

---

## 10. Состояния при смене сессии

```text
logout → profileNotifier.clear() → блок лимонов скрыт
login → profile load → блок с lemons из профиля
order success → profile refresh → обновление шкалы и исчезновение подарка в корзине
```

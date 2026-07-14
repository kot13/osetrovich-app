# Data Model: Каталог товаров

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. ProductSummary (краткая карточка)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Уникальный идентификатор SKU |
| name | string | да | Название товара |
| weightLabel | string | да | Отображаемый вес («500 г», «1 кг») |
| priceRub | int | да | Цена за единицу, рубли (целое) |
| imageUrl | string | да | URI основного фото для сетки |
| categoryIds | List\<string\> | да | Категории (для фильтра `categoryId`) |

**UI (карточка)**:
- `name`: max 2 lines, `TextOverflow.ellipsis`
- `weightLabel`: subtitle под названием
- `priceRub` → `formatPriceRub()`

**Источник**: `GET /catalog/products` → `items[]`

---

## 2. ProductDetail (страница товара)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | SKU |
| name | string | да | Полное название |
| weightLabel | string | да | Вес |
| priceRub | int | да | Цена за единицу |
| imageUrls | List\<string\> | да | min 1; галерея |
| description | string | да | Текст описания |
| categoryIds | List\<string\> | да | Категории |

**UI**:
- `name`: полный текст, перенос строк
- `imageUrls`: `PageView` horizontal
- `description`: body text под ценой

**Источник**: `GET /catalog/products/{id}`

---

## 3. ProductListPage (ответ API списка)

| Поле | Тип | Описание |
|------|-----|----------|
| items | List\<ProductSummary\> | Текущая страница |
| total | int | Всего в выборке категории |
| hasMore | bool | Есть следующая страница |
| offset | int | Текущий offset запроса |
| limit | int | Размер страницы (≤ 20) |

**Инвариант**: `items.length ≤ limit`; `hasMore === false` → дальнейшие `loadMore` не вызываются.

---

## 4. ProductsUiState (клиент, сетка каталога)

| Поле | Тип | Описание |
|------|-----|----------|
| items | List\<ProductSummary\> | Накопленные товары всех загруженных страниц |
| categoryId | string | Активный фильтр (из `selectedCategoryIdProvider`) |
| isLoadingInitial | bool | Первая загрузка категории |
| isLoadingMore | bool | Подгрузка следующей страницы |
| hasMore | bool | Из последнего ответа API |
| errorMessage | string? | Ошибка на русском |
| loadMoreError | string? | Ошибка только подгрузки (items сохранены) |

**Вычисляемые**:
- `isEmpty` = `!isLoadingInitial && items.isEmpty && errorMessage == null`
- `nextOffset` = `items.length`

**Переходы**:

```text
category change ──► reset items, offset=0 ──► fetch page 0
scroll end + hasMore ──► isLoadingMore ──► append items
fetch error (initial) ──► errorMessage, items=[]
fetch error (more) ──► loadMoreError, items unchanged
```

---

## 5. CartLineItem (локальная корзина)

| Поле | Тип | Описание |
|------|-----|----------|
| productId | string | SKU |
| quantity | int | ≥ 1 пока позиция в корзине |

**Хранилище**: `Map<String, int>` в `CartNotifier.state` (ключ = productId).

**Операции**:

```text
add/increment(productId) ──► quantity += 1 (min 1)
decrement(productId) ──► quantity -= 1; if 0 → remove key
remove(productId) ──► delete key
```

**Не хранится** в CartLineItem: name, price — берутся из ProductSummary/Detail при отображении (будущий экран корзины).

---

## 6. CartState (агрегаты для UI)

| Поле | Тип | Описание |
|------|-----|----------|
| lines | Map\<string, int\> | productId → quantity |

**Вычисляемые**:
- `distinctCount` = `lines.length` — **бейдж Tab Bar** (FR-006)
- `quantityOf(id)` = `lines[id] ?? 0`
- `isInCart(id)` = `quantityOf(id) > 0`

**Синхронизация**: `ProductCard`, `ProductDetailScreen`, `MainShell` — все `ref.watch(cartNotifierProvider)`.

---

## 7. CatalogCategory (без изменений)

Из `001-init-app-shell`: `id`, `name`, `sortOrder`. Chip `id: all` → query `categoryId=all`.

---

## 8. ProductCardVisualState (UI-only)

| Состояние | Условие | Вид |
|-----------|---------|-----|
| default | quantity == 0 | кнопка «цена +» слева внизу карточки |
| inCart | quantity ≥ 1 | панель «− K × цена +» слева внизу; фото, название, вес видны |

---

## 9. Навигация

| Маршрут | Экран |
|---------|-------|
| `/catalog` | CatalogScreen (chips + grid) |
| `/catalog/product/:id` | ProductDetailScreen |

**Tab Bar index**: 1 — Каталог; badge на index 3 — Корзина.

---

## 10. Диаграмма связей

```text
CatalogCategory[] ──filter──► ProductsNotifier ──► ProductSummary[] (grid)
                                      │
                                      └── tap ──► ProductDetail (API by id)

CartNotifier ◄── QuantityPriceBar (card + detail)
     │
     └── distinctCount ──► MainShell cart badge
```

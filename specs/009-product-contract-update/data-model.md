# Data Model: Обновление каталога по контракту

**Дата**: 2026-07-19  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## Константы (клиент)

| Имя | Значение | Описание |
|-----|----------|----------|
| `kAllCategoriesId` | `0` | Синтетическая категория «Все»; в API → query `categoryId=all` |

---

## 1. CatalogCategory

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | int | да | Id с сервера; `0` только для клиентской «Все» |
| name | string | да | Название для Filter Chip |
| sortOrder | int | да | Порядок сортировки |

**Источник**: `GET /catalog/categories` (без id=0); «Все» добавляется в `CategoriesNotifier`
через `withAllCategoryFirst()` — всегда первая в списке, даже если API не возвращает id=0.

**Валидация**: `id >= 0`; id с сервера `>= 1`.

---

## 2. ProductSummary

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | int | да | SKU |
| name | string | да | Название |
| weightLabel | string | да | Вес («0.5 кг») |
| priceRub | int | да | Текущая цена; при `special=true` — спеццена |
| oldPriceRub | int | да | Старая цена (парсинг; UI вне scope) |
| imageUrl | string | да | Фото для сетки |
| categoryIds | List\<int\> | да | Категории товара |
| sale | bool | да | Участие в акции → бейдж «Акция» |
| special | bool | да | Спеццена → бейдж «СПЕЦЦЕНА» |

**UI (карточка)**:
- Промо-бейджи: `ProductPromoBadges(sale:, special:)` поверх фото
- Остальной layout без изменений (name, weight, QuantityPriceBar)

**Источник**: `GET /catalog/products` → `items[]`, `GET /home/weekly-products`

---

## 3. ProductDetail

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | int | да | SKU |
| name | string | да | Название |
| weightLabel | string | да | Вес |
| priceRub | int | да | Цена |
| oldPriceRub | int | да | Парсинг; UI вне scope |
| imageUrls | List\<string\> | да | Галерея |
| description | string | да | Описание |
| categoryIds | List\<int\> | да | Категории |
| sale | bool | да | Согласованность с summary |
| special | bool | да | Согласованность с summary |

**UI**: бейджи **не** показываются на детальном экране (scope spec).

**Источник**: `GET /catalog/products/{id}`

---

## 4. ProductsUiState (обновление)

| Поле | Тип | Было | Стало |
|------|-----|------|-------|
| categoryId | int | string (`'all'`) | int (`kAllCategoriesId`) |

**API mapping**: `categoryId == 0 ? 'all' : '$categoryId'`

---

## 5. CartState (обновление)

| Поле | Тип | Было | Стало |
|------|-----|------|-------|
| quantities | Map | Map\<String, int\> | Map\<int, int\> |

**Инвариант**: ключи — `ProductSummary.id` из каталога.

---

## 6. ProductPromoBadges (presentation)

| Проп | Тип | Описание |
|------|-----|----------|
| sale | bool | Показать «Акция» |
| special | bool | Показать «СПЕЦЦЕНА» |

**Правила**:
- `sale && !special` → один бейдж «Акция»
- `special && !sale` → один бейдж «СПЕЦЦЕНА»
- оба `true` → оба бейджа в ряд
- оба `false` → `SizedBox.shrink()` / не рендерить Row

---

## 7. Связи с существующими сущностями (без изменения контракта)

| Сущность | Поле | Тип | Примечание |
|----------|------|-----|------------|
| OrderLine | productId | string | Остаётся string в API; `int.parse` при повторном заказе |
| OrderLineInput | productId | string | При создании заказа — `productId.toString()` |

---

## Миграция данных в коде

```text
String productId  ──► int id          (ProductSummary, ProductDetail, CartNotifier)
String categoryId ──► int categoryId  (ProductsUiState; 0 = all)
List<String> categoryIds ──► List<int>
+ sale, special, oldPriceRub в fromJson
```

Тестовые фикстуры и моки обновляются в том же PR; обратная совместимость со строковыми id
не поддерживается (breaking change контракта).

# Research: Обновление каталога по контракту

**Дата**: 2026-07-19  
**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md)

## 1. Тип идентификаторов категорий и товаров

**Decision**: `CatalogCategory.id`, `ProductSummary.id`, `ProductDetail.id` и элементы
`categoryIds` — тип `int` в Dart. Синтетическая категория «Все» — `id = 0` (константа
`kAllCategoriesId`), не приходит с сервера.

**Rationale**: соответствует OpenAPI (`type: integer` для `CatalogCategory.id`,
`ProductSummary.id`, path `/catalog/products/{id}`). Query-параметр `categoryId` остаётся
`string` в REST (`"all"` или строковое представление числа) — маппинг на клиенте:
`0 → "all"`, иначе `"$id"`.

**Alternatives considered**:
- Оставить `String` и парсить при запросе — отклонено: расхождение с контрактом, лишние
  `parse`/`toString` на каждом слое.
- `typedef ProductId = int` — отложено; простой `int` достаточен для scope фичи.

---

## 2. Состояние фильтра категории в UI

**Decision**: `ProductsUiState.categoryId` меняется с `String` на `int`; значение по
умолчанию `kAllCategoriesId` (0). `CategoryChips.selectedId` и `onSelected` — `int`.

**Rationale**: единый тип с `CatalogCategory.id`; chip «Все» выбирается как `id: 0`.

**Alternatives considered**:
- Хранить `String` только для API query — отклонено: дублирование и путаница с
  числовыми id категорий с сервера.

---

## 3. Корзина и ключи Map

**Decision**: `CartNotifier` state — `Map<int, int>` (productId → quantity). Все методы
`increment` / `decrement` / `addQuantity` принимают `int productId`.

**Rationale**: product id в каталоге — `int`; корзина привязана к каталогу. `OrderLine.productId`
в API заказов остаётся `string` — при `repeat_order` использовать `int.parse(line.productId)`.

**Alternatives considered**:
- Оставить `Map<String, int>` с `product.id.toString()` — отклонено: лишние преобразования
  в каждом виджете.

---

## 4. Маршрутизация go_router

**Decision**: path остаётся `product/:id` (строка в URL); в `builder` — `int.parse(id)`.
`ProductDetailScreen.productId` — `int`. `productDetailProvider` — `FutureProvider.family<
ProductDetail, int>`.

**Rationale**: go_router path parameters всегда строки; один parse на границе навигации.

**Alternatives considered**:
- Typed routes (go_router extras) — избыточно для одного параметра.

---

## 5. Поля sale, special и oldPriceRub

**Decision**: добавить в `ProductSummary` и `ProductDetail` поля `sale`, `special` (bool,
required) и `oldPriceRub` (int, required в JSON, **не отображать** в UI в этой фиче).

**Rationale**: OpenAPI помечает все четыре поля required; парсинг без UI для `oldPriceRub`
сохраняет contract-first без расширения scope.

**Alternatives considered**:
- Игнорировать `oldPriceRub` при парсинге — отклонено: нарушение принципа VI (моки/контракт).

---

## 6. UI промо-бейджей

**Decision**: новый виджет `ProductPromoBadges` — `Positioned` top-left (8 px inset) поверх
фото в `ProductCard` внутри `Stack`. Порядок слева направо: **«Акция»**, затем **«СПЕЦЦЕНА»**
(если оба `true`). Стили:
- «Акция» — фон `AppColors.accent`, текст `AppColors.dark`
- «СПЕЦЦЕНА» — фон `AppColors.primary`, текст белый

Шрифт: 10–11 pt, `fontWeight: w600`, padding horizontal 6 / vertical 2, `BorderRadius.circular(4)`.

**Rationale**: соответствует spec (оба бейджа, русские тексты, фирменная палитра); overlay
на фото не съедает место под название/цену.

**Alternatives considered**:
- Бейджи под названием — отклонено: ломает фиксированную высоту текстового блока карточки.
- Один комбинированный бейдж — отклонено: spec требует различать акцию и спеццену.

---

## 7. Мок-данные

**Decision**: категории с числовыми id (1…N); первая синтетическая «Все» с `id: 0`.
Товары — числовые id (1001+), `categoryIds: [int]`. Минимум 3 товара с разными
комбинациями `sale`/`special` для ручной и widget-проверки; остальным — `false/false`.

**Rationale**: демонстрация всех edge cases из spec без раздувания мока.

---

## 8. Аналитика

**Decision**: сигнатуры `reportProductView` / `reportAddToCart` остаются `String productId`;
передавать `productId.toString()` при вызове из каталога/корзины.

**Rationale**: AppMetrica params — строковые; изменение интерфейса аналитики вне scope.

**Alternatives considered**:
- Перевести analytics на `int` — отложено до отдельной фичи.

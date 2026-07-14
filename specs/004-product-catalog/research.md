# Research: Каталог товаров

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md)

## 1. API каталога товаров

**Decision**: REST-эндпоинты под тегом `catalog`, **без** `bearerAuth`:

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/catalog/products?categoryId&offset&limit` | Пагинированный список (limit max 20) |
| GET | `/catalog/products/{id}` | Деталь товара |

**Response list**: `{ items, total, hasMore, offset, limit }`.

**Query**:
- `categoryId` — обязательный; значение `all` (как chip «Все») возвращает товары всех категорий.
- `offset` — default 0; `limit` — default 20, max 20.

**Rationale**: offset/limit проще cursor для мока и соответствует FR-002; категория `all`
уже есть в Filter Chips (init-app-shell).

**Alternatives considered**:
- **Cursor-based pagination** — лучше для live-каталога, но избыточно для v1 с фиксированным моком.
- **GraphQL** — вне стека проекта (REST + OpenAPI).

**Мок**: ≥60 товаров распределены по категориям; 3–5 товаров с несколькими `imageUrls`;
`GET /catalog/products/unknown` → 404.

---

## 2. Модели ProductSummary vs ProductDetail

**Decision**:
- **ProductSummary** — для сетки: `id`, `name`, `weightLabel`, `priceRub`, `imageUrl`, `categoryIds`.
- **ProductDetail** — для страницы: те же поля + `imageUrls[]`, `description`.

**Rationale**: меньший payload списка; деталь подгружается по клику (может содержать длинное описание).

**Alternatives considered**:
- **Единая модель с optional description** — проще, но тащит description в каждую страницу списка.

---

## 3. Пагинация и infinite scroll

**Decision**: `ProductsNotifier` + `ScrollController` с порогом **200 px** до конца списка.

**Поток**:
1. Смена `selectedCategoryId` → сброс `items`, `offset=0`, загрузка первой страницы.
2. `loadMore()` если `hasMore && !isLoadingMore`.
3. Append `items` к накопленному списку.

**UI**: `GridView.builder` внутри `CustomScrollView` или `GridView` с `controller`; индикатор
внизу при `isLoadingMore`; без повторного запроса при `hasMore: false`.

**Rationale**: нативный Flutter без `infinite_scroll_pagination` — меньше зависимостей;
паттерн предсказуем в тестах (mock scroll notifications).

**Alternatives considered**:
- **Пакет infinite_scroll_pagination** — удобен, но лишняя зависимость для одного экрана.
- **Riverpod `AsyncNotifier` без накопления** — не поддерживает append без кастомного state.

---

## 4. Сетка 2 колонки

**Decision**: `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` на ширине < 600 dp;
`LayoutBuilder` / `MediaQuery` для tablet MAY использовать 3–4 колонки (Complexity Tracking не требуется — optional в plan).

**Отступы**: `crossAxisSpacing: 12`, `mainAxisSpacing: 12`, horizontal padding 16 — согласовано с карточками home.

**Rationale**: FR-001; типовой phone-first e-commerce layout.

---

## 5. Локальная корзина (без API)

**Decision**: `CartNotifier extends Notifier<Map<String, int>>` (productId → quantity).

**API notifier**:
- `add(productId)` / `increment` / `decrement` / `quantityOf(id)` / `distinctCount`.

**Правила**:
- `decrement` до 0 → `remove` ключа.
- `distinctCount` = `state.keys.length` — для Tab Bar badge (FR-006).

**Rationale**: spec Assumptions — корзина локальна до серверной синхронизации; мгновенный UX (SC-003).

**Alternatives considered**:
- **`POST /cart/items` сразу** — преждевременно без экрана корзины и checkout.
- **shared_preferences** — отложить до фичи персистентной корзины.

**Badge UI**: при `distinctCount == 0` бейдж скрыт (как unread на «Главной»); иначе `Badge` на иконке корзины в `MainShell`.

---

## 6. Карточка товара и QuantityPriceBar

**Decision**: общий виджет `QuantityPriceBar` для:
- нижней кнопки на `ProductCard` (compact, выровнена слева);
- закреплённой панели внизу `ProductDetailScreen` (в `Column` внутри `body`).

**Состояния**:
- `quantity == 0`: одна кнопка «300 ₽ +» (accent background).
- `quantity >= 1`: «− K × 300 ₽ +» на карточке и на детали (на детали — на всю ширину).

**Карточка при quantity ≥ 1**:
- без тени и без overlay количества по центру;
- зарезервированная высота под название/вес — фото не схлопывает текст;
- tap на bar изолирован — не открывает деталь (FR edge case).

**Rationale**: DRY между сеткой и деталью; единый UX ± (spec).

---

## 7. Страница товара и навигация

**Decision**: маршрут `/catalog/product/:id` — **внутри** ветки catalog (Tab Bar виден).

**Загрузка**: `ProductDetailScreen` вызывает `GET /catalog/products/{id}`; fallback — lookup
в уже загруженном списке, если API ещё не вернулся (опциональная оптимизация).

**Галерея**: `PageView` + `PageController`; индикатор точек только при `imageUrls.length > 1`.

**Floating bar**: `Column` в `body` (`Expanded` scroll + `_ProductDetailBar`), **не**
`Scaffold.bottomNavigationBar` — иначе конфликт с Tab Bar `MainShell` и контент не
отображается. `Scaffold.primary: false` для вложенного scaffold.

**Rationale**: FR-007 — стек внутри вкладки; сохранение scroll каталога при back (indexedStack branch).

**Alternatives considered**:
- **`parentNavigatorKey: root`** full-screen — скрывает Tab Bar; spec не требует.

---

## 8. Изображения товаров

**Decision**: пакет **`cached_network_image`**; URL из мока (placeholder-сервис или статические URI).

**Placeholder/error**: серый контейнер + иконка `Icons.image_not_supported_outlined`, цвет `#252A2F`.

**Rationale**: товары с URL (как баннеры на главной); кэш снижает повторные загрузки при scroll back.

**Alternatives considered**:
- **Только assets** — не масштабируется на боевой API с CDN.
- **Image.network без cache** — лишний трафик при пагинации.

---

## 9. Формат цены

**Decision**: утилита `formatPriceRub(int priceRub) → '300 ₽'` в `lib/core/utils/price_formatter.dart`.

**Правило**: целые рубли, неразрывный пробел перед «₽», без копеек в v1.

**Rationale**: FR-012; без добавления `intl` — достаточно для целых цен.

---

## 10. Смена категории и scroll

**Decision**: при `select(categoryId)` — `ScrollController.jumpTo(0)` + reset notifier.

**Rationale**: FR-011; пользователь не остаётся «в середине» чужого списка.

---

## 11. Тестирование

**Decision**:

| Уровень | Объект |
|---------|--------|
| Unit | `CartNotifier`, `ProductsNotifier` (pagination logic), `formatPriceRub` |
| Widget | `ProductCard` (states 0/1/N qty), `QuantityPriceBar`, `CatalogScreen` grid |
| Integration | catalog_flow: scroll → add 2 SKU → badge 2 → open detail → back sync |

**Мок API**: category `fish` — ≥25 товаров для проверки второй страницы.

**Rationale**: конституция III + SC-004.

# Research: Акции и новости

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md)

## 1. API материалов (акции и новости)

**Decision**: REST-эндпоинты под тегом `promotions`, **без** `bearerAuth`:

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/promotions/articles?type={all\|promotion\|news}` | Список опубликованных материалов по фильтру |
| GET | `/promotions/articles/{id}` | Деталь материала с полным HTML-телом |

**Query `type`**: обязательный; значения `all` (все), `promotion` (акции) или `news` (новости).

**Response list**: `{ items: PromotionArticleSummary[] }` — отсортированы по `publishedAt`
убыванию на стороне API/мока.

**Response detail**: `PromotionArticleDetail` — summary-поля + `bodyHtml`.

**Ошибки**: неизвестный `id` или снятый с публикации материал → `404` + `ErrorResponse`.

**Rationale**: публичный контент (FR-015); фильтр по типу соответствует Filter Chips (FR-004);
без пагинации — полный список в одном ответе (Assumptions spec).

**Alternatives considered**:
- **Единый эндпоинт без type + клиентская фильтрация** — лишний трафик при росте контента.
- **GraphQL** — вне стека проекта (REST + OpenAPI).

**Мок**: ≥5 акций и ≥4 новости; 1 материал с эмодзи и списками в HTML; 1 с `<script>` для
теста санитизации; 1 с битым `imageUrl` для заглушки; `id: unpublished-demo` не в списке,
`GET` по id → 404.

---

## 2. Модели Summary vs Detail

**Decision**:
- **PromotionArticleSummary** — для ленты: `id`, `type`, `title`, `publishedAt`, `imageUrl`.
- **PromotionArticleDetail** — для страницы: те же поля + `bodyHtml`.

**Rationale**: лента не тащит длинный HTML; деталь подгружается по клику.

**Alternatives considered**:
- **Единая модель с optional bodyHtml** — проще, но раздувает payload списка.

---

## 3. Filter Chips «Все» / «Акции» / «Новости»

**Decision**: статический список из трёх значений `PromotionType` (`all`, `promotion`, `news`);
виджет `PromotionTypeChips` по образцу `CategoryChips` (`FilterChip`, `AppColors.accent`).

**Состояние**: `selectedPromotionTypeProvider` — default `PromotionType.all` (FR-003).

**Поток**: смена типа → `PromotionsNotifier.reload(type)` → сброс ошибки, загрузка списка;
`ScrollController.jumpTo(0)` при смене чипа (аналог смены категории в каталоге).

**Rationale**: FR-002–004; визуальная согласованность с каталогом (Assumptions).

**Alternatives considered**:
- **TabBar вместо Chips** — spec явно требует Filter Chips.
- **Только два чипа без «Все»** — отклонено: пользователь должен видеть общую ленту по умолчанию.

---

## 4. Лента в одну колонку

**Decision**: `ListView.separated` с `PromotionArticleCard`; padding horizontal 16;
`CachedNetworkImage` для обложки (aspect ratio ~16:9 или фиксированная высота 200).

**Карточка**: `InkWell` / `Material` → `context.push('/promotions/article/$id')`;
метка типа «Акция»/«Новость»; заголовок max 2 lines + ellipsis (edge case).

**Пустое состояние**: `EmptyState(message: AppStrings.nothingFound)` при `items.isEmpty`
без ошибки; чипы остаются над списком (FR-013).

**Rationale**: FR-005–008; переиспользование `cached_network_image` из каталога.

**Alternatives considered**:
- **GridView** — противоречит FR-005 (одна колонка).
- **SliverList в CustomScrollView** — оправдано при sticky chips; для v1 достаточно Column
  (chips + Expanded ListView).

---

## 5. Детальная страница и навигация

**Decision**: маршрут `/promotions/article/:id` — **внутри** ветки promotions (Tab Bar виден).

**Загрузка**: `PromotionDetailScreen` → `GET /promotions/articles/{id}` через repository;
состояния loading / error / data (как `ProductDetailScreen`).

**AppBar**: стандартный primary `AppBar` (как на экранах авторизации);
`leading: IconButton(Icons.arrow_back)` → `context.pop()` (FR-009).

**Контент** (сверху вниз): обложка → `Chip`/метка типа → заголовок → дата
(`formatPublishedDate`) → `PromotionHtmlBody`.

**Rationale**: FR-009–010; паттерн catalog/notifications; indexedStack сохраняет scroll ленты
при pop (FR-014).

**Alternatives considered**:
- **Деталь из кэша списка без второго запроса** — нет `bodyHtml` в summary; нужен API detail.
- **Full-screen через root navigator** — скрывает Tab Bar; spec не требует.

---

## 6. Безопасный HTML и эмодзи

**Decision**: пакет **`flutter_html`** (^3.0.0); виджет `PromotionHtmlBody` с явным whitelist
тегов: `p`, `br`, `strong`, `b`, `em`, `i`, `ul`, `ol`, `li`, `a`.

**Ссылки**: `onLinkTap` → `url_launcher` (`launchUrl`, внешний браузер).

**Санитизация**: теги вне whitelist не рендерятся; `script`, `iframe`, `object`, `style`,
обработчики событий — игнорируются (FR-012). Эмодзи в текстовых узлах отображаются нативно
(UTF-8).

**Стили**: базовые через `Style` / `Style.fromTextStyle` — цвет `#252A2F`, line height 1.5;
без произвольных inline-стилей из HTML (Assumptions spec).

**Rationale**: FR-011–012, SC-004–005; готовый парсер вместо самописного дерева виджетов.

**Alternatives considered**:
- **`WebView` для HTML** — риск XSS, тяжелее, хуже accessibility.
- **Пакет `html` + ручной builder** — полный контроль, но больше кода и тестов.
- **`flutter_widget_from_html`** — альтернатива; `flutter_html` проще для ограниченного whitelist.

---

## 7. Формат даты публикации

**Decision**: утилита `formatPublishedDate(DateTime)` в `lib/core/utils/date_formatter.dart`:
«14 июля 2026» — день + русское название месяца (родительный падеж) + год; **без времени**.

**Реализация**: константный массив из 12 русских месяцев; без зависимости `intl`
(согласовано с подходом `price_formatter` в 004).

**Rationale**: spec acceptance scenario («14 июля 2026»); Assumptions — русская локаль.

**Alternatives considered**:
- **`intl` / `DateFormat`** — корректнее для локалей, но лишняя зависимость для одного формата.

---

## 8. Состояние и PromotionsNotifier

**Decision**: `PromotionsNotifier extends AsyncNotifier<List<PromotionArticleSummary>>`;
`build()` читает `ref.watch(selectedPromotionTypeProvider)` и загружает список для типа.

**Методы**: `reload()` — повторная загрузка (кнопка retry при ошибке).

**UI**: `promotionsAsync.when(loading, error, data)`; при error — `ErrorRetryWidget` или
аналог с текстом на русском; чипы всегда видимы.

**Rationale**: паттерн Riverpod из notifications/catalog; реактивная смена при смене типа.

**Alternatives considered**:
- **Два отдельных кэша (promotion/news)** — избыточно при полной перезагрузке без пагинации.

---

## 9. Изображения обложки

**Decision**: `CachedNetworkImage` + placeholder/error — как в `ProductCard` каталога:
фон `AppColors.background`, иконка `Icons.image_outlined` / `Icons.image_not_supported_outlined`
с 40% opacity.

**Rationale**: FR-016; единый паттерн с 004-product-catalog.

---

## 10. Тестирование

**Decision**:

| Уровень | Объект |
|---------|--------|
| Unit | `formatPublishedDate`, `PromotionType` mapping, mock filter by type |
| Widget | `PromotionTypeChips` (active state), `PromotionArticleCard`, `PromotionHtmlBody` (safe vs script) |
| Integration | promotions_flow: chips → list → detail → back → chip preserved |

**Мок API**: тип `news` — ≥2 элемента; `promotion` — ≥3; деталь `promo-1` содержит `<strong>` и эмодзи.

**Rationale**: конституция III + SC-003–005.

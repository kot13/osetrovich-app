# Research: Наполнение главного экрана

**Дата**: 2026-07-15  
**Фича**: [spec.md](./spec.md)

## 1. Расширение схемы баннера и типизированные ссылки

**Decision**: заменить опциональный `linkUrl` на объект `link` с дискриминатором `type`:

| type | Поля | Действие в приложении |
|------|------|----------------------|
| `none` | — | Нажатие без навигации |
| `external` | `url` | `url_launcher`, `LaunchMode.externalApplication` |
| `promotion` | `targetId` | `context.push('/promotions/article/{id}')` |
| `news` | `targetId` | тот же маршрут детали (`PromotionDetailScreen`) |
| `product` | `targetId` | `context.push('/catalog/product/{id}')` |

**Rationale**: FR-003–FR-005; единый контракт вместо эвристики по URL; 404 на детальном экране уже обрабатывается в 004/006.

**Alternatives considered**:
- **Оставить только `linkUrl`** — невозможно различить внутренние типы без хрупкого парсинга deep link.
- **Отдельные поля `promotionId`, `productId`** — избыточно; один `targetId` + `type` достаточен.

---

## 2. Эндпоинт «Товары недели»

**Decision**: `GET /home/weekly-products` без авторизации; ответ — массив `ProductSummary` (переиспользование схемы каталога).

```yaml
WeeklyProductsResponse:
  required: [items]
  properties:
    items:
      type: array
      items:
        $ref: '#/components/schemas/ProductSummary'
```

**Rationale**: FR-007–FR-009; те же поля, что в каталоге; карточка `ProductCard` переиспользуется без дублирования модели.

**Alternatives considered**:
- **Отдельная схема `WeeklyProduct`** — дублирование `ProductSummary`.
- **Query в `/products?featured=weekly`** — менее явный контракт для главной.

---

## 3. Текущий заказ и статусы

**Decision**: `GET /orders/current` с `bearerAuth`; ответ `{ order: CurrentOrder | null }`.

**OrderStatus** (расширение v0.5.0):

| API value | UI (русский) |
|-----------|--------------|
| `accepted` | Принят |
| `processing` | В обработке |
| `assembly` | Сборка |
| `delivery` | Доставка |
| `completed` | Выполнено |

Маппинг `pending` (legacy из createOrder) → `accepted` на клиенте и в моке при сохранении.

**CurrentOrder** = `Order` + поля оценки:

| Поле | Тип | Описание |
|------|-----|----------|
| ratingState | enum | `not_applicable` \| `pending` \| `submitted` \| `skipped` |
| ratingStars | int? | 1–5, если `submitted` |

**Логика `ratingState`**:
- Статус ≠ `completed` → `not_applicable`
- `completed` + нет оценки и не пропущено → `pending`
- После POST rating → `submitted`
- После POST skip → `skipped`

**Rationale**: FR-010–FR-018; явная машина состояний для UI (оценка vs повтор).

**Alternatives considered**:
- **Два булева `ratingSubmitted` / `ratingSkipped`** — менее однозначно при расширении.
- **`GET /orders?limit=1`** — вне scope «истории»; избыточно для главной.

---

## 4. API оценки заказа

**Decision**:

| Метод | Путь | Body |
|-------|------|------|
| POST | `/orders/{orderId}/rating` | `{ stars: 1..5, comment?: string }` |
| POST | `/orders/{orderId}/rating/skip` | — |

Оба с `bearerAuth`; 404 если заказ не найден или не принадлежит пользователю; 409 если оценка уже отправлена или пропущена.

**UI оценки**: `showModalBottomSheet` с 5 интерактивными звёздами (`Icons.star`), опциональное поле комментария, кнопки «Отправить» / «Отмена». Минимум для отправки — выбранная звезда (1–5).

**Rationale**: spec Assumptions («шкала на этапе планирования»); стандартный e-commerce паттерн; bottom sheet не ломает Tab Bar.

**Alternatives considered**:
- **Отдельный полноэкранный экран** — избыточно для одного действия.
- **Только звёзды без API skip** — не выполняет FR-017.

---

## 5. Повтор заказа (клиент)

**Decision**: без отдельного API; доменная функция `repeatOrderToCart(CurrentOrder, CartNotifier, CatalogRepository)`:

1. Для каждой `OrderLine` — `getProductById`; при успехе `cartNotifier.add(productId, quantity)` (суммирование с существующими).
2. Собрать список недоступных `productId`.
3. Если добавлено ≥ 1 позиции → `context.go('/cart')` + snackbar при частичном успехе.
4. Если 0 → snackbar «Повторить заказ невозможно», корзина без изменений.

Цены берутся из актуального каталога (spec Assumptions).

**Rationale**: FR-019–FR-020; корзина клиентская (005); серверу не нужен дублирующий endpoint.

**Alternatives considered**:
- **`POST /orders/{id}/repeat`** — серверная корзина отсутствует в v1.
- **Использовать snapshot-цены из заказа** — против Assumptions spec.

---

## 6. Мок-данные и хранение заказов

**Decision** в `MockApiClient`:

- `_ordersByUserId: Map<String, List<StoredOrder>>` — после `createOrder` сохранять заказ со статусом `accepted`.
- Предустановленные сценарии для демо-пользователя (по `profile.id`):
  - **active**: заказ в `delivery`
  - **completed-pending-rating**: `completed` + `ratingState: pending`
  - **completed-ready-repeat**: `completed` + `ratingState: skipped`
- `GET /orders/current` → последний неархивированный заказ пользователя (или preset).
- Баннеры: 3+ записи с реальными `imageUrl` (CDN placeholder / URL из мок-товаров), все типы `link`.
- `GET /home/weekly-products` → 6–8 товаров из `_products` (фиксированные id).

**Rationale**: принцип VI; ручная проверка всех user stories без боевого API.

---

## 7. UI главной: композиция и ошибки

**Decision**: `HomeScreen` `ListView` (порядок из spec Assumptions):

```text
1. BannerCarousel (+ error/retry или shrink)
2. HomeContactButton
3. HomeWeeklyProductsSection (скрыт если items пуст)
4. HomeOrderHistorySection (только auth + order != null)
5. AuthPromptBanner (гость)
```

Каждый блок — независимый `AsyncValue` / `FutureProvider`; ошибка одного не блокирует остальные (edge cases spec).

**Карусель**: обернуть `_BannerContent` в `InkWell` / `GestureDetector`; логика ссылок — `BannerLinkHandler` (domain или core/navigation).

**Лента товаров**: `SizedBox(height: ~280)` + `ListView.separated` horizontal; `SizedBox(width: 160, child: ProductCard(...))`.

**Rationale**: FR-006, FR-022; изоляция загрузок; переиспользование `ProductCard`.

---

## 8. Навигация на «Корзину»

**Decision**: `context.go('/cart')` через `go_router` (ветка index 3 `StatefulShellRoute`).

**Rationale**: единый паттерн shell-навигации; не требует проброса `navigationShell` в home.

---

## 9. Тексты UI (app_strings)

| Ключ | Текст |
|------|-------|
| homeWeeklyProductsTitle | Товары недели |
| homeOrderHistoryTitle | История заказов |
| homeOrderStatusAccepted | Принят |
| homeOrderStatusProcessing | В обработке |
| homeOrderStatusAssembly | Сборка |
| homeOrderStatusDelivery | Доставка |
| homeOrderStatusCompleted | Выполнено |
| homeContactOperator | Связаться с оператором |
| homeOrderRatingPrompt | Пожалуйста, оцените ваш заказ, это поможет нам стать лучше! |
| homeOrderRate | Оценить |
| homeOrderSkipRating | Пропустить |
| homeRepeatOrder | Повторить заказ |
| homeOrderRatingTitle | Оценка заказа |
| homeOrderRatingSubmit | Отправить |
| homeOrderRatingCommentHint | Комментарий (необязательно) |
| homeRepeatOrderPartial | Некоторые товары недоступны и не добавлены в корзину |
| homeRepeatOrderFailed | Не удалось повторить заказ: товары недоступны |
| homeBannerLinkFailed | Не удалось открыть ссылку |
| homeLoadError | Не удалось загрузить данные |
| homeRetry | Повторить |

**Rationale**: принцип II; FR-015 дословно.

---

## 10. Тестирование

| Уровень | Объект |
|---------|--------|
| Unit | `orderStatusLabel`, `BannerLink` parsing, `repeatOrderToCart`, rating state guards |
| Widget | `BannerCarousel` tap navigation, `HomeWeeklyProductsSection`, `HomeOrderHistorySection` (статусы, rating/repeat visibility), rating bottom sheet |
| Integration | `home_screen_flow`: banners → product; weekly add to cart; order block → repeat → cart |
| Contract | mock: `getHomeBanners` links, `getWeeklyProducts`, `getCurrentOrder`, rating/skip endpoints |

**Rationale**: конституция III; user stories 1–5.

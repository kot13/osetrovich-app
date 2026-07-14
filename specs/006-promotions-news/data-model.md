# Data Model: Акции и новости

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. PromotionType (тип материала)

| Значение API | UI (чип / метка) | Описание |
|--------------|------------------|----------|
| `all` | «Все» | Все опубликованные материалы (акции и новости) |
| `promotion` | «Акции» / «Акция» | Маркетинговые акции |
| `news` | «Новости» / «Новость» | Новости магазина |

**Валидация**: три значения для фильтра; `promotion` и `news` — тип материала в ответе API;
неизвестное в API → ошибка парсинга / дефект мока.

---

## 2. PromotionArticleSummary (краткая карточка ленты)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Уникальный идентификатор |
| type | PromotionType | да | `promotion` или `news` |
| title | string | да | Заголовок |
| publishedAt | DateTime | да | Дата публикации (ISO 8601) |
| imageUrl | string | да | URI обложечного фото |

**UI (карточка)**:
- `imageUrl` → `CachedNetworkImage` или заглушка (как в карточке товара каталога)
- `type` → метка «Акция» или «Новость»
- `title`: max 2 lines, `TextOverflow.ellipsis`
- `publishedAt` → `formatPublishedDate()`

**Источник**: `GET /promotions/articles?type=...` → `items[]`

**Инвариант**: в списке только опубликованные материалы (`isPublished` не отдаётся клиенту).

---

## 3. PromotionArticleDetail (детальная страница)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Идентификатор |
| type | PromotionType | да | Тип |
| title | string | да | Заголовок |
| publishedAt | DateTime | да | Дата публикации |
| imageUrl | string | да | Обложка |
| bodyHtml | string | да | Основной текст с HTML-разметкой |

**UI**:
- `type` → метка «Акция» или «Новость»
- `bodyHtml` → `PromotionHtmlBody` (whitelist тегов)

**Источник**: `GET /promotions/articles/{id}`

---

## 4. PromotionArticlesResponse (ответ API списка)

| Поле | Тип | Описание |
|------|-----|----------|
| items | List\<PromotionArticleSummary\> | Материалы, отсортированные по `publishedAt` desc |

**Инвариант**: при `type=all` в `items` могут быть и акции, и новости; при `promotion` или
`news` — только соответствующий тип.

---

## 5. PromotionsFeedUiState (клиент, лента)

Представление через `AsyncValue<List<PromotionArticleSummary>>` + отдельно
`selectedPromotionTypeProvider`.

| Аспект | Описание |
|--------|----------|
| loading | Первичная загрузка / смена типа |
| error | `errorMessage` на русском, retry доступен |
| data | Список карточек или пустой → `EmptyState` |
| selectedType | `all` (default), `promotion` или `news` |

**Переходы**:

```text
open screen ──► type=all ──► fetch articles (all)
chip → promotion ──► scroll top ──► fetch articles(promotion)
chip → news ──► scroll top ──► fetch articles(news)
tap card ──► navigate /promotions/article/:id
pop detail ──► preserve selectedType + scroll offset (indexedStack + ScrollController)
chip change ──► jumpTo(0) + reload
```

---

## 6. PromotionDetailUiState (клиент, деталь)

| Поле | Тип | Описание |
|------|-----|----------|
| article | PromotionArticleDetail? | Загруженные данные |
| isLoading | bool | Запрос детали |
| errorMessage | string? | Ошибка / 404 на русском |

**Переходы**:

```text
open ──► loading ──► success (render) | error (message + back)
404 ──► «Материал недоступен» (или AppStrings equivalent)
```

---

## 7. HtmlContent (правила отображения bodyHtml)

| Разрешённые теги | Назначение |
|------------------|------------|
| p, br | Абзацы, переносы |
| strong, b, em, i | Выделение |
| ul, ol, li | Списки |
| a | Гиперссылки (внешний браузер) |

**Запрещено**: script, iframe, object, embed, form, input, style (как активный HTML),
on* атрибуты.

**Эмодзи**: в текстовых узлах UTF-8, без отдельной сущности в модели.

---

## 8. Навигация

| Маршрут | Экран |
|---------|-------|
| `/promotions` | PromotionsScreen (chips + list) |
| `/promotions/article/:id` | PromotionDetailScreen |

**Tab Bar index**: 2 — «Акции».

---

## 9. Диаграмма связей

```text
PromotionType (chip) ──► selectedPromotionTypeProvider
                              │
                              ▼
                    PromotionsNotifier ──► PromotionArticleSummary[] (list)
                              │
                              └── tap id ──► PromotionDetailScreen
                                                    │
                                                    └── GET by id ──► PromotionArticleDetail
                                                                          └── bodyHtml → PromotionHtmlBody
```

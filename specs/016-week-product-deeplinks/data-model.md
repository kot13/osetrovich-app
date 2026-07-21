# Data Model: Признак «Товар недели» и диплинки

**Дата**: 2026-07-21  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/](./contracts/)

## 1. ProductSummary / ProductDetail (изменение)

Добавляется поле к существующим моделям (фича 009):

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| productOfWeek | bool | да | Признак «Товар недели» из ERP → бейдж на карточке |

**UI (карточка)**: `ProductPromoBadges(productOfWeek:, sale:, special:)` — порядок бейджей
см. [research.md](./research.md) §2.

**Источник**: `GET /catalog/products`, `GET /catalog/products/{id}`,
`GET /home/weekly-products`.

**Валидация**: boolean; отсутствие ключа в JSON — ошибка парсинга (required в OpenAPI).

---

## 2. DeepLinkTarget (клиентская модель)

Результат парсинга `osetrovich://` URL; не персистируется.

| Поле | Тип | Описание |
|------|-----|----------|
| path | String | Целевой путь go_router (например `/catalog/product/1000`) |
| categoryId | int? | Если диплинк категории — id для `selectedCategoryIdProvider` |
| isFallback | bool | `true` если исходный URL невалиден → path = `/home` |

**Создание**: `DeepLinkResolver.resolve(String url) → DeepLinkTarget`.

**Инварианты**:
- `path` всегда начинается с `/`
- `categoryId` задан только для `catalog` и `catalog/category/{id}`
- Для `catalog` без category — `categoryId` implicitly `kAllCategoriesId` (0)

---

## 3. DeepLinkRoute (контрактная таблица)

Логическая сущность из [deeplink-schema.yaml](./contracts/deeplink-schema.yaml):

| deeplink_path | go_router_path | id_type |
|---------------|----------------|---------|
| `home` | `/home` | — |
| `catalog` | `/catalog` | — |
| `catalog/category/{id}` | `/catalog` + category side-effect | int |
| `catalog/product/{id}` | `/catalog/product/{id}` | int |
| `promotions` | `/promotions` | — |
| `promotions/articles/{id}` | `/promotions/article/{id}` | string |
| `profile` | `/profile` | — |
| `notifications` | `/home/notifications` | — |
| `notifications/{id}` | `/home/notifications/{id}` | string |

---

## 4. PushDeeplinkPayload (расширение)

Объединённый вход push-навигации (строка payload от AppMetrica):

| Формат | Пример | Обработка |
|--------|--------|-----------|
| Raw URL | `osetrovich://catalog/product/1000` | `DeepLinkResolver` |
| JSON + deeplink | `{ "deeplink": "osetrovich://home" }` | URL приоритетнее type |
| JSON + url | `{ "url": "osetrovich://promotions" }` | то же |
| Legacy JSON | `{ "type": "product", "targetId": "1000" }` | контракт 008 |
| Empty | `""` или `{}` | `/home/notifications` |

Полный контракт: [push-deeplink-v2.yaml](./contracts/push-deeplink-v2.yaml).

---

## 5. Состояние навигации каталога (без изменения схемы)

| Provider | Тип | Роль в диплинках |
|----------|-----|------------------|
| `selectedCategoryIdProvider` | `int` | Устанавливается при `catalog` / `catalog/category/{id}` |
| `productsNotifierProvider` | `ProductsUiState` | `selectCategory(id)` после смены категории |

---

## 6. Связи с существующими сущностями

```text
OpenAPI ProductSummary.productOfWeek
        ↓ parse
ProductSummary.productOfWeek
        ↓
ProductCard → ProductPromoBadges

osetrovich:// URL (статья / push / OS)
        ↓
DeepLinkResolver → DeepLinkTarget
        ↓
DeepLinkNavigation → GoRouter + Riverpod side-effects
```

---

## 7. Ошибки и пустые состояния

| Сценарий | Поведение |
|----------|-----------|
| Неизвестный path диплинка | `DeepLinkTarget(path: '/home', isFallback: true)` |
| `catalog/product/abc` | fallback `/home` |
| `catalog/product/99999` (нет в API) | переход на `/catalog/product/99999`; экран детали — штатное empty/error |
| `promotions/articles/missing` | деталь статьи — штатное empty state |
| `notifications/unknown` | деталь уведомления — штатное empty state |

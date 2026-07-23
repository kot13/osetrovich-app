# Data Model: Штучный товар, цена за кг и старая цена

**Дата**: 2026-07-23  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi-delta.yaml](./contracts/openapi-delta.yaml)

## 1. ProductSummary (обновление)

| Поле | Тип | Обязательное | Было | Стало / UI |
|------|-----|--------------|------|------------|
| id | int | да | ✓ | без изменений |
| name | string | да | ✓ | без изменений |
| weightLabel | string | да | ✓ | без изменений |
| priceRub | int | да | ✓ | текущая цена на кнопке и в панели количества |
| oldPriceRub | int | да | парсинг | **UI**: зачёркнутая на кнопке при `oldPriceRub > priceRub` и qty=0 |
| pricePerKgRub | int | да | **новое** | **UI**: строка «X ₽/кг» при `> 0` под весом на карточке |
| imageUrl | string | да | ✓ | без изменений |
| categoryIds | List\<int\> | да | ✓ | без изменений |
| sale | bool | да | ✓ | бейдж «Акция» |
| special | bool | да | ✓ | бейдж «СПЕЦЦЕНА» |
| productOfWeek | bool | да | ✓ | бейдж «Товар недели» |
| pieceProduct | bool | да | **новое** | парсинг; UI вне scope |

**Источник**: `GET /catalog/products`, `GET /home/weekly-products`

**Валидация клиента**:
- `priceRub >= 0`, `oldPriceRub >= 0`, `pricePerKgRub >= 0` (как в OpenAPI minimum: 0)
- Отображение старой цены: `oldPriceRub > priceRub`
- Отображение цены/кг: `pricePerKgRub > 0`

---

## 2. ProductDetail (обновление)

| Поле | Тип | Обязательное | UI |
|------|-----|--------------|-----|
| pricePerKgRub | int | да | строка под весом при `> 0` |
| pieceProduct | bool | да | парсинг; UI вне scope |
| oldPriceRub | int | да | зачёркнутая на нижней кнопке при qty=0 и `oldPriceRub > priceRub` |

Остальные поля без изменений относительно фичи 009/004.

**Источник**: `GET /catalog/products/{id}`

---

## 3. ProductPriceDisplay (утилита, presentation/domain)

| Функция | Сигнатура | Описание |
|---------|-----------|----------|
| shouldShowStrikethroughOldPrice | `(oldPriceRub, priceRub) → bool` | `oldPriceRub > priceRub` |
| formatPricePerKgRub | `(pricePerKgRub) → String` | «2 400 ₽/кг» через `formatPriceRub` + суффикс |

---

## 4. QuantityPriceBar (обновление props)

| Проп | Тип | Default | Описание |
|------|-----|---------|----------|
| priceRub | int | — | текущая цена (было) |
| oldPriceRub | int | `0` | для зачёркнутой цены на кнопке «добавить» |
| quantity | int | — | было |
| mode | QuantityPriceBarMode | compact | было |

**Правила отображения**:
- `quantity == 0` && `shouldShowStrikethroughOldPrice` → кнопка «[̶s̶t̶a̶r̶a̶y̶a̶] [текущая] +»
- `quantity >= 1` → «− K × [текущая] +» (oldPriceRub игнорируется)
- иначе → «[текущая] +»

---

## 5. ProductCard layout (текстовый блок)

```text
┌─────────────────────┐
│ [фото + бейджи]     │
├─────────────────────┤
│ Название (2 строки) │
│ weightLabel         │
│ pricePerKg (opt.)   │  ← только если pricePerKgRub > 0
├─────────────────────┤
│ QuantityPriceBar    │
└─────────────────────┘
```

`_kProductTextBlockHeight`: 54 → ~70 (см. research §5).

---

## 6. ProductDetailScreen layout (фрагмент)

```text
Галерея
Название
weightLabel
pricePerKg (opt.)     ← если > 0
priceRub (основная)
Описание
─────────────
[QuantityPriceBar]    ← oldPriceRub при qty=0
```

---

## 7. Связи без изменения контракта

| Сущность | Изменение |
|----------|-----------|
| CartNotifier | нет |
| OrderLine | нет |
| ProductPromoBadges | нет |

---

## Миграция в коде

```text
ProductSummary / ProductDetail:
  + pricePerKgRub: int
  + pieceProduct: bool
  fromJson: читать оба поля (required)

QuantityPriceBar:
  + oldPriceRub
  + strikethrough UI при qty=0

ProductCard / ProductDetailScreen:
  + price per kg line
  + pass oldPriceRub to QuantityPriceBar

MockApiClient:
  + pricePerKgRub, pieceProduct во всех товарах
  + матрица комбинаций для тестовых id

price_formatter.dart:
  + formatPricePerKgRub
```

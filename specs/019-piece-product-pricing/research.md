# Research: Штучный товар, цена за кг и старая цена

**Дата**: 2026-07-23  
**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md)

## 1. Новые поля контракта каталога

**Decision**: добавить в `ProductSummary` и `ProductDetail` поля `pricePerKgRub` (`int`,
required) и `pieceProduct` (`bool`, required). Поле `oldPriceRub` уже парсится с фичи 009 —
в этой фиче добавляется **отображение** в UI.

**Rationale**: OpenAPI (`openapi/openapi.yaml`) уже помечает все три поля required в
`ProductSummary` и `ProductDetail`. Порядок внедрения по конституции VI: контракт готов →
моки → модели → UI.

**Alternatives considered**:
- Отложить `pieceProduct` до отдельной фичи корзины — отклонено: поле required в JSON,
  парсинг обязателен; UI-бейдж вне scope.

---

## 2. Условие показа зачёркнутой старой цены

**Decision**: показывать старую цену на кнопке добавления только при `quantity == 0` и
`oldPriceRub > priceRub`. Вынести правило в чистую функцию
`bool shouldShowStrikethroughOldPrice({required int oldPriceRub, required int priceRub})`
в `lib/core/utils/product_price_display.dart` (или рядом с `price_formatter.dart`).

**Rationale**: соответствует spec FR-002/FR-003; единая логика для карточки, главной и
детального экрана; тестируется unit-тестом без виджетов.

**Alternatives considered**:
- Показывать при `oldPriceRub != priceRub` — отклонено: при равенстве нет смысла для
  покупателя.
- Показывать при `oldPriceRub > 0` — отклонено: при `oldPriceRub < priceRub` вводит в
  заблуждение.

---

## 3. Расширение `QuantityPriceBar`

**Decision**: добавить опциональный параметр `oldPriceRub` (default `0` или передавать
явно). При `quantity == 0` и `shouldShowStrikethroughOldPrice` — кнопка `_BarButton`
рендерит `Row` / `FittedBox` с:
1. `Text` старой цены — `TextDecoration.lineThrough`, цвет `AppColors.dark` с пониженной
   непрозрачностью (~0.6), шрифт на 1 pt меньше текущей цены;
2. отступ 4 px;
3. `Text` текущей цены + « +».

При `quantity >= 1` — без изменений (только `priceRub`).

**Rationale**: единый компонент уже используется в `ProductCard`, `ProductDetailScreen` и
косвенно на главной через `ProductCard`; дублирование разметки кнопки не требуется.

**Alternatives considered**:
- Отдельный виджет `AddToCartPriceButton` — отклонено: дублирование compact/detail режимов.
- Зачёркнутая цена в теле карточки — отклонено: spec требует именно на кнопке.

---

## 4. Цена за килограмм — формат и размещение

**Decision**:
- Формат: `formatPricePerKgRub(int pricePerKgRub) => '${formatPriceRub(pricePerKgRub)}/кг'`
  в `price_formatter.dart` (использует существующий неразрывный пробел перед ₽).
- Показ только при `pricePerKgRub > 0`.
- **Карточка (`ProductCard`)**: строка под `weightLabel`, стиль как у веса
  (`fontSize: 12`, `AppColors.dark` 60% opacity).
- **Деталь (`ProductDetailScreen`)**: под `weightLabel`, над основной ценой за единицу;
  `fontSize: 14`, вторичный цвет.

**Rationale**: spec FR-005–FR-007; визуальная иерархия — вес → цена/кг → цена за единицу /
кнопка.

**Alternatives considered**:
- Показывать цену/кг на кнопке — отклонено: перегружает compact-кнопку в 2 колонки.
- Отдельный бейдж — отклонено: не в spec.

---

## 5. Высота текстового блока карточки

**Decision**: увеличить `_kProductTextBlockHeight` с 54 до ~70 px (или использовать
`min` height + дополнительная строка без жёсткого overflow), чтобы вместить опциональную
строку цены за кг без обрезки названия (2 строки) и веса.

**Rationale**: edge case из spec — длинные суммы и дополнительная строка; фиксированная
высота сохраняет выравнивание сетки 2×N.

**Alternatives considered**:
- Динамическая высота карточки — отклонено: ломает ровную сетку каталога.

---

## 6. Признак `pieceProduct`

**Decision**: парсить и хранить в моделях; **отдельный UI не показывать**. Поведение корзины
(`increment`/`decrement` по штукам) не меняется — уже соответствует spec US3.

**Rationale**: spec Assumptions явно исключают бейдж «Штучный товар»; поле готовит данные
для будущих сценариев ERP.

---

## 7. Мок-данные

**Decision**: в `MockApiClient._buildMockProducts` задать матрицу комбинаций (минимум):

| Индекс / id | oldPrice > price | pricePerKgRub | pieceProduct |
|-------------|------------------|---------------|--------------|
| 1000 | да (+150) | 2400 | false |
| 1001 | нет (special) | 0 | false |
| 1002 | нет | 1800 | true |
| икра 2000 | да (+200) | 12000 | false |

Остальным товарам — `pricePerKgRub: 0`, `pieceProduct: false`, `oldPriceRub: priceRub`.

**Rationale**: покрытие SC-001–SC-003 и ручных сценариев quickstart без раздувания мока.

---

## 8. Тестирование

**Decision**:
- **Unit**: `shouldShowStrikethroughOldPrice`, `formatPricePerKgRub`, `fromJson` с новыми
  полями (`product_model_test.dart`).
- **Widget**: `quantity_price_bar_test.dart` (новый) — старая цена на кнопке; обновить
  `product_card_test.dart` — цена/кг, старая цена; `product_detail_screen_test.dart` —
  цена/кг и панель.
- **Integration**: без изменений сценария каталога, если widget-покрытие достаточно.

**Rationale**: конституция III; основной функционал — отображение цен и парсинг полей.

---

## 9. Аналитика и корзина

**Decision**: без изменений. `CartNotifier` хранит только `productId → quantity`; старая
цена и цена/кг не участвуют в расчётах корзины (spec Assumptions).

**Rationale**: scope ограничен каталогом и карточками.

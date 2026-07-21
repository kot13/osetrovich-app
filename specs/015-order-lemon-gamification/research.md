# Research: Геймификация «Делай заказы — получай призы»

**Дата**: 2026-07-21  
**Фича**: [spec.md](./spec.md)

## 1. Источник счётчика лимонов

**Decision**: поле `lemons` (integer, 0–10) в `UserProfile` (`GET /profile/me`). Отдельный
эндпоинт геймификации **не** вводится.

**Rationale**: spec FR-005; единый источник с профилем; `profileNotifierProvider` уже
используется на «Главной» и в «Корзине» (скидка лояльности); без лишнего HTTP-запроса.

**Alternatives considered**:
- **`GET /gamification/lemon-progress`** — дублирование данных, рассинхрон с профилем.
- **Локальный счётчик на клиенте** — нарушает FR-006 (начисление на сервере).

---

## 2. Подарок в корзине — контракт и отображение

**Decision**: при `lemons == 10` в `UserProfile` возвращается опциональный объект
`lemonGift` (`LemonGiftPreview`): `productId`, `name`, `weightLabel`, `imageUrl`. Клиент
добавляет синтетическую строку корзины, когда одновременно:

- пользователь авторизован;
- `profile.lemons == 10`;
- локальная корзина не пуста (`cartNotifierProvider`).

В UI строка отображается с заголовком **«Подарок»** (FR-011); детали (`weightLabel`,
изображение) — из `lemonGift`. Количество и цена — фиксированы: qty 1, цена 0 ₽; без
кнопок +/- (FR-008).

**Rationale**: spec FR-007, FR-008; сервер определяет состав подарка; клиентская корзина
остаётся локальной (как в 005), подарок не входит в `CreateOrderRequest.items` — сервер
добавляет его при `POST /orders`, если у покупателя 10 лимонов.

**Alternatives considered**:
- **Отправлять gift productId в CreateOrderRequest** — риск манипуляции; сервер должен
  решать сам.
- **Только текст «Подарок» без `lemonGift`** — не выполняет FR-008 (нет данных от сервера).
- **Отдельный `GET /cart/preview`** — нет серверной корзины; избыточный эндпоинт.

---

## 3. Начисление и сброс лимонов (мок и контракт)

**Decision**: логика на сервере (в моке — `MockApiClient.createOrder`):

| Состояние до заказа | Действие при успешном `POST /orders` |
|---------------------|--------------------------------------|
| `lemons` 0–9 | `lemons += 1` |
| `lemons == 10` | подарок в составе заказа; после ответа `lemons = 1` |

Клиент после успешного checkout вызывает `profileNotifier.refresh()` для обновления шкалы
на главной (FR-012, SC-002).

**Rationale**: spec FR-006, FR-009, FR-010; неуспешный заказ не меняет `_profile.lemons` в
моке.

**Alternatives considered**:
- **Сброс до 0 после подарка** — противоречит spec («снова 1 лимон»).
- **Инкремент на клиенте** — нарушает server-side source of truth.

---

## 4. Расширение моделей корзины

**Decision**:

| Модель | Изменение |
|--------|-----------|
| `CartLineItemView` | поле `isGift: bool` (default `false`); для подарка `priceRub = 0`, `quantity = 1` |
| `cartDisplayLinesProvider` | **NEW** — `List<CartLineItemView>` = обычные строки + опциональный gift |
| `CartLineTile` | если `isGift` — без `QuantityPriceBar`, badge/заголовок «Подарок», без удаления |
| `order_totals_provider` | подарок не увеличивает `itemsSubtotalRub` (цена 0) |

**Rationale**: минимальное расширение существующей модели; один виджет строки с ветвлением.

**Alternatives considered**:
- **Отдельный `CartGiftTile`** — дублирование layout карточки.
- **Отдельный список подарков** — хуже UX, spec требует позицию в списке товаров.

---

## 5. Блок на «Главной»

**Decision**:

| Компонент | Описание |
|-----------|----------|
| `HomeLemonGamificationCard` | **NEW** — заголовок, ряд из 10 `LemonProgressIcon`, подпись |
| `LemonProgressIcon` | **NEW** — иконка лимона: заполненный `AppColors.accent`, пустой — серый `#BDBDBD` |
| `buildHomeLemonGamificationUiModel` | **NEW** — domain: `lemons` → 10 bool filled |
| `HomeScreen` | вставить карточку **после** `HomeProfileSlot`, **до** `HomeWeeklyProductsSection` |

Условия показа: авторизован + `profileAsync.hasValue` + `!profileAsync.hasError` (FR-001).
При loading/error блок скрыт (как loyalty slot при ошибке профиля).

**Rationale**: spec User Story 4; сосуществование с блоком лояльности (014).

**Alternatives considered**:
- **Объединить с `HomeLoyaltyStatusCard`** — разная семантика и lifecycle; усложняет карточку.
- **Показывать гостям с заглушкой** — противоречит FR-001.

---

## 6. Иконка лимона

**Decision**: виджет `LemonProgressIcon` на базе `CustomPaint` или композиции `Icon` +
овальная форма (простой силуэт лимона 24×24 logical px). Заполненный — `AppColors.accent`
(#FFB400); пустой — `#BDBDBD` (нейтральный серый для неактивного состояния).

**Rationale**: spec требует жёлтые/серые лимоны; accent палитры совпадает с «жёлтым»;
серый — функциональный цвет неактивного шага, не брендовый элемент (см. Complexity Tracking
в plan.md).

**Alternatives considered**:
- **PNG/SVG asset** — избыточно для 10 мелких иконок на шкале; MAY добавиться позже.
- **Emoji 🍋** — непредсказуемый рендер на платформах.

---

## 7. OpenAPI и версия контракта

**Decision**: инкремент `openapi/openapi.yaml` до **v0.12.5**:

- `UserProfile.lemons` (required, 0–10)
- `UserProfile.lemonGift` (nullable, `LemonGiftPreview`)
- `OrderLine.isGift` (optional boolean, default false) — для ответа заказа с подарком

Дельта в `specs/015-order-lemon-gamification/contracts/openapi.yaml`.

**Rationale**: конституция VI — contract-first.

---

## 8. Мок-данные для ручной проверки

**Decision**: в `MockApiClient.ensureProfile` / `_lemonsForPhone`:

| Телефон | lemons | lemonGift |
|---------|--------|-----------|
| `+79004444444` | 0 | null |
| `+79005555555` | 7 | null |
| `+79006666666` | 10 | демо-товар (например, икра 50 г) |
| остальные | 3 | null |

При `createOrder`: обновлять `_profile.lemons` по таблице из §3; при `lemons == 10` добавлять
gift-строку в `OrderLine` с `isGift: true`.

**Rationale**: покрытие quickstart-сценариев (0, прогресс, подарок).

---

## 9. Строки локализации (`app_strings.dart`)

**Decision**: добавить:

| Ключ | Значение |
|------|----------|
| `homeLemonGamificationTitle` | Делай заказы — получай призы |
| `homeLemonGamificationCaption` | Один заказ = Один лимон |
| `cartGiftLabel` | Подарок |

**Rationale**: FR-002, FR-004, FR-011; единый источник текстов.

---

## 10. Тестовая стратегия

**Decision**:

| Уровень | Файлы |
|---------|-------|
| Unit | `home_lemon_gamification_ui_model_test.dart`, `cart_gift_line_test.dart` (правила gift line) |
| Unit (network) | `mock_api_client_test.dart` — lemons в профиле, инкремент/сброс при заказе |
| Widget | `home_lemon_gamification_card_test.dart`, `cart_line_tile_test.dart` (gift variant) |
| Widget | UPDATE `home_screen_test.dart`, `cart_order_summary_test.dart` |
| Integration | UPDATE `home_screen_flow_test.dart`, checkout flow с 10 лимонами |

**Rationale**: конституция III; покрытие SC-001–SC-005.

---

## 11. Обновление профиля после checkout

**Decision**: в `CheckoutNotifier.submit` после успешного `createOrder` вызвать
`ref.read(profileNotifierProvider.notifier).refresh()` (помимо `invalidate(currentOrderProvider)`).

**Rationale**: FR-012 без ожидания ручного pull-to-refresh; шкала и корзина (исчезновение
подарка) обновляются сразу.

**Alternatives considered**:
- **Только pull-to-refresh** — не выполняет SC-002.

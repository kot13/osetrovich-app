# Research: Признак «Товар недели» и диплинки

**Дата**: 2026-07-21  
**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md)

## 1. Поле productOfWeek в доменной модели

**Decision**: добавить `productOfWeek` (`bool`, required) в `ProductSummary` и
`ProductDetail`; парсинг из JSON-ключа `productOfWeek` без переименования.

**Rationale**: OpenAPI уже содержит поле в обеих схемах; endpoint `GET /home/weekly-products`
возвращает `ProductSummary[]` — сортировка (сначала `productOfWeek`, затем `special`) на
стороне сервера; клиент только отображает признак.

**Alternatives considered**:
- Вычислять «товар недели» на клиенте по позиции в списке weekly-products — отклонено:
  бейдж должен быть на карточке и в каталоге вне блока «Товары недели».
- Отдельная модель `WeeklyProduct` — отклонено: дублирование `ProductSummary`.

---

## 2. UI бейджа «Товар недели»

**Decision**: расширить `ProductPromoBadges` параметром `productOfWeek`. Порядок слева
направо: **«Товар недели»** → **«Акция»** → **«СПЕЦЦЕНА»**. Стиль бейджа: фон
`AppColors.dark` (`#252A2F`), текст `AppColors.accent` (`#FFB400`).

**Rationale**: отличается от «Акция» (accent фон) и «СПЕЦЦЕНА» (primary фон); использует
только утверждённую палитру (конституция VIII). Детальный экран товара без бейджей —
согласовано с фичей 009 (признак парсится, UI только на карточке).

**Alternatives considered**:
- Отдельный виджет `ProductOfWeekBadge` — отклонено: три бейджа в одном ряду, единая
  компоновка.
- Бейдж только в блоке «Товары недели» — отклонено: FR-002 требует каталог и главную.

---

## 3. Пакет для входящих диплинков

**Decision**: добавить зависимость **`app_links`** (^6.x) для подписки на
`uriLinkStream` / `getInitialLink()` (custom URL scheme + будущие App Links).

**Rationale**: официально рекомендуемый пакет экосистемы Flutter; поддерживает cold start
и foreground; интегрируется с `GoRouter.go()`.

**Alternatives considered**:
- Только нативные каналы MethodChannel — отклонено: дублирование платформенного кода.
- `uni_links` — устарел, заменён на `app_links`.
- Встроенный deep linking только через go_router без пакета — недостаточен для custom scheme
  на обеих платформах без boilerplate.

---

## 4. Единый резолвер диплинков

**Decision**: класс `DeepLinkResolver` в `lib/core/deeplink/deeplink_resolver.dart`:

| Вход (`osetrovich://…`) | Выход (go_router path) | Побочный эффект |
|-------------------------|------------------------|-----------------|
| `home` | `/home` | — |
| `catalog` | `/catalog` | `selectedCategoryId = kAllCategoriesId` |
| `catalog/category/{id}` | `/catalog` | `selectedCategoryId = int.parse(id)` |
| `catalog/product/{id}` | `/catalog/product/{id}` | — |
| `promotions` | `/promotions` | — |
| `promotions/articles/{id}` | `/promotions/article/{id}` | — |
| `profile` | `/profile` | — |
| `notifications` | `/home/notifications` | — |
| `notifications/{id}` | `/home/notifications/{id}` | — |

Невалидный путь, нечисловой id для category/product, неизвестный host → fallback `/home`.

Парсинг: `Uri.parse(url)`; scheme MUST быть `osetrovich`; path segments после host.

**Rationale**: FR-006, FR-009; единая таблица для статей, push и внешних ссылок; внутренний
маршрут статей (`article` vs `articles`) инкапсулирован в резолвере.

**Alternatives considered**:
- Отдельные обработчики в push и HTML — отклонено: расхождение маршрутов.
- Новый go_router path `/catalog/category/:id` — возможен, но избыточен: каталог уже
  фильтруется через `selectedCategoryIdProvider`; достаточно side-effect при `router.go('/catalog')`.

---

## 5. Навигация по категории из диплинка

**Decision**: `DeepLinkNavigation.navigate(router, ref, target)` перед `router.go(path)`:
если `target.categoryId != null`, вызвать
`ref.read(selectedCategoryIdProvider.notifier).select(target.categoryId!)` и
`ref.read(productsNotifierProvider.notifier).selectCategory(...)`.

**Rationale**: `CatalogScreen` не читает query-параметры; существующий state в Riverpod —
минимальное изменение.

**Alternatives considered**:
- Query ` /catalog?category=5` + рефакторинг `CatalogScreen` — больше scope.
- Extra в GoRouter — не переживает cold start без сериализации.

---

## 6. Push: приоритет URL над JSON

**Decision**: расширить `PushDeeplinkHandler.resolveRouteFromPayloadString`:

1. Trim payload; если строка начинается с `osetrovich://` → `DeepLinkResolver`.
2. Иначе JSON-decode; если есть ключ `deeplink` или `url` со значением `osetrovich://…` →
   резолвер (приоритет над `type`/`targetId`).
3. Иначе legacy JSON `{ type, targetId }` по контракту 008.
4. Пустой/невалидный payload → `/home/notifications` (поведение 011).

**Rationale**: FR-011; обратная совместимость маркетинговых рассылок AppMetrica.

**Alternatives considered**:
- Только URL, удалить JSON — отклонено: ломает фичу 008.
- Отдельный handler для URL — отклонено: дублирование fallback-логики.

---

## 7. Ссылки в HTML статей

**Decision**: в `PromotionHtmlBody.onLinkTap`: если `url.startsWith('osetrovich://')`,
вызвать `DeepLinkNavigation` через `context` + `GoRouter` / `WidgetRef`; иначе —
`launchUrl` (внешний браузер), как сейчас.

**Rationale**: FR-007; минимальное изменение существующего виджета.

**Alternatives considered**:
- `Linkify` с кастомным протоколом — избыточно при уже используемом `flutter_html`.

---

## 8. Регистрация URL scheme (нативная)

**Decision**:

- **Android** (`AndroidManifest.xml`): `intent-filter` с `action VIEW`, `category DEFAULT`,
  `category BROWSABLE`, `data android:scheme="osetrovich"`.
- **iOS** (`Info.plist`): `CFBundleURLTypes` → `CFBundleURLSchemes` = `osetrovich`.

`launchMode="singleTop"` уже задан — повторные диплинки доставляются в существующий activity.

**Rationale**: FR-005; стандартная регистрация custom scheme.

**Alternatives considered**:
- App Links `https://osetrovich.ru/...` — вне scope spec.

---

## 9. Подключение app_links в приложении

**Decision**: `deeplink_navigation_setup.dart` (аналог `push_navigation_setup.dart`):

- `AppLinks().getInitialLink()` при старте после bootstrap.
- `AppLinks().uriLinkStream` для foreground/background.
- Каждый URI → `DeepLinkResolver` → `DeepLinkNavigation.navigate`.

Подключить в `App.build` рядом с `pushNavigationSetupProvider`.

**Rationale**: симметрия с push; единая точка входа для внешних ссылок (US4).

---

## 10. Моки productOfWeek

**Decision**: в `MockApiClient` для части товаров `productOfWeek: true` (например id 1000,
1001 в weekly list и 1–2 позиции в каталоге); остальные `false`. Weekly products endpoint
возвращает товары с mixed flags для тестов бейджа и сортировки.

**Rationale**: FR-004; воспроизводимые сценарии в quickstart.

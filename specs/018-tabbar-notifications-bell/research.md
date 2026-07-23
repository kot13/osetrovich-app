# Research: Колокольчик уведомлений на всех вкладках Tab Bar

**Дата**: 2026-07-22  
**Фича**: [spec.md](./spec.md)

## 1. Размещение UI — переиспользуемый виджет

**Decision**: вынести колокольчик из `HomeScreen` в виджет
`NotificationBellAction` (`lib/features/notifications/presentation/widgets/notification_bell_action.dart`).
Виджет подписан на `unreadCountProvider`, отображает `Icons.notifications_none` и красный
бейдж с числом (как на «Главной» сейчас), по нажатию вызывает навигацию через хелпер
`openNotificationsList(BuildContext)`.

**Rationale**: FR-001, FR-002 — единый визуальный стиль без копипасты в пяти экранах;
соответствие принципу IV (логика навигации вынесена из виджетов в хелпер).

**Alternatives considered**:
- **Дублировать Stack+IconButton в каждом экране** — риск расхождения стиля и поведения.
- **Общий `AppBar` wrapper для всех вкладок** — слишком инвазивный рефакторинг shell;
  не все экраны имеют одинаковую структуру AppBar (профиль гость/авторизован).

---

## 2. Навигация — вложенные маршруты в каждой ветке shell

**Decision**: зарегистрировать одинаковые вложенные маршруты `notifications` и
`notifications/:id` в **каждой** из пяти веток `StatefulShellRoute` в `app_router.dart`:

| Ветка | Корень | Список | Деталь |
|-------|--------|--------|--------|
| Главная | `/home` | `/home/notifications` | `/home/notifications/:id` |
| Каталог | `/catalog` | `/catalog/notifications` | `/catalog/notifications/:id` |
| Акции | `/promotions` | `/promotions/notifications` | `/promotions/notifications/:id` |
| Корзина | `/cart` | `/cart/notifications` | `/cart/notifications/:id` |
| Профиль | `/profile` | `/profile/notifications` | `/profile/notifications/:id` |

Хелпер `openNotificationsList` определяет префикс ветки по `GoRouterState.matchedLocation`
(или `uri.pathSegments.first`) и выполняет `context.push('$prefix/notifications')`.

**Rationale**: FR-004–FR-006 — push внутри текущей ветки shell сохраняет активную вкладку
Tab Bar; `context.pop()` возвращает на корневой экран той же ветки без переключения на «Главную».

**Alternatives considered**:
- **Только `/home/notifications` для всех вкладок** — нарушает FR-005/FR-006: go_router
  переключит ветку на «Главную».
- **Модальный full-screen route с `parentNavigatorKey: root`** — pop вернёт на предыдущую
  вкладку, но Tab Bar может не отражать контекст; сложнее тестировать.
- **Отдельная шестая вкладка «Уведомления»** — против spec и конституции V.

---

## 3. Диплинки и push — без изменений маршрутов

**Decision**: существующие диплинки `osetrovich://notifications` и push-навигация
`/home/notifications/{id}` **не меняются** в рамках фичи 018. `DeepLinkResolver` и
`PushDeeplinkHandler` продолжают вести на ветку `/home`.

**Rationale**: spec Assumptions — push и диплинки вне scope; обратная совместимость с
фичами 016/017; колокольчик — отдельный UX-путь с сохранением контекста вкладки.

**Alternatives considered**:
- **Редирект deeplink на текущую вкладку** — избыточная сложность, не запрошена в spec.

---

## 4. Источник данных бейджа

**Decision**: переиспользовать существующие `unreadCountNotifierProvider` и
`unreadCountProvider` без изменений API. На корневых экранах вкладок (кроме «Главной»,
где уже есть `watch(notificationsNotifierProvider)`) достаточно `watch(unreadCountProvider)`;
при необходимости eager-load списка — только на экранах, где пользователь открывает
уведомления (экран списка сам загружает данные).

**Rationale**: spec Assumptions — единый счётчик уже есть; FR-007 обеспечивается Riverpod
broadcast одного провайдера на все экземпляры `NotificationBellAction`.

**Alternatives considered**:
- **Отдельный провайдер на вкладку** — гарантированный рассинхрон бейджей.

---

## 5. Оформление бейджа

**Decision**: сохранить текущую вёрстку с `HomeScreen` (красный круг, белый текст, `fontSize: 10`).
При рефакторинге вынести цвет бейджа в `AppColors` (например, `badgeError` или переиспользовать
существующий токен), если в палитре есть подходящий — без изменения визуала для пользователя.

**Rationale**: FR-002, SC-005 — визуальный паритет с эталоном «Главной»; принцип VIII —
избегать новых хардкодов `Colors.red` в виджетах.

**Alternatives considered**:
- **Flutter `Badge` widget (как у корзины в Tab Bar)** — другой визуальный стиль; не соответствует
  эталону колокольчика на «Главной».

---

## 6. Профиль — два Scaffold

**Decision**: добавить `actions: [NotificationBellAction()]` в **оба** `AppBar` в
`ProfileScreen` (ветка гостя и авторизованного пользователя).

**Rationale**: FR-001, FR-009 — колокольчик для гостя и авторизованного одинаково.

---

## 7. OpenAPI и моки

**Decision**: изменения REST API **не требуются**. Контракт фичи — навигационный
(`contracts/tab-notifications-routes.yaml`), не OpenAPI.

**Rationale**: принцип VI — нет новых эндпоинтов; фича чисто presentation + routing.

---

## 8. Тестирование

**Decision**:

| Уровень | Файл / область | Что проверяем |
|---------|----------------|---------------|
| Widget | `notification_bell_action_test.dart` | иконка; бейдж при count>0; скрыт при 0; tap → push |
| Widget | `catalog_screen_test.dart`, `promotions_screen_test.dart`, `cart_screen_test.dart`, `profile_screen_test.dart` | наличие колокольчика в AppBar |
| Widget / Router | `app_router_notifications_test.dart` или расширение `main_shell_test.dart` | с «Корзины» tap bell → `/cart/notifications`; pop → `/cart`; Tab Bar на «Корзине» |
| Regression | `home_screen_test.dart` | бейдж по-прежнему работает после выноса виджета |
| Integration | расширение `integration_test/notifications_flow_test.dart` | сценарий с не-home вкладки (опционально P2) |

**Rationale**: принцип III — основной функционал (колокольчик + навигация) покрыт widget и
router тестами; integration — для сквозного сценария US2.

**Alternatives considered**:
- **Только golden-тесты** — не проверяют навигацию и pop-контекст.

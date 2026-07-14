# Research: Уведомления и доработки главной

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md)

## 1. Состояние уведомлений и реактивный badge

**Decision**: `AsyncNotifier<List<AppNotification>>` (`notificationsNotifierProvider`) +
вычисляемый `unreadCountProvider` как `Provider<int>` от списка

**Rationale**:
- После `markRead` / `markAllRead` Notifier обновляет список → badge на «Главной» пересчитывается
  автоматически через `ref.watch` без ручного invalidate.
- Один источник правды вместо разрозненных `getUnreadCount` и списка.
- `GET /notifications/unread-count` остаётся в OpenAPI для cold start / будущего polling;
  в UI после загрузки списка badge берётся из локального состояния.

**Alternatives considered**:
- **Отдельный FutureProvider для badge** — рассинхрон после mark-read без сложного invalidate.
- **Stream из WebSocket** — вне scope; только REST + моки.

---

## 2. Навигация к уведомлениям

**Decision**: вложенные `GoRoute` в ветке `/home` shell:

| Маршрут | Экран |
|---------|-------|
| `/home` | Главная |
| `/home/notifications` | Список уведомлений |
| `/home/notifications/:id` | Деталь уведомления |

Колокольчик: `context.push('/home/notifications')`. Кнопка «Назад» — `context.pop()`.

**Rationale**: соответствует spec Assumptions (вложенная навигация поверх вкладки «Главная»);
Tab Bar остаётся видимым; состояние главной сохраняется в indexedStack.

**Alternatives considered**:
- **Full-screen routes с `parentNavigatorKey`** (как auth) — скрывает Tab Bar; не требуется.
- **Отдельная вкладка** — против spec.

---

## 3. API-контракт уведомлений

**Decision**: расширить OpenAPI:

- `GET /notifications` → `{ items: Notification[] }`
- `GET /notifications/{id}` → `Notification`
- `POST /notifications/{id}/read` → `204`
- `POST /notifications/read-all` → `204`

Все с `bearerAuth`. Схема `Notification`: `id`, `title`, `body`, `createdAt` (ISO 8601),
`isRead`.

**Rationale**: RESTful мутации read; согласовано с существующим `/notifications/unread-count`.

**Мок**: 3–5 уведомлений, 3 непрочитанных; мутации меняют in-memory список.

---

## 4. Индикация прочитано / не прочитано

**Decision**: в списке — жирный заголовок + accent dot / фон карточки для непрочитанных;
прочитанные — обычный вес текста, без dot, цвет `AppColors.text` приглушённый.

**Rationale**: SC-003 — однозначное визуальное различие без лишних иконок.

---

## 5. Бесконечная карусель баннеров

**Decision**: `PageView.builder` с большим `itemCount` (например `10000`) и индексом
`index % banners.length`; `initialPage` в середине диапазона; `viewportFraction: 0.88`,
`padEnds: false` для peek соседних баннеров; `Timer.periodic` — автопрокрутка каждые 5 с.

**Rationale**: без новых зависимостей; активный баннер на всю ширину с видимыми краями
соседних; автопрокрутка по SC-004.

**Alternatives considered**:
- **carousel_slider package** — лишняя зависимость для 3 слайдов.
- **PageView loop без modulo** — на последнем слайде нет «круга».

---

## 6. Отступ шапки — баннер

**Decision**: `Padding(padding: EdgeInsets.only(top: 16))` вокруг `BannerCarousel` на
`HomeScreen` (или внутри карусели сверху).

**Rationale**: простое, предсказуемое решение; соответствует FR-011.

---

## 7. Блок «Связаться»

**Decision**: на «Главной» — `HomeContactButton` (серая баннер-кнопка, как по размеру
`AuthPromptBanner`) + `url_launcher` `tel:+78125645548`. В профиле — `ContactBlock`
(`ListTile` в `LegalSupportSection`).

**Rationale**: тот же паттерн, что планировался в 001-init-app-shell; возврат зависимости
в `pubspec.yaml`.

**Размещение**: между баннерами и `AuthPromptBanner` (или над баннерами — ниже отступа;
решение: после баннеров, перед auth prompt).

---

## 8. Переименование вкладки «Акции»

**Decision**: изменить `AppStrings.tabPromotions` с «Акции и новости» на «Акции»;
обновить widget-тесты shell и promotions screen.

**Rationale**: единая константа для Tab Bar и AppBar; маршрут `/promotions` без изменений.

---

## 9. Тестовая стратегия

| Слой | Что тестируем |
|------|----------------|
| Unit | `NotificationsRepository` (мок ApiClient); unread count после mark read/all |
| Widget | список (read/unread styles), деталь, FAB mark-all скрыт при all read; home carousel + contact |
| Integration | главная → уведомления → деталь → назад; badge уменьшается |

**Инструменты**: `flutter_test`, `integration_test`, `mocktail`.

---

## 10. Загрузка уведомлений при старте

**Decision**: `notificationsNotifierProvider` загружается при первом `watch` (экран списка
или `HomeScreen` для badge). `HomeScreen` вызывает `ref.watch(notificationsNotifierProvider)`
косвенно через `unreadCountProvider`.

**Rationale**: не блокировать cold start; badge появляется после первой загрузки на главной.

---

## 11. Кнопка «Отметить все прочитанным»

**Decision**: `FloatingActionButton.extended` внизу экрана списка; скрыта, если
`unreadCount == 0`. Не размещать в AppBar — заголовок «Уведомления» обрезается на узких экранах.

**Rationale**: FR-003; полный заголовок в шапке; явное действие в зоне большого пальца.

# Data Model: Колокольчик уведомлений на всех вкладках Tab Bar

**Дата**: 2026-07-22  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/](./contracts/)

## 1. Существующие сущности (без изменения схемы)

Фича **не вводит** новых API-моделей. Используются сущности из фич 002/011:

### UnreadCount (бейдж колокольчика)

| Поле | Тип | Источник | Описание |
|------|-----|----------|----------|
| count | int | `GET /v1/notifications/unread-count` → `NotificationBadge.unreadCount` | Число непрочитанных; 0 — бейдж скрыт |

**Клиентское представление**: `unreadCountProvider` → `int` (при loading/error → 0).

### AppNotification (экран списка/детали)

Без изменений — см. `lib/features/notifications/domain/app_notification.dart`.

---

## 2. NotificationBellAction (UI-состояние)

Виджет presentation-слоя; не персистируется.

| Вход | Тип | Описание |
|------|-----|----------|
| unreadCount | int | из `ref.watch(unreadCountProvider)` |

| Отображение | Условие |
|-------------|---------|
| Иконка `notifications_none` | всегда |
| Красный бейдж с текстом `{count}` | `unreadCount > 0` |
| Бейдж скрыт | `unreadCount == 0` |

**Действие**: tap → `openNotificationsList(context)` → push `/{tabRoot}/notifications`.

---

## 3. TabNotificationRoute (навигационная модель)

Логическая привязка корневой вкладки к маршрутам уведомлений. См.
[tab-notifications-routes.yaml](./contracts/tab-notifications-routes.yaml).

| tabRoot | listPath | detailPath |
|---------|----------|------------|
| `/home` | `/home/notifications` | `/home/notifications/{id}` |
| `/catalog` | `/catalog/notifications` | `/catalog/notifications/{id}` |
| `/promotions` | `/promotions/notifications` | `/promotions/notifications/{id}` |
| `/cart` | `/cart/notifications` | `/cart/notifications/{id}` |
| `/profile` | `/profile/notifications` | `/profile/notifications/{id}` |

**Инварианты**:
- Экраны списка и детали — те же `NotificationsListScreen` / `NotificationDetailScreen`.
- `pop` со списка возвращает на `tabRoot`; активная вкладка shell = ветка `tabRoot`.
- Диплинки `osetrovich://notifications/*` по-прежнему резолвятся в `/home/notifications/*`.

---

## 4. Переходы состояния бейджа

```text
User on any tab root screen
  → NotificationBellAction watches unreadCountProvider

User opens notification / mark all read / foreground push refresh
  → unreadCountNotifier.refresh() or local decrement (existing notifiers)
  → unreadCountProvider updates
  → all NotificationBellAction instances rebuild with new count

User taps bell on tab {T}
  → push /{T}/notifications
  → shell branch {T} stays active

User pops from notifications list
  → return to /{T}
```

---

## 5. Затрагиваемые экраны (presentation)

| Экран | Файл | Изменение |
|-------|------|-----------|
| Главная | `home_screen.dart` | заменить inline bell на `NotificationBellAction` |
| Каталог | `catalog_screen.dart` | +`actions: [NotificationBellAction()]` |
| Акции | `promotions_screen.dart` | +`actions` |
| Корзина | `cart_screen.dart` | +`actions` |
| Профиль | `profile_screen.dart` | +`actions` (оба Scaffold) |

Вложенные экраны (product detail, promotion detail, notification detail) — **без** колокольчика
(spec Edge Cases).

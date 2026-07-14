# Data Model: Уведомления и доработки главной

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. AppNotification (Уведомление)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Уникальный идентификатор |
| title | string | да | Заголовок (список + деталь) |
| body | string | да | Полное содержимое (детальный экран) |
| createdAt | DateTime | да | Дата/время создания; отображается на детали |
| isRead | bool | да | `false` = непрочитано |

**Валидация**:
- `title` и `body` не пустые в ответе API.
- `createdAt` парсится из ISO 8601.

**Переходы состояния**:

```text
isRead: false ── open detail / POST .../read ──► isRead: true
isRead: false ── POST .../read-all ──► isRead: true (все элементы)
```

**UI**:
- Список: краткий preview (`title` + укороченный `body` или только `title` + время).
- Деталь: `title`, форматированное `createdAt`, полный `body`.

---

## 2. NotificationsState (UI state списка)

| Поле | Тип | Описание |
|------|-----|----------|
| items | List\<AppNotification\> | Загруженный список |
| isLoading | bool | Первичная загрузка / refresh |
| errorMessage | string? | Сообщение на русском |
| isMarkingAll | bool | Идёт запрос mark-all |

**Вычисляемые**:
- `unreadCount` = `items.where((n) => !n.isRead).length`
- `hasUnread` = `unreadCount > 0`
- `markAllEnabled` = `hasUnread && !isMarkingAll`

---

## 3. NotificationBadge (обновление)

Наследует модель из 001-init-app-shell; источник данных меняется:

| Поле | Тип | Описание |
|------|-----|----------|
| unreadCount | int | Derived из `NotificationsState.unreadCount` |

**UI**: при `unreadCount == 0` badge на колокольчике скрыт.

**Синхронизация**: после `markRead(id)` или `markAllRead()` Notifier обновляет `items` →
badge пересчитывается без отдельного запроса `unread-count`.

---

## 4. TabIndex (обновление)

| Значение | Вкладка | Route |
|----------|---------|-------|
| 0 | Главная | `/home` |
| 1 | Каталог | `/catalog` |
| 2 | **Акции** | `/promotions` |
| 3 | Корзина | `/cart` |
| 4 | Профиль | `/profile` |

---

## 5. HomeLayout (порядок блоков на «Главной»)

Сверху вниз:

1. AppBar (колокольчик + badge)
2. Отступ (`top: 16`)
3. BannerCarousel (3 баннера, infinite loop, peek, auto-scroll 5 s)
4. `HomeContactButton` («Связаться», серая баннер-кнопка)
5. AuthPromptBanner (если не авторизован)

---

## 6. EmptyStateConfig (дополнение)

| Экран | message | actionLabel |
|-------|---------|-------------|
| Уведомления (пусто) | «Уведомлений пока нет» | — |

---

## Диаграмма связей

```text
HomeScreen
  ├── watches unreadCountProvider ◄── notificationsNotifierProvider
  ├── push → /home/notifications
  ├── BannerCarousel (3 items, loop, peek, auto-scroll)
  └── HomeContactButton → tel:+78125645548

NotificationsListScreen
  ├── watches notificationsNotifierProvider
  ├── markAllRead() via FAB (hidden when all read)
  └── push → /home/notifications/:id

NotificationDetailScreen
  ├── markRead(id) on open (if !isRead)
  └── pop → list (updated isRead flags)

MockApiClient
  └── mutable List<AppNotification> _notifications
```

# Data Model: Push в foreground и диплинки уведомлений

**Дата**: 2026-07-22  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/](./contracts/)

## 1. PushIncomingMessage (клиентская модель, NEW)

Нормализованное входящее push-сообщение после парсинга FCM / AppMetrica payload. Не
персистируется.

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| title | String? | нет | Заголовок из `notification.title` |
| body | String? | нет | Текст из `notification.body` |
| deeplink | String? | нет | `osetrovich://notifications/{id}` из `data.deeplink` |
| notificationId | String? | нет | Десятичная строка из `data.notification_id` |

**Инварианты**:
- Хотя бы одно из `deeplink`, `notificationId` SHOULD быть задано для order push.
- Если задан только `notificationId` — навигационный URL =
  `osetrovich://notifications/{notificationId}`.
- `title` / `body` MUST NOT участвовать в построении маршрута.

**Создание**: `PushIncomingMapper.fromFcm(RemoteMessage)` / `fromPayloadString(String?)`.

---

## 2. FcmOrderPushData (контрактная сущность)

Логическая структура order push от бэкенда. См. [fcm-order-push.yaml](./contracts/fcm-order-push.yaml).

| Блок | Поле | Тип | Обязательность |
|------|------|-----|----------------|
| notification | title | string | да (для отображения) |
| notification | body | string | да (для отображения) |
| data | deeplink | string (URI) | MUST при order push |
| data | notification_id | string (decimal) | MUST при order push |

**Правило согласованности**: id в `deeplink` MUST совпадать с `notification_id`.

---

## 3. PushDeeplinkPayload v3 (расширение)

Расширение [push-deeplink-v2.yaml](../016-week-product-deeplinks/contracts/push-deeplink-v2.yaml):

| Формат | Пример | Маршрут |
|--------|--------|---------|
| JSON order push | `{"deeplink":"osetrovich://notifications/42","notification_id":"42"}` | `/home/notifications/42` |
| JSON только id | `{"notification_id":"42"}` | `/home/notifications/42` |
| Raw URL | `osetrovich://notifications/42` | `/home/notifications/42` |
| Legacy | `{"type":"notification","targetId":"42"}` | `/home/notifications/42` |
| Empty | `""` | `/home/notifications` |

Полный контракт: [push-deeplink-v3.yaml](./contracts/push-deeplink-v3.yaml).

---

## 4. AppNotification / UnreadCount (без изменения схемы)

Существующие модели из фич 002/011:

- **AppNotification** — `id`, `title`, `body`, `createdAt`, `isRead`; источник API.
- **UnreadCount** — integer с `GET /v1/notifications/unread-count`; бейдж колокольчика.

**Переходы при foreground push**:

```text
PushIncomingMessage received (foreground)
  → refresh UnreadCount (API)
  → reload Notifications list (API)
  → optional show MaterialBanner

User taps banner / system notification
  → PushDeeplinkHandler → /home/notifications/{id}
  → NotificationDetailScreen
  → markRead (POST /read) if unread
  → decrement UnreadCount

GET detail / list missing id (404 or absent)
  → UI: «Уведомление не найдено»
```

---

## 5. ForegroundHandlerState (in-memory)

| Поле | Тип | Описание |
|------|-----|----------|
| lastReceivedAt | DateTime? | Время последнего foreground push (debug) |
| pendingBanner | PushIncomingMessage? | Текущий баннер (если показан) |

Управляется `PushForegroundHandler`; не персистируется.

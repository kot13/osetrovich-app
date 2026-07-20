# Data Model: Mobile API 0.10.0 — push-токены и реальные уведомления

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. AppNotification (существующая доменная модель)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Идентификатор из БД (например `"42"`), не stub `n1` |
| title | string | да | Заголовок (тип события кодируется текстом) |
| body | string | да | Текст; может содержать `\n` |
| createdAt | DateTime (UTC) | да | ISO8601 из API |
| isRead | boolean | да | Прочитано ли in-app |

**Источник**: `GET /notifications`, `GET /notifications/{id}`.

**Правила**:
- Не парсить номер заказа или тип из `title`/`body` (кроме явного UI-правила для CTA оценки
  по точному совпадению `title == «Заказ доставлен»`).
- `copyWith(isRead:)` для оптимистичного UI в notifier (опционально).

---

## 2. PushTokenRequest (DTO, новый)

| Поле | Тип (JSON) | Обязательное | Описание |
|------|------------|--------------|----------|
| token | string | да | FCM registration token |
| platform | string | да | `ios` или `android` |

**Источник**: клиент → `PUT /profile/push-token`.

**Ответы**:
- `204` — успех
- `401` — сессия недействительна
- `422` — пустой или невалидный `token`

---

## 3. UnreadCountResponse (DTO, существующий)

| Поле | Тип (JSON) | Обязательное | Описание |
|------|------------|--------------|----------|
| unreadCount | integer | да | Число непрочитанных in-app уведомлений |

**Источник**: `GET /notifications/unread-count`.

**Связь с UI**: бейдж на колокольчике главной (`HomeScreen`).

---

## 4. ProfilePreferences (существующая)

| Поле | Тип | Описание |
|------|-----|----------|
| pushEnabled | boolean | Желание пользователя получать push |

**Источник**: `GET/PATCH /profile/preferences`.

**Переходы** (клиент):

```text
pushEnabled: false → true
  → запрос разрешения ОС
  → PATCH preferences
  → syncPushEnabled (AppMetrica)
  → registerPushToken

pushEnabled: true → false
  → PATCH preferences
  → syncPushEnabled(false)
  → (опционально) очистить локальный lastRegisteredToken
```

---

## 5. PushRegistrationState (in-memory, клиент)

| Поле | Тип | Описание |
|------|-----|----------|
| lastRegisteredToken | string? | Последний успешно отправленный на сервер token |
| lastRegisteredPlatform | string? | `ios` / `android` |
| isRegistering | boolean | Защита от параллельных PUT |

**Жизненный цикл**:

```text
[login / tokenRefresh / pushEnabled=true]
  → obtain FCM token from PushService
  → if token != lastRegistered → PUT /profile/push-token → 204 → save lastRegistered
  → on 401 → session flow (фича 010)
  → on 422 → log, skip (не блокировать UI)
```

---

## 6. NotificationAction (доменный хелпер, новый)

| Значение | Условие | UI |
|----------|---------|-----|
| none | любой другой title | только текст |
| rateOrder | `title == «Заказ доставлен»` | CTA «Оценить заказ» |

**Навигация rateOrder**:
1. `GET /orders/current`
2. если `ratingState == pending` → `OrderRatingSheet`
3. иначе — snackbar «Оценка недоступна» / скрыть CTA

---

## 7. NotificationsCacheMigration (локальная метка версии)

| Ключ (shared_preferences) | Тип | Описание |
|---------------------------|-----|----------|
| notifications_cache_version | int | Текущая версия схемы = `2` (API 0.10.0) |

**Правило**: при `stored < 2` — invalidate `notificationsNotifierProvider` и
`unreadCountNotifierProvider`; записать `2`.

---

## 8. Связи сущностей

```text
AuthSession ──► PushTokenRegistrationService ──► PUT /profile/push-token
       │
       ├──► GET /notifications ──► List<AppNotification>
       └──► GET /notifications/unread-count ──► unreadCount (badge)

AppNotification (title «Заказ доставлен») ──► NotificationAction.rateOrder
       └──► CurrentOrder.ratingState ──► OrderRatingSheet
```

---

## 9. Типовые title/body с сервера (справочно, не парсить)

| Событие | title | body (пример) |
|---------|-------|-----------------|
| Заказ принят | Заказ принят | Ваш заказ принят в обработку. |
| На доставке | Заказ на доставке | Многострочный состав + сумма |
| Водитель | Водитель назначен | Имя водителя |
| Доставлен | Заказ доставлен | Призыв оставить отзыв… |

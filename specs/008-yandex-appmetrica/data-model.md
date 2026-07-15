# Data Model: Интеграция Yandex AppMetrica

**Дата**: 2026-07-15  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/](./contracts/)

## 1. FunnelEvent (доменная модель клиента)

Представление шага воронки до отправки в SDK. Не персистируется локально (буфер — в AppMetrica SDK).

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| name | FunnelEventName | да | Имя события (контракт) |
| timestamp | DateTime | да | Время на клиенте (SDK добавляет своё) |
| sessionId | string? | нет | Заполняется SDK AppMetrica автоматически |
| productId | string? | для `product_view`, `add_to_cart` | ID товара |
| orderId | string? | для `order_success` | ID заказа |
| orderTotalRub | int? | для `order_success` | Сумма заказа в рублях |

### FunnelEventName (enum)

| Значение | Контракт `event` | UI-триггер |
|----------|------------------|------------|
| appLaunch | `app_launch` | Старт приложения |
| catalogView | `catalog_view` | Вкладка «Каталог» |
| productView | `product_view` | Карточка товара |
| addToCart | `add_to_cart` | Добавление в корзину |
| checkoutStart | `checkout_start` | Непустая «Корзина» |
| orderSuccess | `order_success` | Успешное оформление |

**Валидация**:
- `productId` MUST NOT быть пустым для `product_view` / `add_to_cart`.
- `orderId` и `orderTotalRub` обязательны для `order_success`.
- PII-поля MUST NOT присутствовать.

**Клиент**: `lib/core/analytics/analytics_events.dart`

---

## 2. AnalyticsUserContext

Контекст пользователя для AppMetrica User Profile (не REST API).

| Поле | Тип | Описание |
|------|-----|----------|
| userId | string? | Внутренний ID пользователя (из сессии); null для гостя |
| pushEnabled | bool | Зеркало `UserProfile.pushEnabled` |

**Переходы**:
- Login success → `userId` установлен
- Logout → `userId` сброшен
- Toggle push в профиле → `pushEnabled` обновлён + синхронизация push SDK

**Клиент**: обновление через `AnalyticsService.setUserId` и `PushService.syncPreferences`

---

## 3. CrashReport (внешняя сущность AppMetrica)

Модель не дублируется в клиенте — формируется SDK. Для документации:

| Поле | Источник | Описание |
|------|----------|----------|
| crashTime | AppMetrica | Время сбоя |
| appVersion | AppMetrica | Версия из `pubspec` / build |
| platform | AppMetrica | `android` / `ios` |
| stackTrace | AppMetrica | Стек вызовов |

**Клиент**: без отдельного класса; включено через `AppMetricaConfig.flutterCrashReporting`.

---

## 4. PushToken (SDK)

| Поле | Тип | Описание |
|------|-----|----------|
| token | string | FCM/APNs токен через AppMetrica |
| transport | string | `fcm` / `apns` |
| updatedAt | DateTime | Время получения из `tokenStream` |

**Персистенция**: только в AppMetrica; клиент не сохраняет в `shared_preferences`.

**Клиент**: `AppMetricaPushService` — listener `AppMetricaPush.tokenStream`

---

## 5. PushDeeplink (payload push)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| type | PushTargetType | да | Тип целевого экрана |
| targetId | string? | при `order`, `promotion`, `notification`, `product` | ID сущности |

### PushTargetType (enum)

| Значение | Маршрут | Примечание |
|----------|---------|------------|
| home | `/home` | Общее сообщение |
| order | `/home` | Блок заказа на главной; `targetId` — orderId для будущего scroll/highlight |
| promotion | `/promotions/article/{targetId}` | Акция |
| notification | `/home/notifications/{targetId}` | In-app деталь уведомления |
| product | `/catalog/product/{targetId}` | Товар |

**Валидация**:
- Неизвестный `type` → fallback `/home`
- Отсутствующий `targetId` при обязательном типе → fallback `/home`

**Клиент**: `lib/core/push/push_deeplink_handler.dart`

---

## 6. Связи с существующими сущностями

```text
UserProfile.pushEnabled ──► PushService.syncPreferences()
                         └──► AppMetrica User Profile attribute push_enabled

AuthSession.userId ──► AnalyticsService.setUserProfileID()

CartNotifier ──► AnalyticsService.reportAddToCart(productId)

CheckoutNotifier ──► AnalyticsService.reportOrderSuccess(orderId, total)

Order (cart) ──► orderId, total для order_success
ProductSummary.id ──► productId в событиях каталога
```

---

## 7. Состояния push-интеграции

```text
[Не инициализирован]
    │ AppMetrica.activate + AppMetricaPush.activate
    ▼
[SDK активен]
    │ pushEnabled=false ИЛИ permission denied
    ▼
[Push приостановлен] ──toggle on + permission granted──► [Push активен]
    │ logout / deactivate
    ▼
[Токен не используется для рассылки]
```

**Правило FR-010**: рассылка из панели AppMetrica MUST таргетировать сегмент
`push_enabled=true` (настраивается в консоли) + OS permission на устройстве.

# Data Model: Инициализация приложения

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. CatalogCategory (Категория каталога)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Уникальный идентификатор (`all`, `fish`, `caviar`, …) |
| name | string | да | Отображаемое название на русском («Рыба», «Все», …) |
| sortOrder | int | да | Порядок в Filter Chips |

**Валидация**:
- `name` не пустой.
- Первая категория с `id: "all"` и `name: "Все"` всегда присутствует в ответе API.

**Связи**: используется на экране «Каталог»; выбранная категория хранится в UI-state (`selectedCategoryId`).

---

## 2. AuthSession (Сессия авторизации)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| accessToken | string | да | JWT access token |
| refreshToken | string | да | JWT refresh token |
| expiresAt | DateTime | да | Момент истечения access token |
| phone | string | да | Номер в формате E.164 (+79XXXXXXXXX) |

**Состояния (state machine)**:

```text
unauthenticated → smsRequested(phone) → authenticated(session)
                      ↑___________|  (back from sms screen)
authenticated → unauthenticated (logout, future)
```

**Хранение**:
- `accessToken`, `refreshToken` → `flutter_secure_storage`
- `phone`, `expiresAt` → в памяти провайдера / optional secure

**Влияние на UI**:
- `unauthenticated`: профиль — заглушка, главная — блок «Авторизуйтесь»
- `authenticated`: заглушки скрыты; профиль — placeholder «Вы вошли» (вне scope деталей)

---

## 3. SmsAuthFlow (Поток SMS-авторизации, UI state)

| Поле | Тип | Описание |
|------|-----|----------|
| phone | string? | Введённый номер |
| step | enum | `phoneInput` \| `smsCodeInput` |
| resendSecondsRemaining | int | 0–60; 0 = кнопка «Повторить запрос» активна |
| isLoading | bool | Идёт сетевой запрос |
| errorMessage | string? | Сообщение на русском |

**Переходы**:
- `phoneInput` + успешный request → `smsCodeInput`, `resendSecondsRemaining = 60`
- Таймер тикает каждую секунду до 0
- Resend при 0 → снова request, сброс таймера на 60
- Успешный verify → `AuthSession`, очистка flow state
- Back → `phoneInput`, phone сохранён

---

## 4. Banner (Баннер главной)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Идентификатор |
| imageUrl | string | да | URL изображения |
| linkUrl | string | нет | Ссылка при тапе (будущее) |
| sortOrder | int | да | Порядок в карусели |

---

## 5. NotificationBadge (Счётчик уведомлений)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| unreadCount | int | да | ≥ 0; отображается на колокольчике |

**UI**: при `unreadCount == 0` badge скрыт или показывает «0» — решение: скрывать при 0.

---

## 6. TabIndex (Навигация Tab Bar)

| Значение | Вкладка | Route |
|----------|---------|-------|
| 0 | Главная | `/home` |
| 1 | Каталог | `/catalog` |
| 2 | Акции и новости | `/promotions` |
| 3 | Корзина | `/cart` |
| 4 | Профиль | `/profile` |

**Программный переход**: корзина → каталог: `context.go('/catalog')` или `shell.goBranch(1)`.

---

## 7. EmptyStateConfig (Конфигурация пустых состояний)

Не персистентная сущность; константы в `app_strings.dart`:

| Экран | message | actionLabel | actionTarget |
|-------|---------|-------------|--------------|
| Корзина | «В корзине пока пусто» | «Перейти в каталог» | `/catalog` |
| Профиль (guest) | «Необходима авторизация» | «Войти» | `/auth/phone` |
| Каталог | «Ничего не нашлось» | — | — |
| Акции | «Ничего не нашлось» | — | — |

---

## 8. API Error (Ошибка API)

| Поле | Тип | Описание |
|------|-----|----------|
| code | string | Машинный код (`INVALID_CODE`, `NETWORK_ERROR`, …) |
| message | string | Сообщение на русском для пользователя |

**Маппинг HTTP**:
- 400 + `INVALID_CODE` → «Неверный код»
- 400 + `INVALID_PHONE` → «Некорректный номер телефона»
- 5xx / timeout → «Не удалось выполнить запрос. Попробуйте ещё раз»

---

## Диаграмма связей

```text
AppStartup
  ├── loads CatalogCategory[]
  ├── loads Banner[]
  └── loads NotificationBadge

AuthSession ── affects ── Home (auth banner), Profile (guest vs auth)

CatalogScreen
  ├── CatalogCategory[] (chips)
  └── selectedCategoryId (local state)

SmsAuthFlow ── on success ──► AuthSession
```

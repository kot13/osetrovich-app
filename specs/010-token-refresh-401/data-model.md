# Data Model: Автоматическое обновление токена при 401

**Дата**: 2026-07-20  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. AuthSession (существующая доменная модель)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| accessToken | string | да | JWT для заголовка `Authorization: Bearer` |
| refreshToken | string | да | Токен продления сессии |
| expiresAt | DateTime | да | Срок действия access (сейчас `neverExpiresAt` на клиенте) |
| phone | string | да | Телефон пользователя для UI и аналитики |

**Источник**: вход по СМС, восстановление из `SecureTokenStorage`, обновление после refresh.

**Переходы состояния**:

```text
[нет сессии] --login/restore--> [авторизован]
[авторизован] --refresh OK--> [авторизован] (новые токены)
[авторизован] --refresh FAIL / logout--> [нет сессии]
```

---

## 2. TokenResponse (DTO, существующая)

| Поле | Тип (JSON) | Обязательное | Описание |
|------|------------|--------------|----------|
| access_token | string | да | Новый access JWT |
| refresh_token | string | да | Новый refresh (или тот же — по ответу сервера) |
| expires_in | integer | да | TTL access в секундах |
| token_type | string | да | Всегда `Bearer` |

**Источник**: `POST /auth/sms/verify`, `POST /auth/refresh`.

**Правила после refresh (клиент)**:
- Перезаписать оба токена в `SecureTokenStorage`
- Обновить `AuthSession` в `authSessionProvider` (access + refresh)
- `phone` не меняется при refresh

---

## 3. SecureTokenStorage (существующая)

| Ключ | Значение | Описание |
|------|----------|----------|
| access | string? | Access JWT |
| refresh | string? | Refresh JWT |

**Операции**: `saveTokens`, `readAccessToken`, `readRefreshToken`, `clear`.

**Инвариант**: при `onSessionExpired` оба ключа удаляются; `authSessionProvider.state = null`.

---

## 4. TokenRefreshState (логика интерцептора, in-memory)

Не персистируется; живёт в экземпляре `TokenRefreshInterceptor`.

| Поле | Тип | Описание |
|------|-----|----------|
| refreshInFlight | Future\<TokenResponse\>? | Текущая операция refresh (дедупликация) |
| isRefreshing | bool | Вычисляемо: `refreshInFlight != null` |

**Жизненный цикл «волны» 401**:

```text
1. Запрос A → 401 → start refresh (refreshInFlight = future)
2. Запрос B → 401 → await тот же refreshInFlight
3. Refresh OK → save tokens → retry A, B с новым access → refreshInFlight = null
4. Refresh FAIL → onSessionExpired → reject A, B с UNAUTHORIZED
```

---

## 5. ApiException (расширение использования)

| Поле | Тип | Описание |
|------|-----|----------|
| code | string | Машинный код: `UNAUTHORIZED`, `NETWORK_ERROR`, `NOT_FOUND`, … |
| message | string | **Русскоязычное** сообщение для UI |

**Коды, релевантные фиче**:

| code | Когда | message (пример) |
|------|-------|------------------|
| UNAUTHORIZED | 401 после неуспешного refresh / нет refresh | «Сессия истекла. Войдите снова.» |
| NETWORK_ERROR | таймаут, нет сети | «Нет соединения с интернетом» |
| SESSION_EXPIRED | alias/logout side-effect | то же, что UNAUTHORIZED для UI |

**Правило UI**: виджеты MUST показывать `ApiException.message` или `AppStrings.*`, **NEVER**
`error.toString()` для сетевых исключений.

---

## 6. Исключённые пути (не запускают auto-refresh)

| Path prefix | Причина |
|-------------|---------|
| `/auth/sms/request` | Публичный вход |
| `/auth/sms/verify` | Публичный вход |
| `/auth/refresh` | Сам refresh; 401 → logout |
| Запрос с `extra['skipTokenRefresh'] == true` | Служебный вызов refresh |

---

## 7. Колбэки Dio (инъекция)

| Колбэк | Сигнатура | Вызывается когда |
|--------|-----------|------------------|
| onTokensRefreshed | `Future<void> Function(TokenResponse)` | Успешный `POST /auth/refresh` |
| onSessionExpired | `Future<void> Function()` | Неуспешный refresh, нет refresh-токена, 401 на `/auth/refresh` |

**Связь с провайдерами**: реализация делегирует в `AuthSessionNotifier` (`setSession` /
`clearSession` с сохранением phone при refresh).

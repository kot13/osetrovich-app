# Data Model: Профиль пользователя

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. UserProfile (Профиль пользователя)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Идентификатор пользователя |
| name | string | да | Отображаемое имя |
| phone | string | да | Телефон `+7XXXXXXXXXX` |
| email | string? | нет | Email (может быть null) |
| emailVerified | bool | да | `true` только после verify |
| pushEnabled | bool | да | Настройка push (дублирует preferences) |

**Валидация**:
- `name`: 1–100 символов, не только пробелы.
- `phone`: pattern `^\+7\d{10}$`.
- `email`: формат email при наличии.

**Переходы**:

```text
name ── PATCH /profile/me ──► name (updated)
phone ── POST phone/verify ──► phone (updated)
email null ── POST email/verify ──► email + emailVerified: true
email set ── POST email/verify (new) ──► email + emailVerified: true
pushEnabled ── PATCH /profile/preferences ──► pushEnabled
```

---

## 2. ProfilePreferences

| Поле | Тип | Описание |
|------|-----|----------|
| pushEnabled | bool | Желание получать push |

**UI**: SwitchListTile на ProfileScreen; синхронизация с `GET/PATCH /profile/preferences`.

---

## 3. VerificationChallenge (смена телефона / email)

| Поле | Тип | Описание |
|------|-----|----------|
| type | enum | `phone_change` \| `email_verify` |
| target | string | Новый телефон или email |
| retryAfterSeconds | int | 60 по умолчанию |
| expiresAt | DateTime? | опционально в моке |

**API**:
- Request: `POST .../request` → `{ retryAfterSeconds }`
- Verify: `POST .../verify` → `{ code }` + target

**Ошибки** (ErrorResponse.code):
| code | Сценарий |
|------|----------|
| `invalid_code` | Неверный код |
| `phone_taken` | Телефон занят |
| `email_taken` | Email занят |
| `invalid_email` | Некорректный формат |

---

## ~~4. LocalAuthSettings~~ (снято с scope)

Локальный PIN, биометрия и app lock **не реализуются**. Сессия JWT бессрочна на клиенте
до явного выхода.

---

## 4. AuthSession (клиент)

| Поле | Тип | Описание |
|------|-----|----------|
| accessToken | string | JWT access |
| refreshToken | string | JWT refresh |
| phone | string | Телефон из сессии |
| expiresAt | DateTime | `9999-12-31` — клиент не истекает сессию |
| isExpired | bool | Всегда `false` |

**Хранилище**: `flutter_secure_storage` (ключи access/refresh token).

---

## 5. ProfileUiState

| Поле | Тип | Описание |
|------|-----|----------|
| profile | UserProfile? | Загруженный профиль |
| isLoading | bool | Первичная загрузка |
| isSavingName | bool | PATCH name in flight |
| errorMessage | string? | Ошибка на русском |

---

## 6. ProfileScreenLayout (порядок блоков)

### Авторизованный пользователь

1. AppBar «Профиль»
2. Поле «Имя» (редактируемое)
3. Поле «Email» (+ статус «Подтверждён» / «Не подтверждён», tap → verify flow)
4. Поле «Телефон» (tap → change flow)
5. Секция «Безопасность»: Switch «Push-уведомления»
6. ContactBlock «Связаться» (`ListTile`, как оферта)
7. Ссылка «Оферта и политика конфиденциальности»
8. SocialLinksRow (VK, OK — FA Brands, `#252A2F`)
9. Кнопка «Выйти» (заливка `#FFB400`, текст `#252A2F`)

### Неавторизованный

1. AppBar «Профиль»
2. EmptyState «Необходима авторизация» + «Войти»
3. ContactBlock, оферта, соцсети (без персональных полей)

---

## Диаграмма связей

```text
ProfileScreen
  ├── watches profileNotifierProvider ◄── ProfileRepository ◄── ApiClient
  ├── watches authSessionProvider
  ├── push → /profile/change-phone, /profile/email
  ├── ContactBlock (core/widgets), SocialLinksRow, LegalLink
  └── logout → AuthRepository.logout + clear session

ChangePhoneFlow
  ├── POST /profile/phone/request
  └── POST /profile/phone/verify → refresh profile

EmailVerifyFlow
  ├── POST /profile/email/request
  └── POST /profile/email/verify → refresh profile

MockApiClient
  ├── mutable UserProfile _profile per session
  └── ensureProfile(phone) при restore session
```

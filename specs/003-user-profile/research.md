# Research: Профиль пользователя

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md)

## 1. API профиля и верификации

**Decision**: REST-эндпоинты под тегом `profile` с `bearerAuth`:

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/profile/me` | Текущий профиль |
| PATCH | `/profile/me` | Обновление имени |
| POST | `/profile/phone/request` | Запрос СМС на новый номер |
| POST | `/profile/phone/verify` | Подтверждение смены телефона |
| POST | `/profile/email/request` | Запрос кода на email |
| POST | `/profile/email/verify` | Подтверждение email |
| GET | `/profile/preferences` | pushEnabled |
| PATCH | `/profile/preferences` | pushEnabled |

**Rationale**: единый префикс `/profile`; отделение preferences от PII; согласовано с
auth (`/auth/sms/*`) по формату кодов и `retryAfterSeconds: 60`.

**Alternatives considered**:
- **`/users/me`** — менее явная привязка к вкладке «Профиль».
- **Один PATCH для всех полей** — email/phone требуют двухшаговой верификации.

**Мок**: профиль привязан к JWT-сессии; коды `123456` (телефон/email); email
`taken@example.com` → 409; телефон `+79999999999` → 409.

---

## 2. Смена телефона vs auth-flow

**Decision**: отдельные эндпоинты `/profile/phone/*` (не reuse `/auth/sms/*`), UI —
копия паттерна `PhoneInputScreen` + `SmsCodeScreen` с общим виджетом кода.

**Rationale**: смена телефона требует уже авторизованной сессии; семантика и ошибки
(номер занят) отличаются от первичного входа.

**Alternatives considered**:
- **Reuse `/auth/sms/request` с флагом** — размывает контракт login vs change.

---

## 3. Email-верификация

**Decision**: двухшаговый flow: ввод email → экран 6-значного кода; таймер 60 с;
валидация RFC5322 упрощённая (regex `^[^\s@]+@[^\s@]+\.[^\s@]+$`).

**Rationale**: UX идентичен СМС (FR-015); пользователь уже знаком с паттерном.

---

## 4. Локальный PIN и биометрия

**Decision**: пакет **`local_auth`** + **`flutter_secure_storage`**:

- PIN: 6 цифр; хранится SHA-256 hash (не plaintext) в secure storage.
- Ключи: `local_pin_hash`, `biometric_enabled`.
- Биометрия: `LocalAuthentication.authenticate()` перед включением toggle;
  `local_auth` sticky session не используем — проверка при каждом unlock.
- **App lock**: при `authSession != null && pin установлен` — overlay `AppLockScreen`
  при cold start и `AppLifecycleState.resumed` (после background > 0 с).

**Rationale**: PIN локальный (не JWT); конституция IX — JWT для API, PIN для UX на
устройстве. `local_auth` — de-facto стандарт Flutter.

**Alternatives considered**:
- **PIN на сервере** — out of scope spec; лишняя задержка и риски.
- **shared_preferences для PIN** — нарушает безопасность.

**Logout**: очистка `local_pin_hash`, `biometric_enabled` вместе с JWT.

**Forgot PIN**: кнопка «Войти по СМС» → logout + redirect `/auth/phone`.

---

## 5. Push-уведомления

**Decision**: **`permission_handler`** для `Permission.notification`; preference
`pushEnabled` синхронизируется через `PATCH /profile/preferences`.

**Rationale**: в мок-фазе FCM не обязателен (spec: toggle + permission ОС); достаточно
сохранить настройку и запросить разрешение. Регистрация device token — follow-up при
подключении push-backend.

**Alternatives considered**:
- **firebase_messaging сразу** — преждевременно без боевого FCM-проекта.
- **Только UI toggle без permission** — не выполняет SC-005 и edge case ОС.

**UI**: SwitchListTile; при denied permanently — `openAppSettings()` через
`permission_handler`.

---

## 6. ContactBlock и соцсети

**Decision**: перенести `ContactBlock` в `lib/core/widgets/contact_block.dart`;
новый `SocialLinksRow` с иконками VK/OK → `url_launcher`.

**Rationale**: FR-011/FR-012; DRY между «Главной» и «Профилем».

**URLs** (константы в `app_strings` или `profile_constants.dart`):
- Оферта: `https://osetrovich.ru/privacy-policy`
- VK: `https://vk.com/osetrovich`
- OK: `https://ok.ru/osetrovich`

---

## 7. Навигация

**Decision**: вложенные `GoRoute` в ветке `/profile`:

| Маршрут | Экран |
|---------|-------|
| `/profile` | ProfileScreen |
| `/profile/change-phone` | ChangePhoneScreen |
| `/profile/change-phone/code` | ChangePhoneCodeScreen |
| `/profile/email` | EmailVerifyScreen |
| `/profile/email/code` | EmailCodeScreen |
| `/profile/pin/setup` | PinSetupScreen |
| `/profile/pin/change` | PinChangeScreen |

Смена телефона/email/pin: `context.push` с `parentNavigatorKey: _rootNavigatorKey`
(как auth) — полноэкранный стек поверх Tab Bar.

**Rationale**: согласовано с `/auth/*` и `/home/notifications/*`; Tab Bar виден на
главном профиле, скрыт на wizard-экранах верификации.

---

## 8. Неавторизованный профиль

**Decision**: заглушка `EmptyState` (как сейчас) + **ниже** секция `LegalSupportSection`:
«Связаться», оферта, соцсети — доступны без входа (spec US6 scenario 5).

**Rationale**: юридическая информация и связь с магазином без барьера авторизации.

---

## 9. Состояние профиля

**Decision**: `AsyncNotifier<UserProfile>` (`profileNotifierProvider`); после PATCH/verify
— `ref.invalidateSelf()` или локальное обновление state.

**Rationale**: единый источник для ProfileScreen; logout → provider reset через
`authSessionProvider` listener.

---

## 10. Тестовая стратегия

| Слой | Что тестируем |
|------|----------------|
| Unit | ProfileRepository; email validator; PIN hash; push preference mapping |
| Widget | ProfileScreen (auth/unauth); поля; logout; social links; switch push |
| Widget | Change phone/email code screens (timer, back, error) |
| Integration | login → profile → change name → logout; phone change flow |

**Инструменты**: `flutter_test`, `integration_test`, `mocktail`; `local_auth` mock через
abstract `LocalAuthService` interface.

---

## 11. Версия OpenAPI

**Decision**: bump `info.version` → **0.3.0**; добавить tag `profile`.

**Rationale**: semver контракта по фичам (0.2.0 → notifications-home).

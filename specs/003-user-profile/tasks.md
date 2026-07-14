---

description: "Список задач для фичи «Профиль пользователя»"
---

# Tasks: Профиль пользователя

**Input**: Design documents from `/specs/003-user-profile/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и integration тесты включены для каждой user story.

**Organization**: Задачи сгруппированы по user story для независимой реализации и проверки.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Можно выполнять параллельно (разные файлы, нет зависимостей от незавершённых задач)
- **[Story]**: User story из spec.md (US1–US6)
- В описании указан точный путь к файлу

## Path Conventions

- **Flutter (Osetrovich)**: `lib/`, `test/`, `integration_test/`, `openapi/`
- Структура согласно [plan.md](./plan.md)

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Зависимости, контракт API, структура каталогов

- [x] T001 Add `local_auth` and `permission_handler` to `pubspec.yaml` and run `flutter pub get`
- [x] T002 Merge OpenAPI v0.3.0 from `specs/003-user-profile/contracts/openapi.yaml` into `openapi/openapi.yaml` (profile endpoints + UserProfile schema)
- [x] T003 [P] Create feature directory tree `lib/features/profile/{data,domain,presentation/presentation/widgets}/` per plan.md
- [x] T004 [P] Create test directory `test/features/profile/` and stub `integration_test/profile_flow_test.dart`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: API-клиент, моки, доменная модель, общие виджеты — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T005 [P] Add profile UI strings to `lib/core/l10n/app_strings.dart`: name, email, phone, emailVerified, logout, pin, biometric, push, privacyPolicy, changePhone, changeEmail, securitySection
- [x] T006 [P] Create `lib/features/profile/domain/user_profile.dart` per data-model.md
- [x] T007 Extend `lib/core/network/api_client.dart` with profile methods: `getProfile`, `updateProfile`, `requestPhoneChange`, `verifyPhoneChange`, `requestEmailVerification`, `verifyEmail`, `getProfilePreferences`, `updateProfilePreferences`
- [x] T008 Update `lib/core/network/mock_api_client.dart`: mutable `_profile` per session, codes `123456`, conflicts `+79999999999` / `taken@example.com`
- [x] T009 [P] Create `lib/features/profile/data/profile_repository.dart` wrapping ApiClient
- [x] T010 Create `lib/features/profile/domain/profile_notifier.dart` with `profileNotifierProvider`
- [x] T011 [P] Move `lib/features/home/presentation/contact_block.dart` to `lib/core/widgets/contact_block.dart`; update import in `lib/features/home/presentation/home_screen.dart`
- [x] T012 [P] Create reusable `lib/core/widgets/verification_code_field.dart` (6-digit input, shared by phone/email/pin flows)

**Checkpoint**: API, модель и общие виджеты готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Экран профиля и выход (Priority: P1) 🎯 MVP

**Goal**: Авторизованный профиль с именем, email, телефоном; заглушка для неавторизованных; выход

**Independent Test**: Войти → «Профиль» → данные видны → «Выйти» → заглушка (quickstart С1–С2, С9)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T013 [P] [US1] Unit-тест `ProfileRepository` в `test/features/profile/profile_repository_test.dart` (getProfile, updateProfile)
- [x] T014 [P] [US1] Unit-тест `profile_notifier` в `test/features/profile/profile_notifier_test.dart` (load, logout clears state)
- [x] T015 [P] [US1] Widget-тест `ProfileScreen` в `test/features/profile/profile_screen_test.dart` (auth fields, unauth empty state, logout button)
- [x] T016 [P] [US1] Integration-тест login → profile → logout в `integration_test/profile_flow_test.dart`

### Implementation for User Story 1

- [x] T017 [P] [US1] Create `lib/features/profile/presentation/widgets/profile_field_tile.dart` (label + value, tap handler)
- [x] T018 [US1] Replace `lib/features/profile/presentation/profile_screen.dart`: load profile via `profileNotifierProvider`; show name/email/phone tiles; unauth `EmptyState`
- [x] T019 [US1] Implement logout in `profile_screen.dart`: call `AuthRepository.logout`, clear `profileNotifierProvider`, reset session via `authSessionProvider`
- [x] T020 [US1] Wire profile load on tab open: `ref.watch(profileNotifierProvider)` when `authSessionProvider != null`

**Checkpoint**: Профиль и выход работают; заглушка для неавторизованных сохранена

---

## Phase 4: User Story 2 — Имя и смена телефона (Priority: P1)

**Goal**: Редактирование имени; смена телефона через СМС-код (как auth-flow)

**Independent Test**: Изменить имя; сменить телефон с кодом `123456` (quickstart С3–С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T021 [P] [US2] Unit-тест phone change в `test/features/profile/profile_repository_test.dart` (request, verify, phone_taken error)
- [x] T022 [P] [US2] Widget-тест `ChangePhoneScreen` в `test/features/profile/change_phone_screen_test.dart`
- [x] T023 [P] [US2] Widget-тест `ChangePhoneCodeScreen` в `test/features/profile/change_phone_code_screen_test.dart` (timer, back, invalid code)

### Implementation for User Story 2

- [x] T024 [US2] Create `lib/features/profile/presentation/change_phone_screen.dart` (phone mask +7, submit → request code)
- [x] T025 [US2] Create `lib/features/profile/presentation/change_phone_code_screen.dart` (6-digit code, retry 60s, back)
- [x] T026 [US2] Add editable name field + PATCH save in `lib/features/profile/presentation/profile_screen.dart`
- [x] T027 [US2] Add phone tile tap → `context.push('/profile/change-phone')` in `profile_screen.dart`
- [x] T028 [US2] Add routes `/profile/change-phone` and `/profile/change-phone/code` with `parentNavigatorKey` in `lib/core/router/app_router.dart`
- [x] T029 [US2] Refresh profile after successful phone verify in `change_phone_code_screen.dart`

**Checkpoint**: Имя и телефон обновляются через API; ошибки на русском

---

## Phase 5: User Story 3 — Email с подтверждением кодом (Priority: P2)

**Goal**: Указание/смена email с 6-значным кодом; статус «Подтверждён»

**Independent Test**: Email → код `123456` → emailVerified true (quickstart С5)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T030 [P] [US3] Unit-тест email verify в `test/features/profile/profile_repository_test.dart` (request, verify, email_taken)
- [x] T031 [P] [US3] Unit-тест email validator в `test/features/profile/email_validator_test.dart`
- [x] T032 [P] [US3] Widget-тест `EmailVerifyScreen` и `EmailCodeScreen` в `test/features/profile/email_verify_screen_test.dart`

### Implementation for User Story 3

- [x] T033 [US3] Create `lib/features/profile/domain/email_validator.dart`
- [x] T034 [US3] Create `lib/features/profile/presentation/email_verify_screen.dart` (email input, validation)
- [x] T035 [US3] Create `lib/features/profile/presentation/email_code_screen.dart` (code + retry timer)
- [x] T036 [US3] Add email tile with verified badge in `lib/features/profile/presentation/profile_screen.dart`
- [x] T037 [US3] Add routes `/profile/email` and `/profile/email/code` in `lib/core/router/app_router.dart`

**Checkpoint**: Email подтверждается кодом; конфликты обрабатываются

---

## Phase 6: User Story 4 — Код для входа и биометрия (Priority: P2)

**Goal**: PIN 6 цифр (secure storage), биометрия через `local_auth`, app lock при resume

**Independent Test**: Установить PIN → включить био → resume → unlock (quickstart С6)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО)

- [x] T038 [P] [US4] Unit-тест `LocalAuthService` (pin hash, enable/disable biometric) в `test/features/profile/local_auth_service_test.dart`
- [x] T039 [P] [US4] Widget-тест `PinSetupScreen` в `test/features/profile/pin_setup_screen_test.dart`
- [x] T040 [P] [US4] Widget-тест `AppLockScreen` в `test/features/profile/app_lock_screen_test.dart`

### Implementation for User Story 4

- [x] T041 [US4] Create `lib/features/profile/domain/local_auth_service.dart` (SHA-256 pin hash, `local_auth`, secure storage keys)
- [x] T042 [US4] Create `lib/features/profile/presentation/pin_setup_screen.dart` (enter PIN twice)
- [x] T043 [US4] Create `lib/features/profile/presentation/pin_change_screen.dart` (verify old → new twice)
- [x] T044 [US4] Create `lib/features/profile/presentation/app_lock_screen.dart` (PIN/biometric unlock, «Забыли код?» → logout)
- [x] T045 [US4] Add security section in `profile_screen.dart`: setup/change PIN, biometric Switch (only if pin set)
- [x] T046 [US4] Integrate app lock overlay on cold start/resume in `lib/main.dart` or app-level wrapper when session + pin exist
- [x] T047 [US4] Add routes `/profile/pin/setup` and `/profile/pin/change` in `lib/core/router/app_router.dart`
- [x] T048 [US4] Clear pin/biometric on logout in `profile_screen.dart` or `local_auth_service.dart`

**Checkpoint**: PIN и биометрия работают локально; сброс при выходе

---

## Phase 7: User Story 5 — Push-уведомления (Priority: P3)

**Goal**: Switch push в профиле; permission ОС; sync с `PATCH /profile/preferences`

**Independent Test**: Toggle push → restart → состояние сохранено (quickstart С7)

### Tests for User Story 5 (ОБЯЗАТЕЛЬНО)

- [x] T049 [P] [US5] Unit-тест `PushPreferencesService` в `test/features/profile/push_preferences_service_test.dart`
- [x] T050 [P] [US5] Widget-тест push switch в `test/features/profile/profile_screen_test.dart` (toggle, denied permission message)

### Implementation for User Story 5

- [x] T051 [US5] Create `lib/features/profile/domain/push_preferences_service.dart` (`permission_handler` + repository PATCH)
- [x] T052 [US5] Add `SwitchListTile` push toggle in `lib/features/profile/presentation/profile_screen.dart`
- [x] T053 [US5] Handle denied OS permission: show Russian message + `openAppSettings()` in `push_preferences_service.dart`

**Checkpoint**: Push preference синхронизируется; permission запрашивается при включении

---

## Phase 8: User Story 6 — Поддержка, оферта и соцсети (Priority: P3)

**Goal**: «Связаться», оферта, VK/OK — на профиле (в т.ч. для неавторизованных)

**Independent Test**: Звонок, privacy URL, VK, OK открываются (quickstart С8)

### Tests for User Story 6 (ОБЯЗАТЕЛЬНО)

- [x] T054 [P] [US6] Widget-тест `SocialLinksRow` в `test/features/profile/social_links_row_test.dart`
- [x] T055 [P] [US6] Widget-тест `LegalSupportSection` в `test/features/profile/legal_support_section_test.dart`

### Implementation for User Story 6

- [x] T056 [P] [US6] Create `lib/features/profile/presentation/widgets/social_links_row.dart` (VK + OK icons → `url_launcher`)
- [x] T057 [US6] Create `lib/features/profile/presentation/widgets/legal_support_section.dart` (`ContactBlock`, privacy link `https://osetrovich.ru/privacy-policy`)
- [x] T058 [US6] Integrate `LegalSupportSection` in `lib/features/profile/presentation/profile_screen.dart` for both auth and unauth layouts

**Checkpoint**: Справочные блоки доступны на «Профиле»

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Качество, регрессии, валидация quickstart

- [x] T059 [P] Update `test/features/home/home_screen_test.dart` if ContactBlock import path changed
- [x] T060 [P] Add Android/iOS permission entries for `local_auth` and `permission_handler` in platform manifests per package docs
- [x] T061 Run `dart format .` and `flutter analyze` — zero issues
- [x] T062 Run full `flutter test` suite — all green
- [x] T063 Run `integration_test/profile_flow_test.dart` on device/emulator per `quickstart.md` С1–С9

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Старт сразу
- **Foundational (Phase 2)**: После Setup — **блокирует все user stories**
- **US1 (Phase 3)**: После Foundational — **MVP**
- **US2 (Phase 4)**: После US1 (profile screen exists)
- **US3 (Phase 5)**: После US1; независима от US2
- **US4 (Phase 6)**: После US1; независима от US2/US3
- **US5 (Phase 7)**: После US1 (profile screen)
- **US6 (Phase 8)**: После T011 (ContactBlock); может параллельно с US2–US5 после US1
- **Polish (Phase 9)**: После всех желаемых user stories

### User Story Dependencies

| Story | Зависит от | Независимый тест |
|-------|------------|------------------|
| US1 | Phase 2 | Вход → профиль → выход |
| US2 | US1 | Имя + смена телефона |
| US3 | US1 | Email verify |
| US4 | US1 | PIN + био + app lock |
| US5 | US1 | Push toggle |
| US6 | T011 | Связаться, оферта, соцсети |

### Within Each User Story

- Тесты MUST быть написаны первыми и падать до реализации
- data → domain → presentation → router
- Story complete перед переходом к следующему приоритету (US2 после US1 обязательно)

---

## Parallel Example: User Story 1

```bash
# Параллельно — тесты:
test/features/profile/profile_repository_test.dart
test/features/profile/profile_notifier_test.dart
test/features/profile/profile_screen_test.dart

# Параллельно после T009:
lib/features/profile/presentation/widgets/profile_field_tile.dart
```

## Parallel Example: User Story 4

```bash
# Параллельно:
lib/features/profile/domain/local_auth_service.dart
test/features/profile/local_auth_service_test.dart
test/features/profile/pin_setup_screen_test.dart
```

## Parallel Example: User Story 6

```bash
# Параллельно:
lib/features/profile/presentation/widgets/social_links_row.dart
lib/features/profile/presentation/widgets/legal_support_section.dart
test/features/profile/social_links_row_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US1 — профиль и выход
4. Phase 4: US2 — имя и телефон
5. **STOP и VALIDATE**: `integration_test/profile_flow_test.dart` + quickstart С1–С4, С9

### Incremental Delivery

1. Setup + Foundational → API и модель
2. US1 → Профиль + logout (MVP core)
3. US2 → Имя + телефон (MVP complete для P1)
4. US3 → Email
5. US4 → PIN + биометрия
6. US5 → Push
7. US6 → Поддержка и соцсети
8. Polish → quickstart полностью

### Suggested MVP Scope

**User Stories 1 + 2** (Phase 1–4): просмотр профиля, выход, имя и смена телефона —
минимальная ценность для авторизованного пользователя.

---

## Notes

- Мок: код `123456` для phone/email; phone taken `+79999999999`; email taken `taken@example.com`
- Logout: JWT + clear PIN/biometric (US4) + invalidate profile
- Верификационные экраны: `parentNavigatorKey: _rootNavigatorKey` (как `/auth/*`)
- Push: без FCM в мок-фазе — только preference + OS permission
- PIN: только локально, не в OpenAPI
- Всего задач: **63** (Setup 4 + Foundational 8 + US1 8 + US2 9 + US3 8 + US4 11 + US5 5 + US6 5 + Polish 5)

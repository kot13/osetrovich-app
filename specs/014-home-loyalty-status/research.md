# Research: Блок статуса лояльности на главной

**Дата**: 2026-07-21  
**Фича**: [spec.md](./spec.md)

## 1. Источник данных — профиль пользователя

**Decision**: данные статуса лояльности, скидки и номера карты читаются из существующего
`GET /profile/me` (поля `loyaltyStatus`, `discount`, `card` в `UserProfile`). Отдельный
эндпоинт для главной **не** вводится.

**Rationale**: решение зафиксировано в spec (Assumptions); OpenAPI уже расширен; один
источник правды для профиля и главной; переиспользование `ProfileNotifier` /
`profileNotifierProvider`.

**Alternatives considered**:
- **`GET /home/loyalty-status`** — дублирование данных профиля, лишний запрос на главной.
- **Локальный кэш только на главной** — риск рассинхрона с экраном профиля.

---

## 2. Загрузка профиля на «Главной»

**Decision**: `HomeScreen` для авторизованного пользователя `watch(profileNotifierProvider)`.
Провайдер уже реализован в `lib/features/profile/domain/profile_notifier.dart` и
загружает профиль при первом обращении после появления сессии.

**Rationale**: FR-004, FR-011; единый кэш профиля между «Главной» и «Профилем»; при входе
`build()` нотифаера перезапускается по `authSessionProvider`.

**Pull-to-refresh**: в `_refreshHome` добавить `profileNotifier.refresh()` для
авторизованных (FR-010).

**Alternatives considered**:
- **Отдельный `homeProfileProvider`** — дублирование запроса `getProfile()`.
- **Eager load при restore session** — избыточный запрос до открытия главной.

---

## 3. Условия отображения зоны под баннерами

**Decision**: вынести правила в `HomeProfileSlotUiState` (domain):

| Сессия | Профиль | UI |
|--------|---------|-----|
| гость | — | кнопка «Авторизоваться» |
| авторизован | loading / error | `SizedBox.shrink()` |
| авторизован | `loyaltyStatus == null` | пусто |
| авторизован | `loyaltyStatus != null` | блок лояльности |

Строка скидки — только при `discount > 0`. Строка с картой — только при непустом `card`.

**Rationale**: FR-005, FR-007, FR-008, FR-009; логика тестируется unit-тестом без виджетов.

**Alternatives considered**:
- **Условия inline в `HomeScreen`** — нарушение принципа IV (бизнес-логика в виджете).

---

## 4. Маппинг `LoyaltyStatus` → отображаемое название

**Decision**: enum `LoyaltyStatus` в `lib/features/profile/domain/` + функция
`loyaltyStatusLabel(LoyaltyStatus status)`:

| API / enum | UI (рус.) |
|------------|-----------|
| `super_vip` | Super VIP |
| `vip` | VIP |
| `elite` | Elite |
| `premium` | Premium |
| `friend` | Друг |
| `club_member` | Участник клуба |

Парсинг JSON: `loyaltyStatusFromJson(String?)` → `LoyaltyStatus?` (`null` если поле
отсутствует или `null` в ответе).

**Rationale**: FR-006; единый маппинг для главной и потенциального использования в профиле;
английские брендовые названия (Super VIP, VIP, Elite, Premium) оставляем как в ТЗ.

**Alternatives considered**:
- **Локализация через ARB** — избыточно для фиксированного набора из 6 значений.

---

## 5. UI-компоненты и замена «Связаться»

**Decision**:

| Компонент | Действие |
|-----------|----------|
| `HomeContactButton` | Удалить использование с `HomeScreen`; файл MAY остаться до cleanup или удалить, если больше нигде не используется |
| `AuthPromptBanner` | Убрать с `HomeScreen` (FR-003) |
| `HomeAuthButton` | **NEW** — CTA «Авторизоваться», стиль как у бывшего contact (surface + `AppColors`), tap → `/auth/phone` |
| `HomeLoyaltyStatusCard` | **NEW** — информационная карточка: заголовок статуса, опционально скидка и номер карты |
| `HomeProfileSlot` | **NEW** — выбирает между auth / loyalty / empty по `HomeProfileSlotUiState` |

Визуал: фон карточки — `AppColors.background` или `AppColors.dark` с alpha 0.08 (как
`HomeContactButton`); акцент скидки — `AppColors.accent`; текст — `AppColors.dark`.

**Rationale**: FR-001–FR-003, FR-013; минимальный diff; переиспользование паттерна padding
16 + borderRadius 12.

**Alternatives considered**:
- **Переименовать `HomeContactButton` в auth** — семантически неверно, проще новый виджет.

---

## 6. Расширение модели `UserProfile`

**Decision**: добавить поля:

```dart
final LoyaltyStatus? loyaltyStatus;
final int discount;       // 0–100, required, default 0
final String? card;
```

`fromJson`: `discount` обязателен; `loyaltyStatus` и `card` nullable.

**Rationale**: соответствие OpenAPI `UserProfile` (required: `discount`).

---

## 7. Мок-данные для ручной проверки

**Decision**: в `MockApiClient.ensureProfile` задавать loyalty по телефону:

| Телефон | loyaltyStatus | discount | card |
|---------|---------------|----------|------|
| `+79001111111` | `premium` | 10 | `1234567890` |
| `+79002222222` | `vip` | 0 | `null` |
| `+79003333333` | `null` | 0 | `null` |
| остальные | `club_member` | 5 | `9876543210` |

**Rationale**: покрытие сценариев quickstart (статус+скидка+карта, статус без скидки, без
статуса); согласовано с демо-номерами из 007 для заказов.

---

## 8. OpenAPI и версия контракта

**Decision**: инкремент `openapi/openapi.yaml` до **v0.12.4** — дельта только по
`UserProfile` + `LoyaltyStatus` (уже частично в рабочей копии как v0.12.3); фичевый
`contracts/openapi.yaml` документирует изменение для merge.

**Rationale**: конституция VI — contract-first; моки и `UserProfile.fromJson` синхронизируются.

---

## 9. Строки локализации (`app_strings.dart`)

**Decision**: добавить:

| Ключ | Значение |
|------|----------|
| `homeAuthButton` | Авторизоваться |
| `homeLoyaltyDiscount` | Скидка {percent}% |
| `homeLoyaltyCard` | Карта {number} |

`authPrompt` («Авторизуйтесь») остаётся для других экранов, на главной не используется.

**Rationale**: FR-002, FR-012; явное различие текста кнопки по spec.

---

## 10. Тестовая стратегия

**Decision**:

| Уровень | Файлы |
|---------|-------|
| Unit | `loyalty_status_label_test.dart`, `home_profile_slot_ui_state_test.dart` |
| Unit (network) | расширение `mock_api_client_test.dart` — поля loyalty в профиле |
| Widget | `home_auth_button_test.dart`, `home_loyalty_status_card_test.dart`; UPDATE `home_screen_test.dart`, `contact_block_test` не затрагивается |
| Integration | UPDATE `home_screen_flow_test.dart` — гость / premium / без статуса |

**Rationale**: конституция III; покрытие правил видимости и маппинга статусов (SC-003, SC-004).

# Data Model: Блок статуса лояльности на главной

**Дата**: 2026-07-21  
**Фича**: [spec.md](./spec.md) | **Контракты**: [contracts/openapi.yaml](./contracts/openapi.yaml)

## 1. UserProfile (расширение)

| Поле | Тип | Обязательное | Описание |
|------|-----|--------------|----------|
| id | string | да | Идентификатор пользователя |
| name | string | да | Отображаемое имя |
| phone | string | да | Телефон `+7XXXXXXXXXX` |
| email | string? | нет | Email |
| emailVerified | bool | да | Подтверждение email |
| pushEnabled | bool | да | Push-настройка |
| loyaltyStatus | LoyaltyStatus? | нет | Уровень лояльности; `null` — не назначен |
| discount | int | да | Персональная скидка 0–100 % |
| card | string? | нет | Номер дисконтной / клубной карты |

**Валидация API**:
- `discount`: integer, 0–100.
- `loyaltyStatus`: одно из значений enum или `null`.
- `card`: произвольная непустая строка при наличии.

**Клиент**: `lib/features/profile/domain/user_profile.dart`.

---

## 2. LoyaltyStatus (enum)

| Значение API | Dart enum | UI label |
|--------------|-----------|----------|
| `super_vip` | `superVip` | Super VIP |
| `vip` | `vip` | VIP |
| `elite` | `elite` | Elite |
| `premium` | `premium` | Premium |
| `friend` | `friend` | Друг |
| `club_member` | `clubMember` | Участник клуба |

**Клиент**: `lib/features/profile/domain/loyalty_status.dart` (enum + `fromJson` / `toJson`).

**Функция отображения**: `loyaltyStatusLabel(LoyaltyStatus status)` → `String`.

---

## 3. HomeProfileSlotUiState (UI-модель главной)

Производная модель для зоны под баннерами; не приходит с сервера.

| Поле | Тип | Описание |
|------|-----|----------|
| mode | HomeProfileSlotMode | Что показывать в слоте |

### HomeProfileSlotMode (enum)

| Значение | Условие | UI |
|----------|---------|-----|
| `guestAuth` | не авторизован | `HomeAuthButton` |
| `hidden` | авторизован, loading/error/нет статуса | пусто |
| `loyalty` | авторизован, `loyaltyStatus != null` | `HomeLoyaltyStatusCard` |

**Построение**: `buildHomeProfileSlotUiState({ required bool isAuthenticated, required AsyncValue<UserProfile?> profile })`.

---

## 4. HomeLoyaltyStatusUiModel (содержимое карточки)

| Поле | Тип | Показывать в UI |
|------|-----|-----------------|
| statusLabel | string | всегда |
| discountPercent | int? | если > 0 |
| cardNumber | string? | если непустой |

**Построение**: `buildHomeLoyaltyStatusUiModel(UserProfile profile)` — требует
`profile.loyaltyStatus != null`.

---

## 5. Диаграмма потока данных

```text
HomeScreen
  ├── watch isAuthenticatedProvider
  ├── watch profileNotifierProvider (если авторизован)
  └── HomeProfileSlot
        ├── guestAuth → HomeAuthButton → /auth/phone
        ├── hidden → SizedBox.shrink()
        └── loyalty → HomeLoyaltyStatusCard
              └── данные из UserProfile (loyaltyStatus, discount, card)

ProfileNotifier
  └── ProfileRepository.getProfile() → ApiClient GET /profile/me
```

---

## 6. Изменения на «Главной» (layout)

Порядок блоков после фичи:

1. AppBar «Главная»
2. Карусель баннеров
3. **HomeProfileSlot** (auth | loyalty | пусто)
4. «Товары недели»
5. «История заказов» (если есть текущий заказ)

**Удалено с главной**: `HomeContactButton`, нижний `AuthPromptBanner`.

**Без изменений**: ContactBlock в профиле, «Связаться с оператором» в блоке заказа.

---

## 7. Состояния при смене сессии

```text
logout → profileNotifier.clear() (уже в ProfileScreen) → guestAuth
login → profileNotifier.build() → loading → hidden | loyalty
pull-to-refresh (auth) → profileNotifier.refresh() → обновление loyalty-блока
```

# Research: Инициализация приложения

**Дата**: 2026-07-14  
**Фича**: [spec.md](./spec.md)

## 1. Управление состоянием

**Decision**: `flutter_riverpod` (Riverpod 2.x)

**Rationale**:
- Провайдеры легко переопределяются в тестах (override) без DI-фреймворка.
- `AsyncNotifier` / `Notifier` хорошо моделируют загрузку категорий и auth-сессию.
- Соответствует конституции: предсказуемое, тестируемое состояние вне виджетов.

**Alternatives considered**:
- **Bloc** — много boilerplate для простых экранов-заглушек.
- **Provider (legacy)** — менее выразительная типизация, Riverpod — преемник.
- **GetX** — слабее интеграция с тестами и community best practices.

---

## 2. Навигация и Tab Bar

**Decision**: `go_router` с `StatefulShellRoute.indexedStack`

**Rationale**:
- Сохраняет состояние каждой вкладки при переключении (US1 AC3).
- Вложенные маршруты: auth-стек поверх shell или отдельные `GoRoute` вне tab branches.
- Декларативная конфигурация, deep links в будущем.

**Alternatives considered**:
- **Navigator 2.0 вручную** — избыточная сложность.
- **auto_route** — codegen; для init-фичи go_router достаточен без build_runner навигации.

**Маппинг вкладок**:

| Индекс | Маршрут | Экран |
|--------|---------|-------|
| 0 | `/home` | Главная |
| 1 | `/catalog` | Каталог |
| 2 | `/promotions` | Акции и новости |
| 3 | `/cart` | Корзина |
| 4 | `/profile` | Профиль |

Auth: `/auth/phone`, `/auth/sms` — вне shell, full-screen.

---

## 3. HTTP-клиент и моки

**Decision**: `dio` + переключатель `MockApiClient` / `DioClient` через Riverpod

**Rationale**:
- Interceptors для Bearer JWT (конституция IX).
- Моки реализуют те же интерфейсы репозиториев, возвращая данные из OpenAPI-примеров.
- Переключение `useMockApi: true` в dev до подключения боевого API.

**Alternatives considered**:
- **http package** — нет interceptors из коробки.
- **chopper + swagger codegen** — отложить до стабилизации OpenAPI; ручные DTO на init.

---

## 4. JWT и secure storage

**Decision**: `flutter_secure_storage` для `access_token` и `refresh_token`

**Rationale**: соответствие конституции IX; Keychain/Keystore на платформах.

**Поток авторизации**:
1. `POST /auth/sms/request` — тело `{ "phone": "+79XXXXXXXXX" }`
2. `POST /auth/sms/verify` — `{ "phone", "code" }` → `{ access_token, refresh_token, expires_in }`
3. `POST /auth/refresh` — `{ refresh_token }` → новая пара токенов
4. Interceptor добавляет `Authorization: Bearer <access_token>`

**Мок**: код `123456` всегда валиден в dev-моке.

---

## 5. Маска телефона +7

**Decision**: `mask_text_input_formatter` с маской `+7 (###) ###-##-##`

**Rationale**: готовое решение, валидация полноты номера (10 цифр после +7).

**Валидация**: кнопка «Продолжить» активна только при 11 цифрах (7 + 10).

---

## 6. Таймер повторного запроса СМС (60 с)

**Decision**: `Timer` в `SmsCodeNotifier` + `Stream`/`state` с `resendSecondsRemaining`

**Rationale**:
- Unit-тестируемо через `FakeAsync` или injectable `Clock`.
- UI: кнопка disabled при `remaining > 0`, текст «Повторить через N сек».

---

## 7. Баннерокрутилка

**Decision**: `PageView` + `PageController` (без внешней зависимости)

**Rationale**: достаточно для карусели на init; `carousel_slider` — опционально позже.

**Данные**: `GET /home/banners` — массив `{ id, imageUrl, linkUrl? }`; мок — 3 placeholder-баннера.

---

## 8. Filter Chips категорий

**Decision**: горизонтальный `ListView` + `ChoiceChip` / кастомный chip на `FilterChip`

**Rationale**: Material 3 ChoiceChip; активный чип — accent `#FFB400`, неактивный — background.

**Загрузка**: при `main()` / `AppStartupNotifier` — `GET /catalog/categories`; кэш в провайдере.

---

## 9. Звонок в поддержку

**Decision**: не входит в scope фичи init-app-shell; кнопка «Поддержка» на «Главной» не
реализуется.

**Rationale**: убрано из реализации; при необходимости — отдельная фича или раздел профиля.

---

## 10. Нативный сплэш и имя приложения

**Decision**: `flutter_native_splash` — логотип osetrovich на фоне `#213C57`; для Android 12+
отдельное изображение `osetrovich_logo_android12.png` (логотип внутри квадрата с тем же фоном).

**Отображаемое имя**: «Осетрович» (`AndroidManifest` / `Info.plist` / `MaterialApp.title`).

**Rationale**: брендированный первый экран; соответствие фирменной палитре (конституция VIII).

---

## 11. Счётчик уведомлений

**Decision**: `GET /notifications/unread-count` → `{ count: int }`; мок возвращает `3`

**Rationale**: отдельный лёгкий эндпоинт; клик по колокольчику — no-op в scope (spec Assumptions).

---

## 12. Тестовая стратегия

| Слой | Что тестируем |
|------|----------------|
| Unit | валидация телефона, таймер resend, auth repository (мок dio) |
| Widget | TabBar 5 вкладок, empty states, phone/sms экраны, chips |
| Integration | переключение вкладок, полный auth flow с мок-API |

**Инструменты**: `flutter_test`, `integration_test`, `mocktail`.

---

## 13. Инициализация Flutter-проекта

**Decision**: `flutter create . --org ru.osetrovich --project-name osetrovich` в корне репозитория

**Rationale**: стандартная структура android/ios; Spec Kit docs остаются в `specs/`, код в `lib/`.

**Минимальные SDK**: Android minSdk 21+, iOS 13+ (Flutter defaults).

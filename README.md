# Осетрович

Мобильное приложение интернет-магазина [osetrovich.ru](https://osetrovich.ru) для **Android** и **iOS**.

Кроссплатформенный клиент на Flutter: каталог, корзина, акции, профиль, SMS-авторизация с JWT. На этапе разработки данные приходят из **мок-API**, контракт описан в OpenAPI.

## Описание

Приложение реализует каркас магазина:

- **Tab Bar** — Главная, Каталог, Акции и новости, Корзина, Профиль
- **Главная** — счётчик уведомлений, баннеры, призыв авторизоваться
- **Каталог** — Filter Chips с категориями (загружаются при старте)
- **Корзина / Акции** — пустые состояния с понятными заглушками
- **Профиль** — вход по номеру телефона (+7) и СМС-коду (6 цифр)
- **Авторизация** — JWT-токены в защищённом хранилище; при ответе API **401** клиент автоматически обновляет access-токен через `POST /auth/refresh`, при неуспехе — выход из аккаунта

Спецификации и план разработки — в каталоге [`specs/`](specs/). Конституция проекта — [`.specify/memory/constitution.md`](.specify/memory/constitution.md).

### Стек

| Компонент | Технология |
|-----------|------------|
| UI | Flutter, Material 3 |
| Состояние | Riverpod |
| Навигация | go_router |
| Сеть | dio + мок-клиент |
| API-контракт | OpenAPI (`openapi/openapi.yaml`) |
| Тесты | flutter_test, integration_test |

## Требования

### Обязательно

- **Flutter SDK** (stable channel), **Dart 3.7+**
- **Git**

Проверка окружения:

```bash
flutter doctor
```

### Для запуска на устройствах

| Платформа | Требования |
|-----------|------------|
| **Android** | Android Studio или Android SDK, эмулятор или физическое устройство (API 21+) |
| **iOS** | macOS, Xcode, симулятор или iPhone (iOS 13+) |

### Для разработки

- Редактор с поддержкой Dart/Flutter (VS Code, Android Studio, Cursor)
- Для integration-тестов — подключённый эмулятор или устройство

## Установка и запуск

### 1. Клонировать репозиторий

```bash
git clone <url-репозитория>
cd osetrovich
```

### 2. Установить зависимости

```bash
flutter pub get
```

### 3. Запустить приложение

Список доступных устройств:

```bash
flutter devices
```

Запуск (подставьте свой `deviceId` при необходимости):

```bash
flutter run
# или явно:
flutter run -d chrome      # web (для быстрой проверки UI)
flutter run -d macos       # macOS desktop
flutter run -d <deviceId>  # Android / iOS
```

### Yandex AppMetrica (аналитика, краши, push)

Для сборок с аналитикой передайте API-ключ через `--dart-define` (ключи **не коммитить**):

```bash
flutter run --dart-define=APPMETRICA_API_KEY=<your_debug_api_key>
```

Без ключа приложение использует `NoOpAnalyticsService` — тесты и локальная разработка работают без AppMetrica.

Подробная настройка воронки, крашей и push: [`specs/008-yandex-appmetrica/quickstart.md`](specs/008-yandex-appmetrica/quickstart.md).

### Мок-API

По умолчанию приложение работает с **мок-данными** (без боевого бэкенда). Флаг в коде:

```dart
// lib/core/network/providers.dart
const useMockApi = true;
```

Для тестирования авторизации в моке валидный СМС-код: **`123456`**.

### Подключение к боевому API

Адрес: `https://trout.osetrovich.ru/v1`

Пример: `https://trout.osetrovich.ru/v1/auth/sms/request`

Чтобы переключиться с мока на боевой бэкенд, установите `useMockApi = false` в `lib/core/network/providers.dart` и перезапустите приложение.

Спецификация REST API: [`openapi/openapi.yaml`](openapi/openapi.yaml).

## Сборка Android (APK / AAB)

### APK

Для установки на устройство или внутреннего тестирования:

```bash
# release (оптимизированная сборка)
flutter build apk --release

# debug (быстрее собирается, для отладки)
flutter build apk --debug
```

Готовый файл:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Отдельные APK по архитектурам (меньше размер каждого файла):

```bash
flutter build apk --release --split-per-abi
```

Файлы появятся в `build/app/outputs/flutter-apk/` (`app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk` и т.д.).

Установка на подключённое устройство:

```bash
flutter install -d <deviceId>
```

Команда ожидает уже собранный **release**-APK. После `flutter build apk --release` можно установить вручную:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### AAB (Google Play)

Для публикации в Google Play нужен Android App Bundle:

```bash
flutter build appbundle --release
```

Готовый файл:

```text
build/app/outputs/bundle/release/app-release.aab
```

### Подпись release-сборок

Сейчас `release` подписывается **debug-ключом** (см. `android/app/build.gradle.kts`) — этого достаточно для локальной проверки.

Для публикации в Google Play настройте release-подпись: [Flutter — Android deployment](https://docs.flutter.dev/deployment/android#signing-the-app).

## Тесты

### Unit- и widget-тесты

```bash
flutter test
```

### Статический анализ

```bash
flutter analyze
dart format .
```

### Integration-тесты

Требуется подключённый эмулятор или устройство:

```bash
flutter devices
flutter test integration_test/ -d <deviceId>
```

Подробные сценарии ручной проверки — в [`specs/001-init-app-shell/quickstart.md`](specs/001-init-app-shell/quickstart.md).

## Структура проекта

```text
lib/
├── core/           # тема, роутер, сеть, строки UI
├── features/       # home, catalog, cart, profile, auth, …
├── app.dart
└── main.dart
openapi/            # OpenAPI-спецификация
specs/              # спецификации фич (Spec Kit)
test/               # unit + widget тесты
integration_test/   # сквозные тесты
```

## Полезные ссылки

- [Документация Flutter](https://docs.flutter.dev/)
- [osetrovich.ru](https://osetrovich.ru)

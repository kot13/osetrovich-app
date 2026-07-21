# Quickstart: Признак «Товар недели» и диплинки

**Фича**: [spec.md](./spec.md) | **План**: [plan.md](./plan.md) | **Модель**: [data-model.md](./data-model.md)

Руководство по проверке фичи после реализации.

## Предварительные требования

- Flutter SDK (stable), Dart 3.x
- Репозиторий с выполненными задачами из `tasks.md`
- Мок-API включён (`useMockApi = true` в `lib/core/network/providers.dart`)
- Зависимость `app_links` добавлена в `pubspec.yaml`
- Нативная регистрация схемы `osetrovich` в AndroidManifest и Info.plist

## Установка и запуск

```bash
flutter pub get
flutter run
```

## Автоматические тесты

```bash
flutter test test/core/deeplink/
flutter test test/core/push/push_deeplink_handler_test.dart
flutter test test/features/catalog/
flutter test test/features/promotions/
flutter analyze
```

**Ожидание**: unit-тесты `DeepLinkResolver` покрывают все 9 маршрутов + fallback;
`PushDeeplinkHandler` — URL priority + legacy JSON; widget-тесты бейджа «Товар недели».

---

## Сценарии ручной проверки

### С1. Бейдж «Товар недели» в каталоге (US1, FR-001–FR-003)

1. Открыть «Каталог».
2. Найти товар с `productOfWeek: true` в моках (см. `mock_api_client.dart`).
3. На карточке виден бейдж **«Товар недели»** (тёмный фон, жёлтый текст).
4. Товар с `productOfWeek: false` — бейджа нет.
5. Товар с `productOfWeek + sale + special` — три бейджа в ряд.

### С2. Бейдж в ленте «Товары недели» (US1)

1. Открыть «Главная» → блок «Товары недели».
2. Бейджи отображаются по тем же правилам, что в каталоге.
3. Тап по карточке → деталь товара загружается без ошибок.

### С3. Диплинк из статьи (US2, FR-007)

1. Открыть акцию/новость с HTML-ссылкой `osetrovich://catalog/product/1000` в теле
   (добавить в мок-статью при необходимости).
2. Нажать ссылку → открывается страница товара **внутри приложения**.
3. Внешняя ссылка `https://osetrovich.ru` в той же статье → открывается браузер.

### С4. Диплинки разделов из статьи (FR-006)

Проверить ссылки в тестовой статье (или через adb/xcrun, см. С6):

| Ссылка | Ожидание |
|--------|----------|
| `osetrovich://home` | Вкладка «Главная» |
| `osetrovich://catalog` | «Каталог», chip «Все» |
| `osetrovich://catalog/category/200` | «Каталог», выбрана категория 200 |
| `osetrovich://promotions` | «Акции и Новости» |
| `osetrovich://profile` | «Профиль» |
| `osetrovich://notifications` | Список уведомлений |

### С5. Push с URL диплинком (US3, FR-008, FR-011)

1. Отправить тестовый push через AppMetrica с payload:
   `osetrovich://notifications/notif-1` (или JSON `{ "deeplink": "osetrovich://..." }`).
2. Нажать уведомление → открывается деталь уведомления.
3. Push с legacy JSON `{ "type": "product", "targetId": "1000" }` без URL → товар 1000
   (обратная совместимость 008).
4. Push без URL и без type → список уведомлений (011).

### С6. Внешний диплинк (US4, FR-005)

**Android** (эмулятор/устройство с установленным приложением):

```bash
adb shell am start -a android.intent.action.VIEW -d "osetrovich://promotions"
```

**iOS Simulator**:

```bash
xcrun simctl openurl booted "osetrovich://catalog/product/1000"
```

**Ожидание**: приложение открывается на целевом экране (cold start и из фона).

### С7. Некорректные диплинки (Edge cases, FR-009–FR-010)

| Ссылка | Ожидание |
|--------|----------|
| `osetrovich://unknown` | «Главная», без краша |
| `osetrovich://catalog/product/abc` | «Главная» |
| `osetrovich://catalog/product/99999` | Экран товара с empty/error state |
| `osetrovich://promotions/articles/missing-id` | Empty state статьи |

### С8. Боевой API (опционально)

1. `useMockApi = false`.
2. Каталог и «Товары недели» загружаются с `https://trout.osetrovich.ru/v1`.
3. Бейдж «Товар недели» соответствует полю `productOfWeek` в ответе сервера.

---

## Контракты

| Файл | Проверка |
|------|----------|
| [deeplink-schema.yaml](./contracts/deeplink-schema.yaml) | `DeepLinkResolver` unit-тесты |
| [push-deeplink-v2.yaml](./contracts/push-deeplink-v2.yaml) | `PushDeeplinkHandler` unit-тесты |
| [openapi-delta.yaml](./contracts/openapi-delta.yaml) | парсинг моделей + моки |

## Troubleshooting

| Симптом | Проверка |
|---------|----------|
| Диплинк открывает браузер / ничего | AndroidManifest intent-filter; iOS CFBundleURLTypes |
| Категория не выбирается | `selectedCategoryIdProvider` + `productsNotifier.selectCategory` |
| Push ведёт на список уведомлений | payload не содержит `osetrovich://`; проверить поле `deeplink` |
| Бейдж не виден | `productOfWeek: true` в моке; hot restart после изменения моков |

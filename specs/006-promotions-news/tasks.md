---

description: "Список задач для фичи «Акции и новости»"
---

# Tasks: Акции и новости

**Input**: Design documents from `/specs/006-promotions-news/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/openapi.yaml, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и integration тесты включены для каждой user story.

**Organization**: Задачи сгруппированы по user story для независимой реализации и проверки.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Можно выполнять параллельно (разные файлы, нет зависимостей от незавершённых задач)
- **[Story]**: User story из spec.md (US1–US3)
- В описании указан точный путь к файлу

## Path Conventions

- **Flutter (Osetrovich)**: `lib/`, `test/`, `integration_test/`, `openapi/`
- Структура согласно [plan.md](./plan.md)

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Зависимости, контракт API, структура каталогов

- [x] T001 Add `flutter_html` to `pubspec.yaml` and run `flutter pub get`
- [x] T002 Merge OpenAPI v0.6.0 from `specs/006-promotions-news/contracts/openapi.yaml` into `openapi/openapi.yaml` (tag `promotions`, `/promotions/articles` endpoints + schemas)
- [x] T003 [P] Create directory `lib/features/promotions/presentation/widgets/` per plan.md
- [x] T004 [P] Create directories `lib/features/promotions/data/`, `lib/features/promotions/domain/` and stub `integration_test/promotions_flow_test.dart`

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модели, API-клиент, моки, репозиторий, notifier — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T005 [P] Add promotions UI strings to `lib/core/l10n/app_strings.dart`: `chipPromotions`, `chipNews`, `typePromotion`, `typeNews`, `articlesLoadFailed`, `articleNotFound`, `retry`
- [x] T006 [P] Create `lib/core/utils/date_formatter.dart` with `formatPublishedDate(DateTime) → '14 июля 2026'` (Russian month names, no intl)
- [x] T007 [P] Create `lib/features/promotions/domain/promotion_type.dart` (`PromotionType.all|promotion|news`, API query value) and `lib/features/promotions/domain/promotion_article.dart` (`PromotionArticleSummary`, `PromotionArticleDetail` with `fromJson` per data-model.md)
- [x] T008 Extend `lib/core/network/api_client.dart` with `getPromotionArticles(PromotionType type)` and `getPromotionArticleById(String id)`; implement in Dio client class in same file
- [x] T009 Update `lib/core/network/mock_api_client.dart`: ≥5 promotions + ≥4 news sorted by `publishedAt` desc; sample `bodyHtml` with lists/emoji; one entry with `<script>` for security test; invalid `imageUrl` sample; `getPromotionArticleById` returns 404 for unknown/unpublished id
- [x] T010 [P] Create `lib/features/promotions/data/promotions_repository.dart` wrapping `getPromotionArticles` and `getPromotionArticleById`
- [x] T011 Create `lib/features/promotions/domain/selected_type_provider.dart` with `selectedPromotionTypeProvider` default `PromotionType.all`
- [x] T012 Create `lib/features/promotions/domain/promotions_notifier.dart` with `promotionsNotifierProvider`: watches `selectedPromotionTypeProvider`, loads list on type change, `reload()` for retry per data-model.md

**Checkpoint**: API, модели и notifier готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Фильтрация ленты по типу контента (Priority: P1) 🎯 MVP

**Goal**: Filter Chips «Все» / «Акции» / «Новости»; по умолчанию активен «Все»; смена чипа перезагружает ленту; пустое состояние для типа без материалов

**Independent Test**: Открыть «Акции» → три чипа, активен «Все» → переключить «Акции»/«Новости» → активный чип и обновлённый список/пустое состояние (quickstart С1, С3)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T013 [P] [US1] Unit-тест `formatPublishedDate` в `test/core/utils/date_formatter_test.dart`
- [x] T014 [P] [US1] Unit-тест `PromotionsNotifier` (reload on type change, empty list) в `test/features/promotions/promotions_notifier_test.dart`
- [x] T015 [P] [US1] Widget-тест `PromotionTypeChips` в `test/features/promotions/promotion_type_chips_test.dart` (three chips, accent on selected, tap switches)

### Implementation for User Story 1

- [x] T016 [P] [US1] Create `lib/features/promotions/presentation/widgets/promotion_type_chips.dart`: horizontal `FilterChip` row «Все»/«Акции»/«Новости» mirroring `category_chips.dart` (`AppColors.accent`)
- [x] T017 [US1] Convert `lib/features/promotions/presentation/promotions_screen.dart` to `ConsumerStatefulWidget`: `PromotionTypeChips` → updates `selectedPromotionTypeProvider`; body shows `promotionsNotifierProvider` loading/error/`EmptyState` (chips always visible)
- [x] T018 [US1] Update `test/features/promotions/promotions_screen_test.dart`: ProviderScope + overrides — expect chips, default «Все» selected, empty state when mock returns no items for type

**Checkpoint**: Фильтрация по типу работает; карточки ленты ещё не обязательны

---

## Phase 4: User Story 2 — Просмотр ленты акций и новостей (Priority: P1)

**Goal**: Одноколоночная лента карточек (фото, метка типа, заголовок, дата); сортировка от новых к старым; tap по карточке готовит переход на деталь

**Independent Test**: При данных в моке — одна колонка карточек с фото/меткой типа/заголовком/датой; порядок по дате; tap на карточку (quickstart С2)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T019 [P] [US2] Unit-тест `PromotionsRepository` в `test/features/promotions/promotions_repository_test.dart`
- [x] T020 [P] [US2] Widget-тест `PromotionArticleCard` в `test/features/promotions/promotion_article_card_test.dart` (image, type badge, title ellipsis max 2 lines, formatted date, catalog-style placeholder on bad image)
- [x] T021 [P] [US2] Widget-тест ленты в `test/features/promotions/promotions_screen_test.dart` (single-column list, item count matches mock, newest first)

### Implementation for User Story 2

- [x] T022 [P] [US2] Create `lib/features/promotions/presentation/widgets/promotion_article_card.dart`: `CachedNetworkImage` cover (catalog-style placeholder), type badge, title, `formatPublishedDate`, `InkWell` `onTap` callback
- [x] T023 [US2] Update `lib/features/promotions/presentation/promotions_screen.dart`: `ListView.separated` with `ScrollController`; `jumpTo(0)` on chip change; render `PromotionArticleCard` for each item; preserve scroll on return from detail (FR-014)
- [x] T024 [US2] Wire `PromotionArticleCard.onTap` in `lib/features/promotions/presentation/promotions_screen.dart` to `context.push('/promotions/article/${article.id}')` (route added in US3)

**Checkpoint**: Лента карточек полностью работает; детальная страница — в US3

---

## Phase 5: User Story 3 — Чтение детальной страницы акции или новости (Priority: P2)

**Goal**: Деталь с кнопкой «Назад», фото, меткой типа, заголовком, датой, безопасным HTML и эмодзи

**Independent Test**: Открыть материал из ленты → все поля → back → сохранённый чип (quickstart С4, С5)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T025 [P] [US3] Unit-тест `MockApiClient.getPromotionArticleById` (404, html body) в `test/core/network/mock_api_client_promotions_test.dart`
- [x] T026 [P] [US3] Widget-тест `PromotionHtmlBody` в `test/features/promotions/promotion_html_body_test.dart` (renders `strong`/lists/links; `<script>` not executed/visible)
- [x] T027 [P] [US3] Widget-тест `PromotionDetailScreen` в `test/features/promotions/promotion_detail_screen_test.dart` (back button, type badge, title, date, html body; 404 state)

### Implementation for User Story 3

- [x] T028 [P] [US3] Create `lib/features/promotions/presentation/widgets/promotion_html_body.dart`: `flutter_html` whitelist tags (`p`, `br`, `strong`, `b`, `em`, `i`, `ul`, `ol`, `li`, `a`); `onLinkTap` via `url_launcher`; `AppColors.dark` text style
- [x] T029 [US3] Create `lib/features/promotions/presentation/promotion_detail_screen.dart`: load via repository; primary AppBar (auth style) back → `context.pop()`; cover image + type label + title + date + `PromotionHtmlBody`; loading/error/not-found states
- [x] T030 [US3] Add nested route `/promotions/article/:id` in `lib/core/router/app_router.dart` inside promotions branch (preserve Tab Bar)

**Checkpoint**: Все три user story работают end-to-end

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Сквозные проверки, контракт, документация

- [x] T031 [P] Integration-тест полного flow в `integration_test/promotions_flow_test.dart`: chips → list → detail → back → chip preserved (quickstart С1–С5)
- [x] T032 Run `flutter analyze` and `dart format` on changed files; fix any issues
- [x] T033 [P] Manual validation per `specs/006-promotions-news/quickstart.md` (С6 placeholder image, С7 errors, без авторизации)
- [x] T034 Update `specs/006-promotions-news/spec.md` **Status** to `Implemented` after all tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Foundational
- **US2 (Phase 4)**: Depends on US1 screen shell (`PromotionsScreen` with chips + notifier)
- **US3 (Phase 5)**: Depends on US2 card tap + list navigation target
- **Polish (Phase 6)**: Depends on US1–US3

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| **US1** (P1) | Phase 2 only | Chips + type filter + empty state |
| **US2** (P1) | US1 screen | Single-column feed cards + sort order |
| **US3** (P2) | US1 + US2 | Detail page + HTML + back preserves chip |

### Parallel Opportunities

- **Phase 1**: T003 ∥ T004
- **Phase 2**: T005 ∥ T006 ∥ T007; T010 after T008–T009
- **US1 tests**: T013 ∥ T014 ∥ T015
- **US1 impl**: T016 before T017–T018
- **US2 tests**: T019 ∥ T020 ∥ T021; **US2 impl**: T022 before T023–T024
- **US3 tests**: T025 ∥ T026 ∥ T027; **US3 impl**: T028 before T029–T030

### Parallel Example: User Story 1

```bash
# Tests first (parallel):
flutter test test/core/utils/date_formatter_test.dart
flutter test test/features/promotions/promotions_notifier_test.dart
flutter test test/features/promotions/promotion_type_chips_test.dart

# Then implementation:
# T016 promotion_type_chips.dart
# T017–T018 promotions_screen.dart + test update
```

### Parallel Example: User Story 2

```bash
# Tests (parallel):
flutter test test/features/promotions/promotions_repository_test.dart
flutter test test/features/promotions/promotion_article_card_test.dart
flutter test test/features/promotions/promotions_screen_test.dart

# Implementation:
# T022 promotion_article_card.dart
# T023–T024 wire list + navigation
```

### Parallel Example: User Story 3

```bash
# Tests (parallel):
flutter test test/core/network/mock_api_client_promotions_test.dart
flutter test test/features/promotions/promotion_html_body_test.dart
flutter test test/features/promotions/promotion_detail_screen_test.dart

# Implementation:
# T028 promotion_html_body.dart → T029 detail screen → T030 router
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: `flutter test test/features/promotions/` — chips + filter + empty state
5. Demo filter-only promotions tab

### Incremental Delivery

1. Setup + Foundational → API ready
2. **US1** → Filter Chips + type switching (MVP)
3. **US2** → content feed with cards
4. **US3** → detail page + safe HTML
5. **Polish** → integration + quickstart

### Suggested MVP Scope

**User Story 1** (Phase 3) — минимальный инкремент: Filter Chips «Все»/«Акции»/«Новости» с перезагрузкой ленты и пустым состоянием.

---

## Notes

- Эндпоинты promotions **без** JWT (публичный контент, FR-015)
- Пагинация **не** входит в scope — полный список из одного API-ответа
- При смене чипа: `ScrollController.jumpTo(0)` + reload notifier (как смена категории в каталоге)
- `flutter_html` whitelist MUST блокировать `script`/`iframe` (FR-012, SC-005)
- Заголовок вкладки остаётся «Акции» (`AppStrings.tabPromotions`); чипы — «Все»/«Акции»/«Новости» внутри экрана
- Заменяет пустое состояние из `001-init-app-shell` на `PromotionsScreen`

---

## Task Summary

| Phase | Tasks | Count |
|-------|-------|-------|
| Setup | T001–T004 | 4 |
| Foundational | T005–T012 | 8 |
| US1 | T013–T018 | 6 |
| US2 | T019–T024 | 6 |
| US3 | T025–T030 | 6 |
| Polish | T031–T034 | 4 |
| **Total** | | **34** |

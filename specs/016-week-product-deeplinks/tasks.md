---

description: "Список задач для фичи «Признак Товар недели и диплинки»"
---

# Tasks: Признак «Товар недели» и диплинки

**Input**: Design documents from `/specs/016-week-product-deeplinks/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Для основного функционала тесты ОБЯЗАТЕЛЬНЫ (конституция, принцип III): unit,
widget и integration тесты включены для каждой user story.

**Organization**: Задачи сгруппированы по user story для независимой реализации и проверки.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Можно выполнять параллельно (разные файлы, нет зависимостей от незавершённых задач)
- **[Story]**: User story из spec.md (US1–US4)
- В описании указан точный путь к файлу

## Path Conventions

- **Flutter (Osetrovich)**: `lib/`, `test/`, `integration_test/`, `openapi/`
- Структура согласно [plan.md](./plan.md)
- Контракты: `contracts/deeplink-schema.yaml`, `contracts/push-deeplink-v2.yaml`, `contracts/openapi-delta.yaml`

---

## Phase 1: Setup (Подготовка фичи)

**Purpose**: Зависимости, строки локализации, проверка OpenAPI

- [x] T001 Add `app_links: ^6.3.2` to `pubspec.yaml`; run `flutter pub get`
- [x] T002 [P] Add `badgeProductOfWeek` («Товар недели») to `lib/core/l10n/app_strings.dart`
- [x] T003 [P] Verify `productOfWeek` is present and required in `ProductSummary` and `ProductDetail` in `openapi/openapi.yaml` (reference `specs/016-week-product-deeplinks/contracts/openapi-delta.yaml`; no schema change if already merged)

---

## Phase 2: Foundational (Блокирующая инфраструктура)

**Purpose**: Модель `productOfWeek`, моки, ядро диплинков, нативная регистрация схемы — MUST завершить до user stories

**⚠️ CRITICAL**: User story work не начинается до завершения этой фазы

- [x] T004 [P] Extend `lib/features/catalog/domain/product.dart`: add required `productOfWeek` (bool) to `ProductSummary` and `ProductDetail`; update `fromJson` per data-model.md §1
- [x] T005 Update `lib/core/network/mock_api_client.dart`: set `productOfWeek: true` for weekly product ids (e.g. 1000, 1001) and 1–2 catalog items; `false` for others per research.md §10
- [x] T006 [P] Create `lib/core/deeplink/deeplink_target.dart`: class `DeepLinkTarget` with `path`, `categoryId?`, `isFallback` per data-model.md §2
- [x] T007 Create `lib/core/deeplink/deeplink_resolver.dart`: `DeepLinkResolver.resolve(String url)` mapping all 9 routes + fallback per `contracts/deeplink-schema.yaml`
- [x] T008 Create `lib/core/deeplink/deeplink_navigation.dart`: `navigate(GoRouter, WidgetRef, DeepLinkTarget)` — `selectedCategoryIdProvider` + `productsNotifierProvider.selectCategory` side-effect before `router.go`
- [x] T009 [P] Create `lib/core/deeplink/deeplink_providers.dart`: `deepLinkResolverProvider`, `appLinksProvider` (if needed)
- [x] T010 [P] Add `intent-filter` for `osetrovich` scheme (`VIEW`, `DEFAULT`, `BROWSABLE`) to `android/app/src/main/AndroidManifest.xml` per `contracts/deeplink-schema.yaml`
- [x] T011 [P] Add `CFBundleURLTypes` with scheme `osetrovich` to `ios/Runner/Info.plist` per `contracts/deeplink-schema.yaml`
- [x] T012 [P] Unit-тест парсинга `productOfWeek` в `test/features/catalog/product_model_test.dart` (true/false/missing key fails)
- [x] T013 [P] Unit-тест `DeepLinkResolver` (all 9 routes, invalid path, invalid int id, fallback) в `test/core/deeplink/deeplink_resolver_test.dart`
- [x] T014 [P] Update product fixtures repo-wide: add `productOfWeek: false` to `ProductSummary`/`ProductDetail` constructors in `test/features/catalog/product_card_test.dart`, `test/features/catalog/product_grid_test.dart`, `test/core/network/mock_api_client_products_test.dart`, and other failing tests

**Checkpoint**: Модель, моки, резолвер и нативная схема готовы — можно начинать user stories

---

## Phase 3: User Story 1 — Бейдж «Товар недели» на карточках товара (Priority: P1) 🎯 MVP

**Goal**: Покупатель видит бейдж «Товар недели» на карточке в каталоге и в ленте «Товары недели», если `productOfWeek = true`

**Independent Test**: Открыть каталог с товаром `productOfWeek: true` → бейдж виден; `false` → бейджа нет; на главной те же правила (quickstart С1–С2)

### Tests for User Story 1 (ОБЯЗАТЕЛЬНО)

> **NOTE: Написать тесты ПЕРВЫМИ; убедиться, что они падают до реализации**

- [x] T015 [P] [US1] Extend `test/features/catalog/product_promo_badges_test.dart`: badge «Товар недели» when `productOfWeek: true`; order Товар недели → Акция → СПЕЦЦЕНА; style dark+accent
- [x] T016 [P] [US1] Update `test/features/catalog/product_card_test.dart`: card with `productOfWeek: true` shows badge text from `AppStrings.badgeProductOfWeek`
- [x] T017 [P] [US1] Update `test/features/home/home_weekly_products_section_test.dart`: weekly product with `productOfWeek: true` renders badge on card

### Implementation for User Story 1

- [x] T018 [P] [US1] Extend `lib/features/catalog/presentation/widgets/product_promo_badges.dart`: add `productOfWeek` param; badge style `_BadgeStyle.productOfWeek` (`AppColors.dark` bg, `AppColors.accent` text) per research.md §2
- [x] T019 [US1] Pass `productOfWeek` into `ProductPromoBadges` from `lib/features/catalog/presentation/widgets/product_card.dart`
- [x] T020 [US1] Verify `lib/features/home/presentation/home_weekly_products_section.dart` uses `ProductCard` — badge appears automatically after T019 (no duplicate badge logic)

**Checkpoint**: Бейдж «Товар недели» отображается в каталоге и на главной; widget-тесты зелёные

---

## Phase 4: User Story 2 — Переход по диплинку из статьи (Priority: P1)

**Goal**: Ссылки `osetrovich://…` в HTML теле акций/новостей открывают целевой экран внутри приложения; `https://` — во внешнем браузере

**Independent Test**: Открыть статью с ссылкой `osetrovich://catalog/product/1000` → страница товара; внешняя ссылка → браузер (quickstart С3–С4)

### Tests for User Story 2 (ОБЯЗАТЕЛЬНО)

- [x] T021 [P] [US2] Extend `test/features/promotions/promotion_html_body_test.dart`: tap `osetrovich://catalog/product/1000` calls `DeepLinkNavigation` / `GoRouter.go`; tap `https://…` calls `launchUrl`

### Implementation for User Story 2

- [x] T022 [US2] Update `lib/features/promotions/presentation/widgets/promotion_html_body.dart`: in `onLinkTap`, if URL starts with `osetrovich://` — resolve via `DeepLinkResolver` and navigate with `DeepLinkNavigation`; else `launchUrl` (FR-007)
- [x] T023 [US2] Add sample `osetrovich://` links in mock promotion article HTML in `lib/core/network/mock_api_client.dart` (e.g. link to product and catalog category) for manual QA

**Checkpoint**: Диплинки из статей работают; внешние ссылки не сломаны

---

## Phase 5: User Story 3 — Переход по диплинку из push-уведомления (Priority: P1)

**Goal**: Push с URL `osetrovich://…` или JSON `{ "deeplink": "..." }` ведёт на целевой экран; legacy JSON (008) и пустой payload (011) сохранены

**Independent Test**: Симулировать payload `osetrovich://notifications/notif-1` → деталь уведомления; legacy `{ type: product, targetId: "1000" }` → товар; пустой → список уведомлений (quickstart С5)

### Tests for User Story 3 (ОБЯЗАТЕЛЬНО)

- [x] T024 [P] [US3] Extend `test/core/push/push_deeplink_handler_test.dart` per `contracts/push-deeplink-v2.yaml`: raw URL; JSON `deeplink`/`url` priority over `type`; legacy JSON; empty → `/home/notifications`

### Implementation for User Story 3

- [x] T025 [US3] Extend `lib/core/push/push_deeplink_handler.dart`: resolution order — (1) raw `osetrovich://`, (2) JSON `deeplink`/`url`, (3) legacy `type`/`targetId`, (4) fallback `/home/notifications`; delegate URL paths to `DeepLinkResolver`
- [x] T026 [US3] Update `lib/core/push/push_navigation_setup.dart` if needed: ensure `navigate` uses extended handler (category side-effects require `WidgetRef` — pass ref or apply category in handler via callback from setup)

**Checkpoint**: Push-навигация по URL и обратная совместимость 008/011 работают

---

## Phase 6: User Story 4 — Открытие диплинка извне приложения (Priority: P2)

**Goal**: Ссылки `osetrovich://…` из ОС (adb/xcrun) открывают приложение на целевом экране (cold start и из фона)

**Independent Test**: `adb shell am start -d "osetrovich://promotions"` → раздел «Акции и Новости» (quickstart С6)

### Tests for User Story 4 (ОБЯЗАТЕЛЬНО)

- [x] T027 [P] [US4] Create `integration_test/deeplink_flow_test.dart`: pump app, invoke `DeepLinkResolver` + `router.go` for `osetrovich://catalog` and `osetrovich://home`; assert correct route/screen

### Implementation for User Story 4

- [x] T028 [US4] Create `lib/core/deeplink/deeplink_navigation_setup.dart`: `AppLinks().getInitialLink()` on bootstrap + `uriLinkStream` subscription → `DeepLinkNavigation.navigate`
- [x] T029 [US4] Wire `deeplinkNavigationSetupProvider` in `lib/app.dart` alongside `pushNavigationSetupProvider(router)`

**Checkpoint**: Внешние диплинки обрабатываются на обеих платформах

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Регрессии, анализ, валидация quickstart

- [x] T030 [P] Run `flutter test` for `test/core/deeplink/`, `test/core/push/`, `test/features/catalog/`, `test/features/promotions/`; fix any regressions from `productOfWeek` field
- [x] T031 Run `flutter analyze`; ensure zero errors
- [x] T032 Execute manual scenarios from `specs/016-week-product-deeplinks/quickstart.md` (С1–С8); document any gaps in plan.md Complexity Tracking if needed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **User Stories (Phase 3–6)**: Depend on Foundational
  - US1 (бейдж) — независима от US2–US4 после Phase 2
  - US2 (статьи) — зависит от `DeepLinkResolver` + `DeepLinkNavigation` (Phase 2)
  - US3 (push) — зависит от `DeepLinkResolver` (Phase 2); может идти параллельно с US2 после T007–T008
  - US4 (app_links) — зависит от `DeepLinkNavigation` (Phase 2); после или параллельно US2/US3
- **Polish (Phase 7)**: Depends on all desired user stories

### User Story Dependencies

| Story | Зависит от | Независимый тест |
|-------|------------|------------------|
| US1 (P1) | Phase 2 (модель + моки) | Бейдж в каталоге/главной |
| US2 (P1) | Phase 2 (резолвер + навигация) | Ссылка в HTML статьи |
| US3 (P1) | Phase 2 (резолвер) | Push payload → экран |
| US4 (P2) | Phase 2 + US3 желательно (единый navigate) | adb/xcrun intent |

### Within Each User Story

- Tests MUST be written first and FAIL before implementation
- US1: model (Phase 2) → badges widget → product_card
- US2–US4: resolver (Phase 2) → source-specific wiring (HTML / push / app_links)

### Parallel Opportunities

- **Phase 1**: T002 ∥ T003
- **Phase 2**: T004 ∥ T006 ∥ T009 ∥ T010 ∥ T011 ∥ T012 ∥ T013; then T005, T007, T008 sequentially
- **After Phase 2**: US1 ∥ US2 ∥ US3 (разные файлы); US4 после T028 или параллельно с US2/US3
- **Within US1**: T015 ∥ T016 ∥ T017; T018 ∥ (after T015)

---

## Parallel Example: User Story 1

```bash
# Tests first (parallel):
T015: test/features/catalog/product_promo_badges_test.dart
T016: test/features/catalog/product_card_test.dart
T017: test/features/home/home_weekly_products_section_test.dart

# Implementation (parallel after tests):
T018: lib/features/catalog/presentation/widgets/product_promo_badges.dart
# T019 depends on T018
```

## Parallel Example: User Stories 2 + 3

```bash
# After Phase 2 complete, two developers:
Developer A: T021–T023 (article HTML links)
Developer B: T024–T026 (push handler extension)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (модель + моки; deeplink core можно отложить для чистого MVP бейджа — но Phase 2 целиком рекомендуется до merge)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: quickstart С1–С2
5. Demo бейджа «Товар недели»

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 → бейдж в каталоге и на главной (MVP контракта API)
3. US2 → диплинки из статей (контент-маркетинг)
4. US3 → диплинки из push (ретеншн)
5. US4 → внешние intent (полный контракт FR-005)
6. Polish → регрессии и quickstart

### Suggested MVP Scope

**User Story 1** (бейдж «Товар недели») — минимальная ценность при обновлении OpenAPI.
Диплинки (US2–US4) — следующий инкремент; US2 и US3 — P1, US4 — P2.

---

## Notes

- Детальный экран товара **без** бейджей (как фича 009) — только парсинг `productOfWeek`
- Внутренний маршрут статей: `/promotions/article/{id}`; внешний диплинк: `promotions/articles/{id}`
- `DeepLinkNavigation` MUST принимать `WidgetRef` для категории каталога
- Commit after each task or logical group; stop at any checkpoint to validate story independently

## Task Summary

| Phase | Tasks | Count |
|-------|-------|-------|
| Setup | T001–T003 | 3 |
| Foundational | T004–T014 | 11 |
| US1 (P1) | T015–T020 | 6 |
| US2 (P1) | T021–T023 | 3 |
| US3 (P1) | T024–T026 | 3 |
| US4 (P2) | T027–T029 | 3 |
| Polish | T030–T032 | 3 |
| **Total** | **T001–T032** | **32** |

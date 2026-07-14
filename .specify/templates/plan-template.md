# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart 3.x / Flutter (stable channel)

**Primary Dependencies**: Flutter SDK, state management (указать в research.md), HTTP-клиент, OpenAPI tooling

**Storage**: Локальное хранилище по необходимости (shared_preferences, secure_storage); сервер — REST API

**Testing**: flutter test (unit + widget), integration_test

**Target Platform**: Android + iOS

**Project Type**: mobile-app (Flutter, магазин osetrovich.ru)

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] **Flutter multi-platform**: решение покрывает Android и iOS без дублирования логики
- [ ] **Русский UI**: все пользовательские тексты на русском
- [ ] **Тесты**: для основного функционала запланированы unit, widget и/или integration тесты
- [ ] **Flutter best practices**: слоистая архитектура, нет бизнес-логики в виджетах
- [ ] **Tab Bar**: корневая навигация через нижний Tab Bar (или обосновано отклонение)
- [ ] **OpenAPI + моки**: изменения API отражены в OpenAPI; моки соответствуют контракту
- [ ] **Русские спеки**: spec.md и связанные артефакты на русском языке
- [ ] **Фирменная палитра**: UI использует `#252A2F`, `#213C57`, `#FFB400`, `#F4F5F5` через ThemeData
- [ ] **JWT-авторизация**: защищённые эндпоинты через Bearer token; токены в secure storage

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
lib/
├── core/                 # общие утилиты, тема, роутинг, DI
├── features/             # feature-first модули (presentation/domain/data)
└── main.dart

test/                     # unit + widget тесты
integration_test/         # сквозные сценарии

openapi/                  # OpenAPI-спецификация REST API
└── [моки по контракту — в lib/ или test/fixtures/]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |

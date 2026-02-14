---
description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Watermark**: [mode] — [what this means for task depth]
**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories and acceptance criteria), design/research.md, design/data-model.md, design/contracts/

## Task Format

```text
- [ ] [TaskID] [Story?] Description with file path
```

- **Task ID**: Sequential (T001, T002...) in execution order
- **[Story]**: Which user story (e.g., [US1], [US2]) — REQUIRED for story phase tasks, omitted for Setup/Foundational/Polish
- Include exact file paths in descriptions
- Parallel execution is determined by the Dependency Graph section, not inline markers

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project — adjust based on plan.md structure

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Acceptance criteria from spec.md (placed with each story)
  - Feature requirements from plan.md
  - Entities from design/data-model.md
  - Endpoints from design/contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Validated against its acceptance criteria via the validator agent
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 0: Implementation Setup

**Purpose**: Verify project infrastructure and hydrate tasks into the native task system. These tasks are executed by the `/implement` command before any code is written.

- [ ] T000 Verify project setup (CLAUDE.md exists, .gitignore configured, ignore files present)
- [ ] TPRE Hydrate all tasks from this file into the native task system (TaskCreate for each task + gate, TaskUpdate for dependencies)
- [ ] TVER Verify hydration correctness (task count matches, no circular deps, gates positioned correctly)

⟶ **Phase 0 must complete before any implementation code is written.**

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [ ] T003 Setup database schema and migrations framework
- [ ] T004 Implement authentication/authorization framework
- [ ] T005 Create base models/entities that all stories depend on
- [ ] T006 Configure error handling and logging infrastructure

---

## Phase 3: User Story 1 — [Title] (P1)

**Goal**: [Brief description of what this story delivers]

**Acceptance Criteria** (from spec.md):
1. [Observable action] → [Expected output]
2. [Observable action] → [Expected output]
3. [Observable action with threshold/boundary] → [Expected output]

**Codebase Pointers** (from /tasks exploration):
- [Pattern reference: e.g., "Handler pattern: see `src/handlers/existing.py` — class with service injection, method per endpoint"]
- [Registration point: e.g., "Register routes in `src/routes.py` at line ~30"]
- [Test pattern: e.g., "See `tests/test_existing.py` — pytest fixtures with mock service, parametrize for edge cases"]
- [Related files: e.g., "`src/models/shared.py` may need new fields"]

### Tasks

- [ ] T007 [US1] Implement [Entity1] model and [Entity2] model in src/models/[entities].py
- [ ] T008 [US1] Implement [Service] with [endpoint/feature] in src/services/[service].py, register in src/[location]/[routes].py
- [ ] T009 [US1] Write tests for US1 in tests/test_[feature].py

⟶ **VALIDATOR GATE (US1)**: ACs 1-3

**Verification Steps**:
1. AC1: Run `[test command]` → expect PASS
2. AC2: Run `[specific command or curl]` → expect [specific output]
3. AC3: Run `[specific command]` → expect [specific output]

---

## Phase 4: User Story 2 — [Title] (P2)

**Goal**: [Brief description of what this story delivers]

**Acceptance Criteria** (from spec.md):
1. [Observable action] → [Expected output]
2. [Observable action] → [Expected output]

**Codebase Pointers** (from /tasks exploration):
- [Relevant patterns, files, and notes for this story]

### Tasks

- [ ] T010 [US2] Implement [Service + endpoint] in src/services/[service].py, register in src/[location]/[routes].py
- [ ] T011 [US2] Write tests for US2 in tests/test_[feature].py

⟶ **VALIDATOR GATE (US2)**: ACs 1-2

**Verification Steps**:
1. AC1: Run `[test command]` → expect PASS
2. AC2: Run `[specific command]` → expect [specific output]

---

## Phase 5: User Story 3 — [Title] (P3)

**Goal**: [Brief description of what this story delivers]

**Acceptance Criteria** (from spec.md):
1. [Observable action] → [Expected output]

**Codebase Pointers** (from /tasks exploration):
- [Relevant patterns, files, and notes for this story]

### Tasks

- [ ] T012 [US3] Implement [Service + endpoint] in src/services/[service].py
- [ ] T013 [US3] Write tests for US3 in tests/test_[feature].py

⟶ **VALIDATOR GATE (US3)**: AC 1

**Verification Steps**:
1. AC1: Run `[test command]` → expect PASS

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization across all stories
- [ ] TXXX Security hardening

---

## Dependency Graph

This section is machine-parseable and used for native Tasks hydration during implementation.

### Phase dependencies
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase N

### Task dependencies
T000 → TPRE                      # Setup before hydration
TPRE → TVER                      # Hydration before verification
TVER → T001                      # Phase 0 complete before Phase 1
T001 → T002
T002 → T003, T004               # T003/T004 are parallel
T003, T004, T005, T006 → T007   # All foundational must complete before US1
T007, T008 → T009               # Models before services
T009 → T010                     # Service before endpoints
T010 → T011                     # Core before error handling
T011 → GATE_US1                 # Gate waits for all US1 tasks
GATE_US1 → T012                 # US2 starts after US1 gate passes
T012 → T013
T013 → T014
T014 → T015
T015 → GATE_US2                 # Gate waits for all US2 tasks
GATE_US2 → T016                 # US3 starts after US2 gate passes
T016 → T017
T017 → T018
T018 → GATE_US3

### Parallel groups
GROUP_1: T003, T004              # Independent foundational, different files
GROUP_2: T007, T008              # Independent models, different files: src/models/entity1.py, src/models/entity2.py

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **MANDATORY**: Validator gate must pass for US1 before proceeding
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Validator gate passes → Deploy/Demo (MVP)
3. Add User Story 2 → Validator gate passes → Deploy/Demo
4. Add User Story 3 → Validator gate passes → Deploy/Demo
5. Each story adds value without breaking previous stories

### Notes

- Each user story should be independently completable and testable via its acceptance criteria
- Validator gates between stories ensure quality before proceeding
- Parallel execution opportunities are defined in the Dependency Graph section
- Commit after each task or logical group
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

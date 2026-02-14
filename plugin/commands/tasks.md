---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/check-prerequisites.sh --json` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities AND acceptance criteria)
   - **Optional**: design/data-model.md (entities), design/contracts/ (API endpoints), design/research.md (decisions), quickstart.md (test scenarios)
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Read watermark**: Extract the watermark from spec.md metadata. This determines task depth:
   - **spike**: Implementation tasks only, no test tasks, no validator gates. Findings document is the output.
   - **poc**: Implementation tasks only, validator gates included.
   - **demo**: Implementation tasks only, validator gates included.
   - **mvp**: Implementation tasks + integration test-writing tasks, validator gates included.
   - **production**: Implementation tasks + unit/integration/e2e test-writing tasks, validator gates included.
   - **refactor**: Implementation tasks + maintain test coverage tasks, validator gates included.
   - **tech-debt**: Implementation tasks + targeted test tasks, validator gates included.

4. **Extract acceptance criteria**: From spec.md, extract the acceptance criteria for each user story. Each AC must be:
   - An observable action (API call, UI interaction, data query)
   - With an expected output (response code, UI state, data value)
   - Independently verifiable
   - Include threshold/boundary where applicable

   Place these ACs directly under each user story heading in the generated tasks.md.

5. **Explore target codebase** (the lead engineer step):

   Before generating tasks, explore the actual project to understand where changes will land. Use an Explore agent or direct file reads to examine:

   - **Existing file structure**: What files exist at the paths referenced in plan.md? What patterns do they follow?
   - **Modification targets**: Which existing files will be modified (not just created)? What's their current structure?
   - **Registration/wiring points**: Where do new components need to be registered? (e.g., route registration, dependency injection, module exports)
   - **Related files that may need updating**: What else references the areas being changed? (e.g., shared types, configuration, imports)
   - **Test patterns**: How are existing tests structured? What test runner and assertion patterns are used?

   This exploration produces three outputs used in task generation:
   - **Codebase pointers**: File paths, line ranges, and notes for each story (e.g., "Look at `src/handlers/existing_handler.py` for the handler pattern — class with service injection, method per endpoint, error wrapping")
   - **Natural task groupings**: Which changes land in the same file and should be one task (e.g., three handlers in one file = one task, not three)
   - **Verification commands**: For each story, the concrete commands to verify it works (e.g., `[test runner] [test file/pattern]`, `curl localhost:[port]/api/[endpoint]`)

6. **Execute task generation workflow**:
   - Load plan.md and extract tech stack, libraries, project structure
   - Load spec.md and extract user stories with priorities (P1, P2, P3...)
   - If design/data-model.md exists: Extract entities and map to user stories
   - If design/contracts/ exists: Map endpoints to user stories
   - If design/research.md exists: Extract decisions for setup tasks
   - **Use codebase exploration results** to scope tasks: group changes by file, include codebase pointers in task descriptions, collapse same-file work into single tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate validator gate markers with verification steps between user stories (except at spike watermark)
   - Generate dependency graph (see Dependency Graph Generation below)
   - Validate task completeness (each user story has all needed tasks, independently testable)

7. **Generate tasks.md**: Use `.specify/templates/tasks-template.md` as structure, fill with:
   - Correct feature name from plan.md
   - Watermark and its meaning in the header
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
     - **Codebase Pointers** per story: file paths, patterns, and notes from the exploration step — these give the implementing agent "look here, check this" context that minimises search time
     - Each story includes: goal, acceptance criteria from spec.md, implementation tasks
     - At mvp+ watermark: include test-writing tasks alongside implementation tasks
     - Validator gate marker with **Verification Steps** after each story's tasks (except spike) — concrete commands derived from the exploration step
   - Final Phase: Polish & cross-cutting concerns
   - Dependency Graph section at bottom
   - Implementation Strategy section
   - Clear file paths for each task

8. **Report**: Output path to generated tasks.md and summary:
   ```
   Tasks generated: [total]
     - Setup: [count]
     - Foundational: [count]
     - US1: [count]
     - US2: [count]
     - ...
     - Polish: [count]
   Validator gates: [count]
   Parallel groups: [count] ([total tasks in parallel groups] tasks)
   Dependencies: [count]
   Acceptance criteria coverage: [covered]/[total] (all ACs have validator gate)
   Watermark: [mode]
   ```

9. **Update decisions.md**: Record the task generation approach and any decisions made (e.g., task ordering rationale, which tasks were included/excluded based on watermark, codebase exploration findings).

10. **Update session-summary.md**: Update `FEATURE_DIR/session-summary.md` — mark `/tasks` as `done` in the Pipeline Progress table. Add task count and validator gate count to notes column.

11. **Stage Completion Gate**: Before reporting, verify this stage's outputs. **All checks must pass — if any fail, fix the gap before proceeding.**

    **Artifact checks** (file must exist and be non-empty):
    - [ ] `FEATURE_DIR/tasks.md` — generated with task list
    - [ ] `FEATURE_DIR/decisions.md` — Gate Decisions has `/tasks` entry
    - [ ] `FEATURE_DIR/session-summary.md` — `/tasks` row updated

    **Content checks**:
    - [ ] tasks.md has `## Dependency Graph` section with phase deps, task deps, and parallel groups
    - [ ] Every user story phase has acceptance criteria from spec.md
    - [ ] Every user story phase has codebase pointers from exploration step
    - [ ] Every user story (except spike watermark) has a validator gate marker with verification steps
    - [ ] No parallel groups contain tasks targeting the same file
    - [ ] All task IDs are sequential and unique
    - [ ] session-summary.md Pipeline Progress shows `/tasks` as `done`

    If any check fails: **STOP**. Fix the gap. Re-verify. Do not skip.

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable — each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and validation.

### Task Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label
   - User Story phases: MUST have story label
   - Polish phase: NO story label
4. **Description**: Clear action with exact file path

**Examples**:

- `- [ ] T001 Create project structure per implementation plan`
- `- [ ] T005 Implement authentication middleware in src/middleware/auth.py`
- `- [ ] T012 [US1] Create User model in src/models/user.py`
- `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`

### Acceptance Criteria Placement

Each user story phase MUST include its acceptance criteria from spec.md, placed immediately after the story heading:

```markdown
## Phase 3: User Story 1 — [Title] (P1)

**Goal**: [Brief description]

**Acceptance Criteria** (from spec.md):
1. GET /api/status returns 200 with JSON body containing "version", "db_status"
2. When DuckDB is accessible, db_status = "connected"
3. When DuckDB is not accessible, db_status = "disconnected" and endpoint still returns 200
```

### Validator Gate Markers

Between each user story phase (except at spike watermark), place a validator gate with **Verification Steps** — the concrete commands the validator will run to verify the story works. These are derived from the codebase exploration (Step 5) and represent how to test each AC:

```markdown
⟶ **VALIDATOR GATE (US1)**: ACs 1-3

**Verification Steps**:
1. AC1: Run `[test runner] [test file/pattern for this story] -v` → expect PASS
2. AC2: Start app with valid config, run `curl localhost:[port]/api/[endpoint]` → expect 200 with [expected fields]
3. AC3: Start app with invalid config, run `curl localhost:[port]/api/[endpoint]` → expect [degraded response behaviour]
```

Each verification step specifies: which AC it tests, what command to run, and what the expected outcome is. The validator executes these commands and reports PASS/FAIL per AC.

**If implementation adjustments change what was built**: Update the verification steps before dispatching the validator. Record the change as an Adjustment in decisions.md.

### Codebase Pointers

Each user story phase MUST include a **Codebase Pointers** section after the acceptance criteria. These come from the exploration step (Step 5) and give the implementing agent the "look here, check this" context:

```markdown
**Codebase Pointers** (from /tasks exploration):
- Handler pattern: see `src/handlers/[existing_handler]` — [describe the pattern: class/struct structure, method signatures, error handling approach]
- Registration: new components registered in `src/[config_or_routes_file]` at [location hint]
- Test pattern: see `tests/[existing_test_file]` — [describe the pattern: fixtures, mocks, assertion style]
- Related: `src/[shared_module]/` may need updates if new types or shared logic is introduced
```

These pointers minimise the search time during implementation — the agent knows where to look before it starts coding.

### Task Organization

1. **From User Stories (spec.md)** — PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story: models, services, endpoints, UI
   - At mvp+ watermark: include test-writing tasks in the story phase

2. **From Contracts**: Map each endpoint to the user story it serves

3. **From Data Model**: Map each entity to its user story. If entity serves multiple stories, put in earliest story or Foundational phase.

4. **From Setup/Infrastructure**: Shared → Setup phase. Foundational/blocking → Foundational phase. Story-specific → within that story's phase.

5. **From Codebase Exploration**: Group changes that land in the same file into a single task. If multiple handlers all go in one file, that's one task with a checklist, not separate parallel tasks that can't actually parallelize.

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites — MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Models → Services → Endpoints → Integration
  - At mvp+ watermark: Test tasks alongside implementation
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns

## Dependency Graph Generation

The tasks command MUST generate a `## Dependency Graph` section at the bottom of tasks.md. This section is machine-parseable and used by the implement command for native Tasks hydration.

### Parallelism Identification Rules

Apply these rules when determining which tasks can run in parallel:

1. **Phase boundaries are hard dependencies** — all Phase N tasks must complete before Phase N+1
2. **Within a phase, default is sequential** unless parallelism criteria met
3. **Parallelism criteria** (ALL must be true):
   - Different target files (parsed from task descriptions and verified during codebase exploration)
   - No data dependency (task B doesn't reference output of task A)
   - No shared state mutation (both don't modify the same service/module)
4. **Same-file rule**: If multiple tasks target the same file, they MUST be collapsed into a single task (with a checklist if needed). Do NOT create parallel groups for same-file tasks — they can't actually parallelize and create false expectations in the DAG.
5. **Validator gates** depend on ALL tasks in their story
6. **Next story's first task** depends on previous story's validator gate

### Dependency Graph Format

```markdown
## Dependency Graph

### Phase dependencies
Phase 1 → Phase 2 → Phase 3 → Phase 4

### Task dependencies
T001 → T002
T002 → T003, T004, T005    # T003/T004/T005 are parallel
T003, T004, T005 → T006    # All foundational must complete
T006 → T007                 # Sequential chain
T008, T009 → GATE_US1       # Gate waits for all US1 tasks
GATE_US1 → T010             # Next story starts after gate

### Parallel groups
GROUP_1: T003, T004, T005   # Reason: independent foundational, different files
GROUP_2: T008, T009          # Reason: backend + frontend, independent
```

Each parallel group MUST include a reason referencing the different target files.

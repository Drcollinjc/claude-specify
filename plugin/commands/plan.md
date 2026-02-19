---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. The script also creates the `design/` subdirectory. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC, `FEATURE_DIR/decisions.md`, `.specify/memory/product-principles.md` (product thesis), and `.specify/memory/constitution.md` (engineering constitution). Load IMPL_PLAN template (already copied). Read `.claude/rules/session-workflow.md` for pipeline stage context.

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section (two-document model: product thesis alignment + engineering constitution check)
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate `design/research.md` (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate `design/data-model.md`, `design/contracts/`, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design (both thesis and engineering constitution)

4. **Post-planning**: Record decisions, update session-summary.md, run Stage Completion Gate, then report. See Post-Planning Steps section below.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents** using the Task tool with `subagent_type: "Explore"` and `model: "haiku"`:
   - **Why haiku**: Research subagents retrieve and summarise existing information — they don't make architectural decisions. Haiku is sufficient for information gathering and costs ~10x less than Opus. The implementing agent synthesises the research into decisions using the main model.

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
       → subagent_type: "Explore", model: "haiku"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
       → subagent_type: "Explore", model: "haiku"
   ```

3. **Consolidate findings** in `design/research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: `design/research.md` with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `design/research.md` complete

1. **Data Model Handling**:
   - **If `design/data-model-draft.md` exists** (from `/architecture` Phase 2.5):
     - Copy `design/data-model-draft.md` → `design/data-model.md`
     - Skip data model generation (already validated during architecture phase)
     - Reference validated schemas in contracts

   - **If `design/data-model-draft.md` does NOT exist**:
     - Extract entities from feature spec → `design/data-model.md`
     - Entity name, fields, relationships
     - Validation rules from requirements
     - State transitions if applicable
     - **Warning**: No validation against actual data sources (consider running `/architecture` first)

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `design/contracts/`
   - Reference `design/data-model.md` schemas for request/response types

3. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
   - **Verify**: Check exit code. If script is not found or fails, WARN but continue (non-blocking).
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: `design/data-model.md` (from draft or generated), `design/contracts/*`, quickstart.md, agent-specific file

## Post-Planning Steps

4. **Record decisions**: Update `FEATURE_DIR/decisions.md` with planning decisions — technology choices resolved, alternatives rejected, and any gate decisions.

5. **Update session-summary.md**: Update `FEATURE_DIR/session-summary.md` — mark `/plan` as `done` in the Pipeline Progress table. List generated design artifacts in notes column (e.g., "research.md, data-model.md, contracts/status-api.yaml, quickstart.md").

6. **Stage Completion Gate**: Before reporting, verify this stage's outputs. **All checks must pass — if any fail, fix the gap before proceeding.**

   **Artifact checks** (file must exist and be non-empty):
   - [ ] `IMPL_PLAN` (plan.md) — populated with technical context (not template placeholders)
   - [ ] `FEATURE_DIR/design/research.md` — research decisions documented
   - [ ] `FEATURE_DIR/design/data-model.md` — entities defined (if data involved)
   - [ ] `FEATURE_DIR/design/contracts/` — at least one contract file (if API involved)
   - [ ] `FEATURE_DIR/quickstart.md` — integration scenarios documented
   - [ ] `FEATURE_DIR/decisions.md` — Gate Decisions has `/plan` entry
   - [ ] `FEATURE_DIR/session-summary.md` — `/plan` row updated

   **Content checks**:
   - [ ] plan.md Technical Context has no unresolved "NEEDS CLARIFICATION" markers
   - [ ] plan.md Constitution Check section is filled (all principles evaluated)
   - [ ] decisions.md has planning decisions recorded
   - [ ] session-summary.md Pipeline Progress shows `/plan` as `done`

   If any check fails: **STOP**. Fix the gap. Re-verify. Do not skip.

7. **Report**: Command ends after planning. Report branch, IMPL_PLAN path, and generated artifacts (all design artifacts under `design/`).

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications

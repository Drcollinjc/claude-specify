---
description: Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Goal

Identify inconsistencies, duplications, ambiguities, and underspecified items across the three core artifacts (`spec.md`, `plan.md`, `tasks.md`) before implementation. This command MUST run only after `/tasks` has successfully produced a complete `tasks.md`.

## Operating Constraints

**READ-ONLY for spec.md, plan.md, and tasks.md**: Do **not** modify these planning artifacts. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

**WRITABLE**: `decisions.md` (for gate recording), `session-summary.md` (for stage tracking), and checklist files in `checklists/` (for evaluation marks).

**Two-Document Authority**: Both the product thesis (`.specify/memory/product-principles.md`) and the engineering constitution (`.specify/memory/constitution.md`) are authoritative within this analysis scope. Engineering constitution conflicts are automatically CRITICAL. Product thesis conflicts are flagged as HIGH (they indicate potential scope or value misalignment). Neither may be diluted, reinterpreted, or silently ignored. If a principle itself needs to change, that must occur via the `/constitution` command outside `/analyze`.

## Execution Steps

### 1. Initialize Analysis Context

Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md
- DECISIONS = FEATURE_DIR/decisions.md
- DESIGN_DIR = FEATURE_DIR/design/

Abort with an error message if any required file is missing (instruct the user to run missing prerequisite command).
For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From spec.md:**

- Overview/Context
- Functional Requirements
- Non-Functional Requirements
- User Stories
- Edge Cases (if present)

**From plan.md:**

- Architecture/stack choices
- Data Model references (check `design/data-model.md` if referenced)
- Phases
- Technical constraints

**From design/ artifacts** (if they exist):

- `design/research.md`: Technology decisions
- `design/data-model.md`: Entity definitions
- `design/contracts/`: API contracts

**From tasks.md:**

- Task IDs
- Descriptions
- Phase grouping
- Dependency Graph section (parallel groups, task dependencies, validator gates)
- Referenced file paths
- Acceptance criteria per user story

**From product thesis:**

- Load `.specify/memory/product-principles.md` for product value alignment

**From engineering constitution:**

- Load `.specify/memory/constitution.md` for engineering principle validation

### 3. Build Semantic Models

Create internal representations (do not include raw artifacts in output):

- **Requirements inventory**: Each functional + non-functional requirement with a stable key (derive slug based on imperative phrase; e.g., "User can upload file" → `user-can-upload-file`)
- **User story/action inventory**: Discrete user actions with acceptance criteria
- **Task coverage mapping**: Map each task to one or more requirements or stories (inference by keyword / explicit reference patterns like IDs or key phrases)
- **Product thesis rule set**: Extract thesis principles and their values/costs
- **Engineering constitution rule set**: Extract principle names and MUST/SHOULD normative statements

### 4. Detection Passes (Token-Efficient Analysis)

Focus on high-signal findings. Limit to 50 findings total; aggregate remainder in overflow summary.

#### A. Duplication Detection

- Identify near-duplicate requirements
- Mark lower-quality phrasing for consolidation

#### B. Ambiguity Detection

- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`, etc.)

#### C. Underspecification

- Requirements with verbs but missing object or measurable outcome
- User stories missing acceptance criteria alignment
- Tasks referencing files or components not defined in spec/plan

#### D. Constitution & Thesis Alignment

- Any requirement or plan element conflicting with an engineering constitution MUST principle (CRITICAL)
- Any feature scope that violates a product thesis value (HIGH — e.g., crossing intelligence/execution boundary per Thesis §6, missing explainability per Thesis §2/§10)
- Missing mandated sections or quality gates from constitution

#### E. Coverage Gaps

- Requirements with zero associated tasks
- Tasks with no mapped requirement/story
- Non-functional requirements not reflected in tasks (e.g., performance, security)
- **Acceptance criteria coverage**: Do all user stories have testable ACs? Are all ACs covered by a validator gate in the Dependency Graph?
- **Validator gate completeness**: Does every user story have a corresponding validator gate? Are ACs observable and independently verifiable?
- **User Journey Test coverage**: Does every user story have a User Journey Test section with executable Playwright MCP steps? If missing, flag as MEDIUM (validator gates will still run engineering ACs, but user-perspective validation is missing).
- **Intelligence Eval coverage** (if spec has Intelligence Eval Requirements section): Are eval rubrics defined for each LLM chain step? Are satisfaction thresholds set? Are fixture requirements described? If the spec declares LLM chain steps but lacks rubrics or thresholds, flag as HIGH.

#### F. Inconsistency

- Terminology drift (same concept named differently across files)
- Data entities referenced in plan but absent in spec (or vice versa)
- Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note)
- Conflicting requirements (e.g., one requires Next.js while other specifies Vue)

#### G. Checklist Evaluation

If `FEATURE_DIR/checklists/` exists and contains checklist files:

1. Load each checklist file
2. For each unchecked item (`- [ ]`), evaluate it against the spec, plan, and tasks:
   - Read the question (e.g., "Are error handling requirements defined for all API failure modes?")
   - Check the relevant spec/plan sections for the answer
   - Mark `- [x]` if the requirement IS adequately specified, leave `- [ ]` if it is NOT
3. Write the evaluated checklist back to the file
4. Include checklist evaluation results in the analysis report:
   - Per-checklist: total items, passed, failed
   - Failed items feed into the findings table as coverage gaps

This is the "run the unit tests for requirements" step. `/checklist` generates the tests; `/analyze` runs them.

### 5. Severity Assignment

Use this heuristic to prioritize findings:

- **CRITICAL**: Violates engineering constitution MUST, missing core spec artifact, or requirement with zero coverage that blocks baseline functionality
- **HIGH**: Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion
- **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case
- **LOW**: Style/wording improvements, minor redundancy not affecting execution order

### 6. Produce Compact Analysis Report

Output a Markdown report (no file writes) with the following structure:

## Specification Analysis Report

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| A1 | Duplication | HIGH | spec.md:L120-134 | Two similar requirements ... | Merge phrasing; keep clearer version |

(Add one row per finding; generate stable IDs prefixed by category initial.)

**Coverage Summary Table:**

| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|

**Product Thesis Alignment Issues:** (if any)

**Engineering Constitution Alignment Issues:** (if any)

**Unmapped Tasks:** (if any)

**Metrics:**

- Total Requirements
- Total Tasks
- Coverage % (requirements with >=1 task)
- Ambiguity Count
- Duplication Count
- Critical Issues Count

### 7. Provide Next Actions

At end of report, output a concise Next Actions block:

- If CRITICAL issues exist: Recommend resolving before `/implement`
- If only LOW/MEDIUM: User may proceed, but provide improvement suggestions
- Provide explicit command suggestions: e.g., "Run `/specify` with refinement", "Run `/plan` to adjust architecture", "Manually edit tasks.md to add coverage for 'performance-metrics'"

### 8. Record Analysis Gate Decision

Update `FEATURE_DIR/decisions.md` under Gate Decisions:
- Record analysis outcome (PASS/BLOCK)
- Record CRITICAL issue count and summaries
- Record gate decision rationale

### 9. Offer Remediation

Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply them automatically.)

### 10. Update session-summary.md

Update `FEATURE_DIR/session-summary.md` — mark `/analyze` as `done` in the Pipeline Progress table. Add analysis outcome (PASS/BLOCK) and issue counts to notes column.

### 11. Stage Completion Gate

Before completing, verify this stage's outputs. **All checks must pass — if any fail, fix the gap before proceeding.**

**Artifact checks** (file must exist and be non-empty):
- [ ] `FEATURE_DIR/decisions.md` — Gate Decisions has `/analyze` entry with outcome
- [ ] `FEATURE_DIR/session-summary.md` — `/analyze` row updated
- [ ] If checklists exist: all checklist files have been evaluated (no unchecked items that should be checked)

**Content checks**:
- [ ] Analysis report was output to user (findings table, coverage summary, metrics)
- [ ] decisions.md gate entry includes PASS/BLOCK and CRITICAL issue count
- [ ] session-summary.md Pipeline Progress shows `/analyze` as `done`

If any check fails: **STOP**. Fix the gap. Re-verify. Do not skip.

## Operating Principles

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation
- **Progressive disclosure**: Load artifacts incrementally; don't dump all content into analysis
- **Token-efficient output**: Limit findings table to 50 rows; summarize overflow
- **Deterministic results**: Rerunning without changes should produce consistent IDs and counts

### Analysis Guidelines

- **NEVER modify spec.md, plan.md, or tasks.md** (read-only for planning artifacts; decisions.md, session-summary.md, and checklists/ are writable)
- **NEVER hallucinate missing sections** (if absent, report them accurately)
- **Prioritize engineering constitution violations** (these are always CRITICAL)
- **Flag product thesis violations** (these are HIGH — scope/value misalignment)
- **Use examples over exhaustive rules** (cite specific instances, not generic patterns)
- **Report zero issues gracefully** (emit success report with coverage statistics)

## Context

$ARGUMENTS

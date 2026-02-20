# Release: Spec-Driven Development Refactor

**Branch**: `006-spec-driven-refactor`
**Base**: `7d025d7` (Phases 1-5) + flow fixes + constitution redesign
**Date**: 2026-02-10
**Scope**: Engineering plugin architecture, pipeline flow, constitution v5.0.0

---

## 1. What This Release Is

This release transforms a personal AI-assisted development workflow into **organisational engineering infrastructure** — a reusable plugin that governs how software is specified, planned, and built across projects and teams.

The work happened in three waves:
1. **Phases 1-5** (committed `7d025d7`): Structural refactor of commands, templates, scripts, and rules
2. **Flow fixes** (9 fixes, 11 files): Bug fixes and consistency improvements discovered during Level 1-2 testing
3. **Constitution redesign** (v4.0.0 → v5.0.0): Two-document governance model with product thesis, translation mechanism, and technology-agnostic engineering principles

---

## 2. Why This Exists

### The Problem

The original system worked for one person on one project. It had:
- 7 engineering principles, but only 3 were universal — the rest baked in AWS, DuckDB, Python, and demo-stage assumptions
- A single constitution that mixed product values, engineering constraints, and technology decisions
- Pipeline commands that loaded an "orchestrator" from GitHub at runtime
- No governance model for how principles evolve as the org grows

### The Organisational Infrastructure Reframing

The turning point in the design was recognising that this system is not a personal workflow — it is infrastructure for a future engineering org of 3-5 people with distinct roles. Every decision was re-evaluated against: **"Does this work with a Product Owner, Architect, Lead Engineer, Developer, and QA person, each owning different gates?"**

This reframing produced:
- Gate-to-role mapping (PO → /specify, Architect → /architecture, Lead Eng → /plan + /tasks, Developer → /implement, QA → validator agent)
- "Humans at judgment points, AI at labour points" as the core philosophy
- A constitution that any team on any stack can follow

---

## 3. Architecture Decisions

### 3.1 Plugin Structure (D01)

The `.specify/` directory is the portable plugin. `.claude/` is project-local configuration.

```
.specify/                              # Org-level plugin (versioned)
  commands/ → .claude/commands/        # Pipeline commands (installed)
  templates/                           # Artifact templates
  scripts/                             # Automation (bash)
  rules/                               # Plugin-level rules
    constitution-translation.md        # Translation mechanism
  memory/
    product-principles.md              # Product thesis
    constitution.md                    # Engineering constitution (derived)

.claude/                               # Project-level (not portable)
  commands/                            # Commands (from plugin)
  rules/                               # Project-specific rules
    cloud-architecture.md              # This project's tech patterns
    duckdb-patterns.md                 # This project's DB patterns
  agents/                              # Agent definitions
```

**Why**: The plugin travels between projects. Project-specific technology rules stay local. When the org updates the thesis, all projects get the update via `/constitution sync`.

### 3.2 Two-Document Governance Model (C1, C14)

**Before**: One constitution mixing product values, engineering principles, and technology standards.

**After**: Three layers with distinct change frequencies and audiences.

| Layer | File | Audience | Changes |
|-------|------|----------|---------|
| Product Thesis | `.specify/memory/product-principles.md` | Whole org | Rarely |
| Engineering Constitution | `.specify/memory/constitution.md` | Engineers + AI agents | When thesis changes or practice evolves |
| Project Configuration | `.claude/rules/`, `CLAUDE.md` | Project team | With project evolution |

The thesis defines **values with explicit costs** (11 resolved tensions + 4 unresolved). The engineering constitution derives **constraints** from those values via a formal translation mechanism.

### 3.3 Watermark System (D03)

Watermark controls **task TYPE**, not task count. Scope controls count.

| Watermark | Test Tasks? | Validator Agent? |
|-----------|-------------|-----------------|
| spike | No | No |
| poc | No | Yes |
| demo | No | Yes |
| mvp | Integration tests | Yes |
| production | Unit + integration + e2e | Yes |

**Why**: A demo and an MVP might have the same number of tasks, but MVP tasks include test-writing tasks. Granularity is constant; the type of work at each task varies with watermark.

### 3.4 Validator Agent (D04)

A separate agent with **structurally restricted tools** (read-only — cannot use Write or Edit). Dispatched at story gate boundaries during `/implement`.

**Why it's non-negotiable**: Documented failures in Features 003, 004, and 005 where checkboxes were marked complete but acceptance criteria were not actually met. The validator produces binary PASS/FAIL reports with diagnostic pointers. The implement agent must reproduce failures locally before re-dispatching.

### 3.5 Native Tasks Hydration (D06)

One-way: `tasks.md` → Claude native Tasks. Never syncs back.

**Why**: `tasks.md` is a gate-approved planning artifact. It's immutable after `/analyze` approval. Execution state lives in native Tasks. If they diverge, the planning artifact is still the source of truth for what was approved.

### 3.6 Mandatory /analyze Gate (D20)

`/analyze` runs automatically at the start of `/implement`. Blocks if CRITICAL issues found. This is the quality gate between planning and execution.

### 3.7 DAG Representation in tasks.md (D15)

The Dependency Graph section in `tasks.md` is machine-parseable with explicit phase dependencies, task dependencies, parallel groups with rationale, and validator gates.

**Parallelism rules** (D16): Phase boundaries are hard deps. Within a phase, tasks can run in parallel only if they touch different files, have no data dependency, and share no state.

---

## 4. The Six Engineering Principles (v5.0.0)

Derived from the product thesis via the translation mechanism. Each is technology-agnostic, testable by `/analyze`, and imposes a real cost.

### I. Requirements Are Contracts
*From Thesis §3 (Trust Above All)*

Validation is binary. Specs are source of truth. No "close enough." Consistency across modules is a trust dimension.

**Cost**: Every deviation requires stop-and-ask, slowing velocity when specs are still finding shape.

### II. Explainability is Architectural
*From Thesis §2 (AI as Collaborator) + §10 (AI Transparency)*

Every AI feature includes an explanation mechanism. Explanation is structural, not cosmetic. Inferential leaps must be explicit.

**Cost**: Every AI feature takes longer because the explanation layer is mandatory at all stages.

### III. Respect the Product Boundary
*From Thesis §6 (Intelligence Layer Boundary)*

We build intelligence, not execution. Specs describing execution-layer functionality violate this principle. Human-in-the-loop for external system pushes.

**Cost**: We leave execution-layer revenue on the table and depend on third-party integration quality.

### IV. Terminology is Invariant
*From Thesis §11 (Terminology is Invariant)*

Domain terms fixed early, consistent everywhere. Renaming is deliberate and propagated simultaneously.

**Cost**: Early naming decisions carry more weight than feels comfortable.

### V. Architecture for Change
*From Thesis §8 (Freedom With Focus)*

Interface-first design. Type 1/Type 2 decision classification. Tech selection weighted: local testability > language alignment > developer experience > iteration speed > cost > operational simplicity. All features testable on laptop.

**Cost**: Interface-first takes longer upfront. Selection weighting may exclude cheaper tools.

### VI. Learning is Intentional
*From Thesis §9 (Learning is Core)*

Assumptions tracked. Uncertainty zones identified before implementation. Learnings captured at story boundaries. The engineering flow itself evolves on evidence.

**Cost**: Tracking and capturing learnings takes time that could be spent building.

### What Was Dropped and Why

| Old Principle | Disposition | Rationale |
|--------------|-------------|-----------|
| I. Demo-First Development | Dropped | Planning discipline, not constitutional. Conflicts with watermark system. Vertical slice delivery lives in /tasks. |
| II. AWS Infrastructure Foundation | → `.claude/rules/cloud-architecture.md` | Technology-specific. A Go team on GCP can't use it. |
| IV. Component Testing | Dropped | Superseded by watermark system. "No unit tests required" contradicts production watermark. |
| VI. Pragmatic Observability | → `.claude/rules/` + CLAUDE.md | Universal part folded into Architecture for Change. CloudWatch/Lambda specifics to project rules. |
| VII. Developer Experience | → Architecture for Change | Tech selection criteria absorbed into Principle V. |

---

## 5. Translation Mechanism

The bridge between thesis and constitution. Encoded at `.specify/rules/constitution-translation.md`.

### How It Works

For each thesis principle:
1. **Identify** engineering domains it touches
2. **Articulate violations** — what would break this value?
3. **Invert** into MUST/SHOULD statements
4. **State the engineering cost** (no watermark-specific language)
5. **Define the /analyze check**
6. **Consolidate** — multiple thesis principles may converge on one engineering principle

### Three-Gate Assessment for Updates

When the thesis changes:

- **Gate 1**: Does it touch engineering? (If purely product/culture → no update)
- **Gate 2**: Do existing principles already catch the violations? (If yes → no update)
- **Gate 3**: Does the proposed principle pass the universality test? (Applicable across stacks? Testable by /analyze? Not duplicating existing?) — If fails → route to `.claude/rules/` as project-specific

**Overfitting signal**: >1 new principle per quarter suggests over-constraint.

---

## 6. Pipeline Flow

```
/specify → /clarify → [/architecture] → /plan → /tasks → /checklist → /analyze → /implement
```

### Thesis Awareness by Command

| Command | Thesis | Eng Constitution | Output Format |
|---------|--------|-----------------|---------------|
| /specify | Full check | No | Inline flags |
| /clarify | Full check | No | Inline flags |
| /architecture | Full check | Full check | Formal section (table) |
| /plan | Full check | Full check | Formal section (table) |
| /tasks | No | No | Downstream of validated artifacts |
| /checklist | Full check | No | Inline flags, thesis-informed items |
| /analyze | Full check | Full check (primary) | Formal analysis report |
| /implement | No | No | Executes validated plan |

**Key decision (C10)**: All commands do a FULL check against ALL principles — no "light" vs "full" distinction. This prevents coupling between commands and specific principles. When the thesis evolves, commands don't need updating.

---

## 7. Design Process & How We Got Here

### The Raw Materials

The design emerged from a multi-session collaborative process:

1. **Initial conversation** — 131KB of back-and-forth exploring architecture, debating trade-offs, resolving contested decisions
2. **Architecture agreement** — Structural decisions captured, but reasoning was thin
3. **Forensic critique** — 20 issues found where context compaction distorted or omitted reasoning. Key finding: documents were 70% structurally correct but only 30% correct on reasoning
4. **Design thesis** — The WHY document. Captured contested nature of decisions, both positions in debates, and the specific failures/evidence that made decisions non-negotiable
5. **Decision register** — 22 decisions (D01-D22) with status, rationale, and nuance
6. **Implementation plan** — 5 phases with per-file specs and verification steps
7. **Testing plan** — 3-level strategy (incremental → synthetic → real feature)
8. **Constitution redesign** — 16 decisions (C1-C16) redesigning the governance model

### Critical Turning Points

1. **Organisational infrastructure reframing**: The user clarified this isn't a personal workflow — it's for a future 3-5 person org. This reversed positions on constitution scope, gate count, artifact count, and task granularity.

2. **Validator agent evidence**: 4 documented failures in prior features (003, 004 issues 6-7, 005) where self-reported validation was incorrect. Made the validator's structural tool restrictions non-negotiable.

3. **Watermark TYPE vs COUNT**: The user explicitly corrected an early misunderstanding. Watermark controls what KIND of tasks exist (with/without tests), not how MANY. Scope controls count.

4. **Context compaction risk**: The forensic critique revealed that AI context compaction loses nuanced reasoning. This led to: (a) saving design artifacts to files early, (b) the PreCompact hook, (c) decisions.md as a compaction-surviving artifact.

5. **Two-document model**: The thesis was already written but conflated with the constitution. Separating them — with a formal translation mechanism — was the breakthrough that made the constitution portable across stacks.

### Lessons Learned (for future iterations)

- Save design artifacts to files EARLY. Context compaction loses nuanced reasoning.
- The WHY behind decisions matters more than the WHAT. Record both positions in debates.
- Don't propose mechanisms that don't exist in Claude Code (e.g., semantic rule matching — only path-based matching is supported).
- Evaluate everything against "does this work with 3-5 engineers with distinct roles?"
- "Close enough" in validation compounds. Binary pass/fail is harder but prevents trust erosion.
- Testing the tooling (Level 2 synthetic feature) catches issues that unit-level checks miss.

---

## 8. Open Questions & Assumptions

These are items that were either explicitly parked, noted as low-confidence agreements, or identified as needing future resolution.

### Parked (Deliberately Deferred)

| Item | Status | When to Revisit |
|------|--------|----------------|
| Retro process design | Parked — flagged as over-elaborate for current scale | When team > 2 people |
| Shape Up integration | Parked — 6-week cycle appealing but not adopted | When scope control becomes a problem |
| Plugin extraction to separate repo | Deferred — Phase 4 of original plan | When applying to second project in different repo |
| Org-standards repo (evolved from claude-skills) | Deferred | When cross-project patterns emerge |
| Human-in-the-loop threshold framework | Unresolved tension in thesis | When building external system integrations |
| Data model flexibility vs correctness boundary | Unresolved tension in thesis | When data model stabilises |
| Cross-platform pattern intelligence | Unresolved tension in thesis | When multi-tenant data patterns emerge |

### Assumptions to Validate

| Assumption | Risk if Wrong | How to Check |
|-----------|--------------|-------------|
| PreCompact hook fires reliably on compaction | Context loss in long sessions | Monitor decisions.md for hook-generated entries |
| Parallel task limit of 2-4 concurrent subagents is practical | Slower implementation or file conflicts | Observe during first multi-story /implement |
| Validator agent structured reports are actionable enough | Tennis problem (back-and-forth without progress) | Watch for >2 validator cycles on same issue |
| Full thesis check on every command doesn't slow the pipeline | Commands become sluggish | Time /specify and /plan runs before and after |
| Technology selection weighting generalises beyond this project | Teams reject the weighting for their context | Apply to the new non-product project as a test |
| One-way tasks hydration doesn't cause execution drift | Approved plan and execution diverge silently | Compare tasks.md to native Tasks completion state |

### Low-Confidence Agreements

These were proposed-and-not-rejected rather than explicitly debated:

- **Mandatory /analyze**: Proposed as part of a batch of changes, accepted as part of blanket approval. The principle is sound but the specific trigger (auto-run at /implement start) hasn't been tested under resistance.
- **design/ subdirectory**: Agreed as a minor point in a large response. Works in practice but could be revisited if artifact count feels excessive for simple features.
- **Checkbox format in tasks.md**: Never explicitly discussed. The DAG representation in the Dependency Graph section makes checkboxes largely moot for execution tracking.

---

## 9. Enforcement Layer (Post Level 3 Testing)

### The Problem

A Level 3 test (applying the plugin to a new project — slack-mcp-server, feature 001-canvas-list-tools) revealed a critical gap: the `.specify` framework defines process correctly but had **zero enforcement** in the three always-loaded locations. After context compaction, the agent lost command instructions and reverted to "code fast" defaults.

10 failures were catalogued (F1-F10): tasks not hydrated, all validator gates skipped, no session-summary.md created, decisions.md not updated, context compaction destroyed process memory.

### Root Cause

Claude Code has three locations that are always loaded into the system prompt and survive context compaction:
- `CLAUDE.md` (project root)
- `.claude/rules/*.md` (all files)
- `MEMORY.md` (auto-loaded)

Command files (`.claude/commands/`) are only loaded when invoked and lost on compaction. The `.specify/` directory must be actively read. The enforcement gap: `.claude/rules/` contained only descriptive context ("session-summary.md tracks progress"), not imperative enforcement ("STOP. Create session-summary.md before writing any code").

### Fixes Applied

1. **Created `.claude/rules/implementation-enforcement.md`** (CRITICAL) — Hard imperative rules: command invocation enforcement, validator gate enforcement, session artifact enforcement, compaction recovery protocol, decisions trace enforcement
2. **Strengthened `.claude/rules/session-workflow.md`** (v2.1.0 → v2.2.0) — Added MANDATORY section with imperative rules at top, compaction recovery protocol referencing PreCompact hook
3. **Added CLAUDE.md bootstrap to `/specify`** — Phase 1.8 creates CLAUDE.md if missing when plugin is applied to a new project
4. **Wired `.claude/rules/verification.md` into gate protocol** — Added Gate Protocol Integration section with trigger mechanism
5. **Added Phase 0 to `tasks-template.md`** — Implementation Setup phase (verify project setup, hydrate tasks, verify hydration) before any code is written

### Key Insight

Descriptive language in rules ("session-summary.md tracks progress") does not override agent defaults. Imperative language ("STOP. YOU MUST create session-summary.md") does. The enforcement layer bridges the gap between process definition (`.specify/`, commands) and agent behaviour (`.claude/rules/`, `CLAUDE.md`, `MEMORY.md`).

---

## 10. Level 3 Review Improvements

### Token & Quality Analysis

A post-implementation review of the Level 3 test produced token usage data and quality scores (Process: 82/100, Code Quality: 72/100). Four improvements were implemented:

### 10.1 Planning Sufficiency Feedback Loop

Added "Planning sufficiency" as a scan domain in per-story and cross-cutting learnings (implement.md Step 10 and Step 13). At each story gate, the agent assesses: "Were the planning artifacts sufficient to implement this story without significant exploration? What was missing?"

This creates a feedback loop: learnings from Feature N improve plan quality for Feature N+1.

### 10.2 Codebase-Aware Task Generation

Added Step 5 to `/tasks`: before generating tasks, explore the actual codebase to understand file structure, existing patterns, and test approaches. This is the "lead engineer scoping" model — understand the codebase, give pointers in the tasks about where changes go and what else is affected.

Three outputs:
- **Codebase Pointers** per story: "look here, check this" context that minimises search time during implementation
- **Natural task groupings**: same-file changes collapsed into one task (eliminates false parallelism)
- **Verification commands**: concrete test commands per story

### 10.3 Verification Steps in Validator Gates

Gate markers now include concrete verification steps — the QA test script:

```markdown
⟶ **VALIDATOR GATE (US1)**: ACs 1-3

**Verification Steps**:
1. AC1: Run `[test command]` → expect PASS
2. AC2: Run `curl localhost:[port]/api/[endpoint]` → expect 200 with [expected fields]
```

The validator executes these steps and reports PASS/FAIL based on command output. This replaces the previous approach where validators received only ACs and had to figure out how to verify them at runtime.

### 10.4 Validator Dispatch via Explore Subagent

The original design specified `.claude/agents/validator.md` as a separate agent with structurally restricted tools. Claude Code's Task tool only supports fixed subagent types. The `Explore` type has exactly the right restrictions:
- CAN read files (Read, Glob, Grep)
- CAN run commands (Bash — for tests, curl, etc.)
- CANNOT use Write, Edit, or Task tools (platform-enforced)

Validator is now dispatched as `Task(subagent_type: "Explore", model: "sonnet")`. This provides structural read-only enforcement at the platform level, plus independent judgment via a different model.

---

## 11. Files Changed in This Release

### New Files (3)
- `.specify/rules/constitution-translation.md` — Translation mechanism + three-gate assessment
- `.specify/memory/product-principles.md` — Product thesis (11 resolved + 4 unresolved tensions)
- `.claude/rules/implementation-enforcement.md` — Process enforcement layer (imperative rules)

### Rewritten (2)
- `.specify/memory/constitution.md` — v5.0.0: 6 technology-agnostic principles
- `.claude/commands/constitution.md` — 4 execution modes for two-document model

### Updated (15)
- `.claude/commands/specify.md` — Thesis awareness + CLAUDE.md bootstrap (Phase 1.8)
- `.claude/commands/clarify.md` — Thesis awareness (inline flags)
- `.claude/commands/plan.md` — Two-document constitution check
- `.claude/commands/analyze.md` — Two-document authority, thesis violations as HIGH
- `.claude/commands/checklist.md` — Thesis-informed checklist items
- `.claude/commands/implement.md` — Enforcement fixes, planning sufficiency learnings, Explore validator dispatch
- `.claude/commands/tasks.md` — Codebase-aware generation (Step 5), verification steps, same-file collapse rule
- `.claude/rules/session-workflow.md` — v2.2.0: MANDATORY section, compaction recovery protocol
- `.claude/rules/verification.md` — Gate Protocol Integration section
- `.specify/scripts/bash/common.sh` — Script fixes
- `.specify/scripts/bash/create-new-feature.sh` — Script fixes
- `.specify/templates/commands/architecture.md` — Two-document alignment section
- `.specify/templates/plan-template.md` — Two-document Constitution Check table
- `.specify/templates/tasks-template.md` — Phase 0, codebase pointers, verification steps in gates
- `CLAUDE.md` — Migrated project-specific standards (resource naming, config mgmt, observability)

---

## 10. How to Apply This to a New Project

1. Copy the `.specify/` directory into the new project
2. Copy `.claude/rules/` into the new project (these are the enforcement rules that survive context compaction)
3. Run `/constitution` to either:
   - **If same org**: The thesis and constitution travel with the plugin. Project-specific rules go in `.claude/rules/`.
   - **If different org**: Use Mode D (interactive creation) to build a new thesis, then derive engineering principles.
4. Add project-specific technology rules to `.claude/rules/` (e.g., the language, framework, and database patterns for this project)
5. Run `/specify` on your first feature — this will create `CLAUDE.md` if missing and the thesis check will flag any misalignment with the product principles
6. Populate the project's `MEMORY.md` with the enforcement protocol summary (compaction recovery, pipeline order, command invocation requirement) — this is the ultimate safety net as MEMORY.md is always loaded

**Enforcement architecture** (three always-loaded locations):
- `CLAUDE.md` — project-level instructions (created by `/specify` if missing)
- `.claude/rules/` — enforcement rules (copied with the plugin, survive compaction)
- `MEMORY.md` — compaction recovery protocol (populated per-project)

The engineering constitution applies universally. The product thesis applies to the org. Project-specific technology choices live in `.claude/rules/` and `CLAUDE.md`.

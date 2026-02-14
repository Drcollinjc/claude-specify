# Session Workflow v2.2.0

## Purpose
Maintain context continuity across pipeline stages through session summary and decision trace updates.

## MANDATORY

These rules are non-negotiable. They apply at ALL times during pipeline execution.

1. **Every pipeline stage MUST update its tracking artifacts.** `/specify` creates `session-summary.md` and `decisions.md`. Every subsequent stage updates them. If you complete a stage without updating these artifacts, STOP and fix it before moving on.

2. **Session artifacts are required for implementation.** If `session-summary.md` or `decisions.md` do not exist when `/implement` starts, earlier stages were skipped. Do NOT proceed — create the artifacts or run the missing stages.

3. **After context compaction, STOP and recover.** The PreCompact hook has already captured a snapshot to `decisions.md`. Before continuing ANY work: (1) read `session-summary.md`, (2) read the PreCompact snapshot in `decisions.md`, (3) run `TaskList`. Do NOT write code until process state is re-established.

## Rules vs Steps

Rules provide **context** — they explain WHY something matters. Commands provide **steps** — they enforce WHAT must happen. If something must happen, it must be a numbered step in a command file, not just a note in a rule. This rule file explains the tracking system; the actual create/update steps are embedded in each command.

## Two Tracking Artifacts

### decisions.md (Human-facing audit trail)
- **Audience**: Lead engineer, architect, auditor
- **Purpose**: Why decisions were made, validation evidence, adjustments
- **Updated by**: Each pipeline skill as its final step

### session-summary.md (AI-facing operational log)
- **Audience**: Claude resuming work in a new session
- **Purpose**: Where things stand — which stages complete, what artifacts exist, current task
- **Updated by**: Each pipeline skill as its final step

## Pipeline Stage Updates

| Stage | decisions.md | session-summary.md |
|-------|-------------|-------------------|
| `/specify` | CREATE — record watermark selection rationale | CREATE — initialize progress table |
| `/clarify` | Record scope-changing clarifications | Update stage status |
| `/architecture` | Record architecture decisions (Type 1/2) | Update stage status, list artifacts |
| `/plan` | Record planning decisions, alternatives rejected | Update stage status, list design artifacts |
| `/tasks` | Record task generation approach | Update stage status, task count |
| `/checklist` | Record any requirement quality issues found | Update stage status |
| `/analyze` | Record analysis gate decision (pass/block) | Update stage status |
| `/implement` | Record progress, validator evidence, adjustments | Update current task, completion status |

## Session Resume Protocol

When resuming work in a new session:
1. Read `session-summary.md` for current state
2. Read `decisions.md` for context on past decisions
3. Check native Tasks (`TaskList`) for execution progress
4. Continue from where the last session left off

## Compaction Recovery Protocol

The PreCompact hook automatically captures a snapshot to `decisions.md` before compaction occurs. After compaction, you lose command instructions but `.claude/rules/` files (including this one) are reloaded.

**IMMEDIATELY after compaction, YOU MUST**:

1. Read `FEATURE_DIR/session-summary.md` — tells you which pipeline stages are complete and what's current
2. Read the PreCompact snapshot in `FEATURE_DIR/decisions.md` — tells you what was happening at compaction time
3. Run `TaskList` — shows native task execution progress (tasks survive compaction)
4. DO NOT continue writing code until you have re-established state from these three sources
5. Resume from where native Tasks indicate you left off

**What survives compaction**:
- Native Tasks (check via `TaskList`)
- `decisions.md` (has PreCompact snapshot)
- `session-summary.md` (has pipeline stage progress)
- `.claude/rules/` files (reloaded into system prompt)
- `MEMORY.md` (reloaded into system prompt)

## Lightweight vs Full Architecture Review

### Use Lightweight Review (in plan.md) when ALL are true:
- Feature builds on existing patterns
- All new components are reversible
- No new external service integrations
- No data migration complexity

### Use Full `/architecture` when ANY are true:
- Introducing new technology stack
- Irreversible data changes
- External service integrations
- Multi-team coordination required
- Security-sensitive changes

## Artifact Directory Convention

- **Feature root** (`specs/NNN-feature-name/`): spec.md, plan.md, tasks.md, decisions.md, session-summary.md, quickstart.md
- **Design subdirectory** (`design/`): research.md, data-model.md, contracts/
- **Checklists subdirectory** (`checklists/`): requirements.md, api.md, security.md, etc.

The `design/` subdirectory is created by `setup-plan.sh` (during `/plan`) and `create-new-feature.sh` (during `/specify`). All commands reference design artifacts under `design/`.

## Anti-Patterns
- Skipping session summary creation at specify stage
- Not updating session summary after each stage
- Starting new sessions without reading session-summary.md
- Capturing only "what" without "why" in decisions log
- Modifying tasks.md during implementation (it's a planning artifact — immutable after gate approval)
- Relying on rules for enforcement — rules provide context, commands provide steps

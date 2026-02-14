---
description: MANDATORY enforcement rules for the .specify pipeline. These rules survive context compaction and override default agent behaviour. Apply during ALL implementation work.
---
# Implementation Enforcement v1.0.0

## Purpose

Enforce the `.specify` pipeline protocol. These rules are ALWAYS loaded and survive context compaction. They bridge the gap between process definition (in `.claude/commands/`) and agent behaviour.

**Why this file exists**: Commands define the right steps but are only loaded when invoked. After context compaction, the agent loses command instructions and reverts to defaults. This file ensures critical process gates are never skipped.

## MANDATORY RULES

### 1. Command Invocation

Implementation MUST be done via the `/implement` command. Do NOT write implementation code outside of `/implement`.

The `/implement` command contains the full protocol: prerequisites, analysis gate, context loading, task hydration, dependency graph execution, validator gates, decisions trace, and session artifact updates.

**If you find yourself writing implementation code without having invoked `/implement`, STOP.** Re-invoke the command. The protocol exists because ad-hoc implementation skips hydration, gates, and tracking — all of which failed in testing.

### 2. Pipeline Order

The pipeline stages MUST run in order. Do NOT skip stages:

```
/specify → /clarify → [/architecture] → /plan → /tasks → /checklist → /analyze → /implement
```

- `/specify` MUST run before `/plan`
- `/tasks` MUST run before `/implement`
- `/analyze` runs automatically at the start of `/implement` — do NOT bypass it

If the user asks to "just implement" without prior stages, warn them that skipping stages increases rework risk. Proceed only with explicit user approval.

### 3. Task Hydration

Before writing ANY implementation code, tasks from `tasks.md` MUST be hydrated into the native task system using `TaskCreate`.

- Parse tasks.md → TaskCreate for each task and gate
- Set dependencies via TaskUpdate with addBlockedBy
- Verify hydration: task count matches, no circular deps, gates correctly positioned

**If tasks are not hydrated, STOP.** The `/implement` command handles this at Steps 7-9. If you're past those steps and tasks aren't hydrated, something went wrong — investigate before proceeding.

### 4. Validator Gates

At every `GATE_USn` marker in tasks.md, YOU MUST dispatch the validator agent using the Task tool with `subagent_type: "Explore"` and `model: "sonnet"`. The Explore subagent has structural tool restrictions — it cannot Write, Edit, or create Tasks. This is platform-enforced.

- **NEVER self-validate.** The implementing agent MUST NOT evaluate acceptance criteria and mark gates as passed. Only the validator agent's structured report can close a gate.
- **NEVER skip gates.** Every user story has a gate. Every gate must be run.
- The validator receives the **verification steps** from tasks.md and verifies by **executing each step and reporting PASS/FAIL based on command output**.
- If the validator agent cannot be dispatched, STOP and inform the user. Do NOT fall back to self-validation.

**Exception**: Skip validator gates at `spike` watermark only.

### 5. Session Artifacts

`session-summary.md` and `decisions.md` MUST exist in FEATURE_DIR before implementation starts.

- `/specify` creates both artifacts. If they don't exist, earlier pipeline stages were skipped.
- If missing when `/implement` starts: create them before writing any code.
- Update `decisions.md` at: implementation start, every gate, every adjustment, completion.
- Update `session-summary.md` at: implementation completion.

### 6. Decisions Trace

Record in `FEATURE_DIR/decisions.md` throughout implementation:

- **At start**: Watermark, task count, timestamp
- **At each gate**: PASS/FAIL with validator evidence summary
- **At adjustments**: What changed, why, impact
- **At issues**: Tech debt or problems discovered
- **At learnings**: Process observations per story + cross-cutting
- **At completion**: Summary with task/gate counts

This is NON-NEGOTIABLE. The decisions trace is the human-facing audit trail and the compaction safety net.

## COMPACTION RECOVERY PROTOCOL

After context compaction, the PreCompact hook has already captured a snapshot to `decisions.md`. You will lose command instructions but NOT these rules.

**IMMEDIATELY after compaction**:

1. Read `FEATURE_DIR/session-summary.md` for pipeline state (which stages complete, current stage)
2. Read the PreCompact snapshot in `FEATURE_DIR/decisions.md` for what was happening at compaction time
3. Run `TaskList` to see native task execution progress
4. DO NOT continue writing code until you have re-established process state from these three sources
5. Resume from where the native Tasks indicate you left off, following the dependency graph

**If session-summary.md or decisions.md don't exist**: Earlier process was not followed. Warn the user. Create them now with what you know from TaskList.

## ANTI-PATTERNS (things that indicate process failure)

- Writing implementation code without TaskCreate having been called
- Marking a GATE task as completed without a validator agent report
- No entries in decisions.md during implementation
- No session-summary.md in the feature directory
- Continuing to code after compaction without reading session artifacts
- "Just coding" without having invoked `/implement`

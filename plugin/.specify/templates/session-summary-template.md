# Session Summary: {Feature Name}

**Feature ID**: {feature-id}
**Session Date**: {YYYY-MM-DD}
**Branch**: {branch-name}
**Watermark**: {spike/poc/demo/mvp/production/refactor/tech-debt}
**Status**: {In Progress/Complete}

## Purpose

This document is for **Claude reading when resuming work** in a new session. It captures where things stand — which pipeline stages are complete, what artifacts exist, and the current task. For the human-facing decision audit trail (why decisions were made, validation evidence), see `decisions.md`.

## Pipeline Progress

| Stage | Status | Artifacts | Notes |
|-------|--------|-----------|-------|
| /specify | {done/pending} | spec.md, decisions.md | |
| /clarify | {done/skipped} | | |
| /architecture | {done/skipped} | | |
| /plan | {done/pending} | plan.md, design/* | |
| /tasks | {done/pending} | tasks.md | |
| /checklist | {done/pending} | checklists/* | |
| /analyze | {done/pending} | | |
| /implement | {done/pending} | | |

---

## Codebase Context Discovered

### Existing Structure

**Relevant Files/Directories**:
- {file/directory}: {purpose/what we found}

**Patterns Observed**:
- {Pattern 1}: {Description}
- {Pattern 2}: {Description}

**Surprises/Gotchas**:
- {Anything unexpected discovered}

---

## Implementation Patterns Established

### Pattern 1: {Pattern Name}

**Pattern**:
```
{Code snippet or pseudocode}
```

**Benefits**: {Why this pattern was chosen}

**Extensibility**: {How this can be extended in future}

---

## Current Execution State

**Current task**: {Task ID and description, or "not yet started"}
**Tasks complete**: {X/Y}
**Current user story**: {US[N] title, or "N/A"}
**Blockers**: {none/description}

---

## Environment Details

### Development Setup

**Dependencies**: {Key dependencies}
**Configuration**: {Important config details}

**Local Testing**:
```bash
# Commands used to test locally
```

### Infrastructure

**Existing Resources**: {AWS resources or other infrastructure}
**New Resources**: {What was added}
**Integration Points**: {How components connect}

---

## For Next Developer / Session

### Resume Instructions

1. Read this file for current state
2. Read `decisions.md` for context on past decisions
3. Check native Tasks (`TaskList`) for execution progress
4. Continue from where the last session left off

### If Continuing This Feature

**To complete deferred work**:
- {Phase/task}: {What needs to be done}
- {Phase/task}: {What needs to be done}

### If Starting New Feature

1. Clear this context
2. Run `/specify` with feature description
3. Follow the pipeline: specify → clarify → plan → tasks → checklist → analyze → implement
4. New session-summary.md is created at `/specify`

---

## Open Questions / TODOs

### Short-term
- [ ] {Question or TODO}
- [ ] {Question or TODO}

### Long-term
- [ ] {Question or TODO}
- [ ] {Question or TODO}

---

## References

**Related Documents**:
- `spec.md` - Feature specification
- `decisions.md` - Decision trace (human-facing audit trail)
- `plan.md` - Implementation plan
- `tasks.md` - Task breakdown
- `quickstart.md` - Testing procedures
- `design/` - Research, data model, contracts

**Code Locations**:
- {Component}: `{file}:{line-range}`

**External Resources**:
- {Link or reference}

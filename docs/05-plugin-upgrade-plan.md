# 05 — Plugin Upgrade Plan (Post slac-mcp-server Retrospective)

**Date**: 2026-03-24
**Claude Code Version**: v2.1.81
**Status**: PLAN — awaiting execution

## Motivation

The first real-world test of the plugin (slac-mcp-server, feature 001-canvas-list-tools) surfaced 6 actionable improvements (issues #5–#8) and Anthropic has released significant Claude Code platform upgrades since mid-February 2026. This plan captures what to adopt, what to defer, and what is currently broken.

## Platform Feature Validation (v2.1.81)

Before planning around new features, we validated which actually work:

| Feature | Status | Evidence |
|---------|--------|----------|
| `model` in agent frontmatter | **Works** | Abstract names (sonnet, haiku, opus) resolve correctly since v2.1.73 |
| `maxTurns` in agent frontmatter | **Works** | No bug reports found |
| `disallowedTools` in agent frontmatter | **Partial** | Blocks named tools; bypassable via Bash (sed, awk, echo). GitHub #31292 |
| `effort` in agent frontmatter | **Not supported** | Only works for skills/commands, not agents. GitHub #34553 |
| `isolation: worktree` in frontmatter | **Broken** | Auth regression in v2.1.81 (#37258); silently ignored for plugin agents (#34775) |
| Rules `globs:` path-scoping | **Partial** | Unquoted CSV format works; YAML arrays and quoted strings broken (#16299, #17204) |

## Phases

### Phase 1 — Quick Wins (Issues #7, #8)

Independent changes, no platform feature dependencies. Can execute in parallel.

#### Issue #7: Same-File Parallel Task Detection

**Problem**: Tasks targeting the same file are marked as parallel in the DAG but cannot actually run in parallel.

**Changes**:

| File | Change |
|------|--------|
| `plugin/commands/tasks.md` | Add same-file collision detection pass after task generation. For each parallel group, parse file paths from task descriptions. If any path appears in >1 task, collapse into single task. |
| `plugin/commands/implement.md` | Strengthen hydration verification: parse file paths for each parallel group, STOP if collision detected. |

#### Issue #8: Happy-Path Test Requirement

**Problem**: Validator gates can pass with only error-case test coverage.

**Changes**:

| File | Change |
|------|--------|
| `plugin/.specify/templates/tasks-template.md` | Add note: at least one AC per story must test the primary successful flow. |
| `plugin/commands/tasks.md` | Add validation: flag stories with only edge-case/error ACs, derive happy-path AC from story goal. |
| `plugin/commands/checklist.md` | Add AC quality rule 5: happy-path coverage check. |
| `plugin/rules/verification.md` | Add to gate protocol: each story gate MUST include at least one happy-path verification step. |

### Phase 2 — Agent Frontmatter Definitions (Issue #10)

**Decision**: Create agent definitions using the features that work (`model`, `maxTurns`, `disallowedTools`). Drop `effort` (not supported for agents). Keep prompt-level reinforcement alongside `disallowedTools` since it is bypassable via Bash.

#### New Files: `plugin/agents/`

**`research.md`**
```yaml
---
model: haiku
maxTurns: 15
disallowedTools:
  - Write
  - Edit
  - NotebookEdit
  - TaskCreate
  - TaskUpdate
---
```
Purpose: Information gathering, codebase exploration. Extracted from plan.md research agent dispatch.

**`file-writer.md`**
```yaml
---
model: sonnet
maxTurns: 30
disallowedTools:
  - TaskCreate
  - TaskUpdate
---
```
Purpose: Structured file creation from explicit instructions. Extracted from implement.md parallel subagent dispatch.

**`validator.md`**
```yaml
---
model: sonnet
maxTurns: 25
disallowedTools:
  - Write
  - Edit
  - NotebookEdit
  - TaskCreate
  - TaskUpdate
---
```
Purpose: Three-layer validation (engineering ACs, user journey tests, intelligence evals). Extracted from implement.md validator dispatch protocol.

**Note on `disallowedTools` bypass**: The Bash tool can still perform file writes via sed/awk/echo. Agent prompts will include explicit instructions: "Do NOT use Bash to write or modify files. Your role is read-only verification." This provides defense-in-depth — platform enforcement catches tool calls, prompt enforcement catches Bash workarounds.

#### Modified Files

| File | Change |
|------|--------|
| `plugin/commands/implement.md` | Replace inline model/subagent_type params with agent definition references for validator and file-writer dispatch. Keep three-layer protocol in implement.md but reference validator agent for execution. |
| `plugin/commands/plan.md` | Replace inline research agent dispatch with reference to `agents/research.md`. |
| `plugin/rules/implementation-enforcement.md` | Rewrite Section 6 (Subagent Model Selection) to reference agent definitions instead of inline parameters. Keep rationale text. |

### Phase 3 — Skills 2.0 Evaluation (Issue #11)

**Recommendation**: Do NOT migrate commands to Skills 2.0.

**Reasons**:
1. Plugin supports 14 AI agents (Gemini, Copilot, Cursor, etc.) — Skills 2.0 is Claude-specific
2. Skills 2.0 is young — the commands pattern is battle-tested
3. Commands already work well; Skills adds abstraction without clear benefit

**Worth revisiting later**:
- `${CLAUDE_PLUGIN_DATA}` for cross-feature state (eval results, learnings database)
- `effort` in skill frontmatter once it reaches agent support

**Deliverable**: This evaluation section serves as the evaluation doc. No separate file needed.

### Phase 4 — Native Worktree Migration (Issue #9) — DEFERRED

**Status**: BLOCKED by two open bugs:
- **#37258**: Auth regression in v2.1.81 — `isolation: worktree` fails with "Not logged in"
- **#34775**: `isolation: worktree` in plugin agent frontmatter is silently ignored

**Decision**: Keep custom `scripts/worktree.sh` approach in consuming projects. The implement.md worktree orchestration protocol (lines 156–187) remains unchanged.

**Trigger to revisit**: When both #37258 and #34775 are closed and verified. At that point:
1. Create `plugin/agents/story-executor.md` with `isolation: worktree`
2. Migrate git plumbing to native; keep port offset + Docker as WorktreeCreate hook
3. Simplify implement.md worktree section

### Bonus — Rules Path-Scoping Test (Issue #2)

The `globs:` CSV format reportedly works in recent versions. Worth testing our rules files with the unquoted CSV format:

```yaml
---
globs: docker/app/**/*.py, docker/app/**/*.sql
---
```

If confirmed working, update all tech-specific rules in `examples/rules/` with appropriate globs. This would reduce context noise significantly.

**Test approach**: Create a test rule with `globs: docker/app/**/*.py` and verify it only loads when working in Python files, not when editing frontend TypeScript.

## Dependency Graph

```
Phase 1a: Issue #7 (same-file detection)  ─┐
Phase 1b: Issue #8 (happy-path ACs)       ─┼─→ Phase 2: Agent Frontmatter (W1)
Phase 3:  Skills 2.0 eval (parallel)      ─┘         │
                                                      │
                                              Phase 4: Worktree (DEFERRED)
```

- Phases 1a, 1b, and 3 have no dependencies — execute in parallel
- Phase 2 can start after Phase 1 completes (implement.md is modified by both)
- Phase 4 is blocked by platform bugs

## File Change Summary

| File | Phase | Action |
|------|-------|--------|
| `plugin/agents/research.md` | 2 | CREATE |
| `plugin/agents/file-writer.md` | 2 | CREATE |
| `plugin/agents/validator.md` | 2 | CREATE |
| `plugin/commands/implement.md` | 1a, 2 | MODIFY |
| `plugin/commands/plan.md` | 2 | MODIFY |
| `plugin/commands/tasks.md` | 1a, 1b | MODIFY |
| `plugin/commands/checklist.md` | 1b | MODIFY |
| `plugin/rules/implementation-enforcement.md` | 2 | MODIFY |
| `plugin/rules/verification.md` | 1b | MODIFY |
| `plugin/.specify/templates/tasks-template.md` | 1b | MODIFY |

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `disallowedTools` bypassed via Bash | High | Medium | Defense-in-depth: platform + prompt enforcement |
| `maxTurns` too low causes incomplete work | Medium | Medium | Conservative defaults, tune after first run (Type 2) |
| Agent frontmatter format changes | Low | Medium | All Type 2 decisions, document migration path |
| implement.md changes introduce regression | Medium | High | Test on refactor task before feature work |
| `effort` added to agents in future version | Likely | Positive | Add when available; plan is forward-compatible |

## Success Criteria

1. All three agent definitions load correctly and enforce model + maxTurns + disallowedTools
2. Validator agent cannot use Write/Edit tools (platform-enforced)
3. Tasks generated by /tasks have no same-file parallel groups
4. Every user story gate includes at least one happy-path verification step
5. Plugin pipeline runs end-to-end on a refactor task with updated definitions

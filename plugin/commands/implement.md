---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

### Step 1: Prerequisites

Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### Step 2: Verify Checklists Evaluated

If FEATURE_DIR/checklists/ exists:
- Scan all checklist files for evaluation status
- `/analyze` should have already evaluated all checklist items (marking `[x]` or `[ ]` based on spec review)
- Create a status table:

  ```text
  | Checklist | Total | Passed | Failed | Status |
  |-----------|-------|--------|--------|--------|
  | ux.md     | 12    | 12     | 0      | PASS   |
  | api.md    | 8     | 5      | 3      | FAIL   |
  ```

- **If any checklist has failed items**: STOP and ask user whether to proceed (failed items indicate spec gaps)
- **If any checklist has unevaluated items** (all `[ ]`, none `[x]`): the `/analyze` step likely didn't run or didn't evaluate. STOP — instruct user to run `/analyze` first.
- **If all items evaluated and passed**: Proceed automatically

### Step 3: Mandatory Analyze Gate

Run the `/analyze` skill automatically before any implementation begins.

- If **CRITICAL** issues found: **STOP**. Report issues to user. Do not proceed until resolved.
- If no CRITICAL issues: Proceed. Record the analysis gate result in FEATURE_DIR/decisions.md under Gate Decisions.

### Step 4: Load Implementation Context

Read from FEATURE_DIR:
- **REQUIRED**: tasks.md (complete task list with dependency graph)
- **REQUIRED**: plan.md (tech stack, architecture, file structure)
- **REQUIRED**: spec.md (user stories, acceptance criteria, watermark)
- **REQUIRED**: decisions.md (decision trace — read for context, write throughout)
- **IF EXISTS**: design/data-model.md (entities and relationships)
- **IF EXISTS**: design/contracts/ (API specifications)
- **IF EXISTS**: design/research.md (technical decisions)
- **IF EXISTS**: quickstart.md (integration scenarios)

Read the watermark from spec.md metadata.

### Step 5: Project Setup Verification

**REQUIRED**: Verify `CLAUDE.md` exists in the repository root. If missing, warn the user: "CLAUDE.md is missing — this file provides always-loaded project instructions. Run `/specify` to create it, or create it manually." Do NOT proceed without user acknowledgment.

**REQUIRED**: Create/verify ignore files based on actual project setup:

**Detection & Creation Logic**:
- Check if git repo: `git rev-parse --git-dir 2>/dev/null` → create/verify .gitignore
- Check if Dockerfile* or Docker in plan.md → create/verify .dockerignore
- Check if .eslintrc* or eslint.config.* exists → create/verify .eslintignore
- Check if .prettierrc* exists → create/verify .prettierignore
- Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
- Check if terraform files (*.tf) exist → create/verify .terraformignore

**If ignore file exists**: Verify essential patterns, append missing critical patterns only.
**If missing**: Create with full pattern set for detected technology.

**Common Patterns by Technology** (from plan.md tech stack):
- **Node.js/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
- **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
- **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
- **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
- **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`
- **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

**Tool-Specific Patterns**:
- **Docker**: `node_modules/`, `.git/`, `*.log*`, `.env*`, `coverage/`
- **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`

### Step 6: Identify Available Tools

Check what tools and services are available:
- MCP servers (Playwright, GitHub, etc.)
- CLI tools (curl, pytest, jest, npm, dbt, etc.)
- Running services (check ports if needed)

This informs what the validator agent can use during gate verification.

### Step 7: Parse Tasks and Build Dependency Graph

Parse tasks.md to extract:

1. **Task list**: Each task's ID, description, story label, file paths
2. **Acceptance criteria**: Per user story (placed under story headings)
3. **Validator gates**: GATE_USn markers between stories
4. **Dependency graph**: From the `## Dependency Graph` section:
   - Phase dependencies
   - Task dependencies (A → B notation)
   - Parallel groups with rationale

### Step 8: Hydrate Native Tasks

One-way hydration: tasks.md → native Tasks. **Never sync back.** tasks.md is a planning artifact, immutable after gate approval.

For each task in tasks.md:
- `TaskCreate` with:
  - **subject**: Task ID + description (e.g., "T007 [US1] Create User model in src/models/user.py")
  - **description**: Full task description including file paths and any relevant context from plan.md
  - **activeForm**: Present continuous (e.g., "Creating User model")

For each validator gate:
- `TaskCreate` with:
  - **subject**: "GATE_USn — Validate acceptance criteria for User Story N"
  - **description**: List of acceptance criteria to verify
  - **activeForm**: "Validating User Story N acceptance criteria"

For each dependency in the graph:
- `TaskUpdate` with `addBlockedBy` to set the dependency

### Step 9: Automated Hydration Verification

Before execution begins, verify hydration correctness:
- Task count matches tasks.md (implementation tasks + gate tasks)
- No circular dependencies in the graph
- Validator gates are correctly positioned (blocked by all story tasks, blocking next story)
- Parallel groups target distinct files (parse file paths from task descriptions)

If verification fails: **STOP**. Report the discrepancy. Do not proceed.

### Step 10: Execute Tasks Following DAG

Execute tasks in dependency order:

**For each ready task** (no unresolved blockedBy):

1. Mark as in_progress: `TaskUpdate` with `status: "in_progress"`
2. Execute the task (write code, create files, run commands)
3. Mark as completed: `TaskUpdate` with `status: "completed"`
4. Check if any dependent tasks are now unblocked

**For parallel groups**: When all tasks in a parallel group are ready (dependencies met), execute them. Use the Task tool to dispatch independent subagents for file-writing tasks on different files. Practical limit: 2-3 concurrent subagents. Wait for all to complete before moving to dependent tasks.

**At validator gates**:

When all tasks for a user story are complete and a GATE_USn task becomes ready:

1. Mark gate as in_progress
2. Dispatch the **validator agent** using the Task tool with `subagent_type: "Explore"` and `model: "sonnet"`:
   - **Why Explore**: The Explore subagent type has structural tool restrictions — it CANNOT use Write, Edit, or Task tools. This is enforced by the platform, not by instruction. This prevents the validator from modifying code or marking its own tasks complete.
   - **Why sonnet**: A different model from the implementing agent provides independent judgment.
   - **No self-validation**: The implementing agent MUST NOT evaluate acceptance criteria itself and mark the gate as passed. Only the validator agent's structured report can close a gate. If dispatch fails, retry — do not fall back to self-validation.
   - Provide the validator with:
     - The **acceptance criteria** for that user story
     - The **verification steps** from tasks.md — these are the concrete test commands to execute
     - **Specific test commands** to run for the project (derived from the codebase exploration during `/tasks`)
     - **File paths** for the implementation (so the validator knows what was built)
     - **Setup instructions** if needed (e.g., "start server with `python -m uvicorn src.main:app`")
   - Include this instruction in the validator's prompt: **"For each acceptance criterion, execute the verification step provided. Run the test command or call the endpoint. Report PASS or FAIL based on the command output. Include the actual output as evidence."**
   - The validator executes the test plan and reports results. This is the QA model: run the steps, observe the output, report what happened.
3. Wait for the validator's structured report
4. **If ALL criteria PASS**:
   - Mark gate as completed
   - Record validation evidence in decisions.md under "Validation Evidence" for that story
   - **Per-story learnings checkpoint**: Before proceeding to the next story, record at least one process observation tagged `[USn]` in the decisions.md Learnings section. Scan these domains:
     - **Requirements**: gaps, ambiguities, or contradictions discovered during coding
     - **Process**: steps that were slow, confusing, skipped, or out of order
     - **Tooling**: scripts, templates, agents, or commands that didn't behave as expected
     - **Architecture**: assumptions from plan.md that proved wrong during implementation
     - **Planning sufficiency**: Were plan.md, research.md, contracts/, and the codebase pointers in tasks.md sufficient to implement this story without significant exploration? What was missing, wrong, or would have saved time?
     - **Other**: anything notable not covered above
   - If nothing was learned: write `[USn] No novel findings`
   - Proceed to next story
5. **If ANY criterion FAILS**:
   - Read the validator's report carefully (exact request, actual response, diagnostic pointer)
   - Fix the issue locally
   - **Reproduce the validator's test locally** before re-dispatching (this is the tennis-breaker)
   - Re-dispatch the validator agent
   - Repeat until all criteria pass
   - Record the fix and re-validation in decisions.md under "Adjustments"

**Skip validator gates at spike watermark** — just proceed to next phase.

### Step 11: Progress Tracking and Error Handling

- Native Tasks track all progress (survives context compaction)
- Report progress after each completed task
- If a non-parallel task fails: halt, investigate, fix before proceeding
- For parallel tasks: if one fails, complete the others, then address the failure
- Record any implementation adjustments in decisions.md under "Adjustments"

### Step 12: Decisions Trace

Throughout implementation, maintain the decisions.md decision trace:

- **At start**: Record implementation start with watermark, task count, and timestamp
- **At each gate**: Record PASS/FAIL with evidence (validator report summary)
- **At adjustments**: Record what changed, why, and impact
- **At issues**: Record any tech debt or issues discovered under "Issues & Tech Debt"
- **At learnings**: Record any insights under "Learnings"
- **At completion**: Record implementation completion summary

### Step 13: Completion

When all tasks and gates are complete:

1. Verify all native Tasks show completed status (`TaskList`)

2. **MANDATORY cross-cutting learnings review**: Per-story learnings were captured at each gate (Step 10). Now review the implementation as a whole for cross-cutting findings that aren't story-specific. Write at least one additional entry to the "Learnings" section in decisions.md (tagged `[cross-cutting]`). Scan these domains:
   - **Requirements**: gaps, ambiguities, or contradictions discovered during coding
   - **Process**: steps that were slow, confusing, skipped, or out of order
   - **Tooling**: scripts, templates, agents, or commands that didn't behave as expected
   - **Architecture**: assumptions from plan.md that proved wrong during implementation
   - **Planning sufficiency**: Overall, did the planning artifacts give the implementing agent what it needed? What should future /plan or /tasks runs capture that this one didn't?
   - **Other**: anything notable not covered above

   If genuinely nothing new beyond per-story findings: write `[cross-cutting] No novel findings beyond per-story observations.`

3. Record completion summary in decisions.md

4. **Update session-summary.md**: Mark `/implement` as `done` in the Pipeline Progress table. Update Current Execution State section with final task count, completion status, and any open issues.

5. **Stage Completion Gate**: Before reporting, verify this stage's outputs. **All checks must pass — if any fail, fix the gap before proceeding.**

   **Artifact checks** (file must exist and be non-empty):
   - [ ] All implementation files created per tasks.md
   - [ ] `FEATURE_DIR/decisions.md` — has `/implement` gate entries, validation evidence for all stories, and Learnings entries (per-story + cross-cutting)
   - [ ] `FEATURE_DIR/session-summary.md` — `/implement` row marked done

   **Content checks**:
   - [ ] All native Tasks show completed status
   - [ ] Every user story has validation evidence in decisions.md (GATE entries with PASS)
   - [ ] Learnings section has at least one entry per completed user story plus one cross-cutting entry
   - [ ] Issues & Tech Debt table is populated (even if empty — confirm it was reviewed)
   - [ ] session-summary.md Pipeline Progress shows `/implement` as `done`

   If any check fails: **STOP**. Fix the gap. Re-verify. Do not skip.

6. Report final status:
   ```
   Implementation complete.
   Tasks: [completed]/[total]
   Validator gates: [passed]/[total]
   Adjustments: [count]
   Issues discovered: [count]
   Learnings captured: [count] ([per-story] + [cross-cutting])
   ```

Note: This command assumes a complete task breakdown exists in tasks.md with a dependency graph section. If tasks are incomplete or missing the dependency graph, suggest running `/tasks` first to regenerate the task list.

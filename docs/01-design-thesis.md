desig# Design Thesis: Spec-Driven Development Plugin Architecture

This document captures the **reasoning, motivations, and contested decisions** that produced the agreed architecture. It is grounded in the actual design conversation and corrects the distortions identified in the forensic critique (04-forensic-critique.md). Where a point was contested and resolved, both positions are recorded.

---

## Part 1: The Foundational Problem

### Why this architecture exists at all

The entire architecture is motivated by a single observation about non-deterministic systems. At its core:

> "We are dealing with non-deterministic systems. This isn't a straightforward abstraction on top of a known deterministic system."
> — (transcript line 1265)

And the organisational consequence:

> "In a world where humans have ownership of these gates, and they report into someone — how can they say they have observability of the process and stand over the work being done by the agents? We need some form of traceability."
> — (transcript line 1265)

This is not about good engineering practice in the abstract. It is about the specific challenge of **governing AI-generated work in an organisation** where people are accountable for outputs they didn't personally produce. The architecture exists to make AI-assisted engineering auditable, traceable, and governable at scale.

### The organisational infrastructure reframing — the turning point

The conversation began with a red team critique (transcript lines 737-887) arguing the process was over-engineered. The critique was specific and forceful:

- "Feature 001 was a health check endpoint — it went through this entire ceremony."
- "9 specification documents for one feature."
- "At some point the process IS the project."
- "The constitution has more governance structure than most startups' entire engineering practices."

This critique was **explicitly retracted** after a pivotal exchange. The user said:

> "I'm using these 5 features to try and develop a workflow that I can codify and then use a commons for my organisation to take once we get more engineers onboard. I'm trying to bring together a rigorous engineering process in order to have longer running tasks that require less human involvement."
> — (transcript line 891-897)

The response:

> "Fair. I was evaluating this as a personal workflow when you're building organisational infrastructure. That changes the calculus significantly."
> — (transcript line 901-903)

This single exchange reversed positions on:

| Decision | Before reframing | After reframing |
|----------|-----------------|-----------------|
| Constitution | "Cut it — merge useful bits into CLAUDE.md" | "Appropriate — codified principles prevent drift across teams" |
| Gate count | "Too many for one person" | "Maps to role boundaries in a future org" |
| Task granularity | "Cap at 20-25 tasks" | "80 tasks enables delegation across developers" |
| Artifact count | "9 documents is excessive" | "A mature team produces all of these" |

**Why this matters**: The architecture is not designed for a solo developer. It is designed for an organisation that doesn't fully exist yet, being tested by a solo developer. Every decision should be evaluated against the question: "Does this work when there are 3-5 engineers with distinct roles?"

---

## Part 2: Core Philosophy

### "Humans at judgment points, AI at labour points"

This was agreed as the governing principle for the entire pipeline (transcript line 1008-1026):

> "What you actually want is: humans at judgment points, AI at labour points."

With a clean boundary:

> "Humans never execute. AI never makes judgment calls."

The explicit mapping:

| Point | Human (judgment) | AI (labour) |
|-------|-----------------|-------------|
| Specification | Approve spec | Generate spec draft |
| Architecture | Approve architecture (Type 1 decisions) | Generate plan + design artifacts |
| Planning | Approve plan | Generate task breakdown |
| Tasks | Approve task breakdown + test coverage | Execute implementation |
| Validation | Review evidence | Run validation (validator agent) |
| Retro | Review and approve learnings | Generate retro summary |

### Gate-to-role mapping

Each gate maps to a future organisational role (transcript line 911-923):

```
SPECIFY      → Product Owner / Stakeholder
ARCHITECTURE → Architect
PLAN         → Lead Engineer
TASKS        → Lead Engineer + QA
IMPLEMENT    → Developer (AI-assisted)
VALIDATE     → QA reviews evidence
RETRO        → Team captures learnings
```

This mapping is foundational to the architecture's purpose. The current single-person "all gates" phase is the testing period for a multi-role workflow. When a lead engineer, QA, and architect join the organisation, each will own their respective gates without needing to restructure the process.

### Traceability as organisational accountability

Even if models become 99.9% reliable, the architecture maintains that:

> "The gates aren't just about catching errors. They're about organisational accountability. A lead engineer who signs off on a plan is taking responsibility for that plan. A QA who reviews validation evidence is attesting to quality. These are human responsibilities that don't disappear with better AI."
> — (transcript line 1523-1527)

The traceability architecture:

```
Every AI-generated artifact has:
├── What was generated (the artifact itself)
├── What context was provided (spec, plan, constraints)
├── What decisions were made (decision trace)
├── Who reviewed and approved (gate owner)
└── What evidence supports it (validation results, test output)
```

---

## Part 3: The Validator Agent — Evidence-Driven, Non-Negotiable

### WHY it exists — the evidence trail

The validator agent is not a "nice to have." It is motivated by specific, documented failures across features:

- **Feature 003**: "44/44 tasks complete, all validation tests passed" — but zero validation tasks were actually defined (transcript line 205)
- **Feature 004, Issue 6**: snake_case/camelCase mismatch — validation tasks were marked [x] while the API was sending the wrong format (transcript line 206)
- **Feature 004, Issue 7**: Status values were wrong — the agent validated its own incorrect assumptions (transcript line 207)
- **Feature 005, TD-001**: JSON format non-determinism — implementation tasks marked complete despite a fundamental assumption being wrong (transcript line 207)

The core insight:

> "The `[x]` checkbox is not evidence of validation. It's evidence that a task was attempted."
> — (transcript line 201-209)

And the structural cause:

> "The same agent that wrote the code is also validating it, in the same context where it 'knows' what it built."
> — (transcript line 202)

### WHAT the validator does

A custom Claude Code agent (`.claude/agents/validator.md`) with **structural separation** — not behavioural, structural:

- **ALLOWED tools**: Read, Glob, Grep, Bash (read-only commands, curl, test runners), Playwright
- **DISALLOWED tools**: Write, Edit, Task, NotebookEdit
- **It literally cannot modify code** — it can only observe and report

This makes the "Agent-as-a-Judge" pattern structural. The validator doesn't "choose" not to edit files — it can't.

### The validator report — solving the "tennis problem"

The user raised a specific concern about "tennis" (transcript line 2144): the implementation agent fixes something it THINKS was the issue, re-dispatches the validator, which finds another issue, back and forth.

The agreed solution has two parts:

**Part 1 — Report specificity.** For each failing acceptance criterion, the validator returns:
1. The exact request made (e.g., `POST /api/icp/chat {"message": "What about manufacturing?"}`)
2. The actual response received (full body)
3. What was expected vs what was found
4. A diagnostic pointer ("Check win rate threshold comparison logic in response generation")

**Part 2 — Reproduce before re-dispatching.** The implementation agent must reproduce the validator's test locally (quick curl/Playwright check) BEFORE re-dispatching the validator. This is the tennis-breaker (transcript line 2171):

> "After fixing a FAIL, reproduce the validator's test locally before re-dispatching."

### When the validator runs

| Watermark | Validator? | What it checks | How |
|-----------|-----------|----------------|-----|
| Spike | No | N/A — findings document only | N/A |
| POC | Yes | "Does the core technical approach work?" | Runs the specific thing being proved |
| Demo | Yes | "Do all acceptance criteria pass?" | curl/Playwright against running app |
| MVP | Yes | ACs + test suite passes | pytest/jest + Playwright + AC checks |
| Production | Yes | ACs + full test suite + performance + security | Full CI-equivalent validation |
| Refactor | Yes | Existing tests still pass + targeted regression | Existing test suite + new regression |
| Tech Debt | Yes | Targeted regression for changed areas | Affected test subsets |

The user explicitly confirmed: "The validator agent scope should run for every watermark including POC... spike is really just a research... I don't think it needs to have anything" (transcript line 1952).

---

## Part 4: The Watermark System

### What the watermark controls (and what it doesn't)

This distinction was carefully established and then oversimplified in the original output documents.

**The watermark controls task TYPE** — whether tests are written alongside implementation.

**SCOPE controls task COUNT** — how many tasks a feature needs is determined by the feature's scope, not by an arbitrary watermark-based cap.

The user's pushback was explicit (transcript line 1636, paraphrased): "I don't like that there are these caps on tasks... I see absolutely no reason why the scope makes sense and that scope is maybe something that should influence what goes into the ultimate set of tasks but I don't think we should be limiting ourselves to the number of tasks."

The agreed response:

> "No task count caps. You're right — scope determines task count, not an arbitrary limit. The watermark influences what KIND of tasks (tests or not), not how many."
> — (transcript line 1924-1926)

And crucially, task granularity remains constant across ALL watermarks:

> "An agent with a vague task ('build the API') drifts. An agent with a specific task ('implement GET /api/summary in routes.py returning SummaryResponse') stays focused. That specificity is needed at EVERY watermark."
> — (transcript line 1384)

### Watermarks defined

| Mode | Scope | Verification | Test artefacts | Validator |
|------|-------|-------------|----------------|-----------|
| **Spike** | Time-boxed investigation | Findings document | None | No |
| **POC** | Prove feasibility | Feasibility check | None | Yes |
| **Demo** | Show value to stakeholders | AC verification | None | Yes |
| **MVP** | Ship to real users | Validator + manual QA | Integration tests | Yes |
| **Production** | Scale and harden | Full CI pipeline | Unit + integration + e2e | Yes |
| **Refactor** | Improve existing code | Regression testing | Existing + new tests | Yes |
| **Tech Debt** | Address known issues | Targeted regression | Targeted tests | Yes |

The task list generated by `/speckit.tasks` is **watermark-specific** — it only includes tasks appropriate for the watermark. No conditional tags like `[MVP+]` in the generated output. If you're at Demo watermark, no test-writing tasks appear. (Agreed at transcript line 1962-1964.)

---

## Part 5: Testing, Validation, and Tasks — The Careful Distinction

### Three things, not one

The conversation carefully distinguished three concerns (transcript line 1448-1453):

1. **Implementation tasks** — Write the feature code
2. **Test tasks** — Write automated tests FOR the feature (produce test FILES that persist in CI)
3. **Validation** — The validator agent checks acceptance criteria are met

### "Tasks are tasks" — what this actually means

The user said (transcript line 1636, paraphrased): "Tasks are tasks... we have the tasks that need to be done and then we have an understanding of whether we're writing tests for the future or we are writing tests and doing validation."

This means:
- **Validation is NOT a task anymore** — it is a structural gate between user stories, performed by the validator agent
- **Test-writing IS still a task** (at MVP+ watermark) — but it's just a task like any other
- The watermark determines whether test-writing tasks are included in the task list
- The task list for any given feature is clean — just the tasks for that watermark

### The tasks.md structure

```markdown
## User Story 1 - Data-Backed Chat (P1)

**Acceptance Criteria**:
1. "What about healthcare?" returns real DuckDB metrics
2. >40% win rate → "Add to Primary ICP" suggested
3. <20% win rate → warning context
4. <5 records → uncertainty callout

### Tasks
- [ ] T007 [US1] Replace mock chat() with real agent call
- [ ] T008 [US1] Implement response parsing
- [ ] T009 [US1] Add win rate threshold logic
- [ ] T010 [US1] Update useICPChat hook

⟶ VALIDATOR GATE: ACs 1-4 verified before next story
```

Acceptance criteria live WITH the story. The validator gate is a structural marker between stories, not a task with an ID. At MVP+ watermark, test-writing tasks would appear naturally in the tasks list.

**Note — checkbox format**: Whether tasks.md retains `- [ ]` checkboxes or drops them was NOT discussed in the conversation. The original output document (02) invented the recommendation to remove checkboxes. This is an open question.

---

## Part 6: Native Tasks and One-Way Hydration

### The problem being solved

The current implementation uses `[x]` checkboxes in tasks.md to track progress. These are fragile — if context compacts, progress tracking is lost. The agent doesn't reliably follow sequence, skips validation, marks things done when they're not.

### The solution

At the start of `/speckit.implement`, parse tasks.md and hydrate into Claude Code's native Task system:

- Each task gets: subject, description, activeForm, dependencies (`addBlockedBy`/`addBlocks`)
- Validator gate tasks are inserted between user stories, blocked by all story tasks
- Dependencies are enforced programmatically — a validator gate CAN'T be skipped because it's blocked by dependencies
- Task state survives context compaction
- `Ctrl+T` gives live progress visibility

### One-way hydration — and WHY

**tasks.md → native Tasks. Never sync back.**

The reason (not captured in the original documents): tasks.md is reviewed and approved at a gate. It is a **planning artifact that should be immutable after gate approval**. Modifying it during implementation would mean the approved artifact changes post-approval.

The user confirmed: "Task as plan only, I'm happy with it just being clean, does not need [progress tracking]" (transcript line 1952).

Execution state lives in native Tasks. The decision trace captures what happened. tasks.md stays as the plan that was approved.

---

## Part 7: decisions.md and session-summary.md — Audience Matters

### The distinction

These serve different audiences (transcript lines 1997-2003):

- **decisions.md** — for HUMANS reviewing the feature's decision history. The audience is a lead engineer, architect, or auditor looking at why decisions were made, what validation evidence exists, and what adjustments happened.

- **session-summary.md** — for CLAUDE reading when resuming work. The audience is the AI agent needing to know where things stand: which stages are complete, what artifacts exist, what's the current task.

### What decisions.md captures

Accumulates through the entire feature lifecycle:

- **Gate decisions**: Which stages passed, what was decided, who reviewed, what adjustments were made and why
- **Validation evidence**: Structured reports from the validator agent (PASS/FAIL per AC with actual output)
- **Issues and tech debt**: Discovered during implementation
- **Learnings**: Insights captured during work
- **Context snapshots**: Captured by PreCompact hook before context compaction

### How gates populate it

Each skill's final step includes "update decisions.md with this stage's trace." This is built into the skill instructions, not a hook. It's part of the workflow, not automation around the workflow (transcript line 1902).

---

## Part 8: Hooks — Deliberately Minimal

### What was proposed and REJECTED

The conversation initially proposed multiple hooks (transcript lines 500-543):
- `TaskCompleted` — auto-trigger retro after every task
- `SubagentStop` — capture validation results when validator finishes
- `SessionStart` — auto-pull latest skills
- `PreCompact` — learning capture before compaction

All except PreCompact were explicitly rejected (transcript lines 1904-1930):

> "You don't need hooks between gates. The gates ARE the natural capture points."
> "No complex hook system. One PreCompact hook. Everything else is skill logic. Hooks are fragile across Claude Code updates."

### What was kept: One PreCompact hook

Fires automatically before Claude Code compacts context. Captures a state snapshot to decisions.md:

- Which tasks are complete
- Which task is in progress
- Current user story
- Any blockers / in-flight decisions
- Key state summary

This ensures continuity across context compaction events. The hook is a simple shell script that reads native Tasks state and appends a snapshot section to decisions.md.

The PreCompact hook fires on both auto compaction (hitting ~95% context capacity) and manual compaction (user triggers `/compact`).

---

## Part 9: Plugin Structure and Claude-Skills Disposition

### The distribution answer

The target is a distributable Claude Code plugin — a package that can be installed into any project. When installed, skills map to `.claude/commands/`, agents to `.claude/agents/`, rules to `.claude/rules/`.

### Claude-skills: what moves, what stays, and WHY the disposition changed

The initial proposal left cloud-architecture.md, data-modeling.md, and duckdb-patterns.md in claude-skills (as "domain knowledge"). The user pushed back (transcript line 1952):

> "Cloud architecture, data modelling, DuckDB patterns... why are they moved into the plugin? I can see how lessons learned retro and skill evolution are part of the meta process but considering architecture data modelling DP patterns would be useful skills for the engineering process."

This was a correction — the user's judgment was better on this point. The response:

> "I was wrong to exclude them. Cloud architecture, data modelling, DuckDB patterns — these are engineering knowledge that supports the engineering process. They go in the plugin under rules/."
> — (transcript line 1970-1972)

**Move to plugin `rules/`** (engineering knowledge):
- thinking.md, verification.md, debugging.md, python-tdd.md, speckit-workflow.md
- cloud-architecture.md, data-modeling.md, duckdb-patterns.md

**Stay in claude-skills** (meta-process and historical record):
- lessons-learned.md, skill-evolution.md, retrospective.md, lesson files

**Delete**: orchestrator/main.md — replaced by Claude Code's native matching.

### The orchestrator removal

The orchestrator is gone (transcript line 1824): "No keyword matching, no skill selection function." Rules load via Claude's native path matching. Skills load via slash commands.

But the claude-skills **repo** is not abandoned. The user's words (transcript line 1251-1253): "I will eventually be turning this into a similar organisation wide repo for managing the standards and best practices we operate under." The orchestrator goes, but the repo transitions into an org knowledge base.

### The two-repo architecture (acknowledged, deferred)

The conversation established two repos (transcript lines 1569-1584):

1. **speckit** (plugin) — engineering process machinery
2. **org-standards** (evolved from claude-skills) — organisational knowledge base serving multiple purposes beyond just Claude Code

However, the user then explicitly deferred the org-standards work (transcript line 1636, paraphrased): "Let's just think about distributing Claude artifacts for the engineering process... we'll take what's relevant for this plugin from claude-skills... get this working really well first before moving onto thinking about other things."

**Current scope is the plugin only.** The org-standards concept was discussed and parked.

---

## Part 10: Naming — OPEN, Not Settled

The user suggested at the very end of the conversation (transcript line 2147):

> "I would also suggest we refactor out the use of the spec kit language to just more SDLC or spec driven development type language."

The response: "Agreed. I'll use simpler, SDLC-aligned names throughout the review. We can settle on the exact prefix later."

**Naming is NOT settled.** The direction (away from "speckit" toward SDLC terminology) is agreed. The specific names have not been workshopped. The original output document (02) listed specific file renames as if they were settled — they are not.

---

## Part 11: The Retro Process — Explicitly Deferred

The conversation produced an elaborate retro tier classification system (Tier 1: Rules, Tier 2: Patterns, Tier 3: Heuristics, Tier 4: Observations) at transcript lines 1489-1516. The user's response (transcript line 1636, paraphrased):

> "The retro process avoiding overfitting... this feels quite over elaborate not necessary... maybe spin up a separate task to research and understand how retro items could fit into the evolution of the plugin architecture."

The agreed response (transcript line 1932-1934): "No retro tier classification yet. You flagged this as over-elaborate and suggested a separate research task. I agree."

**The retro mechanism is explicitly parked.** decisions.md captures learnings. How those learnings evolve into rules/standards is a separate research task, not part of the current scope.

---

## Part 12: The analyze Command — Borderline Agreement

The `/speckit.analyze` command being made mandatory (running automatically at the start of implement) was proposed (transcript line 302-313) and appeared in the adjusted architecture (transcript line 1601): "Runs /speckit.analyze automatically (mandatory, not optional)."

The user did not explicitly approve or reject this specific point — it was part of a large block that received general agreement. This is a **low-confidence agreement** — proposed and not rejected, but not specifically endorsed either.

---

## Part 13: Pipeline Flow

```
/specify [watermark]  → creates spec.md, decisions.md
                      → Gate: human approves spec

/clarify              → resolves ambiguities, updates spec.md

/architecture         → generates architecture decisions
                      → Gate: human approves architecture (Type 1 decisions)

/plan                 → generates plan.md + design/ artifacts
                      → Gate: human approves plan

/tasks                → generates tasks.md (watermark-specific)
                      → [analyze may run automatically — see Part 12]
                      → Gate: human (+ QA at MVP+) approves tasks and test coverage

/implement            → hydrates native Tasks
                      → executes tasks sequentially
                      → dispatches validator agent at story gates
                      → records evidence in decisions.md
                      → PreCompact captures snapshots
                      → Gate: human (+ QA) reviews validation evidence

/retro                → [DEFERRED — see Part 11]
```

Each stage reads decisions.md for context and records its own decisions. The watermark set at `/specify` flows through the entire pipeline.

---

## Part 14: Phased Implementation — Explicitly Agreed

The path from current state to plugin distribution (transcript lines 2114-2136):

1. **Phase 1**: Restructure in this project into a plugin-like layout. Commands become skills. Templates, scripts, and rules reorganise. Validator agent gets created. Does not change how things are invoked.

2. **Phase 2**: Test on the next feature in this project. Run the restructured flow. Test the validator agent, native Tasks hydration, and decision trace.

3. **Phase 3**: Apply to the MCP server project. The user has "a specific piece of work on a separate repo that's a much more straightforward problem... good for testing" (transcript line 1952).

4. **Phase 4**: Extract to a standalone plugin repo. Set up plugin.json manifest. Install into both projects as a proper plugin.

**Current work**: An extensive review of the existing skill/command files against the agreed architecture, identifying what needs to change. Implementation begins after this review is complete.

---

## Part 15: What Was Explicitly NOT Included and Why

| Excluded | Reason |
|----------|--------|
| Task count caps | Scope determines count, not watermark (user pushback, line 1636) |
| JSON task state file | Native Tasks are the structured layer; tasks.md is human-readable; no need for a third representation (line 1928) |
| Complex hook system | Hooks are fragile across Claude Code updates; one PreCompact hook, everything else is skill logic (line 1930) |
| Retro tier classification | Flagged as over-elaborate; deferred to separate research task (line 1932) |
| Shape Up / evidence-based cutting | Parked; user needs more features before patterns become clear (line 1247) |
| PR-based stage gates | Too much overhead for current scale; decisions.md provides traceability without PR ceremony (line 1261) |
| Subagent-per-task execution | Over-engineering for current scale; validator is the specific isolation needed (line 882) |

---

## Part 16: Open Questions and Low-Confidence Agreements

These items were not fully resolved in the conversation:

1. **Exact naming convention** — Direction agreed (away from speckit), specifics not workshopped
2. **Checkbox format in tasks.md** — Never discussed; original document invented this recommendation
3. **Mandatory analyze** — Proposed, not rejected, but part of a blanket approval rather than specific endorsement
4. **design/ subdirectory** — Agreed, but as a minor point in a wall of text, not a carefully considered decision (low-confidence agreement)
5. **Constitution revision scope** — Acknowledged as needed (especially Principle IV re: validator agent), but deferred as "the final phase of changes"

---

## Summary: How This Architecture Was Arrived At

This architecture was NOT designed top-down. It was arrived at through a contested four-round debate:

**Round 1** (transcript lines 173-378): Initial analysis identified four problems — validation theatre, context degradation, fictional parallelism markers, no automated retro capture. Proposed six changes including validation subagents, task-per-subagent execution, and a full plugin system.

**Round 2** (transcript lines 397-887): Red team critique challenged the entire system as over-engineered. Argued for stripping back to 3 stages, cutting the constitution, capping tasks at 20-25, and avoiding parallel infrastructure.

**Round 3** (transcript lines 891-1241): The organisational infrastructure reframing reversed the red team positions. Gates were recognised as role boundaries. Task granularity was recognised as enabling delegation. The constitution was recognised as appropriate governance for a multi-engineer future. The "humans at judgment points, AI at labour points" philosophy was established.

**Round 4** (transcript lines 1244-2191): Detailed feedback refined the architecture. Task caps were removed. Test tasks were distinguished from validation. decisions.md replaced PR-per-stage overhead. The validator report was designed to solve the tennis problem. Domain knowledge was moved into the plugin. The retro process was deferred. Phased implementation was agreed.

The journey through this debate IS the rationale. Every decision carries the weight of having been challenged, defended, and refined through 4 rounds of feedback between a user building organisational infrastructure and an AI that initially underestimated the scope of that ambition.

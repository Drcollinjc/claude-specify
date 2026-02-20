# Harness Evolution: From Token Forensics to Autonomous Intelligence Validation

**Document type**: Design thesis — captures diagnostic signals, research synthesis, and architectural decisions for evolving the claude-specify plugin into a lean-context, autonomous agentic development harness.

**Date**: 2026-02-17
**Status**: Active — workstreams substantially executed, remaining items deferred to next feature
**Companion document**: `tmp/token-usage-forensic-analysis.md` (the diagnostic data that initiated this work)
**Plugin repo**: https://github.com/Drcollinjc/claude-specify

---

## Table of Contents

1. [How We Got Here](#1-how-we-got-here)
2. [The Diagnostic Signals](#2-the-diagnostic-signals)
3. [Research Inputs](#3-research-inputs)
4. [The Three Pillars Architecture](#4-the-three-pillars-architecture)
5. [Pillar 1: Context Efficiency](#5-pillar-1-context-efficiency)
6. [Pillar 2: Mechanical Enforcement](#6-pillar-2-mechanical-enforcement)
7. [Pillar 3: Intelligence Validation](#7-pillar-3-intelligence-validation)
8. [Eval Strategy by Output Type](#8-eval-strategy-by-output-type)
9. [Prompt-Version Coupling and Eval Lifecycle](#9-prompt-version-coupling-and-eval-lifecycle)
10. [The Shift Work Boundary](#10-the-shift-work-boundary)
11. [StrongDM Technique Mapping](#11-strongdm-technique-mapping)
12. [OpenAI Harness Alignment Analysis](#12-openai-harness-alignment-analysis)
13. [Git Worktrees and Parallelism](#13-git-worktrees-and-parallelism)
14. [Test Data Architecture](#14-test-data-architecture)
15. [Always-Loaded Context Optimisation](#15-always-loaded-context-optimisation)
16. [Structured Retro Signals](#16-structured-retro-signals)
17. [Model Benchmarking and Regression](#17-model-benchmarking-and-regression)
18. [Red Team Analysis of Proposals](#18-red-team-analysis-of-proposals)
19. [Decision Register](#19-decision-register)
20. [Workstreams and Next Steps](#20-workstreams-and-next-steps)
21. [Sources](#21-sources)

---

## 1. How We Got Here

### The Starting Point: Feature 008

Feature 008 (ICP-IBP Campaign Architecture) was the first feature run through the complete claude-specify pipeline — from `/specify` through `/implement` — on a single model (Opus 4.6). It was deliberately run as a baseline: no model switching, no optimisation, just the raw pipeline cost.

**Total pipeline cost: ~$87.84**

This number prompted the first question: *where is the money going, and how much is waste?*

### The Forensic Analysis (2026-02-12)

The token usage forensic analysis (`tmp/token-usage-forensic-analysis.md`) was a 1,422-line deep-dive into every stage of the pipeline. It dissected token flows, identified waste categories, classified cost by type, and proposed a three-phase optimisation plan.

**Key findings from the forensic analysis:**

| Signal | Insight | Implication |
|--------|---------|-------------|
| Thinking tokens = 58% of cost ($51.25) | The model's internal reasoning dominates, not input/output | Model selection is the highest-leverage cost control |
| Subagent isolation saved $16.63 | Keeping 665K tokens out of main context prevented exponential replay | The subagent architecture pays for itself 2.3x over |
| Stale content replay = 6% ($5.03) | Content from earlier stages persists and gets replayed on every turn | Session boundaries between stages eliminate this entirely |
| /implement = 55% of pipeline cost ($48.07) | One stage dominates the pipeline | Optimising /implement matters more than all planning stages combined |
| 4 compactions in /implement cost ~$3.00 direct + context loss | Long sessions cause cascading overhead | Shorter sessions with better state management are worth pursuing |
| All 6 model selection validation gates passed | Sonnet is safe for all planning stages; Haiku is safe for research subagents | Model selection can save ~$10.69 per pipeline with validated quality retention |

### The Evolution Trigger

The forensic analysis answered "where is the waste?" but opened a larger question: *what kind of system should claude-specify become?* The cost data was a symptom. The underlying questions were architectural:

1. **Context management**: How should agents access information? (Loading everything into context is the brute-force approach. What's the elegant approach?)
2. **Enforcement model**: How do we prevent mistakes? (Rules in system prompt trust the agent. Linters don't.)
3. **Validation completeness**: What are we NOT validating that we should be? (Engineering correctness is covered. User experience is partially covered. Intelligence quality has zero coverage.)
4. **Autonomy boundary**: Where should the human be involved? (Currently: everywhere. Goal: upfront only.)
5. **Parallelism**: Can agents work simultaneously? (Currently: sequential. The dependency graph often allows parallelism.)

These questions drove the research phase documented below.

---

## 2. The Diagnostic Signals

Before researching solutions, we catalogued the problems — not just from the forensic analysis, but from the accumulated experience of building features 001-008.

### Signal 1: Context Window as a Cost Multiplier

Every token introduced at turn `j` in a session of `N` turns is replayed as cached input on every subsequent turn. A 40K-token file read at turn 5 in a 60-turn session costs $1.35 total (cache write + 55 cache reads). The same file read at turn 55 costs $0.35.

**The compounding effect**: In the 008 /specify+/clarify+/plan combined session, ~90K tokens of stale content (reference docs, templates, old skill prompts) were replayed across ~42 turns, costing ~$1.90 in pure waste.

**Diagnosis**: Content management is passive — files are read when needed and forgotten about. The system has no concept of content lifecycle (needed now, needed later, or consumed and disposable).

### Signal 2: Trust-Based Enforcement Fails Under Compaction

The pipeline relies on rules files (`.claude/rules/`) loaded into the system prompt to enforce process. After context compaction, the agent retains the rules but loses the command instructions that provide the enforcement steps. In 008's 4 compaction events, recovery required re-reading 3 artifacts and re-establishing state each time — adding ~$1.23 in overhead.

**Diagnosis**: Enforcement through instructions is fragile. The agent must *choose* to follow the process. OpenAI's insight — "linter errors teach while they block" — reveals the gap: we tell the agent what to do, but nothing stops it from doing something else.

### Signal 3: Three Validation Dimensions, Only One Covered

The 008 implementation validated engineering correctness thoroughly — 7 validator gates, all with structured PASS/FAIL evidence. But two dimensions were unvalidated:

- **UI/UX**: Some ACs used Playwright MCP for browser checks, but no systematic user journey validation. The validator checked "does the page load?" not "does the flow make sense?"
- **Intelligence**: The LLM chain (UCI generation → IBP → message execution) had zero validation of output quality. We checked "does the API return JSON?" not "are the insights relevant and well-calibrated?"

**Diagnosis**: The validator gates answer "did we build what the spec says?" but not "does what we built actually work for the user?" The missing layer is particularly acute for LLM-powered features where the intelligence IS the product.

### Signal 4: Human Bottleneck at the Wrong Stage

In the 008 pipeline, human involvement was distributed across all stages — reviewing spec, answering clarification questions, reviewing plan, reviewing analysis, and implicitly reviewing implementation through PR review. The most valuable human input was upfront (shaping intent during /specify and /clarify). The least valuable was mid-implementation (the human has less context than the agent at that point).

**Diagnosis**: The human should be heavily involved in defining WHAT to build and HOW to validate it. The human should NOT be involved in the building itself — that should be fully autonomous, validated by the harness.

### Signal 5: No Regression Safety Net

Each feature is self-contained. When feature 009 is implemented, there's no automated check that 008's functionality still works. When a new Claude model releases, there's no benchmark to detect quality regression in the intelligence layer.

**Diagnosis**: The pipeline builds features but doesn't accumulate a testing estate. Each feature's validation is ephemeral — it runs during implementation and is never run again.

---

## 3. Research Inputs

Five external inputs shaped the architecture below. Each brought a different lens to the problems identified in Section 2.

### 3.1 OpenAI Harness Engineering (February 2026)

**Source**: https://openai.com/index/harness-engineering/

OpenAI published a detailed account of building a million-line codebase with zero manually-written code. Their team of 3-7 engineers achieved ~3.5 PRs/engineer/day using Codex.

**Key concepts that influenced our thinking:**

**"Harness engineering is everything around it: constraints, feedback loops, observability, enforcement."** — The distinction between context engineering (what the agent sees) and harness engineering (what the system prevents, measures, and corrects) reframed our approach. We had been focused on context (what docs to load, how to manage token budget). The harness perspective shifted focus to enforcement and feedback loops.

**"Linter errors were written to teach — every failure message doubled as context for the next attempt."** — Custom linters that block AND educate. When the agent violates an architectural constraint, the linter error message explains why and how to fix it. The agent's next attempt incorporates the lesson. This is fundamentally different from a rules file that says "don't do X" — the linter makes X impossible.

**"When something failed, the fix was almost never 'try harder.' The question was: what capability is missing?"** — Failures as harness deficiencies, not agent deficiencies. This diagnostic lens changes how we respond to problems: instead of adding more instructions, we add more infrastructure.

**Per-worktree isolated environments with observability.** — Each agent task gets its own running application, log stream, and metrics endpoint. All torn down when the task completes. This enables parallel execution and prevents state pollution between stories.

**"Corrections are cheap and waiting is expensive."** — Their merge philosophy prioritises throughput over traditional gatekeeping. Test flakes get follow-up runs, not blocking investigation. This is contextual to their team and model maturity, but the principle is relevant: at demo watermark, we should optimise for iteration speed.

### 3.2 Git Worktrees for Parallel Agent Execution

**Sources**: Anthropic official docs, Cursor parallel agents, agent-worktree, git-worktree-runner, multiple community articles (full list in Section 17).

Git worktrees have become the de facto standard for parallel AI agent development as of late 2025. The pattern: create a linked working directory per agent, each on its own branch, sharing the same `.git` object database.

**Key findings:**

- Worktrees are lightweight (~150 MB vs ~1 GB for full clone of a 30K-file repo)
- Two worktrees editing different files is completely safe — each has its own filesystem namespace
- Commits in any worktree are immediately visible in the shared Git database
- Claude Code officially documents worktrees for parallel sessions
- Multiple open-source tools exist: agent-worktree (Rust), git-worktree-runner (CodeRabbit), parallel-worktrees (Claude Code skill)
- Practical concerns: port management for parallel Docker instances, dependency installation per worktree, merge coordination

**The opportunity**: Map worktrees to user stories during /implement. The orchestrating agent stays in the main worktree, dispatches story agents to isolated worktrees, coordinates merges. This solves the compaction cascade (story agents are short-lived) and enables true parallelism for independent stories.

### 3.3 Feedback Loops and the Missing Validation Layer

**Sources**: Anthropic's "Demystifying Evals for AI Agents", Playwright MCP documentation, BDD/Gherkin literature, Meta's JiT Testing paper (full list in Section 17).

**Key insight**: The spec template already uses Given/When/Then syntax for acceptance scenarios. BDD's core contribution is not the syntax — it's the idea that acceptance scenarios should be EXECUTABLE. In our harness, executable means Playwright MCP tool calls.

The research identified a validation pyramid for agentic harnesses:

```
        Human Review (golden paths + demo scripts)
       Visual + Accessibility Evals (model-based UX grading)
      User Scenario Tests (Playwright MCP user journey execution)
     Validator Gates (current AC verification — curl + code inspection)
    Contract + Schema (Pydantic models, TypeScript types, API contracts)
```

Layers 1-2 (bottom) exist. Layer 3 (validator gates) exists but is engineering-focused. Layers 4-5 are new — they validate from the user's perspective, not the engineer's.

**The demo script pattern**: Instead of the human reviewing code diffs, auto-generate a step-by-step walkthrough document and a screenshot gallery. The human reviews what the app looks like and how it behaves, not how it's implemented.

### 3.4 StrongDM Software Factory Techniques (February 2026)

**Source**: https://factory.strongdm.ai/techniques (6 techniques) + https://factory.strongdm.ai/principles

StrongDM AI operates under two radical charters: "Code must not be written by humans" and "Code must not be reviewed by humans." Their inflection point came in late 2024 when long-horizon agentic coding workflows began to compound correctness rather than error.

**The six techniques and their relevance:**

| Technique | Core Concept | Our Mapping |
|-----------|-------------|-------------|
| **Digital Twin Universe** | Behavioural clones of external services for unlimited deterministic testing | LLM response recording for engineering tests; live calls for intelligence evals |
| **Gene Transfusion** | Point agents at working exemplars, not just descriptions | Formalise cross-feature pattern reuse (e.g., "build US3 like 005's ICP Builder page") |
| **The Filesystem** | Mutable, inspectable world-state; agents navigate context through files | Direct validation of our session-summary.md / decisions.md / spec.md artifact pattern |
| **Shift Work** | Interactive vs non-interactive growth; "Spec + Test Suite = Complete Intent" | Maps to our pipeline split: /specify-/analyze (interactive) vs /implement (non-interactive) |
| **Semport** | Semantically-aware automated ports between languages | Future: auto-sync Pydantic models ↔ TypeScript interfaces |
| **Pyramid Summaries** | Reversible summarisation at multiple zoom levels | Formalises the token forensic's "reference doc subagent" pattern; multi-resolution artifact access |

**The foundational loop (Seed → Validation → Feedback)**: Their three-part loop maps directly to our pipeline. `/specify` is the Seed. Validator gates are the Validation. `decisions.md` learnings fed back into rules are the Feedback. The loop continues until holdout scenarios pass consistently.

**The satisfaction vs boolean insight**: StrongDM moved from boolean test assertions to probabilistic "satisfaction" measures because agents gamed narrow tests (returning `true` to pass assertions). This directly informs how we should validate intelligence outputs — satisfaction scores with statistical thresholds, not boolean pass/fail.

### 3.5 LLM Evaluation Frameworks and Patterns

**Sources**: Anthropic eval guide, OpenAI evals framework, promptfoo, Braintrust, Langfuse, DeepEval, EDD methodology (full list in Section 17).

**The eval-driven development (EDD) methodology**: Write evals BEFORE implementation, iterate until they pass. This is TDD adapted for stochastic systems. The Pragmatic Engineer guide recommends starting with error analysis (review 100+ traces), grouping into themes, then building targeted evals from failure patterns.

**Anthropic's three grader types** (priority order):
1. **Code-based** — fastest, most reliable, deterministic (structural checks)
2. **LLM-based** — fast, flexible, requires rubrics and calibration (semantic checks)
3. **Human** — most flexible, slowest, use primarily for calibration (gold standard)

**promptfoo emerged as the strongest framework fit**: Provider-agnostic, YAML-configured, native Anthropic support, first-class CI/CD integration, supports structural + semantic + performance assertions in a single config.

**Key principle from Anthropic**: "Grade outcomes, not the path agents take." And: "Prioritise volume over quality — more questions with slightly lower signal is better than fewer questions with high-quality human grading."

---

## 4. The Three Pillars Architecture

The research synthesis converged on three reinforcing pillars. Each addresses a different diagnostic signal, and together they transform claude-specify from a process governance tool into an autonomous development harness.

```
                    ┌─────────────────────────────────┐
                    │     Autonomous /implement        │
                    │  (the goal: human not involved)  │
                    └────────────┬────────────────────┘
                                 │
              ┌──────────────────┼──────────────────────┐
              │                  │                       │
    ┌─────────▼──────────┐ ┌────▼──────────────┐ ┌─────▼──────────────┐
    │  Pillar 1:         │ │  Pillar 2:        │ │  Pillar 3:         │
    │  Context           │ │  Mechanical       │ │  Intelligence      │
    │  Efficiency        │ │  Enforcement      │ │  Validation        │
    │                    │ │                   │ │                    │
    │  - Token budget    │ │  - Linters that   │ │  - Structural      │
    │  - Session bounds  │ │    teach          │ │    evals           │
    │  - Model selection │ │  - CI gates       │ │  - Semantic evals  │
    │  - Pyramid sums    │ │  - Contract tests │ │  - Consistency     │
    │  - Worktree        │ │  - Pre-commit     │ │    evals           │
    │    isolation        │ │    hooks          │ │  - Flow-level      │
    │                    │ │                   │ │    evals           │
    └────────────────────┘ └───────────────────┘ └────────────────────┘
              │                  │                       │
              └──────────────────┼──────────────────────┘
                                 │
                    ┌────────────▼────────────────────┐
                    │   Signal: Diagnostic Data        │
                    │   - Token forensics              │
                    │   - Gate pass/fail evidence       │
                    │   - Eval satisfaction scores      │
                    │   - Model benchmark comparisons   │
                    │   - Cost per task/story/feature   │
                    └──────────────────────────────────┘
```

**Why three pillars and not one**: Each pillar addresses a different failure mode.
- Without context efficiency: the system works but costs too much
- Without mechanical enforcement: the system relies on agent compliance (fragile)
- Without intelligence validation: the system builds correct infrastructure around incorrect intelligence

---

## 5. Pillar 1: Context Efficiency

### Problem Statement

The 008 pipeline consumed ~$87.84 on Opus 4.6. The projected optimised cost is ~$54.20 (38% reduction). The largest reducible cost categories are thinking tokens (model selection), subagent costs (model selection), and stale content replay (session boundaries).

### Validated Optimisations (from 008 data)

These are confirmed safe by 008's validation gate analysis:

| Optimisation | Savings/pipeline | Confidence | Status |
|-------------|----------------:|------------|--------|
| One stage per session (planning) | $3.60 | High — validated by /tasks, /checklist, /analyze all running fresh | Ready to apply |
| Haiku for research subagents | $1.40 | High — 008 research outputs used without re-investigation | Ready to apply |
| Sonnet for file-writing subagents | $2.00 | High — 008 subagents produced correct output from structured instructions | Ready to apply |
| Sonnet for /specify, /clarify, /tasks, /checklist, /analyze | $10.69 | High — all 6 decision gate questions passed | Conditional on watermark |
| Mid-stage /compact in /plan and /implement | $1.50 | Medium — depends on research.md quality | Ready to apply |

### Proposed: Pyramid Summaries for Artifact Access

Inspired by StrongDM's Pyramid Summary technique. Instead of loading full documents into context, maintain multi-resolution views:

```
Level 0 (2 words):     "ICP campaign architecture"
Level 1 (1 paragraph): Core entities, flow, scoring model, screen count
Level 2 (1 page):      Entity relationships, API surface, chain stages, key decisions
Level 3 (full doc):    Complete reference with all detail
```

Agents read the resolution appropriate to their task. Research agents might need Level 3. The orchestrating agent during /implement might only need Level 1 for context recovery after compaction.

**Implementation approach**: During `/specify`, after writing spec.md, auto-generate a `spec-summary.md` with Level 0-2 summaries. Same for plan.md → `plan-summary.md`. These summaries are cheap to produce (one-time output cost) and save significant replay cost when used instead of full documents.

### Proposed: Worktree-Based Context Isolation

Detailed in Section 11. The key context efficiency benefit: each story agent in its own worktree only loads files relevant to its story, not the entire codebase. Combined with sparse checkout, this could reduce per-agent context by 50-70%.

### Watermark-Conditional Model Selection

The 008 validation confirmed Sonnet is safe for all planning stages at demo watermark. But this shouldn't be applied universally:

| Watermark | /specify, /clarify | /plan | /tasks, /checklist | /analyze | /implement |
|-----------|-------------------|-------|-------------------|----------|------------|
| spike | Haiku | Sonnet | Haiku | Sonnet | Sonnet |
| poc | Sonnet | Sonnet | Sonnet | Sonnet | Sonnet |
| demo | Sonnet | Opus | Sonnet | Sonnet | Opus |
| mvp | Sonnet | Opus | Sonnet | Opus | Opus |
| production | Opus | Opus | Sonnet | Opus | Opus |

The rationale: higher watermarks require deeper reasoning for governance compliance, architecture decisions, and code quality. The cost increase is justified by the quality requirement.

---

## 6. Pillar 2: Mechanical Enforcement

### Problem Statement

The current enforcement model relies on rules files loaded into the system prompt and command files that provide step-by-step instructions. After context compaction, the agent retains rules but loses command instructions. Even without compaction, enforcement is aspirational — the agent must choose to comply.

OpenAI's insight: "Linter errors were written to teach — every failure message doubled as context for the next attempt." The agent CANNOT bypass a linter. When it violates a constraint, the error message teaches it what to do instead.

### Current Enforcement Inventory

| Mechanism | Type | Survives Compaction? | Can Be Bypassed? |
|-----------|------|---------------------|-----------------|
| `.claude/rules/*.md` | System prompt instructions | Yes (reloaded) | Yes (agent chooses) |
| `.claude/commands/*.md` | Step-by-step command instructions | No (lost) | Yes (agent can skip steps) |
| `session-summary.md` | State recovery artifact | Yes (file) | N/A (read-only state) |
| `decisions.md` | Audit trail | Yes (file) | N/A (write-only log) |
| Validator gates | Subagent verification | Yes (task system) | No* (subagent can't write) |

*Validator gates are the strongest current enforcement because the validator is structurally restricted (Explore subagent can't Write/Edit). But the implementing agent can still self-validate by skipping the gate.

### Proposed: Linters as Teaching Instruments

Create project-level pre-commit hooks and custom linters that enforce constitution principles mechanically. When the agent violates a constraint, the commit is rejected with an error message that teaches the agent what to fix.

**Example linters:**

```bash
# Constitution Principle I: Requirements Are Contracts
# Linter: Verify API responses match Pydantic model schemas
check_api_contract_sync:
  description: "Every Pydantic model with a camelCase alias must have a corresponding TypeScript interface"
  error_message: |
    CONTRACT DRIFT DETECTED: {model_name} in {python_file} has fields not present in {ts_file}.
    Missing fields: {missing_fields}
    Fix: Update {ts_file} to include these fields with matching types.
    Constitution reference: Principle I — 'consistency across modules is a trust dimension'

# Constitution Principle V: Architecture for Change
# Linter: Enforce file size limits
check_file_size:
  description: "No single source file exceeds 300 lines"
  error_message: |
    FILE TOO LARGE: {file} has {lines} lines (limit: 300).
    This violates the Architecture for Change principle — large files are hard to modify safely.
    Fix: Extract logically independent sections into separate modules.
    Suggested splits: {suggested_splits}
```

**Key design principle**: The error message IS the instruction. It tells the agent exactly what's wrong, why it matters (constitution reference), and how to fix it. The agent's next attempt incorporates this feedback automatically — no human intervention needed.

### Proposed: Contract Tests Between Frontend and Backend

The frontend TypeScript interfaces and backend Pydantic models must stay in sync. Currently this is manual and error-prone. A contract test verifies at build time:

```python
def test_pydantic_models_match_typescript_interfaces():
    """Verify Python model JSON schema matches TypeScript interface expectations."""
    from campaign_models import Prospect, ICPSummary, UCIResult
    for model in [Prospect, ICPSummary, UCIResult]:
        schema = model.model_json_schema()
        ts_interface = parse_typescript_interface(f"frontend/src/types/{model.__name__}.ts")
        assert set(schema["properties"].keys()) == set(ts_interface.fields.keys()), \
            f"Contract drift in {model.__name__}: Python has {schema['properties'].keys()}, TS has {ts_interface.fields.keys()}"
```

This is a mechanical check that runs on every commit. No agent compliance required.

### Proposed: Structural Tests as CI Gates

Beyond linters, add structural tests that verify architectural invariants:

- No circular imports between modules
- All API routes have Pydantic response models
- All LLM prompt templates use safe string formatting (not `str.format()`)
- Seed data files match the Pydantic model schemas
- Docker compose health checks pass

These tests run in CI and block merges. They encode lessons learned (e.g., the `str.format()` lesson from 008) into permanent, mechanical enforcement.

---

## 7. Pillar 3: Intelligence Validation

### Problem Statement

The current pipeline validates three things:
1. **Engineering correctness**: Does the code compile, do APIs return expected responses, are files in the right places?
2. **UI functionality**: Do pages load, do navigation links work, do components render?
3. **Process compliance**: Were the right pipeline stages run, are artifacts complete?

It does NOT validate:
4. **Intelligence quality**: Given this user context and these inputs, does the LLM produce output that is relevant, well-calibrated, grounded, and consistent?

This is the most critical gap for a product whose core value proposition IS the intelligence layer. We're building infrastructure around intelligence we've never validated.

### The Intelligence Chain in Our Product

The product's value flows through a chain of LLM calls:

```
User Context (ICP + Prospect + Attributes)
    │
    ▼
[LLM Call 1] UCI Generation
    Input: ICP profile, prospect data, attribute scores
    Output: Structured UCI with scored insights, rationale, confidence levels
    │
    ▼
[LLM Call 2] IBP Generation
    Input: UCI output, ICP playbook templates
    Output: Prioritised plays with messaging angles, channel recommendations
    │
    ▼
[LLM Call 3-6] Message Execution Chain (4 stages)
    Input: IBP output, channel config, tone rules, stage context
    Output: Stage-specific messages with provenance annotations
    │
    ▼
User Sees: Scored insights, recommended plays, generated messages with source attribution
```

Each arrow is an LLM call with an implicit **contract**: given this input shape and content, produce output with this shape, this quality, and this relevance. Currently, we verify the shape (Pydantic models parse the response). We do NOT verify the quality or relevance.

### The Four Layers of Intelligence Validation

Drawing from Anthropic's eval guide, promptfoo's assertion architecture, and StrongDM's satisfaction measures:

#### Layer 1: Structural Validation (Deterministic, Cheap, Fast)

```yaml
# Does the LLM output parse correctly?
assertions:
  - type: is-json
  - type: javascript
    value: "JSON.parse(output).insights.length >= 3"
  - type: javascript
    value: "JSON.parse(output).scores.every(s => s >= 0 && s <= 100)"
  - type: javascript
    value: "JSON.parse(output).insights.every(i => i.rationale.length >= 20)"
```

**What it catches**: Prompt regressions where the model stops producing valid JSON, omits required fields, returns scores outside bounds, or produces truncated rationales.

**When to run**: Every build. Zero additional LLM cost — can use recorded responses (DTU pattern).

**Relationship to engineering validation**: This overlaps with Pydantic model validation but goes deeper. Pydantic checks "is it valid JSON with the right fields?" Structural evals check "are the values within expected ranges and proportions?"

#### Layer 2: Semantic Validation (Probabilistic, Moderate Cost)

```yaml
# Is the content relevant and grounded?
assertions:
  - type: llm-rubric
    value: |
      Given input context about a {{industry}} company with {{size}} employees
      selling {{product}} to {{target_market}}:
      1. Are insights specific to this industry? (not generic B2B advice)
      2. Do scores correlate with the attribute data provided?
         (high engagement score when engagement data is strong)
      3. Are rationales grounded in the input data?
         (no hallucinated company names, products, or metrics)
      4. Is confidence calibrated?
         (high confidence when signal is strong, low when sparse)
    threshold: 0.8
```

**What it catches**: Quality degradation — the model produces valid JSON but the content is generic, hallucinated, or poorly calibrated. This is the most common failure mode when prompts drift or models update.

**When to run**: On prompt changes and model updates. Uses a judge model (different from the model being evaluated to avoid self-grading bias).

**The rubric is the spec**: These rubrics encode what "good intelligence" looks like for our product. They're the intelligence equivalent of acceptance criteria — written during /specify alongside engineering ACs.

#### Layer 3: Consistency Validation (Probabilistic, Moderate Cost)

```yaml
# Does the same input produce statistically similar outputs?
config:
  runs: 5
assertions:
  - type: javascript
    value: |
      const scores = outputs.map(o => JSON.parse(o).scores.icp_fit);
      const mean = scores.reduce((a,b) => a+b) / scores.length;
      const variance = scores.map(s => (s-mean)**2).reduce((a,b) => a+b) / scores.length;
      const stddev = Math.sqrt(variance);
      return stddev < 15;  // Score standard deviation threshold
```

**What it catches**: Instability — the model produces wildly different outputs for the same input. Critical for user trust. If a user runs the same analysis twice and gets score 85 then score 42, the product loses credibility.

**Metrics**: Using Anthropic's framework:
- `pass@k`: Probability of at least one correct output in k attempts (discovery metric)
- `pass^k`: Probability ALL k attempts are correct (reliability metric)
- At k=5 with 75% per-trial success: pass@5 = 99.9%, pass^5 = 23.7%. The gap between these numbers quantifies the reliability challenge.

**When to run**: On model updates and significant prompt changes. This is the most expensive eval layer (5x the LLM calls) but the most informative for production readiness.

#### Layer 4: Flow-Level Validation (End-to-End, Highest Value)

```yaml
# Does the complete chain produce coherent output?
chain:
  - step: uci_generation
    input: fixtures/prospect-001-active.json
    validate: uci_schema + uci_semantic_rubric
    pass_output_to: ibp_generation
  - step: ibp_generation
    input: previous_output + fixtures/playbook-standard-4touch.json
    validate: ibp_schema + ibp_semantic_rubric
    pass_output_to: message_execution
  - step: message_execution
    input: previous_output + fixtures/channel-email-config.json
    validate: message_schema + message_semantic_rubric
flow_assertions:
  - no_information_loss: "Key entities from step 1 present in step 3 output"
  - no_hallucination_amplification: "Step 3 claims grounded in step 1 data"
  - provenance_valid: "Every annotation traces to a real source component"
  - coherent_narrative: "The progression from insight → play → message tells a consistent story"
```

**What it catches**: Chain-level failures — each step might be fine individually but the composition breaks. Information gets lost between steps. Hallucinations in step 1 get amplified in step 2. Provenance annotations point to non-existent sources.

**When to run**: On significant feature changes, model updates, and as part of the regression suite. This is the highest-value eval because it validates the user's actual experience.

### How Intelligence Evals Fold Into the Pipeline

The evals are not an afterthought bolted onto /implement. They're first-class artifacts created during the specification phase:

**During /specify:**
- Write intelligence eval rubrics alongside ACs
  - "For UCI generation, insights must be industry-specific (not generic B2B advice)"
  - "Scores must correlate with attribute data (high engagement score when engagement data is strong)"
- Define eval fixture inputs (the test data)
  - "Use prospect-001 (active, strong engagement, weak intent) as the primary fixture"
- Define satisfaction thresholds
  - "Semantic satisfaction >= 0.8, consistency σ < 15"

**During /plan:**
- Design the eval architecture alongside technical architecture
  - Which chain steps need which eval layers?
  - What judge model to use?
  - Where do recorded responses vs live calls apply?

**During /tasks:**
- Include eval tasks alongside implementation tasks
  - "T007: Create UCI eval fixtures in evals/fixtures/"
  - "T008: Write UCI semantic rubric in evals/rubrics/"
  - "T009: Create promptfoo config for UCI structural + semantic evals"

**During /implement:**
- Build the evals alongside the feature
- Run evals as part of validator gates:

```
GATE_US3 — UCI Generation
  Engineering ACs:      6/6 PASS (curl, code inspection)
  User Journey Tests:   4/4 PASS (Playwright MCP)
  Intelligence Evals:
    Structural:         PASS (valid JSON, all fields, score ranges)
    Semantic:           0.85 satisfaction (threshold: 0.7) — PASS
    Consistency:        σ=8.2 across 5 runs (threshold: σ<15) — PASS
  GATE VERDICT:         PASS
```

### The Deterministic vs Probabilistic Challenge

This is the core tension you identified. Engineering and UI validation are deterministic — run once, get a definitive answer. Intelligence validation is probabilistic — run N times, get a statistical distribution.

**Our approach (informed by Anthropic + StrongDM):**

| Validation Type | Deterministic? | Runs Needed | Cost Model |
|----------------|---------------|-------------|-----------|
| Structural (Layer 1) | Yes | 1 | Use recorded responses (free) |
| Semantic (Layer 2) | No (judge model has variance) | 1-3 | Judge model cost (Sonnet) |
| Consistency (Layer 3) | No (measuring variance) | 5 | 5x target model cost |
| Flow-level (Layer 4) | No (chain amplifies variance) | 3-5 | 3-5x full chain cost |

**For CI/CD (every build):** Run only Layer 1 (structural) using recorded responses. Zero LLM cost, sub-second execution, catches prompt regressions.

**For validator gates (during /implement):** Run Layers 1-2 (structural + semantic). One live LLM call per chain step, plus one judge call. Catches quality issues before moving to the next story.

**For model upgrades and releases:** Run all 4 layers. Full statistical analysis. Generate comparison report. This is the benchmark suite.

### The Recorded Response Pattern (DTU Applied)

StrongDM's Digital Twin Universe insight, applied to our LLM calls:

During the first successful /implement run, **record every LLM input-output pair** as fixtures:

```
evals/
  recorded/
    uci-generation/
      input-prospect-001.json
      output-prospect-001-claude-sonnet-4.5-20250929.json
      input-prospect-002.json
      output-prospect-002-claude-sonnet-4.5-20250929.json
    ibp-generation/
      ...
    message-execution/
      ...
```

These recorded responses serve dual purposes:
1. **Engineering CI**: Use recorded responses for structural evals — deterministic, free, fast
2. **Intelligence baseline**: Compare future live outputs against recorded baselines for semantic drift detection

When a new model releases, run live calls and compare against recorded baselines. If semantic similarity drops below threshold, investigate.

---

## 8. Eval Strategy by Output Type

### The Insight: Not All LLM Outputs Are Equal

The four-layer eval framework (Section 7) treats all LLM outputs somewhat uniformly. In practice, different output types have fundamentally different eval requirements based on how much variance is acceptable and how much reasoning transparency is needed.

**Feedback signal**: The product's intelligence chain contains at least two distinct output categories that require different eval strategies.

### Category A: Deterministic-Intent Outputs (Text-to-SQL, Structured Queries)

Some LLM outputs have a **correct answer**. When a user asks "show me prospects with engagement score above 70," there is a specific SQL query (or set of equivalent queries) that satisfies this. The variance tolerance is near-zero.

**What matters beyond output correctness:**
- **Reasoning transparency**: It's not enough that the SQL is correct. We need visibility into WHY the model chose that query structure. Did it correctly identify the right table? Did it understand the column semantics? Did it handle the filter condition correctly?
- **Reasoning consistency**: Given the same input context and prompt, the model should not only produce equivalent SQL but arrive at it through consistent reasoning. If the rationale shifts across runs ("I used the prospects table because..." vs "I queried dim_customer because..."), that indicates fragile understanding even if the SQL happens to be correct.
- **Rationale-output alignment**: The stated reasoning must actually support the generated SQL. A correct query with wrong reasoning is arguably worse than a wrong query with right reasoning — the former hides a fragile mapping that will break on harder inputs.

**Eval approach for Category A:**

```yaml
# Text-to-SQL eval: tight variance, reasoning required
assertions:
  # Output correctness (deterministic)
  - type: javascript
    value: |
      const result = JSON.parse(output);
      // SQL equivalence check — does it return the same result set?
      return sqlEquivalent(result.sql, expected.sql, testDatabase);

  # Reasoning required
  - type: javascript
    value: |
      const result = JSON.parse(output);
      return result.reasoning && result.reasoning.length > 50;

  # Reasoning-output alignment (model-graded)
  - type: llm-rubric
    value: |
      Given this SQL query and the model's stated reasoning:
      1. Does the reasoning correctly identify the target table(s)?
      2. Does the reasoning correctly explain the filter/join logic?
      3. Is there anything in the SQL not explained by the reasoning?
      4. Is there anything in the reasoning not reflected in the SQL?
    threshold: 0.9  # Tight — reasoning must align with output

  # Consistency (5 runs)
  - type: consistency
    runs: 5
    check: "reasoning themes must overlap across runs"
    threshold: 0.85  # High — reasoning should be stable
```

**Key principle**: For Category A, eval the reasoning WITH the output, not just the output alone. Record reasoning traces alongside SQL for debugging. When reasoning drifts but output stays correct, that's a leading indicator of future breakage.

### Category B: Creative-Intent Outputs (UCI Insights, Message Generation)

Some LLM outputs have **no single correct answer**. A UCI insight can be expressed many ways. An email can be written in different styles while conveying the same message. Variance is expected and healthy — like a human writing the same email differently on different days.

**What matters:**
- **Intent preservation**: Does the output achieve the same communication goal regardless of phrasing?
- **Grounding**: Are claims anchored in the input data (not hallucinated)?
- **Quality floor**: Is every output above a minimum quality bar?
- **Score calibration**: For scored outputs (ICP fit scores, confidence levels), the numerical values should be reasonably stable even if the text varies.

**Eval approach for Category B:**

```yaml
# UCI/Message eval: wider variance, intent-focused
assertions:
  # Structural (deterministic)
  - type: is-json
  - type: javascript
    value: "JSON.parse(output).insights.length >= 3"

  # Semantic quality (model-graded, moderate threshold)
  - type: llm-rubric
    value: |
      Given the input prospect data:
      1. Are insights specific to this prospect's industry?
      2. Are claims grounded in the provided attribute data?
      3. Is the overall narrative coherent?
    threshold: 0.7  # Moderate — quality floor, not perfection

  # Score consistency (tighter than text consistency)
  - type: javascript
    runs: 5
    value: |
      const scores = outputs.map(o => JSON.parse(o).scores.icp_fit);
      const stddev = calculateStdDev(scores);
      return stddev < 15;  // Scores should be stable even if text varies

  # Text consistency (looser — intent, not wording)
  - type: similar
    runs: 3
    threshold: 0.6  # Low — different phrasing is fine if intent matches
```

**Key principle**: For Category B, eval the intent and quality floor, not the specific text. Accept variance in phrasing. Hold the line on grounding and score calibration.

### The Spectrum Between Categories

Most real outputs fall somewhere between these poles:

```
Deterministic                                              Creative
    ◄──────────────────────────────────────────────────────────►

Text-to-SQL    Attribute     ICP Scoring    UCI Insights    Message
               Extraction    (numerical)    (narrative)     Generation

Tight variance ──────────────────────────────────► Wide variance
High reasoning ──────────────────────────────────► Low reasoning
transparency                                       transparency needed
```

The eval framework should let each chain step declare where it falls on this spectrum, and the thresholds adjust accordingly.

### Design Principle: Start Minimal, Don't Over-Fit

The GTM data ecosystem is still evolving. Screen flows, data models, and intelligence chain steps will change as the product matures. The eval architecture must be flexible enough to accommodate this flux.

**Practical guidance:**
- Start with 2-3 representative fixtures per chain step, not a combinatorial matrix
- Let fixtures emerge from real usage, not hypothetical scenarios
- When a chain step changes, update its fixtures — don't maintain backward compatibility with stale fixtures
- The eval configuration (thresholds, rubrics, Category A/B classification) is a living artifact that evolves with the product
- Resist the urge to build a comprehensive fixture estate before the data model stabilises — that investment gets invalidated by the next data model change

---

## 9. Prompt-Version Coupling and Eval Lifecycle

### The Versioning Relationship

Every eval fixture is implicitly tied to the prompt that generated the expected output characteristics. When the prompt changes, the eval expectations must be re-evaluated.

```
Prompt v1 + Fixture A → Expected Output Characteristics v1
Prompt v2 + Fixture A → Expected Output Characteristics v2 (must be re-derived)
```

**The lifecycle:**

1. **Prompt v1 created** during /implement → eval fixtures created alongside → baseline established
2. **Prompt v1 in production** → fixtures used for regression testing → model upgrades evaluated against v1 fixtures
3. **Prompt v2 created** (tuning, bug fix, or feature evolution) → v1 fixtures become **regression baselines only** → v2 fixtures derived from the new prompt's actual outputs
4. **Comparison**: v2 should meet or exceed v1 quality on the same fixture inputs — but the specific expected outputs may differ because the prompt changed

### What This Means Practically

**Fixture files should reference their prompt version:**

```json
{
  "fixture_id": "prospect-001-active",
  "prompt_version": "uci-generation-v1",
  "prompt_file": "docker/app/prompts/uci_generation.md",
  "prompt_hash": "a3f8c2d...",
  "created_at": "2026-02-20",
  "input": { "..." },
  "expected_characteristics": { "..." }
}
```

When the prompt file changes (detected via hash comparison), the eval runner flags: "Prompt has changed since fixtures were created. Run in BASELINE mode to capture new expected characteristics, or run in REGRESSION mode to compare against previous version."

### Two Eval Modes

**BASELINE mode** (after prompt change):
- Run fixtures against the new prompt
- Capture outputs as the new expected characteristics
- Compare quality metrics against the previous version's baseline
- Human reviews: "Is the new prompt better, worse, or equivalent?"

**REGRESSION mode** (steady state):
- Run fixtures against the current prompt
- Compare outputs against the current version's expected characteristics
- Flag deviations beyond thresholds
- No human involvement unless a threshold is breached

### Why Previous Fixtures Remain Valuable

When prompt v2 replaces v1, the v1 fixtures don't become useless. They become:
- **Regression indicators**: Does v2 still handle the scenarios v1 handled?
- **Quality trajectory data**: Plot quality scores over prompt versions to track improvement
- **Model comparison baselines**: When evaluating a new Claude version, run against ALL historical fixtures to detect subtle regressions across the full prompt history

### The Accumulation Pattern

```
Feature 008: Prompt v1 → 3 fixtures → baseline scores
Feature 009: Prompt v1 tweaked → v2 → 3 new fixtures + v1 fixtures as regression
Feature 010: New chain step added → v3 → 2 new fixtures for new step + all prior fixtures
...
Prompt v8: 20+ fixtures accumulated, all with prompt version metadata
  → Run the full estate on model upgrade → comprehensive regression detection
```

The fixture estate grows WITH the product. Each prompt iteration adds fixtures. The earlier fixtures become the regression safety net. This is the compounding loop that makes the system increasingly valuable over time.

---

## 10. The Shift Work Boundary

StrongDM's Shift Work technique crystallises the autonomy boundary you described. The pipeline splits into two fundamentally different modes:

### Interactive Mode (Human Shapes Intent)

```
/specify  →  /clarify  →  /plan  →  review /analyze + /checklist
    ↑            ↑           ↑              ↑
    │            │           │              │
  Human writes  Human      Human          Human reviews
  feature       answers    reviews         analysis output,
  description,  questions, architecture    checklist, eval
  reviews spec  refines    decisions       rubrics, fixtures
  + ACs + eval  scope +
  rubrics       eval fixtures
```

**Human involvement**: Heavy. The human is defining WHAT to build, HOW to validate the engineering, HOW to validate the intelligence, and what QUALITY thresholds to apply.

**The spec becomes richer**: In addition to user stories + ACs, the spec now includes:
- User Journey Tests (executable via Playwright MCP)
- Intelligence eval rubrics (what "good" looks like for each LLM call)
- Eval fixtures (test data with expected output characteristics)
- Satisfaction thresholds (statistical quality bars)

This upfront investment pays off as autonomous execution safety.

### Non-Interactive Mode (Agent Executes Autonomously)

```
/implement  ─────────────────────────────────────────────────►  Done
    │
    ├── Build feature code
    ├── Build eval infrastructure
    ├── Run engineering ACs at gates
    ├── Run user journey tests at gates
    ├── Run intelligence evals at gates
    ├── Fix issues, re-validate, iterate
    ├── Generate screenshot gallery
    ├── Generate eval results summary
    └── Generate demo script
```

**Human involvement**: Zero during execution. The "test suite" (ACs + user journeys + intelligence evals) constitutes "complete intent."

**Human involvement resumes**: After /implement completes. The human reviews:
1. Screenshot gallery — visual proof of each story's implementation
2. Eval results summary — quality scores for intelligence outputs
3. Demo script — step-by-step manual verification instructions

This review is lightweight (10-15 minutes) because the automated validation has already caught engineering, UI, and intelligence issues. The human is verifying alignment with intent, not debugging implementation.

### The "Complete Intent" Formula

Drawing from StrongDM's Shift Work principle:

```
Complete Intent = Spec (what to build)
               + Engineering ACs (how to verify the infrastructure)
               + User Journey Tests (how to verify the UX)
               + Intelligence Eval Rubrics (how to verify the AI)
               + Eval Fixtures (test data for the AI)
               + Satisfaction Thresholds (statistical quality bars)
```

If any of these is missing, the intent is incomplete and autonomous execution is risky. The `/analyze` gate should verify completeness of all six components before greenlighting /implement.

---

## 11. StrongDM Technique Mapping

### How Each Technique Applies to Our System

#### Digital Twin Universe → LLM Response Recording

**Current state**: Every LLM call in the product goes to a live API. Validation of LLM outputs is zero — we only check that the API returns parseable JSON.

**Target state**: Record LLM input-output pairs during development. Use recorded responses for deterministic CI testing (structural checks). Use live responses for intelligence quality testing (semantic + consistency checks). This separates "does the plumbing work?" from "does the intelligence work?"

**Implementation**: Instrument the LLM service layer to optionally record responses to `evals/recorded/`. Add a `RECORD_LLM_RESPONSES=true` environment variable for development. The recording layer captures: input (full prompt), output (full response), model version, latency, token count.

#### Gene Transfusion → Cross-Feature Exemplar Reuse

**Current state**: During /plan, research agents explore the existing codebase for patterns. But this exploration is ad-hoc — the agent discovers patterns on its own.

**Target state**: When generating tasks, explicitly attach exemplar files from previous features. "Build this component following the pattern in `frontend/src/pages/005/ICPBuilder.tsx`" is more powerful than describing the pattern.

**Implementation**: Add an "Exemplar" field to the tasks.md template. During /tasks generation, the codebase exploration agent identifies relevant exemplars for each task and includes them as references.

#### The Filesystem → Already Implemented

Our pipeline artifact pattern (session-summary.md, decisions.md, spec.md, plan.md, tasks.md) IS the filesystem technique. StrongDM validates this approach explicitly.

**Enhancement opportunity**: Apply the "genrefying" concept — periodically restructure the filesystem artifacts for optimal future retrieval. This could mean maintaining an `index.md` in each feature directory that summarises all artifacts at a glance.

#### Shift Work → Pipeline Boundary Formalisation

**Current state**: The /implement command runs /analyze automatically, then executes tasks. But the boundary between interactive and non-interactive isn't explicit — the human can intervene at any point.

**Target state**: Formally declare the boundary. After the human approves the /analyze output, /implement runs fully autonomously. No human questions, no mid-process review. The validator gates and intelligence evals provide all the feedback the agent needs.

**Implementation**: Add an "Autonomous Execution Approved" flag to decisions.md after /analyze review. The /implement command checks this flag and adjusts its behaviour — no AskUserQuestion calls, no checkpoint pauses, fully autonomous with subagent dispatch.

#### Semport → Frontend/Backend Model Sync

**Current state**: Pydantic models (Python) and TypeScript interfaces are manually maintained in sync. Drift causes runtime errors.

**Target state**: Auto-generate TypeScript interfaces from Pydantic models (or vice versa). When one changes, the other updates automatically.

**Implementation**: Medium-term. Use a code generation step in /implement that runs after backend models are written, generating TypeScript interfaces. Or use contract tests (Pillar 2) to catch drift.

#### Pyramid Summaries → Multi-Resolution Artifact Access

**Current state**: Agents load full documents into context. A 43K-token reference document costs $1.35 when read early in a session.

**Target state**: Maintain multi-resolution summaries of key documents. Agents read the resolution appropriate to their task. Full detail available when needed via expansion.

**Implementation**: During /specify, after writing spec.md, auto-generate Level 0-2 summaries. Store in `spec-summary.md`. Same pattern for plan.md, research.md. Modify command files to read summaries by default, with explicit full-doc reads only when deep detail is needed.

---

## 12. OpenAI Harness Alignment Analysis

### Where We're Aligned

| Concept | OpenAI Harness | claude-specify | Assessment |
|---------|---------------|---------------|------------|
| Repository as source of truth | AGENTS.md + versioned docs | CLAUDE.md + specs/ + .specify/ | Aligned |
| Plans as first-class artifacts | Execution plans with decision logs | spec.md, plan.md, decisions.md | Aligned |
| Layered architecture enforcement | Custom linters + structural tests | Constitution + /analyze gate | We enforce later; they enforce continuously |
| Context as scarce resource | "Map not manual" — small pointer file | CLAUDE.md + rules/ with path scoping | Aligned |
| Composable skills | Codex Skills (versionable, mountable) | /specify, /clarify, /plan etc. | Aligned |
| Subagent for research | Unnamed but implied in parallel dispatch | Research agents, validator agents | Aligned |

### Where They're Ahead

| Capability | OpenAI | claude-specify | Gap |
|-----------|--------|---------------|-----|
| Mechanical enforcement | Custom linters with teaching error messages | Rules in system prompt (aspirational) | **Critical gap** — our enforcement can be bypassed |
| Per-task app instances | App boots per worktree with isolated observability | Shared Docker compose | **Significant gap** — limits parallelism |
| Agent self-review loop | Multi-round review until all reviewers satisfied | One-shot validator gate | **Moderate gap** — no iteration before human review |
| Background quality agents | Recurring scans, quality grades, auto-refactoring PRs | No post-feature quality tracking | **Moderate gap** — no long-term quality monitoring |
| Agent-generated code optimised for agent legibility | "Repository optimised first for Codex's legibility" | No explicit agent legibility optimisation | **Low gap** — our codebase is small enough to not need this yet |

### Where We're Ahead

| Capability | claude-specify | OpenAI | Assessment |
|-----------|---------------|--------|------------|
| Governance depth | Two-document model (thesis + constitution) with versioning, amendment protocol, overfitting guard | "Core beliefs" + "golden principles" (informal) | We have more rigorous governance |
| Decision auditing | decisions.md with structured evidence, PreCompact snapshots | "Decision logs" (mentioned but not detailed) | We have better decision traceability |
| Watermark adaptation | Process rigor scales with feature maturity (spike → production) | Same process for everything | We can dial rigor; they can't |
| Intelligence validation framework | Proposed 4-layer eval system (this document) | Not described | Our proposed system goes further |

### What We Should Adopt From OpenAI

**Priority 1: Teaching linters.** Implement pre-commit hooks and custom linters that produce error messages designed to teach the agent. This is the single highest-impact adoption from the OpenAI harness.

**Priority 2: Per-worktree app instances.** Make the Docker dev environment boot per worktree with port arithmetic. This enables parallel story execution and isolated validation.

**Priority 3: Self-review loop.** Extend the validator gate to allow the implementing agent to fix issues and re-validate before the gate is marked PASS/FAIL. Currently, gate failure requires manual investigation.

**Priority 4: Background quality agents.** After a feature merges, run a quality scan that checks for code duplication, unused exports, stale imports, and schema drift. Auto-open cleanup PRs.

---

## 13. Git Worktrees and Parallelism

### The Opportunity

The /implement dependency graph often allows parallel execution. In 008, US3 (Attribute Catalogue), US4 (UCI Generation), and US5 (Execution Chain) could have run simultaneously after the foundational backend was in place.

### Proposed Architecture

```
/implement starts on main worktree
    │
    ├── Phase 1-2: Sequential (main worktree)
    │     Backend models, seed data, shared types, routing
    │     These MUST be sequential — later stories depend on them
    │
    ├── Phase 3+: Parallel (story worktrees)
    │     git worktree add ../us3-attribute-catalogue -b us3
    │     git worktree add ../us4-uci-generation -b us4
    │     git worktree add ../us5-execution-chain -b us5
    │
    │     Each worktree:
    │       - Own Claude Code session (via Task tool or agent-teams)
    │       - Own Docker instance (port offset: 8001/3001, 8002/3002, etc.)
    │       - Own test execution
    │       - Commits to own branch
    │
    ├── Validator gates run per worktree
    │     GATE_US3: Validator agent in us3 worktree
    │     GATE_US4: Validator agent in us4 worktree
    │     GATE_US5: Validator agent in us5 worktree
    │
    ├── Sequential merge (orchestrating agent)
    │     Merge us3 → integration branch (resolve conflicts)
    │     Merge us4 → integration branch (resolve conflicts)
    │     Merge us5 → integration branch (resolve conflicts)
    │
    └── Phase N: Polish (main worktree, integration branch)
          Cross-story integration tests
          Flow-level intelligence evals
          Screenshot gallery generation
```

### Why This Is Better Than "One Story Per Session"

The token forensic analysis proposed splitting /implement into 7 story-sessions. Red team analysis identified critical problems:
- /analyze would re-run 7 times (catastrophic cost increase)
- Task system doesn't persist across sessions (re-hydration overhead)
- Context loss between sessions (no memory of previous stories' implementation)

Worktrees solve these problems differently:
- The **orchestrating agent stays in ONE session** — no /analyze re-run, task state preserved
- Story agents are **subagents** dispatched via Task tool — short-lived, no compaction
- Context is **naturally scoped** — each agent sees only its story's files
- Merge coordination happens in the main worktree with full context

### Practical Requirements

| Requirement | Solution | Effort |
|-------------|----------|--------|
| Port management | Docker compose override with `PORT_OFFSET` env var | Low — template change |
| Dependency installation | Post-create hooks: `npm ci`, `docker compose build` | Low — script addition |
| Merge coordination | Orchestrating agent merges branches sequentially | Medium — implement.md change |
| Sparse checkout | Optional: limit files per worktree to relevant story paths | Low — git config |
| Hook compatibility | Set `core.hooksPath` to absolute path | Low — one-time config |

### Adoption Path

1. **Phase 1 (next feature)**: Build worktree automation directly into /implement. The orchestrating agent creates worktrees, configures Docker port offsets, dispatches story agents, and coordinates merges. The first feature using this IS the trial — expect iteration on the automation scripts, but build the infrastructure rather than doing it manually.
2. **Phase 2 (following feature)**: Refine based on Phase 1 learnings. Optimise dependency installation time, tune sparse checkout scoping, improve merge conflict handling.
3. **Phase 3 (future)**: Integrate with Claude Code agent-teams for native multi-agent coordination with shared task lists and inter-agent messaging.

---

## 14. Test Data Architecture

### The Minimum Dataset Problem

You identified that expanding the go-to-market metric system requires a minimum dataset available for every testing cycle. This dataset must:

1. Be consistent across runs (deterministic seed data for engineering tests)
2. Be representative of real usage (realistic ICP profiles, prospect data, attribute scores)
3. Cover edge cases (sparse data, missing fields, extreme scores)
4. Grow with each feature (additive fixture accumulation)
5. Enable regression detection (baseline outputs for comparison)

### Starting Point: Minimal Structure, Let It Grow

The GTM data ecosystem is in flux. Screen flows, intelligence chain steps, and data models will evolve as the product matures. Over-engineering the fixture estate now means investing in structure that gets invalidated by the next data model change.

**Design principle**: Start with 2-3 representative fixtures per chain step. Let the structure emerge from real usage rather than anticipated usage.

```
evals/
  fixtures/                          # Flat to start — add subdirectories when needed
    prospect-active.json             # Active prospect, strong engagement, weak intent
    prospect-sparse.json             # Edge case: minimal attribute data
    icp-finserv.json                 # Representative ICP profile
  rubrics/                           # One per chain step
    uci-quality.md                   # "What good UCI output looks like"
    message-quality.md               # "What good messages look like"
  recorded/                          # Recorded LLM responses (DTU pattern)
    {model-id}/                      # Organised by model version
      {chain-step}-{fixture-id}.json # e.g., uci-generation-prospect-active.json
  configs/
    promptfooconfig.yaml             # Main eval configuration
  results/                           # Historical eval run results
```

**What's deliberately missing**: No deep subdirectory hierarchy, no per-channel/per-playbook organisation, no comprehensive edge case matrix. These emerge when the product stabilises and the eval data shows which dimensions matter most.

### Fixture Design Principles

1. **Each fixture has a documented purpose**: A `purpose` field in the JSON explains what it tests, not just what data it contains.

2. **Fixtures are additive, not planned**: Each feature adds fixtures from its actual implementation. Don't create fixtures speculatively for scenarios that haven't been built yet.

3. **Fixtures include expected output characteristics, not exact outputs**: Ranges, required fields, and quality markers — not brittle golden-file comparisons.

4. **When a fixture breaks due to data model change, update or delete it**: Don't maintain backward compatibility with stale fixtures. The cost of a stale fixture (false confidence) exceeds the cost of recreating it.

```json
{
  "fixture_id": "prospect-active",
  "prompt_version": "uci-generation-v1",
  "prompt_hash": "a3f8c2d...",
  "purpose": "Active prospect with strong engagement, weak intent — tests score calibration",
  "input": { "...prospect data..." },
  "expected_characteristics": {
    "structural": {
      "insights_count_min": 3,
      "score_range": [0, 100],
      "required_fields": ["attribute", "score", "rationale", "confidence"]
    },
    "semantic": {
      "industry_specific": true,
      "engagement_score_expected": "high (>70) given strong engagement data",
      "intent_score_expected": "low (<40) given weak intent signals"
    }
  }
}
```

Note the inclusion of `prompt_version` and `prompt_hash` — tying fixtures to their prompt version per Section 9.

---

## 15. Always-Loaded Context Optimisation

### Problem Statement

Every API turn loads the system prompt — CLAUDE.md, all rules files, MEMORY.md, and Claude Code's own system instructions. The forensic analysis measured this at ~14,762 tokens per turn. While prompt caching discounts this to 10% on subsequent turns, the content itself displaces useful context and contributes to the >200K token pricing cliff on long sessions.

More importantly: after compaction events, the always-loaded files are the ONLY instructions that survive. Whatever is in these files must be sufficient to recover the process state and continue correctly.

### The "Map Not Manual" Principle (from OpenAI)

OpenAI's core context management insight: *"Give the agent a map, not a 1,000-page instruction manual. Context is a scarce resource."*

Their AGENTS.md is a small pointer file that references deeper sources of truth. Our equivalent (CLAUDE.md + rules files) is currently more manual than map — it contains the full content inline rather than pointing to reference documents.

### Current State: What's Always Loaded

| File | Tokens | Purpose | Compaction-Critical? |
|------|-------:|---------|---------------------|
| CLAUDE.md | ~1,446 | Tech stack, commands, code style | Partially — legacy entries from 8 features |
| cloud-architecture.md | ~1,357 | AWS patterns, decision framework | No — only relevant for infra features |
| data-modeling.md | ~971 | Data patterns, naming conventions | No — only relevant for data features |
| debugging.md | ~239 | Debugging process | Useful but small |
| duckdb-patterns.md | ~962 | DuckDB-specific SQL patterns | No — only relevant for analytics features |
| implementation-enforcement.md | ~1,365 | Pipeline enforcement rules | **Yes — critical for compaction recovery** |
| python-tdd.md | ~227 | TDD cycle, test patterns | No — only relevant for test-heavy features |
| session-workflow.md | ~1,359 | Session tracking, compaction recovery | **Yes — critical for compaction recovery** |
| thinking.md | ~471 | Problem analysis framework | Useful but generic |
| verification.md | ~724 | Validation patterns, gate protocol | **Yes — critical for gate execution** |
| MEMORY.md | ~641 | Cross-session memory | **Yes — project state and lessons** |
| Claude Code system | ~3,000 | Framework instructions | Yes (not modifiable) |
| MCP tool definitions | ~2,000 | Playwright tools | No — not used in planning stages |
| **Total** | **~14,762** | | |

**Compaction-critical content**: ~4,089 tokens (implementation-enforcement + session-workflow + verification + MEMORY.md). This is what MUST survive and be coherent after compaction.

**Feature-specific content**: ~3,517 tokens (cloud-architecture + data-modeling + duckdb-patterns + python-tdd). This should only load when relevant files are being worked on.

### Optimisation Actions

**1. CLAUDE.md cleanup** — Currently accumulates tech entries from every feature. Should be a concise project map (~40 lines max):
- Active branch and feature
- Core tech stack (one entry, not eight overlapping entries)
- Key commands (backend, frontend, tests)
- Pointer to specs/ for feature-specific context
- Pointer to `.claude/rules/` for enforcement rules
- The MANUAL ADDITIONS section (git/GitHub conventions)

**2. Path-scope feature-specific rules** — Add `paths:` frontmatter so they only load when relevant:
```yaml
# duckdb-patterns.md
---
paths: ["docker/**/*.py", "**/*.sql", "**/dbt/**"]
---

# cloud-architecture.md
---
paths: ["cdk/**", "infrastructure/**", "docker-compose*.yml"]
---

# python-tdd.md
---
paths: ["tests/**", "**/*_test.py", "**/test_*.py"]
---
```

**3. MEMORY.md as operational map** — Keep MEMORY.md focused on:
- Current project state (branch, PR status)
- Next task with pointer to relevant design doc
- Plugin architecture summary (how to update, where things live)
- Critical lessons learned (only those that prevent repeated mistakes)
- Remove anything that duplicates CLAUDE.md or rules files

**4. Compaction-critical content audit** — Ensure the three enforcement rules files contain everything needed to recover after compaction, without depending on command file instructions that get lost.

---

## 16. Structured Retro Signals

### Problem Statement

The pipeline currently captures qualitative decision traces in `decisions.md` and process state in `session-summary.md`. These are valuable for session continuity but insufficient for systematic process improvement. There's no structured, quantifiable data about:

- Which tasks took the most tokens/time?
- Which validator gates had false positives or false negatives?
- Which eval thresholds are too loose or too tight?
- Where did the agent struggle and self-correct?
- How do quality scores trend across features?

Without quantified signals, retros are based on narrative memory ("I think /plan took longer than expected") rather than data.

### What to Capture

#### At Task Level (during /implement)

```markdown
<!-- Auto-appended to decisions.md at task completion -->
### Task Metrics: T014 [US3] ProspectPipeline

| Metric | Value |
|--------|-------|
| Turns | 8 |
| Self-corrections | 1 (fixed import path after linter error) |
| Subagent dispatches | 0 |
| Files created | 1 |
| Files modified | 2 |
| Duration (approx) | 4m |
```

#### At Gate Level (during validator execution)

```markdown
### Gate Metrics: GATE_US3

| Metric | Value |
|--------|-------|
| Engineering ACs | 6/6 PASS |
| User Journey steps | 4/4 PASS |
| Intelligence evals | Structural: PASS, Semantic: 0.85, Consistency: σ=8.2 |
| False positives | 0 |
| False negatives identified later | (updated post-feature if discovered) |
| Validator model | Sonnet 4.5 |
| Validator turns | 12 |
```

#### At Feature Level (during /implement completion)

```markdown
### Feature Metrics: 008-ibp-campaign-architecture

| Metric | Value |
|--------|-------|
| Total tasks | 22 |
| Total gates | 7 |
| Gate pass rate | 7/7 first-attempt (100%) |
| Compaction events | 4 |
| Self-corrections | 12 |
| Worktrees used | 0 (single session) |
| Eval fixtures created | 5 |
| Eval pass rate | Structural 100%, Semantic 87% avg |
| Estimated cost | ~$48 |
```

### How Signals Feed Into Retros

After a feature completes, the structured metrics enable data-driven retro questions:

- "US5 took 3x the turns of other stories — why?" → investigate task complexity or unclear spec
- "GATE_US2 had 2 false positives — should we adjust the validator prompt or AC wording?"
- "Semantic eval score for message generation was 0.72 (lowest in pipeline) — is the rubric too strict or is the prompt underperforming?"
- "4 compaction events — should we have used worktrees for this feature size?"
- "Self-corrections concentrated in frontend routing — add a linter for route registration?"

### The Improvement Flywheel

```
Feature N metrics → Retro analysis → Harness improvement → Feature N+1 metrics → ...
```

Each feature's metrics become input for the next feature's process. Retro analysis identifies:
1. **Threshold adjustments**: Tighten or loosen eval thresholds based on observed quality
2. **Linter candidates**: Repeated self-corrections in the same area → create a linter
3. **Prompt tuning signals**: Low semantic scores → refine the LLM prompt
4. **Process improvements**: High compaction rate → use worktrees; high false positive rate → refine validator prompt
5. **Cost tracking**: Per-feature cost trending → validate that optimisations are working

### Storage and Format

Structured metrics are appended to `decisions.md` (they're part of the decision/evidence trail). For cross-feature analysis, a `retro-metrics.json` file accumulates feature-level summaries:

```json
{
  "features": [
    {
      "id": "008-ibp-campaign-architecture",
      "date": "2026-02-14",
      "watermark": "demo",
      "tasks": 22,
      "gates": 7,
      "gate_first_pass_rate": 1.0,
      "compactions": 4,
      "self_corrections": 12,
      "eval_scores": {
        "structural_pass_rate": 1.0,
        "semantic_avg": 0.87,
        "consistency_avg_stddev": 8.2
      },
      "estimated_cost": 48.07,
      "model_main": "opus-4.6",
      "model_subagents": "sonnet-4.5"
    }
  ]
}
```

This file persists across features and enables longitudinal analysis.

---

## 17. Model Benchmarking and Regression

### The Model Upgrade Protocol

When a new Claude model releases (e.g., Sonnet 4.5 → Sonnet 5.0):

1. **Run the full eval suite** against both models using the same fixtures
2. **Compare per-category**: structural pass rate, semantic satisfaction scores, consistency metrics, latency, token consumption, cost
3. **Generate a comparison report**:

```markdown
## Model Comparison: Claude Sonnet 4.5 vs Sonnet 5.0
Date: 2026-03-15
Fixtures: 12 scenarios across 3 chain steps

### UCI Generation
| Metric | Sonnet 4.5 | Sonnet 5.0 | Delta |
|--------|-----------|-----------|-------|
| Structural pass rate | 100% | 100% | — |
| Semantic satisfaction | 0.85 | 0.91 | +0.06 |
| Consistency (σ) | 8.2 | 6.1 | -2.1 (better) |
| Avg latency | 2.1s | 1.8s | -0.3s |
| Avg cost | $0.003 | $0.004 | +$0.001 |

### Message Execution Chain
| Metric | Sonnet 4.5 | Sonnet 5.0 | Delta |
|--------|-----------|-----------|-------|
| Structural pass rate | 100% | 98% | -2% ⚠️ |
| ... | ... | ... | ... |

### Recommendation
- UCI Generation: UPGRADE — quality improvement across all semantic metrics
- Message Execution: INVESTIGATE — 2% structural regression in stage 3
- Overall: CONDITIONAL UPGRADE pending stage 3 investigation
```

4. **Flag regressions**: Any category dropping >5% triggers investigation
5. **Decision**: Update prompts to work with new model, pin old model version, or accept tradeoff

### Cost-Quality Tradeoff Analysis

promptfoo supports parallel testing across models:

```yaml
providers:
  - id: anthropic:messages:claude-sonnet-4-5-20250929
    label: "Current (Sonnet 4.5)"
  - id: anthropic:messages:claude-sonnet-5-0-20260301
    label: "Candidate (Sonnet 5.0)"
tests:
  - vars:
      prospect: file://fixtures/prospects/prospect-001-active.json
    assert:
      - type: llm-rubric
        value: file://rubrics/uci-quality.md
      - type: cost
        threshold: 0.01
      - type: latency
        threshold: 5000
```

This generates a side-by-side comparison with quality, cost, and latency for each model across every fixture.

### The Accumulating Benchmark Estate

Every feature adds fixtures. The benchmark suite grows over time:

```
Feature 008: 5 fixtures (3 ICPs × 5 prospects × 4 chain steps = initial suite)
Feature 009: +3 fixtures (new ICP type, new edge cases)
Feature 010: +2 fixtures (multi-language messaging, new channel)
...
Feature 020: 30+ fixtures covering the full product surface
```

This estate becomes increasingly valuable:
- **Regression detection**: New features can't break old functionality
- **Model comparison**: Comprehensive benchmark across the entire product surface
- **Quality tracking**: Longitudinal view of intelligence quality over time
- **Cost tracking**: How model upgrades affect operational costs

---

## 18. Red Team Analysis of Proposals

### What Could Go Wrong

#### Risk 1: Eval Maintenance Burden

**Concern**: Every new feature requires writing rubrics, creating fixtures, and configuring evals. This adds upfront work to /specify and /plan.

**Mitigation**: Start small — 3-5 fixtures per feature, one rubric per chain step. The eval infrastructure (promptfoo config, fixture directory structure) is created once and reused. The marginal cost of adding a fixture is minutes, not hours.

**Assessment**: The upfront cost is real but the long-term value (regression safety, model benchmarking, autonomous /implement confidence) far exceeds it.

#### Risk 2: LLM-as-Judge Reliability

**Concern**: Using an LLM to judge another LLM's output introduces its own error rate. The judge might miss quality issues or flag false positives.

**Mitigation**: Anthropic's guidance: use binary PASS/FAIL rather than 1-5 scales (reduces noise). Use a different model for judging (reduces self-grading bias). Calibrate judges against human judgment on 20-30 examples. Monitor judge agreement rate over time.

**Assessment**: Medium risk. The alternative (no intelligence validation) is higher risk. The judge doesn't need to be perfect — it needs to catch obvious quality degradation. Fine-grained quality assessment stays with the human during upfront review.

#### Risk 3: Worktree Complexity

**Concern**: Managing multiple worktrees, Docker instances, port allocations, and merge coordination adds operational complexity.

**Mitigation**: Build the automation from the start, but treat the first feature using it as the trial. The automation scripts themselves will need iteration — expect rough edges. The key principle is: build the infrastructure (worktree creation, port arithmetic, merge coordination), accept that the first pass won't be perfect, and refine based on actual failure modes.

**Assessment**: Medium risk. The first feature will surface the real problems (dependency installation timing, merge conflicts, Docker state pollution). Building automation from day one means those problems are captured in code that can be debugged and improved, rather than in manual steps that get forgotten.

#### Risk 4: Over-Engineering for Demo Watermark

**Concern**: Full intelligence eval suites, worktree parallelism, and teaching linters might be overkill for demo-stage features.

**Mitigation**: Apply the watermark principle to the harness itself. Demo watermark: structural evals only, no worktrees, basic linters. Production watermark: full eval suite, parallel execution, comprehensive enforcement.

**Assessment**: Valid concern. The harness should be proportionate to the feature's maturity level.

#### Risk 5: Probabilistic Eval Flakiness

**Concern**: Consistency evals (5 runs, check variance) might flake due to natural LLM variance, creating false failures that block /implement.

**Mitigation**: Set thresholds conservatively (high variance tolerance initially). Track baseline variance per fixture. Only tighten thresholds as baseline data accumulates. Allow threshold overrides with documented justification.

**Assessment**: Medium risk. Requires tuning. Start with generous thresholds and tighten based on data.

---

## 19. Decision Register

| # | Decision | Rationale | Status | Date |
|---|----------|-----------|--------|------|
| D1 | Adopt three-pillar architecture (context efficiency, mechanical enforcement, intelligence validation) | Each pillar addresses a distinct failure mode identified in diagnostic signals | **Implemented** — plugin commands wired for all three pillars | 2026-02-17 |
| D2 | Session boundaries between all pipeline stages | Validated by 008 data — eliminates stale content replay, saves $3.60/pipeline | Approved — apply immediately | 2026-02-17 |
| D3 | Watermark-conditional model selection | Sonnet validated safe for demo watermark; higher watermarks need Opus for governance/architecture | **Implemented** — haiku/sonnet/opus roles in plan.md, implement.md, enforcement rules | 2026-02-17 |
| D4 | promptfoo as the eval framework | Provider-agnostic, YAML-configured, native Anthropic support, first-class CI/CD integration | Proposed — awaiting W2.2+ (fixture creation) | 2026-02-17 |
| D5 | Four-layer intelligence eval system (structural, semantic, consistency, flow-level) | Covers the full spectrum from deterministic to probabilistic validation | Proposed — awaiting W2.2+ | 2026-02-17 |
| D6 | User Journey Tests as a spec-level artifact | Closes the gap between engineering ACs and user expectations | **Implemented** — spec-template.md, analyze.md, implement.md Layer 2 | 2026-02-17 |
| D7 | Human involvement boundary at /analyze review | /implement runs fully autonomously; human reviews output, not process | **Implemented** — autonomous execution flag in analyze.md + implement.md | 2026-02-17 |
| D8 | Recorded LLM responses for deterministic CI (DTU pattern) | Separates "does the plumbing work?" (deterministic) from "does the intelligence work?" (probabilistic) | Proposed — awaiting W2.5 | 2026-02-17 |
| D9 | Worktree automation from day one (skip manual phase) | Building infrastructure captures problems in debuggable code rather than manual steps; the first feature IS the trial | **Implemented** — scripts/worktree.sh + implement.md orchestration protocol | 2026-02-17 |
| D10 | Teaching linters over aspirational rules for constitution enforcement | Mechanical enforcement is more reliable than trust-based compliance | **Implemented** — str.format linter + file size linter as pre-commit hooks | 2026-02-17 |
| D11 | Additive fixture estate growing with each feature | Each feature's fixtures become part of the regression suite | Proposed — awaiting W2.2+ | 2026-02-17 |
| D12 | Model benchmark protocol for version upgrades | The eval estate becomes a benchmark suite for model comparison | Proposed — awaiting eval infrastructure | 2026-02-17 |
| D13 | Differentiated eval strategy by output type (Category A/B) | Text-to-SQL needs tight variance + reasoning transparency; creative outputs (UCI/messages) tolerate wider variance with intent-focus | **Implemented** — spec template Category A/B classification, implement.md Layer 3 eval protocol | 2026-02-17 |
| D14 | Prompt-version coupling with BASELINE/REGRESSION eval modes | Fixtures tied to prompt versions via hash; prompt changes trigger BASELINE mode to re-derive expectations; steady-state runs REGRESSION mode | Proposed — awaiting W6.1+ | 2026-02-17 |
| D15 | Always-loaded context optimisation (map not manual) | CLAUDE.md cleanup to ~40 lines, path-scope feature-specific rules, MEMORY.md as operational map — reduce always-loaded from ~14,762 to ~8,000 tokens | **Partially implemented** — CLAUDE.md + MEMORY.md done; path-scoping broken (platform bug, issue #2) | 2026-02-17 |
| D16 | Structured retro signals at task/gate/feature level | Quantified metrics (turns, self-corrections, eval scores, cost) enable data-driven retros and the continuous improvement flywheel | **Implemented** — decisions-template.md metrics + enforcement rule v1.1.0 learnings checkpoints | 2026-02-17 |
| D17 | Minimal fixture estate — start with 2-3, let structure emerge | GTM data model is in flux; over-engineering fixtures means investing in structure that gets invalidated by data model changes | **Implemented** — evals/ directory structure with minimal scaffolding | 2026-02-17 |

---

## 20. Workstreams — Execution Status

*Updated 2026-02-17 after two execution sessions.*

### 20.1 Completed Workstreams

| Item | What Was Done | Where | Repo |
|------|--------------|-------|------|
| **W1.1** | User Journey Test section added to all 3 user story templates in spec-template.md | `plugin/.specify/templates/spec-template.md` | claude-specify |
| **W1.2** | Intelligence Eval Requirements section (LLM Chain Steps, Eval Rubrics, Satisfaction Thresholds, Fixture Requirements) added to spec-template.md | `plugin/.specify/templates/spec-template.md` | claude-specify |
| **W1.3** | /analyze Coverage Gaps section checks for User Journey Test and Intelligence Eval coverage | `plugin/commands/analyze.md` §4E | claude-specify |
| **W1.4** | /implement validator gate Layer 2: Playwright MCP user journey execution | `plugin/commands/implement.md` Step 10 | claude-specify |
| **W1.5** | /implement validator gate Layer 3: Intelligence eval execution against rubrics/thresholds | `plugin/commands/implement.md` Step 10 | claude-specify |
| **W1.8** | Autonomous execution flag: /analyze asks after PASS, /implement reads from decisions.md | `plugin/commands/analyze.md` §10, `plugin/commands/implement.md` Step 4 | claude-specify |
| **W1.10** | Exemplar field added to Codebase Pointers in tasks template | `plugin/.specify/templates/tasks-template.md` | claude-specify |
| **W2.1** | evals/ directory structure (fixtures, rubrics, recorded, configs, results) + README | `evals/README.md`, `evals/*/` | animis-analytics-agent |
| **W3.2** | Pre-commit hook: file size limit (300 lines, Constitution Principle V reference) | `scripts/lint-file-size.sh`, `.pre-commit-config.yaml` | animis-analytics-agent |
| **W3.3** | Pre-commit hook: str.format() on prompt templates (teaching error message) | `scripts/lint-no-str-format-prompts.sh`, `.pre-commit-config.yaml` | animis-analytics-agent |
| **W4.1** | Docker compose port offset via BACKEND_PORT env var; Vite reads FRONTEND_PORT/BACKEND_PORT | `docker/docker-compose.yml`, `frontend/vite.config.ts` | animis-analytics-agent |
| **W4.2** | Worktree automation script: create/list/teardown/teardown-all with auto port offsets | `scripts/worktree.sh` (181 lines) | animis-analytics-agent |
| **W4.3** | Worktree orchestration protocol in /implement: when to use, creation, dispatch, merge, teardown | `plugin/commands/implement.md` Step 10 | claude-specify |
| **W5.1** | `globs:` frontmatter present on tech rules files | `.claude/rules/duckdb-patterns.md` etc. | animis-analytics-agent |
| **W5.2** | Research subagents use `model: "haiku"` in /plan | `plugin/commands/plan.md` | claude-specify |
| **W5.3** | File-writing subagents use `model: "sonnet"` in /implement | `plugin/commands/implement.md` Step 10 | claude-specify |
| **W5.5** | CLAUDE.md compressed from ~87 lines (8 tech entries) to 44-line project map | `CLAUDE.md` | animis-analytics-agent |
| **W5.6** | MEMORY.md deduplicated — removed overlap with enforcement rules, consolidated to operational map | `memory/MEMORY.md` | auto-memory |
| **W5.7** | implementation-enforcement.md v1.1.0: 3-layer validation, subagent model selection, learnings checkpoints — all survive compaction | `plugin/rules/implementation-enforcement.md` | claude-specify |
| **W7.1** | Task-level metric template in decisions-template.md (turns, self-corrections, files) | `plugin/.specify/templates/decisions-template.md` | claude-specify |
| **W7.2** | Gate-level metric template in decisions-template.md (AC pass/fail, eval scores, validator model) | `plugin/.specify/templates/decisions-template.md` | claude-specify |
| **W7.3** | Feature-level metric template in decisions-template.md (totals, cost, compaction events) | `plugin/.specify/templates/decisions-template.md` | claude-specify |

### 20.2 Remaining Workstreams

#### Next Feature Prerequisites (do during next feature's /implement)

| Item | Change | Blocker | Priority |
|------|--------|---------|----------|
| **W2.2** | Create initial fixture set for 008's intelligence chain (UCI generation, attribute scoring) | Needs backend running to capture actual LLM outputs | High |
| **W2.3** | Write UCI semantic rubric (`evals/rubrics/uci-quality.md`) | Needs W2.2 fixtures to evaluate against | High |
| **W2.4** | Write structural eval config (`promptfooconfig.yaml`) | Needs W2.2 fixtures | High |
| **W3.1** | Pre-commit hook: API contract sync (Pydantic ↔ TypeScript interfaces) | Needs a feature with new API endpoints to test against | High |
| **W4.4** | Worktree refinement (sparse checkout, conflict handling, dep install timing) | Needs first real worktree usage to surface problems | Medium |

#### Backlog (after next feature)

| Item | Change | Depends On | Priority |
|------|--------|------------|----------|
| **W1.6** | Demo-script.md generation at /implement completion | Nice-to-have | Medium |
| **W1.7** | Screenshot gallery generation at /implement completion | Nice-to-have | Medium |
| **W1.9** | Pyramid Summary generation at /specify and /plan completion | Nice-to-have | Low |
| **W2.5** | Instrument LLM service layer for response recording (DTU pattern) | W2.2-W2.4 | Medium |
| **W2.6** | Model comparison config for promptfoo | W2.4 | Medium |
| **W2.7** | Flow-level eval config (chain validation) | W2.4 | Medium |
| **W2.8** | GitHub Actions workflow for eval-on-PR | W2.4 | Low |
| **W3.4** | Structural test: seed data matches Pydantic models | Next feature | Medium |
| **W3.5** | Structural test: all API routes have response models | Next feature | Low |
| **W5.4** | Watermark-conditional model recommendation table in commands | Optional refinement | Medium |
| **W6.1** | Add prompt_version/prompt_hash fields to fixture schema | W2.2 | Medium |
| **W6.2** | Prompt hash detection in eval runner (detect prompt drift) | W6.1 | Medium |
| **W6.3** | BASELINE mode: capture new expected characteristics after prompt change | W6.2 | Low |
| **W6.4** | REGRESSION mode: compare against current version's expected characteristics | W6.2 | Low |
| **W7.4** | Auto-append task metrics to decisions.md at task completion | Process refinement | Medium |
| **W7.5** | retro-metrics.json for cross-feature longitudinal analysis | Multiple features needed | Low |

### 20.3 Known Platform Issues

**Rules path-scoping is broken** (Claude Code bugs [#16299](https://github.com/anthropics/claude-code/issues/16299), [#21858](https://github.com/anthropics/claude-code/issues/21858)):

- The `globs:` frontmatter on `.claude/rules/` files is parsed but NOT respected — all rules load into every turn regardless
- **Impact**: ~3,500 tokens of tech-specific rules (duckdb-patterns, cloud-architecture, python-tdd, data-modeling) load into context on every turn even when working on frontend-only tasks
- **Tracked**: Issue [#2](https://github.com/Drcollinjc/claude-specify/issues/2) in the plugin repo
- **Workaround**: None available. Wait for platform fix. The token waste is annoying but not blocking.

### 20.4 Pickup Instructions for Next Session

**Start here** when continuing this work:

1. **Read this document** (Sections 4-9) for architectural context on the three pillars and eval strategy
2. **Read `memory/MEMORY.md`** for current operational state (branch, completed items, remaining items)
3. **Read `tmp/token-usage-forensic-analysis.md`** if working on cost optimisation

**What's ready to use now** (no further work needed):
- 3-layer validator gates are wired (engineering ACs → Playwright user journey → intelligence evals)
- Worktree orchestration protocol is in /implement (will activate when a feature has 3+ independent stories)
- Teaching linters are in .pre-commit-config.yaml (install with `pre-commit install`)
- Subagent model selection is baked into commands (haiku for research, sonnet for writing/validation)
- Autonomous execution approval flow is wired (/analyze asks, /implement respects)

**What needs a running backend** (do during next feature):
- W2.2-W2.4: Build eval fixtures by running 008's intelligence chain and capturing outputs
- Start backend: `cd docker && docker compose up --build -d`
- Exercise the chain: `curl http://localhost:8000/api/campaign/generate-ucis` (or equivalent)
- Capture outputs into `evals/fixtures/`

**Repos**:
- Main: `/Users/jonathancollins/workspace/animis-analytics-agent` (branch: `main`)
- Plugin: `/Users/jonathancollins/workspace/claude-specify` (branch: `main`)
- Submodule pointer is up to date — run `./scripts/setup-specify.sh` after checkout to install plugin files

---

## 21. Sources

### OpenAI Harness Engineering
- [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/) — Primary source
- [Harness Engineering Is Not Context Engineering](https://mtrajan.substack.com/p/harness-engineering-is-not-context) — Analysis
- [Martin Fowler: Harness Engineering](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html) — Commentary
- [Self-Improving Agents: the Agent Harness](https://arize.com/blog/closing-the-loop-coding-agents-telemetry-and-the-path-to-self-improving-software/) — Extended analysis
- [Unlocking the Codex harness: App Server architecture](https://openai.com/index/unlocking-the-codex-harness/) — Technical deep-dive
- [Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/) — Agent loop internals

### StrongDM Software Factory
- [StrongDM Factory Techniques](https://factory.strongdm.ai/techniques) — Overview page
- [Digital Twin Universe](https://factory.strongdm.ai/techniques/dtu) — Behavioural clones
- [Gene Transfusion](https://factory.strongdm.ai/techniques/gene-transfusion) — Pattern propagation
- [The Filesystem](https://factory.strongdm.ai/techniques/filesystem) — Agent state management
- [Shift Work](https://factory.strongdm.ai/techniques/shift-work) — Interactive vs non-interactive growth
- [Semport](https://factory.strongdm.ai/techniques/semport) — Semantic porting
- [Pyramid Summaries](https://factory.strongdm.ai/techniques/pyramid-summaries) — Multi-resolution context
- [Factory Principles](https://factory.strongdm.ai/principles) — Seed/Validation/Feedback loop
- [Weather Report](https://factory.strongdm.ai/weather-report) — Model selection matrix

### Git Worktrees for AI Agents
- [Claude Code Common Workflows](https://code.claude.com/docs/en/common-workflows) — Official documentation
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams) — Experimental multi-agent
- [agent-worktree](https://github.com/nekocode/agent-worktree) — Rust tool
- [git-worktree-runner](https://github.com/coderabbitai/git-worktree-runner) — CodeRabbit tool
- [parallel-worktrees](https://github.com/spillwavesolutions/parallel-worktrees) — Claude Code skill
- [Nx Blog: Git Worktrees and AI Agents](https://nx.dev/blog/git-worktrees-ai-agents)
- [Upsun: Git Worktrees for Parallel AI Coding](https://devcenter.upsun.com/posts/git-worktrees-for-parallel-ai-coding-agents/)

### LLM Evaluation and Evals
- [Anthropic: Create Strong Empirical Evaluations](https://platform.claude.com/docs/en/test-and-evaluate/develop-tests) — Official eval guide
- [Anthropic: Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) — Agent eval methodology
- [Anthropic: Bloom](https://alignment.anthropic.com/2025/bloom-auto-evals/) — Automated behavioural evals
- [OpenAI: Agent Evals](https://platform.openai.com/docs/guides/agent-evals) — Trace grading
- [OpenAI: Testing Agent Skills with Evals](https://developers.openai.com/blog/eval-skills/) — Practical methodology
- [promptfoo](https://www.promptfoo.dev/docs/intro/) — Open-source eval framework
- [Braintrust: How to Eval](https://www.braintrust.dev/articles/how-to-eval) — Commercial eval platform
- [Langfuse](https://langfuse.com/docs/evaluation/overview) — Open-source LLM observability
- [DeepEval](https://github.com/confident-ai/deepeval) — pytest for LLMs
- [Pragmatic Engineer: LLM Evals Guide](https://newsletter.pragmaticengineer.com/p/evals)
- [Eval-Driven Development](https://github.com/itsderek23/awesome-eval-driven-development) — Awesome list
- [EDDOps: Academic Paper](https://arxiv.org/html/2411.13768v3) — Formal methodology

### Feedback Loops and Validation
- [Playwright MCP](https://github.com/microsoft/playwright-mcp) — Browser automation for agents
- [Playwright MCP 2026 Guide](https://www.testleaf.com/blog/playwright-mcp-ai-test-automation-2026/)
- [Meta: JiT Testing](https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/)
- [Philipp Schmid: Agent Harness](https://www.philschmid.de/agent-harness-2026) — Harness as OS analogy
- [Pact: Contract Testing](https://docs.pact.io/) — Consumer-driven contracts

### Agentic Development Patterns
- [OpenAI: Introducing AgentKit](https://openai.com/index/introducing-agentkit/) — Agent evaluation toolkit
- [LangChain: State of Agent Engineering](https://www.langchain.com/state-of-agent-engineering) — Industry survey
- [LangChain: AgentEvals](https://github.com/langchain-ai/agentevals) — Agent trajectory evaluators
- [Permit.io: Human-in-the-Loop Best Practices](https://www.permit.io/blog/human-in-the-loop-for-ai-agents-best-practices-frameworks-use-cases-and-demo)

---

*This document is a living artifact. It will be updated as workstreams execute and decisions are validated or revised.*

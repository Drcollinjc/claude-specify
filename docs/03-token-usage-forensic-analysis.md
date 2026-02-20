# Token Usage Forensic Analysis: .specify Pipeline

**Feature**: 008-ibp-campaign-architecture
**Model**: Claude Opus 4.6
**Sessions observed**: /specify + /clarify + /plan (single session, 2 compactions), /tasks (fresh), /checklist (fresh), /analyze (fresh), /implement (single session, 4 compactions)
**Date**: 2026-02-12 (updated post-implementation)
**Purpose**: Identify token waste, quantify costs, recommend optimisations per stage
**Decision**: All stages run on Opus 4.6 for feature 008 (baseline). Model optimisation deferred to post-feature assessment. **Post-implementation: Decision Gate answers now available (Section 9).**

---

## 1. How Token Billing Works in Claude Code

Understanding the cost model is essential before analysing waste. Every API call (turn) sends the **full conversation history** plus the system prompt.

### Pricing: Opus 4.6

| Token Type | Rate (per MTok) | Notes |
|-----------|----------------|-------|
| Input (fresh) | $5.00 | First time content appears |
| Input (cache write) | $6.25 | 1.25x input — first turn only |
| Input (cache read) | $0.50 | 90% discount on subsequent turns |
| Output (response) | $25.00 | Visible text + tool calls |
| Output (thinking) | $25.00 | Extended thinking — billed at output rate |

### The "Replay Tax"

Content introduced at turn `j` in a session of `N` turns is sent as input on every subsequent turn. With prompt caching:

```
Total cost for content at turn j = cache_write + (N - j) × cache_read
                                 = tokens × $6.25/MTok + (N - j) × tokens × $0.50/MTok
                                 = tokens × ($6.25 + 0.50 × (N - j)) / 1,000,000
```

**Example**: A 40K-token file read at turn 5 in a 60-turn session:
- Cache write: 40,000 × $6.25/MTok = $0.25
- Cache reads: 40,000 × $0.50/MTok × 55 turns = $1.10
- **Total input cost for that one file: $1.35**

The same file read at turn 55 (5 turns from end):
- Cache write: $0.25
- Cache reads: 40,000 × $0.50/MTok × 5 turns = $0.10
- **Total: $0.35**

**Key insight**: Content read early costs 4-6x more than content read late, because it's replayed on every subsequent turn. Content read by a subagent in its own context window costs ZERO replay tax in the parent.

### Extended Thinking Dominates Output Cost

On Opus 4.6, each turn generates ~3,000-25,000 thinking tokens (average ~10,000) plus ~200-2,000 visible response tokens. Thinking tokens are billed at the **output rate** ($25/MTok).

For a 60-turn session:
- Thinking: ~600,000 tokens × $25/MTok = **$15.00**
- Visible responses: ~60,000 tokens × $25/MTok = **$1.50**
- **Total output: ~$16.50**

Output tokens typically represent **60-75% of total session cost**.

---

## 2. System Prompt Baseline (Fixed Cost Per Turn)

These files are loaded into the system prompt on **every single API turn** and cannot be dropped during a session.

### Always-Loaded Files

| File | Lines | Chars | Tokens (est.) | Relevant to 008? |
|------|------:|------:|---------------:|-------------------|
| CLAUDE.md | 86 | 5,784 | 1,446 | Partially — much is legacy tech |
| cloud-architecture.md | 135 | 5,428 | 1,357 | No — 008 has no infra changes |
| data-modeling.md | 95 | 3,885 | 971 | Partially — DuckDB patterns not used |
| debugging.md | 44 | 955 | 239 | Yes (generic) |
| duckdb-patterns.md | 122 | 3,849 | 962 | No — 008 uses JSON files |
| implementation-enforcement.md | 100 | 5,461 | 1,365 | Yes |
| python-tdd.md | 49 | 909 | 227 | No — demo watermark, no tests |
| session-workflow.md | 101 | 5,435 | 1,359 | Yes |
| thinking.md | 70 | 1,884 | 471 | Yes (generic) |
| verification.md | 78 | 2,896 | 724 | Yes |
| MEMORY.md | 35 | 2,562 | 641 | Yes |
| Claude Code system instructions | — | — | ~3,000 | Yes (framework) |
| MCP tool definitions (Playwright) | — | — | ~2,000 | No — not used in planning |
| **Total** | **915** | **39,048** | **~14,762** | |

### System Prompt Cost Per Session

| Session Length | Cache Write (turn 1) | Cache Reads (turns 2-N) | Total System Prompt Cost |
|---------------|---------------------|------------------------|-------------------------|
| 20 turns | $0.09 | $0.14 | **$0.23** |
| 40 turns | $0.09 | $0.29 | **$0.38** |
| 60 turns | $0.09 | $0.43 | **$0.52** |

### Waste in System Prompt

**Not relevant to 008**: `cloud-architecture.md` (1,357 tok), `duckdb-patterns.md` (962 tok), `python-tdd.md` (227 tok), `data-modeling.md` DuckDB sections (~400 tok), MCP Playwright tools (~2,000 tok)

**Total irrelevant system prompt content**: ~4,946 tokens per turn

Over 60 turns: 4,946 × $0.50/MTok × 59 = **$0.15 wasted on irrelevant rules**

This is relatively small because prompt caching discounts it to 10%. The system prompt is NOT the primary cost driver.

---

## 3. Per-Stage Token Flow

### Methodology

Token estimates use 4 chars/token for prose, 3.5 chars/token for code. Turn counts are estimated from the observed workflow. Thinking tokens estimated at ~10,000/turn average for Opus 4.6.

---

### 3.1 Stage: /specify (~18 turns)

#### What enters context

| Content | Tokens | Category | Persists? |
|---------|-------:|----------|-----------|
| **Skill prompt expansion** | | | |
| /specify command instructions | ~4,360 | Essential | YES — entire session |
| Feature description × 6 (interpolated into bash examples) | ~3,750 | **DUPLICATE** | YES — entire session |
| **File reads** | | | |
| spec-template.md | ~990 | Essential (consumed) | YES — entire session |
| product-principles.md | ~6,260 | Essential (consumed) | YES — entire session |
| ll1-v3-complete.md (chunked reads) | ~43,564 | Essential for /specify | YES — persists into /clarify and /plan |
| ll1-demo-narrative-v2.md | ~3,765 | Essential for /specify | YES — persists into /clarify and /plan |
| UI Mockups (7 JSX files) | ~21,235 | Essential for /specify | YES — persists into /clarify and /plan |
| 005 codebase exploration | ~21,688 | Essential for /specify | YES — persists into /clarify and /plan |
| decisions-template.md | ~196 | Essential (consumed) | YES |
| session-summary-template.md | ~818 | Essential (consumed) | YES |
| **File writes (echoed back)** | | | |
| spec.md (compose + echo) | ~12,754 | Echo is duplicate | YES |
| decisions.md | ~2,000 | Echo is duplicate | YES |
| session-summary.md | ~1,500 | Echo is duplicate | YES |
| checklists/requirements.md | ~832 | Echo is duplicate | YES |
| **Script outputs** | ~1,000 | Essential | YES |
| **User interactions** (clarification Q&A) | ~3,000 | Essential | YES |
| **Subtotal new content** | **~127,712** | | |

#### Cost estimate

| Cost Component | Tokens | Rate | Cost |
|---------------|-------:|------|-----:|
| System prompt (18 turns) | 14,762 × 18 | Cached at $0.50/MTok (17 of 18) | $0.22 |
| New content (cache writes) | 127,712 | $6.25/MTok | $0.80 |
| Content replay within /specify (cache reads) | ~127,712 × avg 9 | $0.50/MTok | $0.57 |
| Thinking tokens | ~180,000 | $25/MTok | $4.50 |
| Response tokens | ~15,000 | $25/MTok | $0.38 |
| **Stage total** | | | **$6.47** |

#### Key waste in /specify

| Waste Item | Tokens | Replay Turns | Wasted Cost | Classification |
|-----------|-------:|------------:|------------:|----------------|
| Feature description × 5 extra copies in skill prompt | 3,125 | 17 | $0.05 | Duplicate (template fix) |
| ll1-v3-complete.md persisting into /clarify + /plan | 43,564 | ~42 | $0.92 | **Stale — should be isolated to subagent** |
| ll1-demo-narrative-v2.md persisting | 3,765 | ~42 | $0.08 | Stale |
| UI Mockups persisting | 21,235 | ~42 | $0.45 | **Stale — should be isolated** |
| 005 codebase persisting | 21,688 | ~42 | $0.46 | **Stale — should be isolated** |
| Write echoes (content composed then echoed) | ~8,543 | ~5 avg | $0.02 | Duplicate (no config to fix) |
| Templates read then never referenced again | ~2,004 | 17 | $0.02 | Stale (minor) |
| **Total identifiable waste** | | | **$2.00** | ~31% of stage cost |

---

### 3.2 Stage: /clarify (~12 turns)

#### What enters context

By the time /clarify starts, the conversation already carries ~128K tokens from /specify.

| Content | Tokens | Category | Persists? |
|---------|-------:|----------|-----------|
| **Inherited from /specify** | ~128,000 | Mostly stale | YES |
| **Skill prompt expansion** | | | |
| /clarify command instructions | ~3,289 | Essential | YES |
| Feature description × 1 | ~625 | Acceptable | YES |
| **File reads** | | | |
| spec.md (re-read for scan) | ~6,377 | Essential — but already in context from /specify write | YES |
| product-principles.md (re-read) | ~6,260 | **DUPLICATE** — already in context from /specify | YES |
| **File writes** | | | |
| spec.md updates (5 clarifications) | ~3,000 | Essential | YES |
| decisions.md update | ~500 | Essential | YES |
| session-summary.md update | ~500 | Essential | YES |
| **User interactions** (5 Q&A) | ~5,000 | Essential | YES |
| **Subtotal new content** | **~25,551** | | |

#### Cost estimate

| Cost Component | Tokens | Rate | Cost |
|---------------|-------:|------|-----:|
| System prompt (12 turns) | 14,762 × 12 | Cached | $0.15 |
| Inherited /specify history (cache reads) | ~128,000 × 12 | $0.50/MTok | $0.77 |
| New content (cache writes) | 25,551 | $6.25/MTok | $0.16 |
| Content replay within /clarify | ~25,551 × avg 6 | $0.50/MTok | $0.08 |
| Thinking tokens | ~120,000 | $25/MTok | $3.00 |
| Response tokens | ~10,000 | $25/MTok | $0.25 |
| **Stage total** | | | **$4.41** |

#### Key waste in /clarify

| Waste Item | Tokens | Replay Turns | Wasted Cost | Classification |
|-----------|-------:|------------:|------------:|----------------|
| Inherited stale /specify content (tmp/ files, templates, 005 code) | ~90,252 | 12 | $0.54 | **Stale — session boundary would eliminate** |
| /specify skill prompt still in history | ~8,110 | 12 | $0.05 | Stale (no config to drop) |
| spec.md re-read (already in context from /specify write) | ~6,377 | 11 | $0.07 | **Duplicate read** |
| product-principles.md re-read | ~6,260 | 11 | $0.07 | **Duplicate read** |
| **Total identifiable waste** | | | **$0.73** | ~17% of stage cost |

---

### 3.3 Stage: /plan (~30 turns)

#### What enters context

By the time /plan starts, the conversation carries ~153K tokens from /specify + /clarify. Note: first compaction likely happened mid-/plan, reducing this. But compaction itself costs a turn (summarisation output tokens).

| Content | Tokens | Category | Persists? |
|---------|-------:|----------|-----------|
| **Inherited from /specify + /clarify** | ~153,000 | Mostly stale | YES (until compaction) |
| **Skill prompt expansion** | | | |
| /plan command instructions | ~1,439 | Essential | YES |
| **File reads** | | | |
| spec.md (re-read) | ~6,377 | **DUPLICATE** (3rd read) | YES |
| decisions.md (re-read) | ~1,664 | **DUPLICATE** (already in context) | YES |
| product-principles.md (re-read) | ~6,260 | **DUPLICATE** (3rd read) | YES |
| constitution.md | ~3,486 | Essential (first read) | YES |
| session-workflow.md | ~1,359 | **DUPLICATE** (already in system prompt!) | YES |
| plan-template.md | ~1,310 | Essential (consumed) | YES |
| **Research agent outputs** | | | |
| Agent: Bedrock models | ~3,000 | Essential (consumed into research.md) | YES |
| Agent: Frontend routing | ~3,000 | Essential (consumed) | YES |
| Agent: Data seeding | ~3,000 | Essential (consumed) | YES |
| Agent: 005 codebase | ~3,000 | Essential (consumed) | YES |
| **File writes (all new, echoed)** | | | |
| research.md | ~4,194 | Echo is duplicate | YES |
| plan.md | ~5,451 | Echo is duplicate | YES |
| data-model.md | ~6,085 | Echo is duplicate | YES |
| campaign-api.yaml | ~5,287 | Echo is duplicate | YES |
| quickstart.md | ~2,735 | Echo is duplicate | YES |
| decisions.md update | ~1,000 | Echo is duplicate | YES |
| session-summary.md rewrite | ~3,507 | Echo is duplicate | YES |
| **Compaction turns** (2 compactions) | | | |
| Compaction summary output | ~4,000 | Essential overhead | YES |
| Post-compaction re-reads | ~10,000 | Recovery overhead | YES |
| **Script outputs** | ~500 | Essential | YES |
| **Subtotal new content** | **~76,654** | | |

#### Cost estimate

Pre-compaction costs are higher because the inherited history is large. Post-compaction costs are lower but the compaction itself costs output tokens. Estimated with 2 compactions splitting the 30 turns into segments of ~12, ~12, ~6.

| Cost Component | Tokens | Rate | Cost |
|---------------|-------:|------|-----:|
| System prompt (30 turns) | 14,762 × 30 | Cached | $0.37 |
| Inherited history (pre-compaction, ~12 turns) | ~153,000 × 12 | $0.50/MTok | $0.92 |
| Post-compaction 1 (compressed history, ~12 turns) | ~40,000 × 12 | $0.50/MTok | $0.24 |
| Post-compaction 2 (compressed history, ~6 turns) | ~50,000 × 6 | $0.50/MTok | $0.15 |
| New content (cache writes) | 76,654 | $6.25/MTok | $0.48 |
| Content replay within /plan | ~76,654 × avg 8 | $0.50/MTok | $0.31 |
| Thinking tokens (incl. compaction summaries) | ~300,000 | $25/MTok | $7.50 |
| Response tokens | ~25,000 | $25/MTok | $0.63 |
| **Stage total** | | | **$10.60** |

#### Key waste in /plan

| Waste Item | Tokens | Replay Turns | Wasted Cost | Classification |
|-----------|-------:|------------:|------------:|----------------|
| Inherited stale content from /specify + /clarify (pre-compaction) | ~90,000 | 12 | $0.54 | **Stale — session boundary eliminates** |
| /specify + /clarify skill prompts in history | ~11,399 | 12 | $0.07 | Stale |
| spec.md 3rd read | ~6,377 | 29 | $0.13 | **Duplicate** |
| product-principles.md 3rd read | ~6,260 | 29 | $0.13 | **Duplicate** |
| decisions.md re-read (already in context) | ~1,664 | 29 | $0.03 | **Duplicate** |
| session-workflow.md re-read (already in system prompt!) | ~1,359 | 29 | $0.02 | **Duplicate — already loaded as a rule** |
| Research agent outputs persisting after research.md written | ~12,000 | ~20 | $0.12 | Stale |
| Write echoes (files written then echoed) | ~14,130 | ~10 avg | $0.07 | Duplicate (no config fix) |
| Compaction overhead (2 × summarisation) | ~8,000 | — | $0.20 | Process overhead |
| Post-compaction recovery reads | ~10,000 | — | $0.06 | Process overhead |
| **Total identifiable waste** | | | **$1.37** | ~13% of stage cost |

---

## 4. Full Session Cost Summary

### Token Flow (all 7 pipeline stages)

| Stage | New Content | Inherited Stale | Thinking | Response | Subagents | Est. Cost |
|-------|------------|----------------|----------|----------|-----------|-----------|
| /specify | 127,712 | 0 | 180,000 | 15,000 | 0 | $6.47 |
| /clarify | 25,551 | ~90,252 stale | 120,000 | 10,000 | 0 | $4.41 |
| /plan | 76,654 | ~101,399 stale | 300,000 | 25,000 | ~166K (4 research) | $10.60 |
| /tasks (fresh) | 69,100 main | 0 | ~200,000 | ~20,000 | ~123K (2 agents) | ~$9.00 |
| /checklist (fresh) | 32,773 main | 0 | ~100,000 | ~10,000 | 0 | ~$3.19 |
| /analyze (fresh) | 67,795 main | 0 | ~150,000 | ~25,000 | ~60K (1 evaluator) | ~$6.10 |
| /implement (1 session) | 155,000 main | compaction-managed | ~1,200,000 | ~250,000 | ~664K (15 agents) | ~$48.07 |
| **Pipeline total** | **~554K main** | **~192K** | **~2,250,000** | **~355,000** | **~1,013K** | **~$87.84** |

### Cost by Category (all 7 stages)

| Category | Est. Cost | % of Total | Reducible? |
|----------|-----------|-----------|------------|
| **Thinking tokens** | $51.25 | 58% | Partially — effort level, model selection |
| **Response tokens** | $8.76 | 10% | No — this is the useful output |
| **Subagent costs** | $16.04 | 18% | Yes — model selection (Sonnet/Haiku for subagents) |
| **System prompt replay** | $2.09 | 2% | Partially — path-scoping rules |
| **Fresh content reads** | $2.91 | 3% | Yes — reduce duplicate reads |
| **Stale content replay** | $5.03 | 6% | **Yes — session boundaries** |
| **Compaction overhead** | $0.66 | 1% | Yes — avoid by session boundaries |
| **Write echoes** | $1.10 | 1% | No — Claude Code doesn't offer config |
| **Total** | **~$87.84** | **100%** | |

> Note: /implement dominates at 55% of pipeline cost ($48.07 of $87.84). Thinking tokens remain the largest category at 58%, but the share dropped from 71% (planning-only) because /implement introduces significant subagent costs (18% of total). Subagents are the second-largest cost category — and the most reducible via model selection.

### What You're Paying For

```
Thinking tokens ████████████████████████████████  58%  ← Biggest lever (model selection + effort)
Subagent costs  ██████████                         18%  ← Second biggest (model selection)
Response tokens █████                              10%  ← Useful output
Stale replay    ███                                 6%  ← Session boundaries fix
Content reads   ██                                  3%  ← Reducible duplicates
System prompt   █                                   2%  ← Mostly cached, low priority
Compaction      █                                   1%  ← Symptom, not cause
Write echoes    █                                   1%  ← Not configurable
```

---

## 5. Duplication Map

### Files Read Multiple Times (Same Session)

| File | Read During | Times Read | Tokens per Read | Total Waste |
|------|------------|:----------:|----------------:|------------:|
| product-principles.md | /specify, /clarify, /plan | 3 | 6,260 | 12,520 duplicate tokens |
| spec.md | /specify (write), /clarify (read), /plan (read) | 3 | 6,377 | 12,754 duplicate tokens |
| decisions.md | /specify (write), /plan (read) | 2 | 1,664 | 1,664 duplicate tokens |
| session-workflow.md | System prompt (always), /plan (explicit read) | 2 | 1,359 | 1,359 duplicate tokens |
| ll1-v3-complete.md | /specify (main), /plan (subagent — isolated) | 1 in main | 43,564 | 0 (subagent isolated) |
| **Total duplicate reads** | | | | **28,297 tokens** |

### Content That Enters Context Twice (Write + Echo)

Every `Write` and `Edit` tool call: Claude composes the content (~N tokens of output) and then the tool result echoes it back (~N tokens of input). This is inherent to how Claude Code works — no configuration to change it.

| File Written | Compose (output) | Echo (input) | Total "Double Pay" |
|-------------|------------------:|-------------:|-------------------:|
| spec.md | 6,377 | 6,377 | 12,754 |
| decisions.md (create + update) | 2,664 | 2,664 | 5,328 |
| session-summary.md (create + rewrite) | 4,257 | 4,257 | 8,514 |
| research.md | 2,097 | 2,097 | 4,194 |
| plan.md | 2,726 | 2,726 | 5,452 |
| data-model.md | 3,043 | 3,043 | 6,086 |
| campaign-api.yaml | 5,287 | 5,287 | 10,574 |
| quickstart.md | 1,368 | 1,368 | 2,736 |
| checklists/requirements.md | 416 | 416 | 832 |
| **Total** | **28,235** | **28,235** | **56,470** |

The echo (input) portion enters the conversation history and gets replayed on every subsequent turn. At cached rates ($0.50/MTok), this costs ~$0.014 per turn × average 20 remaining turns = ~$0.28 across the session. Not huge individually, but adds up.

### Skill Prompt Accumulation

When multiple skills are invoked in one session, ALL their expanded prompts persist in conversation history:

| Skill | Expanded Size | Turns After Invocation | Replay Cost |
|-------|-------------:|----------------------:|------------:|
| /specify | ~8,110 | ~42 (through /clarify + /plan) | $0.17 |
| /clarify | ~3,914 | ~30 (through /plan) | $0.06 |
| /plan | ~1,439 | ~15 (within /plan) | $0.01 |
| **Total** | **~13,463** | | **$0.24** |

The /specify skill prompt (8,110 tokens) persists for 42 turns after it's no longer needed. This is pure waste. In a fresh session for /clarify, it wouldn't exist.

### Reference Documents That Outlive Their Purpose

| Document | Tokens | Read At | Useful Until | Stale For | Replay Cost When Stale |
|----------|-------:|---------|-------------|-----------|----------------------:|
| ll1-v3-complete.md | 43,564 | /specify turn ~3 | End of /specify | /clarify + /plan (~42 turns) | $0.92 |
| UI Mockups (7 files) | 21,235 | /specify turns ~8-10 | End of /specify | /clarify + /plan (~40 turns) | $0.42 |
| 005 codebase files | 21,688 | /specify turns ~12-15 | End of /specify | /clarify + /plan (~35 turns) | $0.38 |
| ll1-demo-narrative-v2.md | 3,765 | /specify turn ~5 | End of /specify | /clarify + /plan (~42 turns) | $0.08 |
| spec-template.md | 990 | /specify turn 2 | /specify turn 3 | Rest of session (~55 turns) | $0.03 |
| Research agent outputs | 12,000 | /plan turn ~5 | /plan turn ~8 | Rest of /plan (~20 turns) | $0.12 |
| **Total stale replay cost** | | | | | **$1.95** |

---

## 6. Available Configuration Levers

### What Claude Code Supports Today

#### 6.1 Session Boundaries (`/clear` or new conversation)

**Impact**: HIGH — eliminates ALL stale content from previous stages
**Configuration**: No config needed — just start a new conversation
**Token savings**: ~$2.00-3.00 per stage transition (eliminates inherited stale content + old skill prompts)
**Trade-off**: Must re-read session-summary.md and decisions.md at start of each new session (~2,000 tokens — trivial)

#### 6.2 Path-Specific Rules Loading

**Impact**: MEDIUM — reduces system prompt by ~5,000 tokens/turn
**Configuration**: Add `paths:` frontmatter to rules files
**Files to scope**:

```yaml
# .claude/rules/duckdb-patterns.md — add at top:
---
paths:
  - "docker/**/*.py"
  - "src/**/*.py"
  - "**/*.sql"
---

# .claude/rules/cloud-architecture.md — add at top:
---
paths:
  - "cdk/**"
  - "infrastructure/**"
  - "docker-compose*.yml"
---

# .claude/rules/python-tdd.md — add at top:
---
paths:
  - "tests/**"
  - "**/*_test.py"
  - "**/test_*.py"
---
```

**Token savings per session**: ~5,000 tokens × 0.50/MTok × 60 turns = ~$0.15
**Worth doing**: Yes, but low priority — prompt caching makes this cheap.

#### 6.3 Model Selection for Subagents

**Impact**: HIGH — subagents are currently running on expensive models
**Configuration**: Specify `model: "haiku"` in Task tool calls for research agents

**Cost comparison for a research agent (~25K total tokens)**:

| Model | Input Cost | Output Cost | Total |
|-------|-----------|------------|------:|
| Opus 4.6 | $0.06 | $0.38 | $0.44 |
| Sonnet 4.5 | $0.04 | $0.23 | $0.27 |
| Haiku 4.5 | $0.01 | $0.08 | $0.09 |

For 4 research agents: Opus = $1.76, Haiku = $0.36. **Savings: $1.40 per /plan run.**

#### 6.4 Extended Thinking Budget

**Impact**: HIGH — thinking tokens are 70% of total cost
**Configuration**:

```bash
# Environment variable
export MAX_THINKING_TOKENS=10000    # Down from 31,999 default

# Or effort level (Opus 4.6 only)
export CLAUDE_CODE_EFFORT_LEVEL=medium  # or "low" for simple stages
```

**Estimated savings**: Reducing from avg ~10K to avg ~5K thinking per turn:
- 60 turns × 5,000 saved × $25/MTok = **$7.50 saved per session** (35% of total)

**Trade-off**: Risk of lower quality reasoning for complex architectural decisions.
**Recommendation**: Use `medium` effort for /clarify and /tasks. Keep `high` for /plan and /implement.

#### 6.5 Model Selection Per Stage

**Impact**: VERY HIGH — Sonnet 4.5 is 80% cheaper output than Opus 4.6
**Configuration**: `/model sonnet` or start session with `claude --model sonnet`

| Stage | Recommended Model | Reasoning |
|-------|------------------|-----------|
| /specify | Sonnet 4.5 | Template-filling, not complex reasoning |
| /clarify | Sonnet 4.5 | Question generation, spec updates |
| /plan | Opus 4.6 | Architecture decisions, constitution check |
| /tasks | Sonnet 4.5 | Task decomposition from existing artifacts |
| /checklist | Sonnet 4.5 | Checklist generation |
| /analyze | Sonnet 4.5 | Cross-artifact comparison |
| /implement | Opus 4.6 | Code generation, complex reasoning |

**Savings estimate** for /specify + /clarify on Sonnet instead of Opus:
- Thinking: 300K tokens × ($25 - $15)/MTok = **$3.00 saved**
- Input: 200K fresh tokens × ($5 - $3)/MTok = **$0.40 saved**
- **Total: ~$3.40 saved** for two stages

#### 6.6 Early Compaction (`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`)

**Impact**: LOW — compaction preserves stale content (just summarised). Better to use session boundaries.
**Configuration**: `export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50`
**When useful**: If you MUST run multiple stages in one session.

#### 6.7 Manual Compact Between Stages

**Impact**: MEDIUM — `/compact` manually summarises before starting next stage
**When useful**: Between stages in the same session
**Limitation**: Still costs output tokens for the summary, and loses nuanced context

#### 6.8 Disable Auto Memory

**Impact**: LOW — MEMORY.md is only 2,562 chars (641 tokens)
**Configuration**: `export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`
**Recommendation**: Keep enabled — the memory is valuable for cross-session continuity

#### 6.9 Tool Search for MCP

**Impact**: LOW-MEDIUM — Playwright tools load definitions (~2K tokens) every turn
**Configuration**: `export ENABLE_TOOL_SEARCH=auto:5`
**When useful**: If you have multiple MCP servers. Current setup only has Playwright.

### What Claude Code Does NOT Support

| Desired Feature | Status | Workaround |
|----------------|--------|------------|
| Truncate tool output (Read/Write echoes) | Not available | None — echoes are inherent |
| Mark content as ephemeral/"forget this" | Not available | `/compact` or session boundary |
| Exclude specific rules files dynamically | Not available | Use `paths:` frontmatter (static) |
| Drop earlier conversation turns | Not available | `/clear` drops everything |
| Summarise subagent output before returning | Not available | Instruct subagent in prompt to be concise |
| Limit skill prompt size | Not available | Modify skill templates to reduce interpolation |

---

## 7. Model Capability Assessment: Opus 4.6 Self-Evaluation

> **Context**: This assessment was written by Opus 4.6 during the 008 pipeline, reflecting on whether its "less powerful" siblings (Sonnet 4.5, Haiku 4.5) could accomplish the same work without quality degradation. Feature 008 will run entirely on Opus 4.6 to establish a quality baseline. This section is preserved for post-feature comparison if model selection is tested on the next feature.

### Assessment Framework

Each stage is evaluated on the cognitive demands it places on the model:

| Demand Type | Description | Opus Advantage |
|-------------|-------------|---------------|
| **Structured extraction** | Parse input, fill templates, follow format instructions | Minimal — Sonnet excels at instruction-following |
| **Multi-document synthesis** | Cross-reference 3+ documents, identify contradictions | Moderate — Opus holds more context coherently |
| **Trade-off reasoning** | Evaluate alternatives with competing criteria | Significant — Opus reasons about 2nd/3rd-order effects |
| **Creative generation** | Write novel content (prompts, narratives, data) | Moderate — quality scales with model capability |
| **Governance compliance** | Check against abstract principles, detect subtle violations | Significant — requires nuanced principle interpretation |

### Per-Stage Capability Matrix

| Stage | Primary Demand | Sonnet Risk | Haiku Risk | Opus Justification |
|-------|---------------|-------------|------------|-------------------|
| /specify | Structured extraction | **Low** — template provides guardrails | Medium — may miss subtle scope issues | Over-qualified for this work |
| /clarify | Structured extraction + ambiguity detection | **Low** — taxonomy framework guides analysis | Medium — weaker at detecting unstated ambiguities | Over-qualified; taxonomy compensates |
| /plan (Phase 0) | Multi-document synthesis + trade-off reasoning | **Medium** — may produce shallower alternatives analysis | High — would miss trade-offs | Justified for architecture decisions |
| /plan (Phase 1) | Structured extraction + creative generation | **Low** — data model and contracts are mechanical | Medium — API design needs domain understanding | Split possible: Opus for Phase 0, Sonnet for Phase 1 |
| /tasks | Structured extraction | **Low** — decomposition from existing artifacts | Low-Medium — task ordering is formulaic | Over-qualified |
| /checklist | Structured extraction | **Low** — checklist generation is template-driven | Low — minimal reasoning required | Over-qualified |
| /analyze | Multi-document synthesis | **Low-Medium** — cross-artifact comparison is structured | Medium — may miss subtle inconsistencies | Borderline; structured format helps |
| /implement | Trade-off reasoning + creative generation + code quality | **Medium** — code generation quality matters | **High** — insufficient for production code | Justified for code generation |
| Subagents: research | Structured extraction | **Low** — read docs, extract patterns | **Low** — information retrieval is Haiku's strength | Significantly over-qualified |
| Subagents: validation | Structured extraction + compliance checking | **Low** — ACs are binary pass/fail | Low-Medium — may need Sonnet for nuanced ACs | Over-qualified |

### Detailed Stage Assessments

#### /specify — Sonnet Expected Quality: 95-100%

The spec template (`spec-template.md`) provides strong structural guardrails. The work is: parse feature description → extract entities → write user stories → generate acceptance criteria. Sonnet 4.5 is excellent at following structured instructions with high fidelity.

**Where Sonnet might fall short**: Detecting a subtle scope violation against the product thesis (e.g., whether a feature crosses the §6 intelligence/execution boundary). But the `/clarify` stage exists specifically to catch what `/specify` misses.

**Evidence from 008**: The spec produced for 008 was largely driven by the detailed user input. The model's contribution was structural organisation, not creative reasoning.

#### /clarify — Sonnet Expected Quality: 90-95%

The ambiguity taxonomy (functional scope, data model, UX flow, non-functional, etc.) provides a structured scanning framework. Sonnet would reliably generate relevant questions from each category.

**Where Sonnet might fall short**: The 5th clarification question in 008 (about full 4-touch sequence generation vs progressive) required understanding the downstream state management implications. Sonnet might default to a simpler question. But: the maximum is 5 questions, and 4 out of 5 strong questions is still effective.

**Risk**: Low. The clarification loop is interactive — the user catches and redirects if a question misses the mark.

#### /plan — Opus Justified for Phase 0, Sonnet Adequate for Phase 1

**Phase 0 (Research + Constitution Check)**: This is where Opus genuinely earns its cost. The 008 /plan required:
- Evaluating 5 research areas with competing trade-offs (e.g., Sequential Strands Agents vs tool-based chaining — the decision hinged on coordination complexity vs debuggability vs the existing 005 pattern)
- Constitution check against 17 abstract principles, some requiring interpretation (e.g., §10 "Explain every AI output" — does "explanation" mean inline provenance or a separate explanation endpoint?)
- Synthesising findings from 4 research agents into coherent decisions with documented rationale

Sonnet would produce decisions but with shallower "Alternatives considered" sections. The *why* behind rejecting tool-based chaining would be less rigorous. For Type 2 (reversible) decisions at demo watermark, this is acceptable. For Type 1 decisions or production watermark, the reasoning depth matters.

**Phase 1 (Design Artifacts)**: Writing data-model.md, campaign-api.yaml, and quickstart.md is mechanical — translating decisions into structured formats. Sonnet would produce equivalent output. The data model has clear entities from the spec, the API contracts follow REST conventions, and the quickstart follows a standard template.

#### /tasks — Sonnet Expected Quality: 95-100%

Task decomposition from plan + spec + data model is formulaic. The plan already specifies the project structure (which files to create), the data model specifies entities, and the contracts specify endpoints. The task generator's job is to order these into a dependency graph.

**Evidence**: The tasks-template.md (230 lines, 8,388 chars) provides extensive structural guidance including dependency patterns and gate placement rules.

#### /implement — Opus Justified

Code generation quality scales with model capability. The 008 feature includes:
- LLM prompt engineering (writing Strands Agent system prompts for 4 execution chain stages)
- SSE streaming implementation
- React component architecture with provenance colour-coding
- Data model translation between camelCase (frontend) and snake_case (backend)

Sonnet would write functional code but might need more iterations. Opus tends to get patterns right on the first pass, which saves downstream debugging turns (and therefore tokens). The net cost difference may be smaller than the model price difference suggests.

#### Subagents — Haiku Sufficient for Research, Sonnet for Validation

**Research agents**: Read a document, extract relevant patterns, summarise findings. This is information retrieval — Haiku's core strength. The 4 research agents dispatched during /plan used 166K total tokens on Opus. On Haiku, the same work would cost ~$0.30 vs ~$2.50. Quality would be equivalent for structured extraction.

**Validator agents**: Check acceptance criteria against implementation. Most ACs are binary (element exists / API returns 200 / colour matches). Haiku could handle simple ACs. But some 008 ACs involve nuanced checks (e.g., "provenance annotations trace to correct source component" requires understanding the colour-coding model). Sonnet is the safe choice here.

### Quality Risk Summary

| Model Switch | Estimated Quality Retention | Token Savings | Quality-Adjusted Savings |
|-------------|---------------------------|---------------|-------------------------|
| /specify: Opus → Sonnet | 95-100% | $2.50 | $2.50 (no quality loss) |
| /clarify: Opus → Sonnet | 90-95% | $1.50 | $1.35 (minor risk) |
| /plan Phase 0: Keep Opus | 100% (baseline) | $0 | $0 |
| /plan Phase 1: Opus → Sonnet | 95-100% | $2.00 | $2.00 (no quality loss) |
| /tasks: Opus → Sonnet | 95-100% | $2.00 | $2.00 (no quality loss) |
| /checklist: Opus → Sonnet | 95-100% | $1.00 | $1.00 (no quality loss) |
| /analyze: Opus → Sonnet | 90-95% | $1.50 | $1.35 (minor risk) |
| /implement: Keep Opus | 100% (baseline) | $0 | $0 |
| Research subagents: Opus → Haiku | 95-100% | $2.14 | $2.14 (no quality loss) |
| Validator subagents: Opus → Sonnet | 95% | $0.50 | $0.48 (minor risk) |
| **Total potential** | | **$13.14** | **$12.82** |

### What "Quality Degradation" Actually Looks Like

The risk isn't catastrophic failure. Sonnet won't produce a broken spec or an invalid data model. The degradation manifests as:

1. **Shallower rationale documentation** — "Chose X because simpler" instead of "Chose X because: (a) matches 005 pattern reducing learning curve, (b) reversible if dynamic routing needed later, (c) avoids tool coordination overhead that only benefits multi-model strategies we're deferring"

2. **Fewer detected edge cases** — Opus might flag that UCI sub-sector anchoring creates a state management question when prospects move between ICPs. Sonnet processes the happy path correctly but is less likely to volunteer adjacent concerns.

3. **Less rigorous governance checks** — The constitution check against 17 principles requires holding abstract principles in mind while scanning concrete implementation decisions. Sonnet may mark more principles as "N/A" when a careful reading reveals a subtle relevance.

4. **More implementation iterations** — Sonnet code may need 1-2 additional edit cycles for complex patterns (SSE streaming, prompt engineering). The saved model cost may be partially offset by additional turns.

### Recommendation: Baseline on Opus 4.6, Reassess Post-Feature

**For feature 008**: Run all stages on Opus 4.6 to establish the quality baseline. The output artifacts (spec, plan, data model, contracts, tasks, code) will serve as the reference standard.

**For feature 009+**: Compare 008 output quality against the Sonnet-estimated quality levels above. If the user assesses that /specify and /clarify output was "template-shaped" (i.e., the model's reasoning didn't materially improve the output beyond what the template structure guided), switch those stages to Sonnet.

**Validation approach**: After 008 is complete, review:
- Did any /specify output require rework at /clarify? (If no → Sonnet is safe)
- Did any /clarify question miss a critical ambiguity caught later? (If no → Sonnet is safe)
- Were /plan Phase 1 artifacts (data-model, contracts) ever revised for quality? (If no → Sonnet is safe)
- Did research subagent output need re-investigation? (If no → Haiku is safe)

---

## 8. Per-Stage Recommendations

### 8.1 /specify

**Run on (008)**: Opus 4.6 (baseline)
**Run on (future, pending validation)**: Sonnet 4.5 (new session)
**008 actual cost**: $6.47 (Opus)
**Future estimated cost**: $3.50 (Sonnet, with optimisations below)

| Optimisation | Change | Savings | Available Now? |
|-------------|--------|--------:|:--------------:|
| Use Sonnet 4.5 instead of Opus | `/model sonnet` or `claude --model sonnet` | $2.50 | Pending 008 review |
| Delegate tmp/ file reads to subagents | Modify /specify command to dispatch Explore agents for reference doc reading | $0.92 | Yes |
| Fix skill template interpolation | Remove 5 duplicate feature description embeddings from bash examples | $0.05 | Yes |
| Use Haiku for reference doc subagents | `model: "haiku"` in Task calls | $0.35 | Yes |
| **Total savings** | | **$3.82** | |

**Model assessment** (see Section 7): Estimated 95-100% quality retention on Sonnet. Primary demand is structured extraction — the spec template provides strong guardrails. The product thesis check is the only task requiring deeper reasoning, and /clarify exists as a safety net.

**008 validation checkpoint**: After 008 /specify is complete, assess: Did the spec require rework at /clarify that a structured model could have prevented? If no significant rework → Sonnet is safe for future features.

**Subagent pattern for reference docs**: Instead of reading ll1-v3-complete.md (43K tokens) directly:

```
Task: "Read tmp/ICP-IBP-Campaign Architecture/ll1-v3-complete.md and extract:
1. Key entities and relationships
2. Scoring methodology
3. Execution chain stages
4. Screen descriptions for S1-S7
Write a summary to specs/008/design/reference-summary.md (max 200 lines)."
model: haiku
subagent_type: Explore
```

Main agent reads only the 200-line summary (~2,500 tokens vs 43,564 tokens).

### 8.2 /clarify

**Run on (008)**: Opus 4.6 (baseline)
**Run on (future, pending validation)**: Sonnet 4.5 (new session — separate from /specify)
**008 actual cost**: $4.41 (Opus, same session as /specify)
**Future estimated cost**: $2.20 (Sonnet, fresh session, with optimisations below)

| Optimisation | Change | Savings | Available Now? |
|-------------|--------|--------:|:--------------:|
| New session (no inherited /specify content) | Start fresh conversation | $0.54 | Yes |
| Use Sonnet 4.5 | Model switch | $1.50 | Pending 008 review |
| Skip re-reading product-principles.md (create compact checklist) | One-time creation of constitution-compact.md (~30 lines) | $0.07 | Yes |
| Don't re-read spec.md (session starts by reading it fresh — same cost but no duplication) | Session boundary handles this | $0.07 | Yes |
| **Total savings** | | **$2.18** | |

**Model assessment** (see Section 7): Estimated 90-95% quality retention on Sonnet. The ambiguity taxonomy framework provides structured guidance. Minor risk: Sonnet may generate slightly less incisive clarification questions for edge cases. The interactive Q&A loop mitigates this — the user redirects if a question misses the mark.

**008 validation checkpoint**: After 008 /clarify is complete, assess: Did any clarification question reveal a subtlety that required deep reasoning (rather than systematic scanning)? If most questions were taxonomy-driven → Sonnet is safe.

**Why a new session**: /clarify needs spec.md, product-principles.md, and decisions.md. That's ~14K tokens to re-read at the start. But the /specify session carried ~128K tokens of inherited stale content. Fresh start is 9x cheaper.

### 8.3 /plan

**Run on (008)**: Opus 4.6 (baseline — justified for trade-off reasoning)
**Run on (future)**: Opus 4.6 for Phase 0 (research + decisions), potentially Sonnet for Phase 1 (design artifacts)
**008 actual cost**: $10.60 (Opus, same session as /specify + /clarify, 2 compactions)
**Future estimated cost**: $6.50 (Opus, fresh session, with optimisations below)

| Optimisation | Change | Savings | Available Now? |
|-------------|--------|--------:|:--------------:|
| New session (no inherited /specify + /clarify content) | Start fresh conversation | $0.61 | Yes |
| Use Haiku for research subagents | `model: "haiku"` in Task calls | $1.40 | Yes |
| Don't re-read spec.md (it will be read once fresh in this session) | Avoid redundant Read call | $0.13 | Yes |
| Don't re-read session-workflow.md (already in system prompt) | Skip explicit Read | $0.02 | Yes |
| Create constitution-compact.md (read 30 lines instead of 510) | One-time file creation | $0.13 | Yes |
| `/compact` after research phase, before design phase | Manual compact mid-stage | $0.50 | Yes |
| Instruct research agents to return concise summaries | Modify agent prompts | $0.12 | Yes |
| **Total savings** | | **$2.91** | |
| | | | |
| *Future*: Use Sonnet for Phase 1 (design artifacts) after Phase 0 research | Switch model mid-session | $2.00 | Pending 008 review |

**Model assessment** (see Section 7): /plan is the strongest case for Opus. Phase 0 requires evaluating 5 research areas with competing trade-offs, synthesising research agent outputs, and checking 17 governance principles against concrete decisions. Sonnet would produce decisions but with shallower rationale — the "Alternatives considered" sections would be less rigorous. Phase 1 (data-model, contracts, quickstart) is mechanical translation of Phase 0 decisions — Sonnet would produce equivalent output.

**008 validation checkpoint**: After 008 /plan is complete, assess two things:
1. Did Phase 0 decisions require reasoning that went beyond "pick the simpler option"? (If yes → Opus justified for Phase 0)
2. Were Phase 1 artifacts (data-model.md, campaign-api.yaml) ever revised for quality issues? (If no → Sonnet safe for Phase 1)

**Mid-stage compact**: After writing research.md, the research agent outputs and reference doc discussions are no longer needed. `/compact focus on research.md findings, spec.md requirements, plan.md technical decisions` would shed ~30K tokens before the design phase.

### 8.4 /tasks (observed — 008 session)

**Run on (008)**: Opus 4.6 (fresh session after `/clear`)
**Run on (future, pending validation)**: Sonnet 4.5 (new session)
**008 estimated cost**: ~$8.00-10.00 (Opus, fresh session)
**Future estimated cost**: ~$4.00-5.00 (Sonnet)

| Optimisation | Change | Savings | Available Now? |
|-------------|--------|--------:|:--------------:|
| New session (fresh start) | ✅ Applied — user cleared context before /tasks | Validated: eliminated all /plan stale content | Yes |
| Use Sonnet 4.5 | Task decomposition is structured, not creative | ~$3.00 vs Opus | See validation below |
| Use Haiku for Explore subagent | Codebase exploration is structured file reading | ~$0.30 | Yes |
| Use Haiku for verification subagent | Completion gate is 9 binary checks | ~$0.20 | Yes |
| Don't read governance docs | Tasks doesn't need constitution check | ✅ Applied — no governance reads | Yes |
| Don't read reference docs (tmp/) | All info is in plan.md + data-model.md now | ✅ Applied — no tmp/ reads | Yes |
| **Total** | | Use Sonnet + Haiku subagents, fresh session | |

#### Observed Token Flow

| Content | Tokens (est.) | Category |
|---------|-------------:|----------|
| **Skill prompt expansion** | | |
| /tasks command instructions | ~3,600 | Essential |
| **File reads (main context)** | | |
| spec.md | ~6,400 | Essential |
| plan.md | ~2,700 | Essential |
| data-model.md | ~3,000 | Essential |
| research.md | ~2,100 | Essential |
| quickstart.md | ~1,400 | Essential |
| campaign-api.yaml | ~5,300 | Essential |
| tasks-template.md | ~3,600 | Essential (consumed) |
| session-summary.md | ~1,800 | Essential |
| decisions.md | ~1,700 | Essential |
| **Subagent dispatches** | | |
| Explore agent (Sonnet): codebase exploration | ~80K (isolated) | Essential — 34 tool uses in subagent context |
| Explore agent (Sonnet): completion gate verification | ~43K (isolated) | Essential — 9 checks |
| **Subagent results returned to main** | ~6,000 | Essential |
| **File writes** | | |
| tasks.md (compose + echo) | ~30,000 | Output + echo |
| decisions.md update | ~1,000 | Output + echo |
| session-summary.md updates (3 edits) | ~500 | Output + echo |
| **Subtotal new content (main)** | **~69,100** | |
| **Subtotal subagent (isolated)** | **~123,000** | |

#### 008 Validation Checkpoint (Completed)

**Were the generated tasks well-ordered with correct dependencies?**
- ✅ Dependency graph verified by completion gate agent (9/9 checks PASS)
- ✅ All task IDs sequential and unique
- ✅ No parallel groups contain same-file tasks
- ✅ All 7 user stories have ACs, codebase pointers, and validator gates

**Quality assessment**: The output was high quality but the **extended thinking was disproportionate to the task**. The model deliberated extensively (~15K+ thinking tokens) on the same-file rule interpretation, task granularity decisions, and whether to split frontend tasks per-story. These were ultimately rule-application decisions, not creative reasoning — the tasks-template.md provided the framework, the model just needed to apply it systematically.

**Conclusion: Sonnet is safe for /tasks.** The primary challenge was structured decomposition guided by a detailed template. The codebase exploration (the genuinely useful part) was already delegated to a subagent. Sonnet's instruction-following capability is sufficient for template-guided task generation.

#### Key Insights from /tasks Session

1. **Session boundary validated**: Fresh start meant ~0 stale content. Total main-context reads (~32K tokens) were all essential. No waste from inherited /specify + /clarify + /plan content.

2. **Subagent isolation worked perfectly**: The Explore agent read 34 files (~80K tokens) for codebase exploration. These stayed in the subagent's context — the main agent received only a ~4K summary. Without subagent isolation, 80K tokens would replay on every subsequent turn (at $0.50/MTok × ~15 remaining turns = $0.60 waste).

3. **Subagent model selection opportunity**: Both subagents ran on Sonnet. The Explore agent's work was structured file reading — Haiku would produce equivalent output for ~$0.09 vs ~$0.27 (Sonnet). The verification agent ran 3 Read tool calls and applied 9 binary checks — also Haiku-safe.

4. **tasks.md is the largest single file write**: At ~15K tokens of output, it's the most expensive Write in the pipeline so far. The echo adds another ~15K to context. This is unavoidable — the file needs to be comprehensive for the implementing agent.

5. **Thinking token dominance confirmed**: The extended thinking for task organization decisions was the largest cost component. Much of it was deliberating on interpretation of the same-file rule and task granularity — decisions that Sonnet would resolve faster with less deliberation (and arrive at the same conclusion).

6. **No governance reads needed**: /tasks correctly skipped product-principles.md and constitution.md — these aren't needed for task decomposition. This saved ~10K tokens of reads plus replay costs.

### 8.5 /checklist (observed — 008 session)

**Run on (008)**: Opus 4.6 (fresh session after `/clear`)
**Run on (future, pending validation)**: Sonnet 4.5 (new session)
**008 estimated cost**: ~$4.00-5.00 (Opus, fresh session)
**Future estimated cost**: ~$2.00-2.50 (Sonnet)

| Optimisation | Change | Savings | Available Now? |
|-------------|--------|--------:|:--------------:|
| New session (fresh start) | ✅ Applied — user cleared context before /checklist | Validated: eliminated all /tasks stale content | Yes |
| Use Sonnet 4.5 | Checklist generation is template-driven structured extraction | ~$2.00 vs Opus | See validation below |
| Skip product-principles.md re-read | Create constitution-compact.md (thesis summary) | ~$0.10 | Yes |
| **Total** | | Use Sonnet, fresh session | |

#### Observed Token Flow

| Content | Tokens (est.) | Category |
|---------|-------------:|----------|
| **Skill prompt expansion** | | |
| /checklist command instructions | ~4,940 | Essential — **largest skill prompt in the pipeline** |
| **File reads (main context)** | | |
| spec.md | ~6,377 | Essential |
| product-principles.md | ~6,260 | Essential (thesis check required by command) — **4th read in pipeline** |
| checklist-template.md | ~200 | Essential (consumed) |
| session-summary.md | ~1,754 | Essential |
| plan.md | ~2,726 | Essential |
| tasks.md | ~5,000 | Essential |
| requirements.md (existing checklist) | ~416 | Essential (avoid duplication) |
| **Script outputs** | ~200 | Essential |
| **User interactions** (1 clarifying Q&A) | ~500 | Essential |
| **File writes (echoed back)** | | |
| checklists/full-audit.md (compose + echo) | ~4,000 | Output + echo |
| session-summary.md edit | ~100 | Output + echo |
| **Verification bash outputs** | ~300 | Essential |
| **Subtotal new content** | **~32,773** | |

#### Cost Estimate

| Cost Component | Tokens | Rate | Cost |
|---------------|-------:|------|-----:|
| System prompt (~10 turns) | 14,762 × 10 | Cached at $0.50/MTok (9 of 10) | $0.16 |
| New content (cache writes) | 32,773 | $6.25/MTok | $0.20 |
| Content replay within /checklist (cache reads) | ~32,773 × avg 5 | $0.50/MTok | $0.08 |
| Thinking tokens | ~100,000 | $25/MTok | $2.50 |
| Response tokens | ~10,000 | $25/MTok | $0.25 |
| **Stage total** | | | **~$3.19** |

#### Waste in /checklist

| Waste Item | Tokens | Replay Turns | Wasted Cost | Classification |
|-----------|-------:|------------:|------------:|----------------|
| product-principles.md (4th read in pipeline; could use compact version) | ~6,260 | 9 | $0.03 | **Duplicate across stages** |
| /checklist skill prompt examples & anti-examples (4,940 tokens — half is examples) | ~2,500 | 9 | $0.01 | Overhead (template design issue) |
| **Total identifiable waste** | | | **~$0.04** | ~1% of stage cost |

**Waste is minimal** because the session was fresh and the stage is efficient. The dominant cost is thinking tokens (78% of total).

#### 008 Validation Checkpoint (Completed)

**Was the generated checklist well-structured with appropriate traceability?**
- ✅ 58 items across 10 quality dimensions
- ✅ 100% traceability (58/58 items have spec references or gap markers)
- ✅ All items are requirements-quality questions, not implementation checks
- ✅ Product thesis principles correctly identified and applied (§2, §3, §10)
- ✅ Acceptance criteria quality (D18) checks included

**Quality assessment**: Output quality was high but the **thinking was disproportionate**. The model deliberated extensively on category boundaries, item phrasing, and whether items crossed the "testing requirements" vs "testing implementation" line. These are judgment calls, but the command template provides extensive examples and anti-examples (~2,500 tokens of examples) that Sonnet would follow equally well.

**Conclusion: Sonnet is safe for /checklist.** The primary challenge was structured generation guided by a detailed template with clear anti-patterns. The D18 acceptance criteria quality rules are mechanical checks. The product thesis alignment required reading principles and mapping to feature context — structured extraction, not creative reasoning.

#### Key Insights from /checklist Session

1. **Largest skill prompt**: At ~4,940 tokens, /checklist is the largest command in the pipeline. Roughly half (~2,500 tokens) is examples and anti-examples. These are valuable for quality guardrails but represent fixed overhead per session.

2. **Session boundary validated again**: Fresh start meant all reads were essential. No inherited stale content. Waste was near-zero at ~$0.04 (1% of stage cost).

3. **No subagents needed**: Unlike /tasks (which dispatched Explore agents for codebase scanning), /checklist works entirely in main context. The work is cross-referencing spec sections against quality criteria — inherently sequential.

4. **product-principles.md replay tax across pipeline**: This is now the 4th read of product-principles.md across the pipeline (/specify, /clarify, /plan, /checklist). At ~6,260 tokens per read, the cumulative fresh-read cost is ~$0.16. With session boundaries (each read is fresh, no cross-session replay), this is acceptable. The constitution-compact.md recommendation would reduce each read to ~800 tokens, saving ~$0.14 across 4 reads — marginal but clean.

5. **Thinking tokens dominate even more here**: At 78% of stage cost (vs 70% pipeline average), /checklist has an even higher thinking-to-output ratio. The model "thinks hard" about requirement quality assessment but the output is a structured list. Sonnet would resolve these assessments with less deliberation.

### 8.6 /analyze (observed — 008 session)

**Run on (008)**: Opus 4.6 (fresh session after `/clear`)
**Run on (future, pending validation)**: Sonnet 4.5 (new session)
**008 estimated cost**: ~$6.00-8.00 (Opus, fresh session — higher than pre-estimate due to checklist evaluation subagent + post-analysis remediation work)
**Future estimated cost**: ~$3.00-4.00 (Sonnet)

| Optimisation | Change | Savings | Available Now? |
|-------------|--------|--------:|:--------------:|
| New session (fresh start) | ✅ Applied — user cleared context before /analyze | Validated: eliminated all /checklist stale content | Yes |
| Use Sonnet 4.5 | Cross-artifact comparison is structured, template-guided | ~$3.00 vs Opus | See validation below |
| Use Haiku for checklist evaluation subagent | Checklist items are binary pass/fail checks against spec sections | ~$0.20 | Yes |
| Skip redundant governance doc reads | Constitution + thesis already checked in prior stages; /analyze only needs to verify no *new* violations from plan/task changes | ~$0.15 | Yes |
| **Total** | | Use Sonnet + Haiku subagent, fresh session | |

#### Observed Token Flow

| Content | Tokens (est.) | Category |
|---------|-------------:|----------|
| **Skill prompt expansion** | | |
| /analyze command instructions | ~2,705 | Essential |
| **Prerequisites script** | ~200 | Essential |
| **File reads (main context)** | | |
| spec.md | ~6,377 | Essential |
| plan.md | ~2,726 | Essential |
| tasks.md | ~5,000 | Essential |
| decisions.md | ~1,664 | Essential |
| session-summary.md | ~1,754 | Essential |
| design/research.md | ~2,097 | Essential |
| design/data-model.md | ~3,043 | Essential |
| design/contracts/campaign-api.yaml | ~5,287 | Essential |
| checklists/requirements.md | ~416 | Essential |
| checklists/full-audit.md | ~2,040 | Essential |
| product-principles.md | ~6,260 | Essential (thesis alignment check required) — **5th read in pipeline** |
| constitution.md | ~3,486 | Essential (constitution alignment check) |
| **Subagent dispatches** | | |
| Explore agent (Sonnet): checklist evaluation (full-audit.md 58 items) | ~60K (isolated) | Essential — evaluated each item against spec/plan/tasks |
| **Subagent results returned to main** | ~3,000 | Essential |
| **Analysis output** | | |
| Findings table (15 findings) | ~2,000 | Output |
| Coverage summary table | ~3,000 | Output |
| Metrics and next actions | ~500 | Output |
| **File writes (echoed back)** | | |
| decisions.md update (gate decision + adjustments) | ~1,500 | Output + echo |
| session-summary.md updates | ~500 | Output + echo |
| checklists/full-audit.md (18 items checked) | ~2,040 | Output + echo |
| **Post-analysis remediation** (user-directed) | | |
| spec.md edit (FR-015 buyer count) | ~500 | Remediation |
| plan.md edit (Scale/Scope) | ~500 | Remediation |
| tasks.md edit (T001) | ~500 | Remediation |
| research.md edit (roleId→buyerId + data counts) | ~500 | Remediation |
| AWS Bedrock model verification (curl + invoke-model) | ~1,000 | Pre-implement check |
| Playwright MCP verification (browser_navigate) | ~500 | Pre-implement check |
| Settings file reads (.claude/settings*.json) | ~2,000 | Pre-implement check |
| Token analysis doc read (this file) | ~7,000 | Session documentation |
| **Subtotal new content (main)** | **~67,795** | |
| **Subtotal subagent (isolated)** | **~60,000** | |

#### Cost Estimate

| Cost Component | Tokens | Rate | Cost |
|---------------|-------:|------|-----:|
| System prompt (~25 turns) | 14,762 × 25 | Cached at $0.50/MTok (24 of 25) | $0.44 |
| New content (cache writes) | 67,795 | $6.25/MTok | $0.42 |
| Content replay within /analyze (cache reads) | ~67,795 × avg 12 | $0.50/MTok | $0.41 |
| Thinking tokens | ~150,000 | $25/MTok | $3.75 |
| Response tokens | ~25,000 | $25/MTok | $0.63 |
| Subagent (Sonnet): checklist evaluation | ~60,000 | Mixed rates | ~$0.45 |
| **Stage total** | | | **~$6.10** |

#### Waste in /analyze

| Waste Item | Tokens | Replay Turns | Wasted Cost | Classification |
|-----------|-------:|------------:|------------:|----------------|
| product-principles.md (5th read in pipeline; could use compact version) | ~6,260 | 20+ | $0.06 | **Duplicate across stages** |
| constitution.md (could use compact version for re-check) | ~3,486 | 20+ | $0.03 | **Duplicate across stages** |
| Post-analysis remediation in same session (edits to 4 files + verification) | ~12,000 | 10+ | $0.06 | **Session scope creep** — remediation could be deferred to /implement or a new session |
| Token analysis doc read (documentation task, not part of /analyze protocol) | ~7,000 | 5+ | $0.02 | **Out-of-scope work in session** |
| **Total identifiable waste** | | | **~$0.17** | ~3% of stage cost |

**Waste is low** because the session was fresh. The dominant cost is thinking tokens (61% of total). The post-analysis remediation and pre-implement checks added ~$1.50 to what would otherwise be a pure /analyze stage cost of ~$4.50.

#### 008 Validation Checkpoint (Completed)

**Was the analysis comprehensive and accurate?**
- ✅ All 3 core artifacts cross-referenced (spec.md, plan.md, tasks.md)
- ✅ All design artifacts loaded and checked (research.md, data-model.md, campaign-api.yaml)
- ✅ Both governance documents checked (product-principles.md, constitution.md)
- ✅ Checklist evaluation: 18/58 items passed in full-audit.md (most failures are acceptable demo-watermark underspecification)
- ✅ 15 findings identified (0 CRITICAL, 1 HIGH, 7 MEDIUM, 7 LOW)
- ✅ 100% FR→task coverage verified
- ✅ All 7 user stories have validator gates confirmed
- ✅ 0 constitution violations, 0 thesis violations

**Quality assessment**: The cross-artifact comparison required holding spec requirements, plan decisions, task descriptions, and data model entities simultaneously. The HIGH finding (F1: buyer count inconsistency between spec FR-015 and plan Scale/Scope) was a genuine catch — `3-5 buyers/prospect × 15 prospects ≠ ~25 total buyers`. This inconsistency would have caused confusion during seed data generation. The checklist evaluation subagent was appropriately conservative but occasionally too strict — 4 items (CHK006, CHK031, CHK045, CHK051) were manually upgraded where design artifacts adequately covered the requirement but the spec-only reading said "not specified."

**Conclusion: Sonnet is likely safe for /analyze, but with caveats.** The structured format (findings table with severity/category/recommendation columns) provides strong guardrails. The coverage gap analysis is mechanical (does each FR have a task?). However, the **subtle cross-artifact inconsistencies** (like F1) require genuine reasoning about numerical relationships across documents. Sonnet would catch most issues but might miss the subtler numerical/logical inconsistencies. **Recommendation**: Use Sonnet for /analyze but with a final Opus review pass for MEDIUM+ findings — total cost ~$3.50 (Sonnet base) + $0.50 (Opus review) = $4.00, still cheaper than full Opus at $6.10.

#### Key Insights from /analyze Session

1. **Session boundary validated again**: Fresh start meant all reads were essential. No inherited stale content from /checklist. This is the 4th consecutive stage to validate the "one stage per session" recommendation.

2. **Checklist evaluation is a natural subagent task**: The 58-item full-audit.md evaluation was correctly delegated to a subagent. Each item requires reading the question, finding the relevant spec section, and making a binary judgment. This is structured work that benefits from isolation (the 60K tokens of spec cross-referencing stay in the subagent's context).

3. **Post-analysis remediation inflated session cost**: The user requested artifact updates (F1/F2 fixes) and pre-implement checks (AWS Bedrock, Playwright MCP, permissions) in the same session. This added ~$1.50 to the pure /analyze cost. Recommendation: keep remediation as a separate session or defer simple fixes to /implement startup.

4. **Governance doc replay tax continues**: product-principles.md has now been read 5 times across the pipeline. At ~6,260 tokens per read, the cumulative fresh-read cost is ~$0.20. constitution-compact.md would reduce this to ~$0.04 total.

5. **Thinking tokens still dominate**: At 61% of stage cost, thinking is the primary expense. The model deliberated extensively on severity classification (CRITICAL vs HIGH vs MEDIUM) and coverage gap analysis. These are judgment calls guided by clear heuristics in the /analyze command — Sonnet's instruction-following would produce similar classifications with less deliberation.

6. **Subagent model selection**: The checklist evaluation subagent ran on Sonnet. The work is structured binary evaluation — Haiku would produce equivalent output. Estimated savings: ~$0.25 per /analyze run.

### 3.7 Stage: /implement (observed — 008 session)

#### Session Structure

Single extended session with **4 compaction events**, producing 4 continuation segments. Estimated ~100 main-context turns total across all segments (~25 turns per segment before compaction). Implementation covered 22 tasks + 7 validator gates across 10 phases.

**Subagent-heavy architecture**: 15 subagents dispatched total — 8 for parallel file writing (Opus, general-purpose), 7 for validator gates (Sonnet, Explore).

#### What enters context (main agent)

| Content | Tokens | Category | Persists? |
|---------|-------:|----------|-----------|
| **Skill prompt expansion** | | | |
| /implement command instructions | ~3,473 | Essential | YES — entire session |
| /analyze auto-run (embedded in /implement) | ~2,705 | Essential | YES (pre-implementation gate) |
| **File reads (state recovery — repeated after each compaction)** | | | |
| spec.md (ACs reference) | ~6,377 × 4 reads | Essential — **4 reads due to compaction recovery** | YES |
| tasks.md (hydration + reference) | ~5,000 × 2 reads | Essential | YES |
| decisions.md (growing: 1,664 → 9,000) | ~5,000 × 5 reads | Essential — **growing file read repeatedly** | YES |
| session-summary.md | ~1,754 × 4 reads | Essential (compaction recovery) | YES |
| plan.md | ~2,726 | Essential (1 read at start) | YES |
| **Implementation file reads (for editing)** | | | |
| Frontend pages (7 files, ~150-270 lines each) | ~15,000 | Essential | YES |
| Frontend components (8 files, ~20-80 lines each) | ~8,000 | Essential | YES |
| Backend files (models, service, routes, app.py) | ~12,000 | Essential | YES |
| Seed data files (7 JSON files, spot-checks) | ~5,000 | Essential | YES |
| **Implementation file writes (main agent edits)** | | | |
| Page component edits (error states, navigation fixes) | ~8,000 | Output + echo | YES |
| decisions.md updates (~10 edits: gates, learnings, completion) | ~12,000 | Output + echo | YES |
| session-summary.md updates | ~2,000 | Output + echo | YES |
| **Subagent dispatch prompts** | ~8,000 | Essential (15 dispatches) | YES |
| **Subagent result returns** | ~15,000 | Essential (15 results) | YES |
| **Task system operations** (TaskCreate × 29, TaskUpdate × ~40) | ~10,000 | Essential | YES |
| **Compaction overhead** (4 compactions) | | | |
| Compaction summary output | ~16,000 | Process overhead | YES |
| Post-compaction re-reads | ~20,000 | Recovery overhead | YES |
| **Subtotal new content (main)** | **~155,000** | | |

#### Subagent costs (isolated from main context)

| Subagent Type | Count | Model | Total Tokens (all) | Est. Cost |
|---------------|------:|-------|-------------------:|----------:|
| **Implementation file writers** | 8 | Opus 4.6 | 312,576 | ~$4.50 |
| LLM prompt templates (a2b0a7f) | 1 | Opus | 35,330 | ~$0.55 |
| messages.json seed data (a0c9d15) | 1 | Opus | 70,925 | ~$1.10 |
| attributes.json seed data (a6bcd61) | 1 | Opus | 42,354 | ~$0.65 |
| TypeScript types (acc542e) | 1 | Opus | 32,791 | ~$0.50 |
| RootLayout (a7d4b5d) | 1 | Opus | 28,285 | ~$0.44 |
| App.tsx routes + stubs (adc3547) | 1 | Opus | 29,169 | ~$0.45 |
| Campaign API functions (a60b824) | 1 | Opus | 38,081 | ~$0.59 |
| useCampaign hook (a29723c) | 1 | Opus | 35,641 | ~$0.55 |
| **Validator gates** | 7 | Sonnet 4.5 | 322,350 | ~$2.50 |
| GATE_US1 (est.) | 1 | Sonnet | ~45,000 | ~$0.35 |
| GATE_US2 (a5898bc) | 1 | Sonnet | 48,751 | ~$0.38 |
| GATE_US3 (a6f16dc) | 1 | Sonnet | 44,531 | ~$0.35 |
| GATE_US4 (afd672e) | 1 | Sonnet | 52,740 | ~$0.41 |
| GATE_US5 (ad03644) | 1 | Sonnet | 35,514 | ~$0.27 |
| GATE_US6 (ad47d40) | 1 | Sonnet | 43,667 | ~$0.34 |
| GATE_US7 (a9455bf) | 1 | Sonnet | 52,147 | ~$0.40 |
| **File verification** | 1 | Haiku 4.5 | 29,557 | ~$0.09 |
| **Subtotal subagents (isolated)** | **16** | | **664,483** | **~$7.09** |

#### Cost estimate

| Cost Component | Tokens | Rate | Cost |
|---------------|-------:|------|-----:|
| System prompt (100 turns, 4 segments) | 14,762 × 100 | Cached at $0.50/MTok | $0.74 |
| Fresh content reads (cache writes) | 155,000 | $6.25/MTok | $0.97 |
| Inherited history replay (with compaction resets, avg ~50K × 80 turns) | ~4,000,000 | $0.50/MTok | $2.00 |
| New content replay within segments | ~155,000 × avg 8 | $0.50/MTok | $0.62 |
| Thinking tokens (100 turns × avg 12K) | ~1,200,000 | $25/MTok | $30.00 |
| Response tokens (100 turns × avg 2.5K) | ~250,000 | $25/MTok | $6.25 |
| Compaction overhead (4 × summary output) | ~16,000 | $25/MTok | $0.40 |
| Implementation subagents (Opus) | 312,576 | Mixed rates | ~$4.50 |
| Validator subagents (Sonnet) | 322,350 | Mixed rates | ~$2.50 |
| Verification subagent (Haiku) | 29,557 | Mixed rates | ~$0.09 |
| **Stage total** | | | **~$48.07** |

#### Key waste in /implement

| Waste Item | Tokens | Replay Turns | Wasted Cost | Classification |
|-----------|-------:|------------:|------------:|----------------|
| spec.md re-read 3 extra times (compaction recovery) | ~19,131 | ~60 avg | $0.57 | **Compaction tax — session per story would eliminate** |
| decisions.md growing file re-read 4 extra times | ~20,000 | ~50 avg | $0.50 | **Compaction tax — growing file amplifies replay** |
| session-summary.md re-read 3 extra times | ~5,262 | ~60 avg | $0.16 | **Compaction tax** |
| /analyze + /implement skill prompts persisting after gate | ~6,178 | ~80 | $0.25 | Stale (no config fix) |
| Implementation subagents on Opus instead of Sonnet | — | — | ~$2.00 | **Model selection — Sonnet adequate for file writing** |
| All 7 stories in one session (caused 4 compactions) | — | — | ~$3.00 | **Session boundary — one story per session recommended** |
| Compaction overhead (4 × summary + recovery) | ~36,000 | — | $0.90 | Process overhead (avoidable with session boundaries) |
| **Total identifiable waste** | | | **~$7.38** | ~15% of stage cost |

#### Key Insights from /implement Session

1. **Thinking tokens dominate even more at /implement**: At $30.00 (62% of stage cost), thinking is the overwhelming expense. The model deliberates on code structure, component design, and data model translation — work that Opus does well first-pass but at 5x the output rate of Sonnet. The question is whether Sonnet's potential for more edit iterations still comes out cheaper.

2. **4 compactions is too many**: Each compaction costs ~$0.35 (summary output + recovery reads) plus loses nuanced context about in-progress work. The recommendation to run one user story per session would have produced ~7 shorter sessions with 0 compactions, eliminating ~$3.00 in compaction overhead plus ~$1.23 in repeated session-artifact reads.

3. **Subagent-heavy architecture was highly effective**: 15 subagents kept ~665K tokens out of the main context. Without subagent isolation, these tokens would replay on every subsequent main-context turn. Estimated savings: 665K × $0.50/MTok × 50 avg remaining turns = **$16.63 saved** by using subagents. The subagent architecture paid for itself 2.3x over.

4. **Implementation file-writing subagents could use Sonnet**: The 8 Opus subagents produced high-quality code (TypeScript types, React components, API functions, JSON seed data). But this work is **structured extraction from plan.md + data-model.md + contracts** — exactly the kind of template-guided generation where Sonnet excels. Estimated savings: ~$2.00 (8 subagents × ~$0.25 delta per agent).

5. **Validator subagents (Sonnet) worked excellently**: All 7 gates produced structured PASS/FAIL reports with specific evidence. Two false positives emerged (US3 AC4 route path assumption, US5 AC4 backend-vs-frontend responsibility), both easily assessed by the implementing agent. No real failures were missed. **Conclusion: Sonnet is confirmed safe for validators. Haiku is NOT recommended — validators need to reason about code structure, not just run binary checks.**

6. **Parallel validator dispatch saved time**: Dispatching US5/US6/US7 validators simultaneously (3 parallel) while auditing code during wait time was an efficient pattern. Total validator wall-clock time: ~8 minutes for 7 gates (vs ~56 minutes serial).

7. **Native task system was the compaction safety net**: All 4 compaction recoveries took ~2 minutes each: read session-summary.md → read decisions.md → TaskList → resume. The task IDs and completion status survived perfectly. The PreCompact hook's generic "check native Tasks" message was sufficient but could capture the current task ID for faster recovery.

8. **decisions.md grows significantly during /implement**: Starting at ~1,664 tokens and ending at ~9,000 tokens (validation evidence + learnings). Each re-read after compaction sends the growing file. This is a unique /implement tax — no other stage grows an artifact this much during execution.

---

### 8.7 /implement (observed — 008 session)

**Run on (008)**: Opus 4.6 (single session, all 7 stories)
**Observed cost**: ~$48.07 (Opus, single session with 4 compactions)
**Future recommended cost**: ~$28-35 (Opus main agent, Sonnet file-writing subagents, one story per session)

| Optimisation | Change | Savings | Available Now? |
|-------------|--------|--------:|:--------------:|
| **One story per session** | Prevents compaction cascade, eliminates recovery overhead | ~$4.23 | Yes |
| Use Sonnet for file-writing subagents | 8 subagents writing from plan/data-model are structured extraction | ~$2.00 | ✅ Validated by 008 |
| Use Sonnet for validator subagents | **Confirmed safe** — all 7 gates accurate, 2 false positives (no missed failures) | Already applied ($2.50 vs ~$4.50 on Opus) | ✅ Validated |
| `/compact` after foundational phase | Shed backend code context before frontend story phases | ~$1.00 | Yes |
| Read only the current story's files | Don't load all 7 pages into context simultaneously | ~$0.50 | Yes |
| **Total** | | **~$7.73** | |

**Model assessment (post-008 validation)**: Opus is justified for the **main implementing agent** — it produced correct code on first pass for SSE streaming patterns, Pydantic v2 camelCase configuration, React Router Outlet patterns, and static Tailwind colour maps. The first-pass quality saved downstream debugging turns that would have cost more than the Opus premium.

However, **file-writing subagents do not need Opus**. The 8 implementation subagents received detailed instructions from the main agent (file path, component structure, data schema) and produced structured code from plan.md + data-model.md. This is template-guided generation — Sonnet's strength.

**Validator subagent model selection (CONFIRMED)**: Sonnet validators produced high-quality structured reports. Two false positives emerged (US3 AC4: incorrect route path assumption; US5 AC4: confused backend/frontend responsibility). Both were trivially assessed by the implementing agent. No real failures were missed. **Haiku is NOT recommended for validators** — the nuanced AC checks (provenance annotation correctness, colour-coding model compliance, navigation flow verification) require code comprehension beyond Haiku's capability.

#### 008 Validation Checkpoint (Completed)

**Did file-writing subagents need Opus?**
- ❌ No. All 8 subagents produced correct output from structured instructions. The seed data agents (messages.json at 70K tokens, attributes.json at 42K tokens) were the most expensive and the most mechanical — they translated data-model.md entities into JSON. Sonnet would produce equivalent output.

**Did validator subagents miss any real failures?**
- ❌ No. All 7 gates produced accurate reports. The only issue was the US5 AC5 navigation bug (navigating to Pipeline without diagnostic context), which the validator correctly identified.

**Did the main agent need Opus for code generation?**
- ✅ Partially. The main agent's direct code edits (error states, navigation fixes, ProgressStepper line connector fix) were straightforward. But the main agent also orchestrated the dependency graph, assessed validator false positives, and managed compaction recovery — tasks where Opus's reasoning depth was valuable. **Recommendation: Keep Opus for the main implementing agent.**

**Were 4 compactions avoidable?**
- ✅ Yes. Running one story per session (7 sessions of ~15 turns each) would have produced 0 compactions. Each compaction cost ~$0.35 direct + ~$0.40 indirect (recovery re-reads, lost nuanced context). Total avoidable cost: ~$3.00.

---

## 9. Projected Savings: Full Pipeline

### Feature 008: Opus 4.6 Baseline (Observed)

All stages ran on Opus 4.6 to establish quality baseline. "Optimised" column applies non-model optimisations only.

| Stage | Model | Sessions | 008 Observed | Optimised (non-model) | Savings |
|-------|-------|----------|----------:|----------:|--------:|
| /specify | Opus 4.6 | shared | $6.47 | $5.50 | -$0.97 |
| /clarify | Opus 4.6 | shared | $4.41 | $3.50 | -$0.91 |
| /plan | Opus 4.6 | shared | $10.60 | $7.80 | -$2.80 |
| /tasks | Opus 4.6 | ✅ fresh | ~$9.00 | ~$9.00 | $0 (already fresh) |
| /checklist | Opus 4.6 | ✅ fresh | ~$3.19 | ~$3.19 | $0 (already fresh) |
| /analyze | Opus 4.6 | ✅ fresh | ~$6.10 | ~$4.50 | -$1.60 (remediation excluded) |
| /implement | Opus 4.6 | 1 (4 compactions) | ~$48.07 | ~$42.34 | -$5.73 (session boundaries + compact) |
| **Pipeline total** | | **1 → 7** | **~$87.84** | **~$75.83** | **-$12.01 (14%)** |

Non-model savings available immediately:
- Session boundaries: -$3.60 (planning stages) + -$4.23 (/implement: one story per session)
- Haiku research subagents: -$1.40 (4 agents in /plan)
- Haiku checklist evaluation subagent: -$0.25 (/analyze)
- `/compact` after foundational phase: -$1.00 (/implement)
- Scoped file reads in /implement: -$0.50
- Avoid duplicate file reads: -$0.38 (planning stages)
- Mid-stage compact in /plan: -$0.50
- Skip redundant reads (session-workflow.md etc.): -$0.40
- Separate remediation from analysis session: -$1.50 (/analyze)

### Feature 009+: With Model Selection (Validated by 008)

| Stage | Model | Sessions | Est. Cost | vs 008 Observed | vs 008 Optimised |
|-------|-------|----------|----------:|--------:|--------:|
| /specify | Sonnet 4.5 | 1 | $3.50 | -$2.97 | -$2.00 |
| /clarify | Sonnet 4.5 | 1 | $2.20 | -$2.21 | -$1.30 |
| /plan | Opus 4.6 | 1 | $6.50 | -$4.10 | -$1.30 |
| /tasks | Sonnet 4.5 | 1 | $4.50 | -$4.50 | -$4.50 |
| /checklist | Sonnet 4.5 | 1 | $2.00 | -$1.19 | -$1.19 |
| /analyze | Sonnet 4.5 | 1 | $3.50 | -$2.60 | -$1.00 |
| **Planning total** | | **6** | **$22.20** | **-$17.57** | **-$11.29** |
| /implement (7 stories) | Opus main + Sonnet subagents | 7 | ~$32.00 | -$16.07 | -$10.34 |
| **Feature total** | | **13** | **~$54.20** | **-$33.64 (38%)** | **-$21.63 (29%)** |

> **Key change from pre-implementation estimate**: /implement actual cost ($48.07) was well below the pre-estimate range ($56-105). The subagent-heavy architecture kept costs lower than expected because subagent context isolation prevented the exponential replay tax. The 009+ estimate of ~$32 reflects: Sonnet file-writing subagents (-$2.00), session boundaries (-$4.23), mid-implement compact (-$1.00), scoped file reads (-$0.50), and a ~$8 natural reduction from splitting into 7 shorter sessions (less thinking per session due to smaller context windows).

### Savings Breakdown (008 Observed → 009+ Full Optimisation)

```
/implement optimisations                           ████████████████████  $16.07 (48%) ← Biggest lever
  ├─ Session boundaries (one story/session)                              $4.23
  ├─ Sonnet file-writing subagents                                       $2.00
  ├─ Compact + scoped reads                                              $1.50
  └─ Shorter sessions (less thinking/context)                            $8.34
Model selection (Sonnet for 5 planning stages)     ████████████          $10.69 (32%) ← Validated by 008
Session boundaries (planning stages)               ████                  $3.60  (11%) ← Available now
Haiku subagents (research + checklist eval)        ██                    $1.65   (5%) ← Available now
Separate remediation from analysis                 █                     $1.50   (4%) ← Available now
Reduced duplicate reads + mid-stage compact        █                     $1.28   (4%) ← Available now
Total                                                                   $33.64
```

> **008 taught us**: /implement is 55% of pipeline cost. Optimising the planning stages alone (the pre-implementation focus) would save only $17.57 — less than half the potential. The biggest single lever is splitting /implement into per-story sessions ($12.57 combined from session boundaries + shorter session thinking savings).

### Decision Gate: Model Selection Validation (008 Answers)

Feature 008 is complete. All 6 validation questions can now be answered:

| # | Question | 008 Answer | Decision |
|---|----------|-----------|----------|
| 1 | Did /specify output require significant rework at /clarify? | **No.** /clarify asked 5 questions; all were refinements (UCI pool+select, progress stepper UX), not rework of spec errors. The spec template guided correct structure. | **→ Switch /specify to Sonnet** |
| 2 | Did /clarify miss a critical ambiguity caught later in /plan or /implement? | **No.** The only /implement issue (US5 AC5 diagnostic→UCI navigation) was a UX gap, not an ambiguity that /clarify should have caught. All 5 clarifications were accurate and used during implementation. | **→ Switch /clarify to Sonnet** |
| 3 | Did /plan Phase 1 artifacts need quality revisions? | **No.** data-model.md, campaign-api.yaml, and quickstart.md were used as-is during implementation. One minor inconsistency (buyer count: spec said ~25 vs ~20 derived) was caught by /analyze pre-implement. | **→ Switch /plan Phase 1 to Sonnet** |
| 4 | Did research subagent output need re-investigation by main agent? | **No.** All 4 research findings (Bedrock models, routing coexistence, data seeding, 005 codebase patterns) were accepted and used directly. The Strands Agent sequential pattern decision was correct. | **→ Switch research subagents to Haiku** |
| 5 | Did /analyze miss a cross-artifact inconsistency caught during /implement? | **No.** /analyze caught 15 findings (1 HIGH, 7 MEDIUM, 7 LOW). The HIGH finding (buyer count inconsistency) was fixed pre-implement. No undiscovered inconsistencies emerged during coding. | **→ Switch /analyze to Sonnet** |
| 6 | Did validator subagent miss a real acceptance criteria failure? | **No.** All 7 validator gates produced accurate reports. 2 false positives (US3 AC4, US5 AC4) but 0 missed real failures. The US5 AC5 navigation bug was correctly identified by the validator. | **→ Keep validators on Sonnet (confirmed). Do NOT use Haiku.** |

**Summary**: All 6 gates pass. Sonnet is safe for all planning stages. Haiku is safe for research subagents. Opus justified only for /plan Phase 0 (trade-off reasoning) and /implement main agent (code orchestration + compaction recovery).

---

## 10. Implementation Priority Matrix

### Phase 1: Apply Now (No Model Changes) — Validated by 008

| # | Action | Where | Savings | Effort |
|---|--------|-------|--------:|--------|
| 1 | **One stage per session** (planning) | Workflow habit — start fresh conversation for each pipeline stage | $3.60/pipeline | None |
| 2 | **One story per session** (/implement) | Run each user story in a separate session to eliminate compaction cascade | $4.23/pipeline | None |
| 3 | **Use Haiku for research subagents** | Add `model: "haiku"` in Task calls during /plan research dispatch | $1.40/pipeline | None |
| 4 | **Use Sonnet for file-writing subagents** (/implement) | Add `model: "sonnet"` in Task calls for implementation file writers | $2.00/pipeline | None |
| 5 | **Mid-stage `/compact`** in /plan (after Phase 0) and /implement (after foundational phase) | Manual step | $1.50/pipeline | None |
| 6 | **Add `paths:` frontmatter** to duckdb-patterns.md, cloud-architecture.md, python-tdd.md, data-modeling.md | `.claude/rules/` | $0.15/session | 10 min |
| 7 | **Skip redundant reads** — don't re-read session-workflow.md (in system prompt), avoid re-reading files already in context | Awareness | $0.40/pipeline | None |
| 8 | **Scoped file reads in /implement** — read only the current story's files, not all 7 pages simultaneously | Awareness | $0.50/pipeline | None |
| | **Phase 1 total savings** | | **~$13.78/pipeline** | |

### Phase 2: Model Selection — All Gates Passed (see Section 9)

| # | Action | Trigger | Savings | Effort |
|---|--------|---------|--------:|--------|
| 9 | **Use Sonnet for /specify, /clarify, /tasks, /checklist, /analyze** | ✅ All 6 Decision Gate questions answered — Sonnet validated safe | $10.69/pipeline | None |
| 10 | **Keep validators on Sonnet** (confirmed, do NOT downgrade to Haiku) | ✅ 008 confirmed: 0 missed failures, 2 false positives (acceptable) | Already applied | N/A |
| 11 | **Per-stage model configuration in .specify** | After manual model selection proves effective across 2 features | Variable | 4 hours |
| | **Phase 2 total savings** | | **~$10.69/pipeline** | |

### Phase 3: Plugin Improvements (Backlog)

| # | Action | Where | Savings | Effort |
|---|--------|-------|--------:|--------|
| 12 | **Create constitution-compact.md** (~30 lines) for quick governance checks | `.specify/memory/` | $0.20/pipeline | 30 min |
| 13 | **Fix /specify template interpolation** — use placeholder in bash examples | `.claude/commands/specify.md` | $0.05/pipeline | 15 min |
| 14 | **Add "concise output" instruction** to research subagent prompts | `/plan` command | $0.12/pipeline | 10 min |
| 15 | **Delegate tmp/ reference doc reading to subagents** in /specify | Modify /specify command flow | $1.27/pipeline | 2 hours |
| 16 | **Create reference-summary.md pattern** — subagent summarises large docs, main agent reads summary | New convention in /specify | $0.92/pipeline | 1 hour |
| 17 | **Add "skip if in context" awareness** for repeated file reads | Modify /clarify and /plan commands | $0.38/pipeline | 1 hour |
| 18 | **Artifact deduplication** — plan.md references data-model.md instead of duplicating | Refactor plan template | Minor | 2 hours |
| 19 | **CLAUDE.md cleanup** — remove legacy tech entries, reduce to <40 lines | CLAUDE.md | $0.05/session | 30 min |
| 20 | **Enhance PreCompact hook** — capture current task ID for faster compaction recovery | `.claude/hooks/` | $0.30/pipeline | 1 hour |

---

## 11. Anthropic Best Practices Reference

### From Official Documentation

1. **Prompt caching** is the single biggest leverage point — 70-90% savings on repeated context. Claude Code enables this automatically. (Source: [Anthropic Prompt Caching Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching))

2. **Cache TTL is 5 minutes** — if there's a gap > 5 minutes between turns, the cache expires and the next turn pays full price. This means long pauses between interactions (e.g., waiting for user input during /clarify Q&A) can cause cache misses. (Source: [Anthropic Pricing](https://platform.claude.com/docs/en/about-claude/pricing))

3. **Context window cost tiers**: Under 200K tokens is standard pricing. Over 200K triggers 2x input / 1.5x output pricing. The 008 session likely crossed 200K before first compaction, meaning some turns were billed at the elevated rate. (Source: [Claude API Pricing](https://platform.claude.com/docs/en/about-claude/pricing))

4. **Average Claude Code cost**: ~$6/developer/day. The 008 planning session cost ~$21 — roughly 3.5x the daily average — confirming that running 3 stages in one session is an outlier. (Source: [Claude Code Costs](https://code.claude.com/docs/en/costs))

5. **Batch API for non-urgent work**: 50% off both input and output tokens. Not applicable to interactive Claude Code sessions, but relevant if `.specify` ever moves to headless/CI execution. (Source: [Anthropic Pricing](https://platform.claude.com/docs/en/about-claude/pricing))

6. **Extended thinking tokens are output-priced**: They dominate cost at 70% of total. Lowering `MAX_THINKING_TOKENS` or effort level is the highest-leverage cost control after model selection. (Source: [Extended Thinking Docs](https://platform.claude.com/docs/en/build-with-claude/extended-thinking))

### Key Pricing Numbers for This Project

| Metric | Opus 4.6 | Sonnet 4.5 | Haiku 4.5 |
|--------|----------|------------|-----------|
| Input (fresh) | $5/MTok | $3/MTok | $1/MTok |
| Input (cached) | $0.50/MTok | $0.30/MTok | $0.10/MTok |
| Output | $25/MTok | $15/MTok | $5/MTok |
| Input >200K | $10/MTok | $6/MTok | $2/MTok |
| Output >200K | $37.50/MTok | $22.50/MTok | $7.50/MTok |

The jump to >200K input pricing is a hidden tax on long sessions. Another reason to use session boundaries.

---

## Appendix A: File Size Reference

### System Prompt (loaded every turn)

| File | Lines | Chars | Est. Tokens |
|------|------:|------:|------------:|
| CLAUDE.md | 86 | 5,784 | 1,446 |
| cloud-architecture.md | 135 | 5,428 | 1,357 |
| data-modeling.md | 95 | 3,885 | 971 |
| debugging.md | 44 | 955 | 239 |
| duckdb-patterns.md | 122 | 3,849 | 962 |
| implementation-enforcement.md | 100 | 5,461 | 1,365 |
| python-tdd.md | 49 | 909 | 227 |
| session-workflow.md | 101 | 5,435 | 1,359 |
| thinking.md | 70 | 1,884 | 471 |
| verification.md | 78 | 2,896 | 724 |
| MEMORY.md | 35 | 2,562 | 641 |
| **Total** | **915** | **39,048** | **~9,762** |

### Feature Artifacts (008)

| File | Lines (pre→post impl) | Chars (pre→post) | Est. Tokens (post) | Notes |
|------|----------------------:|------------------:|-------------------:|-------|
| spec.md | 264 | 25,506 | 6,377 | Unchanged during /implement |
| plan.md | 161 | 10,902 | 2,726 | Unchanged (planning artifact) |
| decisions.md | 105 → ~350 | 6,656 → ~25,000 | ~6,250 | **Grew 3.8x** — validation evidence, learnings, gates |
| session-summary.md | 164 → 165 | 7,014 → ~7,200 | ~1,800 | Minor update (pipeline table) |
| quickstart.md | 170 | 5,470 | 1,368 | Unchanged |
| design/research.md | 165 | 8,388 | 2,097 | Unchanged |
| design/data-model.md | 303 | 12,170 | 3,043 | Unchanged |
| design/contracts/campaign-api.yaml | 687 | 18,505 | 5,287 | Unchanged |
| checklists/requirements.md | 38 | 1,662 | 416 | Unchanged |
| checklists/full-audit.md | 102 | 8,160 | 2,040 | Unchanged |
| tasks.md | 381 | ~20,000 | ~5,000 | Unchanged (planning artifact) |
| **Total** | **~2,890** | **~148,963** | **~36,404** | |

### Implementation Files Created (008)

| Category | Files | Total Lines | Est. Tokens |
|----------|------:|------------:|------------:|
| Backend models/services/routes | 3 | ~1,800 | ~7,200 |
| LLM prompt templates | 5 | ~500 | ~2,000 |
| Seed data (JSON) | 7 | ~3,500 | ~14,000 |
| Frontend pages (008/) | 7 | ~1,400 | ~5,600 |
| Frontend components (campaign/) | 11 | ~800 | ~3,200 |
| Frontend hooks/types/api | 3 | ~700 | ~2,800 |
| Layout + routing changes | 2 | ~200 | ~800 |
| **Total implementation** | **38** | **~8,900** | **~35,600** |

### Reference Documents (tmp/)

| File | Lines | Chars | Est. Tokens |
|------|------:|------:|------------:|
| ll1-v3-complete.md | 2,590 | 174,256 | 43,564 |
| ll1-demo-narrative-v2.md | 410 | 15,058 | 3,765 |
| UI Mockups (7 JSX files) | 1,718 | 74,323 | 21,235 |
| **Total** | **4,718** | **263,637** | **~68,564** |

### Governance Documents

| File | Lines | Chars | Est. Tokens |
|------|------:|------:|------------:|
| product-principles.md | 299 | 25,043 | 6,260 |
| constitution.md | 212 | 13,942 | 3,486 |
| **Total** | **511** | **38,985** | **~9,746** |

### Skill Commands

| File | Lines | Chars | Est. Tokens |
|------|------:|------:|------------:|
| specify.md | 340 | 17,443 | 4,361 |
| clarify.md | 204 | 13,157 | 3,289 |
| plan.md | 118 | 5,755 | 1,439 |
| tasks.md | 264 | 14,436 | 3,609 |
| implement.md | 255 | 13,891 | 3,473 |
| architecture.md | 15 | 726 | 182 |
| analyze.md | 249 | 10,819 | 2,705 |
| checklist.md | 331 | 19,759 | 4,940 |
| constitution.md | 105 | 5,596 | 1,399 |
| **Total** | **1,881** | **101,582** | **~25,397** |

---

## Appendix B: Recommended .claude/rules/ Scoping

```yaml
# duckdb-patterns.md — only load for data/query work
---
paths:
  - "docker/**/*.py"
  - "**/*.sql"
  - "**/dbt/**"
---

# cloud-architecture.md — only load for infrastructure
---
paths:
  - "cdk/**"
  - "infrastructure/**"
  - "docker-compose*.yml"
  - "Dockerfile*"
---

# python-tdd.md — only load for test files
---
paths:
  - "tests/**"
  - "**/*_test.py"
  - "**/test_*.py"
---

# data-modeling.md — only load for data/model work
---
paths:
  - "docker/app/*_models.py"
  - "docker/app/*_service.py"
  - "**/*.sql"
  - "**/design/data-model*"
---
```

**Files to keep always-loaded** (no paths: scoping):
- `implementation-enforcement.md` — process gate, must be universal
- `session-workflow.md` — session management, must be universal
- `verification.md` — quality gates, must be universal
- `thinking.md` — general reasoning framework
- `debugging.md` — general debugging (small file, 239 tokens)

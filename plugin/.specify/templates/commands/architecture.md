# Architecture Command

Generate a high-level architecture overview with technology decision matrices BEFORE detailed planning begins. This serves as a checkpoint for reviewing major infrastructure and technology choices.

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

---

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC, `.specify/memory/product-principles.md` (product thesis), and `.specify/memory/constitution.md` (engineering constitution).

3. **Generate architecture.md** in SPECS_DIR with:
   - Architecture Summary (2-3 paragraphs)
   - Key Technology Decisions (decision matrix for each major choice)
   - Constitution Alignment Check (quick validation against principles)
   - Open Questions (for user to clarify)
   - Decision Type Classification (Type 1 vs Type 2 decisions)
   - Recommended Next Steps

4. **Stop and report**: Command ends after architecture.md generation. Report path and checkpoint status.

---

## Generation Instructions

### Phase 1: Architecture Summary (5 minutes)

Write 2-3 paragraphs describing the proposed high-level architecture approach:

```markdown
## Architecture Summary

[Paragraph 1: Problem statement and architectural approach]
This feature requires [key capability]. We propose a [architecture pattern] that [key benefits]. The architecture prioritizes [primary goal: local dev / cost / scale / etc.].

[Paragraph 2: Core components and data flow]
The system consists of [N] main components: [list]. Data flows from [source] through [transformation] to [destination]. [Key technology X] handles [responsibility Y].

[Paragraph 3: Deployment and operational model]
In local development, [local workflow]. On AWS, [deployment pattern]. The architecture supports [scale/demo requirements] and provides clear upgrade path to [future state].
```

### Phase 2: Key Technology Decisions (25 minutes)

For each major technology choice (orchestration, database, framework, etc.), create a **decision record with weighted matrix**.

#### Context-Dependent Weighting (IMPORTANT)

Decision matrix weights should be **context-dependent**, not fixed across all decisions. The constitution principles (local testability, single-language Python) establish general preferences, but when evaluating **specialist tooling**, the **specialist capability** should be weighted appropriately.

**Weighting Guidelines by Decision Type:**

| Decision Type | Primary Criterion (30-35%) | Secondary Criteria | Reduced Weight |
|---------------|----------------------------|-------------------|----------------|
| **UI Framework** | UI capability/polish | Developer experience, Iteration speed | Local testability (15-20%), Single-language (15%) |
| **State Management** | Simplicity for scope | Developer experience | Standard weights |
| **Backend API** | Integration simplicity | Developer experience, Local testability | Standard weights |
| **Data Storage** | Spec alignment + Simplicity | Developer experience | Query capability (lower for MVP) |
| **Orchestration** | Local testability | Python alignment | Standard weights |
| **Database** | Local testability | Python alignment, Iteration speed | Standard weights |

**Rationale:** When evaluating a UI framework, the primary purpose is building a polished UI—so UI capability should be weighted highest (30-35%), not general principles like Python alignment. Conversely, when evaluating orchestration or database choices, local testability and Python alignment are directly relevant and should retain higher weights.

**Key Principle:** The weighted score should produce sensible results without needing manual overrides. If you find yourself overriding the matrix result, reconsider whether the weights match the decision context.

---

```markdown
### Decision: [Technology Category - e.g., "Workflow Orchestration"]

**Context:** [1-2 sentences explaining why this decision matters for the feature]

**Options Considered:**

#### Option A: [Technology Name]
- **Description**: [1 sentence]
- **Example**: [Concrete example of how it would be used]
- **Local development**: [How developers test locally]
- **Language fit**: [Python-native? Introduces new language?]

#### Option B: [Technology Name]
- **Description**: [1 sentence]
- **Example**: [Concrete example of how it would be used]
- **Local development**: [How developers test locally]
- **Language fit**: [Python-native? Introduces new language?]

#### Option C: [Technology Name]
- **Description**: [1 sentence]
- **Example**: [Concrete example of how it would be used]
- **Local development**: [How developers test locally]
- **Language fit**: [Python-native? Introduces new language?]

**Decision Matrix:**

| Criterion | Weight | Option A | Option B | Option C | Notes |
|-----------|--------|----------|----------|----------|-------|
| Local testability | 30% | 8/10 | 5/10 | 9/10 | [Why these scores] |
| Single-language (Python) | 25% | 7/10 | 4/10 | 8/10 | [Why these scores] |
| Developer experience | 20% | 6/10 | 7/10 | 9/10 | [Why these scores] |
| Iteration speed | 15% | 6/10 | 8/10 | 7/10 | [Why these scores] |
| Monthly cost (demo) | 5% | 5/10 | 10/10 | 6/10 | [Why these scores] |
| Operational simplicity | 5% | 8/10 | 9/10 | 7/10 | [Why these scores] |
| **Weighted Total** | 100% | **7.0** | **6.1** | **8.3** | |

**Recommendation:** Option C - [Technology Name]

**Rationale:**
Option C scores highest (8.3/10) because it excels at local testability (9/10) and maintains Python codebase alignment (8/10), which are highest-weighted criteria per Constitution Principle VI. While Option B is cheaper (10/10 on cost), the 40% cost savings doesn't justify the poor local development experience (5/10) and context-switching to JSON/YAML (4/10 on language fit).

**Trade-offs:**

✅ **Pros:**
- Full local testing without AWS credentials
- Python-native APIs (standard debugging, IDE support)
- Fast iteration: edit-test-debug cycle under 2 minutes
- No context-switching to JSON/YAML/Node.js

⚠️ **Cons:**
- Higher monthly AWS cost (~$X vs ~$Y for Option B)
- Requires self-managed control plane (vs fully managed Option B)
- Learning curve if team unfamiliar with technology

📊 **Cost Impact:**
- Local dev: $0 (runs on laptop)
- AWS deployment: ~$X/month (vs $Y for Option B = $Z difference)
- Annual difference: ~$ABC (acceptable per constitution for dev velocity gains)

🔄 **Migration Path:**
- Clear upgrade path to [managed service / enterprise version] when [condition: scale / team size / etc.]
- Reversible decision if [specific conditions change]

**Decision Type:** Type 2 (Reversible)
- Can migrate to Option B if cost becomes prohibitive (cutover estimated at 2-3 days)
- Not locked into vendor or proprietary APIs
- Infrastructure as code enables switching orchestration layer
```

### Phase 2.5: Data Modeling Decisions (15 minutes)

**When to execute this phase:**
- Feature involves data storage (databases, data lakes, event streams)
- New entities or schemas need to be defined
- Existing data sources need to be integrated

**When to skip:**
- Feature is purely computational (no data persistence)
- No changes to data models (UI-only changes, configuration updates)

#### Step 1: Data Source Discovery

Prompt user for data source locations:

```markdown
📊 DATA SOURCE DISCOVERY

This feature involves data modeling. To ensure accurate schema generation, please specify where to find your data sources.

🔍 **Option 1: Specify Paths** (Recommended)
Provide paths to existing data sources:
- CSV files: data/raw/*.csv, s3://bucket/prefix/
- SQL schemas: data/schema/*.sql, migrations/*.sql
- ORM models: src/models/*.py, entities/*.py
- Database connection: postgres://host:port/db (if accessible)

Example: data/raw/*.csv data/schema/create_revops_database.py

🎯 **Option 2: Generate from Spec**
Type "generate" to create data models from feature specification only.
⚠️  Warning: No validation against actual data sources.

📝 **Option 3: Skip Data Modeling**
Type "skip" if this feature doesn't involve data model changes.

Enter data source paths (or "generate"/"skip"):
```

#### Step 2: Application Type Detection

Use data-modeling skill to detect application type from spec:

```python
# Analytical keywords: analytics, metrics, reporting, dashboard, medallion, lakehouse
# Transactional keywords: CRUD, API, microservice, REST, OLTP, normalized
# Streaming keywords: real-time, event, stream, Kafka, Kinesis, CDC, event-driven

application_type = detect_application_type(feature_spec)
# Returns: ("analytical" | "transactional" | "streaming" | "hybrid")
```

Report detected type:

```markdown
**Detected Application Type**: Analytical (15 keywords matched)
**Data Modeling Pattern**: Medallion Architecture (bronze/silver/gold)
**Best Practices Domain**: Analytical databases (DuckDB, Redshift, BigQuery)
```

#### Step 3: Schema Discovery & Extraction

If user provided data source paths, extract actual schemas:

```markdown
**Data Sources Discovered**: 3 sources

| Source Type | Path | Tables/Files | Confidence |
|-------------|------|--------------|------------|
| CSV | data/raw/customers_master.csv | 1 file, 60 cols | High |
| SQL Schema | data/schema/create_revops_database.py | 14 tables | High |
| ORM Models | models/customer.py | 3 models | Medium |

**Naming Conventions Detected**:
- CSV files: camelCase (customerId, companyName)
- Database: snake_case (customer_id, company_name)
- **Transformation required**: CSV → Database ingestion must convert camelCase to snake_case

**Key Findings**:
- Primary entity: Customer (appears in 8 of 14 tables)
- Dimension tables: customers_master, firmographic_data, icp_scores
- Fact tables: opportunities, financial_data, product_usage
- Reference tables: naics_lookup
- Temporal tables: opportunity_stage_history, rep_activities
```

#### Step 4: Domain-Specific Validation

Apply data-modeling skill validation checks based on detected application type:

**For Analytical Applications:**
- [ ] All fact tables have documented grain statements
- [ ] Dimension tables separated from fact tables
- [ ] Partitioning strategy specified
- [ ] No many-to-many without bridge tables
- [ ] Wide tables threshold (<50 columns)
- [ ] Time dimension present

**For Transactional Applications:**
- [ ] All foreign keys defined with CASCADE rules
- [ ] Primary keys on all tables
- [ ] Audit columns present (created_at, updated_at)
- [ ] Soft delete pattern for important entities
- [ ] No duplicate data across tables

**For Streaming Applications:**
- [ ] Events include event_id, event_type, event_timestamp, schema_version
- [ ] Idempotency keys defined for critical events
- [ ] No UPDATE operations (append-only)
- [ ] Schema evolution strategy documented

Report validation results:

```markdown
### Data Modeling Decision: Analytical Data Architecture

**Validation Results**:

#### ✅ PASSED (10/15)
- [x] Bronze layer preserves raw data immutability
- [x] Silver layer staging models defined
- [x] Gold layer separates domains (RevOps, ICP)
- [x] Partitioning strategy specified (quarterly)
- [x] Primary keys defined on all tables
- [x] Dimension tables identified
- [x] Fact table aggregations documented
- [x] Time-based partitioning for query pruning
- [x] Star schema pattern in gold layer
- [x] Data quality gates defined (bronze→silver, silver→gold)

#### ⚠️ WARNINGS (3/15)
- [ ] **customers_master has 60 columns** (threshold: 50 for single table)
  - **Recommendation**: Split into dim_customer_core + dim_customer_firmographic
  - **Impact**: Medium - Improves query performance, reduces join complexity
  - **Effort**: 2-3 hours to refactor

- [ ] **No time dimension table (dim_date)**
  - **Recommendation**: Add dim_date for calendar operations (fiscal vs calendar quarters)
  - **Impact**: Low - Nice to have for advanced analytics
  - **Effort**: 1 hour to generate

- [ ] **Missing documentation on CSV → Database transformations**
  - **Recommendation**: Document camelCase → snake_case mapping in data-model.md
  - **Impact**: Medium - Prevents confusion during implementation
  - **Effort**: 30 minutes

#### ❌ FAILED (2/15)
- [ ] **fct_financial_data grain inconsistent**
  - **Issue**: data-model.md describes transactional data (row per transaction) but actual schema is quarterly summary (row per quarter)
  - **Recommendation**: Update data-model.md to match actual quarterly summary structure
  - **Impact**: CRITICAL - Implementation would fail with schema mismatch
  - **Effort**: 2 hours to correct + regenerate dependent contracts

- [ ] **Foreign keys reference non-existent columns**
  - **Issue**: data-model.md shows customer_id INTEGER FK, but actual schema uses TEXT and account_name for joins
  - **Recommendation**: Update all FK references to match actual schema
  - **Impact**: CRITICAL - SQL queries would fail
  - **Effort**: 1-2 hours to correct across all tables

**Overall Assessment**: ⚠️ **2 Critical Issues Block Implementation** - Must fix before proceeding to planning

**Best Practices Applied**:
1. ✅ Medallion architecture for analytical workloads
2. ✅ Denormalized gold layer (star schema)
3. ✅ Partitioning by time dimension (quarterly)
4. ⚠️ Wide dimension tables (customers_master: 60 columns)
5. ✅ Separate fact tables by domain (RevOps, ICP)

**Decision Type**: Type 1 (Irreversible)
- **Rationale**: Medallion architecture requires 4-6 weeks to change once implemented
- **Migration Path**: If data exceeds 100GB, migrate to Aurora/Redshift (2-3 days of work)
```

#### Step 5: User Decision on Critical Issues

If critical validation failures found, prompt user:

```
❌ CRITICAL DATA MODELING ISSUES FOUND

2 critical issues block implementation:

1. ❌ fct_financial_data grain inconsistent
   Schema mismatch between data-model.md and actual database
   → Fix: Update data-model.md to match quarterly summary structure
   → Effort: 2 hours

2. ❌ Foreign keys reference non-existent columns
   customer_id INTEGER FK doesn't match actual schema (TEXT, account_name joins)
   → Fix: Update FK references across all tables
   → Effort: 1-2 hours

⚠️  3 warnings (non-blocking): See details above

📋 NEXT STEPS:

Option A: Fix issues in architecture.md before proceeding ✅
  - Update data-model-draft.md with corrections
  - Re-run validation checks
  - Proceed to /plan when ✅ GREEN

Option B: Acknowledge and proceed (NOT RECOMMENDED)
  - Implementation will fail when loading actual data
  - Will waste 2-4 days discovering these issues during testing

Option C: Regenerate from actual sources automatically
  - Discard spec-based data-model.md
  - Generate fresh from discovered schemas
  - Proceed to /plan with validated models

Choose option (A/B/C):
```

If only warnings found, prompt:

```
⚠️  DATA MODELING WARNINGS

3 non-blocking warnings found: [list above]

✅ These warnings don't block implementation but represent tech debt.

Address warnings now? (y/n):
- y: Incorporate recommendations into architecture.md
- n: Document as known tech debt, proceed to /plan
```

#### Step 6: Generate data-model-draft.md

Create validated data model document in specs/{feature}/ directory:

```markdown
# Data Model: [Feature Name]

## Application Type
**Primary Domain**: Analytical
**Pattern**: Medallion Architecture (bronze/silver/gold)

## Validation Status
- ✅ Schema validated against actual data sources
- ⚠️ 3 warnings (see architecture.md for details)
- ❌ 2 critical issues (MUST FIX before implementation)

## Data Source Mapping

[Document CSV → Bronze → Silver → Gold transformations]
[Include column name mappings]
[Show actual schemas from discovered sources]

## Schema Validation Summary

| Table | CSV Columns | DB Columns | Coverage | Status |
|-------|-------------|------------|----------|--------|
| customers_master | 60 | 14 | 23% | ⚠️ Subset used |
| opportunities | 22 | 22 | 100% | ✅ Match |
...

## Critical Corrections Required

[List fixes needed with before/after schemas]
```

**Output**: Save as `specs/{feature}/data-model-draft.md`

### Phase 3: Constitution Alignment (5 minutes)

Full check against both the product thesis (`.specify/memory/product-principles.md`) and the engineering constitution (`.specify/memory/constitution.md`). This is a formal section in the artifact.

```markdown
## Constitution Alignment

### Product Thesis Alignment

Evaluate the architecture against ALL product thesis principles. Mark N/A where a principle doesn't apply to this feature.

| Thesis Principle | Status | Notes |
|-----------------|--------|-------|
| §1 Confidence Over Speed | ✅/⚠️/❌/N/A | [1 sentence] |
| §2 AI as Collaborator | ✅/⚠️/❌/N/A | [1 sentence] |
| §3 Trust Above All | ✅/⚠️/❌/N/A | [1 sentence] |
| §4 Opinionated Process | ✅/⚠️/❌/N/A | [1 sentence] |
| §5 Craft is Competitive Advantage | ✅/⚠️/❌/N/A | [1 sentence] |
| §6 Intelligence Layer Boundary | ✅/⚠️/❌/N/A | [1 sentence] |
| §7 Writing Over Meetings | ✅/⚠️/❌/N/A | [1 sentence] |
| §8 Freedom With Focus | ✅/⚠️/❌/N/A | [1 sentence] |
| §9 Learning is Core | ✅/⚠️/❌/N/A | [1 sentence] |
| §10 AI Transparency | ✅/⚠️/❌/N/A | [1 sentence] |
| §11 Terminology Invariant | ✅/⚠️/❌/N/A | [1 sentence] |

### Engineering Constitution Alignment

Evaluate the architecture against ALL engineering constitution principles.

| Eng Principle | Status | Notes |
|--------------|--------|-------|
| I. Requirements Are Contracts | ✅/⚠️/❌ | [1 sentence] |
| II. Explainability is Architectural | ✅/⚠️/❌/N/A | [1 sentence] |
| III. Respect the Product Boundary | ✅/⚠️/❌ | [1 sentence] |
| IV. Terminology is Invariant | ✅/⚠️/❌ | [1 sentence] |
| V. Architecture for Change | ✅/⚠️/❌ | [1 sentence on local testability, coupling, Type 1/2 decisions] |
| VI. Learning is Intentional | ✅/⚠️/❌ | [1 sentence on assumptions tracking] |

### Data Modeling Validation ✅ / ⚠️ / ❌
**Application Type Detected**: [Analytical / Transactional / Streaming / Hybrid]
**Best Practices Applied**: [List key patterns applied]
**Critical Issues**: [N] ([Schema mismatches / Missing constraints / etc.])
**Warnings**: [N] ([Wide tables / Missing indexes / etc.])

**Overall**: ✅ Validated / ⚠️ Warnings present / ❌ Critical issues block implementation

**Overall Assessment:** ✅ All principles satisfied / ⚠️ Minor concerns / ❌ Violations require justification

**Concerns/Justifications:**
[If any ⚠️ or ❌ above, explain why and justify the deviation]
```

### Phase 4: Decision Type Classification (5 minutes)

Apply Amazon's Type 1 vs Type 2 decision framework:

```markdown
## Decision Type Classification

Amazon distinguishes between two types of decisions:
- **Type 1 (One-way door)**: Irreversible or very hard to reverse. Require careful analysis and senior approval.
- **Type 2 (Two-way door)**: Reversible. Can be made quickly, experimented with, and changed if needed.

### Decision Analysis

| Decision | Type | Reversibility | Time to Reverse | Rationale |
|----------|------|---------------|-----------------|-----------|
| [Technology X] | Type 2 | High | 2-3 days | Infrastructure as code enables switching; no vendor lock-in |
| [Technology Y] | Type 2 | Medium | 1 week | API abstractions exist; data migration straightforward |
| [Technology Z] | Type 1 | Low | 4-6 weeks | Tightly coupled to data model; requires re-architecture |

**Type 1 Decisions (Require Careful Review):**
[List any Type 1 decisions and explain why they're hard to reverse]

**Type 2 Decisions (Can Experiment):**
[List Type 2 decisions - these can be tried and changed]

**Recommendation:**
Focus user review on Type 1 decisions. Type 2 decisions can proceed with implementation and course-correct if needed.
```

### Phase 5: Open Questions (3 minutes)

Surface any unresolved questions requiring user input:

```markdown
## Open Questions

Questions that need clarification before proceeding to detailed planning:

- [ ] **Q1:** [Specific question about requirements or constraints]
  - **Why it matters:** [Impact on architecture]
  - **Options:** [A / B / C]

- [ ] **Q2:** [Specific question about scale or performance targets]
  - **Why it matters:** [Impact on technology choice]
  - **Options:** [X / Y / Z]

- [ ] **Q3:** [Specific question about team expertise or preferences]
  - **Why it matters:** [Impact on learning curve / velocity]
  - **Options:** [Known tech / New tech]
```

### Phase 6: Recommended Next Steps (2 minutes)

```markdown
## Recommended Next Steps

### If Architecture Approved ✅
Run `/plan` to generate:
- Detailed technical design (plan.md)
- Research documentation (research.md)
- Data models (data-model.md)
- API contracts (contracts/)
- Quickstart guide (quickstart.md)

The planning phase will **reference decisions from this architecture.md** to avoid redundant research on major technology choices.

### If Changes Needed ⚠️
1. Provide feedback on specific decisions that need revision
2. Update spec.md if requirements changed
3. Re-run `/architecture` with updated context

### If Approach Rejected ❌
Revisit feature specification (spec.md) to clarify:
- User stories and acceptance criteria
- Success metrics and constraints
- Scale and performance requirements
```

---

## Post-Architecture Steps

### Update decisions.md
Record architecture decisions (Type 1 and Type 2) in `FEATURE_DIR/decisions.md` under Gate Decisions with rationale and alternatives rejected.

### Update session-summary.md
Update `FEATURE_DIR/session-summary.md` — mark `/architecture` as `done` in the Pipeline Progress table. List key decisions and their types in notes column.

### Stage Completion Gate

Before reporting, verify this stage's outputs. **All checks must pass — if any fail, fix the gap before proceeding.**

**Artifact checks** (file must exist and be non-empty):
- [ ] `FEATURE_DIR/architecture.md` — generated with decision matrices
- [ ] `FEATURE_DIR/decisions.md` — Gate Decisions has `/architecture` entry
- [ ] `FEATURE_DIR/session-summary.md` — `/architecture` row updated

**Content checks**:
- [ ] architecture.md has at least one technology decision matrix
- [ ] All Type 1 decisions are explicitly flagged
- [ ] Constitution alignment check is completed
- [ ] session-summary.md Pipeline Progress shows `/architecture` as `done`

If any check fails: **STOP**. Fix the gap. Re-verify. Do not skip.

## Stop and Report

After generating architecture.md, output:

```
✅ Architecture overview created: [FULL_PATH_TO_architecture.md]

📋 Key decisions documented:
1. [Decision 1]: [Recommended Technology] (Score: X.X/10)
2. [Decision 2]: [Recommended Technology] (Score: X.X/10)
3. [Decision 3]: [Recommended Technology] (Score: X.X/10)

🚦 Decision types:
- Type 1 (Irreversible): [N] decisions - REQUIRE CAREFUL REVIEW
- Type 2 (Reversible): [M] decisions - Can experiment and iterate

⚖️ Constitution alignment: [✅ All principles satisfied / ⚠️ Minor concerns - see architecture.md / ❌ Violations require justification]

⏸️ **USER CHECKPOINT REQUIRED**

Please review architecture.md and choose:

1. ✅ **Approve architecture** → Run `/plan` to proceed with detailed design
2. ⚠️ **Request changes** → Provide feedback, will regenerate with updates
3. ❌ **Reject approach** → Revisit feature specification (spec.md)

Questions? Open issues in architecture.md "Open Questions" section need answers before planning.
```

---

## Key Rules

- **High-level only**: No detailed API contracts, data schemas, or implementation code
- **Decision matrices mandatory**: Every major technology choice needs weighted scoring
- **Surface trade-offs clearly**: No "perfect solution" narratives - be honest about pros/cons
- **Type 1 vs Type 2**: Explicitly classify decision reversibility
- **Constitution-aligned**: Map every decision to constitution principles
- **Enable informed decisions**: User should understand consequences before approving
- **No implementation**: Save detailed design for /plan phase

---

## Examples of Good Decision Matrices

### Example 1: Workflow Orchestration

| Criterion | Weight | Prefect | Step Functions | Airflow |
|-----------|--------|---------|----------------|---------|
| Local testability | 30% | 9/10 | 3/10 | 6/10 |
| Python alignment | 25% | 10/10 | 2/10 | 7/10 |
| Developer experience | 20% | 8/10 | 4/10 | 6/10 |
| Iteration speed | 15% | 9/10 | 5/10 | 5/10 |
| Monthly cost | 5% | 6/10 | 10/10 | 3/10 |
| Operational simplicity | 5% | 7/10 | 9/10 | 4/10 |
| **Total** | 100% | **8.5** | **3.8** | **6.2** |

**Recommendation:** Prefect (8.5/10) - Excels at highest-priority criteria (local dev, Python-native)

### Example 2: Database Choice

| Criterion | Weight | DuckDB | Aurora PostgreSQL | Redshift |
|-----------|--------|--------|-------------------|----------|
| Local testability | 30% | 10/10 | 4/10 | 2/10 |
| Python alignment | 25% | 9/10 | 7/10 | 6/10 |
| Developer experience | 20% | 8/10 | 8/10 | 7/10 |
| Iteration speed | 15% | 9/10 | 5/10 | 4/10 |
| Monthly cost | 5% | 10/10 | 3/10 | 2/10 |
| Operational simplicity | 5% | 8/10 | 9/10 | 6/10 |
| **Total** | 100% | **9.1** | **5.9** | **4.8** |

**Recommendation:** DuckDB (9.1/10) - Perfect for local dev and demo scale

---

## When NOT to Use This Command

Skip `/architecture` for:
- Simple features with obvious technology choices
- Features using only existing technologies in codebase
- Infrastructure changes with no new technology decisions
- Minor updates or bug fixes

Use it when:
- Introducing new infrastructure or frameworks
- Multiple viable approaches exist with trade-offs
- Technology decision impacts developer experience significantly
- Cost/complexity needs explicit discussion before detailed planning

---

---

## Session Summary Update (MANDATORY)

After architecture.md is generated, update `session-summary.md`:

1. **Update SpecKit Flow Progress table**:
   - Set ARCHITECTURE row: Status = ✅ Complete
   - Record Started timestamp (when command began)
   - Record Completed timestamp (now)
   - Calculate Duration
   - Note artifacts: "architecture.md" or "lightweight in plan.md"

2. **Update Architecture Review Summary section**:
   - Set Review Type: Full
   - List key technology decisions with recommendations
   - Add net-new introductions table
   - Set Recommendation status

3. **Add to Decisions Log**:
   - Add row for each major technology decision
   - Include: Date, Stage=ARCHITECTURE, Decision, Rationale, Impact

4. **Update Validation Checkpoints**:
   - Set "Architecture review" = ✅ PASS (or ⚠️ with notes if concerns)

5. **Add to Session Summary Update Log**:
   - Add row: Timestamp, "/speckit.architecture", "Set ARCHITECTURE = ✅, added N technology decisions"

**Example update**:
```markdown
| ARCHITECTURE | ✅ Complete | 2026-01-26 10:00 | 2026-01-26 10:45 | 45 min | architecture.md |
```

---

**Template Version**: 1.1.0 | **Created**: 2025-11-12 | **Updated**: 2026-01-26

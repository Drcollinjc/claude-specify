<!--
SYNC IMPACT REPORT
==================
Version: 4.0.0 -> 5.0.0 (Two-document model: product thesis + engineering constitution)
Change Type: MAJOR (Complete rewrite — all technology-specific content removed, principles reduced from 7 to 6, two-document governance model adopted)

Removed Principles:
  - Principle I: Demo-First Development (dropped — planning discipline, not constitutional; conflicts with watermark system)
  - Principle II: AWS Infrastructure Foundation (dropped — technology-specific, moved to .claude/rules/)
  - Principle IV: Component Testing Over Test Suites (dropped — superseded by watermark system in /tasks and /implement)
  - Principle VI: Pragmatic Observability (dropped as standalone — folds into Architecture for Change + project-specific rules)
  - Principle VII: Developer Experience & Iteration Velocity (dropped as standalone — folds into Architecture for Change)

New Principles:
  - Principle II: Explainability is Architectural (derived from Thesis §2 + §10)
  - Principle III: Respect the Product Boundary (derived from Thesis §6)
  - Principle IV: Terminology is Invariant (derived from Thesis §11)
  - Principle VI: Learning is Intentional (derived from Thesis §9)

Retained Principles (restructured):
  - Principle I: Requirements Are Contracts (was III — enhanced from Thesis §3)
  - Principle V: Architecture for Change (was V — expanded to absorb dev experience, observability, interface-first)

Removed Sections:
  - AWS Infrastructure Standards (65+ lines — already in .claude/rules/cloud-architecture.md and .claude/rules/duckdb-patterns.md)
  - Development Workflow (already encoded in pipeline commands)
  - Quality Gates (superseded by watermark system and Stage Completion Gates in commands)
  - Documentation requirements (already in each command's completion gate)

Added Sections:
  - Preamble referencing product-principles.md
  - "This costs us" statement on every principle
  - /analyze check on every principle
  - Derivation traceability (which thesis principles feed each eng principle)

Templates Requiring Updates:
  ✅ .specify/templates/plan-template.md — Constitution Check section updated for two-document model
  ✅ .specify/templates/commands/architecture.md — Constitution Alignment updated
  ✅ .claude/commands/constitution.md — Rewritten for two-document model
  ✅ .claude/commands/specify.md — Thesis awareness added
  ✅ .claude/commands/clarify.md — Thesis awareness added
  ✅ .claude/commands/plan.md — Thesis awareness added
  ✅ .claude/commands/analyze.md — Thesis awareness added
  ✅ .claude/commands/checklist.md — Thesis awareness added

Rationale for MAJOR version bump:
Complete structural rewrite. All 7 original principles replaced with 6 technology-agnostic principles derived from product thesis. Two-document governance model adopted. All project-specific content removed. This is backward-incompatible with v4.0.0 — commands referencing old principle names/numbers must be updated.

Previous Version: 4.0.0 (2025-11-14)
Date: 2026-02-10
-->

# Engineering Constitution

**Version**: 5.0.0 | **Ratified**: 2025-01-10 | **Last Amended**: 2026-02-10

## Preamble

This constitution defines the engineering principles that govern how we build software. These principles are **derived from** the product thesis at `.specify/memory/product-principles.md` via the translation mechanism at `.specify/rules/constitution-translation.md`.

The product thesis defines **who** we build for, **why**, and what **values** we hold. This constitution translates those values into **engineering constraints** — the things we must not violate when we specify, plan, design, and implement.

These principles are:
- **Technology-agnostic**: They apply regardless of language, cloud provider, or framework
- **Testable**: Each has concrete checks that `/analyze` can evaluate against specs and plans
- **Costly**: Each imposes a real trade-off. If a principle costs nothing, it isn't a real principle

Project-specific technology choices, patterns, and standards belong in `.claude/rules/` and `CLAUDE.md`, not here.

## Principles

### I. Requirements Are Contracts

*Derived from: Product Thesis §3 — Trust Above All Other Quality Attributes*

**What it prevents**: Optimistic validation, "close enough" acceptance, trust-eroding inconsistency across modules.

**MUST statements**:
- Validation is binary. Specs are source of truth. If the spec says X, the implementation delivers exactly X.
- No optimistic assumptions. "Likely intentional", "close enough", and "probably fine" are never acceptable without explicit user confirmation.
- Consistency across modules is a trust dimension. If two parts of the system describe the same entity differently, that is a trust failure.
- Stories are "done" only when all acceptance criteria are met, all tests pass, and no known issues remain.

**This costs us**: Every deviation from spec — even ones that seem obviously fine — requires a stop-and-ask. This slows implementation velocity, especially in early stages where specs are still finding their shape. We accept this because the alternative — optimistic validation that defers surprises — erodes trust and compounds rework.

**/analyze check**: No "close enough" language in artifacts. Status reporting uses binary pass/fail. Acceptance criteria are specific and measurable. No unresolved deviations from spec.

---

### II. Explainability is Architectural

*Derived from: Product Thesis §2 — AI as Collaborator, Never as Oracle + §10 — AI Transparency is Non-Negotiable*

**What it prevents**: Black-box AI features. Recommendations without reasoning. Explanation treated as polish rather than structure.

**MUST statements**:
- Every AI feature must include an explanation mechanism. The user must always be able to ask "why" and receive a substantive answer.
- Explanation is structural, not cosmetic. It must be designed into the architecture from the start, not retrofitted.
- When the AI takes an inferential leap, the leap must be explicit. The reasoning must be legible and challengeable.
- The fidelity of the explanation may vary (raw data at early stages, polished UI later), but its existence is non-negotiable at any stage.

**This costs us**: Every AI feature takes longer to build because the explanation layer is mandatory, not optional. Some features will feel heavier than they "need" to be. We accept this because retrofitting explainability into a system built without it is orders of magnitude harder than including it from the start.

**/analyze check**: AI features in spec include explanation requirements. No AI output without a reasoning mechanism. Specs describe how users understand the basis for AI recommendations.

---

### III. Respect the Product Boundary

*Derived from: Product Thesis §6 — Intelligence Layer Boundary*

**What it prevents**: Scope creep into the execution layer. Building features that belong in CRMs, marketing automation, or outreach platforms.

**MUST statements**:
- We build intelligence, not execution. Specs describing execution-layer functionality (sending emails, managing pipelines, running campaigns) violate this principle.
- Integration contracts define how intelligence becomes operational. The shape and reliability of these contracts matter; the execution itself is not our responsibility.
- Human-in-the-loop must be considered for any action where the product pushes configuration into external systems.

**This costs us**: We leave revenue on the table by refusing to build execution features users would pay for. We depend on integration quality with third-party tools we don't control. We accept this because crossing the boundary dilutes focus and puts us in competition with established execution platforms instead of complementing them.

**/analyze check**: Spec does not describe execution-layer functionality. Integration points use contracts, not direct execution. Features that push to external systems include human-in-the-loop consideration.

---

### IV. Terminology is Invariant

*Derived from: Product Thesis §11 — Terminology is Invariant*

**What it prevents**: Terminology drift across artifacts, code, UI, and documentation. Accidental renaming that compounds confusion.

**MUST statements**:
- Domain terms are fixed early and used consistently across code, API, UI, documentation, and specs.
- Renaming is allowed but is a deliberate, documented decision that propagates everywhere simultaneously. It is never accidental drift.
- A shared glossary of domain terms is established and maintained. AI agents must be explicitly constrained to use canonical terms, not synonyms.

**This costs us**: Early naming decisions carry more weight than feels comfortable. We may sometimes feel locked into a term that isn't perfect. Maintaining terminology consistency requires discipline, especially across AI-generated code. We accept this because terminology drift across a multi-module product creates compounding confusion that is far more expensive to fix later.

**/analyze check**: No terminology drift between spec, plan, and tasks. Consistent entity naming across all artifacts. No unexplained synonyms for the same concept.

---

### V. Architecture for Change

*Derived from: Product Thesis §8 — Freedom With Focus, Not Freedom Without Direction*

**What it prevents**: Deep coupling. Technology lock-in. Irreversible decisions made without justification. Poor developer experience slowing iteration.

**MUST statements**:
- Validate interfaces and contracts before building implementations. Loose coupling and clear boundaries between components.
- Type 1 (irreversible) and Type 2 (reversible) decisions must be classified and justified. Type 1 decisions require careful analysis; Type 2 decisions can be experimented with.
- Technology selection must be weighted by: local testability > language alignment > developer experience > iteration speed > cost > operational simplicity.
- All features must be testable on a developer's laptop without cloud credentials.
- Migration paths must be documented for Type 1 decisions.

**This costs us**: Interface-first design takes longer upfront than diving into implementation. Classifying decisions adds process. The technology selection weighting may rule out tools that are cheaper or more feature-rich but score poorly on developer experience. We accept this because the cost of reversing a deeply coupled architecture or unwinding a technology lock-in dwarfs the upfront investment in changeability.

**/analyze check**: Tech selection criteria documented. Interfaces defined before implementations. Coupling assessed. Migration paths noted for Type 1 decisions. Features include local development workflow.

---

### VI. Learning is Intentional

*Derived from: Product Thesis §9 — Learning is a Core Operating Principle*

**What it prevents**: Assumptions going untracked. Uncertainty zones unidentified. Completed work with no captured learnings. The engineering flow stagnating rather than evolving.

**MUST statements**:
- Assumptions must be tracked explicitly in specs and plans. When an assumption proves correct, that's signal. When it proves wrong, that's more valuable signal.
- Areas of uncertainty must be identified before implementation begins, not discovered during it.
- Learnings must be captured at story boundaries — what worked, what didn't, what we'd do differently.
- The engineering flow itself is treated as a product. It evolves based on evidence, not tradition or convenience.

**This costs us**: Tracking assumptions and capturing learnings takes time that could be spent building. Revisiting past decisions can feel like rework. We accept this because learning compounds — each documented assumption and captured insight makes the next feature faster and the next decision better-informed.

**/analyze check**: Spec documents assumptions. Plan identifies uncertainty zones. Tasks allow for learning capture at story boundaries.

## Governance

### Amendment Process

This constitution may be amended when:
1. The product thesis changes and the translation mechanism (`.specify/rules/constitution-translation.md`) identifies uncaught violations requiring a new or modified principle
2. Engineering practice evolves and an existing principle no longer serves its purpose
3. A principle is found to be untestable, too vague, or duplicative

Amendments require:
1. Running the three-gate assessment from the translation mechanism
2. Documented rationale for the change (what problem does it solve?)
3. Version increment following semantic versioning
4. Sync impact report prepended to this file
5. Update to all dependent templates and command files via the `/constitution` command

### Versioning Policy

- **MAJOR** (X.0.0): Principles added, removed, or fundamentally redefined
- **MINOR** (x.Y.0): Existing principles materially expanded or MUST statements added
- **PATCH** (x.y.Z): Clarifications, wording improvements, cost statement refinements

### Overfitting Guard

More than one new engineering principle per quarter suggests over-constraint. Engineering principles should be stable. If principles are changing frequently, investigate whether:
- The product thesis is changing too fast
- The translation is overfitting (turning preferences into mandates)
- Existing principles could be extended rather than new ones created

### Compliance

- The `/plan` command MUST include a Constitution Check section evaluating compliance with all principles
- The `/analyze` command treats constitution violations as CRITICAL findings
- The `/architecture` command evaluates technology decisions against these principles
- Deviations from principles MUST be explicitly justified
- This constitution is subordinate to the product thesis — if a conflict is found, the thesis governs and the constitution is amended

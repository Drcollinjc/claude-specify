# Constitution Translation Mechanism v1.0.0

## Purpose

This rule encodes how product thesis principles are translated into engineering constitution principles. It is the bridge between `.specify/memory/product-principles.md` (the org's product thesis) and `.specify/memory/constitution.md` (the engineering constitution).

The `/constitution` command references this mechanism when creating, updating, or syncing the engineering constitution.

## Core Rule

A thesis principle expresses a **value** with an **explicit cost**. An engineering principle codifies the **constraints** that value imposes on engineering decisions. The translation works by asking:

> **"What engineering decisions would violate this value?"**

The inverse of those violations becomes the engineering principle.

## Translation Process

For each thesis principle:

### Step 1: Identify Engineering Domains

Which engineering domains does this thesis principle touch?

- Architecture
- API design
- Data model
- Testing
- Tooling
- Developer workflow
- Observability
- Security

If the thesis principle touches **zero** engineering domains (purely product positioning, org culture, or competitive strategy), it does **not** produce an engineering principle. Document this routing decision.

### Step 2: Articulate Violations

What would a spec, plan, or implementation look like that **breaks** this value? Be concrete. Write specific examples of violations, not abstract descriptions.

Example: For "AI as Collaborator" — a violation would be an AI feature that produces a recommendation with no explanation mechanism, no way for the user to ask "why."

### Step 3: Invert into MUST/SHOULD Statements

The engineering principle prevents the violations identified in Step 2. Each violation class becomes a normative statement:

- **MUST**: The violation would directly break the thesis value (non-negotiable)
- **SHOULD**: The violation would weaken the thesis value but may have legitimate exceptions

### Step 4: State the Engineering Cost

What trade-off does the engineering team absorb by honouring this principle?

Rules for cost statements:
- MUST NOT include watermark-specific language (no "at demo level" or "in production")
- MUST provide calibration context for agent judgment calls
- MUST describe the trade-off in engineering terms (time, complexity, scope, velocity)

### Step 5: Define the Check

How does `/analyze` detect a violation in a spec or plan? If you cannot define a concrete check, the principle is too vague for the engineering constitution. Go back to Step 3 and make it more specific.

The check must be:
- Evaluable from spec.md, plan.md, and tasks.md content (no runtime checks)
- Binary — either the artifact passes or it doesn't
- Documented as part of the engineering principle

### Step 6: Consolidate

- Multiple thesis principles may converge on **one** engineering principle (e.g., Thesis 2 + Thesis 10 both produce "Explainability is Architectural")
- One thesis principle may produce **zero** engineering principles (it's implemented structurally by the pipeline, or is purely a product/org principle)
- Document the mapping: which thesis principles feed each engineering principle

## Three-Gate Assessment for Sync Impact

When the product thesis changes and translation is re-run, use this assessment to determine whether the engineering constitution needs updating.

### Gate 1: Does It Touch Engineering?

The thesis change must affect at least one engineering domain (architecture, API design, data model, testing, tooling, developer workflow).

- **If NO** (purely product positioning, org culture, competitive strategy): **STOP**. No engineering constitution update. Document in sync impact report: "Thesis change does not touch engineering domains."
- **If YES**: Proceed to Gate 2.

### Gate 2: Does It Create Uncaught Violations?

Run Steps 2-3 of the translation mechanism. Do the existing engineering principles already catch the violations this thesis change implies?

- **If YES** (existing principles cover the violation classes): **STOP**. No engineering constitution update. The existing principles are sufficient. Document in sync impact report: "Existing principle [X] already covers this violation class."
- **If NO** (there is a violation class that falls through ALL existing principles): Proceed to Gate 3.

### Gate 3: Does the New Principle Pass the Universality Test?

If a new engineering principle is proposed, it must pass all three checks:

1. **Applicable across any project type and tech stack** — A Go team on GCP must be able to follow it. A mobile team must be able to follow it. If it's specific to a language, cloud provider, or framework, it fails.
2. **Testable by /analyze** — It has at least one MUST statement that can be checked against spec/plan/tasks content. If it can only be verified at runtime or requires subjective judgment, it fails.
3. **Not duplicating an existing principle** — If an existing principle could be extended to cover this, extend it rather than creating a new principle.

- **If PASSES all three**: Add as a new engineering principle in `.specify/memory/constitution.md`.
- **If FAILS any check**: The concern becomes a **project-specific rule** in `.claude/rules/`, not a constitutional principle. The sync impact report documents this routing decision and which gate failed.

### Overfitting Signal

More than one new engineering principle per quarter suggests over-constraint. Engineering principles should be stable. If you find yourself adding principles frequently, consider whether:

- The thesis is changing too fast (product direction is unstable)
- The translation is overfitting (turning preferences into mandates)
- Existing principles could be extended instead

## Sync Impact Report Format

When the `/constitution` command runs a sync, it produces a report with this structure:

```markdown
## Sync Impact Report

**Thesis version**: [version]
**Constitution version**: [old] -> [new]
**Date**: [YYYY-MM-DD]

### Changes Assessed

| Thesis Change | Gate 1 | Gate 2 | Gate 3 | Outcome |
|---------------|--------|--------|--------|---------|
| [description] | PASS/FAIL | PASS/FAIL/N/A | PASS/FAIL/N/A | [action taken] |

### Engineering Constitution Updates

[List any principle additions, modifications, or removals with rationale]

### Project-Specific Rules Routed

[List any concerns routed to .claude/rules/ with Gate 3 failure reason]

### No-Action Items

[List thesis changes that required no engineering update, with gate that stopped them]
```

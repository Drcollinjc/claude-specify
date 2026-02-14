---
description: Create or update the project constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Two-Document Governance Model

This command manages two documents and the translation mechanism between them:

1. **Product Thesis** (`.specify/memory/product-principles.md`) — WHO we build for, WHY, what VALUES. Written for the whole organisation. Changes rarely.
2. **Engineering Constitution** (`.specify/memory/constitution.md`) — Engineering principles DERIVED from the thesis. Technology-agnostic, universally applicable. Changes when thesis changes or engineering practice evolves.
3. **Translation Mechanism** (`.specify/rules/constitution-translation.md`) — HOW thesis principles become engineering principles. The bridge between the two documents.

## Execution Modes

Determine which mode to execute based on `$ARGUMENTS`:

### Mode A: Update Product Thesis
**Trigger**: User says "update thesis", "update principles", "change product principles", or provides new/modified thesis content.

1. Load `.specify/memory/product-principles.md`.
2. Apply the user's changes (add, modify, or remove thesis principles).
3. Follow versioning: MAJOR for principle removals/redefinitions, MINOR for additions, PATCH for clarifications.
4. Write updated thesis back to `.specify/memory/product-principles.md`.
5. **Trigger sync** — proceed to Mode C automatically.

### Mode B: Update Engineering Constitution Directly
**Trigger**: User says "update constitution", "update engineering principles", or provides engineering-specific principle changes.

1. Load `.specify/memory/constitution.md`.
2. Apply the user's changes.
3. Follow versioning in the constitution's Governance section.
4. Validate technology-agnosticism: scan for language names, cloud providers, framework references, specific tools. Flag any found.
5. Validate testability: each principle must have an `/analyze check` section with concrete checks.
6. Write updated constitution with sync impact report prepended.
7. Run consistency propagation (Step 6 below).

### Mode C: Sync — Translate Thesis Changes to Engineering Constitution
**Trigger**: Automatically after Mode A, or user says "sync", "translate", "run translation".

1. Load all three documents: thesis, constitution, translation mechanism.
2. For each thesis principle, run the translation process (Steps 1-6 from translation mechanism).
3. For each candidate engineering principle change, run the **Three-Gate Assessment**:
   - **Gate 1**: Does the thesis change touch engineering? If NO → no update, document.
   - **Gate 2**: Do existing engineering principles already catch the violations? If YES → no update, document.
   - **Gate 3**: Does the proposed new/modified principle pass the universality test? If NO → route to `.claude/rules/` as project-specific rule, document.
4. Apply approved changes to `.specify/memory/constitution.md`.
5. For any concerns routed to `.claude/rules/`, create or update the appropriate rule file with a traceability note.
6. Generate sync impact report (format defined in translation mechanism).
7. Run consistency propagation (Step 6 below).

### Mode D: Interactive Creation (No Existing Documents)
**Trigger**: Neither thesis nor constitution exists, or user says "create", "initialize".

1. Guide user through product thesis creation:
   - What are you building? Who for? Why?
   - What are your resolved tensions? (values with explicit costs)
   - What are your unresolved tensions?
2. Write thesis to `.specify/memory/product-principles.md`.
3. Run translation to derive engineering principles.
4. Write constitution to `.specify/memory/constitution.md`.
5. Run consistency propagation (Step 6 below).

## Step 6: Consistency Propagation

After any constitution change, validate dependent artifacts:

1. Read `.specify/templates/plan-template.md` — ensure Constitution Check section aligns with current principles.
2. Read `.specify/templates/commands/architecture.md` — ensure Constitution Alignment section references current principles.
3. Read each command file in `.claude/commands/` — verify thesis/constitution loading instructions reference correct file paths and principle names.
4. Report any misalignments found (do not auto-fix command files — report for manual review).

## Step 7: Technology-Agnosticism Validation

Scan the updated engineering constitution for:
- Programming language names (Python, Go, Java, Rust, etc.)
- Cloud provider names (AWS, GCP, Azure, etc.)
- Framework/tool names (React, Django, DuckDB, Prefect, etc.)
- Platform-specific patterns (Lambda, ECS, S3, etc.)

Any found → **WARNING**: These belong in `.claude/rules/` or `CLAUDE.md`, not in the constitution. Flag for user to relocate.

## Step 8: Output

Produce a final summary:
- New version(s) and bump rationale for each document updated
- Sync impact report (if Mode C ran)
- Any project-specific concerns routed to `.claude/rules/`
- Any consistency propagation misalignments found
- Any technology-agnosticism warnings
- Suggested commit message

## Formatting & Style

- Use Markdown headings exactly as in the existing documents.
- Each engineering principle must have: derivation line, "What it prevents", MUST statements, "This costs us", `/analyze check`.
- Product thesis principles must have: description, "This means", "This costs us".
- Keep sync impact reports as HTML comments at the top of the constitution file.

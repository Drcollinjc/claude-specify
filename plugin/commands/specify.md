---
description: Create or update the feature specification from a natural language feature description.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

## Phase 1: Watermark Selection

The watermark controls task TYPE (not count) for all downstream stages. If `$ARGUMENTS` includes a watermark keyword, use it. Otherwise, prompt the user to select one.

**Valid watermarks**: `spike`, `poc`, `demo`, `mvp`, `production`, `refactor`, `tech-debt`

| Watermark | Test tasks | Validator agent | What validator checks |
|-----------|-----------|----------------|----------------------|
| spike | No | No | N/A (findings doc only) |
| poc | No | Yes | Core technical approach works |
| demo | No | Yes | All acceptance criteria pass |
| mvp | Integration tests | Yes | ACs + test suite passes |
| production | Unit + integration + e2e | Yes | ACs + full test suite + performance |
| refactor | Maintain coverage | Yes | Existing tests + targeted regression |
| tech-debt | Targeted | Yes | Affected test subsets |

Record the selected watermark in spec.md metadata and decisions.md.

## Phase 1.5: Product Thesis Awareness

Load `.specify/memory/product-principles.md` (the product thesis). During specification generation, perform a **full thesis check** against ALL thesis principles. This is an inline check — no formal section in the spec, but flag any violations as they are detected.

**Thesis check behavior**:
- For each thesis principle, assess whether the feature description aligns with or violates the principle
- Mark principles as N/A where they clearly don't apply to this feature
- If a violation is detected (e.g., feature describes execution-layer functionality that violates §6, or lacks explanation mechanism for AI features per §2/§10):
  - Flag it inline during spec generation as: `[THESIS FLAG: §N — description of concern]`
  - Integrate the flag into the relevant spec section (e.g., add a constraint or out-of-scope note)
- If no violations: proceed silently (no output for passing checks)

**Key thesis principles to watch during /specify**:
- §6 (Intelligence Layer Boundary) — is the feature crossing into execution?
- §2/§10 (AI as Collaborator / AI Transparency) — do AI features include explanation requirements?
- §11 (Terminology) — are domain terms consistent with any established glossary?

## Phase 1.8: Project Enforcement Setup

Check if `CLAUDE.md` exists in the repository root. If it does NOT exist, create a minimal `CLAUDE.md` with the following content:

```markdown
# [Project Name] Development Guidelines

This project uses the `.specify` engineering plugin for structured development.

## Pipeline

All implementation MUST go through the `.specify` pipeline:
```
/specify → /clarify → [/architecture] → /plan → /tasks → /checklist → /analyze → /implement
```

## Rules

See `.claude/rules/` for enforcement rules that apply at all times.

## Active Technologies

[To be populated by /plan command]

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
```

Replace `[Project Name]` with the repository name (from the git remote or directory name).

If `CLAUDE.md` already exists, verify it contains the pipeline reference and `.claude/rules/` pointer. If missing, append them inside the MANUAL ADDITIONS markers.

## Phase 2: Specification Workflow

Given that feature description, do this:

1. **Generate a concise short name** (2-4 words) for the branch:
   - Analyze the feature description and extract the most meaningful keywords
   - Create a 2-4 word short name that captures the essence of the feature
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
   - Keep it concise but descriptive enough to understand the feature at a glance
   - Examples:
     - "I want to add user authentication" → "user-auth"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"

2. **Check for existing branches before creating new one**:
   
   a. First, fetch all remote branches to ensure we have the latest information:
      ```bash
      git fetch --all --prune
      ```
   
   b. Find the highest feature number across all sources for the short-name:
      - Remote branches: `git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
      - Local branches: `git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
      - Specs directories: Check for directories matching `specs/[0-9]+-<short-name>`
   
   c. Determine the next available number:
      - Extract all numbers from all three sources
      - Find the highest number N
      - Use N+1 for the new branch number
   
   d. Run the script `.specify/scripts/bash/create-new-feature.sh --json "$ARGUMENTS"` with the calculated number and short-name:
      - Pass `--number N+1` and `--short-name "your-short-name"` along with the feature description
      - Bash example: `.specify/scripts/bash/create-new-feature.sh --json "$ARGUMENTS" --json --number 5 --short-name "user-auth" "Add user authentication"`
      - PowerShell example: `.specify/scripts/bash/create-new-feature.sh --json "$ARGUMENTS" -Json -Number 5 -ShortName "user-auth" "Add user authentication"`
   
   **IMPORTANT**:
   - Check all three sources (remote branches, local branches, specs directories) to find the highest number
   - Only match branches/directories with the exact short-name pattern
   - If no existing branches/directories found with this short-name, start with number 1
   - You must only ever run this script once per feature
   - The JSON is provided in the terminal as output - always refer to it to get the actual content you're looking for
   - The JSON output will contain BRANCH_NAME and SPEC_FILE paths
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot")

3. Load `.specify/templates/spec-template.md` to understand required sections.

4. Follow this execution flow:

    1. Parse user description from Input
       If empty: ERROR "No feature description provided"
    2. Extract key concepts from description
       Identify: actors, actions, data, constraints
    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts feature scope or user experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
    4. Fill User Scenarios & Testing section
       If no clear user flow: ERROR "Cannot determine user scenarios"
    5. Generate Functional Requirements
       Each requirement must be testable
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)
    6. Define Success Criteria
       Create measurable, technology-agnostic outcomes
       Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
       Each criterion must be verifiable without implementation details
    7. Identify Key Entities (if data involved)
    8. Return: SUCCESS (spec ready for planning)

5. Write the specification to SPEC_FILE using the template structure, replacing placeholders with concrete details derived from the feature description (arguments) while preserving section order and headings. Include the watermark in the spec metadata section.

6. **Create decisions.md**: Copy `.specify/templates/decisions-template.md` to `FEATURE_DIR/decisions.md`. Fill in the metadata (feature name, watermark, date, branch). Record the specify gate decision: watermark selection rationale and any scope-impacting choices made during spec generation.

7. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `FEATURE_DIR/checklists/requirements.md` with these validation items:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]
      
      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]
      
      ## Content Quality
      
      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed
      
      ## Requirement Completeness
      
      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified
      
      ## Feature Readiness
      
      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification
      
      ## Notes
      
      - Items marked incomplete require spec updates before `/clarify` or `/plan`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user in this format:

           ```markdown
           ## Question [N]: [Topic]
           
           **Context**: [Quote relevant spec section]
           
           **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]
           
           **Suggested Answers**:
           
           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A      | [First suggested answer] | [What this means for the feature] |
           | B      | [Second suggested answer] | [What this means for the feature] |
           | C      | [Third suggested answer] | [What this means for the feature] |
           | Custom | Provide your own answer | [Explain how to provide custom input] |
           
           **Your choice**: _[Wait for user response]_
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

8. **Update decisions.md**: Record the specify gate decision — watermark rationale, any scope decisions, and clarification outcomes.

9. **Create session-summary.md**: Copy `.specify/templates/session-summary-template.md` to `FEATURE_DIR/session-summary.md`. Fill in metadata (feature name, branch, watermark, date). Mark `/specify` as `done` in the Pipeline Progress table. Leave all other stages as `pending`.

10. **Stage Completion Gate**: Before reporting, verify this stage's outputs. **All checks must pass — if any fail, fix the gap before proceeding.**

    **Artifact checks** (file must exist and be non-empty):
    - [ ] `FEATURE_DIR/spec.md` — written with feature content (not template placeholders)
    - [ ] `FEATURE_DIR/decisions.md` — metadata populated, Gate Decisions has `/specify` entry
    - [ ] `FEATURE_DIR/session-summary.md` — created with metadata, `/specify` marked done
    - [ ] `FEATURE_DIR/checklists/requirements.md` — created with validation items

    **Content checks**:
    - [ ] spec.md contains watermark in metadata section
    - [ ] spec.md has at least one user story with acceptance criteria
    - [ ] decisions.md Gate Decisions table has at least one row for `/specify`
    - [ ] session-summary.md Pipeline Progress shows `/specify` as `done`

    If any check fails: **STOP**. Fix the gap. Re-verify. Do not skip.

11. Report completion with branch name, spec file path, decisions.md path, checklist results, watermark, and readiness for the next phase (`/clarify` or `/plan`).

**NOTE:** The script creates and checks out the new branch and initializes the spec file before writing.

## General Guidelines

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: RESTful APIs unless specified otherwise

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)

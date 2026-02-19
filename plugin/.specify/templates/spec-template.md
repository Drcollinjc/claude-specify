# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

**User Journey Test** *(executable by validator agent via Playwright MCP)*:

<!--
  Define the step-by-step user journey that validates this story from the user's perspective.
  Each step should be an observable browser action with an expected visual/functional result.
  The validator agent executes these steps using Playwright MCP tools during GATE verification.
-->

1. Navigate to [URL] → page loads with [expected content]
2. Click [element] → [expected navigation or state change]
3. Verify [specific visual/functional outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

**User Journey Test** *(executable by validator agent via Playwright MCP)*:

1. Navigate to [URL] → page loads with [expected content]
2. [Action] → [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

**User Journey Test** *(executable by validator agent via Playwright MCP)*:

1. Navigate to [URL] → page loads with [expected content]
2. [Action] → [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]
- **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]  
- **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]
- **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]
- **FR-005**: System MUST [behavior, e.g., "log all security events"]

*Example of marking unclear requirements:*

- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g., "Users can complete account creation in under 2 minutes"]
- **SC-002**: [Measurable metric, e.g., "System handles 1000 concurrent users without degradation"]
- **SC-003**: [User satisfaction metric, e.g., "90% of users successfully complete primary task on first attempt"]
- **SC-004**: [Business metric, e.g., "Reduce support tickets related to [X] by 50%"]

## Intelligence Eval Requirements *(include only for features with LLM-powered chains)*

<!--
  CONDITIONAL SECTION: Include this section ONLY when the feature involves LLM calls
  (text generation, structured extraction, scoring, classification, etc.).
  Remove this entire section if the feature has no LLM-powered components.

  Purpose: Define what "good intelligence" looks like BEFORE implementation,
  so the validator can verify output quality alongside engineering correctness.
-->

### LLM Chain Steps

<!--
  List each LLM call in the feature's intelligence chain.
  For each step, classify its output type:
  - Category A (deterministic-intent): Tight variance expected (e.g., text-to-SQL, entity extraction)
  - Category B (creative-intent): Wider variance acceptable (e.g., message generation, insight narrative)
-->

| Step | Input | Output | Category | Variance Tolerance |
|------|-------|--------|----------|--------------------|
| [Step 1 name] | [What goes in] | [What comes out] | A or B | [tight/moderate/wide] |
| [Step 2 name] | [What goes in] | [What comes out] | A or B | [tight/moderate/wide] |

### Eval Rubrics

<!--
  For each chain step, define what "good" output looks like.
  These rubrics become the judge criteria during validator gates.
-->

**[Step 1 name]**:
- [Quality dimension 1, e.g., "Insights must be specific to the prospect's industry, not generic advice"]
- [Quality dimension 2, e.g., "Scores must correlate with the attribute data provided"]
- [Quality dimension 3, e.g., "Rationales must be grounded in input data, no hallucinated claims"]

### Satisfaction Thresholds

<!--
  Define the quality bars that must be met during validator gates.
  These are starting points — they will be tuned based on observed eval results.
-->

| Eval Layer | Threshold | Notes |
|-----------|-----------|-------|
| Structural (schema, field presence, value ranges) | 100% pass | Non-negotiable — output must parse correctly |
| Semantic (rubric satisfaction via judge model) | >= 0.7 | Starting threshold — tune based on results |
| Consistency (score stability across N runs) | [Define if needed] | Only for Category A outputs or scored fields |

### Fixture Requirements

<!--
  Describe the minimum test data needed for intelligence evals.
  Keep it minimal — 2-3 representative scenarios per chain step.
  Detailed fixture files are created during /implement, not here.
-->

- [Fixture 1]: [Brief description, e.g., "Active prospect with strong engagement, weak intent — tests score calibration"]
- [Fixture 2]: [Brief description, e.g., "Edge case with sparse data — tests graceful degradation"]

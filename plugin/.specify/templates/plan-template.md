# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Watermark**: [spike/poc/demo/mvp/production/refactor/tech-debt]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`
**Decisions**: `/specs/[###-feature-name]/decisions.md`

**Note**: This template is filled in by the `/plan` command.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*Sources: `.specify/memory/product-principles.md` (product thesis) + `.specify/memory/constitution.md` (engineering constitution)*

### Product Thesis Alignment

| Thesis Principle | Status | Notes |
|-----------------|--------|-------|
| §1 Confidence Over Speed | ✅/⚠️/❌/N/A | |
| §2 AI as Collaborator | ✅/⚠️/❌/N/A | |
| §3 Trust Above All | ✅/⚠️/❌/N/A | |
| §4 Opinionated Process | ✅/⚠️/❌/N/A | |
| §5 Craft is Competitive Advantage | ✅/⚠️/❌/N/A | |
| §6 Intelligence Layer Boundary | ✅/⚠️/❌/N/A | |
| §7 Writing Over Meetings | ✅/⚠️/❌/N/A | |
| §8 Freedom With Focus | ✅/⚠️/❌/N/A | |
| §9 Learning is Core | ✅/⚠️/❌/N/A | |
| §10 AI Transparency | ✅/⚠️/❌/N/A | |
| §11 Terminology Invariant | ✅/⚠️/❌/N/A | |

### Engineering Constitution Alignment

| Eng Principle | Status | Notes |
|--------------|--------|-------|
| I. Requirements Are Contracts | ✅/⚠️/❌ | |
| II. Explainability is Architectural | ✅/⚠️/❌/N/A | |
| III. Respect the Product Boundary | ✅/⚠️/❌ | |
| IV. Terminology is Invariant | ✅/⚠️/❌ | |
| V. Architecture for Change | ✅/⚠️/❌ | |
| VI. Learning is Intentional | ✅/⚠️/❌ | |

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── spec.md              # Feature specification (/specify command output)
├── decisions.md         # Decision trace (/specify creates, all stages update)
├── plan.md              # This file (/plan command output)
├── quickstart.md        # Phase 1 output (/plan command)
├── session-summary.md   # AI-facing operational log
├── design/              # Design artifacts subdirectory
│   ├── research.md      # Phase 0 output (/plan command)
│   ├── data-model.md    # Phase 1 output (/plan command)
│   └── contracts/       # Phase 1 output (/plan command)
├── checklists/          # Requirement quality checklists (/checklist command)
└── tasks.md             # Task breakdown (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |

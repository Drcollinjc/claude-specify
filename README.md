# claude-specify

Spec-driven development pipeline for Claude Code (and other AI coding agents).

`claude-specify` is an engineering process plugin that gives AI coding agents a structured pipeline for building features: from natural language description to validated implementation. It installs pipeline commands (`/specify`, `/plan`, `/implement`, ...), enforcement rules, and a two-document governance model into any project.

## What It Does

Instead of ad-hoc prompting, `claude-specify` enforces a repeatable pipeline:

```
/specify → /clarify → [/architecture] → /plan → /tasks → /checklist → /analyze → /implement
```

Each stage produces artifacts that feed the next. The pipeline is enforced by rules that load into the agent's context, ensuring stages aren't skipped even across context compaction.

### Two-Document Governance

1. **Product Principles** (`.specify/memory/product-principles.md`) — Your product thesis. Defines who you're building for, why, and what trade-offs you've resolved. This is the source of truth for product decisions.

2. **Engineering Constitution** (`.specify/memory/constitution.md`) — Engineering principles derived from the product thesis via a translation mechanism. Governs how the agent makes implementation decisions.

The constitution is generated from principles using `/constitution` — you write the thesis, the agent derives the engineering rules.

### What Gets Generated Per Feature

Each `/specify` invocation creates a feature directory under `specs/`:

```
specs/007-feature-name/
├── spec.md              # Feature specification
├── plan.md              # Implementation plan
├── tasks.md             # Dependency-ordered task list
├── decisions.md         # Decision audit trail
├── session-summary.md   # AI-facing operational log
├── design/              # Research, data models, contracts
└── checklists/          # Custom verification checklists
```

## Installation

### Prerequisites

- A project directory (doesn't need to be a git repo, but branching works better with git)
- Claude Code (or another AI coding agent that reads `.claude/` config)

### Install

```bash
git clone https://github.com/your-org/claude-specify.git
cd claude-specify
./install.sh install /path/to/your-project
```

This copies:
- `.specify/` — Pipeline config (thesis, constitution, scripts, templates)
- `.claude/commands/` — 9 pipeline commands
- `.claude/rules/` — 4 process-enforcement rules
- `specs/` — Feature specification directory

### Update

```bash
./install.sh update /path/to/your-project
```

Updates `.specify/` and commands. Skips existing rules to preserve your customizations (use `--force` to overwrite).

### Uninstall

```bash
./install.sh uninstall /path/to/your-project
```

Removes `.specify/`, plugin commands, and plugin rules. Preserves `specs/` (your feature artifacts).

## Getting Started

After installation:

1. **Write your product thesis.** Edit `.specify/memory/product-principles.md` with your product's purpose, audience, values, and trade-offs. This is the foundation everything else derives from.

2. **Generate your constitution.** Run `/constitution` in Claude Code. The agent will read your thesis and generate engineering principles.

3. **Start a feature.** Run `/specify` with a natural language description of what you want to build. The agent creates a branch, spec file, and tracking artifacts.

4. **Follow the pipeline.** Each stage builds on the last:
   - `/specify` — Captures the feature in structured spec format
   - `/clarify` — Identifies underspecified areas, asks targeted questions
   - `/architecture` — (Optional) For features requiring architectural decisions
   - `/plan` — Generates implementation plan with technology decisions
   - `/tasks` — Creates dependency-ordered, implementable tasks
   - `/checklist` — Generates custom verification checklist
   - `/analyze` — Cross-artifact consistency check (runs automatically before `/implement`)
   - `/implement` — Executes tasks with validator gates between user stories

## Pipeline Commands

| Command | Purpose |
|---------|---------|
| `/specify` | Create feature spec from natural language description |
| `/clarify` | Ask up to 5 targeted clarification questions |
| `/architecture` | Architecture decisions for complex features |
| `/plan` | Generate implementation plan |
| `/tasks` | Generate dependency-ordered task list |
| `/checklist` | Generate custom verification checklist |
| `/analyze` | Cross-artifact consistency analysis |
| `/implement` | Execute tasks with enforcement and validation |
| `/constitution` | Generate/update engineering constitution from thesis |

## Customization

### Adding Project-Specific Rules

The `examples/rules/` directory contains reference rules for common domains:

- `cloud-architecture.md` — AWS architecture patterns
- `duckdb-patterns.md` — DuckDB-specific patterns
- `python-tdd.md` — Python test-driven development
- `debugging.md` — Systematic debugging approach
- `data-modeling.md` — Domain-specific data modeling

Copy any that apply to your project into `.claude/rules/`:

```bash
cp examples/rules/python-tdd.md /path/to/project/.claude/rules/
```

You can also write your own rules. Any `.md` file in `.claude/rules/` is loaded into the agent's context.

### Watermark System

The `/specify` command supports watermarks that control task granularity:

| Watermark | Purpose | Task Style |
|-----------|---------|------------|
| `spike` | Exploration, no gates | Minimal tasks, no validator |
| `poc` | Proof of concept | Light tasks |
| `demo` | Demonstrable feature | Standard tasks with gates |
| `mvp` | Minimum viable product | Full tasks with gates |
| `production` | Production-ready | Comprehensive tasks, security review |
| `refactor` | Code improvement | Focused on before/after |
| `tech-debt` | Debt reduction | Targeted cleanup |

## How It Works

### Enforcement

Four rule files in `.claude/rules/` survive context compaction and enforce the pipeline:

- **implementation-enforcement.md** — Prevents coding outside `/implement`, enforces task hydration and validator gates
- **session-workflow.md** — Maintains `decisions.md` and `session-summary.md` across stages
- **verification.md** — Binary validation patterns (PASS/FAIL, no "close enough")
- **thinking.md** — Structured problem analysis before implementation

### Validator Gates

During `/implement`, the agent dispatches a read-only validator subagent at each user story boundary. The validator checks acceptance criteria and produces a PASS/FAIL report. The implementing agent cannot self-validate — this separation prevents optimistic completion.

### Context Compaction Recovery

When the agent's context window fills up and compresses, session artifacts (`decisions.md`, `session-summary.md`) and native tasks survive. The enforcement rules reload automatically and include a recovery protocol that prevents the agent from continuing without re-establishing state.

## Project Structure

```
claude-specify/
├── README.md                    # This file
├── install.sh                   # Install/update/uninstall script
├── VERSION                      # Semantic version
├── plugin/                      # Everything that gets installed
│   ├── .specify/                # → PROJECT/.specify/
│   │   ├── memory/              # Product thesis + constitution
│   │   ├── rules/               # Constitution translation mechanism
│   │   ├── scripts/bash/        # Pipeline automation scripts
│   │   └── templates/           # Spec, plan, tasks, decisions templates
│   ├── commands/                # → PROJECT/.claude/commands/
│   └── rules/                   # → PROJECT/.claude/rules/
└── examples/                    # NOT installed — reference only
    └── rules/                   # Domain-specific rule examples
```

## License

MIT

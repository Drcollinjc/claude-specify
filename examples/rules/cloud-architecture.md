---
globs: ["cdk/**", "infrastructure/**", "**/*stack*", "**/*cdk*"]
---
# Cloud Architecture v1.0.0

## Purpose
Architect AI/ML/Data applications on AWS with pragmatic Python-first approach, considering project stage (demo/development/scale/production) and applying Amazon's Type 1 vs Type 2 decision framework.

## Core Principles

### 1. Stage-Appropriate Architecture
Different project stages demand different architectural approaches:

**Demo Stage** (Prove Concept):
- Optimize for: Speed to demo, local development, iteration velocity
- Accept: Higher operational complexity, self-managed services
- Avoid: Over-engineering, premature optimization, expensive managed services

**Development Stage** (Build MVP):
- Optimize for: Developer experience, testing, modularity
- Accept: Technical debt if documented, monolithic start
- Avoid: Distributed systems complexity, microservices prematurely

**Scale Stage** (Handle Growth):
- Optimize for: Performance, cost efficiency at volume
- Accept: Increased operational complexity, migration effort
- Avoid: Rewrites, breaking changes to stable APIs

**Production Stage** (Enterprise):
- Optimize for: Reliability, security, compliance
- Accept: Higher costs, slower velocity, process overhead
- Avoid: Unproven technologies, undocumented dependencies

### 2. Python-First Philosophy
Maintain single-language codebase to minimize context-switching:

- Embrace: Python for application logic, infrastructure (CDK), data processing, orchestration
- Domain-specific languages where appropriate (SQL for queries, YAML for static config)
- Avoid: Mixing languages for same concern, JSON/YAML as business logic

### 3. Local-First Development
Every feature MUST be testable on developer laptop without AWS:

- Full transformation pipeline runnable locally
- Test suites execute without AWS credentials
- Fast feedback loops (<5 min edit-test-debug)
- Standard Python tooling (pytest, debuggers, type hints)

Strategies: LocalStack, DuckDB instead of Aurora, file-based queues, Docker Compose

### 4. Type 1 vs Type 2 Decisions (Amazon Framework)

**Type 1 Decisions (One-Way Doors):**
- Irreversible or very costly to reverse
- Require careful analysis, senior review, POCs
- Examples: Data model design, API contracts, database choice

**Type 2 Decisions (Two-Way Doors):**
- Reversible with reasonable effort
- Can experiment, iterate, change direction
- Examples: Orchestration tool, specific library version, deployment approach

**Decision Classification Matrix:**

| Factor | Type 1 (Irreversible) | Type 2 (Reversible) |
|--------|----------------------|---------------------|
| Data migration cost | High (weeks) | Low (days) |
| API contract changes | Breaking changes to clients | Internal only |
| Vendor lock-in | Proprietary formats/APIs | Open standards |
| Learning curve | Team retraining required | Individual ramp-up |
| Infrastructure coupling | Tightly coupled to cloud primitives | Abstracted, portable |

## AWS Architecture Patterns

### Data Architecture

**Demo/Development:**
```
DuckDB (local + S3 Parquet) → For analytics workloads <100GB
├─ Pros: Perfect local dev, Python-native, fast queries
├─ Cons: Not managed, manual scaling
└─ Type 2: Easy migration to Aurora/Redshift
```

**Scale/Production:**
```
Aurora Serverless v2 → For transactional workloads
Redshift Serverless → For analytical workloads >100GB
```

### Workflow Orchestration

**Preferred:** Prefect OSS (Python-native, local testing, great DX)
**Alternative:** AWS Step Functions (fully managed, cheap, poor local testing)

### Compute Patterns

- **Lambda**: Stateless, <15min, event-driven. ARM64 for cost savings.
- **ECS Fargate**: Stateful, long-running. ARM64 (Graviton) for 20% savings.
- **Batch**: Large-scale ML training only when Fargate insufficient.

## Decision Framework — Evaluation Criteria (Priority Order)

1. **Local Testability** (30%): Can developers run full workflow on laptop?
2. **Single-Language Alignment** (25%): Pure Python or introduces new language?
3. **Developer Experience** (20%): IDE support, standard patterns?
4. **Iteration Speed** (15%): How fast to add features, refactor?
5. **Cost** (5%): Monthly cost at stage?
6. **Operational Simplicity** (5%): Managed vs self-hosted trade-offs?

## Architecture Review Checklist

- [ ] Data ingestion decoupled from transformation
- [ ] Transformation decoupled from serving layer
- [ ] Infrastructure decoupled from business logic
- [ ] Type 1 decisions identified and justified
- [ ] Type 2 decisions documented with migration paths
- [ ] Vendor lock-in risks assessed
- [ ] Virtual environments for dependency isolation
- [ ] Structured logging (JSON format for CloudWatch)
- [ ] Configuration via environment variables + .env files

## Anti-Patterns

- Over-engineering for demo stage (microservices, complex event-driven architecture)
- Polyglot for no reason (Node.js orchestration when Python Prefect exists)
- AWS service kitchen sink (using every service because it exists)
- Ignoring local development (requiring AWS for every test)
- Type 1 decision rushing (choosing managed DB without evaluating alternatives)

## Migration Paths (By Stage)

Demo → Development: Add observability, CI/CD. DuckDB stays.
Development → Scale: Consider DuckDB → Aurora/Redshift if volume grows. Add caching.
Scale → Production: Multi-region, security audits, SLAs, managed services.

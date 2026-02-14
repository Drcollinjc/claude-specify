---
globs: ["**/*.sql", "dbt/**/*", "**/models/**", "**/*schema*", "**/*migration*"]
---
# Data Modeling v1.0.0

## Purpose
Domain-specific data modeling best practices and validation for analytical, transactional, and streaming applications.

## Application Type Detection

Detect application type from feature specification keywords:

### Analytical Applications
**Keywords**: analytics, metrics, reporting, dashboard, BI, data warehouse, medallion, lakehouse, aggregation, OLAP, dimensional model, star schema, fact table, dimension table
**Primary Concerns**: Query performance, denormalization, aggregation patterns, grain consistency
**Validation Focus**: Star schema structure, slowly changing dimensions, partitioning strategy, fact/dimension separation

### Transactional Applications
**Keywords**: CRUD, application backend, API, microservice, REST, user management, OLTP, normalized, relational, foreign key
**Primary Concerns**: Write performance, referential integrity, ACID compliance, data consistency

### Streaming Applications
**Keywords**: real-time, event, stream, Kafka, Kinesis, CDC, event-driven, pub/sub, event sourcing
**Primary Concerns**: Throughput, idempotency, late arrival handling, schema evolution

## Best Practices by Domain

### Analytical Data Models (Star Schema / Medallion Architecture)

1. Denormalize for reads: Minimize joins in analytical queries
2. Grain consistency: Every fact table has clear grain (one row = one business event)
3. Slowly Changing Dimensions (SCD): Track historical changes
4. Partitioning: Partition by time for query pruning
5. Separate facts from dimensions

**Naming Conventions:**
- Fact tables: `fct_` prefix
- Dimension tables: `dim_` prefix
- Staging tables: `stg_` prefix
- Bridge tables: `bridge_` prefix

**Validation Checklist:**
- All fact tables have documented grain statements
- Dimension tables identified and separated
- Foreign keys to dimensions defined (even if not enforced)
- Partitioning strategy specified
- No many-to-many without bridge tables
- Wide tables <50 columns threshold

### Transactional Data Models (Normalized Schema 3NF)

1. 3rd Normal Form: Minimize redundancy
2. Strong referential integrity: Foreign keys with CASCADE rules
3. Single source of truth: Each entity has one canonical table
4. Audit trails: created_at, updated_at, updated_by on all tables
5. Soft deletes: deleted_at instead of hard deletes

**Naming Conventions:**
- Tables: Plural nouns (`customers`, `orders`)
- Primary keys: `{table_singular}_id`
- Boolean columns: `is_` or `has_` prefix
- Timestamps: `_at` suffix

### Streaming Data Models (Event Sourcing / Immutable Events)

1. Immutable events: Never update, only append
2. Self-contained messages: Include all context
3. Schema evolution: Forward/backward compatibility
4. Idempotency keys: Enable exactly-once processing
5. Event versioning: Track schema version in payload

## Validation Severity Levels

**Critical**: Schema mismatches, missing primary keys, broken FK references, inconsistent grain, missing idempotency
**Warning**: Wide tables (>50 cols), missing FK indexes, undocumented transformations, missing audit columns
**Info**: Normalization/denormalization suggestions, convenience views, partitioning optimization

## Common Data Type Standards

### Analytical (DuckDB, Redshift, BigQuery)
```sql
customer_id TEXT                    -- Flexible for UUIDs
revenue DECIMAL(18,2)               -- Exact precision
win_rate_pct DECIMAL(5,2)          -- 0.00-100.00
transaction_date DATE               -- Day precision
event_timestamp TIMESTAMP           -- Second precision
```

### Transactional (PostgreSQL, MySQL)
```sql
customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid()
account_balance DECIMAL(18,2) NOT NULL DEFAULT 0
status VARCHAR(20) CHECK (status IN ('active', 'suspended'))
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

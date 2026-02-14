---
globs: ["**/*.sql", "**/*duckdb*", "dbt/**/*", "**/models/**"]
---
# DuckDB Patterns v1.1.0

## Purpose
DuckDB-specific patterns and common pitfalls when migrating from PostgreSQL.

## CSV Reading

### Critical Pattern: Use Row Number for Header

```sql
-- WRONG (boolean, unreliable with sparse data)
FROM read_csv('path.csv', header=TRUE, AUTO_DETECT=TRUE)

-- CORRECT (explicit row number)
FROM read_csv('path.csv',
    header=1,           -- Row number, not boolean!
    delim=',',          -- Explicit delimiter
    AUTO_DETECT=TRUE,   -- Let DuckDB infer types
    ignore_errors=true  -- Handle malformed rows gracefully
)
```

**Why**: Empty values in early rows can cause DuckDB's auto-detection to skip to later rows, detecting data as headers.

### Validation Before Building Models
Always test CSV reading before writing dbt models:
```sql
SELECT * FROM read_csv('path.csv', header=1) LIMIT 5;
```

## SQL Syntax Differences from PostgreSQL

| PostgreSQL | DuckDB | Notes |
|------------|--------|-------|
| `STRFTIME('%Y-Q', date, 'modifier')` | `STRFTIME(date, '%Y') \|\| '-Q' \|\| QUARTER(date)` | 3-param not supported |
| `%q` format specifier | `QUARTER()` function | %q not recognized in DuckDB |
| STRFTIME(format, date) | STRFTIME(date, format) | Parameter order reversed |
| `date + INTERVAL '1 day'` | `date + INTERVAL 1 DAY` | Slightly different syntax |

## Connection Patterns

### Read-Only Mode for Analytics
```python
# For analytics services (SELECT only)
conn = duckdb.connect('path.duckdb', read_only=True)

# For ETL/transformation (needs writes)
conn = duckdb.connect('path.duckdb', read_only=False)
```

### Per-Request Connections for Web/Agent Applications
For web applications and agents handling concurrent requests, create fresh connections per request:

```python
def execute_query(db_path: str, query: str) -> list[dict]:
    """Execute query with per-request connection.

    Why per-request:
    - Thread-safe without locks
    - No connection pool overhead for file-based DB
    - Each request gets isolated connection state
    - Automatic cleanup on function exit
    """
    conn = duckdb.connect(db_path, read_only=True)
    try:
        result = conn.execute(query).fetchdf()
        return result.to_dict('records')
    finally:
        conn.close()
```

**Why NOT connection pooling**: DuckDB file-based connections are fast (~1ms), pooling adds complexity without benefit, shared connections cause file locking issues.

### File Locking
- `read_only=False`: Exclusive lock, blocks other processes
- `read_only=True`: Shared lock, allows concurrent readers
- Default to `read_only=True` unless writes are needed

## Schema Patterns

### Use TEXT for IDs
DuckDB handles TEXT IDs efficiently. Don't force INTEGER:
```sql
customer_id TEXT PRIMARY KEY  -- 'CUST-00001'
```

### Schema-Qualified Table Names
```sql
SELECT * FROM main_gold.dim_customer;
SELECT DISTINCT table_schema FROM information_schema.tables;
```

## NL Agent System Prompt Patterns

When building NL-to-SQL agents with DuckDB:

### Domain-to-Table Mapping
Include explicit mappings in system prompt:
```
- "customers", "accounts", "companies" → dim_customer table
- "deals", "opportunities", "sales" → fct_opportunities table
```

### DuckDB-Specific SQL Instructions
```
- Use STRFTIME(date_column, '%Y-%m') for date formatting
- Use QUARTER(date_column) for quarter extraction
- String concatenation: col1 || '-' || col2
- Date arithmetic: date_column + INTERVAL 7 DAY
```

## Anti-Patterns
- Using `header=TRUE` instead of `header=1`
- Assuming PostgreSQL SQL syntax works in DuckDB
- Opening analytics databases in write mode
- Not validating CSV reading before building models
- Assuming INTEGER IDs when data uses TEXT
- Using shared connections for concurrent web requests
- Connection pooling for file-based DuckDB

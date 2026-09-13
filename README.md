# PostgreSQL JSONB — Flexible Student Profiles & JSON vs JSONB Benchmark

A hands-on exploration of PostgreSQL's `JSONB` type for storing student profile
data that doesn't fit a rigid, fixed-column schema — comparing `JSON` vs `JSONB`
storage, benchmarking query performance with and without indexes, and testing
containment (`@>`), key-existence (`?`), and jsonpath (`@?`) operators on a
dataset of 1,000,000 rows.

## Why JSONB?

Student records often carry optional, nested, or evolving attributes —
scholarships, skill lists, subject-wise exam scores, extracurricular data —
that vary from student to student. Rather than adding new nullable columns
every time a new attribute appears, this project stores that variable part of
the profile as JSONB alongside a normal relational core (`id`, `name`,
`student_id`, `class`), then benchmarks how well Postgres performs on it at
scale.

## What this covers

- `JSON` vs `JSONB` storage and query performance, side by side
- GIN indexing on JSONB columns and its effect on containment queries
- Practical query patterns: `->`, `->>`, `?`, `@>`, `@?` (jsonpath)
- Before/after benchmarks (`EXPLAIN ANALYZE`) on 500K rows per table
- Running Postgres in Docker with a Python script for querying/inserting

## Tech Stack

- PostgreSQL 16
- Docker
- Python
- SQL / JSON / JSONB / GIN Indexes
- Windows 11, 16 GB RAM

## Setup

```bash
docker compose up -d
docker exec -it postgres_jsonb_demo psql -U postgres -d student_db
```

Run the Python query script:

```bash
python jsonb_queries.py
```

---

## Benchmark: JSON vs JSONB Performance

### Overview

Two identical-shape tables, 500,000 rows each (1,000,000 rows total), were
used to measure query performance, JSON parsing overhead, JSONB binary
storage advantages, GIN index effectiveness, and containment query speed.

### Dataset

```sql
CREATE TABLE students_json (
    id SERIAL PRIMARY KEY,
    profile JSON
);

CREATE TABLE students_jsonb (
    id SERIAL PRIMARY KEY,
    profile JSONB
);
```

Populated with generated records of this shape:

```json
{
  "name": "Student_1",
  "age": 22,
  "city": "Siliguri",
  "gpa": 3.01
}
```

| Table            | Records   |
|------------------|-----------|
| students_json    | 500,000   |
| students_jsonb   | 500,000   |
| **Total**        | 1,000,000 |

### Benchmark 1 — Missing Key Lookup

```sql
SELECT * FROM students_json  WHERE profile->>'stream' = 'Science';
SELECT * FROM students_jsonb WHERE profile->>'stream' = 'Science';
```

The dataset has no `stream` field, so Postgres has to scan and evaluate every row.

| Table  | Execution Time |
|--------|----------------|
| JSON   | 200.303 ms     |
| JSONB  | 66.203 ms      |

**Finding:** JSONB completed the scan roughly 3x faster than JSON, even though both queries returned zero rows.

### Benchmark 2 — GPA Filtering

```sql
SELECT * FROM students_json  WHERE (profile->>'gpa')::numeric > 3.5;
SELECT * FROM students_jsonb WHERE (profile->>'gpa')::numeric > 3.5;
```

| Table  | Execution Time | Rows Returned | Rows Removed |
|--------|----------------|----------------|---------------|
| JSON   | 737.288 ms     | 62,204         | 437,796       |
| JSONB  | 428.615 ms     | 61,923         | 438,077       |

**Finding:** JSONB was ~1.7x faster while performing the same full-table scan.

### GIN Index Creation

```sql
CREATE INDEX idx_students_jsonb_profile
ON students_jsonb
USING GIN(profile);
```

### Benchmark 3 — Indexed Containment Query

```sql
SELECT * FROM students_jsonb WHERE profile @> '{"city":"Siliguri"}';
```

| Metric          | Value        |
|-----------------|--------------|
| Rows Returned   | 125,278      |
| Execution Time  | 55.485 ms    |
| Query Plan      | Bitmap Index Scan → Bitmap Heap Scan |

**Finding:** Postgres used the GIN index directly, cutting execution time dramatically versus a full scan.

### Benchmark 4 — Missing Document Search Using GIN

```sql
SELECT * FROM students_jsonb WHERE profile @> '{"scholarship":true}';
```

| Metric          | Value     |
|-----------------|-----------|
| Rows Returned   | 0         |
| Execution Time  | 0.097 ms  |

**Finding:** The GIN index ruled out any match almost instantly, no scan required.

### Results Summary

| Benchmark                        | JSON        | JSONB      |
|-----------------------------------|-------------|------------|
| Missing Key Scan                  | 200.303 ms  | 66.203 ms  |
| GPA Filter                        | 737.288 ms  | 428.615 ms |
| GIN Indexed City Lookup           | N/A         | 55.485 ms  |
| GIN Indexed Missing Key Search    | N/A         | 0.097 ms   |

### Key Findings

- **JSONB is faster** — it outperformed JSON in every comparable test.
- **JSONB reduces parsing overhead** — JSON stores raw text; JSONB stores a
  binary representation Postgres can process more efficiently.
- **GIN indexes are a game changer** — query time dropped from hundreds of
  milliseconds to ~55 ms on 500,000 JSONB documents.
- **JSON can't compete on indexing** — it doesn't support GIN indexes, the
  containment operator (`@>`), or efficient document search, which is why
  Postgres recommends JSONB for most production workloads.

### Conclusion

This benchmark shows that JSONB is significantly faster than JSON for
read-heavy workloads, supports advanced indexing and document search, and
that GIN indexes provide substantial performance gains at scale. JSONB is
the preferred choice for production use cases involving APIs, search
functionality, analytics workloads, event data, and flexible schemas.

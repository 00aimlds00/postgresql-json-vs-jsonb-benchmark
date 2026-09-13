Here's a GitHub-ready README that turns your work into a strong portfolio project.

PostgreSQL JSON vs JSONB Performance Benchmark
Overview

This project benchmarks PostgreSQL's JSON and JSONB data types using a large dataset of 500,000 records per table (1 million total records).

The objective was to measure:

Query performance
JSON parsing overhead
JSONB binary storage advantages
GIN index effectiveness
Containment query performance

All tests were executed inside PostgreSQL running in Docker.

Tech Stack
PostgreSQL 16
Docker
SQL
JSON
JSONB
GIN Indexes
Windows 11
16 GB RAM
Dataset

Two tables were created containing identical data.

JSON Table
CREATE TABLE students_json (
    id SERIAL PRIMARY KEY,
    profile JSON
);

JSONB Table
CREATE TABLE students_jsonb (
    id SERIAL PRIMARY KEY,
    profile JSONB
);

Adding 500000 records in each table

student_db=# INSERT INTO students_json(profile)
SELECT json_build_object(
    'name', 'Student_' || g,
    'age', floor(random()*10 + 15),
    'gpa', round((random()*4)::numeric, 2),
    'city',
    (ARRAY['Siliguri','Kolkata','Delhi','Mumbai','Hyderabad','Bangalore'])
    [floor(random()*6 + 1)]
)
FROM generate_series(1,500000) g;

student_db=# INSERT INTO students_jsonb(profile)
SELECT jsonb_build_object(
    'name', 'Student_' || g,
    'age', floor(random()*10 + 15),
    'gpa', round((random()*4)::numeric, 2),
    'city',
    (ARRAY['Siliguri','Kolkata','Delhi','Mumbai','Hyderabad','Bangalore'])
    [floor(random()*4 + 1)]
)
FROM generate_series(1,500000) g;

Sample Record
{
  "name": "Student_1",
  "age": 22,
  "city": "Siliguri",
  "gpa": 3.01
}

Dataset Size
Table	Recordsstudents_json	500,000
students_jsonb	500,000
Total	1,000,000
Benchmark 1: Missing Key Lookup

Query:

EXPLAIN ANALYZE
SELECT *
FROM students_json
WHERE profile->>'stream' = 'Science';

EXPLAIN ANALYZE
SELECT *
FROM students_jsonb
WHERE profile->>'stream' = 'Science';

Observation

The dataset did not contain a stream field.

PostgreSQL was forced to scan every row and evaluate the condition.

Results
Table	Execution TimeJSON	200.303 ms
JSONB	66.203 ms
Finding

JSONB completed the scan approximately 3x faster than JSON despite both queries returning zero rows.

Benchmark 2: GPA Filtering

Query:

EXPLAIN ANALYZE
SELECT *
FROM students_json
WHERE (profile->>'gpa')::numeric > 3.5;

EXPLAIN ANALYZE
SELECT *
FROM students_jsonb
WHERE (profile->>'gpa')::numeric > 3.5;

JSON
Execution Time: 737.288 ms
Rows Returned: 62,204
Rows Removed: 437,796

JSONB
Execution Time: 428.615 ms
Rows Returned: 61,923
Rows Removed: 438,077

Results
Table	Execution TimeJSON	737.288 ms
JSONB	428.615 ms
Finding

JSONB was approximately 1.7x faster while performing the same full-table scan operation.

GIN Index Creation

A GIN index was added to the JSONB column.

CREATE INDEX idx_students_jsonb_profile
ON students_jsonb
USING GIN(profile);

Benchmark 3: Indexed Containment Query

Query:

EXPLAIN ANALYZE
SELECT *
FROM students_jsonb
WHERE profile @> '{"city":"Siliguri"}';

Execution Plan
Bitmap Index Scan
Bitmap Heap Scan

Results
Rows Returned: 125,278

Execution Time: 55.485 ms

Finding

PostgreSQL successfully utilized the GIN index.

Execution time dropped dramatically compared with full table scans.

Benchmark 4: Missing Document Search Using GIN

Query:

EXPLAIN ANALYZE
SELECT *
FROM students_jsonb
WHERE profile @> '{"scholarship":true}';

Results
Rows Returned: 0

Execution Time: 0.097 ms

Finding

The GIN index was able to determine that no matching documents existed almost instantly.

Query Plan Comparison
Without Index
Seq Scan


PostgreSQL examined every row.

With GIN Index
Bitmap Index Scan
Bitmap Heap Scan


PostgreSQL directly located matching rows using the index.

Results Summary
Benchmark	JSON	JSONBMissing Key Scan	200.303 ms	66.203 ms
GPA Filter	737.288 ms	428.615 ms
GIN Indexed City Lookup	N/A	55.485 ms
GIN Indexed Missing Key Search	N/A	0.097 ms
Key Findings
JSONB is Faster

JSONB consistently outperformed JSON in all comparable tests.

JSONB Reduces Parsing Overhead

JSON stores raw text.

JSONB stores a binary representation that PostgreSQL can process more efficiently.

GIN Indexes are Game Changers

A GIN index reduced query execution time from hundreds of milliseconds to approximately:

55 ms


for a dataset containing:

500,000 JSONB documents

JSON Cannot Compete Here

JSON does not support:

GIN indexing
Containment operator (@>)
Efficient document searching

These are major reasons PostgreSQL recommends JSONB for most production workloads.

Conclusion

This benchmark demonstrates that:

JSONB is significantly faster than JSON for read-heavy workloads.
JSONB supports advanced indexing and document search capabilities.
GIN indexes provide substantial performance improvements on large datasets.
JSONB is the preferred choice for production applications involving:
APIs
Search functionality
Analytics workloads
Event data
Flexible schemas




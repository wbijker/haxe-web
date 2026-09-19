# Queryability — what is not implemented

Taken from a diff of `CodeQuery`'s `ISelectQuery`/`IQuery` members and its `SqlExpressions` node
types against this port. Worked in batches of ten, top down.

## Expressions

- [x] 1. `NOT`
- [x] 2. `IN (…)` over a list
- [x] 3. `IN (…)` over a subquery
- [x] 4. `BETWEEN`
- [x] 5. `LIKE` / `ILIKE`
- [x] 6. `IS DISTINCT FROM`
- [x] 7. `CASE WHEN`
- [x] 8. `COALESCE` / `NULLIF`
- [x] 9. String functions — `UPPER`, `LOWER`, `LENGTH`, `TRIM`, `SUBSTRING`
- [x] 10. String concatenation
- [x] 11. `CAST`
- [x] 12. Raw SQL, as an escape hatch
- [x] 13. Scalar subquery
- [x] 14. Quantified comparison — `= ANY (…)`, `> ALL (…)`
- [x] 15. Parameters, rather than values written into the SQL
- [x] 16. Date part extraction
- [x] 17. Date arithmetic and intervals
- [x] 18. Numeric functions — `ABS`, `ROUND`, `CEIL`, `FLOOR`
- [x] 19. `SqlType` on a column
- [x] 20. A visitor, in place of the driver's downcast chain

## Windows and aggregates

- [x] 21. `ROW_NUMBER`, `RANK`, `DENSE_RANK`
- [x] 22. `LEAD`, `LAG`
- [x] 23. `FIRST_VALUE`, `LAST_VALUE`
- [x] 24. Window frames — `ROWS`/`RANGE BETWEEN`
- [x] 25. An inline `OVER (…)`, without naming the window
- [x] 26. `FILTER (WHERE …)` on an aggregate
- [x] 27. `DISTINCT` inside any aggregate

## Statements

- [x] 28. `UNION`, `UNION ALL`
- [x] 29. `INTERSECT`, `EXCEPT`
- [x] 30. `GROUP BY ROLLUP`
- [x] 31. `GROUP BY CUBE`
- [x] 32. `GROUPING SETS`
- [x] 33. CTEs — `WITH`
- [x] 34. Recursive CTEs
- [x] 35. Row locking — `FOR UPDATE`, `SKIP LOCKED`, `NOWAIT`
- [x] 36. Lateral joins
- [x] 37. `UPDATE … FROM <source>`
- [x] 38. `DELETE … USING <source>`
- [x] 39. Multi-row `INSERT`
- [x] 40. `INSERT … SELECT`
- [x] 41. Upsert — `ON CONFLICT`
- [x] 42. Joins declared on an entity
- [x] 43. `DbView`
- [x] 44. Insert strategy and identity override

## Execution

- [x] 45. A driver that runs what it renders — `ISqlTranslator` renders, `ISqlDriver` adds
  somewhere to send it, and the PHP runtime (`PhpDriver`, `PdoTranslator`, `PdoExecutor`) runs it
  through PDO. `RunPhp` is the whole port end to end against an in-memory SQLite database.

## Day 2 – SQL Joins and Sub-queries
- **Date:** 22 Oct 2025
- **Focus:** INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL OUTER JOIN, SUB-QUERIES- IN. EXISTS, CORRELATED sub-queries
- **Queries:** 5 
- **Tools:** MySQL 

---

### 🧠 Concepts Basics:
- **JOINS:**
  - ***INNER JOIN***: Matching records
  - ***OUTER JOIN***: 
    - ***LEFT JOIN***: INNER JOIN + additional records from the left table which aren't present in the right table.
    - ***RIGHT JOIN***: INNER JOIN + additional records from the right table which are not present in the left table.
    - ***FULL OUTER JOIN***: INNER JOIN + additional records from the left table which aren't present in the  right table + additional records from the right table which aren't present in the left table.
  - ***SELF JOIN***: A table joins with itself and aliases important to differentiate the tables formed.
    - ***Types***: INNER, LEFT, RIGHT
  - ***NATURAL JOIN***: combines based on common column name and compatible data types
  - ***CROSS JOIN***: Cartesian product of two tables; brings out every possible combination of pairs in both tables.

- **SUB-QUERIES**:
  - Query inside another query.
  - Inner query gives result/output-->used as input for outer query.
  **Types**:
    - ***Scalar subquery***: single value result (eg: WHERE <condition> = <sub-query>)
    - ***Multiple rows sub-query***: (eg: WHERE <condition> IN <sub-query>)
      - single col, multiple rows
      - multiple cols, multiple rows
    - ***Correlated sub-query***: Inner sub-query is dependent on outer query; For every record of outer query, inner sub-query gets executed again so that it's resource intensive.
    - ***Nested sub-query***: sub-query inside another sub-query.

- **WITH CLAUSE**:
  - **Common table expressions (CTE)** is useful for creating a temporary result set which can be reused multiple times in the main query which makes it so readable, easier to maintain and debug complex queries later without needing multiple subqueries/ joins.

- **EXISTS/ NOT EXISTS**:
  - Checks the boolean expression (Yes/ No)
  - eg: customers with no orders, department with no employees.
  - If the sub-query fetches no records then --> NOT EXISTS condition becomes true


---

### Tricks / Insights

* `EXISTS` / `NOT EXISTS` > `IN` / `NOT IN` because of NULL-safety.
  - EXISTS and NOT EXISTS are preferred over IN and NOT IN because **they handle NULL values safely and efficiently**.
  - NOT IN can return no rows if the subquery contains even a single NULL, while NOT EXISTS always evaluates each row logically — it’s NULL-safe.

  - EXISTS checks row-by-row.
  - It doesn’t care about NULLs — if the condition matches, it’s true; if not, it’s false.
      - Hence, NOT EXISTS is always reliable, even when NULLs exist.
  - **So which one is faster?**
    - They’re logically different — not performance substitutes. 
    - EXISTS is usually more efficient for correlated subqueries because it stops scanning as soon as it finds a match (‘short-circuit evaluation’). 
    - IN must evaluate the whole list.
* `CROSS JOIN` is ideal when comparing to one global value (e.g., overall avg sales).
* Use `JOIN + ON` when comparison is key-based (per department or store).
* `CASE WHEN` helps you **label records** directly in SELECT rather than filter them.
* Window functions can replace many subqueries once you’re comfortable (`AVG(...) OVER()` etc.).

---

### Quick patterns & solutions (from Questions solved)

- Q1: Customers with orders — use `EXISTS` or `JOIN`; `EXISTS` avoids duplicates.
- Q2: Total spent per customer (include zeros) — `LEFT JOIN` + `COALESCE(SUM(amount), 0)` + `GROUP BY`.
- Q3: Orders without successful payment — use `NOT EXISTS`:
  ```sql
  SELECT o.* FROM orders o
  WHERE NOT EXISTS (
    SELECT 1 FROM payments p
    WHERE p.order_id = o.order_id AND p.payment_status = 'Succeeded'
  );
  ```
- Q4: Customers with no orders — NOT EXISTS anti-join pattern.
- Q5: Customers with avg order > overall avg — CTE to compute per-customer AVG, then compare to AVG of those values (CTE + CROSS JOIN or subquery).

---

## 🧠 Concepts Revised
| Concept | Pattern / Keyword | Example / Trick |
|----------|------------------|-----------------|
| Existence check | `EXISTS` / `NOT EXISTS` | Safer than `IN` / `NOT IN` (NULL-safe) |
| Left join + NULL handling | `LEFT JOIN` + `CASE WHEN col IS NULL THEN 0` | For customers with no orders |
| Compare with overall average | `CTE + CROSS JOIN` | Compare each group to global metric |
| Missing matches | `LEFT JOIN` + `WHERE right.col IS NULL` | Find records with no related rows |
| Conditional remarks | `CASE WHEN` in SELECT | Label Above/Below Avg, High/Low spend |
| Subquery type | Correlated subquery | Refers to outer query per row |
| Filter scope | `WHERE` = row filter, `HAVING` = group filter | Use HAVING for aggregates only |

---

## Mistakes / Debugs

* Tried to use `HAVING` without `GROUP BY` → error.
* Used `NOT IN` on NULL-containing subquery → returned empty set.
* Mixed aggregation levels (`AVG(SUM())`) → solved using CTE layering.


## ⚙️ Tricks / Insights

- **EXISTS vs IN**
  - `EXISTS` checks if *a row exists* → efficient & NULL-safe  
  - `IN` checks if *a value matches any list* → can fail silently with NULLs  
  - ✅ Prefer `EXISTS` in interviews — it shows both performance and correctness awareness.  
  - Example:
    ```sql
    -- Safer pattern
    SELECT c.customer_id
    FROM customers c
    WHERE EXISTS (
        SELECT 1 FROM orders o
        WHERE o.customer_id = c.customer_id
          AND o.order_status = 'Completed'
    );
    ```

- **Business-aware filtering**
  - Always check for *valid business events* like:
    - `order_status = 'Completed'`
    - `payment_status = 'Succeeded'`
  - Shows analytical thinking, not just coding.

- **LEFT JOIN + NULL fix**
  ```sql
  SELECT c.customer_id, COALESCE(SUM(o.amount), 0) AS total_order_amount
  FROM customers c
  LEFT JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_id;

→ Use COALESCE() (or CASE WHEN) to replace NULLs with 0.

- **Compare per-entity vs overall average**
```sql
WITH per_customer AS (
    SELECT customer_id, AVG(amount) AS avg_order
    FROM orders GROUP BY customer_id
),
total_avg AS (
    SELECT AVG(avg_order) AS overall_avg FROM per_customer
)
SELECT c.customer_name, p.avg_order
FROM per_customer p
CROSS JOIN total_avg t
JOIN customers c USING (customer_id)
WHERE p.avg_order > t.overall_avg;
```

- **Find records without a match**
```sql
SELECT o.order_id
FROM orders o
LEFT JOIN payments p USING(order_id)
WHERE p.order_id IS NULL;
```

→ “Find orders without payment.”

## 💬 Mistakes or Debugs:
| Issue |	Fix |
| ----- | --- |
| Used NOT IN instead of NOT EXISTS | 	NOT IN fails with NULLs, use NOT EXISTS |
| Missed alias in subquery | Always alias derived tables (AS t) |
| Checked “at least one order” without filtering by completed ones |Add business logic filter (order_status='Completed') |
| Confused JOIN vs WHERE EXISTS	| JOIN = return matching data, EXISTS = return boolean check |
| Used ON in CROSS JOIN	| ❌ CROSS JOIN never takes ON, use only WHERE for comparison |

## ✅ Summary:
- Use `EXISTS` for logical checks, `LEFT JOIN` for inclusion with missing data, and `CROSS JOIN` for comparisons with overall aggregates.
- Always anchor your queries to business meaning, not just syntax.


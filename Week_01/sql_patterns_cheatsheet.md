# SQL Patterns & Interview Cheatsheet
**Purpose:** Quick revision of 90% of real interview query patterns — clean, explainable, and easy to recall under pressure.

---

## Pattern Buckets — Think Like an Interviewer

| # | Pattern Name | Core SQL Concept | Typical Keywords / Clues |
|---|---------------|------------------|---------------------------|
| 1 | Basic Filters | `SELECT`, `WHERE`, `ORDER BY` | top-N, filter, recent, highest |
| 2 | Aggregations | `GROUP BY`, `HAVING` | total, average, count, min/max |
| 3 | Comparison to Global Avg | `CTE` + `CROSS JOIN` | above/below avg (entire dataset) |
| 4 | Comparison to Dept Avg | `CTE` + `JOIN` + `ON` | per-group comparison |
| 5 | Ranking | `ROW_NUMBER`, `RANK`, `DENSE_RANK` | top 3, nth highest |
| 6 | Conditional Metrics | `CASE WHEN` | active vs inactive, flagging |
| 7 | Existence Check | `EXISTS`, `NOT EXISTS` | customers with / without orders |
| 8 | Subqueries | `IN`, `NOT IN`, `EXISTS` | nested filters, subset comparisons |
| 9 | Joins & Lookups | `INNER`, `LEFT JOIN` | data combination, enrichment |
| 10 | Window KPIs | `OVER()`, `PARTITION BY` | running total, moving avg |
| 11 | Self Comparison | Self-Join / Window | previous, next, difference |
| 12 | NULL Handling | `COALESCE()`, `EXISTS` | avoid NULL issues |

---

## Short Tricks & Recall Rules

| Concept | Rule / Shortcut | Example / Tip |
|----------|-----------------|----------------|
| Compare with global avg | `CTE + CROSS JOIN` | Compare every row to one scalar avg |
| Compare with group avg | `CTE + JOIN` | Join on dept_id / category |
| Above/Below filter | Use `WHERE metric > (subquery)` | Filter out using subquery or CTE |
| Conditional flag | `CASE WHEN ... THEN ... ELSE ... END` | Label above/below, active/inactive |
| Filter aggregated data | `HAVING` (not WHERE) | `HAVING SUM(sales) > 10000` |
| NULL-safe existence | Use `EXISTS`, not `IN` | `EXISTS` avoids NULL trap |
| Cross Join rule | No `ON` condition | Used to compare each row with global aggregate |
| Debug tip | Run CTEs independently | CTE = readable, debuggable |
| Window rank syntax | `RANK() OVER(PARTITION BY dept ORDER BY salary DESC)` | Always use partitioning for per-group rank |
| Fast Top-N | `ORDER BY col DESC LIMIT n` | Simpler than window if just top-N required |

---

## 🧩 Common Pattern Templates

### 1️⃣ Compare Row vs Global Average
```sql
WITH base AS (
  SELECT store_id, SUM(price) AS total_sales
  FROM sales
  GROUP BY store_id
),
summary AS (
  SELECT AVG(total_sales) AS avg_sales FROM base
)
SELECT b.*, 
       CASE WHEN b.total_sales > s.avg_sales THEN 'Above Avg'
            ELSE 'Below Avg' END AS sales_flag
FROM base b
CROSS JOIN summary s;
```
`NOTE`: Use when comparing entities (e.g., stores, employees) to overall average.

2️⃣ Compare Row vs Group Average (Per Department)
```sql
WITH dept_stats AS (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employee
  GROUP BY dept_id
)
SELECT e.emp_name, e.dept_id, e.salary
FROM employee e
JOIN dept_stats d
  ON e.dept_id = d.dept_id
WHERE e.salary > d.avg_salary;
```
`NOTE`: Use when comparing each row within its own group.

3️⃣ Existence / Non-Existence Check
-- Employees who belong to a department
```sql
SELECT e.emp_name
FROM employee e
WHERE EXISTS (
  SELECT 1
  FROM department d
  WHERE d.dept_id = e.dept_id
);
```
-- Departments with no employees
```sql
DELETE FROM department d
WHERE NOT EXISTS (
  SELECT 1
  FROM employee e
  WHERE e.dept_id = d.dept_id
);
```
`NOTE`:EXISTS / NOT EXISTS is NULL-safe.
NOT IN breaks if subquery has NULLs.

4️⃣ Ranking & Top-N
```sql
SELECT emp_name, dept_id, salary,
       DENSE_RANK() OVER(PARTITION BY dept_id ORDER BY salary DESC) AS rnk
FROM employee
WHERE rnk <= 3;
```
`NOTE`:✅ For “Top 3 per department” type questions.
⚠️ Remember: RANK() can skip numbers, DENSE_RANK() doesn’t.

5️⃣ Conditional Aggregation with CASE
```sql
SELECT dept_id,
       SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM employee
GROUP BY dept_id;
```
`NOTE`: ✅ Great for pivot-style counts or classifying KPIs.

6️⃣ Filter After Aggregation (HAVING)
```sql
SELECT dept_id, COUNT(emp_id) AS emp_count
FROM employee
GROUP BY dept_id
HAVING COUNT(emp_id) > 5;
```
`NOTE`: ✅ HAVING filters after aggregation (post-GROUP BY).

7️⃣ Self Join (Compare Row-to-Row)
```sql
SELECT e1.emp_name AS emp, e2.emp_name AS manager
FROM employee e1
JOIN employee e2
  ON e1.manager_id = e2.emp_id;
```
`NOTE`: ✅ Used when table references itself (e.g., employees & managers).

8️⃣ Window Aggregate — Running Total
```sql
SELECT emp_id, order_date,
       SUM(amount) OVER(PARTITION BY emp_id ORDER BY order_date) AS running_total
FROM sales;
```
'NOTE': ✅ Interviewer loves this pattern — shows modern SQL fluency.


---


**NULL-Safety Rule** (Explanation):
| Comparison |	Behavior | 	Safe with NULLs? |	Recommended? |
| ---------- | --------- | ----------------- | ------------- |
| IN / NOT IN | Compares list of values	| ❌ Fails if any NULL present | ❌ Avoid with NULLs |
| EXISTS / NOT EXISTS |	Checks row existence |	✅ Always safe | ✅ Use instead |

**Why:**
- NOT IN (1, 2, NULL) → returns nothing because NULL makes the comparison unknown.
- NOT EXISTS checks rows logically → no NULL issue.

**Safe Universal Template**
```sql
WITH base AS (
  -- Step 1: Aggregate or prepare data
  SELECT <entity>, <metric>
  FROM <table>
  GROUP BY <entity>
),
summary AS (
  -- Step 2: Calculate summary stat
  SELECT AVG(<metric>) AS avg_metric
  FROM base
)
-- Step 3: Compare or label
SELECT b.*, 
       CASE WHEN b.<metric> > s.avg_metric THEN 'Above'
            ELSE 'Below' END AS remarks
FROM base b
CROSS JOIN summary s;
```

`NOTE`: ✅ Universal pattern for comparison, classification, filtering problems.


---


**Mistake logs**:
| Mistake |	Fix |
| ------- | --- |
| Forgot alias for CTE | Always alias each subquery/CTE |
| Used ON in CROSS JOIN	| ❌ CROSS JOIN doesn’t need ON |
| Mixed aggregate and non-aggregate columns | Always GROUP BY non-aggregates |
| Used WHERE instead of HAVING for aggregate filter | Use HAVING after aggregation |
| Used NOT IN with NULLs | Replace with NOT EXISTS |


---


**Quick Recall Triggers**:

- “Above/below avg?” → CTE + CROSS JOIN

- “Per department?” → CTE + JOIN

- “Who has / who doesn’t?” → EXISTS / NOT EXISTS

- “Top-N?” → DENSE_RANK() or LIMIT

- “Conditional logic?” → CASE WHEN

- “After aggregation filter?” → HAVING

- “NULL-safe?” → EXISTS

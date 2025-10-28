# Day 2 – Subqueries practice questions

* **Date:** 22 Oct 2025
* **Focus:**  EXISTS / NOT EXISTS, Subqueries, CTEs
* **Queries:** 10 Questions
* **Tools:** MySQL

---

## Concepts Revised

| Concept                    | Pattern / Keyword            | Example / Trick                              |
| -------------------------- | ---------------------------- | -------------------------------------------- |
| Compare within group       | `JOIN + ON dept`             | Find employees earning above dept average    |
| Compare with overall value | `CROSS JOIN + WHERE`         | Compare store vs overall avg sales           |
| Conditional remarks        | `CASE WHEN ... THEN ... END` | Add “Above Avg / Below Avg” flags            |
| Subquery filter            | `IN` / `EXISTS`              | Find departments with (or without) employees |
| Safe deletion              | `DELETE … WHERE NOT EXISTS`  | Remove depts without employees               |
| Aggregated comparison      | `HAVING`                     | Filter groups after aggregation              |
| Inline aggregation         | `WITH CTE` or subquery       | Avoid nested SUM-inside-AVG errors           |

---

## Rule-of-Thumb Patterns

| Situation                      | Recommended Pattern              | Reason                            |
| ------------------------------ | -----------------------          | --------------------------------- |
| when comparing row with a single aggregated 
value **(like avg across all)**  | ✅ `CROSS JOIN + WHERE`          | One global metric (no key needed) |
| when comparing row with per group aggregated 
value **(like avg per dept)**    | ✅ `JOIN + ON dept_name + WHERE` | One metric per group              |
| Add remarks / category         | ✅ `CASE WHEN in SELECT clause`  | Cleaner than multiple queries     |
| Delete unmatched rows or checking
boolean expression -yes/no       | ✅ `WHERE NOT EXISTS`            | NULL-safe, faster than `NOT IN`   |
| Filter aggregated data 
only above/ below                | ✅ `HAVING`                      | Works after `GROUP BY`            |

---

## Example Patterns

**🔹 Compare with Dept Average** (JOIN + ON + WHERE)

```sql
WITH dept_avg AS (
  SELECT dept_name, AVG(salary) AS avg_sal
  FROM employee
  GROUP BY dept_name
)
SELECT e.*
FROM employee e
JOIN dept_avg d ON e.dept_name = d.dept_name
WHERE e.salary > d.avg_sal;
```

**🔹 Compare with Global Average** (CROSS JOIN + WHERE)

```sql
WITH avg_sal AS (SELECT AVG(salary) AS avg_salary FROM employee)
SELECT e.*
FROM employee e
CROSS JOIN avg_sal a
WHERE e.salary > a.avg_salary;
```

**🔹 Conditional Remark** (CASE WHEN in SELECT clause)

```sql
SELECT emp_name, salary,
       CASE WHEN salary > 50000 THEN 'Above Avg'
            ELSE 'Below Avg' END AS remark
FROM employee;
```

**🔹 Delete Departments with No Employees** (checking the unmatched rows/ boolean)

```sql
DELETE FROM department d
WHERE NOT EXISTS (
  SELECT 1 FROM employee e
  WHERE e.dept_name = d.dept_name
);
```

---

## Tricks / Insights

* `EXISTS` / `NOT EXISTS` > `IN` / `NOT IN` because of NULL-safety.
* `CROSS JOIN` is ideal when comparing to one global value (e.g., overall avg sales).
* Use `JOIN + ON` when comparison is key-based (per department or store).
* `CASE WHEN` helps you **label records** directly in SELECT rather than filter them.
* Window functions can replace many subqueries once you’re comfortable (`AVG(...) OVER()` etc.).

---

## Mistakes / Debugs

* Tried to use `HAVING` without `GROUP BY` → error.
* Used `NOT IN` on NULL-containing subquery → returned empty set.
* Mixed aggregation levels (`AVG(SUM())`) → solved using CTE layering.

---


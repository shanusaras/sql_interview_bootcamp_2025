# Day 2 – SQL Joins and Sub-queries
- **Date:** 22 Oct 2025
- **Focus:** INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL OUTER JOIN, SUB-QUERIES- IN. EXISTS, CORRELATED sub-queries
- **Queries:** 6 (including challenge)
- **Tools:** MySQL 

---

## 🧠 Concepts Basics:
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

## Tricks / Insights

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

## Mistakes / Debugs

* Tried to use `HAVING` without `GROUP BY` → error.
* Used `NOT IN` on NULL-containing subquery → returned empty set.
* Mixed aggregation levels (`AVG(SUM())`) → solved using CTE layering.

---


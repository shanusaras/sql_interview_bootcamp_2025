# Day 1 – SQL Foundations & Aggregations
- **Date:** 21 Oct 2025
- **Focus:** SELECT, WHERE, ORDER BY, DISTINCT, GROUP BY, HAVING
- **Queries:** 6 (including challenge)
- **Tools:** MySQL 

---

## 🧠 Concepts Learned
| Concept                 | Pattern / Keyword            | Example / Trick              |
| ----------------------- | ---------------------------- | ---------------------------- |
| Unique Count            | `COUNT(DISTINCT col)`        | Count unique IDs             |
| Aggregation             | `SUM(), AVG(), MIN(), MAX()` | Always pair with `GROUP BY`  |
| Date filter             | `BETWEEN 'start' AND 'end'`  | Inclusive range filter       |
| Ranking                 | `ORDER BY ... DESC LIMIT n`  | Top-N pattern                |
| Conditional Aggregation | `HAVING` after `GROUP BY`    | For aggregate filters        |
| Quick metric            | `(price * quantity)`         | Revenue / sales pattern      |
| Sorting & readability   | Use `ROUND()` + `AS alias`   | Makes output interview-ready |


---

## Tricks / Insights
- **string concat** → `CONCAT(first_name, ' ', last_name)`
    - Always use **single quotes `' '`** for strings — this avoids issues if the interviewer’s DB has `ANSI_QUOTES` mode enabled, which treats double quotes as identifiers instead of string literals.
- **Date extraction** → `YEAR(hire_date)` or direct comparison
- If asked to find the total amount of customer **who has atleast one order/ purchase**, check the constraint: If order_id/ sale_id is the **primary key**—> then they are unique + non -null so **no need to GROUP BY** and use SUM to get the amount for each transaction/ order .
- **Use aggregation** —> only to perform on multiple row values for same category
- **When calculating total sales amount per customer** --> use **COUNT(order_id/sale_id)** to know the frequency of the purchase / no of purchases/ no of orders too for one customer
- **Don't use mixed aggregates in the single SELECT clause**: Use CTEs, sub-queries and structure the first aggregate and then use it in outer query;
    - To avoid aggregation nesting errors, I isolate levels of aggregation using subqueries.
    - eg. 
    ```sql
    WITH customer_totals AS (
    SELECT customer_id, SUM(price * quantity) AS total_amount
    FROM Sales
    GROUP BY customer_id
    )
    SELECT customer_id, total_amount
    FROM customer_totals
    WHERE total_amount = (SELECT MAX(total_amount) FROM customer_totals);
```
---

## 💬 Mistakes or Debugs
- Misused double quotes in CONCAT — fixed with single quotes `' '`.
- Redundant use of primary key column in GROUP BY


---


/*
DAY 1: Foundation & Aggregations (21st Oct)

Topics:
✔️ SELECT, WHERE, ORDER BY, LIMIT, DISTINCT
✔️ COUNT, SUM, AVG, MIN, MAX
✔️ GROUP BY, HAVING
✔️ Simple single-table KPIs

Sample table: Sales
*/

CREATE DATABASE sql_challenge;
USE sql_challenge;

DROP TABLE  IF EXISTS Sales;

CREATE TABLE Sales(
	sale_id INT PRIMARY KEY,
    customer_id INT,
    product_name VARCHAR(50),
    category VARCHAR(30),
    quantity INT,
    price DECIMAL(10, 2),
    sale_date DATE);

INSERT INTO Sales
VALUES 
(1, 101, 'Laptop', 'Electronics', 1, 75000, '2025-10-01'),
(2, 102, 'Phone', 'Electronics', 2, 30000, '2025-10-02'),
(3, 103, 'Shoes', 'Fashion', 1, 4000, '2025-09-28'),
(4, 101, 'Headphones', 'Electronics', 1, 2000, '2025-09-30'),
(5, 104, 'T-shirt', 'Fashion', 3, 1200, '2025-10-03'),
(6, 102, 'Watch', 'Accessories', 1, 5000, '2025-10-05'),
(7, 105, 'Laptop', 'Electronics', 1, 85000, '2025-09-15'),
(8, 101, 'Shoes', 'Fashion', 2, 8000, '2025-10-06');

SELECT * FROM Sales;

-- =========================================================================================
-- Q1️ — Retrieve all columns for all sales
SELECT * FROM Sales;


-- Q2 - Find the total number of unique customers who purchased something
SELECT COUNT(DISTINCT customer_id) AS unique_no_customers
FROM Sales
WHERE sale_id IS NOT NULL;

-- ✅Optimal solution
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM Sales;
/* 
Explanation:
The WHERE sale_id IS NOT NULL is redundant (since sale_id is the primary key and cannot be NULL).
*/


-- Q3 - Find total sales amount and average sales per customer
SELECT customer_id, ROUND(SUM(quantity * price), 2) AS sales_amount, ROUND(AVG(quantity * price), 2) AS avg_sales
FROM Sales
GROUP BY customer_id
ORDER BY customer_id;

-- ✅Optimal solution
-- They didn't ask the no of orders also per customer but good to include COUNT() metric too
SELECT customer_id,
			 COUNT(sale_id) AS no_of_orders,
       ROUND(SUM(price * quantity), 2) AS total_sales,
       ROUND(AVG(price * quantity), 2) AS avg_sales
FROM Sales
GROUP BY customer_id
ORDER BY total_sales DESC;
/*
Explanation:
Ordering by customer_id is fine; But prefer descending by total_sales for 
“top customer” ranking.
*/


-- Q4 - List top 3 highest-value transactions
SELECT sale_id, ROUND(SUM(quantity * price), 2) AS amount 
FROM Sales
GROUP BY sale_id
ORDER BY amount DESC
LIMIT 3;

-- ✅Optimal solution
SELECT sale_id,
       (quantity * price) AS total_amount
FROM Sales
ORDER BY total_amount DESC
LIMIT 3;
/*
Explanation:
Since each sale_id is unique → SUM() = direct transaction total.
→ no need to GROUP BY.
If sale_id repeats (e.g., multiple items per sale), then grouping makes sense.

So you could simplify without SUM().
*/


-- Q5 - Find total sales and average order value per category for October 2025
SELECT category, ROUND(SUM(quantity * price), 2) AS total_sales, 
				 ROUND(AVG(quantity * price), 2) AS avg_order_value
FROM sales
WHERE sale_date BETWEEN '2025-10-01' AND '2025-10-31'
GROUP BY category
ORDER BY category;

-- ✅Optimal version:( outside the scope of the questions anyways)
SELECT category,
       ROUND(SUM(price * quantity), 2) AS total_sales,
       ROUND(AVG(price * quantity), 2) AS avg_order_value
FROM Sales
WHERE sale_date BETWEEN '2025-10-01' AND '2025-10-31'
GROUP BY category
HAVING total_sales > 5000
ORDER BY total_sales DESC;
/*
Explanation:
“for high-performing categories,” think: use HAVING with an aggregate condition.
HAVING SUM(price * quantity) > 5000
This would filter only categories with > ₹5000 in total sales.

But your version still works fine — it’s a matter of including/excluding threshold filtering.
*/

-- Challenge mode:
-- Find which customer spent the most in total and how much.
SELECT customer_id, ROUND(SUM(quantity * price), 2) AS total_amount
FROM Sales
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 1;

-- ✅Solution for follow-up question:
WITH customer_totals AS (
    SELECT customer_id, SUM(price * quantity) AS total_amount
    FROM Sales
    GROUP BY customer_id
)
SELECT customer_id, total_amount
FROM customer_totals
WHERE total_amount = (SELECT MAX(total_amount) FROM customer_totals);

/* 
Explanation:
If two customers tie for the same top spend, you can use this version

We can’t mix grouped and non-grouped columns without an aggregate or GROUP BY. 
To preserve customer context, we filter after computing the max instead of aggregating again.
*/
--  ==========================================================================================
/*
| Concept                 | Pattern / Keyword            | Example / Trick              |
| ----------------------- | ---------------------------- | ---------------------------- |
| Unique Count            | `COUNT(DISTINCT col)`        | Count unique IDs             |
| Aggregation             | `SUM(), AVG(), MIN(), MAX()` | Always pair with `GROUP BY`  |
| Date filter             | `BETWEEN 'start' AND 'end'`  | Inclusive range filter       |
| Ranking                 | `ORDER BY ... DESC LIMIT n`  | Top-N pattern                |
| Conditional Aggregation | `HAVING` after `GROUP BY`    | For aggregate filters        |
| Quick metric            | `(price * quantity)`         | Revenue / sales pattern      |
| Sorting & readability   | Use `ROUND()` + `AS alias`   | Makes output interview-ready |
*/
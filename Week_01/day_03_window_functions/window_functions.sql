-- Q1

DROP TABLE IF EXISTS orders_w1;
DROP TABLE IF EXISTS customers_w1;


-- customers_w1
CREATE TABLE customers_w1 (
  customer_id INT PRIMARY KEY,
  name VARCHAR(50)
);

INSERT INTO customers_w1 VALUES
(1,'Alice'), (2,'Bob'), (3,'Carol'), (4,'Dave');

-- orders_W1
CREATE TABLE orders_w1 (
  order_id INT PRIMARY KEY,
  customer_id INT,
  order_date DATE,
  amount DECIMAL(10,2),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO orders_w1 VALUES
(101,1,'2025-10-01',100.00),
(102,1,'2025-10-05',50.00),
(103,2,'2025-10-02',120.00),
(104,3,'2025-10-03',120.00),
(105,3,'2025-09-30',30.00),
(106,2,'2025-09-28',200.00),
(107,4,'2025-10-01',170.00),
(108,1,'2025-09-15',300.00),
(109,4,'2025-10-10',30.00);

/* Task: For each customer and month (YYYY-MM), produce:
✔️month
✔️customer_id, name
✔️monthly_total
✔️monthly_rank (1 = highest spend), using RANK() so ties get same rank.
Sort by month desc, then monthly_rank.

Expected output (for sample data) — columns: 
month, customer_id, name, monthly_total, monthly_rank:

2025-10 | 4 | Dave  | 200.00 | 1
2025-10 | 2 | Bob   | 120.00 | 2
2025-10 | 3 | Carol | 120.00 | 2
2025-10 | 1 | Alice | 150.00 | 4
2025-09 | 1 | Alice | 300.00 | 1
2025-09 | 2 | Bob   | 200.00 | 2
2025-09 | 3 | Carol | 30.00  | 3
*/
-- solution
SELECT * FROM customers_w1;
SELECT * FROM orders_w1;

-- monthly totals then rank per month (ties allowed)
-- group by month, cust_id, name--> find sum(amount)
-- outer query--> ranking the various cust_id per month so --> RANK() , partition by month wise, order by monthly_total desc

WITH monthly AS (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    o.customer_id,
    c.name,
    SUM(amount) AS monthly_total
  FROM orders_w1 o
  JOIN customers_w1 c USING (customer_id)
  GROUP BY DATE_FORMAT(order_date, '%Y-%m'), o.customer_id, c.name
)
SELECT
  month,
  customer_id,
  name,
  monthly_total,
  RANK() OVER (PARTITION BY month ORDER BY monthly_total DESC) AS monthly_rank
FROM monthly
ORDER BY month DESC, monthly_rank;

/* NOTE:
Pattern: GROUP to get metrics; then use window functions on the aggregated result.
*/

-- ====================================================================================
-- Q2
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  name VARCHAR(50),
  dept VARCHAR(30),
  salary INT
);

INSERT INTO employees VALUES
(1,'Asha','Engineering',120000),
(2,'Ravi','Engineering',95000),
(3,'Mina','Engineering',120000),
(4,'Sameer','Sales',90000),
(5,'Priya','Sales',85000),
(6,'Karan','Sales',90000),
(7,'Leela','HR',70000);

/* Task: For each dept, return the 2nd highest salary and the employees who earn it. 
Use window functions (DENSE_RANK() or ROW_NUMBER() appropriately).

--NOTE: The below solution is only sample one:
Expected output (sample data) — columns: dept, emp_id, name, salary
Engineering | 2 | Ravi   | 95000
Sales       | 4 | Sameer | 90000
Sales       | 6 | Karan  | 90000
HR          | (no row) -- if no 2nd highest exists
*/
-- SOLUTION :
SELECT * FROM employees;
-- per dept, nth highest salary( have to return the value, not the rank) along with employees
-- use dense_rank()

-- The below solution will filter out the NULL if any in the result
WITH dept AS (SELECT DISTINCT dept
			  FROM employees),
	  ranked AS (SELECT *,
						DENSE_RANK() OVER(PARTITION BY dept ORDER BY salary DESC) AS d_rank
				 FROM employees)
SELECT d.dept, r.emp_id, r.name, r.salary
FROM dept d
LEFT JOIN ranked r USING (dept)
WHERE r.d_rank = 2
ORDER BY d_rank
;

-- Explanation: 
-- The above solution does not show NULL for HR even though I used LEFT JOIN because
-- LEFT JOIN --> fetches all the depts but 
-- WHERE --> filters only the second rank after joining-->so essentially filters out NULL value
-- so solution is:
-- 		--> use filter condition in JOIN ON condition itself as follows👇

-- so to retain NULL in the result as asked in the question, use this solution 👇 ✅✅✅
WITH dept AS (SELECT DISTINCT dept
			   FROM employees),
	ranked AS (SELECT *,
				DENSE_RANK() OVER(PARTITION BY dept ORDER BY salary DESC) AS d_rank
                FROM employees)
SELECT d.dept, r.emp_id, r.name, r.salary
FROM dept d
LEFT JOIN ranked r ON d.dept = r.dept AND r.d_rank= 2 -- we are retaining all the depts despite having NULL result
-- (or) LEFT JOIN ranked r ON d.dept = r.dept 
--      WHERE r.d_rank= 2 or r.d_rank OR r.d_rank IS NULL   -- Show dept rows where d_rank = 2 OR where there is no match (r.d_rank IS NULL):
ORDER BY d_rank;

-- Explanation:
/*
To preserve NULLs, either:
✔️ Put the filter inside the ON clause (so unmatched left rows remain), or
✔️ Allow IS NULL in the WHERE (explicitly keep unmatched rows).

PATTERNS AND EDGE CASES:
Pattern: 
For “Nth distinct value per group” use:
1. If all the employees with the NTH value (even with ties)--> use DENSE_RANK() and then left join 
2. If interviewer expects one deterministic row (even among ties) → ROW_NUMBER() with a tie-breaker.

WHEN TO USE LEFT JOIN: 
If you need to show groups (departments) even when no matching metric exists, 
✔️ build the full group list and 
✔️ LEFT JOIN the metric.

-- comment
Why NTH_VALUE “not working”? 
	NTH_VALUE(expr, N) returns the Nth value in the window frame relative to each row. 
	It’s not the natural choice when you want row(s) whose salary equals the department's Nth-highest distinct salary.

-- SUMMARY:
- Mistake: Tried using NTH_VALUE without understanding frame semantics.
- Fix: Use DENSE_RANK()/ROW_NUMBER() depending on tie semantics (DENSE_RANK when we want distinct salary ranks).
- Pattern: For "Nth highest value per group" use ranking (DENSE_RANK/ROW_NUMBER) .

-- ======================================================================================
-- Q3 
DROP TABLE IF EXISTS daily_sales;

CREATE TABLE daily_sales (
  sale_date DATE PRIMARY KEY,
  total_amount DECIMAL(10,2)
);

INSERT INTO daily_sales VALUES
('2025-10-01', 100.00),
('2025-10-02', 120.00),
('2025-10-03', 50.00),
('2025-10-04', 200.00),
('2025-10-05', 0.00),
('2025-10-06', 300.00),
('2025-10-07', 80.00),
('2025-10-08', 90.00);

/* Task: For each sale_date, compute:
✔️running_total (cumulative sum from the earliest date up to that date)
✔️moving_7day_total (sum of total_amount over the current date and previous 6 days — use a frame like ROWS BETWEEN 6 PRECEDING AND CURRENT ROW or RANGE depending on gaps)

Expected output (sample rows shown):
2025-10-01 | running_total=100.00 | moving_7day_total=100.00
2025-10-02 | running_total=220.00 | moving_7day_total=220.00
...
2025-10-08 | running_total=940.00 | moving_7day_total=840.00
*/
-- solution:
SELECT * FROM daily_sales;
-- for each sale_date, --> 
-- running total--> aggregate +window frame --> SUM(amount), ROWS between...
-- moving 7-day total--> so aggregate + window frame--> SUM(amount),...RANGE BETWEEN INTERVAL 6 day and current row
-- if the dates are repeated, have to group by sale_date to find the total amount per date--> then apply window function

SELECT sale_date,
		SUM(amount) OVER(ORDER BY sale_date

SELECT
  sale_date,
  SUM(total_amount) OVER (ORDER BY sale_date
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
  SUM(total_amount) OVER (ORDER BY sale_date
                          RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW) AS moving_7row_total
FROM daily_sales
ORDER BY sale_date;

/*

(If your MySQL supports RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW you may use that; correlated subquery always works and is explicit.)

Doubts answered
ROWS vs RANGE: 
ROWS counts rows (e.g., last 6 rows), 
RANGE uses logical value difference (e.g., last 6 days). 
If dates have gaps and you need 7-calendar-day window use RANGE with INTERVAL or the correlated subquery.

Which to use in interviews? 
Explain requirements: if problem statement says “last 7 days” use date-based approach; if it says “last 7 records” ROWS is fine.

Q3: Misused ROWS vs intended calendar-range.
- Mistake: Assumed ROWS=7-days; ROWS counts rows not calendar days.
- Fix: If requirement is "last N calendar days", use RANGE with INTERVAL (if supported) or a correlated subquery/join.
- Pattern: For time-window aggregations be explicit: rows-based vs time-interval-based.
*/

-- =====================================================================================
-- Q4
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS orders_w2;

CREATE TABLE users (
  user_id INT PRIMARY KEY,
  username VARCHAR(50)
);

INSERT INTO users VALUES (1,'u_alice'),(2,'u_bob'),(3,'u_carol');

CREATE TABLE orders_w2 (
  order_id INT PRIMARY KEY,
  user_id INT,
  order_ts DATETIME,
  amount DECIMAL(9,2),
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO orders_w2 VALUES
(1,1,'2025-10-01 10:00:00',100.00),
(2,1,'2025-10-07 09:00:00',40.00),
(3,1,'2025-10-10 12:00:00',60.00),
(4,2,'2025-10-02 11:00:00',120.00),
(5,2,'2025-10-09 12:00:00',80.00),
(6,3,'2025-09-25 09:00:00',30.00);

/* Task: Produce for each user_id and each week (ISO week or YEAR-WEEK(order_ts,1) — specify which) the total orders week_total and
 the pct_change_from_prev_week using LAG() over weeks. 
 Include users/weeks with zero orders (LEFT JOIN calendar/weeks or generate weeks) — but for
 this timed exercise, it's OK to return weeks present in data. Order results by user_id, week.

Expected sample output:
user_id | week      | week_total | prev_week_total | pct_change
1       | 2025-W40  | 140.00     | 100.00          | 40.0%
1       | 2025-W41  | 60.00      | 140.00          | -57.14%
2       | 2025-W40  | 120.00     | NULL            | NULL
2       | 2025-W41  | 80.00      | 120.00          | -33.33%
3       | 2025-W39  | 30.00      | NULL            | NULL

*/
-- solution:
SELECT * FROM users;
SELECT* FROM orders_w2;

-- partition by user_id, then week,--> calc sum() 
-- previous week total --> lag(), pct change--?week_total 

WITH total AS (SELECT *,
					SUM(amount) OVER(PARTITION BY user_id, yearweek(order_ts) ORDER BY user_id, yearweek(order_ts)) AS week_total
             FROM orders_w2),
	previous_week_total AS (SELECT*,
								LAG(week_total) OVER() AS prev_week_total
							FROM total)
SELECT u.*,p.order_ts, p.week_total, p.prev_week_total, p.prev_week_total- p.week_total AS pct_change
FROM previous_week_total p
LEFT JOIN users u USING (user_id)
;

-- how can i extract year and week only or month and date only etc, from the datetime column or date column?
-- why can't i get one week as single group here?
-- how pct_cahnge can be calculated here?
-- your solution didnt give the user name so there is no need to left join here right?
-- how does your solution has no null in the first row where lag() is used as such in prev_week_total?
	

-- ==========================================================================================
-- Q5
DROP TABLE IF EXISTS purchases;

CREATE TABLE purchases (
  purchase_id INT PRIMARY KEY,
  user_id INT,
  purchase_date DATE,
  amount DECIMAL(8,2)
);

INSERT INTO purchases VALUES
(1,1,'2025-10-01',100.00),
(2,1,'2025-10-02',50.00),
(3,1,'2025-10-03',75.00),
(4,1,'2025-10-05',20.00),
(5,2,'2025-10-01',10.00),
(6,2,'2025-10-02',20.00),
(7,3,'2025-10-10',30.00);

/* Task: For each user, compute their longest consecutive-day purchase streak 
(i.e., max number of days where purchases happened on consecutive calendar days). 
Then return top users ordered by streak length desc. Use LAG() to identify breaks, or 
the date - row_number() trick (gap-and-island).

Expected sample output:
user_id | longest_streak
1       | 3
2       | 2
3       | 1
*/
-- solution
SELECT * FROM users;
SELECT * FROM purchases;
-- per user, --> longest consecutive- day purchase streak--> max no of days of purchase in consecutive manner--> calc continuous days of purchase for a user
-- so count purchase dates if they are continuous as length for a user
-- rank users from highest length to lowest 

-- how to get the condition--> 
-- first find diff -->current date- previous date 
-- if diff <=1 then sum(diff) as length
-- dense_rank() based on length desc 

WITH CTE AS (SELECT *,
			 STR_TO_DATE(purchase_date, "%Y%m%d")- (LAG(STR_TO_DATE(purchase_date, "%Y%m%d"), 1, 0) OVER(PARTITION BY user_id ORDER BY purchase_date)) AS diff_length
             FROM purchases),
	 length AS (SELECT *,
				CASE WHEN diff_length <= 1 THEN SUM(diff_length) OVER() 
					ELSE NULL 
                    END AS length
				FROM CTE)
SELECT user_id,length, DENSE_RANK() OVER(ORDER BY length DESC) AS D_RANK
FROM length
ORDER BY D_RANK;
	 
			  
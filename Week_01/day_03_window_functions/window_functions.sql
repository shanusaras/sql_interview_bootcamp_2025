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
-- per month( extract month), per cust_id--> total amount 
-- rank() in descending order of amount
-- get all column names

-- solution
WITH CTE AS (SELECT *,
					SUM(amount) OVER(PARTITION BY MONTH(order_date), customer_id ORDER BY amount DESC) AS monthly_total
			FROM orders_w1)
            
SELECT c1.order_date, c1.customer_id, c2.name, c1.monthly_total,  
		RANK() OVER() AS monthly_rank
FROM CTE c1
JOIN customers_w1 c2 USING (customer_id);

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

Expected output (sample data) — columns: dept, emp_id, name, salary
Engineering | 2 | Ravi   | 95000
Sales       | 4 | Sameer | 90000
Sales       | 6 | Karan  | 90000
HR          | (no row) -- if no 2nd highest exists
*/
-- SOLUTION 
SELECT * FROM employees;
-- per dept, nth highest salary( have to return the value, not the rank) along with employees

WITH CTE AS (SELECT *, 
					-- NTH_VALUE(salary, 2) over(PARTITION BY dept ORDER  BY salary DESC  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS n_value
												
                    DENSE_RANK() OVER(PARTITION BY dept ORDER BY salary DESC) AS row_num
			 FROM employees)
SELECT dept, emp_id, name, salary
FROM CTE
WHERE row_num= 2;

-- comment
-- why n_th value is not working?
-- why null cant be specified for HR dept in partition
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

SELECT sale_date,
		SUM(total_amount) OVER(ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
        SUM(total_amount) OVER(ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_7day_total
FROM daily_sales;

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

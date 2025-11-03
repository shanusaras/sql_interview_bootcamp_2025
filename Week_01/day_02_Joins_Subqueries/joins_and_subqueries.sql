-- Drop if exist
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Customers;

-- Customers table
CREATE TABLE Customers (
  customer_id INT PRIMARY KEY,
  customer_name VARCHAR(80),
  email VARCHAR(120),
  city VARCHAR(50),
  signup_date DATE
);

INSERT INTO Customers (customer_id, customer_name, email, city, signup_date) VALUES
(1, 'Alice Rao', 'alice@example.com', 'Bangalore', '2023-01-10'),
(2, 'Bob Kumar', 'bob@example.com', 'Chennai', '2023-02-15'),
(3, 'Charlie Singh', 'charlie@example.com', 'Hyderabad', '2023-03-20'),
(4, 'David Iyer', 'david@example.com', 'Pune', '2023-04-01'),
(5, 'Eva Roy', 'eva@example.com', 'Delhi', '2023-05-05'),
(6, 'Faisal Khan', 'faisal@example.com', 'Mumbai', '2023-06-01');

-- Orders table
CREATE TABLE Orders (
  order_id INT PRIMARY KEY,
  customer_id INT,
  order_date DATE,
  amount DECIMAL(10,2),
  status VARCHAR(20),
  FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

INSERT INTO Orders (order_id, customer_id, order_date, amount, status) VALUES
(101, 1, '2023-06-01', 500.00, 'Completed'),
(102, 1, '2023-06-05', 300.00, 'Completed'),
(103, 2, '2023-07-10', 400.00, 'Completed'),
(104, 3, '2023-08-12', 250.00, 'Pending'),
(105, 4, '2023-09-01', 800.00, 'Completed'),
(106, 2, '2023-09-20', 150.00, 'Cancelled'),
(107, NULL, '2023-10-01', 120.00, 'Completed'); -- order with missing customer to test edge cases

-- Payments table
CREATE TABLE Payments (
  payment_id INT PRIMARY KEY,
  order_id INT,
  payment_date DATE,
  payment_method VARCHAR(30),
  payment_status VARCHAR(20),
  FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

INSERT INTO Payments (payment_id, order_id, payment_date, payment_method, payment_status) VALUES
(1001, 101, '2023-06-02', 'UPI', 'Succeeded'),
(1002, 102, '2023-06-06', 'Credit Card', 'Succeeded'),
(1003, 103, '2023-07-11', 'UPI', 'Failed'),
(1004, 105, '2023-09-02', 'Debit Card', 'Succeeded'),
(1005, 104, '2023-08-13', 'Wallet', 'Pending');

-- ====================================================================================================
-- Q1: Find all customers who have placed at least one order.
-- Q2: List all customers and their total order amount. Include customers with zero orders (show 0).
-- Q3: Find orders that do not have a successful payment.
-- Q4: Find customers who haven’t placed any orders yet.
-- Q5: Find customers whose average order amount is greater than the overall average order amount across all customers.
 -- =====================================================================================================================
 SELECT * FROM Customers ;
 SELECT * FROM orders;
 SELECT * FROM payments;
 -- --------------------------------------------------------------------------------------
 -- Q1: Find all customers who have placed at least one order.
 -- customers with atleast one order
 SELECT DISTINCT c.customer_id, c.customer_name, c.email, c.city, c.signup_date
 FROM customers c
 JOIN orders USING (customer_id)
 WHERE EXISTS (SELECT *
				FROM orders o
				WHERE o.customer_id= c.customer_id); 


-- The above solution is redundant--> 
/* 
- JOIN orders already limits customers to those with at least one order.
- The EXISTS subquery duplicates the same check.
- DISTINCT is needed only because a customer with many orders would otherwise appear multiple times 
— better to deduplicate by grouping or use DISTINCT with simpler join.
- The order status should be "completed" for a successful order placement so it is also a filter condition.

-- ✅ Optimized version:
-- Option A: (simple and readable)
*/
SELECT DISTINCT c.customer_id, c.customer_name, c.email, c.city, c.signup_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status= "Completed";

-- Option B: (EXISTS version) Recommended for clear intent avoids duplicates
SELECT c.customer_id, c.customer_name, c.email, c.city, c.signup_date
FROM customers c
WHERE EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.customer_id = c.customer_id AND o.status= "Completed"
);

/* Tips:
1. Use JOIN --> when you need order details with each customer row.
2. Use EXISTS --> when you only need to test the presence (EXISTS avoid duplicates internally).
3. DISTINCT--> can hide design issues--> prefer controlling duplicates via the correct pattern.
*/
-- tip: If payment also needed to be completed, we can add that to the EXISTS sub-query
-- filter like the following: (clarify the question)
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE o.customer_id = c.customer_id
      AND o.status = 'Completed'
      AND p.payment_status = 'Succeeded'
);
-- -------------------------------------------------------------------------------------------------------

-- Q2: List all customers and their total order amount. Include customers with zero orders (show 0).
-- List all customers and their total order amount. Include customers with zero orders (show 0).
-- left join customers + orders, 
-- total order amount per customer--> group by id in orders table 
-- filter if amount is null add 0 ,else amount

WITH total_order AS (SELECT customer_id, SUM(amount) AS total_amount
					 FROM orders
                     GROUP BY customer_id)
SELECT c.customer_id, c.customer_name, CASE WHEN t.total_amount IS NULL THEN 0
											ELSE t.total_amount
                                            END AS total_order_amount
FROM customers c
LEFT JOIN total_order t ON c.customer_id= t.customer_id;

-- optimal version: (LET JOIN + GROUP BY , COALESCE)
SELECT c.customer_id, c.customer_name, COALESCE(SUM(o.amount), 0) AS order_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id= o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY order_amount DESC;

-- ----------------------------------------------------------------------------------------------------------------------------

-- Q3: Find orders that do not have a successful payment.
SELECT * FROM orders;
SELECT * FROM payments;

-- orders from table --which are not in payments table + payment_status except succeeded in payments table
SELECT o.order_id, p.payment_status
FROM orders o
LEFT JOIN payments p USING (order_id) 
WHERE p.payment_status NOT LIKE "Succeeded";

/* Explanation:
❌ This excludes orders that have no payment record 
because p.payment_status will be NULL and p.payment_status NOT LIKE 'Succeeded' 
evaluates to UNKNOWN (filtered out).

-- Option A optimal version: NOT EXISTS (ideal for removing orders with null payments also) */
SELECT o.order_id, o.customer_id, o.order_date, o.amount
FROM orders o
WHERE NOT EXISTS (SELECT 1
				  FROM payments p 
                  WHERE o.order_id= p.order_id
                        AND p.payment_status= "Succeeded");

/* Explanation:
This returns orders that don't have any successful payment (includes no payments and payments that
never succeeded)

-- Option B: optimal version */
SELECT o.order_id, o.customer_id, o.amount, o.order_date, p.payment_status
FROM orders o
LEFT JOIN payments p USING (order_id) 
WHERE p.payment_status IS NULL OR p.payment_status <> "Succeeded";

/* Pattern / Trick:
- For “no matching successful child record,” use NOT EXISTS 
(handles multiple payments and NULLs properly).
- Avoid NOT LIKE 'Succeeded' alone — be explicit: IS NULL OR <> 'Succeeded'. */

-- --------------------------------------------------------------------------------------

--  Q4: Find customers who haven’t placed any orders yet.
SELECT c.customer_id, c.customer_name, c.signup_date
FROM customers c
WHERE NOT EXISTS (SELECT 1
				  FROM orders o
                  WHERE o.customer_id= c.customer_id);
                  

-- NOTE: Pattern / Trick:
-- NOT EXISTS is NULL-safe and the go-to anti-join pattern.

-- ---------------------------------------------------------------------------------------
-- -- Q5: Find customers whose average order amount is greater than the overall average order amount across all customers.
-- avg amount per customer
-- avg (avg amount per customer)
-- 1>2

SELECT * FROM orders;

WITH avg_amount AS (SELECT customer_id, AVG(amount) AS avg_amount
					FROM orders
                    GROUP BY customer_id),
                    
		total_avg AS (SELECT AVG(avg_amount) AS total_avg
						   FROM avg_amount)
SELECT c.customer_id,c.customer_name, a.avg_amount, t.total_avg
FROM avg_amount a
CROSS JOIN total_avg t  -- can also use JOIN + ON filter condition
JOIN customers c ON a.customer_id= c.customer_id
WHERE a.avg_amount> t.total_avg
ORDER BY a.avg_amount DESC;

/* Edge-cases to note (mention in interview):
- Customers with no orders are excluded (AVG undefined). 
If interviewer wants them included with avg=0, you must handle that explicitly.

- Using NOT EXISTS for scenarios with nulls/sparse data is safer.

Pattern / Trick::
- CTE for per-entity aggregation → compute global aggregate from that CTE → compare via CROSS JOIN or subquery.
- This is the canonical “compare group metric to global metric” pattern.

-- -------------------------*********---------------------------------------------------------------





 

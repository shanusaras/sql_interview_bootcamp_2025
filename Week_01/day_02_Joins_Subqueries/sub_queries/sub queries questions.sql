/*
1) Find the employees who earn more than the average salary earned by all employees
2) Find the employees who earn the highest salary in each department.
3) Find department who do not have any employees
4) Find the employees in each department who earn more than the average salary in that department.
5)  Find stores whose sales were better than the average sales accross all stores
6) Fetch all employee details and add remarks to those employees who earn more than the average pay.
7) Find Departments with Above-Average Total Salaries
8) Insert data to employee history table. Make sure not insert duplicate records.
9)  Give 10% increment to all employees in Bangalore location based on the maximum
salary earned by an emp in each dept. Only consider employees in employee_history table.
10) Delete all departments who do not have any employees.
*/

-- ===========================================================================================

USE SUB_QUERY;
SELECT * FROM sales;
SELECT * FROM department;
SELECT * FROM employee;
SELECT * FROM employee_history; 

-- solutions:
-- 1) using CROSS JOIN + WHERE filter ✅
WITH totals AS (SELECT dept_name, SUM(salary) AS tot_sal
				FROM employee
                GROUP BY dept_name),
	average AS (SELECT AVG(tot_sal) AS avg_sal
				FROM totals)

SELECT *
FROM totals t
CROSS JOIN average a
WHERE t.tot_sal> a.avg_sal;

-- using sub-query:
SELECT *
FROM employee e
WHERE e.salary> (SELECT AVG(salary) as avg_salary FROM employee)
ORDER BY e.salary DESC;

-- using JOIN
SELECT *
FROM employee e
JOIN (SELECT avg(salary) a_sal
	  FROM employee) m
ON e.salary> m.a_sal
ORDER BY e.salary;

-- 2) Find the employees who earn the highest salary in each department.
SELECT e.*, m.m_sal
FROM employee e
JOIN (SELECT dept_name, max(salary) m_sal
	  FROM employee
      GROUP BY dept_name) m
ON e.DEPT_NAME= m.dept_name
WHERE e.salary = m.m_sal
ORDER BY e.dept_name, e.salary;

-- Used CTE + JOIN
WITH max_salaries AS (SELECT dept_name, MAX(salary) as max_salary
					  FROM employee e
					  GROUP BY dept_name)
SELECT *
FROM employee e
JOIN max_salaries m ON e.dept_name = m.dept_name
WHERE e.salary = m.max_salary
ORDER BY e.dept_name, e.salary;

-- 3) Find department who do not have any employees
SELECT dept_name
FROM department
WHERE dept_name NOT IN (SELECT DISTINCT dept_name
						FROM EMPLOYEE);

-- RECOMMENEDED APPROACH ✅
SELECT *
FROM department d
WHERE NOT EXISTS (SELECT *
					FROM employee e
                    WHERE e.dept_name= d.dept_name);
                    
                        
-- 4) Find the employees in each department who earn more than the average salary in that department.

SELECT e.*, a.average_salary
FROM employee e
JOIN (SELECT dept_name, avg(salary) average_salary
	  FROM employee
      GROUP BY dept_name) a
ON e.dept_name= a.dept_name
WHERE e.salary > a.average_salary
ORDER BY e.dept_name, e.salary;

-- use CTE + JOIN
WITH average AS (SELECT dept_name, AVG(salary) as avg_sal
				 FROM employee
			     GROUP BY dept_name)
SELECT *
FROM employee e
JOIN average a ON e.dept_name= a.dept_name
WHERE e.salary > a.avg_sal
ORDER BY e.dept_name, e.salary;


-- 5)  Find stores whose sales were better than the average sales accross all stores

SELECT * FROM sales;

WITH total_sales AS (SELECT store_name, sum(price) total_price
					 FROM sales
                     GROUP BY store_name)
SELECT *
FROM total_sales t
JOIN (SELECT AVG(total_price) average_price FROM total_sales) a
ON t.total_price > a.average_price
ORDER BY t.store_name;

-- CTE + CROSS JOIN and filter 
-- (for comparing single aggregate value with group aggregates)
-- total sales per store
-- avg(total sales)

WITH total AS (SELECT store_id, store_name, SUM(price) AS tot_sales
				FROM sales
                GROUP BY store_id, store_name),
	average AS (SELECT AVG(tot_sales) AS avg_sales
				FROM total)
SELECT *
FROM total t
CROSS JOIN average a
WHERE t.tot_sales > a.avg_sales;

-- 6) Fetch all employee details and add remarks to those employees who earn more than the average pay.

SELECT *, (CASE WHEN e.salary> a.average_salary
			   THEN 'higher than the average'
		   END ) remarks
FROM employee e
LEFT JOIN (SELECT avg(salary) average_salary
			FROM employee) a
ON e.salary> a.average_salary
ORDER BY remarks DESC;

-- RECOMMENDED: CROSS JOIN, CASE statement
WITH average AS (SELECT AVG(salary) as avg_sal 
				 FROM employee)
                 
SELECT e.*, CASE WHEN e.salary > a.avg_sal THEN 'above average'
				 ELSE null
				END AS remarks
FROM employee e
CROSS JOIN average a -- since here one aggregate value is compared with every row
ORDER BY 1;

-- 7) Find Departments with Above-Average Total Salaries
WITH total_salaries AS (SELECT dept_name, sum(salary) total_salary
						FROM employee
                        GROUP BY dept_name)
SELECT *
FROM total_salaries t
JOIN (SELECT avg(total_salary) average FROM total_salaries) a
ON t.total_salary> a.average
ORDER BY t.total_salary;


-- Recommended : CTE + CROSS JOIN, filter
WITH totals AS (SELECT dept_name, SUM(salary) AS tot_sal
				FROM employee
                GROUP BY dept_name),
	average AS (SELECT AVG(tot_sal) AS avg_sal
				FROM totals)

SELECT *
FROM totals t
CROSS JOIN average a
WHERE t.tot_sal> a.avg_sal;

-- 8) Insert data to employee history table. Make sure not insert duplicate records.
SELECT * FROM employee_history;

INSERT INTO employee_history
SELECT e.emp_id, e.emp_name, e.dept_name, e.salary, d.location
FROM employee e
JOIN department d ON e.dept_name = d.dept_name
WHERE NOT EXISTS (SELECT emp_id 
					 FROM employee_history eh
                     WHERE e.emp_id= eh.emp_id);
                     
-- 9)  Give 10% increment to all employees in Bangalore location based on the maximum
-- salary earned by an emp in each dept. Only consider employees in employee_history table.
WITH max_sal AS (SELECT dept_name, max(salary) max_salary
				 FROM employee_history
                 GROUP BY dept_name)
UPDATE employee e
JOIN department d ON e.dept_name= d.dept_name
JOIN max_sal m ON m.dept_name= e.dept_name
SET e.salary= e.salary + 0.1*m.max_salary
WHERE d.location= 'Bangalore'
AND e.emp_id IN (SELECT emp_id 
					FROM employee_history);

-- 10) Delete all departments who do not have any employees.
DELETE FROM department
WHERE dept_name NOT IN (SELECT DISTINCT dept_name 
						FROM employee);
                        
-- RECOMMENDED APPROACH: use NOT EXISTS to check boolean answer like yes/ no
DELETE FROM department d
WHERE NOT EXISTS (SELECT *
				  FROM employee e
                  WHERE e.dept_name= d.dept_name);
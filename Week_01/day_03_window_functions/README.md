## DAY 3: Window functions (23rd Oct)

## Topics:
-  ROW_NUMBER(), RANK(), DENSE_RANK()
-  SUM(), COUNT(), AVG(), MIN(), MAX() with OVER() clause
-  LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE(), NTH_VALUE(), NTILE(), CUME_DIST(), PERCENT_RANK()
-  frame clause 


---


## Concepts revision:
- **window functions**: 
  - Functions that perform calcs across a set of rows(window) that are related to the current row, without collapsing the rows into single output.
- **NOTE**:
  - Operates over a window of rows--> defined by OVER()--> can be all the rows or defined by partition and orderings.
  - Non-collapsing
  - ***use cases***: Ranking, running totals, moving averages, cumulative statistics etc

- **RANKING FUNCTIONS**:
  - `ROW_NUMBER()`:
    - assigns unique sequential integer to each row within the window/ partition of the result set
    - Purpose: To enumerate rows/ rank them in particular order
  - `RANK()` and `DENSE_RANK()`:
    - assigns rankings to rows within the partition of the result set.
    - ***key difference***: For duplicate records (records with same values)
      - RANK() allows gaps in rankings (skips rank in case of ties)
      - DENSE_RANK() don't allows gaps in rankings (assigns consecutive rankings even when ties occur)

- **ANALYTICAL FUNCTIONS**:
  - `LAG()`:
    - Access data from the previous row in the result set.
    - Purpose: For comparing value across rows.
    - ***syntax***: 
    - ```sql
      LAG(column, offset, default) OVER(PATITION BY... ORDER BY ...)
      ```
  - `LEAD()`:
      - access data from the susequent rows
  - ***purpose of LAG() and LEAD()***:
      - To compare differences between adjacent rows / generating trends in a sequential dataset.
  - `FIRST_VALUE()`:
    - to get the first occurrence within a particular window/ first occurrence of a value in a sequence.
    - ***examples***: earliest date, first transaction, highest rank
  - `LAST_VALUE()`:
    - to get the last occurrence
  - `NTH_VALUE()`:
    - to get the nth value 
  - ***NOTE***: LAST_VALUE() and NTH_VALUE() should be defined by the frame clasue within the OVER() clause.
  - **Frame clause**:
    - allows to have precise control over the range of rows considered by a window function.
    - can define subset of partition in OVER() --> to specify the set of row to perform calc.
    - ***syntax***:
       - ```sql
         <window_function> OVER(PATITION BY ...ORDER BY ...
                                             RANGE / ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW/UNBOUNDED FOLLOWING)
         ```
    - ***default frame clause***:
      - ```SQL
        OVER(....RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        ```
    - ***For `LAST_VALUE() and NTH_VALUE()`, must frame clause to define (but be cautious with runnning totals, incase of duplicate records)***:
       - ```sql
         OVER(...RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
         ```
    - **Difference between RANGE and ROWS in frame clause**:
      - **ROWS**:
        - Specifies a frame by a no of rows relative to the current row.
        - For duplicate records, it will consider only the physical current position of the row(i.e current row) within the window frame.
        - ***example***: running total counts each row separately
      - **RANGE**:
        - Specifies a frame based on the logic range of values relative to the current row 
        - For duplicate records, it considers all the rows based on the logical relation.
        - ***example***: running total treats duplicate dates as one step
      - **NOTE**
        - ROWS--> by row count; RANGE--> moves by ordered value.
        - If duplicates exist in the ORDER BY column, RANGE treats them as one group — ROWS doesn’t.
      - **example question**:
        - | date       | sales |
          | ---------- | ----- |
          | 2024-01-01 | 100   |
          | 2024-01-02 | 200   |
          | 2024-01-02 | 200   |
          | 2024-01-03 | 300   |
          
         - **Query_01: ROWS**
           ```sql
           SUM(sales) OVER (ORDER BY date 
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
           ```
           ➡ running total counts each row separately
           - Result:-
             - | date | running_total     |
               | ---- | ----------------- |
               | 01   | 100               |
               | 02   | 300 (100+200)     |
               | 02   | 500 (100+200+200) |
               | 03   | 800               |


         - **Query_02: RANGE**
           ```sql
           SUM(sales) OVER (ORDER BY date 
                           RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
           ```
           ➡ running total treats duplicate dates as one step
           - Result:-
             - | date | running_total     |
               | ---- | ----------------- |
               | 01   | 100               |
               | 02   | 500 (includes both 200s) |
               | 02   | 500               |
               | 03   | 800               |
  - We can use ***alias** for window frame
    - example:-
      - ```sql
        SELECT *,
              FIRST_VALUE() OVER w AS first,
        FROM product
        WINDOW w AS (PARITION BY ... ORDER BY...RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED       FOLLOWING)
        ```
  - `NTILE()`:
    - to distribute rows into specified no of roughly equal groups/ buckets/ tiles.
    - assigns each row--> a group number and distributes rows evenly as much as possible.
    - ***what about extra rows?***
       - Further assigns to the first few groups.
       - Hence the first few groups might have one more than the later ones.
    - ***use cases***:
      - To segment data into quantiles, percentiles
      - Equal grouping for data analysis: e.g., targeted marketing based on spending
      - visualizing distribution: eg., to create histograms/ other visualizations that require data segmentation into equal intervals.

  - `CUME_DIST()`:
    - Range(>0, 1)
    - % (or) proportion of rows having values <= current row's value.
    - formula:-
      - (no.of rows <= current row) / total no of rows
    - **NOTE**:
      - It accumulates distribution as it moves down the sorted list of rows.
      - For tie values (rows with same values): --> same cumulative distribution value.
    - **use cases**:
      - percentile calc
      - No of students scored below a 'certain' percentile/ grade
      - % of transactions below a 'certain' amount
      - statistical reports/ dashboards --> to analyze data distributions.

  - `PERCENT_RANK()`:
    - Range(0, 1)
    - Relative rank of current row, as percentage of total no of rows in the result set.
    - formula:-
      - (rank/ current row -1)/ (total no of rows -1)
    - **NOTE**:
      - compares the position od data point relative to others in a normalized way.
      - For ties--> same percent rank
    - **use cases**:
      - grading system--> based on percentile ranks instead of absolute scores.
      - performance reviews--> Ranking employees relative to one another.
      - market analysis--> comparing products/ services to determine where they stand relative to competitors.

---


## Patterns to remember:
- **3 main categories**:
  - | Category                          | Purpose                                                        | Common Functions                                                                     | Example Use                                       |
    | --------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------- |
    | **1. Ranking Functions**          | Assign a rank, position, or distribution to each row           | `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`, `PERCENT_RANK()`, `CUME_DIST()` | “Find top 3 products by sales per category”       |
    | **2. Aggregate Window Functions** | Perform aggregate calculations over a window but keep each row | `SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()` (when used with `OVER()`)              | “Show running total of revenue per region”        |
    | **3. Value / Offset Functions**   | Compare or access values from other rows in the window         | `LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()`                                   | “Compare current month’s sales to previous month” |


- **extended categories**
  - | Type                           | Function                                          | What It Does                                             |
    | ------------------------------ | ------------------------------------------------- | -------------------------------------------------------- |
    | **Statistical / Analytical**   | `NTH_VALUE()`, `STDDEV()`, `VARIANCE()`, `CORR()` | Advanced analytics, percentiles, and variability         |
    | **Cumulative / Moving Window** | using `ROWS BETWEEN` or `RANGE BETWEEN` clauses   | Controls frame for running totals, moving averages, etc. |


- **Categorization by Use Case Mental Model**
  - | Goal                            | Category                 | Example Function                          |
    | ------------------------------- | ------------------------ | ----------------------------------------- |
    | Ranking / Percentiles           | Ranking                  | `RANK()`, `PERCENT_RANK()`, `CUME_DIST()` |
    | Trends or Period-over-Period    | Value / Offset           | `LAG()`, `LEAD()`                         |
    | Running totals / Moving average | Aggregate + Window frame | `SUM() OVER (ORDER BY ...)`               |
    | Statistical analysis            | Statistical              | `STDDEV()`, `NTH_VALUE()`                 |

---




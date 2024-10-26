SELECT * FROM df_orders;

-- 1. Find top 10 highest revenue generating products

SELECT 
	product_id, 
	SUM(sale_price) as sales
FROM df_orders
GROUP BY product_id
ORDER BY sales desc
LIMIT 10;

-- 2. Find top 5 highest selling products in each region

WITH cte AS 
(SELECT 
	region, 
	product_id,
	SUM(sale_price) AS sales
FROM df_orders
GROUP BY region, product_id)

SELECT * FROM (
SELECT * , 
ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales DESC) AS rn
FROM cte) A 
WHERE rn <= 5;

-- 3. Find month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023

WITH cte AS (
    SELECT EXTRACT(YEAR FROM order_date) AS order_year, 
           EXTRACT(MONTH FROM order_date) AS order_month, 
           SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY order_year, order_month
)

SELECT order_month,
       SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
       SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM cte
GROUP BY order_month
ORDER BY order_month;

-- 4. For each category which month had highest sales

WITH cte AS
(SELECT 
	category, 
	to_char(order_date, 'YYYYMM') AS order_year_month, 
	SUM(sale_price) AS sales
FROM df_orders
GROUP BY category, order_year_month)
-- ORDER BY category, order_year_month;
SELECT * FROM
(SELECT *, 
row_number() OVER(PARTITION BY category ORDER BY sales DESC) AS ranking 
FROM cte) a
WHERE ranking = 1;


-- 5. Which sub category has highest growth by profit in 2023 compare to 2022

WITH cte AS (
    SELECT
		sub_category,
		EXTRACT(YEAR FROM order_date) AS order_year,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY sub_category, order_year
)

, cte2 AS
(SELECT sub_category,
       SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
       SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM cte
GROUP BY sub_category)
-- ORDER BY sub_category;

SELECT *,
	(sales_2023 - sales_2022) * 100/ sales_2022 AS highest_growth
FROM cte2
ORDER BY highest_growth DESC
LIMIT 1;
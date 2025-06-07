USE Common_database;

SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'orders_processed' AND TABLE_SCHEMA = 'dbo';


UPDATE dbo.orders_processed
SET discount = ROUND(discount, 2);

UPDATE dbo.orders_processed
SET sale_price = ROUND(sale_price, 2);

UPDATE dbo.orders_processed
SET profit = ROUND(profit, 2);

SELECT TOP 10 * FROM dbo.orders_processed;

-- TOP 10 PRODUCTS WITH HIGHEST SALES.
SELECT TOP 10 product_id, SUM(sale_price) AS sales
FROM dbo.orders_processed
GROUP BY product_id
ORDER BY sales DESC;

-- TOP 5 PRODUCTS HIGHEST SELLING PRODUCTS IN EACH REGION.
WITH highest_selling_products_by_region AS (
	SELECT 
		region, 
		product_id, 
		SUM(sale_price) AS sales
	FROM dbo.orders_processed
	GROUP BY region, product_id
)
SELECT * 
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales DESC) AS sales_ranking
	FROM highest_selling_products_by_region
) assigned_ranking
WHERE sales_ranking <= 5;

-- MONTH OVER MONTH GROWTH COMPARISON FOR 2022 AND 2023 SALES. EX JAN 2022 VS JAN 2023. 
WITH month_growth_comparison AS (
	SELECT 
		YEAR(order_date) AS order_year,
		MONTH(order_date) AS order_month,
		ROUND(SUM(sale_price), 2) AS sales
	FROM dbo.orders_processed
	GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
	order_month,
	SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0.0 END) AS '2022_sales',
	SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0.0 END) AS '2023_sales'
FROM month_growth_comparison
GROUP BY order_month
ORDER BY order_month;

-- MONTH COMPARISION OF SALES BY CATEGORIES.
WITH category_cte AS (
	SELECT
		category,
		MONTH(order_date) AS order_month,
		FORMAT(order_date, 'MMM') AS order_month_format,
		ROUND(SUM(sale_price), 2) AS sales
	FROM dbo.orders_processed
	GROUP BY category, MONTH(order_date), FORMAT(order_date, 'MMM')
)
SELECT
	order_month_format,
	SUM(CASE WHEN category = 'Furniture' THEN sales ELSE 0 END) AS furniture_sales,
	SUM(CASE WHEN category = 'Office Supplies' THEN sales ELSE 0 END) AS office_supplies_sales,
	SUM(CASE WHEN category = 'Technology' THEN sales ELSE 0 END) AS technology_sales
FROM category_cte
GROUP BY order_month_format, order_month
ORDER BY order_month;

-- WHICH MONTH HAD HIGHEST SALES FOR EACH CATEGORY.
WITH subcategory_cte AS (
	SELECT
		category,
		FORMAT(order_date, 'yyyy-MM') AS order_year_month,
		SUM(sale_price) AS sales
	FROM dbo.orders_processed
	GROUP BY category, FORMAT(order_date, 'yyyy-MM')
)
SELECT *
FROM
(	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY category ORDER BY sales DESC) AS row_num
	FROM subcategory_cte
)	row_num1
WHERE row_num = 1;

-- WHICH SUM-CATEGORY HAS HIGHEST PROFIT COMPARED TO 2022 AND 2023.
WITH subcategory_cte AS (
	SELECT
		sub_category,
		YEAR(order_date) AS order_year,
		SUM(sale_price) AS sales
	FROM dbo.orders_processed
	GROUP BY sub_category, YEAR(order_date)
), yearwise_sales AS (
	SELECT
		sub_category,
		SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
		SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
	FROM subcategory_cte
	GROUP BY sub_category
)
SELECT *,
	CASE WHEN sales_2022 = 0 THEN 0
	ELSE ROUND((sales_2023 - sales_2022) * 100 / sales_2022, 2) END AS sales_difference
FROM yearwise_sales
ORDER BY ROUND((sales_2023 - sales_2022), 2) DESC;


-- COMPARISION OF SALES BY STATES BY YEAR 2022 & 2023.
WITH state_sales_cte AS (
	SELECT
		state,
		YEAR(order_date) AS order_year,
		SUM(sale_price) AS sales
	FROM dbo.orders_processed
	GROUP BY state, YEAR(order_date)
)
SELECT *,
	CASE WHEN sales_2022 = 0 THEN 0
	ELSE ROUND((sales_2023 - sales_2022) * 100 / sales_2022, 2) END AS sales_difference
FROM
(	SELECT
		state,
		SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
		SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
	FROM state_sales_cte
	GROUP BY state
) e;
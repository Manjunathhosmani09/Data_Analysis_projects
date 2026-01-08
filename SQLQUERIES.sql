USE cleaning_project;

-- Explore dataset
SELECT * FROM retail;
SELECT COUNT(*) AS record_count FROM retail;
SELECT COUNT(DISTINCT customer_id) AS customer_count FROM retail;
SELECT COUNT(DISTINCT category) AS category_count FROM retail;

-- Fix schema issues
DESC retail;
ALTER TABLE retail CHANGE COLUMN ï»¿transactions_id transaction_id INT;
ALTER TABLE retail MODIFY COLUMN sale_date DATE;
ALTER TABLE retail MODIFY COLUMN sale_time TIME;
ALTER TABLE retail RENAME COLUMN quantiy TO quantity;

-- Identify nulls
SELECT *
FROM retail
WHERE customer_id IS NULL OR customer_id = '' OR
      gender IS NULL OR gender = '' OR
      age IS NULL OR age = '' OR
      category IS NULL OR category = '' OR
      quantity IS NULL OR quantity = '' OR
      price_per_unit IS NULL OR price_per_unit = '' OR
      cogs IS NULL OR cogs = '' OR
      transaction_id IS NULL OR transaction_id = '' OR
      total_sale IS NULL OR total_sale = '';

-- Remove duplicates
CREATE TABLE retail_2 AS
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY transaction_id, sale_date, sale_time, customer_id, gender, age, category, quantity, price_per_unit, cogs, total_sale) AS dupe_rank
FROM retail;

DELETE FROM retail_2 WHERE dupe_rank > 1;

-- Electronics sales extremes
SELECT MAX(total_sale) AS max_sale, MIN(total_sale) AS min_sale
FROM retail_2
WHERE category = 'Electronics';

-- Average sales by category
SELECT category, AVG(total_sale) AS avg_sales
FROM retail_2
GROUP BY category
ORDER BY avg_sales DESC;

-- Total sales by category
SELECT category, SUM(total_sale) AS total_sales, COUNT(*) AS transactions
FROM retail_2
GROUP BY category
ORDER BY total_sales DESC;

-- Average age by category
SELECT category, AVG(age) AS avg_age
FROM retail_2
GROUP BY category;

-- Gender split by category
SELECT gender, category, COUNT(*) AS transactions
FROM retail_2
GROUP BY gender, category
ORDER BY category;

-- Top 5 customers by spend
SELECT customer_id, SUM(total_sale) AS total_spend
FROM retail_2
GROUP BY customer_id
ORDER BY total_spend DESC
LIMIT 5;

-- Customers buying across multiple categories
SELECT customer_id, COUNT(DISTINCT category) AS category_count
FROM retail_2
GROUP BY customer_id 
HAVING category_count > 2;

-- Orders by shift
WITH shifts AS (
    SELECT *,
           CASE
               WHEN HOUR(sale_time) <= 12 THEN 'Morning'
               WHEN HOUR(sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
               ELSE 'Evening'
           END AS shiftss
    FROM retail_2
)
SELECT shiftss, COUNT(*) AS orders
FROM shifts
GROUP BY shiftss;

-- Monthly sales trend (2022)
SELECT MONTH(sale_date) AS sale_month,
       SUM(total_sale) AS monthly_sales,
       SUM(SUM(total_sale)) OVER (ORDER BY MONTH(sale_date)) AS running_total
FROM retail_2
WHERE YEAR(sale_date) = 2022
GROUP BY sale_month
ORDER BY sale_month;

-- Yearly + Monthly sales with running totals
SELECT YEAR(sale_date) AS year,
       MONTH(sale_date) AS month,
       SUM(total_sale) AS monthly_sales,
       SUM(SUM(total_sale)) OVER (PARTITION BY YEAR(sale_date) ORDER BY MONTH(sale_date)) AS running_total
FROM retail_2
GROUP BY year, month
ORDER BY year, month;

-- Month-over-Month growth
WITH monthly AS (
    SELECT YEAR(sale_date) AS year,
           MONTH(sale_date) AS month,
           SUM(total_sale) AS monthly_sales,
           LAG(SUM(total_sale)) OVER (PARTITION BY YEAR(sale_date) ORDER BY MONTH(sale_date)) AS prev_sales
    FROM retail_2
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT year, month, monthly_sales,
       ROUND(((monthly_sales - prev_sales) * 100 / prev_sales), 2) AS mom_growth
FROM monthly
ORDER BY year, month;

-- Year-over-Year growth
WITH yearly AS (
    SELECT YEAR(sale_date) AS year,
           MONTH(sale_date) AS month,
           SUM(total_sale) AS monthly_sales,
           LAG(SUM(total_sale)) OVER (ORDER BY YEAR(sale_date), MONTH(sale_date)) AS prev_sales
    FROM retail_2
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT year, month, monthly_sales,
       ROUND(((monthly_sales - prev_sales) * 100 / prev_sales), 2) AS yoy_growth
FROM yearly
ORDER BY year, month;

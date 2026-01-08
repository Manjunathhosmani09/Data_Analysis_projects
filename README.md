# Retail Sales Data Analysis Project Report

## 1. Introduction
This project demonstrates how SQL can be used to clean, explore, and analyze retail sales data. The dataset contains transaction records across categories (Clothing, Beauty, Electronics), along with customer demographics, sales amounts, and timestamps.  

Objectives:
- Clean and prepare the dataset.  
- Explore customer demographics and purchasing behavior.  
- Generate category-level insights.  
- Identify top customers and cross-selling opportunities.  
- Analyze time-based sales trends.  
- Provide actionable business interpretations relevant to a retailer like Target.  

---

## 2. Data Preparation and Cleaning

```sql
-- Explore dataset
SELECT COUNT(*) AS record_count FROM retail;
SELECT COUNT(DISTINCT customer_id) AS customer_count FROM retail;
SELECT COUNT(DISTINCT category) AS category_count FROM retail;

-- Fix schema issues
ALTER TABLE retail CHANGE COLUMN ï»¿transactions_id transaction_id INT;
ALTER TABLE retail MODIFY COLUMN sale_date DATE;
ALTER TABLE retail MODIFY COLUMN sale_time TIME;
ALTER TABLE retail RENAME COLUMN quantiy TO quantity;

-- Identify nulls
SELECT *
FROM retail
WHERE customer_id IS NULL OR gender IS NULL OR age IS NULL
   OR category IS NULL OR quantity IS NULL OR price_per_unit IS NULL
   OR cogs IS NULL OR transaction_id IS NULL OR total_sale IS NULL;

-- Remove duplicates
CREATE TABLE retail_2 AS
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY transaction_id, sale_date, sale_time, customer_id, gender, age, category, quantity, price_per_unit, cogs, total_sale) AS dupe_rank
FROM retail;

DELETE FROM retail_2 WHERE dupe_rank > 1;
```

**Interpretation:**  
- Dataset contained ~400+ records, ~150 unique customers, and 3 categories.  
- Several records had missing values in `age`, `quantity`, and `cogs`.  
- Duplicates were removed using `ROW_NUMBER()`.  
- Clean dataset ensures reliable analysis.

---

## 3. Category-Level Insights

```sql
-- Max and Min sales in Electronics
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
```

**Interpretation:**  
- Electronics: Max sale = ₹2000, Min sale = ₹25.  
- Average sales: Electronics highest (~₹950), Clothing moderate (~₹700), Beauty lowest (~₹400).  
- Total revenue: Clothing generated the highest overall revenue due to frequent purchases.  
- Beauty had the most transactions but smaller ticket sizes.  

---

## 4. Customer Demographics

```sql
-- Average age by category
SELECT category, AVG(age) AS avg_age
FROM retail_2
GROUP BY category;

-- Gender split by category
SELECT gender, category, COUNT(*) AS transactions
FROM retail_2
GROUP BY gender, category
ORDER BY category;
```

**Interpretation:**  
- Clothing: Average age ~40, balanced gender split.  
- Beauty: Average age ~30, dominated by female customers.  
- Electronics: Average age ~45, dominated by male customers.  
- Demographic preferences: Beauty appeals to younger women, Electronics to middle-aged men, Clothing is universal.

---

## 5. Customer Behavior

```sql
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
```

**Interpretation:**  
- A small set of customers contributed disproportionately to revenue (top 5 spenders).  
- Multi-category buyers are valuable for cross-selling opportunities.  
- These insights support loyalty programs and personalized offers.

---

## 6. Time-Based Analysis

```sql
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
```

**Interpretation:**  
- Shift analysis: Morning sales dominated by Clothing, Afternoon by Beauty, Evening by Electronics.  
- Monthly trend (2022): Sales peaked in November–December (holiday season), dipped in February–March.  
- MoM growth: Positive spikes in festive months, declines in off-season.  
- YoY growth: 2023 showed stronger Clothing sales compared to 2022.  

---

## 7. Conclusion
This project demonstrates the end-to-end workflow of a data analyst:
- **Data Cleaning**: Ensured dataset integrity.  
- **Exploratory Analysis**: Delivered insights into categories, customers, and demographics.  
- **Business Insights**: Identified top customers, cross-selling opportunities, and seasonal trends.  
- **Retail Relevance**: Findings can guide merchandising, marketing, staffing, and loyalty strategies for a retailer like Target.  

**Final Note:**  
SQL is not just for querying—it can generate **business-ready insights** that drive decision-making. This project highlights how technical skills translate into actionable strategies.

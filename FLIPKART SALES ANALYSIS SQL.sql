CREATE DATABASE SQL_PROJECT2;
USE SQL_PROJECT2;

-- CREATING TABLE STRUCTURE.

CREATE TABLE FLKPT_DATA (
    product_id VARCHAR(50),
    product_name VARCHAR(255),
    category VARCHAR(100),
    brand VARCHAR(100),
    seller VARCHAR(150),
    seller_city VARCHAR(100),
    price DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    final_price DECIMAL(10,2),
    rating DECIMAL(3,2),
    review_count INT,
    stock_available INT,
    units_sold INT,
    listing_date TEXT,
    delivery_days INT,
    weight_g INT,
    warranty_months INT,
    color VARCHAR(50),
    size VARCHAR(50),
    return_policy_days INT,
    is_returnable BOOLEAN,
    payment_modes VARCHAR(255),
    product_score DECIMAL(5,2),
    seller_rating DECIMAL(3,2)
);

update flkpt_data
set listing_date= str_to_date(listing_date, '%d-%m-%Y');

select * 
from flkpt_data
limit 10;
-- KEY METRICS --

-- TOTAL SALES.
SELECT 
    ROUND(SUM(units_sold*final_price)) AS TOTAL_SALES
FROM FLKPT_DATA;

-- TOTAL UNITS SOLD
SELECT 
    SUM(units_sold) AS TOTAL_SOLD
FROM FLKPT_DATA;

-- AVG SELLING PRICE.
SELECT 
    ROUND(AVG(final_price),1) AS avg_SP
FROM FLKPT_DATA;

-- AVG DISCOUNT %
SELECT 
    CONCAT(ROUND(AVG(discount_percent), 2),'%') AS AVG_DISC
FROM FLKPT_DATA;

-- AVG PRODUCT RATING.
SELECT 
    ROUND(AVG(rating), 2) AS AVG_RATING
FROM FLKPT_DATA;


-- SALES AND REVENUE ANALYSIS. --


-- AVG PRICE VS FINAL SELLING PRICE.
SELECT 
    ROUND(AVG(price),2) AS avg_price,
    ROUND(AVG(final_price),2) AS avg_final_price
FROM flkpt_data;

-- CATEGORYWISE SALES VOLUME.
SELECT category,
    SUM(units_sold) AS TUNITS_SOLD
FROM flkpt_data
GROUP BY category
ORDER BY TUNITS_SOLD DESC;

-- TOTAL PROFIT
SELECT 
    ROUND(SUM((price - final_price) * units_sold), 2) AS total_profit
FROM flkpt_data;

-- MONTHLY SALES
SELECT 
    MONTHNAME(STR_TO_DATE(listing_date, '%Y-%m-%d')) AS month_name,
    ROUND(SUM(final_price * units_sold)) AS total_sales
FROM flkpt_data
GROUP BY month_name
ORDER BY MONTHNAME(STR_TO_DATE(listing_date, '%Y-%m-%d'));

UPDATE flkpt_data
SET LISTING_DATE=str_to_date(LISTING_DATE, '%Y-%m-%d');

SELECT DISTINCT(str_to_date(LISTING_DATE, '%Y-%m-%d'))
FROM FLKPT_DATA;


-- DISCOUNT IMPACT ON SALES.
SELECT 
CASE 
WHEN discount_percent = 0 THEN 'No Discount'
WHEN discount_percent BETWEEN 1 AND 20 THEN 'Low Discount'
WHEN discount_percent BETWEEN 21 AND 50 THEN 'Medium Discount'
ELSE 'High Discount'
END AS discount_bucket,
SUM(units_sold) AS total_units_sold
FROM flkpt_data
GROUP BY discount_bucket;

-- TOP 5 PRODUCTS BY SALES.
SELECT
product_name,
ROUND(SUM(units_sold * final_price)) AS total_sales
FROM flkpt_data
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 5;


-- PRODUCT ANALYSIS 

-- TOTAL NUMBER OF PRODUCTS.
SELECT distinct(COUNT(product_name)) AS total_products
FROM flkpt_data;

-- PRODUCT CATEGORIES AND BRANDS.
SELECT 
    COUNT(DISTINCT category) AS total_categories,
    COUNT(DISTINCT brand) AS total_brands
FROM flkpt_data;


SELECT 
    product_name,
    stock_available
FROM flkpt_data
WHERE stock_available = 0;

-- HIGH RATING BUT LOW SALES PRODUCT. 
SELECT 
    product_name,
    rating,
    units_sold
FROM flkpt_data
WHERE rating >= 4.5
  AND units_sold < (SELECT AVG(units_sold) FROM flkpt_data)
  LIMIT 10;
  
-- RANKING TOP PRODUCTS PER CATEGORY. 
SELECT *
FROM (
    SELECT 
        category,
        product_name,
        product_score,
        dense_rank() OVER (PARTITION BY category ORDER BY product_score DESC) AS rank_in_category
    FROM flkpt_data
) ranked
WHERE rank_in_category <= 3
GROUP BY   category,
        product_name,
        product_score
order by category, rank_in_category;

-- MOST PREFERRED PAYMENT METHOD.
SELECT
    payment_modes,
    COUNT(*) AS product_count
FROM FLKPT_DATA
GROUP BY payment_modes
ORDER BY product_count DESC;

-- OVERSTOCKED PRODUCTS
SELECT 
product_name,
Stock_available,
units_sold
FROM flkpt_data
WHERE stock_available > (SELECT AVG(stock_available) FROM flkpt_data)
AND units_sold < (SELECT AVG(units_sold) FROM flkpt_data);


-- SELLER ANALYSIS. 
-- TOTAL PRODUCTS SOLD BY EACH SELLER. 
SELECT 
    seller, COUNT(*) AS TOTAL_PRODUCTS
FROM
    flkpt_data
GROUP BY seller;


-- TOP 5 SELLERS BY REVENUE. 
SELECT 
    seller,
    ROUND(SUM(units_sold * final_price)) AS total_revenue
FROM flkpt_data
GROUP BY seller
ORDER BY total_revenue DESC
LIMIT 5;

-- AVG SELLER RATING. 
SELECT 
    seller,
    FLOOR(ROUND(AVG(seller_rating), 3)) AS avg_seller_rating
FROM FLKPT_DATA
GROUP BY seller
ORDER BY avg_seller_rating DESC;

-- HIGH REVENUE BUT LOW SELLING SELLER. 
SELECT seller,
FLOOR(ROUND(AVG(seller_rating),3)) AS avg_rating,
ROUND(SUM(units_sold * final_price)) AS total_revenue
FROM FLKPT_DATA
GROUP BY seller
HAVING avg_rating < (SELECT AVG(seller_rating) FROM flkpt_data)
AND total_revenue > (SELECT AVG(units_sold * final_price) FROM flkpt_data);


-- DELIVERY & OPERATIONS

-- LATE DELIVERY PERCENTAGE. 
SELECT 
    CONCAT(ROUND(
        SUM(CASE WHEN delivery_days > 7 THEN 1 ELSE 0 END) * 100 / COUNT(*),
        2
    ), '%') AS late_delivery_percentage
FROM flkpt_data;

-- SHIPPING EFFICIENCY.
SELECT 
CASE 
WHEN delivery_days <= 5 THEN 'Fast'
WHEN delivery_days BETWEEN 6 AND 10 THEN 'Medium'
ELSE 'Slow'
END AS delivery_speed,
COUNT(*) AS total_products_delivrd
FROM flkpt_data
GROUP BY delivery_speed;

-- EARLY VS LATE DELIVERY. 
SELECT 
    CASE 
        WHEN delivery_days <= 7 THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM flkpt_data
GROUP BY delivery_status;

   
-- YEARLY SALES TREND. 
SELECT 
    YEAR(listing_date) AS YEARS,
    SUM(final_price * units_sold) AS sales
FROM flkpt_data
GROUP BY YEARS
ORDER BY YEARS;

-- PEAK SALES MONTH. 
SELECT month,sales
FROM (
    SELECT 
        monthname(listing_date) AS month,
        SUM(final_price * units_sold) AS sales
    FROM flkpt_data
    GROUP BY month
) t
ORDER BY sales DESC
LIMIT 1;

-- DAYWISE PRODUCT LISTINGS. 
SELECT 
    DAYNAME(listing_date) AS day,
    COUNT(*) AS products_listed
FROM flkpt_data
GROUP BY day;

-- FESTIVE SEASON IMPACT. 
SELECT year, quarter, sales
FROM (
SELECT 
YEAR(listing_date) AS year,
QUARTER(listing_date) AS quarter,
SUM(final_price * units_sold) AS sales,
RANK() OVER (PARTITION BY YEAR(listing_date)
ORDER BY SUM(final_price * units_sold) DESC) AS rnk
FROM flkpt_data
GROUP BY year, quarter
) qt
WHERE rnk = 1
ORDER BY year;

-- YEAR ON YEAR PERCENTAGE. 
SELECT year,sales,
LAG(sales) OVER (ORDER BY year) AS prev_year_sales,
CONCAT(ROUND(
(sales - LAG(sales) OVER (ORDER BY year))
/ NULLIF(LAG(sales) OVER (ORDER BY year), 0) * 100, 1
), '%') AS yoy_percent
FROM (
    SELECT 
        YEAR(listing_date) AS year,
        SUM(final_price * units_sold) AS sales
    FROM flkpt_data
    GROUP BY year
) YOYt
ORDER BY year;
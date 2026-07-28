-- =====================================================
-- E-COMMERCE SALES & RETENTION ANALYSIS
-- Database : ecommerce_analysis
-- MySQL 8.0
-- =====================================================

USE ecommerce_analysis;

-- =====================================================
-- SECTION 1 : EXECUTIVE KPIs
-- =====================================================

-- Q1 Total Orders
SELECT COUNT(*) AS total_orders FROM orders;

-- Q2 Total Customers
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers;

-- Q3 Total Revenue
SELECT ROUND(SUM(payment_value),2) AS total_revenue
FROM order_payments;

-- Q4 Average Order Value
SELECT ROUND(SUM(payment_value)/COUNT(DISTINCT order_id),2) AS average_order_value
FROM order_payments;

-- Q5 Average Review Score
SELECT ROUND(AVG(review_score),2) AS average_review_score
FROM order_reviews;

-- Q6 Order Status Distribution
SELECT order_status,COUNT(*) total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- =====================================================
-- SECTION 2 : REVENUE ANALYSIS
-- =====================================================

-- Q7 Monthly Revenue
SELECT DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS month,
ROUND(SUM(op.payment_value),2) revenue
FROM orders o
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY month
ORDER BY month;

-- Q8 Revenue by State
SELECT c.customer_state,
ROUND(SUM(op.payment_value),2) revenue
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- Q9 Revenue by Product Category
SELECT COALESCE(ct.product_category_name_english,'Unknown') category,
ROUND(SUM(oi.price),2) revenue
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
LEFT JOIN category_translation ct
ON p.product_category_name=ct.product_category_name
GROUP BY category
ORDER BY revenue DESC;

-- Q10 Revenue per Customer
SELECT ROUND(SUM(op.payment_value)/
COUNT(DISTINCT c.customer_unique_id),2)
AS revenue_per_customer
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_payments op ON o.order_id=op.order_id;

-- Q11 Highest Value Orders
SELECT o.order_id,
ROUND(SUM(op.payment_value),2) order_value
FROM orders o
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY o.order_id
ORDER BY order_value DESC
LIMIT 10;

-- =====================================================
-- SECTION 3 : CUSTOMER ANALYSIS
-- =====================================================

-- Q12 Customer Segmentation
SELECT c.customer_unique_id,
COUNT(DISTINCT o.order_id) total_orders,
ROUND(SUM(op.payment_value),2) total_spent,
CASE
WHEN SUM(op.payment_value)>=1000 THEN 'VIP'
WHEN SUM(op.payment_value)>=500 THEN 'Premium'
WHEN SUM(op.payment_value)>=200 THEN 'Regular'
ELSE 'New'
END customer_segment
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC;

-- Q13 Repeat Customer %
SELECT ROUND(
100*SUM(CASE WHEN total_orders>1 THEN 1 ELSE 0 END)/COUNT(*),2)
AS repeat_customer_percentage
FROM(
SELECT customer_unique_id,COUNT(*) total_orders
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
GROUP BY customer_unique_id
)t;

-- Q14 Top 20 Customers
SELECT *
FROM(
SELECT c.customer_unique_id,
ROUND(SUM(op.payment_value),2) total_spent,
DENSE_RANK() OVER(ORDER BY SUM(op.payment_value) DESC) customer_rank
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY c.customer_unique_id
)x
WHERE customer_rank<=20;

-- Q15 Running Monthly Revenue
WITH monthly AS(
SELECT DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') month,
SUM(op.payment_value) revenue
FROM orders o
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY month
)
SELECT month,
ROUND(revenue,2) monthly_revenue,
ROUND(SUM(revenue) OVER(ORDER BY month),2) cumulative_revenue
FROM monthly;

-- Q16 Month-over-Month Growth
WITH monthly AS(
SELECT DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') month,
SUM(op.payment_value) revenue
FROM orders o
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY month
)
SELECT month,
ROUND(revenue,2) revenue,
ROUND(LAG(revenue) OVER(ORDER BY month),2) previous_month,
ROUND(
100*(revenue-LAG(revenue) OVER(ORDER BY month))
/LAG(revenue) OVER(ORDER BY month),2
) growth_percentage
FROM monthly;

-- =====================================================
-- SECTION 4 : PRODUCT ANALYSIS
-- =====================================================

-- Q17 Top Categories by Orders
SELECT COALESCE(ct.product_category_name_english,'Unknown') category,
COUNT(*) total_items
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
LEFT JOIN category_translation ct
ON p.product_category_name=ct.product_category_name
GROUP BY category
ORDER BY total_items DESC
LIMIT 10;

-- Q18 Average Product Price by Category
SELECT COALESCE(ct.product_category_name_english,'Unknown') category,
ROUND(AVG(oi.price),2) avg_price
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
LEFT JOIN category_translation ct
ON p.product_category_name=ct.product_category_name
GROUP BY category
ORDER BY avg_price DESC;

-- Q19 Highest Freight Categories
SELECT COALESCE(ct.product_category_name_english,'Unknown') category,
ROUND(AVG(oi.freight_value),2) avg_freight
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
LEFT JOIN category_translation ct
ON p.product_category_name=ct.product_category_name
GROUP BY category
ORDER BY avg_freight DESC;

-- Q20 Category Rating
SELECT COALESCE(ct.product_category_name_english,'Unknown') category,
ROUND(AVG(r.review_score),2) avg_rating
FROM order_items oi
JOIN products p ON oi.product_id=p.product_id
LEFT JOIN category_translation ct
ON p.product_category_name=ct.product_category_name
JOIN order_reviews r ON oi.order_id=r.order_id
GROUP BY category
ORDER BY avg_rating DESC;

-- =====================================================
-- SECTION 5 : SELLER ANALYSIS
-- =====================================================

-- Q21 Top Sellers
SELECT seller_id,
ROUND(SUM(price),2) revenue
FROM order_items
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;

-- Q22 Seller Order Count
SELECT seller_id,
COUNT(DISTINCT order_id) total_orders
FROM order_items
GROUP BY seller_id
ORDER BY total_orders DESC
LIMIT 10;

-- Q23 Revenue by Seller State
SELECT s.seller_state,
ROUND(SUM(oi.price),2) revenue
FROM sellers s
JOIN order_items oi
ON s.seller_id=oi.seller_id
GROUP BY s.seller_state
ORDER BY revenue DESC;

-- =====================================================
-- SECTION 6 : DELIVERY ANALYSIS
-- =====================================================

-- Q24 Average Delivery Days
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date,
order_purchase_timestamp)),2) avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Q25 Delayed Orders
SELECT COUNT(*) delayed_orders
FROM orders
WHERE order_delivered_customer_date >
order_estimated_delivery_date;

-- Q26 Delivery Days by State
SELECT c.customer_state,
ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
o.order_purchase_timestamp)),2) avg_days
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_days DESC;

-- =====================================================
-- SECTION 7 : REVIEW ANALYSIS
-- =====================================================

-- Q27 Rating Distribution
SELECT review_score,
COUNT(*) reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Q28 Rating by State
SELECT c.customer_state,
ROUND(AVG(r.review_score),2) avg_rating
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_reviews r ON o.order_id=r.order_id
GROUP BY c.customer_state
ORDER BY avg_rating DESC;

-- =====================================================
-- SECTION 8 : ADVANCED ANALYTICS
-- =====================================================

-- Q29 Top 10% Customers
WITH spending AS(
SELECT c.customer_unique_id,
SUM(op.payment_value) total_spent
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_payments op ON o.order_id=op.order_id
GROUP BY c.customer_unique_id
)
SELECT *,
NTILE(10) OVER(ORDER BY total_spent DESC) spending_decile
FROM spending;

-- Q30 Revenue Contribution by State
SELECT customer_state,
ROUND(SUM(revenue),2) revenue,
ROUND(100*SUM(revenue)/SUM(SUM(revenue)) OVER(),2) pct_revenue
FROM(
SELECT c.customer_state,
op.payment_value revenue
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
JOIN order_payments op ON o.order_id=op.order_id
)x
GROUP BY customer_state
ORDER BY revenue DESC;

-- =====================================================
-- BUSINESS QUESTION 31
-- What is the average time gap between consecutive purchases?
-- =====================================================

WITH purchases AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS previous_purchase
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
)

SELECT
    ROUND(
        AVG(DATEDIFF(order_purchase_timestamp, previous_purchase)),
        2
    ) AS avg_days_between_purchases
FROM purchases
WHERE previous_purchase IS NOT NULL;

-- =====================================================
-- BUSINESS QUESTION 32
-- Analyze monthly customer cohorts.
-- =====================================================

WITH first_purchase AS (
    SELECT
        c.customer_unique_id,
        MIN(DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m')) AS cohort_month
    FROM customers c
    JOIN orders o
        ON c.customer_id=o.customer_id
    GROUP BY c.customer_unique_id
),

activity AS (
    SELECT
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS active_month
    FROM customers c
    JOIN orders o
        ON c.customer_id=o.customer_id
)

SELECT
    f.cohort_month,
    a.active_month,
    COUNT(DISTINCT a.customer_unique_id) AS active_customers
FROM first_purchase f
JOIN activity a
    ON f.customer_unique_id=a.customer_unique_id
GROUP BY
    f.cohort_month,
    a.active_month
ORDER BY
    f.cohort_month,
    a.active_month;

-- =====================================================
-- BUSINESS QUESTION 33
-- Perform RFM Segmentation.
-- =====================================================

WITH rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM orders),
            MAX(o.order_purchase_timestamp)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(op.payment_value) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id=o.customer_id
    JOIN order_payments op
        ON o.order_id=op.order_id
    GROUP BY c.customer_unique_id
),

scores AS (
    SELECT *,
        NTILE(4) OVER(ORDER BY recency DESC) AS r_score,
        NTILE(4) OVER(ORDER BY frequency) AS f_score,
        NTILE(4) OVER(ORDER BY monetary) AS m_score
    FROM rfm
)

SELECT *,
CASE
    WHEN r_score <= 2 AND m_score >= 3 THEN 'At-Risk High Value'
    WHEN r_score = 1 AND f_score = 4 THEN 'Champions'
    WHEN r_score = 4 AND f_score = 4 THEN 'Loyal Customers'
    WHEN r_score = 4 AND f_score = 1 THEN 'New Customers'
    ELSE 'Others'
END AS segment
FROM scores;

-- =====================================================
-- BUSINESS QUESTION 34
-- Does delayed delivery affect customer reviews?
-- =====================================================

SELECT
CASE
    WHEN DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ) <= 0 THEN 'On Time'

    WHEN DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ) <= 5 THEN 'Slightly Late'

    ELSE 'Very Late'
END AS delay_bucket,

ROUND(AVG(r.review_score),2) AS avg_review_score,

COUNT(*) AS order_count

FROM orders o

JOIN order_reviews r
    ON o.order_id=r.order_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY delay_bucket

ORDER BY avg_review_score DESC;


-- =====================================================
-- BUSINESS QUESTION 35
-- Which are the top-selling products in each category?
-- =====================================================

SELECT *
FROM (
    SELECT
        COALESCE(ct.product_category_name_english,'Unknown') AS category,
        oi.product_id,
        ROUND(SUM(oi.price),2) AS revenue,
        DENSE_RANK() OVER(
            PARTITION BY ct.product_category_name_english
            ORDER BY SUM(oi.price) DESC
        ) AS product_rank
    FROM order_items oi
    JOIN products p
        ON oi.product_id=p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name=ct.product_category_name
    GROUP BY
        category,
        oi.product_id
) x
WHERE product_rank <= 5;

-- =====================================================
-- BUSINESS QUESTION 36
-- Which payment methods are most preferred?
-- =====================================================

SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(SUM(payment_value),2) AS total_revenue,
    ROUND(AVG(payment_value),2) AS average_payment
FROM order_payments
GROUP BY payment_type
ORDER BY total_revenue DESC;
-- =====================================================
-- EXECUTIVE SUMMARY (Fill after analysis)
-- =====================================================
-- 1. Highest Revenue State:
-- 2. Best Product Category:
-- 3. Average Order Value:
-- 4. Repeat Customer Rate:
-- 5. Average Delivery Time:
-- 6. Highest Rated Category:
-- 7. Key Recommendation:
